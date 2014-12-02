module uart_comm_mstr(clk, rst_n, tx_done, cmd_rdy, tx_data, cmd, TX, RX, clr_cmd_rdy, trmt );

 input [7:0] tx_data;
 output [23:0] cmd;
 input clk, rst_n, RX, clr_cmd_rdy, trmt;
 output tx_done, cmd_rdy, TX;

 uart_tx TX_DUT(.clk(clk), .rst_n(rst_n), .tx_done(tx_done), .trmt(trmt), .TX(TX), .tx_data(tx_data));

 uart_comm RX_COMM_DUT(.clk(clk), .rst_n(rst_n), .RX(RX), .clr_cmd_rdy(clr_cmd_rdy), .cmd_rdy(cmd_rdy), .cmd(cmd));

endmodule
