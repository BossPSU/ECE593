import mtx_interface::*;
import tb_mtx_pkg::*;

module tb_mtx_mul_unit (
	parameter WIDTH = 16,
	parameter N = 3
);

	logic clk = 0;
	always #5 clk = ~clk;
	
	mtx_mul_unit DUT(.*);
	env #(WIDTH,N) e;
	
	  // Simple reset check required by spec: done=0 and all C=0 after rst :contentReference[oaicite:13]{index=13}
  	task automatic check_reset_outputs();
    		if (mif.done !== 1'b0) $fatal(1, "[RSTCHK] done not 0 after reset");
    		foreach (mif.C[i,j]) begin
      			if (mif.C[i][j] !== '0) $fatal(1, "[RSTCHK] C[%0d][%0d] not 0 after reset", i, j);
    		end
  	endtask

  	initial begin
    		// Init
    		mif.start = 0;
    		mif.rst   = 0;
    		foreach (mif.A[i,j]) mif.A[i][j] = '0;
    		foreach (mif.B[i,j]) mif.B[i][j] = '0;

    		e = new(mif.DRV, mif.MON);

    		// Apply reset and check
    		e.drv.apply_reset();
    		repeat (1) @(posedge clk);
    		check_reset_outputs();

    		// Run environment
    		e.run();

    		// Stop once we’ve observed enough scoreboard passes
    		// (Generator sends 3 corner + 1000 random by default)
    		wait (e.scb.pass_cnt + e.scb.fail_cnt >= (3 + e.gen.num_random));

    		$display("========================================");
    		$display("TB DONE: PASS=%0d FAIL=%0d", e.scb.pass_cnt, e.scb.fail_cnt);
    		$display("Coverage (cg) = %0.2f%%", e.scb.cg.get_coverage());
    		$display("========================================");

    		if (e.scb.fail_cnt != 0) $fatal(1, "Mismatches detected");
    		$finish;
  	end

endmodule
