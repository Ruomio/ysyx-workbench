`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IR(
    input clk,
    input rst,
    input if_en,
    input [`ysyx_24080020_WIDTH-1:0] addr,

    output reg [`ysyx_24080020_WIDTH-1:0] inst,
    output reg inst_fin,

    // axi-full
    output reg arvalid,
    output reg [1:0] arburst,
    output reg [2:0] arsize,
    output reg [3:0] arid,
    output reg [7:0] arlen,
    output reg [`ysyx_24080020_WIDTH-1:0] araddr,
    input arready,

    input rvalid,
    input rlast,
    input [1:0] rresp,
    input [3:0] rid,
    input [`ysyx_24080020_WIDTH-1:0] rdata,
    output reg rready

);

  always @(posedge clk) begin
    if(!rst) begin
      arvalid <= 'b0;
      araddr <= 'b0;
      arid <= 'b0;
      arsize <= 'b0;
      arlen <= 'b0;
      arburst <= 'b0;
    end
    else if(arready && arvalid) begin
      arvalid <= 'b0;
    end
    else if(if_en) begin
      araddr <= addr;
      arvalid <= 'b1;
      arsize <= 'b10;
      arlen <= 'b0;
      arburst <= 'b0;
      arid <= 'b0;
    end
  end

  always @(posedge clk) begin
    if(!rst) begin
      rready <= 'b0;
      inst <= 'b0;
      inst_fin <= 'b0;
    end
    else if(rvalid) begin
      rready <= 'b1;
      if(rresp == 'b0) begin
        inst <= rdata;
        inst_fin <= 'b1;
      end
      else begin
        `ifdef CONFIG_DPIC
        $error("ir read error");
        `endif
      end
    end
    else begin
      // rready <= 'b0;
      inst_fin <= 'b0;
    end
  end

endmodule
