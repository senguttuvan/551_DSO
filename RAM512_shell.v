module RAM512(rclk,en,we,addr,wdata,rdata);

  input rclk;		// clock (1/2 of system clock, 20MHz)
  input en;			// Active high for reads or writes to occur
  input we;			// Has to be high in addition to en for writes
  input [8:0] addr;	// address for 1 of 512 locations
  input [7:0] wdata;	// data to be written, writes occur on clock high
  output reg [7:0] rdata;	// read data, read occurs on clock high

endmodule
	  
