//
// File: fht_8x8_core.v
// Author: Ivan Rezki
// Topic: RTL Core
// 		  2-Dimensional Fast Hartley Transform
//

// Matrix Transpose 8x8
// Double Buffer
// Buffer size is 64 words, each word is 16 bits

// Matrix Transpose -> 64 clk delay
//			- Double Buffer Solution:
//			- 1st Step:
//				- Write 64 points into the 1st Buffer
//				- No Read from the 2nd Buffer
//			- 2nd Step:
//				- Read 64 points back from the 1st Buffer
//				- Write 64 points into the 2nd Buffer
//			- 3rd Step:
//				- Write 64 points into the 1st Buffer
//				- Read 64 points back from the 2nd Buffer
//			- Repeat 2nd and 3rd as much as necessary
//			- Last Step:
//				- No Write into the 1st Buffer
//				- Read 64 points back from the 2nd Buffer
//
//			- It requires ...


module fht_mtx_tm_8x8 (
	rstn,
	sclk,
	
	// Input
	inp_valid,
	inp_data,
	
	// Output
	mem_mux_data,
	mem_mux_valid
);
parameter N = 8;

input			rstn;
input			sclk;

input			inp_valid;
input	[N-1:0]	inp_data;
	
output	[N-1:0]	mem_mux_data;
output			mem_mux_valid;

// 1st Buffer wire Interface
wire		mxtr_ram_1_WEN;
wire		mxtr_ram_1_CSN;
wire [ 5:0] mxtr_ram_1_A;
wire [15:0] mxtr_ram_1_D;

// 2nd Buffer wire Interface
wire		mxtr_ram_2_WEN;
wire		mxtr_ram_2_CSN;
wire [ 5:0] mxtr_ram_2_A;
wire [15:0] mxtr_ram_2_D;

// Notice: 1

`ifdef USE_FPGA_SPSRAM
	wire [15:0] mxtr_ram_1_Q;
	wire [15:0] mxtr_ram_2_Q;
	spsram_64x16 u_mxtr_ram_1(
		.addr	(mxtr_ram_1_A),
		.clk	(sclk),
		.din	(mxtr_ram_1_D),
		.dout	(mxtr_ram_1_Q),
		.en		(mxtr_ram_1_CSN),
		.we		(mxtr_ram_1_WEN)
	);

	spsram_64x16 u_mxtr_ram_2(
		.addr	(mxtr_ram_2_A),
		.clk	(sclk),
		.din	(mxtr_ram_2_D),
		.dout	(mxtr_ram_2_Q),
		.en		(mxtr_ram_2_CSN),
		.we		(mxtr_ram_2_WEN)
	);
`endif

`ifdef USE_ASIC_SPSRAM
	reg [15:0] mxtr_ram_1_Q;
	reg [15:0] mxtr_ram_2_Q;
	reg	[15:0] spsram_1[63:0];
	always @(posedge sclk)
		if (~mxtr_ram_1_WEN && ~mxtr_ram_1_CSN) spsram_1[mxtr_ram_1_A] <= mxtr_ram_1_D;	// Write
	always @(posedge sclk)
		if ( mxtr_ram_1_WEN && ~mxtr_ram_1_CSN) mxtr_ram_1_Q <= spsram_1[mxtr_ram_1_A];	// Read

	reg	[15:0]	spsram_2[63:0];
	always @(posedge sclk)
		if (~mxtr_ram_2_WEN && ~mxtr_ram_2_CSN) spsram_2[mxtr_ram_2_A] <= mxtr_ram_2_D;	// Write
	always @(posedge sclk)
		if ( mxtr_ram_2_WEN && ~mxtr_ram_2_CSN) mxtr_ram_2_Q <= spsram_2[mxtr_ram_2_A];	// Read
`endif

// <<<------------------------- 1st Buffer Signal Description  -------------------------->>> \\
assign mxtr_ram_1_CSN = ~inp_valid;
assign tr_mem_1_valid =  inp_valid;

reg [6:0] cnt128d_1;
always @(posedge sclk or negedge rstn)
if		(!rstn)				cnt128d_1 <= #1 0;
else if (tr_mem_1_valid)	cnt128d_1 <= #1 cnt128d_1 + 1;

assign	mem_1_sel = cnt128d_1[6];

assign	mxtr_ram_1_WEN	= ~(tr_mem_1_valid & ~mem_1_sel);

assign	mxtr_ram_1_A	= 
						(tr_mem_1_valid && ~mem_1_sel) ? {cnt128d_1[5:3],cnt128d_1[2:0]} : 
						(tr_mem_1_valid &&  mem_1_sel) ? {cnt128d_1[2:0],cnt128d_1[5:3]} : 
						6'b000_000;

assign	mxtr_ram_1_D	= {{16-N{1'b0}},inp_data};
// <<<----------------------------------------------------------------------------------->>> //

// <<<------------------------- 2nd Buffer Signal Description  -------------------------->>> \\
reg [63:0] inp_valid_r;
always @(posedge sclk or negedge rstn)
if (!rstn)	inp_valid_r[63:0]	<= #1 0;
else		inp_valid_r[63:0]	<= #1 {inp_valid_r[62:0],inp_valid};

assign mxtr_ram_2_CSN = ~inp_valid_r[63];
assign tr_mem_2_valid =  inp_valid_r[63];

reg [6:0] cnt128d_2;
always @(posedge sclk or negedge rstn)
if		(!rstn)				cnt128d_2 <= #1 0;
else if (tr_mem_2_valid)	cnt128d_2 <= #1 cnt128d_2 + 1;

assign	mem_2_sel = cnt128d_2[6];

assign	mxtr_ram_2_WEN	= ~(tr_mem_2_valid & ~mem_2_sel);

assign	mxtr_ram_2_A	= 
						(tr_mem_2_valid && ~mem_2_sel) ? {cnt128d_2[5:3],cnt128d_2[2:0]} : 
						(tr_mem_2_valid &&  mem_2_sel) ? {cnt128d_2[2:0],cnt128d_2[5:3]} : 
						6'b000_000;

assign	mxtr_ram_2_D	= {{16-N{1'b0}},inp_data};
// <<<---------------------------------------------------------------------------------->>> //

wire read_ram_1;
wire read_ram_2;

assign read_ram_1 = (mxtr_ram_1_WEN && ~mxtr_ram_1_CSN) ? 1'b1 : 1'b0;
assign read_ram_2 = (mxtr_ram_2_WEN && ~mxtr_ram_2_CSN) ? 1'b1 : 1'b0;

reg [1:0] read_ram_1_r;
reg [1:0] read_ram_2_r;

always @(posedge sclk or negedge rstn)
if	(!rstn)	read_ram_1_r <= #1 0;
else		read_ram_1_r <= #1 {read_ram_1_r[0],read_ram_1};

always @(posedge sclk or negedge rstn)
if	(!rstn)	read_ram_2_r <= #1 0;
else		read_ram_2_r <= #1 {read_ram_2_r[0],read_ram_2};

assign	mem_mux_data =	(read_ram_1_r[0]) ? mxtr_ram_1_Q[N-1:0] : 
						(read_ram_2_r[0]) ? mxtr_ram_2_Q[N-1:0] : 
						16'h0000;

assign mem_mux_valid = (read_ram_1_r[0] | read_ram_2_r[0]);


endmodule
