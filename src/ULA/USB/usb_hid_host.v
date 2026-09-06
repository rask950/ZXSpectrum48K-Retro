`timescale 1ns/1ps

module USB_HID_HOST (
	
	input				USB_CLK,					// 12MHz clock
	input				RESET,						// reset
	inout				USB_Dm,
	inout				USB_Dp,						// USB D- and D+

	output reg	[ 1: 0] DEV_TYPE,					// device type. 0: no device, 1: keyboard, 2: mouse, 3: gamepad
	output reg			REP_PULSE,					// pulse after report received from device. 
											
	output 				CON_ERROR,					// connection or protocol error

	// keyboard
	output reg	[ 7: 0] KEY_MOD,
	output reg	[ 7: 0] KEY_1,
	output reg	[ 7: 0] KEY_2,
	output reg	[ 7: 0] KEY_3,
	output reg	[ 7: 0] KEY_4,

	// mouse
	output reg	[ 7: 0] MOUSE_BTN,					// {5'bx, middle, right, left}
	output reg  [ 7: 0] MOUSE_DX,					// signed 8-bit, cleared after `report` pulse
	output reg 	[ 7: 0] MOUSE_DY,					// signed 8-bit, cleared after `report` pulse

	// gamepad 
	output reg			GAME_LEFT,
	output reg			GAME_RIGHT,
	output reg			GAME_UP,
	output reg			GAME_DOWN,

	output reg			GAME_A,
	output reg			GAME_B,
	output reg			GAME_X,
	output reg			GAME_Y,
	output reg			GAME_SEL,
	output reg			GAME_START,

	// debug
	output		[63: 0]	DBG_HID_REPORT				// last HID report
);

	wire 				DATA_READY;					// data ready
	wire 				DATA_STROBE;				// data strobe for each byte

	wire 		[ 7: 0] UK_PAT;						// actual data
	reg			[ 7: 0] REGS [7];					// 0 (VID_L), 1 (VID_H), 2 (PID_L), 3 (PID_H), 4 (INTERFACE_CLASS), 5 (INTERFACE_SUBCLASS), 6 (INTERFACE_PROTOCOL)

	wire				SAVE;						// save dat[b] to output register r
	wire		[ 3: 0] SAVE_R;						// which register to save to
	wire		[ 3: 0] SAVE_B;						// dat[b]
	wire				CONNECTED;

ukp ukp(
	.RESET(				RESET),
	.USB_CLK(			USB_CLK),
	
	.USB_Dp(			USB_Dp),
	.USB_Dm(			USB_Dm),
	
	.USB_OE(),

	.DATA_READY(		DATA_READY),
	.DATA_STROBE(		DATA_STROBE),
	.DATA_OUT(			UK_PAT),

	.SAVE(				SAVE),
	.SAVE_R(			SAVE_R),
	.SAVE_B(			SAVE_B),

	.CONNECTED(			CONNECTED),
	.CON_ERROR(			CON_ERROR)
);

	reg			[ 3: 0] REC_COUNT;						// counter for recv data
	reg					DATA_STROBE_R;					// delayed data_strobe and data_ready
	reg					DATA_READY_R;
	reg			[ 7: 0] RSP_DATA[8];					// data in last response

	assign DBG_HID_REPORT = { RSP_DATA[7], RSP_DATA[6], RSP_DATA[5], RSP_DATA[4], RSP_DATA[3], RSP_DATA[2], RSP_DATA[1], RSP_DATA[0] };
	
	// assign dbg_regs = regs;

	// Gamepad types, see response_recognition below
	// localparam D_GENERIC = 0;
	// localparam D_GAMEPAD = 1;			
	// localparam D_DS2_ADAPTER = 2;
	// reg [3:0] dev = D_GENERIC;								// device type recognized through VID/PID
	// assign dbg_dev = dev;

	reg					REP_VALID = 0;							// whether current gamepad report is valid

	always @(posedge USB_CLK) begin : process_in_data
	
		DATA_READY_R	<= DATA_READY;
		DATA_STROBE_R	<= DATA_STROBE;
		REP_PULSE		<= 0;									// ensure pulse
		
		if (REP_PULSE == 1) begin
			MOUSE_DX <= 0;										// clear mouse movement for later
			MOUSE_DY <= 0;
		end

		if(~DATA_READY) begin
			
			REC_COUNT <= 0;
		
		end else begin
		
			if(DATA_STROBE && ~DATA_STROBE_R) begin				// rising edge of ukp data strobe

				RSP_DATA[REC_COUNT] <= UK_PAT;

				if (DEV_TYPE == 1) begin	 					// HID protocol - keyboard

					case (REC_COUNT)
						0: KEY_MOD	<= UK_PAT;					// 1st byte modifier keys (Ctrl, Shift, Alt, GUI)
																// 2nd byte reserved (usually 0)
						2: KEY_1	<= UK_PAT;					// 3rd byte key code
						3: KEY_2	<= UK_PAT;					// 4th byte key code
						4: KEY_3	<= UK_PAT;					// 5th byte key code
						5: KEY_4	<= UK_PAT;					// 6th byte key code
					endcase

				end else if (DEV_TYPE == 2) begin				// HID protocal - mouse
	
					case (REC_COUNT)
						0: MOUSE_BTN <= UK_PAT;					// 1st byte mouse buttons
						1: MOUSE_DX	 <= UK_PAT;					// 2nd byte mouse X movement
						2: MOUSE_DY	 <= UK_PAT;					// 3rd byte mouse Y movement
					endcase
	
				end else if (DEV_TYPE == 3) begin				// HID protocol - gamepad

					// A typical report layout:
					// - d[3] is X axis (0: left, 255: right)
					// - d[4] is Y axis
					// - d[5][7:4] is buttons YBAX
					// - d[6][5:4] is buttons START,SELECT
					// Variations:
					// - Some gamepads uses d[0] and d[1] for X and Y axis.
					// - Some transmits a different set when d[0][1:0] is 2 (a dualshock adapater)
				
					case (REC_COUNT)

						0: begin
							if (UK_PAT[1:0] != 2'b10) begin						// for DualShock2 adapter, 2'b10 marks an irrelevant record
								REP_VALID	<= 1;
								GAME_LEFT	<= 0; 
								GAME_RIGHT	<= 0; 
								GAME_UP		<= 0; 
								GAME_DOWN	<= 0;
							end else begin
								REP_VALID	<= 0;
							end

							if (UK_PAT==8'h00) { GAME_LEFT, GAME_RIGHT } <= 2'b10;
							if (UK_PAT==8'hff) { GAME_LEFT, GAME_RIGHT } <= 2'b01;
						end

						1: begin
							if (UK_PAT==8'h00) { GAME_UP, GAME_DOWN } <= 2'b10;
							if (UK_PAT==8'hff) { GAME_UP, GAME_DOWN } <= 2'b01;
						end

						3: if (REP_VALID) begin 
							if (UK_PAT[7:6]==2'b00) { GAME_LEFT, GAME_RIGHT } <= 2'b10;
							if (UK_PAT[7:6]==2'b11) { GAME_LEFT, GAME_RIGHT } <= 2'b01;
						end

						4: if (REP_VALID) begin 
							if (UK_PAT[7:6]==2'b00) { GAME_UP, GAME_DOWN } <= 2'b10;
							if (UK_PAT[7:6]==2'b11) { GAME_UP, GAME_DOWN } <= 2'b01;
						end

						5: if (REP_VALID) begin
							GAME_X <= UK_PAT[4];
							GAME_A <= UK_PAT[5];
							GAME_B <= UK_PAT[6];
							GAME_Y <= UK_PAT[7];
						end

						6: if (REP_VALID) begin
							GAME_SEL	<= UK_PAT[4];
							GAME_START	<= UK_PAT[5];
						end

					endcase

				end

				REC_COUNT <= REC_COUNT + 1;

			end
		end

		// falling edge of ukp data ready
	
		if( ~DATA_READY && DATA_READY_R && DEV_TYPE != 0) REP_PULSE <= 1;

	end

	reg	SAVE_DELAYED;
	reg	CONNECTED_R;

	always @(posedge USB_CLK) begin : response_recognition

		SAVE_DELAYED <= SAVE;
	
		if (SAVE) begin
	
			REGS[SAVE_R] <= RSP_DATA[SAVE_B];
	
		end else if (SAVE_DELAYED && ~SAVE && SAVE_R == 6) begin

			// falling edge of save for bInterfaceProtocol

			if (REGS[4] == 3) begin  											// bInterfaceClass.		3: HID, other: non-HID
				if (REGS[5] == 1)												// bInterfaceSubClass.	1: Boot device
					DEV_TYPE <= REGS[6] == 1 ? 1 : 2;							// bInterfaceProtocol.	1: keyboard, 2: mouse
				else
					DEV_TYPE <= 3;												// gamepad
			end else
				DEV_TYPE <= 0;
		end

		CONNECTED_R <= CONNECTED;

		if (~CONNECTED & CONNECTED_R) DEV_TYPE <= 0;							// clear device type on disconnect
	end

endmodule
