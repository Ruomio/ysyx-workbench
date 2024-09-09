`include "vsrc/define.v"
`default_nettype none
`timescale 1ns/1ns

module tb_top;
reg clk;
reg rst_n;
reg [`ysyx_24080020_WIDTH-1:0] pc;

top 
(
    .rst (rst_n),
    .clk (clk),
    .pc(pc)
);

always #1 clk=~clk;

initial begin
    $dumpfile("build/wave.vcd");
    $dumpvars(0, tb_top);
end

initial begin
    rst_n = 1'b0;
    clk = 1'b0;
    #20;
    rst_n = 1'b1;
    #6000;
    $finish;
end

endmodule
`default_nettype wire