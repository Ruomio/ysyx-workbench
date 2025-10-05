`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_ARBITER (
    input clk,
    input rst,

    // master-1 ifu
    input arvalid_ifu,
    input [`ysyx_24080020_WIDTH-1:0] araddr_ifu,
    input [3:0] arid_ifu,
    input [7:0] arlen_ifu,
    input [2:0] arsize_ifu,
    input [1:0] arburst_ifu,
    output arready_ifu,

    input rready_ifu,
    output [3:0] rid_ifu,
    output rlast_ifu,
    output [`ysyx_24080020_WIDTH-1:0] rdata_ifu,
    output [1:0] rresp_ifu,
    output rvalid_ifu,
    // ifu there isn't AW, W, B

    // master-2 mem
    input arvalid_mem,
    input [`ysyx_24080020_WIDTH-1:0] araddr_mem,
    input [3:0] arid_mem,
    input [7:0] arlen_mem,
    input [2:0] arsize_mem,
    input [1:0] arburst_mem,
    output arready_mem,

    input rready_mem,
    output [`ysyx_24080020_WIDTH-1:0] rdata_mem,
    output [3:0] rid_mem,
    output rlast_mem,
    output [1:0] rresp_mem,
    output rvalid_mem,

    input [`ysyx_24080020_WIDTH-1:0] awaddr_mem,
    input awvalid_mem,
    input [3:0] awid_mem,
    input [7:0] awlen_mem,
    input [2:0] awsize_mem,
    input [1:0] awburst_mem,
    output awready_mem,

    input [`ysyx_24080020_WIDTH-1:0] wdata_mem,
    input [3:0] wstrb_mem,
    input wvalid_mem,
    input wlast_mem,
    output wready_mem,

    output [1:0] bresp_mem,
    output bvalid_mem,
    output [3:0] bid_mem,
    input bready_mem,

    // arbiter deside
    output arvalid_arbiter,
    output [`ysyx_24080020_WIDTH-1:0] araddr_arbiter,
    output [3:0] arid_arbiter,
    output [7:0] arlen_arbiter,
    output [2:0] arsize_arbiter,
    output [1:0] arburst_arbiter,
    input arready_xbar,

    input [`ysyx_24080020_WIDTH-1:0] rdata_xbar,
    input [1:0] rresp_xbar,
    input rvalid_xbar,
    input [3:0] rid_xbar,
    input rlast_xbar,
    output rready_arbiter,

    output [`ysyx_24080020_WIDTH-1:0] awaddr_arbiter,
    output awvalid_arbiter,
    output [3:0] awid_arbiter,
    output [7:0] awlen_arbiter,
    output [2:0] awsize_arbiter,
    output [1:0] awburst_arbiter,
    input awready_xbar,

    output [`ysyx_24080020_WIDTH-1:0] wdata_arbiter,
    output [3:0] wstrb_arbiter,
    output wvalid_arbiter,
    output wlast_arbiter,
    input wready_xbar,

    input [1:0] bresp_xbar,
    input bvalid_xbar,
    input [3:0] bid_xbar,
    output bready_arbiter
);
  wire [2:0] max_cnt;
  reg [2:0] ifu_wait_cnt;
  reg [2:0] mem_wait_cnt;

  reg ifu_or_mem;
  reg wait_rdata;
  reg ar_tmp;

  reg busy;

  assign max_cnt = 3'd7;

  always @(posedge clk) begin
      if(!rst) begin
          busy <= 'b0;
      end
      else if(rvalid_ifu && rready_ifu && rlast_ifu) begin
          busy <= 'b0;
      end
      else if(rvalid_mem && rready_mem && rlast_mem) begin
          busy <= 'b0;
      end
      else if (arvalid_ifu && !arvalid_mem && !busy) begin
        busy <= 'b1;
      end else if (arvalid_mem && !arvalid_ifu && !busy) begin
        busy <= 'b1;
      end else if(arvalid_ifu && arvalid_mem && !busy) begin
        busy <= 'b1;
      end
  end


  always @(posedge clk) begin
    if (!rst) begin
      ifu_or_mem   <= 1'b0;
      ifu_wait_cnt <= 3'b0;
      mem_wait_cnt <= 3'b0;
    end else if (ifu_wait_cnt == max_cnt) begin
      ifu_or_mem   <= 1'b0;

      ifu_wait_cnt <= 3'b0;
    end else if (mem_wait_cnt == max_cnt) begin
      ifu_or_mem   <= 1'b1;

      mem_wait_cnt <= 3'b0;
    end else if (arvalid_ifu && !arvalid_mem && !busy) begin
      ifu_or_mem   <= 1'b0;

      ifu_wait_cnt <= 3'b0;
      // mem_wait_cnt <= mem_wait_cnt + 3'b1;
    end else if (arvalid_mem && !arvalid_ifu && !busy) begin
      ifu_or_mem   <= 1'b1;

      mem_wait_cnt <= 3'b0;
      // ifu_wait_cnt <= ifu_wait_cnt + 3'b1;
    end else if(arvalid_ifu && arvalid_mem && !busy) begin
      // both high level
      ifu_or_mem <= ifu_or_mem;
      if (!ifu_or_mem) mem_wait_cnt <= mem_wait_cnt + 3'b1;
      else ifu_wait_cnt <= ifu_wait_cnt + 3'b1;
    end
  end

  // AR
  assign arvalid_arbiter = ifu_or_mem == 1'b0 ? arvalid_ifu : arvalid_mem;
  assign araddr_arbiter = ifu_or_mem == 1'b0 ? araddr_ifu : araddr_mem;
  assign arid_arbiter = ifu_or_mem == 1'b0 ? arid_ifu : arid_mem;
  assign arsize_arbiter = ifu_or_mem == 1'b0 ? arsize_ifu : arsize_mem;
  assign arlen_arbiter = ifu_or_mem == 1'b0 ? arlen_ifu : arlen_mem;
  assign arburst_arbiter = ifu_or_mem == 1'b0 ? arburst_ifu : arburst_mem;

  assign arready_ifu = ifu_or_mem == 1'b0 ? arready_xbar : 1'b0;
  assign arready_mem = ifu_or_mem == 1'b0 ? 1'b0 : arready_xbar;

  // R
  assign rready_arbiter = ifu_or_mem == 1'b0 ? rready_ifu : rready_mem;

  assign rdata_ifu = ifu_or_mem == 1'b0 ? rdata_xbar : 32'b0;
  assign rresp_ifu = ifu_or_mem == 1'b0 ? rresp_xbar : 2'b0;
  assign rvalid_ifu = ifu_or_mem == 1'b0 ? rvalid_xbar : 1'b0;
  assign rid_ifu = ifu_or_mem == 1'b0 ? rid_xbar : 4'b0;
  assign rlast_ifu = ifu_or_mem == 1'b0 ? rlast_xbar : 1'b0;

  assign rdata_mem = ifu_or_mem == 1'b0 ? 32'b0 : rdata_xbar;
  assign rresp_mem = ifu_or_mem == 1'b0 ? 2'b0 : rresp_xbar;
  assign rvalid_mem = ifu_or_mem == 1'b0 ? 1'b0 : rvalid_xbar;
  assign rid_mem = ifu_or_mem == 1'b0 ? 4'b0 : rid_xbar;
  assign rlast_mem = ifu_or_mem == 1'b0 ? 1'b1 : rlast_xbar;

  // AW
  assign awvalid_arbiter = awvalid_mem;
  assign awaddr_arbiter = awaddr_mem;
  assign awburst_arbiter = awburst_mem;
  assign awsize_arbiter = awsize_mem;
  assign awid_arbiter = awid_mem;
  assign awlen_arbiter = awlen_mem;

  assign awready_mem = awready_xbar;

  // W
  assign wdata_arbiter = wdata_mem;
  assign wstrb_arbiter = wstrb_mem;
  assign wvalid_arbiter = wvalid_mem;
  assign wlast_arbiter = wlast_mem;

  assign wready_mem = wready_xbar;

  // B
  assign bready_arbiter = bready_mem;
  assign bresp_mem = bresp_xbar;
  assign bvalid_mem = bvalid_xbar;
  assign bid_mem = bid_xbar;
endmodule
