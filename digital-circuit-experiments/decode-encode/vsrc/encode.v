module encode42(
    input [3:0] x,
    input en,
    output reg [1:0] y
);

    always @(x or en) begin
        if(en) begin
            y <= 2'b0;
            for(integer i=0; i<4; i++) begin
                if(x[i] == 1) y <= i[1:0];
            end
        end
        else begin
            y <= 2'b0;
        end
    end


endmodule

module encode83(
    input [7:0] x,
    input en,
    output reg [2:0] y
);

    always @(x or en) begin
        if(en) begin
            y <= 3'b0;
            for(integer i=0; i<8; i++) begin
                if(x[i] == 1) y <= i[2:0];
            end
        end
        else begin
            y <= 3'b0;
        end
    end


endmodule
