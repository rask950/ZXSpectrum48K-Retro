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

USB_HID_HOST ZUSB (

	.USB_CLK(		USB_CLK),					// 12MHz clock
	.USB_Dm(		USB_DN),
	.USB_Dp(		USB_DP),					// USB D- and D+
    .RESET(         sys_resetn),

	.DEV_TYPE(		USB_TYP),					// device type. 0: no device, 1: keyboard, 2: mouse, 3: gamepad
												// key_*, mouse_*, game_* valid depending on typ
	.REP_PULSE(		USB_REPORT),				// pulse after report received from device. 
	.CON_ERROR(		USB_ERR),					// connection or protocol error

	// keyboard
	.KEY_MOD(   	USB_KMOD),
	.KEY_1(			USB_KEY[0]),
	.KEY_2(			USB_KEY[1]),
	.KEY_3(			USB_KEY[2]),
	.KEY_4(			USB_KEY[3]),

	// mouse
	.MOUSE_BTN(		USB_MBTN),					// {5'bx, middle, right, left}
	.MOUSE_DX(		USB_MDX),					// signed 8-bit, cleared after `report` pulse
	.MOUSE_DY(		USB_MDY),					// signed 8-bit, cleared after `report` pulse

	// gamepad 
	.GAME_LEFT(		USB_GAME[0]),				// Direction 
	.GAME_RIGHT(	USB_GAME[1]),
	.GAME_UP(		USB_GAME[2]),
	.GAME_DOWN(		USB_GAME[3]),
	.GAME_A(		USB_GAME[4]),				// Buttons
	.GAME_B(		USB_GAME[5]),
	.GAME_X(		USB_GAME[6]), 
	.GAME_Y(		USB_GAME[7]), 
	.GAME_SEL(		USB_GAME[8]), 
	.GAME_START(	USB_GAME[9]),

	// debug
	.DBG_HID_REPORT(USB_DBG)					// last HID report
);


endmodule