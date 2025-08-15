`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_PC (
    input clk,
    input rst,

    // btb <-> pc
    input in_valid,
    output reg in_ready,

    input [`ysyx_24080020_WIDTH-1:0] in_pc,
    input in_special_pc,

    // pc <-> ir
    input if_en_ready,
    output reg special_pc,
    output reg if_en_valid,
    output reg [`ysyx_24080020_WIDTH-1:0] addr
);

    always @(posedge clk) begin
        if(!rst) begin
            addr <= 'b0;
            in_ready <= 'b0;
            special_pc <= 'b0;
        end
        else if(in_valid && in_ready) begin
            in_ready <= 'b0;
            special_pc <= in_special_pc;
            addr <= in_pc;
        end
        else if(in_valid && !if_en_valid) begin
            in_ready <= 'b1;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            if_en_valid <= 'b0;
        end
        else if(if_en_valid && if_en_ready) begin
            if_en_valid <= 'b0;
        end
        else if(in_valid && in_ready) begin
            if_en_valid <= 'b1;
        end
    end

endmodule
