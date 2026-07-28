`ifndef CACHE_PARAMS_SVH
`define CACHE_PARAMS_SVH

// memory wrapper paramaters
localparam DWIDTH = 512;
localparam ADDR_WIDTH=32;
localparam DEPTH  = 16;

// CACHE paramaters
localparam NUM_WAYS=4;
localparam BYTE_OFF_WIDTH = $clog2(DWIDTH/8);
localparam LINE_NUMBER_WIDTH=$clog2(DEPTH);
localparam TAG_WIDTH = ADDR_WIDTH - LINE_NUMBER_WIDTH - BYTE_OFF_WIDTH;


`endif