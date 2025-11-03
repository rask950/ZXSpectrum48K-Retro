`timescale 1ns/1ps

module ZX_Spectrum_ULA(

	input 				SYS_CLK,					// 28MHz (MASTER)
	output				CLK_28,						// 28MHz (SD)
	output				CLK_14,						// 14MHz (MEM)
	output				CLK_7,						//  7MHz (CPU)

	output				RESET,						// reset signal

	output		[ 7: 0] PAGING,						// Paging register

	input  reg	[ 7: 0] DMA_DATA_IN,				// ULA DMA
	output reg	[15: 0] DMA_ADDRESS,
	output reg		 	DMA_RD_ENABLE,

	input				CPU_IORQ,					// CPU 
	input				CPU_MREQ,
	input				CPU_RD,
	input				CPU_WR,
	input		[15: 0] CPU_ADDRESS,
	input		[ 7: 0] CPU_WR_DATA,
	output		[ 7: 0] CPU_RD_DATA,
	output				CPU_INT,
	output				CPU_WAIT,

	// Physical connections

	input  		[ 5: 0] IO_IN,						// Input port FE - AUDIO IN/KB
	output 		[ 1: 0] IO_OUT,						// Output port FE - MIC & SPEAKER

	output		[ 1: 0] LED,

	inout				USB0_DP,					// USB ports
	inout				USB0_DN,
	inout				USB1_DP,
	inout				USB1_DN,

	output		[ 2: 0] TMDSp,						// DVI Output
	output		[ 2: 0] TMDSn,
	output				TMDSp_clock,
	output				TMDSn_clock
);

parameter IO_PORT1 = 0;								// Bit number for port $FE
parameter IO_PORT2 = 2;								// Bit number for port $FB (paging)

localparam FALSE = 1'b0;
localparam TRUE  = 1'b1;

////////////////////////////////////////////////////////////////////////
// ULA IO port regs

reg [7:0]IO_PORT_ULA;								// ULA's only IO port
reg	[7:0]IO_PORT_MEM;								// Memory paging register

assign PAGING = IO_PORT_MEM;

initial begin

	IO_PORT_ULA = 0;
	IO_PORT_MEM = 0; //8'b01010000;					// Default page-in SD card mem

end

////////////////////////////////////////////////////////////////////////
// Main clock generator

wire CLK_140;										// For DVI output (internal)

ZX_Spectrum_CLK zclk(
	.clkin(SYS_CLK),								// Input clock 28MHz
	.reset(1'b0),
	.clkout0(CLK_28),					 			// Output clk 28MHz 
	.clkout1(CLK_140),					 			// Output clk 140MHz
	.clkout2(CLK_14),								// Output clk 14MHz
	.clkout3(CLK_7)						 			// Output clk 7MHz
);

////////////////////////////////////////////////////////////////////////
// DVI output processing

localparam DISPLAY_WIDTH	= 768;		 		// Pixel dimensions of visible display (576p ?)
localparam DISPLAY_HEIGHT	= 576;

localparam INT_X_END		= 256;				// 256 @ 28MHz = 32 @ 3.5MHz - interrupt min duration

localparam DVI_WIDTH		= 895;				// Dimensions (-1) of DVI raster
localparam DVI_HEIGHT		= 623;
localparam DVI_HSYNC_START	= 781;				// Horizontal and vertical sync positions
localparam DVI_HSYNC_END	= 857;
localparam DVI_VSYNC_START	= 586;
localparam DVI_VSYNC_END	= 591;

localparam SPEC_HSTART		= 128;				// Spectrum pixel display horizontal boundaries
localparam SPEC_HEND		= 640;				// within the DVI DISPLAY area
localparam SPEC_VSTART		= 96;				// Spectrum pixel display vertical boundaries
localparam SPEC_VEND		= 480;
localparam SPEC_DSTART		= 94;				// Spectrum DMA start and end 1 row before pixel output
localparam SPEC_DEND		= 478;

reg [3:0]COLOUR_INDEX;							// Current pixel colour index 0-15

reg [7:0]DVI_RED;								// RGB values for current pixel
reg [7:0]DVI_GREEN;
reg [7:0]DVI_BLUE;

reg [9:0]DVI_X;									// Horizontal and vertical counters
reg [9:0]DVI_Y;

reg DVI_HSYNC;									// Horizontal and vertical sync signals
reg DVI_VSYNC;

reg DVI_ENABLE;									// Flag indicating the visible display is being output at DVI
reg DVI_INT;

reg PIXEL_ENABLE;								// Flags for active TV pixel output vs border output
reg PIXEL_READ;

initial begin

	DVI_X = 0;
	DVI_Y = 0;

	DVI_HSYNC  = FALSE;
	DVI_VSYNC  = FALSE;

	DVI_ENABLE = TRUE;
	DVI_INT	= FALSE;

	PIXEL_ENABLE  = FALSE;
	PIXEL_READ	= FALSE;

	DMA_RD_ENABLE = FALSE;

end

////////////////////////////////////////////////////////////////////////
// DVI encoder

ZX_Spectrum_DVI dvi(

	.CLK_PIXEL(	 CLK_28),						// 28MHz DVI pixel clock
	.CLK_SERIAL( CLK_140),						// 140MHz DVI serial bit shift

	.RESET(		 1'b1),							// RESET (active low)

	.DVI_HSYNC(	 DVI_HSYNC),					// Horizontal and
	.DVI_VSYNC(	 DVI_VSYNC),					// Vertical sync
	.DVI_ENABLE( DVI_ENABLE),					// Data enable (displaying pixels)

	.DVI_RED(	 DVI_RED),						// DVI_RED component byte
	.DVI_GREEN(	 DVI_GREEN),					// DVI_GREEN component byte
	.DVI_BLUE(	 DVI_BLUE),						// DVI_BLUE component byte

	.TMDS_CLK_P( TMDSp_clock),					// TMDS +ve clock out
	.TMDS_CLK_N( TMDSn_clock),					// TMDS -ve clock out
	.TMDS_DATA_P(TMDSp),						// TMDS +ve data out (serialized)
	.TMDS_DATA_N(TMDSn)							// TMDS -ve data out (serialized)
);

////////////////////////////////////////////////////////////////////////
// Spectrum pixel component colours

ZX_Spectrum_PAL pal(

	.COLOUR_INDEX(COLOUR_INDEX),
	.RED(		  DVI_RED),
	.GREEN(		  DVI_GREEN),
	.BLUE(		  DVI_BLUE)
);

////////////////////////////////////////////////////////////////////////
// Generate DVI raster

always @(posedge CLK_28) begin

	DVI_X	  <= DVI_X < DVI_WIDTH ? DVI_X + 10'd1 : 10'd0;								// Column/Row counters

	if (DVI_X == DVI_WIDTH) begin 

		DVI_Y <= DVI_Y < DVI_HEIGHT ? DVI_Y + 10'd1 : 10'd0;

	end

	DVI_INT			<=  (DVI_Y == 0 && DVI_X < INT_X_END);

	DVI_ENABLE		<=  (DVI_X < DISPLAY_WIDTH)	&& (DVI_Y < DISPLAY_HEIGHT);			// Set DVI_ENABLE when counters within visible region

	DVI_HSYNC		<=  (DVI_X > DVI_HSYNC_START) && (DVI_X < DVI_HSYNC_END);			// Period where horizontal sync is active

	DVI_VSYNC		<=  (DVI_Y > DVI_VSYNC_START) && (DVI_Y < DVI_VSYNC_END);			// and vertical sync

	PIXEL_ENABLE	<=  (DVI_Y >= SPEC_VSTART && DVI_Y < SPEC_VEND) &&					// Flag for output pixels / border colour
						(DVI_X >= SPEC_HSTART && DVI_X < SPEC_HEND);

	PIXEL_READ		<=  (DVI_Y >= SPEC_VSTART && DVI_Y < SPEC_VEND) &&					// Flag to begin pixel read from buffer - 1 pixel before output enable
						(DVI_X >= SPEC_HSTART - 2 && DVI_X < SPEC_HEND - 2);

	DMA_RD_ENABLE	<=  (DVI_Y >= SPEC_DSTART && DVI_Y < SPEC_DEND) &&					// DMA active 1 SPECTRUM pixel row before display output
						(DVI_X >= SPEC_HSTART && DVI_X < SPEC_HEND);

end

////////////////////////////////////////////////////////////////////////
// Flash delay counter, uses 50Hz interrupt signal as clock

reg [4:0]FRAMES;																		// Count frames for flash period. Bit 4 = flash state

initial begin

	FRAMES = 0;

end

always @ (posedge DVI_INT) begin

	FRAMES <= FRAMES + 5'd1;

end

////////////////////////////////////////////////////////////////////////
// SPECTRUM video processing

reg  [7:0]PIX_BUF[0:63];														// 2 x Pixel and ATTibute buffers
reg  [7:0]ATT_BUF[0:63];
reg  [7:0]PIX;
reg  [7:0]ATT;

reg  [7:0]PIXELS;																// Count the 256 pixels in each row

initial begin

	PIXELS = 0;

end

////////////////////////////////////////////////////////////////////////
// Generate the pixel and border areas from the contents of the buffers

always @ (posedge CLK_14) begin

	if (PIXEL_READ) begin

		PIXELS <= PIXELS + 8'd1;												// Count the 256 pixels of each row

		if (PIXELS[2:0] == 0) begin												// Every 8 pixels pick up new bytes from the buffer

			ATT <= ATT_BUF[ { ~BYTES[8], PIXELS[7:3] } ];						// ~BYTES[8] is the select for the 2 buffers. The one NOT being used to fill from RAM
			PIX <= PIX_BUF[ { ~BYTES[8], PIXELS[7:3] } ];						// Blocking to ensure PIX is set before encoding the colour index

		end
		else begin

			PIX <= PIX << 1;													// Again blocking to ensure PIX is correct

		end
	end

	if (PIXEL_ENABLE)															// Calculate the colour index from Attribute/pixel on/off
		COLOUR_INDEX <= { ATT[6], (PIX[7] ^ (ATT[7] & FRAMES[4])) ? ATT[2:0] : ATT[5:3] };
	else
		COLOUR_INDEX <= IO_PORT_ULA[2:0];										// Border colour from IO port reg

end

////////////////////////////////////////////////////////////////////////
// Read video RAM and fill buffer

reg [15:0]BYTES;																// This counts through 8K video ram + low bit state

// Bits: 15:4, 2 - 12 bit index in memory (0-8191)
// 		 3 		 - 1 = Memory is being accessed. Used for contention compatibility
//		 2:0	 - 0 = Set DMA address for even pixel byte
//				 - 1 = Read pixel
//				 - 2 = Set DMA address for even attribute byte
//				 - 3 = Read attribute
//				 - 4 = Set DMA address for odd pixel byte
//				 - 5 = Read pixel
//				 - 6 = Set DMA address for odd attribute byte
//				 - 7 = Read attribute

initial begin

	BYTES = 0;

end

always @ (posedge CLK_7) begin

	if (RESET) begin
		IO_PORT_ULA <= 8'd0;
		IO_PORT_MEM <= 8'b00010000;												// Page in SD ROM and unlock
	end

	if (~(CPU_IORQ | CPU_WR)) begin												// IO Port write

		if (  ~CPU_ADDRESS[IO_PORT1])					IO_PORT_ULA <= CPU_WR_DATA;		// Standard spectrum IO					
		if ( ~(CPU_ADDRESS[IO_PORT2] | IO_PORT_MEM[5])) IO_PORT_MEM <= CPU_WR_DATA;		// 128K Memory paging register

	end

	if (DMA_RD_ENABLE) begin

		BYTES <= BYTES + 16'd1;

		if (BYTES[3]) begin														// NB CPU clock inhibit bit 3
		
			case(BYTES[1:0])
				'b00: begin														// Address for pixel

					DMA_ADDRESS <= { 3'b010, BYTES[15:14], BYTES[10:8], BYTES[13:11], BYTES[7:4], BYTES[2] };

				end
				'b01: begin														// Read pixels byte

					PIX_BUF[ { BYTES[8], BYTES[7:4], BYTES[2] } ] <= DMA_DATA_IN;

				end
				'b10: begin														// Address for Attribute

					DMA_ADDRESS <= { 6'b010110, BYTES[15:11], BYTES[7:4], BYTES[2] };

				end
				'b11: begin														// Read Attribute byte

					ATT_BUF[ { BYTES[8], BYTES[7:4], BYTES[2] } ] <= DMA_DATA_IN;

				end
			endcase

		end

	end else begin

		if (DVI_INT) BYTES <= 0;									 			// Reset byte count at start of frame
	
	end

end

assign CPU_RD_DATA = ~(CPU_IORQ | CPU_RD | CPU_ADDRESS[IO_PORT1]) ? { 1'b1, IO_IN[5], 1'b1, IO_IN[4:0] & ~USB_IO(CPU_ADDRESS[15:8]) } : 8'bz;

assign CPU_RD_DATA = ~(CPU_IORQ | CPU_RD | CPU_ADDRESS[IO_PORT2]) ? IO_PORT_MEM : 8'bz;

assign IO_OUT		= IO_PORT_ULA[4:3];												// Audio output bits

assign CPU_WAIT		= ~BYTES[3] | CPU_MREQ | CPU_ADDRESS[15] | ~CPU_ADDRESS[14]; 	// Mimic memory contention using WAIT

assign CPU_INT		= ~DVI_INT;														// CPU Interrupt is active low

////////////////////////////////////////////////////////////////////////
// USB

typedef struct packed {
	reg	[ 0: 7][ 4: 0]BIT;
} KB_TYPE;

KB_TYPE KBIT;

reg KCAP;
reg KSYM;
reg [39: 0] KBD_DATA [ 0:255];

initial begin

	KBIT = 40'b0;
	KCAP = 1'b0;
	KSYM = 1'b0;

	$readmemb("usb_kb_lookup.bin", KBD_DATA);

end

function automatic [ 4: 0] USB_IO(
	input [ 7: 0] port
);
	reg [4:0]v = 0;

	if (!port[0]) v = v | { KBIT.BIT[0][4:1], KBIT.BIT[0][0] | (KCAP & (KBIT == 0)) };
	if (!port[1]) v = v | 	KBIT.BIT[1];
	if (!port[2]) v = v | 	KBIT.BIT[2];
	if (!port[3]) v = v | 	KBIT.BIT[3];
	if (!port[4]) v = v | 	KBIT.BIT[4];
	if (!port[5]) v = v | 	KBIT.BIT[5];
	if (!port[6]) v = v | 	KBIT.BIT[6];
	if (!port[7]) v = v | { KBIT.BIT[7][4:2], KBIT.BIT[7][1] | KSYM, KBIT.BIT[7][0] };

	return v;

endfunction

wire CLK_12;																		// USB clock

ZX_Spectrum_USB_CLK uclk (
	.clkin(		SYS_CLK),
	.clkout0(	CLK_12)
);

reg [ 1: 0] USB0_TYP;
reg			USB0_REPORT;
reg			USB0_ERR;

reg [ 7: 0] USB0_KMOD;
reg [ 7: 0] USB0_KEY[0:3];

reg [15: 0] USB0_GAME;

ZX_Spectrum_USB usb0 (

	.USB_CLK(		CLK_12),
	.USB_DP(		USB0_DP),
	.USB_DN(		USB0_DN),

	.USB_TYP(		USB0_TYP),
	.USB_ERR(		USB0_ERR),
	.USB_REPORT(	USB0_REPORT),
	.USB_KMOD(	  	USB0_KMOD),
	.USB_KEY(		USB0_KEY),
	.USB_GAME(	  	USB0_GAME)
);

reg [ 1: 0] USB1_TYP;
reg		 USB1_REPORT;
reg		 USB1_ERR;

reg [ 7: 0] USB1_KMOD;
reg [ 7: 0] USB1_KEY[0:3];

reg [15: 0] USB1_GAME;

ZX_Spectrum_USB usb1 (

	.USB_CLK(		CLK_12),
	.USB_DP(		USB1_DP),
	.USB_DN(		USB1_DN),

	.USB_TYP(		USB1_TYP),
	.USB_ERR(		USB1_ERR),
	.USB_REPORT(	USB1_REPORT),
	.USB_KMOD(	 	USB1_KMOD),
	.USB_KEY(		USB1_KEY),
	.USB_GAME(		USB1_GAME)
);

assign LED = USB1_TYP;

assign KCAP =	USB1_KMOD & 8'h22 ? 1'b1 : 1'b0;
assign KSYM =	USB1_KMOD & 8'h11 ? 1'b1 : 1'b0;
assign KBIT =	KBD_DATA[ { KCAP, USB1_KEY[0][6:0] }] |
				KBD_DATA[ { KCAP, USB1_KEY[1][6:0] }] |
				KBD_DATA[ { KCAP, USB1_KEY[2][6:0] }] |
				KBD_DATA[ { KCAP, USB1_KEY[3][6:0] }];

assign CPU_RD_DATA = CPU_ADDRESS[7:0] == 8'd31 && ~(CPU_IORQ | CPU_RD) ? USB1_KMOD : 8'bz;

assign RESET = USB1_KMOD[1] & USB1_KMOD[2] & USB1_KMOD[6];

endmodule
