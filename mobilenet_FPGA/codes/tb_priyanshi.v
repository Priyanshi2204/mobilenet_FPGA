`timescale 1ns / 1ps

module tb_priyanshi;

// ============================================================
// Parameters
// ============================================================
parameter DATA_WIDTH = 16;
parameter IMG_WIDTH  = 5;

// ============================================================
// Clock / Reset
// ============================================================
reg clk;
reg rst_n;

always #5 clk = ~clk;

// ============================================================
// Pixel stream
// ============================================================
reg [DATA_WIDTH-1:0] pixel_in;
reg                  valid_in;

// ============================================================
// Line buffer outputs
// ============================================================
wire [DATA_WIDTH-1:0] row0, row1, row2;
wire                  valid_lb;
wire                  new_row;

// ============================================================
// Sliding window outputs
// ============================================================
wire [DATA_WIDTH-1:0] w00, w01, w02;
wire [DATA_WIDTH-1:0] w10, w11, w12;
wire [DATA_WIDTH-1:0] w20, w21, w22;
wire                  valid_win;

// ============================================================
// Instantiate Line Buffer
// ============================================================
line_buffer #(
    .DATA_WIDTH(DATA_WIDTH),
    .IMG_WIDTH(IMG_WIDTH)
) u_line_buffer (
    .clk(clk),
    .rst_n(rst_n),
    .pixel_in(pixel_in),
    .valid_in(valid_in),
    .row0(row0),
    .row1(row1),
    .row2(row2),
    .valid_out(valid_lb),
    .new_row(new_row)
);

// ============================================================
// Instantiate Sliding Window
// ============================================================
sliding_window #(
    .DATA_WIDTH(DATA_WIDTH)
) u_sliding_window (
    .clk(clk),
    .rst_n(rst_n),
    .row0(row0),
    .row1(row1),
    .row2(row2),
    .valid_in(valid_lb),
    .new_row(new_row),
    .w00(w00), .w01(w01), .w02(w02),
    .w10(w10), .w11(w11), .w12(w12),
    .w20(w20), .w21(w21), .w22(w22),
    .valid_out(valid_win)
);

// ============================================================
// Stimulus
// ============================================================
integer i;

initial begin
    clk = 0;
    rst_n = 0;
    valid_in = 0;
    pixel_in = 0;

    // Reset
    #20;
    rst_n = 1;

    //----------------------------------------------------------
    // Stream 5x5 image pixels (1 → 25)
    //----------------------------------------------------------
    for (i = 1; i <= 25; i = i + 1) begin
        @(posedge clk);
        pixel_in <= i;
        valid_in <= 1;
    end

    @(posedge clk);
    valid_in <= 0;

    #500;
    $finish;
end

// ============================================================
// Window monitor
// ============================================================
always @(posedge clk) begin
    if (valid_win) begin
        $display("Time %0t", $time);
        $display("[%0d %0d %0d]", w00, w01, w02);
        $display("[%0d %0d %0d]", w10, w11, w12);
        $display("[%0d %0d %0d]", w20, w21, w22);
        $display("-------------------------");
    end
end

endmodule
