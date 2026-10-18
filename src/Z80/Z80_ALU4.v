`timescale 1ns / 1ps

module Z80_ALU (
	
	input					CLK,
	input					RESET,
	input  reg		[ 4: 0]	OPCODE,									// This is the ALU opcode (NOT the CPU opcode)
	input  reg		[ 7: 0]	OP1,
	input  reg		[ 7: 0]	OP2,
	input  reg		[ 7: 0]	INFLAGS,
	output reg		[ 7: 0]	RESULT,
	output reg		[ 7: 0]	OUTFLAGS
);

`include "..\\Global.vh"

localparam			STATE_IDLE   = 2'b00;					// Idle state
localparam			STATE_LOWER  = 2'b01;					// Lower nibble state
localparam			STATE_UPPER  = 2'b10;					// Upper nibble state
localparam			STATE_RESULT = 2'b11;					// Result

reg 		[ 1: 0]	STATE;

reg			[ 3: 0]	OP1_HALF;								// Inputs to primitives
reg			[ 3: 0]	OP2_HALF;
reg					OP_CARRY;
reg					Z_FLAG;
reg					S_FLAG;
reg					P_FLAG;
reg					H_FLAG;

reg			[ 3: 0]	RESULT_LOWER;							// Store lowwer nibble result

wire		[ 3: 0]	PART_RESULT;							// Partial result from the ALU operations
wire		[ 1: 0]	PART_FLAGS;								// Partial flags C, V from ALU operations

initial begin
	STATE = STATE_LOWER;
end

always @(*) begin

	casez(OPCODE)

	ALU_SHL: begin
		case(STATE)
			STATE_LOWER: begin

			end
			STATE_UPPER: begin
			end
			STATE_RESULT: begin
			end
		endcase
	end

	ALU_SHR: begin
		case(STATE)
			STATE_LOWER: begin
			end
			STATE_UPPER: begin
			end
			STATE_RESULT: begin
			end
		endcase
	end

	ALU_BSR: begin
		case(STATE)
			STATE_LOWER: begin
			end
			STATE_UPPER: begin
			end
			STATE_RESULT: begin
			end
		endcase
	end

	ALU_DAA: begin
		case(STATE)
			STATE_LOWER: begin
				OP1_HALF = OP1[3:0];
				OP2_HALF = OP2[3:0];
				OP_CARRY = INFLAGS[FLAG_H];
			end
			STATE_UPPER: begin
			end
			STATE_RESULT: begin
			end
		endcase
	end

	ALU_FLG: begin
		case(STATE)
			STATE_LOWER: begin
				{ PART_RESULT, RESULT_LOWER } = OP1;
				OP_CARRY = FALSE;
			end
			STATE_UPPER: begin
			end
			STATE_RESULT: begin
			end
		endcase
	end

	default: begin
		case(STATE)
			STATE_LOWER: begin
				OP1_HALF = OP1[3:0];
				OP2_HALF = OP2[3:0];
				OP_CARRY = OPCODE[0] & INFLAGS[FLAG_C];
			end
			STATE_UPPER: begin
			end
			STATE_RESULT: begin
			end
		endcase
	end

	endcase
	
end

FLAGSETTER flag_instance (
	.PART_RESULT( { PART_RESULT, RESULT_LOWER } ),
	.Z(				Z_FLAG),
	.S(				S_FLAG),
	.P(				P_FLAG)
);

