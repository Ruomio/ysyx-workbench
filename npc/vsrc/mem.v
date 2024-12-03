`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_MEM(
    input clk,
    input rst,
    input [`ysyx_24080020_WIDTH-1:0] pc,
    input [3:0] pc_len,

    input is_mr_signed,
    input [3:0] mrlen,
    input [3:0] mwlen,
    input [`ysyx_24080020_WIDTH-1:0] mraddr,
    input [`ysyx_24080020_WIDTH-1:0] mwaddr,
    input [`ysyx_24080020_WIDTH-1:0] mwdata,
    input mwen,
    output reg [`ysyx_24080020_WIDTH-1:0] mrdata,
    output reg [`ysyx_24080020_WIDTH-1:0] inst

);
    import "DPI-C" function void write_memory(input int addr, input int len, input int data);
    import "DPI-C" function int read_memory(input int addr, input int len);

    reg [`ysyx_24080020_WIDTH-1:0] last_pc;
    reg [`ysyx_24080020_WIDTH-1:0] last_raddr;

    reg [`ysyx_24080020_WIDTH-1:0] mrdata_tmp;
   

    // read mrdata
    always @(mraddr or mrlen or rst) begin
        if(!rst) begin
            mrdata <= 32'b0;
        end
        else if(mraddr != 32'b0) begin
            mrdata_tmp = read_memory(mraddr, {{28{1'b0}}, mrlen});

            if(!is_mr_signed) begin
                mrdata = mrdata_tmp;
            end
            else begin
                // signed extension
                case(mrlen)
                    4'b1: begin
                        mrdata = {{24{mrdata_tmp[7]}}, mrdata_tmp[7:0]};
                    end
                    4'b10: begin
                        mrdata = {{16{mrdata_tmp[15]}}, mrdata_tmp[15:0]};
                    end
                    default: begin
                        mrdata = mrdata_tmp;
                    end
                endcase
            end
        end
        else begin
            mrdata = mrdata_tmp;
        end

    end

    // read inst
    always @(pc or pc_len or rst) begin
        if(!rst) begin
            inst <= 32'b0;
            last_pc <= 32'b0;
        end
        else if(pc != last_pc) begin
            inst <= read_memory(pc, {{28{1'b0}}, pc_len});
            last_pc <= pc;
        end
        else begin
            inst <= inst;
        end

    end

    // write
    always @(posedge clk) begin
        if(!rst) begin
        end
        else if(mwen) begin
            write_memory(mwaddr, {{28{1'b0}},mwlen}, mwdata);
        end

    end


endmodule