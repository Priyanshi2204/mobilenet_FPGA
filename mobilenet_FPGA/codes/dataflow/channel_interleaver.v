`timescale 1ns / 1ps

module channel_interleaver #(
    parameter DATA_WIDTH   = 16,
    parameter NUM_CHANNELS = 4
)(
    input  wire                              clk,
    input  wire                              rst_n,

    // ============================================================
    // Parallel channel inputs (same pixel index)
    // ============================================================
    input  wire [DATA_WIDTH-1:0]              in_ch0,
    input  wire [DATA_WIDTH-1:0]              in_ch1,
    input  wire [DATA_WIDTH-1:0]              in_ch2,
    input  wire [DATA_WIDTH-1:0]              in_ch3,
    input  wire                              in_valid,
    output wire                              in_ready,

    // ============================================================
    // Serialized output stream
    // ============================================================
    output reg  [DATA_WIDTH-1:0]              out_data,
    output reg                               out_valid,
    input  wire                              out_ready
);

    // ============================================================
    // Internal Storage
    // ============================================================

    // Channel buffer
    reg [DATA_WIDTH-1:0] buffer [0:NUM_CHANNELS-1];

    // Channel index (scalable)
    reg [$clog2(NUM_CHANNELS)-1:0] ch_idx;

    // Busy flag → streaming in progress
    reg busy;

    integer i;

    // ============================================================
    // Input Ready Logic
    // ============================================================

    /*
       Ready when:
       1) Not busy
       2) OR last channel is being accepted
    */
    assign in_ready =
        (~busy) ||
        (busy && (ch_idx == NUM_CHANNELS-1) && out_ready);

    // ============================================================
    // Sequential Logic
    // ============================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy      <= 1'b0;
            ch_idx    <= 0;
            out_data  <= 0;
            out_valid <= 1'b0;

            for (i = 0; i < NUM_CHANNELS; i = i + 1)
                buffer[i] <= 0;
        end
        else begin

            // ====================================================
            // Load new parallel data
            // ====================================================
            if (in_valid && in_ready) begin
                buffer[0] <= in_ch0;
                buffer[1] <= in_ch1;
                buffer[2] <= in_ch2;
                buffer[3] <= in_ch3;

                busy   <= 1'b1;
                ch_idx <= 0;
            end

            // ====================================================
            // Streaming / Serialization
            // ====================================================
            if (busy) begin
                out_valid <= 1'b1;

                // Channel mux (scalable)
                out_data <= buffer[ch_idx];

                // Advance only when downstream ready
                if (out_ready) begin
                    if (ch_idx == NUM_CHANNELS-1) begin
                        // Finished last channel
                        busy   <= 1'b0;
                        ch_idx <= 0;
                    end
                    else begin
                        ch_idx <= ch_idx + 1;
                    end
                end
            end
            else begin
                out_valid <= 1'b0;
            end

        end
    end

endmodule
