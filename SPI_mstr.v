`timescale 1ns/10ps

module SPI_mstr(clk,rst_n,SS_n,SCLK,wrt,done,data_out,MOSI);

input clk,rst_n,wrt;
input [15:0] data_out;			//command/data to slave
output SS_n,SCLK,done,MOSI;

typedef enum reg[1:0] {IDLE,BITS,TRAIL,WAIT_DONE} state_t;
state_t state,nstate;

reg [4:0] dec_cntr,bit_cntr;
reg [7:0] shft_reg;

logic done, SS_n, rst_cnt, en_cnt, shft;


always_ff @(posedge clk, negedge rst_n)
 if (!rst_n)
		state <= IDLE;
 else
		state <= nstate;

always_ff @(posedge clk, negedge rst_n)
 if(!rst_n)
		shft_reg <= 8'h00;
 else if(wrt)
		shft_reg <= {shft_reg[6:0],1'b0};
		
assign MOSI = shft_reg[7];

always_ff @(posedge clk)
	if (rst_cnt)
		bit_cntr <= 5'b00000;
	else if(en_cnt)
		bit_cntr <= bit_cntr + 1;

always_ff @(posedge clk)
	if(rst_cnt)
		dec_cntr <= 5'b01100;
	else
		dec_cntr <= dec_cntr + 1;

assign SCLK = dec_cntr[4];

always_comb
begin
		rst_cnt = 0;
		en_cnt = 0;
		shft = 0;
		done = 1;
		nstate = IDLE;

  case (state)
		
		IDLE : begin
			rst_cnt = 1;
			if (wrt)
				nstate = BITS;
			else
				nstate = IDLE;
			end
		
		BITS : begin
			done = 0;
			SS_n = 0;
			en_cnt = &dec_cntr;
			shft = en_cnt;
			if (bit_cntr == 5'h10)
				nstate = TRIAL;
			else
				nstate = BITS;
		end

		TRAIL : begin
			done = 0;
			SS_n = 0;
			if (&dec_cntr[3:1])
				nstate = WAIT_DONE;
			else
				nstate = TRAIL;
		end
		
		WAIT_DONE : begin
			done = 0;
			if (&dec_cntr)
				nstate = IDLE;
			else
				nstate = WAIT_DONE;
			end
	endcase
end

endmodule
