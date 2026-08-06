/*------------------------------------------------------------------------------
--	Name: Muhammad Sufiyan Sadiq  	
-- 	Date: 13_07_2026
--	Description: This is the code for the ip control blocks contains the csrs
--  Interrupt controller and decoder, interfaces with the txrx block
--
------------------------------------------------------------------------------*/


`include "uart_params.svh"
module ip_control_block (
	input clk,    // Clock
	input resetn,
	input [7:0] data_in,
	input [2:0] add,
	input chip_select,
	input ior,
	input iow,
	input load_rhr,
	input [7:0] RHR_IN,
	output logic [7:0] data_out,
	output logic outen,
	output irq, irq_n,
	output [15:0] o_DL,
	output [7:0] lcr_out,
	output [7:0] thr_out,
	output [7:0] isr_out,
	output [7:0] fcr_out,
	output [7:0] mcr_out,
	output [7:0] msr_out,
	output [7:0] lsr_out,
	output logic thr_valid,
	input tx_ready,
	output thr_empty,

	// input from the external fifo
	input [10:0] rx_fifo_in,
	input fifo_sel,

	// LSR register input
	input i_fifo_err,
	input i_transmit_empty,
	input i_thr_write,
	input i_break_intr,
	input i_framing_err,
	input i_parity_err,
	input i_overrun_err,
	input i_data_ready,	

	// MSR
	input i_CD,
	input i_RI,
	input i_DSR,
	input i_CTS,
	input i_trailing_edge_RI,

	// ISR
	input i_fifos_en1,
	input i_fifos_en2,
	input i_dma_tx_end,
	input i_dma_rx_end,
	input [2:0] i_intrp_id,
	input i_write_intrpt_pulse,
	input i_intr_stat

);

	logic [7:0] rhr_val;
	logic [7:0] thr_val;
	logic [7:0] ier_val;
	logic [7:0] isr_val;
	logic [7:0] fcr_val;
	logic [7:0] lcr_val;
	logic [7:0] mcr_val;
	logic [7:0] lsr_val;
	logic [7:0] msr_val;
	logic [7:0] spr_val;
	logic [7:0] dll_val;
	logic [7:0] dlm_val;
	logic [7:0] psd_val;
	
	// values of individual flags
	logic fifo_dat_err,transmit_empty,thr_empty_bit,break_intrpt,framing_err,parity_err,overrun_err,data_ready;
	logic delta_CTS, delta_DSR, trailing_edge_RI,delta_CD,CTS,DSR,RI,CD;
	
	logic [7:0] rhr_out;
	// output the baud rate from this rapper to the core to the tick generator
	assign o_DL = {dlm_val, dll_val};



	// delta CTS flag (to detect change in CTS after previous read)
	logic cts_q, dsr_q, ri_q, cd_q;
	logic cts_changed, dsr_changed, cd_changed, ri_trailing_edge_changed;
	logic msr_read;
	logic del_cts, del_dsr, del_cd,trail_ri;

	logic deassert_reset;
	logic [7:0] fcr_in;

	/*------------------------------------------------------------------------------
	--  							Decode stage
	------------------------------------------------------------------------------*/
	// select what the ip_control_block is supposed to output
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			data_out <= '0;
		end else begin
			if(ior && chip_select) begin
				case (add)
					RHR_REGISTER: begin
						if(lcr_val[7]) 	data_out <= dll_val;
						else begin
							data_out <= rhr_out;
						end
					end
					IER_REGISTER: begin
						if(lcr_val[7]) 	data_out <= dlm_val;
						else 			data_out <= ier_val;
					end
					ISR_REGISTER: data_out <= isr_val;
					LCR_REGISTER: data_out <= lcr_val;
					MCR_REGISTER: data_out <= mcr_val;
					LSR_REGISTER: begin
						if(lcr_val[7]) 	data_out <= psd_val; 
						else 			data_out <= lsr_val;
					end
					MSR_REGISTER: data_out <= msr_val;
					`ifdef UART_IMPLEMENT_SCRATCHPAD
						SPR_REGISTER: data_out <= spr_val;
					`endif
				endcase
			end
			else begin
				data_out <= data_out;
			end
		end
	end

	always_comb begin
		if(fifo_sel) 	rhr_out = rx_fifo_in[7:0];
		else 			rhr_out = rhr_val;
	end


	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			outen <= '0;
		end else begin
			if(ior && chip_select) begin
				outen <= 1'b1;
			end
		end
	end


	/*------------------------------------------------------------------------------
	--  						   CSR registers
	------------------------------------------------------------------------------*/	
	// regular registers to be loaded with the values from the external shift registers
	
	register #(
		.DEFAULT_VAL('0)
	) RHR(
		.clk   (clk),
		.resetn(resetn),
		.din   (RHR_IN),
		.dout  (rhr_val),
		.wr_en (load_rhr && chip_select)
	);

	//W
	register #(
		.DEFAULT_VAL('0)
	) THR(
		.clk   		(clk)						,
		.resetn		(resetn)					,
		.din   		(data_in)					,
		.wr_en 		((add == THR_REGISTER) && iow && (lcr_val[7] == 0) && chip_select)		,
		.dout  		(thr_val)
	);

	// drive thr_valid to tell the control block that it can be loaded
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			thr_valid <= '0;
		end else begin
			// TODO: check if fifos are enabled or not
			if((add == THR_REGISTER) && iow && (lcr_val[7] == 0)) thr_valid <= 1'b1;
			else if(tx_ready == 1'b1) thr_valid <= 1'b0;
			else thr_valid <= thr_valid;
		end
	end

	assign thr_empty = ~thr_valid;


	register #(
		.DEFAULT_VAL('0)
	) IER(
		.clk   (clk),
		.resetn(resetn),
		.din   (data_in),
		.wr_en ((add == IER_REGISTER) && iow && chip_select),
		.dout  (ier_val)
	);

	logic o_fifos_en1;
	logic o_fifos_en2;
	logic dma_tx_end;
	logic dma_rx_end;
	logic [2:0] intrpt_id_code;
	logic intrpt_status;


	// set individual flags to set the values of ISR register
	register #(
		`ifdef UART_IMPLEMENT_FIFO
		.DEFAULT_VAL(1),
		`else
		.DEFAULT_VAL(0),
		`endif
		.WIDTH      (1)
	) fifos_en1(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_fifos_en1),
		.wr_en (chip_select),
		.dout  (o_fifos_en1)
	);

	register #(
		`ifdef UART_IMPLEMENT_FIFO
		.DEFAULT_VAL(1),
		`else
		.DEFAULT_VAL(0),
		`endif
		.WIDTH      (1)
	) fifos_en2_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_fifos_en2),
		.wr_en (chip_select),
		.dout  (o_fifos_en2)
	);

	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) dma_tx_flag
	(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_dma_tx_end),
		.wr_en (chip_select),
		.dout  (dma_tx_end)
	);

	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) dma_rx_flag
	(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_dma_rx_end),
		.dout  (dma_rx_end),
		.wr_en (chip_select)
	);

	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (3)
	) intrpt_id_flag
	(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_intrp_id),
		.wr_en (i_write_intrpt_pulse && chip_select),
		.dout  (intrpt_id_code)
	);

	register #(
		.DEFAULT_VAL(1),
		.WIDTH      (1)
	) intrpt_status_flag
	(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_intr_stat),
		.dout  (intrpt_status),
		.wr_en (i_write_intrpt_pulse && chip_select)  				// write this whenever any of the interrupts go
	);

	// this will be one full register
	always_comb begin
		isr_val = {o_fifos_en1, o_fifos_en2, dma_tx_end, dma_rx_end, intrpt_id_code, intrpt_status};
	end


 

	register #(
		.DEFAULT_VAL('0)
	) FCR(
		.clk   (clk)																	,
		.resetn(resetn)																	,
		.din   (fcr_in)																,
		.wr_en (((add == FCR_REGISTER) && iow && chip_select) || deassert_reset)		,
		.dout  (fcr_val)
	);


	/*------------------------------------------------------------------------------
	--  		reset fifo bit must go back to 0 after being set
	------------------------------------------------------------------------------*/
	// tp generate a pulse
	always_ff @(posedge clk or negedge resetn) begin 
		if(~resetn) begin
			deassert_reset <= 0;
		end else begin
			// if either of them is one then must first write new fcr_val into this register
			if((|fcr_val[2:1]) == 1'b1) deassert_reset <= 1'b1;
			else deassert_reset <= 1'b0;
		end
	end

	// select input into fcr
	always_comb begin
		if((|fcr_val[2:1]) == 1'b1) fcr_in = {fcr_val[7:5], 2'b00, fcr_val[0]};
		else 						fcr_in = data_in;
	end



	register #(
		.DEFAULT_VAL('0)
	) LCR(
		.clk   (clk)						,
		.resetn(resetn)						,
		.din   (data_in)					,
		.wr_en ((add==LCR_REGISTER) && iow && chip_select)		,
		.dout  (lcr_val)
	);

	register #(
		.DEFAULT_VAL('0)
	) MCR(
		.clk   (clk)						,
		.resetn(resetn)						,
		.din   (data_in)					,
		.wr_en ((add==MCR_REGISTER) && iow && chip_select)		,
		.dout  (mcr_val)
	);





	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) fifo_dat_err_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_fifo_err),
		.dout  (fifo_dat_err),
		.wr_en (chip_select)
	);

	register #(
		.DEFAULT_VAL(1),
		.WIDTH      (1)
	) transmit_empty_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_transmit_empty),
		.dout  (transmit_empty),
		.wr_en (chip_select && 1'b1)
	);

	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) thr_empty_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (~thr_valid),
		.dout  (thr_empty_bit),
		.wr_en (1'b1 && chip_select) // write needs to be a pulse so that we can write this flag
	);

	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) break_intrpt_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_break_intr),
		.dout  (break_intrpt),
		.wr_en (1'b1 && chip_select)
	);


	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) framing_error_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_framing_err),
		.dout  (framing_err),
		.wr_en (1'b1 && chip_select)
	);

	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) parity_error_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_parity_err),
		.dout  (parity_err),
		.wr_en (1'b1 && chip_select)
	);

	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) overrun_error_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_overrun_err),
		.dout  (overrun_err),
		.wr_en (1'b1 && chip_select)
	);


	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) data_ready_flag(
		.clk   		(clk),
		.resetn		(resetn),
		.din   		(i_data_ready),
		.dout  		(data_ready),
		.wr_en 		(load_rhr || (ior && add == '0 && lcr_val[7]) && chip_select) // assert when rhr ready and deassert when ready 
	);

	always_comb begin
		lsr_val = {fifo_dat_err, transmit_empty, thr_empty_bit, break_intrpt, framing_err, parity_err, overrun_err, data_ready}; 
	end

	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) CD_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_CD),
		.dout  (CD),
		.wr_en (iow && chip_select)
	);

	register #(
		.DEFAULT_VAL(1),
		.WIDTH      (1)
	) RI_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_RI),
		.dout  (RI),
		.wr_en (iow && chip_select)
	);

	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) DSR_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (i_DSR),
		.dout  (DSR),
		.wr_en (iow && chip_select)
	);

	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) CTS_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (cts_changed),
		.dout  (CTS),
		.wr_en (iow && chip_select)
	);


	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) delta_CD_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (del_cd),
		.dout  (delta_CD),
		.wr_en (1'b1)
	);

	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) trailing_edge_RI_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (ri_trailing_edge_changed),
		.dout  (trailing_edge_RI),
		.wr_en (1'b1)
	);

	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) delta_DSR_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (del_dsr),
		.dout  (delta_DSR),
		.wr_en (1'b1)
	);


	register #(
		.DEFAULT_VAL(0),
		.WIDTH      (1)
	) delta_CTS_flag(
		.clk   (clk),
		.resetn(resetn),
		.din   (del_cts),
		.dout  (delta_CTS),
		.wr_en (1'b1)
	);

	always_comb begin
		msr_val = {CD,RI,DSR,CTS,delta_CD,trailing_edge_RI, delta_DSR,delta_CTS};
	end


	`ifdef UART_IMPLEMENT_SCRATCHPAD
		register #(
			.DEFAULT_VAL('0)
		) SPR(
			.clk   (clk)									,
			.resetn(resetn)									,
			.din   (data_in)								,
			.wr_en ((add == 3'b111) && iow && chip_select)					,
			.dout  (spr_val)
		);
	`else
		// register is reserved
		register #(
			.DEFAULT_VAL('0)
		) rsvd(
			.clk   (clk),
			.resetn(resetn),
			.wr_en (),
			.din   (),
			.dout  ()
		);
	`endif

	register #(
		.DEFAULT_VAL(8'h01)
	) DLL(
		.clk   (clk)									,
		.resetn(resetn)									,
		.din   (data_in)								,
		.wr_en ((add == '0) && iow && lcr_val[7] && chip_select)		,
		.dout  (dll_val)
	);
	
	register #(
		.DEFAULT_VAL(8'h01)
	) DLM(
		.clk   (clk)									,
		.resetn(resetn)									,
		.din   (data_in)								,
		.wr_en ((add == 3'b001) && iow && lcr_val[7] && chip_select)	,
		.dout  (dlm_val)
	);
	
	register #(
		.DEFAULT_VAL('0)
	) PSD(
		.clk   (clk)									,
		.resetn(resetn)									,
		.din   (data_in)								,
		.wr_en ((add==3'b101) && iow && lcr_val[7] && chip_select)		,
		.dout  (psd_val)

	);


	assign lcr_out = lcr_val;
	assign thr_out = thr_val;
	assign fcr_out = fcr_val;
	assign mcr_out = mcr_val;
	assign msr_out = msr_val;
	assign lsr_out = lsr_val;

	// detect msr read req
	assign msr_read = ior && (add == MSR_REGISTER);

	// detecting change in bits
	assign cts_changed = (CTS != cts_q);
	assign dsr_changed = (DSR != dsr_q);
	assign cd_changed = (CD != cd_q);
	assign ri_trailing_edge_changed = (trailing_edge_RI==1'b1 && i_trailing_edge_RI==1'b0);



	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			cts_q <= 1'b0;
			dsr_q <= 1'b0;
			ri_q <= 1'b0;
			cd_q <= 1'b0;
		end else begin
			cts_q <= i_CTS;
			dsr_q <= i_DSR;
			ri_q <= i_trailing_edge_RI;
			cd_q <= i_CD;
		end
	end


	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			del_cts <= '0;
			del_dsr <= '0;
			del_cd <= '0;
			trail_ri <= '0;
		end else begin
			del_cts <= cts_changed ? 1'b1 : (msr_read ? 1'b0 : del_cts);
			del_dsr <= dsr_changed ? 1'b1 : (msr_read ? 1'b0 : del_dsr);
			del_cd <= cd_changed ? 1'b1 : (msr_read ? 1'b0 : del_cd);
			trail_ri <= ri_trailing_edge_changed ? 1'b1 : (msr_read ? 1'b0 :trail_ri);
		end
	end

endmodule


