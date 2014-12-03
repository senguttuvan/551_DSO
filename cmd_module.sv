
module cmd_module(clk,rst_n,SPI_done,cmd,cmd_rdy,SPI_data,ss,wrt_SPI,EEP_data,send_resp,clr_cmd_rdy,resp_sent,resp_data,
                  trig_cfg,trig_pos,decimator_reg,capture_done,ch1_rdata,ch2_rdata,ch3_rdata,rd_addr,trace_end,
									ram_en,clr_capture_done);              

input clk,rst_n,SPI_done;
input cmd_rdy;
input [23:0] cmd;
input resp_sent;
input [7:0] EEP_data;
input capture_done; // set trig_cfg[5] to 0 , whenever capture_done is asserted
input [8:0] trace_end;
input [7:0] ch1_rdata,ch2_rdata,ch3_rdata;

output reg [8:0] trig_pos;
output reg [3:0] decimator_reg;
output reg [7:0] trig_cfg;
output reg ram_en;
output reg [7:0] resp_data;
output [15:0] SPI_data;
output [2:0] ss;
output wrt_SPI,send_resp;
output clr_cmd_rdy;
output reg [8:0] rd_addr;
output clr_capture_done;

   //////////////////////////////////////////////////////////////////////////
  // Interconnects between modules...declare any wire types you need here //
 //////////////////////////////////////////////////////////////////////////
 reg set_dec,cfg_pot,set_trig_cfg,set_pos,set_clr_capture;
 reg capture_ch1_gain, capture_ch2_gain,capture_ch3_gain;
 reg [15:0] SPI_data;	
 reg [2:0] ss;
 reg wrt_SPI,send_resp; 
 reg clr_cmd_rdy;
 reg [2:0] ch1_gain,ch2_gain,ch3_gain;
 reg [7:0] offset,gain;
 reg flop_offset,flop_gain;
 wire [7:0]corrected;
 reg strt_addrcnt,en_addrcnt,set_channel;
 reg [1:0] chnl;
// reg [7:0]trig_pot;
 localparam DUMP_CHN = 4'h1;
 localparam CFG_GAIN = 4'h2;
 localparam SET_TRIG = 4'h3;
 localparam CFG_TRG  = 4'h4;
 localparam SET_DECM = 4'h5;
 localparam WRT_TRG  = 4'h6;
 localparam RD_TRG   = 4'h7;
 localparam WRT_EEP  = 4'h8;
 localparam RD_EEP   = 4'h9;

 typedef enum reg [3:0] {CMD_DISPATCH,RD_OFFST1,RD_GAIN1,RD_OFFST2,DUMP1,DUMP2,CFG_GAIN2,SET_TRIG2,WRT_EEP2,RD_EEP2,RD_EEP3,EEP_TX,SEND_ACK,
													CFG_TX,SEND_NEGACK} state_t;

///////////////////////////////change order in typedef/////////
 state_t state,nstate;


   /////////////////////////////////////////////
  // Instantiation of gain correction logic  //
 /////////////////////////////////////////////

 wire [7:0] raw;

 assign raw =  (~chnl[1] & ~chnl[0]) ? ch1_rdata :                         //raw is assigned data based on the signal chnl
								(~chnl[1] & chnl[0]) ?  ch2_rdata : ch3_rdata;

 calib_eep icorr(.raw(raw),.off(offset),.gain(gain),.corrected(corrected));           

  ///////////////////////////////////
  // Logic for Command processing //
  /////////////////////////////////

	assign clr_capture_done = (set_clr_capture)?1:0;                                           

///////////address of the RAM////////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if(~rst_n)
			rd_addr <= 9'h000;
		else if(strt_addrcnt)                                            
			rd_addr <= trace_end + 1;
		else if(en_addrcnt)
			rd_addr <= rd_addr + 1;
	end

//////////////////////decimator register//////////////////// 
always_ff @ (posedge clk,negedge rst_n)
	if (!rst_n)
		decimator_reg <= 4'b0000;                                      
	else if(set_dec)
		decimator_reg <= cmd[3:0];


//////////////////////trigger position register//////////////////// 
always_ff @ (posedge clk,negedge rst_n)
	if (!rst_n)
		trig_pos <= 9'h000;
	else if(set_pos)
		trig_pos <= cmd[8:0];


//////////////////////trigger configure register//////////////////// 
always_ff @ (posedge clk,negedge rst_n)
	if (!rst_n)
		trig_cfg <= 8'h00;
	else if(set_trig_cfg)
		trig_cfg	<= cmd[15:8];
	else if(capture_done)
		trig_cfg[5] <= 0;


