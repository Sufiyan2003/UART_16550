/*------------------------------------------------------------------------------
-- 	Author: Muhammad Sufiyan Sadiq
--	Date: 22_07_2026
--	Description: This is the uart_16650 top module and contains the core
--	and the rx tx fifos
------------------------------------------------------------------------------*/


module uart_16550 (
	input clk						,
	input resetn					,
	input [7:0] data_in				,
	input cs1						,
	input cs2						,
	input cs_n						,
	input ior,ior_n					,
	input iow,iow_n					,
	input [2:0] add					,
	input dma_rxend, dma_txend		,
	input cts_n						,
	input dsr_n						,
	input ri_n						,
	input cd_n						,
	input rxd						,
	output [7:0] data_out			,
	output outen					,
	output irq,irq_n				,
	output rxrdy, rxrdy_n			,
	output txrdy, txrdy_n			,
	output rts_n					,
	output dtr_n					,
	output out1_n					,
	output out2_n					,
	output txd
);


	// uart connection with the internal fifos
	uart_interface uart_if(clk, resetn);

	// instantiate the uart_16550 core
	uart_16550_core uart_core(
		.*
	);


	/*------------------------------------------------------------------------------
	--  		Rx and Tx fifos connected with the fifo uart interface
	------------------------------------------------------------------------------*/

	// set the interface here, and the interface will then
	sync_fifo #(
		.DEPTH(16), 
		.DWIDTH(8)
	) RHR_fifo(
		.clk  			(clk)						,
		.rstn 			(resetn)					,
		.wr_en			(uart_if.fifo_rx_push)		,
		.rd_en			(uart_if.fifo_rx_pop)		,
		.din  			(uart_if.fifo_rx_in)		,
		.dout 			(uart_if.fifo_rx_out)		,
		.empty			(uart_if.fifo_rx_empty)		,
		.full 			(uart_if.fifo_rx_full)
	);
	
	sync_fifo #(
		.DEPTH(16), 
		.DWIDTH(8)
	) THR_fifo(
		.clk  			(clk)						,
		.rstn 			(resetn)					,
		.wr_en			(uart_if.fifo_tx_push)		,
		.rd_en			(uart_if.fifo_tx_pop)		,
		.din  			(uart_if.fifo_tx_in)		,
		.dout 			(uart_if.fifo_tx_out)		,
		.empty			(uart_if.fifo_tx_empty)		,
		.full 			(uart_if.fifo_tx_full)
	);




















endmodule



