`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IFU (
    input  wire        clk,
    input  wire        rst,

    // ir -> ifu
    input  wire [`ysyx_24080020_WIDTH-1:0] inst,
    input  wire [`ysyx_24080020_WIDTH-1:0] raddr,
    input  wire        inst_fin_valid,
    output wire        inst_fin_ready,
    input  wire        special_pc_i,
    // output wire        inst_fin,

    // btb -> ifu
    input  wire [`ysyx_24080020_WIDTH-1:0] correct_pc_btb,
    input  wire        need_flush_pipeline,
    output wire        flush_pipeline,

    // ifu -> idu
    output wire [`ysyx_24080020_WIDTH-1:0] pc_ifu,
    output wire [`ysyx_24080020_WIDTH-1:0] inst_ifu,

    input  wire        idu_ifu_ready,
    output wire        ifu_idu_valid
);

//=========================================================================
// 1. 经典 valid-ready 握手（零状态机）
//=========================================================================
// 反压：本级空就能收
assign ifu_idu_valid = valid_q;   // 有数据就向下传
assign inst_fin_ready = ~valid_q;  // 空就能收

// 完成标志：组合（与原文件一致）
// assign inst_fin = inst_fin_valid & inst_fin_ready;

//=========================================================================
// 2. 仅锁 1 bit 标志（零整拍缓冲）
//=========================================================================
reg valid_q;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        valid_q <= 1'b0;
    end
    else if(ifu_idu_valid & idu_ifu_ready) begin
        valid_q <= 1'b0;
    end
    else if(inst_fin_valid & inst_fin_ready) begin
        valid_q <= 1'b1;
        flush_pipeline_q <= need_flush_pipeline;
    end
end


//=========================================================================
// jump inst, flush pipeline
//========================================================================|
reg flush_pipeline_q;
reg [31:0] correct_pc_q;

always @(posedge clk) begin
    if(!rst) begin
        flush_pipeline_q <= 1'b0;
    end
    else if(need_flush_pipeline) begin
        flush_pipeline_q <= 1'b1;
        correct_pc_q <= correct_pc_btb;
    end
    else if((raddr == correct_pc_q) & special_pc_i) begin
        flush_pipeline_q <= 1'b0;
        correct_pc_q <= 32'h0;
    end
end

assign flush_pipeline = flush_pipeline_q;
//=========================================================================
// 3. 输出：组合路径（不锁整拍）
//========================================================================|
assign pc_ifu     = raddr;          // PC 直接连输入
assign inst_ifu   = inst;           // 指令直接连输入

//=========================================================================
// 4. DPI-C 调试接口（可选，面积可综合开关）
//=========================================================================
`ifdef CONFIG_DPIC
// always @(posedge clk) begin
//     if (inst_fin)
//         $display("IFU: PC=0x%08x", raddr);
// end
`endif

endmodule

// `include "ysyx_24080020_DEFINE.v"
// module ysyx_24080020_IFU (
//     input clk,
//     input rst,
//
//     input [`ysyx_24080020_WIDTH-1:0] inst,
//     output reg [`ysyx_24080020_WIDTH-1:0] pc_ifu,
//     output reg [`ysyx_24080020_WIDTH-1:0] inst_ifu,
//     input [`ysyx_24080020_WIDTH-1:0] raddr,
//
//     // pipeline
//     output reg flush_pipeline,
//
//     output inst_fin,
//
//     input special_pc_i,
//
//     input [`ysyx_24080020_WIDTH-1:0] correct_pc_btb,
//     input need_flush_pipeline,
//
//     // ifu <-> ir
//     input inst_fin_valid,
//     output reg inst_fin_ready,
//
//     input idu_ifu_ready,
//     output reg ifu_idu_valid
// );
//
//     `ifdef CONFIG_DPIC
//     import "DPI-C" function void statistics_icache_miss_hit_cnt();
//     import "DPI-C" function void statistics_ifu_get_inst();
//     `endif
//
//     wire if_en;
//     wire if_en_ready;
//
//
//     reg special_pc;
//     reg wb_ifu_shake_hands;
//     reg btype_n_jump;
//
//     // reg state; // 0: idle  ;  1: wait_ready
//     reg [`ysyx_24080020_WIDTH-1:0] correct_pc;
//
//     assign inst_fin = inst_fin_valid & inst_fin_ready;
//
//     // always @(posedge clk) begin
//     //     if(!rst) begin
//     //         state <= 1'b0;
//     //     end
//     //     else if(!state) begin
//     //         if(ifu_idu_valid) state <= 1'b1;
//     //         else state <= 1'b0;
//     //     end
//     //     else begin
//     //         if(idu_ifu_ready) state <= 1'b0;
//     //         else state <= 1'b1;
//     //     end
//     // end
//
//     always @(posedge clk) begin
//         if(!rst) begin
//             ifu_idu_valid <= 1'b0;
//             pc_ifu <= 'b0;
//             inst_fin_ready<= 'b1;
//             special_pc <= 'b0;
//             inst_ifu <= 'b0;
//         end
//         else if(ifu_idu_valid && idu_ifu_ready) begin
//             ifu_idu_valid <= 1'b0;
//             inst_fin_ready<= 'b1;
//         end
//         else if(inst_fin_valid && inst_fin_ready) begin
//             inst_fin_ready <= 'b0;
//
//             pc_ifu <= raddr;
//             inst_ifu <= inst;
//             ifu_idu_valid <= 1'b1;
//
//             `ifdef CONFIG_DPIC
//             statistics_ifu_get_inst();
//             `endif
//         end
//         else if(inst_fin_valid) begin
//             // special_pc <= special_pc_i;
//             // if((raddr != correct_pc) && flush_pipeline) begin
//             //     inst_fin_ready <= 'b1;
//
//             //     `ifdef CONFIG_DPIC
//             //     statistics_icache_miss_hit_cnt();
//             //     `endif
//             // end
//             // else if(!ifu_idu_valid && idu_ifu_ready) begin
//             //     inst_fin_ready <= 'b1;
//
//             //     // if((raddr == correct_pc) && flush_pipeline && special_pc_i) begin
//             //     //     flush_pipeline <= 'b0;
//             //     // end
//             // end
//             if(!ifu_idu_valid && idu_ifu_ready) begin
//                 inst_fin_ready <= 'b1;
//
//                 if((raddr == correct_pc) && flush_pipeline && special_pc_i) begin
//                     flush_pipeline <= 'b0;
//                 end
//             end
//         end
//     end
//
//
//     always @(posedge clk) begin
//         if(!rst) begin
//             btype_n_jump <= 'b0;
//             correct_pc <= 'b0;
//             flush_pipeline <= 'b0;
//         end
//         else if(need_flush_pipeline) begin
//             flush_pipeline <= 'b1;
//             correct_pc <= correct_pc_btb;
//         end
//         else if(!ifu_idu_valid) begin
//             if((raddr == correct_pc) && flush_pipeline && special_pc_i) begin
//                 flush_pipeline <= 'b0;
//             end
//         end
//
//     end
//
//
// endmodule
