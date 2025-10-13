`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_FORWARD(
    input clk,
    input rst,

    input [`ysyx_24080020_REG_WIDTH-1:0] rs1_idu,
    input [`ysyx_24080020_REG_WIDTH-1:0] rs2_idu,

    input [`ysyx_24080020_REG_WIDTH-1:0] rd_exu,
    input [`ysyx_24080020_WIDTH-1:0] rd_data_exu,
    // input rd_en_exu,

    input [`ysyx_24080020_REG_WIDTH-1:0] rd_lsu,
    input [`ysyx_24080020_WIDTH-1:0] rd_data_lsu,
    // input rd_en_lsu,

    // input [`ysyx_24080020_WIDTH-1:0] mrdata,
    // input fin_load,

    input [`ysyx_24080020_REG_WIDTH-1:0] rd_wbu,
    input [`ysyx_24080020_WIDTH-1:0] rd_data_wbu,
    // input rd_en_wbu,

    input [`ysyx_24080020_WIDTH-1:0] val_raddr1,
    input [`ysyx_24080020_WIDTH-1:0] val_raddr2,

    // input is_load,
    // output need_stall,
    output [`ysyx_24080020_WIDTH-1:0] rd_data1_forward,
    output [`ysyx_24080020_WIDTH-1:0] rd_data2_forward,
    output rs1_conflict,
    output rs2_conflict
);
    // reg is_load_next;

    // assign rs1_conflict = (((rs1_idu == rd_exu) && (rd_en_exu)) || ((rs1_idu == rd_lsu) && (rd_en_lsu)) || ((rs1_idu == rd_wbu) && (rd_en_wbu))) && (rs1_idu != 'b0);
    // assign rs2_conflict = (((rs2_idu == rd_exu) && (rd_en_exu)) || ((rs2_idu == rd_lsu) && (rd_en_lsu)) || ((rs2_idu == rd_wbu) && (rd_en_wbu))) && (rs2_idu != 'b0);
    assign rs1_conflict = (((rs1_idu == rd_exu) ) || ((rs1_idu == rd_lsu) ) || ((rs1_idu == rd_wbu) )) && (rs1_idu != 'b0);
    assign rs2_conflict = (((rs2_idu == rd_exu) ) || ((rs2_idu == rd_lsu) ) || ((rs2_idu == rd_wbu) )) && (rs2_idu != 'b0);

    assign rd_data1_forward = rs1_conflict ?
                                rs1_idu == rd_exu ? rd_data_exu :
                                rs1_idu == rd_lsu ? rd_data_lsu :
                                rs1_idu == rd_wbu ? rd_data_wbu :
                                'b0
                            : val_raddr1;

    assign rd_data2_forward = rs2_conflict ?
                                rs2_idu == rd_exu ? rd_data_exu :
                                rs2_idu == rd_lsu ? rd_data_lsu :
                                rs2_idu == rd_wbu ? rd_data_wbu :
                                'b0
                            : val_raddr2;


    // assign need_stall = is_load;
    // assign need_stall_imme = is_load;

    // always @(posedge clk) begin
    //     if(!rst) begin
    //         need_stall <= 'b0;
    //     end
    //     else if(fin_load) begin
    //         need_stall <= 'b0;
    //     end
    //     else if(is_load && !is_load_next) begin
    //         need_stall <= 'b1;
    //     end

    // end

    // always @(posedge clk) begin
    //     if(!rst) begin
    //         is_load_next <= 'b0;
    //     end
    //     else if(is_load) begin
    //         is_load_next <= 'b1;
    //     end
    //     else begin
    //         is_load_next <= 'b0;
    //     end

    // end


endmodule
