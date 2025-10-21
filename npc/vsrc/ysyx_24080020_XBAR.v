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
    output arready_xbar,

    input rready_arbiter,
    output [`ysyx_24080020_WIDTH-1:0] rdata_xbar,
    output [1:0] rresp_xbar,
    output rvalid_xbar,
    output [3:0] rid_xbar,
    output rlast_xbar,

    input [`ysyx_24080020_WIDTH-1:0] awaddr_arbiter,
    input awvalid_arbiter,
    input [3:0] awid_arbiter,
    input [7:0] awlen_arbiter,
    input [2:0] awsize_arbiter,
    input [1:0] awburst_arbiter,
    output awready_xbar,

    input [`ysyx_24080020_WIDTH-1:0] wdata_arbiter,
    input [3:0] wstrb_arbiter,
    input wvalid_arbiter,
    input wlast_arbiter,
    output wready_xbar,

    input bready_arbiter,
    output bvalid_xbar,
    output [3:0] bid_xbar,
    output [1:0] bresp_xbar,


    // Xbar -> slave3 -> CLINT
    output arvalid_xbar_clint,
    output [`ysyx_24080020_WIDTH-1:0] araddr_xbar_clint,
    output [3:0] arid_xbar_clint,
    output [7:0] arlen_xbar_clint,
    output [2:0] arsize_xbar_clint,
    output [1:0] arburst_xbar_clint,
    input arready_clint,

    input [`ysyx_24080020_WIDTH-1:0] rdata_clint,
    input [1:0] rresp_clint,
    input rvalid_clint,
    input [3:0] rid_clint,
    input rlast_clint,
    output rready_xbar_clint,

    output [`ysyx_24080020_WIDTH-1:0] awaddr_xbar_clint,
    output awvalid_xbar_clint,
    output [3:0] awid_xbar_clint,
    output [7:0] awlen_xbar_clint,
    output [2:0] awsize_xbar_clint,
    output [1:0] awburst_xbar_clint,
    input awready_clint,

    output [`ysyx_24080020_WIDTH-1:0] wdata_xbar_clint,
    output [3:0] wstrb_xbar_clint,
    output wvalid_xbar_clint,
    output wlast_xbar_clint,
    input wready_clint,

    input bvalid_clint,
    input [1:0] bresp_clint,
    input [3:0] bid_clint,
    output bready_xbar_clint,

    // XBar -> slave4 -> SOC
    output arvalid_xbar_soc,
    output [`ysyx_24080020_WIDTH-1:0] araddr_xbar_soc,
    output [3:0] arid_xbar_soc,
    output [7:0] arlen_xbar_soc,
    output [2:0] arsize_xbar_soc,
    output [1:0] arburst_xbar_soc,
    input arready_soc,

    input [`ysyx_24080020_WIDTH-1:0] rdata_soc,
    input [1:0] rresp_soc,
    input rvalid_soc,
    input [3:0] rid_soc,
    input rlast_soc,
    output rready_xbar_soc,

    output [`ysyx_24080020_WIDTH-1:0] awaddr_xbar_soc,
    output awvalid_xbar_soc,
    output [3:0] awid_xbar_soc,
    output [7:0] awlen_xbar_soc,
    output [2:0] awsize_xbar_soc,
    output [1:0] awburst_xbar_soc,
    input awready_soc,

    output [`ysyx_24080020_WIDTH-1:0] wdata_xbar_soc,
    output [3:0] wstrb_xbar_soc,
    output wvalid_xbar_soc,
    output wlast_xbar_soc,
    input wready_soc,

    input bvalid_soc,
    input [1:0] bresp_soc,
    input [3:0] bid_soc,
    output bready_xbar_soc
);
    /* Xbar target device
     * 'd0: clint
     * 'd1: soc
     * ...
    */


    reg r_device_addr;
    reg w_device_addr;

    /*
     *   if clint: -> clint
     *   else: -> soc
    */
    // always @(awvalid_arbiter or arvalid_arbiter or rvalid_xbar or rready_arbiter or rlast_xbar or bvalid_xbar or bready_arbiter) begin
    always @(posedge clk) begin
        if(!rst) begin
            r_device_addr <= 'b0;
        end
        else if(arvalid_arbiter) begin
            r_device_addr <= (araddr_arbiter == `ysyx_24080020_CLINT_ADDR
                || araddr_arbiter == (`ysyx_24080020_CLINT_ADDR | 32'h4)) ? 'd0 : 'd1;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            w_device_addr <= 'b0;
        end
        else if(awvalid_arbiter) begin
            w_device_addr <= (awaddr_arbiter == `ysyx_24080020_CLINT_ADDR
                || awaddr_arbiter == (`ysyx_24080020_CLINT_ADDR | 32'h4)) ? 'd0 : 'd1;
        end
    end



    /* AR: Xbar |-> SOC
                |-> CLINT
    */

    assign arvalid_xbar_clint = r_device_addr   == 'd0 ? arvalid_arbiter : 1'b0;
    assign araddr_xbar_clint = r_device_addr    == 'd0 ? araddr_arbiter : 'h0;
    assign arburst_xbar_clint = r_device_addr   == 'd0 ? arburst_arbiter : 'b0;
    assign arsize_xbar_clint = r_device_addr    == 'd0 ? arsize_arbiter : 'b0;
    assign arlen_xbar_clint = r_device_addr     == 'd0 ? arlen_arbiter : 'h0;
    assign arid_xbar_clint = r_device_addr      == 'd0 ? arid_arbiter : 'h0;

    assign arvalid_xbar_soc = r_device_addr    == 'd1 ? arvalid_arbiter : 1'b0;
    assign araddr_xbar_soc = r_device_addr     == 'd1 ? araddr_arbiter : 'h0;
    assign arburst_xbar_soc = r_device_addr    == 'd1 ? arburst_arbiter : 'b0;
    assign arsize_xbar_soc = r_device_addr     == 'd1 ? arsize_arbiter : 'b0;
    assign arlen_xbar_soc = r_device_addr      == 'd1 ? arlen_arbiter : 'h0;
    assign arid_xbar_soc = r_device_addr       == 'd1 ? arid_arbiter : 'h0;

    assign arready_xbar = r_device_addr        == 'd0 ? arready_clint : arready_soc;



    assign rdata_xbar = r_device_addr        == 'd0 ? rdata_clint : rdata_soc;
    assign rresp_xbar = r_device_addr        == 'd0 ? rresp_clint : rresp_soc;
    assign rvalid_xbar = r_device_addr       == 'd0 ? rvalid_clint : rvalid_soc;
    assign rid_xbar = r_device_addr          == 'd0 ? rid_clint : rid_soc;
    assign rlast_xbar = r_device_addr        == 'd0 ? rlast_clint : rlast_soc;

    assign rready_xbar_clint = r_device_addr == 'd0 ? rready_arbiter : 1'b0;
    assign rready_xbar_soc = r_device_addr   == 'd1 ? rready_arbiter : 1'b0;

    assign awaddr_xbar_clint = w_device_addr    == 'd0 ? awaddr_arbiter : 32'b0;
    assign awvalid_xbar_clint = w_device_addr   == 'd0 ? awvalid_arbiter : 1'b0;
    assign awburst_xbar_clint = w_device_addr   == 'd0 ? awburst_arbiter : 2'b0;
    assign awsize_xbar_clint = w_device_addr    == 'd0 ? awsize_arbiter : 3'b0;
    assign awlen_xbar_clint = w_device_addr     == 'd0 ? awlen_arbiter : 8'b0;
    assign awid_xbar_clint = w_device_addr      == 'd0 ? awid_arbiter : 4'b0;

    assign awaddr_xbar_soc = w_device_addr       == 'd1 ? awaddr_arbiter : 32'b0;
    assign awvalid_xbar_soc = w_device_addr      == 'd1 ? awvalid_arbiter : 1'b0;
    assign awburst_xbar_soc = w_device_addr      == 'd1 ? awburst_arbiter : 2'b0;
    assign awsize_xbar_soc = w_device_addr       == 'd1 ? awsize_arbiter : 3'b0;
    assign awlen_xbar_soc = w_device_addr        == 'd1 ? awlen_arbiter : 8'b0;
    assign awid_xbar_soc = w_device_addr         == 'd1 ? awid_arbiter : 4'b0;

    assign awready_xbar = w_device_addr         == 'd0 ? awready_clint : awready_soc;


    assign wdata_xbar_clint = w_device_addr     == 'd0 ? wdata_arbiter : 32'b0;
    assign wstrb_xbar_clint = w_device_addr     == 'd0 ? wstrb_arbiter : 4'b0;
    assign wvalid_xbar_clint = w_device_addr    == 'd0 ? wvalid_arbiter : 1'b0;
    assign wlast_xbar_clint = w_device_addr     == 'd0 ? wlast_arbiter : 1'b0;

    assign wdata_xbar_soc = w_device_addr       == 'd1 ? wdata_arbiter : 32'b0;
    assign wstrb_xbar_soc = w_device_addr       == 'd1 ? wstrb_arbiter : 4'b0;
    assign wvalid_xbar_soc = w_device_addr      == 'd1 ? wvalid_arbiter : 1'b0;
    assign wlast_xbar_soc = w_device_addr       == 'd1 ? wlast_arbiter : 1'b0;

    assign wready_xbar = w_device_addr          == 'd0 ? wready_clint : wready_soc;

    assign bresp_xbar = w_device_addr           == 'd0 ? bresp_clint : bresp_soc;
    assign bvalid_xbar = w_device_addr          == 'd0 ? bvalid_clint : bvalid_soc;
    assign bid_xbar = w_device_addr             == 'd0 ? bid_clint : bid_soc;

    assign bready_xbar_clint = w_device_addr    == 'd0 ? bready_arbiter : 1'b0;
    assign bready_xbar_soc = w_device_addr      == 'd1 ? bready_arbiter : 1'b0;

endmodule
