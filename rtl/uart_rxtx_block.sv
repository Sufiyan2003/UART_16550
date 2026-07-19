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
	output logic txd,
	input [7:0] thr_val,
	input [7:0] lcr_val,
	input [15:0] BR,
	output [7:0] rhr_val,
	output load_rx_reg,
	output tx_ready,
	input thr_valid
);

	logic rx_shift_reg;
	logic tx_shift_reg;
	logic rx_parity; // to calculate parity of received data
	logic load_thr;


	// mux inputs
	logic parity_out; // calculated by combinational logic
	logic thr_shift_out;
	logic [2:0] mux_sel;

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
		.wr_en    		(tx_shift_reg), // comes from tx_controller 
		.parallel_in  	(thr_val), // 
		.parallel_load	(load_thr), // comes from tx controller
		.shift_out    	(thr_shift_out)

	);

	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			load_thr <= 0;
		end else begin
			if(tx_ready && thr_valid) 	load_thr <= 1'b1;
			else 						load_thr <= 1'b0;
		end
	end

	// TODO: add a mux to select between the stop bits (1) , the parity bit and the start bit (0)
	always_comb begin
		// if even parity
		if(lcr_val[4]) parity_out = ~(^thr_val);
		else 		   parity_out = ^thr_val;
	end

	// mux
	always_comb begin
		case (mux_sel)
			3'b000: txd = 1'b1;
			3'b001: txd = 1'b0;
			3'b010: txd = thr_shift_out;
			3'b011: txd = parity_out;
			3'b100: txd = 1'b1;
			default : txd = 1'b1;
		endcase
	end




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
		.rx_shift_reg(rx_shift_reg)
	);
	


	uart_tx_ctrl uart_tx_control(
		.clk          (clk),
		.resetn       (resetn),
		.BR           (BR),
		.i_even_parity(lcr_val[4]),
		.i_parity_en  (lcr_val[3]),
		.i_data_bits  (lcr_val[1:0]),
		.i_stop_bits  (lcr_val[2]),
		.thr_valid    (thr_valid),
		.tx_shift_reg (tx_shift_reg),
		.tx_ready     (tx_ready),
		.o_mux_sel	  (mux_sel)
	);
	




endmodule : uart_rxtx_block

