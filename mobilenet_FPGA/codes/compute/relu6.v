module relu6 #(
    parameter DATA_W = 16,
    parameter FRAC_W = 8
)(
    input  wire signed [DATA_W-1:0] data_in,
    output wire signed [DATA_W-1:0] data_out
);

    localparam signed [DATA_W-1:0] SIX_QUANTIZED = 6 <<< FRAC_W;

    assign data_out = (data_in < 0)               ? 0 :
                      (data_in > SIX_QUANTIZED)   ? SIX_QUANTIZED :
                                                    data_in;

endmodule
