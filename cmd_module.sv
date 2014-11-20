module cmd_module(clk,rst_n,SPI_done,cmd,cmd_rdy,SPI_data,ss,wrt_SPI,capture_ch1_gain,capture_ch2_gain,capture_ch3_gain,send_resp,clr_cmd_rdy);

input clk,rst_n,SPI_done;
input cmd_rdy;
input [23:0] cmd;

output [15:0] SPI_data;
output [2:0] ss;
output wrt_SPI,send_resp;
output capture_ch1_gain,capture_ch2_gain,capture_ch3_gain,clr_cmd_rdy;

  //////////////////////////////////////////////////////////////////////////
  // Interconnects between modules...declare any wire types you need here//
  ////////////////////////////////////////////////////////////////////////

 reg capture_ch1_gain, capture_ch2_gain,capture_ch3_gain;
 reg [15:0] SPI_data;	
 reg [2:0] ss;
 reg wrt_SPI,send_resp; 
 reg clr_cmd_rdy;
 

 localparam CFG_GAIN = 4'h2;
 localparam SET_TRIG = 4'h3;
 localparam WRT_EEP  = 4'h8;
 localparam RD_EEP   = 4'h9;

 typedef enum reg [2:0] {CMD_DISPATCH,CFG_GAIN2,SET_TRIG2,WRT_EEP2,RD_EEP2,RD_EEP3} state_t;

 state_t state,nstate;


  ///////////////////////////////////
  // Logic for Command processing //
  /////////////////////////////////

always_ff @ (posedge clk,negedge rst_n)
	if (!rst_n)
		state <= CMD_DISPATCH;
	else
		state <= nstate;
	
always_comb 
begin	

 SPI_data = 16'h0000;
 ss = 3'b000;
 wrt_SPI = 0;
 send_resp = 1;
 clr_cmd_rdy = 0;

