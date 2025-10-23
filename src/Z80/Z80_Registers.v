`include "Z80_Registers.vh"

////////////////////////////////////////////////////////////////////////////////
// Register Decode. Input argument bits:
// 0-2 = Requested register (0-7 for B-A) except 6 - (HL)
// 3   = EXA - EX AF, AF' status
// 4   = EXX - EXX status
// 5   = IX Prefix
// 6   = IY Prefix

module REG_DECODE ( 
    input  reg IY,
    input  reg IX,
    input  reg EXX,
    input  reg EXA,
    input  reg [2:0]REG_NUM,

    output reg [4:0]REG8_INDEX,                  // Output index for 8 bit reg
    output reg [3:0]REG16_INDEX                  // Output index for 16 bit reg
);

`include "..\\Global.vh"

localparam REG_B   = 0;
localparam REG_C   = 1;
localparam REG_D   = 2;
localparam REG_E   = 3;
localparam REG_H   = 4;
localparam REG_L   = 5;
localparam REG_A   = 6;
localparam REG_F   = 7;
localparam REG_B_  = 8;
localparam REG_C_  = 9;
localparam REG_D_  = 10;
localparam REG_E_  = 11;
localparam REG_H_  = 12;
localparam REG_L_  = 13;
localparam REG_A_  = 14;
localparam REG_F_  = 15;
localparam REG_IXH = 16;
localparam REG_IXL = 17;
localparam REG_IYH = 18;
localparam REG_IYL = 19;
localparam REG_I   = 20;
localparam REG_R   = 21;
localparam REG_SPH = 22;
localparam REG_SPL = 23;
localparam REG_PCH = 24;
localparam REG_PCL = 25;
localparam REG_W   = 26;
localparam REG_Z   = 27;

localparam REG_BC  = 0;
localparam REG_DE  = 1;
localparam REG_HL  = 2;
localparam REG_AF  = 3;
localparam REG_BC_ = 4;
localparam REG_DE_ = 5;
localparam REG_HL_ = 6;
localparam REG_AF_ = 7;
localparam REG_IX  = 8;
localparam REG_IY  = 9;
localparam REG_IR  = 10;
localparam REG_SP  = 11;
localparam REG_PC  = 12;
localparam REG_WZ  = 13;

assign REG8_INDEX  = LOOKUP8( { IY, IX, EXX, EXA, REG_NUM });

assign REG16_INDEX = LOOKUP16({ IY, IX, EXX, EXA, REG_NUM });

function automatic [4:0] LOOKUP8( 
	input [6:0]REG_ID
);

    localparam REG_NA = 5'b11111;

	casez(REG_ID)


        'bzzz0111: LOOKUP8 = REG_A;             // A (~EXA, EXX/IX/IY ignored)

        'bzzz1111: LOOKUP8 = REG_A_;            // A'( EXA, EXX/IX/IY ignored)


        'bzz0z000: LOOKUP8 = REG_B;             // B (~EXX, EXA/IX/IY ignored)

        'bzz1z000: LOOKUP8 = REG_B_;            // B'( EXX, EXA/IX/IY ignored)

        'bzz0z001: LOOKUP8 = REG_C;             // C (~EXX, EXA/IX/IY ignored)

        'bzz1z001: LOOKUP8 = REG_C_;            // C'( EXX, EXA/IX/IY ignored)


        'bzz0z010: LOOKUP8 = REG_D;             // D (~EXX, EXA/IX/IY ignored)

        'bzz1z010: LOOKUP8 = REG_D_;            // D'( EXX, EXA/IX/IY ignored)

        'bzz0z011: LOOKUP8 = REG_E;             // E (~EXX, EXA/IX/IY ignored)

        'bzz1z011: LOOKUP8 = REG_E_;            // E'( EXX, EXA/IX/IY ignored)


        'b000z100: LOOKUP8 = REG_H;             // H (~EXX, EXA/IX/IY ignored)

        'b001z100: LOOKUP8 = REG_H_;            // H'( EXX, EXA/IX/IY ignored)

        'b000z101: LOOKUP8 = REG_L;             // L (~EXX, EXA/IX/IY ignored)

        'b001z101: LOOKUP8 = REG_L_;            // L'( EXX, EXA/IX/IY ignored)


        'b01zz100: LOOKUP8 = REG_IXH;           // H (~IY/IX, EXX/EXA ignored)

        'b01zz101: LOOKUP8 = REG_IXL;           // L (~IY/IX, EXX/EXA ignored)

        'b10zz100: LOOKUP8 = REG_IYH;           // H (IY/~IX, EXX/EXA ignored)

        'b10zz101: LOOKUP8 = REG_IYL;           // L (IY/~IX, EXX/EXA ignored)


        default:   LOOKUP8 = REG_NA;            // This should never happen but is here to prevent inferred latches

    endcase

endfunction


function automatic [3:0] LOOKUP16( 
	input [6:0]REG_ID
);

    localparam REG_NA = 4'b1111;

    casez(REG_ID)

        'bzzzz011: LOOKUP16 = REG_SP;           // SP (IX/IY/EXX/EXA ignored) - SET0 - 3 gives SP

        'bzzz0111: LOOKUP16 = REG_AF;           // AF (~EXA, EXX/IX/IY ignored) SET1 - 3 gives AF

        'bzzz1111: LOOKUP16 = REG_AF_;          // AF' (EXA, EXX/IX/IY ignored)

        'bzz0zz00: LOOKUP16 = REG_BC;           // BC (~EXX, EXA/IX/IY ignored) BC - Same in both sets

        'bzz1zz00: LOOKUP16 = REG_BC_;          // BC' (EXX, EXA/IX/IY ignored)

        'bzz0zz01: LOOKUP16 = REG_DE;           // DE (~EXX, EXA/IX/IY ignored) DE - Same in both sets

        'bzz1zz01: LOOKUP16 = REG_DE_;          // DE' (EXX, EXA/IX/IY ignored)

        'b000zz10: LOOKUP16 = REG_HL;           // HL  (~IY/~IX/~EXX EXA ignored) HL - Same in both sets

        'b001zz10: LOOKUP16 = REG_HL_;          // HL' (~IY/~IX/EXX EXA ignored)

        'b01zzz10: LOOKUP16 = REG_IX;           // HL (~IY/IX, EXX/EXA ignored) IX - Same in both sets

        'b10zzz10: LOOKUP16 = REG_IY;           // HL (IY/~IX, EXX/EXA ignored)

        default:   LOOKUP16 = REG_NA;           // This should never happen but is here to prevent inferred latches

    endcase

endfunction

endmodule
