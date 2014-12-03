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
   wire [8:0] trig_pos;
   wire capture_done;


   //From cmd_module to ram_iface
   wire dump_en;    //Enable data dump
   wire [1:0] channel;  //Selects the channel
   wire corrected;

  ///////////////////////////////////////////////////////
  // Instantiate the blocks of your digital core next //
  /////////////////////////////////////////////////////

  cmd_module icmd(clk,rst_n,SPI_done,cmd,cmd_rdy,SPI_data,ss,wrt_SPI,EEP_data,send_resp,clr_cmd_rdy,resp_sent,resp_data,
                  trig_cfg,trig_pos,decimator_reg,capture_done);
  
  //Trigger & Capture Logic////
  
  // trig_cap TRIG_CAP(.clk(clk), .rst_n(rst_n), .trig1(trig1), .trig2(trig2), .adc_clk(adc_clk), .trig_cfg(trig_cfg), .trig_pos(trig_pos), .decimator_reg(decimator_reg), .capture_done(capture_done));

  ///// RAM Interface /////
  
  // ram_iface  RAM_IFACE(.ch1_rdata(ch1_rdata), .ch2_rdata(ch2_rdata), .ch3_rdata(ch3_rdata), .rclk(rclk), .clk(clk), .rst_n(rst_n), .en(en), .we(we), .addr(addr),.dump_en(dump_en), .channel(channel), .corrected(corrected), .EEP_data(EEP_data));

  endmodule
 


