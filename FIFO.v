module top #(
    parameter width = 16,
    parameter depth = 32
)(
    input RCLK, LCLK, WRDV, RDEN,
    input [width-1:0] WRDAT,
    output reg F, E,
    output reg [width-1:0] RDDAT
);

	reg [width-1:0] mem [0:depth-1];
	
	reg [5:0] wr_ptr_bin = 0;
    reg [5:0] rd_ptr_bin = 0;
	
	wire [5:0] wr_ptr_grey;
    wire [5:0] rd_ptr_grey;
	
	assign rd_ptr_grey = rd_ptr_bin ^ (rd_ptr_bin >> 1);
	assign wr_ptr_grey = wr_ptr_bin ^ (wr_ptr_bin >> 1);
	
	reg [5:0] wr_ptr_grey_sync_1, wr_ptr_grey_sync_2;
    reg [5:0] rd_ptr_grey_sync_1, rd_ptr_grey_sync_2;
	
	
	// Update the read syncs when LCLK fires and update the write syncs when the RCLK fires
	
	always @(posedge LCLK) begin
		rd_ptr_grey_sync_1 <= rd_ptr_grey;
		rd_ptr_grey_sync_2 <= rd_ptr_grey_sync_1;
	end
	
	always @(posedge RCLK) begin
		wr_ptr_grey_sync_1 <= wr_ptr_grey;
		wr_ptr_grey_sync_2 <= wr_ptr_grey_sync_1;
	end
	
	
	// Write data into the registers of the FIFO memory on the firing of the LCLK given that the source has "Write Valid" and the FIFO is not full
	
	always @(posedge LCLK) begin
		if (WRDV && ~F) begin
			mem[wr_ptr_bin[4:0]] <= WRDAT;
			wr_ptr_bin <= wr_ptr_bin + 1;
		end
	end
	
	// Read data from the registers of the FIFO memory on the firing of the RCLK given that the reader has "Read Enabled" and the FIFO is not empty
	
	always @(posedge RCLK) begin
			if (RDEN && ~E) begin
				RDDAT <= mem[rd_ptr_bin[4:0]];
				rd_ptr_bin <= rd_ptr_bin + 1;
			end
	end
	
	
	// Set the Full and Empty flags as per the read and write pointers
	
	always@(*) begin
		// Full logic : first two MSBs match but the other two match
		F = (wr_ptr_grey == {~rd_ptr_grey_sync_2[5:4], rd_ptr_grey_sync_2[3:0]});
		
		// Empty logic : read pointer equal to write pointer
		E = rd_ptr_grey == wr_ptr_grey_sync_2; 
	end
	
endmodule