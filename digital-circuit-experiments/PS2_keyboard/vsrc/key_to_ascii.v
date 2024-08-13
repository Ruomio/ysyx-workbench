module key_to_ascii(
    input [7:0] key,
    output reg [7:0] ascii
);


    always @(*) begin
        case(key)
            8'h45: ascii = 8'h30;    // 0-9
            8'h16: ascii = 8'h31;   
            8'h1e: ascii = 8'h32;
            8'h26: ascii = 8'h33;
            8'h25: ascii = 8'h34;
            8'h2e: ascii = 8'h35;
            8'h36: ascii = 8'h36;
            8'h3d: ascii = 8'h37;
            8'h3e: ascii = 8'h38;
            8'h46: ascii = 8'h39;

            8'h1c: ascii = 8'h61;    // a-z
            8'h32: ascii = 8'h62;
            8'h21: ascii = 8'h63;
            8'h23: ascii = 8'h64;
            8'h24: ascii = 8'h65;
            8'h2b: ascii = 8'h66;
            8'h34: ascii = 8'h67;
            8'h33: ascii = 8'h68;
            8'h43: ascii = 8'h69;
            8'h3b: ascii = 8'h6a;
            8'h42: ascii = 8'h6b;    // k
            8'h4b: ascii = 8'h6c;
            8'h3a: ascii = 8'h6d;
            8'h31: ascii = 8'h6e;
            8'h44: ascii = 8'h6f;
            8'h4d: ascii = 8'h70;
            8'h15: ascii = 8'h71;
            8'h2d: ascii = 8'h72;
            8'h1b: ascii = 8'h73;
            8'h2c: ascii = 8'h74;
            8'h3c: ascii = 8'h75;
            8'h2a: ascii = 8'h76;
            8'h1d: ascii = 8'h77;
            8'h22: ascii = 8'h78;
            8'h35: ascii = 8'h79;
            8'h1a: ascii = 8'h7a;

            default: ascii = 8'h00;
        endcase
    end


endmodule
