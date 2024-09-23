`include "vsrc/define.v"
module ysyx_24080020_REG #(
    parameter WIDTH = 32
) (
    input clk,
    input rst,

    input [4:0] raddr1,
    input [4:0] raddr2,

    input wen,
    input [4:0] waddr,
    input [31:0] wdata,

    output reg [`ysyx_24080020_WIDTH-1:0] val_raddr1,
    output reg [`ysyx_24080020_WIDTH-1:0] val_raddr2
);

    reg [WIDTH-1:0] regs[WIDTH-1:0];

    reg [`ysyx_24080020_WIDTH-1:0] next_wdata;

    integer  i;

    always @(posedge clk) begin
        if(!rst) begin
            for(i = 0; i<6'd32; i = i+1 ) begin
                regs[i] <= 32'b0;
            end
        end
        else if(wen && (waddr != 0)) begin
            regs[waddr] <= next_wdata;
        end
        else begin
            regs[0] <= 32'b0;
        end
    end

    always @(posedge clk) begin
        next_wdata <= wdata;
    end

    assign val_raddr1 = raddr1 != 5'b0 ? regs[raddr1] : 32'b0;
    assign val_raddr2 = raddr2 != 5'b0 ? regs[raddr2] : 32'b0;

endmodule