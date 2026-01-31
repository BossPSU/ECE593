import MUL_package::*;
module mac_tb();

	logic clk,rst;
	logic [BITS-1:0] w,x;
	logic [F_BITS-1:0] f;
	logic [F_BITS-1:0] expected_f;
	int tests, fails;
	
	always #50 clk = ~clk;
	
	ece593w26_mac MAC(.*);
	
	initial begin
		clk = 0;
		rst = 1;
		tests = 0;
		fails = 0;
		
		@(posedge clk);
		rst = 0;
		//input w and x at first cycle, then a new w and x at second clock cycle
		//check first w and x multiplication at 3rd clock cycle
		//check second w and x multiplication + previous result at 4th clock cycle
		for (int i = 0; i<256; i++) begin
			for (int j = 0; j<256; j++) begin
				tests++;
				rst = 0;
				w = i[7:0];
				x = j[7:0];
				@(posedge clk);
				#25; //time for combinational logic to complete
				expected_f = w*x; //check multiplier only
				w = $urandom();
				x = $urandom();
				repeat (2) @(posedge clk); //wait for pipeline to fill
				#25;
				if (f != expected_f) begin
					$display("Error: W=%0d, X=%0d, expected f=%0d, actual f=%0d",w,x,expected_f,f);
					fails++;
				end
				@(posedge clk); //check accumulator by adding output to previous output
				#25; //time for combinational logic to complete
				expected_f += w*x;
				if (f != expected_f) begin
					$display("Error: W=%0d, X=%0d, expected f=%0d, actual f=%0d",w,x,expected_f,f);
					fails++;
				end
				rst = 1; //reset everything to 0 and give time for logic to settle
				#5;
				if (tests % 10000 == 0) begin
					$display("---- Completed %0d tests ----", tests);
				end
			end
		end
		$display("FAILS: %0d",fails);
		$stop;
	end
endmodule
