`timescale 1ns/1ps

module func_cov_tb;

	logic X, Y, Z, T, U, V;
	bit   clk;
	logic rst_n;

	func_cov dut (
		.X(X), .Y(Y), .Z(Z), .T(T), .U(U), .V(V),
		.clk(clk),
		.rst_n(rst_n)
		);

	initial clk = 0;
	always #5 clk = ~clk;


	task automatic drive_and_tick(
		input logic x_i, y_i, z_i, t_i, u_i, v_i
		);
		begin
			X = x_i; Y = y_i; Z = z_i; T = t_i; U = u_i; V = v_i;
			@(posedge clk);
			#1; 
		end
	endtask

	initial begin

		X=0; Y=0; Z=0; T=0; U=0; V=0;
		rst_n = 0;
		repeat (2) @(posedge clk);
		rst_n = 1;
		@(posedge clk);

		drive_and_tick(0,0, 0,0,0,0);  // hits xy_00
		drive_and_tick(0,1, 0,0,0,0);  // hits xy_others (implicit)
		drive_and_tick(1,1, 0,0,0,0);  // hits ignore bin (doesn't count)

		drive_and_tick(0,0, 0,0,0,0);  // ensure Z=0 sampled
		drive_and_tick(0,0, 1,0,0,0);  // 0=>1 rise
		drive_and_tick(0,0, 0,0,0,0);  // 1=>0 fall


		drive_and_tick(0,0, 0,0,1,0);
		drive_and_tick(0,0, 0,0,1,0);
		drive_and_tick(0,0, 0,0,1,0);  // hits u_3_consec


		drive_and_tick(0,0, 0,0,0,0);  // {T,V}=00 hits wildcard

		drive_and_tick(0,0, 0,1,0,0);  // {T,V}=10 (first hit)
		drive_and_tick(0,0, 0,0,0,1);  // {T,V}=01 (gap)
		drive_and_tick(0,0, 0,1,0,0);  // {T,V}=10 (second hit) => hits tv_10_twice

		drive_and_tick(0,0, 0,1,0,1);  // {T,V}=11 hits tv_11


		drive_and_tick(0,0, 0,0,0,0);

		drive_and_tick(1,0, 0,0,0,0);
		drive_and_tick(1,0, 1,0,0,0);
		drive_and_tick(0,0, 0,0,1,0);

		repeat (3) @(posedge clk);
		$display("TB completed. Check coverage report for bin hits.");
		$stop;
	end

endmodule

