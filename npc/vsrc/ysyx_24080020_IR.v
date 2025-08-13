`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IR(
    input clk,
    input rst,

    // pc <-> ir
    input special_pc_i,
    input [`ysyx_24080020_WIDTH-1:0] addr,
    input if_en_valid,
    output reg if_en_ready,

    // ir <-> ifu
    output reg inst_fin_valid,
    output reg [`ysyx_24080020_WIDTH-1:0] inst,
    input inst_fin_ready,

    // icache -> ir
    input special_pc_icache,
    input [`ysyx_24080020_WIDTH-1:0] raddr_icache,
    output reg [`ysyx_24080020_WIDTH-1:0] raddr_ir,
    output reg special_pc_ir,

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

  reg if_en_shake_hands;

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
    else begin
    end

  end

  always @(posedge clk) begin
    if(!rst) begin
        if_en_ready <= 'b0;
        special_pc_o <= 'b0;
    end
    else if(if_en_valid && if_en_ready) begin
        if_en_ready <= 'b0;

        if_en_shake_hands <= 'b1;

        araddr <= addr;
        arsize <= 'b10;
        arlen <= 'b0;
        arburst <= 'b0;
        arid <= 'b0;
        special_pc_o <= special_pc_i;

    end
    else if(if_en_valid) begin
        if(!arvalid && !if_en_shake_hands) begin
            if_en_ready <= 'b1;
        end
    end
  end

  always @(posedge clk) begin
      if(!rst) begin
          if_en_shake_hands <= 'b0;
      end
      else if(if_en_shake_hands) begin
            arvalid <= 'b1;
            if_en_shake_hands <= 'b0;
      end
  end

  always @(posedge clk) begin
    if(!rst) begin
      rready <= 'b0;
      inst <= 'b0;
      raddr_ir <= 'b0;
      special_pc_ir <= 'b0;
    end
    else if(rvalid && rready) begin
      rready <= 'b0;
      if(rresp == 'b0) begin
        inst <= rdata;
        inst_fin_valid <= 'b1;
        raddr_ir <= raddr_icache;
        special_pc_ir <= special_pc_icache;
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
