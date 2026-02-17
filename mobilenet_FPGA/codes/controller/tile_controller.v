`timescale 1ns / 1ps

module tile_controller #(
    parameter TILE_H = 16,
    parameter TILE_W = 8,
    parameter DATA_BYTES = 2
)(
    input  wire        clk,
    input  wire        rst,

    input  wire        start,
    input  wire        tile_done,

    input  wire [15:0] H,
    input  wire [15:0] W,

    output reg         tile_start,
    output reg         all_done,

    output reg         first_tile,
    output reg         last_tile,

    output reg [15:0]  tile_x,
    output reg [15:0]  tile_y,

    output reg [31:0]  ifm_base_addr,
    output reg [31:0]  ofm_base_addr
);

    // FSM
    localparam IDLE      = 3'd0;
    localparam PREP      = 3'd1;
    localparam ISSUE     = 3'd2;
    localparam WAIT_DONE = 3'd3;
    localparam UPDATE    = 3'd4;
    localparam DONE      = 3'd5;

    reg [2:0] state, next_state;

    //--------------------------------------------------
    // Tile logic
    //--------------------------------------------------
    wire end_of_row = (tile_x + TILE_W >= W);
    wire end_of_col = (tile_y + TILE_H >= H);
    wire curr_last  = end_of_row && end_of_col;

    reg [15:0] next_x, next_y;

    always @(*) begin
        if (end_of_row) begin
            next_x = 0;
            next_y = tile_y + TILE_H;
        end else begin
            next_x = tile_x + TILE_W;
            next_y = tile_y;
        end
    end

    //--------------------------------------------------
    // State register
    //--------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    //--------------------------------------------------
    // Next state
    //--------------------------------------------------
    always @(*) begin
        next_state = state;

        case (state)
            IDLE:
                if (start) next_state = PREP;

            PREP:
                next_state = ISSUE;

            ISSUE:
                next_state = WAIT_DONE;

            WAIT_DONE:
                if (tile_done) next_state = UPDATE;

            UPDATE:
                if (curr_last)
                    next_state = DONE;
                else
                    next_state = PREP;

            DONE:
                if (!start) next_state = IDLE;
        endcase
    end

    //--------------------------------------------------
    // Output logic
    //--------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tile_x <= 0;
            tile_y <= 0;
            tile_start <= 0;
            all_done <= 0;
            first_tile <= 0;
            last_tile <= 0;
            ifm_base_addr <= 0;
            ofm_base_addr <= 0;
        end else begin

            tile_start <= 0;

            case (state)

                //----------------------------------
                IDLE: begin
                    if (start) begin
                        tile_x <= 0;
                        tile_y <= 0;
                        all_done <= 0;
                        first_tile <= 1;
                    end
                end

                //----------------------------------
                PREP: begin
                    // prepare outputs
                    last_tile <= curr_last;

                    ifm_base_addr <= ((tile_y * W) + tile_x) * DATA_BYTES;
                    ofm_base_addr <= ((tile_y * W) + tile_x) * DATA_BYTES;

                    if (!(tile_x == 0 && tile_y == 0))
                        first_tile <= 0;
                end

                //----------------------------------
                ISSUE: begin
                    tile_start <= 1;
                end

                //----------------------------------
                WAIT_DONE: begin
                end

                //----------------------------------
                UPDATE: begin
                    if (!curr_last) begin
                        tile_x <= next_x;
                        tile_y <= next_y;
                    end
                end

                //----------------------------------
                DONE: begin
                    all_done <= 1;
                end

            endcase
        end
    end

endmodule
