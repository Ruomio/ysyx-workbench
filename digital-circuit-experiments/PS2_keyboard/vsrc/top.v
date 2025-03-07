module top(
    input clk, clrn,
    output ps2_clk, ps2_data,
    input nextdata_n,
    // input [7:0] code,
    output reg [7:0] data,
    output reg ready,
    output reg overflow,
    output reg [6:0] bcd0,
    output reg [6:0] bcd1,
    output reg [6:0] bcd2,
    output reg [6:0] bcd3,
    output reg [6:0] bcd4,
    output reg [6:0] bcd5,
    output reg [7:0] cnt

);

    // reg [7:0] code = 8'h15;
    // reg ps2_clk, ps2_data;

    // reg [7:0] key_code;
    reg [7:0] ascii_code;

    reg [7:0] last_data;


    // ps2_model u_ps2_model(code, ps2_clk, ps2_data);

    ps2_keyboard u_ps2_keyboard(.clk(clk), .clrn(clrn), .ps2_clk(ps2_clk), .ps2_data(ps2_data), .nextdata_n(nextdata_n), .data(data), .ready(ready), .overflow(overflow));

    key_to_ascii u_key_to_ascii(data, ascii_code);

    always@(data, clrn, nextdata_n) begin
        if(clrn == 0) begin
            last_data = 8'b0;
            cnt = 8'b0;
    end
        else if(nextdata_n && data != last_data && data != 8'hf0) begin
            cnt = cnt + 1;
            last_data = data;
        end
        else begin
            cnt = cnt;
            last_data = last_data;
        end
    end

    bcd7seg u_bcd7seg_1(data[3:0], bcd0);
    bcd7seg u_bcd7seg_2(data[7:4], bcd1);
    bcd7seg u_bcd7seg_3(ascii_code[3:0], bcd2);
    bcd7seg u_bcd7seg_4(ascii_code[7:4], bcd3);
    bcd7seg u_bcd7seg_5(cnt[3:0], bcd4);
    bcd7seg u_bcd7seg_6(cnt[7:4], bcd5);
    
    // reg [31:0] cnt = 32'b0;

    // always @(posedge clk or negedge clk) begin
    //     if(!rst) begin
    //         cnt <= 32'b0;
    //     end
    //     else begin
    //         if(cnt == 32'b1111_1111) begin
    //             cnt <=  32'b0;
    //             
    //         end
    //         else begin
    //             cnt <= cnt + 1'b1;
    //             
    //         end
    //     end
    // end
endmodule
