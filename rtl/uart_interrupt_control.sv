/*------------------------------------------------------------------------------
-- Author: Muhammad Sufiyan Sadiq 
-- Date: 27_07_2026
-- Description: This is to generate the interrupt signal and send its output
-- to the csr block to write into the ISR register
-- 
------------------------------------------------------------------------------*/

module uart_interrupt_control (
	input clk,    // Clock
	input resetn
);


	logic [7:0] isr_val;

	logic fifos1_enabled;
	logic fifos2_enabled;
	logic dma_tx_end;
	logic dma_rx_end;
	logic [2:0] intr_id_code;
	logic intr_stat;

	typedef enum logic [2:0] {
		NO_INTERRUPT			= 3'b000,
		RECEIVER_LINE_STATUS 	= 3'b011, 
		RECEIVER_DATA_READY 	= 3'b010, 
		RECEPTION_TIMEOUT 		= 3'b110, 
		TRANSMITTER_EMPTY 		= 3'b001, 
		MODEM_STATUS 			= 3'b000, 
		DMA_RECEPTION_END 		= 3'b111, 
		DMA_TRANSMISSION_END	= 3'b101
	} interrupt_stat_code_e;
	
	interrupt_stat_code_e interrupt;

	// this is to set the interrupt status
	always_ff @(posedge clk or negedge resetn) begin : proc_
		if(~resetn) begin
			intr_stat <= 1'b1;
			intr_id_code <= '0;
			interrupt <= NO_INTERRUPT;
		end else begin
			// write logic for each type of interrupt
			intr_id_code <= '0;
		end
	end



	assign fifos1_enabled = 1'b1;
	assign fifos2_enabled = 1'b1;



endmodule : uart_interrupt_control