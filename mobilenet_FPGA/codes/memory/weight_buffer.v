`timescale 1ns / 1ps

module weight_buffer #(
    parameter WR_DATA_W = 64,
    parameter DATA_W    = 16,
    parameter PAR       = 9,
    parameter ADDR_W    = 10,
    parameter DEPTH     = 1024
)(
    input  wire clk,
    input  wire rst_n,

    input  wire [WR_DATA_W-1:0] wr_data,
    input  wire                 wr_en,
    input  wire [ADDR_W-1:0]    wr_addr,

    input  wire [ADDR_W-1:0]    rd_addr,
    output reg  [PAR*DATA_W-1:0] weight_vec
);

(* ram_style = "block" *)
reg [PAR*DATA_W-1:0] mem [0:DEPTH-1];

integer i;

//////////////////////////////////////////////////////////
// Initialize memory
//////////////////////////////////////////////////////////

initial begin
    for(i=0;i<DEPTH;i=i+1)
        mem[i] = 0;
end

//////////////////////////////////////////////////////////
// Write weights (pack 9 weights into mem[0])
//////////////////////////////////////////////////////////

always @(posedge clk)
begin
    if(wr_en)
    begin
        case(wr_addr)

        0: mem[0][63:0]     <= wr_data;
        1: mem[0][127:64]   <= wr_data;
        2: mem[0][143:128]  <= wr_data[15:0];

        default: ;

        endcase
    end
end

//////////////////////////////////////////////////////////
// Read weights
//////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        weight_vec <= 0;
    else
        weight_vec <= mem[rd_addr];
end

endmodule