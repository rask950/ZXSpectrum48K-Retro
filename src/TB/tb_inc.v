
`timescale 1ns / 1ps

module tb_inc (
	input sys_clk
);

`include "..\\Global.vh"

	reg					INC_DIR;									// Incrementer direction
	reg					INC_BITS;									// Number of bits (0=7, 1=16)
	reg			[15: 0]	INC_IN;										// Input to incrementer
	wire			[15: 0]	INC_OUT;									// Output from incrementer

	initial begin
		INC_DIR = 1'b1;
		INC_BITS = 1'b1;
		INC_IN = 16'h007F;

		#10 $monitor("direction %b bits %b input %h output %h", INC_DIR, INC_BITS, INC_IN, INC_OUT );
	end

	Z80_INCREMENTER2 ZINC (
		.INC_DIR(		INC_DIR),
		.INC_BITS(		INC_BITS),
		.INC_IN(		INC_IN),
		.INC_OUT(		INC_OUT)
	);

endmodule