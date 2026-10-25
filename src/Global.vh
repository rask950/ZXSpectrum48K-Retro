//`ifndef _GLOBAL

////////////////////////////////////////////////////////////////////////////////
// Generic values

localparam ACTIVE	= 1'b0;					// Active low inputs
localparam INACTIVE	= 1'b1;

localparam FALSE = 1'b0;
localparam TRUE  = 1'b1;

////////////////////////////////////////////////////////////////////////////////
// Bit positions in flags register

localparam FLAG_C = 0;						// Carry
localparam FLAG_N = 1;						// Add/Subtract
localparam FLAG_P = 2;						// Parity/Overflow
localparam FLAG_H = 4;						// Half carry
localparam FLAG_Z = 6;						// Zero
localparam FLAG_S = 7;						// Sign (-ve)

localparam ALU_ADD	= 5'b00000;
localparam ALU_ADC	= 5'b00001;				// C in
localparam ALU_SUB	= 5'b00010;
localparam ALU_SBC	= 5'b00011;				// C in

localparam ALU_AND	= 5'b00100;
localparam ALU_XOR	= 5'b00101;
localparam ALU_OR	= 5'b00110;
localparam ALU_CP	= 5'b00111;

localparam ALU_DAA	= 5'b01000;				// C and H
localparam ALU_FLG	= 5'b01011;				// Pseudo-operation for setting flags only

localparam ALU_BIT	= 5'b01100;
localparam ALU_SET	= 5'b01101;
localparam ALU_RES	= 5'b01110;
localparam ALU_NONE	= 5'b01111;				// No operation

localparam ALU_RLC	= 5'b10000;
localparam ALU_RRC	= 5'b10001;
localparam ALU_RL	= 5'b10010;				// C in
localparam ALU_RR	= 5'b10011;				// C in
localparam ALU_SLA	= 5'b10100;
localparam ALU_SRA	= 5'b10101;
localparam ALU_SLL	= 5'b10110;
localparam ALU_SRL	= 5'b10111;

localparam ALU_SHR	= 5'b1zzz1;             // Match shift/rotate right
localparam ALU_SHL	= 5'b1zzz0;             // Match shift/rotate left

//`define _GLOBAL 1
//`endif
