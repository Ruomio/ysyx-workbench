module ysyx_24080020_IFU #(
    parameter  WIDTH = 32,
    parameter DEPTH = 8 
)
(
    input clk,
    input rst,
    input [WIDTH-1:0] pc,
    input [3:0] len,
    output [WIDTH-1:0] snpc
    // output reg [WIDTH-1:0] inst,
);

    reg [WIDTH-1:0] snpc_reg;


    always @(posedge clk) begin
        if(!rst) begin
            snpc_reg <= `ysyx_24080020_MBASE;
        end
        else begin
            snpc_reg <= pc + {{28{1'b0}}, len};
        end
    end

    assign snpc = snpc_reg;

    // assign inst = pmem_read[pc - 32'h80000000];
endmodule