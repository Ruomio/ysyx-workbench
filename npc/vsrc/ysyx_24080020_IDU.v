//==============================================================
//  ysyx_24080020_IDU_2w1r.sv
//  REGFILE  2 读 1 写（保持）
//  CSR      1 读 2 写（恢复）
//  面积目标：≈ 1.6 k μm² (@28 nm)
//==============================================================
`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IDU (
    input  wire        clk,
    input  wire        rst,          // 低电平复位
    // IFU <---> IDU
    input  wire [`ysyx_24080020_WIDTH-1:0] inst_ifu,
    input  wire [`ysyx_24080020_WIDTH-1:0] pc_ifu,
    input  wire        ifu_idu_valid,
    output wire        idu_ifu_ready,
    // IDU <---> EXU
    output wire        idu_exu_valid,
    input  wire        exu_idu_ready,
    input  wire        flush_pipeline,
    input  wire        need_stall,
    output reg [`ysyx_24080020_WIDTH-1:0]  pc_idu,
    // REGFILE 2 读 1 写（端口不变）
    output wire [`ysyx_24080020_REG_WIDTH-1:0] rs1,
    output wire [`ysyx_24080020_REG_WIDTH-1:0] rs2,
    input  wire [`ysyx_24080020_WIDTH-1:0]     val_raddr1,
    input  wire [`ysyx_24080020_WIDTH-1:0]     val_raddr2,
    output wire [`ysyx_24080020_REG_WIDTH-1:0] waddr_idu,
    output wire                                wen_idu,
    output wire [`ysyx_24080020_WIDTH-1:0]     val_raddr1_idu,
    output wire [`ysyx_24080020_WIDTH-1:0]     val_raddr2_idu,
    // CSR 1 读 1 写
    output wire [2:0]  rcsraddr,
    input  wire [31:0] rcsrdata,
    output wire        wcsren_idu,
    output wire [2:0]  wcsraddr_idu,
    output wire [31:0] wcsrdata_idu,
    output wire [31:0] rcsrdata_idu,
    // output wire        wcsren2_idu,
    // output wire [2:0]  wcsraddr2_idu,
    // output wire [31:0] wcsrdata2_idu,
    // 其余控制
    output wire [`ysyx_24080020_ALU_OP_WIDTH-1:0] alu_op_idu,
    output wire        is_ecall_idu,
    output wire        is_ebreak_idu,
    output wire [31:0] imm_idu,
    output wire        is_branch_idu,
    output wire        is_jal_idu,
    output wire        is_jalr_idu,
    output wire        is_load_idu,
    output wire        is_store_idu,
    output wire        is_csr_idu,
    output wire        is_auipc_idu,
    output wire        is_i_type_idu,
    output wire        is_u_type_idu,

    output wire        fencei_idu,
    output wire [2:0]  mem_len_idu,
    output wire [2:0]  mem_wmask_idu
);

