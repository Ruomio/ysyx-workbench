`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_PC (
    input clk,
    input rst,
    input next,
    input is_update_pc,
    input is_dnpc,
    input [`ysyx_24080020_WIDTH-1:0] dnpc,
    output reg if_en,
    output reg [`ysyx_24080020_WIDTH-1:0] addr
);

    reg cnt, dnpc_en, update;
    reg first_if;

    always @(posedge clk) begin
        if(!rst) begin
            addr <= `ysyx_24080020_MBASE;
            cnt <= 1'b0;
            first_if <= 1'b0;
        end
        else if(cnt) begin
            if(!first_if) begin
                first_if <= 1'b1;

                addr <= addr;
                cnt <= 1'b0;
                if_en <= 1'b1;
            end
            else if(next) begin
                if(dnpc_en) begin
                    addr <= dnpc;
                    dnpc_en <=  'b0;
                    update <= 'b1;
                end
                else begin
                    addr <=  addr + 32'd4;
                    update <= 'b0;
                end
                cnt <= 1'b0;
                if_en <= 1'b1;
            end
        end
        else if(is_update_pc) begin
            cnt <= 'b1;
        end
        else begin
            // addr <= addr;
            if_en <= 1'b0;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            dnpc_en <= 'b0;
            update <= 'b0;
        end
        else if(is_dnpc && !update) begin
            dnpc_en <= 'b1;
        end
    end



endmodule
