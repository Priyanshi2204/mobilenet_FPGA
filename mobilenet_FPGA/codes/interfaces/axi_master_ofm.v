module axi_master_ofm #(
    parameter AXI_ADDR_W = 32,
    parameter AXI_DATA_W = 128,
    parameter BUF_ADDR_W = 10,
    parameter BURST_LEN  = 128
)(
    input  wire clk,
    input  wire rst_n,

    //--------------------------------------------------
    // Control
    //--------------------------------------------------
    input  wire start_write,
    input  wire [AXI_ADDR_W-1:0] base_addr,
    output reg  done,

    //--------------------------------------------------
    // AXI WRITE ADDRESS CHANNEL
    //--------------------------------------------------
    output reg  [AXI_ADDR_W-1:0] awaddr,
    output reg                   awvalid,
    input  wire                  awready,

    output reg  [7:0]            awlen,
    output reg  [2:0]            awsize,
    output reg  [1:0]            awburst,

    //--------------------------------------------------
    // AXI WRITE DATA CHANNEL
    //--------------------------------------------------
    output reg  [AXI_DATA_W-1:0] wdata,
    output reg                   wvalid,
    input  wire                  wready,
    output reg                   wlast,
    output reg  [(AXI_DATA_W/8)-1:0] wstrb,

    //--------------------------------------------------
    // AXI WRITE RESPONSE
    //--------------------------------------------------
    input  wire bvalid,
    output reg  bready,

    //--------------------------------------------------
    // OFM BUFFER READ PORT
    //--------------------------------------------------
    output reg  [BUF_ADDR_W-1:0] rd_addr,
    input  wire [AXI_DATA_W-1:0] axi_out_data,
    input  wire [(AXI_DATA_W/8)-1:0] axi_wstrb
);

    // =========================================================
    // START EDGE DETECT
    // =========================================================

    reg start_d;
    wire start_pulse;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            start_d <= 0;
        else
            start_d <= start_write;
    end

    assign start_pulse = start_write & ~start_d;

    // =========================================================
    // FSM STATES
    // =========================================================

    localparam IDLE = 3'd0;
    localparam ADDR = 3'd1;
    localparam WRITE= 3'd2;
    localparam RESP = 3'd3;
    localparam DONE = 3'd4;

    reg [2:0] state, next_state;

    // =========================================================
    // Beat counter
    // =========================================================

    reg [$clog2(BURST_LEN):0] beat_cnt;

    wire w_fire = wvalid && wready;

    // =========================================================
    // STATE REGISTER
    // =========================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // =========================================================
    // NEXT STATE LOGIC
    // =========================================================

    always @(*) begin
        next_state = state;

        case (state)

            IDLE:
                if (start_pulse)
                    next_state = ADDR;

            ADDR:
                if (awvalid && awready)
                    next_state = WRITE;

            WRITE:
                if (w_fire && wlast)
                    next_state = RESP;

            RESP:
                if (bvalid)
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
            awaddr  <= 0;
            awvalid <= 0;
            awlen   <= 0;
            awsize  <= 0;
            awburst <= 0;
        end else begin

            case (state)

                IDLE: begin
                    awaddr  <= base_addr;
                    awlen   <= BURST_LEN - 1;
                    awsize  <= $clog2(AXI_DATA_W/8);
                    awburst <= 2'b01; // INCR
                    awvalid <= 0;
                end

                ADDR: begin
                    awvalid <= 1;
                    if (awvalid && awready)
                        awvalid <= 0;
                end

            endcase
        end
    end

    // =========================================================
    // WRITE DATA CHANNEL
    // =========================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wvalid   <= 0;
            wlast    <= 0;
            wdata    <= 0;
            wstrb    <= 0;
            rd_addr  <= 0;
            beat_cnt <= 0;
        end else begin

            //--------------------------------------------------
            // Counter
            //--------------------------------------------------
            if (state == IDLE && start_pulse)
                beat_cnt <= 0;
            else if (state == WRITE && w_fire)
                beat_cnt <= beat_cnt + 1;

            //--------------------------------------------------
            // Write channel
            //--------------------------------------------------
            case (state)

                WRITE: begin
                    wvalid <= 1;

                    // Drive data from buffer
                    wdata <= axi_out_data;
                    wstrb <= axi_wstrb;
                    rd_addr <= beat_cnt;

                    // Last signal
                    wlast <= (beat_cnt == BURST_LEN-1);

                end

                default: begin
                    wvalid <= 0;
                    wlast  <= 0;
                end

            endcase
        end
    end

    // =========================================================
    // RESPONSE CHANNEL
    // =========================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bready <= 0;
        else begin
            case (state)
                RESP: bready <= 1;
                default: bready <= 0;
            endcase
        end
    end

    // =========================================================
    // DONE (1-cycle pulse)
    // =========================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            done <= 0;
        else
            done <= (state == DONE);
    end

endmodule
