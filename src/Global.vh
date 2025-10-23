//`ifndef _GLOBAL

////////////////////////////////////////////////////////////////////////////////
// Generic values

localparam ACTIVE	= 1'b0;				  // Active low inputs
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

localparam ALU_ADD = 5'b00000;
localparam ALU_ADC = 5'b00001;
localparam ALU_SUB = 5'b00010;
localparam ALU_SBC = 5'b00011;
localparam ALU_ARI = 5'b000zz;				// Match arithmetic opcodes

localparam ALU_AND = 5'b00100;
localparam ALU_XOR = 5'b00101;
localparam ALU_OR  = 5'b00110;
localparam ALU_CP  = 5'b00111;
localparam ALU_LOG = 5'b001zz;				// Match logical opcodes

localparam ALU_RLC = 5'b01000;
localparam ALU_RRC = 5'b01001;
localparam ALU_RL  = 5'b01010;
localparam ALU_RR  = 5'b01011;
localparam ALU_SLA = 5'b01100;
localparam ALU_SRA = 5'b01101;
localparam ALU_SLL = 5'b01110;
localparam ALU_SRL = 5'b01111;
localparam ALU_SHR = 5'b01zzz;              // Match shift/rotate opcodes

localparam ALU_FLG = 5'b11111;
localparam ALU_NEG = 5'b11110;
localparam ALU_DAA = 5'b11101;

//`define _GLOBAL 1
//`endif
