`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_XBAR(
    input clk,
    input rst,

    // AXI-lite arbiter -> xbar
    input arvalid_arbiter,
    input [`ysyx_24080020_WIDTH-1:0] araddr_arbiter,
    output reg arready_xbar,

    input rready_arbiter,
    output reg [`ysyx_24080020_WIDTH-1:0] rdata_xbar,
    output reg [1:0] rresp_xbar,
    output reg rvalid_xbar,

    input [`ysyx_24080020_WIDTH-1:0] awaddr_arbiter,
    input awvalid_arbiter,
    output reg awready_xbar,

    input [`ysyx_24080020_WIDTH-1:0] wdata_arbiter,
    input [3:0] wstrb_arbiter,
    input wvalid_arbiter,
    output reg wready_xbar,

    input bready_arbiter,
    output reg bvalid_xbar,
    output reg [1:0] bresp_xbar,

    // XBar -> slave1 -> SRAM
    output reg arvalid_xbar_sram,
    output reg [`ysyx_24080020_WIDTH-1:0] araddr_xbar_sram,
    input arready_sram,

    input [`ysyx_24080020_WIDTH-1:0] rdata_sram,
    input [1:0] rresp_sram,
    input rvalid_sram,
    output reg rready_xbar_sram,

    output reg [`ysyx_24080020_WIDTH-1:0] awaddr_xbar_sram,
    output reg awvalid_xbar_sram,
    input awready_sram,

    output reg [`ysyx_24080020_WIDTH-1:0] wdata_xbar_sram,
    output reg [3:0] wstrb_xbar_sram,
    output reg wvalid_xbar_sram,
    input wready_sram,

    input bvalid_sram,
    input [1:0] bresp_sram,
    output reg bready_xbar_sram,

    // Xbar -> slave2 -> UART
    output reg arvalid_xbar_uart,
    output reg [`ysyx_24080020_WIDTH-1:0] araddr_xbar_uart,
    input arready_uart,

    input [`ysyx_24080020_WIDTH-1:0] rdata_uart,
    input [1:0] rresp_uart,
    input rvalid_uart,
    output reg rready_xbar_uart,

    output reg [`ysyx_24080020_WIDTH-1:0] awaddr_xbar_uart,
    output reg awvalid_xbar_uart,
    input awready_uart,

    output reg [`ysyx_24080020_WIDTH-1:0] wdata_xbar_uart,
    output reg [3:0] wstrb_xbar_uart,
    output reg wvalid_xbar_uart,
    input wready_uart,

    input bvalid_uart,
    input [1:0] bresp_uart,
    output reg bready_xbar_uart
);
    /* Xbar target device
     * 3'd0: error
     * 3'd1: sram
     * 3'd2: uart
     * ...
    */
    wire [2:0] device_addr;

    assign device_addr =
        awvalid_arbiter == 1'b1 ?
            ((awaddr_arbiter >= `ysyx_24080020_MBASE) && (awaddr_arbiter < 32'h81000000)) ?
                3'd1
                :
                (awaddr_arbiter == `ysyx_24080020_SERIAL_PORT) ?
                    3'd2
                    :
                    3'd0
        :
            ((arvalid_arbiter == 1'b1) ?
                ((araddr_arbiter >= `ysyx_24080020_MBASE) && (araddr_arbiter < 32'h81000000)) ? 3'd1 :
                    (araddr_arbiter == `ysyx_24080020_SERIAL_PORT) ? 3'd2 : 3'd0
            :
            3'd0);

    /* AR: Xbar -> UART
                |
                -> SRAM
    */
    assign araddr_xbar_sram = device_addr == 3'd1 ? araddr_arbiter : 32'b0;
    assign arvalid_xbar_sram = device_addr == 3'd1 ? arvalid_arbiter : 1'b0;

    assign aradddr_xbar_uart = device_addr == 3'd2 ? araddr_arbiter : 32'b0;
    assign arvalid_xbar_uart = device_addr == 3'd2 ? arvalid_arbiter : 1'b0;

    assign arready_xbar = device_addr == 3'd1 ? arready_sram :
                          device_addr == 3'd2 ? arready_uart : 1'b0;


    /* R:  UART ---
                  |---> Xbar
           SRAM ---
    */
    assign rdata_xbar = device_addr == 3'd1 ? rdata_sram :
                        device_addr == 3'd2 ? rdata_uart : 32'b0;
    assign rresp_xbar = device_addr == 3'd1 ? rresp_sram :
                        device_addr == 3'd2 ? rresp_uart : 2'b0;
    assign rvalid_xbar = device_addr == 3'd1 ? rvalid_sram :
                         device_addr == 3'd2 ? rvalid_uart : 1'b0;
    assign rready_xbar_sram = device_addr == 3'd1 ? rready_arbiter : 1'b0;
    assign rready_xbar_uart = device_addr == 3'd2 ? rready_arbiter : 1'b0;

    /* AW: Xbar --> UART
                |
                -> SRAM
    */
    assign awaddr_xbar_sram = device_addr == 3'd1 ? awaddr_arbiter : 32'b0;
    assign awvalid_xbar_sram = device_addr == 3'd1 ? awvalid_arbiter : 1'b0;

    assign awaddr_xbar_uart = device_addr == 3'd2 ? awaddr_arbiter : 32'b0;
    assign awvalid_xbar_uart = device_addr == 3'd2 ? awvalid_arbiter : 1'b0;

    assign awready_xbar = device_addr == 3'd1 ? awready_sram :
                          device_addr == 3'd2 ? awready_uart : 1'b0;

    /* W: Xbar --> UART
                |
                -> SRAM
    */
    assign wdata_xbar_sram = device_addr == 3'd1 ? wdata_arbiter : 32'b0;
    assign wstrb_xbar_sram = device_addr == 3'd1 ? wstrb_arbiter : 4'b0;
    assign wvalid_xbar_sram = device_addr == 3'd1 ? wvalid_arbiter : 1'b0;

    assign wdata_xbar_uart = device_addr == 3'd2 ? wdata_arbiter : 32'b0;
    assign wstrb_xbar_uart = device_addr == 3'd2 ? wstrb_arbiter : 4'b0;
    assign wvalid_xbar_uart = device_addr == 3'd2 ? wvalid_arbiter : 1'b0;

    assign wready_xbar = device_addr == 3'd1 ? wready_sram :
                         device_addr == 3'd2 ? wready_uart : 1'b0;

    /* B: UART ---
                 |---> Xbar
          SRAM ---
    */
    assign bresp_xbar = device_addr == 3'd1 ? bresp_sram :
                        device_addr == 3'd2 ? bresp_uart : 2'b0;
    assign bvalid_xbar = device_addr == 3'd1 ? bvalid_sram :
                         device_addr == 3'd2 ? bvalid_uart : 1'b0;
    assign bready_xbar_sram = device_addr == 3'd1 ? bready_arbiter : 1'b0;
    assign bready_xbar_uart = device_addr == 3'd2 ? bready_arbiter : 1'b0;

endmodule
