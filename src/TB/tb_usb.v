//
// Example for using the usb_hid_host core
// nand2mario, 8/2023
//

module usb_hid_host_demo (
    input sys_clk,

    // LEDs
    output [1:0] led,

    // USB
    inout usbdm,
    inout usbdp

);

reg sys_resetn = 0;

    always @(posedge clk) begin
    sys_resetn <= 1;
end

//reg flg = 0;
//reg [31:0]cnt = 0;

//always @(posedge clk_usb) begin

//    if (cnt == 12_000_000) begin
//        cnt <= 0;
//        flg <= ~flg;
//    end else begin
//        cnt <= cnt + 1;
//    end
//end

//assign led[0] = flg;

wire clk = sys_clk;
wire clk_sdram = ~sys_clk;  
wire clk_usb;

// USB clock 12Mhz
gowin_pll_usb pll_usb (
    .clkin(sys_clk),
    .clkout0(clk_usb),       // 12Mhz usb clock
    .reset(1'b0)
);


//ZX_Spectrum_CLK zclk(
//	.clkin(sys_clk),							// Input clock 28MHz
//	.reset(1'b0),
//	.clkout0(clk_usb),					 		// Output clk 12MHz
//	.clkout1(CLK_28),					 		// Output clk 28MHz 
//	.clkout2(CLK_140),					 		// Output clk 140MHz
//	.clkout3(CLK_14),							// Output clk 14MHz
//	.clkout4(CLK_7)						 		// Output clk 7MHz
//);

wire [1:0] usb_type;
wire [7:0] key_modifiers, key1, key2, key3, key4;
wire [7:0] mouse_btn;
wire signed [7:0] mouse_dx, mouse_dy;
wire [63:0] hid_report;
wire [7:0] hid_regs [7];

usb_hid_host usb (
    .usbclk(clk_usb), .usbrst_n(sys_resetn),
    .usb_dm(usbdm), .usb_dp(usbdp),	
    .typ(usb_type), .report(usb_report),
    .key_modifiers(key_modifiers), .key1(key1), .key2(key2), .key3(key3), .key4(key4),
    .mouse_btn(mouse_btn), .mouse_dx(mouse_dx), .mouse_dy(mouse_dy),
    .game_l(game_l), .game_r(game_r), .game_u(game_u), .game_d(game_d),
    .game_a(game_a), .game_b(game_b), .game_x(game_x), .game_y(game_y), 
    .game_sel(game_sel), .game_sta(game_sta),
    .conerr(usb_conerr), .dbg_hid_report(hid_report)
);

//hid_printer prt (
//    .clk(clk_usb), .resetn(sys_resetn),
//    .uart_tx(UART_TXD), .usb_type(usb_type), .usb_report(usb_report),
//    .key_modifiers(key_modifiers), .key1(key1), .key2(key2), .key3(key3), .key4(key4),
//    .mouse_btn(mouse_btn), .mouse_dx(mouse_dx), .mouse_dy(mouse_dy),
//    .game_l(game_l), .game_r(game_r), .game_u(game_u), .game_d(game_d),
//    .game_a(game_a), .game_b(game_b), .game_x(game_x), .game_y(game_y), 
//    .game_sel(game_sel), .game_sta(game_sta)
//);

reg report_toggle;      // blinks whenever there's a report
always @(posedge clk_usb) if (usb_report) report_toggle <= ~report_toggle;

assign led = { usbdm, usbdp }; // usb_type;      // ~{usb_conerr, report_toggle};

endmodule