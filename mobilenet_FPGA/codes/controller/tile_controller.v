module tile_controller #(
    parameter TILE_H = 16,
    parameter TILE_W = 8,
    parameter DATA_BYTES = 2
)(
    input  wire        clk,
    input  wire        rst,

    // control
    input  wire        start,
    input  wire        tile_done,

    // config
    input  wire [15:0] H,
    input  wire [15:0] W,

    // outputs
    output reg         tile_start,
    output reg         all_done,

    output reg         first_tile,
    output reg         last_tile,

    output reg [15:0]  tile_x,
    output reg [15:0]  tile_y,

    output reg [31:0]  ifm_base_addr,
    output reg [31:0]  ofm_base_addr
);

    // FSM states
    localparam IDLE        = 3'd0;
    localparam INIT        = 3'd1;
    localparam START_TILE  = 3'd2;
    localparam WAIT_DONE   = 3'd3;
    localparam NEXT_TILE   = 3'd4;
    localparam DONE        = 3'd5;

    reg [2:0] state, next_state;

    // ------------------------------------------------
    // STATE REGISTER
    // ------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ------------------------------------------------
    // NEXT STATE LOGIC
    // ------------------------------------------------
    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start)
                    next_state = INIT;
            end

            INIT: begin
                next_state = START_TILE;
            end

            START_TILE: begin
                next_state = WAIT_DONE;
            end

            WAIT_DONE: begin
                if (tile_done)
                    next_state = NEXT_TILE;
            end

            NEXT_TILE: begin
                if (last_tile)
                    next_state = DONE;
                else
                    next_state = START_TILE;
            end

            DONE: begin
                next_state = IDLE;
            end
        endcase
    end

    // ------------------------------------------------
    // HELPER SIGNALS
    // ------------------------------------------------
    wire end_of_row;
    wire end_of_col;

    assign end_of_row = (tile_x + TILE_W >= W);
    assign end_of_col = (tile_y + TILE_H >= H);

    // ------------------------------------------------
    // CONTROL LOGIC
    // ------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tile_start   <= 0;
            all_done     <= 0;
            tile_x       <= 0;
            tile_y       <= 0;
            first_tile   <= 0;
            last_tile    <= 0;
            ifm_base_addr <= 0;
            ofm_base_addr <= 0;
        end else begin
            // default
            tile_start <= 0;
            all_done   <= 0;

            case (state)

                IDLE: begin
                    tile_x     <= 0;
                    tile_y     <= 0;
                    first_tile <= 0;
                    last_tile  <= 0;
                end

                INIT: begin
                    tile_x     <= 0;
                    tile_y     <= 0;
                    first_tile <= 1;
                    last_tile  <= (TILE_H >= H && TILE_W >= W);
                end

                START_TILE: begin
                    tile_start <= 1;

                    first_tile <= (tile_x == 0 && tile_y == 0);
                    last_tile  <= (end_of_row && end_of_col);

                    // compute base addresses
                    ifm_base_addr <= ((tile_y * W) + tile_x) * DATA_BYTES;
                    ofm_base_addr <= ((tile_y * W) + tile_x) * DATA_BYTES;
                end

                WAIT_DONE: begin
                    // wait for tile_done
                end

                NEXT_TILE: begin
                    if (!last_tile) begin
                        if (end_of_row) begin
                            // move to next row
                            tile_x <= 0;
                            tile_y <= tile_y + TILE_H;
                        end else begin
                            // move to next column
                            tile_x <= tile_x + TILE_W;
                        end
                    end
                end

                DONE: begin
                    all_done <= 1;
                end

            endcase
        end
    end

endmodule
