import MUL_package::*;
module ece593w26_acc(input logic [F_BITS-1:0] a,b, input logic cin, output logic [F_BITS-1:0] sum, output logic cout);
	
	RCA RCA1(a,b,cin,sum,cout);
	
endmodule
