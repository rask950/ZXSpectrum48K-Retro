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

assign RESULT = INDEX[2:1] == 2'b00 ? INFLAGS[FLAG_Z] ^ ~INDEX[0] :
                INDEX[2:1] == 2'b01 ? INFLAGS[FLAG_C] ^ ~INDEX[0] :
                INDEX[2:1] == 2'b10 ? INFLAGS[FLAG_P] ^ ~INDEX[0] :
                					  INFLAGS[FLAG_S] ^ ~INDEX[0];

endmodule

