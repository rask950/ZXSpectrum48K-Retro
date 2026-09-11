`timescale 1ns / 1ps

module Z80_ALU (
	input  reg		[ 4: 0]	OPCODE,
	input  reg		[ 7: 0]	OP1,
	input  reg		[ 7: 0]	OP2,
	input  reg		[ 7: 0]	INFLAGS,
	output wire		[ 7: 0]	RESULT,
	output wire		[ 7: 0]	OUTFLAGS
);

`include "..\\Global.vh"

	wire		[ 7: 0]	TMPRES;
	wire		[ 3: 0] FLAGS;

	assign RESULT = OPCODE == ALU_CP ? OP1 : TMPRES;

	FLAGSET flagset(
		.OPCODE(OPCODE),
		.RESULT(TMPRES),
		.INFLAGS(FLAGS),
		.OUTFLAGS(OUTFLAGS)
	);

	FLG8 flg0(									// Set flags ONLY 
		.OP1(OP1),
		.cin(INFLAGS[FLAG_C]),
		.ENABLE(OPCODE == ALU_FLG),
		.result(TMPRES),
		.cout(FLAGS)
	);

	ADD8 add0(
		.p1(OP1),
		.p2(OP2),
		.cin(FALSE),
		.ENABLE(OPCODE == ALU_ADD),
		.result(TMPRES),
		.cout(FLAGS)
	);

	ADD8 adc0(
		.p1(OP1),
		.p2(OP2),
		.cin(INFLAGS[FLAG_C]),
		.ENABLE(OPCODE == ALU_ADC),
		.result(TMPRES),
		.cout(FLAGS)
	);

	SUB8 sub0(
		.p1(OP1),
		.p2(OP2),
		.cin(FALSE),
		.ENABLE(OPCODE == ALU_SUB),
		.result(TMPRES),
		.cout(FLAGS)
	);

	SUB8 sbc0(
		.p1(OP1),
		.p2(OP2),
		.cin(INFLAGS[FLAG_C]),
		.ENABLE(OPCODE == ALU_SBC),
		.result(TMPRES),
		.cout(FLAGS)
	);

	AND8 and0(
		.p1(OP1),
		.p2(OP2),
		.ENABLE(OPCODE == ALU_AND),
		.result(TMPRES),
		.cout(FLAGS)
	);

	OR8 or0(
		.p1(OP1),
		.p2(OP2),
		.ENABLE(OPCODE == ALU_OR),
		.result(TMPRES),
		.cout(FLAGS)
	);

	XOR8 xor0(
		.p1(OP1),
		.p2(OP2),
		.ENABLE(OPCODE == ALU_XOR),
		.result(TMPRES),
		.cout(FLAGS)
	);

	CP8 cp0(
		.p1(OP1),
		.p2(OP2),
		.cin(FALSE),
		.ENABLE(OPCODE == ALU_CP),
		.result(TMPRES),
		.cout(FLAGS)
	);

	RLC8 rlc0 (
		.p1(OP1),
		.ENABLE(OPCODE == ALU_RLC),
		.result(TMPRES),
		.cout(FLAGS)
	);

	RRC8 rrc0 (
		.p1(OP1),
		.ENABLE(OPCODE == ALU_RRC),
		.result(TMPRES),
		.cout(FLAGS)
	);

	RL8 rl0 (
		.p1(OP1),
		.cin(INFLAGS[FLAG_C]),
		.ENABLE(OPCODE == ALU_RL),
		.result(TMPRES),
		.cout(FLAGS)
	);

	RR8 rr0 (
		.p1(OP1),
		.cin(INFLAGS[FLAG_C]),
		.ENABLE(OPCODE == ALU_RR),
		.result(TMPRES),
		.cout(FLAGS)
	);

	SLA8 sla0 (
		.p1(OP1),
		.ENABLE(OPCODE == ALU_SLA),
		.result(TMPRES),
		.cout(FLAGS)
	);

	SLA8 sll0 (
		.p1(OP1),
		.ENABLE(OPCODE == ALU_SLL),
		.result(TMPRES),
		.cout(FLAGS)
	);

	SRA8 sra0 (
		.p1(OP1),
		.ENABLE(OPCODE == ALU_SRA),
		.result(TMPRES),
		.cout(FLAGS)
	);

	SRL8 srl0 (
		.p1(OP1),
		.ENABLE(OPCODE == ALU_SRL),
		.result(TMPRES),
		.cout(FLAGS)
	);

