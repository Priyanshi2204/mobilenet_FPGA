`timescale 1ns / 1ps

module sliding_window #(
    parameter DATA_WIDTH = 16
)(
    input  wire clk,
    input  wire rst_n,

    input  wire [DATA_WIDTH-1:0] row0,
    input  wire [DATA_WIDTH-1:0] row1,
    input  wire [DATA_WIDTH-1:0] row2,
    input  wire valid_in,
    input  wire new_row,

    output reg [DATA_WIDTH-1:0] w00, w01, w02,
    output reg [DATA_WIDTH-1:0] w10, w11, w12,
    output reg [DATA_WIDTH-1:0] w20, w21, w22,

    output reg valid_out
);

reg [1:0] col_cnt;
reg valid_pipe;

reg [DATA_WIDTH-1:0] s0_0, s0_1, s0_2;
reg [DATA_WIDTH-1:0] s1_0, s1_1, s1_2;
reg [DATA_WIDTH-1:0] s2_0, s2_1, s2_2;

reg new_row_d1, new_row_d2;

////////////////////////////////////////////////////////////
// Delay new_row signal
////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        new_row_d1 <= 0;
        new_row_d2 <= 0;
    end
    else
    begin
        new_row_d1 <= new_row;
        new_row_d2 <= new_row_d1;
    end
end

////////////////////////////////////////////////////////////
// Sliding window logic
////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        col_cnt   <= 0;
        valid_out <= 0;

        s0_0 <= 0; s0_1 <= 0; s0_2 <= 0;
        s1_0 <= 0; s1_1 <= 0; s1_2 <= 0;
        s2_0 <= 0; s2_1 <= 0; s2_2 <= 0;
    end

    // Row boundary
    else if(new_row_d2)
    begin
        col_cnt   <= 0;
        valid_out <= 0;
    end

    // Normal streaming operation
    else if(valid_in)
    begin
        // Shift registers
        s0_0 <= s0_1;
        s0_1 <= s0_2;
        s0_2 <= row0;

        s1_0 <= s1_1;
        s1_1 <= s1_2;
        s1_2 <= row1;

        s2_0 <= s2_1;
        s2_1 <= s2_2;
        s2_2 <= row2;

        // Column counter
        if(col_cnt < 2)
            col_cnt <= col_cnt + 1;

        // Output window
        w00 <= s0_0; w01 <= s0_1; w02 <= s0_2;
        w10 <= s1_0; w11 <= s1_1; w12 <= s1_2;
        w20 <= s2_0; w21 <= s2_1; w22 <= s2_2;

        // Valid signal
        valid_out <= (col_cnt >= 1);
    end

    else
    begin
        valid_out <= 0;
    end
end

endmodule