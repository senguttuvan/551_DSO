
module dig_core(clk,rst_n,adc_clk,trig1,trig2,SPI_data,wrt_SPI,SPI_done,ss,EEP_data,
                rclk,en,we,addr,ch1_rdata,ch2_rdata,ch3_rdata,cmd,cmd_rdy,clr_cmd_rdy,
								resp_data,send_resp,resp_sent);
				
  input clk,rst_n;								// clock and active low reset
  output adc_clk,rclk;							// 20MHz clocks to ADC and RAM
  input trig1,trig2;							// trigger inputs from AFE
  output [15:0] SPI_data;						// typically a config command to digital pots or EEPROM
  output wrt_SPI;								// control signal asserted for 1 clock to initiate SPI transaction
  output [2:0] ss;								// determines which Slave gets selected 000=>trig, 001-011=>chX_ss, 100=>EEP
  input SPI_done;								// asserted by SPI peripheral when finished transaction
  input [7:0] EEP_data;							// Formed from MISO from EEPROM.  only lower 8-bits needed from SPI periph
  output en,we;									// RAM block control signals (common to all 3 RAM blocks)
  output [8:0] addr;							// Address output to RAM blocks (common to all 3 RAM blocks)
  input [7:0] ch1_rdata,ch2_rdata,ch3_rdata;	// data inputs from RAM blocks
  input [23:0] cmd;								// 24-bit command from HOST
  input cmd_rdy;								// tell core command from HOST is valid
  output clr_cmd_rdy;
  output [7:0] resp_data;						// response byte to HOST
  output send_resp;								// control signal to UART comm block that initiates a response
  input resp_sent;								// input from UART comm block that indicates response finished sending
  
  //////////////////////////////////////////////////////////////////////////
  // Interconnects between modules...declare any wire types you need here//
  ////////////////////////////////////////////////////////////////////////

  ///From the command processing unit to the trig_cap module//////
   wire [3:0] decimator_reg;
   wire [7:0] trig_cfg;    
   wire [8:0] trig_pos,wr_addr,rd_addr,trace_end;
   wire capture_done;
	 reg adc_clk;
	 wire [7:0] resp_to_send;

  ////////////////////////////From cmd_module to ram_iface////////////////////////
   wire [1:0] channel;                      //Selects the channel


	 //////////////////////////////// Trigger logic inputs//////////////////////////
	 wire trigEdge;
	 wire [1:0] trigSrc;                   
	 wire wrt_en,dump_en,wr_en;


  ///////////////////////////////////////////////////////
  // Instantiate the blocks of your digital core next //
  /////////////////////////////////////////////////////

 cmd_module icmd	(.clk(clk),
									 .rst_n(rst_n), 
									 .SPI_done(SPI_done),
									 .cmd(cmd), 
									 .cmd_rdy(cmd_rdy), 
									 .SPI_data(SPI_data),
									 .ss(ss),
									 .wrt_SPI(wrt_SPI),
									 .EEP_data(EEP_data),
									 .send_resp(send_resp),
									 .clr_cmd_rdy(clr_cmd_rdy),
									 .resp_sent(resp_sent),
									 .resp_to_send(resp_data) ,
									 .trig_cfg(trig_cfg) ,
									 .trig_pos(trig_pos) ,
									 .decimator_reg(decimator_reg),
									 .capture_done(capture_done) ,
									 .ch1_rdata(ch1_rdata) ,
									 .ch2_rdata(ch2_rdata) ,
									 .ch3_rdata(ch3_rdata),
									 .addr(rd_addr),
									 .trace_end(trace_end), 
									 .clr_capture_done(clr_capture_done),
									 .dump_en(dump_en));



	////////////////////////////////
  // Generate rclk and adc_clk //
	//////////////////////////////
	
	always @(posedge clk)
	if (!rst_n)
		adc_clk <= 0;
	else
    adc_clk <= ~adc_clk;
	
	assign rclk = ~adc_clk;

	//////////////////////////
  // Assign ram controls //
	////////////////////////
	
	assign en = wrt_en | dump_en;
	assign addr = (~dump_en) ? wr_addr : rd_addr;
	assign we = (~dump_en)? wr_en : 1'b0 ; 

  /////////////////////////////////////////////////////////////////
  ///////////////////Trigger & Capture Logic//////////////////////
  ///////////////////////////////////////////////////////////////

	assign trigSrc = trig_cfg[1:0];
	assign trigEdge = trig_cfg[4];

  
 capture CAP(	.clk(clk), .rst_n(rst_n), .triggered(triggered), .rclk(adc_clk),
									  .trig_cfg(trig_cfg), .trig_pos(trig_pos),.trace_end(trace_end),.trig_en(trig_en),
									  .decimator_reg(decimator_reg), .capture_done(capture_done),
									  .clr_capture_done(clr_capture_done),
									  .armed(armed), .we(wr_en), .en(wrt_en), .addr(wr_addr));

trig itrig(	.clk(clk),.rst_n(rst_n),.trigSrc(trigSrc),.trigEdge(trigEdge),.armed(armed),
							.trig_en(trig_en),.set_capture_done(capture_done),
							.trigger1(trig1),.trigger2(trig2),.triggered(triggered));

endmodule
 


