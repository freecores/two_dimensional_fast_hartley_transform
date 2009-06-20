//
// File: signed_mult_const_fpga.v
// Author: Ivan Rezki
// Topic: RTL Core
// 		  2-Dimensional Fast Hartley Transform
//

// Signed Multiplier - constant sqrt(2) = 1.41421

// 8 bit accuracy:
// 1.41421*a = (256*1.41421)*a/256 = 362.03776*a/256 = 362*a/256
// product = 362*a/2^8
// wire [8:0] mult_constant = 9'd362;

// 15 bit accuracy:
// 1.41421*a = (32768*1.41421)*a/32768 = 46340.95*a/32768
// product = 46341*a/2^15
// wire [15:0] mult_constant = 16'd46341;

// 16 bit accuracy:
// 1.41421*a = (65536*1.41421)*a/65536 = 92681*a/65536
// product = 92681*a/2^16
// wire [16:0] mult_constant = 17'd92681;

module signed_mult_const_fpga (
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
input  signed [N-1:0] a; // variable - positive/negative
output signed [N  :0] p; // product output

// FHT constant
// wire [8:0] mult_constant; // always positive
// assign mult_constant = 9'd362;

wire signed [17:0] mult_constant; // always positive
assign mult_constant = {1'b0, 17'd92681};

reg signed [N-1:0] a_FF;
always @(posedge clk)
if		(!rstn) a_FF <= #1 0;
else if (valid)	a_FF <= #1 a;

wire signed [(16+1)+N-1:0] p_tmp = $signed(a_FF) * $signed(mult_constant);

//assign p = p_tmp[(16+1)+N-1:16];// >> 16;
assign p = p_tmp >> 16;

endmodule