case (state)
	CMD_DISPATCH : begin
		if (cmd_rdy) begin
			case (cmd[19:16])
				CFG_GAIN : begin
					wrt_SPI = 1;
					///// ss is determined from cmd[9:8]
					case (cmd[9:8])
						2'b00 : begin
							ss = 3'b001;
							capture_ch1_gain = 1;
						end
						2'b01 : begin
							ss = 3'b010;
							capture_ch2_gain  = 1;
						end
						default : begin
							ss = 3'b011;
							capture_ch3_gain  = 1;	//have to keep track of channel gains locally
						end
					endcase
			
					////// SPI data to send is based on ggg bits
					case (cmd[12:10])
						3'b000 : SPI_data = 16'h1302;
						3'b001 : SPI_data = 16'h1305;
						3'b010 : SPI_data = 16'h1309;
						3'b011 : SPI_data = 16'h1314;
						3'b100 : SPI_data = 16'h1328;
						3'b101 : SPI_data = 16'h1346;
						3'b110 : SPI_data = 16'h136B;
						3'b111 : SPI_data = 16'h13DD;
					endcase
						clr_cmd_rdy = 1;
						nstate = CFG_GAIN2;
				  end
				
			  SET_TRIG : begin
						ss = 3'b111;
						SPI_data = {8'h00,cmd[7:0]};
        	 	wrt_SPI = 1;
						nstate = SET_TRIG2;
				  end

  		  WRT_EEP : begin
					 	wrt_SPI = 1;
						ss = 3'b100;			// select EEPROM on SPI bus
						SPI_data = {2'b01,cmd[13:0]};	// addresss is in 13:8 , data to write is in 7:0
						nstate = WRT_EEP2;
				   end

			  RD_EEP : begin
					 	wrt_SPI = 1;
						ss = 3'b100;			// select EEPROM on SPI bus
						SPI_data = {2'b00,cmd[13:0]};	// addresss is in 13:8 and lower bits are o
						nstate = RD_EEP2;
				  end

			  default : begin	// unkown command so neg ack
						send_resp = 0;
			  end
			endcase
					clr_cmd_rdy = 1;
		end
		else begin
			nstate = CMD_DISPATCH;
			   
		end
	end

	CFG_GAIN2 : begin
		if(SPI_done) 
				nstate = CMD_DISPATCH;
		else begin
			if (capture_ch1_gain)
				ss = 3'b001;
			else if (capture_ch2_gain)
				ss = 3'b010;
			else
				ss = 3'b011;
			nstate = CFG_GAIN2;
			 clr_cmd_rdy = 1;
		end
	end

 	SET_TRIG2 : begin
				if(SPI_done) begin
				nstate = CMD_DISPATCH;
	end
			else begin
//	 			wrt_SPI = 1;
	 			ss = 3'b111;	// select EEPROM on SPI bus
				nstate = SET_TRIG2;
				 clr_cmd_rdy = 1;
			end
	 end

 WRT_EEP2 : begin
			if(SPI_done) begin
				nstate = CMD_DISPATCH;
			end
			else begin
	// 			wrt_SPI = 1;
	 			ss = 3'b100;	// select EEPROM on SPI bus
				nstate = WRT_EEP2;
			 clr_cmd_rdy = 1;
			end
	 end

 RD_EEP2  : begin
		if (SPI_done) begin
			nstate = RD_EEP3;
			wrt_SPI = 1;
			ss = 3'b100;
		end
		else begin
//		 	wrt_SPI = 1;
		 	ss = 3'b100;	// select EEPROM on SPI bus
			nstate = RD_EEP2;
 clr_cmd_rdy = 1;	
		end
	 end

 RD_EEP3 : begin
	if (SPI_done) begin
		nstate = CMD_DISPATCH;
	 end
	else begin
//		wrt_SPI = 1;
		ss = 3'b100;
		nstate = RD_EEP3;
	end
end


 default  : begin
			 SPI_data = 16'h0000;
			 send_resp = 1;
			 ss = 3'b000;
			 wrt_SPI = 0;
			 nstate = CMD_DISPATCH;
			 clr_cmd_rdy = 1;
	 end
endcase
end

endmodule


/*
module cmd_module_tb();

input clk,rst_n,SPI_done;
input cmd_rdy;
input [23:0] cmd;

output [15:0] SPI_data;
output [2:0] ss;
output wrt_SPI,send_resp;
output capture_ch1_gain,capture_ch2_gain,capture_ch3_gain;


DSO_dig icmd(clk,rst_n,adc_clk,ch1_data,ch2_data,ch3_data,trig1,trig2,MOSI,MISO,
               SCLK,trig_ss_n,ch1_ss_n,ch2_ss_n,ch3_ss_n,EEP_ss_n,TX,RX,LED_n);


initial begin
clk = 1;
forever #1 clk = ~clk;
end

initial begin
RX = 8'h02;
RX = 8'h1C;
RX = 8'hEF;




rst_n = 0;
icmd.cmd_rdy = 1;
@(posedge clk)
	icmd.cmd_rdy = 1;
@(negedge clk);
	rst_n = 1;

repeat (1) @(posedge clk);

if( ( icmd.SPI_data == 16'h13DD ) && (icmd.wrt_SPI) && ( icmd.ss == 3'b001 ))
		$display("Success");

icmd.cmd = 24'h031CEF;
repeat (1) @(posedge clk) ;
@(negedge clk) icmd.cmd_rdy = 0;
if( ( icmd.SPI_data == 16'h00EF ) && (icmd.wrt_SPI) && ( icmd.ss == 3'b111 ))
		$display("Success");

icmd.cmd = 24'h081CEF;

@(negedge clk) icmd.cmd_rdy = 0;
repeat (1) @(posedge clk);

@(icmd.SPI_done)
if( ( icmd.SPI_data == 16'h5CEF ) && (icmd.wrt_SPI) && ( icmd.ss == 3'b100 ))
		$display("Success");

icmd.cmd_rdy = 1;
icmd.cmd = 24'h092CBF;

repeat (2) @(posedge clk);

@(icmd.SPI_done)
if( ( icmd.SPI_data == 16'h2CBF ) && (icmd.wrt_SPI) && ( icmd.ss == 3'b100 ))
		$display("Success");

repeat (2) @(posedge clk);
$stop;
end

initial begin
$monitor ("time: %g cmd : %h SPI_data : %h ss : %b wrt_SPI : %b",$time,icmd.cmd,icmd.SPI_data,icmd.idcore.ss,icmd.wrt_SPI );
end

endmodule

*/