//`timescale 1ns/10ps
module DSO_dig(clk,rst_n,adc_clk,ch1_data,ch2_data,ch3_data,trig1,trig2,MOSI,MISO,
               SCLK,trig_ss_n,ch1_ss_n,ch2_ss_n,ch3_ss_n,EEP_ss_n,TX,RX,LED_n);
				
  input clk,rst_n;								// clock and active low reset
  output adc_clk;								// 20MHz clocks to ADC
  input [7:0] ch1_data,ch2_data,ch3_data;		// input data from ADC's
  input trig1,trig2;							// trigger inputs from AFE
  input MISO;									// Driven from SPI output of EEPROM chip
  output MOSI;									// SPI output to digital pots and EEPROM chip
  output SCLK;									// SPI clock (40MHz/16)
  output ch1_ss_n,ch2_ss_n,ch3_ss_n;			// SPI slave selects for configuring channel gains (active low)
  output trig_ss_n;								// SPI slave select for configuring trigger level
  output EEP_ss_n;								// Calibration EEPROM slave select
  output TX;									// UART TX to HOST
  input RX;										// UART RX from HOST
  output LED_n;									// control to active low LED
  
  ////////////////////////////////////////////////////
  // Define any wires needed for interconnect here //
  //////////////////////////////////////////////////

 reg	EEP_ss_n,	ch3_ss_n,	ch2_ss_n,	ch1_ss_n,	trig_ss_n ;
 wire en;
 reg enable;
 reg SSn;
 wire [2:0] ss;
 wire cmd_rdy,SPI_done,send_resp,resp_sent;
 wire [23:0] cmd;
 wire [15:0] SPI_data;
 wire [7:0] resp_data;
 
  /////////////////////////////
  // Instantiate SPI master //
  ///////////////////////////
 
  SPI_mstr iSpi_mstr(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),.wrt(wrt_SPI),.done(SPI_done),.data_out(SPI_data),.MOSI(MOSI),.MISO(MISO),.data_in(data_in));

  ///////////////////////////////////////////////////////////////
  // You have a SPI master peripheral with a single SS output //
  // you might have to do something creative to generate the //
  // 5 individual SS needed (3 AFE, 1 Trigger, 1 EEP)       //
  ///////////////////////////////////////////////////////////
 
 always @(posedge clk, negedge rst_n)
	if (!rst_n)
		enable <= 0;
	else if(wrt_SPI)
		enable <= ss[2:0];

 always @(posedge clk, negedge rst_n)
	if (!rst_n)
		SSn <= 1;
	else
		SSn <= SS_n;

 always @(enable,SSn)
 begin

	EEP_ss_n = 0;
	ch3_ss_n = 0;
	ch2_ss_n = 0;
	ch1_ss_n = 0;
	trig_ss_n = 0;

	case (enable)
	   
   		3'b000 : 	trig_ss_n = SSn; 
	   
		3'b001 :	 ch1_ss_n = SSn;

		3'b010 :	 ch2_ss_n = SSn;

		3'b011 :	 ch3_ss_n = SSn;

		3'b100 : 	EEP_ss_n = SSn;
	
		default : begin
			EEP_ss_n = 0;
			ch3_ss_n = 0;
			ch2_ss_n = 0;
			ch1_ss_n = 0;
			trig_ss_n = 0;
	  end
	endcase
 end

	///////////////////////////////////
  // Instantiate UART_comm module //
  /////////////////////////////////
			


	uart_comm_transceiver iuart(.clk(clk), .rst_n(rst_n), .tx_done(resp_sent), .cmd_rdy(cmd_rdy),
     .tx_data(resp_data), .cmd(cmd), .TX(TX), .RX(RX), .clr_cmd_rdy(clr_cmd_rdy),.trmt(send_resp) );

	    
  ///////////////////////////
  // Instantiate dig_core //
  /////////////////////////

	dig_core idcore(clk,rst_n,adc_clk,trig1,trig2,SPI_data,wrt_SPI,SPI_done,ss,EEP_data,
              rclk,en,we,addr,ch1_rdata,ch2_rdata,ch3_rdata,cmd,cmd_rdy,clr_cmd_rdy,
							resp_data,send_resp,resp_sent);

  //////////////////////////////////////////////////////////////
  // Instantiate the 3 512 RAM blocks that store A2D samples //
  ////////////////////////////////////////////////////////////
  RAM512 iRAM1(.rclk(rclk),.en(en),.we(we),.addr(addr),.wdata(ch1_data),.rdata(ch1_rdata));
  RAM512 iRAM2(.rclk(rclk),.en(en),.we(we),.addr(addr),.wdata(ch2_data),.rdata(ch2_rdata));
  RAM512 iRAM3(.rclk(rclk),.en(en),.we(we),.addr(addr),.wdata(ch3_data),.rdata(ch3_rdata));

