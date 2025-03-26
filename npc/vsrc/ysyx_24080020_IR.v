`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IR(
    input clk,
    input rst,
    input if_en,
    input [`ysyx_24080020_WIDTH-1:0] addr,

    output reg [`ysyx_24080020_WIDTH-1:0] inst,
    output reg inst_fin,

    // axi-lite
    output reg arvalid,
    output reg [1:0] arburst,
    output reg [2:0] arsize,
    output reg [3:0] arid,
    output reg [7:0] arlen,
    output reg [`ysyx_24080020_WIDTH-1:0] araddr,
    input arready,

    input rvalid,
    input rlast,
    input [1:0] rresp,
    input [3:0] rid, 
    input [`ysyx_24080020_WIDTH-1:0] rdata,
    output reg rready

);
    `ifdef CONFIG_DPIC
    import "DPI-C" function void statistics_ifu_get_inst();
    `endif

    reg cnt;
    reg inst_fin_axi;
    reg inst_fin_cache;

    // CACHE
    localparam cache_size_bits = $clog2(`ysyx_24080020_CACHE_SIZE);
    localparam cache_num_bits = $clog2(`ysyx_24080020_CACHE_NUM);
    localparam cache_tag_size = 32 - cache_size_bits - cache_num_bits;
    localparam cache_data_width = 8 * `ysyx_24080020_CACHE_SIZE;

    wire [cache_tag_size-1:0]               cache_tag_tmp;
    wire [cache_num_bits-1:0]               cache_index_tmp;
    wire [cache_size_bits-1:0]              cache_offset_tmp;

    reg                                     cache_hit;
    reg [cache_data_width-1 : 0]              cache_data  [0 : `ysyx_24080020_CACHE_NUM-1];
    reg [cache_tag_size-1 : 0]              cache_tag   [0 : `ysyx_24080020_CACHE_NUM-1];
    reg                                     cache_valid [0 : `ysyx_24080020_CACHE_NUM-1];


    assign cache_tag_tmp = addr[31 : cache_num_bits+cache_size_bits];
    assign cache_index_tmp = addr[cache_num_bits+cache_size_bits-1 : cache_size_bits];
    assign cache_offset_tmp = addr[cache_size_bits-1 : 0];

    assign inst_fin = inst_fin_axi || inst_fin_cache;


    always @(posedge clk) begin
        if(!rst) begin
            cache_hit <= 'b0;
            inst_fin_cache <= 'b0;

            for (reg [cache_num_bits-1:0] i = 'b0; i < `ysyx_24080020_CACHE_NUM - 1 || i == ('d`ysyx_24080020_CACHE_NUM - 1)[cache_num_bits-1:0]; i = i + 'b1 ) begin
                cache_data[i] <= 'b0;
                cache_tag[i] <= 'b0;
                cache_valid[i] <= 'b0;
            end
        end
        else if(cache_tag[cache_index_tmp] == cache_tag_tmp && cache_valid[cache_index_tmp] == 1'b1) begin
            cache_hit <= 'b1;
        end
        else if(rvalid && rready) begin
            // have updated the cache
            inst <= cache_data[cache_index_tmp];
            inst_fin_cache <= 1'b1;
        end
        else begin
            cache_hit <= 'b0;
            inst_fin_cache <= 'b0;
        end 
    end

    always @(posedge clk) begin
        if(!rst) begin
            arvalid <= 1'b0;
            cnt <= 1'b0;
        end
        else if(if_en) begin
            if(cnt == 1'b1) begin
                // cache hit
                if(cache_hit) begin
                    inst <= cache_data[cache_index_tmp];
                    inst_fin_cache <= 1'b1;
                end
                else begin
                    // cache miss, need to read from memory
                    arvalid <= 1'b1;
                    araddr <= addr;
                    arid <= 4'b0;
                    arlen <= 8'b0;
                    arsize <= 3'b10;
                    arburst <<= 2'b0;
                end

                cnt <= 1'b0;
            end
            else begin
                cnt <= 1'b1;
            end
        end
        else if(arready && arvalid) begin
            arvalid <= 1'b0;
            `ifdef CONFIG_DPIC
            statistics_ifu_get_inst();
            `endif
        end
        else begin
            arvalid <= arvalid;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            rready <= 1'b0;
            inst_fin_axi <= 'b0;
        end
        else if(rvalid) begin
            rready <= 1'b1;

            // inst <= rdata;
            // inst_fin_axi <= 1'b1;

            // rresp != 2'b0 : error

            // update cache
            cache_tag[cache_index_tmp] <= cache_tag_tmp;
            cache_data[cache_index_tmp] <= rdata;
            cache_valid[cache_index_tmp] <= 1'b1;
        end
        else begin
            rready <= 1'b0;
            inst_fin_axi <= 1'b0;
        end
    end


endmodule
