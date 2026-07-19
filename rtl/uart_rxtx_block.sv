/*------------------------------------------------------------------------------
-- Name: Muhammad Sufiyan Sadiq 
-- Date: 18_07_2026
-- Description: This contains the rxtx control and the shift registers which 
-- 
------------------------------------------------------------------------------*/

module uart_rxtx_block (
	input clk,
	input resetn,
	input rxd,
	output txd,
	input [7:0] thr_val,
	input [7:0] lcr_val,
	input [15:0] BR,
	output [7:0] rhr_val,
	output load_rx_reg
);

	logic rx_shift_reg;
	logic rx_parity; // to calculate parity of received data

	shift_register receive_register
	(
		.clk			(clk),
		.resetn			(resetn),
		.din			(rxd),
		.parallel_in  	('0),
		.parallel_load	('0),
		.wr_en			(rx_shift_reg),// this comes to enable regular shift
		.dout			(rhr_val),
		.shift_out		() 			// needed for tx reg only
	);



	shift_register transmit_register(
		.clk      		(clk),
		.resetn   		(resetn),
		.din      		('0),
		.dout     		(),
		.wr_en    		(), // comes from tx_controller 
		.parallel_in  	(thr_val), // 
		.parallel_load	(), // comes from tx controller
		.shift_out    	(txd)

	);


	/*------------------------------------------------------------------------------
	--  UART rx controller
	------------------------------------------------------------------------------*/
	uart_rx_ctrl uart_rx_control
	(
		.clk         (clk),
		.resetn      (resetn),
		.rxd         (rxd),
		.i_data_bits (lcr_val[1:0]),
		.i_parity_en (lcr_val[3]),
		.i_stop_bits (lcr_val[2]),
		.i_even_parity(lcr_val[4]),
		.BR          (BR),
		.load_rx_reg  (load_rx_reg),
		.rx_shift_reg(rx_shift_reg),
		.tx_shift_reg(),
		.tx_load     ()
	);
	



	




endmodule : uart_rxtx_block

