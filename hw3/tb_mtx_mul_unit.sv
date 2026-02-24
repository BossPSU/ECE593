module tb_mtx_mul_unit (
	parameter WIDTH = 16,
	parameter N = 3
)(
	input  logic clk,
    	input  logic rst,
    	input  logic start,
    	input  logic [WIDTH-1:0] A [N-1:0][N-1:0],
    	input  logic [WIDTH-1:0] B [N-1:0][N-1:0],
    	output logic [2*WIDTH-1:0] C [N-1:0][N-1:0],
    	output logic done
);

	mtx_mul_unit DUT(.*);
	
