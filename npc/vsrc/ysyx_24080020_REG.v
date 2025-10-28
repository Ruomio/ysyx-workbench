`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_REG
(
    input clk,
    input rst,

`ifdef CONFIG_DPIC
    input skip_ref_mem,
    input [`ysyx_24080020_WIDTH-1:0] pc_lsu,
    output reg [`ysyx_24080020_WIDTH-1:0] pc_wbu,
    input is_dnpc_mem,
    input [`ysyx_24080020_WIDTH-1:0] dnpc_mem,
`endif

    input [`ysyx_24080020_REG_WIDTH-1:0] raddr1,
    input [`ysyx_24080020_REG_WIDTH-1:0] raddr2,


    input wen_mem,
    input [`ysyx_24080020_REG_WIDTH-1:0] waddr_mem,
    input [`ysyx_24080020_WIDTH-1:0] wdata_mem,
    output reg [`ysyx_24080020_REG_WIDTH-1:0] waddr_wb,
    output reg [`ysyx_24080020_WIDTH-1:0] wdata_wb,
    output reg wen_wb,


    // out src1 & src2
    output [`ysyx_24080020_WIDTH-1:0] val_raddr1,
    output [`ysyx_24080020_WIDTH-1:0] val_raddr2,

    input mem_wb_valid,
    output reg wb_mem_ready
);
    reg [`ysyx_24080020_WIDTH-1:0] regs[0:`ysyx_24080020_REG_NUM-1];

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
        else if(cnt) begin
            cnt <= 'b0;
            waddr_wb <= 'b0;
        end
        else if(mem_wb_valid && wb_mem_ready) begin
            wb_mem_ready <= 'b0;

            cnt <= 'b1;
            // shake hands successfully
            waddr_wb <= waddr_mem;
            wdata_wb <= wdata_mem;

        end
        else if(mem_wb_valid) begin
            wb_mem_ready <= 1'b1;
        end
    end

    // regs write
    // always @(posedge clk) begin
    //     if(!rst) begin
    //         regs[0] <= 'b0;
    //     end
    //     else if(wen_wb) begin
    //         regs[waddr_wb] <= rd_data_wb;
    //         regs[0] <= 'b0;
    //     end
    // end
    always @(posedge clk) begin
        if(wen_wb && |waddr_wb) begin
            regs[waddr_wb] <= wdata_wb;
        end
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


    // regs read
    // assign val_raddr1 = regs[raddr1];
    // assign val_raddr2 = regs[raddr2];
    assign val_raddr1 = raddr1 == 'b0 ? 'b0 : regs[raddr1];
    assign val_raddr2 = raddr2 == 'b0 ? 'b0 : regs[raddr2];


    //=========================================================================
    // DPI-C调试接口（可选）
    //=========================================================================
    `ifdef CONFIG_DPIC
    import "DPI-C" function void npc_difftest_skip_ref();

    reg is_dnpc_wb;
    reg [`ysyx_24080020_WIDTH-1:0] dnpc_wb;
    reg skip_ref_wb;



    always @(posedge clk) begin
        if(!rst) begin
        end
        else if(cnt) begin
            if(skip_ref_wb) begin
                skip_ref_wb <= 1'b0;
                // npc_difftest_skip_ref();
            end
        end
        else if(mem_wb_valid && wb_mem_ready) begin
            pc_wbu <= pc_lsu;
            is_dnpc_wb <= is_dnpc_mem;
            dnpc_wb <= dnpc_mem;
            skip_ref_wb <= skip_ref_mem;

            npc_difftest_skip_ref();
        end
    end

    `endif

endmodule
