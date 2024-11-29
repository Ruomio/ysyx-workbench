`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_REG  
(
    input clk,
    input rst,

    input [4:0] raddr1,
    input [4:0] raddr2,

    input [`ysyx_24080020_WIDTH-1:0] is_load_mem,

    input wen_mem,
    input [4:0] waddr_mem,
    input [`ysyx_24080020_WIDTH-1:0] alu_out_mem,
    input [`ysyx_24080020_WIDTH-1:0] mrdata_mem,

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
    input ifu_wb_ready,
    output reg wb_ifu_valid,
    output reg wb_mem_ready
);

    reg [`ysyx_24080020_WIDTH-1:0] regs[`ysyx_24080020_WIDTH-1:0];
    // csrs[0] = mepc, csrs[1] = mstatus, csrs[2] = mcause, csrs[3] = mtvec
    reg [`ysyx_24080020_WIDTH-1:0] csrs[4:0];

    reg state; // 0:idle;    1:wait_ready

    integer  i;
 
    reg [2:0] wcsr_idx;
    reg [2:0] wcsr_idx2;
    reg [2:0] rcsr_idx;

    reg [`ysyx_24080020_WIDTH-1:0] alu_out_wb;
    reg [`ysyx_24080020_WIDTH-1:0] mrdata_wb;
    
    reg wcsren_wb;
    reg [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr_wb;
    reg [`ysyx_24080020_WIDTH-1:0] wcsrdata_wb;
    reg wcsren2_wb;
    reg [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2_wb;
    reg [`ysyx_24080020_WIDTH-1:0] wcsrdata2_wb;

    wire [`ysyx_24080020_WIDTH-1:0] result;

    assign result = is_load_wb == 1'b1 ? mrdata_wb : alu_out_wb;

    always @(posedge clk) begin
        if(!rst) begin
            state <= 1'b0;
        end
        else if(!state) begin
            if(reg_pc_valid) state <= 1'b1;
            else state <= 1'b0;
        end
        else begin
            if(pc_reg_ready) state <= 1'b0;
            else state <= 1'b1;
        end

    end

    always @(posedge clk) begin
        if(mem_wb_valid) begin
            if(wb_ifu_valid) wb_mem_ready <= 1'b0;
            else begin
                wb_mem_ready <= 1'b1;

                // shake hands successfully
                wen_wb <= wen_mem;
                waddr_wb <= waddr_mem;
                mrdata_wb <= mrdata_mem;

                wcsren_wb <= wcsren_mem;
                wcsraddr_wb <= wcsraddr_mem;
                wcsrdata_wb <= wcsrdata_wb;

                wcsren2_wb <= wcsren2_mem;
                wcsraddr2_wb <= wcsraddr2_mem;
                wcsrdata2_wb <= wcsrdata2_wb;

                alu_out_wb <= alu_out_mem;
                is_load_wb <= is_load_mem;

            end
        end
        else if(ifu_wb_ready && state) begin
            // shake hands successfully
            wb_ifu_valid <= 1'b0;
        end
        else begin
            wb_ifu_valid <= 1'b1;
            wb_mem_ready <= 1'b0;
        end

    end

    // regs write
    always @(posedge clk) begin
        if(!rst) begin
            for(i = 0; i<6'd32; i = i+1 ) begin
                regs[i] <= 32'b0;
            end
        end
        else if(wen_wb && (waddr_wb != 5'b0) && pc_reg_ready && state) begin
            regs[waddr_wb] <= result;
        end
        else begin
            regs[0] <= 32'b0;
        end
    end

    // csrs write
    always @(posedge clk or rst) begin
        if(!rst) begin
            for(i = 0; i<3'd5; i = i+1) csrs[i] <= 32'b0;
            csrs[1] <= 32'h1800;
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
            csrs[4] <= 32'b0;
        end
    end

    always @(wcsraddr_wb or rcsraddr or wcsraddr2_wb) begin
        case(wcsraddr_wb)
            `ysyx_24080020_MEPC_ADDR:     wcsr_idx = 3'd0;
            `ysyx_24080020_MSTATUS_ADDR:  wcsr_idx = 3'd1;
            `ysyx_24080020_MCAUSE_ADDR:   wcsr_idx = 3'd2;
            `ysyx_24080020_MTVEC_ADDR:    wcsr_idx = 3'd3;
            default: wcsr_idx = 3'd4;
        endcase

        case(wcsraddr2_wb)
            `ysyx_24080020_MEPC_ADDR:     wcsr_idx2 = 3'd0;
            `ysyx_24080020_MSTATUS_ADDR:  wcsr_idx2 = 3'd1;
            `ysyx_24080020_MCAUSE_ADDR:   wcsr_idx2 = 3'd2;
            `ysyx_24080020_MTVEC_ADDR:    wcsr_idx2 = 3'd3;
            default: wcsr_idx2 = 3'd4;
        endcase

        case(rcsraddr)
            `ysyx_24080020_MEPC_ADDR:     rcsr_idx = 3'd0;
            `ysyx_24080020_MSTATUS_ADDR:  rcsr_idx = 3'd1;
            `ysyx_24080020_MCAUSE_ADDR:   rcsr_idx = 3'd2;
            `ysyx_24080020_MTVEC_ADDR:    rcsr_idx = 3'd3;
            default: rcsr_idx = 3'd4;
        endcase
    end

    assign val_raddr1 = regs[raddr1];
    assign val_raddr2 = regs[raddr2];

    assign rcsrdata = csrs[rcsr_idx];
endmodule