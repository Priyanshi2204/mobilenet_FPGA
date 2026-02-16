`timescale 1ns / 1ps

module line_buffer #(
    parameter DATA_WIDTH = 16,
    parameter IMG_WIDTH  = 64
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire [DATA_WIDTH-1:0]    pixel_in,
    input  wire                     valid_in,

    // Vertical taps
    output reg  [DATA_WIDTH-1:0]    row0,  // 2 rows above
    output reg  [DATA_WIDTH-1:0]    row1,  // 1 row above
    output reg  [DATA_WIDTH-1:0]    row2,  // current row

    output reg                      valid_out
);

    // ============================================================
    // Line buffers (BRAM)
    // ============================================================

    (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0] linebuf1 [0:IMG_WIDTH-1];

    (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0] linebuf2 [0:IMG_WIDTH-1];

    // ============================================================
    // Counters
    // ============================================================

    reg [$clog2(IMG_WIDTH)-1:0] col;
    reg [1:0] row_cnt;

    // ============================================================
    // Main logic
    // ============================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col       <= 0;
            row_cnt   <= 0;
            valid_out <= 0;

            row0 <= 0;
            row1 <= 0;
            row2 <= 0;
        end
        else if (valid_in) begin

            //--------------------------------------------------
            // Read vertical taps
            //--------------------------------------------------
            row0 <= linebuf2[col];
            row1 <= linebuf1[col];
            row2 <= pixel_in;

            //--------------------------------------------------
            // Update line buffers
            //--------------------------------------------------
            linebuf2[col] <= linebuf1[col];
            linebuf1[col] <= pixel_in;

            //--------------------------------------------------
            // Update column pointer
            //--------------------------------------------------
            if (col == IMG_WIDTH-1) begin
                col <= 0;

                if (row_cnt < 2)
                    row_cnt <= row_cnt + 1;
            end
            else begin
                col <= col + 1;
            end

            //--------------------------------------------------
            // Valid generation (2 rows ready)
            //--------------------------------------------------
            if (row_cnt >= 2)
                valid_out <= 1;
            else
                valid_out <= 0;
        end
    end

endmodule
