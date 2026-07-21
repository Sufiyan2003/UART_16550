/**
	Name: Muhammad Sufiyan Sadiq
	Date: 10_07_2026
	Description: This is the uart16650_core accordin to the datasheet
*/


module uart_16550_core (
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
	
	logic io_read, io_write;
	logic [15:0] o_DL;
	logic [7:0] lcr_val;
	logic [7:0] rhr_val;
	logic [7:0] thr_val;
	logic load_rhr;
	logic tx_ready;
	logic thr_valid;
	logic o_frame_err;
	logic o_parity_err;
	logic thr_empty;
	
	assign io_write = iow && ~iow_n;
	assign io_read  = ior && ~ior_n;


	/*------------------------------------------------------------------------------
	--  					UART control block
	------------------------------------------------------------------------------*/

	// TODO: rhr value can also come from a rx fifo if it is enabled
	// need to add define with seperate routing in that case
	ip_control_block uart_ctrl(
		.clk     (clk),
		.resetn  (resetn),
		.data_in (data_in),
		.add     (add),
		.cs1     (cs1),
		.cs2     (cs2),
		.cs_n    (cs_n),
		.ior     (io_read),
		.iow     (io_write),
		.data_out(data_out),
		.outen   (outen),
		.irq     (irq),
		.irq_n   (irq_n),
		.o_DL    (o_DL),
		.lcr_out (lcr_val),
		.load_rhr(load_rhr),
		.RHR_IN  (rhr_val),
		.tx_ready (tx_ready),
		.thr_valid(thr_valid),
		.thr_out  (thr_val),
		// LSR flags
		.i_fifo_err				(),
		.i_transmit_empty		(),
		.i_thr_empty			(thr_empty),
		.i_thr_write			(thr_write),
		.i_break_intr			(),
		.i_framing_err			(o_frame_err),
		.i_parity_err			(o_parity_err),
		.i_overrun_err			(),
		.i_data_ready			(load_rhr),
		// MSR flags
		.i_CD					(),
		.i_RI					(),
		.i_DSR					(),
		.i_CTS					(),
		.i_delta_CD				(),
		.i_trailing_edge_RI		(),
		.i_delta_DSR			(),
		.i_delta_CTS			(),
		// ISR flags
		.i_fifos_en1			(),
		.i_fifos_en2			(),
		.i_dma_tx_end			(),
		.i_dma_rx_end			(),
		.i_intrp_id				(),
		.i_intr_stat			()
	);
	

	uart_rxtx_block uart_rxtx_blk(
		.clk        	(clk),
		.resetn     	(resetn),
		.lcr_val    	(lcr_val),
		.rxd        	(rxd),
		.thr_val    	(thr_val),
		.BR         	(o_DL),
		.rhr_val		(rhr_val),
		.load_rx_reg	(load_rhr),
		.tx_ready   	(tx_ready),
		.thr_valid  	(thr_valid),
		.thr_write   	(thr_write),
		.o_frame_err	(o_frame_err),
		.thr_empty   	(thr_empty),
		.o_parity_err	(o_parity_err)
	);


endmodule