module SPI_slv(clk,rst_n,tx_data,SCLK,SS_n,MOSI,MISO,cmd_rcvd,cmd_rdy,rsp_rdy,eep_rd);

input clk,rst_n,SS_n,SCLK,MOSI,eep_rd;
input [15:0] tx_data;

output [15:0] cmd_rcvd;
output MISO;
output cmd_rdy,rsp_rdy;

typedef enum reg {IDLE,TX} state_t;
state_t state,nstate;

// shift register and buffer //
reg[15:0] shft_reg,buffer;

// flops for metastability //
reg SCLK_ff1,SCLK_ff2,SCLK_ff3,SS_n_ff1,SS_n_ff2;
reg MOSI_ff1,MOSI_ff2,MOSI_ff3;


// outputs of state machine are of type logic //
logic shft,ld,cmd_rdy,set_cmd_rdy,rsp_rdy;

wire negSCLK;

///////////////////////////////
// eep_rd is double buffered //
/////////////////////////////
always_ff @(posedge clk)
 if (eep_rd)
		buffer <= tx_data;


////////////////////////////////////
// Implement response ready flop //
//////////////////////////////////
always_ff @(posedge clk,negedge rst_n)
 if (!rst_n)
		rsp_rdy <= 0;
 else if (eep_rd)
		rsp_rdy <= 1;
 else if (ld)
		rsp_rdy <= 0;


/////////////////////////////////////
// create parallel shift register //
///////////////////////////////////
always_ff @(posedge clk)
	if(ld)
		shft_reg <= buffer;
  else if (shft)
		shft_reg <= {shft_reg[14:0],MOSI_ff3};

assign MISO = shft_reg[15];


///////////////////////////////////////////////////
// double-flop SCLK and SS_n for meta-stability //
/////////////////////////////////////////////////
always_ff @ (posedge clk, negedge rst_n)
 if (!rst_n)
		begin
			SCLK_ff1 <= 1'b0;
			SCLK_ff2 <= 1'b0;
			SCLK_ff3 <= 1'b0;
			SS_n_ff1 <= 1'b1;
			SS_n_ff2 <= 1'b1;
			MOSI_ff1 <= 1'b0;
			MOSI_ff2 <= 1'b0;
			MOSI_ff3 <= 1'b0;
		end
	else
		begin
			SCLK_ff1 <= SCLK;
			SCLK_ff2 <= SCLK_ff1;
			SCLK_ff3 <= SCLK_ff2;
			SS_n_ff1 <= SS_n;
			SS_n_ff2 <= SS_n_ff1;
			MOSI_ff1 <= MOSI;
			MOSI_ff2 <= MOSI_ff1;
			MOSI_ff3 <= MOSI_ff2;
		end

///////////////////////////////
// Implement State register //
/////////////////////////////

always_ff @(posedge clk, negedge rst_n)
 if (!rst_n)
		state <= IDLE;
 else
		state <= nstate;

///////////////////////////////////
// Implement cmd ready register //
/////////////////////////////////
always_ff @(posedge clk,negedge rst_n)
 if (!rst_n)
		cmd_rdy <= 0;
 else if (ld)
		cmd_rdy <= 0;
 else if (set_cmd_rdy)
		cmd_rdy <= 1;

//////////////////////////////
// Negative edge detection //
////////////////////////////
assign negSCLK = ~SCLK_ff2 && SCLK_ff3;

//////////////////////////////
// MOSI is stored in Slave //
////////////////////////////
assign cmd_rcvd = shft_reg;


///////////////////
// Implement SM //
/////////////////
always_comb
begin

	shft = 0;
	ld = 0;
	set_cmd_rdy = 0;

  case (state)
		
		IDLE : begin
			if (!SS_n_ff2)
			 begin
				nstate = TX;
				ld =1;
			 end
			else
				nstate = IDLE;
			end

		TX : begin
			shft = negSCLK & ~SS_n_ff2;
			if (SS_n_ff2)
				begin
					set_cmd_rdy = 1;
					nstate = IDLE;
				end
			else
					nstate = TX;
			end
	endcase
end


endmodule
