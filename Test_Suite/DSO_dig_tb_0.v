//`timescale 1ns/10ps

/* This is my primary test_bench. It tests all the commands and if data inconsistency is present,
 * by checking the sum of channel2 and channel 3 data. The values used for the channels are -
 *
 * Trigger level - 0x81
 * Analog gain - 111 for all 3 channels
 * Gain - 0x80 for all 3 channels
 * Offset - 0x00 for all 3 channels
 *
 * Extra - Capture done test and Negative ACK test
 * 
 */

module DSO_dig_tb0();
	
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
	


///////////////////////////////////
// MY OWN VARIABLES FOR TESTING //
/////////////////////////////////

integer i = 0,i2 = 0,i3 = 0,fd,fd2,fd3;

reg [7:0] ch1_mem [0:511];
reg [7:0] ch2_mem [0:511];
reg [7:0] ch3_mem [0:511];

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



//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////// ANALOG GAIN COMMAND ////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////
///////  Analog gain of channel 1  ////////
//////////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h021C00;                                      // 111 configure analog gain
repeat(10) @(posedge clk);
send_cmd = 0;


while (resp_rdy != 1'b1) begin 
@(posedge clk);
end

if (resp_rcv == 8'ha5) 
	$display("Command acknowledged !");
else
	$display("ALERT! command not acknowledged !");


if (  iAFE.POT1.iCHX_CFG.cmd_rcvd == 16'h13DD )
		$display("Set Analog gain(ch1) success ! The analog gain value : %h " , iAFE.POT1.iCHX_CFG.cmd_rcvd );
else
		$display("ALERT ! Set Analog gain(ch1) failed ! The analog gain value : %h " , iAFE.POT1.iCHX_CFG.cmd_rcvd );


clr_resp_rdy = 1;
////////////////////////////////////////////
///////  Analog gain of channel 2  ////////
//////////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h021D00; 
repeat(10) @(posedge clk);                                     //111 configure analog gain
send_cmd = 0;
clr_resp_rdy = 0;

/*
 *  IMPORTANT : Be careful with this random delay (#70). After deasserting the clr_resp_rdy
 *	the resp_rdy == 1 (asserted for previous command) condition will be true for some time ,
 *  even before the new command has been completely transmitted
 */
 
repeat(20) @(posedge clk);


while (resp_rdy != 1'b1) begin 
@(posedge clk);
end

if (resp_rcv == 8'ha5) 
	$display("Command acknowledged !");
else
	$display("ALERT! command not acknowledged !");


if (  iAFE.POT2.iCHX_CFG.cmd_rcvd == 16'h13DD )
		$display("Set Analog gain(ch2) success ! The analog gain value : %h " , iAFE.POT2.iCHX_CFG.cmd_rcvd );
else
		$display("ALERT ! Set Analog gain(ch2) failed ! The analog gain value : %h " , iAFE.POT2.iCHX_CFG.cmd_rcvd );


clr_resp_rdy = 1;
////////////////////////////////////////////
///////  Analog gain of channel 3  ////////
//////////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h021E00;                                      //011 configure analog gain
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




//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////// SET TRIGGER COMMAND ////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////
///////  Set trigger level  //////////
/////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h030C81;                                      //set trigger level as 0x81
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

if (  iAFE.POT4.iCHX_CFG.cmd_rcvd == 16'h1381 )
		$display("Set trigger level success ! The trigger value : %h " , iAFE.POT4.iCHX_CFG.cmd_rcvd );
else
		$display("ALERT ! Set trigger level failed ! The trigger value  : %h " , iAFE.POT4.iCHX_CFG.cmd_rcvd );


clr_resp_rdy = 1;





//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////// SET TRIG POSITION COMMAND //////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////
////  Writing trig pos register ///
//////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h0401FF;                                      //set trig pos = 512
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

if (  iDUT.idcore.icmd.trig_pos == 9'h1FF )
		$display("Set trigger position success ! The trigger position : %h " , iDUT.idcore.icmd.trig_pos );
else
		$display("ALERT ! Set trigger position failed ! The trigger position : %h " , iDUT.idcore.icmd.trig_pos );


clr_resp_rdy = 1;




//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////// SET DECIMATOR COMMAND //////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////
////  Writing decimator register //
//////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h050100;                                      //set decimator = 4
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

if (  iDUT.idcore.icmd.decimator_reg == 4'h3 )
		$display("Set decimator register success ! The decimator register value : %h " , iDUT.idcore.icmd.decimator_reg );
else
		$display("ALERT ! Set decimator register failed ! The decimator register value : %h " , iDUT.idcore.icmd.decimator_reg );


clr_resp_rdy = 1;




//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////// SET TRIG CONFIG COMMAND ////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////
////  Writing trig cfg   /////
/////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h060400;                                      //command to write trig_cfg
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

if (  iDUT.idcore.icmd.trig_cfg == 8'h04 ||  iDUT.idcore.icmd.trig_cfg == 8'h24  )
		$display("Set trig config register success ! The trig config register value : %h " , iDUT.idcore.icmd.trig_cfg );
else
		$display("ALERT ! Set trig config register failed ! The trig config register value : %h " , iDUT.idcore.icmd.trig_cfg );


clr_resp_rdy = 1;


//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////// READ TRIG CONFIG COMMAND ///////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////
/////////////////////////Read trig cfg//////////////////////
///////////////////////////////////////////////////////////
cmd_snd = 24'h070000;                               			 //command to read trig_cfg
send_cmd = 1;
repeat(10) @(posedge clk);
send_cmd = 0;
repeat(20) @(posedge clk);
clr_resp_rdy = 0;

while (resp_rdy != 1'b1) begin 
@(posedge clk);
end

if (resp_rcv == 8'h04 || resp_rcv == 8'h24) begin     //We dont know if the capture done bit is set
		$display("Command acknowledged !");
		$display("Read trig config success ! Received trig config register value : %h ", resp_rcv );
end else begin
		$display("ALERT! command not acknowledged !");
		$display("ALERT ! Read trig config register failed ! The response received : %h " , resp_rcv );
end

clr_resp_rdy = 1;



//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////// WRITE EEPROM COMMAND ///////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////
////  Write EEPROM (channel1 - gain)  /////
//////////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h080E80;                                      //command to write eeprom
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

if (  iEEP.mem[8'h0E] == 8'h80 )
		$display("Write EEPROM(channel1 - gain)  success ! The EEPROM  value (addr:0E) : %h " , iEEP.mem[8'h0E] );
else
		$display("ALERT ! Write EEPROM(channel1 - gain) failed ! The EEPROM  value (addr:0E) : %h " , iEEP.mem[8'h0E] );

clr_resp_rdy = 1;
////////////////////////////////////////////
////  Write EEPROM (channel1 - offset)  ///
//////////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h080F00;                                      //command to write eeprom
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

if (  iEEP.mem[8'h0F] == 8'h00 )
		$display("Write EEPROM(channel1 - offset)  success ! The EEPROM  value (addr:0F) : %h " , iEEP.mem[8'h0F] );
else
		$display("ALERT ! Write EEPROM(channel1 - offset) failed ! The EEPROM  value (addr:0F) : %h " , iEEP.mem[8'h0F] );


clr_resp_rdy = 1;

////////////////////////////////////////////
////  Write EEPROM (channel2 - gain)  /////
//////////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h081E80;                                      //command to write eeprom
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

if (  iEEP.mem[8'h1E] == 8'h80 )
		$display("Write EEPROM(channel2 - gain)  success ! The EEPROM  value (addr:1E) : %h " , iEEP.mem[8'h1E] );
else
		$display("ALERT ! Write EEPROM(channel2 - gain) failed ! The EEPROM  value (addr:1E) : %h " , iEEP.mem[8'h1E] );

clr_resp_rdy = 1;
////////////////////////////////////////////
////  Write EEPROM (channel2 - offset)  ///
//////////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h081F00;                                      //command to write eeprom
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

if (  iEEP.mem[8'h1F] == 8'h00 )
		$display("Write EEPROM(channel2 - offset)  success ! The EEPROM  value (addr:1F) : %h " , iEEP.mem[8'h1F] );
else
		$display("ALERT ! Write EEPROM(channel2 - offset) failed ! The EEPROM  value (addr:1F) : %h " , iEEP.mem[8'h1F] );


clr_resp_rdy = 1;

////////////////////////////////////////////
////  Write EEPROM (channel3 - gain)  /////
//////////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h082E80;                                      //command to write eeprom
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

if (  iEEP.mem[8'h2E] == 8'h80 )
		$display("Write EEPROM(channel3 - gain)  success ! The EEPROM  value (addr:2E) : %h " , iEEP.mem[8'h2E] );
else
		$display("ALERT ! Write EEPROM(channel3 - gain) failed ! The EEPROM  value (addr:2E) : %h " , iEEP.mem[8'h2E] );

clr_resp_rdy = 1;
////////////////////////////////////////////
////  Write EEPROM (channel3 - offset)  ///
//////////////////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h082F00;                                      //command to write eeprom
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

if (  iEEP.mem[8'h2F] == 8'h00 )
		$display("Write EEPROM(channel3 - offset)  success ! The EEPROM  value (addr:2F) : %h " , iEEP.mem[8'h2F] );
else
		$display("ALERT ! Write EEPROM(channel3 - offset) failed ! The EEPROM  value (addr:2F) : %h " , iEEP.mem[8'h2F] );


clr_resp_rdy = 1;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////// READ EEPROM COMMAND ///////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////
////  Read EEPROM   /////
////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h092F00;                                      //command to read eeprom
repeat(10) @(posedge clk);
send_cmd = 0;
clr_resp_rdy = 0;
repeat(20) @(posedge clk);

while (resp_rdy != 1'b1) begin 
@(posedge clk);
end

if (resp_rcv == 8'h00 ) begin
		$display("Command acknowledged !");
		$display("Read EEPROM(channel3 - offset) success ! Received EEPROM  value (addr:2F) value : %h ", resp_rcv );
end else begin
		$display("ALERT! command not acknowledged !");
		$display("ALERT ! Read EEPROM(channel3 - offset) failed ! The response received : %h " , resp_rcv );
end




clr_resp_rdy = 1;




/////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////  FINALLY THE DUMP COMMAND !!  //////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////



/////////////////////////////////////////////
//  Read trig config till capture done   ///
///////////////////////////////////////////

while (resp_rcv != 8'h24) begin 

// Read trig cfg

	cmd_snd = 24'h070000;                               			 //command to read trig_cfg
	send_cmd = 1;
	repeat(10) @(posedge clk);
	send_cmd = 0;
	clr_resp_rdy = 0;
	repeat(20) @(posedge clk);

	while (resp_rdy != 1'b1) begin 
		@(posedge clk);
	end

	if (resp_rcv == 8'h24) begin
			$display("Capture done ! Trig cfg : %h", resp_rcv);
	end
	clr_resp_rdy = 1;
		
end

$display(" Trig config register : %h", resp_rcv);



////////////////////////////
////  Dump channel 1  /////
//////////////////////////


fd = $fopen("ch1.ods");

if ( fd == 0)
	$display ("ALERT! Unable to open ch1 file");



send_cmd = 1;                             
cmd_snd = 24'h010000;                                      
repeat(10) @(posedge clk);
send_cmd = 0;
clr_resp_rdy = 0;
repeat(20) @(posedge clk);

while (resp_rdy != 1'b1) begin 
		@(posedge clk);
end

while (i <= 509) begin // i < 510 and not 511 because first value is already received
		clr_resp_rdy = 1;
		repeat(10) @(posedge clk);
		clr_resp_rdy = 0;
		repeat(20) @(posedge clk);

	
	ch1_mem[i] = resp_rcv;

	$fdisplay(fd,"%h",resp_rcv);

	while (resp_rdy != 1'b1) begin 
			@(posedge clk);
	end
	i = i + 1;
end

$display("Dump channel 1 done !");
$fclose(fd);


clr_resp_rdy = 1;


////////////////////////////
////  Dump channel 2  /////
//////////////////////////
fd2 = $fopen("ch2.ods");

if ( fd2 == 0)
	$display ("ALERT! Unable to open ch2 file");

send_cmd = 1;                             
cmd_snd = 24'h010100;                                     
repeat(10) @(posedge clk);
send_cmd = 0;
clr_resp_rdy = 0;
repeat(20) @(posedge clk);

while (resp_rdy != 1'b1) begin 
		@(posedge clk);
end

while (i2 <= 509) begin // i < 510 and not 511 because first value is already received
		clr_resp_rdy = 1;
		repeat(10) @(posedge clk);
		clr_resp_rdy = 0;
		repeat(20) @(posedge clk);

	
	ch2_mem[i2] = resp_rcv;

	$fdisplay(fd2,"%h",resp_rcv);

	while (resp_rdy != 1'b1) begin 
			@(posedge clk);
	end
	i2 = i2 + 1;
end

$display("Dump channel 2 done !");
$fclose(fd2);


clr_resp_rdy = 1;


////////////////////////////
////  Dump channel 3  /////
//////////////////////////


fd3 = $fopen("ch3.ods");

if ( fd3 == 0)
	$display ("ALERT! Unable to open ch3 file");


send_cmd = 1;                             
cmd_snd = 24'h010200;                                      
repeat(10) @(posedge clk);
send_cmd = 0;
clr_resp_rdy = 0;
repeat(20) @(posedge clk);

while (resp_rdy != 1'b1) begin 
		@(posedge clk);
end

while (i3 <= 509) begin // i < 510 and not 511 because first value is already received
		clr_resp_rdy = 1;
		repeat(10) @(posedge clk);
		clr_resp_rdy = 0;
		repeat(20) @(posedge clk);


	ch3_mem[i3] = resp_rcv;

	$fdisplay(fd3,"%h",resp_rcv);

	while (resp_rdy != 1'b1) begin 
			@(posedge clk);
	end
	i3 = i3 + 1;
end

$display("Dump channel 3 done !");
$fclose(fd3);


clr_resp_rdy = 1;

$display("Random Sum of ch2 + ch3 : %h ", ch2_mem[20] + ch3_mem[20]);
///////////////////////////////////////////////////////////////
///////////////////// CHECK DATA CONSISTENCY /////////////////
/////////////////////////////////////////////////////////////

for (i = 0; i < 511; i = i + 1)
	if (( ch2_mem[i] + ch3_mem[i] > 9'h102 ) || (( ch2_mem[i] + ch3_mem[i] < 9'hFE ))) begin
			$display ("ALERT ! Data inconsistency present");
			$stop;
	end

$display(" SUCCESS !!! Data consistency test passed");




////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////// CAPTURE DONE CHECK ///////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////
////  Writing trig cfg   /////
/////////////////////////////
send_cmd = 1;                             
cmd_snd = 24'h060500;                                      //command to write trig_cfg
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

if (  iDUT.idcore.icmd.trig_cfg == 8'h05 )
		$display("Set trig config register success ! The trig config register value : %h " , iDUT.idcore.icmd.trig_cfg );
else
		$display("ALERT ! Set trig config register failed ! The trig config register value : %h " , iDUT.idcore.icmd.trig_cfg );


clr_resp_rdy = 1;


/////////////////////////////////////////////
//  Read trig config till capture done   ///
///////////////////////////////////////////

while (resp_rcv != 8'h25) begin 

// Read trig cfg

	cmd_snd = 24'h070000;                               			 //command to read trig_cfg
	send_cmd = 1;
	repeat(10) @(posedge clk);
	send_cmd = 0;
	clr_resp_rdy = 0;
	repeat(20) @(posedge clk);

	while (resp_rdy != 1'b1) begin 
		@(posedge clk);
	end

	if (resp_rcv == 8'h25) begin
			$display("Capture done ! Trig cfg : %h", resp_rcv);
	end
	clr_resp_rdy = 1;
		
end

$display(" Trig config register : %h", resp_rcv);



$display (" Success ! Capture done has been reset and set again ");



////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////  NEGATIVE ACK CHECK  //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////
////  Check for negative ACK  ////
/////////////////////////////////
cmd_snd = 24'hAA0000;                             //command for NACK
send_cmd = 1;
repeat(10) @(posedge clk);
send_cmd = 0;
clr_resp_rdy = 0;
repeat(20) @(posedge clk);

while (resp_rdy != 1'b1) begin 
@(posedge clk);
end

if (resp_rcv == 8'hEE ) begin
		$display("Negative acknowledgement test success ! Received response : %h", resp_rcv);
end else begin
		$display("ALERT ! Negative acknowledgement test failed ! The response received : %h " , resp_rcv );
end


#400;
$stop;

end

always
  #1 clk = ~clk;
			 
initial begin
// $monitor("%g cmd_rdy:%d cmd:%h iDUT_resp_sent:%h Resp_rcvd : %h RAM_read_address: %d i : %d", $time , iDUT.cmd_rdy , iDUT.cmd, iDUT.resp_data , resp_rcv, iDUT.idcore.icmd.addr, i);
//$monitor(" ch3 ss_n : %h,  ch2 ss_n : %h CHECKING ANALOG GAIN: %h ", ch1_ss_n, ch2_ss_n, iAFE.POT1.cmd );
//$monitor(" trig ss_n : %h, ch2 ss_n : %h CHECKING SET TRIGGER: %h ", trig_ss_n, ch2_ss_n, iAFE.POT4.cmd );
//$monitor(" CHECKING TRIGGER POS: %h ", iDUT.idcore.trig_pos );
//$monitor(" CHECKING DECIMATOR REG: %h ", iDUT.idcore.decimator_reg );
//$monitor(" CHECKING WRITE CONFIG: %h ", iDUT.idcore.trig_cfg );
//$monitor(" CHECKING WRITE EEPROM: %h ", iEEP.mem[7] );
//$monitor(" EEPROM data : %h ",  iDUT.EEP_data );

end


endmodule
			 
			 