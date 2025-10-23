module ZX_Spectrum_USB(

	input 		USB_CLK,
	inout		USB_DP,
	inout		USB_DN,
	
	output reg [1:0]USB_TYP,
	output reg USB_ERR,
	output reg USB_REPORT,
	
	output reg [7:0]USB_KMOD,
	output reg [7:0]USB_KEY[0:3],

    output reg [15:0]USB_GAME
);

wire [7:0]USB_MBTN;
wire [7:0]USB_MDX;
wire [7:0]USB_MDY;
wire [63:0]USB_DBG;

reg sys_resetn = 0;

    always @(posedge USB_CLK) begin
    sys_resetn <= 1;
end

assign USB_GAME[15:10] = 6'b0;

usb_hid_host ZUSB (

	.usbclk(		USB_CLK),					// 12MHz clock
	.usb_dm(		USB_DN),
	.usb_dp(		USB_DP),					// USB D- and D+
    .usbrst_n(      sys_resetn),

	.typ(			USB_TYP),					// device type. 0: no device, 1: keyboard, 2: mouse, 3: gamepad
												// key_*, mouse_*, game_* valid depending on typ
	.report(		USB_REPORT),				// pulse after report received from device. 
	.conerr(		USB_ERR),					// connection or protocol error

	// keyboard
	.key_modifiers(	USB_KMOD),
	.key1(			USB_KEY[0]),
	.key2(			USB_KEY[1]),
	.key3(			USB_KEY[2]),
	.key4(			USB_KEY[3]),

	// mouse
	.mouse_btn(		USB_MBTN),					// {5'bx, middle, right, left}
	.mouse_dx(		USB_MDX),					// signed 8-bit, cleared after `report` pulse
	.mouse_dy(		USB_MDY),					// signed 8-bit, cleared after `report` pulse

	// gamepad 
	.game_l(		USB_GAME[0]), 
	.game_r(		USB_GAME[1]),
	.game_u(		USB_GAME[2]),
	.game_d(		USB_GAME[3]),				// left right up down
	.game_a(		USB_GAME[4]),
	.game_b(		USB_GAME[5]),
	.game_x(		USB_GAME[6]), 
	.game_y(		USB_GAME[7]), 
	.game_sel(		USB_GAME[8]), 
	.game_sta(		USB_GAME[9]),			    // buttons

	// debug
	.dbg_hid_report(USB_DBG)	// last HID report
);


endmodule