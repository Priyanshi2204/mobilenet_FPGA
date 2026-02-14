module dma_controller #(    
    parameter AXI_ADDR_W = 32
)(
    input  wire clk,
    input  wire rst_n,

    //--------------------------------------------------
    // Global control
    //--------------------------------------------------
    input  wire start,

    //--------------------------------------------------
    // Tile controller interface
    //--------------------------------------------------
    input  wire tile_start,
    input  wire tile_last,
    input  wire [AXI_ADDR_W-1:0] ifm_base_addr,
    input  wire [AXI_ADDR_W-1:0] ofm_base_addr,

    output reg  tile_done,

    //--------------------------------------------------
    // Fold / compute interface
    //--------------------------------------------------
    input  wire compute_done,
    output reg  compute_start,

    //--------------------------------------------------
    // AXI master interfaces
    //--------------------------------------------------
    input  wire ifm_done,
    input  wire weight_done,
    input  wire ofm_done,

    output reg  ifm_start,
    output reg  weight_start,
    output reg  ofm_start,

    output reg [AXI_ADDR_W-1:0] ifm_addr,
    output reg [AXI_ADDR_W-1:0] weight_addr,
    output reg [AXI_ADDR_W-1:0] ofm_addr,

    //--------------------------------------------------
    // Global done
    //--------------------------------------------------
    output reg  all_done
);

    // ------------------------------------------------
    // FSM STATES
    // ------------------------------------------------
    localparam IDLE           = 4'd0;
    localparam LOAD_WEIGHT    = 4'd1;
    localparam WAIT_WEIGHT    = 4'd2;
    localparam WAIT_TILE      = 4'd3;
    localparam LOAD_IFM       = 4'd4;
    localparam WAIT_IFM       = 4'd5;
    localparam START_COMPUTE  = 4'd6;
    localparam WAIT_COMPUTE   = 4'd7;
    localparam STORE_OFM      = 4'd8;
    localparam WAIT_OFM       = 4'd9;
    localparam NEXT_TILE      = 4'd10;
    localparam DONE           = 4'd11;

    reg [3:0] state, next_state;

    //--------------------------------------------------
    // STATE REGISTER
    //--------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    //--------------------------------------------------
    // NEXT STATE LOGIC
    //--------------------------------------------------
    always @(*) begin
        next_state = state;

        case (state)

            IDLE:
                if (start)
                    next_state = LOAD_WEIGHT;

            LOAD_WEIGHT:
                next_state = WAIT_WEIGHT;

            WAIT_WEIGHT:
                if (weight_done)
                    next_state = WAIT_TILE;

            WAIT_TILE:
                if (tile_start)
                    next_state = LOAD_IFM;

            LOAD_IFM:
                next_state = WAIT_IFM;

            WAIT_IFM:
                if (ifm_done)
                    next_state = START_COMPUTE;

            START_COMPUTE:
                next_state = WAIT_COMPUTE;

            WAIT_COMPUTE:
                if (compute_done)
                    next_state = STORE_OFM;

            STORE_OFM:
                next_state = WAIT_OFM;

            WAIT_OFM:
                if (ofm_done)
                    next_state = NEXT_TILE;

            NEXT_TILE:
                if (tile_last)
                    next_state = DONE;
                else
                    next_state = WAIT_TILE;

            DONE:
                next_state = IDLE;

        endcase
    end

    //--------------------------------------------------
    // CONTROL LOGIC
    //--------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ifm_start    <= 0;
            weight_start <= 0;
            ofm_start    <= 0;
            compute_start<= 0;
            tile_done    <= 0;
            all_done     <= 0;

            ifm_addr     <= 0;
            weight_addr  <= 0;
            ofm_addr     <= 0;
        end else begin

            // default deassert
            ifm_start     <= 0;
            weight_start  <= 0;
            ofm_start     <= 0;
            compute_start <= 0;
            tile_done     <= 0;
            all_done      <= 0;

            case (state)

                //--------------------------------------------------
                IDLE: begin
                end

                //--------------------------------------------------
                LOAD_WEIGHT: begin
                    weight_start <= 1;
                    weight_addr  <= 0;  // base weight addr (set externally later)
                end

                //--------------------------------------------------
                WAIT_WEIGHT: begin
                end

                //--------------------------------------------------
                WAIT_TILE: begin
                end

                //--------------------------------------------------
                LOAD_IFM: begin
                    ifm_start <= 1;
                    ifm_addr  <= ifm_base_addr;
                end

                //--------------------------------------------------
                WAIT_IFM: begin
                end

                //--------------------------------------------------
                START_COMPUTE: begin
                    compute_start <= 1;
                end

                //--------------------------------------------------
                WAIT_COMPUTE: begin
                end

                //--------------------------------------------------
                STORE_OFM: begin
                    ofm_start <= 1;
                    ofm_addr  <= ofm_base_addr;
                end

                //--------------------------------------------------
                WAIT_OFM: begin
                end

                //--------------------------------------------------
                NEXT_TILE: begin
                    tile_done <= 1;
                end

                //--------------------------------------------------
                DONE: begin
                    all_done <= 1;
                end

            endcase
        end
    end

endmodule