endmodule
  

module DSO_digtb();

  reg clk,rst_n;								// clock and active low reset
  wire adc_clk;								// 20MHz clocks to ADC
  reg [7:0] ch1_data,ch2_data,ch3_data;		// reg data from ADC's
  reg trig1,trig2;							// trigger regs from AFE
  wire MISO;									// Driven from SPI wire of EEPROM chip
  wire MOSI;									// SPI wire to digital pots and EEPROM chip
  wire SCLK;									// SPI clock (40MHz/16)
  wire ch1_ss_n,ch2_ss_n,ch3_ss_n;			// SPI slave selects for configuring channel gains (active low)
  wire trig_ss_n;								// SPI slave select for configuring trigger level
  wire EEP_ss_n;								// Calibration EEPROM slave select
  wire TX;									// UART TX to HOST
  wire RX;										// UART RX from HOST
  wire LED_n;									// control to active low LED

	reg r;
	wire tx_done;
	
	reg trmt;
	reg [7:0] tx_data;
	
	
  reg slave_wrt;
  reg [15:0] slavetx_data;

	wire [15:0] cmd_rcvd;
	wire cmd_rdy;
	wire rsp_rdy;
	

DSO_dig icmd(clk,rst_n,adc_clk,ch1_data,ch2_data,ch3_data,trig1,trig2,MOSI,MISO,
               SCLK,trig_ss_n,ch1_ss_n,ch2_ss_n,ch3_ss_n,EEP_ss_n,TX,RX,LED_n);



uart_tx DUT(.TX(RX), .trmt(trmt), .tx_data(tx_data), .rst_n(rst_n), .clk(clk), .tx_done(tx_done));


SPI_slv islave(.clk(clk),.rst_n(rst_n),.tx_data(slavetx_data),.SCLK(SCLK),.MISO(MISO),.SS_n(ch1_ss_n),.MOSI(MOSI),.cmd_rcvd(cmd_rcvd),
								.cmd_rdy(cmd_rdy),.rsp_rdy(rsp_rdy));

initial begin
clk = 1;
forever #1 clk = ~clk;
end

initial begin
//RX = 8'h02;
//RX = 8'h1C;
//RX = 8'hEF;
rst_n = 0;
trmt = 0;

repeat(2) @(posedge clk);
@ (negedge clk);
rst_n =1;
tx_data = 8'h02;
trmt = 1;
slavetx_data = 16'h0001;

repeat(20) @ (posedge clk);
trmt =0;
repeat(600)@(posedge clk);
$display("%g byte 1 done" , $time);
@(negedge clk) trmt = 1;
tx_data = 8'h1C;
repeat(20) @ (posedge clk);
trmt =0;
repeat(600)@(posedge clk);
$display("%g byte 2 done" , $time);
@(negedge clk) trmt = 1;
tx_data = 8'hEF;
repeat(20) @ (posedge clk);
trmt =0;
repeat(600)@(posedge clk);
$display("%g byte 3 done" , $time);
repeat(1000)@(posedge clk);

$display("dataaa : %h", cmd_rcvd);

$stop;

end

initial
	$monitor("%g cmd_rdy:%d cmd:%h icmd_response:%h", $time , icmd.cmd_rdy ,icmd.cmd, icmd.resp_data);

endmodule