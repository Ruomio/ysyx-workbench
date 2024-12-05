`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_MEM(
    input clk,
    input rst,

    // memory
    input mren_exu,
    input mrtype_exu,
    input [3:0] mrlen_exu,
    input mwen_exu,
    input [3:0] mwmask_exu,
    input [`ysyx_24080020_WIDTH-1:0] mraddr_exu,
    input [`ysyx_24080020_WIDTH-1:0] mwaddr_exu,
    input [`ysyx_24080020_WIDTH-1:0] mwdata_exu,
    output reg [`ysyx_24080020_WIDTH-1:0] mrdata_mem,

    input [`ysyx_24080020_WIDTH-1:0] alu_out_exu,
    output reg [`ysyx_24080020_WIDTH-1:0] alu_out_mem,

    // csrs
    input wcsren_exu,
    input [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr_exu,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata_exu,
    input wcsren2_exu,
    input [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2_exu,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata2_exu,
    output reg wcsren_mem,
    output reg [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr_mem,
    output reg [`ysyx_24080020_WIDTH-1:0] wcsrdata_mem,
    output reg wcsren2_mem,
    output reg [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2_mem,
    output reg [`ysyx_24080020_WIDTH-1:0] wcsrdata2_mem,
    // regs
    input wen_exu,
    input [4:0] waddr_exu,
    output reg wen_mem,
    output reg [4:0] waddr_mem,

    input reg is_load_exu,
    output reg is_load_mem,

    input is_dnpc_exu,
    input [`ysyx_24080020_WIDTH-1:0] dnpc_new_exu,
    output reg is_dnpc_mem,
    output reg [`ysyx_24080020_WIDTH-1:0] dnpc_mem,

    // bus
    input exu_mem_valid,
    input wb_mem_ready,
    output reg mem_exu_ready,
    output reg mem_wb_valid

);
    import "DPI-C" function void write_memory(input int addr, input int len, input int data);
    import "DPI-C" function int read_memory(input int addr, input int len);

    reg mren_mem;
    reg mwen_mem;
    reg mrtype_mem;
    reg [3:0] mrlen_mem;
    reg [3:0] mwmask_mem;
    reg [`ysyx_24080020_WIDTH-1:0] mrdata_tmp;
    reg [`ysyx_24080020_WIDTH-1:0] mraddr_mem;
    reg [`ysyx_24080020_WIDTH-1:0] mwaddr_mem;
    reg [`ysyx_24080020_WIDTH-1:0] mwdata_mem;

    reg state; // 0: idle;   1: wait_ready


    // axi-lite
    wire [5:0] lfsr;
    reg arvalid;
    wire arready;
    wire [`ysyx_24080020_WIDTH-1:0] araddr;

    reg rready
    wire rvalid;
    wire [1:0] rresp;
    wire [`ysyx_24080020_WIDTH-1:0] rdata;

    reg awvalid;
    wire awready;
    wire [`ysyx_24080020_WIDTH-1:0] awaddr;

    reg wvalid;
    wire wready;
    wire [3:0] wstrb;
    wire [`ysyx_24080020_WIDTH-1:0] wdata; 

    reg bready;
    wire bvalid;
    wire [1:0] bresp;



    always @(posedge clk) begin
        if(!rst) begin
            state <= 1'b0;
        end
        else if(!state) begin
            if(mem_wb_valid) state <= 1'b1;
            else state <= 1'b0;
        end
        else begin
            if(wb_mem_ready) state <= 1'b0;
            else state <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if(exu_mem_valid) begin
            if(mem_wb_valid) mem_exu_ready <= 1'b0;
            else begin
                mem_exu_ready <= 1'b1;

                // update reg
                wen_mem <= wen_exu;
                waddr_mem <= waddr_exu;

                is_load_mem <= is_load_exu;
                is_dnpc_mem <= is_dnpc_exu;
                dnpc_mem <= dnpc_new_exu;

                mren_mem <= mren_exu;
                mrtype_mem <= mrtype_exu;
                mrlen_mem <= mrlen_exu;
                mraddr_mem <= mraddr_exu;
                mwen_mem <= mwen_exu;
                mwmask_mem <= mwmask_exu;
                mwaddr_mem <= mwaddr_exu;
                mwdata_mem <= mwdata_exu;

                alu_out_mem <= alu_out_exu;

                wcsren_mem <= wcsren_exu;
                wcsraddr_mem <= wcsraddr_exu;
                wcsrdata_mem <= wcsrdata_exu;
                wcsren2_mem <= wcsren2_exu;
                wcsraddr2_mem <= wcsraddr2_exu;
                wcsrdata2_mem <= wcsrdata2_exu;

                // mem_wb_valid <= 1'b1;
                if(!mwen_exu && !mren_exu) begin
                    mem_wb_valid <= 1'b1;
                end
            end
        end
        else if(wb_mem_ready && state) begin
            mem_wb_valid <= 1'b0;

        end
        else begin
            mem_exu_ready <= 1'b0;
        end

    end



    assign lfsr = 6'd2;
    assign araddr = mraddr_mem;
    
    always @(posedge clk) begin
        if(!rst) begin
            arvalid <= 1'b0;
        end
        else if(arvalid && arready) begin
            arvalid <= 1'b0;
        end
        else if(mren_mem) begin
            arvalid <= 1'b1;

            mren_mem <= 1'b0;
        end
        else begin
            arvalid <= arvalid;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            rready <= 1'b0;
            mrdata_mem <= 32'b0;
        end
        else if(rvalid) begin
            rready <= 1'b1;
            if(rresp == 2'b0) begin
                if(mrtype_mem) begin
                    // zero extension
                    case(mrlen_mem)
                        4'd1:   mrdata_mem <= {{24{1'b0}}, rdata[7:0]};
                        4'd2:   mrdata_mem <= {{16{1'b0}}, rdata[15:0]};
                        4'd4:   mrdata_mem <= rdata;
                        default: mrdata_mem <= 32'hffffffff;
                    endcase
                end
                else begin
                    // signed extension
                    case(mrlen_mem)
                        4'd1:   mrdata_mem <= {{24{rdata[7]}}, rdata[7:0]};
                        4'd2:   mrdata_mem <= {{16{rdata[15]}}, rdata[15:0]};
                        4'd4:   mrdata_mem <= rdata;
                        default: mrdata_mem <= 32'hffffffff;
                    endcase
                end
                
                mem_wb_valid <= 1'b1;
            end
            else begin
                // read error
                mrdata_mem <= 32'hffffffff;
            end
        end
        else begin
            rready <= 1'b0;
        end
    end

    assign awaddr = mwaddr_mem;
    always @(posedge clk) begin
        if(!rst) begin
            awvalid <= 1'b0;
        end
        else if(awvalid && awready) begin
            awvalid <= 1'b0;
            wvalid <= 1'b1;
        end
        else if(mwen_mem) begin
            awvalid <= 1'b1;

            mwen_mem <= 1'b0;
        end
        else begin
            awvalid <= awvalid;
        end
    end

    assign wdata = mwdata_mem;
    assign wstrb = mwmask_mem == 4'b1 ? 4'b1 :
                   mwmask_mem == 4'b10 ? 4'b11 :
                   mwmask_mem == 4'b100 ? 4'b1111 : 
                   4'b0;
    always @(posedge clk) begin
        if(!rst) begin
            wvalid <= 1'b0;
        end
        else if(wvalid && wready) begin
            wvalid <= 1'b0;
        end
        else begin
            wvalid <= wvalid;
        end
    end


    always @(posedge clk) begin
        if(!rst) begin
            bready <= 1'b0;
        end
        else if(bvalid) begin
            bready <= 1'b1;

            mem_wb_valid <= 1'b1;
            // bresp != 0 : error
        end
        else begin
            bready <= 1'b0;
        end
    end


    // axi-lite sram
    ysyx_24080020_SRAM u_mem_sram(
        .clk(clk),
        .rst(rst),
        .lfsr(lfsr),

        .arvalid(arvalid),
        .araddr(araddr),
        .arready(arready),

        .rready(rready),
        .rdata(rdata),
        .rresp(rresp),
        .rvalid(rvalid),

        .awaddr(awaddr),
        .awvalid(awvalid),
        .awready(awready),

        .wdata(wdata),
        .wstrb(wstrb),
        .wvalid(wvalid),
        .wready(wready),

        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready)
    );
   
    // always @(posedge clk) begin
    //     if(mren_mem) begin
    //         mrdata_tmp <= read_memory(mraddr_mem, {{28{1'b0}}, mrlen_mem});
    //     end
    //     else begin
    //         mrdata_tmp <= mrdata_tmp;
    //     end
    // end

    // // read mrdata
    // always @(posedge clk) begin
    //     if(!rst) begin
    //         mrdata_mem <= 32'b0;
    //     end
    //     else if(mraddr_mem != 32'b0 && mren_mem) begin
    //         if(mrtype_mem) begin
    //             // zero extension
    //             mrdata_mem <= mrdata_tmp;
    //         end
    //         else begin
    //             // signed extension
    //             case(mrlen_mem)
    //                 4'b0001: begin
    //                     mrdata_mem <= {{24{mrdata_tmp[7]}}, mrdata_tmp[7:0]};
    //                 end
    //                 4'b0010: begin
    //                     mrdata_mem <= {{16{mrdata_tmp[15]}}, mrdata_tmp[15:0]};
    //                 end
    //                 4'b0100: begin
    //                     mrdata_mem <= mrdata_tmp;
    //                 end
    //                 default: begin
    //                     mrdata_mem <= ~32'b0;
    //                 end
    //             endcase

    //         end
    //         mren_mem <= 1'b0;
    //         mem_wb_valid <= 1'b1;
    //     end
    //     else begin
    //         mrdata_mem <= mrdata_mem;
    //     end

    // end

    // reg cnt;
    // // write
    // always @(posedge clk) begin
    //     if(!rst) begin
    //         cnt <= 1'b0;
    //     end
    //     else if(mwen_mem) begin
    //         if(cnt) begin
    //             write_memory(mwaddr_mem, {{28{1'b0}},mwmask_mem}, mwdata_mem);
    //             // mem_wb_valid <= 1'b1;
    //             mwen_mem <= 1'b0;
    //             mem_wb_valid <= 1'b1;

    //             cnt <= 1'b0;
    //         end
    //         else cnt <= 1'b1;
    //     end

    // end




endmodule