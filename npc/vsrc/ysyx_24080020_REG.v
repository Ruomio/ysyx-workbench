`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_REG
(
    input clk,
    input rst,

    input skip_ref_mem,

    input [`ysyx_24080020_WIDTH-1:0] pc_lsu,
    output reg [`ysyx_24080020_WIDTH-1:0] pc_wbu,

    input [`ysyx_24080020_REG_WIDTH-1:0] raddr1,
    input [`ysyx_24080020_REG_WIDTH-1:0] raddr2,

    input is_load_mem,
    input is_dnpc_mem,
    input [`ysyx_24080020_WIDTH-1:0] dnpc_mem,

    input wen_mem,
    input [`ysyx_24080020_REG_WIDTH-1:0] waddr_mem,
    // input [`ysyx_24080020_WIDTH-1:0] alu_out_mem,
    // input [`ysyx_24080020_WIDTH-1:0] mrdata_mem,
    input [`ysyx_24080020_WIDTH-1:0] rd_data_mem,
    output reg [`ysyx_24080020_REG_WIDTH-1:0] waddr_wb,
    output reg [`ysyx_24080020_WIDTH-1:0] rd_data_wb,
    output reg wen_wb,

    input is_ebreak_lsu,
    // output [`ysyx_24080020_WIDTH-1:0] result,

    //csr
    input wcsren_mem,
    input [2:0] wcsraddr_mem,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata_mem,
    input wcsren2_mem,
    input [2:0] wcsraddr2_mem,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata2_mem,
    input [2:0] rcsraddr,

    // out src1 & src2
    output [`ysyx_24080020_WIDTH-1:0] val_raddr1,
    output [`ysyx_24080020_WIDTH-1:0] val_raddr2,
    // out csr
    output [`ysyx_24080020_WIDTH-1:0] rcsrdata,

    input mem_wb_valid,
    // input ifu_wb_ready,
    // output reg wb_ifu_valid,
    output reg wb_mem_ready
);
`ifdef CONFIG_DPIC
    import "DPI-C" function void ebreak();
    import "DPI-C" function void npc_difftest_skip_ref();

    reg is_dnpc_wb;
    reg [`ysyx_24080020_WIDTH-1:0] dnpc_wb;
    reg skip_ref_wb;
`endif

    reg [`ysyx_24080020_WIDTH-1:0] regs[0:`ysyx_24080020_REG_NUM-1];
    // csrs[0] = mepc, csrs[1] = mstatus, csrs[2] = mcause, csrs[3] = mtvec, csrs[4] = MVENDORID, csrs[5] = MARCHID
    reg [`ysyx_24080020_WIDTH-1:0] csrs[0:5];


    reg is_load_wb;

    reg cnt;


    reg wcsren_wb;
    reg [2:0] wcsraddr_wb;
    reg [`ysyx_24080020_WIDTH-1:0] wcsrdata_wb;
    reg wcsren2_wb;
    reg [2:0] wcsraddr2_wb;
    reg [`ysyx_24080020_WIDTH-1:0] wcsrdata2_wb;

    always @(posedge clk) begin
        if(!rst) begin
            wb_mem_ready <= 'b0;
            cnt <= 'b0;
        end
        else if(cnt && !wen_wb) begin
            cnt <= 'b0;
            waddr_wb <= 'b0;

`ifdef CONFIG_DPIC
            if(skip_ref_wb) begin
                skip_ref_wb <= 1'b0;
                npc_difftest_skip_ref();
            end
`endif
        end
        else if(mem_wb_valid && wb_mem_ready) begin
            wb_mem_ready <= 'b0;

            // shake hands successfully
            waddr_wb <= waddr_mem;
            rd_data_wb <= rd_data_mem;

            wcsren_wb <= wcsren_mem;
            wcsraddr_wb <= wcsraddr_mem;
            wcsrdata_wb <= wcsrdata_mem;

            wcsren2_wb <= wcsren2_mem;
            wcsraddr2_wb <= wcsraddr2_mem;
            wcsrdata2_wb <= wcsrdata2_mem;

            is_load_wb <= is_load_mem;

            pc_wbu <= pc_lsu;


            cnt <= 'b1;



            `ifdef CONFIG_DPIC
            is_dnpc_wb <= is_dnpc_mem;
            dnpc_wb <= dnpc_mem;
            skip_ref_wb <= skip_ref_mem;
            if(is_ebreak_lsu) ebreak();
            `endif
        end
        else if(mem_wb_valid) begin
            wb_mem_ready <= 1'b1;
        end
    end

    // regs write - 优化的集中式实现
    integer j;
    always @(posedge clk) begin
        if (!rst) begin
            for (j = 0; j < `ysyx_24080020_REG_NUM; j = j + 1) begin
                regs[j] <= 32'b0;
            end
        end else if (wen_wb && waddr_wb != 4'b0) begin
            regs[waddr_wb] <= rd_data_wb;
        end
        // 寄存器0始终保持为0
        regs[0] <= 32'b0;
    end

    always @(posedge clk) begin
        if(!rst) begin
            wen_wb <= 'b0;
        end
        else if(wen_wb) begin
            wen_wb <= 1'b0;
        end
        else if(mem_wb_valid && wb_mem_ready) begin
            wen_wb <= wen_mem;
        end
    end

    // csrs write - 优化实现
    always @(posedge clk) begin
        if(!rst) begin
            csrs[0] <= 32'b0;           // mepc
            csrs[1] <= 32'h1800;        // mstatus
            csrs[2] <= 32'b0;           // mcause
            csrs[3] <= 32'b0;           // mtvec
            csrs[4] <= 32'h79737978;    // MVENDORID
            csrs[5] <= 32'h16f6e94;     // MARCHID
        end
        else  begin
            if(wcsren_wb && wcsraddr_wb < 3'd6) csrs[wcsraddr_wb] <= wcsrdata_wb;
            if(wcsren2_wb && wcsraddr2_wb < 3'd6) csrs[wcsraddr2_wb] <= wcsrdata2_wb;
        end
    end

    // 读取端口优化 - 显式多路复用器避免大型组合逻辑
    reg [`ysyx_24080020_WIDTH-1:0] val_raddr1_reg;
    reg [`ysyx_24080020_WIDTH-1:0] val_raddr2_reg;
    reg [`ysyx_24080020_WIDTH-1:0] rcsrdata_reg;
    
    always @(*) begin
        case(raddr1)
            4'd0: val_raddr1_reg = 32'b0;
            4'd1: val_raddr1_reg = regs[1];
            4'd2: val_raddr1_reg = regs[2];
            4'd3: val_raddr1_reg = regs[3];
            4'd4: val_raddr1_reg = regs[4];
            4'd5: val_raddr1_reg = regs[5];
            4'd6: val_raddr1_reg = regs[6];
            4'd7: val_raddr1_reg = regs[7];
            4'd8: val_raddr1_reg = regs[8];
            4'd9: val_raddr1_reg = regs[9];
            4'd10: val_raddr1_reg = regs[10];
            4'd11: val_raddr1_reg = regs[11];
            4'd12: val_raddr1_reg = regs[12];
            4'd13: val_raddr1_reg = regs[13];
            4'd14: val_raddr1_reg = regs[14];
            4'd15: val_raddr1_reg = regs[15];
            default: val_raddr1_reg = 32'b0;
        endcase
    end
    
    always @(*) begin
        case(raddr2)
            4'd0: val_raddr2_reg = 32'b0;
            4'd1: val_raddr2_reg = regs[1];
            4'd2: val_raddr2_reg = regs[2];
            4'd3: val_raddr2_reg = regs[3];
            4'd4: val_raddr2_reg = regs[4];
            4'd5: val_raddr2_reg = regs[5];
            4'd6: val_raddr2_reg = regs[6];
            4'd7: val_raddr2_reg = regs[7];
            4'd8: val_raddr2_reg = regs[8];
            4'd9: val_raddr2_reg = regs[9];
            4'd10: val_raddr2_reg = regs[10];
            4'd11: val_raddr2_reg = regs[11];
            4'd12: val_raddr2_reg = regs[12];
            4'd13: val_raddr2_reg = regs[13];
            4'd14: val_raddr2_reg = regs[14];
            4'd15: val_raddr2_reg = regs[15];
            default: val_raddr2_reg = 32'b0;
        endcase
    end
    
    always @(*) begin
        case(rcsraddr)
            3'd0: rcsrdata_reg = csrs[0];
            3'd1: rcsrdata_reg = csrs[1];
            3'd2: rcsrdata_reg = csrs[2];
            3'd3: rcsrdata_reg = csrs[3];
            3'd4: rcsrdata_reg = csrs[4];
            3'd5: rcsrdata_reg = csrs[5];
            default: rcsrdata_reg = 32'b0;
        endcase
    end

    assign val_raddr1 = val_raddr1_reg;
    assign val_raddr2 = val_raddr2_reg;
    assign rcsrdata = rcsrdata_reg;
endmodule
