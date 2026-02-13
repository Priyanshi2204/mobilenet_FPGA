module pingpong_buffer #(
    parameter DATA_W = 128,
    parameter ADDR_W = 10,
    parameter DEPTH  = 1024
)(
    input  wire clk,
    input  wire rst_n,

    // ============================================
    // Write side (DMA / Loader)
    // ============================================
    input  wire [DATA_W-1:0] wr_data,
    input  wire              wr_en,
    input  wire [ADDR_W-1:0] wr_addr,

    // ============================================
    // Read side (Compute / Stream)
    // ============================================
    input  wire [ADDR_W-1:0] rd_addr,
    input  wire              rd_en,
    output reg  [DATA_W-1:0] rd_data,

    // ============================================
    // Control
    // ============================================
    input  wire switch_banks   // toggle ping ↔ pong
);

    // =========================================================
    // Bank select registers
    // =========================================================

    reg wr_bank_sel;
    reg rd_bank_sel;

    // Write bank toggles on switch
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_bank_sel <= 1'b0;
        else if (switch_banks)
            wr_bank_sel <= ~wr_bank_sel;
    end

    // Read bank is always opposite
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_bank_sel <= 1'b1;
        else if (switch_banks)
            rd_bank_sel <= ~rd_bank_sel;
    end

    // =========================================================
    // Dual BRAM banks
    // =========================================================

    (* ram_style = "block" *)
    reg [DATA_W-1:0] bank_ping [0:DEPTH-1];

    (* ram_style = "block" *)
    reg [DATA_W-1:0] bank_pong [0:DEPTH-1];

    // =========================================================
    // Write logic
    // =========================================================

    always @(posedge clk) begin
        if (wr_en) begin
            if (wr_bank_sel == 1'b0)
                bank_ping[wr_addr] <= wr_data;
            else
                bank_pong[wr_addr] <= wr_data;
        end
    end

    // =========================================================
    // Read logic
    // =========================================================

    always @(posedge clk) begin
        if (rd_en) begin
            if (rd_bank_sel == 1'b0)
                rd_data <= bank_ping[rd_addr];
            else
                rd_data <= bank_pong[rd_addr];
        end
    end

endmodule

