import MUL_package::*;
module ece593w26_mac(
	input logic clk, rst,
	input logic [BITS-1:0] w,x,
	output logic [F_BITS-1:0] f
);

	logic [BITS-1:0] w2mul,x2mul;
	logic [F_BITS-1:0] mul2acc, acc2f, mul, sum;
	logic cout;
	
	assign f = acc2f;

	always_ff @(posedge clk or posedge rst) begin
		if(rst)begin
			w2mul <= 0;
			x2mul <= 0;
			mul2acc <= 0;
			acc2f <= 0;
		end else begin
			w2mul <= w;
			x2mul <= x;
			mul2acc <= mul;
			acc2f <= sum;
		end
	end
	
	ece593w26_mul MUL(w2mul,x2mul,mul);
	ece593w26_acc ACC(mul2acc,acc2f, 1'b0, sum, cout);

endmodule
