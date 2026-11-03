`ifndef _PARAMS

////////////////////////////////////////////////////////////////////////////////
// CPU states

parameter STATE_IDLE	= 9'b000000000;

parameter STATE_T1H		= 4'b0001;							// 1 - T state numbers
parameter STATE_T1L		= 4'b0010;							// 2
parameter STATE_T2H		= 4'b0011;							// 3
parameter STATE_T2L		= 4'b0100;							// 4
parameter STATE_T3H		= 4'b0101;							// 5
parameter STATE_T3L		= 4'b0110;							// 6
parameter STATE_T4H		= 4'b0111;							// 7
parameter STATE_T4L		= 4'b1000;							// 8
parameter STATE_T5H		= 4'b1001;							// 9
parameter STATE_T5L		= 4'b1010;							// 10
parameter STATE_T6H		= 4'b1011;							// 11
parameter STATE_T6L		= 4'b1100;							// 12

parameter STATE_M1T1H	= 9'b0_0000_0001;					//  1 - M1 Cycle - instruction fetch/decode and refresh
parameter STATE_M1T1L	= 9'b0_0000_0010;					//  2
parameter STATE_M1T2H	= 9'b0_0000_0011;					//  3
parameter STATE_M1T2L	= 9'b0_0000_0100;					//  4
parameter STATE_M1T3H	= 9'b0_0000_0101;					//  5
parameter STATE_M1T3L	= 9'b0_0000_0110;					//  6
parameter STATE_M1T4H	= 9'b0_0000_0111;					//  7
parameter STATE_M1T4L	= 9'b0_0000_1000;					//  8
parameter STATE_M1T5H	= 9'b0_0000_1001;					//  9
parameter STATE_M1T5L	= 9'b0_0000_1010;					//  A
parameter STATE_M1T6H	= 9'b0_0000_1011;					//  B
parameter STATE_M1T6L	= 9'b0_0000_1100;					//  C	

parameter STATE_NIT1H	= 9'b0_0001_0001;					// 11 - NMI/INT1/HALT M1 Cycle
parameter STATE_NIT1L	= 9'b0_0001_0010;					// 12
parameter STATE_NIT2H	= 9'b0_0001_0011;					// 13
parameter STATE_NIT2L	= 9'b0_0001_0100;					// 14
parameter STATE_NIT3H	= 9'b0_0001_0101;					// 15
parameter STATE_NIT3L	= 9'b0_0001_0110;					// 16
parameter STATE_NIT4H	= 9'b0_0001_0111;					// 17
parameter STATE_NIT4L	= 9'b0_0001_1000;					// 18

parameter STATE_GN1T1H	= 9'b0_0010_0001;					// 21 - General Cycle 1 - 16 bit addition etc
parameter STATE_GN1T1L	= 9'b0_0010_0010;					// 22
parameter STATE_GN1T2H	= 9'b0_0010_0011;					// 23
parameter STATE_GN1T2L	= 9'b0_0010_0100;					// 24
parameter STATE_GN1T3H	= 9'b0_0010_0101;					// 25
parameter STATE_GN1T3L	= 9'b0_0010_0110;					// 26
parameter STATE_GN1T4H	= 9'b0_0010_0111;					// 27
parameter STATE_GN1T4L	= 9'b0_0010_1000;					// 28
parameter STATE_GN1T5H	= 9'b0_0010_1001;					// 29
parameter STATE_GN1T5L	= 9'b0_0010_1010;					// 2A

parameter STATE_GN2T1H	= 9'b0_0011_1001;					// E9 - General Cycle 2 - Block instructions
parameter STATE_GN2T1L	= 9'b0_0011_1010;					// EA
parameter STATE_GN2T2H	= 9'b0_0011_1011;					// EB
parameter STATE_GN2T2L	= 9'b0_0011_1100;					// EC
parameter STATE_GN2T3H	= 9'b0_0011_1101;					// ED
parameter STATE_GN2T3L	= 9'b0_0011_1110;					// EE
parameter STATE_GN2T4H	= 9'b0_0011_1111;					// EF
parameter STATE_GN2T4L	= 9'b0_0011_0000;					// F0
parameter STATE_GN2T5H	= 9'b0_0011_0001;					// F1
parameter STATE_GN2T5L	= 9'b0_0011_0010;					// F2



parameter STATE_MR1T1H	= 9'b0_0100_0001;					// 41 - MR1 - Memory read 1
parameter STATE_MR1T1L	= 9'b0_0100_0010;					// 42
parameter STATE_MR1T2H	= 9'b0_0100_0011;					// 43
parameter STATE_MR1T2L	= 9'b0_0100_0100;					// 44
parameter STATE_MR1T3H	= 9'b0_0100_0101;					// 45
parameter STATE_MR1T3L	= 9'b0_0100_0110;					// 46

parameter STATE_MR1T4H	= 9'b0_0100_0111;					// 47
parameter STATE_MR1T4L	= 9'b0_0100_1000;					// 48
parameter STATE_MR1T5H	= 9'b0_0100_1001;					// 49
parameter STATE_MR1T5L	= 9'b0_0100_1010;					// 4A

parameter STATE_MR2T1H	= 9'b0_0101_0001;					// 51 - MR2 - Memory read 2
parameter STATE_MR2T1L	= 9'b0_0101_0010;					// 52
parameter STATE_MR2T2H	= 9'b0_0101_0011;					// 53
parameter STATE_MR2T2L	= 9'b0_0101_0100;					// 54
parameter STATE_MR2T3H	= 9'b0_0101_0101;					// 55
parameter STATE_MR2T3L	= 9'b0_0101_0110;					// 56

parameter STATE_MR2T4H	= 9'b0_0101_0111;					// 57
parameter STATE_MR2T4L	= 9'b0_0101_1000;					// 58
parameter STATE_MR2T5H	= 9'b0_0101_1001;					// 59
parameter STATE_MR2T5L	= 9'b0_0101_1010;					// 5A

parameter STATE_MR3T1H	= 9'b0_0110_0001;					// 61 - MR3 - Memory read 3
parameter STATE_MR3T1L	= 9'b0_0110_0010;					// 62
parameter STATE_MR3T2H	= 9'b0_0110_0011;					// 63
parameter STATE_MR3T2L	= 9'b0_0110_0100;					// 64
parameter STATE_MR3T3H	= 9'b0_0110_0101;					// 65
parameter STATE_MR3T3L	= 9'b0_0110_0110;					// 66

parameter STATE_MR4T1H	= 9'b0_0111_0001;					// 71 - MR4 - Memory read 4
parameter STATE_MR4T1L	= 9'b0_0111_0010;					// 72
parameter STATE_MR4T2H	= 9'b0_0111_0011;					// 73
parameter STATE_MR4T2L	= 9'b0_0111_0100;					// 74
parameter STATE_MR4T3H	= 9'b0_0111_0101;					// 75
parameter STATE_MR4T3L	= 9'b0_0111_0110;					// 76

parameter STATE_MRT1H	= 9'b0_01zz_0001;					//  1 - Match for all RD cycles
parameter STATE_MRT1L	= 9'b0_01zz_0010;					//  2
parameter STATE_MRT2H	= 9'b0_01zz_0011;					//  3
parameter STATE_MRT2L	= 9'b0_01zz_0100;					//  4
parameter STATE_MRT3H	= 9'b0_01zz_0101;					//  5
parameter STATE_MRT3L	= 9'b0_01zz_0110;					//  6

parameter STATE_MRT4H	= 9'b0_01zz_0111;					//  7
parameter STATE_MRT4L	= 9'b0_01zz_1000;					//  8
parameter STATE_MRT5H	= 9'b0_01zz_1001;					//  9
parameter STATE_MRT5L	= 9'b0_01zz_1010;					//  A

parameter STATE_MW1T1H	= 9'b0_1000_0001;					// 81 - MW1 - Memory write 1
parameter STATE_MW1T1L	= 9'b0_1000_0010;					// 82
parameter STATE_MW1T2H	= 9'b0_1000_0011;					// 83
parameter STATE_MW1T2L	= 9'b0_1000_0100;					// 84
parameter STATE_MW1T3H	= 9'b0_1000_0101;					// 85
parameter STATE_MW1T3L	= 9'b0_1000_0110;					// 86

parameter STATE_MW1T4H	= 9'b0_1000_0111;					// 87
parameter STATE_MW1T4L	= 9'b0_1000_1000;					// 88
parameter STATE_MW1T5H	= 9'b0_1000_1001;					// 89
parameter STATE_MW1T5L	= 9'b0_1000_1010;					// 8A

parameter STATE_MW2T1H	= 9'b0_1001_0001;					// 91 - MW2 - Memory write 2
parameter STATE_MW2T1L	= 9'b0_1001_0010;					// 92
parameter STATE_MW2T2H	= 9'b0_1001_0011;					// 93
parameter STATE_MW2T2L	= 9'b0_1001_0100;					// 94
parameter STATE_MW2T3H	= 9'b0_1001_0101;					// 95
parameter STATE_MW2T3L	= 9'b0_1001_0110;					// 96

parameter STATE_MW2T4H	= 9'b0_1001_0111;					// 97
parameter STATE_MW2T4L	= 9'b0_1001_1000;					// 98
parameter STATE_MW2T5H	= 9'b0_1001_1001;					// 99
parameter STATE_MW2T5L	= 9'b0_1001_1010;					// 9A

parameter STATE_MWT1H	= 9'b0_10zz_0001;					//  1 - Match for all WR cycles
parameter STATE_MWT1L	= 9'b0_10zz_0010;					//  2
parameter STATE_MWT2H	= 9'b0_10zz_0011;					//  3
parameter STATE_MWT2L	= 9'b0_10zz_0100;					//  4
parameter STATE_MWT3H	= 9'b0_10zz_0101;					//  5
parameter STATE_MWT3L	= 9'b0_10zz_0110;					//  6

parameter STATE_MWT4H	= 9'b0_10zz_0111;					//  7
parameter STATE_MWT4L	= 9'b0_10zz_1000;					//  8
parameter STATE_MWT5H	= 9'b0_10zz_1001;					//  9
parameter STATE_MWT5L	= 9'b0_10zz_1010;					//  A

parameter STATE_IRT1H	= 9'b0_1100_0001;					// C1 - IR - IO read
parameter STATE_IRT1L	= 9'b0_1100_0010;					// C2
parameter STATE_IRT2H	= 9'b0_1100_0011;					// C3
parameter STATE_IRT2L	= 9'b0_1100_0100;					// C4
parameter STATE_IRT3H	= 9'b0_1100_0101;					// C5
parameter STATE_IRT3L	= 9'b0_1100_0110;					// C6

parameter STATE_IRT4H	= 9'b0_1100_0111;					// C7
parameter STATE_IRT4L	= 9'b0_1100_1000;					// C8

parameter STATE_IWT1H	= 9'b0_1101_0001;					// D1 - IW - IO Write
parameter STATE_IWT1L	= 9'b0_1101_0010;					// D2
parameter STATE_IWT2H	= 9'b0_1101_0011;					// D3
parameter STATE_IWT2L	= 9'b0_1101_0100;					// D4
parameter STATE_IWT3H	= 9'b0_1101_0101;					// D5
parameter STATE_IWT3L	= 9'b0_1101_0110;					// D6

parameter STATE_IWT4H	= 9'b0_1101_0111;					// D7
parameter STATE_IWT4L	= 9'b0_1101_1000;					// D8

parameter STATE_GNTXH	= 9'b1_11zz_zzz1;					// Match general H cycles

parameter STATE_GNT1H	= 9'b1_11zz_0001;					// Match cycles T1H
parameter STATE_GNT2H	= 9'b1_11zz_0011;					// T2H
parameter STATE_GNT3H	= 9'b1_11zz_0101;					// T3H
parameter STATE_GNT4H	= 9'b1_11zz_0111;					// T4H
parameter STATE_GNT5H	= 9'b1_11zz_1001;					// T5H

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

parameter PLA_LDARI   = 12'b00100101z111;			// LD A,I (0)/LD A,R (1)
parameter PLA_LDRIA   = 12'b00100100z111;			// LD I,A (0)/LD R,A (1)

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