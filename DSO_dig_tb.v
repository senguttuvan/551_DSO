//`timescale 1ns/10ps
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

repeat(2) @(posedge clk);
@ (negedge clk);
rst_n =1;																									//deassert rst_n


////////////////////////////////////////////
///////  Analog gain of channel  //////////
//////////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h020C00;                                      //configure analog gain
#20;
send_cmd = 0;
#500;

while ( iAFE.POT1.iCHX_CFG.cmd_rcvd != 16'h1314) begin 
@(posedge clk);
end

if ( iAFE.POT1.iCHX_CFG.cmd_rcvd == 16'h1314)
			$display("Analog gain cfg success");

///////////////////////////////////////
///////  Set trigger level  //////////
/////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h030C81;                                      //set trigger level as 0x81
#20;
send_cmd = 0;
#500;

repeat (1500) begin 
		@(posedge clk);
end

////////////////////////////////////
////  Writing trig pos register ///
//////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h0401FF;                                      //set trig pos = 512
#20;
send_cmd = 0;
#500;

repeat (1500) begin 
		@(posedge clk);
end

////////////////////////////////////
////  Writing decimator register //
//////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h050104;                                      //set decimator = 4
#20;
send_cmd = 0;
#500;

repeat (1500) begin 
		@(posedge clk);
end

///////////////////////////////
////  Writing trig cfg   /////
/////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h060400;                                      //command to write trig_cfg
#20;
send_cmd = 0;
#500;

repeat (1500) begin 
		@(posedge clk);
end

/////////////////////////////////////////////////////////////
/////////////////////////Read trig cfg//////////////////////
///////////////////////////////////////////////////////////
cmd_snd = 24'h070000;                               			 //command to read trig_cfg
send_cmd = 1;
#20;
send_cmd = 0;
#500;

repeat (3000) begin 
		@(posedge clk);
end


//////////////////////////////////////////////////////
///////  Waiting so that trig_cfg is sent  //////////
////////////////////////////////////////////////////

repeat (500) begin
		#5;
end

if (resp_rcv == 8'h04)
	$display("Read trig cfg success");

///////////////////////////
////  Write EEPROM   /////
/////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h080680;                                      //command to write eeprom
#20;
send_cmd = 0;
#500;

repeat (1500) begin 
		@(posedge clk);
end

///////////////////////////
////  Write EEPROM   /////
/////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h080702;                                      //command to write eeprom
#20;
send_cmd = 0;
#500;

repeat (1500) begin 
		@(posedge clk);
end

//////////////////////////
////  Read EEPROM   /////
////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h090600;                                      //command to read eeprom
#20;
send_cmd = 0;
#500;

repeat (3000) begin 
		@(posedge clk);
end



if (resp_rcv == 8'h80)
	$display("Read EEPROM success");


while (resp_rcv != 8'h24) begin 

// Read trig cfg

	cmd_snd = 24'h070000;                               			 //command to read trig_cfg
	send_cmd = 1;
	#20;
	send_cmd = 0;
	#500;
	
	repeat (3500) begin 
			@(posedge clk);
	end

	if (resp_rcv == 8'h24) begin
		$display("Capture done ! trig cfg : %b", resp_rcv);
	end
		
end

$display("Read trig cfg : %b", resp_rcv);

//////////////////
////  Dump  /////
////////////////
send_cmd = 1;                             
cmd_snd = 24'h010000;                                      //command to read eeprom
#20;
send_cmd = 0;
#500;

repeat (14000) begin 
		@(posedge clk);
end


/*
genvar i;

for (i = 0; i < 3;i++)
begin

end
*/



/*
/////////////////////////////////////////////////////////////////////
////////////////// Check for negative ACK  /////////////////////////
///////////////////////////////////////////////////////////////////
cmd_snd = 24'hAA0000;                             //command for NACK
send_cmd = 1;
#20;
send_cmd = 0;
#500;

repeat (500) begin 
		#10;
end
*/

#400;
$stop;

/*
/////////////////////////////////////////0////////////////////
/////////////////////Dump command///////////////////////////
///////////////////////////////////////////////////////////

cmd_snd=24'h010111;                                //command for dump channel
send_cmd=1;
repeat(2) @(posedge clk);
send_cmd=0;




$stop;
/*
send_cmd = 1;
cmd_snd = 24'h070000;
#20;
send_cmd = 0;

@(cmd_sent);
$stop;
@(resp_rdy);
	$strobe ("%h", resp_rcv); 
*/

/*
tx_data = 8'h07;
trmt = 1;
repeat(20) @ (posedge clk);
trmt =0;
repeat(600)@(posedge clk);
$display("%g byte 1 done" , $time);

@(negedge clk) trmt = 1;
tx_data = 8'h14;
repeat(20) @ (posedge clk);
trmt =0;
repeat(600)@(posedge clk);
$display("%g byte 2 done" , $time);

@(negedge clk) trmt = 1;
tx_data = 8'h00;
repeat(20) @ (posedge clk);
trmt =0;
repeat(600)@(posedge clk);
$display("%g byte 3 done" , $time);
repeat(1000)@(posedge clk);


$display("dataaa : %h", DUT.tx_data);

/*
$display("%g Write offset to EEPROM done" , $time);

@(negedge clk) trmt = 1;
tx_data = 8'h09;
repeat(20) @ (posedge clk);
trmt =0;
repeat(600)@(posedge clk);

@(negedge clk) trmt = 1;
tx_data = 8'h03;
repeat(20) @ (posedge clk);
trmt =0;
repeat(600)@(posedge clk);

@(negedge clk) trmt = 1;
tx_data = 8'h01;
repeat(20) @ (posedge clk);
trmt =0;



@(posedge iDUT.SPI_done);
@(posedge iDUT.SPI_done);
*/

end

always
  #1 clk = ~clk;
			 
initial begin
 $monitor("%g cmd_rdy:%d cmd:%h iDUT_response:%h EEPROM done , data : %h : resp : %h read_address: %h", $time , iDUT.cmd_rdy , iDUT.cmd, iDUT.resp_data , iDUT.EEP_data, resp_rcv, iDUT.idcore.icmd.addr);
//$monitor(" ch1 ss_n : %h,  ch2 ss_n : %h CHECKING ANALOG GAIN: %h ", ch1_ss_n, ch2_ss_n, iAFE.POT1.cmd );
//$monitor(" trig ss_n : %h, ch2 ss_n : %h CHECKING SET TRIGGER: %h ", trig_ss_n, ch2_ss_n, iAFE.POT4.cmd );
//$monitor(" CHECKING TRIGGER POS: %h ", iDUT.idcore.trig_pos );
//$monitor(" CHECKING DECIMATOR REG: %h ", iDUT.idcore.decimator_reg );
//$monitor(" CHECKING WRITE CONFIG: %h ", iDUT.idcore.trig_cfg );
//$monitor(" CHECKING WRITE EEPROM: %h ", iEEP.mem[7] );
end


endmodule
			 
			 