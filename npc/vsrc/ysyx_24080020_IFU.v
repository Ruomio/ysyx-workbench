`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IFU (
    input clk,
    input rst,

    input [`ysyx_24080020_WIDTH-1:0] dnpc_exu,
    input is_dnpc_exu,
    input lsu_busy,

    output reg [`ysyx_24080020_WIDTH-1:0] pc_ifu,
    output reg [`ysyx_24080020_WIDTH-1:0] inst_ifu,
    output reg if_en,
    input exu_mem_shake_hands,
    output update_pc,
    input [`ysyx_24080020_WIDTH-1:0] raddr,

    // pipeline
    input control_adventure,
    output reg flush_pipeline,

    output inst_fin,

    // axi-lite
    input arready,
    output reg arvalid,
    output reg [1:0] arburst,
    output reg [2:0] arsize,
    output reg [3:0] arid,
    output reg [7:0] arlen,
    output reg [`ysyx_24080020_WIDTH-1:0] araddr,

    input rvalid,
    input rlast,
    input [1:0] rresp,
    input [3:0] rid,
    input [`ysyx_24080020_WIDTH-1:0] rdata,
    output reg rready,


    input wb_ifu_valid,
    input idu_ifu_ready,
    output reg ifu_wb_ready,
    output reg ifu_idu_valid
);

    wire inst_fin_valid;
    wire [`ysyx_24080020_WIDTH-1:0] addr;

    reg inst_fin_ready;

    reg is_dnpc;
    reg is_update_pc;
    reg dnpc_en;
    reg [`ysyx_24080020_WIDTH-1:0] dnpc, inst;

    reg wb_ifu_shake_hands;
    reg next_inst, need_update_pc, skip_once;


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
            inst <= 'b0;
            inst_fin_ready<= 'b0;
        end
        else if(inst_fin_valid) begin
            if((raddr != dnpc) && !dnpc_en) begin
                inst_fin_ready <= 'b1;
            end
            else if(inst_fin_ready) begin
                inst_fin_ready <= 'b0;
                dnpc_en <= 'b1;
            end
            else if(!ifu_idu_valid) begin

                inst_fin_ready <= 'b1;

                pc_ifu <= raddr;
                inst_ifu <= inst;
                next_inst <= 'b1;
                ifu_idu_valid <= 1'b1;
                flush_pipeline <= 'b0;

            end
        end
        else begin
            inst_fin_ready <= 'b0;
            // ifu_idu_valid <= ifu_idu_valid;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            ifu_wb_ready <= 1'b0;
        end
        else if(ifu_idu_valid && idu_ifu_ready && state) begin
            ifu_idu_valid <= 1'b0;
            // is_dnpc <= 'b0;
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
            // if_en <= 1'b0;
            ifu_wb_ready <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            wb_ifu_shake_hands <= 1'b0;
            need_update_pc <= 1'b0;
        end
        else if(need_update_pc) begin
            // update
            is_update_pc <= 1'b1;

            wb_ifu_shake_hands <= 1'b0;
            next_inst <= 'b0;

            need_update_pc <= 'b0;
        end
        else if(wb_ifu_shake_hands) begin
            need_update_pc <= 1'b1;
        end
        else begin
            // wb_ifu_shake_hands <= 1'b0;
            is_update_pc <= 1'b0;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            next_inst <= 'b1;
            dnpc <= 'b0;
            is_dnpc <= 'b0;
            dnpc_en <= 'b1;
        end
        else if(if_en) begin
            is_dnpc <= 'b0;
        end
        else if(control_adventure) begin
            if(dnpc_en) begin
                dnpc_en <= 'b0;
                // pc incorrect
                next_inst <= 'b1;
                is_dnpc <= is_dnpc_exu;
                dnpc <= dnpc_exu;
                flush_pipeline <= 'b1;
                // if(!lsu_busy) begin
                //     skip_once <= 'b1;
                // end
            end
        end
    end



    ysyx_24080020_PC u_pc(
        .clk(clk),
        .rst(rst),
        .next(arvalid && arready),
        .is_update_pc(is_update_pc),
        .dnpc(dnpc),
        // .pc_ifu(pc_ifu),
        .is_dnpc(is_dnpc),
        .if_en(if_en),
        .addr(addr)
    );

    ysyx_24080020_IR u_ir(
        .clk(clk),
        .rst(rst),
        .lsu_busy(lsu_busy),

        .if_en(if_en),
        .addr(addr),
        .inst(inst),
        .inst_fin_valid(inst_fin_valid),
        .inst_fin_ready(inst_fin_ready),
        .update_pc(update_pc),

        // axi-lite
        .arvalid(arvalid),
        .araddr(araddr),
        .arburst(arburst),
        .arsize(arsize),
        .arid(arid),
        .arlen(arlen),
        .arready(arready),

        .rvalid(rvalid),
        .rlast(rlast),
        .rid(rid),
        .rresp(rresp),
        .rdata(rdata),
        .rready(rready)
    );


endmodule
