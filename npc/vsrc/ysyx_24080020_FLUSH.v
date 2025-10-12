`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_FLUSH (
    input clk,
    input rst,

    input           need_flush_pipeline,
    input [31:0]    correct_pc,
    output          flush_pipeline,

    input           special_pc_,
    input [31:0]    raddr_,

);


//=========================================================================
// jump inst, flush pipeline
//========================================================================|
reg flush_pipeline_q;
reg [31:0] correct_pc_q;

always @(posedge clk) begin
    if(!rst) begin
        flush_pipeline_q <= 1'b0;
    end
    else if(need_flush_pipeline) begin
        flush_pipeline_q <= 1'b1;
        correct_pc_q <= correct_pc;
    end
    else if((raddr_ == correct_pc_q) & special_pc_) begin
        flush_pipeline_q <= 1'b0;
        correct_pc_q <= 32'h0;
    end
end

assign flush_pipeline = flush_pipeline_q;

endmodule
