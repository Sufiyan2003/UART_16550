/*------------------------------------------------------------------------------
--  Author: Muhammad Sufiyan Sadiq
--	Date: 19_07_2026
--	Description: This is the tx control block, used to transmit a UART frame
------------------------------------------------------------------------------*/


module uart_tx_ctrl (
	input clk,    // Clock/ Asynchronous reset active low
	input resetn,
	input [15:0] BR,
	input [1:0] i_data_bits,
	input i_parity_en,
	input i_stop_bits,
	input i_even_parity,
	input thr_valid,
	output logic [2:0] o_mux_sel,
	output logic tx_shift_reg,
	output logic thr_empty, // to let csrs know that the thr register is empty
	output logic thr_write,
	output logic tx_ready // shift register ready to accept data from thr csr
);


	logic [15:0] tx_counter;
	logic start_tx_counter;
	logic [3:0] data_lim;
	logic clear_tx_counter;
	logic tx_d;
	logic tx_parity;


	typedef enum  {IDLE, START, DATA, PARITY, STOP} uart_st;
	
	uart_st tx_state, tx_state_nxt;

	logic [3:0] sent_data_bits;
	logic sent_stop_bits;

	/*------------------------------------------------------------------------------
	--  						State transitions
	------------------------------------------------------------------------------*/
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			tx_state <= IDLE;
		end else begin
			tx_state <= tx_state_nxt;
		end
	end

	// combinational logic to manage next state value
	always_comb begin
		tx_state_nxt = tx_state;
		clear_tx_counter = '0;
		tx_ready = '0;
		o_mux_sel = '0;
		case(tx_state)
			// IDLE -> START when there is something in THR to send
			IDLE: begin
				o_mux_sel = '0;
				if(thr_valid) begin
					tx_ready = 1'b1;
					tx_state_nxt = START;
				end
				else begin
					// do nothing wait for something to be loaded in THR
					tx_state_nxt = IDLE;
				end
			end
			START: begin
				o_mux_sel = 3'b001;
				if(tx_counter == (BR -1)) begin
					tx_state_nxt = DATA;
					clear_tx_counter = 1'b1;
				end
				else begin
					tx_state_nxt = START;
				end
			end
			DATA: begin
				o_mux_sel = 3'b010;
				clear_tx_counter = 1'b0;
				tx_state_nxt = DATA;
				if(tx_counter == BR-1) begin
					clear_tx_counter = 1'b1;
					if(sent_data_bits == (data_lim-1)) begin
						if(i_parity_en) tx_state_nxt = PARITY;
						else 			tx_state_nxt = STOP;
					end
					else begin
						tx_state_nxt = DATA;
					end
				end
			end
			PARITY: begin
				o_mux_sel = 3'b011;
				if(tx_counter == BR-1) begin	
					clear_tx_counter = 1'b1;
					tx_state_nxt = STOP;
				end
				else begin		
					clear_tx_counter = 1'b0;
					tx_state_nxt = PARITY; 
				end
			end
			STOP: begin
				o_mux_sel = 3'b100;
				if(tx_counter == BR-1) begin
					clear_tx_counter = 1'b1;
					if(sent_stop_bits == i_stop_bits) 	tx_state_nxt = IDLE;
					else 								tx_state_nxt = STOP;
				end
				else clear_tx_counter = 1'b0;
			end
		endcase

	end

	// to track emptiness of the thr register
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			thr_empty <= 0;
		end else begin
			if(tx_state==IDLE && tx_state_nxt==IDLE) thr_empty <= 1'b1;
			else 									 thr_empty <= 1'b0;
		end
	end

	// block to generate write to thr_empty flag
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			thr_write <= 0;
		end else begin
			// toggle bit when a byte is unloaded from thr (STOP -> IDLE)
			if(tx_state == STOP && tx_state_nxt==IDLE) thr_write = 1'b1;
			// toggle bit when a byte is loaded to thr (IDLE -> START)
			else if(tx_state == IDLE && tx_state_nxt == START) thr_write = 1'b1;
			else thr_write = 1'b0;
		end
	end




	/*------------------------------------------------------------------------------
	--  						Date bits to send
	------------------------------------------------------------------------------*/
	always_comb begin
		case(i_data_bits)
			2'b00: data_lim = 4'b0101;
			2'b01: data_lim = 4'b0110;
			2'b10: data_lim = 4'b0111;
			2'b11: data_lim = 4'b1000;
		endcase
	end


	/*------------------------------------------------------------------------------
	--  				Managing data bits and stop bits
	------------------------------------------------------------------------------*/

	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			sent_data_bits <= 0;
		end else begin
			if(tx_state != DATA && tx_state_nxt == DATA)
				sent_data_bits <= 0;
			else if(tx_state == DATA && tx_counter == BR-1)
				sent_data_bits <= sent_data_bits + 1'b1;
			else
				sent_data_bits <= sent_data_bits;
		end
	end

	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			sent_stop_bits <= 0;
		end else begin
			if(tx_state != STOP && tx_state_nxt == STOP)
				sent_stop_bits <= 0;
			else if(tx_state == STOP && tx_counter == BR-1)
				sent_stop_bits <= sent_stop_bits + 1'b1;
			else 
				sent_stop_bits <= sent_stop_bits;
		end
	end


	/*------------------------------------------------------------------------------
	--  				Baud rate counter management
	------------------------------------------------------------------------------*/
	always_ff @(posedge clk or negedge resetn) begin : proc_
		if(~resetn) begin
			tx_counter <= 0;
		end else begin
			if(clear_tx_counter) tx_counter <= '0;
			else if(tx_state != IDLE) tx_counter <= tx_counter + 1'b1;
			else tx_counter <= '0;
		end
	end


	/*------------------------------------------------------------------------------
	--  				Shift external tx shift register
	------------------------------------------------------------------------------*/
	always_comb begin
		tx_shift_reg = 1'b0;
		if(tx_state == DATA && tx_counter == BR-1) 	tx_shift_reg = 1'b1;
		else 										tx_shift_reg = 1'b0;
	end


	// NOTE: parity will be generated in O(1) when THR is loaded then it is sent





endmodule : uart_tx_ctrl







