module layer_controller #(
    parameter MAX_LAYERS = 100,
    parameter AXI_ADDR_W = 32
)(
    input  wire clk,
    input  wire rst_n,

    //--------------------------------------------------
    // Control
    //--------------------------------------------------
    input  wire start,
    input  wire layer_done,   // from dma_controller

    //--------------------------------------------------
    // Outputs
    //--------------------------------------------------
    output reg  layer_start,
    output reg  all_done,

    // config
    output reg [15:0] H,
    output reg [15:0] W,
    output reg [15:0] Cin,
    output reg [15:0] Cout,

    output reg [AXI_ADDR_W-1:0] weight_addr,
    output reg [AXI_ADDR_W-1:0] ifm_addr,
    output reg [AXI_ADDR_W-1:0] ofm_addr
);

    //--------------------------------------------------
    // LAYER CONFIG MEMORY
    //--------------------------------------------------
    reg [15:0] layer_Cin  [0:MAX_LAYERS-1];
    reg [15:0] layer_Cout [0:MAX_LAYERS-1];
    reg [15:0] layer_H    [0:MAX_LAYERS-1];
    reg [15:0] layer_W    [0:MAX_LAYERS-1];

    reg [AXI_ADDR_W-1:0] layer_weight_addr [0:MAX_LAYERS-1];

    //--------------------------------------------------
    // INIT (example)
    //--------------------------------------------------
    initial begin
        // Example layers
        layer_Cin[0]  = 3;
        layer_Cout[0] = 16;
        layer_H[0]    = 224;
        layer_W[0]    = 224;
        layer_weight_addr[0] = 32'h0000_0000;

        layer_Cin[1]  = 16;
        layer_Cout[1] = 32;
        layer_H[1]    = 112;
        layer_W[1]    = 112;
        layer_weight_addr[1] = 32'h0001_0000;
    end

    //--------------------------------------------------
    // INTERNAL REGISTERS
    //--------------------------------------------------
    reg [7:0] layer_idx;
    reg pingpong;

    //--------------------------------------------------
    // BUFFER BASE ADDRESSES (ON-CHIP)
    //--------------------------------------------------
    localparam BUFFER0_ADDR = 32'h8000_0000;
    localparam BUFFER1_ADDR = 32'h8100_0000;

    //--------------------------------------------------
    // FSM STATES
    //--------------------------------------------------
    localparam IDLE        = 3'd0;
    localparam LOAD_CONFIG = 3'd1;
    localparam START_LAYER = 3'd2;
    localparam WAIT_LAYER  = 3'd3;
    localparam NEXT_LAYER  = 3'd4;
    localparam DONE        = 3'd5;

    reg [2:0] state, next_state;

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
                    next_state = LOAD_CONFIG;

            LOAD_CONFIG:
                next_state = START_LAYER;

            START_LAYER:
                next_state = WAIT_LAYER;

            WAIT_LAYER:
                if (layer_done)
                    next_state = NEXT_LAYER;

            NEXT_LAYER:
                if (layer_idx == MAX_LAYERS-1)
                    next_state = DONE;
                else
                    next_state = LOAD_CONFIG;

            DONE:
                next_state = IDLE;
        endcase
    end

    //--------------------------------------------------
    // CONTROL LOGIC
    //--------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            layer_start <= 0;
            all_done    <= 0;
            layer_idx   <= 0;
            pingpong    <= 0;
        end else begin

            layer_start <= 0;
            all_done    <= 0;

            case (state)

                IDLE: begin
                    layer_idx <= 0;
                    pingpong  <= 0;
                end

                //--------------------------------------------------
                LOAD_CONFIG: begin
                    Cin <= layer_Cin[layer_idx];
                    Cout<= layer_Cout[layer_idx];
                    H   <= layer_H[layer_idx];
                    W   <= layer_W[layer_idx];

                    weight_addr <= layer_weight_addr[layer_idx];

                    // ping-pong addressing
                    if (layer_idx == 0) begin
                        ifm_addr <= 32'h0000_0000; // input image in DDR
                    end else begin
                        ifm_addr <= (pingpong) ? BUFFER1_ADDR : BUFFER0_ADDR;
                    end

                    ofm_addr <= (pingpong) ? BUFFER0_ADDR : BUFFER1_ADDR;
                end

                //--------------------------------------------------
                START_LAYER: begin
                    layer_start <= 1;
                end

                //--------------------------------------------------
                WAIT_LAYER: begin
                end

                //--------------------------------------------------
                NEXT_LAYER: begin
                    layer_idx <= layer_idx + 1;
                    pingpong  <= ~pingpong;
                end

                //--------------------------------------------------
                DONE: begin
                    all_done <= 1;
                end

            endcase
        end
    end

endmodule
