`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IFU (
    input clk,
    input rst,

    input [`ysyx_24080020_WIDTH-1:0] dnpc_exu,
    input is_dnpc_exu,
    input lsu_busy,

    input [`ysyx_24080020_WIDTH-1:0] inst,
    output reg [`ysyx_24080020_WIDTH-1:0] pc_ifu,
    output reg [`ysyx_24080020_WIDTH-1:0] inst_ifu,
    input [`ysyx_24080020_WIDTH-1:0] raddr,

    // pipeline
    input control_adventure,
    output reg flush_pipeline,

    output inst_fin,

    output special_pc_o,
    input special_pc_i,

    input inst_fin_valid,
    output reg inst_fin_ready,
    // axi-lite
    // input arready,
    // output reg arvalid,
    // output reg [1:0] arburst,
    // output reg [2:0] arsize,
    // output reg [3:0] arid,
    // output reg [7:0] arlen,
    // output reg [`ysyx_24080020_WIDTH-1:0] araddr,

    // input rvalid,
    // input rlast,
    // input [1:0] rresp,
    // input [3:0] rid,
    // input [`ysyx_24080020_WIDTH-1:0] rdata,
    // output reg rready,


    input wb_ifu_valid,
    input idu_ifu_ready,
    output reg ifu_wb_ready,
    output reg ifu_idu_valid
);

    `ifdef CONFIG_DPIC
    import "DPI-C" function void statistics_icache_miss_hit_cnt();
    import "DPI-C" function void statistics_ifu_get_inst();
    `endif

    // wire [`ysyx_24080020_WIDTH-1:0] addr, inst;
    wire if_en;
    wire if_en_ready;
    wire special_pc;

    // wire inst_fin_valid;
    // reg inst_fin_ready;

    reg wb_ifu_shake_hands;


    reg state; // 0: idle  ;  1: wait_ready

    assign inst_fin = inst_fin_valid & inst_fin_ready;

    always @(posedge clk) begin
        if(!rst) begin
            state <= 1'b0;
        end
        else if(!state) begin
            if(ifu_idu_valid) state <= 1'b1;
            else state <= 1'b0;
        end
        else begin
            if(idu_ifu_ready) state <= 1'b0;
            else state <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            ifu_idu_valid <= 1'b0;
            pc_ifu <= 'b0;
            inst_fin_ready<= 'b0;
        end
        else if(inst_fin_valid && inst_fin_ready) begin
            inst_fin_ready <= 'b0;
        end
        else if(inst_fin_valid) begin
            if((raddr != dnpc_exu) && flush_pipeline) begin
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
                if((raddr == dnpc_exu) && flush_pipeline && special_pc_i) begin
                    flush_pipeline <= 'b0;
                end

            end
        end
        else begin
            inst_fin_ready <= 'b0;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            ifu_wb_ready <= 1'b0;
        end
        else if(ifu_idu_valid && idu_ifu_ready && state) begin
            ifu_idu_valid <= 1'b0;
            `ifdef CONFIG_DPIC
            statistics_ifu_get_inst();
            `endif
        end
        else if(wb_ifu_valid) begin
            if(ifu_idu_valid) begin
                ifu_wb_ready <= 1'b0;
            end
            else begin
                // shake hands
                ifu_wb_ready <= 1'b1;

                wb_ifu_shake_hands <= 1'b1;
            end
        end
        else begin
            ifu_wb_ready <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
        end
        else if(is_dnpc_exu && !control_adventure) begin
            flush_pipeline <= 'b1;
        end
    end



    // ysyx_24080020_PC u_pc(
    //     .clk(clk),
    //     .rst(rst),

    //     // ifu <-> pc
    //     // .update_pc(inst_fin_valid && inst_fin_ready),
    //     .update_pc(arvalid && arready),
    //     .dnpc(dnpc_exu),
    //     .is_dnpc(is_dnpc_exu),

    //     // pc <-> ir
    //     .special_pc(special_pc),
    //     .if_en_valid(if_en),
    //     .if_en_ready(if_en_ready),
    //     .addr(addr)
    // );

    // ysyx_24080020_IR u_ir(
    //     .clk(clk),
    //     .rst(rst),
    //     .lsu_busy(lsu_busy),

    //     // pc <-> ir
    //     .special_pc_i(special_pc),
    //     .if_en_valid(if_en),
    //     .if_en_ready(if_en_ready),
    //     .addr(addr),

    //     // ir <-> ifu
    //     .inst(inst),
    //     .inst_fin_valid(inst_fin_valid),
    //     .inst_fin_ready(inst_fin_ready),

    //     .special_pc_o(special_pc_o),
    //     // axi-lite
    //     .arvalid(arvalid),
    //     .araddr(araddr),
    //     .arburst(arburst),
    //     .arsize(arsize),
    //     .arid(arid),
    //     .arlen(arlen),
    //     .arready(arready),

    //     .rvalid(rvalid),
    //     .rlast(rlast),
    //     .rid(rid),
    //     .rresp(rresp),
    //     .rdata(rdata),
    //     .rready(rready)
    // );


endmodule
