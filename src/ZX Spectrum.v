
////////////////////////////////////////////////////////////////////////

module top(

	input SYS_CLK,								// 28MHz clock
	input BTN1,									// Reset button

	input  [5:0]EXT_IN_PORT,					// Half row KB + AUDIO input port
	output [1:0]EXT_OUT_PORT,					// MIC/SPEAKER AUDIO output
	output [7:0]EXT_ADDRESS_BUS,				// High order address bus for KB read

	output		SD_CLK,							// SD Card connections
	input		SD_DAT0,
	inout		SD_CMD,
	output		SD_DAT1,
	output		SD_DAT2,
	output		SD_DAT3,

	output [2:0]TMDSp,							// HDMI output
	output [2:0]TMDSn,
	output	  TMDSp_clock,
 	output	  TMDSn_clock,

	output [1:0]led,

	inout		USB0_DP,						// USB Data port 0
	inout		USB0_DN,
	inout		USB1_DP,						// USB Data port 1
	inout		USB1_DN
);

`include "Global.vh"

////////////////////////////////////////////////////////////////////////
// ULA control and data buses for DMA

reg [ 7:0]ULA_RD_DATA;
reg [15:0]ULA_ADDRESS;
reg		  ULA_RD;
reg [ 7:0]ULA_PAGING;							// Memory paging control

////////////////////////////////////////////////////////////////////////
// SD control and data buses for DMA

reg  [7:0]SD_WR_DATA;
reg [15:0]SD_ADDRESS;
reg		  SD_WR_EN;

////////////////////////////////////////////////////////////////////////
// CPU control and data buses

wire [7:0]CPU_RD_DATA;
reg  [7:0]CPU_WR_DATA;
reg [15:0]CPU_ADDRESS;
reg		  CPU_M1;
reg		  CPU_MREQ;
reg		  CPU_RD;
reg		  CPU_WR;
reg		  CPU_RFSH;
reg		  CPU_INT;
reg		  CPU_WAIT;
reg       CPU_HALT;

////////////////////////////////////////////////////////////////////////
// Clocks for memory 14MHz (for ULA) and CPU (7MHz)

wire MEM_CLK;
wire CPU_CLK;
wire SDC_CLK;

////////////////////////////////////////////////////////////////////////
// Hgh order 7 bits for keyboard decoding

assign EXT_ADDRESS_BUS = CPU_ADDRESS[15:8];

////////////////////////////////////////////////////////////////////////
// Dual port memory module

ZX_Spectrum_MEM mem(

	.CLK(			MEM_CLK),
	.RESET(			~BTN1),
	.PAGING(		ULA_PAGING),

	.ULA_ADDRESS(	ULA_ADDRESS),					// ULA DMA - memory port A, page 1
	.ULA_RD_DATA(	ULA_RD_DATA),
	.ULA_RD(		ULA_RD),

	.SD_ADDRESS(	SD_ADDRESS),				  // SD DMA - memory port A, page 4
	.SD_WR_DATA(	SD_WR_DATA),
	.SD_WR(			SD_WR_EN),

	.CPU_ADDRESS(	CPU_ADDRESS),					// CPU memory access - port B
	.CPU_RD_DATA(	CPU_RD_DATA),
	.CPU_WR_DATA(	CPU_WR_DATA),
	.CPU_RD(		CPU_RD),
	.CPU_WR(		CPU_WR),
	.CPU_MREQ(		CPU_MREQ)
);

////////////////////////////////////////////////////////////////////////
// Z80 CPU

ZX_Spectrum_Z80 z80(

	.CLK(			CPU_CLK),
	.RESET(			~BTN1),

	.DATA_IN(		CPU_RD_DATA),
	.DATA_OUT(		CPU_WR_DATA),

	.ADDRESS_BUS(	CPU_ADDRESS),

	.NMI(			INACTIVE),
	.INT(			CPU_INT),
	.M1(			CPU_M1),
	.MREQ(			CPU_MREQ),
	.IORQ(			CPU_IORQ),
	.RD(			CPU_RD),
	.WR(			CPU_WR),
	.RFSH(			CPU_RFSH),
	.WAIT(			CPU_WAIT),
    .HALT(          CPU_HALT)
);

////////////////////////////////////////////////////////////////////////
// Spectrum ULA

ZX_Spectrum_ULA #(

	.IO_PORT1(0),								// ULA IO Port $FE
	.IO_PORT2(2)								// Paging Port $FB

	) ula (

	.SYS_CLK(		SYS_CLK),					// Master clock in 50MHz

	.CLK_28(		SDC_CLK),
	.CLK_14(		MEM_CLK),					// Clocks out from ULA
	.CLK_7(		 	CPU_CLK),

	.IO_IN(			EXT_IN_PORT),				// Physical IO
	.IO_OUT(		EXT_OUT_PORT),

	.RESET(		 	~BTN1),						// Reset button

	.PAGING(		ULA_PAGING),				// Memory paging

	.DMA_DATA_IN(	ULA_RD_DATA),				// ULA DMA video generation
	.DMA_ADDRESS(	ULA_ADDRESS),
	.DMA_RD_ENABLE(	ULA_RD),

	.CPU_WR_DATA(	CPU_WR_DATA),				// CPU IO access
	.CPU_RD_DATA(	CPU_RD_DATA),
	.CPU_ADDRESS(	CPU_ADDRESS),
	.CPU_MREQ(	  	CPU_MREQ),
	.CPU_IORQ(		CPU_IORQ),
	.CPU_RD(		CPU_RD),
	.CPU_WR(		CPU_WR),
	.CPU_INT(		CPU_INT),
	.CPU_WAIT(	  	CPU_WAIT),

	.LED(           led),

	.USB0_DP(       USB0_DP),					// USB Data port 0
	.USB0_DN(       USB0_DN),
	.USB1_DP(       USB1_DP),					// USB Data port 1
	.USB1_DN(       USB1_DN),

	.TMDSp(			TMDSp),						// DVI video output
	.TMDSn(			TMDSn),
	.TMDSp_clock(	TMDSp_clock),
	.TMDSn_clock(	TMDSn_clock)
);

////////////////////////////////////////////////////////////////////////
// SD Card

 ZX_Spectrum_SD #(

	 .IO_PORT(1)								// SD IO Port $FD

	 ) sdcard (

	.CLK_28(		SDC_CLK),
 	.RESET(			~BTN1),

 	.CPU_WR_DATA(	CPU_WR_DATA),				// CPU Bus
 	.CPU_RD_DATA(	CPU_RD_DATA),
 	.CPU_ADDRESS(	CPU_ADDRESS),
 	.CPU_IORQ(		CPU_IORQ),
 	.CPU_RD(		CPU_RD),
 	.CPU_WR(		CPU_WR),

 	.DMA_WR_DATA(	SD_WR_DATA),				// SD Card DMA
 	.DMA_ADDRESS(	SD_ADDRESS),
 	.DMA_WR_ENABLE(	SD_WR_EN),
	.ULA_PAGING(	ULA_PAGING),				// Paging memory register so we can lock the IO port

 	.SD_CLK(		SD_CLK),					// SD Card connections
 	.SD_CMD(		SD_CMD),
 	.SD_DAT0(		SD_DAT0),
 	.SD_DAT1(		SD_DAT1),
 	.SD_DAT2(		SD_DAT2),
 	.SD_DAT3(		SD_DAT3)
 );



endmodule
