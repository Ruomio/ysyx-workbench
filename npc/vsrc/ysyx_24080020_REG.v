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
    output reg is_dnpc_wb,
    input [`ysyx_24080020_WIDTH-1:0] dnpc_mem,
    output reg [`ysyx_24080020_WIDTH-1:0] dnpc_wb,

    input wen_mem,
    input [`ysyx_24080020_REG_WIDTH-1:0] waddr_mem,
    input [`ysyx_24080020_WIDTH-1:0] alu_out_mem,
    input [`ysyx_24080020_WIDTH-1:0] mrdata_mem,
    output reg [`ysyx_24080020_REG_WIDTH-1:0] waddr_wb,

    input is_ebreak_lsu,
    output [`ysyx_24080020_WIDTH-1:0] result,

    //csr
    input wcsren_mem,
    input [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr_mem,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata_mem,
    input wcsren2_mem,
    input [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2_mem,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata2_mem,
    input [`ysyx_24080020_CSR_WIDTH-1:0] rcsraddr,

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
`endif

    reg [`ysyx_24080020_WIDTH-1:0] regs[0:`ysyx_24080020_REG_NUM-1];
    // csrs[0] = mepc, csrs[1] = mstatus, csrs[2] = mcause, csrs[3] = mtvec
    reg [`ysyx_24080020_WIDTH-1:0] csrs[7:0];

    reg state; // 0:idle;    1:wait_ready


    reg is_load_wb;

    reg [2:0] wcsr_idx;
    reg [2:0] wcsr_idx2;
    reg [2:0] rcsr_idx;

    reg [`ysyx_24080020_WIDTH-1:0] alu_out_wb;
    reg [`ysyx_24080020_WIDTH-1:0] mrdata_wb;

    reg wen_wb;
    reg cnt;

    reg skip_ref_wb;

    reg wcsren_wb;
    reg [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr_wb;
    reg [`ysyx_24080020_WIDTH-1:0] wcsrdata_wb;
    reg wcsren2_wb;
    reg [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2_wb;
    reg [`ysyx_24080020_WIDTH-1:0] wcsrdata2_wb;

    // reg [`ysyx_24080020_WIDTH-1:0] result;

    assign result = is_load_wb == 1'b1 ? mrdata_wb : alu_out_wb;
    // always @(mrdata_wb or alu_out_wb or is_load_wb) begin
    //     if(is_load_wb) begin
    //         result = mrdata_wb;
    //     end
    //     else begin
    //         result = alu_out_wb;
    //     end
    // end

    always @(posedge clk) begin
        if(!rst) begin
            state <= 1'b0;
            // wb_ifu_valid <= 1'b1;   // first inst
        end
        // else if(!state) begin
        //     if(wb_ifu_valid) state <= 1'b1;
        //     else state <= 1'b0;
        // end
        // else begin
        //     if(ifu_wb_ready) state <= 1'b0;
        //     else state <= 1'b1;
        // end

    end

    always @(posedge clk) begin
        if(!rst) begin
            wb_mem_ready <= 'b0;
            // waddr_wb <= 'b0;
            // mrdata_wb <= 'b0;
            // wcsren_wb <= 'b0;
            // wcsraddr_wb <= 'b0;
            // wcsrdata_wb <= 'b0;
            // wcsren2_wb <= 'b0;
            // wcsraddr2_wb <= 'b0;
            // wcsrdata2_wb <= 'b0;
            // alu_out_wb <= 'b0;
            // is_load_wb <= 'b0;
            // is_dnpc_wb <= 'b0;
            // dnpc_wb <= 'b0;
            // // wb_ifu_valid <= 'b0;
            // skip_ref_wb <= 'b0;
            // pc_wbu <= 'b0;
            cnt <= 'b0;
        end
        // else if(wb_ifu_valid && ifu_wb_ready && state) begin
        else if(cnt && !wen_wb) begin
            cnt <= 'b0;
            // shake hands successfully
            // wb_ifu_valid <= 1'b0;

            // pc_wbu <= pc_lsu;
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
            mrdata_wb <= mrdata_mem;

            wcsren_wb <= wcsren_mem;
            wcsraddr_wb <= wcsraddr_mem;
            wcsrdata_wb <= wcsrdata_mem;

            wcsren2_wb <= wcsren2_mem;
            wcsraddr2_wb <= wcsraddr2_mem;
            wcsrdata2_wb <= wcsrdata2_mem;

            alu_out_wb <= alu_out_mem;
            is_load_wb <= is_load_mem;

            is_dnpc_wb <= is_dnpc_mem;
            dnpc_wb <= dnpc_mem;
            pc_wbu <= pc_lsu;

            skip_ref_wb <= skip_ref_mem;

            cnt <= 'b1;



            `ifdef CONFIG_DPIC
            if(is_ebreak_lsu) ebreak();
            `endif
            `ifdef __ICARUS__
            if(is_ebreak_lsu) begin
                $display("ebreak inst!");
                $finish;
            end
            `endif
        end
        else if(mem_wb_valid) begin
            wb_mem_ready <= 1'b1;
        end
    end

    // regs write
    always @(posedge clk) begin
        if(!rst) begin
            wen_wb <= 'b0;
            regs[0] <= 'b0;
            // for(integer i = 0; i<`ysyx_24080020_REG_WIDTH; i = i+1 ) begin
            //     regs[i] <= 32'b0;
            // end
        end
        else if(wen_wb) begin
            regs[waddr_wb] <= result;
            wen_wb <= 1'b0;
            regs[0] <= 32'b0;
        end
        else if(mem_wb_valid && wb_mem_ready) begin
            wen_wb <= wen_mem;
        end
        else begin
            regs[0] <= 32'b0;
        end
    end

    // csrs write
    always @(posedge clk) begin
        if(!rst) begin
            // for(integer j = 0; j<=3'd7; j = j+1) csrs[j] <= 32'b0;
            csrs[1] <= 32'h1800;
            csrs[4] <= 32'h79737978;
            csrs[5] <= 32'h16f6e94;
        end
        else if(wcsren_wb && wcsren2_wb) begin
            csrs[wcsr_idx] <= wcsrdata_wb;
            csrs[wcsr_idx2] <= wcsrdata2_wb;
        end
        else if(wcsren_wb) begin
            csrs[wcsr_idx] <= wcsrdata_wb;
        end
        else if(wcsren2_wb) begin
            csrs[wcsr_idx2] <= wcsrdata2_wb;
        end
        else begin
            csrs[7] <= 32'b0;
        end
    end

    always @(*) begin
    // always @(wcsraddr_wb or rcsraddr or wcsraddr2_wb) begin
        wcsr_idx = 'b0;

        case(wcsraddr_wb)
            `ysyx_24080020_MEPC_ADDR:     wcsr_idx = 3'd0;
            `ysyx_24080020_MSTATUS_ADDR:  wcsr_idx = 3'd1;
            `ysyx_24080020_MCAUSE_ADDR:   wcsr_idx = 3'd2;
            `ysyx_24080020_MTVEC_ADDR:    wcsr_idx = 3'd3;
            `ysyx_24080020_MVENDORID_ADDR: wcsr_idx = 3'd4;
            `ysyx_24080020_MARCHID_ADDR: wcsr_idx = 3'd5;
            default: wcsr_idx = 3'd7;
        endcase
    end

    always @(*) begin
    // always @(wcsraddr_wb or rcsraddr or wcsraddr2_wb) begin
        wcsr_idx2 = 'b0;

        case(wcsraddr2_wb)
            `ysyx_24080020_MEPC_ADDR:     wcsr_idx2 = 3'd0;
            `ysyx_24080020_MSTATUS_ADDR:  wcsr_idx2 = 3'd1;
            `ysyx_24080020_MCAUSE_ADDR:   wcsr_idx2 = 3'd2;
            `ysyx_24080020_MTVEC_ADDR:    wcsr_idx2 = 3'd3;
            `ysyx_24080020_MVENDORID_ADDR: wcsr_idx2 = 3'd4;
            `ysyx_24080020_MARCHID_ADDR: wcsr_idx2 = 3'd5;
            default: wcsr_idx2 = 3'd7;
        endcase
    end

    always @(*) begin
    // always @(wcsraddr_wb or rcsraddr or wcsraddr2_wb) begin
        rcsr_idx = 'b0;

        case(rcsraddr)
            `ysyx_24080020_MEPC_ADDR:     rcsr_idx = 3'd0;
            `ysyx_24080020_MSTATUS_ADDR:  rcsr_idx = 3'd1;
            `ysyx_24080020_MCAUSE_ADDR:   rcsr_idx = 3'd2;
            `ysyx_24080020_MTVEC_ADDR:    rcsr_idx = 3'd3;
            `ysyx_24080020_MVENDORID_ADDR: rcsr_idx = 3'd4;
            `ysyx_24080020_MARCHID_ADDR: rcsr_idx = 3'd5;
            default: rcsr_idx = 3'd7;
        endcase
    end

    assign val_raddr1 = regs[raddr1];
    assign val_raddr2 = regs[raddr2];

    assign rcsrdata = csrs[rcsr_idx];
endmodule
