`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_PC (
    input clk,
    input rst,

    // ifu <-> pc
    input update_pc_valid,
    output reg update_pc_ready,
    input is_dnpc,
    input [`ysyx_24080020_WIDTH-1:0] dnpc,

    // pc <-> ir
    input if_en_ready,
    output reg if_en_valid,
    output reg [`ysyx_24080020_WIDTH-1:0] addr
);

    reg first_if, pc_en;;

    reg is_dnpc_ir;
    reg [`ysyx_24080020_WIDTH-1:0] dnpc_ir;

    always @(posedge clk) begin
        if(!rst) begin
            addr <= `ysyx_24080020_MBASE;
            first_if <= 1'b0;
            pc_en <= 'b1;
            is_dnpc_ir <= 'b0;
            dnpc_ir <= 'b0;
        end
        else if(update_pc_valid && update_pc_ready) begin
            update_pc_ready <= 'b0;

            // pc_en <= 'b1;

            is_dnpc_ir <= is_dnpc;
            dnpc_ir <= dnpc;

        end
        else if(update_pc_valid) begin
            if(!if_en_valid) begin
                update_pc_ready <= 'b1;
            end
        end
    end

    always @(posedge clk) begin
        if(!rst) begin

        end
        else if(if_en_valid && if_en_ready) begin
            if_en_valid <= 'b0;
            pc_en <= 'b1;
        end
        else if(pc_en) begin
            pc_en <= 'b0;
            if_en_valid <= 'b1;
            is_dnpc_ir <= 'b0;

            if(!first_if) begin
                first_if <= 1'b1;
                addr <= addr;
            end
            else begin
                if(is_dnpc_ir) begin
                    addr <= dnpc_ir;
                end
                else begin
                    addr <=  addr + 32'd4;
                end
            end
        end

    end


endmodule
