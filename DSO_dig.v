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
 reg [2:0] enable;
 wire [2:0] ss;
 wire cmd_rdy,SPI_done,send_resp,resp_sent;
 wire [23:0] cmd;
 wire [15:0] SPI_data,data_in;
 wire [7:0] resp_data;
 reg  [7:0] EEP_data;
 wire [8:0] addr;
 wire [7:0] ch1_rdata,ch2_rdata,ch3_rdata;
 

  /////////////////////////////
  // Instantiate SPI master //
  ///////////////////////////
 
  SPI_mstr iSpi_mstr(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),.wrt(wrt_SPI),.done(SPI_done),.data_out(SPI_data),.MOSI(MOSI),.MISO(MISO),.data_in(data_in));

  ///////////////////////////////////////////////////////////////
  // You have a SPI master peripheral with a single SS output //
  // you might have to do something creative to generate the //
  // 5 individual SS needed (3 AFE, 1 Trigger, 1 EEP)       //
  ///////////////////////////////////////////////////////////

////////////////////////////////////////////////////
///////EEP_data////////////////////////////////////
  always @(posedge clk, negedge rst_n)
 	if (!rst_n)
		EEP_data <= 0;
	else if(SPI_done & EEP_ss_n)
		EEP_data <= data_in[7:0];


//////////////////////////////////////////////////////////////////////
//////////////////decoder logic for slave select/////////////////////
///////////////////////////////////////////////////////////////////////
 always @(ss,SS_n)
 begin

	EEP_ss_n = 1;
	ch3_ss_n = 1;
	ch2_ss_n = 1;
	ch1_ss_n = 1;
	trig_ss_n = 1;

	case (ss)
	   
   	3'b000 : 	trig_ss_n = SS_n;                        
	   
		3'b001 :	ch1_ss_n = SS_n;

		3'b010 :	ch2_ss_n = SS_n;

		3'b011 :	ch3_ss_n = SS_n;

		3'b100 : 	EEP_ss_n = SS_n;
	
		default : begin
			EEP_ss_n = 1;
			ch3_ss_n = 1;
			ch2_ss_n = 1;
			ch1_ss_n = 1;
			trig_ss_n = 1;
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

	dig_core idcore(.clk(clk),.rst_n(rst_n),.adc_clk(adc_clk),.trig1(trig1),.trig2(trig2),.SPI_data(SPI_data),.wrt_SPI(wrt_SPI),.SPI_done(SPI_done),.ss(ss),.EEP_data(EEP_data),
              .rclk(rclk),.en(en),.we(we),.addr(addr),.ch1_rdata(ch1_rdata),.ch2_rdata(ch2_rdata),.ch3_rdata(ch3_rdata),.cmd(cmd),.cmd_rdy(cmd_rdy),.clr_cmd_rdy(clr_cmd_rdy),
							.resp_data(resp_data),.send_resp(send_resp),.resp_sent(resp_sent));

  //////////////////////////////////////////////////////////////
  // Instantiate the 3 512 RAM blocks that store A2D samples //
  ////////////////////////////////////////////////////////////
  RAM512 iRAM1(.rclk(rclk),.en(en),.we(we),.addr(addr),.wdata(ch1_data),.rdata(ch1_rdata));
  RAM512 iRAM2(.rclk(rclk),.en(en),.we(we),.addr(addr),.wdata(ch2_data),.rdata(ch2_rdata));
  RAM512 iRAM3(.rclk(rclk),.en(en),.we(we),.addr(addr),.wdata(ch3_data),.rdata(ch3_rdata));

endmodule

