import uvm_pkg::*;
import tb_mtx_pkg::*;

module tb_mtx_mul_unit #(
	parameter WIDTH = 8,
	parameter N = 3
);

	logic clk;
	initial clk = 0;
	always #5 clk = ~clk;
	
	mtx_if #(WIDTH,N) mif(.clk(clk));
	mtx_mul_unit #(.WIDTH(WIDTH),.N(N)) DUT(
		.clk(clk),
		.rst(mif.rst),
  		.start(mif.start),
  		.A(mif.A),
  		.B(mif.B),
  		.C(mif.C),
  		.done(mif.done)
	);
	
	
	initial begin
		uvm_config_db #(virtual mtx_if #(WIDTH, N))::set(null,"uvm_test_top*","vif",mif);
    	end
	
	initial begin
		$dumpfile("tb_mtx_mul_unit.vcd");
		$dumpvars(0,tb_mtx_mul_unit);
	end
	
	initial begin
		$display("=== MTX MUL UNIT UVM TESTBENCH START ===");
        	run_test("mtx_full_test");   // can also be overridden via +UVM_TESTNAME
        	$display("=== TB DONE ===");
	end	
endmodule
