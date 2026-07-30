`timescale 1ns / 1ns
`include "FIFO.v"

module tb_top;

    parameter width = 16;
    parameter depth = 32;

    // Inputs to UUT (reg)
    reg LCLK;
    reg RCLK;
    reg WRDV;
    reg RDEN;
    reg [width-1:0] WRDAT;

    // Outputs from UUT (wire)
    wire F;
    wire E;
    wire [width-1:0] RDDAT;

    // Instantiate UUT
    top #(
        .width(width),
        .depth(depth)
    ) uut (
        .LCLK(LCLK),
        .RCLK(RCLK),
        .WRDV(WRDV),
        .RDEN(RDEN),
        .WRDAT(WRDAT),
        .F(F),
        .E(E),
        .RDDAT(RDDAT)
    );

    // 1. Simple, continuous clock generators
    always #5 LCLK = (LCLK === 1'b0) ? 1'b1 : 1'b0;
    always #7 RCLK = (RCLK === 1'b0) ? 1'b1 : 1'b0;

    // 2. Absolute hardcoded stimulus sequence
    initial begin
        // Initialize everything strictly to 0
        LCLK  = 0;
        RCLK  = 0;
        WRDV  = 0;
        RDEN  = 0;
        WRDAT = 0;

        // Open wave dump files
        $dumpfile("FIFO_tb.vcd");
        $dumpvars(0, tb_top);
        
        #20; // Let the system settle

        $display("--- Starting Simple Hardcoded Test ---");

        // --- WRITE 1 ---
        WRDAT = 16'hAAAA;
        WRDV  = 1;
        #10; // Hold for 1 LCLK cycle
        WRDV  = 0;
        #10;

        // --- WRITE 2 ---
        WRDAT = 16'hBBBB;
        WRDV  = 1;
        #10;
        WRDV  = 0;
        #20;

        // --- WRITE 3 ---
        WRDAT = 16'hCCCC;
        WRDV  = 1;
        #10;
        WRDV  = 0;
        #30; // Wait a bit

        // --- READ 1 ---
        RDEN = 1;
        #14; // Hold for roughly 1 RCLK cycle
        RDEN = 0;
        $display("[%0t ns] Output after Read 1: %h", $time, RDDAT);
        #20;

        // --- READ 2 ---
        RDEN = 1;
        #14;
        RDEN = 0;
        $display("[%0t ns] Output after Read 2: %h", $time, RDDAT);
        #40;

        $display("--- Hardcoded Test Complete ---");
        $finish;
    end

endmodule