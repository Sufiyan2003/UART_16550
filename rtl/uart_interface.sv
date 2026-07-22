interface uart_interface (input clk, input resetn);
	logic 			fifo_implemented		;
	logic 			fifo_enable				;
	logic [10:0] 	fifo_rx_in				;
	logic [10:0] 	fifo_rx_out				;
	logic 			fifo_rx_push			;
	logic 			fifo_rx_pop				;
	logic 			fifo_rx_reset			;
	logic [1:0] 	fifo_rx_trig_level		;
	logic 			fifo_rx_empty			;
	logic 			fifo_rx_triggered		;
	logic 			fifo_rx_full			;
	logic 			fifo_rx_error			;
	logic [7:0] 	fifo_tx_in				;
	logic [7:0] 	fifo_tx_out				;
	logic 			fifo_tx_push			;
	logic 			fifo_tx_pop				;
	logic 			fifo_tx_reset			;
	logic 			fifo_tx_empty			;
	logic 			fifo_tx_full			;

	modport rx (
		input 	fifo_implemented			,
		output 	fifo_enable					,
		output 	fifo_rx_in					,
		input 	fifo_rx_out					,
		output 	fifo_rx_push				,
		output 	fifo_rx_pop					,
		output 	fifo_rx_reset				,
		output 	fifo_rx_trig_level			,
		input 	fifo_rx_empty				,
		input 	fifo_rx_triggered			,
		input 	fifo_rx_full				,
		input 	fifo_rx_error				,
		output 	fifo_tx_in					,
		input 	fifo_tx_out					,
		output 	fifo_tx_push				,
		output 	fifo_tx_pop					,
		output 	fifo_tx_reset				,
		input 	fifo_tx_empty				,
		input 	fifo_tx_full
	);
	
	modport tx (
		output 	fifo_implemented			,
		input 	fifo_enable					,
		input 	fifo_rx_in					,
		output 	fifo_rx_out					,
		input 	fifo_rx_push				,
		input 	fifo_rx_pop					,
		input 	fifo_rx_reset				,
		input 	fifo_rx_trig_level			,
		output 	fifo_rx_empty				,
		output 	fifo_rx_triggered			,
		output 	fifo_rx_full				,
		output 	fifo_rx_error				,
		input 	fifo_tx_in					,
		output 	fifo_tx_out					,
		input 	fifo_tx_push				,
		input 	fifo_tx_pop					,
		input 	fifo_tx_reset				,
		output 	fifo_tx_empty				,
		output 	fifo_tx_full
	);



endinterface