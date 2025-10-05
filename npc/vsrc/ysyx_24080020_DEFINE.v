// `define CONFIG_DPIC // define in makefile
// ysyxSoCFull and ysyx_24080020_NPC are defined in makefile or iverilog-default

`ifndef ysyxSoCFull
`ifndef ysyx_24080020_NPC
`define ysyx_24080020_NPC
`endif
`endif

`ifdef ysyxSoCFull
`define ysyx_24080020_MBASE 32'h30000000
// IOE
`define ysyx_24080020_CLINT_ADDR  32'h02000000
`endif

`ifdef ysyx_24080020_NPC
`define ysyx_24080020_MBASE 32'h80000000
// IOE
`define ysyx_24080020_CLINT_ADDR 32'ha0000048
`define ysyx_24080020_DEVICE_BASE 32'ha0000000
`define ysyx_24080020_SERIAL_PORT 32'ha00003f8
`endif

// inst cache
`define USE_ICACHE
`define ICACHE_PIPELINE
`define ysyx_24080020_CACHE_SIZE 4
`define ysyx_24080020_CACHE_NUM 2
`define ysyx_24080020_CACHE_WAY 2

// branch
`define ysyx_24080020_BRANCH_SIZE 4
`define ysyx_24080020_BRANCH_NUM 2
`define ysyx_24080020_BRANCH_WAY 2

`define ysyx_24080020_WIDTH 32
`define ysyx_24080020_LEN 4
`define ysyx_24080020_MEM 10
`define ysyx_24080020_CSR_WIDTH 12
`define ysyx_24080020_MEPC_ADDR 12'h341
`define ysyx_24080020_MSTATUS_ADDR 12'h300
`define ysyx_24080020_MCAUSE_ADDR 12'h342
`define ysyx_24080020_MTVEC_ADDR 12'h305
`define ysyx_24080020_MVENDORID_ADDR 12'hf11
`define ysyx_24080020_MARCHID_ADDR 12'hf12

// reg
`define ysyx_24080020_E_EXTERN

`ifdef ysyx_24080020_E_EXTERN
`define ysyx_24080020_REG_NUM 16
`define ysyx_24080020_REG_WIDTH 4
`define ysyx_24080020_RD 10:7
`define ysyx_24080020_RS1 18:15
`define ysyx_24080020_RS2 23:20     // same location as shamt
`else
`define ysyx_24080020_REG_NUM 32
`define ysyx_24080020_REG_WIDTH 5
`define ysyx_24080020_RD 11:7
`define ysyx_24080020_RS1 19:15
`define ysyx_24080020_RS2 24:20     // same location as shamt
`endif

`define ysyx_24080020_OPCODE 6:0
`define ysyx_24080020_FUNCT3 14:12
`define ysyx_24080020_FUNCT7 31:25

// ALU OP code
`define ysyx_24080020_ALU_OP_WIDTH 5
`define ysyx_24080020_ALU_ADD 5'b00000
`define ysyx_24080020_ALU_SUB 5'b00001
`define ysyx_24080020_ALU_SLT 5'b00010
`define ysyx_24080020_ALU_SLTU 5'b00011
`define ysyx_24080020_ALU_OR 5'b00100
`define ysyx_24080020_ALU_XOR 5'b00101
`define ysyx_24080020_ALU_AND 5'b00110
`define ysyx_24080020_ALU_SLL 5'b00111
`define ysyx_24080020_ALU_SRL 5'b01000
`define ysyx_24080020_ALU_SRA 5'b01001
`define ysyx_24080020_ALU_BEQ 5'b01010
`define ysyx_24080020_ALU_BNE 5'b01011
`define ysyx_24080020_ALU_BLT 5'b01100
`define ysyx_24080020_ALU_BLTU 5'b01101
`define ysyx_24080020_ALU_BGE 5'b01110
`define ysyx_24080020_ALU_BGEU 5'b01111
`define ysyx_24080020_ALU_JALR 5'b10000






// I-TYPE
`define ysyx_24080020_I_TYPE 7'b0010011
`define ysyx_24080020_IMM_I 31:20
`define ysyx_24080020_ADDI 3'b000
`define ysyx_24080020_SLTI 3'b010
`define ysyx_24080020_SLTIU 3'b011
`define ysyx_24080020_XORI 3'b100
`define ysyx_24080020_ORI 3'b110
`define ysyx_24080020_ANDI 3'b111
`define ysyx_24080020_SLLI 3'b001
`define ysyx_24080020_SRLAI 3'b101


`define ysyx_24080020_LOAD_TYPE 7'b0000011
`define ysyx_24080020_LB 3'b000
`define ysyx_24080020_LH 3'b001
`define ysyx_24080020_LW 3'b010
`define ysyx_24080020_LBU 3'b100
`define ysyx_24080020_LHU 3'b101

`define ysyx_24080020_FENCEI_TYPE 7'b0001111
`define ysyx_24080020_FENCEI 3'b001

// R-TYPE
`define ysyx_24080020_R_TYPE 7'b0110011
`define ysyx_24080020_ADD_SUB 3'b000
`define ysyx_24080020_SLL 3'b001
`define ysyx_24080020_SLT 3'b010
`define ysyx_24080020_SLTU 3'b011
`define ysyx_24080020_XOR 3'b100
`define ysyx_24080020_SRLA 3'b101
`define ysyx_24080020_OR 3'b110
`define ysyx_24080020_AND 3'b111


// U-TYPE
// `define ysyx_24080020_U_TYPE 7'b0010111     // 7'b0110111
`define ysyx_24080020_IMM_U 31:12



// B-TYPE
`define ysyx_24080020_B_TYPE 7'b1100011
`define ysyx_24080020_BEQ 3'b000
`define ysyx_24080020_BNE 3'b001
`define ysyx_24080020_BLT 3'b100
`define ysyx_24080020_BGE 3'b101
`define ysyx_24080020_BLTU 3'b110
`define ysyx_24080020_BGEU 3'b111


// S-TYPE
`define ysyx_24080020_S_TYPE 7'b0100011
`define ysyx_24080020_SB 3'b000
`define ysyx_24080020_SH 3'b001
`define ysyx_24080020_SW 3'b010


// CSR-TYPE
`define ysyx_24080020_MRET 32'b00110000001000000000000001110011
`define ysyx_24080020_ECALL 32'h00000073
`define ysyx_24080020_CSR_TYPE 7'b1110011
`define ysyx_24080020_ECALL_EBREAK 3'b000
`define ysyx_24080020_CSRRW 3'b001
`define ysyx_24080020_CSRRS 3'b010
`define ysyx_24080020_CSRRC 3'b011
`define ysyx_24080020_CSRRWI 3'b101
`define ysyx_24080020_CSRRSI 3'b110
`define ysyx_24080020_CSRRCI 3'b111

// OTHER
`define ysyx_24080020_LUI 7'b0110111
`define ysyx_24080020_AUIPC 7'b0010111
`define ysyx_24080020_JAL 7'b1101111
`define ysyx_24080020_JALR 7'b1100111


`define ysyx_24080020_EBREAK 7'b1110011
