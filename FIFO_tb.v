`timescale 1ns/1ps
`include "FIFO_SynthesisOptimised.v"

module FIFO_tb;

    localparam WIDTH  = 16;
    localparam HEIGHT = 16;

    reg                 rst;
    reg                 wclk;
    reg                 rclk;
    reg                 wEn;
    reg                 rEn;
    reg  [WIDTH-1:0]    datIn;

    wire [WIDTH-1:0]    datOut;
    wire                empty;
    wire                full;

    //Instantiate the DUT
    FIFO #(
        .WIDTH  (WIDTH),
        .HEIGHT (HEIGHT)
    ) dut (
        .rst    (rst),
        .rclk   (rclk),
        .wclk   (wclk),
        .wEn    (wEn),
        .rEn    (rEn),
        .datIn  (datIn),
        .datOut (datOut),
        .empty  (empty),
        .full   (full)
    );

    //Clock Generation
    initial begin
        wclk = 0;
        forever #5 wclk = ~wclk;
    end

    initial begin
        rclk = 0;
        forever #10 rclk = ~rclk; 
    end

    //Print buffer contents in a clean, single-line format

    task display_buffer(input [8*8-1:0] trigger_event);
        integer i;
        begin
            $write("[%0t ps | Trigger: %s] wptr:%0d rdptr:%0d | F:%b E:%b | MEM: [ ",
                   $time, trigger_event, dut.wrptr_bin, dut.rdptr_bin, full, empty);
            for (i = 0; i < HEIGHT; i = i + 1) begin
                $write("%04h ", dut.mem[i]);
            end
            $write("]\n");
        end
    endtask

    //Triggered on posedge of EITHER wclk or rclk
    initial begin
        //Wait until out of initial reset so we don't spam during initialisation
        @(posedge rst);
        forever begin
            @(posedge wclk or posedge rclk);
            // #1 delta delay allows non-blocking register updates to settle
            #1;
            if (wclk && rclk)
                display_buffer("BOTH_CLK");
            else if (wclk)
                display_buffer("WCLK_EDGE");
            else
                display_buffer("RCLK_EDGE");
        end
    end

    //Main Test Stimulus
    initial begin
        $dumpfile("fifo_concurrent_dump.vcd");
        $dumpvars(0, FIFO_tb);

        // Signal initialisation
        wEn   = 1'b0;
        rEn   = 1'b0;
        datIn = {WIDTH{1'b0}};
        rst   = 1'b0; //Assert active-low reset

        #40;
        @(negedge wclk);
        rst   = 1'b1; //Deassert reset

        //Concurrently run producer (writes) and consumer (reads)
        fork
            //Write Process (Producer)
            begin
                repeat (30) begin
                    @(posedge wclk);
                    if (!full) begin
                        wEn   <= 1'b1;
                        datIn <= $urandom_range(16'h1000, 16'hFFFF);
                    end else begin
                        wEn   <= 1'b0; // Stall on full
                    end
                end
                @(posedge wclk);
                wEn <= 1'b0;
            end

            //Read Process (Consumer)
            begin
                //Let a few items enter the buffer first
                repeat (3) @(posedge rclk);

                repeat (30) begin
                    @(posedge rclk);
                    if (!empty) begin
                        rEn <= 1'b1;
                    end else begin
                        rEn <= 1'b0; //Stall on empty
                    end
                end
                @(posedge rclk);
                rEn <= 1'b0;
            end
        join

        //Drain any remaining words
        $display("\n--- Draining any remaining entries ---");
        while (!empty) begin
            @(posedge rclk);
            rEn <= 1'b1;
            @(posedge rclk);
            rEn <= 1'b0;
        end

        #100;
        $display("\nSimulation Complete.");
        $finish;
    end

endmodule