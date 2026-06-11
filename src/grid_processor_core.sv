// =============================================================================
// Grid Processor Core - 8x8 Massively Parallel Cellular Array
// Oracle internal continuous-state computation
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module grid_processor_core (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        trigger,
    input  wire [7:0]  seed_data,
    input  wire        projection_clk,
    output wire [31:0] grid_state,
    output wire        grid_stable,
    output wire        grid_overflow,
    output wire [31:0] iteration_cnt,
    output wire [63:0] projection_out,
    output wire [3:0]  convergence
);

    wire [3:0] cell_state [0:63];
    wire [63:0] cell_stable;

    reg  [11:0] iteration_counter;
    reg         running;
    reg         overflow_flag;
    reg  [63:0] proj_buffer;
    reg  [3:0]  conv_flag;
    reg  [31:0] compressed_state;

    wire global_stable;

    // ================================================================
    // 8x8 Grid Cell Instantiation with Moore Neighborhood
    // ================================================================
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : row_gen
            for (j = 0; j < 8; j = j + 1) begin : col_gen
                localparam idx  = i * 8 + j;
                localparam n_i  = ((i-1+8)%8);
                localparam s_i  = ((i+1)%8);
                localparam e_j  = ((j+1)%8);
                localparam w_j  = ((j-1+8)%8);
                localparam n_idx = n_i * 8 + j;
                localparam s_idx = s_i * 8 + j;
                localparam e_idx = i * 8 + e_j;
                localparam w_idx = i * 8 + w_j;
                localparam ne_idx = n_i * 8 + e_j;
                localparam nw_idx = n_i * 8 + w_j;
                localparam se_idx = s_i * 8 + e_j;
                localparam sw_idx = s_i * 8 + w_j;

                grid_cell u_cell (
                    .clk       (clk),
                    .rst_n     (rst_n & running),
                    .enable    (1'b1),
                    .nw        (cell_state[nw_idx]),
                    .n         (cell_state[n_idx]),
                    .ne        (cell_state[ne_idx]),
                    .w         (cell_state[w_idx]),
                    .e         (cell_state[e_idx]),
                    .sw        (cell_state[sw_idx]),
                    .s         (cell_state[s_idx]),
                    .se        (cell_state[se_idx]),
                    .seed_in   (idx < 8 ? {4'b0000, seed_data[idx]} : 4'b0000),
                    .state_out (cell_state[idx]),
                    .is_stable (cell_stable[idx])
                );
            end
        end
    endgenerate

    assign global_stable = &cell_stable[63:0];

    reg [3:0] stable_cycle_count;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stable_cycle_count <= 4'b0000;
        else if (global_stable)
            stable_cycle_count <= stable_cycle_count + 1'b1;
        else
            stable_cycle_count <= 4'b0000;
    end

    assign convergence = stable_cycle_count;
    assign grid_stable = (stable_cycle_count >= 4'd3);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            iteration_counter <= 12'b0;
            running           <= 1'b0;
            overflow_flag     <= 1'b0;
        end else if (trigger && !running) begin
            running           <= 1'b1;
            iteration_counter <= 12'b0;
            overflow_flag     <= 1'b0;
        end else if (running) begin
            if (iteration_counter >= 12'd4095) begin
                overflow_flag <= 1'b1;
                running       <= 1'b0;
            end else begin
                iteration_counter <= iteration_counter + 1'b1;
            end
        end
    end

    assign iteration_cnt = {20'b0, iteration_counter};
    assign grid_overflow = overflow_flag;

    // ================================================================
    // Projection Buffer - 64-bit Quantized Collapse
    // ================================================================
    always @(posedge projection_clk or negedge rst_n) begin
        if (!rst_n) begin
            proj_buffer      <= 64'b0;
            compressed_state <= 32'b0;
        end else if (grid_stable || overflow_flag) begin
            proj_buffer[ 0] <= (cell_state[ 0] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[ 1] <= (cell_state[ 1] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[ 2] <= (cell_state[ 2] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[ 3] <= (cell_state[ 3] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[ 4] <= (cell_state[ 4] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[ 5] <= (cell_state[ 5] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[ 6] <= (cell_state[ 6] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[ 7] <= (cell_state[ 7] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[ 8] <= (cell_state[ 8] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[ 9] <= (cell_state[ 9] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[10] <= (cell_state[10] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[11] <= (cell_state[11] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[12] <= (cell_state[12] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[13] <= (cell_state[13] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[14] <= (cell_state[14] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[15] <= (cell_state[15] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[16] <= (cell_state[16] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[17] <= (cell_state[17] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[18] <= (cell_state[18] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[19] <= (cell_state[19] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[20] <= (cell_state[20] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[21] <= (cell_state[21] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[22] <= (cell_state[22] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[23] <= (cell_state[23] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[24] <= (cell_state[24] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[25] <= (cell_state[25] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[26] <= (cell_state[26] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[27] <= (cell_state[27] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[28] <= (cell_state[28] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[29] <= (cell_state[29] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[30] <= (cell_state[30] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[31] <= (cell_state[31] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[32] <= (cell_state[32] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[33] <= (cell_state[33] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[34] <= (cell_state[34] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[35] <= (cell_state[35] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[36] <= (cell_state[36] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[37] <= (cell_state[37] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[38] <= (cell_state[38] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[39] <= (cell_state[39] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[40] <= (cell_state[40] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[41] <= (cell_state[41] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[42] <= (cell_state[42] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[43] <= (cell_state[43] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[44] <= (cell_state[44] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[45] <= (cell_state[45] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[46] <= (cell_state[46] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[47] <= (cell_state[47] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[48] <= (cell_state[48] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[49] <= (cell_state[49] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[50] <= (cell_state[50] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[51] <= (cell_state[51] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[52] <= (cell_state[52] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[53] <= (cell_state[53] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[54] <= (cell_state[54] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[55] <= (cell_state[55] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[56] <= (cell_state[56] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[57] <= (cell_state[57] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[58] <= (cell_state[58] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[59] <= (cell_state[59] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[60] <= (cell_state[60] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[61] <= (cell_state[61] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[62] <= (cell_state[62] >= 4'd2) ? 1'b1 : 1'b0;
            proj_buffer[63] <= (cell_state[63] >= 4'd2) ? 1'b1 : 1'b0;
            compressed_state <= proj_buffer[31:0];
        end
    end

    assign projection_out = proj_buffer;
    assign grid_state     = compressed_state;

endmodule
