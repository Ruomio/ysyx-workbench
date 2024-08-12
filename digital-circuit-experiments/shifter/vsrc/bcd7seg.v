module bcd7seg(
    input [3:0] b,
    output [6:0] h
);

    reg [6:0] h_reg = 7'b1111111;
    always @(b) begin
        case(b)
            4'b0000 : h_reg <= 7'b1000000;      // 0    
            4'b0001 : h_reg <= 7'b1111001;      // 1
            4'b0010 : h_reg <= 7'b0100100;      // 2
            4'b0011 : h_reg <= 7'b0110000;      // 3
            4'b0100 : h_reg <= 7'b0011001;      // 4
            4'b0101 : h_reg <= 7'b0010010;      // 5
            4'b0110 : h_reg <= 7'b0000010;      // 6
            4'b0111 : h_reg <= 7'b1111000;      // 7
            4'b1000 : h_reg <= 7'b0000000;      // 8
            4'b1001 : h_reg <= 7'b0010000;      // 9
            4'b1010 : h_reg <= 7'b0001000;      // a 
            4'b1011 : h_reg <= 7'b0000011;      // b
            4'b1100 : h_reg <= 7'b1000110;      // c
            4'b1101 : h_reg <= 7'b0100001;      // d
            4'b1110 : h_reg <= 7'b0000110;      // e
            4'b1111 : h_reg <= 7'b0001110;      // f
            default : h_reg <= 7'b1111111;
        endcase
    end

    assign h = h_reg;

endmodule
