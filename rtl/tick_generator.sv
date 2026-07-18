/*------------------------------------------------------------------------------
--	Name: Muhammad Sufiyan Sadiq  	
-- 	Date: 13_07_2026
--  Description: controls a counter which outputs to both transmitter and receivers
--
------------------------------------------------------------------------------*/



module tick_generator (
	input clk,    // Clock
	input resetn,
	input [15:0] DL,
	output logic o_tick,
	output [15:0] o_counter
);


	logic [15:0] counter;

	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			counter <= '0;
		end else begin
			if(counter == DL) begin 
				o_tick <= 1'b1;
				counter <= '0;
			end
			else counter <= counter + 1'b1;
		end
	end

	assign o_counter = counter;



endmodule







