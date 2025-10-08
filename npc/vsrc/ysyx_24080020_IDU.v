// `include "ysyx_24080020_DEFINE.v"
// module ysyx_24080020_IDU (
//     input clk,
//     input rst,
//
// `ifdef CONFIG_DPIC
//     output reg is_ebreak,
//
// `endif
//
//
//     // input data_adventure,
//     input need_stall,
//     input rs1_conflict,
//     input rs2_conflict,
//     input [`ysyx_24080020_WIDTH-1:0] rd_data1_forward,
//     input [`ysyx_24080020_WIDTH-1:0] rd_data2_forward,
//
//     input [`ysyx_24080020_WIDTH-1:0] inst_ifu,
//     input [`ysyx_24080020_WIDTH-1:0] pc_ifu,
//     input flush_pipeline,
//
//     // reg
//     output reg wen_idu,
//     output [`ysyx_24080020_REG_WIDTH-1:0] rs1,
//     output [`ysyx_24080020_REG_WIDTH-1:0] rs2,
//     input [`ysyx_24080020_WIDTH-1:0] val_raddr1,
//     input [`ysyx_24080020_WIDTH-1:0] val_raddr2,
//     output reg [`ysyx_24080020_REG_WIDTH-1:0] waddr_idu,
//     output reg [`ysyx_24080020_WIDTH-1:0] wdata_idu,
//     // output reg is_load_idu,
//     output reg is_dnpc_idu,
//     output reg is_jal_idu,
//     output reg is_btype_idu,
//     output reg is_jalr_idu,
//     output reg is_csrtype_idu,
//     // output reg [`ysyx_24080020_WIDTH-1:0] dnpc_idu,
//     output reg fencei_idu,
//
//     // csrs
//     input [`ysyx_24080020_WIDTH-1:0] rcsrdata,
//     output [2:0] rcsraddr_,
//     output reg wcsren_idu,
//     output [2:0] wcsraddr_idu_,
//     output reg [`ysyx_24080020_WIDTH-1:0] wcsrdata_idu,
//     output reg wcsren2_idu,
//     output [2:0] wcsraddr2_idu_,
//     output reg [`ysyx_24080020_WIDTH-1:0] wcsrdata2_idu,
//
//     // alu control
//     output reg [`ysyx_24080020_ALU_OP_WIDTH-1:0] alu_op_idu,
//     output reg [`ysyx_24080020_WIDTH-1:0] pc_idu,
//     output reg [`ysyx_24080020_WIDTH-1:0] src1_idu,
//     output reg [`ysyx_24080020_WIDTH-1:0] src2_idu,
//     output [`ysyx_24080020_WIDTH-1:0] imm_idu,
//     // output reg [`ysyx_24080020_WIDTH-1:0] branch_src1_idu,
//     output reg alu_src2_con_idu,
//
//
//     // memory
//     output reg mren_idu,
//     output reg mrtype_idu,
//     output reg mwen_idu,
//     output reg [3:0] mwmask_idu,
//     output reg [3:0] mrlen_idu,
//
//
//     input ifu_idu_valid,
//     input exu_idu_ready,
//     output reg idu_ifu_ready,
//     output idu_exu_valid_reg
//
// );
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
    // REGFILE 2 读 1 写（端口不变）
    output wire [`ysyx_24080020_REG_WIDTH-1:0] rs1,
    output wire [`ysyx_24080020_REG_WIDTH-1:0] rs2,
    input  wire [`ysyx_24080020_WIDTH-1:0]     val_raddr1,
    input  wire [`ysyx_24080020_WIDTH-1:0]     val_raddr2,
    output wire [`ysyx_24080020_REG_WIDTH-1:0] waddr_idu,
    output wire [`ysyx_24080020_WIDTH-1:0]     wdata_idu,
    output wire                                wen_idu,
    // CSR 1 读 2 写（恢复双写口）
    output wire [2:0]  rcsraddr,
    input  wire [31:0] rcsrdata,
    output wire        wcsren_idu,
    output wire [2:0]  wcsraddr_idu,
    output wire [31:0] wcsrdata_idu,
    output wire        wcsren2_idu,
    output wire [2:0]  wcsraddr2_idu,
    output wire [31:0] wcsrdata2_idu,
    // 其余控制
    output wire        is_ebreak_idu,
    output wire [`ysyx_24080020_ALU_OP_WIDTH-1:0] alu_op_idu,
    output wire [31:0] imm_idu,
    output wire        is_branch_idu,
    output wire        is_jal_idu,
    output wire        is_jalr_idu,
    output wire        is_load_idu,
    output wire        is_store_idu,
    output wire        is_csr_idu,
    output wire        fencei_idu,
    output wire [2:0]  mem_len_idu,
    output wire [2:0]  mem_wmask_idu
);

//=========================================================================
// 1. 立即数 2 级选择（与上一版相同）
//=========================================================================
localparam IMM_I = {{20{inst_ifu[31]}}, inst_ifu[31:20]};
localparam IMM_S = {{20{inst_ifu[31]}}, inst_ifu[31:25], inst_ifu[11:7]};
localparam IMM_B = {{20{inst_ifu[31]}}, inst_ifu[7], inst_ifu[30:25], inst_ifu[11:8], 1'b0};
localparam IMM_U = {inst_ifu[31:12], 12'b0};
localparam IMM_J = {{12{inst_ifu[31]}}, inst_ifu[19:12], inst_ifu[20], inst_ifu[30:21], 1'b0};

wire [1:0] imm_type;
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

assign imm_idu = (imm_type == 2'b00) ? IMM_I :
                 (imm_type == 2'b01) ? IMM_S :
                 (imm_type == 2'b10) ? IMM_B :
                                       IMM_U;          // U/J 共用

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
wire is_ebreak = (inst_ifu == `ysyx_24080020_EBREAK);

