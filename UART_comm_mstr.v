module UART_comm_mstr(clk,rst_n,RX,TX,cmd,send_cmd,cmd_sent,resp_rdy,resp,clr_resp_rdy);

input clk,rst_n,RX,send_cmd,clr_resp_rdy;
input [23:0] cmd;

output [7:0] resp;
output TX,cmd_sent,resp_rdy;


wire [7:0] cmd_part;
reg send,cmd_sent;

uart_tx iutx(.TX(TX), .trmt(send), .tx_data(cmd_part), .rst_n(rst_n), .clk(clk), .tx_done(byte_done));

uart_rx iurx(.clk(clk) , .rst_n(rst_n), .rx_data(resp), .RX(RX), .clr_rdy(clr_resp_rdy), .rdy(resp_rdy));


reg [2:0] tx = 0;

assign cmd_part = ( tx == 0 ) ? cmd [23 : 16] :
			((tx == 1 )? cmd[15:8] :
				((tx == 2)?cmd[7:0] : 8'h00));


reg [1:0] state,nstate;

localparam IDLE = 2'b00;
localparam TXD = 2'b01;
localparam TX2 = 2'b10;


always @(posedge clk, negedge rst_n) begin
if(!rst_n)
state <= IDLE;
else
state <= nstate;
end


reg clr_tx;

always @(posedge clk, negedge rst_n) begin
if(!rst_n)
tx <= 0;
else if (clr_tx)
tx <= 0;
end

reg q = 0;

always @(state,send_cmd,tx,byte_done) begin
send = 0;
cmd_sent = 0;
clr_tx  =0;
case (state)

IDLE : if (send_cmd) begin
					nstate = TXD;
	     end
		   else
		      nstate = IDLE;

TXD : if (tx == 3) begin
			  cmd_sent = 1;
			  nstate = IDLE;
			  clr_tx  =1;
		  end
			else	begin
				send = 1;
				nstate = TX2;
			end

TX2 : if (byte_done) begin
				tx = tx + 1;
				nstate = TXD;
			end
			else begin
				nstate = TX2;
			end
endcase
end


endmodule
