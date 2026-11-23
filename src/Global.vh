//`ifndef _GLOBAL

////////////////////////////////////////////////////////////////////////////////
// Generic values

localparam ACTIVE	= 1'b0;					// Active low inputs
localparam INACTIVE	= 1'b1;

localparam FALSE = 1'b0;
localparam TRUE  = 1'b1;

////////////////////////////////////////////////////////////////////////////////
// Bit positions in flags register

localparam FLAG_C = 0;							// Carry
localparam FLAG_N = 1;							// Add/Subtract
localparam FLAG_P = 2;							// Parity/Overflow
localparam FLAG_H = 4;							// Half carry
localparam FLAG_Z = 6;							// Zero
localparam FLAG_S = 7;							// Sign (-ve)

localparam PFLAG_C	= 3;						// Partial flag bit use
localparam PFLAG_V	= 2;						// For calculating overflow
localparam PFLAG_N	= 1;
localparam PFLAG_H	= 0;

//`define _GLOBAL 1
//`endif
