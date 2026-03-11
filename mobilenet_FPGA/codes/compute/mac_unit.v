module mac_unit #(
    parameter DATA_W = 16,
    parameter ACC_W  = 48
)(
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,

    input  wire signed [DATA_W-1:0] data_in,
    input  wire signed [DATA_W-1:0] weight_in,

    output reg  signed [ACC_W-1:0]  mac_out,
    output reg                      valid_out
);

    //--------------------------------------------------
    // Stage 1: Register inputs
    //--------------------------------------------------

    reg signed [DATA_W-1:0] data_reg;
    reg signed [DATA_W-1:0] weight_reg;
    reg                     valid_reg1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg   <= 0;
            weight_reg <= 0;
            valid_reg1 <= 0;
        end else begin
            data_reg   <= data_in;
            weight_reg <= weight_in;
            valid_reg1 <= valid_in;
        end
    end

    //--------------------------------------------------
    // Stage 2: Multiply
    //--------------------------------------------------

    wire signed [2*DATA_W-1:0] mult_wire;
    assign mult_wire = data_reg * weight_reg;

    reg signed [2*DATA_W-1:0] mult_reg;
    reg                       valid_reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_reg   <= 0;
            valid_reg2 <= 0;
        end else begin
            mult_reg   <= mult_wire;
            valid_reg2 <= valid_reg1;
        end
    end

    //--------------------------------------------------
    // Stage 3: Extend to ACC_W
    //--------------------------------------------------

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mac_out   <= 0;
            valid_out <= 0;
        end else begin
            mac_out   <= {{(ACC_W-2*DATA_W){mult_reg[2*DATA_W-1]}}, mult_reg};
            valid_out <= valid_reg2;
        end
    end

endmodule