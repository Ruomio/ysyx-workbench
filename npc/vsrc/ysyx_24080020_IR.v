`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IR (
    input  wire        clk,
    input  wire        rst,

    // pc <-> ir
    input  wire        special_pc_i,
    input  wire [`ysyx_24080020_WIDTH-1:0] addr,
    input  wire        if_en_valid,
    output wire        if_en_ready,
    // ir <-> ifu
    output wire        inst_fin_valid,
    output wire [`ysyx_24080020_WIDTH-1:0] inst,
    input  wire        inst_fin_ready,
    output wire [`ysyx_24080020_WIDTH-1:0] raddr_ir,
    // icache -> ir
    input  wire        special_pc_icache,
    input  wire [`ysyx_24080020_WIDTH-1:0] raddr_icache,
    output wire        special_pc_ir,
    output wire        special_pc_o,
    // AXI-Full（单 beat，完全组合）
    output wire        arvalid,
    output wire [1:0]  arburst,
    output wire [2:0]  arsize,
    output wire [3:0]  arid,
    output wire [7:0]  arlen,
    output wire [`ysyx_24080020_WIDTH-1:0] araddr,
    input  wire        arready,
    input  wire        rvalid,
    input  wire        rlast,
    input  wire [1:0]  rresp,
    input  wire [3:0]  rid,
    input  wire [`ysyx_24080020_WIDTH-1:0] rdata,
    output wire        rready
);

//=========================================================================
// 1. 地址选择与输出（组合，与原文件 100 % 一致）
//=========================================================================
// assign raddr_ir     = (special_pc_icache) ? raddr_icache : 32'd0;
assign raddr_ir     = raddr_icache;
assign special_pc_ir = special_pc_icache;
assign special_pc_o  = special_pc_i;

//=========================================================================
// 2. 经典 valid-ready 握手（零状态机）
//=========================================================================
// 反压：本级空就能收
assign if_en_ready = ~arvalid;
// AXI valid：组合逻辑，握手后立即拉低
assign arvalid = if_en_valid & if_en_ready & ~ar_done;
wire ar_done  = arvalid & arready;

// AXI 边带：单 beat，完全组合（与原文件一致）
assign arburst = 2'b01;   // INCR
assign arsize  = 3'b010;  // 4 字节
assign arid    = 4'd0;
assign arlen   = 8'd0;    // 单 beat
assign araddr  = addr;

//=========================================================================
// 3. 读数据：同一拍返回（不锁 rdata）
//=========================================================================
assign rready = 1'b1;     // 永远 ready（单 beat）
// assign rdata  = rdata;    // 直接连 ICACHE
// assign rresp  = 2'b00;    // OKAY
// assign rid    = rid;
// assign rlast  = 1'b1;     // 单 beat

// 读完成标志：同一拍有效（与原文件一致）
assign inst_fin_valid = rvalid & rlast & (rresp == 2'b00);

//=========================================================================
// 4. 输出：直接连组合（不锁整拍，与原文件一致）
//=========================================================================
assign inst       = rdata;
// assign pc_mem     = addr;   // PC 直接连输入
assign raddr_ir   = addr;   // 地址直接连输入

//=========================================================================
// 5. DPI-C 调试接口（可选，面积可综合开关）
//=========================================================================
`ifdef CONFIG_DPIC
always @(posedge clk) begin
    if (rvalid & rlast & (rresp != 2'b00))
        $error("IR read error");
end
`endif

endmodule

// `include "ysyx_24080020_DEFINE.v"
// module ysyx_24080020_IR(
//     input clk,
//     input rst,
//
//     // pc <-> ir
//     input special_pc_i,
//     input [`ysyx_24080020_WIDTH-1:0] addr,
//     input if_en_valid,
//     output reg if_en_ready,
//
//     // ir <-> ifu
//     output reg inst_fin_valid,
//     output reg [`ysyx_24080020_WIDTH-1:0] inst,
//     input inst_fin_ready,
//     output reg [`ysyx_24080020_WIDTH-1:0] raddr_ir,
//
//     // icache -> ir
//     input special_pc_icache,
//     input [`ysyx_24080020_WIDTH-1:0] raddr_icache,
//     output reg special_pc_ir,
//
//     output reg special_pc_o,
//     // axi-full
//     output reg arvalid,
//     output reg [1:0] arburst,
//     output reg [2:0] arsize,
//     output reg [3:0] arid,
//     output reg [7:0] arlen,
//     output reg [`ysyx_24080020_WIDTH-1:0] araddr,
//     input arready,
//
//     input rvalid,
//     input rlast,
//     input [1:0] rresp,
//     input [3:0] rid,
//     input [`ysyx_24080020_WIDTH-1:0] rdata,
//     output reg rready
//
// );
//
//   reg if_en_shake_hands;
//   reg next_inst;
//
//   always @(posedge clk) begin
//     if(!rst) begin
//       next_inst <= 'b1;
//     end
//     else if(arvalid && arready) begin
//       next_inst <= 'b0;
//     end
//     else if(rvalid && rlast && rready) begin
//       next_inst <= 'b1;
//     end
//   end
//
//   always @(posedge clk) begin
//     if(!rst) begin
//       arvalid <= 'b0;
//     end
//     else if(arready && arvalid) begin
//       arvalid <= 'b0;
//     end
//     else if(if_en_shake_hands) begin
//         arvalid <= 'b1;
//     end
//
//   end
//
//   always @(posedge clk) begin
//     if(!rst) begin
//         if_en_ready <= 'b0;
//         special_pc_o <= 'b0;
//         araddr <= 'b0;
//         arid <= 'b0;
//         arsize <= 'b0;
//         arlen <= 'b0;
//         arburst <= 'b0;
//     end
//     else if(if_en_valid && if_en_ready) begin
//         if_en_ready <= 'b0;
//
//         // if_en_shake_hands <= 'b1;
//
//         araddr <= addr;
//         arsize <= 'b10;
//         arlen <= 'b0;
//         arburst <= 'b0;
//         arid <= 'b0;
//         special_pc_o <= special_pc_i;
//
//     end
//     else if(if_en_valid) begin
//         if(!arvalid && !if_en_shake_hands && next_inst) begin
//             if_en_ready <= 'b1;
//         end
//     end
//   end
//
//   always @(posedge clk) begin
//       if(!rst) begin
//           if_en_shake_hands <= 'b0;
//       end
//       else if(if_en_shake_hands) begin
//             // arvalid <= 'b1;
//             if_en_shake_hands <= 'b0;
//       end
//     else if(if_en_valid && if_en_ready) begin
//         if_en_shake_hands <= 'b1;
//     end
//   end
//
//   always @(posedge clk) begin
//     if(!rst) begin
//       rready <= 'b0;
//       inst <= 'b0;
//       raddr_ir <= 'b0;
//       special_pc_ir <= 'b0;
//     end
//     else if(rvalid && rready) begin
//       rready <= 'b0;
//       if(rresp == 'b0) begin
//         inst <= rdata;
//         // inst_fin_valid <= 'b1;
//         raddr_ir <= raddr_icache;
//         special_pc_ir <= special_pc_icache;
//       end
//       else begin
//         `ifdef CONFIG_DPIC
//         $error("ir read error");
//         `endif
//       end
//     end
//     else if(rvalid && rlast && !inst_fin_valid) begin
//       rready <= 'b1;
//     end
//   end
//
//   always @(posedge clk) begin
//       if(!rst) begin
//           inst_fin_valid <= 'b0;
//       end
//       else if(inst_fin_valid && inst_fin_ready) begin
//         inst_fin_valid <= 'b0;
//       end
//     else if(rvalid && rready) begin
//       if(rresp == 'b0) begin
//         inst_fin_valid <= 'b1;
//       end
//     end
//   end
//
// endmodule
