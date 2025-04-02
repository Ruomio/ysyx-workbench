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
    import "DPI-C" function void statistics_icache_hit();
    `endif

    reg fin_r, fin_ar;
    reg [2:0] current_state, next_state;
    localparam IDLE = 0;
    localparam JUDGE = IDLE + 1;
    localparam CHIT = JUDGE + 1;
    localparam CMISS = CHIT + 1;
    localparam AXIAR = CMISS + 1;
    localparam AXIR = AXIAR + 1;
    localparam AXIDone = AXIR + 1;  // not use cache, such as sram

    wire use_icache;

    // CACHE
    localparam cache_size_bits = $clog2(`ysyx_24080020_CACHE_SIZE);
    localparam cache_num_bits = $clog2(`ysyx_24080020_CACHE_NUM);
    localparam cache_tag_size = 32 - cache_size_bits - cache_num_bits;
    localparam cache_data_width = `ysyx_24080020_CACHE_SIZE << 3;
    localparam cache_tag_width = cache_tag_size * (`ysyx_24080020_CACHE_SIZE >> 2);
    localparam data_complete_bits = cache_data_width - 32;
    localparam tag_complete_bits = cache_tag_width - cache_tag_size;

    wire [cache_data_width-1 : 0] shift_rdata;
    wire [cache_data_width-1 : 0] shift_wdata;
    wire [cache_data_width-1 : 0] data_mask;

    wire [cache_tag_width-1 : 0]  shift_rtag;
    wire [cache_tag_width-1 : 0]  shift_wtag;
    wire [cache_tag_width-1 : 0]  tag_mask;

    wire                                    cache_hit;
    wire [cache_tag_size-1:0]               cache_tag_tmp;
    wire [cache_num_bits-1:0]               cache_index_tmp;
    wire [cache_size_bits-1:0]              cache_offset_tmp;

    reg [cache_data_width-1 : 0]            cache_data  [0 : `ysyx_24080020_CACHE_NUM-1];
    reg [cache_tag_width-1 : 0]             cache_tag   [0 : `ysyx_24080020_CACHE_NUM-1];
    reg [cache_size_bits-1 : 0]             cache_valid [0 : `ysyx_24080020_CACHE_NUM-1];


    assign cache_tag_tmp = addr[31 : cache_num_bits+cache_size_bits];
    assign cache_index_tmp = addr[cache_num_bits+cache_size_bits-1 : cache_size_bits];
    assign cache_offset_tmp = addr[cache_size_bits-1 : 0];


    assign shift_rdata = cache_data[cache_index_tmp] >> ({{(32-cache_size_bits){1'b0}}, cache_offset_tmp} << 3);
    assign shift_wdata = ({{data_complete_bits{1'b0}}, rdata} << ({{(32-cache_size_bits){1'b0}}, cache_offset_tmp} << 3));
    assign data_mask = ({{data_complete_bits{1'b0}}, ~32'b0} << ({{(32-cache_size_bits){1'b0}}, cache_offset_tmp} << 3));


    assign shift_rtag = cache_tag[cache_index_tmp] >> (({{32-cache_size_bits{1'b0}}, cache_offset_tmp} >> 2) * cache_tag_size);
    assign shift_wtag = ({{tag_complete_bits{1'b0}}, cache_tag_tmp} << (({{32-cache_size_bits{1'b0}}, cache_offset_tmp} >> 2) * cache_tag_size));
    assign tag_mask = {{tag_complete_bits{1'b0}}, ~{cache_tag_size{1'b0}}} << (({{32-cache_size_bits{1'b0}}, cache_offset_tmp} >> 2) * cache_tag_size);

    assign cache_hit = (( shift_rtag == {{tag_complete_bits{1'b0}}, cache_tag_tmp})
                        && ((cache_valid[cache_index_tmp] >> (cache_offset_tmp >> 2)) == ({cache_size_bits{1'b0}} | 'b1)));

    assign use_icache = (araddr >= 32'h30000000 && araddr < 32'h40000000          // flash
                                || araddr >= 32'h20000000 && araddr < 32'h20001000       // mrom
                                ) ? 1'b1 : 1'b0;


    always @(posedge clk) begin
        if(!rst) begin
            fin_r <= 'b0;
            for (integer  i = 'b0; i < `ysyx_24080020_CACHE_NUM; i = i + 'b1 ) begin
                cache_data[i]   <= 'b0;
                cache_tag[i]    <= 'b0;
                cache_valid[i]  <= 'b0;
            end
        end
        else begin
            current_state <= next_state;
        end
    end

    // next_state
    always @(*) begin
        case(current_state)
            IDLE: begin
                if(if_en) begin
                    next_state = JUDGE;
                end
                else begin
                    next_state = IDLE;
                end
            end
            JUDGE: begin
                if(cache_hit) begin
                    next_state = CHIT;
                end
                else begin
                    next_state = CMISS;
                end
            end
            CHIT: begin
                if(inst_fin) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = CHIT;
                end
            end
            CMISS: begin
                next_state = AXIAR;
            end
            AXIAR: begin
                if(fin_ar) begin
                    next_state = AXIR;
                end
                else begin
                    next_state = AXIAR;
                end
            end
            AXIR: begin
                if(fin_r) begin
                    if(use_icache) begin
                        next_state = CHIT;
                    end
                    else begin
                        next_state = AXIDone;
                    end
                end
                else begin
                    next_state = AXIR;
                end
            end
            AXIDone: begin
                if(inst_fin) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = AXIDone;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        case(current_state)
            IDLE: begin
                inst_fin <= 'b0;
                fin_ar <= 'b0;
                fin_r <= 'b0;
                // do nothing
            end
            JUDGE: begin
                // do nothing
                `ifdef CONFIG_DPIC
                statistics_ifu_get_inst();
                `endif
            end
            CHIT: begin
                inst <= shift_rdata[31:0];
                inst_fin <= 'b1;

                `ifdef CONFIG_DPIC
                // $display("raddr: 0x%x  rdata: 0x%x",araddr, shift_rdata[31:0]);
                // hit cache and not by axi
                if(!fin_r) statistics_icache_hit();
                `endif
            end
            CMISS: begin
                // do nothing
            end
            AXIAR: begin
                if(arready && arvalid) begin
                    arvalid <= 'b0;
                    fin_ar <= 'b1;
                end
                else if(!fin_ar) begin
                    arvalid <= 1'b1;
                    araddr <= addr;
                    arid <= 4'b0;
                    arlen <= 8'b0;
                    arsize <= 3'b10; // 4Byte
                    arburst <= 2'b00; // FIXED
                end
            end
            AXIR: begin
                if(rvalid && rlast) begin
                    rready <= 1'b1;
                    if(rresp == 2'b00) begin // OKAY
                        if(use_icache) begin
                            // update cache
                            cache_tag[cache_index_tmp] <= (cache_tag[cache_index_tmp] & ~tag_mask) | shift_wtag;
                            cache_data[cache_index_tmp] <= (cache_data[cache_index_tmp] & ~data_mask) | shift_wdata;
                            cache_valid[cache_index_tmp] <= cache_valid[cache_index_tmp] | (1 << (cache_offset_tmp >> 2));
                        end

                        fin_r <= 1'b1;
                    end
                    else begin
                        // error
                        `ifdef CONFIG_DPIC
                        $error("fetch inst error");
                        `endif
                    end
                end
            end
            AXIDone: begin
                inst <= rdata;
                inst_fin <= 1'b1;
            end
            default: begin
                // do nothing
            end
        endcase
    end


endmodule
