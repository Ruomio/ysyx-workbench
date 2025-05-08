`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IFU (
    input clk,
    input rst,

    input [`ysyx_24080020_WIDTH-1:0] dnpc_wb,
    input is_dnpc_wb,

    output reg [`ysyx_24080020_WIDTH-1:0] pc_ifu,
    output reg [`ysyx_24080020_WIDTH-1:0] inst_ifu,
    output reg if_en,

    // pipeline
    input control_adventure,

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

    wire inst_fin;
    wire [`ysyx_24080020_WIDTH-1:0] addr;

    reg is_dnpc;
    reg is_update_pc;
    reg [`ysyx_24080020_WIDTH-1:0] dnpc;

    reg wb_ifu_shake_hands;
    reg next_inst;


    reg state; // 0: idle  ;  1: wait_ready

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
        end
        else if(inst_fin) begin
            ifu_idu_valid <= 1'b1;
            pc_ifu <= addr;
        end
        else begin
            // ifu_idu_valid <= ifu_idu_valid;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            ifu_wb_ready <= 1'b0;
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
        else if(idu_ifu_ready && state) begin
            ifu_idu_valid <= 1'b0;
        end
        else begin
            // if_en <= 1'b0;
            ifu_wb_ready <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            wb_ifu_shake_hands <= 1'b0;
            is_dnpc <= 1'b0;
            dnpc <= 32'b0;
        end
        else if(wb_ifu_shake_hands && !control_adventure && next_inst) begin
            // update
            dnpc <= dnpc_wb;
            is_dnpc <= is_dnpc_wb;
            is_update_pc <= 1'b1;

            wb_ifu_shake_hands <= 1'b0;
            next_inst <= 'b0;
        end
        else begin
            // wb_ifu_shake_hands <= 1'b0;
            is_update_pc <= 1'b0;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            next_inst <= 'b1;
        end
        if(idu_ifu_ready && ifu_idu_valid) begin
            next_inst <= 'b1;
        end
    end


    ysyx_24080020_PC u_pc(
        .clk(clk),
        .rst(rst),
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
        .if_en(if_en),
        .addr(addr),
        .inst(inst_ifu),
        .inst_fin(inst_fin),

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
