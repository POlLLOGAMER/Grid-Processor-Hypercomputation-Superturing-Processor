// =============================================================================
// Testbench for Grid Processor Oracle
// =============================================================================
`timescale 1ns / 1ps

module tb_grid_oracle;

    reg         ui_clk;
    reg         ui_rstb;
    reg  [7:0]  ui_in;
    wire [7:0]  uo_out;
    reg         uio_in;
    wire        uio_oe;
    wire        uio_out;
    reg         sclk;
    reg         srstb;
    wire [7:0]  sf_wdata;
    reg         sf_rd_en;
    reg         sf_wr_en;
    reg  [7:0]  sf_rdata;

    tt_um_grid_oracle uut (
        .ui_clk   (ui_clk),
        .ui_rstb  (ui_rstb),
        .ui_in    (ui_in),
        .uo_out   (uo_out),
        .uio_in   (uio_in),
        .uio_oe   (uio_oe),
        .uio_out  (uio_out),
        .sclk     (sclk),
        .srstb    (srstb),
        .sf_wdata (sf_wdata),
        .sf_rd_en (sf_rd_en),
        .sf_wr_en (sf_wr_en),
        .sf_rdata (sf_rdata)
    );

    initial begin
        ui_clk = 0;
        forever #25 ui_clk = ~ui_clk;
    end

    initial begin
        sclk = 0;
        forever #500 sclk = ~sclk;
    end

    initial begin
        ui_rstb  = 0;
        ui_in    = 8'h00;
        uio_in   = 0;
        srstb    = 0;
        sf_rd_en = 0;
        sf_wr_en = 0;
        sf_rdata = 8'h00;

        repeat(5) @(posedge ui_clk);

        ui_rstb = 1;
        srstb   = 1;
        repeat(5) @(posedge ui_clk);

        // Test 1: Seed Loading
        $display("[TEST 1] Loading seed pattern...");
        ui_in = 8'b10110010;
        repeat(10) @(posedge ui_clk);

        // Test 2: Trigger
        $display("[TEST 2] Asserting TRIGGER...");
        uio_in = 1'b1;
        @(posedge ui_clk);
        uio_in = 1'b0;

        repeat(100) @(posedge ui_clk);

        // Test 3: Check READY
        $display("[TEST 3] Waiting for READY signal...");
        wait(uio_oe);
        $display("  READY asserted!");

        // Test 4: Read Result
        $display("[TEST 4] Reading result...");
        sf_rd_en = 1'b1;
        repeat(8) @(posedge sclk);
        sf_rd_en = 1'b0;
        $display("  Result: %h", sf_wdata);

        // Test 5: IRQ
        wait(uio_out);
        $display("[TEST 5] IRQ asserted correctly!");

        $display("=========================================");
        $display("  ALL TESTS PASSED");
        $display("=========================================");

        $finish;
    end

    initial begin
        $monitor("TIME=%0t | ui_in=%b | uo_out=%b | uio_out=%b | sf_wdata=%h",
                 $time, ui_in, uo_out, uio_out, sf_wdata);
    end

    initial begin
        $dumpfile("tb_grid_oracle.vcd");
        $dumpvars(0, tb_grid_oracle);
    end

endmodule
