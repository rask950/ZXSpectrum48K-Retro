////////////////////////////////////////////////////////////////////////////////
// Condition Decode. Index argument bits:
// 0 = NZ
// 1 = Z
// 2 = NC
// 3 = C
// 4 = PO (NP)
// 5 = PE (P)
// 6 = P  (NS)
// 7 = M  (S)

module Z80_CC (
	input			[ 2: 0]	INDEX,
	input			[ 7: 0]	INFLAGS,
	output 					RESULT
);

`include "..\\Global.vh"

assign RESULT = GetFlag() ^ ~INDEX[0];

function automatic GetFlag;

    case(INDEX[2:1])
        2'b00:   GetFlag = INFLAGS[FLAG_Z];
        2'b01:   GetFlag = INFLAGS[FLAG_C];
        2'b10:   GetFlag = INFLAGS[FLAG_P];
        default: GetFlag = INFLAGS[FLAG_S];
    endcase

endfunction

endmodule

