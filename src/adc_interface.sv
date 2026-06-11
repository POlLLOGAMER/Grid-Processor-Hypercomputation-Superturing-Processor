// =============================================================================
// ADC Interface - Thermal Noise Sampling & Exponential Moving Average Filter
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module adc_interface (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  analog_input,
    input  wire        sample_enable,
    output reg  [7:0]  digital_out
);

    reg  [7:0]  ema_accumulator;
    reg  [3:0]  sample_counter;
    reg         sampling_active;
    wire [7:0] ema_increment;
    assign ema_increment = analog_input >> 3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ema_accumulator  <= 8'b0;
            sample_counter   <= 4'b0;
            sampling_active  <= 1'b0;
            digital_out      <= 8'b0;
        end else if (sample_enable && !sampling_active) begin
            sampling_active  <= 1'b1;
            sample_counter   <= 4'b0;
            ema_accumulator  <= analog_input;
        end else if (sampling_active) begin
            if (sample_counter < 4'd15) begin
                ema_accumulator <= ema_accumulator + ema_increment - (ema_accumulator >> 3);
                sample_counter  <= sample_counter + 1'b1;
            end else begin
                sampling_active <= 1'b0;
                digital_out     <= ema_accumulator;
            end
        end
    end

endmodule
