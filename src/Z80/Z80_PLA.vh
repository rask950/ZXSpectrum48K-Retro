`ifndef _PLA

////////////////////////////////////////////////////////////////////////////////
// PLA pattern matches for OPCODE_REG

parameter PLA_PF_EXTD = 11'b00011101101;			// EXTD Prefix only
parameter PLA_PF_IXIY = 11'b00011z11101;			// IX/IY Prefix only
parameter PLA_PF_BITS = 11'b00011001011;			// BITS Prefix (without IX/IY)
parameter PLA_PF_BTXY = 11'bz0011001011;			// BITS Prefix (with IX/IY)

// 8 bit load

parameter PLA_HALT    = 11'bz0001110110;			// HALT
parameter PLA_LDR_HXY = 11'bz0001zzz110;			// LD r,(HL/IX+n/IY+n)
parameter PLA_LDHXY_R = 11'bz0001110zzz;			// LD (HL/IX+n/IY+n),r
parameter PLA_LDR_R   = 11'bz0001zzzzzz;			// LD r,r

parameter PLA_LDHXY_N = 11'bz0000110110;			// LD (HL/IX+n/IY+n),n
parameter PLA_LDR_N	  = 11'bz0000zzz110;			// LD r,n

parameter PLA_LDA_MM  = 11'bz000011z010;			// LD A,(nn) (bit3=0)/LD (nn),A (bit3=1)
parameter PLA_LDA_RR  = 11'bz00000zz010;			// LD A,(rr) (bit3=0)/LD (rr),A (bit3=1)

parameter PLA_LDARI   = 11'b0100101z111;			// LD A,I (0)/LD A,R (1)
parameter PLA_LDRIA   = 11'b0100100z111;			// LD I,A (0)/LD R,A (1)

// 16 bit load

parameter PLA_LDRR_NN  = 11'bz0000zz0001;			// LD rr,nn (BC/DE/HL/SP)
parameter PLA_LDHL_MM = 11'bz000010z010;			// LD HL,(nn) (bit3=0)/LD (nn),HL (bit3=1)
parameter PLA_LDRR_MM = 11'b01001zzz011;			// LD (nn),rr (bit3=0)/LD rr,(nn) (bit3=1)

parameter PLA_LDSP_HL = 11'bz0011111001;			// LD SP,HL
parameter PLA_POPUSH  = 11'bz0011zz0z01;			// POP (bit2=0)/PUSH (bit2=1) BC/DE/HL/AF

// Exchange, block & search

parameter PLA_EXX	  = 11'bz0011011001;			// EXX
parameter PLA_EX_AFAF = 11'bz0000001000;			// EX AF,AF'
parameter PLA_EX_DEHL = 11'bz0011101011;			// EX DE,HL
parameter PLA_EX_SPHL = 11'bz0011100011;			// EX (SP),HL

parameter PLA_LDDIR	  = 11'b010101zz000;			// LDI/LDIR/LDD/LDDR
parameter PLA_CPDIR	  = 11'b010101zz001;			// CPI/CPIR/CPD/CPDR

// 8 bit arithmetic

parameter PLA_ARI_HXY = 11'bz0010zzz110;			// ADD/ADC/SUB/SBC/AND/XOR/OR/CP a,(HL/IX+n/IY+n)
parameter PLA_ARI_N	  = 11'bz0011zzz110;			// ADD/ADC/SUB/SBC/AND/XOR/OR/CP a,n
parameter PLA_ARI_R	  = 11'bz0010zzzzzz;			// ADD/ADC/SUB/SBC/AND/XOR/OR/CP a,r

parameter PLA_IDC_HXY = 11'bz000011010z;			// INC/DEC (HL/IX+n/IY+n)
parameter PLA_IDC_R	  = 11'bz0000zzz10z;			// INC (bit0=0)/DEC (bit0=1) r

// General purpose

parameter PLA_DI	  = 11'bz0011110011;			// DI
parameter PLA_EI	  = 11'bz0011111011;			// EI

parameter PLA_CCF	  = 11'bz0000111111;			// CCF
parameter PLA_SCF	  = 11'bz0000110111;			// SCF
parameter PLA_CPL	  = 11'bz0000101111;			// CPL
parameter PLA_DAA	  = 11'bz0000100111;			// DAA

parameter PLA_IM	  = 11'b01001zzz110;			// IM 0 (zzz)
parameter PLA_NEG	  = 11'b01001zzz100;			// NEG

// 16 bit arithmetic

parameter PLA_ADHL_RR = 11'bz0000zz1001;			// ADD HL,rr
parameter PLA_ASHL_RR = 11'b01001zzz010;			// ADC HL,rr (bit3=0)/SBC HL,rr (bit3=1)

parameter PLA_IDC_RR  = 11'bz0000zzz011;			// INC (bit3=0)/DEC (bit3=1) BC/DE/HL/SP

// Jump

parameter PLA_JP_HXY  = 11'bz0011101001;			// JP (HL)
parameter PLA_JP_NN	  = 11'bz0011000011;			// JP nn
parameter PLA_JPCC_NN = 11'bz0011zzz010;			// JP cc,nn

parameter PLA_DJNZ_N  = 11'bz0000010000;			// DJNZ n
parameter PLA_JR_N	  = 11'bz0000011000;			// JR n
parameter PLA_JRCC_N  = 11'bz00001zz000;			// JR c,n (NZ/Z/NC/C)

// Call/Return

parameter PLA_CALL_NN = 11'bz0011001101;			// CALL nn
parameter PLA_CLCC_NN = 11'bz0011zzz100;			// CALL cc,nn
parameter PLA_RET	  = 11'bz0011001001;			// RET
parameter PLA_RET_CC  = 11'bz0011zzz000;			// RET cc
parameter PLA_RET_NI  = 11'b0100100z101;			// RETN (bit3=0)/RETI (bit3=1)

parameter PLA_RST_N   = 11'bz0011zzz111;			// RST n

// Shift/Rotate

parameter PLA_RRLC_A  = 11'bz00000zz111;			// RLCA/RLA/RRCA/RRA

parameter PLA_SHR_HXY = 11'bz0100zzz110;			// RLC/RL/RRC/RR/SLA/SRA/SLL/SRL (HL/IX+n/IY+n)
parameter PLA_BIT_HXY = 11'bz0101zzz110;			// BIT n,(HL/IX+n/IY+n)
parameter PLA_SET_HXY = 11'bz0110zzz110;			// SET n,(HL/IX+n/IY+n)
parameter PLA_RES_HXY = 11'bz0111zzz110;			// RES n,(HL/IX+n/IY+n)

parameter PLA_SHR_R	  = 11'bz0100zzzzzz;			// RLC/RL/RRC/RR/SLA/SRA/SLL/SRL r
parameter PLA_BIT_R	  = 11'bz0101zzzzzz;			// BIT n,r
parameter PLA_SET_R	  = 11'bz0110zzzzzz;			// SET n,r
parameter PLA_RES_R	  = 11'bz0111zzzzzz;			// RES n,r

parameter PLA_RLRD	  = 11'b0100110z111;			// RRD (bit3=0)/RLD (bit3=1)

// IO

parameter PLA_IO_R_C  = 11'b01001zzz00z;			// IN R,(C) (bit0=0)/OUT (C),A (bit0=1) (B,C,D,E,H,L,A) NOT (HL)
parameter PLA_IO_A_N  = 11'bz001101z011;			// OUT (n),A (bit3=0)/IN A,(n) (bit3=1)
parameter PLA_INIDR	  = 11'b010101zz010;			// INI/INIR/IND/INDR
parameter PLA_OUTIDR  = 11'b010101zz011;			// OUTI/OTIR/OUTD/OTDR

// Interrupt

parameter PLA_I1_NMI  = 11'b0101111111z;			// Special cycle for interrupt - EXTD prefix + $FF

`define _PLA
`endif