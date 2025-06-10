`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IR(
    input clk,
    input rst,
    input if_en,
    input lsu_busy,
    input [`ysyx_24080020_WIDTH-1:0] addr,

    output reg [`ysyx_24080020_WIDTH-1:0] inst,
    output reg inst_fin_valid,

    input inst_fin_ready,

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

  `ifdef CONFIG_DPIC
  import "DPI-C" function void statistics_ifu_get_inst();
  `endif

  reg need_fetch;

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
      `ifdef CONFIG_DPIC
      statistics_ifu_get_inst();
      `endif
    end

  end

  always @(posedge clk) begin
    if(!rst) begin
      need_fetch <= 'b0;
    end
    else if(need_fetch && !lsu_busy) begin
      need_fetch <= 'b0;

      araddr <= addr;
      arvalid <= 'b1;
      arsize <= 'b10;
      arlen <= 'b0;
      arburst <= 'b0;
      arid <= 'b0;
    end
    else if(if_en) begin
      need_fetch <= 'b1;
    end

  end

  always @(posedge clk) begin
    if(!rst) begin
      rready <= 'b0;
      inst <= 'b0;
      inst_fin_valid <= 'b0;
    end
    else if(rvalid && rready) begin
      rready <= 'b0;
      if(rresp == 'b0) begin
        inst <= rdata;
        inst_fin_valid <= 'b1;
      end
      else begin
        `ifdef CONFIG_DPIC
        $error("ir read error");
        `endif
      end
    end
    else if(rvalid && rlast && !inst_fin_valid) begin
      rready <= 'b1;
    end
    else if(inst_fin_valid && inst_fin_ready) begin
      rready <= 'b0;
      inst_fin_valid <= 'b0;
    end
  end

endmodule
