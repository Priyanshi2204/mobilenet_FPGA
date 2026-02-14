module fold_controller #(
    parameter PAR_CH = 16
)(
    input  wire        clk,
    input  wire        rst,

    // control
    input  wire        start,
    input  wire        compute_done,

    // config
    input  wire [15:0] Cin,

    // outputs
    output reg         fold_start,
    output reg         fold_done,
    output reg         all_done,

    output reg         first_fold,
    output reg         last_fold,

    output reg [15:0]  fold_idx,
    output reg [15:0]  ch_base
);

    // FSM states
    localparam IDLE        = 3'd0;
    localparam INIT        = 3'd1;
    localparam START_FOLD  = 3'd2;
    localparam WAIT_COMP   = 3'd3;
    localparam NEXT_FOLD   = 3'd4;
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
                next_state = START_FOLD;
            end

            START_FOLD: begin
                next_state = WAIT_COMP;
            end

            WAIT_COMP: begin
                if (compute_done)
                    next_state = NEXT_FOLD;
            end

            NEXT_FOLD: begin
                if (last_fold)
                    next_state = DONE;
                else
                    next_state = START_FOLD;
            end

            DONE: begin
                next_state = IDLE;
            end
        endcase
    end

    // ------------------------------------------------
    // CONTROL LOGIC
    // ------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fold_start <= 0;
            fold_done  <= 0;
            all_done   <= 0;

            fold_idx   <= 0;
            ch_base    <= 0;

            first_fold <= 0;
            last_fold  <= 0;
        end else begin
            // default
            fold_start <= 0;
            fold_done  <= 0;
            all_done   <= 0;

            case (state)

                IDLE: begin
                    fold_idx   <= 0;
                    ch_base    <= 0;
                    first_fold <= 0;
                    last_fold  <= 0;
                end

                INIT: begin
                    fold_idx   <= 0;
                    ch_base    <= 0;
                    first_fold <= 1;
                    last_fold  <= (PAR_CH >= Cin);
                end

                START_FOLD: begin
                    fold_start <= 1;

                    first_fold <= (fold_idx == 0);
                    last_fold  <= (ch_base + PAR_CH >= Cin);
                end

                WAIT_COMP: begin
                    // wait for compute_done
                end

                NEXT_FOLD: begin
                    fold_done <= 1;

                    if (!last_fold) begin
                        fold_idx <= fold_idx + 1;
                        ch_base  <= ch_base + PAR_CH;
                    end
                end

                DONE: begin
                    all_done <= 1;
                end

            endcase
        end
    end

endmodule
