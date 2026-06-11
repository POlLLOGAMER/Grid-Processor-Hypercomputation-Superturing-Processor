`default_nettype none
`timescale 1ns / 1ps

module grid_cell_array (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire [7:0]  seed_data,
    output wire [63:0] cell_outputs,
    output wire [63:0] cell_stable_flags,
    output wire        global_stable
);

    wire [3:0] cell_state [0:63];

    grid_cell u_cell_0 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[63]), .n(cell_state[56]),
        .ne(cell_state[57]), .w(cell_state[7]),
        .e(cell_state[1]),
        .sw(cell_state[15]), .s(cell_state[8]),
        .se(cell_state[9]),
        .seed_in({4'b0000, seed_data[0]}),
        .state_out(cell_state[0]),
        .is_stable(cell_stable_flags[0])
    );
    assign cell_outputs[3:0] = cell_state[0];

    grid_cell u_cell_1 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[56]), .n(cell_state[57]),
        .ne(cell_state[58]), .w(cell_state[0]),
        .e(cell_state[2]),
        .sw(cell_state[8]), .s(cell_state[9]),
        .se(cell_state[10]),
        .seed_in({4'b0000, seed_data[1]}),
        .state_out(cell_state[1]),
        .is_stable(cell_stable_flags[1])
    );
    assign cell_outputs[7:4] = cell_state[1];

    grid_cell u_cell_2 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[57]), .n(cell_state[58]),
        .ne(cell_state[59]), .w(cell_state[1]),
        .e(cell_state[3]),
        .sw(cell_state[9]), .s(cell_state[10]),
        .se(cell_state[11]),
        .seed_in({4'b0000, seed_data[2]}),
        .state_out(cell_state[2]),
        .is_stable(cell_stable_flags[2])
    );
    assign cell_outputs[11:8] = cell_state[2];

    grid_cell u_cell_3 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[58]), .n(cell_state[59]),
        .ne(cell_state[60]), .w(cell_state[2]),
        .e(cell_state[4]),
        .sw(cell_state[10]), .s(cell_state[11]),
        .se(cell_state[12]),
        .seed_in({4'b0000, seed_data[3]}),
        .state_out(cell_state[3]),
        .is_stable(cell_stable_flags[3])
    );
    assign cell_outputs[15:12] = cell_state[3];

    grid_cell u_cell_4 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[59]), .n(cell_state[60]),
        .ne(cell_state[61]), .w(cell_state[3]),
        .e(cell_state[5]),
        .sw(cell_state[11]), .s(cell_state[12]),
        .se(cell_state[13]),
        .seed_in({4'b0000, seed_data[4]}),
        .state_out(cell_state[4]),
        .is_stable(cell_stable_flags[4])
    );
    assign cell_outputs[19:16] = cell_state[4];

    grid_cell u_cell_5 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[60]), .n(cell_state[61]),
        .ne(cell_state[62]), .w(cell_state[4]),
        .e(cell_state[6]),
        .sw(cell_state[12]), .s(cell_state[13]),
        .se(cell_state[14]),
        .seed_in({4'b0000, seed_data[5]}),
        .state_out(cell_state[5]),
        .is_stable(cell_stable_flags[5])
    );
    assign cell_outputs[23:20] = cell_state[5];

    grid_cell u_cell_6 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[61]), .n(cell_state[62]),
        .ne(cell_state[63]), .w(cell_state[5]),
        .e(cell_state[7]),
        .sw(cell_state[13]), .s(cell_state[14]),
        .se(cell_state[15]),
        .seed_in({4'b0000, seed_data[6]}),
        .state_out(cell_state[6]),
        .is_stable(cell_stable_flags[6])
    );
    assign cell_outputs[27:24] = cell_state[6];

    grid_cell u_cell_7 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[62]), .n(cell_state[63]),
        .ne(cell_state[56]), .w(cell_state[6]),
        .e(cell_state[0]),
        .sw(cell_state[14]), .s(cell_state[15]),
        .se(cell_state[8]),
        .seed_in({4'b0000, seed_data[7]}),
        .state_out(cell_state[7]),
        .is_stable(cell_stable_flags[7])
    );
    assign cell_outputs[31:28] = cell_state[7];

    grid_cell u_cell_8 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[7]), .n(cell_state[0]),
        .ne(cell_state[1]), .w(cell_state[15]),
        .e(cell_state[9]),
        .sw(cell_state[23]), .s(cell_state[16]),
        .se(cell_state[17]),
        .seed_in(4'b0000),
        .state_out(cell_state[8]),
        .is_stable(cell_stable_flags[8])
    );
    assign cell_outputs[35:32] = cell_state[8];

    grid_cell u_cell_9 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[0]), .n(cell_state[1]),
        .ne(cell_state[2]), .w(cell_state[8]),
        .e(cell_state[10]),
        .sw(cell_state[16]), .s(cell_state[17]),
        .se(cell_state[18]),
        .seed_in(4'b0000),
        .state_out(cell_state[9]),
        .is_stable(cell_stable_flags[9])
    );
    assign cell_outputs[39:36] = cell_state[9];

    grid_cell u_cell_10 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[1]), .n(cell_state[2]),
        .ne(cell_state[3]), .w(cell_state[9]),
        .e(cell_state[11]),
        .sw(cell_state[17]), .s(cell_state[18]),
        .se(cell_state[19]),
        .seed_in(4'b0000),
        .state_out(cell_state[10]),
        .is_stable(cell_stable_flags[10])
    );
    assign cell_outputs[43:40] = cell_state[10];

    grid_cell u_cell_11 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[2]), .n(cell_state[3]),
        .ne(cell_state[4]), .w(cell_state[10]),
        .e(cell_state[12]),
        .sw(cell_state[18]), .s(cell_state[19]),
        .se(cell_state[20]),
        .seed_in(4'b0000),
        .state_out(cell_state[11]),
        .is_stable(cell_stable_flags[11])
    );
    assign cell_outputs[47:44] = cell_state[11];

    grid_cell u_cell_12 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[3]), .n(cell_state[4]),
        .ne(cell_state[5]), .w(cell_state[11]),
        .e(cell_state[13]),
        .sw(cell_state[19]), .s(cell_state[20]),
        .se(cell_state[21]),
        .seed_in(4'b0000),
        .state_out(cell_state[12]),
        .is_stable(cell_stable_flags[12])
    );
    assign cell_outputs[51:48] = cell_state[12];

    grid_cell u_cell_13 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[4]), .n(cell_state[5]),
        .ne(cell_state[6]), .w(cell_state[12]),
        .e(cell_state[14]),
        .sw(cell_state[20]), .s(cell_state[21]),
        .se(cell_state[22]),
        .seed_in(4'b0000),
        .state_out(cell_state[13]),
        .is_stable(cell_stable_flags[13])
    );
    assign cell_outputs[55:52] = cell_state[13];

    grid_cell u_cell_14 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[5]), .n(cell_state[6]),
        .ne(cell_state[7]), .w(cell_state[13]),
        .e(cell_state[15]),
        .sw(cell_state[21]), .s(cell_state[22]),
        .se(cell_state[23]),
        .seed_in(4'b0000),
        .state_out(cell_state[14]),
        .is_stable(cell_stable_flags[14])
    );
    assign cell_outputs[59:56] = cell_state[14];

    grid_cell u_cell_15 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[6]), .n(cell_state[7]),
        .ne(cell_state[0]), .w(cell_state[14]),
        .e(cell_state[8]),
        .sw(cell_state[22]), .s(cell_state[23]),
        .se(cell_state[16]),
        .seed_in(4'b0000),
        .state_out(cell_state[15]),
        .is_stable(cell_stable_flags[15])
    );
    assign cell_outputs[63:60] = cell_state[15];

    grid_cell u_cell_16 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[15]), .n(cell_state[8]),
        .ne(cell_state[9]), .w(cell_state[23]),
        .e(cell_state[17]),
        .sw(cell_state[31]), .s(cell_state[24]),
        .se(cell_state[25]),
        .seed_in(4'b0000),
        .state_out(cell_state[16]),
        .is_stable(cell_stable_flags[16])
    );
    assign cell_outputs[67:64] = cell_state[16];

    grid_cell u_cell_17 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[8]), .n(cell_state[9]),
        .ne(cell_state[10]), .w(cell_state[16]),
        .e(cell_state[18]),
        .sw(cell_state[24]), .s(cell_state[25]),
        .se(cell_state[26]),
        .seed_in(4'b0000),
        .state_out(cell_state[17]),
        .is_stable(cell_stable_flags[17])
    );
    assign cell_outputs[71:68] = cell_state[17];

    grid_cell u_cell_18 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[9]), .n(cell_state[10]),
        .ne(cell_state[11]), .w(cell_state[17]),
        .e(cell_state[19]),
        .sw(cell_state[25]), .s(cell_state[26]),
        .se(cell_state[27]),
        .seed_in(4'b0000),
        .state_out(cell_state[18]),
        .is_stable(cell_stable_flags[18])
    );
    assign cell_outputs[75:72] = cell_state[18];

    grid_cell u_cell_19 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[10]), .n(cell_state[11]),
        .ne(cell_state[12]), .w(cell_state[18]),
        .e(cell_state[20]),
        .sw(cell_state[26]), .s(cell_state[27]),
        .se(cell_state[28]),
        .seed_in(4'b0000),
        .state_out(cell_state[19]),
        .is_stable(cell_stable_flags[19])
    );
    assign cell_outputs[79:76] = cell_state[19];

    grid_cell u_cell_20 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[11]), .n(cell_state[12]),
        .ne(cell_state[13]), .w(cell_state[19]),
        .e(cell_state[21]),
        .sw(cell_state[27]), .s(cell_state[28]),
        .se(cell_state[29]),
        .seed_in(4'b0000),
        .state_out(cell_state[20]),
        .is_stable(cell_stable_flags[20])
    );
    assign cell_outputs[83:80] = cell_state[20];

    grid_cell u_cell_21 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[12]), .n(cell_state[13]),
        .ne(cell_state[14]), .w(cell_state[20]),
        .e(cell_state[22]),
        .sw(cell_state[28]), .s(cell_state[29]),
        .se(cell_state[30]),
        .seed_in(4'b0000),
        .state_out(cell_state[21]),
        .is_stable(cell_stable_flags[21])
    );
    assign cell_outputs[87:84] = cell_state[21];

    grid_cell u_cell_22 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[13]), .n(cell_state[14]),
        .ne(cell_state[15]), .w(cell_state[21]),
        .e(cell_state[23]),
        .sw(cell_state[29]), .s(cell_state[30]),
        .se(cell_state[31]),
        .seed_in(4'b0000),
        .state_out(cell_state[22]),
        .is_stable(cell_stable_flags[22])
    );
    assign cell_outputs[91:88] = cell_state[22];

    grid_cell u_cell_23 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[14]), .n(cell_state[15]),
        .ne(cell_state[8]), .w(cell_state[22]),
        .e(cell_state[16]),
        .sw(cell_state[30]), .s(cell_state[31]),
        .se(cell_state[24]),
        .seed_in(4'b0000),
        .state_out(cell_state[23]),
        .is_stable(cell_stable_flags[23])
    );
    assign cell_outputs[95:92] = cell_state[23];

    grid_cell u_cell_24 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[23]), .n(cell_state[16]),
        .ne(cell_state[17]), .w(cell_state[31]),
        .e(cell_state[25]),
        .sw(cell_state[39]), .s(cell_state[32]),
        .se(cell_state[33]),
        .seed_in(4'b0000),
        .state_out(cell_state[24]),
        .is_stable(cell_stable_flags[24])
    );
    assign cell_outputs[99:96] = cell_state[24];

    grid_cell u_cell_25 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[16]), .n(cell_state[17]),
        .ne(cell_state[18]), .w(cell_state[24]),
        .e(cell_state[26]),
        .sw(cell_state[32]), .s(cell_state[33]),
        .se(cell_state[34]),
        .seed_in(4'b0000),
        .state_out(cell_state[25]),
        .is_stable(cell_stable_flags[25])
    );
    assign cell_outputs[103:100] = cell_state[25];

    grid_cell u_cell_26 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[17]), .n(cell_state[18]),
        .ne(cell_state[19]), .w(cell_state[25]),
        .e(cell_state[27]),
        .sw(cell_state[33]), .s(cell_state[34]),
        .se(cell_state[35]),
        .seed_in(4'b0000),
        .state_out(cell_state[26]),
        .is_stable(cell_stable_flags[26])
    );
    assign cell_outputs[107:104] = cell_state[26];

    grid_cell u_cell_27 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[18]), .n(cell_state[19]),
        .ne(cell_state[20]), .w(cell_state[26]),
        .e(cell_state[28]),
        .sw(cell_state[34]), .s(cell_state[35]),
        .se(cell_state[36]),
        .seed_in(4'b0000),
        .state_out(cell_state[27]),
        .is_stable(cell_stable_flags[27])
    );
    assign cell_outputs[111:108] = cell_state[27];

    grid_cell u_cell_28 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[19]), .n(cell_state[20]),
        .ne(cell_state[21]), .w(cell_state[27]),
        .e(cell_state[29]),
        .sw(cell_state[35]), .s(cell_state[36]),
        .se(cell_state[37]),
        .seed_in(4'b0000),
        .state_out(cell_state[28]),
        .is_stable(cell_stable_flags[28])
    );
    assign cell_outputs[115:112] = cell_state[28];

    grid_cell u_cell_29 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[20]), .n(cell_state[21]),
        .ne(cell_state[22]), .w(cell_state[28]),
        .e(cell_state[30]),
        .sw(cell_state[36]), .s(cell_state[37]),
        .se(cell_state[38]),
        .seed_in(4'b0000),
        .state_out(cell_state[29]),
        .is_stable(cell_stable_flags[29])
    );
    assign cell_outputs[119:116] = cell_state[29];

    grid_cell u_cell_30 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[21]), .n(cell_state[22]),
        .ne(cell_state[23]), .w(cell_state[29]),
        .e(cell_state[31]),
        .sw(cell_state[37]), .s(cell_state[38]),
        .se(cell_state[39]),
        .seed_in(4'b0000),
        .state_out(cell_state[30]),
        .is_stable(cell_stable_flags[30])
    );
    assign cell_outputs[123:120] = cell_state[30];

    grid_cell u_cell_31 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[22]), .n(cell_state[23]),
        .ne(cell_state[16]), .w(cell_state[30]),
        .e(cell_state[24]),
        .sw(cell_state[38]), .s(cell_state[39]),
        .se(cell_state[32]),
        .seed_in(4'b0000),
        .state_out(cell_state[31]),
        .is_stable(cell_stable_flags[31])
    );
    assign cell_outputs[127:124] = cell_state[31];

    grid_cell u_cell_32 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[31]), .n(cell_state[24]),
        .ne(cell_state[25]), .w(cell_state[39]),
        .e(cell_state[33]),
        .sw(cell_state[47]), .s(cell_state[40]),
        .se(cell_state[41]),
        .seed_in(4'b0000),
        .state_out(cell_state[32]),
        .is_stable(cell_stable_flags[32])
    );
    assign cell_outputs[131:128] = cell_state[32];

    grid_cell u_cell_33 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[24]), .n(cell_state[25]),
        .ne(cell_state[26]), .w(cell_state[32]),
        .e(cell_state[34]),
        .sw(cell_state[40]), .s(cell_state[41]),
        .se(cell_state[42]),
        .seed_in(4'b0000),
        .state_out(cell_state[33]),
        .is_stable(cell_stable_flags[33])
    );
    assign cell_outputs[135:132] = cell_state[33];

    grid_cell u_cell_34 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[25]), .n(cell_state[26]),
        .ne(cell_state[27]), .w(cell_state[33]),
        .e(cell_state[35]),
        .sw(cell_state[41]), .s(cell_state[42]),
        .se(cell_state[43]),
        .seed_in(4'b0000),
        .state_out(cell_state[34]),
        .is_stable(cell_stable_flags[34])
    );
    assign cell_outputs[139:136] = cell_state[34];

    grid_cell u_cell_35 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[26]), .n(cell_state[27]),
        .ne(cell_state[28]), .w(cell_state[34]),
        .e(cell_state[36]),
        .sw(cell_state[42]), .s(cell_state[43]),
        .se(cell_state[44]),
        .seed_in(4'b0000),
        .state_out(cell_state[35]),
        .is_stable(cell_stable_flags[35])
    );
    assign cell_outputs[143:140] = cell_state[35];

    grid_cell u_cell_36 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[27]), .n(cell_state[28]),
        .ne(cell_state[29]), .w(cell_state[35]),
        .e(cell_state[37]),
        .sw(cell_state[43]), .s(cell_state[44]),
        .se(cell_state[45]),
        .seed_in(4'b0000),
        .state_out(cell_state[36]),
        .is_stable(cell_stable_flags[36])
    );
    assign cell_outputs[147:144] = cell_state[36];

    grid_cell u_cell_37 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[28]), .n(cell_state[29]),
        .ne(cell_state[30]), .w(cell_state[36]),
        .e(cell_state[38]),
        .sw(cell_state[44]), .s(cell_state[45]),
        .se(cell_state[46]),
        .seed_in(4'b0000),
        .state_out(cell_state[37]),
        .is_stable(cell_stable_flags[37])
    );
    assign cell_outputs[151:148] = cell_state[37];

    grid_cell u_cell_38 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[29]), .n(cell_state[30]),
        .ne(cell_state[31]), .w(cell_state[37]),
        .e(cell_state[39]),
        .sw(cell_state[45]), .s(cell_state[46]),
        .se(cell_state[47]),
        .seed_in(4'b0000),
        .state_out(cell_state[38]),
        .is_stable(cell_stable_flags[38])
    );
    assign cell_outputs[155:152] = cell_state[38];

    grid_cell u_cell_39 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[30]), .n(cell_state[31]),
        .ne(cell_state[24]), .w(cell_state[38]),
        .e(cell_state[32]),
        .sw(cell_state[46]), .s(cell_state[47]),
        .se(cell_state[40]),
        .seed_in(4'b0000),
        .state_out(cell_state[39]),
        .is_stable(cell_stable_flags[39])
    );
    assign cell_outputs[159:156] = cell_state[39];

    grid_cell u_cell_40 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[39]), .n(cell_state[32]),
        .ne(cell_state[33]), .w(cell_state[47]),
        .e(cell_state[41]),
        .sw(cell_state[55]), .s(cell_state[48]),
        .se(cell_state[49]),
        .seed_in(4'b0000),
        .state_out(cell_state[40]),
        .is_stable(cell_stable_flags[40])
    );
    assign cell_outputs[163:160] = cell_state[40];

    grid_cell u_cell_41 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[32]), .n(cell_state[33]),
        .ne(cell_state[34]), .w(cell_state[40]),
        .e(cell_state[42]),
        .sw(cell_state[48]), .s(cell_state[49]),
        .se(cell_state[50]),
        .seed_in(4'b0000),
        .state_out(cell_state[41]),
        .is_stable(cell_stable_flags[41])
    );
    assign cell_outputs[167:164] = cell_state[41];

    grid_cell u_cell_42 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[33]), .n(cell_state[34]),
        .ne(cell_state[35]), .w(cell_state[41]),
        .e(cell_state[43]),
        .sw(cell_state[49]), .s(cell_state[50]),
        .se(cell_state[51]),
        .seed_in(4'b0000),
        .state_out(cell_state[42]),
        .is_stable(cell_stable_flags[42])
    );
    assign cell_outputs[171:168] = cell_state[42];

    grid_cell u_cell_43 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[34]), .n(cell_state[35]),
        .ne(cell_state[36]), .w(cell_state[42]),
        .e(cell_state[44]),
        .sw(cell_state[50]), .s(cell_state[51]),
        .se(cell_state[52]),
        .seed_in(4'b0000),
        .state_out(cell_state[43]),
        .is_stable(cell_stable_flags[43])
    );
    assign cell_outputs[175:172] = cell_state[43];

    grid_cell u_cell_44 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[35]), .n(cell_state[36]),
        .ne(cell_state[37]), .w(cell_state[43]),
        .e(cell_state[45]),
        .sw(cell_state[51]), .s(cell_state[52]),
        .se(cell_state[53]),
        .seed_in(4'b0000),
        .state_out(cell_state[44]),
        .is_stable(cell_stable_flags[44])
    );
    assign cell_outputs[179:176] = cell_state[44];

    grid_cell u_cell_45 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[36]), .n(cell_state[37]),
        .ne(cell_state[38]), .w(cell_state[44]),
        .e(cell_state[46]),
        .sw(cell_state[52]), .s(cell_state[53]),
        .se(cell_state[54]),
        .seed_in(4'b0000),
        .state_out(cell_state[45]),
        .is_stable(cell_stable_flags[45])
    );
    assign cell_outputs[183:180] = cell_state[45];

    grid_cell u_cell_46 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[37]), .n(cell_state[38]),
        .ne(cell_state[39]), .w(cell_state[45]),
        .e(cell_state[47]),
        .sw(cell_state[53]), .s(cell_state[54]),
        .se(cell_state[55]),
        .seed_in(4'b0000),
        .state_out(cell_state[46]),
        .is_stable(cell_stable_flags[46])
    );
    assign cell_outputs[187:184] = cell_state[46];

    grid_cell u_cell_47 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[38]), .n(cell_state[39]),
        .ne(cell_state[32]), .w(cell_state[46]),
        .e(cell_state[40]),
        .sw(cell_state[54]), .s(cell_state[55]),
        .se(cell_state[48]),
        .seed_in(4'b0000),
        .state_out(cell_state[47]),
        .is_stable(cell_stable_flags[47])
    );
    assign cell_outputs[191:188] = cell_state[47];

    grid_cell u_cell_48 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[47]), .n(cell_state[40]),
        .ne(cell_state[41]), .w(cell_state[55]),
        .e(cell_state[49]),
        .sw(cell_state[63]), .s(cell_state[56]),
        .se(cell_state[57]),
        .seed_in(4'b0000),
        .state_out(cell_state[48]),
        .is_stable(cell_stable_flags[48])
    );
    assign cell_outputs[195:192] = cell_state[48];

    grid_cell u_cell_49 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[40]), .n(cell_state[41]),
        .ne(cell_state[42]), .w(cell_state[48]),
        .e(cell_state[50]),
        .sw(cell_state[56]), .s(cell_state[57]),
        .se(cell_state[58]),
        .seed_in(4'b0000),
        .state_out(cell_state[49]),
        .is_stable(cell_stable_flags[49])
    );
    assign cell_outputs[199:196] = cell_state[49];

    grid_cell u_cell_50 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[41]), .n(cell_state[42]),
        .ne(cell_state[43]), .w(cell_state[49]),
        .e(cell_state[51]),
        .sw(cell_state[57]), .s(cell_state[58]),
        .se(cell_state[59]),
        .seed_in(4'b0000),
        .state_out(cell_state[50]),
        .is_stable(cell_stable_flags[50])
    );
    assign cell_outputs[203:200] = cell_state[50];

    grid_cell u_cell_51 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[42]), .n(cell_state[43]),
        .ne(cell_state[44]), .w(cell_state[50]),
        .e(cell_state[52]),
        .sw(cell_state[58]), .s(cell_state[59]),
        .se(cell_state[60]),
        .seed_in(4'b0000),
        .state_out(cell_state[51]),
        .is_stable(cell_stable_flags[51])
    );
    assign cell_outputs[207:204] = cell_state[51];

    grid_cell u_cell_52 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[43]), .n(cell_state[44]),
        .ne(cell_state[45]), .w(cell_state[51]),
        .e(cell_state[53]),
        .sw(cell_state[59]), .s(cell_state[60]),
        .se(cell_state[61]),
        .seed_in(4'b0000),
        .state_out(cell_state[52]),
        .is_stable(cell_stable_flags[52])
    );
    assign cell_outputs[211:208] = cell_state[52];

    grid_cell u_cell_53 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[44]), .n(cell_state[45]),
        .ne(cell_state[46]), .w(cell_state[52]),
        .e(cell_state[54]),
        .sw(cell_state[60]), .s(cell_state[61]),
        .se(cell_state[62]),
        .seed_in(4'b0000),
        .state_out(cell_state[53]),
        .is_stable(cell_stable_flags[53])
    );
    assign cell_outputs[215:212] = cell_state[53];

    grid_cell u_cell_54 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[45]), .n(cell_state[46]),
        .ne(cell_state[47]), .w(cell_state[53]),
        .e(cell_state[55]),
        .sw(cell_state[61]), .s(cell_state[62]),
        .se(cell_state[63]),
        .seed_in(4'b0000),
        .state_out(cell_state[54]),
        .is_stable(cell_stable_flags[54])
    );
    assign cell_outputs[219:216] = cell_state[54];

    grid_cell u_cell_55 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[46]), .n(cell_state[47]),
        .ne(cell_state[40]), .w(cell_state[54]),
        .e(cell_state[48]),
        .sw(cell_state[62]), .s(cell_state[63]),
        .se(cell_state[56]),
        .seed_in(4'b0000),
        .state_out(cell_state[55]),
        .is_stable(cell_stable_flags[55])
    );
    assign cell_outputs[223:220] = cell_state[55];

    grid_cell u_cell_56 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[55]), .n(cell_state[48]),
        .ne(cell_state[49]), .w(cell_state[63]),
        .e(cell_state[57]),
        .sw(cell_state[7]), .s(cell_state[0]),
        .se(cell_state[1]),
        .seed_in(4'b0000),
        .state_out(cell_state[56]),
        .is_stable(cell_stable_flags[56])
    );
    assign cell_outputs[227:224] = cell_state[56];

    grid_cell u_cell_57 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[48]), .n(cell_state[49]),
        .ne(cell_state[50]), .w(cell_state[56]),
        .e(cell_state[58]),
        .sw(cell_state[0]), .s(cell_state[1]),
        .se(cell_state[2]),
        .seed_in(4'b0000),
        .state_out(cell_state[57]),
        .is_stable(cell_stable_flags[57])
    );
    assign cell_outputs[231:228] = cell_state[57];

    grid_cell u_cell_58 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[49]), .n(cell_state[50]),
        .ne(cell_state[51]), .w(cell_state[57]),
        .e(cell_state[59]),
        .sw(cell_state[1]), .s(cell_state[2]),
        .se(cell_state[3]),
        .seed_in(4'b0000),
        .state_out(cell_state[58]),
        .is_stable(cell_stable_flags[58])
    );
    assign cell_outputs[235:232] = cell_state[58];

    grid_cell u_cell_59 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[50]), .n(cell_state[51]),
        .ne(cell_state[52]), .w(cell_state[58]),
        .e(cell_state[60]),
        .sw(cell_state[2]), .s(cell_state[3]),
        .se(cell_state[4]),
        .seed_in(4'b0000),
        .state_out(cell_state[59]),
        .is_stable(cell_stable_flags[59])
    );
    assign cell_outputs[239:236] = cell_state[59];

    grid_cell u_cell_60 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[51]), .n(cell_state[52]),
        .ne(cell_state[53]), .w(cell_state[59]),
        .e(cell_state[61]),
        .sw(cell_state[3]), .s(cell_state[4]),
        .se(cell_state[5]),
        .seed_in(4'b0000),
        .state_out(cell_state[60]),
        .is_stable(cell_stable_flags[60])
    );
    assign cell_outputs[243:240] = cell_state[60];

    grid_cell u_cell_61 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[52]), .n(cell_state[53]),
        .ne(cell_state[54]), .w(cell_state[60]),
        .e(cell_state[62]),
        .sw(cell_state[4]), .s(cell_state[5]),
        .se(cell_state[6]),
        .seed_in(4'b0000),
        .state_out(cell_state[61]),
        .is_stable(cell_stable_flags[61])
    );
    assign cell_outputs[247:244] = cell_state[61];

    grid_cell u_cell_62 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[53]), .n(cell_state[54]),
        .ne(cell_state[55]), .w(cell_state[61]),
        .e(cell_state[63]),
        .sw(cell_state[5]), .s(cell_state[6]),
        .se(cell_state[7]),
        .seed_in(4'b0000),
        .state_out(cell_state[62]),
        .is_stable(cell_stable_flags[62])
    );
    assign cell_outputs[251:248] = cell_state[62];

    grid_cell u_cell_63 (
        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),
        .nw(cell_state[54]), .n(cell_state[55]),
        .ne(cell_state[48]), .w(cell_state[62]),
        .e(cell_state[56]),
        .sw(cell_state[6]), .s(cell_state[7]),
        .se(cell_state[0]),
        .seed_in(4'b0000),
        .state_out(cell_state[63]),
        .is_stable(cell_stable_flags[63])
    );
    assign cell_outputs[255:252] = cell_state[63];

    assign global_stable = &cell_stable_flags[63:0];
endmodule
