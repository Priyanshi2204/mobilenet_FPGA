`timescale 1ns / 1ps

module sliding_window #(
    parameter DATA_WIDTH = 16
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Vertical taps
    input  wire [DATA_WIDTH-1:0]    row0,
    input  wire [DATA_WIDTH-1:0]    row1,
    input  wire [DATA_WIDTH-1:0]    row2,
    input  wire                     valid_in,

    // 3x3 window
    output reg  [DATA_WIDTH-1:0]    w00, w01, w02,
    output reg  [DATA_WIDTH-1:0]    w10, w11, w12,
    output reg  [DATA_WIDTH-1:0]    w20, w21, w22,

    output reg                      valid_out
);

    // ============================================================
    // Column counter (for valid)
    // ============================================================

    reg [1:0] col_cnt;

    // ============================================================
    // Shift registers (3 columns)
    // ============================================================

    reg [DATA_WIDTH-1:0] s0_0, s0_1, s0_2;
    reg [DATA_WIDTH-1:0] s1_0, s1_1, s1_2;
    reg [DATA_WIDTH-1:0] s2_0, s2_1, s2_2;

    // ============================================================
    // Main logic
    // ============================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_cnt   <= 0;
            valid_out <= 0;

            s0_0 <= 0; s0_1 <= 0; s0_2 <= 0;
            s1_0 <= 0; s1_1 <= 0; s1_2 <= 0;
            s2_0 <= 0; s2_1 <= 0; s2_2 <= 0;
        end
        else if (valid_in) begin

            //--------------------------------------------------
            // Shift left
            //--------------------------------------------------
            s0_0 <= s0_1;
            s0_1 <= s0_2;
            s0_2 <= row0;

            s1_0 <= s1_1;
            s1_1 <= s1_2;
            s1_2 <= row1;

            s2_0 <= s2_1;
            s2_1 <= s2_2;
            s2_2 <= row2;

            //--------------------------------------------------
            // Column count
            //--------------------------------------------------
            if (col_cnt < 2)
                col_cnt <= col_cnt + 1;

            //--------------------------------------------------
            // Output window
            //--------------------------------------------------
            w00 <= s0_0; w01 <= s0_1; w02 <= s0_2;
            w10 <= s1_0; w11 <= s1_1; w12 <= s1_2;
            w20 <= s2_0; w21 <= s2_1; w22 <= s2_2;

            //--------------------------------------------------
            // Valid generation (2 cols ready)
            //--------------------------------------------------
            if (col_cnt >= 2)
                valid_out <= 1;
            else
                valid_out <= 0;
        end
        else begin
            valid_out <= 0;
        end
    end

endmodule
