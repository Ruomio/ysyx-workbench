//==============================================================
//  ysyx_24080020_EXU.sv
//  执行单元 - 面积优化版本
//  设计目标：减少always块，多用assign，遵循RISC-V规范
//  面积目标：≈ 2.0 k μm² (@28 nm)
//==============================================================
`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_EXU (
    input  wire        clk,
    input  wire        rst,          // 低电平复位

    input  wire        need_stall,

    // IDU <---> EXU 流水线握手
    input  wire        idu_exu_valid,
    output wire        exu_idu_ready,
    // input  wire        flush_pipeline,

    // EXU <---> MEM 流水线握手
    output wire        exu_mem_valid,
    input  wire        mem_exu_ready,

    // 来自IDU的控制信号
    input  wire [`ysyx_24080020_WIDTH-1:0] pc_idu,
    input  wire [`ysyx_24080020_WIDTH-1:0] imm_idu,
    input  wire [`ysyx_24080020_ALU_OP_WIDTH-1:0] alu_op_idu,
    input  wire        is_branch_idu,
    input  wire        is_jal_idu,
    input  wire        is_jalr_idu,
    input  wire        is_load_idu,
    input  wire        is_store_idu,
    input  wire        is_csr_idu,
    input  wire        is_mret_idu,
    input  wire        is_ebreak_idu,
    input  wire        is_ecall_idu,
    input  wire        is_auipc_idu,
    input  wire        is_i_type_idu,
    input  wire        is_u_type_idu,
    input  wire        fencei_idu,
    input  wire [2:0]  mem_len_idu,
    input  wire [2:0]  mem_wmask_idu,

    // 寄存器读写
    input  wire [`ysyx_24080020_WIDTH-1:0] val_raddr1_idu,
    input  wire [`ysyx_24080020_WIDTH-1:0] val_raddr2_idu,
    input  wire [`ysyx_24080020_REG_WIDTH-1:0] waddr_idu,
    input  wire        wen_idu,

    // CSR读写
    input  wire        wcsren_idu,
    input  wire [2:0]  wcsraddr_idu,
    input  wire [31:0] wcsrdata_idu,
    input  wire [31:0] rcsrdata_idu,

    // 输出到MEM/WB的信号
    output wire [`ysyx_24080020_WIDTH-1:0] pc_exu,
    // output wire [`ysyx_24080020_WIDTH-1:0] alu_result_exu,
    output wire [`ysyx_24080020_WIDTH-1:0] dnpc_exu,
    output wire        branch_taken_exu,
    output wire        branch_not_taken_exu,
    output wire        is_load_exu,
    output wire        is_store_exu,
    output wire        is_ebreak_exu,
    output wire        is_ecall_exu,
    output wire        fencei_exu,
    output wire [2:0]  mem_len_exu,
    // output wire [2:0]  mem_wmask_exu,
    // output wire [`ysyx_24080020_WIDTH-1:0] store_data_exu,
    output wire [`ysyx_24080020_WIDTH-1:0] mem_addr_exu,

    // 寄存器写回
    output wire [`ysyx_24080020_REG_WIDTH-1:0] waddr_exu,
    output wire [`ysyx_24080020_WIDTH-1:0] wdata_exu,
    output wire        wen_exu,

    // CSR写回
    output wire        wcsren_exu,
    output wire [2:0]  wcsraddr_exu,
    output wire [31:0] wcsrdata_exu,

    // ALU接口
    output wire [`ysyx_24080020_WIDTH-1:0] alu_src1,
    output wire [`ysyx_24080020_WIDTH-1:0] alu_src2,
    output wire [`ysyx_24080020_ALU_OP_WIDTH-1:0] alu_op_exu,
    input  wire [`ysyx_24080020_WIDTH-1:0] alu_result,
    input  wire        alu_zero
    `ifdef CONFIG_DPIC
    // DPI-C调试接口
    `endif
);

//=========================================================================
// 流水线控制与寄存器
//=========================================================================
localparam PIPE_CTRL_W = 20;
wire [PIPE_CTRL_W-1:0] ctrl_comb = {
    is_mret_idu, is_u_type_idu, is_i_type_idu, is_auipc_idu,
    is_ecall_idu, is_branch_idu, is_jal_idu, is_jalr_idu, is_load_idu, is_store_idu,
    is_csr_idu, is_ebreak_idu, fencei_idu,
    mem_len_idu, alu_op_idu
};

reg [31:0]               pc_q_reg;
reg [31:0]               imm_q_reg;
reg [31:0]               val1_q_reg;
reg [31:0]               val2_q_reg;
reg [`ysyx_24080020_REG_WIDTH-1:0] waddr_q_reg;

