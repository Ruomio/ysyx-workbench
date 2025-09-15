`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_EXU
(
    input clk,
    input rst,
    input [`ysyx_24080020_WIDTH-1:0] pc_idu,
    input [`ysyx_24080020_WIDTH-1:0] imm_idu,
    input is_load_idu,
    output reg is_load_exu,
    output reg [`ysyx_24080020_WIDTH-1:0] pc_exu,

    input skip_ref_idu,
    output reg skip_ref_exu,

    input is_ebreak_idu,
    output reg is_ebreak_exu,

    // branch
    input is_btype_idu,
    input is_jal_idu,
    input is_jalr_idu,
    input is_dnpc_idu,
    // input is_btype_idu,
    input [`ysyx_24080020_WIDTH-1:0] branch_src1_idu,
    input [`ysyx_24080020_WIDTH-1:0] dnpc_idu,
    output reg is_dnpc_exu,
    output reg [`ysyx_24080020_WIDTH-1:0] dnpc_new_exu,
    output reg is_jal_exu,
    output reg is_btype_exu,

    input fencei_idu,
    output reg fencei_exu,

    // alu
    input alu_src2_con_idu,
    input [`ysyx_24080020_WIDTH-1:0] src1_idu,
    input [`ysyx_24080020_WIDTH-1:0] src2_idu,
    input [`ysyx_24080020_ALU_OP_WIDTH-1:0] alu_op_idu,
    output reg [`ysyx_24080020_WIDTH-1:0] alu_out_exu,

    // reg
    input wen_idu,
    input [`ysyx_24080020_REG_WIDTH-1:0] waddr_idu,
    input [`ysyx_24080020_WIDTH-1:0] wdata_idu,
    output reg wen_exu,
    output reg [`ysyx_24080020_REG_WIDTH-1:0] waddr_exu,
    // output reg[`ysyx_24080020_WIDTH-1:0] wdata_exu,

    // memory
    input mwen_idu,
    input [3:0] mwmask_idu,
    input mren_idu,
    input mrtype_idu,
    input [3:0] mrlen_idu,
    output reg mwen_exu,
    output reg [3:0] mwmask_exu,
    output reg mren_exu,
    output reg mrtype_exu,
    output reg [3:0] mrlen_exu,
    output reg [`ysyx_24080020_WIDTH-1:0] mraddr_exu,
    output reg [`ysyx_24080020_WIDTH-1:0] mwaddr_exu,
    output reg [`ysyx_24080020_WIDTH-1:0] mwdata_exu,

    //csrs
    input is_csrtype_idu,
    // input [`ysyx_24080020_WIDTH-1:0] rcsrdata,
    input wcsren_idu,
    input [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr_idu,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata_idu,
    input wcsren2_idu,
    input [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2_idu,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata2_idu,
    output reg wcsren_exu,
    output reg[`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr_exu,
    output reg[`ysyx_24080020_WIDTH-1:0] wcsrdata_exu,
    output reg wcsren2_exu,
    output reg[`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2_exu,
    output reg[`ysyx_24080020_WIDTH-1:0] wcsrdata2_exu,

    // axi
    input idu_exu_valid,
    input mem_exu_ready,
    output reg exu_idu_ready,
    output reg exu_mem_valid
);
`ifdef CONFIG_DPIC
    import "DPI-C" function void statistics_exu_complete_calcu();

    import "DPI-C" function void statistics_idu_calculate_type();
    import "DPI-C" function void statistics_idu_load_type();
    import "DPI-C" function void statistics_idu_store_type();
    import "DPI-C" function void statistics_idu_csr_type();
    import "DPI-C" function void statistics_idu_jump_type();
`endif

    wire [`ysyx_24080020_WIDTH-1:0] alu_src1;
    wire [`ysyx_24080020_WIDTH-1:0] alu_src2;
    wire [`ysyx_24080020_WIDTH-1:0] alu_out;

    wire [`ysyx_24080020_WIDTH-1:0] dnpc;
    wire [`ysyx_24080020_WIDTH-1:0] branch_dnpc;
    wire [`ysyx_24080020_WIDTH-1:0] branch_src1;
    wire [`ysyx_24080020_WIDTH-1:0] branch_src2;

    reg [`ysyx_24080020_WIDTH-1:0] branch_src1_exu;


    reg is_jalr_exu;
    reg is_csrtype_exu;
    reg alu_src2_con_exu;
    reg [`ysyx_24080020_ALU_OP_WIDTH-1:0] alu_op_exu;
    reg [`ysyx_24080020_WIDTH-1:0] dnpc_exu;
    reg [`ysyx_24080020_WIDTH-1:0] imm_exu;
    reg [`ysyx_24080020_WIDTH-1:0] src1_exu;
    reg [`ysyx_24080020_WIDTH-1:0] src2_exu;
    reg [`ysyx_24080020_WIDTH-1:0] wdata_exu;


    reg state;   // 0:idle;   1:wait_ready

    reg cnt;

    reg idu_exu_shake_hand;



    // memory
    always @(alu_out or src2_exu or mwen_exu or mren_exu) begin
        if(mwen_exu) begin
            mwaddr_exu = alu_out;
            mwdata_exu = src2_exu;
        end
        else begin
            mwaddr_exu = 32'b0;
            mwdata_exu = src2_exu;
        end
        if(mren_exu) begin
            mraddr_exu = alu_out;
        end
        else begin
            mraddr_exu = 32'b0;
        end
    end


    // branch
    assign dnpc = is_jalr_exu == 1'b1 ? (branch_dnpc & (~32'b1)) : branch_dnpc;
    always @(dnpc or alu_out or wdata_exu or is_csrtype_exu) begin
        dnpc_new_exu = dnpc;
        alu_out_exu = is_csrtype_exu == 1'b1 ? wdata_exu : alu_out;
    end

    // bus
    always @(posedge clk) begin
        if(!rst) begin
            exu_idu_ready <= 1'b0;

            idu_exu_shake_hand <= 1'b0;

            wen_exu <= 'b0;
            waddr_exu <= 'b0;
            wdata_exu <= 'b0;

            mwen_exu <= 'b0;
            mwmask_exu <= 'b0;
            mren_exu <= 'b0;
            mrtype_exu <= 'b0;
            mrlen_exu <= 'b0;

            is_load_exu <= 'b0;
            is_dnpc_exu <= 'b0;
            branch_src1_exu <= 'b0;

            alu_op_exu <= 'b0;
            alu_src2_con_exu <= 'b0;
            // reg_dst_con_exu <= 'b0;
            imm_exu <= 'b0;

            src1_exu <= 'b0;
            src2_exu <= 'b0;
            pc_exu <= 'b0;
            dnpc_exu <= 'b0;
            is_jalr_exu <= 'b0;
            is_jal_exu <= 'b0;
            is_btype_exu <= 'b0;

            wcsren_exu <= 'b0;
            wcsraddr_exu <= 'b0;
            wcsrdata_exu <= 'b0;
            wcsren2_exu <= 'b0;
            wcsraddr2_exu <= 'b0;
            wcsrdata2_exu <= 'b0;

            is_csrtype_exu <= 'b0;


            fencei_exu <= 'b0;


            skip_ref_exu <= 'b0;
            is_ebreak_exu <= 'b0;
            exu_mem_valid <= 'b0;

        end
        else if(mem_exu_ready && exu_mem_valid && state) begin
            exu_mem_valid <= 1'b0;
            is_dnpc_exu <= 'b0;
            waddr_exu <= 'b0;
            is_btype_exu <= 'b0;
            fencei_exu <= 'b0;
            `ifdef CONFIG_DPIC
            statistics_exu_complete_calcu();
            `endif
        end
        else if(idu_exu_shake_hand) begin
            idu_exu_shake_hand <= 1'b0;

        end
        else if(idu_exu_valid) begin
            if(exu_mem_valid) exu_idu_ready <=  1'b0;
            else if(exu_idu_ready) begin
                exu_idu_ready <= 'b0;
                idu_exu_shake_hand <= 'b1;

                // update all reg type control wire
                wen_exu <= wen_idu;
                waddr_exu <= waddr_idu;
                wdata_exu <= wdata_idu;

                mwen_exu <= mwen_idu;
                mwmask_exu <= mwmask_idu;
                mren_exu <= mren_idu;
                mrtype_exu <= mrtype_idu;
                mrlen_exu <= mrlen_idu;

                is_load_exu <= is_load_idu;
                is_dnpc_exu <= is_dnpc_idu;
                branch_src1_exu <= branch_src1_idu;

                alu_op_exu <= alu_op_idu;
                alu_src2_con_exu <= alu_src2_con_idu;
                // reg_dst_con_exu <= reg_dst_con_idu;
                imm_exu <= imm_idu;

                src1_exu <= src1_idu;
                src2_exu <= src2_idu;
                pc_exu <= pc_idu;
                dnpc_exu <= dnpc_idu;
                is_jalr_exu <= is_jalr_idu;
                is_jal_exu <= is_jal_idu;
                is_btype_exu <= is_btype_idu;

                wcsren_exu <= wcsren_idu;
                wcsraddr_exu <= wcsraddr_idu;
                wcsrdata_exu <= wcsrdata_idu;
                wcsren2_exu <= wcsren2_idu;
                wcsraddr2_exu <= wcsraddr2_idu;
                wcsrdata2_exu <= wcsrdata2_idu;

                is_csrtype_exu <= is_csrtype_idu;

                // cnt <= 1'b1;

                fencei_exu <= fencei_idu;

                skip_ref_exu <= skip_ref_idu;

                is_ebreak_exu <= is_ebreak_idu;

                `ifdef CONFIG_DPIC
                if(is_load_idu) statistics_idu_load_type();
                else if(mwen_idu) statistics_idu_store_type();
                else if(is_csrtype_idu) statistics_idu_csr_type();
                else if(is_dnpc_idu) statistics_idu_jump_type();
                else statistics_idu_calculate_type();
                `endif

            end
            else begin
                // shake hand successfully
                exu_idu_ready <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            state <= 1'b0;
        end
        if(!state) begin
            if(exu_mem_valid) state <= 1'b1;
            else begin
                // idle
                state <= 1'b0;
            end
        end
        else begin
            if(mem_exu_ready) state <= 1'b0;
            else state <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            cnt <= 1'b0;
            exu_mem_valid <= 1'b0;
        end
        else if(cnt == 1'b1) begin
            exu_mem_valid <= 1'b1;
            cnt <= 1'b0;
        end
        else if(idu_exu_shake_hand) begin
            cnt <= 1'b1;
        end
    end

    assign alu_src1 = src1_exu;
    assign alu_src2 = alu_src2_con_exu == 1'b0 ? src2_exu : imm_exu;

    ysyx_24080020_ALU alu(
        .alu_op(alu_op_exu),
        .alu_src1(alu_src1),
        .alu_src2(alu_src2),
        .alu_out(alu_out)
    );

    assign branch_src1 = is_jalr_exu == 1'b1 ? branch_src1_exu :
                            is_csrtype_exu == 1'b1 ? dnpc_exu : pc_exu;
    assign branch_src2 = is_csrtype_exu == 1'b1 ? 32'b0 : imm_exu;

    ysyx_24080020_ADDER u_branch(
        .a(branch_src1),
        .b(branch_src2),
        .c(branch_dnpc)
    );

`ifdef __ICARUS__
    reg [31:0] ref_pc [];
`endif

endmodule
