`ifndef _PARAMS

////////////////////////////////////////////////////////////////////////////////
// CPU states

parameter STATE_IDLE	= 9'b000000000;

parameter STATE_T1H		= 4'b0001;						// T state numbers 1 - 12
parameter STATE_T1L		= 4'b0010;
parameter STATE_T2H		= 4'b0011;
parameter STATE_T2L		= 4'b0100;
parameter STATE_T3H		= 4'b0101;
parameter STATE_T3L		= 4'b0110;
parameter STATE_T4H		= 4'b0111;
parameter STATE_T4L		= 4'b1000;
parameter STATE_T5H		= 4'b1001;
parameter STATE_T5L		= 4'b1010;
parameter STATE_T6H		= 4'b1011;
parameter STATE_T6L		= 4'b1100;

parameter STATE_M1T1H	= 9'b000000001;					// M1 Cycle - instruction fetch/decode and refresh
parameter STATE_M1T1L	= 9'b000000010;
parameter STATE_M1T2H	= 9'b000000011;
parameter STATE_M1T2L	= 9'b000000100;
parameter STATE_M1T3H	= 9'b000000101;
parameter STATE_M1T3L	= 9'b000000110;
parameter STATE_M1T4H	= 9'b000000111;
parameter STATE_M1T4L	= 9'b000001000;
parameter STATE_M1T5H	= 9'b000001001;
parameter STATE_M1T5L	= 9'b000001010;
parameter STATE_M1T6H	= 9'b000001011;
parameter STATE_M1T6L	= 9'b000001100;

parameter STATE_MR1T1H	= 9'b001000001;					// MR1 - Memory read 1
parameter STATE_MR1T1L	= 9'b001000010;
parameter STATE_MR1T2H	= 9'b001000011;
parameter STATE_MR1T2L	= 9'b001000100;
parameter STATE_MR1T3H	= 9'b001000101;
parameter STATE_MR1T3L	= 9'b001000110;
parameter STATE_MR1T4H	= 9'b001000111;
parameter STATE_MR1T4L	= 9'b001001000;
parameter STATE_MR1T5H	= 9'b001001001;
parameter STATE_MR1T5L	= 9'b001001010;

parameter STATE_MR2T1H	= 9'b001010001;					// MR2 - Memory read 2
parameter STATE_MR2T1L	= 9'b001010010;
parameter STATE_MR2T2H	= 9'b001010011;
parameter STATE_MR2T2L	= 9'b001010100;
parameter STATE_MR2T3H	= 9'b001010101;
parameter STATE_MR2T3L	= 9'b001010110;
parameter STATE_MR2T4H	= 9'b001010111;
parameter STATE_MR2T4L	= 9'b001011000;
parameter STATE_MR2T5H	= 9'b001011001;
parameter STATE_MR2T5L	= 9'b001011010;

parameter STATE_MR3T1H	= 9'b001100001;					// MR3 - Memory read 3
parameter STATE_MR3T1L	= 9'b001100010;
parameter STATE_MR3T2H	= 9'b001100011;
parameter STATE_MR3T2L	= 9'b001100100;
parameter STATE_MR3T3H	= 9'b001100101;
parameter STATE_MR3T3L	= 9'b001100110;

parameter STATE_MR4T1H	= 9'b001110001;					// MR4 - Memory read 4
parameter STATE_MR4T1L	= 9'b001110010;
parameter STATE_MR4T2H	= 9'b001110011;
parameter STATE_MR4T2L	= 9'b001110100;
parameter STATE_MR4T3H	= 9'b001110101;
parameter STATE_MR4T3L	= 9'b001110110;

parameter STATE_MRT1H	= 9'b001zz0001;					// Match for all RD cycles
parameter STATE_MRT1L	= 9'b001zz0010;
parameter STATE_MRT2H	= 9'b001zz0011;
parameter STATE_MRT2L	= 9'b001zz0100;
parameter STATE_MRT3H	= 9'b001zz0101;
parameter STATE_MRT3L	= 9'b001zz0110;
parameter STATE_MRT4H	= 9'b001zz0111;
parameter STATE_MRT4L	= 9'b001zz1000;
parameter STATE_MRT5H	= 9'b001zz1001;
parameter STATE_MRT5L	= 9'b001zz1010;

parameter STATE_MW1T1H	= 9'b010000001;					// MW1 - Memory write 1
parameter STATE_MW1T1L	= 9'b010000010;
parameter STATE_MW1T2H	= 9'b010000011;
parameter STATE_MW1T2L	= 9'b010000100;
parameter STATE_MW1T3H	= 9'b010000101;
parameter STATE_MW1T3L	= 9'b010000110;
parameter STATE_MW1T4H	= 9'b010000111;
parameter STATE_MW1T4L	= 9'b010001000;
parameter STATE_MW1T5H	= 9'b010001001;
parameter STATE_MW1T5L	= 9'b010001010;

parameter STATE_MW2T1H	= 9'b010010001;					// MW2 - Memory write 2
parameter STATE_MW2T1L	= 9'b010010010;
parameter STATE_MW2T2H	= 9'b010010011;
parameter STATE_MW2T2L	= 9'b010010100;
parameter STATE_MW2T3H	= 9'b010010101;
parameter STATE_MW2T3L	= 9'b010010110;
parameter STATE_MW2T4H	= 9'b010010111;
parameter STATE_MW2T4L	= 9'b010011000;
parameter STATE_MW2T5H	= 9'b010011001;
parameter STATE_MW2T5L	= 9'b010011010;

parameter STATE_MWT1H	= 9'b010zz0001;					// Match for all WR cycles
parameter STATE_MWT1L	= 9'b010zz0010;
parameter STATE_MWT2H	= 9'b010zz0011;
parameter STATE_MWT2L	= 9'b010zz0100;
parameter STATE_MWT3H	= 9'b010zz0101;
parameter STATE_MWT3L	= 9'b010zz0110;
parameter STATE_MWT4H	= 9'b010zz0111;
parameter STATE_MWT4L	= 9'b010zz1000;
parameter STATE_MWT5H	= 9'b010zz1001;
parameter STATE_MWT5L	= 9'b010zz1010;

parameter STATE_IRT1H	= 9'b011000001;					// IR - IO read
parameter STATE_IRT1L	= 9'b011000010;
parameter STATE_IRT2H	= 9'b011000011;
parameter STATE_IRT2L	= 9'b011000100;
parameter STATE_IRT3H	= 9'b011000101;
parameter STATE_IRT3L	= 9'b011000110;
parameter STATE_IRT4H	= 9'b011000111;
parameter STATE_IRT4L	= 9'b011001000;

parameter STATE_IWT1H	= 9'b100000001;					// IW - IO Write
parameter STATE_IWT1L	= 9'b100000010;
parameter STATE_IWT2H	= 9'b100000011;
parameter STATE_IWT2L	= 9'b100000100;
parameter STATE_IWT3H	= 9'b100000101;
parameter STATE_IWT3L	= 9'b100000110;
parameter STATE_IWT4H	= 9'b100000111;
parameter STATE_IWT4L	= 9'b100001000;

parameter STATE_NIT1H	= 9'b101000001;					// NMI/INT1/HALT M1 Cycle
parameter STATE_NIT1L	= 9'b101000010;
parameter STATE_NIT2H	= 9'b101000011;
parameter STATE_NIT2L	= 9'b101000100;
parameter STATE_NIT3H	= 9'b101000101;
parameter STATE_NIT3L	= 9'b101000110;
parameter STATE_NIT4H	= 9'b101000111;
parameter STATE_NIT4L	= 9'b101001000;

parameter STATE_GN1T1H	= 9'b111000001;					// General Cycle 1 - 16 bit addition etc
parameter STATE_GN1T1L	= 9'b111000010;
parameter STATE_GN1T2H	= 9'b111000011;
parameter STATE_GN1T2L	= 9'b111000100;
parameter STATE_GN1T3H	= 9'b111000101;
parameter STATE_GN1T3L	= 9'b111000110;
parameter STATE_GN1T4H	= 9'b111000111;
parameter STATE_GN1T4L	= 9'b111001000;
parameter STATE_GN1T5H	= 9'b111001001;
parameter STATE_GN1T5L	= 9'b111001010;

parameter STATE_GN2T1H	= 9'b111010001;					// General Cycle 2 - Block instructions
parameter STATE_GN2T1L	= 9'b111010010;
parameter STATE_GN2T2H	= 9'b111010011;
parameter STATE_GN2T2L	= 9'b111010100;
parameter STATE_GN2T3H	= 9'b111010101;
parameter STATE_GN2T3L	= 9'b111010110;
parameter STATE_GN2T4H	= 9'b111010111;
parameter STATE_GN2T4L	= 9'b111011000;
parameter STATE_GN2T5H	= 9'b111011001;
parameter STATE_GN2T5L	= 9'b111011010;

parameter STATE_GNTXH	= 9'b111zzzzz1;					// Match general H cycles

parameter STATE_GNT1H	= 9'b111zz0001;					// Match cycles T1H
parameter STATE_GNT2H	= 9'b111zz0011;					// T2H
parameter STATE_GNT3H	= 9'b111zz0101;					// T3H
parameter STATE_GNT4H	= 9'b111zz0111;					// T4H
parameter STATE_GNT5H	= 9'b111zz1001;					// T5H

////////////////////////////////////////////////////////////////////////////////
// PLA pattern matches for OPCODE_REG

parameter PLA_PF_EXTD = 12'b000011101101;			// EXTD Prefix only
parameter PLA_PF_IXIY = 12'b000011z11101;			// IX/IY Prefix only
parameter PLA_PF_BITS = 12'b000011001011;			// BITS Prefix (without IX/IY)
parameter PLA_PF_BTXY = 12'bzz0011001011;			// BITS Prefix (with IX/IY)

// 8 bit load

parameter PLA_HALT    = 12'bzz0001110110;			// HALT
parameter PLA_LDR_HXY = 12'bzz0001zzz110;			// LD r,(HL/IX+n/IY+n)
parameter PLA_LDHXY_R = 12'bzz0001110zzz;			// LD (HL/IX+n/IY+n),r
parameter PLA_LDR_R   = 12'bzz0001zzzzzz;			// LD r,r

parameter PLA_LDHXY_N = 12'bzz0000110110;			// LD (HL/IX+n/IY+n),n
parameter PLA_LDR_N	  = 12'bzz0000zzz110;			// LD r,n

parameter PLA_LDA_MM  = 12'bzz000011z010;			// LD A,(nn) (bit3=0)/LD (nn),A (bit3=1)
parameter PLA_LDA_RR  = 12'bzz00000zz010;			// LD A,(rr) (bit3=0)/LD (rr),A (bit3=1)

parameter PLA_LDARIA  = 12'b0010010zz111;			// LD I,A (00)/LD A,I (10)/LD R,A (01)/LD A,R (11)

// 16 bit load

parameter PLA_LDRR_NN  = 12'bzz0000zz0001;			// LD rr,nn (BC/DE/HL/SP)
parameter PLA_LDHL_MM = 12'bzz000010z010;			// LD HL,(nn) (bit3=0)/LD (nn),HL (bit3=1)
parameter PLA_LDRR_MM = 12'b001001zzz011;			// LD (nn),rr (bit3=0)/LD rr,(nn) (bit3=1)

parameter PLA_LDSP_HL = 12'bzz0011111001;			// LD SP,HL
parameter PLA_POPUSH  = 12'bzz0011zz0z01;			// POP (bit2=0)/PUSH (bit2=1) BC/DE/HL/AF

// Exchange, block & search

parameter PLA_EXX	  = 12'bzz0011011001;			// EXX
parameter PLA_EX_AFAF = 12'bzz0000001000;			// EX AF,AF'
parameter PLA_EX_DEHL = 12'bzz0011101011;			// EX DE,HL
parameter PLA_EX_SPHL = 12'bzz0011100011;			// EX (SP),HL

parameter PLA_LDDIR	  = 12'b0010101zz000;			// LDI/LDIR/LDD/LDDR
parameter PLA_CPDIR	  = 12'b0010101zz001;			// CPI/CPIR/CPD/CPDR

// 8 bit arithmetic

parameter PLA_ARI_HXY = 12'bzz0010zzz110;			// ADD/ADC/SUB/SBC/AND/XOR/OR/CP a,(HL/IX+n/IY+n)
parameter PLA_ARI_N	  = 12'bzz0011zzz110;			// ADD/ADC/SUB/SBC/AND/XOR/OR/CP a,n
parameter PLA_ARI_R	  = 12'bzz0010zzzzzz;			// ADD/ADC/SUB/SBC/AND/XOR/OR/CP a,r

parameter PLA_IDC_HXY = 12'bzz000011010z;			// INC/DEC (HL/IX+n/IY+n)
parameter PLA_IDC_R	  = 12'bzz0000zzz10z;			// INC (bit0=0)/DEC (bit0=1) r

// General purpose

parameter PLA_DI	  = 12'bzz0011110011;			// DI
parameter PLA_EI	  = 12'bzz0011111011;			// EI

parameter PLA_CCF	  = 12'bzz0000111111;			// CCF
parameter PLA_SCF	  = 12'bzz0000110111;			// SCF
parameter PLA_CPL	  = 12'bzz0000101111;			// CPL
parameter PLA_DAA	  = 12'bzz0000100111;			// DAA

parameter PLA_IM	  = 12'b001001zzz110;			// IM 0 (zzz)
parameter PLA_NEG	  = 12'b001001zzz100;			// NEG

// 16 bit arithmetic

parameter PLA_ADHL_RR = 12'bzz0000zz1001;			// ADD HL,rr
parameter PLA_ASHL_RR = 12'b001001zzz010;			// ADC HL,rr (bit3=0)/SBC HL,rr (bit3=1)

parameter PLA_IDC_RR  = 12'bzz0000zzz011;			// INC (bit3=0)/DEC (bit3=1) BC/DE/HL/SP

// Jump

parameter PLA_JP_HXY  = 12'bzz0011101001;			// JP (HL)
parameter PLA_JP_NN	  = 12'bzz0011000011;			// JP nn
parameter PLA_JPCC_NN = 12'bzz0011zzz010;			// JP cc,nn

parameter PLA_DJNZ_N  = 12'bzz0000010000;			// DJNZ n
parameter PLA_JR_N	  = 12'bzz0000011000;			// JR n
parameter PLA_JRCC_N  = 12'bzz00001zz000;			// JR c,n (NZ/Z/NC/C)

// Call/Return

parameter PLA_CALL_NN = 12'bzz0011001101;			// CALL nn
parameter PLA_CLCC_NN = 12'bzz0011zzz100;			// CALL cc,nn
parameter PLA_RET	  = 12'bzz0011001001;			// RET
parameter PLA_RET_CC  = 12'bzz0011zzz000;			// RET cc
parameter PLA_RET_NI  = 12'b00100100z101;			// RETN (bit3=0)/RETI (bit3=1)

parameter PLA_RST_N   = 12'bzz0011zzz111;			// RST n

// Shift/Rotate

parameter PLA_RRLC_A  = 12'bzz00000zz111;			// RLCA/RLA/RRCA/RRA

parameter PLA_SHR_HXY = 12'bzz0100zzz110;			// RLC/RL/RRC/RR/SLA/SRA/SLL/SRL (HL/IX+n/IY+n)
parameter PLA_BIT_HXY = 12'bzz0101zzz110;			// BIT n,(HL/IX+n/IY+n)
parameter PLA_SET_HXY = 12'bzz0110zzz110;			// SET n,(HL/IX+n/IY+n)
parameter PLA_RES_HXY = 12'bzz0111zzz110;			// RES n,(HL/IX+n/IY+n)

parameter PLA_SHR_R	  = 12'bzz0100zzzzzz;			// RLC/RL/RRC/RR/SLA/SRA/SLL/SRL r
parameter PLA_BIT_R	  = 12'bzz0101zzzzzz;			// BIT n,r
parameter PLA_SET_R	  = 12'bzz0110zzzzzz;			// SET n,r
parameter PLA_RES_R	  = 12'bzz0111zzzzzz;			// RES n,r

parameter PLA_RLRD	  = 12'b00100110z111;			// RRD (bit3=0)/RLD (bit3=1)

// IO

parameter PLA_IO_R_C  = 12'b001001zzz00z;			// IN R,(C) (bit0=0)/OUT (C),A (bit0=1) (B,C,D,E,H,L,A) NOT (HL)
parameter PLA_IO_A_N  = 12'bzz001101z011;			// OUT (n),A (bit3=0)/IN A,(n) (bit3=1)
parameter PLA_INIDR	  = 12'b0010101zz010;			// INI/INIR/IND/INDR
parameter PLA_OUTIDR  = 12'b0010101zz011;			// OUTI/OTIR/OUTD/OTDR

// Interrupt

parameter PLA_I1_NMI  = 12'b00101111111z;			// Special cycle for interrupt - EXTD prefix + $FF

`define _PARAMS 1
`endif