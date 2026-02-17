`timescale 1ns / 1ps

module tb_priyanshi;

    // ============================================================
    // Parameters
    // ============================================================
    parameter DATA_WIDTH   = 16;
    parameter NUM_CHANNELS = 4;

    // ============================================================
    // DUT Signals
    // ============================================================
    reg clk;
    reg rst_n;

    reg  [DATA_WIDTH-1:0] in_ch0;
    reg  [DATA_WIDTH-1:0] in_ch1;
    reg  [DATA_WIDTH-1:0] in_ch2;
    reg  [DATA_WIDTH-1:0] in_ch3;
    reg                   in_valid;
    wire                  in_ready;

    wire [DATA_WIDTH-1:0] out_data;
    wire                  out_valid;
    reg                   out_ready;

    // ============================================================
    // Instantiate DUT
    // ============================================================
    channel_interleaver #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_CHANNELS(NUM_CHANNELS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .in_ch0(in_ch0),
        .in_ch1(in_ch1),
        .in_ch2(in_ch2),
        .in_ch3(in_ch3),
        .in_valid(in_valid),
        .in_ready(in_ready),

        .out_data(out_data),
        .out_valid(out_valid),
        .out_ready(out_ready)
    );

    // ============================================================
    // Clock
    // ============================================================
    always #5 clk = ~clk;  // 100 MHz

    // ============================================================
    // Task: Send one pixel group
    // ============================================================
    task send_group(
        input [15:0] c0,
        input [15:0] c1,
        input [15:0] c2,
        input [15:0] c3
    );
    begin
        @(posedge clk);
        while (!in_ready) @(posedge clk);

        in_ch0   <= c0;
        in_ch1   <= c1;
        in_ch2   <= c2;
        in_ch3   <= c3;
        in_valid <= 1'b1;

        @(posedge clk);
        in_valid <= 1'b0;
    end
    endtask

    // ============================================================
    // Monitor
    // ============================================================
    always @(posedge clk) begin
        if (out_valid && out_ready) begin
            $display("Time %0t → OUT = %0d",
                     $time, out_data);
        end
    end

    // ============================================================
    // Stimulus
    // ============================================================
    initial begin
        clk = 0;
        rst_n = 0;
        in_valid = 0;
        out_ready = 1;

        in_ch0 = 0;
        in_ch1 = 0;
        in_ch2 = 0;
        in_ch3 = 0;

        // Reset
        #20;
        rst_n = 1;

        // =====================================================
        // Test 1: Single group
        // Expect: 10 20 30 40
        // =====================================================
        send_group(10, 20, 30, 40);

        // Wait
        #100;

        // =====================================================
        // Test 2: Back-to-back groups
        // =====================================================
        send_group(1, 2, 3, 4);
        send_group(5, 6, 7, 8);

        #100;

        // =====================================================
        // Test 3: Backpressure
        // =====================================================
        send_group(100, 200, 300, 400);

        #10;
        out_ready = 0;  // Stall downstream

        #40;
        out_ready = 1;  // Resume

        #100;

        $finish;
    end

endmodule
