module USB_HID_HOST_ROM(

    input					CLK,
    input 			[13: 0] ADDRESS,
    output reg		[ 3: 0] DATA
);
    reg 			[ 3: 0] MEMORY [0:535];

    initial $readmemh("usb_hid_host_rom.hex", MEMORY);

    always @(posedge CLK) DATA <= MEMORY[ADDRESS];

endmodule
