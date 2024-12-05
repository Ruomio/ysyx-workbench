`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_IR(
    input clk,
    input rst,
    input if_en,
    input [`ysyx_24080020_WIDTH-1:0] addr,

    output reg [`ysyx_24080020_WIDTH-1:0] inst,
    output reg inst_fin

);
    // import "DPI-C" function int read_memory(input int addr, input int len);

    wire rvalid, awready, wready, bvalid;
    wire [1:0] rresp, bresp;
    wire [5:0] lfsr;
    wire [`ysyx_24080020_WIDTH-1:0] rdata;
    
    
    reg arvalid, arready, rready;

    assign lfsr = 6'b1;


    // always @(posedge clk) begin
    //     if(!rst) begin
    //         inst <= 32'b0;
    //     end
    //     else if(if_en) begin
    //         inst <= read_memory(addr, 32'b100);
    //         inst_fin <= 1'b1;
    //     end
    //     else begin
    //         inst <= inst;
    //         inst_fin <= 1'b0;
    //     end
    // end

    always @(posedge clk) begin
        if(!rst) begin
            arvalid <= 1'b0;
        end
        else if(if_en) begin
            arvalid <= 1'b1;
        end
        else if(arready && arvalid) begin
            arvalid <= 1'b0;
        end
        else begin
            arvalid <= arvalid;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            rready <= 1'b0;
        end
        else if(rvalid && rresp == 2'b0) begin
            rready <= 1'b1;

            inst <= rdata;
            inst_fin <= 1'b1;
        end
        else begin
            rready <= rready;

            inst <= inst;
            inst_fin <= 1'b0;
        end
    end

    ysyx_24080020_SRAM u_ir_sram(
        .clk(clk),
        .rst(rst),

        .lfsr(lfsr),
        // axi-lite
        .araddr(addr),
        .arvalid(arvalid),
        .arready(arready),

        .rready(rready),
        .rdata(rdata),
        .rresp(rresp),
        .rvalid(rvalid),

        .awaddr(32'b0),
        .awvalid(1'b0),
        .awready(awready),

        .wdata(32'b0),
        .wstrb(4'b0),
        .wvalid(1'b0),
        .wready(wready),

        .bresp(bresp),
        .bvalid(bvalid),
        .bready(1'b0)
    );

endmodule