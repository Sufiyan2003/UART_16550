/*------------------------------------------------------------------------------
--	Name: Muhammad Sufiyan Sadiq  	
-- 	Date: 13_07_2026
--	Description: This is the code for the ip control blocks contains the csrs
--  Interrupt controller and decoder, interfaces with the txrx block
--
------------------------------------------------------------------------------*/



module ip_control_block (
	input clk,    // Clock
	input resetn,
	input [7:0] data_in,
	input [2:0] add,
	input cs1,cs2,cs_n,
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
	output logic thr_valid,
	input tx_ready
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
	
	// output the baud rate from this rapper to the core to the tick generator
	assign o_DL = {dlm_val, dll_val};
	/*------------------------------------------------------------------------------
	--  							Decode stage
	------------------------------------------------------------------------------*/
	// select what the ip_control_block is supposed to output
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			data_out <= '0;
		end else begin
			if(ior) begin
				case (add)
					3'b000: begin
						if(lcr_val[7]) 	data_out <= dll_val;
						else 			data_out <= rhr_val;
					end
					3'b001: begin
						if(lcr_val[7]) 	data_out <= dlm_val;
						else 			data_out <= ier_val;
					end
					3'b010: data_out <= isr_val;
					3'b011: data_out <= lcr_val;
					3'b100: data_out <= mcr_val;
					3'b101: begin
						if(lcr_val[7]) 	data_out <= psd_val; 
						else 			data_out <= lsr_val;
					end
					3'b110: data_out <= msr_val;
					3'b111:	data_out <= spr_val;
				endcase
			end
		end
	end


	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			outen <= '0;
		end else begin
			if(ior) begin
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
		.wr_en (load_rhr)
	);

	//W
	register #(
		.DEFAULT_VAL('0)
	) THR(
		.clk   		(clk)						,
		.resetn		(resetn)					,
		.din   		(data_in)					,
		.wr_en 		((add == '0) && iow && (lcr_val[7] == 0))		,
		.dout  		(thr_val)
	);

	// drive thr_valid to tell the control block that it can be loaded
	always_ff @(posedge clk or negedge resetn) begin
		if(~resetn) begin
			thr_valid <= '0;
		end else begin
			// TODO: once thr is loaded the valid flag should be set to 0
			if((add == '0) && iow && (lcr_val[7] == 0)) thr_valid <= 1'b1;
			else if(tx_ready == 1'b1) thr_valid <= 1'b0;
			else thr_valid <= thr_valid;
		end
	end



	register #(
		.DEFAULT_VAL('0)
	) IER(
		.clk   (clk),
		.resetn(resetn),
		.din   (data_in),
		.wr_en ((add == 3'b001) && iow),
		.dout  (ier_val)
	);

	register #(
		.DEFAULT_VAL(8'b1)
	) ISR(
		.clk   (clk)						,
		.resetn(resetn)						,
		.din   (data_in)					,
		.wr_en ('0)							,
		.dout  (isr_val)
		);

	register #(
		.DEFAULT_VAL('0)
	) FCR(
		.clk   (clk)						,
		.resetn(resetn)						,
		.din   (data_in)					,
		.wr_en ((add == 3'b010) && iow)		,
		.dout  (fcr_val)
	);

	register #(
		.DEFAULT_VAL('0)
	) LCR(
		.clk   (clk)						,
		.resetn(resetn)						,
		.din   (data_in)					,
		.wr_en ((add==3'b011) && iow)		,
		.dout  (lcr_val)
	);

	register #(
		.DEFAULT_VAL('0)
	) MCR(
		.clk   (clk)						,
		.resetn(resetn)						,
		.din   (data_in)					,
		.wr_en ((add==3'b100) && iow)		,
		.dout  (mcr_val)
	);

	register #(
		.DEFAULT_VAL(8'h60)
	) LSR(
		.clk   (clk)						,
		.resetn(resetn)						,
		.din   ('0)							,
		.wr_en ('0)							,
		.dout  (lsr_val)
	);

	register #(
		.DEFAULT_VAL('0)
	) MSR(
		.clk   (clk)									,
		.resetn(resetn)									,
		.din   ('0)										,
		.wr_en ('0)										,
		.dout  (msr_val)
	);

	register #(
		.DEFAULT_VAL('0)
	) SPR(
		.clk   (clk)									,
		.resetn(resetn)									,
		.din   (data_in)								,
		.wr_en ((add == 3'b111) && iow)					,
		.dout  (spr_val)
	);

	register #(
		.DEFAULT_VAL(8'h01)
	) DLL(
		.clk   (clk)									,
		.resetn(resetn)									,
		.din   (data_in)								,
		.wr_en ((add == '0) && iow && lcr_val[7])		,
		.dout  (dll_val)
	);
	
	register #(
		.DEFAULT_VAL(8'h01)
	) DLM(
		.clk   (clk)									,
		.resetn(resetn)									,
		.din   (data_in)								,
		.wr_en ((add == 3'b001) && iow && lcr_val[7])	,
		.dout  (dlm_val)
	);
	
	register #(
		.DEFAULT_VAL('0)
	) PSD(
		.clk   (clk)									,
		.resetn(resetn)									,
		.din   (data_in)								,
		.wr_en ((add==3'b101) && iow && lcr_val[7])		,
		.dout  (psd_val)

	);


	assign lcr_out = lcr_val;
	assign thr_out = thr_val;


endmodule


