`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_ARBITER (
    input clk,
    input rst,

    // master-1 ifu
    input arvalid_ifu,
    input [`ysyx_24080020_WIDTH-1:0] araddr_ifu,
    output reg arready_ifu,

    input rready_ifu,
    output reg [`ysyx_24080020_WIDTH-1:0] rdata_ifu,
    output reg [1:0] rresp_ifu,
    output reg rvalid_ifu,
    // ifu there isn't AW, W, B

    // master-2 mem
    input arvalid_mem,
    input [`ysyx_24080020_WIDTH-1:0] araddr_mem,
    output reg arready_mem,

    input rready_mem,
    output reg [`ysyx_24080020_WIDTH-1:0] rdata_mem,
    output reg [1:0] rresp_mem,
    output reg rvalid_mem,

    input [`ysyx_24080020_WIDTH-1:0] awaddr_mem,
    input awvalid_mem,
    output reg awready_arbiter,

    input [`ysyx_24080020_WIDTH-1:0] wdata_mem,
    input [3:0] wstrb_mem,
    input wvalid_mem,
    output reg wready_arbiter,

    output reg [1:0] bresp_arbiter,
    output reg bvalid_arbiter,
    input bready_mem,

    // arbiter deside
    output reg arvalid_arbiter,
    output reg [`ysyx_24080020_WIDTH-1:0] araddr_arbiter,
    input arready_xbar,

    input [`ysyx_24080020_WIDTH-1:0] rdata_xbar,
    input [1:0] rresp_xbar,
    input rvalid_xbar,
    output reg rready_arbiter,

    output reg [`ysyx_24080020_WIDTH-1:0] awaddr_arbiter,
    output reg awvalid_arbiter,
    input awready_xbar,

    output reg [`ysyx_24080020_WIDTH-1:0] wdata_arbiter,
    output reg [3:0] wstrb_arbiter,
    output reg wvalid_arbiter,
    input wready_xbar,

    input [1:0] bresp_xbar,
    input bvalid_xbar,
    output reg bready_arbiter
);
  wire [2:0] max_cnt;
  reg [2:0] ifu_wait_cnt;
  reg [2:0] mem_wait_cnt;

  reg ifu_or_mem;
  reg wait_rdata;
  reg ar_tmp;

  assign max_cnt = 3'd7;


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
    end else if (arvalid_ifu && !arvalid_mem) begin
      ifu_or_mem   <= 1'b0;

      ifu_wait_cnt <= 3'b0;
      // mem_wait_cnt <= mem_wait_cnt + 3'b1;
    end else if (arvalid_mem && !arvalid_ifu) begin
      ifu_or_mem   <= 1'b1;

      mem_wait_cnt <= 3'b0;
      // ifu_wait_cnt <= ifu_wait_cnt + 3'b1;
    end else if (!arvalid_ifu && !arvalid_mem) begin
      // shake hands success and set arvalid low
      ifu_or_mem <= ifu_or_mem;
    end else begin
      // both high level
      ifu_or_mem <= ifu_or_mem;
      if (!ifu_or_mem) mem_wait_cnt <= mem_wait_cnt + 3'b1;
      else ifu_wait_cnt <= ifu_wait_cnt + 3'b1;
    end
  end

  // AR
  assign arvalid_arbiter = ifu_or_mem == 1'b0 ? arvalid_ifu : arvalid_mem;
  assign araddr_arbiter = ifu_or_mem == 1'b0 ? araddr_ifu : araddr_mem;
  assign arready_ifu = ifu_or_mem == 1'b0 ? arready_xbar : 1'b0;
  assign arready_mem = ifu_or_mem == 1'b0 ? 1'b0 : arready_xbar;

  // R
  assign rready_arbiter = ifu_or_mem == 1'b0 ? rready_ifu : rready_mem;
  assign rdata_ifu = ifu_or_mem == 1'b0 ? rdata_xbar : 32'b0;
  assign rdata_mem = ifu_or_mem == 1'b0 ? 32'b0 : rdata_xbar;
  assign rresp_ifu = ifu_or_mem == 1'b0 ? rresp_xbar : 2'b0;
  assign rresp_mem = ifu_or_mem == 1'b0 ? 2'b0 : rresp_xbar;
  assign rvalid_ifu = ifu_or_mem == 1'b0 ? rvalid_xbar : 1'b0;
  assign rvalid_mem = ifu_or_mem == 1'b0 ? 1'b0 : rvalid_xbar;

  // AW
  assign awvalid_arbiter = awvalid_mem;
  assign awaddr_arbiter = awaddr_mem;
  assign awready_arbiter = awready_xbar;

  // W
  assign wdata_arbiter = wdata_mem;
  assign wstrb_arbiter = wstrb_mem;
  assign wvalid_arbiter = wvalid_mem;
  assign wready_arbiter = wready_xbar;

  // B
  assign bready_arbiter = bready_mem;
  assign bresp_arbiter = bresp_xbar;
  assign bvalid_arbiter = bvalid_xbar;

  // arvalid, araddr: master -> arbiter
  // always @(posedge clk) begin
  //     if(!rst) begin
  //         arvalid_arbiter <= 1'b0;
  //         araddr_arbiter <= 32'b0;
  //     end
  //     else if(!ifu_or_mem) begin
  //         arvalid_arbiter <= arvalid_ifu;
  //         araddr_arbiter <= araddr_ifu;

  //     end
  //     else begin
  //         arvalid_arbiter <= arvalid_mem;
  //         araddr_arbiter <= araddr_mem;
  //     end
  // end

  // arready: slave -> arbiter
  // always @(posedge clk) begin
  //     if(!rst) begin
  //         arready_ifu <= 1'b0;
  //         arready_mem <= 1'b0;
  //     end
  //     else if(!ifu_or_mem) begin
  //         arready_ifu <= arready_xbar;
  //     end
  //     else begin
  //         arready_mem <= arready_xbar;
  //     end
  // end


  // rvalid: arbiter -> master
  // always @(posedge clk) begin
  //     if(!rst) begin
  //         rvalid_ifu <= 1'b0;
  //         rvalid_mem <= 1'b0;

  //     end
  //     else if(!ifu_or_mem) begin
  //         rvalid_ifu <= rvalid_xbar;
  //         rresp_ifu <= rresp_xbar;
  //         rdata_ifu <= rdata_xbar;

  //         rvalid_mem <= 1'b0;
  //     end
  //     else begin
  //         rvalid_mem <= rvalid_xbar;
  //         rresp_mem <= rresp_xbar;
  //         rdata_mem <= rdata_xbar;

  //         rvalid_ifu <= 1'b0;
  //     end
  // end

  // rready: master -> arbiter
  // always @(posedge clk) begin
  //     if(!rst) begin
  //         rready_arbiter <= 1'b0;
  //     end
  //     else if(!ifu_or_mem) begin
  //         rready_arbiter <= rready_ifu;
  //     end
  //     else begin
  //         rready_arbiter <= rready_mem;
  //     end
  // end

endmodule
