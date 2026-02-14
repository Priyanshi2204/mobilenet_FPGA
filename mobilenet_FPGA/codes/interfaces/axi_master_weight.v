`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// AXI MASTER WEIGHT READER - DDR → WEIGHT BUFFER (FOLDING MODE)
//////////////////////////////////////////////////////////////////////////////////

module axi_master_weight #(

    parameter AXI_ADDR_W = 32,
    parameter AXI_DATA_W = 128,
    parameter WR_DATA_W  = 64,
    parameter BUF_ADDR_W = 10,
    parameter BURST_LEN  = 128

)(
    input  wire clk,
    input  wire rst_n,

    //--------------------------------------------------
    // Control
    //--------------------------------------------------
    input  wire start_read,
    input  wire [AXI_ADDR_W-1:0] base_addr,
    output reg  done,

    //--------------------------------------------------
    // AXI READ ADDRESS CHANNEL
    //--------------------------------------------------
    output reg  [AXI_ADDR_W-1:0] araddr,
    output reg                   arvalid,
    input  wire                  arready,

    output reg  [7:0]            arlen,
    output reg  [2:0]            arsize,
    output reg  [1:0]            arburst,

    //--------------------------------------------------
    // AXI READ DATA CHANNEL
    //--------------------------------------------------
    input  wire [AXI_DATA_W-1:0] rdata,
    input  wire                  rvalid,
    input  wire                  rlast,
    output reg                   rready,

    //--------------------------------------------------
    // Weight buffer write port
    //--------------------------------------------------
    output reg  [WR_DATA_W-1:0]  wr_data,
    output reg                   wr_en,
    output reg  [BUF_ADDR_W-1:0] wr_addr
);

    // =========================================================
    // FSM
    // =========================================================

    localparam IDLE = 0,
               ADDR = 1,
               READ = 2,
               DONE = 3;

    reg [1:0] state, next_state;

    // =========================================================
    // Counters
    // =========================================================

    reg [$clog2(BURST_LEN):0] beat_cnt;
    reg                       half_sel;

    // =========================================================
    // FSM SEQ
    // =========================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // =========================================================
    // FSM COMB
    // =========================================================

    always @(*) begin
        next_state = state;

        case (state)

            IDLE:
                if (start_read)
                    next_state = ADDR;

            ADDR:
                if (arready)
                    next_state = READ;

            //--------------------------------------------------
            // Exit only AFTER upper half of last beat
            //--------------------------------------------------
            READ:
                if (rlast && rvalid && half_sel)
                    next_state = DONE;

            DONE:
                next_state = IDLE;

        endcase
    end

    // =========================================================
    // ADDRESS CHANNEL
    // =========================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            araddr  <= 0;
            arvalid <= 0;
            arlen   <= 0;
            arsize  <= 0;
            arburst <= 0;
        end
        else begin
            case (state)

                IDLE: begin
                    araddr  <= base_addr;
                    arvalid <= 0;

                    arlen   <= BURST_LEN - 1;
                    arsize  <= $clog2(AXI_DATA_W/8);
                    arburst <= 2'b01;
                end

                ADDR: begin
                    arvalid <= 1;
                    if (arready)
                        arvalid <= 0;
                end

            endcase
        end
    end

    // =========================================================
    // READ → SPLIT → BUFFER WRITE
    // =========================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rready   <= 0;
            wr_en    <= 0;
            wr_data  <= 0;
            wr_addr  <= 0;
            beat_cnt <= 0;
            half_sel <= 0;
        end
        else begin

            //--------------------------------------------------
            // Default
            //--------------------------------------------------
            wr_en <= 0;

            case (state)

                READ: begin
                    rready <= 1;

                    if (rvalid) begin

                        wr_en <= 1;

                        //--------------------------------------
                        // Lower half
                        //--------------------------------------
                        if (!half_sel) begin
                            wr_data  <= rdata[63:0];
                            wr_addr  <= {beat_cnt, 1'b0};
                            half_sel <= 1;
                        end

                        //--------------------------------------
                        // Upper half
                        //--------------------------------------
                        else begin
                            wr_data  <= rdata[127:64];
                            wr_addr  <= {beat_cnt, 1'b1};
                            half_sel <= 0;
                            beat_cnt <= beat_cnt + 1;
                        end
                    end
                end

                //--------------------------------------------------
                // Reset only when restarting
                //--------------------------------------------------
                IDLE: begin
                    rready   <= 0;
                    beat_cnt <= 0;
                    half_sel <= 0;
                end

            endcase
        end
    end

    // =========================================================
    // DONE FLAG
    // =========================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            done <= 0;
        else
            done <= (state == DONE);
    end

endmodule

