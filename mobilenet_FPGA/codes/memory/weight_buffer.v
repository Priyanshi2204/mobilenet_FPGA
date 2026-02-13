module weight_buffer #(
    parameter WR_DATA_W = 64,
    parameter RD_DATA_W = 128,
    parameter ADDR_W    = 10,
    parameter DEPTH     = 1024
)(
    input  wire clk,
    input  wire rst_n,

    input  wire [WR_DATA_W-1:0] wr_data,
    input  wire                 wr_en,
    input  wire [ADDR_W-1:0]    wr_addr,

    input  wire [ADDR_W-2:0]    rd_addr,
    output reg  [RD_DATA_W-1:0] weight_vec
);

    // -----------------------------
    // Memory
    // -----------------------------
    (* ram_style = "block" *)
    reg [RD_DATA_W-1:0] mem [0:DEPTH-1];

    // Simulation init (optional)
    integer i;
    initial
        for (i=0;i<DEPTH;i=i+1)
            mem[i] = 0;

    // -----------------------------
    // Address split
    // -----------------------------
    wire [ADDR_W-2:0] word_addr = wr_addr[ADDR_W-1:1];
    wire              half_sel  = wr_addr[0];

    // -----------------------------
    // Write packing
    // -----------------------------
    always @(posedge clk) begin
        if (wr_en) begin
            if (!half_sel)
                mem[word_addr][63:0]   <= wr_data;
            else
                mem[word_addr][127:64] <= wr_data;
        end
    end

    // -----------------------------
    // Read
    // -----------------------------
    always @(posedge clk) begin
        weight_vec <= mem[rd_addr];
    end

endmodule
