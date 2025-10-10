`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IFU (
    input clk,
    input rst,

    input [`ysyx_24080020_WIDTH-1:0] inst,
    output reg [`ysyx_24080020_WIDTH-1:0] pc_ifu,
    output reg [`ysyx_24080020_WIDTH-1:0] inst_ifu,
    input [`ysyx_24080020_WIDTH-1:0] raddr,

    // pipeline
    output reg flush_pipeline,

    output inst_fin,

    input special_pc_i,

    input [`ysyx_24080020_WIDTH-1:0] correct_pc_btb,
    input need_flush_pipeline,

    // ifu <-> ir
    input inst_fin_valid,
    output reg inst_fin_ready,

    input idu_ifu_ready,
    output reg ifu_idu_valid
);

    `ifdef CONFIG_DPIC
    import "DPI-C" function void statistics_icache_miss_hit_cnt();
    import "DPI-C" function void statistics_ifu_get_inst();
    `endif

    wire if_en;
    wire if_en_ready;


    reg special_pc;
    reg wb_ifu_shake_hands;
    reg btype_n_jump;

    // reg state; // 0: idle  ;  1: wait_ready
    reg [`ysyx_24080020_WIDTH-1:0] correct_pc;

    assign inst_fin = inst_fin_valid & inst_fin_ready;

    // always @(posedge clk) begin
    //     if(!rst) begin
    //         state <= 1'b0;
    //     end
    //     else if(!state) begin
    //         if(ifu_idu_valid) state <= 1'b1;
    //         else state <= 1'b0;
    //     end
    //     else begin
    //         if(idu_ifu_ready) state <= 1'b0;
    //         else state <= 1'b1;
    //     end
    // end

    always @(posedge clk) begin
        if(!rst) begin
            ifu_idu_valid <= 1'b0;
            pc_ifu <= 'b0;
            inst_fin_ready<= 'b0;
            special_pc <= 'b0;
            inst_ifu <= 'b0;
        end
        else if(ifu_idu_valid && idu_ifu_ready) begin
            ifu_idu_valid <= 1'b0;
        end
        else if(inst_fin_valid && inst_fin_ready) begin
            inst_fin_ready <= 'b0;

            `ifdef CONFIG_DPIC
            statistics_ifu_get_inst();
            `endif
        end
        else if(inst_fin_valid) begin
            special_pc <= special_pc_i;
            if((raddr != correct_pc) && flush_pipeline) begin
                inst_fin_ready <= 'b1;

                `ifdef CONFIG_DPIC
                statistics_icache_miss_hit_cnt();
                `endif
            end
            else if(!ifu_idu_valid) begin
                inst_fin_ready <= 'b1;

                pc_ifu <= raddr;
                inst_ifu <= inst;
                ifu_idu_valid <= 1'b1;
                // if((raddr == correct_pc) && flush_pipeline && special_pc_i) begin
                //     flush_pipeline <= 'b0;
                // end
            end
        end
    end


    always @(posedge clk) begin
        if(!rst) begin
            btype_n_jump <= 'b0;
            correct_pc <= 'b0;
            flush_pipeline <= 'b0;
        end
        else if(need_flush_pipeline) begin
            flush_pipeline <= 'b1;
            correct_pc <= correct_pc_btb;
        end
        else if(!ifu_idu_valid) begin
            if((raddr == correct_pc) && flush_pipeline && special_pc_i) begin
                flush_pipeline <= 'b0;
            end
        end

    end


endmodule
