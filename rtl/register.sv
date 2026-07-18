/*------------------------------------------------------------------------------
-- Name: Muhammad Sufiyan Sadiq  	
-- Date: 13_07_2026
-- Description: Reusable register module
--
------------------------------------------------------------------------------*/



module register #(
	parameter WIDTH=8,
	parameter [WIDTH-1:0] DEFAULT_VAL = {WIDTH{1'b0}}
)(
	input 				clk			, 
	input 				resetn		,
	input [WIDTH-1:0] 	din			,
	input 				wr_en		,
	output [WIDTH-1:0] 	dout 
);

	logic [WIDTH-1:0] data_out;

	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			data_out <= DEFAULT_VAL;
		end else begin
			if(wr_en) begin
				data_out <= din;
			end
		end
	end

	assign dout = data_out;


endmodule

