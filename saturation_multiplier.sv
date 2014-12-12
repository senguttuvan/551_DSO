module saturation_multiplier(sums,gain,corrected);
input [7:0] sums;
input [7:0] gain;                          //inputs

wire [15:0]correc,check;                       //for calculation of product of (gain*(raw+offset))
output [7:0]corrected;                    //outputs
 

 
assign check=sums*gain;
assign correc=(check > 16'h7FFF)?16'h7FFF:check;                        //check if the product is greater than 7FFF and if true saturate the product
 
assign corrected=correc>>7;                                          //right shift by 7 bits
           
endmodule
