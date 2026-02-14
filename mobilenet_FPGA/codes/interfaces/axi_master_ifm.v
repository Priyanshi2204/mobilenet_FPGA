`timescale 1ns / 1ps
module axi_master_ifm #(

    parameter AXI_ADDR_W = 32,
    parameter AXI_DATA_W = 128,
    parameter BUF_ADDR_W = 10,
    parameter BURST_LEN  = 128   // ≤ 256 for AXI4

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
    // IFM BUFFER WRITE PORT
    //--------------------------------------------------
    output reg  [AXI_DATA_W-1:0] wr_data,
    output reg                   wr_en,
    output reg  [BUF_ADDR_W-1:0] wr_addr
);

    // =========================================================
    // FSM STATES
    // =========================================================

    localparam IDLE = 0;
    localparam ADDR = 1;
    localparam READ = 2;
    localparam DONE = 3;

    reg [1:0] state, next_state;

    // =========================================================
    // Beat Counter
    // =========================================================

    reg [$clog2(BURST_LEN):0] beat_cnt;

    // =========================================================
    // FSM SEQUENTIAL
    // =========================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // =========================================================
    // FSM COMBINATIONAL
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

            READ:
//                if ((beat_cnt == BURST_LEN-1 && rvalid) || rlast)
                    if (rvalid && rlast)
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
                    arburst <= 2'b01; // INCR
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
    // READ DATA + COUNTER + BUFFER WRITE
    // =========================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rready   <= 0;
            wr_en    <= 0;
            wr_data  <= 0;
            wr_addr  <= 0;
            beat_cnt <= 0;
        end
        else begin

            //--------------------------------------------------
            // Counter control (separate)
            //--------------------------------------------------
            if (state == IDLE && start_read)
                beat_cnt <= 0;
            else if (state == READ && rvalid)
                beat_cnt <= beat_cnt + 1;

            //--------------------------------------------------
            // Data path
            //--------------------------------------------------
            case (state)

                READ: begin
                    rready <= 1;

                    if (rvalid) begin
                        wr_en   <= 1;
                        wr_data <= rdata;
                        wr_addr <= beat_cnt;
                    end
                    else begin
                        wr_en <= 0;
                    end
                end

                default: begin
                    rready <= 0;
                    wr_en  <= 0;
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
            done <= (state == DONE && next_state == IDLE);

    end

endmodule



