`timescale 1ns/1ps

module code_cov_tb;

	logic A, B, C, P, Q, R;
	bit   clk;
	logic rst_n;

	code_cov dut (
		.A(A), .B(B), .C(C), .P(P), .Q(Q), .R(R),
		.clk(clk),
		.rst_n(rst_n)
	);

	always #25 clk = ~clk;

	task automatic apply_inputs(input logic a,b,c,p,q,r);
		begin
			A=a; B=b; C=c; P=p; Q=q; R=r;
			@(posedge clk);
		end
	endtask

	initial begin
	
		clk  = 0;
		rst_n= 0;
		A=0; B=0; C=0; P=0; Q=0; R=0;

		repeat (2) @(posedge clk);
		rst_n = 1;

		for (int i = 0; i < 64; i++) begin
			apply_inputs(i[0], i[1], i[2], i[3], i[4], i[5]);
		end

		apply_inputs(0,0,0, 1,0,0);
		apply_inputs(0,0,0, 0,1,0);
		apply_inputs(0,0,0, 0,0,1);
		apply_inputs(0,1,0, 0,0,0);
		apply_inputs(0,0,0, 0,0,0);
		apply_inputs(0,0,0, 1,0,0);
		apply_inputs(0,0,0, 0,0,0);
		apply_inputs(1,1,0, 0,0,0);
		apply_inputs(0,0,0, 0,0,0);
		apply_inputs(1,1,0, 0,1,0);
		
		repeat (5) @(posedge clk);
		$stop;
	end

endmodule

