`timescale 1ns / 1ps

module Z80_ALU (
	input  reg		[ 4: 0]	OPCODE,									// This is the ALU opcode (NOT the CPU opcode)
	input  reg		[ 7: 0]	OP1,
	input  reg		[ 7: 0]	OP2,
	input  reg		[ 7: 0]	INFLAGS,
	output wire		[ 7: 0]	RESULT,
	output wire		[ 7: 0]	OUTFLAGS
);

`include "..\\Global.vh"

	wire			[ 7: 0]	PART_RESULT;							// Partial result from the ALU operations
	wire			[ 3: 0]	PART_FLAGS;								// Partial flags (C, P/V, N, H) from ALU operations

	assign RESULT = OPCODE == ALU_CP ? OP1 : PART_RESULT;			// The result is not used for CP only

FLAGSETTER flags0(													// This takes the partial results and sets the final OUTFLAGS
	.OPCODE(		OPCODE),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS),
	.OUTFLAGS(		OUTFLAGS)
);

FLG8 flg0(									// Set flags ONLY 
	.OP1(			OP1),
	.CARRY(			INFLAGS[FLAG_C]),
	.ENABLE(		OPCODE == ALU_FLG),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

ADD8 add0(
	.OP1(			OP1),
	.OP2(			OP2),
	.CARRY(			FALSE),
	.ENABLE(		OPCODE == ALU_ADD),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

ADD8 adc0(
	.OP1(			OP1),
	.OP2(			OP2),
	.CARRY(			INFLAGS[FLAG_C]),
	.ENABLE(		OPCODE == ALU_ADC),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

SUB8 sub0(
	.OP1(			OP1),
	.OP2(			OP2),
	.CARRY(			FALSE),
	.ENABLE(		OPCODE == ALU_SUB),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

SUB8 sbc0(
	.OP1(			OP1),
	.OP2(			OP2),
	.CARRY(			INFLAGS[FLAG_C]),
	.ENABLE(		OPCODE == ALU_SBC),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

AND8 and0(
	.OP1(			OP1),
	.OP2(			OP2),
	.ENABLE(		OPCODE == ALU_AND),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

OR8 or0(
	.OP1(			OP1),
	.OP2(			OP2),
	.ENABLE(		OPCODE == ALU_OR),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

XOR8 xor0(
	.OP1(			OP1),
	.OP2(			OP2),
	.ENABLE(		OPCODE == ALU_XOR),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

SUB8 cp0(
	.OP1(			OP1),
	.OP2(			OP2),
	.CARRY(			FALSE),
	.ENABLE(		OPCODE == ALU_CP),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

RLC8 rlc0 (
	.OP1(			OP1),
	.ENABLE(		OPCODE == ALU_RLC),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

RRC8 rrc0 (
	.OP1(			OP1),
	.ENABLE(		OPCODE == ALU_RRC),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

RL8 rl0 (
	.OP1(			OP1),
	.CARRY(			INFLAGS[FLAG_C]),
	.ENABLE(		OPCODE == ALU_RL),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

RR8 rr0 (
	.OP1(			OP1),
	.CARRY(			INFLAGS[FLAG_C]),
	.ENABLE(		OPCODE == ALU_RR),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

SLA8 sla0 (
	.OP1(			OP1),
	.ENABLE(		OPCODE == ALU_SLA),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

SLA8 sll0 (
	.OP1(			OP1),
	.ENABLE(		OPCODE == ALU_SLL),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

SRA8 sra0 (
	.OP1(			OP1),
	.ENABLE(		OPCODE == ALU_SRA),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);

SRL8 srl0 (
	.OP1(			OP1),
	.ENABLE(		OPCODE == ALU_SRL),
	.PART_RESULT(	PART_RESULT),
	.PART_FLAGS(	PART_FLAGS)
);


////////////////////////////////////////////////////////////////
// FLAG SETTER

module FLAGSETTER (										 			// Set flags according to partial result and flags ...
	input		[ 4: 0]	OPCODE,
	input		[ 7: 0]	PART_RESULT,
	input		[ 3: 0]	PART_FLAGS,									// 4 bit carry/overflow/subtract/half carry from operations
	output		[ 7: 0]	OUTFLAGS
);
	assign OUTFLAGS = { PART_RESULT[7],								// Sign of result
						PART_RESULT == 0,							// Is result Zero 
						FALSE,
						PART_FLAGS[PFLAG_H],						// Half carry
						FALSE,
						(OPCODE[4:2] == 0 | OPCODE == 5'd7) ?		// For arithmetic operations (ADD/ADC/SUB/SBC/CP)
							 PART_FLAGS[PFLAG_C] ^					// Calculate overflow
							 PART_FLAGS[PFLAG_V] :
						   ~(PART_RESULT[7] ^						// Else calculate parity
							 PART_RESULT[6] ^
							 PART_RESULT[5] ^ 
							 PART_RESULT[4] ^ 
							 PART_RESULT[3] ^
							 PART_RESULT[2] ^
							 PART_RESULT[1] ^
							 PART_RESULT[0]),
						PART_FLAGS[PFLAG_N],						// Subtract flag
						PART_FLAGS[PFLAG_C] };						// Carry out

endmodule
endmodule

////////////////////////////////////////////////////////////////
// SET FLAGS

module FLG8 (														// Set flags only.  Carry in so we can retain its state
	input		[ 7: 0]	OP1,
	input  				ENABLE,
	input 				CARRY,
	output		[ 7: 0]	PART_RESULT,
	output		[ 3: 0]	PART_FLAGS	
);

assign PART_RESULT = ENABLE ?			  OP1 : 8'bz;				// Transfer the input value
assign PART_FLAGS  = ENABLE ? { CARRY, 3'b0 } : 4'bz;				// and carry in to the result and output flags

endmodule

////////////////////////////////////////////////////////////////
// ROTATE/SHIFT

module RLC8 (
	input		[ 7: 0]	OP1,
	input  				ENABLE,
	output		[ 7: 0]	PART_RESULT,
	output		[ 3: 0]	PART_FLAGS
);

assign PART_RESULT	= ENABLE ? { OP1[6:0], OP1[7] }	: 8'bz;
assign PART_FLAGS	= ENABLE ? { OP1[7],	 3'b0 }	: 4'bz;

endmodule

module RRC8 (
	input		[ 7: 0]	OP1,
	input  				ENABLE,
	output		[ 7: 0]	PART_RESULT,
	output		[ 3: 0]	PART_FLAGS
);

assign PART_RESULT	= ENABLE ? { OP1[0], OP1[7:1] } : 8'bz;
assign PART_FLAGS	= ENABLE ? { OP1[0],	 3'b0 } : 4'bz;

endmodule

module RL8 (
	input		[ 7: 0]	OP1,
	input				CARRY,
	input  				ENABLE,
	output		[ 7: 0]	PART_RESULT,
	output		[ 3: 0]	PART_FLAGS
);

assign PART_RESULT	= ENABLE ? { OP1[6:0], CARRY } : 8'bz;
assign PART_FLAGS	= ENABLE ? { OP1[7],	3'b0 } : 4'bz;

endmodule

module RR8 (
	input		[ 7: 0]	OP1,
	input				CARRY,
	input  				ENABLE,
	output		[ 7: 0]	PART_RESULT,
	output		[ 3: 0]	PART_FLAGS
);

assign PART_RESULT	= ENABLE ? { CARRY, OP1[7:1] } : 8'bz;
assign PART_FLAGS	= ENABLE ? { OP1[0],	3'b0 } : 4'bz;

endmodule

module SLA8 (
	input		[ 7: 0]	OP1,
	input  				ENABLE,
	output		[ 7: 0]	PART_RESULT,
	output		[ 3: 0]	PART_FLAGS
);

assign PART_RESULT	= ENABLE ? { OP1[6:0],	1'b0 } : 8'bz;
assign PART_FLAGS	= ENABLE ? { OP1[7],	3'b0 } : 4'bz;

endmodule

module SRA8 (
	input		[ 7: 0]	OP1,
	input  				ENABLE,
	output		[ 7: 0]	PART_RESULT,
	output		[ 3: 0]	PART_FLAGS
);

assign PART_RESULT	= ENABLE ? { OP1[7], OP1[7:1] } : 8'bz;
assign PART_FLAGS	= ENABLE ? { OP1[0],	 3'b0 } : 4'bz;

endmodule

module SRL8 (
	input		[ 7: 0]	OP1,
	input  				ENABLE,
	output		[ 7: 0]	PART_RESULT,
	output		[ 3: 0]	PART_FLAGS
);

assign PART_RESULT	= ENABLE ? { 1'b0,	OP1[7:1] } : 8'bz;
assign PART_FLAGS	= ENABLE ? { OP1[0],	3'b0 } : 4'bz;

endmodule

////////////////////////////////////////////////////////////////
// ADD/ADC

module ADD8(
	input		[ 7: 0]	OP1,
	input		[ 7: 0]	OP2,
	input				CARRY,
	input  				ENABLE,
	output		[ 7: 0]	PART_RESULT,
	output		[ 3: 0]	PART_FLAGS
);

	reg			[ 7: 0]	r;
	reg			[ 7: 0]	c;

ADDSUB1 add0( r[0], OP1[0], OP2[0], CARRY);
ADDC1	adc0( c[0], OP1[0], OP2[0], CARRY);

ADDSUB1 add1( r[1], OP1[1], OP2[1], c[0]);
ADDC1	adPART_FLAGS( c[1], OP1[1], OP2[1], c[0]);

ADDSUB1 add2( r[2], OP1[2], OP2[2], c[1]);
ADDC1	adc2( c[2], OP1[2], OP2[2], c[1]);

ADDSUB1 add3( r[3], OP1[3], OP2[3], c[2]);
ADDC1	adc3( c[3], OP1[3], OP2[3], c[2]);

ADDSUB1 add4( r[4], OP1[4], OP2[4], c[3]);
ADDC1	adc4( c[4], OP1[4], OP2[4], c[3]);

ADDSUB1 add5( r[5], OP1[5], OP2[5], c[4]);
ADDC1	adc5( c[5], OP1[5], OP2[5], c[4]);

ADDSUB1 add6( r[6], OP1[6], OP2[6], c[5]);
ADDC1	adc6( c[6], OP1[6], OP2[6], c[5]);

ADDSUB1 add7( r[7], OP1[7], OP2[7], c[6]);
ADDC1	adc7( c[7], OP1[7], OP2[7], c[6]);

assign PART_RESULT = ENABLE ? 	  r : 8'bz;
assign PART_FLAGS	  = ENABLE ? { c[7:6], 1'b0, c[3] } : 4'bz;				// return carry, overflow, subtract, half carry

endmodule

////////////////////////////////////////////////////////////////
// SUB/SBC

module SUB8(
	input		[ 7: 0]	OP1,
	input		[ 7: 0]	OP2,
	input				CARRY,
	input  				ENABLE,
	output		[ 7: 0]	PART_RESULT,
	output		[ 3: 0]	PART_FLAGS
);

	reg			[ 7: 0]	r;
	reg			[ 7: 0]	c;

ADDSUB1 sub0( r[0], OP1[0], OP2[0], CARRY);
SUBC1	sbc0( c[0], OP1[0], OP2[0], CARRY);

ADDSUB1 sub1( r[1], OP1[1], OP2[1], c[0]);
SUBC1	sbPART_FLAGS( c[1], OP1[1], OP2[1], c[0]);

ADDSUB1 sub2( r[2], OP1[2], OP2[2], c[1]);
SUBC1	sbc2( c[2], OP1[2], OP2[2], c[1]);

ADDSUB1 sub3( r[3], OP1[3], OP2[3], c[2]);
SUBC1	sbc3( c[3], OP1[3], OP2[3], c[2]);

ADDSUB1 sub4( r[4], OP1[4], OP2[4], c[3]);
SUBC1	sbc4( c[4], OP1[4], OP2[4], c[3]);

ADDSUB1 sub5( r[5], OP1[5], OP2[5], c[4]);
SUBC1	sbc5( c[5], OP1[5], OP2[5], c[4]);

ADDSUB1 sub6( r[6], OP1[6], OP2[6], c[5]);
SUBC1	sbc6( c[6], OP1[6], OP2[6], c[5]);

ADDSUB1 sub7( r[7], OP1[7], OP2[7], c[6]);
SUBC1	sbc7( c[7], OP1[7], OP2[7], c[6]);

assign PART_RESULT = ENABLE ?					   r : 8'bz;
assign PART_FLAGS  = ENABLE ? { c[7:6], 1'b1, c[3] } : 4'bz;				// return carry, overflow, subtract, half carry

endmodule

////////////////////////////////////////////////////////////////
// AND

module AND8(
	input		[ 7: 0]	OP1,
	input		[ 7: 0]	OP2,
	input  				ENABLE,
	output		[ 7: 0]	PART_RESULT,
	output		[ 3: 0]	PART_FLAGS
);

	reg			[ 7: 0]	r;

AND1 and0( r[0], OP1[0], OP2[0]);

AND1 and1( r[1], OP1[1], OP2[1]);

AND1 and2( r[2], OP1[2], OP2[2]);

AND1 and3( r[3], OP1[3], OP2[3]);

AND1 and4( r[4], OP1[4], OP2[4]);

AND1 and5( r[5], OP1[5], OP2[5]);

AND1 and6( r[6], OP1[6], OP2[6]);

AND1 and7( r[7], OP1[7], OP2[7]);

assign PART_RESULT	= ENABLE ?	  r : 8'bz;
assign PART_FLAGS	= ENABLE ? 4'b0 : 4'bz;

endmodule

////////////////////////////////////////////////////////////////
// OR

module OR8(
	input		[ 7: 0]	OP1,
	input		[ 7: 0]	OP2,
	input  				ENABLE,
	output		[ 7: 0]	PART_RESULT,
	output		[ 3: 0]	PART_FLAGS
);

	reg			[ 7: 0]	r;

OR1 or0( r[0], OP1[0], OP2[0]);

OR1 or1( r[1], OP1[1], OP2[1]);

OR1 or2( r[2], OP1[2], OP2[2]);

OR1 or3( r[3], OP1[3], OP2[3]);

OR1 or4( r[4], OP1[4], OP2[4]);

OR1 or5( r[5], OP1[5], OP2[5]);

OR1 or6( r[6], OP1[6], OP2[6]);

OR1 or7( r[7], OP1[7], OP2[7]);

assign PART_RESULT	= ENABLE ?	  r : 8'bz;
assign PART_FLAGS	= ENABLE ? 4'b0 : 4'bz;

endmodule

////////////////////////////////////////////////////////////////
// XOR

module XOR8(
	input		[ 7: 0]	OP1,
	input		[ 7: 0]	OP2,
	input  				ENABLE,
	output		[ 7: 0]	PART_RESULT,
	output		[ 3: 0]	PART_FLAGS
);

	reg			[ 7: 0]	r;

XOR1 xor0( r[0], OP1[0], OP2[0]);

XOR1 xor1( r[1], OP1[1], OP2[1]);

XOR1 xor2( r[2], OP1[2], OP2[2]);

XOR1 xor3( r[3], OP1[3], OP2[3]);

XOR1 xor4( r[4], OP1[4], OP2[4]);

XOR1 xor5( r[5], OP1[5], OP2[5]);

XOR1 xor6( r[6], OP1[6], OP2[6]);

XOR1 xor7( r[7], OP1[7], OP2[7]);

assign PART_RESULT	= ENABLE ?	  r : 8'bz;
assign PART_FLAGS	= ENABLE ? 4'b0 : 4'bz;

endmodule

////////////////////////////////////////////////////////////////
// Primitives

primitive ADDSUB1 (
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

primitive ADDC1 (
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


primitive SUBC1 (
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

primitive AND1 (
	output 				R,
	input 				A, B
);

	table
		//  A	B 	R
			0	0 :	0;
			0	1 :	0;
			1	0 :	0;
			1	1 :	1;
		endtable

endprimitive

primitive OR1 (
	output 				R,
	input 				A, B
);

	table
		//  A 	B 	R
			0	0 :	0;
			0	1 :	1;
			1	0 :	1;
			1	1 :	1;
		endtable

endprimitive

primitive XOR1 (
	output 				R,
	input 				A, B
);

	table
		//  A 	B 	R
			0	0 :	0;
			0	1 :	1;
			1	0 :	1;
			1	1 :	0;
		endtable

endprimitive