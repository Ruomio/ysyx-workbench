`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_PC (
    input clk,
    input rst,

    // pc -> btb
    output pc_btb_special,
    output pc_btb_valid,
    input btb_pc_ready,
    output [`ysyx_24080020_WIDTH-1:0] pc_addr,

    // btb -> pc
    input  wire        btb_target_valid,
    input [`ysyx_24080020_WIDTH-1:0] btb_target_pc,

    // error jump
    input  wire        fix_valid,
    input [`ysyx_24080020_WIDTH-1:0] fix_pc,
    input in_special_pc
);

    reg [31:0] pc_q;

    // 1. 经典 valid-ready：反压 = 「本级空」
    assign pc_btb_valid   = rst & btb_pc_ready;        // 寄存器输出
    assign pc_btb_special = in_special_pc;     // 直接连输入
    assign pc_addr        = pc_q;              // 当前 PC

    // 2. 更新逻辑：单拍完成
    always @(posedge clk) begin
        if (!rst) begin
            pc_q        <= `ysyx24080020_MBASE;   // 初始 PC
        end
        else if (btb_target_valid) begin    // BTB 握手成功
            pc_q        <= btb_target_pc;
        end
        else if (fix_valid) begin           // 错误刷新握手成功
            pc_q        <= fix_pc;
        end
        else if (pc_btb_valid & btb_pc_ready) begin
            pc_q        <= pc_q + 32'd4;    // 顺序 +4
        end
    end

endmodule
