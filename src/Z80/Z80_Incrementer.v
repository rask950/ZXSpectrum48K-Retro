module Z80_INCREMENTER(

    input				INC_DIR,									// This is 0 for decrement, 1 for increment
    input				INC_BITS,									// This is 0 for 7bits, 1 for 16bits
    input		[15: 0]	INC_IN,
    output		[15: 0]	INC_OUT
);

	localparam FALSE = 1'b0;
	localparam  TRUE = 1'b1;

	wire		[ 1: 0]	c0;											// Carry out from one stage to next
	wire		[ 1: 0]	c1;
	wire		[ 1: 0]	c2;
	wire		[ 1: 0]	c3;
	wire		[ 1: 0]	c4;
	wire		[ 1: 0]	c5;
	wire		[ 1: 0]	c6;
	wire		[ 1: 0]	c7;
	wire		[ 1: 0]	c8;
	wire		[ 1: 0]	c9;
	wire		[ 1: 0]	cA;
	wire		[ 1: 0]	cB;
	wire		[ 1: 0]	cC;
	wire		[ 1: 0]	cD;
	wire		[ 1: 0]	cE;
	wire		[ 1: 0]	cF;

ADDSUB1 add0(INC_OUT[ 0], INC_IN[ 0], 1'b1, 1'b0);
ADDC1	adc0(	   c0[1], INC_IN[ 0], 1'b1, 1'b0);
SUBC1	sbc0(	   c0[0], INC_IN[ 0], 1'b1, 1'b0);

ADDSUB1 add1(INC_OUT[ 1], INC_IN[ 1], 1'b0, c0[INC_DIR]);
ADDC1	adc1(	   c1[1], INC_IN[ 1], 1'b0, 	  c0[1]);
SUBC1	sbc1(	   c1[0], INC_IN[ 1], 1'b0, 	  c0[0]);

ADDSUB1 add2(INC_OUT[ 2], INC_IN[ 2], 1'b0, c1[INC_DIR]);
ADDC1	adc2(	   c2[1], INC_IN[ 2], 1'b0, 	  c1[1]);
SUBC1	sbc2(	   c2[0], INC_IN[ 2], 1'b0, 	  c1[0]);

ADDSUB1 add3(INC_OUT[ 3], INC_IN[ 3], 1'b0, c2[INC_DIR]);
ADDC1	adc3(	   c3[1], INC_IN[ 3], 1'b0, 	  c2[1]);
SUBC1	sbc3(	   c3[0], INC_IN[ 3], 1'b0, 	  c2[0]);

ADDSUB1 add4(INC_OUT[ 4], INC_IN[ 4], 1'b0, c3[INC_DIR]);
ADDC1	adc4(	   c4[1], INC_IN[ 4], 1'b0, 	  c3[1]);
SUBC1	sbc4(	   c4[0], INC_IN[ 4], 1'b0, 	  c3[0]);

ADDSUB1 add5(INC_OUT[ 5], INC_IN[ 5], 1'b0, c4[INC_DIR]);
ADDC1	adc5(	   c5[1], INC_IN[ 5], 1'b0, 	  c4[1]);
SUBC1	sbc5(	   c5[0], INC_IN[ 5], 1'b0, 	  c4[0]);

ADDSUB1 add6(INC_OUT[ 6], INC_IN[ 6], 1'b0, c5[INC_DIR]);
ADDC1	adc6(	   c6[1], INC_IN[ 6], 1'b0, 	  c5[1]);
SUBC1	sbc6(	   c6[0], INC_IN[ 6], 1'b0, 	  c5[0]);

ADDSUB1 add7(INC_OUT[ 7], INC_IN[ 7], 1'b0, INC_BITS & c6[INC_DIR]);	// For the 8th bit, only add in the carry
ADDC1	adc7(	   c7[1], INC_IN[ 7], 1'b0, INC_BITS & c6[1]);			// if INC_BITS is set as this indicates 16 bit addition
SUBC1	sbc7(	   c7[0], INC_IN[ 7], 1'b0, INC_BITS & c6[0]);			// if INC_BITS is reset then the addition is stopped at this point

ADDSUB1 add8(INC_OUT[ 8], INC_IN[ 8], 1'b0, c7[INC_DIR]);
ADDC1	adc8(	   c8[1], INC_IN[ 8], 1'b0, 	  c7[1]);
SUBC1	sbc8(	   c8[0], INC_IN[ 8], 1'b0, 	  c7[0]);

ADDSUB1 add9(INC_OUT[ 9], INC_IN[ 9], 1'b0, c8[INC_DIR]);
ADDC1	adc9(	   c9[1], INC_IN[ 9], 1'b0, 	  c8[1]);
SUBC1	sbc9(	   c9[0], INC_IN[ 9], 1'b0, 	  c8[0]);	

ADDSUB1 addA(INC_OUT[10], INC_IN[10], 1'b0, c9[INC_DIR]);
ADDC1	adcA(	   cA[1], INC_IN[10], 1'b0, 	  c9[1]);
SUBC1	sbcA(	   cA[0], INC_IN[10], 1'b0, 	  c9[0]);

ADDSUB1 addB(INC_OUT[11], INC_IN[11], 1'b0, cA[INC_DIR]);
ADDC1	adcB(	   cB[1], INC_IN[11], 1'b0, 	  cA[1]);
SUBC1	sbcB(	   cB[0], INC_IN[11], 1'b0, 	  cA[0]);

ADDSUB1 addC(INC_OUT[12], INC_IN[12], 1'b0, cB[INC_DIR]);
ADDC1	adcC(	   cC[1], INC_IN[12], 1'b0, 	  cB[1]);
SUBC1	sbcC(	   cC[0], INC_IN[12], 1'b0, 	  cB[0]);

ADDSUB1 addD(INC_OUT[13], INC_IN[13], 1'b0, cC[INC_DIR]);
ADDC1	adcD(	   cD[1], INC_IN[13], 1'b0, 	  cC[1]);
SUBC1	sbcD(	   cD[0], INC_IN[13], 1'b0, 	  cC[0]);

ADDSUB1 addE(INC_OUT[14], INC_IN[14], 1'b0, cD[INC_DIR]);
ADDC1	adcE(	   cE[1], INC_IN[14], 1'b0, 	  cD[1]);
SUBC1	sbcE(	   cE[0], INC_IN[14], 1'b0, 	  cD[0]);

ADDSUB1 addF(INC_OUT[15], INC_IN[15], 1'b0, cE[INC_DIR]);

endmodule