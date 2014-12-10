
module capture(clk, rclk, rst_n, triggered, trig_cfg, trig_en, trig_pos, decimator_reg, capture_done, armed, trace_end, 
								clr_capture_done, we , en, addr);

input clk, rst_n, triggered, rclk, clr_capture_done;
output trig_en;
output reg capture_done, armed, we , en;
output reg [8:0] trace_end;
input [8:0] trig_pos;
input [7:0] trig_cfg;
input [3:0] decimator_reg;

localparam WAIT_TRG = 2'b00;
localparam SAMP1 = 2'b01;
localparam SAMP2 = 2'b10;

reg [1:0] state, next_state;
wire [15:0] dec_pwr;
reg [15:0] dec_cnt;
reg [8:0] smpl_cnt, trig_cnt;
wire [9:0] armed_cnt;        //Sum of smpl_cnt and trig_pos
wire keep;
reg keep_ff, clr_dec_cnt, inc_dec_cnt, clr_trig_cnt, inc_trig_cnt, clr_addr, inc_addr, inc_smpl_cnt, clr_smpl_cnt, clr_armed;
output reg [8:0] addr;


assign trig_src = trig_cfg[1:0];
assign dec_pwr = 1<<decimator_reg;
assign keep = (dec_cnt == dec_pwr) ? 1 : 0;
assign autoroll = trig_cfg[3] & ~trig_cfg[2];
assign norm_trig = ~trig_cfg[3] & trig_cfg[2];
assign trig_en = autoroll | norm_trig;
assign armed_cnt = smpl_cnt + trig_pos;
assign done = (trig_cnt == trig_pos) ? 1 : 0;

always @(posedge clk, negedge rst_n) begin
if(~rst_n)
smpl_cnt <= 9'h000;
else if(clr_smpl_cnt)
smpl_cnt <= 9'h000;
else if(inc_smpl_cnt)
smpl_cnt <= smpl_cnt + 1;
end

always @(posedge clk, negedge rst_n) begin
if(~rst_n)
addr <= 9'h000;
else if(clr_addr)
addr <= 9'h000;
else if (inc_addr)
addr <= addr + 1;
end

always @(posedge clk, negedge rst_n) begin
if(~rst_n)
capture_done <= 0;
else if(clr_capture_done)
capture_done <= 0;
else if(done)
capture_done <= 1;
end

always @(posedge clk, negedge rst_n) begin
if(~rst_n)
keep_ff <= 0;
else
keep_ff <= keep;
end

always @(posedge clk, negedge rst_n) begin
if(~rst_n)
armed <= 0;
else if(clr_armed)
armed <= 0;
else if(armed_cnt == 10'h100)
armed <= 1;
end

always @(posedge clk, negedge rst_n) begin
if(~rst_n)
dec_cnt <= 16'h0000;
else if (clr_dec_cnt)
dec_cnt <= 16'h0000;
else if (inc_dec_cnt)
dec_cnt <= dec_cnt + 1;
end

always @(posedge clk, negedge rst_n) begin
if(~rst_n)
trig_cnt <= 9'h000;
else if(clr_trig_cnt)
trig_cnt <= 9'h000;
else if(inc_trig_cnt)
trig_cnt <= trig_cnt + 1;
end

always @(posedge clk, negedge rst_n) begin
if(~rst_n)
state <= WAIT_TRG;
else
state <= next_state;
end

always @(triggered, done, autoroll, norm_trig, keep) begin

next_state=WAIT_TRG;
trace_end = 0;
clr_dec_cnt = 0;
clr_trig_cnt = 0;
clr_armed = 0;
clr_smpl_cnt = 0;
inc_dec_cnt = 0;
inc_trig_cnt = 0;
inc_smpl_cnt = 0;
inc_addr = 0;
en = 0;
we = 0;

case(state)
WAIT_TRG: begin
         if(trig_en & ~rclk & ~capture_done) begin
           clr_dec_cnt = 1;
           clr_trig_cnt = 1;
           clr_smpl_cnt = 1;
           next_state = SAMP1;
         end
          else
           next_state = WAIT_TRG;
          end
SAMP1 : begin
        we = keep_ff;
        en = keep_ff;
        inc_dec_cnt = 1;
        inc_addr = keep_ff;
        next_state = SAMP2;
        end

SAMP2 : begin
        if (done) begin
        trace_end = addr;
        clr_armed =1;
        next_state = WAIT_TRG;
        end
        else if(triggered) begin
        we = keep;
        en = keep;
        inc_trig_cnt = (norm_trig &triggered | autoroll & armed)&keep;
        clr_dec_cnt = keep; 
        next_state = SAMP1;
        end
        else  begin
        inc_smpl_cnt = 1;
        next_state = SAMP1;
        end
        end
default : next_state = WAIT_TRG;

endcase
end


endmodule
        
        

