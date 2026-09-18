
`timescale 1ns / 1ps

// FLAGS  7   6   5   4   3   2   1   0
//	  S   Z       H      P/V  N   C

module tb_alu (
	input sys_clk
);

`include "..\\Global.vh"

	reg			[ 4: 0]	ALU_OPCODE;									// ALU operation code
	reg			[ 7: 0]	ALU_OP1;									// 1st operand
	reg			[ 7: 0]	ALU_OP2;									// 2nd operand
	reg			[ 7: 0]	ALU_INFLAGS;								// Flags in
	reg			[ 7: 0]	ALU_RESULT;									// Result out
	reg			[ 7: 0]	ALU_OUTFLAGS;								// Flags out

	initial begin
		ALU_OPCODE = ALU_CP;
		ALU_OP1 = 4;
		ALU_OP2 = 4;
		ALU_INFLAGS = 0;
		ALU_RESULT = 0;
		ALU_OUTFLAGS = 0;

		#10 $monitor("result %d ($%h) flags: $%h", ALU_RESULT, ALU_RESULT, ALU_OUTFLAGS );
	end

	Z80_ALU ZALU (
		.opcode(		ALU_OPCODE),
		.op1(			ALU_OP1),
		.op2(			ALU_OP2),
		.inflags(		ALU_INFLAGS),
		.result(		ALU_RESULT),
		.outflags(		ALU_OUTFLAGS)
	);

endmodule