`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_NPC(
    input clk,
    input rst
);

  // pc
  // wire [3:0] pc_len;
  wire [`ysyx_24080020_WIDTH-1:0] pc_ifu, pc_idu;
  // wire [`ysyx_24080020_WIDTH-1:0] snpc, snpc_ifu, snpc_idu, snpc_exu;
  wire [`ysyx_24080020_WIDTH-1:0] dnpc_idu, dnpc_exu, dnpc_mem;
  wire is_dnpc_idu, is_dnpc_exu, is_dnpc_mem, is_dnpc_wb;

  // inst
  wire [`ysyx_24080020_WIDTH-1:0] inst_ifu, inst_idu;
  // wire [6:0] opcode_idu;
  // wire [4:0] rd_idu, rd_exu, rd_mem, rd_wb;
  // wire [2:0] funct3_idu, funct3_exu;
  // wire [6:0] funct7_idu, funct7_exu;
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [`ysyx_24080020_WIDTH-1:0] imm_idu, imm_exu;
  
  wire is_load_idu, is_load_exu, is_load_mem, is_load_wb;
  wire alu_src2_con_idu, alu_src2_con_exu;
  // wire reg_dst_con_idu, reg_dst_con_exu;


  // reg
  wire wen_idu, wen_exu, wen_mem, wen_wb;
  wire [4:0] waddr_idu, waddr_exu, waddr_mem, waddr_wb;
  wire [`ysyx_24080020_WIDTH-1:0] wdata_exec, wdata_mem, wdata_wb;
  wire [`ysyx_24080020_WIDTH-1:0] src1_idu, src1_exu;
  wire [`ysyx_24080020_WIDTH-1:0] src2_idu, src2_exu, src2_mem;
  // csrs
  wire wcsren_idu, wcsren_exu, wcsren_mem, wcsren_wb;
  wire [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr_idu, wcsraddr_exu, wcsraddr_mem, wcsraddr_wb;
  wire [`ysyx_24080020_WIDTH-1:0] wcsrdata_idu, wcsrdata_exu, wcsrdata_mem, wcsrdata_wb;
  wire wcsren2_idu, wcsren2_exu, wcsren2_mem, wcsren2_wb;
  wire [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2_idu, wcsraddr2_exu, wcsraddr2_mem, wcsraddr2_wb;
  wire [`ysyx_24080020_WIDTH-1:0] wcsrdata2_idu, wcsrdata2_exu, wcsrdata2_mem, wcsrdata2_wb;
  wire [`ysyx_24080020_CSR_WIDTH-1:0] rcsraddr_idu, rcsraddr_exu, rcsraddr_mem, rcsraddr_wb;
  wire [`ysyx_24080020_WIDTH-1:0] rcsrdata_idu, rcsrdata_exu, rcsrdata_mem, rcsrdata_wb;

  // memory
  wire mwen_idu, mwen_exu, mwen_mem;
  wire mren_idu, mren_exu, mren_mem;
  wire mrtype_idu, mrtype_exu, mrtype_mem;
  wire [3:0] mrlen_idu, mrlen_exu, mrlen_mem, mrlen_wb;
  wire [3:0] mwmask_idu, mwmask_exu, mwmask_mem, mwmask_wb;
  wire [`ysyx_24080020_WIDTH-1:0] mraddr_exu, mraddr_mem;
  wire [`ysyx_24080020_WIDTH-1:0] mwaddr_exu, mwaddr_mem;
  wire [`ysyx_24080020_WIDTH-1:0] mwdata_exu, mwdata_mem;
  wire [`ysyx_24080020_WIDTH-1:0] mrdata_exu, mrdata_mem, mrdata_wb;

  // alu
  wire [3:0] alu_op_idu, alu_op_exu;
  // wire [`ysyx_24080020_WIDTH-1:0] alu_src1;
  // wire [`ysyx_24080020_WIDTH-1:0] alu_src2;
  // wire [`ysyx_24080020_WIDTH-1:0] alu_out;

  // bus control
  // IFU -> DEU -> EXU -> LSU -> WB
  // ifu -> idu.
  wire ifu_idu_valid;
  wire idu_ifu_ready;

  // idu -> exu
  wire idu_exu_valid;
  wire exu_idu_ready;

  // exu -> mem;
  wire exu_mem_valid;
  wire mem_exu_ready;

  // mem -> reg
  wire mem_wb_valid;
  wire wb_mem_ready;

  // WB -> IFU
  wire wb_ifu_valid;
  wire ifu_wb_ready;

    
    ysyx_24080020_IFU ifu(
        .clk(clk), 
        .rst(rst), 
        .dnpc_wb(dnpc_wb),
        .is_dnpc_wb(is_dnpc_wb),
        .pc_ifu(pc_ifu), 
        .inst_ifu(inst_ifu),
        .wb_ifu_valid(wb_ifu_valid),
        .id_ifu_ready(idu_ifu_ready),
        .ifu_idu_valid(ifu_idu_valid),
        .ifu_wb_ready(ifu_wb_ready)
    );

    ysyx_24080020_IDU idu(
        .clk(clk),
        .rst(rst),
        .inst_ifu(inst_ifu), 
        .val_raddr1(val_raddr1),
        .val_raddr2(val_raddr2),
        .pc_ifu(pc_ifu),
        .imm_idu(imm_idu), 
        // .snpc_ifu(snpc_ifu),
        .wen_idu(wen_idu),
        .is_load_idu(is_load_idu),
        .is_dnpc_idu(is_dnpc_idu),
        .is_jalr_idu(is_jalr_idu),
        // .is_btype_idu(is_btype_idu),
        .is_csrtype_idu(is_csrtype_idu),
        .dnpc_idu(dnpc_idu),

        .rcsrdata(rcsrdata),
        .rcsraddr(rcsraddr),
        .wcsren_idu(wcsren_idu),
        .wcsraddr_idu(wcsraddr_idu),
        .wcsrdata(wcsrdata),
        .wcsren2_idu(wcsren2_idu),
        .wcsraddr2_idu(wcsraddr2_idu),
        .wcsrdata2_idu(wcsrdata2_idu),

        .alu_op_idu(alu_op_idu),
        .alu_src2_con(alu_src2_con),
        .pc_idu(pc_idu),
        .src1_idu(src1_idu),
        .src2_idu(src2_idu),

        .mren_idu(mren_idu),
        .mrtype_idu(mrtype_idu),
        .mrlen_idu(mrlen_idu),
        .mwen_idu(mwen_idu),
        .mwmask_idu(mwmask_idu),

        .ifu_idu_valid(ifu_idu_valid),
        .exu_idu_ready(exu_idu_ready),
        .idu_exu_valid(idu_exu_valid),
        .idu_ifu_ready(idu_ifu_ready)
    );

    ysyx_24080020_REG u_reg(
        .clk(clk), 
        .rst(rst), 
        .raddr1(rs1), 
        .raddr2(rs2), 

        .is_load_mem(is_load_mem),
        .is_dnpc_mem(is_dnpc_mem),
        .is_dnpc_wb(is_dnpc_wb),

        .wen_mem(wen_mem), 
        .waddr_mem(waddr_mem), 
        .wdata_mem(wdata_mem), 
        .mrdata_mem(mrdata_mem),
        .alu_out_mem(alu_out_mem),

        .wcsren_mem(wcsren_mem),
        .wcsraddr_mem(wcsraddr_mem),
        .wcsrdata_mem(wcsrdata_mem),
        .wcsren2_mem(wcsren2_mem),
        .wcsraddr2_mem(wcsraddr2_mem),
        .wcsrdata2_mem(wcsrdata2_mem),

        .val_raddr1(src1), 
        .val_raddr2(src2),
        .rcsraddr(rcsraddr),
        .rcsrdata(rcsrdata),

        .mem_wb_valid(mem_wb_valid),
        .ifu_wb_ready(ifu_wb_ready),
        .wb_mem_ready(wb_mem_ready),
        .wb_ifu_valid(wb_ifu_valid)
    );

    ysyx_24080020_EXU exu(
        .clk(clk),
        .rst(rst),
        .pc_idu(pc_idu),
        .imm_idu(imm_idu),
        .is_load_idu(is_load_idu),

        .is_jalr_idu(is_jalr_idu),
        .is_dnpc_idu(is_dnpc_idu),
        // .is_btype_idu(is_btype_idu),
        .dnpc_idu(dnpc_idu),
        .is_dnpc_exu(is_dnpc_exu),
        .dnpc_new_exu(dnpc_exu),

        .src1_idu(src1_idu),
        .src2_idu(src2_idu),
        .alu_op_idu(alu_op_idu),
        .alu_out_exu(alu_out_exu),

        // reg
        .wen_idu(wen_idu),
        .waddr_idu(waddr_idu),
        .wdata_idu(wdata_idu),
        .wen_exu(wen_exu),
        .waddr_exu(waddr_exu),
        .wdata_exu(wdata_exu),

        //memory
        .mwen_idu(mwen_idu),
        .mwmask_idu(mwmask_idu),
        .mren_idu(mren_idu),
        .mrtype_idu(mrtype_idu),
        .mrlen_idu(mrlen_idu),
        .mwen_exu(mwen_exu),
        .mwmask_exu(mwmask_exu),
        .mren_exu(mren_exu),
        .mrtype_exu(mrtype_exu),
        .mrlen_exu(mrlen_exu),
        .mraddr_exu(mraddr_exu),
        .mwaddr_exu(mwaddr_exu),
        .mwdata_exu(mwdata_exu),

        // csrs
        .is_csrtype_idu(is_csrtype_idu),
        .wcsren_idu(wcsren2_idu),
        .wcsraddr_idu(wcsraddr_idu),
        .wcsrdata_idu(wcsrdata_idu),
        .wcsren2_idu(wcsren2_idu),
        .wcsraddr2_idu(wcsraddr2_idu),
        .wcsrdata2_idu(wcsrdata2_idu),
        .wcsren_exu(wcsren_exu),
        .wcsraddr_exu(wcsraddr_exu),
        .wcsrdata_exu(wcsrdata_exu),
        .wcsren2_exu(wcsren2_exu),
        .wcsraddr2_exu(wcsraddr2_exu),
        .wcsrdata2_exu(wcsrdata2_exu),


        .idu_exu_valid(idu_exu_valid),
        .mem_exu_ready(mem_exu_ready),
        .exu_mem_valid(exu_mem_valid),
        .exu_idu_ready(exu_idu_ready)
    );


    ysyx_24080020_MEM u_mem(
        .clk(clk), 
        .rst(rst), 
        .mren_exu(mren_exu),
        .mrtype_exu(mrtype_exu),
        .mrlen_exu(mrlen_exu),
        .mwen_exu(mwen_exu),
        .mwmask_exu(mwmask_exu),
        .mraddr_exu(mraddr_exu),
        .mwaddr_exu(mwaddr_exu),
        .mwdata_exu(mwdata_exu),
        .mrdata_mem(mrdata_mem),
        
        .alu_out_exu(alu_out_exu),
        .alu_out_mem(alu_out_mem),

        .wcsren_exu(wcsren_exu),
        .wcsraddr_exu(wcsraddr_exu),
        .wcsrdata_exu(wcsrdata_exu),
        .wcsren2_exu(wcsren2_exu),
        .wcsraddr2_exu(wcsraddr2_exu),
        .wcsrdata2_exu(wcsrdata2_exu),
        .wcsren_mem(wcsren_mem),
        .wcsraddr_mem(wcsraddr_mem),
        .wcsrdata_mem(wcsrdata_mem),

        .wen_exu(wen_exu),
        .wen_mem(wen_mem),
        .waddr_mem(waddr_mem),

        .is_load_exu(is_load_exu),
        .is_load_mem(is_load_mem),

        .is_dnpc_exu(is_dnpc_exu),
        .is_dnpc_mem(is_dnpc_mem),

        .exu_mem_valid(exu_mem_valid),
        .wb_mem_ready(wb_mem_ready),
        .mem_exu_ready(mem_exu_ready),
        .mem_wb_valid(mem_wb_valid)
    );

endmodule