ADD4 add_instance (
	.OP1(			OP1_HALF),
	.OP2(			OP2_HALF),
	.CARRY(			OP_CARRY),
	.ENABLE(		OPCODE == ALU_ADD | OPCODE == ALU_ADC),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

SUB4 sub_instance (
	.OP1(			OP1_HALF),
	.OP2(			OP2_HALF),
	.CARRY(			OP_CARRY),
	.ENABLE(		OPCODE == ALU_SUB | OPCODE == ALU_SBC | OPCODE == ALU_CP),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

endmodule

////////////////////////////////////////////////////////////////
// ADD/ADC

module ADD4(
	input		[ 3: 0]	OP1,
	input		[ 3: 0]	OP2,
	input				CARRY,
	input				ENABLE,
	output 		[ 3: 0]	PART_RESULT,
	output 		[ 1: 0]	PART_FLAGS
);

	wire			[ 3: 0]	r;
	wire			[ 3: 0]	c;

ADDSUB1 add0( r[0], OP1[0], OP2[0], CARRY);
ADDC1	adc0( c[0], OP1[0], OP2[0], CARRY);

ADDSUB1 add1( r[1], OP1[1], OP2[1], c[0]);
ADDC1	adc1( c[1], OP1[1], OP2[1], c[0]);

ADDSUB1 add2( r[2], OP1[2], OP2[2], c[1]);
ADDC1	adc2( c[2], OP1[2], OP2[2], c[1]);

ADDSUB1 add3( r[3], OP1[3], OP2[3], c[2]);
ADDC1	adc3( c[3], OP1[3], OP2[3], c[2]);

assign PART_RESULT = ENABLE ?		r : 4'bz;
assign PART_FLAGS  = ENABLE ?  c[3:2] : 2'bz;

endmodule

////////////////////////////////////////////////////////////////
// SUB/SBC

module SUB4(
	input		[ 3: 0]	OP1,
	input		[ 3: 0]	OP2,
	input				CARRY,
	input				ENABLE,
	output 		[ 3: 0]	PART_RESULT,
	output 		[ 1: 0]	PART_FLAGS
);

	wire			[ 3: 0]	r;
	wire			[ 3: 0]	c;

ADDSUB1 add0( r[0], OP1[0], OP2[0], CARRY);
SUBC1	adc0( c[0], OP1[0], OP2[0], CARRY);

ADDSUB1 add1( r[1], OP1[1], OP2[1], c[0]);
SUBC1	adc1( c[1], OP1[1], OP2[1], c[0]);

ADDSUB1 add2( r[2], OP1[2], OP2[2], c[1]);
SUBC1	adc2( c[2], OP1[2], OP2[2], c[1]);

ADDSUB1 add3( r[3], OP1[3], OP2[3], c[2]);
SUBC1	adc3( c[3], OP1[3], OP2[3], c[2]);

assign PART_RESULT = ENABLE ?		r : 4'bz;
assign PART_FLAGS  = ENABLE ?  c[3:2] : 2'bz;

endmodule

////////////////////////////////////////////////////////////////
// FLAG SETTER

module FLAGSETTER (										 			// Set flags according to partial result and flags ...
	input		[ 7: 0]	PART_RESULT,
	output		Z,
	output		S,
	output		P
);
	assign		Z = PART_RESULT == 0;
	assign		S = PART_RESULT[7];
	assign		P = ~^PART_RESULT;

endmodule

////////////////////////////////////////////////////////////////
// SHIFT/ROTATE

module SHLEFT (
	input		[ 3: 0]	OP1,
	input				CARRY,
	input				ENABLE,
	output 		[ 3: 0]	PART_RESULT,
	output 		[ 1: 0]	PART_FLAGS);

	assign PART_RESULT = ENABLE ? { OP1[2:0], CARRY } : 4'bz;		// Shift left operation
	assign PART_FLAGS  = ENABLE ? OP1[3:2] : 2'bz;

endmodule

module SHRIGHT (
	input		[ 3: 0]	OP1,
	input				CARRY,
	input				ENABLE,
	output 		[ 3: 0]	PART_RESULT,
	output 		[ 1: 0]	PART_FLAGS);

	assign PART_RESULT = ENABLE ? { CARRY, OP1[3:1] } : 4'bz;		// Shift right operation
	assign PART_FLAGS  = ENABLE ? OP1[3:2] : 2'bz;

endmodule

////////////////////////////////////////////////////////////////
// Primitives

primitive ADDSUB1 (													// Add AND subtract one bit with carry
	output 				R,
	input 				A, B, C
);

	table
	//  A 	B 	C	R
		0	0	0 :	0;
		0	0	1 :	1;
		0	1	0 :	1;
		0	1	1 :	0;
		1	0	0 :	1;
		1	0	1 :	0;
		1	1	0 :	0;
		1	1	1 :	1;
	endtable

endprimitive

primitive ADDC1 (													// Calculate carry for one bit addition
	output 				R,
	input 				A, B, C
);

	table
		// A 	B 	C	R
			0	0	0 :	0;
			0	0	1 :	0;
			0	1	0 :	0;
			0	1	1 :	1;
			1	0	0 :	0;
			1	0	1 :	1;
			1	1	0 :	1;
			1	1	1 :	1;
		endtable

endprimitive

primitive SUBC1 (													// Calculate carry for one bit subtraction
	output 				R,
	input 				A, B, C
);

	table
		// A 	B 	C	R
			0	0	0 :	0;
			0	0	1 :	1;
			0	1	0 :	1;
			0	1	1 :	1;
			1	0	0 :	0;
			1	0	1 :	0;
			1	1	0 :	0;
			1	1	1 :	1;
		endtable

endprimitive