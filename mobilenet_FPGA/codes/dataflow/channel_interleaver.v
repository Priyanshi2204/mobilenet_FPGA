`timescale 1ns / 1ps

module channel_interleaver #(
    parameter DATA_WIDTH   = 16,
    parameter NUM_CHANNELS = 4
)(
    input  wire                        clk,
    input  wire                        rst_n,

    // Input: 4 parallel channels (same pixel index)
    input  wire [DATA_WIDTH-1:0]       in_ch0,
    input  wire [DATA_WIDTH-1:0]       in_ch1,
    input  wire [DATA_WIDTH-1:0]       in_ch2,
    input  wire [DATA_WIDTH-1:0]       in_ch3,
    input  wire                        in_valid,
    output wire                        in_ready,

    // Output: serialized stream
    output reg  [DATA_WIDTH-1:0]       out_data,
    output reg                         out_valid,
    input  wire                        out_ready
);

    // ============================================================
    // Internal Registers
    // ============================================================

    // Buffer for input channels
    reg [DATA_WIDTH-1:0] buffer [0:NUM_CHANNELS-1];

    // Channel index (0 → 3)
    reg [1:0] ch_idx;

    // Indicates buffer has valid data to stream
    reg       busy;

    // ============================================================
    // Input Ready Logic
    // ============================================================

    // Ready only when not currently streaming OR last output accepted
    assign in_ready = (~busy) || (busy && (ch_idx == NUM_CHANNELS-1) && out_ready);

    // ============================================================
    // Main Sequential Logic
    // ============================================================

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            busy      <= 1'b0;
            ch_idx    <= 2'd0;
            out_data  <= {DATA_WIDTH{1'b0}};
            out_valid <= 1'b0;

            for (i = 0; i < NUM_CHANNELS; i = i + 1) begin
                buffer[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin

            // ====================================================
            // Case 1: Load new data into buffer
            // ====================================================
            if (in_valid && in_ready) begin
                buffer[0] <= in_ch0;
                buffer[1] <= in_ch1;
                buffer[2] <= in_ch2;
                buffer[3] <= in_ch3;

                busy   <= 1'b1;
                ch_idx <= 2'd0;
            end

            // ====================================================
            // Output Logic
            // ====================================================
            if (busy) begin
                out_valid <= 1'b1;

                // Output current channel
                case (ch_idx)
                    2'd0: out_data <= buffer[0];
                    2'd1: out_data <= buffer[1];
                    2'd2: out_data <= buffer[2];
                    2'd3: out_data <= buffer[3];
                endcase

                // Advance only if downstream is ready
                if (out_ready) begin
                    if (ch_idx == NUM_CHANNELS-1) begin
                        // Finished streaming current group
                        busy   <= 1'b0;
                        ch_idx <= 2'd0;
                        out_valid <= 1'b0;  // next cycle may reload
                    end else begin
                        ch_idx <= ch_idx + 1;
                    end
                end
            end else begin
                // No valid output when idle
                out_valid <= 1'b0;
            end

        end
    end

endmodule
