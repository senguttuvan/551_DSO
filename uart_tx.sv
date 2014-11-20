module uart_tx(TX, trmt, tx_data, rst_n, clk, tx_done);

input trmt, clk, rst_n;
input [7:0] tx_data;
output TX;
output reg tx_done;

typedef enum reg[1:0] {IDLE, START, XMIT} state_t;

state_t next_state, state;

reg [3:0] bit_count;
reg [5:0] baud_count;
reg [7:0] command_tx;
wire count_en, tx_start_bit;
wire [7:0] shift_tx;

assign count_en = tx_done ? 0 : ((baud_count==6'd43) ? 1 : 0);
assign shift_tx = (state == IDLE | (state==START)) ? tx_data : (count_en ? {1, command_tx[7:1]} :command_tx);
assign TX = (state==IDLE) ? 1 : (state==START) ? tx_start_bit : command_tx[0];
assign tx_start_bit = (~tx_done) ? 0 : 1;
assign tx_done_bit = bit_count[3] & bit_count[1] & ~trmt;


always @(posedge clk, negedge rst_n) begin
if(!rst_n)
tx_done <= 0;
else if(bit_count[3] & bit_count[1] & ~trmt)
tx_done <= 1;
else if(trmt)
tx_done <= 0;
end

always @(posedge clk, negedge rst_n) begin
if(!rst_n)
state <= IDLE;
else
state <= next_state;
end

always @(posedge clk, negedge rst_n) begin    //For the baud count of 43 cycles
if(!rst_n)
baud_count <= 6'h00;
else if(~count_en & ~tx_done)
baud_count <= baud_count + 1;
else 
baud_count <= 0;
end
  
always @(posedge clk, negedge rst_n) begin    //For the no of bits transmitted
if(!rst_n) 
bit_count <= 4'h0;
else if(count_en)
bit_count <= bit_count + 1;
else if(tx_done)
bit_count <= 4'h0;
end

always @(posedge clk, negedge rst_n) begin
if(!rst_n)
command_tx <= 8'hff;
else
command_tx <= shift_tx;
end



always @(state, trmt, tx_done, count_en) begin
next_state = IDLE;    //Default value

case(state)
IDLE : begin
       if(trmt)
       next_state = START;
       else next_state=IDLE;
       end

START : begin
        if(!tx_done & count_en)
           next_state = XMIT;
        else if(tx_done)
           next_state = IDLE;
        else 
           next_state = START;
        end
  
XMIT : begin
       if(tx_done)
         next_state = START;
       else
         next_state = XMIT;
       end
default : next_state = IDLE;

endcase

end

endmodule


