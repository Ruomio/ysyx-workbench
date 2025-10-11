`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_CSR
(
    input clk,
    input rst,

    //csr
    input is_ecall_lsu,
    input wcsren_mem,
    input [2:0] wcsraddr_mem,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata_mem,
    // input wcsren2_mem,
    // input [2:0] wcsraddr2_mem,
    // input [`ysyx_24080020_WIDTH-1:0] wcsrdata2_mem,

    // out csr
    input [2:0] rcsraddr,
    output reg [`ysyx_24080020_WIDTH-1:0] rcsrdata,

    input mem_wb_valid,
    input wb_mem_ready
);
    // only Machine mode now
    // ecall: csrs[mepc] <= pc; csrs[mcause] <= 'd3; dnpc <= csrs[mtvec];
    // mret: pc <= csrs[mepc]; csrs[mstatus] <= 32'h1800;

    // csrs[0] = mepc, csrs[1] = mstatus, csrs[2] = mcause, csrs[3] = mtvec, // csrs[4] = MVENDORID, csrs[5] = MARCHID
    reg [`ysyx_24080020_WIDTH-1:0] csrs[0:3];

    wire [`ysyx_24080020_WIDTH-1:0] csr_mvendorid, csr_marchid;

    // 精简的流水线寄存器
    reg csr1_wen_wb;
    reg [2:0] csr1_addr_wb;
    reg [`ysyx_24080020_WIDTH-1:0] csr1_data_wb;
    reg is_ecall_wbu;

    assign csr_mvendorid = 32'h79737978;
    assign csr_marchid = 32'h16f6e94;

    always @(posedge clk) begin
        if(!rst) begin
        end
        if(is_ecall_wbu) begin
            is_ecall_wbu <= 'b0;
            csr1_addr_wb <= 'd2;
            csr1_data_wb <= 'hb;
        end
        else if(mem_wb_valid && wb_mem_ready) begin
            // CSR信号
            csr1_wen_wb <= wcsren_mem;
            csr1_addr_wb <= wcsraddr_mem;
            csr1_data_wb <= wcsrdata_mem;
            is_ecall_wbu <= is_ecall_lsu;
        end
    end

    // CSR写入
    always @(posedge clk) begin
        if(!rst) begin
            csrs[1] <= 32'h1800;        // mstatus
        end else begin
            if(csr1_wen_wb) csrs[csr1_addr_wb[1:0]] <= csr1_data_wb;
            // if(csr2_wen_wb) csrs[csr2_addr_wb[1:0]] <= csr2_data_wb;
        end
    end

    // 读取端口
    assign rcsrdata = rcsraddr == 'd0 ? csrs[0] :
                      rcsraddr == 'd1 ? csrs[1] :
                      rcsraddr == 'd2 ? csrs[2] :
                      rcsraddr == 'd3 ? csrs[3] :
                      rcsraddr == 'd4 ? csr_mvendorid :
                      rcsraddr == 'd5 ? csr_marchid :
                      32'h0;
endmodule
