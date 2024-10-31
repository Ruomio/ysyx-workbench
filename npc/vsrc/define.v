`define ysyx_24080020_MBASE 32'h80000000
`define ysyx_24080020_WIDTH 32
`define ysyx_24080020_LEN 4
`define ysyx_24080020_MEM 10
`define ysyx_24080020_CSR_WIDTH 12
`define ysyx_24080020_MEPC_ADDR 12'h341
`define ysyx_24080020_MSTATUS_ADDR 12'h300
`define ysyx_24080020_MCAUSE_ADDR 12'h342
`define ysyx_24080020_MTVEC_ADDR 12'h305


`define ysyx_24080020_OPCODE 6:0
`define ysyx_24080020_RD 11:7
`define ysyx_24080020_FUNCT3 14:12
`define ysyx_24080020_RS1 19:15
`define ysyx_24080020_RS2 24:20     // same location as shamt
`define ysyx_24080020_FUNCT7 31:25

`define ysyx_24080020_EBREAK 7'b1110011

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
`define ysyx_24080020_SRI 3'b101


`define ysyx_24080020_I_TYPEI 7'b0000011
`define ysyx_24080020_LB 3'b000
`define ysyx_24080020_LH 3'b001
`define ysyx_24080020_LW 3'b010
`define ysyx_24080020_LBU 3'b100
`define ysyx_24080020_LHU 3'b101


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

// OTHER
`define ysyx_24080020_LUI 7'b0110111 
`define ysyx_24080020_AUIPC 7'b0010111 
`define ysyx_24080020_JAL 7'b1101111
`define ysyx_24080020_JALR 7'b1100111