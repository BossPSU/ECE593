module HA (input logic a,b,output logic sum, output logic carry);

	xor xor1 (sum, a, b);
	and and1 (carry, a, b);

endmodule
