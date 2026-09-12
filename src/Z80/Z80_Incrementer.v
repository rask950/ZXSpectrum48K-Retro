module Z80_INCREMENTER(

    input				INC_DIR,
    input				INC_BITS,
    input		[15: 0]	INC_IN,
    output		[15: 0]	INC_OUT
);

	localparam FALSE = 1'b0;
	localparam  TRUE = 1'b1;

	wire		[15: 0]	c;											// Carry out from one stage to next

ALU #(.ALU_MODE(2)) a0(
    .I0(INC_IN[0]),
    .I1(TRUE),
    .I3(INC_DIR),
    .SUM(INC_OUT[0]),
    .CIN(~INC_DIR),
    .COUT(c[0])
);

ALU #(.ALU_MODE(2)) a1(
    .I0(INC_IN[1]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[1]),
    .CIN(c[0]),
    .COUT(c[1])
);

ALU #(.ALU_MODE(2)) a2(
    .I0(INC_IN[2]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[2]),
    .CIN(c[1]),
    .COUT(c[2])
);

ALU #(.ALU_MODE(2)) a3(
    .I0(INC_IN[3]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[3]),
    .CIN(c[2]),
    .COUT(c[3])
);

ALU #(.ALU_MODE(2)) a4(
    .I0(INC_IN[4]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[4]),
    .CIN(c[3]),
    .COUT(c[4])
);

ALU #(.ALU_MODE(2)) a5(
    .I0(INC_IN[5]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[5]),
    .CIN(c[4]),
    .COUT(c[5])
);

ALU #(.ALU_MODE(2)) a6(
    .I0(INC_IN[6]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[6]),
    .CIN(c[5]),
    .COUT(c[6])
);

ALU #(.ALU_MODE(2)) a7(
    .I0(INC_IN[7]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[7]),
    .CIN(INC_BITS & c[6]),								// Stop carry out here if BITS=0 (7 bit)
    .COUT(c[7])
);

ALU #(.ALU_MODE(2)) a8(
    .I0(INC_IN[8]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[8]),
    .CIN(c[7]),
    .COUT(c[8])
);

ALU #(.ALU_MODE(2)) a9(
    .I0(INC_IN[9]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[9]),
    .CIN(c[8]),
    .COUT(c[9])
);

ALU #(.ALU_MODE(2)) aA(
    .I0(INC_IN[10]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[10]),
    .CIN(c[9]),
    .COUT(c[10])
);

ALU #(.ALU_MODE(2)) aB(
    .I0(INC_IN[11]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[11]),
    .CIN(c[10]),
    .COUT(c[11])
);

ALU #(.ALU_MODE(2)) aC(
    .I0(INC_IN[12]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[12]),
    .CIN(c[11]),
    .COUT(c[12])
);

ALU #(.ALU_MODE(2)) aD(
    .I0(INC_IN[13]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[13]),
    .CIN(c[12]),
    .COUT(c[13])
);

ALU #(.ALU_MODE(2)) aE(
    .I0(INC_IN[14]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[14]),
    .CIN(c[13]),
    .COUT(c[14])
);

ALU #(.ALU_MODE(2)) aF(
    .I0(INC_IN[15]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[15]),
    .CIN(c[14]),
    .COUT(c[15])
);

endmodule