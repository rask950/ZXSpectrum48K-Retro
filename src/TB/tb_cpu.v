`timescale 1ns / 1ps

module top(
	input sys_clk								// 28MHz clock
);

`include "..\\Global.vh"

reg 		[ 7: 0] mem [0:15];
reg			[23: 0] cnt;

initial begin

	cnt = 0;

	z80.REG.R16[8] = 16'b0;
	z80.REG.R16[12] = 16'hAA00;

	mem[ 0] = 221;
	mem[ 1] = 33;
	mem[ 2] = 6;
	mem[ 3] = 0;
	mem[ 4] = 221;
	mem[ 5] = 203;
	mem[ 6] = 4;
	mem[ 7] = 22;
	mem[ 8] = 118;
	mem[ 9] = 118;
	mem[10] = 118;
	mem[11] = 118;
	mem[12] = 118;
	mem[13] = 118;
	mem[14] = 118;
	mem[15] = 118;

	#0 $monitor("[%h] %h AD %h PC %h IX%b IY%b RD%b BT%b DB%h OP%h IX %h WZ %h - ALU [%b] OP1 %h OP2 %h R %h", cnt, z80.FSM_STATE, CPU_ADDRESS_BUS, z80.REG.R16[12], z80.IX, z80.IY, CPU_RD, z80.BITS, CPU_DATA_BUS, z80.OPCODE_REG, z80.REG.R16[8], z80.REG.R16[12], z80.ZALU.ENABLE, z80.ZALU.OP1, z80.ZALU.OP2, z80.ZALU.RESULT );

end

always @(posedge sys_clk) begin
	cnt	<= cnt + 1;
//	#1 $display("[%h] %h PC %h M1%b MQ%b RD%b RF%b DB%h BC %h AF %h", cnt, z80.FSM_STATE, z80.REG.R16[12], CPU_M1, CPU_MREQ, CPU_RD, CPU_RFSH, CPU_DATA_BUS, z80.REG.R16[0], z80.REG.R16[3] );
//	#1 $display("ALU [%d][%b] OP1 %h OP2 %h R %h", z80.ZALU.STATE, z80.ZALU.ENABLE, z80.ZALU.OP1, z80.ZALU.OP2, z80.ZALU.RESULT );
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

