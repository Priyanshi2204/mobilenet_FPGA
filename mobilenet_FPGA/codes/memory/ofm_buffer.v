module ofm_buffer #(

    parameter DATA_W      = 16,   // Element width (fixed-point)
    parameter AXI_DATA_W  = 128,  // AXI bus width
    parameter ADDR_W      = 10,
    parameter DEPTH       = 1024
)(
    input  wire clk,
    input  wire rst_n,

    // =========================================================
    // Scalar write interface
    // =========================================================
    input  wire [DATA_W-1:0] data_in,
    input  wire              wr_en,
    input  wire [ADDR_W-1:0] wr_addr,

    // Last word handling
    input  wire              last_write,
    input  wire [$clog2(AXI_DATA_W/DATA_W)-1:0] valid_elems,

    // =========================================================
    // AXI read interface
    // =========================================================
    input  wire [ADDR_W-1:0] rd_addr,
    output reg  [AXI_DATA_W-1:0] axi_out_data,
    output reg  [(AXI_DATA_W/8)-1:0] axi_wstrb
);

    // =========================================================
    // Derived parameters
    // =========================================================

    localparam PACK_FACTOR = AXI_DATA_W / DATA_W; // = 8
    localparam PF_BITS     = $clog2(PACK_FACTOR); // = 3

    // =========================================================
    // Memory (BRAM)
    // =========================================================

    (* ram_style = "block" *)
    reg [AXI_DATA_W-1:0] mem [0:DEPTH-1];

    // =========================================================
    // Address decomposition
    // =========================================================

    wire [ADDR_W-1:0] word_addr;
    wire [PF_BITS-1:0] elem_idx;

    assign word_addr = wr_addr >> PF_BITS;        // AXI word index
    assign elem_idx  = wr_addr[PF_BITS-1:0];      // Element slot

// =========================================================
// Write mask (FINAL CORRECT)
// =========================================================

reg [AXI_DATA_W-1:0] write_mask;

always @(*) begin
    write_mask = 0;

    // Always enable only current scalar slot
    write_mask[elem_idx*DATA_W +: DATA_W]
        = {DATA_W{1'b1}};
end
    // =========================================================
    // Packing write logic
    // =========================================================

    wire [AXI_DATA_W-1:0] shifted_data;

    assign shifted_data =
        {{(AXI_DATA_W-DATA_W){1'b0}}, data_in}
        << (elem_idx * DATA_W);

    always @(posedge clk) begin
        if (wr_en) begin
            mem[word_addr] <=
                (mem[word_addr] & ~write_mask) |
                (shifted_data & write_mask);
        end
    end

    // =========================================================
    // AXI write strobe generation
    // =========================================================

    integer b;

    always @(*) begin
        axi_wstrb = 0;

        //------------------------------------------------------
        // Normal → all bytes valid
        //------------------------------------------------------
        if (!last_write) begin
            axi_wstrb = {(AXI_DATA_W/8){1'b1}};
        end

        //------------------------------------------------------
        // Partial last word
        //------------------------------------------------------
        else begin
            for (b = 0; b < valid_elems; b = b + 1) begin
                axi_wstrb[b*(DATA_W/8) +: (DATA_W/8)]
                    = {(DATA_W/8){1'b1}};
            end
        end
    end

    // =========================================================
    // AXI read
    // =========================================================

    always @(posedge clk) begin
        axi_out_data <= mem[rd_addr];
    end

endmodule