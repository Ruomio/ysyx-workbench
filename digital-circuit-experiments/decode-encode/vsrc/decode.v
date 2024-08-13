module decode38
(
    input [2:0] x,
    input en,
    output reg [7:0] y
);


    always @(x or en) begin
        if(en) begin
            for(integer i=0; i<8; i=i+1) begin
                if(x == i)
                    y[i] = 1;
                else
                    y[i] = 0;
            end
        end
        else begin
            y = 8'b0;
        end
    end

endmodule
