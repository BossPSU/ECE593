import tb_mtx_pkg::*;

module tb_mtx_mul_unit #(
	parameter WIDTH = 8,
	parameter N = 3
);

	logic clk;
	initial clk = 0;
	always #5 clk = ~clk;
	
	mtx_if #(WIDTH,N) mif(clk);
	mtx_mul_unit #(.WIDTH(WIDTH),.N(N)) DUT(
		.clk(clk),
		.rst(mif.rst),
  		.start(mif.start),
  		.A(mif.A),
  		.B(mif.B),
  		.C(mif.C),
  		.done(mif.done)
	);
	mtx_environment#(WIDTH,N) env;
	
	
	initial begin
		$display("=== MTX MUL UNIT TB START ===");
    		env = new(mif.DRV,mif.MON,1000);
    		env.run();
    		$display("=== TB DONE ===");
    		$finish;
    	end
	
	initial begin
		$dumpfile("tb_mtx_mul_unit.vcd");
		$dumpvars(0,tb_mtx_mul_unit);
	end
	
endmodule