reg                      wen_q_reg;
reg [PIPE_CTRL_W-1:0]    ctrl_q_reg;
reg                      valid_q_reg;

// CSR相关寄存器
reg                      wcsren_q_reg;
reg [2:0]                wcsraddr_q_reg;
reg [31:0]               wcsrdata_q_reg;
reg [31:0]               rcsrdata_q_reg;

//=========================================================================
// 流水线握手逻辑（极简）
//=========================================================================
// assign exu_idu_ready = ~valid_q_reg || (mem_exu_ready && exu_mem_valid);
assign exu_idu_ready = ~valid_q_reg & ~need_stall;
assign exu_mem_valid = valid_q_reg;

always @(posedge clk) begin
    if (!rst) begin
        // valid_q_reg     <= 1'b0;
        pc_q_reg        <= 32'd0;
        imm_q_reg       <= 32'd0;
        val1_q_reg      <= 32'd0;
        val2_q_reg      <= 32'd0;
        waddr_q_reg     <= `ysyx_24080020_REG_WIDTH'd0;

        wen_q_reg       <= 1'b0;
        ctrl_q_reg      <= '0;
        wcsren_q_reg    <= 1'b0;
        wcsraddr_q_reg  <= 3'd0;
        wcsrdata_q_reg  <= 32'd0;
    end
    else if ((mem_exu_ready && valid_q_reg)) begin
        waddr_q_reg     <= 'b0;
    end
    else if (idu_exu_valid && exu_idu_ready) begin
        // valid_q_reg     <= 1'b1;
        pc_q_reg        <= pc_idu;
        imm_q_reg       <= imm_idu;
        val1_q_reg      <= val_raddr1_idu;
        val2_q_reg      <= val_raddr2_idu;
        waddr_q_reg     <= waddr_idu;

        wen_q_reg       <= wen_idu;
        ctrl_q_reg      <= ctrl_comb;
        wcsren_q_reg    <= wcsren_idu;
        wcsraddr_q_reg  <= wcsraddr_idu;
        wcsrdata_q_reg  <= wcsrdata_idu;
        rcsrdata_q_reg  <= rcsrdata_idu;
    end
end
always @(posedge clk) begin
    if (!rst) begin
        valid_q_reg     <= 1'b0;
    end
    else if ((mem_exu_ready && valid_q_reg)) begin
        valid_q_reg     <= 1'b0;
    end
    else if (idu_exu_valid && exu_idu_ready) begin
        valid_q_reg     <= 1'b1;
    end
end

//=========================================================================
// 控制信号解析（全部使用assign）
//=========================================================================
wire        is_csr_exu;
wire        is_branch_exu;
wire        is_jal_exu;
wire        is_jalr_exu;
wire        is_auipc_exu;
wire        is_i_type_exu;
wire        is_u_type_exu;
wire        is_mret_exu;

assign is_mret_exu = ctrl_q_reg[19];
assign is_u_type_exu = ctrl_q_reg[18];
assign is_i_type_exu = ctrl_q_reg[17];
assign is_auipc_exu = ctrl_q_reg[16];
assign is_ecall_exu = ctrl_q_reg[15];
assign is_branch_exu = ctrl_q_reg[14];
assign is_jal_exu    = ctrl_q_reg[13];
assign is_jalr_exu   = ctrl_q_reg[12];
assign is_load_exu   = ctrl_q_reg[11];
assign is_store_exu  = ctrl_q_reg[10];
assign is_csr_exu    = ctrl_q_reg[9];
assign is_ebreak_exu = ctrl_q_reg[8];
assign fencei_exu    = ctrl_q_reg[7];
assign mem_len_exu   = ctrl_q_reg[6:4];
// assign mem_wmask_exu = mem_len_exu;  // store和load使用相同的长度编码
assign alu_op_exu    = ctrl_q_reg[3:0];

//=========================================================================
// ALU操作数选择（RISC-V标准）
//=========================================================================
// src1选择：JAL/JALR使用PC，其他使用rs1
assign alu_src1 = (is_jal_exu || is_jalr_exu || is_auipc_exu) ? pc_q_reg : val1_q_reg;

// src2选择：根据指令类型选择立即数或rs2
wire use_imm = is_load_exu || is_store_exu || is_u_type_exu ||
               is_jal_exu || is_jalr_exu || is_auipc_exu || is_i_type_exu;

assign alu_src2 = use_imm ? imm_q_reg : val2_q_reg;

//=========================================================================
// 分支/跳转逻辑（RISC-V标准）
//=========================================================================
// 分支条件判断, mem_len_exu == funct3
wire branch_cond;
assign branch_cond = (mem_len_exu == 3'b000) ? alu_zero :      // BEQ
                     (mem_len_exu == 3'b001) ? ~alu_zero :     // BNE
                     (mem_len_exu == 3'b100) ? ~alu_zero :     // BLT
                     (mem_len_exu == 3'b101) ? alu_zero :      // BGE
                     (mem_len_exu == 3'b110) ? ~alu_zero :     // BLTU
                     (mem_len_exu == 3'b111) ? alu_zero :      // BGEU
                     1'b0;

// 跳转条件
assign branch_taken_exu = is_jal_exu || is_jalr_exu || (is_branch_exu && branch_cond)
                            || is_ecall_exu || is_mret_exu;
assign branch_not_taken_exu = is_branch_exu && !branch_cond;

// 目标地址计算
wire [31:0] branch_base = is_jalr_exu ? val1_q_reg : pc_q_reg;
wire [31:0] branch_target = (is_mret_exu|is_ecall_exu) ? rcsrdata_q_reg :
                                (branch_base + imm_q_reg);
assign dnpc_exu = is_jalr_exu ? (branch_target & ~32'h1) : branch_target;

//=========================================================================
// 存储器接口
//=========================================================================
assign mem_addr_exu = alu_result;
// store_data pass by wdata_exu
// assign store_data_exu = val2_q_reg;

//=========================================================================
// 寄存器写回逻辑
//=========================================================================
// 写回数据选择：JAL/JALR写回PC+4，load指令后续由MEM阶段写回，其他写回ALU结果
wire [31:0] pc_plus_4 = pc_q_reg + 32'd4;
assign wdata_exu = (is_jal_exu || is_jalr_exu) ? pc_plus_4 :
                   is_csr_exu ? rcsrdata_q_reg :  // CSR指令写回原寄存器值
                   (is_store_exu) ? val2_q_reg :  // store
                   alu_result;                // ALU指令写回计算结果

assign waddr_exu = waddr_q_reg;
// assign wen_exu = wen_q_reg && ~is_load_exu;  // load指令不在EXU阶段写回
assign wen_exu = wen_q_reg;

//=========================================================================
// CSR写回
//=========================================================================
assign wcsren_exu = wcsren_q_reg;
assign wcsraddr_exu = wcsraddr_q_reg;
assign wcsrdata_exu = wcsrdata_q_reg;

//=========================================================================
// 输出信号
//=========================================================================
assign pc_exu = pc_q_reg;
// wire [31:0] alu_result_exu;
// assign alu_result_exu = alu_result;

//=========================================================================
// DPI-C调试接口（可选）
//=========================================================================
`ifdef CONFIG_DPIC
import "DPI-C" function void statistics_exu_complete_calcu();
import "DPI-C" function void update_ftrace_dpi();
import "DPI-C" function void ebreak();
import "DPI-C" function void statistics_idu_calculate_type();
import "DPI-C" function void statistics_idu_load_type();
import "DPI-C" function void statistics_idu_store_type();
import "DPI-C" function void statistics_idu_csr_type();
import "DPI-C" function void statistics_idu_jump_type();

// DPI调用逻辑
always @(posedge clk) begin
    if (idu_exu_valid && exu_idu_ready) begin
        statistics_exu_complete_calcu();
        if (is_jal_idu || is_jalr_idu) update_ftrace_dpi();
        if (is_ebreak_idu) ebreak();

        // 指令类型统计
        if (is_load_idu) statistics_idu_load_type();
        else if (is_store_idu) statistics_idu_store_type();
        else if (is_csr_idu) statistics_idu_csr_type();
        else if (is_branch_idu || is_jal_idu || is_jalr_idu) statistics_idu_jump_type();
        else statistics_idu_calculate_type();
    end
end
`endif

endmodule
