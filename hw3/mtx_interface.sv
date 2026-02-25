interface mtx_if #(parameter int WIDTH=8, parameter int N=3)(input logic clk);
	logic rst,start,done;
	logic [WIDTH-1:0]   A [N-1:0][N-1:0];
  	logic [WIDTH-1:0]   B [N-1:0][N-1:0];
  	logic [2*WIDTH-1:0] C [N-1:0][N-1:0];
  	
  	clocking drv_cb @(posedge clk);
  		default input #1step;
  		default output #1ns;
  		output rst, start, A, B;
  		input done, C;
  	endclocking
  	
  	clocking mon_cb @(posedge clk);
  		default input #1step;
  		input rst, start, A, B;
  		input done, C;
  	endclocking
  	
  	modport DUT (input clk, rst, start, A, B, output C, done);
  	modport DRV (input clk, done, C, output rst, start, A, B, clocking drv_cb);
  	modport MON (input clk, rst, start, A, B, C, clocking mon_cb);
endinterface : mtx_if
