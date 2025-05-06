`define USE_ICACHE
// `define USE_DCACHE
`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_ICACHE(
  input clk,
  input rst,
  input fencei_mem,

  // axi from lsu
  input arvalid_xbar_i,
  input [`ysyx_24080020_WIDTH-1:0] araddr_xbar_i,
  input [3:0] arid_xbar_i,
  input [7:0] arlen_xbar_i,
  input [2:0] arsize_xbar_i,
  input [1:0] arburst_xbar_i,
  output reg arready_icache_o,

  input rready_xbar_i,
  output reg [`ysyx_24080020_WIDTH-1:0] rdata_icache_o,
  output reg [1:0] rresp_icache_o,
  output reg rvalid_icache_o,
  output reg [3:0] rid_icache_o,
  output reg rlast_icache_o,

  input [`ysyx_24080020_WIDTH-1:0] awaddr_xbar_i,
  input awvalid_xbar_i,
  input [3:0] awid_xbar_i,
  input [7:0] awlen_xbar_i,
  input [2:0] awsize_xbar_i,
  input [1:0] awburst_xbar_i,
  output reg awready_icache_o,

  input [`ysyx_24080020_WIDTH-1:0] wdata_xbar_i,
  input [3:0] wstrb_xbar_i,
  input wvalid_xbar_i,
  input wlast_xbar_i,
  output reg wready_icache_o,

  input bready_xbar_i,
  output reg bvalid_icache_o,
  output reg [3:0] bid_icache_o,
  output reg [1:0] bresp_icache_o,

  // axi to soc
  output reg arvalid_icache_o,
  output reg [`ysyx_24080020_WIDTH-1:0] araddr_icache_o,
  output reg [3:0] arid_icache_o,
  output reg [7:0] arlen_icache_o,
  output reg [2:0] arsize_icache_o,
  output reg [1:0] arburst_icache_o,
  input arready_soc_i,

  output reg rready_icache_o,
  input [`ysyx_24080020_WIDTH-1:0] rdata_soc_i,
  input [1:0] rresp_soc_i,
  input rvalid_soc_i,
  input [3:0] rid_soc_i,
  input rlast_soc_i,

  output reg [`ysyx_24080020_WIDTH-1:0] awaddr_icache_o,
  output reg awvalid_icache_o,
  output reg [3:0] awid_icache_o,
  output reg [7:0] awlen_icache_o,
  output reg [2:0] awsize_icache_o,
  output reg [1:0] awburst_icache_o,
  input awready_soc_i,

  output reg [`ysyx_24080020_WIDTH-1:0] wdata_icache_o,
  output reg [3:0] wstrb_icache_o,
  output reg wvalid_icache_o,
  output reg wlast_icache_o,
  input wready_soc_i,

  output reg bready_icache_o,
  input bvalid_soc_i,
  input [3:0] bid_soc_i,
  input [1:0] bresp_soc_i
);

  `ifdef CONFIG_DPIC
  import "DPI-C" function void statistics_icache_hit();
  import "DPI-C" function void statistics_icache_miss();
  import "DPI-C" function void statistics_dcache_hit();
  `endif
`ifdef USE_ICACHE
  localparam IDLE = 0;
  localparam JUDGE = IDLE + 1;
  localparam CHIT = JUDGE + 1;
  localparam CMISS = CHIT + 1;
  localparam AXIAR = CMISS + 1;
  localparam AXIR = AXIAR + 1;
  localparam AXIDone = AXIR + 1;  // not use cache, such as sram

  reg fin_r, fin_ar, r_en, all_fin, fin_judge, is_hit, update_fifo_index;
  reg [2:0] current_state, next_state;
  reg [31:0] rdata_tmp, araddr_tmp;

  reg flush_cache;
  reg [cache_num_bits-1:0] num_index;

  reg toggle;

  wire use_icache;
  wire in_flash;
  wire in_mrom;
  wire in_sdram;

  integer  i;

  // CACHE
  // cacheway maybe not the 2^n
  localparam cache_way = `ysyx_24080020_CACHE_WAY;
  localparam cache_size = `ysyx_24080020_CACHE_SIZE;
  localparam cache_num = `ysyx_24080020_CACHE_NUM;

  localparam cache_size_bits = $clog2(cache_size);
  localparam cache_size_shift = $clog2(cache_size << 3);
  localparam cache_num_bits = $clog2(cache_num);

  localparam cache_tag_size = 32 - cache_size_bits - cache_num_bits;
  localparam cache_data_ingroup_width = (cache_size << 3) * cache_way;
  localparam cache_tag_width = cache_tag_size;
  localparam cache_tag_ingroup_width = cache_tag_width * cache_way;
  localparam data_complete_bits = cache_data_ingroup_width - 32;
  localparam tag_complete_bits = cache_tag_ingroup_width - cache_tag_size;

  wire [cache_data_ingroup_width-1 : 0] shift_rdata;
  wire [cache_data_ingroup_width-1 : 0] shift_wdata;
  wire [cache_data_ingroup_width-1 : 0] data_mask;

  wire [cache_tag_ingroup_width-1 : 0]  shift_rtag;
  wire [cache_tag_ingroup_width-1 : 0]  shift_wtag;
  wire [cache_tag_ingroup_width-1 : 0]  tag_mask;

  wire                                    cache_hit;
  wire [cache_tag_size-1:0]               cache_tag_tmp;
  wire [cache_num_bits-1:0]               cache_index_tmp;
  wire [cache_size_bits-1:0]              cache_offset_tmp;

  reg [cache_data_ingroup_width - 1 : 0]  cache_data  [0 : cache_num - 1];
  reg [cache_tag_ingroup_width - 1 : 0]   cache_tag   [0 : cache_num - 1];
  reg [cache_way - 1 : 0]                 cache_valid [0 : cache_num - 1];

  reg [cache_way - 1 : 0]                 fifo_index [0 : cache_num - 1];
  reg [cache_way - 1 : 0]                 tag_index;


  assign cache_tag_tmp = araddr_tmp[31 : cache_num_bits+cache_size_bits];
  assign cache_index_tmp = araddr_tmp[cache_num_bits+cache_size_bits-1 : cache_size_bits];
  assign cache_offset_tmp = araddr_tmp[cache_size_bits-1 : 0];


  assign shift_rdata = cache_data[cache_index_tmp] >> ({ {(cache_data_ingroup_width-cache_way){1'b0}}, tag_index} << (cache_size_shift) ) >> ({{(32-cache_size_bits){1'b0}}, cache_offset_tmp} << 3);
  assign shift_wdata = ({{data_complete_bits{1'b0}}, rdata_soc_i} << (({{(cache_data_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_tmp]}) << cache_size_shift) << ({{(32-cache_size_bits){1'b0}}, cache_offset_tmp} << 3));
  assign data_mask = ({{data_complete_bits{1'b0}}, ~32'b0} << (({{(cache_data_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_tmp]}) << cache_size_shift) << ({{(32-cache_size_bits){1'b0}}, cache_offset_tmp} << 3));


  // assign shift_rtag = (cache_tag[cache_index_tmp] & tag_mask) >> (({{32-cache_size_bits{1'b0}}, cache_offset_tmp} >> 2) * cache_tag_size);
  // assign shift_wtag = ({{tag_complete_bits{1'b0}}, cache_tag_tmp} << (({{32-cache_size_bits{1'b0}}, cache_offset_tmp} >> 2) * cache_tag_size));
  // assign tag_mask = {{tag_complete_bits{1'b0}}, ~{cache_tag_size{1'b0}}} << (({{32-cache_size_bits{1'b0}}, cache_offset_tmp} >> 2) * cache_tag_size);
  assign shift_rtag = (cache_tag[cache_index_tmp] >> ({ {(cache_tag_ingroup_width-cache_way){1'b0}}, tag_index} * cache_tag_width)) & ({ {tag_complete_bits{1'b0}}, {cache_tag_width{1'b1}} });
  assign shift_wtag = {{tag_complete_bits{1'b0}}, cache_tag_tmp} << ({ {(cache_tag_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_tmp]} * cache_tag_width);
  assign tag_mask = {{tag_complete_bits{1'b0}}, ~{cache_tag_size{1'b0}}} << ({ {(cache_tag_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_tmp]} * cache_tag_width);

  assign cache_hit = ( shift_rtag == {{tag_complete_bits{1'b0}}, cache_tag_tmp})
                     && ((cache_valid[cache_index_tmp] & ({ {(cache_way-1){1'b0}}, 1'b1} << tag_index)) != 'b0);

  assign in_flash = (araddr_xbar_i >= 32'h30000000 && araddr_xbar_i < 32'h40000000) ? 1'b1 : 1'b0;
  assign in_mrom = (araddr_xbar_i >= 32'h20000000 && araddr_xbar_i < 32'h20001000) ? 1'b1 : 1'b0;
  assign in_sdram = (araddr_xbar_i >= 32'ha0000000 && araddr_xbar_i < 32'hc0000000) ? 1'b1 : 1'b0;

  `ifdef USE_DCACHE
  assign use_icache = in_flash | in_mrom | in_sdram;
  `endif
  `ifndef USE_DCACHE
  assign use_icache = in_flash | in_mrom;
  `endif

  always @(posedge clk) begin
      if(!rst) begin
          current_state <= 'b0;
          tag_index <= 'b0;
          toggle <= 'b0;
          for (i = 'b0; i < `ysyx_24080020_CACHE_NUM; i = i + 'b1 ) begin
              cache_data[i]   <= 'b0;
              cache_tag[i]    <= 'b0;
              cache_valid[i]  <= 'b0;
              fifo_index[i]   <= 'b0;
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
              if(r_en) begin
                  next_state = JUDGE;
              end
              else begin
                  next_state = IDLE;
              end
          end
          JUDGE: begin
              if(flush_cache) begin
                // wait flush cache
                next_state = JUDGE;
              end
              else if(fin_judge) begin
                  if(is_hit && use_icache) begin
                      next_state = CHIT;
                  end
                  else begin
                      next_state = CMISS;
                  end
              end
              else
                  next_state = JUDGE;
          end
          CHIT: begin
              if(all_fin) begin
                  next_state = IDLE;
              end
              else begin
                  next_state = CHIT;
              end
          end
          CMISS: begin
              next_state = AXIAR;
              `ifdef CONFIG_DPIC
              if(in_flash)
                  statistics_icache_miss();
              `endif
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
                      next_state = JUDGE;
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
              if(all_fin) begin
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
              fin_ar <= 'b0;
              fin_r <= 'b0;
              all_fin <= 'b0;

              fin_judge <= 'b0;
              is_hit <= 'b0;
              update_fifo_index <= 'b0;

              tag_index <= 'b0;

              rready_icache_o <= 'b0;
          end
          JUDGE: begin
              if(fin_judge) begin
                araddr_tmp <= {araddr_xbar_i[31:2], 2'b0};
                fin_judge <= 'b0;
              end
              else if(tag_index < cache_way) begin
                if(cache_hit) begin
                  is_hit <= 'b1;
                  fin_judge <= 'b1;
                end
                else begin
                  tag_index <= tag_index + 'b1;
                end
              end
              else begin
                tag_index <= 'b0;
                fin_judge <= 'b1;
              end
          end
          CHIT: begin
              rdata_tmp <= shift_rdata[31:0];
              all_fin <= 'b1;

              `ifdef CONFIG_DPIC
              // hit cache and not by axi
              if(!fin_r) begin
                  if(toggle) begin
                    toggle <= 'b0;
                    if(in_flash)
                      statistics_icache_hit();
                    else if(in_sdram)
                      statistics_dcache_hit();
                    // $display("cache hit addr: 0x%x", araddr_icache_o);
                  end
                  else
                    toggle <= 'b1;
              end
              else begin
                // $display("cache miss addr: 0x%x", araddr_icache_o);
              end
              `endif
          end
          CMISS: begin
              // do nothing
          end
          AXIAR: begin
              if(arready_soc_i && arvalid_icache_o) begin
                  arvalid_icache_o <= 'b0;
                  fin_ar <= 'b1;
              end
              else if(!fin_ar) begin
                  arvalid_icache_o <= 1'b1;
                  if(use_icache) begin
                    // burst trans in sdram
                    araddr_icache_o <= araddr_icache_o & ~(cache_size - 32'b1);

                    arsize_icache_o <= 'b10;
                    arid_icache_o <= 'b0;
                    arlen_icache_o <= (cache_size >> 2) - 1;
                    arburst_icache_o <= 'b01;

                    araddr_tmp <= araddr_tmp & ~(cache_size - 32'b1) ;
                  end
              end
          end
          AXIR: begin
              if(rvalid_soc_i && rready_icache_o) begin
                  rready_icache_o <= 1'b0;
                  if(rresp_soc_i == 2'b00) begin // OKAY
                      rdata_tmp <= rdata_soc_i;
                      if(use_icache) begin
                          // update cache
                          cache_data[cache_index_tmp] <= (cache_data[cache_index_tmp] & ~data_mask) | shift_wdata;
                      end

                      if(rlast_soc_i) begin
                        fin_r <= 1'b1;
                        araddr_tmp <= {araddr_xbar_i[31 : 2], 2'b0};

                        if(use_icache) begin
                          fifo_index[cache_index_tmp] <= (fifo_index[cache_index_tmp] + 'b1) % cache_way;
                          cache_tag[cache_index_tmp] <= (cache_tag[cache_index_tmp] & ~tag_mask) | shift_wtag;
                          cache_valid[cache_index_tmp] <= cache_valid[cache_index_tmp] | (1 << (fifo_index[cache_index_tmp]));
                        end
                      end
                      else begin
                        // update araddr to adapt burst transmit, it's for icache parameter
                        araddr_tmp <= araddr_tmp + 2 ** arsize_icache_o;
                      end
                  end
                  else begin
                      // error
                      `ifdef CONFIG_DPIC
                      $error("fetch inst error");
                      `endif
                  end
              end
              else if(rvalid_soc_i) begin
                rready_icache_o <= 'b1;
              end
          end
          AXIDone: begin
              all_fin <= 1'b1;
          end
          default: begin
              // do nothing
          end
      endcase
  end

  // set icache invalid, when writing after reading.
  always @(posedge clk) begin
    if(!rst) begin

    end
    else if(bvalid_soc_i && use_icache && cache_hit) begin
      // set invalid
      cache_valid[cache_index_tmp] <= cache_valid[cache_index_tmp] & ~(1 << (cache_offset_tmp >> 2));
    end
    else if(awvalid_xbar_i && use_icache) begin
      araddr_tmp <= {awaddr_xbar_i[31:2], 2'b0};
    end


  end

  // AR
  always @(posedge clk) begin
    if(!rst)begin
      r_en <= 'b0;
      arready_icache_o <= 'b0;

      arvalid_icache_o <= 'b0;
      arid_icache_o <= 'b0;
      arlen_icache_o <= 'b0;
      arburst_icache_o <= 'b0;
      arsize_icache_o <= 'b0;
      araddr_icache_o <= 'b0;

    end
    else if(arvalid_xbar_i) begin
      araddr_icache_o <= araddr_xbar_i;
      arlen_icache_o <= arlen_xbar_i;
      arid_icache_o <= arid_xbar_i;
      arburst_icache_o <= arburst_xbar_i;
      arsize_icache_o <= arsize_xbar_i;

      arready_icache_o <= 1'b1;

      araddr_tmp <= araddr_xbar_i;

      r_en <= 'b1;
    end
    else begin
      arready_icache_o <= 1'b0;
      r_en <= 'b0;
    end

  end
  // R
  always @(posedge clk) begin
    if(!rst) begin
      rvalid_icache_o <= 'b0;
      rdata_icache_o <= 'b0;
      rlast_icache_o <= 'b0;
      rresp_icache_o <= 'b0;
      rid_icache_o <= 'b0;
    end
    else if(rready_xbar_i && rvalid_icache_o) begin
      rvalid_icache_o <= 'b0;
      rresp_icache_o <= 'b0;
      rlast_icache_o <= 'b0;
    end
    else if(all_fin) begin
      rvalid_icache_o <= 'b1;
      rdata_icache_o <= rdata_tmp;
      rlast_icache_o <= 'b1;
      rresp_icache_o <= 'b0;
    end
  end

  always @(posedge clk) begin
    if(rst) begin
      flush_cache <= 'b0;
    end
    else if(fencei_mem) begin
      flush_cache <= 'b1;
      num_index <= 'b0;
    end
  end

  always @(posedge clk) begin
    if(rst) begin
      num_index <= 'b0;
    end
    else if({{(32-cache_num_bits){1'b0}} ,num_index} >= cache_num) begin
      flush_cache <= 'b0;
    end
    else if(flush_cache) begin
      cache_valid[num_index] <= {cache_way{1'b0}};
      num_index <= num_index + 'b1;
    end
  end

`endif
`ifndef USE_ICACHE
  // AR
  assign arvalid_icache_o = arvalid_xbar_i;
  assign araddr_icache_o = araddr_xbar_i;
  assign arid_icache_o = arid_xbar_i;
  assign arlen_icache_o = arlen_xbar_i;
  assign arburst_icache_o = arburst_xbar_i;
  assign arsize_icache_o = arsize_xbar_i;
  assign arready_icache_o = arready_soc_i;

  // R
  assign rvalid_icache_o = rvalid_soc_i;
  assign rdata_icache_o = rdata_soc_i;
  assign rresp_icache_o = rresp_soc_i;
  assign rid_icache_o = rid_soc_i;
  assign rlast_icache_o = rlast_soc_i;
  assign rready_icache_o = rready_xbar_i;

`endif
  // AW
  assign awvalid_icache_o = awvalid_xbar_i;
  assign awaddr_icache_o = awaddr_xbar_i;
  assign awlen_icache_o = awlen_xbar_i;
  assign awburst_icache_o = awburst_xbar_i;
  assign awid_icache_o = awid_xbar_i;
  assign awsize_icache_o = awsize_xbar_i;
  assign awready_icache_o = awready_soc_i;
  // W
  assign wvalid_icache_o = wvalid_xbar_i;
  assign wdata_icache_o = wdata_xbar_i;
  assign wstrb_icache_o = wstrb_xbar_i;
  assign wlast_icache_o = wlast_xbar_i;
  assign wready_icache_o = wready_soc_i;
  // B
  assign bvalid_icache_o = bvalid_soc_i;
  assign bid_icache_o = bid_soc_i;
  assign bresp_icache_o = bresp_soc_i;
  assign bready_icache_o = bready_xbar_i;


endmodule
