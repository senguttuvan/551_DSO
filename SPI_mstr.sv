module SPI_mstr(clk,rst_n,SS_n,SCLK,wrt,done,data_out,MOSI,MISO,data_in);

input clk,rst_n,wrt;
input [15:0] data_out;			//command/data to slave
input MISO;
output SS_n,SCLK,done,MOSI;
output [15:0] data_in;

typedef enum reg[1:0] {IDLE,BITS,TRAIL,WAIT_DONE} state_t;
state_t state,nstate;

reg [4:0] dec_cntr,bit_cntr;
reg [15:0] shft_reg;
reg MISO_ff1,MISO_ff2;

logic done, SS_n, rst_cnt, en_cnt, shft;

///////////////////////////////
// Implement State register //
/////////////////////////////

always_ff @(posedge clk, negedge rst_n)
 if (!rst_n)
		state <= IDLE;
 else
		state <= nstate;


/////////////////////////////////////////
// Implement parallel to serial shift //
///////////////////////////////////////

always_ff @(posedge clk, negedge rst_n)
 if(!rst_n)
		shft_reg <= 16'h0000;
 else if(wrt)
		shft_reg <= data_out;
 else if(shft)
		shft_reg <= {shft_reg[14:0],MISO_ff2};
		

assign MOSI = shft_reg[15];


///////////////////////////////
// MISO is stored in Master //
/////////////////////////////

assign data_in = shft_reg;

////////////////////////////
// Implement bit counter //
//////////////////////////

always_ff @(posedge clk)
	if (rst_cnt)
		bit_cntr <= 5'b00000;
	else if(en_cnt)
		bit_cntr <= bit_cntr + 1;

/////////////////////////////
// Implement SCLK counter //
///////////////////////////

always_ff @(posedge clk)
	if(rst_cnt)
		dec_cntr <= 5'b01100;
	else
		dec_cntr <= dec_cntr + 1;

assign SCLK = dec_cntr[4];	// 1: 32 of clk

//////////////////////////////////////////
// double-flop MISO for meta-stability //
////////////////////////////////////////
always_ff @ (posedge clk, negedge rst_n)
 if (!rst_n)
		begin
			MISO_ff1 <= 1'b0;
			MISO_ff2 <= 1'b0;
		end
	else
		begin
			MISO_ff1 <= MISO;
			MISO_ff2 <= MISO_ff1;
		end


///////////////////
// Implement SM //
/////////////////
always_comb
begin
		rst_cnt = 0;
		en_cnt = 0;
		shft = 0;
		done = 1;
		nstate = IDLE;

  case (state)
		
		IDLE : begin
			SS_n = 1;
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
				nstate = TRAIL;
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
			SS_n = 1;
			if (&dec_cntr)
				nstate = IDLE;
			else
				nstate = WAIT_DONE;
			end
	endcase
end

endmodule
