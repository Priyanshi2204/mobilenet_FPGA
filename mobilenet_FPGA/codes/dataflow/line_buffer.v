module line_buffer #(
    parameter DATA_W = 16,
    parameter WIDTH  = 416
)(
    input  wire clk,
    input  wire rst_n,

    input  wire [DATA_W-1:0] pixel_in,
    input  wire              valid_in,

    output reg [DATA_W-1:0] row0,
    output reg [DATA_W-1:0] row1,
    output reg [DATA_W-1:0] row2

);
// =====================================================
    // Line memories (2 previous rows)
    // =====================================================

    (* ram_style = "block" *)
    reg [DATA_W-1:0] line0 [0:WIDTH-1];

    (* ram_style = "block" *)
    reg [DATA_W-1:0] line1 [0:WIDTH-1];
      // =====================================================
    // Column pointer
    // =====================================================

    reg [$clog2(WIDTH)-1:0] col_ptr;
    
     // =====================================================
    // Main logic
    // =====================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_ptr <= 0;
            row0    <= 0;
            row1    <= 0;
            row2    <= 0;
        end
        else if (valid_in) begin

            //------------------------------------------------
            // Read taps
            //------------------------------------------------
            row0 <= line0[col_ptr];
            row1 <= line1[col_ptr];
            row2 <= pixel_in;
             //------------------------------------------------
            // Shift line buffers
            //------------------------------------------------
            line0[col_ptr] <= line1[col_ptr];
            line1[col_ptr] <= pixel_in;

            //------------------------------------------------
            // Column update
            //------------------------------------------------
            if (col_ptr == WIDTH-1)
                col_ptr <= 0;
            else
                col_ptr <= col_ptr + 1;
        end
    end

endmodule