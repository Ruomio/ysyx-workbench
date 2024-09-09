`define ysyx_24080020_MBASE 32'h80000000
`define ysyx_24080020_WIDTH 32
`define ysyx_24080020_LEN 4
`define ysyx_24080020_MEM 10


`define ysyx_24080020_OPCODE 6:0
`define ysyx_24080020_RD 11:7
`define ysyx_24080020_FUNCT3 14:12
`define ysyx_24080020_RS1 19:15
`define ysyx_24080020_RS2 24:20
`define ysyx_24080020_FUNCT& 31:25

`define ysyx_24080020_EBREAK 7'b1110011

// I-TYPE
`define ysyx_24080020_I_TYPE 7'b0000011
`define ysyx_24080020_IMM_I 31:20
`define ysyx_24080020_ADDI 3'b000