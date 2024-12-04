`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_IFU (
    input clk,
    input rst,
    input [`ysyx_24080020_WIDTH-1:0] pc,
    input [3:0] len,
    // output [`ysyx_24080020_WIDTH-1:0] snpc
    output [`ysyx_24080020_WIDTH-1:0] inst

);

    reg [`ysyx_24080020_WIDTH-1:0] instMem [255:0];

    wire [7:0] idx;

    assign idx = pc - 32'h80000000;


    always @(posedge clk) begin
        if(!rst) begin
            inst <= 32'b0;
        end
        else begin
            inst <= instMem[idx];
        end
    end

endmodule