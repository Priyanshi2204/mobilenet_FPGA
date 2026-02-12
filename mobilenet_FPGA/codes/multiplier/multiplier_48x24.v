//////////////////////////////////////////////////////////////////////////////////
module multiplier_48x24 (
    input  wire signed [47:0] inp1, // 32-bit signed multiplicand
    input  wire signed [23:0] inp2, // 16-bit signed multiplier
    output wire signed [41:0] out1  // 48-bit signed product
);

    assign out1 = inp1 * inp2;

endmodule
