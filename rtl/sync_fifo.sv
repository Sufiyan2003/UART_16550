/*------------------------------------------------------------------------------
-- Author: Muhammad Sufiyan Sadiq 
-- Date: 22_07_2026
-- Description: The synchronous fifo block
-- 
------------------------------------------------------------------------------*/


module sync_fifo #(parameter DEPTH=8, DWIDTH=16)
(
    input                   rstn,
                            clk,
                            wr_en,
                            rd_en,
    input      [DWIDTH-1:0] din,
    output reg [DWIDTH-1:0] dout,
    output                  empty,
                            full
);

  // One extra bit on pointers to distinguish full vs empty
  reg [$clog2(DEPTH):0]   wptr;   // <-- note: $clog2(DEPTH) not $clog2(DEPTH)-1
  reg [$clog2(DEPTH):0]   rptr;

  reg [DWIDTH-1:0] fifo[DEPTH];

  always @(posedge clk or negedge rstn) begin
    if (!rstn) wptr <= 0;
    else if (wr_en & !full) begin
      fifo[wptr[$clog2(DEPTH)-1:0]] <= din;   // index with lower bits only
      wptr <= wptr + 1;
    end
  end

  always @(posedge clk or negedge rstn) begin
    if (!rstn) rptr <= 0;
    else if (rd_en & !empty) begin
      dout <= fifo[rptr[$clog2(DEPTH)-1:0]];  // index with lower bits only
      rptr <= rptr + 1;
    end
  end

  // MSB differs = wrapped around = full
  // MSB same + lower bits equal = empty
  assign full  = (wptr[$clog2(DEPTH)] != rptr[$clog2(DEPTH)]) &&
                 (wptr[$clog2(DEPTH)-1:0] == rptr[$clog2(DEPTH)-1:0]);

  assign empty = (wptr == rptr);


endmodule