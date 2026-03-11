`timescale 1ns / 1ps
//named as 16 but is made for 9 adders
module adder_tree_16 #(
    parameter PAR   = 9,
    parameter ACC_W = 48
)(
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,

    input  wire signed [PAR*ACC_W-1:0] in_vec,

    output reg  signed [ACC_W-1:0] sum_out,
    output reg                     valid_out
);

    //---------------------------------------------------------
    // Input register
    //---------------------------------------------------------
    reg signed [PAR*ACC_W-1:0] in_reg;
    reg valid_s0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_reg   <= 0;
            valid_s0 <= 0;
        end
        else begin
            in_reg   <= in_vec;
            valid_s0 <= valid_in;
        end
    end

    //---------------------------------------------------------
    // Stage 0 unpack
    //---------------------------------------------------------
    wire signed [ACC_W-1:0] s0 [0:PAR-1];

    genvar i;
    generate
        for (i = 0; i < PAR; i = i + 1) begin : UNPACK
            assign s0[i] = in_reg[i*ACC_W +: ACC_W];
        end
    endgenerate

    //---------------------------------------------------------
    // Stage1 (9 → 5)
    //---------------------------------------------------------
    reg signed [ACC_W-1:0] s1 [0:4];
    reg valid_s1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1[0]<=0; s1[1]<=0; s1[2]<=0; s1[3]<=0; s1[4]<=0;
            valid_s1 <= 0;
        end
        else begin
            s1[0] <= s0[0] + s0[1];
            s1[1] <= s0[2] + s0[3];
            s1[2] <= s0[4] + s0[5];
            s1[3] <= s0[6] + s0[7];
            s1[4] <= s0[8];

            valid_s1 <= valid_s0;
        end
    end

    //---------------------------------------------------------
    // Stage2 (5 → 3)
    //---------------------------------------------------------
    reg signed [ACC_W-1:0] s2 [0:2];
    reg valid_s2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2[0]<=0; s2[1]<=0; s2[2]<=0;
            valid_s2 <= 0;
        end
        else begin
            s2[0] <= s1[0] + s1[1];
            s2[1] <= s1[2] + s1[3];
            s2[2] <= s1[4];

            valid_s2 <= valid_s1;
        end
    end

    //---------------------------------------------------------
    // Stage3 (3 → 2)
    //---------------------------------------------------------
    reg signed [ACC_W-1:0] s3 [0:1];
    reg valid_s3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s3[0]<=0; s3[1]<=0;
            valid_s3 <= 0;
        end
        else begin
            s3[0] <= s2[0] + s2[1];
            s3[1] <= s2[2];

            valid_s3 <= valid_s2;
        end
    end

    //---------------------------------------------------------
    // Final stage (2 → 1)
    //---------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_out   <= 0;
            valid_out <= 0;
        end
        else begin
            sum_out   <= s3[0] + s3[1];
            valid_out <= valid_s3;
        end
    end

endmodule