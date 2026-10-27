`timescale 1ns / 1ps

module top(
	input sys_clk								// 28MHz clock
);

`include "..\\Global.vh"

reg 		[7:0] mem [0:15];

initial begin

	z80.REG.R16[2] = 0;
	z80.REG.R16[3] = 16'hAA00;

	mem[ 0] = 62;
	mem[ 1] = 71;

	#10 $monitor("ADDRESS %h - DATA %d", CPU_ADDRESS_BUS, CPU_DATA_BUS );
	#1 $monitor("ALU OP1 %h", z80.ALU_OP1 );
	#1 $monitor("PC %h HL %h AF %h", z80.REG.R16[12], z80.REG.R16[2], z80.REG.R16[3] );

end

////////////////////////////////////////////////////////////////////////
// CPU control and data buses

wire [ 7: 0]CPU_DATA_BUS;
reg	 [15: 0]CPU_ADDRESS_BUS;
reg			CPU_M1;
reg			CPU_MREQ;
reg			CPU_RD;
reg			CPU_WR;
reg			CPU_RFSH;
reg			CPU_INT;
reg			CPU_WAIT;
reg			CPU_HALT;


TestMem zmem(
	.CPU_ADDRESS(	CPU_ADDRESS_BUS),				// CPU memory access - port B
	.CPU_DATA(	    CPU_DATA_BUS),
	.CPU_RD(		CPU_RD),
	.CPU_WR(		CPU_WR),
	.CPU_MREQ(		CPU_MREQ)
);

////////////////////////////////////////////////////////////////////////
// Z80 CPU

ZX_Spectrum_Z80 z80(

	.CLK(			sys_clk),
	.RESET(			1'b0),

	.DATA_BUS(		CPU_DATA_BUS),

	.ADDRESS_BUS(	CPU_ADDRESS_BUS),

	.NMI(			1'b1),
	.INT(			1'b1),
	.M1(			CPU_M1),
	.MREQ(			CPU_MREQ),
	.IORQ(			CPU_IORQ),
	.RD(			CPU_RD),
	.WR(			CPU_WR),
	.RFSH(			CPU_RFSH),
	.WAIT(			1'b1),
	.HALT(			CPU_HALT)
);

	module TestMem(
		input [15:0] CPU_ADDRESS,
		inout [7:0] CPU_DATA,
		input CPU_RD,
		input CPU_WR,
		input CPU_MREQ
	);

		always @(*) begin
			if (!(CPU_MREQ | CPU_WR)) mem[CPU_ADDRESS[3:0]] = CPU_DATA;
		end

		assign CPU_DATA = CPU_MREQ | CPU_RD ? 8'bz : mem[CPU_ADDRESS[3:0]];

	endmodule

endmodule

