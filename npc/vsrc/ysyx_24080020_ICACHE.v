`define USE_ICACHE
// `define USE_DCACHE
`define ICACHE_PIPELINE
`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_ICACHE(
  input clk,
  input rst,
  input fencei_mem,

  output in_flash_,
  input busy_i,
  output reg busy,

  output [`ysyx_24080020_WIDTH-1:0] raddr,

  input special_pc_i,
  output reg special_pc_o,
  // axi from lsu
  input arvalid_i,
  input [`ysyx_24080020_WIDTH-1:0] araddr_i,
  input [3:0] arid_i,
  input [7:0] arlen_i,
  input [2:0] arsize_i,
  input [1:0] arburst_i,
  output reg arready_i,

  input rready_i,
  output reg [`ysyx_24080020_WIDTH-1:0] rdata_i,
  output reg [1:0] rresp_i,
  output reg rvalid_i,
  output reg [3:0] rid_i,
  output reg rlast_i,

  // axi to soc
  output reg arvalid_o,
  output reg [`ysyx_24080020_WIDTH-1:0] araddr_o,
  output reg [3:0] arid_o,
  output reg [7:0] arlen_o,
  output reg [2:0] arsize_o,
  output reg [1:0] arburst_o,
  input arready_o,

  output reg rready_o,
  input [`ysyx_24080020_WIDTH-1:0] rdata_o,
  input [1:0] rresp_o,
  input rvalid_o,
  input [3:0] rid_o,
  input rlast_o
);

  `ifdef CONFIG_DPIC
  import "DPI-C" function void statistics_icache_hit();
  import "DPI-C" function void statistics_icache_miss();
  import "DPI-C" function void statistics_dcache_hit();
  `endif
`ifdef USE_ICACHE
`ifndef ICACHE_PIPELINE
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
  reg [cache_num-1:0] num_index;

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
  assign shift_wdata = ({{data_complete_bits{1'b0}}, rdata_o} << (({{(cache_data_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_tmp]}) << cache_size_shift) << ({{(32-cache_size_bits){1'b0}}, cache_offset_tmp} << 3));
  assign data_mask = ({{data_complete_bits{1'b0}}, ~32'b0} << (({{(cache_data_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_tmp]}) << cache_size_shift) << ({{(32-cache_size_bits){1'b0}}, cache_offset_tmp} << 3));


  // assign shift_rtag = (cache_tag[cache_index_tmp] & tag_mask) >> (({{32-cache_size_bits{1'b0}}, cache_offset_tmp} >> 2) * cache_tag_size);
  // assign shift_wtag = ({{tag_complete_bits{1'b0}}, cache_tag_tmp} << (({{32-cache_size_bits{1'b0}}, cache_offset_tmp} >> 2) * cache_tag_size));
  // assign tag_mask = {{tag_complete_bits{1'b0}}, ~{cache_tag_size{1'b0}}} << (({{32-cache_size_bits{1'b0}}, cache_offset_tmp} >> 2) * cache_tag_size);
  assign shift_rtag = (cache_tag[cache_index_tmp] >> ({ {(cache_tag_ingroup_width-cache_way){1'b0}}, tag_index} * cache_tag_width)) & ({ {tag_complete_bits{1'b0}}, {cache_tag_width{1'b1}} });
  assign shift_wtag = {{tag_complete_bits{1'b0}}, cache_tag_tmp} << ({ {(cache_tag_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_tmp]} * cache_tag_width);
  assign tag_mask = {{tag_complete_bits{1'b0}}, ~{cache_tag_size{1'b0}}} << ({ {(cache_tag_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_tmp]} * cache_tag_width);

  assign cache_hit = ( shift_rtag == {{tag_complete_bits{1'b0}}, cache_tag_tmp})
                     && ((cache_valid[cache_index_tmp] & ({ {(cache_way-1){1'b0}}, 1'b1} << tag_index)) != 'b0);

  assign in_flash = (araddr_tmp >= 32'h30000000 && araddr_tmp < 32'h40000000) ? 1'b1 : 1'b0;
  assign in_mrom = (araddr_tmp >= 32'h20000000 && araddr_tmp < 32'h20001000) ? 1'b1 : 1'b0;
  assign in_sdram = (araddr_tmp >= 32'ha0000000 && araddr_tmp < 32'hc0000000) ? 1'b1 : 1'b0;
  assign in_flash_ = in_flash;

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
          busy <= 'b0;
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

              num_index <= 'b0;
          end
          JUDGE: begin
              if(fin_judge) begin
                araddr_tmp <= {araddr_tmp[31:2], 2'b0};
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
  // always @(posedge clk) begin
  //   if(!rst) begin

  //   end
  //   else if(bvalid_soc_i && use_icache && cache_hit) begin
  //     // set invalid
  //     cache_valid[cache_index_tmp] <= cache_valid[cache_index_tmp] & ~(1 << (cache_offset_tmp >> 2));
  //   end
  //   else if(awvalid_xbar_i && use_icache) begin
  //     araddr_tmp <= {awaddr_xbar_i[31:2], 2'b0};
  //   end


  // end

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
    else if(arvalid_xbar_i && !busy) begin
      araddr_icache_o <= araddr_xbar_i;
      arlen_icache_o <= arlen_xbar_i;
      arid_icache_o <= arid_xbar_i;
      arburst_icache_o <= arburst_xbar_i;
      arsize_icache_o <= arsize_xbar_i;

      arready_icache_o <= 1'b1;

      araddr_tmp <= araddr_xbar_i;

      r_en <= 'b1;
      busy <= 'b1;
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
      busy <= 'b0;
    end
    else if(all_fin) begin
      rvalid_icache_o <= 'b1;
      rdata_icache_o <= rdata_tmp;
      rlast_icache_o <= 'b1;
      rresp_icache_o <= 'b0;
    end
  end

  always @(posedge clk) begin
    if(!rst) begin
      flush_cache <= 'b0;
    end
    else if(fencei_mem && !flush_cache) begin
      flush_cache <= 'b1;
      num_index <= 'b0;
    end
  end

  always @(posedge clk) begin
    if(!rst) begin
      num_index <= 'b0;
    end
    else if({{(32-cache_num){1'b0}}, num_index} == cache_num - 'b1) begin
      flush_cache <= 'b0;
    end
    else if(flush_cache) begin
      cache_valid[num_index[cache_num_bits-1:0]] <= {cache_way{1'b0}};
      num_index <= num_index + 'b1;
    end
  end

  // always @(posedge clk) begin
  //   if(!rst) begin

  //   end
  //   else if((awvalid_xbar_i || wvalid_xbar_i) && !busy) begin
  //     busy <= 1'b1;
  //   end
  //   else if(bvalid_icache_o && bready_xbar_i) begin
  //     busy <= 'b0;
  //   end

  // end

`endif  // `ifndef ICACHE_PIPELINE

`ifdef ICACHE_PIPELINE

  reg fin_r, fin_ar, r_en, all_fin, fin_judge, is_hit, update_fifo_index;
  reg [2:0] current_state, next_state;
  reg [31:0] rdata_tmp, araddr_tmp;

  reg flush_cache;
  reg [cache_num-1:0] num_index;

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




// bus
  reg s0_s1_valid;
  reg s1_s0_ready;
  reg s1_s2_valid;
  reg s2_s1_ready;
  reg s2_s0_valid;
  reg s0_s2_ready;
  reg s0_s1_shake_hands, s1_s2_shake_hands, s2_s0_shake_hands;
  reg [`ysyx_24080020_WIDTH-1:0] inst_s0;
  // reg [`ysyx_24080020_WIDTH-1:0] rdata_araddr_s0;

  reg special_pc_tmp;
  reg special_pc_s0;
  reg special_pc_s0_o;

  reg [7:0] arlen_tmp;
  reg [3:0] arid_tmp;
  reg [1:0] arburst_tmp;
  reg [2:0] arsize_tmp;

// tmp <-> s0

    reg tmp_s0_valid;
    reg s0_tmp_ready;
    reg tmp_s0_shake_hands;

    always @(posedge clk) begin
        if(!rst) begin
            tmp_s0_valid <= 'b0;
            s0_tmp_ready <= 'b1;
            tmp_s0_shake_hands <= 'b0;
        end
        else if(tmp_s0_valid && s0_tmp_ready) begin
            tmp_s0_valid <= 'b0;
            s0_tmp_ready <= 'b0;
            tmp_s0_shake_hands <= 'b1;
            // arready_i <= 1'b1;

            araddr_s0 <= araddr_tmp;
            arlen_s0 <= arlen_tmp;
            arid_s0 <= arid_tmp;
            arburst_s0 <= arburst_tmp;
            arsize_s0 <= arsize_tmp;
            special_pc_s0 <= special_pc_tmp;
        end
    end


// s0
    reg [`ysyx_24080020_WIDTH-1:0] araddr_s0, raddr_s0;
    reg [7:0] arlen_s0;
    reg [3:0] arid_s0;
    reg [1:0] arburst_s0;
    reg [2:0] arsize_s0;

    always @(posedge clk) begin
        if(!rst) begin
            s0_s1_valid <= 'b0;
            s0_s2_ready <= 'b1;
            inst_s0 <= 'b0;
            raddr_s0 <= 'b0;
            special_pc_s0 <= 'b0;
            special_pc_s0_o <= 'b0;

            araddr_s0 <= 'b0;
            arlen_s0 <= 'b0;
            arid_s0 <= 'b0;
            arburst_s0 <= 'b0;
            arsize_s0 <= 'b0;
        end
        else if(s0_s1_valid && s1_s0_ready) begin
            s0_s1_valid <= 'b0;
            s0_tmp_ready <= 'b1;
            s0_s1_shake_hands <= 'b1;

            // s1_s0_ready <= 1'b1; // s1 -> s2 hands
            araddr_s1 <= araddr_s0;
            arlen_s1 <= arlen_s0;
            arid_s1 <= arid_s0;
            arburst_s1 <= arburst_s0;
            arsize_s1 <= arsize_s0;
            special_pc_s1 <= special_pc_s0;

        end
        else if(tmp_s0_shake_hands) begin
            tmp_s0_shake_hands <= 'b0;
            s0_s1_valid <= 'b1;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            // rdata_araddr_s0 <= 'b0;
        end
        else if(s2_s0_valid && s0_s2_ready) begin
            s0_s2_ready <= 'b0;
            s2_s0_shake_hands <= 'b1;

            raddr_s0 <= raddr_s2;
            special_pc_s0_o <= special_pc_s2_o;

            inst_s0 <= inst_s2;
        end
        else if(s2_s0_shake_hands) begin
          s2_s0_shake_hands <= 'b0;

          rvalid_i <= 'b1;
          rdata_i <= inst_s0;
          rlast_i <= 'b1;
          rresp_i <= 'b0;
          // rdata_araddr <= rdata_araddr_s0;
        end
    end

// s1
  reg [cache_tag_size-1:0]    cache_tag_s1;
  reg [cache_num_bits-1:0]    cache_index_s1;
  reg [cache_size_bits-1:0]   cache_offset_s1;
  reg [`ysyx_24080020_WIDTH-1:0] araddr_s1;

  reg [7:0] arlen_s1;
  reg [3:0] arid_s1;
  reg [1:0] arburst_s1;
  reg [2:0] arsize_s1;

  reg special_pc_s1;

  always @(posedge clk) begin
    if(!rst) begin
      s1_s2_valid <= 'b0;
      s1_s0_ready <= 'b1;

      araddr_s1 <= 'b0;
      arlen_s1 <= 'b0;
      arid_s1 <= 'b0;
      arburst_s1 <= 'b0;
      arsize_s1 <= 'b0;

      cache_tag_s1 <= 'b0;
      cache_index_s1 <= 'b0;
      cache_offset_s1 <= 'b0;
      special_pc_s1 <= 'b0;
    end
    else if(s0_s1_valid && s1_s0_ready) begin
        s1_s0_ready <= 'b0;
    end
    else if(s0_s1_shake_hands) begin
        s0_s1_shake_hands <= 'b0;

    end
  end

  always @(posedge clk) begin
    if(!rst) begin
      s1_s2_valid <= 'b0;
    end
    else if(s1_s2_valid && s2_s1_ready) begin
      s1_s2_valid <= 1'b0;
      s1_s2_shake_hands <= 'b1;

      araddr_s2 <= araddr_s1;
      arlen_s2 <= arlen_s1;
      arid_s2 <= arid_s1;
      arburst_s2 <= arburst_s1;
      arsize_s2 <= arsize_s1;

      araddr_s2_base <= araddr_s1;
      special_pc_s2_i <= special_pc_s1;
    end
    else if(s0_s1_shake_hands) begin
        s1_s2_valid <= 1'b1;
        cache_tag_s1 <= araddr_s1[31 : cache_num_bits+cache_size_bits];
        cache_index_s1 <= araddr_s1[cache_num_bits+cache_size_bits-1 : cache_size_bits];
        cache_offset_s1 <= araddr_s1[cache_size_bits-1 : 0];

    end
  end


// s2
  localparam IDLE = 0;
  localparam JUDGE = IDLE + 1;
  localparam CHIT = JUDGE + 1;
  localparam CMISS = CHIT + 1;
  localparam AXIAR = CMISS + 1;
  localparam AXIR = AXIAR + 1;
  localparam AXIDone = AXIR + 1;  // not use cache, such as sram

  wire [cache_tag_size-1:0]    cache_tag_s2;
  wire [cache_num_bits-1:0]    cache_index_s2;
  wire [cache_size_bits-1:0]   cache_offset_s2;

  logic has_hit;
  logic total_hits [0 : cache_way - 1];
  logic [cache_way-1:0] tmp_tag_index;

  reg bubble;
  reg all_fin_ready;
  reg special_pc_s2_i, special_pc_s2_o;

  reg [`ysyx_24080020_WIDTH-1:0] araddr_s2;
  reg [`ysyx_24080020_WIDTH-1:0] araddr_s2_base;
  reg [`ysyx_24080020_WIDTH-1:0] inst_s2, raddr_s2;

  reg [7:0] arlen_s2;
  reg [3:0] arid_s2;
  reg [1:0] arburst_s2;
  reg [2:0] arsize_s2;

  assign cache_tag_s2 = araddr_s2[31 : cache_num_bits+cache_size_bits];
  assign cache_index_s2 = araddr_s2[cache_num_bits+cache_size_bits-1 : cache_size_bits];
  assign cache_offset_s2 = araddr_s2[cache_size_bits-1 : 0];

  assign shift_rdata = cache_data[cache_index_s2] >> ({ {(cache_data_ingroup_width-cache_way){1'b0}}, tag_index} << (cache_size_shift) ) >> ({{(32-cache_size_bits){1'b0}}, cache_offset_s2} << 3);
  assign shift_wdata = ({{data_complete_bits{1'b0}}, rdata_o} << (({{(cache_data_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_s2]}) << cache_size_shift) << ({{(32-cache_size_bits){1'b0}}, cache_offset_s2} << 3));
  assign data_mask = ({{data_complete_bits{1'b0}}, ~32'b0} << (({{(cache_data_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_s2]}) << cache_size_shift) << ({{(32-cache_size_bits){1'b0}}, cache_offset_s2} << 3));


  assign shift_rtag = (cache_tag[cache_index_s2] >> ({ {(cache_tag_ingroup_width-cache_way){1'b0}}, tag_index} * cache_tag_width)) & ({ {tag_complete_bits{1'b0}}, {cache_tag_width{1'b1}} });
  assign shift_wtag = {{tag_complete_bits{1'b0}}, cache_tag_s2} << ({ {(cache_tag_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_s2]} * cache_tag_width);
  assign tag_mask = {{tag_complete_bits{1'b0}}, ~{cache_tag_size{1'b0}}} << ({ {(cache_tag_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_s2]} * cache_tag_width);

  assign cache_hit = ( shift_rtag == {{tag_complete_bits{1'b0}}, cache_tag_s2})
                     && ((cache_valid[cache_index_s2] & ({ {(cache_way-1){1'b0}}, 1'b1} << tag_index)) != 'b0);

  generate
    genvar j;
    for (j = 0; j < cache_way; j++) begin
        assign total_hits[j] = (cache_tag[cache_index_s2][(j+1)*cache_tag_width-1:j*cache_tag_width] == cache_tag_s2) && ((cache_valid[cache_index_s2] & ({ {(cache_way-1){1'b0}}, 1'b1} << j)) != 'b0);
    end
  endgenerate

  always_comb begin
      tmp_tag_index = 0;
      has_hit = 0;
      for (int i = 0; i < cache_way; i++) begin
          if (total_hits[i]) begin
              has_hit = 'b1;
              tmp_tag_index = i[cache_way-1:0];
          end
      end
  end

  assign in_flash = (araddr_tmp >= 32'h30000000 && araddr_tmp < 32'h40000000) ? 1'b1 : 1'b0;
  assign in_mrom = (araddr_tmp >= 32'h20000000 && araddr_tmp < 32'h20001000) ? 1'b1 : 1'b0;
  assign in_sdram = (araddr_tmp >= 32'ha0000000 && araddr_tmp < 32'hc0000000) ? 1'b1 : 1'b0;
  assign in_flash_ = in_flash;

  `ifdef USE_DCACHE
  assign use_icache = in_flash | in_mrom | in_sdram;
  `endif
  `ifndef USE_DCACHE
  assign use_icache = in_flash | in_mrom;
  `endif

  always @(posedge clk) begin
    if(!rst) begin
      s2_s1_ready <= 'b1;
      s2_s0_valid <= 'b0;

      inst_s2 <= 'b0;

      araddr_s2 <= 'b0;
      arlen_s2 <= 'b0;
      arid_s2 <= 'b0;
      arburst_s2 <= 'b0;
      arsize_s2 <= 'b0;
      araddr_s2_base <= 'b0;
      raddr_s2 <= 'b0;
      bubble <= 'b0;
      special_pc_s2_i <= 'b0;
      special_pc_s2_o <= 'b0;
    end
    else if(s1_s2_valid && s2_s1_ready) begin
      s2_s1_ready <= 'b0;
      s1_s2_shake_hands <= 'b1;
      s1_s0_ready <= 'b1;
    end
    else if(s1_s2_shake_hands) begin

    end
  end

  always @(posedge clk) begin
    if(!rst) begin
      s2_s0_valid <= 'b0;
      all_fin_ready <= 'b0;
    end
    else if(s2_s0_valid && s0_s2_ready) begin
      s2_s0_valid <= 1'b0;
      s2_s1_ready <= 1'b1;
    end
    else if(all_fin && all_fin_ready) begin
        all_fin_ready <= 'b0;
        s2_s0_valid <= 1'b1;

        inst_s2 <= rdata_tmp;
        s1_s2_shake_hands <= 'b0;
        raddr_s2 <= araddr_s2_base;
        special_pc_s2_o <= special_pc_s2_i;
    end
    else if(all_fin) begin
        all_fin_ready <= 'b1;
    end
  end


  always @(posedge clk) begin
      if(!rst) begin
          current_state <= 'b0;
          tag_index <= 'b0;
          toggle <= 'b0;
          busy <= 'b0;
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
              if(s1_s2_valid && s2_s1_ready) begin
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
              if(all_fin && all_fin_ready) begin
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
              if(all_fin && all_fin_ready) begin
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

              rready_o <= 'b0;

              num_index <= 'b0;
          end
          JUDGE: begin
              if(fin_judge) begin
                  araddr_s2 <= {araddr_s2[31:2], 2'b0};
                  fin_judge <= 'b0;
              end
              else if(has_hit) begin
                  is_hit <= 'b1;
                  tag_index <= tmp_tag_index;
                  fin_judge <= 'b1;
              end
              else begin
                  is_hit <= 'b0;
                  fin_judge <= 'b1;
              end
              // if(fin_judge) begin
              //   araddr_s2 <= {araddr_s2[31:2], 2'b0};
              //   fin_judge <= 'b0;
              // end
              // else if(tag_index < cache_way) begin
              //   if(cache_hit) begin
              //     is_hit <= 'b1;
              //     fin_judge <= 'b1;
              //   end
              //   else begin
              //     tag_index <= tag_index + 'b1;
              //   end
              // end
              // else begin
              //   tag_index <= 'b0;
              //   fin_judge <= 'b1;
              // end
          end
          CHIT: begin
              rdata_tmp <= shift_rdata[31:0];

              all_fin <= 'b1;
              // if(!all_fin_ready)
              //   all_fin <= 'b1;

              `ifdef CONFIG_DPIC
              // hit cache and not by axi
              if(!fin_r) begin
                  if(toggle) begin
                    toggle <= 'b0;
                    if(in_flash)
                      statistics_icache_hit();
                    else if(in_sdram)
                      statistics_dcache_hit();
                    // $display("cache hit addr: 0x%x", araddr_o);
                  end
                  else
                    toggle <= 'b1;
              end
              else begin
                // $display("cache miss addr: 0x%x", araddr_o);
              end
              `endif
          end
          CMISS: begin
              // do nothing
          end
          AXIAR: begin
            if(arready_o && arvalid_o) begin
                arvalid_o <= 'b0;
                fin_ar <= 'b1;
                bubble <= 'b0;
            end
            else if(!fin_ar && !busy_i) begin
                busy <= 'b1;
                arvalid_o <= 1'b1;
                if(use_icache) begin
                    // burst trans in sdram
                    araddr_o <= araddr_s2 & ~(cache_size - 32'b1);

                    arsize_o <= 'b10;
                    arid_o <= 'b0;
                    arlen_o <= (cache_size >> 2) - 1;
                    arburst_o <= 'b01;

                    araddr_s2 <= araddr_s2 & ~(cache_size - 32'b1) ;
                end
            end
          end
          AXIR: begin
              if(rvalid_o && rready_o) begin
                  rready_o <= 1'b0;
                  if(rresp_o == 2'b00) begin // OKAY
                      rdata_tmp <= rdata_o;
                      if(use_icache) begin
                          // update cache
                          cache_data[cache_index_s2] <= (cache_data[cache_index_s2] & ~data_mask) | shift_wdata;
                      end

                      if(rlast_o) begin
                        busy <= 'b0;
                        fin_r <= 1'b1;
                        araddr_s2 <= {araddr_s2_base[31 : 2], 2'b0};

                        if(use_icache) begin
                          fifo_index[cache_index_s2] <= (fifo_index[cache_index_s2] + 'b1) % cache_way;
                          cache_tag[cache_index_s2] <= (cache_tag[cache_index_s2] & ~tag_mask) | shift_wtag;
                          cache_valid[cache_index_s2] <= cache_valid[cache_index_s2] | (1 << (fifo_index[cache_index_s2]));
                        end
                      end
                      else begin
                        // update araddr to adapt burst transmit, it's for icache parameter
                        araddr_s2 <= araddr_s2 + 2 ** arsize_o;
                      end
                  end
                  else begin
                      // error
                      `ifdef CONFIG_DPIC
                      $error("fetch inst error");
                      `endif
                  end
              end
              else if(rvalid_o) begin
                rready_o <= 'b1;
              end
          end
          AXIDone: begin
              if(!all_fin_ready)
                all_fin <= 1'b1;
          end
          default: begin
              // do nothing
          end
      endcase
  end



// axi
  // AR
  always @(posedge clk) begin
    if(!rst)begin
      r_en <= 'b0;
      arready_i <= 'b0;

      arvalid_o <= 'b0;
      arid_o <= 'b0;
      arlen_o <= 'b0;
      arburst_o <= 'b0;
      arsize_o <= 'b0;
      araddr_o <= 'b0;

      arlen_tmp <= 'b0;
      arid_tmp <= 'b0;
      arburst_tmp <= 'b0;
      arsize_tmp <= 'b0;

      special_pc_tmp <= 'b0;
    end
    else if(arvalid_i && arready_i) begin
      arready_i <= 'b0;
      // busy <= 'b0;
    end
    else if(arvalid_i && s0_tmp_ready) begin
      arlen_tmp <= arlen_i;
      arid_tmp <= arid_i;
      arburst_tmp <= arburst_i;
      arsize_tmp <= arsize_i;

      // busy <= 'b1;

      arready_i <= 1'b1;
      araddr_tmp <= araddr_i;
      special_pc_tmp <= special_pc_i;
      tmp_s0_valid <= 'b1;
    end
  end
  // R
  always @(posedge clk) begin
    if(!rst) begin
      rvalid_i <= 'b0;
      rdata_i <= 'b0;
      rlast_i <= 'b0;
      rresp_i <= 'b0;
      rid_i <= 'b0;
      // rdata_araddr <= 'b0;
      special_pc_o <= 'b0;
    end
    else if(rready_i && rvalid_i) begin
      rvalid_i <= 'b0;
      rresp_i <= 'b0;
      rlast_i <= 'b0;
      raddr <= raddr_s0;
      special_pc_o <= special_pc_s0_o;
      // busy <= 'b0;
      s0_s2_ready <= 'b1;
    end
  end

  always @(posedge clk) begin
    if(!rst) begin
      flush_cache <= 'b0;
    end
    else if(fencei_mem && !flush_cache) begin
      flush_cache <= 'b1;
      num_index <= 'b0;
    end
  end

  always @(posedge clk) begin
    if(!rst) begin
      num_index <= 'b0;
    end
    else if({{(32-cache_num){1'b0}}, num_index} == cache_num - 'b1) begin
      flush_cache <= 'b0;
    end
    else if(flush_cache) begin
      cache_valid[num_index[cache_num_bits-1:0]] <= {cache_way{1'b0}};
      num_index <= num_index + 'b1;
    end
  end

  // always @(posedge clk) begin
  //   if(!rst) begin

  //   end
  //   else if((awvalid_xbar_i || wvalid_xbar_i) && !busy) begin
  //     busy <= 1'b1;
  //   end
  //   else if(bvalid_icache_o && bready_xbar_i) begin
  //     busy <= 'b0;
  //   end

  // end


`endif // `ifdef ICACHE_PIPELINE

`endif  // USE_ICACHE




`ifndef USE_ICACHE
  // AR
  assign arvalid_o = arvalid_i;
  assign araddr_o = araddr_i;
  assign arid_o = arid_i;
  assign arlen_o = arlen_i;
  assign arburst_o = arburst_i;
  assign arsize_o = arsize_i;
  assign arready_i = arready_o;

  // R
  assign rvalid_i = rvalid_o;
  assign rdata_i = rdata_o;
  assign rresp_i = rresp_o;
  assign rid_i = rid_o;
  assign rlast_i = rlast_o;
  assign rready_o = rready_i;

`endif

endmodule
