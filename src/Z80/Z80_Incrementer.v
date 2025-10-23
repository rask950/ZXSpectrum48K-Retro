module Z80_INCREMENTER(

    input  INC_DIR,
    input  INC_BITS,
    input  [15:0]INC_IN,
    output [15:0]INC_OUT
);

localparam FALSE = 1'b0;
localparam  TRUE = 1'b1;

wire c0;												// Carry out from one stage to next
wire c1;
wire c2;
wire c3;
wire c4;
wire c5;
wire c6;
wire c7;
wire c8;
wire c9;
wire cA;
wire cB;
wire cC;
wire cD;
wire cE;
wire cF;

ALU #(.ALU_MODE(2)) a0(
    .I0(INC_IN[0]),
    .I1(TRUE),
    .I3(INC_DIR),
    .SUM(INC_OUT[0]),
    .CIN(~INC_DIR),
    .COUT(c0)
);

ALU #(.ALU_MODE(2)) a1(
    .I0(INC_IN[1]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[1]),
    .CIN(c0),
    .COUT(c1)
);

ALU #(.ALU_MODE(2)) a2(
    .I0(INC_IN[2]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[2]),
    .CIN(c1),
    .COUT(c2)
);

ALU #(.ALU_MODE(2)) a3(
    .I0(INC_IN[3]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[3]),
    .CIN(c2),
    .COUT(c3)
);

ALU #(.ALU_MODE(2)) a4(
    .I0(INC_IN[4]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[4]),
    .CIN(c3),
    .COUT(c4)
);

ALU #(.ALU_MODE(2)) a5(
    .I0(INC_IN[5]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[5]),
    .CIN(c4),
    .COUT(c5)
);

ALU #(.ALU_MODE(2)) a6(
    .I0(INC_IN[6]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[6]),
    .CIN(c5),
    .COUT(c6)
);

ALU #(.ALU_MODE(2)) a7(
    .I0(INC_IN[7]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[7]),
    .CIN(INC_BITS & c6),								// Stop carry out here if BITS=0 (7 bit)
    .COUT(c7)
);

ALU #(.ALU_MODE(2)) a8(
    .I0(INC_IN[8]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[8]),
    .CIN(c7),
    .COUT(c8)
);

ALU #(.ALU_MODE(2)) a9(
    .I0(INC_IN[9]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[9]),
    .CIN(c8),
    .COUT(c9)
);

ALU #(.ALU_MODE(2)) aA(
    .I0(INC_IN[10]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[10]),
    .CIN(c9),
    .COUT(cA)
);

ALU #(.ALU_MODE(2)) aB(
    .I0(INC_IN[11]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[11]),
    .CIN(cA),
    .COUT(cB)
);

ALU #(.ALU_MODE(2)) aC(
    .I0(INC_IN[12]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[12]),
    .CIN(cB),
    .COUT(cC)
);

ALU #(.ALU_MODE(2)) aD(
    .I0(INC_IN[13]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[13]),
    .CIN(cC),
    .COUT(cD)
);

ALU #(.ALU_MODE(2)) aE(
    .I0(INC_IN[14]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[14]),
    .CIN(cD),
    .COUT(cE)
);

ALU #(.ALU_MODE(2)) aF(
    .I0(INC_IN[15]),
    .I1(FALSE),
    .I3(INC_DIR),
    .SUM(INC_OUT[15]),
    .CIN(cE),
    .COUT(cF)
);

endmodule