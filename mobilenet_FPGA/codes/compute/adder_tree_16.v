module adder_tree #(
    parameter PAR   = 16,
    parameter ACC_W = 48
)(
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,

    input  wire signed [PAR*ACC_W-1:0] in_vec,

    output reg  signed [ACC_W-1:0] sum_out,
    output reg                     valid_out
);

    // ---------------------------------------------------------
    // Stage 0: Unpack inputs
    // ---------------------------------------------------------

    wire signed [ACC_W-1:0] stage0 [0:PAR-1];

    genvar i;
    generate
        for (i = 0; i < PAR; i = i + 1) begin : UNPACK
            assign stage0[i] = in_vec[i*ACC_W +: ACC_W];
        end
    endgenerate

    // ---------------------------------------------------------
    // Stage 1: PAR → PAR/2
    // ---------------------------------------------------------

    localparam STAGE1 = PAR / 2;
    reg signed [ACC_W-1:0] stage1 [0:STAGE1-1];
    reg valid_s1;

    integer j;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s1 <= 0;
        end else begin
            for (j = 0; j < STAGE1; j = j + 1)
                stage1[j] <= stage0[2*j] + stage0[2*j+1];

            valid_s1 <= valid_in;
        end
    end

    // ---------------------------------------------------------
    // Stage 2
    // ---------------------------------------------------------

    localparam STAGE2 = STAGE1 / 2;
    reg signed [ACC_W-1:0] stage2 [0:STAGE2-1];
    reg valid_s2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s2 <= 0;
        end else begin
            for (j = 0; j < STAGE2; j = j + 1)
                stage2[j] <= stage1[2*j] + stage1[2*j+1];

            valid_s2 <= valid_s1;
        end
    end

    // ---------------------------------------------------------
    // Stage 3
    // ---------------------------------------------------------

    localparam STAGE3 = STAGE2 / 2;
    reg signed [ACC_W-1:0] stage3 [0:STAGE3-1];
    reg valid_s3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s3 <= 0;
        end else begin
            for (j = 0; j < STAGE3; j = j + 1)
                stage3[j] <= stage2[2*j] + stage2[2*j+1];

            valid_s3 <= valid_s2;
        end
    end

    // ---------------------------------------------------------
    // Stage 4 (Final)
    // ---------------------------------------------------------

    reg valid_s4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_out  <= 0;
            valid_s4 <= 0;
        end else begin
            sum_out  <= stage3[0] + stage3[1];
            valid_s4 <= valid_s3;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_out <= 0;
        else
            valid_out <= valid_s4;
    end

endmodule
