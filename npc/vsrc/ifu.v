`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_IFU (
    input clk,
    input rst,

    input [`ysyx_24080020_WIDTH-1:0] dnpc_wb,
    input is_dnpc_wb,

    output reg [`ysyx_24080020_WIDTH-1:0] pc_ifu,
    output reg [`ysyx_24080020_WIDTH-1:0] inst_ifu,

    input wb_ifu_valid,
    input idu_ifu_ready,
    output reg ifu_wb_ready,
    output reg ifu_idu_valid,
    output reg wb_ifu_shake_hand

);
    wire if_en;
    wire inst_fin;
    wire [`ysyx_24080020_WIDTH-1:0] addr;
    // wire [`ysyx_24080020_WIDTH-1:0] snpc;

    reg is_dnpc;
    reg is_update_pc;
    reg [`ysyx_24080020_WIDTH-1:0] dnpc;


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

                wb_ifu_shake_hand <= 1'b1;

            end
        end
        else if(idu_ifu_ready && state) begin
            ifu_idu_valid <= 1'b0;
        end
        // else if(!ifu_idu_valid) begin
        //     // process
        //     is_update_pc <= 1'b0;
        // end
        else begin
            // if_en <= 1'b0;
            ifu_wb_ready <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            wb_ifu_shake_hand <= 1'b0;
        end
        else if(wb_ifu_shake_hand) begin
            // update
            dnpc <= dnpc_wb;
            is_dnpc <= is_dnpc_wb;

            is_update_pc <= 1'b1;
            // if_en <= 1'b1;

            wb_ifu_shake_hand <= 1'b0;

        end
        else begin
            wb_ifu_shake_hand <= 1'b0;
            is_update_pc <= 1'b0;
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
        .inst_fin(inst_fin)
    );


endmodule