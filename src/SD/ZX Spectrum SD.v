module ZX_Spectrum_SD (
	input			CLK_28,
	input			RESET,
	
	inout			[ 7: 0]	CPU_DATA_BUS,								// CPU Buses
	input			[15: 0] CPU_ADDRESS,
	input					CPU_IORQ,
	input					CPU_RD,
	input					CPU_WR,

	output reg 		[ 7: 0]	DMA_WR_DATA,								// SD DMA
	output			[15: 0]	DMA_ADDRESS,
	output reg				DMA_WR_ENABLE,

	input			[ 7: 0]	ULA_PAGING,									// ULA's memory paging register

	output					SD_CLK,										// SD Card external connections
	inout					SD_CMD,
	input					SD_DAT0,
	output					SD_DAT1,
	output					SD_DAT2,
	output					SD_DAT3
);

parameter  IO_PORT				= 3'd1;									// IO port BIT NUMBER (0-7)

localparam TRUE					= 1'b1;
localparam FALSE				= 1'b0;

localparam CLK_SLOW				= 3'd6;									// Bit 6 of clock counter about 2.18KHz
localparam CLK_FAST				= 3'd3;									// Bit 3 of clock counter about 1.75MHz

localparam STATE_IDLE			= 4'd0;									// Waiting on command
localparam STATE_PRE_WRITE		= 4'd1;									// Pre-write delay
localparam STATE_WRITE			= 4'd2;									// Write cmd message
localparam STATE_READ			= 4'd3;									// Wait and read response
localparam STATE_GO_IDLE 		= 4'd4;									// Flip the LAST M flag and enter IDLE
localparam STATE_TIMEOUT		= 4'd5;									// Read timeout
localparam STATE_PRE_READ		= 4'd6;									// Wait for start/init read
localparam STATE_PRE_RD_DATA	= 4'd7;									// Wait for Start/init read data
localparam STATE_RD_DATA		= 4'd8;									// Read data block

localparam CMD_RESET			= 6'h00; 								// CMD0 - Reset all cards to idle
localparam CMD_SEND_CID			= 6'h02; 								// CMD2 - All cards send CID
localparam CMD_SEND_RCA			= 6'h03; 								// CMD3 - Send RCA
localparam CMD_SELECT			= 6'h07;								// CMD7 - Select card by RCA
localparam CMD_IF_COND			= 6'h08;								// CMD8 - Send interface condition
localparam CMD_SEND_STATUS		= 6'h0D;								// CMD13 - Send status
localparam CMD_SET_BLOCKLEN 	= 6'h10;								// CMD16 - Set block length in bytes (512)
localparam CMD_RD_BLOCK			= 6'h11;								// CMD17 - Single block read
localparam CMD_OP_COND			= 6'h29;								// ACMD41 - Send operating conditions
localparam CMD_APP_CMD			= 6'h37;								// CMD55  - Indicates APP mode (A prefix command to follow)
localparam CMD_SEND_OCR			= 6'h3A;								// CMD58 - Read OCR
localparam CMD_IDLE				= 6'h3F;								// MUST be set to this when state is IDLE

localparam PRE_WR_CMD			= 8'd31;								// Pre write command timeout
localparam PRE_RD_CMD			= 16'd1000;								// Pre read command timeout
localparam PRE_RD_DAT			= 16'd10000;							// Pre read data timeout

localparam RSP_NONE				= 8'd0;									// No response
localparam RSP_SHORT			= 8'd46;								// Short reply high bit
localparam RSP_LONG				= 8'd134;								// Long reply high bit

localparam CMD_BITS				= 16'd47;								// High bit index of command
localparam DATA_BITS			= 16'd4111;								// Number of bits in 512 bytes + 2 byte CRC
localparam CRC_BITS				= 16'd4096;								// Number of bits to use for CRC calculation

localparam ERR_OK				= 6'h00;								// OK
localparam ERR_TIMEOUT			= 6'h01;								// Timed out waiting for response
localparam ERR_READ_FAIL		= 6'h02;								// CRC didnt match on read block

localparam SECTOR_BUFFER		= 6'b001000;							// Memory address of sector buffer (high 6 bits of $2000)

///////////////////////////////////////////////////////////////////////////
// Command to SD controller (48 bit)

reg					[ 5: 0]	CMD_CODE;									// 6 bit command code
reg			 [ 0: 3][ 7: 0]	CMD_ARG;									// 32 bit (4*8) arguments
reg		  			[ 6: 0]	CMD_CRC;									// 7 bit crc

