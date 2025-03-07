module ps2_keyboard(clk,clrn,ps2_clk,ps2_data,data,
                    ready,nextdata_n,overflow);
    input clk,clrn,ps2_clk,ps2_data;
    input nextdata_n;
    output [7:0] data;
    output reg ready;
    output reg overflow;     // fifo overflow
    // internal signal, for test
    reg [9:0] buffer;        // ps2_data bits
    reg [7:0] fifo[7:0];     // data fifo
    reg [2:0] w_ptr,r_ptr;   // fifo write and read pointers
    reg [3:0] count;  // count ps2_data bits
    // detect falling edge of ps2_clk
    reg [2:0] ps2_clk_sync;

    always @(posedge clk) begin
        ps2_clk_sync <=  {ps2_clk_sync[1:0],ps2_clk};
    end

    wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];

    always @(posedge clk) begin
        if (clrn == 0) begin // reset
            count <= 0; w_ptr <= 0; r_ptr <= 0; overflow <= 0; ready<= 0;
        end
        else begin
            if ( ready ) begin // read to output next data
                if(nextdata_n == 1'b0) //read next data
                begin
                    r_ptr <= r_ptr + 3'b1;
                    if(w_ptr==(r_ptr+1'b1)) //empty
                        ready <= 1'b0;
                end
            end
            if (sampling) begin
              if (count == 4'd10) begin
                if ((buffer[0] == 0) &&  // start bit
                    (ps2_data)       &&  // stop bit
                    (^buffer[9:1])) begin      // odd  parity
                    fifo[w_ptr] <= buffer[8:1];  // kbd scan code
                    w_ptr <= w_ptr+3'b1;
                    ready <= 1'b1;
                    overflow <= overflow | (r_ptr == (w_ptr + 3'b1));
                end
                count <= 0;     // for next
              end else begin
                buffer[count] <= ps2_data;  // store ps2_data
                count <= count + 3'b1;
              end
            end
        end
    end
    assign data = fifo[r_ptr]; //always set output data

endmodule
// module ps2_keyboard(
//     input clk, clrn, ps2_clk, ps2_data,
//     input nextdata_n,
//     output reg [7:0] data,
//     output reg ready,
//     output reg overflow
// );
// 
//     reg [9:0] buffer;
//     reg [7:0] fifo[7:0];
//     reg [2:0] w_ptr, r_ptr;
//     reg [3:0] count;
//     reg [2:0] ps2_clk_sync;
// 
// 
//     always @(posedge clk) begin
//         ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
//     end
// 
// 
//     wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];
// 
//     always @(posedge clk) begin
//         if(clrn ==0 ) begin
//             count <= 0;
//             w_ptr <= 0;
//             r_ptr <= 0;
//             overflow <= 0;
//             ready <= 0;
//         end
//         else begin
//             if( ready ) begin
//                 if(nextdata_n == 1'b0) begin
//                     r_ptr <= r_ptr + 1'b1;
//                     if(r_ptr + 1'b1 == w_ptr) begin
//                         ready <= 1'b0;
//                     end
//                 end
//             end
// 
//             if(sampling) begin
//                 if(count == 4'b1010) begin
//                     if((buffer[0] == 0) && ps2_data && (^buffer[9:1])) begin
//                         fifo[w_ptr] <= buffer[8:1];
//                         w_ptr <= w_ptr + 3'b1;
//                         ready <= 1'b1;
//                         overflow <= (r_ptr == w_ptr + 3'b1);
// 
//                     end
//                 count <= 4'b0;
//                 end
//                 else begin 
//                     buffer[count] <= ps2_data;
//                     count <= count + 4'b1;
//                 end
//             end
//         end
//     end
// 
//     assign data = fifo[r_ptr];
// 
// endmodule


// module ps2_model(
//     input [7:0] code,
//     output reg ps2_clk,
//     output reg ps2_data
// );
//     parameter [7:0] clk_period = 60;
// 
//     reg [3:0] i;
//     reg [7:0] wait_time;
//     reg [10:0] buffer;
// 
//     always @(code) begin
//         buffer[0] = 1'b0;
//         buffer[8:1] = code;
//         buffer[9] = ~(^code);
//         buffer[10] = 1'b1;
// 
//         for(i = 4'd0; i<4'd11; i = i+1 ) begin
//             ps2_data = buffer[i];
//             wait_time = clk_period/2;
//             while(wait_time > 0) wait_time = wait_time - 8'b1;
//             ps2_clk = 1'b0;
//             wait_time = clk_period/2;
//             while(wait_time > 0) wait_time = wait_time - 8'b1;
//             ps2_clk = 1'b1;
// 
//         end
// 
//     end
// 
// endmodule
