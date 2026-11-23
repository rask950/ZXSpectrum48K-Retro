`ifndef _PLA

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

`define _PLA
`endif