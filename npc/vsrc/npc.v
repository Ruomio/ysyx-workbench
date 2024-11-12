`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_NPC(
    input clk,
    input rst,
    output [31:0] pc
);

  // pc
  wire [3:0] pc_len;
  wire [`ysyx_24080020_WIDTH-1:0] snpc;
  wire [`ysyx_24080020_WIDTH-1:0] dnpc;
  wire is_dnpc;

  // inst
  wire [`ysyx_24080020_WIDTH-1:0] inst;
  wire [6:0] opcode;
  wire [4:0] rd;
  wire [2:0] funct3;
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [`ysyx_24080020_WIDTH-1:0] imm;
  wire [6:0] funct7;


  // wireister
  wire wen;
  wire [4:0] waddr;
  wire [`ysyx_24080020_WIDTH-1:0] wdata;
  wire [`ysyx_24080020_WIDTH-1:0] src1;
  wire [`ysyx_24080020_WIDTH-1:0] src2;
  // csrs
  wire wcsren;
  wire [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr;
  wire [`ysyx_24080020_WIDTH-1:0] wcsrdata;
  wire wcsren2;
  wire [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2;
  wire [`ysyx_24080020_WIDTH-1:0] wcsrdata2;
  wire [`ysyx_24080020_CSR_WIDTH-1:0] rcsraddr;
  wire [`ysyx_24080020_WIDTH-1:0] rcsrdata;

  // memory
  wire mwen;
  wire [3:0] mrlen;
  wire [3:0] mwlen;
  wire [`ysyx_24080020_WIDTH-1:0] mraddr;
  wire [`ysyx_24080020_WIDTH-1:0] mwaddr;
  wire [`ysyx_24080020_WIDTH-1:0] mwdata;
  wire [`ysyx_24080020_WIDTH-1:0] mrdata;

  // bus control
  // IFU -> DEU -> EXU -> LSU -> WB
  // IFU: pc -> ir.
  wire pc_ir_valid;
  wire ir_pc_ready;

  // DEU: IR -> idu
  wire ir_idu_valid;
  wire idu_ir_ready;

  // EXU: idu -> exu
  wire idu_exu_valid;
  wire exu_idu_ready;

  // LSU: exu -> mem;
  wire exu_mem_valid;
  wire mem_exu_ready;

  // WB: mem -> reg
  wire mem_reg_valid;
  wire reg_mem_rerady;

  // WB -> IFU
  wire reg_pc_valid;

    ysyx_24080020_PC u_pc(
        .clk(clk), 
        .rst(rst), 
        .reg_pc_valid(reg_pc_valid), 
        .ir_pc_ready(ir_pc_ready), 
        .is_dnpc(is_dnpc), 
        .dnpc(dnpc), 
        .pc(pc), 
        .pc_len(pc_len),
        .pc_reg_ready(pc_reg_ready),
        .pc_ir_valid(pc_ir_valid)
    );

    ysyx_24080020_IR u_ir(
        .clk(clk),
        .rst(rst),
        .pc_ir_valid(pc_ir_valid),
        .reg_ir_ready(reg_ir_ready),
        .pc(pc),
        .pc_len(pc_len),
        .inst(inst),
        .ir_pc_ready(ir_pc_ready),
        .ir_reg_valid(ir_reg_valid)
    );

    ysyx_24080020_MEM u_mem(
        .clk(clk), 
        .rst(rst), 
        .pc_ir_valid(pc_ir_valid),
        .reg_ir_ready(reg_ir_ready),
        .mraddr(mraddr), 
        .mwaddr(mwaddr), 
        .mwlen(mwlen), 
        .mrlen(mrlen), 
        .mwdata(mwdata), 
        .mwen(mwen), 
        .mrdata(mrdata),
        .ir_reg_valid(ir_reg_valid)
    );
    
    ysyx_24080020_IFU ifu(
        .clk(clk), 
        .rst(rst), 
        .pc(pc), 
        .len(`ysyx_24080020_LEN), 
        .snpc(snpc)
    );

    ysyx_24080020_IDU idu(
        .clk(clk),
        .rst(rst),
        .ir_idu_valid(ir_idu_valid),
        .exu_idu_ready(exu_idu_ready),
        .inst(inst), 
        .opcode(opcode), 
        .rd(rd), 
        .funct3(funct3), 
        .rs1(rs1), 
        .rs2(rs2), 
        .imm(imm), 
        .funct7(funct7),
        .idu_exu_valid(idu_exu_valid),
        .idu_ir_ready(idu_ir_ready)
    );

    ysyx_24080020_REG u_reg(
        .clk(clk), 
        .rst(rst), 
        .raddr1(rs1), 
        .raddr2(rs2), 
        .wen(wen), 
        .waddr(waddr), 
        .wdata(wdata), 
        .wcsren(wcsren),
        .wcsraddr(wcsraddr),
        .wcsrdata(wcsrdata),
        .wcsren2(wcsren2),
        .wcsraddr2(wcsraddr2),
        .wcsrdata2(wcsrdata2),
        .rcsraddr(rcsraddr),
        .val_raddr1(src1), 
        .val_raddr2(src2),
        .rcsrdata(rcsrdata)        
    );

    ysyx_24080020_EXU exu(
        .inst(inst),
        .opcode(opcode), 
        .pc(pc), 
        .funct3(funct3), 
        .funct7(funct7), 
        // reg
        .val_raddr1(src1), 
        .val_raddr2(src2), 
        .rd(rd), 
        .imm(imm),
        // csrs
        .rcsrdata(rcsrdata), 
        .mrdata(mrdata),
        .waddr(waddr), 
        .wdata(wdata), 
        .wen(wen), 
        .is_dnpc(is_dnpc), 
        .dnpc(dnpc), 
        .mraddr(mraddr),
        .mwaddr(mwaddr), 
        .mwdata(mwdata), 
        .mwen(mwen),
        .mwlen(mwlen),
        .mrlen(mrlen),
        // csrs
        .wcsren(wcsren),
        .wcsraddr(wcsraddr),
        .wcsrdata(wcsrdata),
        .wcsren2(wcsren2),
        .wcsraddr2(wcsraddr2),
        .wcsrdata2(wcsrdata2),
        .rcsraddr(rcsraddr)
    );


endmodule
