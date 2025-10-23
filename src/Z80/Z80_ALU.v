`timescale 1ns / 1ps

module Z80_ALU (
	input  reg  [4:0]opcode,
	input  reg  [7:0]op1,
	input  reg  [7:0]op2,
	input  reg  [7:0]inflags,
	output wire [7:0]result,
	output wire [7:0]outflags
);

`include "..\\Global.vh"

wire [7:0]r;
wire [3:0]c1;

assign result = opcode == ALU_CP ? op1 : r;

FLAGS8 flags0(
	.opcode(opcode),
	.r(r),
	.c1(c1),
	.outflags(outflags)
);

FLG8 flg0(									// Set flags ONLY 
	.p1(op1),
	.cin(inflags[FLAG_C]),
	.en(opcode == ALU_FLG),
	.result(r),
	.cout(c1)
);

ADD8 add0(
	.p1(op1),
	.p2(op2),
	.cin(FALSE),
	.en(opcode == ALU_ADD),
	.result(r),
	.cout(c1)
);

ADD8 adc0(
	.p1(op1),
	.p2(op2),
	.cin(inflags[FLAG_C]),
	.en(opcode == ALU_ADC),
	.result(r),
	.cout(c1)
);

SUB8 sub0(
	.p1(op1),
	.p2(op2),
	.cin(FALSE),
	.en(opcode == ALU_SUB),
	.result(r),
	.cout(c1)
);

SUB8 sbc0(
	.p1(op1),
	.p2(op2),
	.cin(inflags[FLAG_C]),
	.en(opcode == ALU_SBC),
	.result(r),
	.cout(c1)
);

AND8 and0(
	.p1(op1),
	.p2(op2),
	.en(opcode == ALU_AND),
	.result(r),
	.cout(c1)
);

OR8 or0(
	.p1(op1),
	.p2(op2),
	.en(opcode == ALU_OR),
	.result(r),
	.cout(c1)
);

XOR8 xor0(
	.p1(op1),
	.p2(op2),
	.en(opcode == ALU_XOR),
	.result(r),
	.cout(c1)
);

SUB8 cp0(
	.p1(op1),
	.p2(op2),
	.cin(FALSE),
	.en(opcode == ALU_CP),
	.result(r),
	.cout(c1)
);

RLC8 rlc0 (
	.p1(op1),
	.en(opcode == ALU_RLC),
	.result(r),
	.cout(c1)
);

RRC8 rrc0 (
	.p1(op1),
	.en(opcode == ALU_RRC),
	.result(r),
	.cout(c1)
);

RL8 rl0 (
	.p1(op1),
	.cin(inflags[FLAG_C]),
	.en(opcode == ALU_RL),
	.result(r),
	.cout(c1)
);

RR8 rr0 (
	.p1(op1),
	.cin(inflags[FLAG_C]),
	.en(opcode == ALU_RR),
	.result(r),
	.cout(c1)
);

SLA8 sla0 (
	.p1(op1),
	.en(opcode == ALU_SLA),
	.result(r),
	.cout(c1)
);

SLA8 sll0 (
	.p1(op1),
	.en(opcode == ALU_SLL),
	.result(r),
	.cout(c1)
);

SRA8 sra0 (
	.p1(op1),
	.en(opcode == ALU_SRA),
	.result(r),
	.cout(c1)
);

SRL8 srl0 (
	.p1(op1),
	.en(opcode == ALU_SRL),
	.result(r),
	.cout(c1)
);

endmodule

////////////////////////////////////////////////////////////////
// FLAG SETTER

