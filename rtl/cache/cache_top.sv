/*------------------------------------------------------------------------------
-- Author: Muhammad Sufiyan Sadiq 
-- Date: 26_07_2026
-- Description: This is the top cache rtl just to test something
-- 
------------------------------------------------------------------------------*/


module cache_top #(
	parameter NUM_WAYS=4
)(
	input clk,    // Clock
	input resetn,
	
);




	// generate the number of memory wrappers as there are number of ways
	genvar i;
	generate
		for (int i = 0; i < count; i++) begin
			memwrap #(
				.DWIDTH    (32),
				.ADDR_WIDTH(8),
				.DEPTH     (16)
			) memory(
				.clk     (clk),
				.resetn  (resetn),
				.write_en(),
				.read_en (),
				.i_addr  (),
				.i_data  (),
				.o_data  ()
			);
		end
	endgenerate





endmodule : cache_top


