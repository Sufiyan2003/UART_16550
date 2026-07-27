/*------------------------------------------------------------------------------
-- Name: Muhammad Sufiyan Sadiq 
-- Date: 18_07_2026
-- Description: This is the shift register
------------------------------------------------------------------------------*/
module shift_register #(
	parameter WIDTH=8,
	parameter [WIDTH-1:0] DEFAULT_VAL = {WIDTH{1'b0}}
)(
	input clk 						,
	input resetn					,
	input [WIDTH-1:0] parallel_in	,
	input parallel_load				,
	input reset_val					,
	input din						,
	input wr_en						,
	input dir						, // 0: LSB-first (UART convention) - new bit enters MSB, shifts down
									  // 1: MSB-first - new bit enters LSB, shifts up
	output [WIDTH-1:0] dout 		,
	output shift_out
);
	logic [WIDTH-1:0] 	data_out	;
	logic 				shift_out_q	;

	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			data_out    <= DEFAULT_VAL;
			shift_out_q <= '0;
		end
		else if(reset_val == 1) begin
			data_out    <= DEFAULT_VAL;
			shift_out_q <= '0;
		end
		else if(parallel_load) begin
			data_out    <= parallel_in;
			// first bit to present on shift_out, matching the direction
			shift_out_q <= dir ? parallel_in[WIDTH-1] : parallel_in[0];
		end
		else begin
			if(wr_en) begin
				if(dir == 1'b0) begin
					// LSB-first: new bit enters at MSB, shifts down toward LSB.
					data_out    <= {din, data_out[WIDTH-1:1]};
					// tap the bit that will occupy position 0 AFTER this
					// shift (= current data_out[1]) so shift_out presents
					// the NEXT bit in sequence, not the one just sent.
					shift_out_q <= data_out[1];
				end
				else begin
					// MSB-first: new bit enters at LSB, shifts up toward MSB.
					data_out    <= {data_out[WIDTH-2:0], din};
					// symmetric fix: tap the bit that will occupy the top
					// position after this shift (= current data_out[WIDTH-2])
					shift_out_q <= data_out[WIDTH-2];
				end
			end
		end
	end

	assign dout      = data_out;
	assign shift_out = shift_out_q;
endmodule : shift_register