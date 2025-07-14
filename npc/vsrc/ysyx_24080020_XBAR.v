`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_XBAR(
    input clk,
    input rst,

    // AXI-lite arbiter -> xbar
    input arvalid_arbiter,
    input [`ysyx_24080020_WIDTH-1:0] araddr_arbiter,
    input [3:0] arid_arbiter,
    input [7:0] arlen_arbiter,
    input [2:0] arsize_arbiter,
    input [1:0] arburst_arbiter,
    output reg arready_xbar,

    input rready_arbiter,
    output reg [`ysyx_24080020_WIDTH-1:0] rdata_xbar,
    output reg [1:0] rresp_xbar,
    output reg rvalid_xbar,
    output reg [3:0] rid_xbar,
    output reg rlast_xbar,

    input [`ysyx_24080020_WIDTH-1:0] awaddr_arbiter,
    input awvalid_arbiter,
    input [3:0] awid_arbiter,
    input [7:0] awlen_arbiter,
    input [2:0] awsize_arbiter,
    input [1:0] awburst_arbiter,
    output reg awready_xbar,

    input [`ysyx_24080020_WIDTH-1:0] wdata_arbiter,
    input [3:0] wstrb_arbiter,
    input wvalid_arbiter,
    input wlast_arbiter,
    output reg wready_xbar,

    input bready_arbiter,
    output reg bvalid_xbar,
    output reg [3:0] bid_xbar,
    output reg [1:0] bresp_xbar,


    // Xbar -> slave3 -> CLINT
    output reg arvalid_xbar_clint,
    output reg [`ysyx_24080020_WIDTH-1:0] araddr_xbar_clint,
    output reg [3:0] arid_xbar_clint,
    output reg [7:0] arlen_xbar_clint,
    output reg [2:0] arsize_xbar_clint,
    output reg [1:0] arburst_xbar_clint,
    input arready_clint,

    input [`ysyx_24080020_WIDTH-1:0] rdata_clint,
    input [1:0] rresp_clint,
    input rvalid_clint,
    input [3:0] rid_clint,
    input rlast_clint,
    output reg rready_xbar_clint,

    output reg [`ysyx_24080020_WIDTH-1:0] awaddr_xbar_clint,
    output reg awvalid_xbar_clint,
    output reg [3:0] awid_xbar_clint,
    output reg [7:0] awlen_xbar_clint,
    output reg [2:0] awsize_xbar_clint,
    output reg [1:0] awburst_xbar_clint,
    input awready_clint,

    output reg [`ysyx_24080020_WIDTH-1:0] wdata_xbar_clint,
    output reg [3:0] wstrb_xbar_clint,
    output reg wvalid_xbar_clint,
    output reg wlast_xbar_clint,
    input wready_clint,

    input bvalid_clint,
    input [1:0] bresp_clint,
    input [3:0] bid_clint,
    output reg bready_xbar_clint,

`ifdef ysyx_24080020_NPC
    // // XBar -> slave1 -> SRAM
    output reg arvalid_xbar_sram,
    output reg [`ysyx_24080020_WIDTH-1:0] araddr_xbar_sram,
    output reg [3:0] arid_xbar_sram,
    output reg [7:0] arlen_xbar_sram,
    output reg [2:0] arsize_xbar_sram,
    output reg [1:0] arburst_xbar_sram,
    input arready_sram,

    input [`ysyx_24080020_WIDTH-1:0] rdata_sram,
    input [1:0] rresp_sram,
    input rvalid_sram,
    input [3:0] rid_sram,
    input rlast_sram,
    output reg rready_xbar_sram,

    output reg [`ysyx_24080020_WIDTH-1:0] awaddr_xbar_sram,
    output reg awvalid_xbar_sram,
    output reg [3:0] awid_xbar_sram,
    output reg [7:0] awlen_xbar_sram,
    output reg [2:0] awsize_xbar_sram,
    output reg [1:0] awburst_xbar_sram,
    input awready_sram,

    output reg [`ysyx_24080020_WIDTH-1:0] wdata_xbar_sram,
    output reg [3:0] wstrb_xbar_sram,
    output reg wvalid_xbar_sram,
    output reg wlast_xbar_sram,
    input wready_sram,

    input bvalid_sram,
    input [1:0] bresp_sram,
    input [3:0] bid_sram,
    output reg bready_xbar_sram,



    // // Xbar -> slave2 -> UART
    output reg arvalid_xbar_uart,
    output reg [`ysyx_24080020_WIDTH-1:0] araddr_xbar_uart,
    output reg [3:0] arid_xbar_uart,
    output reg [7:0] arlen_xbar_uart,
    output reg [2:0] arsize_xbar_uart,
    output reg [1:0] arburst_xbar_uart,
    input arready_uart,

    input [`ysyx_24080020_WIDTH-1:0] rdata_uart,
    input [1:0] rresp_uart,
    input rvalid_uart,
    input [3:0] rid_uart,
    input rlast_uart,
    output reg rready_xbar_uart,

    output reg [`ysyx_24080020_WIDTH-1:0] awaddr_xbar_uart,
    output reg awvalid_xbar_uart,
    output reg [3:0] awid_xbar_uart,
    output reg [7:0] awlen_xbar_uart,
    output reg [2:0] awsize_xbar_uart,
    output reg [1:0] awburst_xbar_uart,
    input awready_uart,

    output reg [`ysyx_24080020_WIDTH-1:0] wdata_xbar_uart,
    output reg [3:0] wstrb_xbar_uart,
    output reg wvalid_xbar_uart,
    output reg wlast_xbar_uart,
    input wready_uart,

    input bvalid_uart,
    input [1:0] bresp_uart,
    input [3:0] bid_uart,
    output reg bready_xbar_uart
`endif


`ifdef ysyxSoCFull
    // XBar -> slave4 -> SOC
    output reg arvalid_xbar_soc,
    output reg [`ysyx_24080020_WIDTH-1:0] araddr_xbar_soc,
    output reg [3:0] arid_xbar_soc,
    output reg [7:0] arlen_xbar_soc,
    output reg [2:0] arsize_xbar_soc,
    output reg [1:0] arburst_xbar_soc,
    input arready_soc,

    input [`ysyx_24080020_WIDTH-1:0] rdata_soc,
    input [1:0] rresp_soc,
    input rvalid_soc,
    input [3:0] rid_soc,
    input rlast_soc,
    output reg rready_xbar_soc,

    output reg [`ysyx_24080020_WIDTH-1:0] awaddr_xbar_soc,
    output reg awvalid_xbar_soc,
    output reg [3:0] awid_xbar_soc,
    output reg [7:0] awlen_xbar_soc,
    output reg [2:0] awsize_xbar_soc,
    output reg [1:0] awburst_xbar_soc,
    input awready_soc,

    output reg [`ysyx_24080020_WIDTH-1:0] wdata_xbar_soc,
    output reg [3:0] wstrb_xbar_soc,
    output reg wvalid_xbar_soc,
    output reg wlast_xbar_soc,
    input wready_soc,

    input bvalid_soc,
    input [1:0] bresp_soc,
    input [3:0] bid_soc,
    output reg bready_xbar_soc
`endif
);
    /* Xbar target device
     * 3'd0: error
     * 3'd1: sram
     * 3'd2: uart
     * 3'd3: clint
     * 3'd4: soc
     * ...
    */

    wire arready_tmp, awready_tmp;
    reg ar_en, aw_en;
    reg arvalid_tmp, awvalid_tmp;

    reg [2:0] device_addr_next;
    reg [2:0] device_addr;

    /*
     *   if clint: -> clint
     *   else: -> soc
    */
    always @(awvalid_arbiter or arvalid_arbiter) begin
        if(awvalid_arbiter) begin
            device_addr = (awaddr_arbiter == `ysyx_24080020_CLINT_ADDR || awaddr_arbiter == `ysyx_24080020_CLINT_ADDR + 32'h4) ? 3'd3 :
                            `ifdef ysyx_24080020_NPC
                            (awaddr_arbiter >= `ysyx_24080020_MBASE && awaddr_arbiter < `ysyx_24080020_DEVICE_BASE) ? 3'd1 :
                            (awaddr_arbiter >= `ysyx_24080020_SERIAL_PORT && awaddr_arbiter < `ysyx_24080020_SERIAL_PORT + 32'h10) ? 3'd2 :
                            3'd0;
                            `endif
                            `ifdef ysyxSoCFull
                            3'd4;
                            `endif
        end
        else if(arvalid_arbiter) begin
            device_addr = (araddr_arbiter == `ysyx_24080020_CLINT_ADDR || araddr_arbiter == `ysyx_24080020_CLINT_ADDR + 32'h4) ? 3'd3 :
                            `ifdef ysyx_24080020_NPC
                            (araddr_arbiter >= `ysyx_24080020_MBASE && araddr_arbiter < `ysyx_24080020_DEVICE_BASE) ? 3'd1 :
                            (araddr_arbiter >= `ysyx_24080020_SERIAL_PORT && araddr_arbiter < `ysyx_24080020_SERIAL_PORT + 32'h10) ? 3'd2 :
                            3'd0;
                            `endif
                            `ifdef ysyxSoCFull
                            3'd4;
                            `endif
        end
        else begin
            device_addr = device_addr_next;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            device_addr_next <= 'b0;
        end
        else begin
            device_addr_next <= device_addr;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            ar_en <= 'b0;
            aw_en <= 'b0;
        end
        else if(arvalid_arbiter) begin
            arvalid_tmp <= 'b1;
        end
        else if(awvalid_arbiter) begin
            awvalid_tmp <= 'b1;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            arvalid_tmp <= 'b0;
            awvalid_tmp <= 'b0;
        end
        else if(arvalid_tmp && arready_tmp) begin
            arvalid_tmp <= 'b0;
        end
        else if(awvalid_tmp && awready_tmp) begin
            awvalid_tmp <= 'b0;
        end
    end

    /* AR: Xbar |-> SOC
                |-> CLINT
    */
    `ifdef ysyx_24080020_NPC
    assign araddr_xbar_sram = device_addr == 3'd1 ? araddr_arbiter : 32'b0;
    assign arvalid_xbar_sram = device_addr == 3'd1 ? arvalid_tmp : 1'b0;
    assign arburst_xbar_sram = device_addr == 3'd1 ? arburst_arbiter : 2'b0;
    assign arsize_xbar_sram = device_addr == 3'd1 ? arsize_arbiter : 3'b0;
    assign arlen_xbar_sram = device_addr == 3'd1 ? arlen_arbiter : 8'b0;
    assign arid_xbar_sram = device_addr == 3'd1 ? arid_arbiter : 4'b0;

    assign araddr_xbar_uart = device_addr == 3'd2 ? araddr_arbiter : 32'b0;
    assign arvalid_xbar_uart = device_addr == 3'd2 ? arvalid_tmp : 1'b0;
    assign arburst_xbar_uart = device_addr == 3'd2 ? arburst_arbiter : 2'b0;
    assign arsize_xbar_uart = device_addr == 3'd2 ? arsize_arbiter : 3'b0;
    assign arlen_xbar_uart = device_addr == 3'd2 ? arlen_arbiter : 8'b0;
    assign arid_xbar_uart = device_addr == 3'd2 ? arid_arbiter : 4'b0;
    `endif

    assign araddr_xbar_clint = device_addr == 3'd3 ? araddr_arbiter : 32'b0;
    assign arvalid_xbar_clint = device_addr == 3'd3 ? arvalid_tmp : 1'b0;
    assign arburst_xbar_clint = device_addr == 3'd3 ? arburst_arbiter : 2'b0;
    assign arsize_xbar_clint = device_addr == 3'd3 ? arsize_arbiter : 3'b0;
    assign arlen_xbar_clint = device_addr == 3'd3 ? arlen_arbiter : 8'b0;
    assign arid_xbar_clint = device_addr == 3'd3 ? arid_arbiter : 4'b0;

    `ifdef ysyxSoCFull
    assign araddr_xbar_soc = device_addr == 3'd4 ? araddr_arbiter : 32'b0;
    assign arvalid_xbar_soc = device_addr == 3'd4 ? arvalid_tmp : 1'b0;
    assign arburst_xbar_soc = device_addr == 3'd4 ? arburst_arbiter : 2'b0;
    assign arsize_xbar_soc = device_addr == 3'd4 ? arsize_arbiter : 3'b0;
    assign arlen_xbar_soc = device_addr == 3'd4 ? arlen_arbiter : 8'b0;
    assign arid_xbar_soc = device_addr == 3'd4 ? arid_arbiter : 4'b0;
    `endif

    assign arready_xbar = device_addr == 3'd3 ? arready_clint :
                          `ifdef ysyx_24080020_NPC
                          device_addr == 3'd1 ? arready_sram :
                          device_addr == 3'd2 ? arready_uart :
                          `endif
                          `ifdef ysyxSoCFull
                          device_addr == 3'd4 ? arready_soc :
                          `endif
                          1'b0;

    assign arready_tmp = arready_xbar;


    /* R:
           SRAM --- |
           UART --- |
           SOC  --- |
           CLINT ---|---> Xbar
    */
    assign rdata_xbar = device_addr == 3'd3 ? rdata_clint :
                        `ifdef ysyx_24080020_NPC
                        device_addr == 3'd1 ? rdata_sram :
                        device_addr == 3'd2 ? rdata_uart :
                        `endif
                        `ifdef ysyxSoCFull
                        device_addr == 3'd4 ? rdata_soc :
                        `endif
                        32'b0;
    assign rresp_xbar = device_addr == 3'd3 ? rresp_clint :
                        `ifdef ysyx_24080020_NPC
                        device_addr == 3'd1 ? rresp_sram :
                        device_addr == 3'd2 ? rresp_uart :
                        `endif
                        `ifdef ysyxSoCFull
                        device_addr == 3'd4 ? rresp_soc :
                        `endif
                        2'b0;
    assign rvalid_xbar = device_addr == 3'd3 ? rvalid_clint :
                        `ifdef ysyx_24080020_NPC
                        device_addr == 3'd1 ? rvalid_sram :
                        device_addr == 3'd2 ? rvalid_uart :
                        `endif
                        `ifdef ysyxSoCFull
                        device_addr == 3'd4 ? rvalid_soc :
                        `endif
                        1'b0;
    assign rid_xbar = device_addr == 3'd3 ? rid_clint :
                      `ifdef ysyx_24080020_NPC
                      device_addr == 3'd1 ? rid_sram :
                      device_addr == 3'd2 ? rid_uart :
                      `endif
                      `ifdef ysyxSoCFull
                      device_addr == 3'd4 ? rid_soc :
                      `endif
                      4'b0;
    assign rlast_xbar = device_addr == 3'd3 ? rlast_clint :
                        `ifdef ysyx_24080020_NPC
                        device_addr == 3'd1 ? rlast_sram :
                        device_addr == 3'd2 ? rlast_uart :
                        `endif
                        `ifdef ysyxSoCFull
                        device_addr == 3'd4 ? rlast_soc :
                        `endif
                        1'b0;
    `ifdef ysyx_24080020_NPC
    assign rready_xbar_sram = device_addr == 3'd1 ? rready_arbiter : 1'b0;
    assign rready_xbar_uart = device_addr == 3'd2 ? rready_arbiter : 1'b0;
    `endif
    assign rready_xbar_clint = device_addr == 3'd3 ? rready_arbiter : 1'b0;
    `ifdef ysyxSoCFull
    assign rready_xbar_soc = device_addr == 3'd4 ? rready_arbiter : 1'b0;
    `endif

    /* AW: Xbar |-> SOC
                |-> CLINT
    */
    `ifdef ysyx_24080020_NPC
    assign awaddr_xbar_sram = device_addr == 3'd1 ? awaddr_arbiter : 32'b0;
    assign awvalid_xbar_sram = device_addr == 3'd1 ? awvalid_tmp : 1'b0;
    assign awburst_xbar_sram = device_addr == 3'd1 ? awburst_arbiter : 2'b0;
    assign awsize_xbar_sram = device_addr == 3'd1 ? awsize_arbiter : 3'b0;
    assign awlen_xbar_sram = device_addr == 3'd1 ? awlen_arbiter : 8'b0;
    assign awid_xbar_sram = device_addr == 3'd1 ? awid_arbiter : 4'b0;

    assign awaddr_xbar_uart = device_addr == 3'd2 ? awaddr_arbiter : 32'b0;
    assign awvalid_xbar_uart = device_addr == 3'd2 ? awvalid_tmp : 1'b0;
    assign awburst_xbar_uart = device_addr == 3'd2 ? awburst_arbiter : 2'b0;
    assign awsize_xbar_uart = device_addr == 3'd2 ? awsize_arbiter : 3'b0;
    assign awlen_xbar_uart = device_addr == 3'd2 ? awlen_arbiter : 8'b0;
    assign awid_xbar_uart = device_addr == 3'd2 ? awid_arbiter : 4'b0;
    `endif

    assign awaddr_xbar_clint = device_addr == 3'd3 ? awaddr_arbiter : 32'b0;
    assign awvalid_xbar_clint = device_addr == 3'd3 ? awvalid_tmp : 1'b0;
    assign awburst_xbar_clint = device_addr == 3'd3 ? awburst_arbiter : 2'b0;
    assign awsize_xbar_clint = device_addr == 3'd3 ? awsize_arbiter : 3'b0;
    assign awlen_xbar_clint = device_addr == 3'd3 ? awlen_arbiter : 8'b0;
    assign awid_xbar_clint = device_addr == 3'd3 ? awid_arbiter : 4'b0;

    `ifdef ysyxSoCFull
    assign awaddr_xbar_soc = device_addr == 3'd4 ? awaddr_arbiter : 32'b0;
    assign awvalid_xbar_soc = device_addr == 3'd4 ? awvalid_tmp : 1'b0;
    assign awburst_xbar_soc = device_addr == 3'd4 ? awburst_arbiter : 2'b0;
    assign awsize_xbar_soc = device_addr == 3'd4 ? awsize_arbiter : 3'b0;
    assign awlen_xbar_soc = device_addr == 3'd4 ? awlen_arbiter : 8'b0;
    assign awid_xbar_soc = device_addr == 3'd4 ? awid_arbiter : 4'b0;
    `endif

    assign awready_xbar = device_addr == 3'd3 ? awready_clint :
                          `ifdef ysyx_24080020_NPC
                          device_addr == 3'd1 ? awready_sram :
                          device_addr == 3'd2 ? awready_uart :
                          `endif
                          `ifdef ysyxSoCFull
                          device_addr == 3'd4 ? awready_soc :
                          `endif
                          1'b0;

    assign awready_tmp = awready_xbar;

    /* W: Xbar  |-> SOC
                |-> CLINT
    */
    `ifdef ysyx_24080020_NPC
    assign wdata_xbar_sram = device_addr == 3'd1 ? wdata_arbiter : 32'b0;
    assign wstrb_xbar_sram = device_addr == 3'd1 ? wstrb_arbiter : 4'b0;
    assign wvalid_xbar_sram = device_addr == 3'd1 ? wvalid_arbiter : 1'b0;
    assign wlast_xbar_sram = device_addr == 3'd1 ? wlast_arbiter : 1'b0;

    assign wdata_xbar_uart = device_addr == 3'd2 ? wdata_arbiter : 32'b0;
    assign wstrb_xbar_uart = device_addr == 3'd2 ? wstrb_arbiter : 4'b0;
    assign wvalid_xbar_uart = device_addr == 3'd2 ? wvalid_arbiter : 1'b0;
    assign wlast_xbar_uart = device_addr == 3'd2 ? wlast_arbiter : 1'b0;
    `endif

    assign wdata_xbar_clint = device_addr == 3'd3 ? wdata_arbiter : 32'b0;
    assign wstrb_xbar_clint = device_addr == 3'd3 ? wstrb_arbiter : 4'b0;
    assign wvalid_xbar_clint = device_addr == 3'd3 ? wvalid_arbiter : 1'b0;
    assign wlast_xbar_clint = device_addr == 3'd3 ? wlast_arbiter : 1'b0;

    `ifdef ysyxSoCFull
    assign wdata_xbar_soc = device_addr == 3'd4 ? wdata_arbiter : 32'b0;
    assign wstrb_xbar_soc = device_addr == 3'd4 ? wstrb_arbiter : 4'b0;
    assign wvalid_xbar_soc = device_addr == 3'd4 ? wvalid_arbiter : 1'b0;
    assign wlast_xbar_soc = device_addr == 3'd4 ? wlast_arbiter : 1'b0;
    `endif

    assign wready_xbar = device_addr == 3'd3 ? wready_clint :
                        `ifdef ysyx_24080020_NPC
                        device_addr == 3'd1 ? wready_sram :
                        device_addr == 3'd2 ? wready_uart :
                        `endif
                        `ifdef ysyxSoCFull
                         device_addr == 3'd4 ? wready_soc :
                        `endif
                         1'b0;

    /* B: SOC  ----|
          CLINT ---|---> Xbar
    */
    assign bresp_xbar = device_addr == 3'd3 ? bresp_clint :
                        `ifdef ysyx_24080020_NPC
                        device_addr == 3'd1 ? bresp_sram :
                        device_addr == 3'd2 ? bresp_uart :
                        `endif
                        `ifdef ysyxSoCFull
                        device_addr == 3'd4 ? bresp_soc :
                        `endif
                        2'b0;
    assign bvalid_xbar = device_addr == 3'd3 ? bvalid_clint :
                        `ifdef ysyx_24080020_NPC
                        device_addr == 3'd1 ? bvalid_sram :
                        device_addr == 3'd2 ? bvalid_uart :
                        `endif
                        `ifdef ysyxSoCFull
                        device_addr == 3'd4 ? bvalid_soc :
                        `endif
                         1'b0;
    assign bid_xbar = device_addr == 3'd3 ? bid_clint :
                        `ifdef ysyx_24080020_NPC
                        device_addr == 3'd1 ? bid_sram :
                        device_addr == 3'd2 ? bid_uart :
                        `endif
                        `ifdef ysyxSoCFull
                        device_addr == 3'd4 ? bid_soc :
                        `endif
                        4'b0;

    `ifdef ysyx_24080020_NPC
    assign bready_xbar_sram = device_addr == 3'd1 ? bready_arbiter : 1'b0;
    assign bready_xbar_uart = device_addr == 3'd2 ? bready_arbiter : 1'b0;
    `endif
    assign bready_xbar_clint = device_addr == 3'd3 ? bready_arbiter : 1'b0;
    `ifdef ysyxSoCFull
    assign bready_xbar_soc = device_addr == 3'd4 ? bready_arbiter : 1'b0;
    `endif

endmodule
