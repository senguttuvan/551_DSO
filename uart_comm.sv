module uart_comm(clk, rst_n, RX, clr_cmd_rdy, cmd_rdy, cmd);


input clk, rst_n, RX;


input clr_cmd_rdy;
output reg cmd_rdy;
output [23:0] cmd;

reg clr_rdy, ld_hi, ld_mid, data_rdy;
reg [7:0] cmd_hi, cmd_mid;
wire [7:0] cmd_hi_comb, cmd_mid_comb;
wire[7:0] rx_data;
wire rdy;

uart_rx RX_DUT(.clk(clk), .rst_n(rst_n), .rdy(rdy), .clr_rdy(clr_rdy), .RX(RX), .rx_data(rx_data));

typedef enum reg[1:0] {IDLE, RX1, RX2, RX3} state_t;
state_t state, next_state;

assign cmd_hi_comb = ld_hi ? rx_data : cmd_hi;
assign cmd_mid_comb = ld_mid ? rx_data : cmd_mid;

assign cmd = cmd_rdy ? {cmd_hi, cmd_mid, rx_data} : 24'h000000;

always @(posedge clk, negedge rst_n) begin
if(~rst_n)
cmd_rdy <= 0;
else if(~clr_cmd_rdy & data_rdy)
cmd_rdy <= data_rdy;
else if(clr_cmd_rdy)
cmd_rdy <= 0;
end


always @(posedge clk, negedge rst_n) begin
if(~rst_n)
cmd_hi <= 8'h00;
else
cmd_hi <= cmd_hi_comb;
end

always @(posedge clk, negedge rst_n) begin
if(~rst_n)
cmd_mid <= 8'h00;
else 
cmd_mid <= cmd_mid_comb;
end

always @(posedge clk, negedge rst_n) begin
if(~rst_n)
state <= IDLE;
else
state <= next_state;
end

always @(state, rdy) begin
data_rdy = 0;
clr_rdy = 0;
next_state = IDLE;
ld_hi = 0;
ld_mid = 0;
case(state)
IDLE : begin
       next_state = RX1;
       clr_rdy =1;
       end

RX1: begin
     if(~rdy)
     next_state = RX1;
     else begin
     next_state = RX2;
     ld_hi =1;
     clr_rdy = 1;
     end
     end

RX2: begin
     if(~rdy)
     next_state = RX2;
     else begin
     next_state = RX3;
     ld_mid = 1;
     clr_rdy = 1;
     end
     end

RX3: begin
     if(~rdy)
     next_state = RX3;
     else begin
     next_state = IDLE;
     data_rdy = 1;
     clr_rdy = 1;
     end
     end
endcase

end


endmodule
    

 
