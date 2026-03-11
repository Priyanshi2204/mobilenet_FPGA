`timescale 1ns / 1ps

module tb_priyanshi;

parameter PAR    = 9;
parameter DATA_W = 16;
parameter ACC_W  = 48;

reg clk;
reg rst_n;
reg valid_in;

reg signed [PAR*DATA_W-1:0] data_vec;
reg signed [PAR*DATA_W-1:0] weight_vec;
reg signed [ACC_W-1:0] psum_in;

wire signed [PAR*ACC_W-1:0] mac_out;
wire valid_out;

integer i;

// DUT
mac_array #(
    .PAR(PAR),
    .DATA_W(DATA_W),
    .ACC_W(ACC_W)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_in),
    .data_vec(data_vec),
    .weight_vec(weight_vec),
    .psum_in(psum_in),
    .mac_out(mac_out),
    .valid_out(valid_out)
);

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
    data_vec = 0;
    weight_vec = 0;
    psum_in = 0;

    #20;
    rst_n = 1;
end

//--------------------------------------------------
//Stimulus
//--------------------------------------------------

reg signed [DATA_W-1:0] data   [0:PAR-1];
reg signed [DATA_W-1:0] weight [0:PAR-1];
reg signed [ACC_W-1:0] expected [0:PAR-1];

initial begin

    wait(rst_n);

    psum_in = 10;

    // Generate simple test values
    for(i=0;i<PAR;i=i+1)
    begin
        data[i]   = i + 1;
        weight[i] = i + 2;

        data_vec[i*DATA_W +: DATA_W]   = data[i];
        weight_vec[i*DATA_W +: DATA_W] = weight[i];

        expected[i] = data[i]*weight[i] + psum_in;
    end

    @(posedge clk);
    valid_in = 1;

    @(posedge clk);
    valid_in = 0;

end

//--------------------------------------------------
//Output Check
//--------------------------------------------------

always @(posedge clk)
begin
    if(valid_out)
    begin
        $display("\nMAC ARRAY OUTPUT:");

        for(i=0;i<PAR;i=i+1)
        begin
            $display("Lane %0d -> Expected = %0d | Got = %0d",
                     i,
                     expected[i],
                     mac_out[i*ACC_W +: ACC_W]);

            if(mac_out[i*ACC_W +: ACC_W] == expected[i])
                $display("PASS");
            else
                $display("FAIL");
        end
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