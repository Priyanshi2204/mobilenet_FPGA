`timescale 1ns / 1ps

module tb_priyanshi;

parameter PAR   = 9;
parameter ACC_W = 48;

reg clk;
reg rst_n;
reg valid_in;

reg  signed [PAR*ACC_W-1:0] in_vec;

wire signed [ACC_W-1:0] sum_out;
wire valid_out;

integer i;

//--------------------------------------------------
// DUT
//--------------------------------------------------
adder_tree_16 #(
    .PAR(PAR),
    .ACC_W(ACC_W)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_in),
    .in_vec(in_vec),
    .sum_out(sum_out),
    .valid_out(valid_out)
);

//--------------------------------------------------
// Clock generation
//--------------------------------------------------
initial begin
    clk = 0;
    forever #5 clk = ~clk;   // 10ns clock
end

//--------------------------------------------------
// Reset
//--------------------------------------------------
initial begin
    rst_n = 0;
    valid_in = 0;
    in_vec = 0;

    #20;
    rst_n = 1;
end

//--------------------------------------------------
// Test stimulus
//--------------------------------------------------
reg signed [ACC_W-1:0] inputs [0:PAR-1];
reg signed [ACC_W-1:0] expected_sum;

initial begin

    wait(rst_n);

    //--------------------------------------------------
    // Test 1
    //--------------------------------------------------

    expected_sum = 0;

    for(i=0;i<PAR;i=i+1) begin
        inputs[i] = i + 1;
        expected_sum = expected_sum + inputs[i];

        in_vec[i*ACC_W +: ACC_W] = inputs[i];
    end

    @(posedge clk);
    valid_in = 1;

    @(posedge clk);
    valid_in = 0;

end

//--------------------------------------------------
// Monitor
//--------------------------------------------------
always @(posedge clk)
begin
    if(valid_out)
    begin
        $display("Time = %0t", $time);
        $display("Expected Sum = %0d", expected_sum);
        $display("Adder Tree Output = %0d", sum_out);

        if(sum_out == expected_sum)
            $display("TEST PASSED\n");
        else
            $display("TEST FAILED\n");
    end
end

//--------------------------------------------------
initial begin
    #200;
    $finish;
end

endmodule
