`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_FORWARD(
    input clk,
    input rst,

    input [4:0] rs1_idu,
    input [4:0] rs2_idu,

    input [4:0] rd_exu,
    input [`ysyx_24080020_WIDTH-1:0] rd_data_exu,

    input [4:0] rd_lsu,
    input [`ysyx_24080020_WIDTH-1:0] rd_data_lsu,

    input [4:0] rd_wbu,
    input [`ysyx_24080020_WIDTH-1:0] rd_data_wbu,

    output reg [`ysyx_24080020_WIDTH-1:0] rd_data1_forward,
    output reg [`ysyx_24080020_WIDTH-1:0] rd_data2_forward,
    output reg rs1_conflict,
    output reg rs2_conflict
);

    assign rs1_conflict = ((rs1_idu == rd_exu) || (rs1_idu == rd_lsu) || (rs1_idu == rd_wbu)) && (rs1_idu != 'b0);
    assign rs2_conflict = ((rs2_idu == rd_exu) || (rs2_idu == rd_lsu) || (rs2_idu == rd_wbu)) && (rs2_idu != 'b0);

    assign rd_data1_forward = rs1_conflict ?
                                rs1_idu == rd_exu ? rd_data_exu :
                                rs1_idu == rd_lsu ? rd_data_lsu :
                                rs1_idu == rd_wbu ? rd_data_wbu :
                                'b0
                            : 'b0;

    assign rd_data2_forward = rs2_conflict ?
                                rs2_idu == rd_exu ? rd_data_exu :
                                rs2_idu == rd_lsu ? rd_data_lsu :
                                rs2_idu == rd_wbu ? rd_data_wbu :
                                'b0
                            : 'b0;

    // reg data_adventure_next;
    // always @(posedge clk) begin
    //     if(!rst) begin
    //         rs1_conflict <= 'b0;
    //         rs2_conflict <= 'b0;
    //         rd_data_forward <= 'b0;
    //     end
    //     else if(data_adventure && !data_adventure_next) begin
    //         if(data1_adventure) rs1_conflict <= 'b1;
    //         else if(data2_adventure) rs2_conflict <= 'b1;

    //         rd_data_forward <= rd_data_exu;
    //     end
    //     else begin

    //     end

    // end

    // always @(posedge clk) begin
    //     if(!rst) begin
    //         data_adventure_next <= 'b0;
    //     end
    //     else if(data_adventure) begin
    //         data_adventure_next <= 'b1;
    //     end
    //     else begin
    //         data_adventure_next <= 'b0;
    //     end
    // end

endmodule
