`include "vsrc/define.v"
module ysyx_24080020_IFU (
    input clk,
    input rst,
    input [`ysyx_24080020_WIDTH-1:0] pc,
    input [3:0] len,
    output [`ysyx_24080020_WIDTH-1:0] snpc,
    output [`ysyx_24080020_WIDTH-1:0] maddr
    //output reg [`ysyx_24080020_WIDTH-1:0] inst

);

    reg [`ysyx_24080020_WIDTH-1:0] snpc_reg;

    assign maddr = pc;


    always @(posedge clk) begin
        if(!rst) begin
            snpc_reg <= pc;
        end
        else begin
            snpc_reg <= pc + {{28{1'b0}}, len};
        end
    end

    assign snpc = snpc_reg;

    // assign inst = pmem_read[pc - 32'h80000000];
endmodule