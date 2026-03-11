`timescale 1ns / 1ps

module tb_priyanshi;

parameter DATA_W = 16;
parameter ACC_W  = 48;

reg clk;
reg rst_n;
reg valid_in;

reg signed [DATA_W-1:0] data_in;
reg signed [DATA_W-1:0] weight_in;

wire signed [ACC_W-1:0] mac_out;
wire valid_out;

// DUT
mac_unit #(
    .DATA_W(DATA_W),
    .ACC_W(ACC_W)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_in),
    .data_in(data_in),
    .weight_in(weight_in),
    .mac_out(mac_out),
    .valid_out(valid_out)
);

integer expected;

//--------------------------------------------------
//Clock generation
//--------------------------------------------------

initial begin
    clk = 0;
    forever #5 clk = ~clk;   // 10ns clock
end

//--------------------------------------------------
//Reset
//--------------------------------------------------

initial begin
    rst_n = 0;
    valid_in = 0;
    data_in = 0;
    weight_in = 0;

    #20;
    rst_n = 1;
end

//--------------------------------------------------
//Stimulus
//--------------------------------------------------

initial begin

    wait(rst_n);

    // Test case
    data_in   = 6;
    weight_in = 7;

    expected = data_in * weight_in;

    @(posedge clk);
    valid_in = 1;

    @(posedge clk);
    valid_in = 0;

end

//--------------------------------------------------
//Monitor Output
//--------------------------------------------------

always @(posedge clk)
begin
    if(valid_out)
    begin
        $display("Time = %0t", $time);
        $display("Expected = %0d", expected);
        $display("MAC Output = %0d", mac_out);

        if(mac_out == expected)
            $display("TEST PASSED\n");
        else
            $display("TEST FAILED\n");
    end
end

//--------------------------------------------------
//Finish simulation
//--------------------------------------------------

initial begin
    #200;
    $finish;
end

endmodule