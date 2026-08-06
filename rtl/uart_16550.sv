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
	logic chip_select;

	logic rxd_q;
	logic [7:0] mcr_val;
	logic [7:0] fcr_val;
	logic [3:0] rcvr_count;
	logic [3:0] data_bytes_rcvd;
	logic [3:0] num_err_entries;

	logic push_with_err, pop_with_err;
	// uart connection with the internal fifos
	uart_interface uart_if(clk, resetn);

	// instantiate the uart_16550 core
	uart_16550_core uart_core(
		.clk					(clk),
		.resetn					(resetn),
		.data_in				(data_in),
		.chip_select			(chip_select),
		.ior 					(ior),
		.ior_n					(ior_n),
		.iow 					(iow),
		.iow_n					(iow_n),
		.add					(add),
		.dma_rxend 				(dma_rxend),
		.dma_txend				(dma_txend),
		.cts_n					(cts_n),
		.dsr_n					(dsr_n),
		.ri_n					(ri_n),
		.cd_n					(cd_n),
		.rxd					(rxd_q),
		.uart_if 				(uart_if),
		.data_out				(data_out),
		.outen					(outen),
		.irq 					(irq),
		.irq_n					(irq_n),
		.rxrdy 					(rxrdy),
		.rxrdy_n				(rxrdy_n),
		.txrdy 					(txrdy),
		.txrdy_n				(txrdy_n),
		.rts_n					(rts_n),
		.dtr_n					(dtr_n),
		.out1_n					(out1_n),
		.out2_n					(out2_n),
		.mcr_val 				(mcr_val),
		.fcr_val  				(fcr_val),
		.txd 					(txd)
	);


	/*------------------------------------------------------------------------------
	--  		Rx and Tx fifos connected with the fifo uart interface
	------------------------------------------------------------------------------*/

	always_comb begin
		case (fcr_val[7:6])
			2'b00: rcvr_count = 1;
			2'b01: rcvr_count = 4;
			2'b10: rcvr_count = 8;
			2'b11: rcvr_count = 14;
		endcase
	end

	always_comb begin
		if(data_bytes_rcvd >= rcvr_count) 	uart_if.fifo_rx_triggered = 1'b1;
		else 								uart_if.fifo_rx_triggered = 1'b0;
	end

	/*------------------------------------------------------------------------------
	--  				Detecting an error in rx fifo
	------------------------------------------------------------------------------*/
	
	`ifdef UART_GENERATE_BI
		// grab it from the top of the fifo
		always_ff @(posedge clk or negedge resetn) begin : proc_
			if(~resetn) begin
				num_err_entries <= 0;
			end else begin
				if(uart_if.fifo_rx_in[9] || uart_if.fifo_rx_in[8]) num_err_entries <= 1;
				else 											   num_err_entries <= '0;
			end
		end
	`else 
	assign push_with_err 	= uart_if.fifo_rx_push && !uart_if.fifo_rx_full && |uart_if.fifo_rx_in[10:8];
	assign pop_with_err 	= uart_if.fifo_rx_pop && !uart_if.fifo_rx_empty && |uart_if.fifo_rx_out[10:8];
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			num_err_entries <= '0;
		end else begin
			// on push high check whether that byte raised PE, FE or BI and or a one into it
			case ({push_with_err, pop_with_err})
				2'b10: num_err_entries <= num_err_entries + 1'b1;
				2'b01: num_err_entries <= num_err_entries - 1'b1;
				default : num_err_entries <= num_err_entries;
			endcase
		end
	end
	`endif


	// set the interface here, and the interface will then
	sync_fifo #(
		.DEPTH(16), 
		.DWIDTH(11)
	) RHR_fifo(
		.clk  				(clk)								,
		.rstn 				(resetn && ~uart_if.fifo_rx_reset)	,
		.wr_en				(uart_if.fifo_rx_push)				,
		.rd_en				(uart_if.fifo_rx_pop)				,
		.din  				(uart_if.fifo_rx_in)				,
		.dout 				(uart_if.fifo_rx_out)				,
		.empty				(uart_if.fifo_rx_empty)				,
		.full 				(uart_if.fifo_rx_full)				,
		.o_occupancy_count	(data_bytes_rcvd)
	);
	
	sync_fifo #(
		.DEPTH(16), 
		.DWIDTH(8)
	) THR_fifo(
		.clk  			(clk)								,
		.rstn 			(resetn && ~uart_if.fifo_tx_reset)	,
		.wr_en			(uart_if.fifo_tx_push)				,
		.rd_en			(uart_if.fifo_tx_pop)				,
		.din  			(uart_if.fifo_tx_in)				,
		.dout 			(uart_if.fifo_tx_out)				,
		.empty			(uart_if.fifo_tx_empty)				,
		.full 			(uart_if.fifo_tx_full)
	);



	// TODO: add the loopback block here
	always_comb begin
		if(mcr_val[4]) 	rxd_q = txd;
	else 			rxd_q = rxd;
	end


	assign chip_select = cs1 && cs2 && ~cs_n;


	assign uart_if.fifo_rx_trig_level 	= fcr_val[7:6]; 
	assign uart_if.fifo_rx_error 		= num_err_entries != 0;

endmodule



