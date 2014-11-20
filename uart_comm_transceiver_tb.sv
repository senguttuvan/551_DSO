module uart_comm_transceiver_tb();

reg clk, rst_n, clr_cmd_rdy, trmt;

wire TX, tx_done;

reg [7:0] tx_data;
wire [23:0] cmd;
wire cmd_rdy;

//self checking. RX wrapped back to RX
uart_comm_transceiver DUT(.clk(clk), .rst_n(rst_n), .tx_done(tx_done), .trmt(trmt), .TX(TX), .tx_data(tx_data), .RX(TX), .clr_cmd_rdy(clr_cmd_rdy), .cmd_rdy(cmd_rdy), .cmd(cmd));


initial begin
clk =0;
rst_n =0;
clr_cmd_rdy = 1;
repeat(20) @ (posedge clk);
@ (negedge clk);
rst_n =1;
clr_cmd_rdy = 0;
tx_data = 8'hca;
trmt = 1;
repeat(20) @ (posedge clk);
trmt =0;
repeat(600)@(posedge clk);

@(negedge clk) trmt = 1;
tx_data = 8'h7b;
repeat(20) @ (posedge clk);
trmt =0;
repeat(600)@(posedge clk);

@(negedge clk) trmt = 1;
tx_data = 8'h67;
repeat(20) @ (posedge clk);
trmt =0;
repeat(600)@(posedge clk);


$display (" %h ", cmd);
$stop;
end

always #1 clk = ~clk;

endmodule

