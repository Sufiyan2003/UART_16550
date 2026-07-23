/*------------------------------------------------------------------------------
-- Name: Muhammad Sufiyan Sadiq  
-- Date:	 15_07_2026
-- Description: This is the testbench of uart core
------------------------------------------------------------------------------*/

module tb;

	parameter FCLK=100_000_000;

	import uvm_pkg::*;
	`include "uvm_macros.svh"
	`include "uart_params.svh"

	logic clk						;
	logic resetn					;
	logic [7:0] data_in				;
	logic cs1						;
	logic cs2						;
	logic cs_n						;
	logic ior,ior_n					;
	logic iow,iow_n					;
	logic dma_rxend, dma_txend		;
	logic [2:0] add 				;
	logic cts_n						;
	logic dsr_n						;
	logic ri_n						;
	logic cd_n						;
	logic rxd						;
	logic [7:0] data_out			;
	logic outen						;
	logic irq, irq_n				;
	logic rxrdy, rxrdy_n			;
	logic txrdy, txrdy_n			;
	logic rts_n						;
	logic dtr_n						;
	logic out1_n					;
	logic out2_n					;
	logic txd 						;


	int i_baud_rate; // baudrate
	logic [2:0]  i_data_bits;
	logic i_parity_en;
	logic i_stop_bits; // 1 stop bits 


	uart_16550 uart_16550_top(
		.*
	);


	initial begin
	  	clk = 1'b0;
	  	resetn = 1'b1;
	  	ior = 0;
	  	iow =0 ;
	  	#3ns;
	  	resetn = 1'b0;
	  	#3ns;
	  	resetn = 1'b1;

	end

	always #0.5ns clk = ~clk;
	bit [7:0] reg_data;

	byte array[] = '{8'h56, 8'h23, 8'h78, 8'h69};
	// block to test out the registers 
	initial begin
		#100ns;
		set_baud_rate(9600, 4'b0000);
		read_from_reg(LCR_REGISTER);
		read_from_reg(DLM_REGISTER);
		read_from_reg(DLL_REGISTER);
		write_to_reg(8'h01, FCR_REGISTER); // enable fifos only 
		set_uart_frame(2'b11, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0);
		#100ns;
		foreach (array[i]) begin
			send_uart_byte(array[i]);
		end
		send_data(8'hEA);
		#1000ns;
		read_from_reg(RHR_REGISTER);
		// #5000ns;
		// send_data(8'hBB);
		#20000ns;
	  	$finish;

	end

	task read_from_reg(input logic [2:0] address);
		@(posedge clk);
  		ior = 1'b1;
  		iow = 1'b0;
  		add = address;
  		@(posedge clk);
  		ior = 1'b0;
  	endtask : read_from_reg

  	task write_to_reg(input bit[7:0] i_data, input bit [2:0] address);
  		@(posedge clk);
  		iow = 1'b1;
  		ior = 1'b0;
  		data_in = i_data;
  		add = address;
  		@(posedge clk);
  		iow = 1'b0;
  	endtask : write_to_reg


  	// for setting baud rate
  	task set_baud_rate(input int baud_rate, input bit [3:0] psd_val);
		real dl_real;
		int dl_int;
		logic [15:0] dl;
		logic [7:0] dll_val, dlm_val;

		dl_real = real'(FCLK) / (16.0 * (real'(psd_val) + 1) * real'(baud_rate));
		dl_int = $rtoi(dl_real);
		i_baud_rate = dl_int;
		$display("dl_real is: %0f",dl_real);
		$display("dl_int is: %0d",dl_int);
		if(dl_int <= 0 || dl_int > 65535)begin
	        $error("Computed DL=%0d out of range for baud_rate=%0d, psd=%0d", dl_int, baud_rate, psd_val);
        	return;
		end

		dl = dl_int[15:0];
		dll_val = dl[7:0];
		dlm_val = dl[15:8];

		// write to lcr_val[7] to access DLL and DLM registers
		write_to_reg(8'h80, LCR_REGISTER);

		// write the DL registers
		write_to_reg(dll_val, DLL_REGISTER);
		write_to_reg(dlm_val, DLM_REGISTER);

		// write to the PSD register
		write_to_reg({4'h0, psd_val}, PSD_REGISTER);
		
		// write this register to avoid writing to DLM and DLL and PSD register
		write_to_reg(8'h00, LCR_REGISTER);
  	endtask : set_baud_rate


  	task set_uart_frame(bit [1:0] word_len, bit stop_bit, bit parity_en, bit even_par, bit force_parity, bit set_break, bit DLAB);
  		bit [7:0] lcr_val;
  		lcr_val = {DLAB, set_break,force_parity,even_par,parity_en,stop_bit,word_len};
  		write_to_reg(lcr_val,LCR_REGISTER);
  		
  	endtask : set_uart_frame

  	// task to load the THR register
  	task send_data(input [7:0] data);
  		write_to_reg(data, THR_REGISTER);
  	endtask



  	/*------------------------------------------------------------------------------
  	--  tasks to transmit data to the uart ip
  	------------------------------------------------------------------------------*/
  	task send_uart_byte(input [7:0] data);
	    integer i;
	    
	    // START bit, start with a 1, start bit is indicated by a 0
	    rxd = 1'b1;
	   	repeat (i_baud_rate) @(posedge clk);

	   	// send the start bit
	   	rxd = 1'b0;
	   	repeat (i_baud_rate) @(posedge clk);

	    // DATA bits (LSB first)
	   	for (i = 0; i < 8; i++) begin
	    	rxd = data[i];
	        repeat (i_baud_rate) @(posedge clk);
	    end

	    // STOP bit
	    rxd = 1'b1;
	   	repeat (i_baud_rate) @(posedge clk);
    
  	endtask



  	// driving the differential signals	
  	assign ior_n 	= ~ior;
  	assign iow_n 	= ~iow;
  	// assign rxrdy_n 	= ~rxrdy;
  	// assign txrdy_n  = ~txrdy;



endmodule