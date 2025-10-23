// 

`ifndef _REGS

    typedef union packed {
        reg [ 0:27][ 7: 0]R8;
        reg [ 0:13][15: 0]R16;
    } REGS;

	typedef struct packed {
		reg [ 5: 0]M;
		reg [ 3: 0]T;
	} FSM_REG;

    `define REG_B   REG.R8[ 0]
    `define REG_C   REG.R8[ 1]
    `define REG_D   REG.R8[ 2]
    `define REG_E   REG.R8[ 3]
    `define REG_H   REG.R8[ 4]
    `define REG_L   REG.R8[ 5]
    `define REG_A   REG.R8[ 6]
    `define REG_F   REG.R8[ 7]
    `define REG_B_  REG.R8[ 8]
    `define REG_C_  REG.R8[ 9]
    `define REG_D_  REG.R8[10]
    `define REG_E_  REG.R8[11]
    `define REG_H_  REG.R8[12]
    `define REG_L_  REG.R8[13]
    `define REG_A_  REG.R8[14]
    `define REG_F_  REG.R8[15]
    `define REG_IXH REG.R8[16]
    `define REG_IXL REG.R8[17]
    `define REG_IYH REG.R8[18]
    `define REG_IYL REG.R8[19]
    `define REG_I   REG.R8[20]
    `define REG_R   REG.R8[21]
    `define REG_SPH REG.R8[22]
    `define REG_SPL REG.R8[23]
    `define REG_PCH REG.R8[24]
    `define REG_PCL REG.R8[25]
    `define REG_W   REG.R8[26]
    `define REG_Z   REG.R8[27]

    `define REG_BC  REG.R16[ 0]
    `define REG_DE  REG.R16[ 1]
    `define REG_HL  REG.R16[ 2]
    `define REG_AF  REG.R16[ 3]
    `define REG_BC_ REG.R16[ 4]
    `define REG_DE_ REG.R16[ 5]
    `define REG_HL_ REG.R16[ 6]
    `define REG_AF_ REG.R16[ 7]
    `define REG_IX  REG.R16[ 8]
    `define REG_IY  REG.R16[ 9]
    `define REG_IR  REG.R16[10]
    `define REG_SP  REG.R16[11]
    `define REG_PC  REG.R16[12]
    `define REG_WZ  REG.R16[13]

    `define CUR_A REG.R8[ EXA ? 14 : 6 ]
    `define CUR_F REG.R8[ EXA ? 15 : 7 ]

    `define CUR_B REG.R8[ EXX ? 8 : 0 ]

	`define CUR_HL REG.R16[IY ? 9  : IX ? 8  : EXX ? 6  : 2]
	`define CUR_H  REG.R8[ IY ? 18 : IX ? 16 : EXX ? 12 : 4]
	`define CUR_L  REG.R8[ IY ? 19 : IX ? 17 : EXX ? 13 : 5]

	`define CUR_DE REG.R16[EXX ? 5 : 1]

	`define CUR_BC REG.R16[EXX ? 4 : 0]

    `define _REGS 1
`endif
