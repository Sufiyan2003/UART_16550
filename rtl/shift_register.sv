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
			data_out <= parallel_in;
		end
		else begin
			if(wr_en) begin
				// LSB-first shift: new bit enters at MSB, existing bits shift
				// down toward LSB. This means the first bit received (which is
				// the original byte's LSB, per UART LSB-first convention) ends
				// up correctly parked at bit 0 once all WIDTH bits have shifted in.
				data_out    <= {din, data_out[WIDTH-1:1]};
				// captures the pre-shift LSB, i.e. the next bit to transmit
				// (LSB-first) when this module is used as a TX shift register
				shift_out_q <= data_out[0];
			end
		end
	end

	assign dout      = data_out;
	assign shift_out = shift_out_q;
endmodule : shift_register