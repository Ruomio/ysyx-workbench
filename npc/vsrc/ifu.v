`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_IFU (
    input clk,
    input rst,

    input [`ysyx_24080020_WIDTH-1:0] dnpc_wb,
    input is_dnpc_wb,

    output [`ysyx_24080020_WIDTH-1:0] pc_ifu,
    output reg [`ysyx_24080020_WIDTH-1:0] inst_ifu,

    input wb_ifu_valid,
    input idu_ifu_ready,
    output reg ifu_wb_ready,
    output reg ifu_idu_valid

);
    reg is_dnpc;
    reg if_en;
    reg is_update_pc;
    reg [`ysyx_24080020_WIDTH-1:0] dnpc;
    wire [`ysyx_24080020_WIDTH-1:0] snpc;


    wire [`ysyx_24080020_WIDTH-1:0] addr;

    reg inst_fin;
    // reg [`ysyx_24080020_WIDTH-1:0] inst_ifu;

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
            // if_en <= 1'b1; // first inst
        end
        else if(inst_fin) begin
            ifu_idu_valid <= 1'b1;
            // inst_fin <= 1'b0;
            if_en <= 1'b0;

            is_update_pc <= 1'b0;
        end
        else begin
            // ifu_idu_valid <= ifu_idu_valid;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin

        end
        else if(wb_ifu_valid) begin
            if(ifu_idu_valid) begin
                ifu_wb_ready <= 1'b0;
            end
            else begin
                // shake hands
                ifu_wb_ready <= 1'b1;

                // update
                dnpc <= dnpc_wb;
                is_dnpc <= is_dnpc_wb;

                if_en <= 1'b1;

                is_update_pc <= 1'b1;
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

    // assign snpc = addr + 32'd4;

    ysyx_24080020_PC u_pc(
        .clk(clk),
        .rst(rst),
        .is_update_pc(is_update_pc),
        .dnpc(dnpc),
        // .snpc(snpc),
        .is_dnpc(is_dnpc),
        .addr(addr)
    );

    ysyx_24080020_IR u_ir(
        .clk(clk),
        .rst(rst),
        .if_en(if_en),
        .addr(addr),
        .inst(inst_ifu),
        .inst_fin(inst_fin)
    );


endmodule