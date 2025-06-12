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

    reg cnt;
    reg first_if;

    always @(posedge clk) begin
        if(!rst) begin
            addr <= `ysyx_24080020_MBASE;
            cnt <= 1'b0;
            first_if <= 1'b0;
        end
        else if(cnt && next) begin
            addr <= is_dnpc ? dnpc :
                    ~first_if ? addr : addr + 32'd4;
            first_if <= 1'b1;

            // pc_ifu <= addr;
            cnt <= 1'b0;
            if_en <= 1'b1;

        end
        else if(is_update_pc) begin
            cnt <= 'b1;
        end
        else begin
            // addr <= addr;
            if_en <= 1'b0;
        end

    end



endmodule
