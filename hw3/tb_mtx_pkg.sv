package tb_mtx_pkg.sv;

	//transaction
	class mtx_transaction #(int WIDTH=8, int N=3);
		
		//inputs
		rand logic [WIDTH-1:0] A [N-1:0][N-1:0];
		rand logic [WIDTH-1:0] B [N-1:0][N-1:0];
		//output
		logic [2*WIDTH-1:0] C [N-1:0][N-1:0];
		
		constraint zero_a {
			(mode == 1) -> { foreach(A[i,j]) A[i][j] == 8'h00; }
		}
		constraint zero_b {
			(mode == 1) -> { foreach(B[i,j]) B[i][j] == 8'h00; }
		}
		constraint identity {
			(mode == 2) -> {
			 foreach(B[i,j]) B[i][j] == ((i == j) ? 8'h01 : 8'h00); 
			 }
		}
		constraint stress_a {
			(mode == 3) -> { foreach(A[i,j]) A[i][j] == 8'hFF; }
		}
		constraint stress_b {
			(mode == 3) -> { foreach(A[i,j]) A[i][j] == 8'hFF; }
		}
		
	endclass
	
	//generator
	class mtx_generator;
		
		mailbox #(mtx_transaction) gen2drv;
		int unsigned num_rand;
		
		function new(mailbox #(mtx_transaction) mb, int unsigned n = 1000);
			gen2driver = mb;
			num_rand = n;
		endfunction
		
		task run();
			mtx_transaction tx;
			
			//test corner cases (mode 1-3)
			tx = new(1);
			gen2drv.put(tx);
			tx = new(2);
			gen2drv.put(tx);
			tx = new(3);
			gen2drv.put(tx);
			
			//test 1000 cases (transactions are random without constraints)
			for (int i = 0; i < num_rand; i++) begin
				tx = new();
				gen2drv.put(tx);
			end
		endtask
	endclass : generator
	
	class mtx_driver #(int WIDTH=8, int N=3);
	
		virtual mxt_if#(WIDTH,N).DRV vif
		mailbox #(mtx_transaction#(WIDTH,N)) gen2drv;
		
		function new(virtual mtx_if#(WIDTH,N).DRV vi, mailbox #(mtx_transaction#(WIDTH,N)) m);
			vif = vi;
			gen2drv = m;
		endfunction
		
		task apply_reset();
			vif.drv_cb.rst   <= 1'b1;
      			vif.drv_cb.start <= 1'b0;
      			foreach (vif.drv_cb.A[i,j]) vif.drv_cb.A[i][j] <= '0;
      			foreach (vif.drv_cb.B[i,j]) vif.drv_cb.B[i][j] <= '0;
      			repeat (2) @(vif.drv_cb);
      			vif.drv_cb.rst <= 1'b0;
      			repeat (1) @(vif.drv_cb);
      		endtask
      		
      		task drive_one(mtx_transaciton#(WIDTH,N) tr);
      			foreach (vif.drv_cb.A[i,j]) vif.drv_cb.A[i][j] <= tr.A[i][j];
      			foreach (vif.drv_cb.B[i,j]) vif.drv_cb.B[i][j] <= tr.B[i][j];

      			@(vif.drv_cb);
      			vif.drv_cb.start <= 1'b1;
      			@(vif.drv_cb);
      			vif.drv_cb.start <= 1'b0;

      			// Hold A/B stable until done asserted (even though C isn't valid yet)
      			do @(vif.drv_cb); while (vif.drv_cb.done !== 1'b1);

      			// After done, you may release A/B (optional)
      			// foreach (vif.drv_cb.A[i,j]) vif.drv_cb.A[i][j] <= 'x;
      			// foreach (vif.drv_cb.B[i,j]) vif.drv_cb.B[i][j] <= 'x;
		endtask
		
		task run();
			mtx_transaction#(WIDTH,N) tr;
			forever begin
				gen2drv.get(tr);
				drive_one(tr);
			end
		endtask
	endclass
	
	class monitor #(int WIDTH=8, int N=3);
		virtual mtx_if#(WIDTH,N).MON vif;
    		mailbox #(mtx_transaction#(WIDTH,N)) mon2scb;
    		
    		function new(virtual mtx_if#(WIDTH,N).MON vi, mailbox (#mtx_transaction#(WIDTH,N)) m);
    			vif = vi;
    			mon2scb = m;
    		endfunction
    		
    		task run();
    			mtx_transaction#(WIDTH,N) tr;
    			forever begin
    			@(vif.mon_cb);
    			if (vif.mon_cb.start === 1'b1) begin
    				tr = new();
    					foreach (vif.mon_cb.A[i,j]) tr.A[i][j] = vif.mon_cb.A[i][j];
          				foreach (vif.mon_cb.B[i,j]) tr.B[i][j] = vif.mon_cb.B[i][j];
					do @(vif.mon_cb);
					while (vif.mon_cb.done !== 1'b1);
					repeat (3) @(vif.mon_cb);
					
					foreach (vif.mon_cb.C[i,j]) tr.C_obs[i][j] = vif.mon_cb.C[i][j];			
					mon2scb.put(tr);
				end
			end
		endtask
	endclass
	
	
			
