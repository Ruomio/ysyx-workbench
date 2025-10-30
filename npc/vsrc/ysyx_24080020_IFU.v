`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IFU (
    input  wire        clk,
    input  wire        rst,

    input wire         need_stall,
    // ir -> ifu
    input  wire [`ysyx_24080020_WIDTH-1:0] inst,
    input  wire [`ysyx_24080020_WIDTH-1:0] raddr,
    input  wire        inst_fin_valid,
    output wire        inst_fin_ready,
    input  wire        special_pc_i,
    // output wire        inst_fin,

    // ifu -> idu
    output wire [`ysyx_24080020_WIDTH-1:0] pc_ifu,
    output wire [`ysyx_24080020_WIDTH-1:0] inst_ifu,

    input  wire        idu_ifu_ready,
    output wire        ifu_idu_valid
);

reg valid_q;
reg [31:0] inst_q, raddr_q;
//=========================================================================
// 1. 经典 valid-ready 握手（零状态机）
//=========================================================================
// 反压：本级空就能收
assign ifu_idu_valid = valid_q;   // 有数据就向下传
// assign inst_fin_ready = (~valid_q);    // 空就能收
assign inst_fin_ready = (~valid_q) & (~need_stall);  // 空就能收

// 完成标志：组合（与原文件一致）
// assign inst_fin = inst_fin_valid & inst_fin_ready;

//=========================================================================
// 2. 仅锁 1 bit 标志（零整拍缓冲）
//=========================================================================

always @(posedge clk) begin
    if (!rst) begin
        valid_q <= 1'b0;
    end
    else if(ifu_idu_valid & idu_ifu_ready) begin
        valid_q <= 1'b0;
    end
    else if(inst_fin_valid & inst_fin_ready & ~need_stall) begin
        valid_q <= 1'b1;
        inst_q <= inst;
        raddr_q <= raddr;
    end
end

//=========================================================================
// 3. 输出：组合路径（不锁整拍）
//========================================================================|
assign pc_ifu     = raddr_q;          // PC 直接连输入
assign inst_ifu   = inst_q;           // 指令直接连输入

//=========================================================================
// 4. DPI-C 调试接口（可选，面积可综合开关）
//=========================================================================
`ifdef CONFIG_DPIC
import "DPI-C" function void statistics_ifu_get_inst();
always @(posedge clk) begin
    if (inst_fin_valid & inst_fin_ready) begin

        statistics_ifu_get_inst();

        // $display("ifu: inst=%h, pc=%h", inst_q, raddr_q);
    end
end
`endif

endmodule
