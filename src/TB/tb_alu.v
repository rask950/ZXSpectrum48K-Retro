
`timescale 1ns / 1ps

// FLAGS  7   6   5   4   3   2   1   0
//		  S   Z       H      P/V  N   C

module top (
	input sys_clk
);

`include "..\\Global.vh"

	reg			[ 4: 0]	ALU_OPCODE;									// ALU operation code
	reg			[ 7: 0]	ALU_OP1;									// 1st operand
	reg			[ 7: 0]	ALU_OP2;									// 2nd operand
	reg			[ 7: 0]	ALU_INFLAGS;								// Flags in
	reg			[ 7: 0]	ALU_RESULT;									// Result out
	reg			[ 7: 0] ALU_OUTFLAGS;								// Individual output flags
	
	initial begin
		ALU_OPCODE = ALU_ADC;
		ALU_OP1 = 8'h08;
		ALU_OP2 = 8'hC8;
		ALU_INFLAGS = 1'b1;

		#10 $display("operation %d + %d", ALU_OP1, 	ALU_OP2);
		#10 $monitor("alu [%d] %h %h %h - PT %b OUT %b", ZALU.STATE, ZALU.RESULT, ZALU.PART_SHIFT, ZALU.PART_RESULT, ZALU.PART_FLAGS, ALU_OUTFLAGS );
	end

	Z80_ALU4 ZALU (
		.CLK(			sys_clk),
		.ENABLE(		1'b1),
		.OPCODE(		ALU_OPCODE),
		.OP1(			ALU_OP1),
		.OP2(			ALU_OP2),
		.INFLAGS(		ALU_INFLAGS),
		.RESULT(		ALU_RESULT),
		.OUTFLAGS(		ALU_OUTFLAGS)
	);

endmodule