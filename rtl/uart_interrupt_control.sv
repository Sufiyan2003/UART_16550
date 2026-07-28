/*------------------------------------------------------------------------------
-- Author: Muhammad Sufiyan Sadiq 
-- Date: 27_07_2026
-- Description: This is to generate the interrupt signal and send its output
-- to the csr block to write into the ISR register
-- 
------------------------------------------------------------------------------*/

module uart_interrupt_control (
	input clk,    // Clock
	input resetn,
	// to generate Receiver line status
	input i_frame_err,
	input i_parity_err,
	input i_data_ready,
	input i_reception_timeout,
	input i_thr_empty,
	input [3:0] i_modem_status_change,
	input i_dma_end_of_reception,
	input i_dma_end_of_transmission,
	output [3:0] interrupt_code
	// to generate received data ready

);


	logic [7:0] isr_val;

	logic dma_tx_end;
	logic dma_rx_end;
	logic [2:0] intr_id_code;
	logic intr_stat;
	
	logic modem_st_change;
	logic [3:0] modem_st_q;

	typedef enum logic [3:0] {
		NO_INTERRUPT			= 4'b0001,
		RECEIVER_LINE_STATUS 	= 4'b0110, 
		RECEIVER_DATA_READY 	= 4'b0100, 
		RECEPTION_TIMEOUT 		= 4'b1100, 
		TRANSMITTER_EMPTY 		= 4'b0010, 
		MODEM_STATUS 			= 4'b0000, 
		DMA_RECEPTION_END 		= 4'b1110, 
		DMA_TRANSMISSION_END	= 4'b1010
	} interrupt_stat_code_e;
	
	interrupt_stat_code_e interrupt;

	// this is to set the interrupt status
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			intr_stat <= 1'b1;
			intr_id_code <= '0;
			interrupt <= NO_INTERRUPT;
		end else begin
			// write logic for each type of interrupt
			// simple if else statement to determinethe interrupt identification code
			if(i_frame_err || i_parity_err) 	interrupt = RECEIVER_LINE_STATUS;
			else if(i_data_ready)           	interrupt = RECEIVER_DATA_READY;
			else if(i_reception_timeout)    	interrupt = RECEPTION_TIMEOUT;
			else if(i_thr_empty)            	interrupt = TRANSMITTER_EMPTY;
			else if(modem_st_change) 			interrupt = MODEM_STATUS;
			else if(i_dma_end_of_reception) 	interrupt = DMA_RECEPTION_END;
			else if(i_dma_end_of_transmission) 	interrupt = DMA_TRANSMISSION_END;
			else 								interrupt = NO_INTERRUPT;
		end
	end

	// to determine change in modem status
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			modem_st_change <= 0;
			modem_st_q <= i_modem_status_change;
		end else begin
			 if(modem_st_q != i_modem_status_change) 	modem_st_change <= 1'b1;
			 else 										modem_st_change <= 1'b0;
		end
	end

	assign interrupt_code = interrupt;

endmodule : uart_interrupt_control