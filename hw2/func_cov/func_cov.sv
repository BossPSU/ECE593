`timescale 1ns/1ps

module func_cov(
	input  logic X, Y, Z, T, U, V,
	input  bit   clk,
	input  logic rst_n
	);

	typedef enum logic [1:0] {S0, S1, S2, S3} state_t;
	state_t st, st_n;

	always_comb begin
		st_n = st;
		unique case (st)
			S0: if (X)  st_n = S1; else if (Y) st_n = S2;
			S1: if (Z)  st_n = S3; else if (!X) st_n = S0;
			S2: if (T)  st_n = S3; else if (!Y) st_n = S0;
			S3: if (U)  st_n = S0; else if (V)  st_n = S1;
			default: st_n = S0;
		endcase
	end

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) st <= S0;
		else        st <= st_n;
	end


	covergroup cg_inputs @(posedge clk);
		option.per_instance = 1;


		coverpoint {X,Y} iff (rst_n)  // cp1
			{
			bins xy_00 = {2'b00};          // explicit bin
			bins xy_others = default;      // implicit (default) bin covers remaining values
			ignore_bins xy_11 = {2'b11};   // ignore bin
			}

		coverpoint Z iff (rst_n)         // cp2
			{
			bins z_rise = (0 => 1);        // transition bin
			bins z_fall = (1 => 0);        // transition bin
			}

		coverpoint U iff (rst_n)         // cp3
			{
			bins u_3_consec = (1[*3]);     // repetition (consecutive) bin
			}
	endgroup

	covergroup cg_ctrl @(posedge clk);
		option.per_instance = 1;


		coverpoint st iff (rst_n) 	// cp4
			{
			bins fsm_seq = (S0 => S1 => S3 => S0); // one FSM transition bin
			}

		coverpoint {T,V} iff (rst_n)     // cp5
			{
			wildcard bins tv_wild_0x = {2'b0?};         // wildcard bin (matches 00 or 01)
			bins tv_10_twice = (2'b10 [->2]);  // repetition (non-consecutive): hit "10" twice, not necessarily back-to-back
			bins tv_11 = {2'b11};              // explicit bin
			}
	endgroup

	cg_inputs cg1 = new();
	cg_ctrl   cg2 = new();

endmodule

