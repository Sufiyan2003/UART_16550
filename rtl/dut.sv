
module dut (
  input  logic clk,
  output my_pkg::state_t state_out
);
  import my_pkg::*;

  state_t state;

  always_ff @(posedge clk)
    state <= (state == DONE) ? IDLE : state_t'(state + 1);

  assign state_out = state;
endmodule