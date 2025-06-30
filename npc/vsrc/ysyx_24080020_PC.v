`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_PC (
    input clk,
    input rst,

    // ifu <-> pc
    input update_pc,
    input is_dnpc,
    input [`ysyx_24080020_WIDTH-1:0] dnpc,

    // pc <-> ir
    input if_en_ready,
    output reg special_pc,
    output reg if_en_valid,
    output reg [`ysyx_24080020_WIDTH-1:0] addr
);

    reg first_if, pc_en;;

    reg is_dnpc_pc, is_dnpc_next;
    reg [`ysyx_24080020_WIDTH-1:0] dnpc_pc;

    always @(posedge clk) begin
        if(!rst) begin
            addr <= `ysyx_24080020_MBASE;
            first_if <= 1'b0;
            pc_en <= 'b1;
        end
        else if(update_pc && !pc_en) begin
            pc_en <= 'b1;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            pc_en <= 'b1;
            special_pc <= 'b0;
        end
        else if(if_en_valid && if_en_ready) begin
            if_en_valid <= 'b0;
            special_pc <= 'b0;
        end
        else if(pc_en) begin
            if_en_valid <= 'b1;
            pc_en <= 'b0;

            if(!first_if) begin
                first_if <= 1'b1;
                addr <= addr;
            end
            else begin
                if(is_dnpc_pc) begin
                    addr <= dnpc_pc;
                    is_dnpc_pc <= 'b0;
                    special_pc <= 'b1;
                end
                else begin
                    addr <=  addr + 32'd4;
                end
            end
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            is_dnpc_pc <= 'b0;
            dnpc_pc <= 'b0;
        end
        else if(is_dnpc && !is_dnpc_next) begin
            is_dnpc_pc <= 'b1;
            dnpc_pc <= dnpc;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            is_dnpc_next <= 'b0;
        end
        else if(is_dnpc) begin
            is_dnpc_next <= 'b1;
        end
        else begin
            is_dnpc_next <= 'b0;
        end
    end


endmodule
