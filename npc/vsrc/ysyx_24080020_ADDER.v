`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_ADDER (
    input [`ysyx_24080020_WIDTH-1:0] a,
    input [`ysyx_24080020_WIDTH-1:0] b,
    output [`ysyx_24080020_WIDTH-1:0] c
);

    assign c = a + b;

endmodule
