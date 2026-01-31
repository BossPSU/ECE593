module FA (input logic a,b,c, output logic sum, output logic carry);

	logic xor1_out;
	logic and1_out, and2_out;

	xor xor1 (xor1_out, a, b);
	xor xor2 (sum, xor1_out, c);

	and and1 (and1_out, a, b);
	and and2 (and2_out, xor1_out, c);

	or or1 (carry, and1_out, and2_out);

endmodule