wire				[47: 0] CMD_MSG = { 2'b01, CMD_CODE, CMD_ARG, CMD_CRC, 1'b1 };

reg							SD_OUT_EN;									// SD card output enable
reg							SD_BIT_OUT;									// SD card output bit

///////////////////////////////////////////////////////////////////////////
// State

reg					[ 3: 0]	FSM_STATE;
reg					[ 3: 0] FSM_NEXT_STATE;
reg							LAST_M;
reg							CUR_LAST_M;									// For detecting changes in LAST_M

///////////////////////////////////////////////////////////////////////////
// Clock counter/divider

reg					[ 2: 0]	CLK_SPEED;
reg					[ 6: 0]	CLK_COUNT;

reg					[ 9: 0]	BIT_COUNT;									// Total number of bits to read
reg					[ 9: 0]	DMA_OFFSET;									// Address offset within buffer

reg					[13: 0]	TIMEOUT;									// Timeout counter max 10000
reg					[15: 0]	CALC_CRC;									// CRC calculated from data
reg					[15: 0]	DATA_CRC;									// CRC read from data block
reg					[ 7: 0]	BYTE_BUF;									// Buffer 1 byte
reg					[ 6: 0]	STATUS;

reg							BUSY;

initial begin

	CMD_CODE			= CMD_IDLE;										// This MUST be this value when IDLE
	CMD_ARG				= 32'd0;
	CMD_CRC				= 8'd0;

	CLK_SPEED			= CLK_SLOW;										// Select SLOW speed
	CLK_COUNT			= 6'b0;

	BUSY				= FALSE;

	SD_OUT_EN			= FALSE;										// No output to SD card
	SD_BIT_OUT			= FALSE;

	DMA_WR_ENABLE		= FALSE;										// No DMA

	LAST_M				= FALSE;										// Indicates IDLE state
	CUR_LAST_M			= FALSE;										// To detect changes in LAST_M

	STATUS 				= 6'd0;
	FSM_STATE			= STATE_IDLE;									// State machine
	FSM_NEXT_STATE		= STATE_IDLE;

end

wire 					IO_SEL;
wire			[ 3: 0]	IO_REG;

assign		IO_SEL	 	= CPU_ADDRESS[IO_PORT] |						// Selected as IO device (Active low)
						  CPU_IORQ |
						  ULA_PAGING[5];

assign		IO_REG	 	= CPU_ADDRESS[11: 8];							// Internal register number 0-15

assign		SD_CLK		= CLK_COUNT[CLK_SPEED];							// Clock speed select

assign		SD_DAT1 	= TRUE;											// Do NOT let SD go into SPI mode
assign		SD_DAT2 	= TRUE;
assign		SD_DAT3		= TRUE;

assign		SD_CMD	 	= SD_OUT_EN ? SD_BIT_OUT  : 1'bz;				// Write command bit
wire		SD_RD_BIT	= SD_OUT_EN ? 1'b1		  : SD_CMD;				// Read command bit
wire		SD_RD_DAT	= SD_OUT_EN ? 1'b1		  : SD_DAT0;			// Read data bit

assign		CPU_DATA_BUS = IO_SEL | CPU_RD ?  8'bz : { BUSY, STATUS };	// CPU read status if IO_SEL AND CPU_RD are both low

///////////////////////////////////////////////////////////////////////////
// Clock generator/IO port writer

always @(posedge CLK_28) begin
	
	if (RESET) begin													// Reset button

		CMD_CODE 		<= CMD_IDLE;
		CUR_LAST_M		<= LAST_M;

	end else begin
		
		if (~(IO_SEL | CPU_WR)) begin									// If writing to the IO ports (Active low)

			case(IO_REG)

			4'hF: begin													// FFFD - 65531
				CMD_CODE	<= CPU_DATA_BUS[5:0];						// NB Writing the command code kicks off the state machine
			end															// So the CPU must write the IO ports in reverse order

			4'hB: begin													// FBFD - 65277
				CMD_ARG[0]	<= CPU_DATA_BUS;							// Write to each of the 4 byte arguments
			end

			4'hC: begin													// FCFD - 65021
				CMD_ARG[1]	<= CPU_DATA_BUS;
			end

			4'hD: begin													// FDFD - 64765
				CMD_ARG[2]	<= CPU_DATA_BUS;
			end

			4'hE: begin													// FEFD - 64509
				CMD_ARG[3]	<= CPU_DATA_BUS;
			end

			endcase
		end

		if (CUR_LAST_M		!= LAST_M) begin							// If LAST_M changes
			CUR_LAST_M		<= LAST_M;									// The SD loop is about to move to IDLE state
			CMD_CODE		<= CMD_IDLE;								// so ensure current code is CMD_IDLE
		end

		CLK_COUNT			<= CLK_COUNT + 7'd1;						// Update the CLK counter

	end
