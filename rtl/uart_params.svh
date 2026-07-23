`ifndef UART_PARAMS_SVH
`define UART_PARAMS_SVH

localparam RHR_REGISTER = 3'b000;
localparam THR_REGISTER = 3'b000;
localparam IER_REGISTER = 3'b001;
localparam ISR_REGISTER = 3'b010;
localparam FCR_REGISTER = 3'b010;
localparam LCR_REGISTER = 3'b011;
localparam MCR_REGISTER = 3'b100;
localparam LSR_REGISTER = 3'b101;
localparam MSR_REGISTER = 3'b110;
localparam SPR_REGISTER = 3'b111;
localparam DLL_REGISTER = 3'b000;
localparam DLM_REGISTER = 3'b001;
localparam PSD_REGISTER = 3'b101;

`endif