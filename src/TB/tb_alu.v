
`timescale 1ns / 1ps

// FLAGS  7   6   5   4   3   2   1   0
//		  S   Z       H      P/V  N   C

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
		ALU_OPCODE = ALU_FLG;
		ALU_OP1 = 8'h40;
		ALU_INFLAGS = 1'b1;

		#10 $display("operation %d + %d", ALU_OP1, 	ALU_OP2);
		#10 $monitor("alu [%d] %h %h - %h %b", ZALU.STATE, ZALU.PART_RESULT, ZALU.PART_SHIFT, ZALU.PART_RESULT, ZALU.PART_FLAGS );
		#10 $monitor("result %h %b", ALU_RESULT, ALU_OUTFLAGS );
	end

	Z80_ALU ZALU (
		.CLK(			sys_clk),
		.RESET(			1'b0),
		.OPCODE(		ALU_OPCODE),
		.OP1(			ALU_OP1),
		.OP2(			ALU_OP2),
		.INFLAGS(		ALU_INFLAGS),
		.RESULT(		ALU_RESULT),
		.OUTFLAGS(		ALU_OUTFLAGS)
	);

endmodule