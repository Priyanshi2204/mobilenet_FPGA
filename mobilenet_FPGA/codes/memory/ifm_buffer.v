module ifm_buffer #(
    parameter DATA_W = 128,
    parameter ADDR_W = 10,
    parameter DEPTH  = 1024
)(
    input  wire clk,
    input  wire rst_n,

    // Write port
    input  wire [DATA_W-1:0] wr_data,
    input  wire              wr_en,
    input  wire [ADDR_W-1:0] wr_addr,

    // Read port
    input  wire [ADDR_W-1:0] rd_addr,
    output reg  [DATA_W-1:0] rd_data
);

    // =====================================================
    // BRAM
    // =====================================================

    (* ram_style = "block" *)
    reg [DATA_W-1:0] mem [0:DEPTH-1];

    integer i;

    // Write
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= 0;
        end
        else if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    // Read
    always @(posedge clk) begin
        rd_data <= mem[rd_addr];
    end

endmodule