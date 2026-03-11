`timescale 1ns / 1ps

module adder_tree #(
    parameter PAR   = 9,
    parameter ACC_W = 48
)(
    input  wire clk,
    input  wire rst_n,
    input  wire signed [PAR*ACC_W-1:0] in_vec,
    output reg  signed [ACC_W-1:0] sum_out
);

    //---------------------------------------------------------
    // Input register (prevents X propagation)
    //---------------------------------------------------------
    reg signed [PAR*ACC_W-1:0] in_reg;

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            in_reg <= 0;
        else
            in_reg <= in_vec;
    end

    //---------------------------------------------------------
    // Stage0 unpack
    //---------------------------------------------------------
    wire signed [ACC_W-1:0] s0 [0:PAR-1];

    genvar i;
    generate
        for(i=0;i<PAR;i=i+1)
        begin : UNPACK
            assign s0[i] = in_reg[i*ACC_W +: ACC_W];
        end
    endgenerate

    //---------------------------------------------------------
    // Stage1 (9→5)
    //---------------------------------------------------------
    reg signed [ACC_W-1:0] s1 [0:4];

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            s1[0]<=0; s1[1]<=0; s1[2]<=0; s1[3]<=0; s1[4]<=0;
        end
        else
        begin
            s1[0] <= s0[0] + s0[1];
            s1[1] <= s0[2] + s0[3];
            s1[2] <= s0[4] + s0[5];
            s1[3] <= s0[6] + s0[7];
            s1[4] <= s0[8];
        end
    end

    //---------------------------------------------------------
    // Stage2 (5→3)
    //---------------------------------------------------------
    reg signed [ACC_W-1:0] s2 [0:2];

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            s2[0]<=0; s2[1]<=0; s2[2]<=0;
        end
        else
        begin
            s2[0] <= s1[0] + s1[1];
            s2[1] <= s1[2] + s1[3];
            s2[2] <= s1[4];
        end
    end

    //---------------------------------------------------------
    // Stage3 (3→2)
    //---------------------------------------------------------
    reg signed [ACC_W-1:0] s3 [0:1];

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            s3[0]<=0; s3[1]<=0;
        end
        else
        begin
            s3[0] <= s2[0] + s2[1];
            s3[1] <= s2[2];
        end
    end

    //---------------------------------------------------------
    // Stage4 final
    //---------------------------------------------------------
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            sum_out <= 0;
        else
            sum_out <= s3[0] + s3[1];
    end

endmodule