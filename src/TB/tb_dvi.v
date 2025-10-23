
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

assign led = ld;

////////////////////////////////////////////////////////////////////////


reg [7:0]DVI_RED;								// RGB values for current pixel
reg [7:0]DVI_GREEN;
reg [7:0]DVI_BLUE;

reg [9:0]DVI_X;									// Horizontal and vertical counters
reg [9:0]DVI_Y;

reg DVI_HSYNC;									// Horizontal and vertical sync signals
reg DVI_VSYNC;

reg DVI_ENABLE;									// Flag indicating the visible display is being output at DVI

initial begin

	DVI_X = 0;
	DVI_Y = 0;

	DVI_HSYNC  = FALSE;
	DVI_VSYNC  = FALSE;

	DVI_ENABLE = TRUE;

    DVI_RED = 8'd20;
    DVI_GREEN = 8'd20;
    DVI_BLUE = 8'd20;

end

////////////////////////////////////////////////////////////////////////
// Generate DVI raster

always @(posedge CLK_28) begin

	DVI_X	  <= DVI_X < DVI_WIDTH ? DVI_X + 10'd1 : 10'd0;								// Column/Row counters

	if (DVI_X == DVI_WIDTH) begin 

		DVI_Y <= DVI_Y < DVI_HEIGHT ? DVI_Y + 10'd1 : 10'd0;

	end

	DVI_ENABLE     <= (DVI_X < DISPLAY_WIDTH)	&& (DVI_Y < DISPLAY_HEIGHT);	// Set DVI_ENABLE when counters within visible region

	DVI_HSYNC	   <= (DVI_X > DVI_HSYNC_START) && (DVI_X < DVI_HSYNC_END);		// Period where horizontal sync is active

	DVI_VSYNC	   <= (DVI_Y > DVI_VSYNC_START) && (DVI_Y < DVI_VSYNC_END);		// and vertical sync

end

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


endmodule
