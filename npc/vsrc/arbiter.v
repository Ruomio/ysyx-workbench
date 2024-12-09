`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_ARBITER(
    input clk,
    input rst,

    // master-1 ifu
    input wb_ifu_shake_hands,
    input arvalid_ifu,
    input [`ysyx_24080020_WIDTH-1:0] araddr_ifu,
    output reg arready_ifu,

    input rready_ifu,
    output reg [`ysyx_24080020_WIDTH-1:0] rdata_ifu,
    output reg [1:0] rresp_ifu,
    output reg rvalid_ifu,

    // master-2 mem
    input exu_mem_shake_hands,
    input arvalid_mem,
    input [`ysyx_24080020_WIDTH-1:0] araddr_mem,
    output reg arready_mem,

    input rready_mem,
    output reg [`ysyx_24080020_WIDTH-1:0] rdata_mem,
    output reg [1:0] rresp_mem,
    output reg rvalid_mem,

    // arbiter deside
    output arvalid_arbiter_slave,
    output [`ysyx_24080020_WIDTH-1:0] araddr_arbiter_slave,
    input arready_slave_arbiter,

    input [`ysyx_24080020_WIDTH-1:0] rdata_slave_arbiter,
    input [1:0] rresp_slave_arbiter,
    input rvalid_slave_arbiter,
    output rready_arbiter_master
);
    wire [2:0] max_cnt;
    reg [2:0] ifu_wait_cnt;
    reg [2:0] mem_wait_cnt;

    reg ifu_or_mem;
    reg wait_rdata;
    reg ar_tmp;

    assign max_cnt = 3'd7;
    

    // arvalid, araddr: master -> arbiter
    always @(posedge clk) begin
        if(!rst) begin
            // ar_tmp <= 1'b0;
            ifu_wait_cnt <= 3'b0;
            mem_wait_cnt <= 3'b0;
        end
        // else if(ar_tmp) begin
        //     if(!ifu_or_mem) begin
        //         arvalid_arbiter_slave <= arvalid_ifu;
        //         araddr_arbiter_slave <= araddr_ifu;
        //     end
        //     else begin
        //         arvalid_arbiter_slave <= arvalid_mem;
        //         araddr_arbiter_slave <= araddr_mem;
        //     end

        //     ar_tmp <= 1'b0;
        // end
        else if(wb_ifu_shake_hands && ifu_wait_cnt == max_cnt) begin
            // ar_tmp <= 1'b1;

            ifu_or_mem <= 1'b0;

            ifu_wait_cnt <= 3'b0;
            mem_wait_cnt <= mem_wait_cnt + 3'b1;
        end
        else if(exu_mem_shake_hands && mem_wait_cnt == max_cnt) begin
            // ar_tmp <= 1'b1;

            ifu_or_mem <= 1'b1;

            mem_wait_cnt <= 3'b0;
            ifu_wait_cnt <= ifu_wait_cnt + 3'b1;
        end
        else if(wb_ifu_shake_hands) begin
            // ar_tmp <= 1'b1;

            ifu_or_mem <= 1'b0;

            ifu_wait_cnt <= 3'b0;
            mem_wait_cnt <= mem_wait_cnt + 3'b1;
        end
        else if(exu_mem_shake_hands) begin
            // ar_tmp <= 1'b1;

            ifu_or_mem <= 1'b1;

            mem_wait_cnt <= 3'b0;
            ifu_wait_cnt <= ifu_wait_cnt + 3'b1;
        end
        else if(!ifu_or_mem) begin
            arvalid_arbiter_slave <= arvalid_ifu;
            araddr_arbiter_slave <= araddr_ifu;
        end
        else begin
            arvalid_arbiter_slave <= arvalid_mem;
            araddr_arbiter_slave <= araddr_mem;
        end
        // else begin
        //     ifu_wait_cnt <= ifu_wait_cnt;
        //     mem_wait_cnt <= mem_wait_cnt;
        // end
    end

    // arready: slave -> arbiter
    always @(posedge clk) begin
        if(!rst) begin
            arready_ifu <= 1'b0;
            arready_mem <= 1'b0;
        end
        else if(!ifu_or_mem) begin
            arready_ifu <= arready_slave_arbiter;
        end
        else begin
            arready_mem <= arready_slave_arbiter;
        end
    end

    // arready: arbiter -> master
    always @(posedge clk) begin
        if(!rst) begin
            arready_ifu <= 1'b0;
            arready_mem <= 1'b0;
        end
        else if(ifu_or_mem == 1'b0) begin
            arready_ifu <= arready_slave_arbiter;
            arready_mem <= 1'b0;
        end
        else begin
            arready_mem <= arready_slave_arbiter;
            arready_ifu <= 1'b0;
        end

    end

    // rvalid: arbiter -> master
    always @(posedge clk) begin
        if(!rst) begin
            rvalid_ifu <= 1'b0;
            rvalid_mem <= 1'b0;

        end
        else if(!ifu_or_mem) begin
            rvalid_ifu <= rvalid_slave_arbiter;
            rresp_ifu <= rresp_slave_arbiter;
            rdata_ifu <= rdata_slave_arbiter;

            rvalid_mem <= 1'b0;
        end
        else begin
            rvalid_mem <= rvalid_slave_arbiter;
            rresp_mem <= rresp_slave_arbiter;
            rdata_mem <= rdata_slave_arbiter;

            rvalid_ifu <= 1'b0;
        end
    end

    // rready: master -> arbiter
    always @(posedge clk) begin
        if(!rst) begin
            rready_arbiter_master <= 1'b0;
        end
        else if(!ifu_or_mem) begin
            rready_arbiter_master <= rready_ifu;
        end
        else begin
            rready_arbiter_master <= rready_mem;
        end
    end

endmodule