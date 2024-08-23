module top
    #(parameter NR_KEY=4, parameter KEY_LEN=2, parameter DATA_LEN=2)
(
    input rst,
    input clk,
    input [7:0] x,
    input [1:0] y,
    output [1:0] f
);

    reg [31:0] cnt = 32'b0;
    reg [1:0]f_reg;


    mux41d #(.NR_KEY(NR_KEY), .KEY_LEN(KEY_LEN), .DATA_LEN(DATA_LEN)) u_mux41d (x, y, f_reg);

    always @(posedge clk) begin
        if(!rst) begin
            cnt <= 32'b0;
        end
        else if(cnt == 32'b11111111) begin
            cnt <=  32'b0;
            f <= ~f;
        end
        else begin
            cnt <= cnt + 1'b1;
        end
    end


    assign f = f_reg;

endmodule

module mux41d
    #(parameter NR_KEY=4, parameter KEY_LEN=2, parameter DATA_LEN=2)
(
    input [7:0] x,
    input [1:0] y,
    output [1:0] f
);
    
    // MuxKey #(4, 2, 2) u_MuxKey (f, y, {
    //     2'b00. x{1,0},
    //     2'b01, x{3,2},
    //     2'b10, x{5,4},
    //     2'b11, x{7,6}
    // });

    MuxKey 
        #(.NR_KEY(NR_KEY), .KEY_LEN(KEY_LEN), .DATA_LEN(DATA_LEN)) u_MuxKey (.out(f), .key(y), .lut({
            2'b00, x[1:0],
            2'b01, x[3:2],
            2'b10, x[5:4],
            2'b11, x[7:6]
            
        }));
endmodule

// module mux41b
//     #(parameter NR_KEY=4, parameter KEY_LEN=2, parameter DATA_LEN=1)
// (
//     input [3:0] x,
//     input [1:0] y,
//     output  f
// );
//     
//     // MuxKey #(4, 2, 2) u_MuxKey (f, y, {
//     //     2'b00. x{1,0},
//     //     2'b01, x{3,2},
//     //     2'b10, x{5,4},
//     //     2'b11, x{7,6}
//     // });
// 
//     MuxKey 
//         #(.NR_KEY(NR_KEY), .KEY_LEN(KEY_LEN), .DATA_LEN(DATA_LEN)) u_MuxKey (.out(f), .key(y), .lut({
//             2'b00, x[0],
//             2'b01, x[1],
//             2'b10, x[2],
//             2'b11, x[3]
//           }));
// endmodule


