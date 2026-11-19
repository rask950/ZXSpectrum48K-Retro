
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
	reg					ALU_ENABLE;	

	reg			[ 7: 0] H;
	reg			[ 7: 0] L;

	reg			[ 7: 0]	COUNT;

	reg			[ 2: 0]	FSM_STATE;

	initial begin
		FSM_STATE = 3'b000;
		H = 8'h98;
		L = 8'h76;	
		COUNT = 8'h00;

		#0 $monitor("[%d][%d] ALU [%d][%h] OP1 %h OP2 %h - PR %h PS %h PF %b - OF %h R %h", COUNT, FSM_STATE, ZALU.ENABLE, ALU_OPCODE, ALU_OP1, ALU_OP2, ZALU.PART_RESULT, ZALU.PART_SHIFT, ZALU.PART_FLAGS, ALU_OUTFLAGS, ALU_RESULT);
	end

	always @(posedge sys_clk) begin

		COUNT <= COUNT + 1;

		case(FSM_STATE)

		3'b000: begin
			ALU_OPCODE 	<= ALU_XOR;
			ALU_OP1 <= 8'hAA;
			ALU_OP2 <= 8'hAB;
			ALU_INFLAGS <= 1'b0;
			ALU_ENABLE <= TRUE;
			FSM_STATE <= 3'b001;
		end

		3'b001: begin
			ALU_ENABLE <= FALSE;
			FSM_STATE <= 3'b101;
		end

		3'b010: begin
			L <= ALU_RESULT;
			ALU_OP1 <= H;
			ALU_INFLAGS <= ALU_OUTFLAGS;
			ALU_ENABLE <= TRUE;
			FSM_STATE <= 3'b011;
		end

		3'b011: begin
			ALU_ENABLE <= FALSE;
			FSM_STATE <= 3'b100;
		end

		3'b100: begin
			H <= ALU_RESULT;
			FSM_STATE <= 3'b101;
		end

		3'b101: begin
		end

		endcase

	end

	Z80_ALU4 ZALU (
		.ENABLE(		ALU_ENABLE),
		.OPCODE(		ALU_OPCODE),
		.OP1(			ALU_OP1),
		.OP2(			ALU_OP2),
		.INFLAGS(		ALU_INFLAGS),
		.RESULT(		ALU_RESULT),
		.OUTFLAGS(		ALU_OUTFLAGS)
	);

endmodule