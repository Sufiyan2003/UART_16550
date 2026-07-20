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
	input [1:0] i_data_bits,
	input i_parity_en,
	input i_stop_bits,
	input i_even_parity,
	output logic rx_shift_reg,
	output logic load_rx_reg,
	output logic parity_err,
	output logic frame_err
);


	// maintaining an rx counter
	logic [15:0] rx_counter		;
	logic start_rx_counter		;
	logic [3:0] data_lim		;
	logic clear_rx_counter		;
	logic rx_d					;
	logic rx_parity						;


 
	typedef enum {IDLE, START, DATA, PARITY, STOP} uart_st;
	uart_st rx_state, rx_state_nxt;

	logic [3:0] rcvd_data_bits;
    logic  rcvd_stop_bits;


    // to save the previous value of rxd
    always_ff @(posedge clk or negedge resetn) begin
    	if(~resetn) begin
    		rx_d <= 0;
    	end else begin
    		rx_d <= rxd;
    	end
    end



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
		parity_err = 1'b0;
		case (rx_state)
			IDLE	: begin
				// exit from IDLE when rxd goes from 1 -> 0
				if(!rxd && rx_d) rx_state_nxt = START;
				else     rx_state_nxt = IDLE;
			end
			START	: begin
				if(rx_counter == (BR >> 1)) begin
					if(rxd == 1'b0) begin
						rx_state_nxt = DATA;
						clear_rx_counter = 1'b1;
					end
					else begin
						rx_state_nxt = IDLE; // go back to idle if the rxd changed during the half sample timeperiod
					end
				end
				else begin
					rx_state_nxt = START;
				end
			end
			DATA : begin
			    clear_rx_counter = 1'b0;
			    rx_state_nxt = DATA;
			    if (rx_counter == BR-1) begin
			        clear_rx_counter = 1'b1;
			        if (rcvd_data_bits == (data_lim-1)) begin
			            if (i_parity_en) rx_state_nxt = PARITY;
			            else             rx_state_nxt = STOP;
			        end
			        else begin
			            rx_state_nxt = DATA;
			        end
			    end
			end
			PARITY 	: begin
				if(rx_counter == BR-1) begin
					clear_rx_counter = 1'b1;
					if(rx_parity == rxd) parity_err = 1'b0;
					else 								 parity_err = 1'b1;
					rx_state_nxt = STOP;
				end
				else begin
					clear_rx_counter = 1'b0;
					rx_state_nxt = PARITY;
				end
			end
			STOP 	: begin
				if(rx_counter == BR-1) begin
					clear_rx_counter = 1'b1;
					if((rcvd_stop_bits == i_stop_bits) && (rxd == 1'b1)) 	rx_state_nxt = IDLE;
					else 													rx_state_nxt = STOP;
				end
				else 
					clear_rx_counter = 1'b0;
			end
		endcase
	end


	/*------------------------------------------------------------------------------
	--  													Frame Error
	------------------------------------------------------------------------------*/
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			frame_err <= 0;
		end else begin
			if(rx_state == STOP && rx_counter == BR-1) begin
				if(rxd == 1'b0) frame_err <= 1'b1;
				else 						frame_err <= 1'b0;
			end else begin
				frame_err <= 1'b0;
			end
		end
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
	--  Incrementing number of data bits received
	------------------------------------------------------------------------------*/
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
          rcvd_data_bits <= 0;
          rcvd_stop_bits <= 0;
        end
        else begin
          if (rx_state != DATA && rx_state_nxt == DATA)
            rcvd_data_bits <= 0;
          else if (rx_state == DATA && rx_counter == BR-1)
            rcvd_data_bits <= rcvd_data_bits + 1'b1;
      
          if (rx_state != STOP && rx_state_nxt == STOP)
            rcvd_stop_bits <= 0;
          else if (rx_state==STOP && rx_counter == BR-1)
            rcvd_stop_bits <= rcvd_stop_bits + 1'b1;    
        end
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


	/*------------------------------------------------------------------------------
	--  							Shifting logic
	------------------------------------------------------------------------------*/
	always_comb begin
	    rx_shift_reg = 1'b0;
	    if (rx_state == DATA && rx_counter == BR-1) rx_shift_reg = 1'b1;
	    else 																				rx_shift_reg = 1'b0;
	    
	end

	/*------------------------------------------------------------------------------
	--  											Parity check
	------------------------------------------------------------------------------*/
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			rx_parity <= 0;
		end else begin
			if((rx_counter == BR-1) && ((rx_state == DATA) && (rx_state_nxt == DATA))) begin
				if(i_even_parity) begin
					if(rxd == 1'b1) begin
						if(rx_parity == 0) rx_parity <= 1'b1;
						else rx_parity <= 1'b0;
					end
					else begin
						rx_parity <= rx_parity;
					end 
				end
				else begin
					if(rxd == 1'b1) begin
							if(rx_parity == 0) rx_parity <= 1'b1;
							else rx_parity <= 1'b0;
						end
						else begin
							rx_parity <= rx_parity;
						end 
					end
				end
			end
	end

	/*------------------------------------------------------------------------------
	--  					Logic to load rx register in case of no error
	------------------------------------------------------------------------------*/
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			load_rx_reg <= 0;
		end else begin
			// if the packet is finished and there are no errors
			// TODO: need to check if less stop bits are sent
			if(rx_state == STOP && rx_state_nxt == IDLE) begin
				if(parity_err == 1'b0) load_rx_reg <= 1'b1;
				else load_rx_reg <= 1'b0;
			end
			else load_rx_reg <= 1'b0;
		end
	end




endmodule