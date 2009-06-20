//
// File: fht_8x8_core.v
// Author: Ivan Rezki
// Topic: RTL Core
// 		  2-Dimensional Fast Hartley Transform
//

// TOP Level
// 2D FHT 64 points -> ... clk delay
// 
//     +------------------------+
//     |                        |
// --->|    2D FHT/64 Points    |---> 
//     |                        |
//     +------------------------+
//     |<---- .. clk delay ---->|
//

// Data is coming from somewhere (e.g. memory) with sclk one by one.
// 1st step 1D FHT by rows:
//			- Shift Register for 8 points -> ... clk delay
//			- Alligner
// 			- Calculate 1D FHT for 8 points. -> ... clk delay
//				- FF is used on the each input of the butterfly
//				- FF is used on the input of the multiplier
// 2nd Step:
// Matrix Transpose -> 64+1 clk delay
// 			- Collecting data until 1st buffer is full as 64 points.
//			- Read 64 points right away after 1st buffer is full.
//			- At the same time 2nd buffer is ready to receive data.
// 			- Collecting data until 2nd buffer is full as 64 points.
//			- Read 64 points right away after 2nd buffer is full.
//			- At the same time 1st buffer is ready to receive data once again.
//			- ...
// 3rd Step 1D FHT by columns.
// 			- Combine data to make 8 points in parallel. -> ... clk delay
// 			- Calculate 1D FHT for 8 points. -> ... clk delay

// NOTES:
// 1. Matrix Transposition maximum data width is 16 bits.

// ----->>> Define Multiplier Type
//`define USE_ASIC_MULT
//`define USE_FPGA_MULT

// ----->>>  Define Memory Type
//`define USE_FPGA_SPSRAM
//`define USE_ASIC_SPSRAM

module fht_8x8_core (
	rstn,
	sclk,

	x_valid,
	x_data,

	fht_2d_valid,
	fht_2d_data
);
// Number of input bits
parameter N = 8;

input	rstn;
input	sclk;

input			x_valid;
input	[N-1:0] x_data;

output			fht_2d_valid;
output	[N+5:0]	fht_2d_data;

// +++--->>> One-Dimensional Fast Hartley Transform - 1st Stage
// Data input [N-1:0] = N bits
// 
wire			fht_1d_valid;
wire	[N+2:0]	fht_1d_data;

fht_1d_x8 #(N) u1_fht_1d_x8_1st(
	.rstn	(rstn),
	.sclk	(sclk),

	// input data
	.x_valid	(x_valid),
	.x_data		(x_data),
	
	// output data
	.fht_valid	(fht_1d_valid),
	.fht_data	(fht_1d_data)
);

// +++--->>> Matrix Transposition <<<---+++ \\
wire			mem_valid;
wire	[N+2:0]	mem_data;
//mtx_trps_8x8_spsram #(N+3) u2_mtx_ts (
//	.rstn		(rstn),
//	.sclk		(sclk),
//	
//	.inp_valid		(fht_1d_valid),
//	.inp_data		(fht_1d_data),
//
//	.mem_mux_data	(mem_data),
//	.mem_mux_valid	(mem_valid)
//);

mtx_trps_8x8_dpsram #(N+3) u2_mtx_ts (
	.rstn		(rstn),
	.sclk		(sclk),
	
	.inp_valid	(fht_1d_valid),
	.inp_data	(fht_1d_data),

	.mem_data	(mem_data),
	.mem_valid	(mem_valid)
);

// +++--->>> One-Dimensional Fast Hartley Transform - 2nd Stage
fht_1d_x8 #(N+3) u3_fht_1d_x8_2nd(
	.rstn	(rstn),
	.sclk	(sclk),

	// input data
	.x_valid	(mem_valid),
	.x_data		(mem_data),
	
	// output data
	.fht_valid	(fht_2d_valid),
	.fht_data	(fht_2d_data)
);

endmodule
