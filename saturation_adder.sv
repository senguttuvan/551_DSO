module saturation_adder(raw,off,sums);
input [7:0]raw;
input signed [7:0]off;
output [7:0]sums;                                  //variable for calculating raw+offset

wire [1:0]of;                                   //for checking if there is an overflow
wire [8:0]sum;
assign pos_off = (~off + 1);
assign sum= off[7] ? (raw - pos_off) : (raw + off);

assign of=(raw[7] & (~off[7]) & sum[8]) ? 2'b01:                    //if of=1 indicates +ve overflow if of=2 indicates -ve overflow else no overflow
          (~raw[7] & off[7] & sum[7]) ? 2'b10 : 2'b00;
 
assign sums=(of==2'b01)?8'hFF:                                    //according to overflow value assign sum as either FF or 00 or keep the same value 
           ((of==2'b10)?8'h00:sum);

endmodule
