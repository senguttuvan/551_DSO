module trig (clk,rst_n,trigSrc,trigEdge,armed,trig_en,set_capture_done,trigger1,trigger2,triggered);
input clk,rst_n,trig_en,armed,trigEdge,set_capture_done,trigSrc,trigger1,trigger2;
output reg triggered;
wire trig2;
wire trig1;

reg q1_trigger, q2_trigger, q3_trigger;

wire trigger_sel_out, pos_edge, neg_edge, trig_set;

assign trigger_sel_out = trigSrc ? trigger2 : trigger1;
assign pos_edge = q2_trigger & ~q3_trigger;
assign neg_edge = ~q2_trigger & q3_trigger;
assign trig_set = trigEdge ? pos_edge : neg_edge;

always_ff @(posedge clk, negedge rst_n) begin
if(~rst_n)
q1_trigger <= 0;
else 
q1_trigger <= trigger_sel_out;
end

always_ff @(posedge clk, negedge rst_n) begin
if(~rst_n)
q2_trigger <= 0;
else
q2_trigger <= q1_trigger;
end

always_ff @(posedge clk, negedge rst_n) begin
if(~rst_n)
q3_trigger <= 0;
else
q3_trigger <= q2_trigger;
end

always_ff@(posedge clk or negedge rst_n)
if(!rst_n)
triggered<=0;
else
triggered<=trig2;

assign trig1=(trig_set&&armed&&trig_en)?1:triggered;
assign trig2=(set_capture_done)?0:trig1;

endmodule


module trigger_tb();

reg clk,rst_n,trig_en,armed,trigEdge,set_capture_done,trigSrc,trigger1,trigger2;
wire triggered;

trig DUT (clk,rst_n,trigSrc,trigEdge,armed,trig_en,set_capture_done,trigger1,trigger2,triggered);

initial begin
clk = 0;
forever #5 clk=~clk;
end

initial begin
@(posedge clk) rst_n=1'b0; trigSrc = 1 ; trigEdge = 1 ;armed = 0 ; set_capture_done = 0; trigger2 = 0; trigger1 = 0; trig_en = 1;


@(posedge clk) rst_n=1'b1;
	armed = 1;
#25;

@(posedge clk) trigger2 = 1;

#200;
$stop;
end

initial
	$monitor (" %b t1 : %b t2 : %b t3 : %b \n", triggered , DUT.q1_trigger , DUT.q2_trigger , DUT.q3_trigger);
endmodule
