/*------------------------------------------------------------------------------
--	Name: Muhammad Sufiyan Sadiq  	
-- 	Date: 13_07_2026
--  Description: This is the rx controller responsible to sample into RHR from
--  rxd
------------------------------------------------------------------------------*/
module uart_rx_ctrl (
	input clk,
	input resetn,
	input rxd,
	input [15:0] BR,
	input i_data_bits,
	input i_parity_en,
	input i_stop_bits,
	output logic rx_shift_reg,
    output logic tx_shift_reg,
    output logic tx_load

	
);


	// maintaining an rx counter
	logic [15:0] rx_counter		;
	logic start_rx_counter		;
	logic [3:0] data_lim		;
	logic clear_rx_counter		;



 
	typedef enum {IDLE, START, DATA, PARITY, STOP} uart_st;
	uart_st rx_state, rx_state_nxt;

	logic [3:0] rcvd_data_bits;
    logic [1:0] rcvd_stop_bits;


	// manage next state transition
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			rx_state <= IDLE;
		end else begin
			rx_state <= rx_state_nxt;
		end
	end

	always_comb begin
		rx_state_nxt = rx_state;
		clear_rx_counter = '0;
		case (rx_state)
			IDLE	: begin
				if(!rxd) rx_state_nxt = START;
				else     rx_state_nxt = IDLE;
			end
			START	: begin
				if(rx_counter == (BR >> 1)) begin
					if(rxd == 1'b0) begin
						rx_state_nxt = DATA;
						clear_rx_counter = 1'b1;
					end
				end
				else begin
					rx_state_nxt = START;
				end
			end
			DATA 	: begin
				if(rcvd_data_bits == (data_lim-1)) begin
					clear_rx_counter = 1'b1;
					if(i_parity_en) 		rx_state_nxt= PARITY;
					else 					rx_state_nxt = STOP;
				end
				else begin
					if(rx_counter != BR-1) begin
						rx_state_nxt = DATA;
					end
					else begin
						rx_state_nxt = 1'b1;
						rx_state_nxt = DATA;
					end
				end
			end
			PARITY 	: begin
				if(rx_counter == BR-1) begin
					clear_rx_counter = 1'b1;
					if(rcvd_stop_bits == i_stop_bits) 	rx_state_nxt = STOP;
					else 								rx_state_nxt = PARITY;
				end
			end
			STOP 	: begin
				if(rx_counter == BR-1) begin
					clear_rx_counter = 1'b1;
					if(rcvd_stop_bits == i_stop_bits) 	rx_state_nxt = IDLE;
					else 								rx_state_nxt = STOP;
				end
			end
		endcase
	end

	/*------------------------------------------------------------------------------
	--  							Shifting logic
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
	--  						Counter management
	------------------------------------------------------------------------------*/
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			rx_counter <= '0;
		end else begin
			if(clear_rx_counter) rx_counter <= '0;
			else if(rx_state != IDLE) rx_counter <= rx_counter + 1'b1;
			else rx_counter <= '0;
		end
	end



endmodule