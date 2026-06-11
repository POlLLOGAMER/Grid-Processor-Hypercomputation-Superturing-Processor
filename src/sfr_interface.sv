// =============================================================================
// SFR Interface - Special Function Register bridge for RP2040 communication
// Maps internal state to external register reads
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module sfr_interface (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        sclk,
    input  wire        srstb,
    input  wire        rd_en,
    input  wire        wr_en,
    input  wire [63:0] projection,
    input  wire [31:0] grid_state,
    input  wire [3:0]  convergence,
    input  wire [31:0] iterations,
    input  wire [3:0]  status,
    output wire [7:0]  sf_wdata
);

    reg [7:0] sfr_regs [0:20];
    reg [4:0] addr;
    reg [7:0] sf_wdata_reg;

    assign sf_wdata = sf_wdata_reg;

    always @(posedge sclk or negedge srstb) begin
        if (!srstb) begin
            sf_wdata_reg <= 8'h00;
            addr         <= 5'b0;
        end else if (wr_en) begin
            sfr_regs[addr] <= sf_wdata_reg;
            addr           <= addr + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sfr_regs[0]  <= 8'h00; sfr_regs[1]  <= 8'h00;
            sfr_regs[2]  <= 8'h00; sfr_regs[3]  <= 8'h00;
            sfr_regs[4]  <= 8'h00; sfr_regs[5]  <= 8'h00;
            sfr_regs[6]  <= 8'h00; sfr_regs[7]  <= 8'h00;
            sfr_regs[8]  <= 8'h00; sfr_regs[9]  <= 8'h00;
            sfr_regs[10] <= 8'h00; sfr_regs[11] <= 8'h00;
            sfr_regs[12] <= 8'h00; sfr_regs[13] <= 8'h00;
            sfr_regs[14] <= 8'h00; sfr_regs[15] <= 8'h00;
            sfr_regs[16] <= 8'h00; sfr_regs[17] <= 8'h00;
            sfr_regs[18] <= 8'h00; sfr_regs[19] <= 8'h00;
            sfr_regs[20] <= 8'h00;
        end else if (rd_en) begin
            sfr_regs[0]  <= projection[63:56];
            sfr_regs[1]  <= projection[55:48];
            sfr_regs[2]  <= projection[47:40];
            sfr_regs[3]  <= projection[39:32];
            sfr_regs[4]  <= projection[31:24];
            sfr_regs[5]  <= projection[23:16];
            sfr_regs[6]  <= projection[15:8];
            sfr_regs[7]  <= projection[7:0];
            sfr_regs[8]  <= grid_state[31:24];
            sfr_regs[9]  <= grid_state[23:16];
            sfr_regs[10] <= grid_state[15:8];
            sfr_regs[11] <= grid_state[7:0];
            sfr_regs[12] <= {4'b0000, convergence};
            sfr_regs[13] <= iterations[31:24];
            sfr_regs[14] <= iterations[23:16];
            sfr_regs[15] <= iterations[15:8];
            sfr_regs[16] <= iterations[7:0];
            sfr_regs[17] <= {4'b0000, status};
        end
    end

endmodule
