//`timescale 1ns/10ps

/* AFE Gain test bench
 *
 * This test is written to improve the cumulative code coverage
 * Mainly tests the analog gain config values 
 *
 * Analog gain - 000 to 111  for any of the 3 channels
 * Gain - 0x80 for all 3 channels
 * Offset - 0x02 for all 3 channels
 *
 */

module DSO_dig_tb();
	
reg clk,rst_n;							// clock and reset are generated in TB

reg [23:0] cmd_snd;						// command Host is sending to DUT
reg send_cmd;
reg clr_resp_rdy;

wire adc_clk,MOSI,SCLK,trig_ss_n,ch1_ss_n,ch2_ss_n,ch3_ss_n,EEP_ss_n;
wire TX,RX;

wire [15:0] cmd_ch1,cmd_ch2,cmd_ch3;			// received commands to digital Pots that control channel gain
wire [15:0] cmd_trig;							// received command to digital Pot that controls trigger level
wire cmd_sent,resp_rdy;							// outputs from master UART
wire [7:0] resp_rcv;
wire [7:0] ch1_data,ch2_data,ch3_data;
wire trig1,trig2;

///////////////////////////
// Define command bytes //
/////////////////////////
localparam DUMP_CH  = 8'h01;		// Channel to dump specified in low 2-bits of second byte
localparam CFG_GAIN = 8'h02;		// Gain setting in bits [4:2], and channel in [1:0] of 2nd byte
localparam TRIG_LVL = 8'h03;		// Set trigger level, lower byte specifies value (46,201) is valid
localparam TRIG_POS = 8'h04;		// Set the trigger position. This is a 13-bit number, samples after capture
localparam SET_DEC  = 8'h05;		// Set decimator, lower nibble of 3rd byte. 2^this value is decimator
localparam TRIG_CFG = 8'h06;		// Write trig config.  2nd byte 00dettcc.  d=done, e=edge,
localparam TRIG_RD  = 8'h07;		// Read trig config register
localparam EEP_WRT  = 8'h08;		// Write calibration EEP, 2nd byte is address, 3rd byte is data
localparam EEP_RD   = 8'h09;		// Read calibration EEP, 2nd byte specifies address

//////////////////////
// Instantiate DUT //
////////////////////
DSO_dig iDUT(.clk(clk),.rst_n(rst_n),.adc_clk(adc_clk),.ch1_data(ch1_data),.ch2_data(ch2_data),
             .ch3_data(ch3_data),.trig1(trig1),.trig2(trig2),.MOSI(MOSI),.MISO(MISO),.SCLK(SCLK),
             .trig_ss_n(trig_ss_n),.ch1_ss_n(ch1_ss_n),.ch2_ss_n(ch2_ss_n),.ch3_ss_n(ch3_ss_n),
			 .EEP_ss_n(EEP_ss_n),.TX(TX),.RX(RX),.LED_n());
			   
///////////////////////////////////////////////
// Instantiate Analog Front End & A2D Model //
/////////////////////////////////////////////
AFE_A2D iAFE(.clk(clk),.rst_n(rst_n),.adc_clk(adc_clk),.ch1_ss_n(ch1_ss_n),.ch2_ss_n(ch2_ss_n),.ch3_ss_n(ch3_ss_n),
             .trig_ss_n(trig_ss_n),.MOSI(MOSI),.SCLK(SCLK),.trig1(trig1),.trig2(trig2),.ch1_data(ch1_data),
			 .ch2_data(ch2_data),.ch3_data(ch3_data));
			 
/////////////////////////////////////////////
// Instantiate UART Master (acts as host) //
///////////////////////////////////////////
UART_comm_mstr iMSTR(.clk(clk), .rst_n(rst_n), .RX(TX), .TX(RX), .cmd(cmd_snd), .send_cmd(send_cmd),
                     .cmd_sent(cmd_sent), .resp_rdy(resp_rdy), .resp(resp_rcv), .clr_resp_rdy(clr_resp_rdy));

/////////////////////////////////////
// Instantiate Calibration EEPROM //
///////////////////////////////////
SPI_EEP iEEP(.clk(clk),.rst_n(rst_n),.SS_n(EEP_ss_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO));
	


initial begin
  clk = 0;
  rst_n = 0;			// assert reset
  ///////////////////////////////
  // Your testing goes here!! //
  /////////////////////////////

rst_n = 0;																								//initial values
send_cmd = 0;
clr_resp_rdy = 0;

repeat(2) @(posedge clk);
@ (negedge clk);
rst_n =1;																									//deassert rst_n



////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////// ANALOG GAIN VARIATION ////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////
///////  Analog gain 000 channel 1  ////////
///////////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h020000;                                      //configure analog gain
repeat(10) @(posedge clk);
send_cmd = 0;


