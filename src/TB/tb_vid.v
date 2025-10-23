
////////////////////////////////////////////////////////////////////////

module top(

	input CLKIN_28,								// 28MHz clock
	input BTN1,									// Reset button

	output [2:0]TMDSp,							// HDMI output
	output [2:0]TMDSn,
	output TMDSp_clock,
 	output TMDSn_clock,

	output led
);

localparam TRUE             = 1'b1;
localparam FALSE            = 1'b0;

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

wire CLK_28;
wire CLK_140;
wire CLK_14;
wire CLK_7;

ZX_Spectrum_CLK zclk(
    .reset(~BTN1),
	.clkin(CLKIN_28),
	.clkout0(CLK_28),                           // DVI pixel clock 28MHz
	.clkout1(CLK_140),                          // DVI serial clock 140MHZ (28 * 5)
	.clkout2(CLK_14),                           // Memory clock 14MHz
	.clkout3(CLK_7)                             // TV pixel/CPU clock 7MHz
);

////////////////////////////////////////////////////////////////////////
// Flash LED once a second for 28MHz

reg [31:0]cnt;
reg ld;

initial begin
    cnt = 0;
    ld = 0;
end

always @(posedge CLK_28) begin

	if (cnt == 32'd28_000_000) begin
		cnt <= 0;
		ld <= ~ld;
	end else begin
		cnt <= cnt + 1;
	end

end

assign led = FRAMES[4];

////////////////////////////////////////////////////////////////////////

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
reg	DMA_RD_ENABLE;

initial begin

	DVI_X = 0;
	DVI_Y = 0;

	DVI_HSYNC  = FALSE;
	DVI_VSYNC  = FALSE;

	DVI_ENABLE = TRUE;

    DVI_RED = 8'd20;
    DVI_GREEN = 8'd20;
    DVI_BLUE = 8'd20;

	PIXEL_ENABLE = FALSE;
	PIXEL_READ = FALSE;
	DMA_RD_ENABLE = FALSE;

end

////////////////////////////////////////////////////////////////////////
// Generate DVI raster

always @(posedge CLK_28) begin

	DVI_X	  <= DVI_X < DVI_WIDTH ? DVI_X + 10'd1 : 10'd0;								// Column/Row counters

	if (DVI_X == DVI_WIDTH) begin 

		DVI_Y <= DVI_Y < DVI_HEIGHT ? DVI_Y + 10'd1 : 10'd0;

	end

	DVI_INT		   <= (DVI_Y == 0 && DVI_X < INT_X_END);

	DVI_ENABLE     <= (DVI_X < DISPLAY_WIDTH)	&& (DVI_Y < DISPLAY_HEIGHT);	// Set DVI_ENABLE when counters within visible region

	DVI_HSYNC	   <= (DVI_X > DVI_HSYNC_START) && (DVI_X < DVI_HSYNC_END);		// Period where horizontal sync is active

	DVI_VSYNC	   <= (DVI_Y > DVI_VSYNC_START) && (DVI_Y < DVI_VSYNC_END);		// and vertical sync

	PIXEL_ENABLE   <= (DVI_Y >= SPEC_VSTART && DVI_Y < SPEC_VEND) &&			// Flag for output pixels / border colour
					  (DVI_X >= SPEC_HSTART && DVI_X < SPEC_HEND);

	PIXEL_READ     <= (DVI_Y >= SPEC_VSTART && DVI_Y < SPEC_VEND) &&			// Flag to begin pixel read from buffer - 1 pixel before output enable
					  (DVI_X >= SPEC_HSTART - 2 && DVI_X < SPEC_HEND - 2);

	DMA_RD_ENABLE <= (DVI_Y >= SPEC_DSTART && DVI_Y < SPEC_DEND) &&				// DMA active 1 SPECTRUM pixel row before display output
					 (DVI_X >= SPEC_HSTART && DVI_X < SPEC_HEND);

end

////////////////////////////////////////////////////////////////////////
// Flash delay counter, uses 50Hz interrupt signal as clock

reg [4:0]FRAMES;																// Count frames for flash period. Bit 4 = flash state

initial begin

	FRAMES = 0;

end

always @ (posedge DVI_INT) begin

	FRAMES <= FRAMES + 1;

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

		PIXELS <= PIXELS + 1;													// Count the 256 pixels of each row

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
		COLOUR_INDEX <= 4'd1;													// Border colour

end

////////////////////////////////////////////////////////////////////////
// Read video RAM and fill buffer

reg [15:0]BYTES;																// This counts through 8K video ram + low bit state

// Bits: 15:4, 2 - Byte index in memory
// 		 3 		 - This is 1 when memory is being accessed, 0 otherwise. Used for contention compatibility
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

reg [15:0]DMA_ADDRESS;
wire [ 7:0]DMA_DATA_IN;

always @ (posedge CLK_7) begin

	if (DMA_RD_ENABLE) begin

		BYTES <= BYTES + 1;

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

ZX_Spectrum_PAL zpal(
	.COLOUR_INDEX(COLOUR_INDEX),
	.RED(DVI_RED),
	.GREEN(DVI_GREEN),
	.BLUE(DVI_BLUE)
);

ZX_Spectrum_DVI zdvi(
    .RESET(1'b1),
    .CLK_PIXEL(CLK_28),
    .CLK_SERIAL(CLK_140),
    .DVI_VSYNC(DVI_VSYNC),
    .DVI_HSYNC(DVI_HSYNC),
    .DVI_ENABLE(DVI_ENABLE),
    .DVI_RED(DVI_RED),
    .DVI_GREEN(DVI_GREEN),
    .DVI_BLUE(DVI_BLUE),
    .TMDS_CLK_P(TMDSp_clock),
    .TMDS_CLK_N(TMDSn_clock),
    .TMDS_DATA_P(TMDSp),
    .TMDS_DATA_N(TMDSn)
);

ZX_Spectrum_MEM zmem(
    
	.CLK(CLK_14),
    .RESET(1'b0),

	.PAGING(8'd0),

    .ULA_RD_DATA(DMA_DATA_IN),
    .ULA_ADDRESS(DMA_ADDRESS),
    .ULA_RD(DMA_RD_ENABLE)
);

endmodule
