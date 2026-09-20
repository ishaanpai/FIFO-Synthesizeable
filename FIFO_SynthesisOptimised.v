`timescale 1ns/1ps

//ACTIVE-LOW RESET - FIFO HEIGHT >= 4

module FIFO
#(parameter WIDTH=16, 
parameter HEIGHT=16)
(input rst, 
input rclk, 
input wclk,
input wEn, 
input rEn, 
input wire [WIDTH-1:0] datIn,
output reg [WIDTH-1:0] datOut,
output reg empty,
output reg full);

    localparam pSize = $clog2(HEIGHT);
    reg [WIDTH-1:0] mem[0:HEIGHT-1];

//rclk domain
    //Read Pointers
    reg [pSize:0] rdptr_bin;
    wire [pSize:0] rdptr_bin_next = rdptr_bin + rdvalid;
    wire [pSize:0] rdptr_grey_next = rdptr_bin_next  ^ (rdptr_bin_next >> 1);
    reg [pSize:0] rdptr_grey;
    
    //Write Syncs
    reg [pSize:0] wrptr_sync1;
    reg [pSize:0] wrptr_sync2;
    
//wclk domain
    //Write Pointers
    reg [pSize:0] wrptr_bin;
    wire [pSize:0] wrptr_bin_next = wrptr_bin + wrvalid;
    wire [pSize:0] wrptr_grey_next = wrptr_bin_next  ^ (wrptr_bin_next >> 1);
    reg [pSize:0] wrptr_grey;

    //Read Syncs
    reg [pSize:0] rdptr_sync1;
    reg [pSize:0] rdptr_sync2;

//Validity
    wire rdvalid = rEn && !empty;
    wire wrvalid = wEn && !full;

//Read Clock Behaviour
    always@(posedge rclk or negedge rst) begin
        if(!rst) begin
            //Resetting Write Synchronisation Pointers
            wrptr_sync1 <= 0;
            wrptr_sync2 <= 0;
        end
        else begin
            //Write Pointer Synchronisation
            wrptr_sync1 <= wrptr_grey;
            wrptr_sync2 <= wrptr_sync1;
        end
    end

    always@(posedge rclk or negedge rst) begin
        if(!rst) begin
            //Resetting Read Pointers
            rdptr_bin <= 0;
            rdptr_grey <= 0;
        end
        else if(rdvalid) begin
            //Read Pointer Updation
            rdptr_bin <= rdptr_bin_next;
            rdptr_grey <= rdptr_grey_next;
        end
    end

    always @(posedge rclk) begin
        if (rdvalid) begin
            //Data Read
            datOut <= mem[rdptr_bin[pSize-1:0]];
        end
    end

    always@(posedge rclk or negedge rst) begin
        if(!rst) begin
            //Resetting Empty Flag
            empty <= 1;
        end
        else begin
            //Empty Flag Updation
            empty <= (rdptr_grey_next == wrptr_sync2);
        end
    end
    

//Write Clock Behaviour
    always@(posedge wclk or negedge rst) begin
        if(!rst) begin
            //Resetting Read Synchronisation Pointers
            rdptr_sync1 <= 0;
            rdptr_sync2 <= 0;
        end
        else begin
            //Read Pointer Synchronisation
            rdptr_sync1 <= rdptr_grey;
            rdptr_sync2 <= rdptr_sync1;
        end
    end

    always@(posedge wclk or negedge rst) begin
        if(!rst) begin
            //Resetting Write Pointers
            wrptr_bin <= 0;
            wrptr_grey <= 0;
        end
        else if(wrvalid) begin
            //Write Pointer Updation
            wrptr_bin <= wrptr_bin_next;
            wrptr_grey <= wrptr_grey_next;
        end
    end

    always@(posedge wclk) begin
        if(wrvalid) begin
            //Data Write
            mem[wrptr_bin[pSize-1:0]] <= datIn;
        end
    end

    always@(posedge wclk or negedge rst) begin
        if(!rst) begin
            //Resetting Full Flag
            full <= 0;
        end
        else begin
            //Full Flag Updation
            full <= (wrptr_grey_next == {~rdptr_sync2[pSize:pSize-1], rdptr_sync2[pSize-2:0]});
        end
    end

endmodule