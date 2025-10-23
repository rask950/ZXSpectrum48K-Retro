
////////////////////////////////////////////////////////////////////////
// Convert Spectrum colour index to RGB values

module ZX_Spectrum_PAL(
    input  reg [3:0]COLOUR_INDEX,                   // 2:0 = colour index (0-7), 3 = bright flag
    output reg [7:0]RED,
    output reg [7:0]GREEN,
    output reg [7:0]BLUE
);

localparam NORMAL_INTENSITY = 192;
localparam BRIGHT_INTENSITY = 255;

assign BLUE  = (COLOUR_INDEX[0] ? (COLOUR_INDEX[3] ? BRIGHT_INTENSITY : NORMAL_INTENSITY ) : 0);
assign RED   = (COLOUR_INDEX[1] ? (COLOUR_INDEX[3] ? BRIGHT_INTENSITY : NORMAL_INTENSITY ) : 0);
assign GREEN = (COLOUR_INDEX[2] ? (COLOUR_INDEX[3] ? BRIGHT_INTENSITY : NORMAL_INTENSITY ) : 0);

endmodule
