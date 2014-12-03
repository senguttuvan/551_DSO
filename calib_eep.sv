module calib_eep(raw,off,gain,corrected);
input [7:0]raw,gain;                          //inputs
input signed [7:0]off;
wire [15:0]correc,check;                       //for calculation of product of (gain*(raw+offset))
output [7:0]corrected;                    //outputs
 

wire [1:0]of;                                   //for checking if there is an overflow
wire [7:0]sum,sums;                                  //variable for calculating raw+offset
 
assign sum=raw+off;
assign of=((~raw[7])&(~off[7])&sum[7])?2'b01:                    //if of=1 indicates +ve overflow if of=2 indicates -ve overflow else no overflow
          ((~raw[7]&off[7]&(sum[7]))?2'b10:2'b00);
 
assign sums=(of==2'b01)?8'hFF:                                    //according to overflow value assign sum as either FF or 00 or keep the same value 
           ((of==2'b10)?8'h00:sum);
 
assign check=sums*gain;
assign correc=(check > 16'h7FFF)?16'h7FFF:check;                        //check if the product is greater than 7FFF and if true saturate the product
 
assign corrected=correc>>7;                                          //right shift by 7 bits
           
endmodule
