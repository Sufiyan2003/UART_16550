/*------------------------------------------------------------------------------
-- Author: Muhammad Sufiyan Sadiq  
-- Date: 26_07_2026
-- Description: A regular single port memory responsible for 
--
------------------------------------------------------------------------------*/



module memwrap  #(
	parameter DWIDTH=32,
	parameter ADDR_WIDTH=8,
	parameter DEPTH=16,
	parameter [DWIDTH-1:0] DEFAULT_VAL = {DWIDTH{1'b0}} 
)(
	input 							clk			,
	input 							resetn		,
	input 							write_en	,
	input 							read_en		,	
	input [ADDR_WIDTH-1:0] 			i_addr		,
	input [DWIDTH-1:0]  			i_data 		,
	output logic [DWIDTH-1:0]		o_data
);

	logic [DWIDTH-1:0] mem[DEPTH];


	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			o_data <= '0;
			for (int i = 0; i < DEPTH; i++) begin
				mem[i] <= DEFAULT_VAL;
			end
		end else begin
			if(write_en && !read_en) mem[i_addr] <= i_data;
			else if(!write_en && read_en) o_data <= mem[i_addr];
			else o_data <= o_data;
		end
	end

endmodule : memwrap