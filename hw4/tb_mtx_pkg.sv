package tb_mtx_pkg;

	import uvm_pkg::*;
	
	localparam int WIDTH = 8;
	localparam int N = 3;
	
	class mtx_seq_item #(int WIDTH=8, int N=3) extends uvm_sequence_item;
		
		//inputs	
		rand logic [WIDTH-1:0] A [N-1:0][N-1:0];
		rand logic [WIDTH-1:0] B [N-1:0][N-1:0];
		//output
		logic [2*WIDTH-1:0] C [N-1:0][N-1:0];
		
		int unsigned mode;
		int unsigned txn_id;
		
		typedef uvm_object_registry #(mtx_seq_item, "mtx_seq_item") type_id;
        	static function type_id get_type(); return type_id::get(); endfunction
       		virtual function uvm_object_wrapper get_object_type();
            		return type_id::get();
        	endfunction
        	virtual function uvm_object create(string name="");
            		mtx_seq_item t = new(name); return t;
        	endfunction
        	static function string type_name(); return "mtx_seq_item"; endfunction
        	virtual function string get_type_name(); return "mtx_seq_item"; endfunction
		
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
		constraint ones_diag {
    			(mode == 4) -> {
				foreach(A[i,j]) A[i][j] == ((i==j) ? 8'h01 : 8'h00);
        			foreach(B[i,j]) B[i][j] == ((i==j) ? 8'h01 : 8'h00);
    			}
		}
		
		constraint cov_sweep {
    			(mode == 5) -> {
        			foreach(A[i,j]) A[i][j] == (i == 0 ? 8'h00 : (i == 1 ? 8'h01 : 8'hFF));
        			foreach(B[i,j]) B[i][j] == (j == 0 ? 8'h00 : (j == 1 ? 8'h01 : 8'hFF));
    			}	
		}
		
		function new(string name = "mtx_seq_item");
			super.new(name);
			mode = 0;
			txn_id = 0;
		endfunction
		
		function mtx_seq_item#(WIDTH,N) clone();
			mtx_seq_item#(WIDTH,N) t;
			t = mtx_seq_item::type_id::create("clone");
			t.mode = this.mode;
			t.txn_id = this.txn_id;
			t.A = this.A;
			t.B = this.B;
			t.C = this.C;
			return t;
		endfunction
	endclass
	
	class mtx_base_seq extends uvm_sequence #(mtx_seq_item);
	
		typedef uvm_object_registry #(mtx_base_seq,"mtx_base_seq") type_id;
        	static function type_id get_type(); return type_id::get(); endfunction
        	virtual function uvm_object_wrapper get_object_type(); return type_id::get(); endfunction
        	virtual function uvm_object create(string name=""); mtx_base_seq t=new(name); return t; endfunction
        	virtual function string get_type_name(); return "mtx_base_seq"; endfunction

        	function new(string name = "mtx_base_seq"); super.new(name); endfunction
		
		task send_item(int unsigned m, int unsigned id);
			mtx_seq_item item;
			item = mtx_seq_item::type_id::create($sformatf("item_m%0d",m));
			item.mode = m;
			item.tx_id = id;
			start_item(item);
			if (!item.randomize())
				`uvm_fatal("RAND", $sformatf("Randomize failed mode=%0d", m))
			finish_item(item);
		endtask
	endclass
	
	class mtx_corner_seq extends mtx_base_seq;
		
		typedef uvm_object_registry #(mtx_corner_seq,"mtx_corner_seq") type_id;
        	static function type_id get_type(); return type_id::get(); endfunction
        	virtual function uvm_object_wrapper get_object_type(); return type_id::get(); endfunction
        	virtual function uvm_object create(string name=""); mtx_corner_seq t=new(name); return t; endfunction
        	virtual function string get_type_name(); return "mtx_corner_seq"; endfunction
        	function new(string name="mtx_corner_seq"); super.new(name); endfunction
		
		task body();
			for (int m =1; m <= 5; m++)
				send_item(m,m-1);
		endtask
	endclass
	
	class mtx_rand_seq extends mtx_base_seq;
	
		typedef uvm_object_registry #(mtx_rand_seq,"mtx_rand_seq") type_id;
        	static function type_id get_type(); return type_id::get(); endfunction
        	virtual function uvm_object_wrapper get_object_type(); return type_id::get(); endfunction
        	virtual function uvm_object create(string name=""); mtx_rand_seq t=new(name); return t; endfunction
        	virtual function string get_type_name(); return "mtx_rand_seq"; endfunction
		
		int unsigned num_txns = 1000;
		
		function new(string name = "mtx_rand_seq");
			super.new(name);
		endfunction
		
		task body();
			for (int i = 0; i < num_txns; i++)
				send_item(0, 5+i);
		endtask
	endclass
	
	class mtx_full_seq extends uvm_sequence #(mtx_seq_item);
	
		typedef uvm_object_registry #(mtx_full_seq,"mtx_full_seq") type_id;
        	static function type_id get_type(); return type_id::get(); endfunction
        	virtual function uvm_object_wrapper get_object_type(); return type_id::get(); endfunction
        	virtual function uvm_object create(string name=""); mtx_full_seq t=new(name); return t; endfunction
        	virtual function string get_type_name(); return "mtx_full_seq"; endfunction
		
		int unsigned num_rand = 1000;
		
		function new(string name = "mtx_full_seq");
			super.new(name);
		endfunction
		
		task body();
			mtx_corner_seq corners;
			mtx_rand_seq randoms;
			
			corners = mtx_corner_seq::type_id::create("corners");
			randoms = mtx_rand_seq::type_id::create("randoms");
			randoms.num_txns = num_rand;
			
			corners.start(m_seqeuncer);
			randoms.start(m_sequencer);
		endtask
	endclass
	
	class mtx_driver extends uvm_driver #(mtx_seq_item);
	
		typedef uvm_component_registry #(mtx_driver,"mtx_driver") type_id;
        	static function type_id get_type(); return type_id::get(); endfunction
        	virtual function uvm_object_wrapper get_object_type(); return type_id::get(); endfunction
        	virtual function uvm_component create_component(string name, uvm_component parent);
            		return new(name,parent);
        	endfunction
        	virtual function string get_type_name(); return "mtx_driver"; endfunction
	
		virtual mtx_if #(WIDTH,N) vif;
		
		function new(string name, uvm_component parent);
			super.new(name, parent);
		endfunction
		
		function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			if (!uvm_config_db #(virtual mtx_if #(WIDTH,N))::get(this, "", "vif", vif))
                		`uvm_fatal("NOVIF", "mtx_driver: cannot get vif from config_db")
		endfunction
		
		task apply_reset();
			vif.drv_cb.rst   <= 1'b1;
      			vif.drv_cb.start <= 1'b0;
      			foreach (vif.drv_cb.A[i,j]) vif.drv_cb.A[i][j] <= '0;
      			foreach (vif.drv_cb.B[i,j]) vif.drv_cb.B[i][j] <= '0;
      			repeat (4) @(vif.drv_cb);
      			vif.drv_cb.rst <= 1'b0;
      			@(vif.drv_cb);
      			`uvm_info("DRV", "Reset de-asserted", UVM_MEDIUM)
      		endtask
      		
      		task drive_one(mtx_seq_item tr);
      			@(vif.drv_cb);
      			foreach (vif.drv_cb.A[i,j]) vif.drv_cb.A[i][j] <= tr.A[i][j];
      			foreach (vif.drv_cb.B[i,j]) vif.drv_cb.B[i][j] <= tr.B[i][j];
			vif.drv_cb.start <= 1'b0;
      			@(vif.drv_cb);
      			vif.drv_cb.start <= 1'b1;
      			@(vif.drv_cb);
      			vif.drv_cb.start <= 1'b0;

      			// Hold A/B stable until done asserted (even though C isn't valid yet)
      			do @(vif.drv_cb); while (vif.drv_cb.done !== 1'b1);

      			repeat (3) @(vif.drv_cb);
		endtask
		
		task run_phase(uvm_phase phase);
			mtx_seq_item tr;
			apply_reset();
			forever begin
				seq_item_port.get_next_item(tr);
				`uvm_info("DRV", $sformatf("Driving txn_id=%0d mode=%0d",tr.txn_id, tr.mode), UVM_HIGH)
				drive_one(tr);
				seq_item_port.item_done();
			end
		endtask
	endclass
	
	class monitor extends uvm_monitor;
	
		typedef uvm_component_registry #(mtx_monitor,"mtx_monitor") type_id;
        	static function type_id get_type(); return type_id::get(); endfunction
        	virtual function uvm_object_wrapper get_object_type(); return type_id::get(); endfunction
        	virtual function uvm_component create_component(string name, uvm_component parent);
            		return new(name,parent);
        	endfunction
        	virtual function string get_type_name(); return "mtx_monitor"; endfunction
		
		virtual mtx_if #(WIDTH,N) vif;
    		uvm_analysis_port #(mtx_seq_item) ap;
    		
    		function new(string name, uvm_component parent);
    			super.new(name, parent);
    		endfunction
    		
    		function void build_phase(uvm_phase phase);
    			super.build_phase(phase);
    			ap = new("ap", this);
    			if (!uvm_config_db #(virtual mtx_if #(WIDTH,N))::get(this, "", "vif", vif))
    				`uvm_fatal("NOVIF", "mtx_monitor: cannot get vif from config_db")
    		endfunction
    		
    		task run_phase(uvm_phase phase);
    			mtx_seq_item pending[$];
    			logic prev_start = 0;
    			logic prev_done = 0;
    			
    			forever begin
    				@(vif.mon_cb);
    				if (vif.mon_cb.start && !prev_start) begin
    					mtx_seq_item tr_in;
    					tr_in = mtx_seq_item::type_id::create("tr_in");
    					foreach (vif.mon_cb.A[i,j]) tr_in.A[i][j] = vif.mon_cb.A[i][j];
          				foreach (vif.mon_cb.B[i,j]) tr_in.B[i][j] = vif.mon_cb.B[i][j];
          				pending.push_back(tr_in);
          				`uvm_info("MON", $sformatf("start detected, pending=%0d",pending.size()), UVM_HIGH)
				end
					
				if (vif.mon_cb.done && !prev_done) begin
					fork
						automatic mtx_seq_item p[$] = pending;
						begin : cap_after_done
							repeat (3) @(vif.mon_cb);
							if (p.size() > 0) begin
								tr_out = pending.pop_front();
								
								foreach (vif.mon_cb.C[i,j]) tr_out.C[i][j] = vif.mon_cb.C[i][j];
								mon2scb.put(tr_out);
								pending = p;
								ap.write(tr_out);
								`uvm_info("MON", $sformatf("C sampled (3 cycles after done), pending=%0d",pending.size()), UVM_HIGH)
							end
							else begin
								`uvm_warning("MON","done seen but pending queue empty!")
							end
						end
					join_none
				end
				
				prev_start = vif.mon_cb.start;
				prev_done = vif.mon_cb.done;
			end
		endtask
	endclass
	
	class mtx_scoreboard extends uvm_scoreboard;
	
		typedef uvm_component_registry #(mtx_scoreboard,"mtx_scoreboard") type_id;
        	static function type_id get_type(); return type_id::get(); endfunction
        	virtual function uvm_object_wrapper get_object_type(); return type_id::get(); endfunction
        	virtual function uvm_component create_component(string name, uvm_component parent);
            		return new(name,parent);
        	endfunction
        	virtual function string get_type_name(); return "mtx_scoreboard"; endfunction
		
		localparam int ACC_BITS = 2*WIDTH;
		
		uvm_analysis_imp #(mtx_seq_item, mtx_scoreboard) analysis_imp;
		
		int unsigned num_checked=0;
    		int unsigned pass_cnt=0;
    		int unsigned fail_cnt=0;
    		
    		function new(string name, uvm_component parent);
    			super.new(name, parent);
    		endfunction
    		
    		function void build_phase(uvm_phase phase)
    			super.build_phase(phase);
    			analysis_imp = new("analysis_imp", this);
    		endfunction	
		
		function automatic logic [ACC_BITS-1:0] golden_cij(
			input logic [WIDTH-1:0] a_row [N],
        		input logic [WIDTH-1:0] b_col [N]
        	);
        		logic [ACC_BITS-1:0] acc = '0;
      			logic [ACC_BITS-1:0] prod;
      			acc = '0;

      			for (int k=0; k<N; k++) begin
      				prod = ACC_BITS'(unsigned'(a_row[k])) * ACC_BITS'(unsigned'(b_col[k]));
      				acc = acc+prod;
      			end
      			return acc;
      		endfunction
      		
      		function void write(mtx_seq_item tr);
      			logic [ACC_BITS-1:0] exp_c [N-1:0][N-1:0];
      			logic [WIDTH-1:0]    a_row [N];
      			logic [WIDTH-1:0]    b_col [N];
      			bit pass =1;    
      			  			
      			for (int i=0; i<N; i++) begin
        			for (int j=0; j<N; j++) begin
          				for (int k=0; k<N; k++) begin
            					a_row[k] = tr.A[i][k];
            					b_col[k] = tr.B[k][j];
          				end
          				exp_c[i][j] = golden_cij(a_row, b_col);
        			 	if (tr.C[i][j] !== exp_c[i][j]) begin
      						`uvm_error("SCB", $sformatf("MISMATCH txn_id=%0d C[%0d][%0d] got=0x%04h exp=0x%04h",tr.txn_id, i, j, tr.C[i][j], exp_c[i][j]))
     						pass = 0;
    					end
       				end
      			end
      				
          		if(pass) pass_cnt++;
          		else fail_cnt++;	
          		num_checked++;
          		
          		`uvm_info("SCB", $sformatf("txn_id=%0d %s  checked=%0d",tr.txn_id, pass ? "PASS" : "FAIL", num_checked), UVM_MEDIUM)
          	endfunction
          	
          	function void report_phase(uvm_phase phase);
          		`uvm_info("SCB", $sformatf(
                		"\n==============================\n" ,
                		"  SCOREBOARD REPORT\n"             ,
                		"  Checked : %0d\n"                 ,
                		"  PASS    : %0d\n"                 ,
                		"  FAIL    : %0d\n"                 ,
                		"==============================" ,
                		num_checked, pass_cnt, fail_cnt), UVM_NONE)
            		if (fail_cnt != 0)
                		`uvm_error("SCB", $sformatf("%0d FAILURES detected!", fail_cnt))
          	endfunction
        endclass
          
	class mtx_coverage extends uvm_subscriber (#mtx_seq_item);
	
		typedef uvm_component_registry #(mtx_coverage,"mtx_coverage") type_id;
        	static function type_id get_type(); return type_id::get(); endfunction
        	virtual function uvm_object_wrapper get_object_type(); return type_id::get(); endfunction
        	virtual function uvm_component create_component(string name, uvm_component parent);
            		return new(name,parent);
        	endfunction
        	virtual function string get_type_name(); return "mtx_coverage"; endfunction
          	
          	mtx_seq_item tr;
          	
          	covergroup cg_matrix_values;
            		cp_a : coverpoint tr.A[0][0] {
                		bins zero = {8'h00};
                		bins one  = {8'h01};
                		bins max  = {8'hFF};
                		bins mid  = {[8'h02 : 8'hFE]};
            		}
            		cp_b : coverpoint tr.B[0][0] {
                		bins zero = {8'h00};
                		bins one  = {8'h01};
                		bins max  = {8'hFF};
                		bins mid  = {[8'h02 : 8'hFE]};
            		}
            		cross_ab : cross cp_a, cp_b;
        	endgroup

        	covergroup cg_modes;
            		cp_mode : coverpoint tr.mode {
                		bins zeros    = {1};
                		bins identity = {2};
                		bins stress   = {3};
                		bins identity2= {4};
                		bins sweep    = {5};
                		bins random   = {0};
            		}
        	endgroup
        	
        	function new(string name, uvm_component parent);
        		super.new(name, parent);
        		tr = mtx_seq_item::type_id::create("tr_cov");
        		cg_matrix_values = new();
        		cg_modes = new;
        	endfunction
        	
        	function void write(mtx_seq_item t);
            		tr = t;
            		cg_matrix_values.sample();
            		cg_modes.sample();
            		// Sample all element combinations for thorough coverage
            		for (int i = 0; i < N; i++)
                		for (int j = 0; j < N; j++) begin
                    		tr.A[0][0] = t.A[i][j];
                    		tr.B[0][0] = t.B[i][j];
                    		cg_matrix_values.sample();
                	end
        	endfunction
        	
        	function void report_phase(uvm_phase phase);
            		`uvm_info("COV", $sformatf("\n  Matrix Values Coverage : %.2f%%\n  Mode Coverage           : %.2f%%",
                	cg_matrix_values.get_coverage(),
                	cg_modes.get_coverage()), UVM_NONE)
        	endfunction
	endclass 
        
        class mtx_agent extends uvm_agent;
        
        	typedef uvm_component_registry #(mtx_agent,"mtx_agent") type_id;
        	static function type_id get_type(); return type_id::get(); endfunction
        	virtual function uvm_object_wrapper get_object_type(); return type_id::get(); endfunction
        	virtual function uvm_component create_component(string name, uvm_component parent);
            		return new(name,parent);
        	endfunction
       		virtual function string get_type_name(); return "mtx_agent"; endfunction

        	mtx_driver                  drv;
        	mtx_monitor                 mon;
        	uvm_sequencer #(mtx_seq_item) seqr;

        	uvm_analysis_port #(mtx_seq_item) ap;  // forwarded from monitor

        	function new(string name, uvm_component parent);
            		super.new(name, parent);
        	endfunction

        	function void build_phase(uvm_phase phase);
            		super.build_phase(phase);
            		seqr = uvm_sequencer #(mtx_seq_item)::type_id::create("seqr", this);
            		drv  = mtx_driver::type_id::create("drv",  this);
            		mon  = mtx_monitor::type_id::create("mon", this);
            		ap   = new("ap", this);
        	endfunction

        	function void connect_phase(uvm_phase phase);
            		drv.seq_item_port.connect(seqr.seq_item_export);
            		mon.ap.connect(ap);
        	endfunction
    	endclass 
          
        class mtx_environment extends uvm_env;
        
        	typedef uvm_component_registry #(mtx_env,"mtx_env") type_id;
        	static function type_id get_type(); return type_id::get(); endfunction
        	virtual function uvm_object_wrapper get_object_type(); return type_id::get(); endfunction
        	virtual function uvm_component create_component(string name, uvm_component parent);
            		return new(name,parent);
        	endfunction
        	virtual function string get_type_name(); return "mtx_env"; endfunction
          	
          	mtx_agent       agent;
        	mtx_scoreboard  scb;
        	mtx_coverage    cov;

        	function new(string name, uvm_component parent);
            		super.new(name, parent);
        	endfunction

        	function void build_phase(uvm_phase phase);
            		super.build_phase(phase);
            		agent = mtx_agent::type_id::create("agent", this);
            		scb   = mtx_scoreboard::type_id::create("scb", this);
            		cov   = mtx_coverage::type_id::create("cov", this);
        	endfunction

        	function void connect_phase(uvm_phase phase);
            		agent.ap.connect(scb.analysis_imp);
            		agent.ap.connect(cov.analysis_export);
        	endfunction
    	endclass

  	class mtx_base_test extends uvm_test;
  	
  		typedef uvm_component_registry #(mtx_base_test,"mtx_base_test") type_id;
        	static function type_id get_type(); return type_id::get(); endfunction
        	virtual function uvm_object_wrapper get_object_type(); return type_id::get(); endfunction
        	virtual function uvm_component create_component(string name, uvm_component parent);
            		return new(name,parent);
        	endfunction
        	virtual function string get_type_name(); return "mtx_base_test"; endfunction
  		
  		mtx_env env;
  		
  		function new(string name, uvm_component parent);
            		super.new(name, parent);
        	endfunction

        	function void build_phase(uvm_phase phase);
            		super.build_phase(phase);
            		env = mtx_env::type_id::create("env", this);
        	endfunction
        endclass
        
        class mtx_full_test extends mtx_base_test;
        	`uvm_component_utils(mtx_full_test)

        	function new(string name, uvm_component parent);
            		super.new(name, parent);
        		endfunction

        	task run_phase(uvm_phase phase);
            		mtx_full_seq seq;
            		phase.raise_objection(this);
            		seq = mtx_full_seq::type_id::create("seq");
            		seq.num_rand = 1000;
            		seq.start(env.agent.seqr);
            		// Small drain delay after last transaction
            		#200;
            		phase.drop_objection(this);
        	endtask
    	endclass
	
	 class mtx_corner_test extends mtx_base_test;
	 
        	typedef uvm_component_registry #(mtx_full_test,"mtx_full_test") type_id;
        	static function type_id get_type(); return type_id::get(); endfunction
        	virtual function uvm_object_wrapper get_object_type(); return type_id::get(); endfunction
        	virtual function uvm_component create_component(string name, uvm_component parent);
            		return new(name,parent);
        	endfunction
        	virtual function string get_type_name(); return "mtx_full_test"; endfunction

        	function new(string name, uvm_component parent);
            		super.new(name, parent);
        		endfunction

        	task run_phase(uvm_phase phase);
            		mtx_corner_seq seq;
            		phase.raise_objection(this);
            		seq = mtx_corner_seq::type_id::create("seq");
            		seq.start(env.agent.seqr);
            		#200;
            		phase.drop_objection(this);
        	endtask
    	endclass 
endpackage 

	
