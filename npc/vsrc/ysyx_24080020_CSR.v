`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_CSR
(
    input clk,
    input rst,

    //csr
    input wcsren_mem,
    input [2:0] wcsraddr_mem,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata_mem,
    input wcsren2_mem,
    input [2:0] wcsraddr2_mem,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata2_mem,

    // out csr
    input [2:0] rcsraddr,
    output reg [`ysyx_24080020_WIDTH-1:0] rcsrdata,

    input mem_wb_valid,
    input wb_mem_ready
);
    // csrs[0] = mepc, csrs[1] = mstatus, csrs[2] = mcause, csrs[3] = mtvec, // csrs[4] = MVENDORID, csrs[5] = MARCHID
    reg [`ysyx_24080020_WIDTH-1:0] csrs[0:3];

    wire [`ysyx_24080020_WIDTH-1:0] csr_mvendorid, csr_marchid;

    // 精简的流水线寄存器
    reg csr1_wen_wb, csr2_wen_wb;
    reg [2:0] csr1_addr_wb, csr2_addr_wb;
    reg [`ysyx_24080020_WIDTH-1:0] csr1_data_wb, csr2_data_wb;

    assign csr_mvendorid = 32'h79737978;
    assign csr_marchid = 32'h16f6e94;

    always @(posedge clk) begin
        if(!rst) begin
        end
        else if(mem_wb_valid && wb_mem_ready) begin
            // CSR信号
            csr1_wen_wb <= wcsren_mem;
            csr1_addr_wb <= wcsraddr_mem;
            csr1_data_wb <= wcsrdata_mem;
            csr2_wen_wb <= wcsren2_mem;
            csr2_addr_wb <= wcsraddr2_mem;
            csr2_data_wb <= wcsrdata2_mem;
        end
    end

    // CSR写入
    always @(posedge clk) begin
        if(!rst) begin
            csrs[1] <= 32'h1800;        // mstatus
        end else begin
            if(csr1_wen_wb) csrs[csr1_addr_wb] <= csr1_data_wb;
            if(csr2_wen_wb) csrs[csr2_addr_wb] <= csr2_data_wb;
        end
    end

    // 读取端口
    // assign rcsrdata = csrs[rcsraddr];
    always @(*) begin
        case(rcsraddr)
            0: rcsrdata = csrs[0];
            1: rcsrdata = csrs[1];
            2: rcsrdata = csrs[2];
            3: rcsrdata = csrs[3];
            4: rcsrdata = csr_mvendorid;
            5: rcsrdata = csr_marchid;
            default: rcsrdata = 32'h0;
        endcase
    end
endmodule
