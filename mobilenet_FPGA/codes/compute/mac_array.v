module mac_array #(
    parameter PAR     = 9,
    parameter DATA_W  = 16,
    parameter ACC_W   = 48
)(
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,

    input  wire signed [PAR*DATA_W-1:0] data_vec,
    input  wire signed [PAR*DATA_W-1:0] weight_vec,
//    input  wire signed [ACC_W-1:0]      psum_in,

    output wire signed [PAR*ACC_W-1:0]  mac_out,
    output wire                         valid_out
);

    genvar i;

    wire [PAR-1:0] valid_lane;

    generate
        for (i = 0; i < PAR; i = i + 1) begin : MAC_LANES

            mac_unit #(
                .DATA_W(DATA_W),
                .ACC_W (ACC_W)
            ) mac_inst (
                .clk       (clk),
                .rst_n     (rst_n),
                .valid_in  (valid_in),

                .data_in   (data_vec [i*DATA_W +: DATA_W]),
                .weight_in (weight_vec[i*DATA_W +: DATA_W]),
//                .psum_in   (psum_in),

                .mac_out  (mac_out[i*ACC_W +: ACC_W]),
                .valid_out (valid_lane[i])
            );

        end
    endgenerate

    // propagate valid signal
    assign valid_out = valid_lane[PAR-1];

endmodule