endmodule

////////////////////////////////////////////////////////////////
// FLAG SETTER

module FLAGSET (										 			// Set flags according to result and flags ...
	input		[ 4: 0]	OPCODE,
	input		[ 7: 0]	RESULT,
	input 		[ 3: 0] INFLAGS,									// 4 bit carry/overflow/subtract/half carry from operations
	output		[ 7: 0] OUTFLAGS
);
	assign OUTFLAGS = { RESULT[7],									// Sign of result
						RESULT == 0,								// Is result Zero 
						1'b0,
						INFLAGS[0],									// Half carry
						1'b0,
						(OPCODE[4:2] == 0 | OPCODE == 5'd7) ?		// For arithmetic operations (ADD/ADC/SUB/SBC/CP)
							INFLAGS[3] ^							// Calculate overflow
							INFLAGS[2] :
						  ~(RESULT[7] ^							 	// Else calculate parity
							RESULT[6] ^
							RESULT[5] ^
							RESULT[4] ^
							RESULT[3] ^
							RESULT[2] ^
							RESULT[1] ^
							RESULT[0]),
						INFLAGS[1],									// Subtract flag
						INFLAGS[3] };								// Carry

endmodule

////////////////////////////////////////////////////////////////
// SET FLAGS

module FLG8 (														// Set flags only.  CIN so we can retain the carry
	input		[ 7: 0] OP1,
	input  		ENABLE,
	input 		cin,
	output [7:0]result,
	output [3:0]cout	
);

assign result = ENABLE ?			OP1 : 8'bz;							// Do nothing but transfer the input value
assign cout	  = ENABLE ? { cin, 3'b0 } : 4'bz;							// and carry in to the result and output flags

endmodule

////////////////////////////////////////////////////////////////
// ROTATE/SHIFT

module RLC8 (
	input  [7:0]p1,
	input  		ENABLE,
	output [7:0]result,
	output [3:0]cout
);

assign result = ENABLE ? { p1[6:0], p1[7] } : 8'bz;
assign cout	  = ENABLE ? { p1[7],	3'b0  } : 4'bz;

endmodule

module RRC8 (
	input  [7:0]p1,
	input  		ENABLE,
	output [7:0]result,
	output [3:0]cout
);

assign result = ENABLE ? { p1[0], p1[7:1] } : 8'bz;
assign cout	= ENABLE ? { p1[0],	3'b0 } : 4'bz;

endmodule

module RL8 (
	input  [7:0]p1,
	input		cin,
	input  		ENABLE,
	output [7:0]result,
	output [3:0]cout
);

assign result = ENABLE ? { p1[6:0], cin } : 8'bz;
assign cout	= ENABLE ? { p1[7],  3'b0 } : 4'bz;

endmodule

module RR8 (
	input  [7:0]p1,
	input		cin,
	input  		ENABLE,
	output [7:0]result,
	output [3:0]cout
);

assign result = ENABLE ? { cin, p1[7:1] } : 8'bz;
assign cout	= ENABLE ? { p1[0],  3'b0 } : 4'bz;

endmodule

module SLA8 (
	input  [7:0]p1,
	input  		ENABLE,
	output [7:0]result,
	output [3:0]cout
);

assign result = ENABLE ? { p1[6:0], 1'b0 } : 8'bz;
assign cout	  = ENABLE ? { p1[7],	3'b0 } : 4'bz;

endmodule

module SRA8 (
	input  [7:0]p1,
	input  		ENABLE,
	output [7:0]result,
	output [3:0]cout
);

assign result = ENABLE ? { p1[7], p1[7:1] } : 8'bz;
assign cout	  = ENABLE ? { p1[0],	3'b0 } : 4'bz;

endmodule

module SRL8 (
	input  [7:0]p1,
	input  		ENABLE,
	output [7:0]result,
	output [3:0]cout
);

assign result = ENABLE ? { 1'b0, p1[7:1] } : 8'bz;
assign cout	  = ENABLE ? { p1[0],	3'b0 } : 4'bz;

endmodule

////////////////////////////////////////////////////////////////
// ADD/ADC

module ADD8(
	input  [7:0]p1,
	input  [7:0]p2,
	input		cin,
	input  		ENABLE,
	output [7:0]result,
	output [3:0]cout
);

reg [7:0]r;
reg [7:0]c;

ADDSUB1 add0( r[0], p1[0], p2[0], cin);
ADDC1	adc0( c[0], p1[0], p2[0], cin);

ADDSUB1 add1( r[1], p1[1], p2[1], c[0]);
ADDC1	adc1( c[1], p1[1], p2[1], c[0]);

ADDSUB1 add2( r[2], p1[2], p2[2], c[1]);
ADDC1	adc2( c[2], p1[2], p2[2], c[1]);

ADDSUB1 add3( r[3], p1[3], p2[3], c[2]);
ADDC1	adc3( c[3], p1[3], p2[3], c[2]);

ADDSUB1 add4( r[4], p1[4], p2[4], c[3]);
ADDC1	adc4( c[4], p1[4], p2[4], c[3]);

ADDSUB1 add5( r[5], p1[5], p2[5], c[4]);
ADDC1	adc5( c[5], p1[5], p2[5], c[4]);

ADDSUB1 add6( r[6], p1[6], p2[6], c[5]);
ADDC1	adc6( c[6], p1[6], p2[6], c[5]);

ADDSUB1 add7( r[7], p1[7], p2[7], c[6]);
ADDC1	adc7( c[7], p1[7], p2[7], c[6]);

assign result = ENABLE ? 	  r : 8'bz;
assign cout	  = ENABLE ? { c[7:6], 1'b0, c[3] } : 4'bz;				// return carry, overflow, subtract, half carry

endmodule

////////////////////////////////////////////////////////////////
// SUB/SBC

module SUB8(
	input  [7:0]p1,
	input  [7:0]p2,
	input		cin,
	input  		ENABLE,
	output [7:0]result,
	output [3:0]cout
);

reg [7:0]r;
reg [7:0]c;

ADDSUB1 sub0( r[0], p1[0], p2[0], cin);
SUBC1	sbc0( c[0], p1[0], p2[0], cin);

ADDSUB1 sub1( r[1], p1[1], p2[1], c[0]);
SUBC1	sbc1( c[1], p1[1], p2[1], c[0]);

ADDSUB1 sub2( r[2], p1[2], p2[2], c[1]);
SUBC1	sbc2( c[2], p1[2], p2[2], c[1]);

ADDSUB1 sub3( r[3], p1[3], p2[3], c[2]);
SUBC1	sbc3( c[3], p1[3], p2[3], c[2]);

ADDSUB1 sub4( r[4], p1[4], p2[4], c[3]);
SUBC1	sbc4( c[4], p1[4], p2[4], c[3]);

ADDSUB1 sub5( r[5], p1[5], p2[5], c[4]);
SUBC1	sbc5( c[5], p1[5], p2[5], c[4]);

ADDSUB1 sub6( r[6], p1[6], p2[6], c[5]);
SUBC1	sbc6( c[6], p1[6], p2[6], c[5]);

ADDSUB1 sub7( r[7], p1[7], p2[7], c[6]);
SUBC1	sbc7( c[7], p1[7], p2[7], c[6]);

assign result = ENABLE ?	  r : 8'bz;
assign cout	  = ENABLE ? { c[7:6], 1'b1, c[3] } : 4'bz;				// return carry, overflow, subtract, half carry

endmodule

////////////////////////////////////////////////////////////////
// CP

module CP8(
	input  [7:0]p1,
	input  [7:0]p2,
	input		cin,
	input  		ENABLE,
	output [7:0]result,
	output [3:0]cout
);

reg [7:0]r;
reg [7:0]c;

ADDSUB1 sub0( r[0], p1[0], p2[0], 1'b0);
SUBC1	sbc0( c[0], p1[0], p2[0], 1'b0);

ADDSUB1 sub1( r[1], p1[1], p2[1], c[0]);
SUBC1	sbc1( c[1], p1[1], p2[1], c[0]);

ADDSUB1 sub2( r[2], p1[2], p2[2], c[1]);
SUBC1	sbc2( c[2], p1[2], p2[2], c[1]);

ADDSUB1 sub3( r[3], p1[3], p2[3], c[2]);
SUBC1	sbc3( c[3], p1[3], p2[3], c[2]);

ADDSUB1 sub4( r[4], p1[4], p2[4], c[3]);
SUBC1	sbc4( c[4], p1[4], p2[4], c[3]);

ADDSUB1 sub5( r[5], p1[5], p2[5], c[4]);
SUBC1	sbc5( c[5], p1[5], p2[5], c[4]);

ADDSUB1 sub6( r[6], p1[6], p2[6], c[5]);
SUBC1	sbc6( c[6], p1[6], p2[6], c[5]);

ADDSUB1 sub7( r[7], p1[7], p2[7], c[6]);
SUBC1	sbc7( c[7], p1[7], p2[7], c[6]);

assign result = ENABLE ?	  p1 : 8'bz;
assign cout	  = ENABLE ? { c[7:6], 1'b1, c[3] } : 4'bz;				// return carry, overflow, subtract, half carry

endmodule

////////////////////////////////////////////////////////////////
// AND

module AND8(
	input  [7:0]p1,
	input  [7:0]p2,
	input  		ENABLE,
	output [7:0]result,
	output [3:0]cout
);

reg [7:0] r;

AND1 and0( r[0], p1[0], p2[0]);

AND1 and1( r[1], p1[1], p2[1]);

AND1 and2( r[2], p1[2], p2[2]);

AND1 and3( r[3], p1[3], p2[3]);

AND1 and4( r[4], p1[4], p2[4]);

AND1 and5( r[5], p1[5], p2[5]);

AND1 and6( r[6], p1[6], p2[6]);

AND1 and7( r[7], p1[7], p2[7]);

assign result = ENABLE ?	r : 8'bz;
assign cout	  = ENABLE ? 4'b0 : 4'bz;

endmodule

////////////////////////////////////////////////////////////////
// OR

module OR8(
	input  [7:0]p1,
	input  [7:0]p2,
	input  		ENABLE,
	output [7:0]result,
	output [3:0]cout
);

reg [7:0] r;

OR1 or0( r[0], p1[0], p2[0]);

OR1 or1( r[1], p1[1], p2[1]);

OR1 or2( r[2], p1[2], p2[2]);

OR1 or3( r[3], p1[3], p2[3]);

OR1 or4( r[4], p1[4], p2[4]);

OR1 or5( r[5], p1[5], p2[5]);

OR1 or6( r[6], p1[6], p2[6]);

OR1 or7( r[7], p1[7], p2[7]);

assign result = ENABLE ?	r : 8'bz;
assign cout	  = ENABLE ? 4'b0 : 4'bz;

endmodule

////////////////////////////////////////////////////////////////
// XOR

module XOR8(
	input  [7:0]p1,
	input  [7:0]p2,
	input  		ENABLE,
	output [7:0]result,
	output [3:0]cout
);

reg [7:0] r;

XOR1 xor0( r[0], p1[0], p2[0]);

XOR1 xor1( r[1], p1[1], p2[1]);

XOR1 xor2( r[2], p1[2], p2[2]);

XOR1 xor3( r[3], p1[3], p2[3]);

XOR1 xor4( r[4], p1[4], p2[4]);

XOR1 xor5( r[5], p1[5], p2[5]);

XOR1 xor6( r[6], p1[6], p2[6]);

XOR1 xor7( r[7], p1[7], p2[7]);

assign result = ENABLE ?	r : 8'bz;
assign cout	= ENABLE ? 4'b0 : 4'bz;

endmodule

////////////////////////////////////////////////////////////////
// Primitives

primitive ADDSUB1 (
	output 	R,
	input 	A, B, C
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
	output 	R,
	input 	A, B, C
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
	output 	R,
	input 	A, B, C
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
	output 	R,
	input 	A, B
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
	output 	R,
	input 	A, B
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
	output 	R,
	input 	A, B
);

	table
		//  A 	B 	R
			0	0 :	0;
			0	1 :	1;
			1	0 :	1;
			1	1 :	0;
		endtable

endprimitive


