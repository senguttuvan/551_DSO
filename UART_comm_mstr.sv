module UART_comm_mstr(clk,rst_n,RX,TX,cmd,send_cmd,cmd_sent,resp_rdy,resp_rcv,clr_resp_rdy);

input clk,rst_n,RX,send_cmd,clr_resp_rdy;
input [23:0] cmd;

output [7:0] resp_rcv;
output TX,resp_rdy;
output reg cmd_sent;

reg clr_tx;
reg q = 0;
wire [7:0] cmd_part;
reg send;
reg inc_cnt;

uart_tx iutx(.TX(TX), .trmt(send), .tx_data(cmd_part), .rst_n(rst_n), .clk(clk), .tx_done(part_done));

uart_rx iurx(.clk(clk) , .rst_n(rst_n), .rx_data(resp_rcv), .RX(RX), .clr_rdy(clr_resp_rdy), .rdy(resp_rdy));


reg [2:0] tx = 0;

assign cmd_part = ( tx == 0 ) ? cmd [23 : 16] :                                //assign cmd_part ie tx_data as either the first byte,second byte 
			((tx == 1 )? cmd[15:8] :																								//or last byte based on tx's value
				((tx == 2)?cmd[7:0] : 8'h00));


typedef enum reg[1:0] {IDLE, TXD, TX2} state_t;
state_t state,nstate;

//////////////////////////////////////////////////////////////
//////////////////state machine implementation///////////////
////////////////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
if(!rst_n)
state <= IDLE;
else
state <= nstate;
end

///////////////////////////////////////////////////////////////
////////////////////Implemetation of tx///////////////////////
/////////////////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
if(!rst_n)
tx <= 0;
else if (clr_tx)
tx <= 0;
else if(inc_cnt)
tx <= tx+1;
end

///////////////////////////////////////////////////////////////////
//////////////////////////Combinational block/////////////////////
/////////////////////////////////////////////////////////////////
always_comb
begin
send = 0;
cmd_sent = 0;
clr_tx  =0;
inc_cnt = 0;
nstate = IDLE;
			case (state)

							IDLE : if (send_cmd)                            //if cmd has been sent go to TXD state
												nstate = TXD;
								
										else
												nstate = IDLE;                        

							TXD : if (tx == 3) begin                       //if tx is 3 clear tx and go to IDLE and send an ACK
																	cmd_sent = 1;
																	nstate = IDLE;
																	clr_tx  =1;
																	end
										else	begin
																	send = 1;                     //otherwise go to TX2 state and enable send signal
																	nstate = TX2;
													end

							TX2 : if (part_done) begin                       //if part_done ie tx_done is high increment tx 
																		inc_cnt = 1;
																		nstate = TXD;              //and go back to TXD
																	end
										else 
																	nstate = TX2;
			 endcase
																	end


endmodule
