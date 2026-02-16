module axi_master_ofm #(

    parameter AXI_ADDR_W = 32,
    parameter AXI_DATA_W = 128,
    parameter BUF_ADDR_W = 10,
    parameter BURST_LEN  = 128

)(
    input  wire clk,
    input  wire rst_n,

    //--------------------------------------------------
    // Control
    //--------------------------------------------------
    input  wire start_write,
    input  wire [AXI_ADDR_W-1:0] base_addr,
    output reg  done,

    //--------------------------------------------------
    // AXI WRITE ADDRESS CHANNEL
    //--------------------------------------------------
    output reg  [AXI_ADDR_W-1:0] awaddr,
    output reg                   awvalid,
    input  wire                  awready,

    output reg  [7:0]            awlen,
    output reg  [2:0]            awsize,
    output reg  [1:0]            awburst,

    //--------------------------------------------------
    // AXI WRITE DATA CHANNEL
    //--------------------------------------------------
    output reg  [AXI_DATA_W-1:0] wdata,
    output reg                   wvalid,
    input  wire                  wready,
    output reg                   wlast,
    output reg  [(AXI_DATA_W/8)-1:0] wstrb,

    //--------------------------------------------------
    // AXI WRITE RESPONSE
    //--------------------------------------------------
    input  wire bvalid,
    output reg  bready,

    //--------------------------------------------------
    // OFM BUFFER READ PORT
    //--------------------------------------------------
    output reg  [BUF_ADDR_W-1:0] rd_addr,
    input  wire [AXI_DATA_W-1:0] axi_out_data,
    input  wire [(AXI_DATA_W/8)-1:0] axi_wstrb
);
