`ifndef VERILATOR
module testbench;
  reg [4095:0] vcdfile;
  reg clock;
`else
module testbench(input clock, output reg genclock);
  initial genclock = 1;
`endif
  reg genclock = 1;
  reg [31:0] cycle = 0;
  reg [3:0] PI_rid;
  reg [31:0] PI_addr;
  reg [1:0] PI_rresp;
  reg [0:0] PI_rvalid;
  reg [0:0] PI_rst;
  wire [0:0] PI_clk = clock;
  reg [0:0] PI_if_en;
  reg [0:0] PI_rlast;
  reg [31:0] PI_rdata;
  reg [0:0] PI_arready;
  iCacheTest UUT (
    .rid(PI_rid),
    .addr(PI_addr),
    .rresp(PI_rresp),
    .rvalid(PI_rvalid),
    .rst(PI_rst),
    .clk(PI_clk),
    .if_en(PI_if_en),
    .rlast(PI_rlast),
    .rdata(PI_rdata),
    .arready(PI_arready)
  );
`ifndef VERILATOR
  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end
    #5 clock = 0;
    while (genclock) begin
      #5 clock = 0;
      #5 clock = 1;
    end
  end
`endif
  initial begin
`ifndef VERILATOR
    #1;
`endif
    UUT.u_ir.araddr = 32'b00000000000000000000000000000000;
    UUT.u_ir.arburst = 2'b00;
    UUT.u_ir.arid = 4'b0000;
    UUT.u_ir.arlen = 8'b00000000;
    UUT.u_ir.arsize = 3'b000;
    UUT.u_ir.arvalid = 1'b0;
    UUT.u_ir.current_state = 3'b000;
    UUT.u_ir.fin_ar = 1'b0;
    UUT.u_ir.fin_r = 1'b0;
    UUT.u_ir.inst = 32'b00000000000000000000000000000000;
    UUT.u_ir.inst_fin = 1'b1;
    UUT.u_ir.rready = 1'b0;
    UUT.u_memory.arready = 1'b0;
    UUT.u_memory.\mem[0]  = 32'b10000000000000000000000000000000;
    UUT.u_memory.\mem[10]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[11]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[12]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[13]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[14]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[15]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[16]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[17]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[18]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[19]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[1]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[20]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[21]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[22]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[23]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[24]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[25]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[26]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[27]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[28]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[29]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[2]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[30]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[31]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[3]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[4]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[5]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[6]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[7]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[8]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.\mem[9]  = 32'b00000000000000000000000000000000;
    UUT.u_memory.paddr = 32'b00000000000000000000000000000000;
    UUT.u_memory.r_en = 1'b0;
    UUT.u_memory.rdata = 32'b00000000000000000000000000000000;
    UUT.u_memory.rid = 4'b0000;
    UUT.u_memory.rlast = 1'b0;
    UUT.u_memory.rresp = 2'b00;
    UUT.u_memory.rvalid = 1'b0;
    UUT.u_ir.cache_data[4'b0000] = 32'b00000000000000000000000000000000;
    UUT.u_ir.cache_tag[4'b0000] = 26'b00000000000000000000000000;
    UUT.u_ir.cache_valid[4'b0000] = 1'b0;

    // state 0
    PI_rid = 4'b0000;
    PI_addr = 32'b00000000000000000000000000000000;
    PI_rresp = 2'b00;
    PI_rvalid = 1'b0;
    PI_rst = 1'b0;
    PI_if_en = 1'b0;
    PI_rlast = 1'b0;
    PI_rdata = 32'b00000000000000000000000000000000;
    PI_arready = 1'b0;
  end
  always @(posedge clock) begin
    genclock <= cycle < 0;
    cycle <= cycle + 1;
  end
endmodule