while (resp_rdy != 1'b1) begin 
@(posedge clk);
end

if (resp_rcv == 8'ha5) 
	$display("Command acknowledged !");
else
	$display("ALERT! command not acknowledged !");


if (  iAFE.POT1.iCHX_CFG.cmd_rcvd == 16'h1302 )
		$display("Set Analog gain(ch1) success ! The analog gain value : %h " , iAFE.POT1.iCHX_CFG.cmd_rcvd );
else
		$display("ALERT ! Set Analog gain(ch1) failed ! The analog gain value : %h " , iAFE.POT1.iCHX_CFG.cmd_rcvd );


clr_resp_rdy = 1;
////////////////////////////////////////////////
///////  Analog gain 001 of channel 2  ////////
//////////////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h020500; 
repeat(10) @(posedge clk);                                     //configure analog gain
send_cmd = 0;
clr_resp_rdy = 0;
repeat(20) @(posedge clk);


while (resp_rdy != 1'b1) begin 
@(posedge clk);
end

if (resp_rcv == 8'ha5) 
	$display("Command acknowledged !");
else
	$display("ALERT! command not acknowledged !");


if (  iAFE.POT2.iCHX_CFG.cmd_rcvd == 16'h1305 )
		$display("Set Analog gain(ch2) success ! The analog gain value : %h " , iAFE.POT2.iCHX_CFG.cmd_rcvd );
else
		$display("ALERT ! Set Analog gain(ch2) failed ! The analog gain value : %h " , iAFE.POT2.iCHX_CFG.cmd_rcvd );


clr_resp_rdy = 1;
////////////////////////////////////////////////
///////  Analog gain 010 of channel 3  ////////
//////////////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h020A00;                                      //configure analog gain
repeat(10) @(posedge clk);
send_cmd = 0;
clr_resp_rdy = 0;
repeat(20) @(posedge clk);


while (resp_rdy != 1'b1) begin 
@(posedge clk);
end

if (resp_rcv == 8'ha5) 
	$display("Command acknowledged !");
else
	$display("ALERT! command not acknowledged !");


if (  iAFE.POT3.iCHX_CFG.cmd_rcvd == 16'h1309 )
		$display("Set Analog gain(ch3) success ! The analog gain value : %h " , iAFE.POT3.iCHX_CFG.cmd_rcvd );
else
		$display("ALERT ! Set Analog gain(ch3) failed ! The analog gain value : %h " , iAFE.POT3.iCHX_CFG.cmd_rcvd );

clr_resp_rdy = 1;

///////////////////////////////////////////////
///////  Set gain of 100 to channel 2 ////////
/////////////////////////////////////////////


send_cmd = 1;                             
cmd_snd = 24'h021100;                                      //configure analog gain
repeat(10) @(posedge clk);
send_cmd = 0;
clr_resp_rdy = 0;
repeat(20) @(posedge clk);


while (resp_rdy != 1'b1) begin 
@(posedge clk);
end

if (resp_rcv == 8'ha5) 
	$display("Command acknowledged !");
else
	$display("ALERT! command not acknowledged !");


if (  iAFE.POT2.iCHX_CFG.cmd_rcvd == 16'h1328 )
		$display("Set Analog gain(ch2) success ! The analog gain value : %h " , iAFE.POT2.iCHX_CFG.cmd_rcvd );
else
		$display("ALERT ! Set Analog gain(ch2) failed ! The analog gain value : %h " , iAFE.POT2.iCHX_CFG.cmd_rcvd );


clr_resp_rdy = 1;

///////////////////////////////////////////////
///////  Set gain of 101 to channel 1 ////////
/////////////////////////////////////////////


send_cmd = 1;                             
cmd_snd = 24'h021400;                                      //configure analog gain
repeat(10) @(posedge clk);
send_cmd = 0;
clr_resp_rdy = 0;
repeat(20) @(posedge clk);


while (resp_rdy != 1'b1) begin 
@(posedge clk);
end

if (resp_rcv == 8'ha5) 
	$display("Command acknowledged !");
else
	$display("ALERT! command not acknowledged !");


if (  iAFE.POT1.iCHX_CFG.cmd_rcvd == 16'h1346 )
		$display("Set Analog gain(ch1) success ! The analog gain value : %h " , iAFE.POT1.iCHX_CFG.cmd_rcvd );
else
		$display("ALERT ! Set Analog gain(ch1) failed ! The analog gain value : %h " , iAFE.POT1.iCHX_CFG.cmd_rcvd );


clr_resp_rdy = 1;


///////////////////////////////////////////////
///////  Set gain of 111 to channel 3 ////////
/////////////////////////////////////////////


send_cmd = 1;                             
cmd_snd = 24'h021E00;                                      //configure analog gain
repeat(10) @(posedge clk);
send_cmd = 0;
clr_resp_rdy = 0;
repeat(20) @(posedge clk);


while (resp_rdy != 1'b1) begin 
@(posedge clk);
end

if (resp_rcv == 8'ha5) 
	$display("Command acknowledged !");
else
	$display("ALERT! command not acknowledged !");


if (  iAFE.POT3.iCHX_CFG.cmd_rcvd == 16'h13DD )
		$display("Set Analog gain(ch3) success ! The analog gain value : %h " , iAFE.POT3.iCHX_CFG.cmd_rcvd );
else
		$display("ALERT ! Set Analog gain(ch3) failed ! The analog gain value : %h " , iAFE.POT3.iCHX_CFG.cmd_rcvd );


clr_resp_rdy = 1;

#400;
$stop;

end

always
  #1 clk = ~clk;
			 

endmodule
			 
			 