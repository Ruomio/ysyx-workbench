`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_PC (
    input clk,
    input rst,

    // pc -> btb
    output pc_btb_special,
    output pc_btb_valid,
    input btb_pc_ready,
    output [`ysyx_24080020_WIDTH-1:0] pc_addr,
    output [`ysyx_24080020_WIDTH-1:0] pc_btb_target,
    output pc_btb_update,

    // exu -> pc
    input branch_not_taken,
    input branch_taken,
    input [`ysyx_24080020_WIDTH-1:0] pc_base,
    input [`ysyx_24080020_WIDTH-1:0] pc_target,

    // btb -> pc
    input  wire                      btb_target_valid,
    input [`ysyx_24080020_WIDTH-1:0] btb_target_pc

);

    reg update_q;
    reg [31:0] pc_q, pc_target_q;


    wire update_btb = (branch_taken & (~btb_target_valid)) |
                        (branch_not_taken & btb_target_valid);

    // 1. 经典 valid-ready：反压 = 「本级空」
    assign pc_btb_valid   = rst & btb_pc_ready;        // 寄存器输出
    assign pc_btb_special = update_q;     // 直接连输入
    assign pc_addr        = pc_q;              // 当前 PC

    assign pc_btb_update  = update_q;
    assign pc_btb_target  = pc_target_q;

    // 2. 更新逻辑：单拍完成
    always @(posedge clk) begin
        if (!rst) begin
            pc_q        <= `ysyx_24080020_MBASE;   // 初始 PC
        end
        else if(update_btb & (~update_next)) begin
            pc_q        <= pc_base;
            pc_target_q <= pc_target;
            update_q    <= 1'b1;
        end
        else if (btb_target_valid) begin    // BTB hit
            pc_q        <= btb_target_pc;
        end
        else if (pc_btb_valid & btb_pc_ready) begin
            pc_q        <= update_q ? btb_target_pc :  pc_q + 32'd4;    // 顺序 +4
            update_q    <= 1'b0;
        end
    end

    reg update_next;
    always @(posedge clk) begin
        if (!rst) begin
            update_next    <= 1'b0;
        end
        else begin
            update_next    <= update_btb;
        end
    end

endmodule
