`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IR(
    input clk,
    input rst,
    input lsu_busy,

    // pc <-> ir
    input special_pc_i,
    input [`ysyx_24080020_WIDTH-1:0] addr,
    input if_en_valid,
    output reg if_en_ready,

    // ir <-> ifu
    output reg inst_fin_valid,
    output reg [`ysyx_24080020_WIDTH-1:0] inst,
    input inst_fin_ready,

    output reg special_pc_o,
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
    else begin
    end

  end

  always @(posedge clk) begin
    if(!rst) begin
        if_en_ready <= 'b0;
    end
    else if(if_en_valid && if_en_ready) begin
        if_en_ready <= 'b0;
    end
    else if(if_en_valid) begin
        if(!lsu_busy) begin
            araddr <= addr;
            arvalid <= 'b1;
            arsize <= 'b10;
            arlen <= 'b0;
            arburst <= 'b0;
            arid <= 'b0;

            special_pc_o <= special_pc_i;

            if_en_ready <= 'b1;
        end
    end
  end

  always @(posedge clk) begin
    if(!rst) begin
      rready <= 'b0;
      inst <= 'b0;
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
  end

  always @(posedge clk) begin
      if(!rst) begin
          inst_fin_valid <= 'b0;
      end
      else if(inst_fin_valid && inst_fin_ready) begin
        inst_fin_valid <= 'b0;
      end
  end

endmodule