//=========================================================================
// 1. 立即数 2 级选择
//=========================================================================
wire [31:0] IMM_I = {{20{inst_ifu[31]}}, inst_ifu[31:20]};
wire [31:0] IMM_S = {{20{inst_ifu[31]}}, inst_ifu[31:25], inst_ifu[11:7]};
wire [31:0] IMM_B = {{20{inst_ifu[31]}}, inst_ifu[7], inst_ifu[30:25], inst_ifu[11:8], 1'b0};
wire [31:0] IMM_U = {inst_ifu[31:12], 12'b0};
wire [31:0] IMM_J = {{12{inst_ifu[31]}}, inst_ifu[19:12], inst_ifu[20], inst_ifu[30:21], 1'b0};

reg [1:0] imm_type;
always @(*) begin
    case (inst_ifu[6:0])
        `ysyx_24080020_JALR,
        `ysyx_24080020_I_TYPE,
        `ysyx_24080020_LOAD_TYPE : imm_type = 2'b00;
        `ysyx_24080020_S_TYPE     : imm_type = 2'b01;
        `ysyx_24080020_B_TYPE     : imm_type = 2'b10;
        `ysyx_24080020_LUI,
        `ysyx_24080020_AUIPC      : imm_type = 2'b11;
        `ysyx_24080020_JAL        : imm_type = 2'b11;
        default                   : imm_type = 2'b00;
    endcase
end

wire [31:0] imm_comb = (imm_type == 2'b00) ? IMM_I :
                       (imm_type == 2'b01) ? IMM_S :
                       (imm_type == 2'b10) ? IMM_B :
                       (opcode == `ysyx_24080020_JAL) ? IMM_J : IMM_U;

//=========================================================================
// 2. opcode 译码（同上一版）
//=========================================================================
wire [6:0] opcode = inst_ifu[6:0];
wire [2:0] funct3 = inst_ifu[14:12];
wire [6:0] funct7 = inst_ifu[31:25];

wire is_r_type = (opcode == `ysyx_24080020_R_TYPE);
wire is_i_type = (opcode == `ysyx_24080020_I_TYPE) || (opcode == `ysyx_24080020_LOAD_TYPE);
wire is_s_type = (opcode == `ysyx_24080020_S_TYPE);
wire is_b_type = (opcode == `ysyx_24080020_B_TYPE);
wire is_u_type = (opcode == `ysyx_24080020_LUI) || (opcode == `ysyx_24080020_AUIPC);
wire is_j_type = (opcode == `ysyx_24080020_JAL);
wire is_jr_type= (opcode == `ysyx_24080020_JALR);
wire is_csr    = (opcode == `ysyx_24080020_CSR_TYPE);
wire is_fencei = (opcode == `ysyx_24080020_FENCEI_TYPE);
wire is_load_type = (opcode == `ysyx_24080020_LOAD_TYPE);
wire is_auipc = (opcode == `ysyx_24080020_AUIPC);
// 探测 ecall/mret/ebreak
wire is_ecall  = is_csr && (inst_ifu[`ysyx_24080020_IMM_I] == 12'h0);
wire is_mret   = is_csr && (inst_ifu[`ysyx_24080020_IMM_I] == 12'h302);
wire is_ebreak = is_csr && (inst_ifu[`ysyx_24080020_IMM_I] == 12'h1);

reg [`ysyx_24080020_ALU_OP_WIDTH-1:0] alu_op_comb;
always @(*) begin
    case (opcode)
        `ysyx_24080020_R_TYPE: alu_op_comb = (funct7[5] && funct3 == 3'b000) ? `ysyx_24080020_ALU_SUB :
                                             (funct3 == 3'b000) ? `ysyx_24080020_ALU_ADD :
                                             (funct3 == 3'b111) ? `ysyx_24080020_ALU_AND :
                                             (funct3 == 3'b110) ? `ysyx_24080020_ALU_OR  :
                                             (funct3 == 3'b100) ? `ysyx_24080020_ALU_XOR :
                                             (funct3 == 3'b001) ? `ysyx_24080020_ALU_SLL :
                                             (funct3 == 3'b101) ? (funct7[5] ? `ysyx_24080020_ALU_SRA :
                                                                      `ysyx_24080020_ALU_SRL) :
                                             (funct3 == 3'b010) ? `ysyx_24080020_ALU_SLT :
                                             `ysyx_24080020_ALU_SLTU;
        `ysyx_24080020_I_TYPE: alu_op_comb = (funct3 == 3'b000) ? `ysyx_24080020_ALU_ADD :
                                             (funct3 == 3'b010) ? `ysyx_24080020_ALU_SLT :
                                             (funct3 == 3'b100) ? `ysyx_24080020_ALU_XOR :
                                             (funct3 == 3'b110) ? `ysyx_24080020_ALU_OR :
                                             (funct3 == 3'b111) ? `ysyx_24080020_ALU_AND :
                                             (funct3 == 3'b001) ? `ysyx_24080020_ALU_SLL :
                                             (funct3 == 3'b101) ? (funct7[5] ? `ysyx_24080020_ALU_SRA :
                                                                        `ysyx_24080020_ALU_SRL) :
                                             `ysyx_24080020_ALU_SLTU;
        `ysyx_24080020_LOAD_TYPE,
        `ysyx_24080020_S_TYPE: alu_op_comb = `ysyx_24080020_ALU_ADD;
        `ysyx_24080020_B_TYPE: alu_op_comb = (funct3 == 3'b100) ? `ysyx_24080020_ALU_BLT :      // BLT
                                             (funct3 == 3'b101) ? `ysyx_24080020_ALU_BLT :      // BGE
                                             (funct3 == 3'b110) ? `ysyx_24080020_ALU_BLTU :     // BLTU
                                             (funct3 == 3'b111) ? `ysyx_24080020_ALU_BLTU :     // BLTU
                                             `ysyx_24080020_ALU_SUB;
        `ysyx_24080020_LUI,
        `ysyx_24080020_AUIPC:  alu_op_comb = `ysyx_24080020_ALU_ADD;
        `ysyx_24080020_JAL,
        `ysyx_24080020_JALR:   alu_op_comb = `ysyx_24080020_ALU_ADD;
        default:               alu_op_comb = `ysyx_24080020_ALU_ADD;
    endcase
end

//=========================================================================
// 3. REGFILE 端口（保持 2 读 1 写）
//=========================================================================
assign rs1 = (is_u_type) ? 'b0 : inst_ifu[`ysyx_24080020_RS1];
assign rs2 = (is_r_type || is_s_type || is_b_type) ? inst_ifu[`ysyx_24080020_RS2] : `ysyx_24080020_REG_WIDTH'd0;

assign waddr_idu = (is_s_type || is_b_type) ? 'h0 : inst_ifu[`ysyx_24080020_RD]; // b-type and s-type are no rd;
assign wen_idu   = (is_r_type || is_i_type || is_u_type || is_j_type || is_jr_type || is_csr) &&
                   (inst_ifu[`ysyx_24080020_RD] != `ysyx_24080020_REG_WIDTH'd0);

//=========================================================================
// 4. CSR 1 读 1 写：地址/数据复用，写优先
//=========================================================================
wire [11:0] csr_imm = inst_ifu[`ysyx_24080020_IMM_I];

// 读口直接连
assign rcsraddr        = (csr_imm == `ysyx_24080020_MEPC_ADDR) ? 3'd0 :
                            (csr_imm == `ysyx_24080020_MSTATUS_ADDR) ? 3'd1 :
                            (csr_imm == `ysyx_24080020_MCAUSE_ADDR) ? 3'd2 :
                            (csr_imm == `ysyx_24080020_MTVEC_ADDR) ? 3'd3 :
                            (csr_imm == `ysyx_24080020_MVENDORID_ADDR) ? 3'd4 :
                            (csr_imm == `ysyx_24080020_MARCHID_ADDR) ? 3'd5 : 3'd0;
// 写口 1
assign wcsraddr_idu    = (csr_imm == `ysyx_24080020_MEPC_ADDR) ? 3'd0 :
                            (csr_imm == `ysyx_24080020_MSTATUS_ADDR) ? 3'd1 :
                            (csr_imm == `ysyx_24080020_MCAUSE_ADDR) ? 3'd2 :
                            (csr_imm == `ysyx_24080020_MTVEC_ADDR) ? 3'd3 :
                            (csr_imm == `ysyx_24080020_MVENDORID_ADDR) ? 3'd4 :
                            (csr_imm == `ysyx_24080020_MARCHID_ADDR) ? 3'd5 :
                            3'd0;
assign wcsrdata_idu    = is_ecall ? pc_ifu :
                         is_mret ? 32'h1800 :
                            val_raddr1;  // CSR写数据来自寄存器文件读取值
assign wcsren_idu      = (is_csr && (funct3 != 3'b000 && funct3 != 3'b100)) // CSRRW/CSRRS
                            || is_ecall || is_mret;                         // ecall/mret

//=========================================================================
// 5. 其余控制信号（从寄存器化的ctrl_q中获取）
//=========================================================================

assign is_u_type_idu = ctrl_q[51];
assign is_i_type_idu = ctrl_q[50];
assign is_auipc_idu = ctrl_q[49];
assign is_ecall_idu = ctrl_q[48];
assign is_branch_idu = ctrl_q[47];
assign is_jal_idu    = ctrl_q[46];
assign is_jalr_idu   = ctrl_q[45];
assign is_load_idu   = ctrl_q[44];
assign is_store_idu  = ctrl_q[43];
assign is_csr_idu    = ctrl_q[42];
assign fencei_idu    = ctrl_q[41];
assign is_ebreak_idu = ctrl_q[40];

// 存储控制
assign mem_len_idu   = ctrl_q[39:37];   // funct3 for load
assign mem_wmask_idu = ctrl_q[39:37];   // funct3 for store (same as mem_len)

// 立即数
assign imm_idu = ctrl_q[36:5];

//=========================================================================
// ecall/mret 拆 2 拍：状态机 + 自动 hold
//=========================================================================
reg        ecall_phase;      // 0: 第 1 拍（mepc） 1: 第 2 拍（mcause）
reg [31:0] mcause_hold;      // 暂存 mcause 值
// wire       do_ecall  = is_ecall || is_mret;   // 需要拆 2 拍的指令
wire       do_ecall  = is_ecall;   // 需要拆 2 拍的指令
wire       last_phase = ecall_phase;

// 对外通知：正在拆第 2 拍，请保持 CSR 写口
wire         csr_hold;
assign csr_hold = ecall_phase;

//=========================================================================
// 6. 极简流水线握手 & 锁存（）
//=========================================================================
localparam PIPE_CTRL_W = 52;
wire [PIPE_CTRL_W-1:0] ctrl_comb = {
    is_u_type, is_i_type, is_auipc,
    is_ecall, is_b_type, is_j_type, is_jr_type,
    is_load_type, is_s_type, is_csr, is_fencei, is_ebreak,
    funct3, imm_comb, alu_op_comb
};

reg [PIPE_CTRL_W-1:0]    ctrl_q;
reg                      valid_q;
reg [31:0]               val1_q;
reg [31:0]               val2_q;
reg [31:0]               rcsr_q;

assign idu_ifu_ready = ~valid_q && !need_stall;
assign idu_exu_valid = valid_q && !flush_pipeline;

// 写 CSR 第 1 拍信号（组合）
wire ecall_write1 = do_ecall && !ecall_phase;

always @(posedge clk) begin
    if (!rst) begin
        valid_q     <= 1'b0;
        pc_idu        <= 32'd0;
        ctrl_q      <= '0;
        // val1_q      <= 32'd0;
        // val2_q      <= 32'd0;
        ecall_phase <= 1'b0;
        mcause_hold <= 32'd0;
    end
    else if ((exu_idu_ready && valid_q) || flush_pipeline) begin
        valid_q     <= 1'b0;
        ecall_phase <= 1'b0;
    end
    else if (valid_q && do_ecall && !ecall_phase) begin
        // ecall/mret 第 1 拍完成，进入第 2 拍
        ecall_phase <= 1'b1;
    end
    else if (valid_q && ecall_phase) begin
        // 第 2 拍：写 mcause 完成
        ecall_phase <= 1'b0;
    end
    else if (ifu_idu_valid && idu_ifu_ready && !need_stall) begin
        // 新指令进入
        valid_q     <= 1'b1;
        pc_idu      <= pc_ifu;
        ctrl_q      <= ctrl_comb;
        val1_q      <= val_raddr1;
        val2_q      <= val_raddr2;
        rcsr_q      <= rcsrdata;

        if (do_ecall) begin
            ecall_phase <= 1'b0;          // 开始第 1 拍
            mcause_hold <= (is_ecall) ? 32'd11 : 32'd3;   // ecall=11, mret=3
        end
        else begin
            ecall_phase <= 1'b0;
        end
    end
end

assign alu_op_idu = ctrl_q[4:0];
assign val_raddr1_idu = val1_q;
assign val_raddr2_idu = val2_q;
assign rcsrdata_idu = rcsr_q;


endmodule