module FLAGS8 (											 			// Set flags according to result and flags ...
	input [4:0]opcode,
	input [7:0]r,
	input [3:0]c1,													// 4 bit carry/overflow/subtract/half carry from operations
	output [7:0]outflags
);
	assign outflags = { r[7],										// Sign of result
						r == 0,								 		// Is result Zero 
						1'b0,
						c1[0],										// Half carry
						1'b0,
						(opcode[4:2] == 0 | opcode == 5'd7) ?		// For arithmetic operations (ADD/ADC/SUB/SBC/CP)
							 c1[3] ^ c1[2] :						// Calculate overflow
							~(r[7] ^  r[6] ^ r[5] ^ r[4] ^ r[3] ^ 	// Else calculate parity
							  r[2] ^  r[1] ^ r[0]),
						c1[1],			// Subtract					// Subtract flag
						c1[3] };		// Carry					// Carry out

endmodule

////////////////////////////////////////////////////////////////
// SET FLAGS

module FLG8 (														// Set flags only.  CIN so we can retain the carry
	input  [7:0]p1,
	input  		en,
	input 		cin,
	output [7:0]result,
	output [3:0]cout	
);

assign result = en ?			p1 : 8'bz;							// Do nothing but transfer the input value
assign cout	  = en ? { cin, 3'b0 } : 4'bz;							// and carry in to the result and output flags

endmodule

////////////////////////////////////////////////////////////////
// ROTATE/SHIFT

module RLC8 (
	input  [7:0]p1,
	input  		en,
	output [7:0]result,
	output [3:0]cout
);

assign result = en ? { p1[6:0], p1[7] } : 8'bz;
assign cout	  = en ? { p1[7],	3'b0  } : 4'bz;

endmodule

module RRC8 (
	input  [7:0]p1,
	input  		en,
	output [7:0]result,
	output [3:0]cout
);

assign result = en ? { p1[0], p1[7:1] } : 8'bz;
assign cout	= en ? { p1[0],	3'b0 } : 4'bz;

endmodule

module RL8 (
	input  [7:0]p1,
	input		cin,
	input  		en,
	output [7:0]result,
	output [3:0]cout
);

assign result = en ? { p1[6:0], cin } : 8'bz;
assign cout	= en ? { p1[7],  3'b0 } : 4'bz;

endmodule

module RR8 (
	input  [7:0]p1,
	input		cin,
	input  		en,
	output [7:0]result,
	output [3:0]cout
);

assign result = en ? { cin, p1[7:1] } : 8'bz;
assign cout	= en ? { p1[0],  3'b0 } : 4'bz;

endmodule

module SLA8 (
	input  [7:0]p1,
	input  		en,
	output [7:0]result,
	output [3:0]cout
);

assign result = en ? { p1[6:0], 1'b0 } : 8'bz;
assign cout	= en ? { p1[7],	3'b0 } : 4'bz;

endmodule

module SRA8 (
	input  [7:0]p1,
	input  		en,
	output [7:0]result,
	output [3:0]cout
);

assign result = en ? { p1[7], p1[7:1] } : 8'bz;
assign cout	= en ? { p1[0],	3'b0 } : 4'bz;

endmodule

module SRL8 (
	input  [7:0]p1,
	input  		en,
	output [7:0]result,
	output [3:0]cout
);

assign result = en ? { 1'b0, p1[7:1] } : 8'bz;
assign cout	= en ? { p1[0],	3'b0 } : 4'bz;

endmodule

////////////////////////////////////////////////////////////////
// ADD/ADC

module ADD8(
	input  [7:0]p1,
	input  [7:0]p2,
	input		cin,
	input  		en,
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

assign result = en ? 	  r : 8'bz;
assign cout	  = en ? { c[7:6], 1'b0, c[3] } : 4'bz;				// return carry, overflow, subtract, half carry

endmodule

////////////////////////////////////////////////////////////////
// SUB/SBC

module SUB8(
	input  [7:0]p1,
	input  [7:0]p2,
	input		cin,
	input  		en,
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

assign result = en ?	  r : 8'bz;
assign cout	  = en ? { c[7:6], 1'b1, c[3] } : 4'bz;				// return carry, overflow, subtract, half carry

endmodule

////////////////////////////////////////////////////////////////
// AND

module AND8(
	input  [7:0]p1,
	input  [7:0]p2,
	input  		en,
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

assign result = en ?	r : 8'bz;
assign cout	= en ? 4'b0 : 4'bz;

endmodule

////////////////////////////////////////////////////////////////
// OR

module OR8(
	input  [7:0]p1,
	input  [7:0]p2,
	input  		en,
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

assign result = en ?	r : 8'bz;
assign cout	= en ? 4'b0 : 4'bz;

endmodule

////////////////////////////////////////////////////////////////
// XOR

module XOR8(
	input  [7:0]p1,
	input  [7:0]p2,
	input  		en,
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

assign result = en ?	r : 8'bz;
assign cout	= en ? 4'b0 : 4'bz;

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