end

///////////////////////////////////////////////////////////////////////////
// SD state machine

	// Combinational logic for FSM next state determination

always @(*) begin

	if (RESET) begin

        FSM_STATE       			 = STATE_IDLE;

	end else begin

        FSM_STATE					 = FSM_NEXT_STATE;

    end
end

always @(posedge SD_CLK) begin

	if (RESET) begin													// Reset button

		DMA_WR_ENABLE <= FALSE;
		
	end else begin
	
		case(FSM_STATE)


		STATE_IDLE: begin												// Idle stat waits for CMD_CODE to contain a new command

			if (CMD_CODE != CMD_IDLE) begin

				STATUS			<= 0;									// No errors yet
				BUSY			<= TRUE;								// We're getting busy

				TIMEOUT 		<= 14'd0;								// Clear timeout for next state
	
				{ SD_BIT_OUT, SD_OUT_EN } <= { TRUE, TRUE };			// Output enabled and bit set high so the start bit 0 will be detected

				FSM_NEXT_STATE	<= STATE_PRE_WRITE;

			end

		end

		// Begin writing the command (in the buffer) to the SD Card

		STATE_PRE_WRITE: begin											// Pre write - wait for TIMEOUT cycles

			TIMEOUT			<= TIMEOUT + 14'd1;							// Wait for TIMEOUT cycles

			if (TIMEOUT		== PRE_WR_CMD) begin 						// Timeout expired (31 cycles) - start write

				CMD_CRC	 	<= 7'd0;									// Prepare to write, clear CRC

				BIT_COUNT 	<= CMD_BITS;								// Initialize bit counter for command write

				SD_OUT_EN	<= TRUE;									// Enable output to SD Card

				FSM_NEXT_STATE <= STATE_WRITE;							// Next state is WRITE

			end
		end


		STATE_WRITE: begin												// The actual WRITE operation

			if (BIT_COUNT 		== 10'h3FF) begin						// All bits sent

				SD_OUT_EN		<= FALSE;								// Turn off output

				TIMEOUT			<= PRE_RD_CMD;							// Set pre read timeout

				FSM_NEXT_STATE	<= CMD_CODE == CMD_RESET ? STATE_GO_IDLE :		// Read response not expected - go idle
														   STATE_PRE_READ;		// else prepare to read the response

			end else begin
				
				BIT_COUNT 	<= BIT_COUNT - 10'd1;						// Count down bits sent

				SD_BIT_OUT	<= CMD_MSG[ BIT_COUNT ];					// Enable output and set bit value

				if (BIT_COUNT > 7) CMD_CRC <= CRC7( CMD_CRC, CMD_MSG[ BIT_COUNT ] );	// Update CRC

			end
		end

		// Now begin reading the response from the SD Card

		STATE_PRE_READ: begin											// Wait for start bit of response

			if (SD_RD_BIT		== 1'b0) begin							// Data goes low to indicate start of response

				DMA_OFFSET		<= 16'h201;								// Address of response buffer in RAM
				BYTE_BUF		<= 8'd0;		  						// Clear byte buffer
				DMA_WR_ENABLE	<= TRUE;								// Enable DMA for writing response to RAM
				BIT_COUNT 		<= CMD_CODE == CMD_SEND_CID ? RSP_LONG :		// Number of bits to read depends on the command
															  RSP_SHORT;		// 48 or 136 bits

				FSM_NEXT_STATE	<= STATE_READ;

			end else begin

				TIMEOUT <= TIMEOUT - 14'd1;								// Timeout expires
				if (TIMEOUT == 14'd0) FSM_NEXT_STATE <= STATE_TIMEOUT;

			end

		end


		STATE_READ: begin
			
			BIT_COUNT <= BIT_COUNT - 8'd1;								// Don't bother with CRC check as not all responses have one

			if (BIT_COUNT		== 10'h3FF) begin						// All bits of entire message read

				DMA_WR_ENABLE	<= FALSE;								// Turn off DMA

				TIMEOUT			<= PRE_RD_DAT;							// Set longer timeout for data read

				FSM_NEXT_STATE	<= // CMD_CODE == CMD_RD_BLOCK ? STATE_PRE_RD_DATA :
															  STATE_GO_IDLE;

			end else begin

				BYTE_BUF[ BIT_COUNT[2:0] ] <= SD_RD_BIT;				// Set bit in the byte buffer

				if ( BIT_COUNT[2:0] == 3'd7 ) begin						// Byte complete - write to RAM area

					DMA_OFFSET 	<= DMA_OFFSET + 10'd1;

					DMA_WR_DATA <= BYTE_BUF;

				end

			end
		end


		// STATE_PRE_RD_DATA: begin

		// 	if (SD_RD_DAT	== 1'b0) begin								// If start bit (0) found

		// 		DAT_BIT_IN 	<= 16'h0;									// Bit in count 0
		// 		CALC_CRC	<= 16'b0;									// Clear calculated CRC

		// 		FSM_NEXT_STATE <= STATE_RD_DATA;						// Enter read data state

		// 	end else begin
			
		// 		TIMEOUT		<= TIMEOUT - 14'd1;							// Timeout expires
		// 		if (TIMEOUT == 14'd0) FSM_NEXT_STATE <= STATE_TIMEOUT;

		// 	end

		// end


		// STATE_RD_DATA: begin

		// 	DAT_BIT_IN <= DAT_BIT_IN + 14'd1;							// Count the bits read

		// 	if (DAT_BIT_IN < CRC_BITS) begin							// Bits 0 - 4095 (512 bytes)

		// 		CALC_CRC <= CRC16( CALC_CRC, SD_RD_DAT);				// Update calculated CRC16 with the new bit

		// 		BYTE_BUF[ ~DAT_BIT_IN[2:0] ] <= SD_RD_DAT;				// Set bit in the byte buffer

		// 		if ( DAT_BIT_IN[2:0] == 3'd0 ) begin					// Byte complete - write to RAM area

		// 			{ DMA_WR_ENABLE, DMA_WR_DATA } <= { TRUE, BYTE_BUF };

		// 		end else begin

		// 			DMA_WR_ENABLE 	<= FALSE;							// Turn off DMA for incomplete byte

		// 		end

		// 	end else begin 
				
		// 		DATA_CRC[ ~DAT_BIT_IN[3:0] ] <= SD_RD_DAT;				// Set final bit in the CRC reg

		// 		if (DAT_BIT_IN > CRC_BITS) begin						// Bits 4097 - 4111

		// 			DMA_WR_ENABLE 	<= FALSE;							// Turn off DMA

		// 			if ( DAT_BIT_IN > DATA_BITS) begin					// All bits have been read, check CRC
						
		// 				if (DATA_CRC != CALC_CRC) STATUS <= ERR_READ_FAIL;	// Error

		// 				FSM_NEXT_STATE <= STATE_GO_IDLE;				// Back to IDLE state
		// 			end

		// 		end else begin											// Bit 4096

		// 			{ DMA_WR_ENABLE, DMA_WR_DATA } <= { TRUE, BYTE_BUF };	// Write the final byte

		// 		end

		// 	end
		// end


		STATE_TIMEOUT: begin

			STATUS			<= ERR_TIMEOUT;								// Indicate error condition
			FSM_NEXT_STATE	<= STATE_GO_IDLE;

		end


		STATE_GO_IDLE: begin											// Prepare to go into IDLE state

			if (CMD_CODE == CMD_SELECT) CLK_SPEED <= CLK_FAST;			// Switch speed up

			DMA_WR_ENABLE <= FALSE;										// Turn off DMA
			SD_OUT_EN	  <= FALSE;										// Disable SD output
			BUSY		  <= FALSE;										// We're not busy

			LAST_M		  <= ~LAST_M;									// Indicate going IDLE		

			FSM_NEXT_STATE <= STATE_IDLE;								// Enter IDLE state and wait on command

		end

		endcase

	end																	// end of RESET

end

assign DMA_ADDRESS = { SECTOR_BUFFER, DMA_OFFSET };					// Buffer address $2000 (8192)

function automatic	[ 6: 0]	CRC7(
	input			[ 6: 0]	CRC,
	input					BIT
);

	CRC7 =	{ CRC[5:0],	CRC[6] ^ BIT } ^								// 7 bit CRC calculation
			{ 	  3'b0,	CRC[6] ^ BIT, 3'b0 };

endfunction

function automatic 	[15: 0]	CRC16(
	input			[15: 0]	CRC,
	input					BIT
);

	CRC16 = {		CRC[14: 0],			 CRC[15] ^ BIT } ^				// 16 bit CRC calculation
			{ 3'b0, CRC[15] ^ BIT, 6'b0, CRC[15] ^ BIT, 5'b0 };

endfunction


endmodule
