`ifndef _FSM

    typedef union packed {
        reg [ 0:27][ 7: 0]R8;
        reg [ 0:13][15: 0]R16;
    } REGS;

	typedef struct packed {
		reg [ 3: 0]M;
		reg [ 3: 0]T;
	} FSM_REG;

////////////////////////////////////////////////////////////////////////////////
// CPU states

parameter STATE_IDLE	= 8'b00_00_0000;

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

////////////////////////////////////////////////////////////////////////////////
// Machine cycles begin 000

parameter STATE_M1T1H	= 8'b00_00_0001;					//  1 - 00 - M1 Cycle - instruction fetch/decode and refresh
parameter STATE_M1T1L	= 8'b00_00_0010;					//  2
parameter STATE_M1T2H	= 8'b00_00_0011;					//  3
parameter STATE_M1T2L	= 8'b00_00_0100;					//  4
parameter STATE_M1T3H	= 8'b00_00_0101;					//  5
parameter STATE_M1T3L	= 8'b00_00_0110;					//  6
parameter STATE_M1T4H	= 8'b00_00_0111;					//  7
parameter STATE_M1T4L	= 8'b00_00_1000;					//  8
parameter STATE_M1T5H	= 8'b00_00_1001;					//  9
parameter STATE_M1T5L	= 8'b00_00_1010;					//  A
parameter STATE_M1T6H	= 8'b00_00_1011;					//  B
parameter STATE_M1T6L	= 8'b00_00_1100;					//  C	

parameter STATE_NIT1H	= 8'b00_01_0001;					// 11 - 01 - NMI/INT1/HALT M1 Cycle (fake M1 cycle)
parameter STATE_NIT1L	= 8'b00_01_0010;					// 12
parameter STATE_NIT2H	= 8'b00_01_0011;					// 13
parameter STATE_NIT2L	= 8'b00_01_0100;					// 14
parameter STATE_NIT3H	= 8'b00_01_0101;					// 15
parameter STATE_NIT3L	= 8'b00_01_0110;					// 16
parameter STATE_NIT4H	= 8'b00_01_0111;					// 17
parameter STATE_NIT4L	= 8'b00_01_1000;					// 18

parameter STATE_GN1T1H	= 8'b00_10_0001;					// 21 - 10 - General Cycle 1 - 16 bit addition etc
parameter STATE_GN1T1L	= 8'b00_10_0010;					// 22
parameter STATE_GN1T2H	= 8'b00_10_0011;					// 23
parameter STATE_GN1T2L	= 8'b00_10_0100;					// 24
parameter STATE_GN1T3H	= 8'b00_10_0101;					// 25
parameter STATE_GN1T3L	= 8'b00_10_0110;					// 26
parameter STATE_GN1T4H	= 8'b00_10_0111;					// 27
parameter STATE_GN1T4L	= 8'b00_10_1000;					// 28
parameter STATE_GN1T5H	= 8'b00_10_1001;					// 29
parameter STATE_GN1T5L	= 8'b00_10_1010;					// 2A

parameter STATE_GN2T1H	= 8'b00_11_0001;					// 31 - 11 - General Cycle 2 - Block instructions
parameter STATE_GN2T1L	= 8'b00_11_0010;					// 32
parameter STATE_GN2T2H	= 8'b00_11_0011;					// 33
parameter STATE_GN2T2L	= 8'b00_11_0100;					// 34
parameter STATE_GN2T3H	= 8'b00_11_0101;					// 35
parameter STATE_GN2T3L	= 8'b00_11_0110;					// 36
parameter STATE_GN2T4H	= 8'b00_11_0111;					// 37
parameter STATE_GN2T4L	= 8'b00_11_1000;					// 38
parameter STATE_GN2T5H	= 8'b00_11_1001;					// 39
parameter STATE_GN2T5L	= 8'b00_11_1010;					// 3A

parameter STATE_GNT1H	= 8'b00_1z_0001;					// Match general T1H cycles
parameter STATE_GNT2H	= 8'b00_1z_0011;					// T2H
parameter STATE_GNT3H	= 8'b00_1z_0101;					// T3H
parameter STATE_GNT4H	= 8'b00_1z_0111;					// T4H
parameter STATE_GNT5H	= 8'b00_1z_1001;					// T5H

////////////////////////////////////////////////////////////////////////////////
// Memory read cycles begin 001

parameter STATE_MR1T1H	= 8'b01_00_0001;					// 41 - 00 - MR1 - Memory read 1
parameter STATE_MR1T1L	= 8'b01_00_0010;					// 42
parameter STATE_MR1T2H	= 8'b01_00_0011;					// 43
parameter STATE_MR1T2L	= 8'b01_00_0100;					// 44
parameter STATE_MR1T3H	= 8'b01_00_0101;					// 45
parameter STATE_MR1T3L	= 8'b01_00_0110;					// 46
parameter STATE_MR1T4H	= 8'b01_00_0111;					// 47
parameter STATE_MR1T4L	= 8'b01_00_1000;					// 48
parameter STATE_MR1T5H	= 8'b01_00_1001;					// 49
parameter STATE_MR1T5L	= 8'b01_00_1010;					// 4A

parameter STATE_MR2T1H	= 8'b01_01_0001;					// 51 - 01 - MR2 - Memory read 2
parameter STATE_MR2T1L	= 8'b01_01_0010;					// 52
parameter STATE_MR2T2H	= 8'b01_01_0011;					// 53
parameter STATE_MR2T2L	= 8'b01_01_0100;					// 54
parameter STATE_MR2T3H	= 8'b01_01_0101;					// 55
parameter STATE_MR2T3L	= 8'b01_01_0110;					// 56
parameter STATE_MR2T4H	= 8'b01_01_0111;					// 57
parameter STATE_MR2T4L	= 8'b01_01_1000;					// 58
parameter STATE_MR2T5H	= 8'b01_01_1001;					// 59
parameter STATE_MR2T5L	= 8'b01_01_1010;					// 5A

parameter STATE_MR3T1H	= 8'b01_10_0001;					// 61 - 10 - MR3 - Memory read 3
parameter STATE_MR3T1L	= 8'b01_10_0010;					// 62
parameter STATE_MR3T2H	= 8'b01_10_0011;					// 63
parameter STATE_MR3T2L	= 8'b01_10_0100;					// 64
parameter STATE_MR3T3H	= 8'b01_10_0101;					// 65
parameter STATE_MR3T3L	= 8'b01_10_0110;					// 66

parameter STATE_MR4T1H	= 8'b01_11_0001;					// 71 - 11 - MR4 - Memory read 4
parameter STATE_MR4T1L	= 8'b01_11_0010;					// 72
parameter STATE_MR4T2H	= 8'b01_11_0011;					// 73
parameter STATE_MR4T2L	= 8'b01_11_0100;					// 74
parameter STATE_MR4T3H	= 8'b01_11_0101;					// 75
parameter STATE_MR4T3L	= 8'b01_11_0110;					// 76

parameter STATE_MRT1H	= 8'b01_zz_0001;					// z1 - Match for all RD cycles
parameter STATE_MRT1L	= 8'b01_zz_0010;					// z2
parameter STATE_MRT2H	= 8'b01_zz_0011;					// z3
parameter STATE_MRT2L	= 8'b01_zz_0100;					// z4
parameter STATE_MRT3H	= 8'b01_zz_0101;					// z5
parameter STATE_MRT3L	= 8'b01_zz_0110;					// z6
parameter STATE_MRT4H	= 8'b01_zz_0111;					// z7
parameter STATE_MRT4L	= 8'b01_zz_1000;					// z8
parameter STATE_MRT5H	= 8'b01_zz_1001;					// z9
parameter STATE_MRT5L	= 8'b01_zz_1010;					// zA

////////////////////////////////////////////////////////////////////////////////
// Memory write cycles begin 10

parameter STATE_MW1T1H	= 8'b10_00_0001;					// 81 - 00 - MW1 - Memory write 1
parameter STATE_MW1T1L	= 8'b10_00_0010;					// 82
parameter STATE_MW1T2H	= 8'b10_00_0011;					// 83
parameter STATE_MW1T2L	= 8'b10_00_0100;					// 84
parameter STATE_MW1T3H	= 8'b10_00_0101;					// 85
parameter STATE_MW1T3L	= 8'b10_00_0110;					// 86
parameter STATE_MW1T4H	= 8'b10_00_0111;					// 87
parameter STATE_MW1T4L	= 8'b10_00_1000;					// 88
parameter STATE_MW1T5H	= 8'b10_00_1001;					// 89
parameter STATE_MW1T5L	= 8'b10_00_1010;					// 8A

parameter STATE_MW2T1H	= 8'b10_01_0001;					// 91 - 01 - MW2 - Memory write 2
parameter STATE_MW2T1L	= 8'b10_01_0010;					// 92
parameter STATE_MW2T2H	= 8'b10_01_0011;					// 93
parameter STATE_MW2T2L	= 8'b10_01_0100;					// 94
parameter STATE_MW2T3H	= 8'b10_01_0101;					// 95
parameter STATE_MW2T3L	= 8'b10_01_0110;					// 96
parameter STATE_MW2T4H	= 8'b10_01_0111;					// 97
parameter STATE_MW2T4L	= 8'b10_01_1000;					// 98
parameter STATE_MW2T5H	= 8'b10_01_1001;					// 99
parameter STATE_MW2T5L	= 8'b10_01_1010;					// 9A

parameter STATE_MWT1H	= 8'b10_zz_0001;					// z1 - Match for all WR cycles
parameter STATE_MWT1L	= 8'b10_zz_0010;					// z2
parameter STATE_MWT2H	= 8'b10_zz_0011;					// z3
parameter STATE_MWT2L	= 8'b10_zz_0100;					// z4
parameter STATE_MWT3H	= 8'b10_zz_0101;					// z5
parameter STATE_MWT3L	= 8'b10_zz_0110;					// z6
parameter STATE_MWT4H	= 8'b10_zz_0111;					// z7
parameter STATE_MWT4L	= 8'b10_zz_1000;					// z8
parameter STATE_MWT5H	= 8'b10_zz_1001;					// z9
parameter STATE_MWT5L	= 8'b10_zz_1010;					// zA

////////////////////////////////////////////////////////////////////////////////
// IO read/write cycles begin 11

parameter STATE_IRT1H	= 8'b11_00_0001;					// C1 - 00 - IR - IO read
parameter STATE_IRT1L	= 8'b11_00_0010;					// C2
parameter STATE_IRT2H	= 8'b11_00_0011;					// C3
parameter STATE_IRT2L	= 8'b11_00_0100;					// C4
parameter STATE_IRT3H	= 8'b11_00_0101;					// C5
parameter STATE_IRT3L	= 8'b11_00_0110;					// C6
parameter STATE_IRT4H	= 8'b11_00_0111;					// C7
parameter STATE_IRT4L	= 8'b11_00_1000;					// C8

parameter STATE_IWT1H	= 8'b11_01_0001;					// D1 - 01 IW - IO Write
parameter STATE_IWT1L	= 8'b11_01_0010;					// D2
parameter STATE_IWT2H	= 8'b11_01_0011;					// D3
parameter STATE_IWT2L	= 8'b11_01_0100;					// D4
parameter STATE_IWT3H	= 8'b11_01_0101;					// D5
parameter STATE_IWT3L	= 8'b11_01_0110;					// D6
parameter STATE_IWT4H	= 8'b11_01_0111;					// D7
parameter STATE_IWT4L	= 8'b11_01_1000;					// D8

`define _FSM
`endif