wire [`ysyx_24080020_ALU_OP_WIDTH-1:0] alu_op_comb;
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
        `ysyx_24080020_S_TYPE,
        `ysyx_24080020_B_TYPE: alu_op_comb = `ysyx_24080020_ALU_ADD;
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
assign rs1 = inst_ifu[`ysyx_24080020_RS1];
assign rs2 = (is_r_type || is_s_type || is_b_type) ? inst_ifu[`ysyx_24080020_RS2] : 5'd0;

assign waddr_idu = inst_ifu[`ysyx_24080020_RD];
assign wdata_idu = (is_load_idu) ? val_raddr2 :      // LSU 回写
                   (is_csr_idu)   ? csr_rdata :      // CSR 回写
                                    val_raddr1;       // ALU/PC+4
assign wen_idu   = (is_r_type || is_i_type || is_u_type || is_j_type || is_jr_type || is_load_idu || is_csr_idu) &&
                   (inst_ifu[`ysyx_24080020_RD] != 5'd0);

//=========================================================================
// 4. CSR 1 读 2 写：地址/数据复用，写优先
//=========================================================================
wire [2:0] csr_imm = inst_ifu[`ysyx_24080020_IMM_I][2:0];

assign rcsraddr        = csr_imm;                     // 读口直接连
// 写口 1
assign wcsraddr_idu    = csr_imm;
assign wcsrdata_idu    = val_raddr1;
assign wcsren_idu      = is_csr && (funct3 == 3'b001 || funct3 == 3'b101); // CSRRW/CSRRS
// 写口 2
assign wcsraddr2_idu   = csr_imm;
assign wcsrdata2_idu   = val_raddr1;
assign wcsren2_idu     = is_csr && (funct3 == 3'b010 || funct3 == 3'b110); // CSRRC/CSRRWI

//=========================================================================
// 5. 其余控制信号（极简）
//=========================================================================
assign is_branch_idu = is_b_type;
assign is_jal_idu    = is_j_type;
assign is_jalr_idu   = is_jr_type;
assign is_load_idu   = (opcode == `ysyx_24080020_LOAD_TYPE);
assign is_store_idu  = is_s_type;
assign is_csr_idu    = is_csr;
assign fencei_idu    = is_fencei;
assign is_ebreak_idu = is_ebreak;

// 存储控制
assign mem_len_idu  = (is_load_idu) ?
                      funct3 : 'b0;
assign mem_wmask_idu = (is_store_idu) ?
                      funct3 : 'b0;

//=========================================================================
// 6. 极简流水线握手 & 锁存（）
//=========================================================================
localparam PIPE_CTRL_W = 19;
wire [PIPE_CTRL_W-1:0] ctrl_comb = {
    is_branch_idu, is_jal_idu, is_jalr_idu,
    is_load_idu, is_store_idu, is_csr_idu, fencei_idu, is_ebreak_idu,
    mem_len_idu, mem_wmask_idu, alu_op_comb
};

reg [31:0]               pc_q;
reg [PIPE_CTRL_W-1:0]    ctrl_q;
reg                      valid_q;

assign idu_ifu_ready = ~valid_q;
assign idu_exu_valid = valid_q;

always @(posedge clk) begin
    if (!rst) begin
        valid_q <= 1'b0;
        pc_q    <= 32'd0;
        ctrl_q  <= '0;
    end
    else if (exu_idu_ready || flush_pipeline) begin
        valid_q <= 1'b0;
    end
    else if (ifu_idu_valid && !valid_q && !need_stall) begin
        valid_q <= 1'b1;
        pc_q    <= pc_ifu;
        ctrl_q  <= ctrl_comb;
    end
end

assign alu_op_idu = ctrl_q[`ysyx_24080020_ALU_OP_WIDTH-1:0];

endmodule
