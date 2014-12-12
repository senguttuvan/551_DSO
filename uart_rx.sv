
module uart_rx(clk, rst_n, rx_data, RX, clr_rdy, rdy);

input clr_rdy, clk, rst_n, RX;
output reg rdy;
output reg[7:0] rx_data;

reg q1_RX, q2_RX, q3_RX, clr_rcv, count_en, baud_count_en, clr_baud, data_rdy;
wire rx_fall, bit_count_en, bit_half_count;
wire [9:0] data_shift;

reg [5:0] baud_count;
reg [3:0] bit_count;
reg [7:0] rcv_data;

typedef enum reg[1:0] {IDLE, START, RCV, STOP} state_t;
state_t state, next_state;

always @(posedge clk, negedge rst_n) begin
if(!rst_n)
q1_RX <= 0;
else
q1_RX <= RX;
end

always @(posedge clk) begin
q2_RX <= q1_RX;             // double flopping RX
q3_RX <= q2_RX;
end

assign rx_fall = q3_RX & ~q2_RX;
 

assign data_shift = (count_en) ? {q2_RX, rcv_data[7:1]} : rcv_data;
assign bit_count_en = (baud_count == 6'd43) ? 1 : 0;
assign bit_half_count = (baud_count == 6'd22) ? 1: 0;



always @(posedge clk, negedge rst_n) begin   //rdy after start and stop bits
if(!rst_n)
rdy <= 0;
else if(clr_rdy)
rdy <= 0;
else if(!clr_rdy & data_rdy)
rdy <= 1;
end

always @(posedge clk, negedge rst_n) begin
if(~rst_n)
rx_data <= 8'h00;
else if(bit_count[3])
rx_data <= rcv_data[7:0];
end

always @(posedge clk, negedge rst_n) begin    //Counting to 43 cycles
if(!rst_n)
baud_count <= 6'h00;
else if(bit_count_en | clr_baud)
baud_count <= 6'h00;
else if(baud_count_en & ~bit_count_en)
baud_count <= baud_count + 1;
end

always @(posedge clk, negedge rst_n) begin      //Counting the number of incoming bits
if(!rst_n)
bit_count <= 4'h0;
else if(clr_rdy | clr_rcv)
bit_count <= 4'h0;
else if(count_en)
bit_count <= bit_count + 1;
end


always @(posedge clk, negedge rst_n) begin   //shift register for incoming data
if(!rst_n)
rcv_data <= 8'h00;
else if(~clr_rcv)
rcv_data <= data_shift;
else
rcv_data <= 8'h00;
end

always @(posedge clk, negedge rst_n) begin
if(!rst_n)
state <= IDLE;
else
state <= next_state;
end

always @(state, rx_fall, bit_count, bit_count_en, clr_baud, bit_half_count) begin

next_state = IDLE;   //Default state
clr_rcv = 0;
count_en = 0;
baud_count_en = 0;
data_rdy = 0;
clr_baud = 0;
case(state)

IDLE : begin
       if(rx_fall) begin
        next_state = START;
        clr_rcv = 1;
       end
       else
        next_state = IDLE;
       end
START : begin
        baud_count_en = 1;
        if(bit_half_count) begin
        next_state = RCV;
        clr_baud = 1;
        end
        else 
        next_state = START;
        end

RCV : begin
      baud_count_en = 1;
      count_en = bit_count_en;
      if(~bit_count[3])   //counting to 10 including the stop and the start bits
        next_state = RCV;
      else begin
        clr_baud = 1;
        next_state = STOP;
      end
      end
        

STOP : begin
        baud_count_en = 1;
        if(bit_count_en) begin
         next_state = IDLE;
         clr_baud = 1;
         data_rdy = 1;
        end
        else
         next_state = STOP;
        end
        

default : next_state =IDLE;

endcase

end

endmodule




