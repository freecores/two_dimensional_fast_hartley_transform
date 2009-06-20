//
// File: signed_mult_const_asic.v
// Author: Ivan Rezki
// Topic: RTL Core
// 		  2-Dimensional Fast Hartley Transform
//

// Signed Multiplier - constant sqrt(2) = 1.41421
// 1.41421*a = (256*1.41421)*a/256 = 362.03776*a/256 = 362*a/256
// product = 362*a/2^8

module signed_mult_const_asic (
	rstn,
	clk,
	valid,
	a,
	p
);

parameter		N = 8;
input			rstn;
input			clk;
input			valid;
input  [N-1:0] a; // variable - positive/negative
output [N  :0] p; // product output

// FHT constant
wire [8:0] mult_constant; // always positive
assign mult_constant = 9'd362;

reg [N-1:0] a_FF;
always @(posedge clk)
if		(!rstn) a_FF <= #1 0;
else if (valid)	a_FF <= #1 a;

// Convert into 2's complement if (a_FF) is negative
wire [N-1:0] b;
assign b = a_FF[N-1] ? {~a_FF[N-1:0] + {{N-1{1'b0}},1'b1} } : a_FF[N-1:0];

// Multiply 2 positive numbers 
// b[N-2:0] * mult_constant[8:0]
// output result mult_wo_sign
// N-2+1 - number of (b) bits
// 8+1   - number of mult_constant bits
// N-2+1+8+1 - number of bits on the output
// = N+8 = [N+7:0]
wire [N+7:0] mult_wo_sign; // mult without sign
assign mult_wo_sign = b[N-2:0]*mult_constant;

// Divide on 256 - [N+7-8:0] = [N-1:0]
wire [N-1:0] div256; // divided 256
assign div256 = mult_wo_sign >> 8;

assign p = a_FF[N-1] ? 
					{1'b1,{~div256[N-1:0] + {{N-1{1'b0}},1'b1}} } : 
					{1'b0,  div256[N-1:0]}
					;
endmodule
