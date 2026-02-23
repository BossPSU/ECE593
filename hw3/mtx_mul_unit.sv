//////////////////////////////////////////////////
// Accumulator unit
// For ECE581/ECE530 ASIC Classes
// Synthesis and Physical Design and
// For ECE-593 Pre-Si Validation Class
// Prepared by Venkatesh Patil (v.p@pdx.edu)
/////////////////////////////////////////////////
//D - Flipflop
module dff (
    input  clk,
    input  rst,
    input  d,
    output reg q
);
    always @(posedge clk)
        if (rst) q <= 1'b0;
        else     q <= d;
endmodule

//Full Adder
module full_adder_g (
    input  a, b, cin,
    output sum, cout
);
    wire a1, a2, a3;

    xor (sum, a, b, cin);
    and (a1, a, b);
	and (a2, b, cin);
	and (a3, a, cin);
    or  (cout, a1, a2, a3);
endmodule

//Accumulator
module acc_unit #(
    parameter WIDTH = 16
)(
    input  rst,
    input  clk,
    input  [WIDTH-1:0] mul2acc,
    output [WIDTH-1:0] f
);

    wire [WIDTH-1:0] sum;
    wire [WIDTH:0]   carry;
	
	// carry[0] is 0
    buf(carry[0],1'b0);

    // Ripple-carry adder
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : ADDER
            full_adder_g FA (
                .a   (f[i]),
                .b   (mul2acc[i]),
                .cin (carry[i]),
                .sum (sum[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate
	// If carry[WIDTH]=1, then there is a overflow f has to be of size WIDTH+1
	// But as given f is of size WIDTH and not WIDTH+1,
   // I'm ignoring the carry(additional bit) and proceeding with WIDTH no. of bits 
   // for subsequent additions
	
	
    // Register to store multiple bits
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : REG
            dff dff_inst (
                .clk(clk),
                .rst(rst),
                .d  (sum[i]),
                .q  (f[i])
            );
        end
    endgenerate

endmodule



/////////////////////////////////////////////////////////////
// Wallace tree multiplier implementation at structural level
// For ECE581/ECE530 Classes and
// For ECE-593 Pre-Si Validation Class
//
// Prepared by Venkatesh Patil (v.p@pdx.edu)
// ///////////////////////////////////////////////////////////

// Full Adder
module full_adder (
    input  logic a, b, cin,
    output logic sum, cout
);
    wire a1, a2, a3;
 
    xor (sum, a, b, cin);
    and (a1, a, b);
    and (a2, a, cin);
    and (a3, b, cin);
    or  (cout, a1, a2, a3);

endmodule

//Multiplier logic
module mul_unit #(
    parameter WIDTH = 8
)(
    input  logic rst,
    input  logic clk,
    input  logic [WIDTH-1:0] w2mul,
    input  logic [WIDTH-1:0] x2mul,
    output logic [2*WIDTH-1:0] mul2acc
);
  
    localparam PWIDTH = 2*WIDTH;
    logic [2*WIDTH-1:0] temp;
    

    // Step 1: Partial products generation
		
		//array to store partial products
    	wire [WIDTH-1:0] pp [WIDTH-1:0]; 
    
	genvar i, j;
    	generate
        	for (i = 0; i < WIDTH; i++) begin : pp_row
            	for (j = 0; j < WIDTH; j++) begin : pp_column
                	and (pp[i][j], w2mul[j], x2mul[i]);
            	end
        	end
    	endgenerate
    

    // Step2: Bit matrix alignment
	// Creating a bit matrix by shifting partial products
    // and appending zeros for remaining left, right bits 
    wire [PWIDTH-1:0] bit_matrix [WIDTH-1:0];
        
    generate
        for (i = 0; i < WIDTH; i++) begin : matrix_rows
            for (j = 0; j < PWIDTH; j++) begin : matrix_columns
                if (j >= i && j < i+WIDTH) begin : valid_bit
                    buf (bit_matrix[i][j], pp[i][j-i]);
                end 
				else begin : zero_bit
                    buf (bit_matrix[i][j], 1'b0);
                end
            end
        end
    endgenerate
    

    // Step3: Wallace tree reduction
		
		//Array to store intermediate sums
    	wire [PWIDTH:0] sum [WIDTH:0]; 
    
    	// Initialize sum[0] = 0 - (sum of stage 0) 
    	generate
        	for (j = 0; j <= PWIDTH; j++) begin : init_sum
            	buf (sum[0][j], 1'b0);
        	end
    	endgenerate
    
    	// Sequentially add each partial product - ripple carry adders
    	generate
        for (i = 0; i < WIDTH; i++) begin : add_chain
            wire [PWIDTH:0] carry;
            
            // Carry in for LSB is 0
            buf (carry[0], 1'b0);
            
            for (j = 0; j < PWIDTH; j++) begin : add_bits
                full_adder FA (
                    .a(sum[i][j]),
                    .b(bit_matrix[i][j]),
                    .cin(carry[j]),
                    .sum(sum[i+1][j]),
                    .cout(carry[j+1])
                );
            end
            
            // MSB carry propagates to next stage
            buf (sum[i+1][PWIDTH], carry[PWIDTH]);
        end
    	endgenerate
    
    	// Final sum result - last stage
    	generate
        	for (j = 0; j < PWIDTH; j++) begin : final_sum
            	buf (temp[j], sum[WIDTH][j]);
        	end
    	endgenerate

	//Flipflop to store mul2acc
	always@(posedge clk) begin
		if(rst)
		mul2acc <= 0;
		else
		mul2acc <= temp;
	end

endmodule


/////////////////////////////////////////////////
// MAC unit top design
// Instantiates multiplier and accumulator units
// For ECE581/ECE530 ASIC Classes and
// For ECE-593 Pre-Si Validation Class
//
// Venkatesh Patil (v.p@pdx.edu)
////////////////////////////////////////////////

module mac_unit #(
    parameter WIDTH = 8
)(
    input  rst,
    input  clk,
    input unsigned [WIDTH-1:0] w,
    input unsigned [WIDTH-1:0] x,
    output unsigned [2*WIDTH-1:0] f
);

	//Internal signals
	logic [WIDTH-1:0] w2mul, x2mul;
	logic [2*WIDTH-1:0] mul2acc;

	//Flipflop to store w2mul
	always @(posedge clk) begin
        if (rst) w2mul <= '0;
        else     w2mul <= w;
	end

	//Flipflop to store x2mul
	always @(posedge clk) begin
        if (rst) x2mul <= '0;
        else     x2mul <= x;
	end
	
	//Multiplier
	mul_unit #(.WIDTH(WIDTH)) multiplier
			(.rst(rst), 
			 .clk(clk),
			 .w2mul(w2mul),
			 .x2mul(x2mul), 
			 .mul2acc(mul2acc)
			 );
	
	//Accumulator
	acc_unit #(.WIDTH(2*WIDTH)) accumulator 
			(.rst(rst),
			 .clk(clk),
			 .mul2acc(mul2acc),
			 .f(f)
			);
			
endmodule

/////////////////////////////////////////////////
// Matrix Multiplication Unit top design
// Instantiates MAC units
// For ECE581/ECE530 ASIC Classes and
// For ECE-593 Pre-Si Validation Class
//
// Venkatesh Patil (v.p@pdx.edu)
////////////////////////////////////////////////


module mtx_mul_unit #(
    parameter WIDTH = 16,
    parameter N = 3 // Matrix size NxN
)(
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic [WIDTH-1:0] A [N-1:0][N-1:0],
    input  logic [WIDTH-1:0] B [N-1:0][N-1:0],
    output logic [2*WIDTH-1:0] C [N-1:0][N-1:0],
    output logic done
);

    // Control logic for dot product accumulation
    // In a real system, we need to feed the row/column elements sequentially 
    // to the MAC unit.
    logic [$clog2(N):0] count;
    logic active;

    always_ff @(posedge clk) begin
        if (rst) begin
            count <= 0;
            active <= 0;
            done <= 0;
        end else if (start) begin
            count <= 0;
            active <= 1;
            done <= 0;
        end else if (active) begin
            if (count == N-1) begin
                active <= 0;
                done <= 1;
            end else begin
                count <= count + 1;
            end
        end
    end

    // Instantiate an NxN grid of MACs
    genvar i, j;
    generate
        for (i = 0; i < N; i++) begin : row
            for (j = 0; j < N; j++) begin : col
                // Each MAC calculates C[i][j] = sum(A[i][k] * B[k][j])
                // We mux the inputs based on the current 'count' index
                mac_unit #(.WIDTH(WIDTH)) mac_inst (
                    .clk(clk),
                    .rst(rst || start), // Reset accumulator at start of new matmul
                    .w(A[i][count]),    // Row i, element k
                    .x(B[count][j]),    // Column j, element k
                    .f(C[i][j])
                );
            end
        end
    endgenerate

endmodule