//////////////////////State machine's definition//////////////////// 
always_ff @ (posedge clk,negedge rst_n)
	if (!rst_n)
		state <= CMD_DISPATCH;
	else
		state <= nstate;

//////////////////////channel 1's analog gain //////////////////// 
always_ff @ (posedge clk,negedge rst_n)
	if (!rst_n)
		ch1_gain <= 3'b000;
	else if(capture_ch1_gain)
		ch1_gain <= cmd[12:10];


//////////////////////channel 2's analog gain//////////////////// 
always_ff @ (posedge clk,negedge rst_n)
	if (!rst_n)
		ch2_gain <= 3'b000;
	else if(capture_ch2_gain)
		ch2_gain <= cmd[12:10];


//////////////////////channel 3's analog gain//////////////////// 
always_ff @ (posedge clk,negedge rst_n)
	if (!rst_n)
		ch3_gain <= 3'b000;
	else if(capture_ch3_gain)
		ch3_gain <= cmd[12:10];


//////////////////////offset of the caliberation unit//////////////////// 
always_ff @ (posedge clk,negedge rst_n)
	if (!rst_n)
		offset <= 8'h00;
	else if(flop_offset)
		offset <= EEP_data;


//////////////////////gain of the caliberation unit//////////////////// 
always_ff @ (posedge clk,negedge rst_n)
	if (!rst_n)
		gain <= 8'h00;
 else if(flop_gain)
		gain <= EEP_data;


//////////////////////chnl determines which channel to choose//////////////////// 
always_ff @ (posedge clk,negedge rst_n)
	if (!rst_n)
		chnl <= 2'b00;
	else if(set_channel)
		chnl <= cmd[9:8];


