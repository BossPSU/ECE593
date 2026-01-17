import MUL_package::*;
module ece593w26_mul(input logic [BITS-1:0] a,b, output logic [F_BITS-1:0] prod);
	
	//unpacked arrays to store wallace tree sums and carries
	logic s[52:0];
	logic c[53:0];
	
	//final 16bit numbers for RCA generated from Wallace tree reduction
	logic [F_BITS-1:0] reduced_Wallace[1:0];
	
	//partial product array
	logic p[BITS-1:0][BITS-1:0];
	always_comb begin
		for (int i=0; i<BITS; i++)begin
			for (int j=0; j<BITS; j++)begin
			p[j][i] = a[j] & b[i];
			end
		end
	end
	
	//wallace tree reduction stages
	//partial prodcut rows grouped into groups of three, extra rows passed
	//collums with 1pp are passed, 2pp use HA, 3pp use FA
	//groups are reduced from 3rows to 2 rows each stage
	//continue stages until only 2 rows remain, then use RCA to get product
	//groups and reduction shown in excel file
	
	
	//Wallace Tree Reduction HA and FA
	//stage 1 group 1
	HA HA1(p[0][1],p[1][0],s[0],c[0]);
	FA FA1(p[0][2],p[1][1],p[2][0],s[1],c[1]);
	FA FA2(p[0][3],p[1][2],p[2][1],s[2],c[2]);
	FA FA3(p[0][4],p[1][3],p[2][2],s[3],c[3]);
	FA FA4(p[0][5],p[1][4],p[2][3],s[4],c[4]);
	FA FA5(p[0][6],p[1][5],p[2][4],s[5],c[5]);
	FA FA6(p[0][7],p[1][6],p[2][5],s[6],c[6]);
	HA HA2(p[1][7],p[2][6],s[7],c[7]);
	
	//stage 1 group 2 
	HA HA3(p[3][1],p[4][0],s[8],c[8]);
	FA FA7(p[3][2],p[4][1],p[5][0],s[9],c[9]);
	FA FA8(p[3][3],p[4][2],p[5][1],s[10],c[10]);
	FA FA9(p[3][4],p[4][3],p[5][2],s[11],c[11]);
	FA FA10(p[3][5],p[4][4],p[5][3],s[12],c[12]);
	FA FA11(p[3][6],p[4][5],p[5][4],s[13],c[13]);
	FA FA12(p[3][7],p[4][6],p[5][5],s[14],c[14]);
	HA HA4(p[4][7],p[5][6],s[15],c[15]);
	
	//stage 2 group 1
	HA HA5(s[1],c[0],s[16],c[16]);
	FA FA13(s[2],c[1],p[3][0],s[17],c[17]);
	FA FA14(s[3],c[2],s[8],s[18],c[18]);
	FA FA15(s[4],c[3],s[9],s[19],c[19]);
	FA FA16(s[5],c[4],s[10],s[20],c[20]);
	FA FA17(s[6],c[5],s[11],s[21],c[21]);
	FA FA18(s[7],c[6],s[12],s[22],c[22]);
	FA FA19(p[2][7],c[7],s[13],s[23],c[23]);
	
	//stage 2 group 2
	HA HA6(c[9],p[6][0],s[24],c[24]);
	FA FA20(c[10],p[6][1],p[7][0],s[25],c[25]);
	FA FA21(c[11],p[6][2],p[7][1],s[26],c[26]);
	FA FA22(c[12],p[6][3],p[7][2],s[27],c[27]);
	FA FA23(c[13],p[6][4],p[7][3],s[28],c[28]);
	FA FA24(c[14],p[6][5],p[7][4],s[29],c[29]);
	FA FA25(c[15],p[6][6],p[7][5],s[30],c[30]);
	HA HA7(p[6][7],p[7][6],s[31],c[31]);
	
	//stage 3
	HA HA8(s[17],c[16],s[32],c[32]);
	HA HA9(s[18],c[17],s[33],c[33]);
	FA FA26(s[19],c[18],c[8],s[34],c[34]);
	FA FA27(s[20],c[19],s[24],s[35],c[35]);
	FA FA28(s[21],c[20],s[25],s[36],c[36]);
	FA FA29(s[22],c[21],s[26],s[37],c[37]);
	FA FA30(s[23],c[22],s[27],s[38],c[38]);
	FA FA31(s[14],c[23],s[28],s[39],c[39]);
	HA HA10(s[15],s[29],s[40],c[40]);
	HA HA11(p[5][7],s[30],s[41],c[41]);
	
	//stage 4
	HA HA12(s[33],c[32],s[42],c[42]);
	HA HA13(s[34],c[33],s[43],c[43]);
	HA HA14(s[35],c[34],s[44],c[44]);
	FA FA32(s[36],c[35],c[24],s[45],c[45]);
	FA FA33(s[37],c[36],c[25],s[46],c[46]);
	FA FA34(s[38],c[37],c[26],s[47],c[47]);
	FA FA35(s[39],c[38],c[27],s[48],c[48]);
	FA FA36(s[40],c[39],c[28],s[49],c[49]);
	FA FA37(s[41],c[40],c[29],s[50],c[50]);
	FA FA38(s[31],c[41],c[30],s[51],c[51]);
	HA HA15(p[7][7],c[31],s[52],c[52]);
	
	//assign reduced wallace and RCA
	assign reduced_Wallace[0] = {1'b0,s[52],s[51],s[50],s[49],s[48],s[47],s[46],s[45],s[44],s[43],s[42],s[32],s[16],s[0],p[0][0]};
	assign reduced_Wallace[1] = {c[52],c[51],c[50],c[49],c[48],c[47],c[46],c[45],c[44],c[43],c[42], 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
	
	RCA RCA1(reduced_Wallace[0],reduced_Wallace[1],1'b0,prod,c[53]);
endmodule
	
	
	
	
