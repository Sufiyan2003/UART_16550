/*------------------------------------------------------------------------------
-- Author: Muhammad Sufiyan Sadiq 
-- Date: 26_07_2026
-- Description: This is the top cache rtl just to test something
-- 
------------------------------------------------------------------------------*/

`include "cache_params.svh"
module cache_top (
	input 					clk			,    // Clock
	input 					resetn		,
	input [ADDR_WIDTH-1:0] 	i_address	,
	input 					i_write 	,
	input 					i_req_valid ,
	input 					i_read 		,
	input [DWIDTH-1:0]  	i_data		,
	output 					o_hit 		,
	output 					o_miss
	
);

	logic [NUM_WAYS-1:0] write_to_cache;

	logic [BYTE_OFF_WIDTH-1:0] byte_offset; 
	logic [LINE_NUMBER_WIDTH-1:0] line_number;
	logic [TAG_WIDTH-1:0] tag_value;

	// dissect the input address
	assign byte_offset = i_address[BYTE_OFF_WIDTH-1:0];
	assign line_number = i_address[BYTE_OFF_WIDTH + LINE_NUMBER_WIDTH-1:BYTE_OFF_WIDTH];
	assign tag_value   = i_address[ADDR_WIDTH-1 : BYTE_OFF_WIDTH + LINE_NUMBER_WIDTH];
	

	// generate the number of memory wrappers as there are number of ways
	genvar i;
	generate
		// data storage
		for (i = 0; i < NUM_WAYS; i++) begin
			memwrap #(
				.DWIDTH    (DWIDTH),
				.ADDR_WIDTH(ADDR_WIDTH),
				.DEPTH     (DEPTH)
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

		// for storing tags
		for (i = 0; i < NUM_WAYS; i++) begin
			memwrap #(
				.DWIDTH    (TAG_WIDTH),
				.ADDR_WIDTH(ADDR_WIDTH),
				.DEPTH     (DEPTH)
			) tag_memory(
				.clk     (clk),
				.resetn  (resetn),
				.i_data  (),
				.i_addr  (),
				.o_data  (),
				.read_en (),
				.write_en()
			);
		end

		// for storing valid lines
		for (i = 0; i < NUM_WAYS; i++) begin
			memwrap #(
				.ADDR_WIDTH(ADDR_WIDTH),
				.DEPTH     (DEPTH),
				.DWIDTH    (1),
				.DEFAULT_VAL (1)
			) valid_mem(
				.clk     (clk),
				.resetn  (resetn),
				.i_data  (),
				.i_addr  (),
				.o_data  (),
				.read_en (),
				.write_en()
			);
		end

		for (i = 0; i < NUM_WAYS; i++) begin
			memwrap #(
				.ADDR_WIDTH(ADDR_WIDTH),
				.DEPTH     (DEPTH),
				.DWIDTH    (1)
			) dirty_mem(
				.clk     (clk),
				.resetn  (resetn),
				.i_data  (),
				.i_addr  (),
				.o_data  (),
				.read_en (),
				.write_en()
			);
		end

	endgenerate


	// Check whether the address is present inside the cache or not
	logic read_tag_mem;
	always_ff @(posedge clk or negedge resetn) begin : proc_
		if(~resetn) begin
			read_tag_mem <= 1'b0;
		end else begin
			// if its a valid read request
			if(i_req_valid && i_read) begin
				read_tag_mem <= 1'b1;
			end
			else read_tag_mem <= 1'b0;

		end
	end





endmodule : cache_top