///////////////////////////combinational block///////////////////
 always_comb 
 begin	

 SPI_data = 16'h0000;
 ss = 3'b000;
 wrt_SPI = 0;                         ///////default values//////////
 send_resp = 0;
 clr_cmd_rdy = 0;
 resp_data = 8'hA5;
 capture_ch1_gain = 0;
 capture_ch2_gain = 0;
 capture_ch3_gain = 0;
 flop_offset = 0;
 flop_gain = 0;
 strt_addrcnt = 0;
 en_addrcnt = 0;
 set_channel = 0;
 set_dec=0;
 set_trig_cfg=0;
 set_pos=0;
 ram_en=0;
 set_clr_capture= 0;

        case (state)                                               //if state is CMD_DISPATCH check for cmd_rdy
							CMD_DISPATCH : begin                                 //if cmd_rdy is high check the first byte of cmd
											if (cmd_rdy) begin
															case (cmd[19:16])

													DUMP_CHN : begin                         //
																		wrt_SPI = 1;
																		ss = 3'b100;
																		set_channel = 1;
																						case (cmd[9:8])
																												2'b00 : begin
																																SPI_data = {4'h0,ch1_gain,1'b0,8'h00};
																																end
																												2'b01 : begin
																																SPI_data = {4'h1,ch2_gain,1'b0,8'h00};		
																																end
																												2'b10 : begin
																																SPI_data = {4'h2,ch3_gain,1'b0,8'h00};		
																																end
																																endcase
																				nstate = RD_OFFST1;
																				end

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
															
																							nstate = CFG_GAIN2;
				  														end
				
							
													CFG_TRG:		begin
																			set_pos=1;
																			nstate=SEND_ACK;
																			end

													SET_DECM:	 begin
																			set_dec=1;
																			nstate=SEND_ACK;
																	    end

													WRT_TRG:	begin
																			set_trig_cfg=1;
																			set_clr_capture= ~cmd[5];
																			nstate=SEND_ACK;
																		end

													RD_TRG:begin
																		resp_data=trig_cfg;
																		send_resp=1;
																		nstate=CFG_TX;
																		end	
					
			 										SET_TRIG :begin
																		ss = 3'b000;
																		SPI_data = {8'h13,cmd[7:0]};
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
																		SPI_data = {2'b00,cmd[13:0]};	// addresss is in 13:8 
																		nstate = RD_EEP2;
				  													end

			  								default : begin	// unkown command so neg ack
																	resp_data = 8'hEE;
																	clr_cmd_rdy = 1;
																	send_resp = 1;
																	nstate = SEND_NEGACK;
			  													end
												endcase
								end								
								else 
													nstate = CMD_DISPATCH;
                end

							RD_OFFST1 :  begin
																				if (SPI_done) begin
																									nstate = RD_GAIN1;
																											end
																				else begin
		 																					ss = 3'b100;	// select EEPROM on SPI bus
																							nstate = RD_OFFST1;
																							end
	 																			end

  							RD_GAIN1 : 	begin
																			if (SPI_done) begin
																									nstate = RD_OFFST2;
																									flop_offset = 1;
																										end
																			else begin
		 																				ss = 3'b100;	// select EEPROM on SPI bus
																						nstate = RD_GAIN1;
																						wrt_SPI = 1;
																						
																										case (cmd[9:8])
																														2'b00 : begin
																																		SPI_data = {4'h0,ch1_gain,1'b1,8'h00};
																																		end
																														2'b01 : begin
																																		SPI_data = {4'h1,ch2_gain,1'b1,8'h00};						
																																		end
																														2'b10 : begin
																																		SPI_data = {4'h2,ch3_gain,1'b1,8'h00};						
																																		end
																										endcase
																					end
	 													end

								RD_OFFST2 : begin
															if(SPI_done) begin
																						nstate = DUMP1;
																						flop_gain = 1;
		  																			strt_addrcnt = 1;
		  																			ram_en = 1;		
																						end
								
															else begin
																						ss = 3'b100;	// select EEPROM on SPI bus
																						nstate = RD_OFFST2;
 																						wrt_SPI = 1;
																						SPI_data = 16'h0000;
																	end
														end

							DUMP1 : begin
													if(rd_addr == trace_end)
																			nstate = SEND_ACK;
													else begin
																		nstate = DUMP2;
																		resp_data = corrected;
		  															send_resp = 1;
													     end
                     end


  						DUMP2 : begin
													if(resp_sent) begin
			 																	nstate = DUMP1;
			 																	en_addrcnt = 1;
																				end
	 												else begin
			 													nstate = DUMP2;
																resp_data = corrected;
													end
											end

						CFG_GAIN2 : begin
														if(SPI_done) begin
																				nstate = SEND_ACK;
																		end
														else begin
																			if (~cmd[9]&&~cmd[8])
																			ss = 3'b001;
																			else if (~cmd[9]&&cmd[8])
																			ss = 3'b010;
																			else
																			ss = 3'b011;
																nstate = CFG_GAIN2;
																	end
												end

 						SET_TRIG2 : begin
														if(SPI_done) 
																		nstate = SEND_ACK;
														else begin
	 																	ss = 3'b000;	// select Trigger digital pot (in AFE) on SPI bus
																		nstate = SET_TRIG2;
																	end
	 											end

 						WRT_EEP2 : begin
														if(SPI_done) begin
																		nstate = SEND_ACK;													
															end																					
														else begin
	 																	ss = 3'b100;	// select EEPROM on SPI bus
																		nstate = WRT_EEP2;
																	end
	 											end

 						RD_EEP2  : begin
												if (SPI_done) begin
																			nstate = RD_EEP3;
																			wrt_SPI = 1;
																			ss = 3'b100;
																			end
												else begin
		 																ss = 3'b100;	// select EEPROM on SPI bus
																		nstate = RD_EEP2;
															end
	 									end

				 		RD_EEP3 : begin
												if (SPI_done) begin
																			nstate = EEP_TX;
																			resp_data = EEP_data;
																			send_resp = 1;
	 													 end
												else begin
																			ss = 3'b100; // select EEPROM on SPI bus
																			nstate = RD_EEP3;
														 end
										end

					 EEP_TX : begin
											if(resp_sent)
												nstate = SEND_ACK;
											else begin
												nstate = EEP_TX;
												resp_data = EEP_data;
											end
										 end

					 CFG_TX : begin
											if(resp_sent)
												nstate = SEND_ACK;
											else begin
												nstate = CFG_TX;
												resp_data = trig_cfg;
											 end
											end
					

					 SEND_ACK : begin
												clr_cmd_rdy = 1;
												send_resp = 1;
												nstate = CMD_DISPATCH;
											end

					 SEND_NEGACK : begin
												resp_data = 8'hEE;
												nstate = CMD_DISPATCH;
											end


 						default  : begin
	 									SPI_data = 16'h0000;
	 									ss = 3'b000;
										wrt_SPI = 0;
	 									send_resp = 0;
	 									clr_cmd_rdy = 0;
	 									resp_data = 8'hA5;
	 									capture_ch1_gain = 0;
	 									capture_ch2_gain = 0;
	 									capture_ch3_gain = 0;
	 									flop_offset = 0;
	 									flop_gain = 0;
   									strt_addrcnt = 0;
   									en_addrcnt = 0;
   									set_channel = 0;
   									set_dec=0;
   									set_trig_cfg=0;
	 									set_pos=0;
										ram_en=0;
										set_clr_capture= 0;
	 									end
		endcase
end
endmodule
