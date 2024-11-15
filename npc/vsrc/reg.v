`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_REG  
(
    input clk,
    input rst,

    input mem_reg_valid,
    input pc_reg_ready,

    input [4:0] raddr1,
    input [4:0] raddr2,

    input wen,
    input [4:0] waddr,
    input [31:0] wdata,

    //csr
    input wcsren,
    input [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata,
    input wcsren2,
    input [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata2,
    input [`ysyx_24080020_CSR_WIDTH-1:0] rcsraddr,

    // out src1 & src2
    output [`ysyx_24080020_WIDTH-1:0] val_raddr1,
    output [`ysyx_24080020_WIDTH-1:0] val_raddr2,

    // out csr
    output [`ysyx_24080020_WIDTH-1:0] rcsrdata,
    output reg reg_pc_valid,
    output reg reg_mem_ready
);

    reg [`ysyx_24080020_WIDTH-1:0] regs[`ysyx_24080020_WIDTH-1:0];
    // csrs[0] = mepc, csrs[1] = mstatus, csrs[2] = mcause, csrs[3] = mtvec
    reg [`ysyx_24080020_WIDTH-1:0] csrs[4:0];

    reg state; // 0:idle;    1:wait_ready

    integer  i;
 
    reg [2:0] wcsr_idx;
    reg [2:0] wcsr_idx2;
    reg [2:0] rcsr_idx;


    always @(posedge clk) begin
        if(!state) begin
            if(reg_pc_valid) state <= 1'b1;
            else state <= 1'b0;
        end
        else begin
            if(pc_reg_ready) state <= 1'b0;
            else state <= 1'b1;
        end

    end

    always @(posedge clk) begin
        if(mem_reg_valid) begin
            if(reg_pc_valid) reg_mem_ready <= 1'b0;
            else reg_mem_ready <= 1'b1;
        end
        else if(pc_reg_ready && !state) begin
            reg_pc_valid <= 1'b0;
        end
        else begin
            reg_pc_valid <= 1'b1;
            reg_mem_ready <= 1'b0;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            for(i = 0; i<6'd32; i = i+1 ) begin
                regs[i] <= 32'b0;
            end
        end
        else if(wen && (waddr != 5'b0) && pc_reg_ready && !state) begin
            regs[waddr] <= wdata;
        end
        else begin
            regs[0] <= 32'b0;
        end
    end

    always @(posedge clk or rst) begin
        if(!rst) begin
            for(i = 0; i<3'd5; i = i+1) csrs[i] <= 32'b0;
            csrs[1] <= 32'h1800;
        end
        else if(wcsren && wcsren2) begin
            csrs[wcsr_idx] <= wcsrdata;
            csrs[wcsr_idx2] <= wcsrdata2;
        end
        else if(wcsren) begin
            csrs[wcsr_idx] <= wcsrdata;
        end
        else if(wcsren2) begin
            csrs[wcsr_idx2] <= wcsrdata2;
        end
        else begin 
            csrs[4] <= 32'b0;
        end
    end

    always @(wcsraddr or rcsraddr or wcsraddr2) begin
        case(wcsraddr)
            `ysyx_24080020_MEPC_ADDR:     wcsr_idx = 3'd0;
            `ysyx_24080020_MSTATUS_ADDR:  wcsr_idx = 3'd1;
            `ysyx_24080020_MCAUSE_ADDR:   wcsr_idx = 3'd2;
            `ysyx_24080020_MTVEC_ADDR:    wcsr_idx = 3'd3;
            default: wcsr_idx = 3'd4;
        endcase

        case(wcsraddr2)
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