/**
	Name: Muhammad Sufiyan Sadiq
	Date: 10_07_2026
	Description: This is the uart16650_core accordin to the datasheet
*/

`include "uart_params.svh"
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
	uart_interface.rx uart_if 		,
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
	logic [7:0] isr_val;
	logic [7:0] fcr_val;
	logic load_rhr;
	logic load_rhr_reg;
	logic tx_ready;
	logic thr_valid;
	logic o_frame_err;
	logic o_parity_err;
	logic thr_empty;
	logic sel_fifo;	
	logic [7:0] reg_thr_val;
	logic reg_thr_valid;
	logic reg_frame_err;
	logic reg_parity_err;
	logic tx_load_fifo;

	assign io_write = iow && ~iow_n;
	assign io_read  = ior && ~ior_n;

	logic rx_fifo_frame_err;
	logic rx_fifo_parity_err;

	assign rx_fifo_frame_err 	= uart_if.fifo_rx_out[9];
	assign rx_fifo_parity_err 	= uart_if.fifo_rx_out[8];
	/*------------------------------------------------------------------------------
	--  					UART control block
	------------------------------------------------------------------------------*/

	// TODO: rhr value can also come from a rx fifo if it is enabled
	// need to add define with seperate routing in that case
	ip_control_block uart_ctrl(
		.clk     				(clk),
		.resetn  				(resetn),
		.data_in 				(data_in),
		.add     				(add),
		.cs1     				(cs1),
		.cs2     				(cs2),
		.cs_n    				(cs_n),
		.ior     				(io_read),
		.iow     				(io_write),
		.data_out				(data_out),
		.outen   				(outen),
		.irq     				(irq),
		.irq_n   				(irq_n),
		.o_DL    				(o_DL),
		.lcr_out 				(lcr_val),
		.load_rhr				(load_rhr_reg),
		.isr_out           		(isr_val),
		.RHR_IN  				(rhr_val),
		.fcr_out           		(fcr_val),
		.tx_ready 				(tx_ready),
		.thr_valid				(reg_thr_valid),
		.thr_out  				(reg_thr_val),
		.rx_fifo_in        		(uart_if.fifo_rx_out),
		.fifo_sel          		(sel_fifo),
		// LSR flags
		.i_fifo_err				(),
		.i_transmit_empty		(),
		.i_thr_empty			(thr_empty),
		.i_thr_write			(thr_write),
		.i_break_intr			(),
		.i_framing_err			(o_frame_err),
		.i_parity_err			(o_parity_err),
		.i_overrun_err			(),
		.i_data_ready			(load_rhr_reg),
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
	


	// framing errors might come from rxtx control or it can come from the fifo, rename it to act as an output of a mux
	uart_rxtx_block uart_rxtx_blk(
		.clk        	(clk),
		.resetn     	(resetn),
		.lcr_val    	(lcr_val),
		.rxd        	(rxd),
		.thr_val    	(thr_val),   // output from the mux
		.BR         	(o_DL),
		.rhr_val		(rhr_val),
		.load_rx_reg	(load_rhr),
		.tx_ready   	(tx_ready),
		.thr_valid  	(thr_valid), // this will come from the output of a mux
		.thr_write   	(thr_write),
		.o_frame_err	(reg_frame_err),
		.thr_empty   	(thr_empty),
		.o_parity_err	(reg_parity_err)
	);


	// need to write and encorder so that when in fifo mode
	// the register doesnt get loaded and instead the fifo write is enabled

	always_comb begin
		// means fifos are actually present 
		if(fcr_val[0]) 			sel_fifo = 1'b1;
		else  					sel_fifo = 1'b0;
	end

	// block to assign load_rhr to valid destination
	// load rhr fifo is basically fifo_rx_push
	always_comb begin
		if(sel_fifo) begin
			uart_if.fifo_rx_push 	= load_rhr;
			// [BI, FE, PE, DATA] (Break indication ignored for now)
			uart_if.fifo_rx_in 		= {1'b0, rx_fifo_frame_err, rx_fifo_parity_err, rhr_val};
			// data in given to fifo_tx_in, write to occur via control block
			uart_if.fifo_tx_in 		= data_in;
			uart_if.fifo_tx_push 	= tx_load_fifo;
			load_rhr_reg 			= '0;
			o_frame_err				= rx_fifo_frame_err;
			o_parity_err 			= rx_fifo_parity_err;
			thr_val 				= uart_if.fifo_tx_out;
			thr_valid 				= ~uart_if.fifo_tx_empty;
			uart_if.fifo_tx_pop 	= ~uart_if.fifo_tx_empty && tx_ready; 
		end
		else begin
			load_rhr_reg 			= load_rhr;
			uart_if.fifo_rx_push 	= 0;
			uart_if.fifo_tx_in 		= '0;
			o_frame_err 			= reg_frame_err;
			o_parity_err 			= reg_parity_err;
			thr_val 				= reg_thr_val;
			thr_valid 				= reg_thr_valid;
		end
	
	end

	// pop from the fifo
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
	 		uart_if.fifo_rx_pop <= 0;
		end else begin
			// if fifos are enabled by the user
	 		if(io_read && (add == RHR_REGISTER) && fcr_val[0]) 	uart_if.fifo_rx_pop <= 1'b1;
	 		else 												uart_if.fifo_rx_pop <= 1'b0;
		end
	end

	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			tx_load_fifo <= 0;
		end else begin
			if(add == THR_REGISTER && fcr_val[0] && (~lcr_val[7]) && iow) 	tx_load_fifo <= 1'b1;
			else 															tx_load_fifo <= 1'b0;			
		end
	end


endmodule