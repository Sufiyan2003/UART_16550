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
	input i_force_parity,
	input fifo_empty,
	input rx_fifo_full,
	output logic rx_shift_reg,
	output logic load_rx_reg,
	output logic parity_err,
	output logic rx_timeout,
	output logic fifo_overrun,
	output logic o_BI,
	output logic frame_err
);


	// maintaining an rx counter
	logic [15:0] rx_counter		;
	logic start_rx_counter		;
	logic [3:0] data_lim		;
	logic clear_rx_counter		;
	logic rx_d					;
	logic rx_parity				;

	logic [15:0] 	timeout_counter;
	logic [15:0] 	char_time;

	typedef enum {IDLE, START, DATA, PARITY, STOP} uart_st;
	uart_st rx_state, rx_state_nxt, rx_state_prev;

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
			rx_state_prev <= rx_state;
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
					if(rx_parity == rxd) 	parity_err = 1'b0;
					else 				 	parity_err = 1'b1;
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
					if((rcvd_stop_bits == i_stop_bits) && (rxd == 1'b1)) 						rx_state_nxt = IDLE;
					else if((rcvd_stop_bits == i_stop_bits) && (rxd == 1'b0 && rx_d == 1'b1)) 	rx_state_nxt = START;
					else 																		rx_state_nxt = STOP;
				end

				else 
					clear_rx_counter = 1'b0;
			end
		endcase
	end


	/*------------------------------------------------------------------------------
	--  							Frame Error
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
	    if ((rx_state == DATA) && rx_counter == BR-1) rx_shift_reg = 1'b1;
	    else rx_shift_reg = 1'b0;
	    
	end

	/*------------------------------------------------------------------------------
	--  											Parity check
	------------------------------------------------------------------------------*/
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			rx_parity <= 0;
		end else begin
			if((rx_counter == BR-1) && ((rx_state == DATA) && (rx_state_nxt == DATA))) begin
				if(i_force_parity) begin
					if(i_even_parity) 	rx_parity <= 1'b1;
					else 				rx_parity <= 1'b0;
				end
				else begin
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
	end

	/*------------------------------------------------------------------------------
	--  			Logic to load rx register in case of no error
	------------------------------------------------------------------------------*/
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			load_rx_reg <= 0;
		end else begin
			// if the packet is finished and there are no errors
			// TODO: need to check if less stop bits are sent
			if((rx_state == STOP && (rx_state_nxt == IDLE || rx_state_nxt == START))) load_rx_reg <= 1'b1;
			else 																	load_rx_reg <= 1'b0;
		end
	end



	assign char_time = BR * (1 + data_lim + i_parity_en + (i_stop_bits ? 2 : 1));


	/*------------------------------------------------------------------------------
	--  					For timeout condition
	------------------------------------------------------------------------------*/
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			timeout_counter<= '0;
			rx_timeout <= 0;
		end else begin
			if(fifo_empty) begin
				timeout_counter <= '0;
				rx_timeout <= 1'b0;
			end
			else if(load_rx_reg == 1'b1) timeout_counter <= 1'b0;
			else if(timeout_counter == (4*char_time - 1)) rx_timeout <= 1'b1;
			else begin 
				timeout_counter <= timeout_counter + 1'b1;
				rx_timeout <= rx_timeout;
			end
		end
	end

	/*------------------------------------------------------------------------------
	--  						For break interrupt
	------------------------------------------------------------------------------*/
	logic bi_counter;
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			 o_BI <= 0;
			 bi_counter <= '0;
		end else begin
			if(rxd == 0) begin
				if(bi_counter >= char_time) o_BI <= 1'b1;
				else 						o_BI <= 1'b0;
			end
			else  begin
				bi_counter <= '0;
				o_BI <= 1'b0;
			end
		end
	end




	/*------------------------------------------------------------------------------
	--  				For detecting overrun error
	------------------------------------------------------------------------------*/
	always_ff @(posedge clk or negedge resetn) begin : proc_
		if(~resetn) begin
			fifo_overrun <= 0;
		end else begin
			if(rx_state == START && rx_state_nxt==DATA && rx_fifo_full) fifo_overrun <= 1'b1;
			else 														fifo_overrun <= 1'b0;
		end
	end



endmodule