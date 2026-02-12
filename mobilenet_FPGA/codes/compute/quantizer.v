module quantizer #(
    parameter ACC_W   = 48,
    parameter SCALE_W = 24,
    parameter DATA_W  = 16,
    parameter FRAC_W  = 8      // Q7.8 output format
)(
    input  wire clk,
    input  wire rst_n,

    input  wire signed [ACC_W-1:0]   data_in,     // 48-bit accumulator
    input  wire signed [SCALE_W-1:0] scale,       // 24-bit scale factor
    input  wire signed [DATA_W-1:0]  zero_point,  // Usually 0 in symmetric quant

    output reg  signed [DATA_W-1:0]  data_out
);

    // ---------------------------------------------------------
    // Stage 1: Multiply accumulator by scale
    // ---------------------------------------------------------

    wire signed [ACC_W+SCALE_W-1:0] mult_wire;
    reg  signed [ACC_W+SCALE_W-1:0] mult_reg;

    multiplier_48x24 inst1 (
        .inp1(data_in),
        .inp2(scale),
        .out1(mult_wire)
    );

    // ---------------------------------------------------------
    // Stage 2: Shift back to Q7.8 domain
    // ---------------------------------------------------------

    reg signed [ACC_W-1:0] shifted_reg;

    // We assume scale is in Q(0.SCALE_W) format.
    // So we right-shift by SCALE_W - FRAC_W
    localparam SHIFT_AMT = SCALE_W - FRAC_W;

    // ---------------------------------------------------------
    // Stage 3: Saturation to DATA_W
    // ---------------------------------------------------------

    reg signed [ACC_W-1:0] biased_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_reg    <= 0;
            shifted_reg <= 0;
            biased_reg  <= 0;
            data_out    <= 0;
        end else begin

            // Stage 1
            mult_reg <= mult_wire;

            // Stage 2
            shifted_reg <= mult_reg >>> SHIFT_AMT;

            // Add zero point (if asymmetric quantization)
            biased_reg <= shifted_reg + zero_point;

            // Stage 3: Saturation
            if (biased_reg > $signed({1'b0, {(DATA_W-1){1'b1}}})) begin
                data_out <= {1'b0, {(DATA_W-1){1'b1}}};   // Max positive
            end
            else if (biased_reg < $signed({1'b1, {(DATA_W-1){1'b0}}})) begin
                data_out <= {1'b1, {(DATA_W-1){1'b0}}};   // Max negative
            end
            else begin
                data_out <= biased_reg[DATA_W-1:0];
            end

        end
    end

endmodule
