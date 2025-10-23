
////////////////////////////////////////////////////////////////////////

module top(

	input CLKIN_28,								// 28MHz master clock 
	input BTN1,									// Reset button active low

	output led
);

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

reg [31:0]cnt;
reg ld;

initial begin
	cnt = 0;
	ld = 0;
end

// Flash LED once a second for 28MHz

// always @(posedge CLK_28) begin

// 	if (cnt == 32'd28_000_000) begin
// 		cnt <= 0;
// 		ld <= ~ld;
// 	end else begin
// 		cnt <= cnt + 1;
// 	end

// end

// Flash LED once a second for 140MHz

//always @(posedge CLK_140) begin

//	if (cnt == 32'd140_000_000) begin
//		cnt <= 0;
//		ld <= ~ld;
//	end else begin
//		cnt <= cnt + 1;
//	end

//end

// Flash LED once a second for 14MHz

//always @(posedge CLK_14) begin

//	if (cnt == 32'd14_000_000) begin
//		cnt <= 0;
//		ld <= ~ld;
//	end else begin
//		cnt <= cnt + 1;
//	end

//end

// Flash LED once a second for 7MHz

always @(posedge CLK_7) begin

	if (cnt == 32'd7_000_000) begin
		cnt <= 0;
		ld <= ~ld;
	end else begin
		cnt <= cnt + 1;
	end

end











assign led = ld;

endmodule