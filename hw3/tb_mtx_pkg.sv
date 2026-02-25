package tb_mtx_pkg;

	//transaction
	class mtx_transaction #(int WIDTH=8, int N=3);
		
		//inputs
		rand logic [WIDTH-1:0] A [N-1:0][N-1:0];
		rand logic [WIDTH-1:0] B [N-1:0][N-1:0];
		//output
		logic [2*WIDTH-1:0] C [N-1:0][N-1:0];
		
		int unsigned mode;
		int unsigned txn_id;
		
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
			(mode == 3) -> { foreach(B[i,j]) B[i][j] == 8'hFF; }
		}
		
		function new(int unsigned m = 0, int unsigned id = 0);
			mode = m;
			txn_id = id;
		endfunction
		
		function mtx_transaction#(WIDTH,N) clone();
			mtx_transaction#(WIDTH,N) t = new(mode, txn_id);
			t.A = this.A;
			t.B = this.B;
			t.C = this.C;
			return t;
		endfunction
	endclass
	
	//generator
	class mtx_generator #(int WIDTH=8, int N=3);
		
		mailbox #(mtx_transaction#(WIDTH,N)) gen2drv;
		int unsigned num_rand;
		
		event gen_done;
		
		function new(mailbox #(mtx_transaction#(WIDTH,N)) mb, int unsigned n = 1000);
			gen2drv = mb;
			num_rand = n;
		endfunction
		
		task run();
			mtx_transaction#(WIDTH,N) tx;
			int unsigned id = 0;
			
			//test corner cases (mode 1-3)
			tx = new(1,id++);
			assert(tx.randomize());
			gen2drv.put(tx.clone());
			tx = new(2,id++);
			assert(tx.randomize());
			gen2drv.put(tx.clone());
			tx = new(3,id++);
			assert(tx.randomize());
			gen2drv.put(tx.clone());
			
			//test 1000 cases (transactions are random without constraints)
			for (int i = 0; i < num_rand; i++) begin
				tx = new(0,id++);
				assert(tx.randomize());
				gen2drv.put(tx.clone());
			end
		endtask
	endclass
	
	class mtx_driver #(int WIDTH=8, int N=3);
	
		virtual mtx_if#(WIDTH,N).DRV vif;
		mailbox #(mtx_transaction#(WIDTH,N)) gen2drv;
		
		function new(virtual mtx_if#(WIDTH,N).DRV vi, mailbox #(mtx_transaction#(WIDTH,N)) m);
			vif = vi;
			gen2drv = m;
		endfunction
		
		task apply_reset();
			vif.drv_cb.rst   <= 1'b1;
      			vif.drv_cb.start <= 1'b0;
      			foreach (vif.A[i,j]) vif.A[i][j] <= '0;
      			foreach (vif.B[i,j]) vif.B[i][j] <= '0;
      			repeat (4) @(vif.drv_cb);
      			vif.rst <= 1'b0;
      			@(vif.drv_cb);
      		endtask
      		
      		task drive_one(mtx_transaction#(WIDTH,N) tr);
      			@(vif.drv_cb);
      			foreach (vif.A[i,j]) vif.A[i][j] <= tr.A[i][j];
      			foreach (vif.B[i,j]) vif.B[i][j] <= tr.B[i][j];
			vif.start <= 1'b0;
      			@(vif.drv_cb);
      			vif.start <= 1'b1;
      			@(vif.drv_cb);
      			vif.start <= 1'b0;

      			// Hold A/B stable until done asserted (even though C isn't valid yet)
      			do @(vif.drv_cb); while (vif.done !== 1'b1);

      			repeat (3) @(vif.drv_cb);
		endtask
		
		task run(int unsigned total);
			mtx_transaction#(WIDTH,N) tr;
			apply_reset();
			repeat (total) begin
				gen2drv.get(tr);
				drive_one(tr);
			end
			$display("[DRV] done driving %0d", total);
		endtask
	endclass
	
	class monitor #(int WIDTH=8, int N=3);
		virtual mtx_if#(WIDTH,N).MON vif;
    		mailbox #(mtx_transaction#(WIDTH,N)) mon2scb;
    		
    		mtx_transaction#(WIDTH,N) pending[$];
    		
    		function new(virtual mtx_if#(WIDTH,N).MON vi, mailbox #(mtx_transaction#(WIDTH,N)) m);
    			vif = vi;
    			mon2scb = m;
    		endfunction
    		
    		task run(int unsigned total);
    			mtx_transaction#(WIDTH,N) tr_in, tr_out;
    			logic prev_start = 0;
    			logic prev_done = 0;
    			int count = 0;
    			
    			forever begin
    				@(vif.mon_cb);
    				if (vif.mon_cb.start && !prev_start) begin
    					tr_in = new();
    					foreach (vif.mon_cb.A[i,j]) tr_in.A[i][j] = vif.mon_cb.A[i][j];
          				foreach (vif.mon_cb.B[i,j]) tr_in.B[i][j] = vif.mon_cb.B[i][j];
          				pending.push_back(tr_in);
				end
					
				if (vif.mon_cb.done && !prev_done) begin
					fork
						begin : cap_after_done
							repeat (3) @(vif.mon_cb);
							if (pending.size() >0) begin
								tr_out = pending.pop_front();
								
								foreach (vif.mon_cb.C[i,j]) tr_out.C[i][j] = vif.mon_cb.C[i][j];
								mon2scb.put(tr_out);
								count++;
								$display("[MON] captured %0d/%0d", count, total);
							end
							else begin
								$warning("[MON] done seen but pending queue empty at t=%0t", $time);
							end
						end
					join_none
				end
				
				prev_start = vif.mon_cb.start;
				prev_done = vif.mon_cb.done;
			end
		endtask
	endclass
	
	class mtx_scoreboard #(int WIDTH=8, int N=3);
	
		localparam int ACC_BITS = 2*WIDTH;
		
		mailbox #(mtx_transaction#(WIDTH,N)) mon2scb;
		
		int unsigned num_checked=0;
    		int unsigned pass_cnt=0;
    		int unsigned fail_cnt=0;
		
		covergroup cg with function sample(logic [WIDTH-1:0] av, logic [WIDTH-1:0] bv);
			cp_a : coverpoint av {
				bins zero = {'0};
        			bins one  = {1};
        			bins max  = {{WIDTH{1'b1}}};
        			bins mid  = {[2 : (1<<WIDTH)-2]};
        		}
        		cp_b : coverpoint bv {
        			bins zero = {'0};
        			bins one  = {1};
        			bins max  = {{WIDTH{1'b1}}};
        			bins mid  = {[2 : (1<<WIDTH)-2]};
			}
			cross_ab : cross cp_a, cp_b;
		endgroup
		
		
		function new(mailbox #(mtx_transaction#(WIDTH,N)) mb);
			mon2scb = mb;
			cg = new();
		endfunction
		
		function automatic logic [ACC_BITS-1:0] golden_cij(
			input logic [WIDTH-1:0] a_row [N],
        		input logic [WIDTH-1:0] b_col [N]
        	);
        		logic [ACC_BITS-1:0] acc;
      			logic [ACC_BITS-1:0] prod;
      			acc = '0;

      			for (int k=0; k<N; k++) begin
      				prod = ACC_BITS'(unsigned'(a_row[k])) * ACC_BITS'(unsigned'(b_col[k]));
      				acc = acc+prod;
      			end
      			return acc;
      		endfunction
      		
      		task run();
      			mtx_transaction#(WIDTH,N) tr;
      			
      			logic [ACC_BITS-1:0] exp_c [N-1:0][N-1:0];
      			logic [WIDTH-1:0]    a_row [N];
      			logic [WIDTH-1:0]    b_col [N];

      			bit pass;

      			forever begin
      				mon2scb.get(tr);
      				pass = 1;
      				
      				for (int i=0; i<N; i++) begin
        				for (int j=0; j<N; j++) begin
          					for (int k=0; k<N; k++) begin
            						a_row[k] = tr.A[i][k];
            						b_col[k] = tr.B[k][j];
          					end
          					exp_c[i][j] = golden_cij(a_row, b_col);
        				 	if (tr.C[i][j] !== exp_c[i][j]) begin
      							$error("[SCB] MISMATCH C[%0d][%0d] got=%0h exp=%0h", i, j, tr.C[i][j], exp_c[i][j]);
     							pass = 0;
    						end
        				end
      				end
      				
      				for (int i=0; i<N; i++)
        				for (int j=0; j<N; j++)
          					cg.sample(tr.A[i][j], tr.B[i][j]);
          			if(pass) pass_cnt++;
          			else fail_cnt++;
          			
          			num_checked++;
          		end
          	endtask
          	
          	function void report();
          		$display("Checked=%0d Pass=%0d Fail=%0d", num_checked, pass_cnt, fail_cnt);
          		$display("FCov    : %0.2f%%", cg.get_coverage());
          	endfunction
          endclass
          
          class mtx_environment #(int WIDTH=8, int N=3);
          	
          	mtx_generator   #(WIDTH,N)    gen;
  		mtx_driver      #(WIDTH,N)    drv;
  		monitor         #(WIDTH,N)    mon;   
  		mtx_scoreboard  #(WIDTH,N)    scb;

  		// Mailboxes
  		mailbox #(mtx_transaction#(WIDTH,N)) gen2drv;
  		mailbox #(mtx_transaction#(WIDTH,N)) mon2scb;

  		// Virtual interfaces
  		virtual mtx_if#(WIDTH,N).DRV drv_vif;
  		virtual mtx_if#(WIDTH,N).MON mon_vif;

  		int unsigned num_rand;
  		int unsigned total;
  		
  		function new(virtual mtx_if#(WIDTH,N).DRV dv,virtual mtx_if#(WIDTH,N).MON mv,int unsigned n = 1000);
  		
  			drv_vif = dv;
    			mon_vif = mv;
    			num_rand = n;
    			total    = n + 3;
    			gen2drv  = new();
    			mon2scb  = new();
    			gen = new(gen2drv, num_rand);
    			drv = new(drv_vif, gen2drv);
    			mon = new(mon_vif, mon2scb);
    			scb = new(mon2scb);
    			
    		endfunction
    		
    		task run();
    			fork
    				gen.run();
    				drv.run(total);
    				mon.run(total);
    				scb.run();
    			join_none
    			
    			wait (scb.num_checked == total);
    			repeat(5) @(drv_vif.drv_cb);
    			scb.report();
    		endtask
    	endclass
	
endpackage 		
