`timescale 1ns/1ps

module code_cov (
	input  logic A, B, C, P, Q, R,
	input  bit   clk,
	input  logic rst_n
	);


	logic [3:0] x, y;
	logic [7:0] acc;
	logic [7:0] shreg;
	logic [3:0] vec;
	logic       comb_out;
	logic [7:0] expr_bus;


	function automatic logic [7:0] mix_expr(
		input logic A_i, B_i, C_i, P_i, Q_i, R_i,
		input logic [3:0] x_i, y_i
		);
		
		logic [7:0] t;
	
		begin
			t = {4'(A_i + B_i + C_i + P_i), (x_i ^ y_i)};
			t = (Q_i) ? (t + 8'h1D) : (t - 8'h03);
			t = (R_i) ? (t ^ 8'hA5) : (t ^ 8'h5A);
			mix_expr = t;
		end
	endfunction


	typedef enum logic [1:0] {S_IDLE=2'b00, S_1=2'b01, S_2=2'b10, S_3=2'b11} state_t;
	state_t state, state_n;

	always_comb begin
		state_n = state;
		unique case (state)
			S_IDLE: begin
				if (P) state_n = S_1;
				else   state_n = S_IDLE;
			end

			S_1: begin
				if (R) state_n = S_IDLE;
				else if (Q) state_n = S_2;
				else   state_n = S_3;
			end

			S_2: begin
				if (R) state_n = S_3;
				else   state_n = S_IDLE;
			end

			S_3: begin
				if (A && B) state_n = S_IDLE;
				else        state_n = S_2;
			end
		endcase
	end

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			state   <= S_IDLE;
			x       <= 4'h0;
			y       <= 4'hF;
			acc     <= 8'h00;
			shreg   <= 8'h01;
			vec     <= 4'h0;
			expr_bus<= 8'h00;
		end else begin
			state <= state_n;
			x <= {A,B,C,P};          
			y <= {Q,R,A,B};

			if (A) begin
				acc <= acc + {4'h0, x};
			end else begin
				acc <= acc - {4'h0, y};
			end

			if (B && !C)       shreg <= {shreg[6:0], 1'b1};
			else if (!B && C)  shreg <= {1'b0, shreg[7:1]};
			else               shreg <= shreg ^ 8'hFF;

			unique case ({P,Q})
				2'b00: vec <= vec + 4'd1;
				2'b01: vec <= vec - 4'd1;
				2'b10: vec <= vec ^ x;
				2'b11: vec <= ~vec;
			endcase

			expr_bus <= mix_expr(A,B,C,P,Q,R,x,y);
		end
	end

	always_comb begin
		comb_out = (A ^ B ^ C) ? (P & Q) : (P | R);

		if ((x == 4'h0) && (y == 4'h0)) begin
			comb_out = 1'b0;
		end else if ((x[0] && y[0]) || (x[3] && y[3])) begin
			comb_out = ~comb_out;
		end else begin
			comb_out = comb_out;
		end
	end

endmodule

