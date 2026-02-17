`timescale 1ns/1ps

module tb_aadya;

    //--------------------------------------------------
    // PARAMETERS
    //--------------------------------------------------
    parameter TILE_H     = 16;
    parameter TILE_W     = 8;
    parameter DATA_BYTES = 2;

    //--------------------------------------------------
    // SIGNALS
    //--------------------------------------------------
    reg clk;
    reg rst;

    reg start;
    reg tile_done;

    reg [15:0] H;
    reg [15:0] W;

    wire tile_start;
    wire all_done;

    wire first_tile;
    wire last_tile;

    wire [15:0] tile_x;
    wire [15:0] tile_y;

    wire [31:0] ifm_base_addr;
    wire [31:0] ofm_base_addr;

    //--------------------------------------------------
    // DUT
    //--------------------------------------------------
    tile_controller #(
        .TILE_H(TILE_H),
        .TILE_W(TILE_W),
        .DATA_BYTES(DATA_BYTES)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .tile_done(tile_done),
        .H(H),
        .W(W),
        .tile_start(tile_start),
        .all_done(all_done),
        .first_tile(first_tile),
        .last_tile(last_tile),
        .tile_x(tile_x),
        .tile_y(tile_y),
        .ifm_base_addr(ifm_base_addr),
        .ofm_base_addr(ofm_base_addr)
    );

    //--------------------------------------------------
    // CLOCK
    //--------------------------------------------------
    always #5 clk = ~clk;

    //--------------------------------------------------
    // UTIL
    //--------------------------------------------------
    task wait_cycles(input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    //--------------------------------------------------
    // WAIT FOR TILE_START (SAFE VERSION)
    //--------------------------------------------------
    task wait_for_tile_start;
        integer timeout;
        begin
            timeout = 0;

            while (!tile_start && !all_done) begin
                @(posedge clk);
                timeout = timeout + 1;

                if (timeout > 50) begin
                    $display("ERROR @%0t: tile_start timeout!", $time);
                    $finish;
                end
            end
        end
    endtask

    //--------------------------------------------------
    // EXPECTED ADDR
    //--------------------------------------------------
    function [31:0] calc_addr;
        input [15:0] x;
        input [15:0] y;
        input [15:0] width;
        begin
            calc_addr = ((y * width) + x) * DATA_BYTES;
        end
    endfunction

    //--------------------------------------------------
    // MAIN TEST
    //--------------------------------------------------
    task run_test(input [15:0] h_val, input [15:0] w_val);
        integer exp_x, exp_y;
        integer tile_count;
        begin
            $display("\n===============================");
            $display("TEST: H=%0d W=%0d", h_val, w_val);
            $display("===============================\n");

            H = h_val;
            W = w_val;

            exp_x = 0;
            exp_y = 0;
            tile_count = 0;

            //--------------------------------------------------
            // START
            //--------------------------------------------------
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            //--------------------------------------------------
            // LOOP
            //--------------------------------------------------
            while (!all_done) begin

                // WAIT FOR VALID TILE
                wait_for_tile_start();

                // EXIT IF FINISHED
                if (all_done)
                    disable run_test;

                //--------------------------------------------------
                // CHECK TILE POSITION
                //--------------------------------------------------
                if (tile_x !== exp_x || tile_y !== exp_y) begin
                    $display("ERROR: tile coord mismatch. Got (%0d,%0d) Exp (%0d,%0d)",
                             tile_x, tile_y, exp_x, exp_y);
                end

                //--------------------------------------------------
                // CHECK ADDRESSES
                //--------------------------------------------------
                if (ifm_base_addr !== calc_addr(exp_x, exp_y, W))
                    $display("ERROR: IFM addr mismatch");

                if (ofm_base_addr !== calc_addr(exp_x, exp_y, W))
                    $display("ERROR: OFM addr mismatch");

                //--------------------------------------------------
                // FLAGS
                //--------------------------------------------------
                if (tile_count == 0 && !first_tile)
                    $display("ERROR: first_tile not set!");

                //--------------------------------------------------
                // PROCESS TILE
                //--------------------------------------------------
                wait_cycles(2);

                tile_done = 1;
                @(posedge clk);
                tile_done = 0;

                //--------------------------------------------------
                // NEXT EXPECTED
                //--------------------------------------------------
                if ((exp_x + TILE_W) >= W) begin
                    exp_x = 0;
                    exp_y = exp_y + TILE_H;
                end else begin
                    exp_x = exp_x + TILE_W;
                end

                tile_count = tile_count + 1;

                @(posedge clk);
            end

            //--------------------------------------------------
            // FINAL
            //--------------------------------------------------
            if (!all_done)
                $display("ERROR: all_done not asserted!");
            else
                $display("PASS: Completed all tiles correctly!");

            wait_cycles(3);
        end
    endtask

    //--------------------------------------------------
    // TEST SEQUENCE
    //--------------------------------------------------
    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        tile_done = 0;

        wait_cycles(5);
        rst = 0;

        run_test(16, 8);
        run_test(16, 32);
        run_test(64, 8);
        run_test(32, 32);
        run_test(30, 20);

        $display("\nALL TESTS DONE\n");
        $finish;
    end

    //--------------------------------------------------
    // MONITOR
    //--------------------------------------------------
    initial begin
        $monitor("T=%0t | start=%b tile_start=%b done=%b | x=%0d y=%0d first=%b last=%b all_done=%b",
            $time, start, tile_start, tile_done,
            tile_x, tile_y, first_tile, last_tile, all_done);
    end

endmodule
