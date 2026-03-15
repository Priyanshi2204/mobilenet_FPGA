`timescale 1ns / 1ps

module tb_priyanshi;

parameter DATA_W = 16;
parameter ACC_W  = 48;
parameter IMG_W  = 5;
parameter PAR    = 9;

reg clk;
reg rst_n;

reg [DATA_W-1:0] pixel_in;
reg valid_in;

wire signed [DATA_W-1:0] pixel_out;
wire valid_out;

////////////////////////////////////////////////////////////
// Weight buffer interface
////////////////////////////////////////////////////////////

reg [63:0] wr_data;
reg wr_en;
reg [9:0] wr_addr;
reg [9:0] rd_addr;   // match DUT width

////////////////////////////////////////////////////////////
// Bias
////////////////////////////////////////////////////////////

reg signed [ACC_W-1:0] bias;

////////////////////////////////////////////////////////////
// DUT
////////////////////////////////////////////////////////////

testing_small #(
    .DATA_W(DATA_W),
    .ACC_W(ACC_W),
    .IMG_W(IMG_W),
    .PAR(PAR)
) dut (

    .clk(clk),
    .rst_n(rst_n),

    .pixel_in(pixel_in),
    .valid_in(valid_in),

    .wr_data(wr_data),
    .wr_en(wr_en),
    .wr_addr(wr_addr),
    .rd_addr(rd_addr),

    .bias(bias),

    .pixel_out(pixel_out),
    .valid_out(valid_out)
);

////////////////////////////////////////////////////////////
// Clock
////////////////////////////////////////////////////////////

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

////////////////////////////////////////////////////////////
// Reset
////////////////////////////////////////////////////////////

initial begin
    rst_n   = 0;
    valid_in= 0;
    pixel_in= 0;

    wr_en   = 0;
    wr_addr = 0;
    wr_data = 0;

    rd_addr = 0;
    bias    = 0;

    #20;
    rst_n = 1;
end

////////////////////////////////////////////////////////////
// Image Memory (5x5)
////////////////////////////////////////////////////////////

reg [DATA_W-1:0] image [0:24];
integer i;

initial begin
    image[0]=1;   image[1]=2;   image[2]=3;   image[3]=4;   image[4]=5;
    image[5]=6;   image[6]=7;   image[7]=8;   image[8]=9;   image[9]=10;
    image[10]=11; image[11]=12; image[12]=13; image[13]=14; image[14]=15;
    image[15]=16; image[16]=17; image[17]=18; image[18]=19; image[19]=20;
    image[20]=21; image[21]=22; image[22]=23; image[23]=24; image[24]=25;
end

////////////////////////////////////////////////////////////
// Write Weights (3x3 kernel of ones)
////////////////////////////////////////////////////////////

initial begin

    wait(rst_n);
    @(posedge clk);

    wr_en = 1;

    // weights 0..3
    wr_data = {16'd1,16'd1,16'd1,16'd1};
    wr_addr = 0;
    @(posedge clk);

    // weights 4..7
    wr_data = {16'd1,16'd1,16'd1,16'd1};
    wr_addr = 1;
    @(posedge clk);

    // weight 8
    wr_data = {48'd0,16'd1};
    wr_addr = 2;
    @(posedge clk);

    wr_en = 0;
    #20;
end

////////////////////////////////////////////////////////////
// Read Address (single kernel)
////////////////////////////////////////////////////////////

always @(posedge clk)
    rd_addr <= 0;

////////////////////////////////////////////////////////////
// Stream Image Pixels
////////////////////////////////////////////////////////////

initial begin

    wait(rst_n);
    #100;

    for(i=0;i<25;i=i+1)
    begin
        @(posedge clk);
        pixel_in <= image[i];
        valid_in <= 1;
    end

    @(posedge clk);
    valid_in <= 0;

end

////////////////////////////////////////////////////////////
// Output Monitor
////////////////////////////////////////////////////////////

integer out_count = 0;

always @(posedge clk)
begin
    if(valid_out)
    begin
        $display("Output pixel %0d = %0d at time %0t",
                 out_count, pixel_out, $time);

        out_count = out_count + 1;
    end
end

////////////////////////////////////////////////////////////
// Finish
////////////////////////////////////////////////////////////

initial begin
    #2000;
    $finish;
end

endmodule