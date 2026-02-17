`timescale 1ns/1ps

module tb_aadya;

    parameter PAR   = 9;
    parameter ACC_W = 48;

    reg clk;
    reg rst_n;
    reg valid_in;
    reg signed [PAR*ACC_W-1:0] in_vec;

    wire signed [ACC_W-1:0] sum_out;
    wire valid_out;

    // DUT
    adder_tree #(
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

    // Clock: 10ns period
    always #5 clk = ~clk;

    integer i;

    initial begin
        $display("TESTBENCH STARTED");
        // Init
        clk      = 0;
        rst_n    = 0;
        valid_in = 0;
        in_vec   = 0;

        // Reset
        #20;
        rst_n = 1;

        // -------------------------------------------------
        // TEST 1: all ones → expected sum = 9
        // -------------------------------------------------
        @(posedge clk);
        valid_in = 1;
        for (i = 0; i < PAR; i = i + 1)
            in_vec[i*ACC_W +: ACC_W] = 1;

        @(posedge clk);
        valid_in = 0;

        // Wait for pipeline latency (4 cycles)
        repeat (5) @(posedge clk);

        if (valid_out)
            $display("TEST1: sum_out = %0d (expected 9)", sum_out);

        // -------------------------------------------------
        // TEST 2: 1..9 → expected sum = 45
        // -------------------------------------------------
        @(posedge clk);
        valid_in = 1;
        for (i = 0; i < PAR; i = i + 1)
            in_vec[i*ACC_W +: ACC_W] = i + 1;

        @(posedge clk);
        valid_in = 0;

        repeat (5) @(posedge clk);

        if (valid_out)
            $display("TEST2: sum_out = %0d (expected 45)", sum_out);

        // -------------------------------------------------
        // TEST 3: negative values
        // -------------------------------------------------
        @(posedge clk);
        valid_in = 1;
        for (i = 0; i < PAR; i = i + 1)
            in_vec[i*ACC_W +: ACC_W] = -i;

        @(posedge clk);
        valid_in = 0;

        repeat (5) @(posedge clk);

        if (valid_out)
            $display("TEST3: sum_out = %0d", sum_out);

        // Finish
        #20;
        $finish;
    end

    // Monitor
    always @(posedge clk) begin
        if (valid_out) begin
            $display("Time=%0t | Output Valid | Sum=%0d", $time, sum_out);
        end
    end

endmodule
