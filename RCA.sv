import MUL_package::*;
module RCA(
	input logic [F_BITS-1:0] a,b,
	input logic cin,
	output logic[F_BITS-1:0] sum,
	output logic cout
);
	
	logic [F_BITS:0] c;
	assign c[0] = cin;
	
	genvar i;
	generate
		for (i=0; i<F_BITS; i++) begin : GEN_FA
			FA u_fa(
				.a (a[i]),
				.b (b[i]),
				.c (c[i]),
				.sum (sum[i]),
				.carry(c[i+1])
			);
		end
	endgenerate
	
	assign cout = c[F_BITS];

endmodule
