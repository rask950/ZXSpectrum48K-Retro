`timescale 1ns / 1ps

module ZX_Spectrum_Z80 (

	input CLK,
	input RESET,

	input  reg  [7:0]DATA_IN,
	output reg  [7:0]DATA_OUT,
	output reg [15:0]ADDRESS_BUS,

	input  reg WAIT,
	input  reg INT,
	input  reg NMI,
	output reg M1,
	output reg MREQ,
	output reg IORQ,
	output reg RD,
	output reg WR,
	output reg RFSH,
	output reg HALT
);

`include "..\\Global.vh"

`include "Z80_Parameters.vh"

`include "Z80_Registers.vh"

FSM_REG FSM_STATE;												// CPU state
FSM_REG FSM_NEXT_STATE;											// CPU state next clock
reg	    FSM_LAST_M;												// Indicates last M cycle of instruction

reg [7:0]OPCODE_REG;											// Opcode

reg IX;									 						// Instruction prefixes
reg IY;
reg BITS;
reg EXTD;

reg [1:0]INT_MODE;												// Interrupt mode 0-2
reg IFF1;														// Interrupt enabled FF 1
reg IFF2;														// and 2
reg EXA;														// Selects AF or AF'
reg EXX;														// Selects ALT registers

initial begin

	FSM_STATE		= STATE_IDLE;								// Initialise FSM
	FSM_NEXT_STATE	= STATE_M1T1H;
	FSM_LAST_M		= FALSE;

	////////////////////////////////////////////////////////////////////////////
	// CPU Internal status control

	INT_MODE = 0;												// Interrupt mode 0-2
	IFF1	 = FALSE;											// Interrupt enabled FF 1
	IFF2	 = FALSE;											// and 2
	EXA		 = FALSE;											// AF/AF'
	EXX		 = FALSE;											// BC,DE,HL/BC',DE',HL'

	////////////////////////////////////////////////////////////////////////////
	// CPU Instruction prefixes

	IX	 = FALSE;
	IY	 = FALSE;
	BITS = FALSE;
	EXTD = FALSE;

	////////////////////////////////////////////////////////////////////////////
	// CPU External control signals

	M1	 = INACTIVE;
	WR	 = INACTIVE;
	RD	 = INACTIVE;
	MREQ = INACTIVE;
	IORQ = INACTIVE;
	RFSH = INACTIVE;

	`REG_PC = 16'd0;					  						// Start execution here
end

	////////////////////////////////////////////////////////////////////////////
	// CPU Register decoder

reg [2:0]CPU_REG_NUM;											// Register decode bus
reg [4:0]REG8_INDEX;											// Decoded index for 8 bit regs
reg [3:0]REG16_INDEX;											// Decoded index for 16 bit regs

REGS REG;														// Register file

REG_DECODE ZREG(
	.IY( IY),
	.IX( IX),
	.EXX(EXX),
	.EXA(EXA),
	.REG_NUM(CPU_REG_NUM),
	.REG8_INDEX( REG8_INDEX),
	.REG16_INDEX(REG16_INDEX)
);

	////////////////////////////////////////////////////////////////////////////
	// Arithmetic unit 

reg [4:0]ALU_OPCODE;											// ALU operation code
reg [7:0]ALU_OP1;												// 1st operand
reg [7:0]ALU_OP2;												// 2nd operand
reg [7:0]ALU_INFLAGS;											// Flags in
reg [7:0]ALU_RESULT;											// Result out
reg [7:0]ALU_OUTFLAGS;											// Flags out

Z80_ALU YALU (
	.opcode(	ALU_OPCODE),
	.op1(		ALU_OP1),
	.op2(		ALU_OP2),
	.inflags(	ALU_INFLAGS),
	.result(	ALU_RESULT),
	.outflags(	ALU_OUTFLAGS)
);

	////////////////////////////////////////////////////////////////////////////
	// Incrementer

reg 	  INC_DIR;												// Direction INC/DEC
reg		  INC_BITS;												// Number of bits (0=7, 1=16)
reg [15:0]INC_OUT;												// Output from incrementer

Z80_INCREMENTER ZINC (
	.INC_DIR(	INC_DIR),
	.INC_BITS(	INC_BITS),
	.INC_IN(	ADDRESS_BUS),
	.INC_OUT(	INC_OUT)
);

	////////////////////////////////////////////////////////////////////////////
	// Condition code 

reg [2:0]CC_INDEX;												// CC index NZ,Z,NC,C,PO,PE,P,M
reg [7:0]CC_INFLAGS;											// Flags in
wire 	 CC_RESULT;												// Result out

Z80_CC ZCC (
	.index(		CC_INDEX),
	.inflags(	CC_INFLAGS),
	.result(	CC_RESULT)
);

	////////////////////////////////////////////////////////////////////////////
	// Main CPU processing loop!

always @(posedge CLK) begin

	if (RESET) begin

		`REG_PC	 <= 0;

		INT_MODE <= 0;												// Interrupt mode 0-2
		IFF1	 <= FALSE;											// Interrupt enabled FF 1
		IFF2	 <= FALSE;											// and 2
		EXA		 <= FALSE;											// AF/AF'
		EXX		 <= FALSE;											// BC,DE,HL/BC',DE',HL'

		IX	 <= FALSE;
		IY	 <= FALSE;
		BITS <= FALSE;
		EXTD <= FALSE;

		FSM_NEXT_STATE	<= STATE_M1T1H;
        FSM_STATE        = STATE_IDLE;
		FSM_LAST_M		 = FALSE;

	end else begin

        FSM_STATE = FSM_NEXT_STATE;

    end

	casez(FSM_STATE)

	///////////////////////////////////////////////////////////////////////////
	// M1 Pseudo cycle for NMI/INT1/HALT that does NOT pick up a new opcode

	STATE_NIT1H: begin										    // T1
		ADDRESS_BUS 	 <=`REG_PC;								// PC -> Address bus and incrementer (not used)
		M1			     <= ACTIVE;					    		// M1 active
		FSM_NEXT_STATE.T <= STATE_T1L;
	end

	STATE_NIT1L: begin										    // One half-cycle later ...
		MREQ			 <= ACTIVE;
		RD				 <= ACTIVE;								// MREQ and RD go active
		FSM_NEXT_STATE.T <= STATE_T2H;							// PC NOT updated
	end

	STATE_NIT2H: begin										    // T2 - Process WAIT signal
		FSM_NEXT_STATE.T <= STATE_T2L;
	end

	STATE_NIT2L: begin											// Execute T2 again if WAIT is active
		FSM_NEXT_STATE.T <= WAIT ? STATE_T3H : STATE_T2H;
	end

	STATE_NIT3H: begin											// T3 - Prepare to refresh  NO INSTRUCTION READ
		ADDRESS_BUS		 <= `REG_IR;
		M1			 	 <= INACTIVE;
		RD			 	 <= INACTIVE;
		MREQ			 <= INACTIVE;
		RFSH			 <= ACTIVE;
		INC_DIR			 <= TRUE;								// Set incrementer to add 7 bits
		INC_BITS		 <= FALSE;
		FSM_NEXT_STATE	 <= STATE_M1T3L;						// Remainder follows the usual M1
	end

	///////////////////////////////////////////////////////////////////////////
	// M1 Machine Cycle 1 - Read opcode and refresh

	STATE_M1T1H: begin										    // T1 - Prepare to read opcode
		ADDRESS_BUS 	 <=`REG_PC;								// PC -> Address bus and incrementer
		M1			     <= ACTIVE;					    		// M1 active
		INC_DIR			 <= TRUE;								// Set incrementer to add 16 bits
		INC_BITS		 <= TRUE;
		FSM_NEXT_STATE.T <= STATE_T1L;
	end

	STATE_M1T1L: begin										    // One half-cycle later ...
	   `REG_PC			 <= INC_OUT;							// Update PC
		MREQ			 <= ACTIVE;
		RD				 <= ACTIVE;								//	MREQ and RD go active
		FSM_NEXT_STATE.T <= STATE_T2H;
	end

	STATE_M1T2H: begin										    // T2 - Process WAIT signal
		FSM_NEXT_STATE.T <= STATE_T2L;
	end

	STATE_M1T2L: begin											// Execute T2 again if WAIT is active
		if (WAIT) begin											// Wait is INACTIVE
	        OPCODE_REG 		 <= DATA_IN;
			FSM_NEXT_STATE.T <= STATE_T3H;
		end else begin
			FSM_NEXT_STATE.T <= STATE_T2H;
		end
	end

	STATE_M1T3H: begin											// T3 - Prepare to refresh & Instruction decode
 		ADDRESS_BUS		 <=`REG_IR;								// The OPCODE can be used from here onwards
		M1			 	 <= INACTIVE;
		RD			 	 <= INACTIVE;
		MREQ			 <= INACTIVE;
		RFSH			 <= ACTIVE;
		INC_BITS		 <= FALSE;								// Set incrementer to add 7 bits
		FSM_NEXT_STATE.T <= STATE_T3L;
	end

	STATE_M1T3L: begin
		MREQ			 <= ACTIVE;								// MREQ active for refresh
	   `REG_IR			 <= INC_OUT;							// Update IR reg
		FSM_NEXT_STATE.T <= STATE_T4H;
	end

	STATE_M1T4H: begin
		FSM_NEXT_STATE.T <= STATE_T4L;
	end

	STATE_M1T4L: begin											// MREQ & RFSH inactive
		RFSH			<= INACTIVE;
		MREQ			<= INACTIVE;
	end															// Instruction defines next state

	STATE_M1T5H: begin											// T5 - a few instructions need this
		FSM_NEXT_STATE.T <= STATE_T5L;
	end

	STATE_M1T6H: begin										  	// T6 - even fewer need this
		FSM_NEXT_STATE.T <= STATE_T6L;
	end

	///////////////////////////////////////////////////////////////////////////
	// MR Machine Cycle - Memory Read

	STATE_MRT1H: begin											// T1 - Address bus initialized elsewhere
		FSM_NEXT_STATE.T <= STATE_T1L;
	end

	STATE_MRT1L: begin											// MREQ and RD active
		MREQ			 <= ACTIVE;
		RD				 <= ACTIVE;
		FSM_NEXT_STATE.T <= STATE_T2H;
	end

	STATE_MRT2H: begin								 			// T2 - Process WAIT signal
		FSM_NEXT_STATE.T <= STATE_T2L;
	end

	STATE_MRT2L: begin											// Execute T2 again if WAIT is active
		FSM_NEXT_STATE.T <= WAIT ? STATE_T3H : STATE_T2H;
	end

	STATE_MRT3H: begin											// [Data can be read here]
		FSM_NEXT_STATE.T <= STATE_T3L;
	end

	STATE_MRT3L: begin											// RD, MREQ inactive
		RD			 	<= INACTIVE;				 			// Instruction defines next state
		MREQ			<= INACTIVE;
	end

	STATE_MRT4H: begin
		FSM_NEXT_STATE.T <= STATE_T4L;
	end

	STATE_MRT5H: begin
		FSM_NEXT_STATE.T <= STATE_T5L;
	end

	///////////////////////////////////////////////////////////////////////////
	// MW Machine Cycle - Memory Write

	STATE_MWT1H: begin											// Address bus initialized elsewhere
		FSM_NEXT_STATE.T <= STATE_T1L;
	end

	STATE_MWT1L: begin											// MREQ active
		MREQ			 <= ACTIVE;								// Data bus initialized elsewhere
		FSM_NEXT_STATE.T <= STATE_T2H;
	end

	STATE_MWT2H: begin											// T2 - Process WAIT signal
		FSM_NEXT_STATE.T <= STATE_T2L;
	end

	STATE_MWT2L: begin											// Execute T2 again if WAIT is active
		if (WAIT) begin											// NB active LOW
			FSM_NEXT_STATE.T <= STATE_T3H;
			WR				 <= ACTIVE;							// WR active at this point
		end else begin
			FSM_NEXT_STATE.T <= STATE_T2H;
		end
	end

	STATE_MWT3H: begin
		FSM_NEXT_STATE.T <= STATE_T3L;
	end

	STATE_MWT3L: begin											// WR, MREQ inactive
		WR				<= INACTIVE;							// Instruction defines next state
		MREQ			<= INACTIVE;
	end

	STATE_MWT4H: begin
		FSM_NEXT_STATE.T <= STATE_T4L;
	end

	STATE_MWT5H: begin
		FSM_NEXT_STATE.T <= STATE_T5L;
	end

	///////////////////////////////////////////////////////////////////////////
	// IR Machine Cycle - IO Read

	STATE_IRT1H: begin											// IO port address initialized elsewhere
		FSM_NEXT_STATE.T <= STATE_T1L;
	end

	STATE_IRT1L: begin
		FSM_NEXT_STATE.T <= STATE_T2H;
	end

	STATE_IRT2H: begin											// IORQ and RD active
		RD				 <= ACTIVE;
		IORQ			 <= ACTIVE;
		FSM_NEXT_STATE.T <= STATE_T2L;
	end

	STATE_IRT2L: begin											// A wait cycle is inserted here
		FSM_NEXT_STATE.T <= STATE_T3H;
	end

	STATE_IRT3H: begin											// T3 - Extra WAIT cycle
		FSM_NEXT_STATE.T <= STATE_T3L;
	end

	STATE_IRT3L: begin											// Execute T3 again if WAIT is active
		FSM_NEXT_STATE.T <= WAIT ? STATE_T4H : STATE_T3H;
	end

	STATE_IRT4H: begin
		FSM_NEXT_STATE.T <= STATE_T4L;
	end

	STATE_IRT4L: begin											// IORQ and RD inactive
		IORQ			<= INACTIVE;							// Instruction defines next state
		RD				<= INACTIVE;
	end

	////////////////////////////////////////////////////////////////////////
	// IW Machine Cycle - IO Write

	STATE_IWT1H: begin											// IO port address initialized elsewhere
		FSM_NEXT_STATE.T <= STATE_T1L;
	end

	STATE_IWT1L: begin											// Insert wait state extra
		FSM_NEXT_STATE.T <= STATE_T2H;							// Data bus initialized elsewhere
	end

	STATE_IWT2H: begin								 			// IORQ and WR active
		WR				 <= ACTIVE;
		IORQ			 <= ACTIVE;
		FSM_NEXT_STATE.T <= STATE_T2L;
	end

	STATE_IWT2L: begin											// Insert extra wait here
		FSM_NEXT_STATE.T <= STATE_T3H;
	end

	STATE_IWT3H: begin								 			// TW - Extra WAIT signal
		FSM_NEXT_STATE.T <= STATE_T3L;
	end

	STATE_IWT3L: begin											// Execute TW again if WAIT is active
		FSM_NEXT_STATE.T <= WAIT ? STATE_T4H : STATE_T3H;
	end

	STATE_IWT4H: begin
		FSM_NEXT_STATE.T <= STATE_T4L;
	end

	STATE_IWT4L: begin											// IORQ and WR inactive
		IORQ			<= INACTIVE;							// Instruction defines MIWT3L
		WR				<= INACTIVE;
	end

	////////////////////////////////////////////////////////////////////////
	// General Machine Cycle - misc operations
	
	STATE_GNT1H: FSM_NEXT_STATE.T <= STATE_T1L;					// For each general H, move on to L
	STATE_GNT2H: FSM_NEXT_STATE.T <= STATE_T2L;
	STATE_GNT3H: FSM_NEXT_STATE.T <= STATE_T3L;
	STATE_GNT4H: FSM_NEXT_STATE.T <= STATE_T4L;
	STATE_GNT5H: FSM_NEXT_STATE.T <= STATE_T5L;

	endcase

	////////////////////////////////////////////////////////////////////////////
	// Main instruction decode and execution
	
	casez({ IY, IX, EXTD, BITS, OPCODE_REG })

	////////////////////////////////////////////////////////////////////////////
	// Instruction prefixes

	PLA_PF_EXTD: begin												// M1(4) EXTD [ED]
		if (FSM_STATE == STATE_M1T4L) begin
			EXTD				<= TRUE;							// Set the flag and get next opcode
			FSM_NEXT_STATE.T	<= STATE_T1H;
		end
	end

	PLA_PF_IXIY: begin												// M1(4) IX/IY [DD/FD]
		if (FSM_STATE == STATE_M1T4L) begin
			if (OPCODE_REG[5]) IY <= TRUE; else IX <= TRUE;
			FSM_NEXT_STATE.T	  <= STATE_T1H;
		end
	end

	PLA_PF_BITS: begin												// M1(4) BITS only [CB]
		if (FSM_STATE == STATE_M1T4L) begin
			BITS			 <= TRUE;								// Set the flag and get next opcode
			FSM_NEXT_STATE.T <= STATE_M1T1H;
		end
	end

	PLA_PF_BTXY: begin												// M1(4) BITS with IX/IY [CB]
		
		case(FSM_STATE)

		STATE_M1T4L: begin											// M1 that read the CB prefix
			FSM_NEXT_STATE	<= STATE_MR1T1H;
		end



		STATE_MR1T1H: begin											// MR(3) Prepare to read displacement
			ADDRESS_BUS		<= `REG_PC;
			INC_DIR			<= TRUE;								// ADD 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3L: begin
		   `REG_PC			<= INC_OUT;								// PC + 1
			ALU_OP2			<= DATA_IN;								// Pick up the displacement into ALU
			BITS			<= TRUE;								// Set the BITS flag
			FSM_NEXT_STATE	<= STATE_M1T1H;							// Go directly to another M1 for opcode
		end

		endcase

	end

	////////////////////////////////////////////////////////////////////////////
	// Special case HALT - MUST go BEFORE LD r,(HL)/LD (HL),r

	PLA_HALT: begin													// M1(4) HALT

		if (FSM_STATE == STATE_M1T4L) begin
			if (INT & NMI) begin                                	// No interrupt has happened
				HALT			<= ACTIVE;							// HALT output goes active
				FSM_NEXT_STATE	<= STATE_NIT1H;						// Now start a pseudo M1 cycle which comes back here
			end else begin
				HALT			<= INACTIVE;						// HALT goes inactive
				FSM_LAST_M		 = TRUE;
			end
		end

	end


	////////////////////////////////////////////////////////////////////////////
	// 8-Bit load group
	
	PLA_LDR_HXY: begin												// M1(4) LD r,(HL/IX+n/IY+n)

		case(FSM_STATE)

		STATE_M1T4L: begin
		   `REG_WZ			<= `CUR_HL;								// Base address to WZ
			FSM_NEXT_STATE	<= (IX|IY) ? STATE_MR1T1H : STATE_MR2T1H;
		end



		STATE_MR1T1H: begin											// MR(3) Read displacement
			ADDRESS_BUS		<=`REG_PC;
			INC_DIR			<= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3L: begin
		   `REG_PC			<= INC_OUT;
			ALU_OP2			<= DATA_IN;								// Pick up displacement byte
			FSM_NEXT_STATE	<= STATE_GN1T1H;						// Now start a new cycle for calculation
		end



		STATE_GN1T1H: begin											// MG(5) For displacement and timing purposes
			ALU_OPCODE		<= ALU_ADC;								// Prepare to add displacement
			ALU_OP1			<=`REG_Z;								// To temp reg
			ALU_INFLAGS		<= 8'd0;								// Clear carry
		end

		STATE_GN1T1L: begin
		   `REG_Z			 <= ALU_RESULT;							// Low byte result to Z
			FSM_NEXT_STATE.T <= STATE_T2H;
		end

		STATE_GN1T2H: begin
			ALU_OP1			<=`REG_W;
			ALU_OP2			<= {8{ ALU_OP2[7] }};					// This is 255 or 0 depending on the sign of OP2
			ALU_INFLAGS		<= ALU_OUTFLAGS;						// Also need the flags for any carry
		end

		STATE_GN1T2L: begin
		   `REG_W			 <= ALU_RESULT;							// High byte result to W - Ignore flags
			FSM_NEXT_STATE.T <= STATE_T3H;
		end

		STATE_GN1T3L: FSM_NEXT_STATE.T	<= STATE_T4H;				// Timing

		STATE_GN1T4L: FSM_NEXT_STATE.T	<= STATE_T5H;

		STATE_GN1T5L: FSM_NEXT_STATE	<= STATE_MR2T1H;			// Move on to memory read



		STATE_MR2T1H: begin											// MR(3) Read byte
			ADDRESS_BUS		<=`REG_WZ;								// Read address to bus
			IY				<= FALSE;								// Cancel IX and IY prefix so H and L are correct
			IX				<= FALSE;
			CPU_REG_NUM		<= OPCODE_REG[5:3];						// Decode the destination reg
		end

		STATE_MR2T3H: begin
			REG.R8[REG8_INDEX] <= DATA_IN;							// The actual load
		end

		STATE_MR2T3L: begin											// Instruction complete
			FSM_LAST_M		= TRUE;
		end

		endcase
	end

	PLA_LDHXY_R: begin												// M1(4) LD (HL/IX+n/IY+n),r

		case(FSM_STATE)

		STATE_M1T4L: begin
		   `REG_WZ 			<= `CUR_HL;								// Base address to WZ
			FSM_NEXT_STATE	<= (IX|IY) ? STATE_MR1T1H : STATE_MW1T1H;
		end



		STATE_MR1T1H: begin											// MR(3)
			ADDRESS_BUS		<=`REG_PC;					 			// Read displacement
			INC_DIR			<= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3L: begin											// Add displacement
		   `REG_PC			<= INC_OUT;
			ALU_OP2			<= DATA_IN;
			FSM_NEXT_STATE	<= STATE_GN1T1H;						// Now start a new cycle for calculation
		end



		STATE_GN1T1H: begin											// MG(5) For displacement and timing purposes
			ALU_OPCODE		<= ALU_ADC;								// Prepare to add displacement
			ALU_OP1			<=`REG_Z;								// To temp reg
			ALU_INFLAGS		<= 8'd0;								// Clear carry
		end

		STATE_GN1T1L: begin
		   `REG_Z			 <= ALU_RESULT;							// Low byte result to Z
			FSM_NEXT_STATE.T <= STATE_T2H;
		end

		STATE_GN1T2H: begin
			ALU_OP1			<=`REG_W;
			ALU_OP2			<= {8{ ALU_OP2[7] }};					// This is 255 or 0 depending on the sign of OP2
			ALU_INFLAGS		<= ALU_OUTFLAGS;						// Also need the flags for any carry
		end

		STATE_GN1T2L: begin
		   `REG_W			 <= ALU_RESULT;							// High byte result to W - Ignore flags
			FSM_NEXT_STATE.T <= STATE_T3H;
		end

		STATE_GN1T3L: FSM_NEXT_STATE.T	<= STATE_T4H;				// Timing

		STATE_GN1T4L: FSM_NEXT_STATE.T	<= STATE_T5H;

		STATE_GN1T5L: FSM_NEXT_STATE	<= STATE_MW1T1H;



		STATE_MW1T1H: begin											// MW(3) Write byte
			ADDRESS_BUS		<=`REG_WZ;								// Address to bus
			IY				<= FALSE;								// Cancel IX and IY prefix so H and L are correct
			IX				<= FALSE;
			CPU_REG_NUM		<= OPCODE_REG[2:0];						// Decode the source reg
		end

		STATE_MW1T1L: begin											// Value to data bus
			DATA_OUT		<= REG.R8[REG8_INDEX];
		end

		STATE_MW1T3L: begin											// Instruction complete
			FSM_LAST_M		= TRUE;
		end

		endcase
	end

	PLA_LDR_R: begin												// M1(4) LD r,r

		case(FSM_STATE)

		STATE_M1T3L: begin											// Decode source register
			CPU_REG_NUM		<= OPCODE_REG[2:0];
		end

		STATE_M1T4H: begin											// Read source register to data bus
		   `REG_Z			<= REG.R8[REG8_INDEX];					// Temp save source value
			CPU_REG_NUM		<= OPCODE_REG[5:3];						// Decode destination register
		end

		STATE_M1T4L: begin
			REG.R8[REG8_INDEX]	<=`REG_Z;							// Set value of destination register
			FSM_LAST_M		= TRUE;									// Complete
		end

		endcase
	end

	PLA_LDHXY_N: begin												// M1(4) LD (HL/IX+n/IY+n),n

		case(FSM_STATE)

		STATE_M1T4L: begin
		   `REG_WZ			<= `CUR_HL;								// Base address to WZ
			FSM_NEXT_STATE	<= (IX|IY) ? STATE_MR1T1H : STATE_MR2T1H;
		end



		STATE_MR1T1H: begin											// MR(5) - Should be next M cycle but isn't
			ADDRESS_BUS		 <=`REG_PC;					 			// Read displacement
			INC_DIR			 <= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		 <= TRUE;
		end

		STATE_MR1T3L: begin											// Add displacement
		   `REG_PC			 <= INC_OUT;
			ALU_OP2			 <= DATA_IN;							// Displacement to ALU
			FSM_NEXT_STATE.T <= STATE_T4H;							// Now add 2 extra cycles
		end

		STATE_MR1T4H: begin
			ALU_OPCODE		<= ALU_ADC;								// Prepare to add displacement
			ALU_OP1			<=`REG_Z;								// To temp reg
			ALU_INFLAGS		<= 8'd0;								// Clear carry
		end

		STATE_MR1T4L: begin
		   `REG_Z			 <= ALU_RESULT;							// Low byte result to Z
			FSM_NEXT_STATE.T <= STATE_T5H;
		end

		STATE_MR1T5H: begin
			ALU_OP1			<=`REG_W;
			ALU_OP2			<= {8{ ALU_OP2[7] }};					// This is 255 or 0 depending on the sign of OP2
			ALU_INFLAGS		<= ALU_OUTFLAGS;						// Also need the flags for any carry
		end

		STATE_MR1T5L: begin
		   `REG_W			<= ALU_RESULT;							// High byte result to W - Ignore flags
			FSM_NEXT_STATE	<= STATE_MR2T1H;
		end



		STATE_MR2T1H: begin											// MR(3)
			ADDRESS_BUS		<=`REG_PC;					 			// Read address to bus
			INC_DIR			<= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR2T3L: begin											// Data read, proceed to write
		   `REG_PC			<= INC_OUT;
			DATA_OUT		<= DATA_IN;								// Data IN goes to OUT
			FSM_NEXT_STATE	<= STATE_MW1T1H;
		end



		STATE_MW1T1H: begin											// MW(3)
			ADDRESS_BUS		<=`REG_WZ;								// Address to bus
		end

		STATE_MW1T3L: begin											// Instruction complete
			FSM_LAST_M		= TRUE;
		end

		endcase
	end

	PLA_LDR_N: begin												// M1(4) LD r,n

		case(FSM_STATE)

		STATE_M1T4L: begin								 			// Begin read cycle for immediate value
			FSM_NEXT_STATE	<= STATE_MR1T1H;
		end



		STATE_MR1T1H: begin											// MR(3)
			ADDRESS_BUS		<=`REG_PC;								// PC to address bus
			INC_DIR			<= TRUE;
			INC_BITS		<= TRUE;
			CPU_REG_NUM		<= OPCODE_REG[5:3];						// Decode destination register
		end

		STATE_MR1T3L: begin
		   `REG_PC				<= INC_OUT;							// Move past immediate byte
			REG.R8[REG8_INDEX]	<= DATA_IN;							// Make the assignment
			FSM_LAST_M		= TRUE;									// Instruction complete
		end

		endcase
	end

	PLA_LDA_MM: begin												// M1(4) LD A,(nn)/LD (nn),A

		case(FSM_STATE)

		STATE_M1T4L: begin							 				// Begin read cycle for immediate low byte
			FSM_NEXT_STATE	<= STATE_MR1T1H;
		end



		STATE_MR1T1H: begin											// MR(3) Read immediate low
			ADDRESS_BUS		<=`REG_PC;								// PC to address bus
			INC_DIR			<= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3H: begin											// Update PC and read low byte to temp register
			ADDRESS_BUS		<= INC_OUT;								// Next address
		   `REG_Z			<= DATA_IN;
		end

		STATE_MR1T3L: begin											// Prepare to read high byte
			FSM_NEXT_STATE	<= STATE_MR2T1H;
		end



		STATE_MR2T3H: begin											// MR(3) Update PC read high byte to temp reg
		   `REG_PC			<= INC_OUT;
		   `REG_W			<= DATA_IN;
		end

		STATE_MR2T3L: begin											// Now read/write depending on opcode
			ADDRESS_BUS		<=`REG_WZ;								// Temp reg holds the address
			FSM_NEXT_STATE	<= OPCODE_REG[3] ? STATE_MR3T1H : STATE_MW1T1H;
		end



		STATE_MR3T3H: begin											// MR(3)
		   `CUR_A			<= DATA_IN;
		end

		STATE_MR3T3L: begin											// Read byte into A
			FSM_LAST_M		= TRUE;
		end



		STATE_MW1T1L: begin											// MW(3) Write byte in A
		   DATA_OUT			<=`CUR_A;
		end

		STATE_MW1T3L: begin											// Instruction complete
			FSM_LAST_M		= TRUE;
		end

		endcase
	end

	PLA_LDA_RR: begin												// M1(4) LD A,(BC/DE)/LD (BC/DE),A

		case(FSM_STATE)

		STATE_M1T4H: begin
			CPU_REG_NUM		<= { 2'b0, OPCODE_REG[4] };				// Select BC or DE
		end

		STATE_M1T4L: begin
			ADDRESS_BUS		<= REG.R16[REG16_INDEX];				// BC/DE to address bus
			FSM_NEXT_STATE	<= OPCODE_REG[3] ? STATE_MR1T1H : STATE_MW1T1H;
		end



		STATE_MR1T3H: begin											// MR(3) Read byte into A
		   `CUR_A			<= DATA_IN;
		end

		STATE_MR1T3L: begin											// OR
			FSM_LAST_M		= TRUE;
		end



		STATE_MW1T1L: begin											// MW(3) Write byte in A
		   DATA_OUT			<=`CUR_A;
		end

		STATE_MW1T3L: begin											// Instruction complete
			FSM_LAST_M		= TRUE;
		end

		endcase
	end

	PLA_LDARIA: begin												// M1(5) LD I/R,A - LD A,I/R

		case(FSM_STATE)

		STATE_M1T4H: begin

			case(OPCODE_REG[4:3])
				2'b00: `REG_I	<= `CUR_A;
				2'b01: `CUR_A	<= `REG_I;
				2'b10: `REG_R	<= `CUR_A;
				2'b11: `CUR_A	<= `REG_R;
			endcase
		end

		STATE_M1T4L: begin											// Extra cycle to set P
			FSM_NEXT_STATE.T	<= STATE_T5H;
		end

		STATE_M1T5L: begin
		   `CUR_F[FLAG_P]  <= IFF2;
			FSM_LAST_M		= TRUE;									//	Complete
		end

		endcase
	end

	////////////////////////////////////////////////////////////////////////////
	// 16-Bit load group

	PLA_LDRR_NN: begin												// M1(4) LD rr,nn [BC/DE/HL/IX/IY/SP]

		case(FSM_STATE)

		STATE_M1T4L: begin							 				// Begin read cycle for immediate low byte
			FSM_NEXT_STATE	<= STATE_MR1T1H;
		end



		STATE_MR1T1H: begin											// MR(3)
			ADDRESS_BUS		<=`REG_PC;								// PC to address bus
			INC_DIR			<= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3H: begin											// MR(3) Read low byte
			ADDRESS_BUS		<= INC_OUT;
		   `REG_Z			<= DATA_IN;
		end

		STATE_MR1T3L: begin											// Prepare to read high byte
			FSM_NEXT_STATE	<= STATE_MR2T1H;
		end



		STATE_MR2T1H: begin											// MR(3) Read high byte
			CPU_REG_NUM		<= OPCODE_REG[6:4];						// 16 bit reg set 0 - BC-SP (NB bit 6 always 0)
		end

		STATE_MR2T3H: begin											// Update PC and write to reg
		   `REG_PC				 <= INC_OUT;
		   	REG.R16[REG16_INDEX] <= { DATA_IN, `REG_Z };			// Byte read is high, temp is low
		end

		STATE_MR2T3L: begin											// Instruction complete
			FSM_LAST_M		= TRUE;
		end

		endcase
	end

	PLA_LDHL_MM,													// M1(4) LD rr,(nn)/(nn),rr [BC/DE/HL/IX/IY/SP]
	PLA_LDRR_MM: begin												

		case(FSM_STATE)

		STATE_M1T4L: begin							 				// Begin read cycle for immediate low byte
			FSM_NEXT_STATE	<= STATE_MR1T1H;
		end



		STATE_MR1T1H: begin											// MR(3) Read immediate low byte
			ADDRESS_BUS		<=`REG_PC;								// PC to address bus
			INC_DIR			<= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3H: begin
			ADDRESS_BUS		<= INC_OUT;
		   `REG_Z			<= DATA_IN;								// Read low byte to temp register
		end

		STATE_MR1T3L: begin											// Prepare to read high byte
			FSM_NEXT_STATE	<= STATE_MR2T1H;
		end



		STATE_MR2T3H: begin											// MR(3) Read high byte to temp reg
		   `REG_PC			<= INC_OUT;
		   `REG_W			<= DATA_IN;
		end

		STATE_MR2T3L: begin											// Now read/write depending on opcode
			ADDRESS_BUS		<=`REG_WZ;								// Temp reg holds the address
			CPU_REG_NUM		<= { 1'b0, OPCODE_REG[5:4] };			// Start decode - 16 bit reg set 0 (BC/DE/HL/SP)
			FSM_NEXT_STATE	<= OPCODE_REG[3] ? STATE_MR3T1H : STATE_MW1T1H;
		end



		STATE_MR3T3H: begin											// MR(3) Read low byte to temp register
		   `REG_Z			<= DATA_IN;
		end

		STATE_MR3T3L: begin											// Prepare to read high byte
			FSM_NEXT_STATE	<= STATE_MR4T1H;
		end



		STATE_MR4T1H: begin
			ADDRESS_BUS		<= INC_OUT;								// Address to address bus
		end

		STATE_MR4T3H: begin											// MR(3) DATA_IN is high, temp is low		
		   	REG.R16[REG16_INDEX] <= { DATA_IN, `REG_Z };
		end

		STATE_MR4T3L: begin											// Instruction complete
			FSM_LAST_M		= TRUE;
		end



		STATE_MW1T1H: begin											// MW(3) Write low byte
		  `REG_WZ			<= REG.R16[REG16_INDEX];				// Temp reg holds the value to write
		end

		STATE_MW1T1L: begin
		   DATA_OUT			<=`REG_Z;
		end

		STATE_MW1T3L: begin											// Prepare to write high byte
			FSM_NEXT_STATE	<= STATE_MW2T1H;
		end



		STATE_MW2T1H: begin											// MW(3) Write high byte
			ADDRESS_BUS		<= INC_OUT;
			DATA_OUT		<=`REG_W;
		end

		STATE_MW2T3L: begin											// Instruction complete
			FSM_LAST_M		= TRUE;
		end

		endcase
	end

	PLA_LDSP_HL: begin												// M1(6) LD SP,HL

		case(FSM_STATE)

		STATE_M1T4L: FSM_NEXT_STATE.T <= STATE_T5H;					// Insert 2 extra cycles

		STATE_M1T5L: FSM_NEXT_STATE.T <= STATE_T6H;

		STATE_M1T6L: begin
		   `REG_SP		<= `CUR_HL;
			FSM_LAST_M	 = TRUE;
		end

		endcase
	end
	
	PLA_POPUSH: begin												// M1(4/5) POP rr(bit2=0)/PUSH rr(bit2=1) [BC/DE/HL/IX/IY/AF]

		case(FSM_STATE)

			STATE_M1T4L: begin
				ADDRESS_BUS		<=`REG_SP;							// Stack pointer to address bus & incrementer
				INC_BITS		<= TRUE;							// 16 bit
				CPU_REG_NUM <= { 1'b1, OPCODE_REG[5:4] };			// Reg 16 bit set 1 (BC/DE/HL/IX/IY/AF)
				FSM_NEXT_STATE <= OPCODE_REG[2] ? STATE_M1T5H : STATE_MR1T1H;
			end

			STATE_M1T5L: begin
				INC_DIR			<= FALSE;							// Set incrementer to sub
				FSM_NEXT_STATE	<= STATE_MW1T1H;					// PUSH Takes an extra cycle for some reason
			end



			STATE_MR1T1H: begin										// MR(3) This is the POP cycle
				INC_DIR		<= TRUE;								// Set incrementer to add
			end

			STATE_MR1T3H: begin
			   `REG_Z		<= DATA_IN;								// Read low byte to temp reg
			end

			STATE_MR1T3L: begin
				ADDRESS_BUS	<= INC_OUT;								// SP + 1
				FSM_NEXT_STATE	<= STATE_MR2T1H;
			end



			STATE_MR2T3H: begin										// MR(3) Read high byte
			   `REG_W	<= DATA_IN;
			   `REG_SP	<= INC_OUT;									// SP + 2
			end

			STATE_MR2T3L: begin										// Set register value
				REG.R16[REG16_INDEX] <= `REG_WZ;
				FSM_LAST_M	= TRUE;
			end



			STATE_MW1T1H: begin										// MW(3) This is the PUSH cycle
			  `REG_WZ		<= REG.R16[REG16_INDEX];				// Value to write to temp reg
			end

			STATE_MW1T1L: begin
			   DATA_OUT		<=`REG_W;								// Write high byte
			   ADDRESS_BUS	<= INC_OUT;								// SP - 1 NB BEFORE Write
			end

			STATE_MW1T3L: begin
				FSM_NEXT_STATE	<= STATE_MW2T1H;
			end



			STATE_MW2T1H: begin										// MW(3) Write low byte
			   DATA_OUT		<=`REG_Z;
			   ADDRESS_BUS	<= INC_OUT;								// SP - 1
			end

			STATE_MW2T3H: begin
			   `REG_SP		<= ADDRESS_BUS;							// Set stack pointer
			end

			STATE_MW2T3L: begin
				FSM_LAST_M		= TRUE;
			end

		endcase
	end

	////////////////////////////////////////////////////////////////////////////
	// Exchange, block transfer and search group

	PLA_EXX: begin													// M1(4) EXX
		if (FSM_STATE == STATE_M1T4L) begin							// Invert EXX
			EXX			<= ~EXX;
			FSM_LAST_M	 = TRUE;
		end
	end

	PLA_EX_AFAF: begin												// M1(4) EX AF,AF'
		if (FSM_STATE == STATE_M1T4L) begin							// Invert EXA
			EXA			<= ~EXA;
			FSM_LAST_M	 = TRUE;
		end
	end

	PLA_EX_DEHL: begin												// M1(4) EX DE,HL
		if (FSM_STATE == STATE_M1T4L) begin
		   `CUR_HL <= `CUR_DE;										// This one swaps the actual values
		   `CUR_DE <= `CUR_HL;
			FSM_LAST_M	= TRUE;
		end
	end

	PLA_EX_SPHL: begin												// M1(4) EX (SP),HL/IX/IY

		case(FSM_STATE)
		
		STATE_M1T4L: begin											// Begin unstack low byte
			FSM_NEXT_STATE <= STATE_MR1T1H;
		end



		STATE_MR1T1H: begin											// MR(3)
			ADDRESS_BUS		<=`REG_SP;								// SP to address bus
			INC_DIR			<= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3H: begin											// Update address save low byte to temp register
		   `REG_Z			<= DATA_IN;
		end

		STATE_MR1T3L: begin											// Prepare to read high byte
			ADDRESS_BUS		<= INC_OUT;								// SP + 1
			FSM_NEXT_STATE	<= STATE_MR2T1H;
		end



		STATE_MR2T3H: begin											// MR(4) High byte to temp register
		   `REG_W			<= DATA_IN;
		end

		STATE_MR2T3L: FSM_NEXT_STATE.T <= STATE_T4H;				// Extra cycle to do the exchange

		STATE_MR2T4L: begin
		   `CUR_HL			<=`REG_WZ;								// The actual swap
		   `REG_WZ			<=`CUR_HL;
			FSM_NEXT_STATE	<= STATE_MW1T1H;					
		end



		STATE_MW1T1L: begin											// MW(3) Write back value
			DATA_OUT		<=`REG_W;								// High byte first
			INC_DIR			<= FALSE;								// Set incrementer to sub 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MW1T3L: begin	
			FSM_NEXT_STATE	<= STATE_MW2T1H;
		end



		STATE_MW2T1H: begin											// MW(5) ?
			ADDRESS_BUS		<= INC_OUT;								// This is now the original SP
			DATA_OUT		<=`REG_Z;								// Write the low byte
		end

		STATE_MW2T3L: FSM_NEXT_STATE.T <= STATE_T4H;				// 2 extra cycles - timing

		STATE_MW2T4L: FSM_NEXT_STATE.T <= STATE_T5H;

		STATE_MW2T5L: begin											// Instruction complete
			FSM_LAST_M		= TRUE;
		end

		endcase
	end

	PLA_LDDIR:begin													// M1(4) LDI/LDIR/LDD/LDDR

		case(FSM_STATE)

			STATE_M1T4L: begin										// Begin a read cycle for (HL)
				INC_DIR			<= ~OPCODE_REG[3];					// Set incrementer to add/sub for LDI/LDD
				INC_BITS		<= TRUE;
				FSM_NEXT_STATE	<= STATE_MR1T1H;
			end



			STATE_MR1T1H: begin										// MR(3)
				ADDRESS_BUS		<= `CUR_HL;							// HL to address bus
			end

			STATE_MR1T3L: begin										// Now begin the write cycle for (DE)
				DATA_OUT	<= DATA_IN;								// Data to write
			   `CUR_HL		<= INC_OUT;								// Update HL
				FSM_NEXT_STATE	<= STATE_MW1T1H;
			end



			STATE_MW1T1H: begin										// MW(5)
				ADDRESS_BUS		<= `CUR_DE;							// DE to address bus
			end

			STATE_MW1T3L:begin
			   `CUR_DE	<= INC_OUT;
				FSM_NEXT_STATE.T	<= STATE_T4H;					// Use a couple of extra cycles
			end

			STATE_MW1T4L:begin
			   `CUR_F[FLAG_P]	<= `CUR_BC != 1;					// Set parity/overflow if BC will become 0
				INC_DIR			<= FALSE;							// Set incrementer to sub for BC count
			   	ADDRESS_BUS		 <= `CUR_BC;						// Update BC
				FSM_NEXT_STATE.T <= STATE_T5H;	
			end

			STATE_MW1T5L: begin
			   `CUR_BC				<= INC_OUT;						// Update BC count

				if (OPCODE_REG[4] & `CUR_F[FLAG_P])					// If we are doing a REPEAT, move on to next cycle
					FSM_NEXT_STATE	<= STATE_GN1T1H;
				else
					FSM_LAST_M		 = TRUE;						// Otherwise, indicate instruction complete
			end



			STATE_GN1T1L: begin
				ADDRESS_BUS		 <= `REG_PC;						// Step back and do the instruction again
				FSM_NEXT_STATE.T <= STATE_T2H;
			end

			STATE_GN1T2L: begin
				ADDRESS_BUS		 <= INC_OUT;						// PC - 1
				FSM_NEXT_STATE.T <= STATE_T3H;
			end

			STATE_GN1T3L: begin
			   `REG_PC			 <= INC_OUT;						// PC - 2
				FSM_NEXT_STATE.T <= STATE_T4H;
			end 

			STATE_GN1T4L: FSM_NEXT_STATE.T <= STATE_T5H;

			STATE_GN1T5L: begin
				FSM_LAST_M		= TRUE;								// Instruction complete
			end

		endcase
	end

	PLA_CPDIR: begin												// M1(4) CPI/CPIR/CPD/CPDR

		case(FSM_STATE)

			STATE_M1T4L: begin										// Begin a read cycle for (HL)
				INC_DIR			<= ~OPCODE_REG[3];					// Set incrementer to add/sub for CPI/CPD
				INC_BITS		<= TRUE;							// 16 bits
				FSM_NEXT_STATE	<= STATE_MR1T1H;
			end



			STATE_MR1T1H: begin										// MR(3)
				ADDRESS_BUS		<= `CUR_HL;							// HL to address bus and INCREMENTER
			end

			STATE_MR1T3L: begin										// Now begin the comparison cycle for A
				ALU_OP2    <= DATA_IN;								// Data to ALU for comparison
			   `CUR_HL		<= INC_OUT;								// Update HL
				FSM_NEXT_STATE	<= STATE_GN1T1H;
			end



			STATE_GN1T1H:begin										// MG(5)
				ALU_OPCODE		<= ALU_CP;							// Intialize ALU for Compare
				ALU_OP1			<= `CUR_A;							// Compare with A
				ALU_INFLAGS		<= `CUR_F;
			end

			STATE_GN1T1L:begin
			   `CUR_F[7:1]		 <= ALU_OUTFLAGS[7:1];				// Set flags except C
				FSM_NEXT_STATE.T <= STATE_T2H;	
			end

			STATE_GN1T2L: begin
			   `CUR_F[FLAG_P]	 <= `CUR_BC != 1;					// Set parity/overflow if BC will become 0
				INC_DIR			 <= FALSE;							// Set incrementer to sub for BC count
				FSM_NEXT_STATE.T <= STATE_T3H;
			end

			STATE_GN1T3L: FSM_NEXT_STATE.T  <= STATE_T4H;

			STATE_GN1T4L: begin
			   	ADDRESS_BUS		 <= `CUR_BC;						// BC to address bus for INCREMENTER
				FSM_NEXT_STATE.T <= STATE_T5H;
			end

			STATE_GN1T5L:begin										// If we are doing a REPEAT, move on to next cycle
			   `CUR_BC			<= INC_OUT;							// Update BC - 1

				if (OPCODE_REG[4] & `CUR_F[FLAG_P] & ~`CUR_F[FLAG_Z]) 
					FSM_NEXT_STATE	<= STATE_GN2T1H;
				else
					FSM_LAST_M		 = TRUE;						// Indicate instruction complete
			end



			STATE_GN2T1H: begin										// MG(5) for repeat
				ADDRESS_BUS		<= `REG_PC;							// Step back and do the instruction again
			end

			STATE_GN2T1L: begin
				ADDRESS_BUS		 <= INC_OUT;						// PC - 1
				FSM_NEXT_STATE.T <= STATE_T2H;
			end

			STATE_GN2T2L: begin
			   `REG_PC			 <= INC_OUT;						// PC - 2
				FSM_NEXT_STATE.T <= STATE_T3H;
			end

			STATE_GN2T3L: FSM_NEXT_STATE.T	<= STATE_T4H;			// Timing

			STATE_GN2T4L: FSM_NEXT_STATE.T	<= STATE_T5H;

			STATE_GN2T5L: begin
				FSM_LAST_M		= TRUE;								// Instruction complete
			end

		endcase
	end

	////////////////////////////////////////////////////////////////////////////
	// 8-Bit arithmetic group

	PLA_ARI_HXY: begin												// M1(4) ADD/ADC/SUB/SBC/AND/XOR/OR/CP (HL/IX+n/IY+n)
		
		case(FSM_STATE)
		
		STATE_M1T4L: begin							 				// Base address to WZ
		   `REG_WZ			<= `CUR_HL;
			FSM_NEXT_STATE	<= (IX|IY) ? STATE_MR1T1H : STATE_MR2T1H;
		end



		STATE_MR1T1H: begin											// MR(3) PC to address bus to read displacement
			ADDRESS_BUS		<=`REG_PC;
			INC_DIR			<= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3L: begin
		   `REG_PC			<= INC_OUT;								// Add (sign extended) displacement to base
			ALU_OP2			<= DATA_IN;								// Pick up displacement byte
			FSM_NEXT_STATE	<= STATE_GN1T1H;						// Now start a new cycle for calculation
		end



		STATE_GN1T1H: begin											// MG(5) For displacement and timing purposes
			ALU_OPCODE		<= ALU_ADC;								// Prepare to add displacement
			ALU_OP1			<=`REG_Z;								// To temp reg
			ALU_INFLAGS		<= 8'd0;								// Clear carry
		end

		STATE_GN1T1L: begin
		   `REG_Z			 <= ALU_RESULT;							// Low byte result to Z
			FSM_NEXT_STATE.T <= STATE_T2H;
		end

		STATE_GN1T2H: begin
			ALU_OP1			<=`REG_W;
			ALU_OP2			<= {8{ ALU_OP2[7] }};					// This is 255 or 0 depending on the sign of OP2
			ALU_INFLAGS		<= ALU_OUTFLAGS;						// Also need the flags for any carry
		end

		STATE_GN1T2L: begin
		   `REG_W			 <= ALU_RESULT;							// High byte result to W - Ignore flags
			FSM_NEXT_STATE.T <= STATE_T3H;
		end

		STATE_GN1T3L: FSM_NEXT_STATE.T	<= STATE_T4H;				// Timing

		STATE_GN1T4L: FSM_NEXT_STATE.T	<= STATE_T5H;

		STATE_GN1T5L: FSM_NEXT_STATE	<= STATE_MR2T1H;



		STATE_MR2T1H: begin
			ADDRESS_BUS		<=`REG_WZ;								// MR(3) Read address to bus
		end

		STATE_MR2T3H: begin							 				// Initialize ALU
			ALU_OPCODE  <= { 2'b0, OPCODE_REG[5:3] };
			ALU_OP1		<=`CUR_A;
			ALU_INFLAGS	<=`CUR_F;
			ALU_OP2		<= DATA_IN;
		end

		STATE_MR2T3L: begin											// Instruction complete
		   `CUR_A			<= ALU_RESULT;							// Save result and flags
		   `CUR_F			<= ALU_OUTFLAGS;
			FSM_LAST_M		= TRUE;
		end

		endcase
	end

	PLA_ARI_N: begin												// M1(4) ADD/ADC/SUB/SBC/AND/XOR/OR/CP n
		
		case(FSM_STATE)

		STATE_M1T4L: begin											// Begin read cycle for immediate value
			FSM_NEXT_STATE	<= STATE_MR1T1H;
		end



		STATE_MR1T1H: begin											// MR(3) PC to address bus
			ADDRESS_BUS		<=`REG_PC;
			INC_DIR			<= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3H: begin											// Update PC and initialize ALU
		   `REG_PC			<= INC_OUT;
			ALU_OPCODE  	<= { 2'b0, OPCODE_REG[5:3] };
			ALU_OP1		<=`CUR_A;
			ALU_INFLAGS	<=`CUR_F;
			ALU_OP2		<= DATA_IN;
		end

		STATE_MR1T3L: begin											// Store result and flags back in AF/AF'
		   `CUR_A			<= ALU_RESULT;
		   `CUR_F			<= ALU_OUTFLAGS;
			FSM_LAST_M		= TRUE;									// Instruction complete
		end

		endcase
	end

	PLA_ARI_R: begin												// M1(4) ADD/ADC/SUB/SBC/AND/XOR/OR/CP r

		case(FSM_STATE)

		STATE_M1T3L: begin
			CPU_REG_NUM		<= OPCODE_REG[2:0];
		end

        STATE_M1T4H: begin
			ALU_OPCODE  <= { 2'b0, OPCODE_REG[5:3] };				// Initialize ALU
			ALU_OP1	 <=`CUR_A;
			ALU_INFLAGS <=`CUR_F;
			ALU_OP2	 <= REG.R8[REG8_INDEX];
		end

		STATE_M1T4L: begin											// Store result and flags back in AF
		   `CUR_A		<= ALU_RESULT;
		   `CUR_F		<= ALU_OUTFLAGS;
			FSM_LAST_M	 = TRUE;									// Instruction complete
		end

		endcase
	end

	PLA_IDC_HXY: begin												// M1(4) INC/DEC (HL/IX+n/IY+n)
		case(FSM_STATE)
		
		STATE_M1T4L: begin											// Base address to WZ
		   `REG_WZ			<= `CUR_HL;
			FSM_NEXT_STATE	<= (IX|IY) ? STATE_MR1T1H : STATE_MR2T1H;
		end



		STATE_MR1T1H: begin											// MR(3) Read displacement
			ADDRESS_BUS		<=`REG_PC;
			INC_DIR			<= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3L: begin
		   `REG_PC			<= INC_OUT;								// Move past displacement
			ALU_OP2			<= DATA_IN;								// Write it directly to the ALU
			FSM_NEXT_STATE	<= STATE_GN1T1H;						// Now start a new cycle for calculation
		end



		STATE_GN1T1H: begin											// MG(5) For displacement and timing purposes
			ALU_OPCODE		<= ALU_ADC;								// Prepare to add displacement
			ALU_OP1			<=`REG_Z;								// To temp reg
			ALU_INFLAGS		<= 8'd0;								// Clear carry
		end

		STATE_GN1T1L: begin
		   `REG_Z			 <= ALU_RESULT;							// Low byte result to Z
			FSM_NEXT_STATE.T <= STATE_T2H;
		end

		STATE_GN1T2H: begin
			ALU_OP1			<=`REG_W;
			ALU_OP2			<= {8{ ALU_OP2[7] }};					// This is 255 or 0 depending on the sign of OP2
			ALU_INFLAGS		<= ALU_OUTFLAGS;						// Also need the flags for any carry
		end

		STATE_GN1T2L: begin
		   `REG_W			 <= ALU_RESULT;							// High byte result to W - Ignore flags
			FSM_NEXT_STATE.T <= STATE_T3H;
		end

		STATE_GN1T3L: FSM_NEXT_STATE.T	<= STATE_T4H;				// Timing

		STATE_GN1T4L: FSM_NEXT_STATE.T	<= STATE_T5H;

		STATE_GN1T5L: FSM_NEXT_STATE	<= STATE_MR2T1H;



		STATE_MR2T1H: begin											// MR(4)
			ADDRESS_BUS		<=`REG_WZ;					 			// Read address to bus
		end

		STATE_MR2T3H: begin								 			// Initialize ALU
			ALU_OPCODE		<= OPCODE_REG[0] ? ALU_SUB : ALU_ADD;
			ALU_OP1			<= DATA_IN;
			ALU_INFLAGS		<=`CUR_F;
			ALU_OP2			<= 8'h01;								// Value to add/sub
		end

		STATE_MR2T3L: begin											// Now write back the result
			DATA_OUT		<= ALU_RESULT;
		   `CUR_F[7:1]		<= ALU_OUTFLAGS[7:1];					// Set flags except C
			FSM_NEXT_STATE	<= STATE_MW1T1H;
		end



		STATE_MW1T3L: begin											// MW(3) Write back result
			FSM_LAST_M = TRUE;
		end

		endcase
	end

	PLA_IDC_R: begin												// M1(4) INC/DEC r

		case(FSM_STATE)

		STATE_M1T3L: begin											// Decode register
			CPU_REG_NUM		<= OPCODE_REG[5:3];
		end
		
		STATE_M1T4H: begin											// Read the base address
			ALU_OPCODE		<= OPCODE_REG[0] ? ALU_SUB : ALU_ADD;
			ALU_OP1			<= REG.R8[REG8_INDEX];
			ALU_INFLAGS		<=`CUR_F;
			ALU_OP2			<= 8'h01;								// Value to add/sub
		end

		STATE_M1T4L: begin											// Now write back the result
			REG.R8[REG8_INDEX]	<= ALU_RESULT;
		   `CUR_F[7:1]			<= ALU_OUTFLAGS[7:1];				// Set flags except C
			FSM_LAST_M			 = TRUE;
		end

		endcase
	end

	////////////////////////////////////////////////////////////////////////////
	// General purpose group

	PLA_DI: begin													// M1(4) DI
		if (FSM_STATE == STATE_M1T4L) begin
			IFF1		<= FALSE;									// Reset interrupt enable FFs
			IFF2		<= FALSE;
			FSM_LAST_M	 = TRUE;
		end
	end

	PLA_EI: begin													// M1(4) EI
		if (FSM_STATE == STATE_M1T4L) begin
			IFF1			<= TRUE;								// Set interrupt enable FFs
			IFF2			<= TRUE;
			FSM_NEXT_STATE	<= STATE_M1T1H;							// Do not execute LAST_M, just start the next instruction
		end
	end

	PLA_CCF: begin													// M1(4) CCF
		if (FSM_STATE == STATE_M1T4L) begin
		   `CUR_F[FLAG_C]	<= ~`CUR_F[FLAG_C];						// Invert the carry
			FSM_LAST_M		 = TRUE;
		end
	end

	PLA_SCF: begin													// M1(4) SCF
		if (FSM_STATE == STATE_M1T4L) begin
		   `CUR_F[FLAG_C]	<= TRUE;								// Set the carry
			FSM_LAST_M		 = TRUE;
		end
	end

	PLA_CPL: begin													// M1(4) CPL
		if (FSM_STATE == STATE_M1T4L) begin
		   `CUR_A			<= ~`CUR_A;								// Invert A
		   `CUR_F[FLAG_H]	<= TRUE;								// Set H and N
		   `CUR_F[FLAG_N]	<= TRUE;
			FSM_LAST_M		 = TRUE;
		end
	end

	PLA_DAA: begin													// M1(4) DAA

        case(FSM_STATE)
		
		STATE_M1T3H: begin
			ALU_OPCODE	<= ALU_ADD;									// Prepare to add $06 to A
			ALU_OP1		<= `CUR_A;
			ALU_OP2		<= 8'h06;
		end

		STATE_M1T3L: begin
            if (`CUR_F[FLAG_H] || `CUR_A[3:0] > 4'd9) begin
               `CUR_A			<= ALU_RESULT;						// Save result if required
               `CUR_F[FLAG_H]	<= TRUE;
            end
		end

		STATE_M1T4H: begin
 		   	ALU_OP1		<= `CUR_A;
			ALU_OP2		<= 8'h60;									// Prepare to add $60
		end

		STATE_M1T4L: begin

           	if (`CUR_F[FLAG_C] || `CUR_A[7:4] > 4'd9) begin			// Test upper nibble of A
               `CUR_A			<= ALU_RESULT;
               `CUR_F[FLAG_C]	<= TRUE;
            end

 			FSM_LAST_M		 = TRUE;
		end
		
		endcase
	end

	PLA_IM: begin													// M1(4) IM n
		if (FSM_STATE == STATE_M1T4L) begin
			INT_MODE	<= OPCODE_REG[4:3];							// This is 00-IM 0, 10-IM1, 11-IM2
			FSM_LAST_M	 = TRUE;
		end
	end

	PLA_NEG: begin													// M1(4) NEG

		case(FSM_STATE)
		
		STATE_M1T4H: begin
		   ALU_OPCODE		<= ALU_ADD;								// NEG is CPL then +1
		   ALU_OP1			<=~`CUR_A;								// CPL A
		   ALU_OP2			<= 8'd1;
		   ALU_INFLAGS		<= `CUR_F;
		end

		STATE_M1T4L: begin
		   `CUR_A			<= ALU_RESULT;
		   `CUR_F			<= ALU_OUTFLAGS | 2;					// Flags + n set
			FSM_LAST_M		 = TRUE;
		end

		endcase
	end

	////////////////////////////////////////////////////////////////////////////
	// 16-Bit arithmetic group

	PLA_ADHL_RR: begin												// M1(4) ADD HL,rr

		case(FSM_STATE)

		STATE_M1T4L: begin
			FSM_NEXT_STATE	<= STATE_GN1T1H;						// Start general purpose cycle for addition
		end



		STATE_GN1T1L: begin											// MG(4)
			CPU_REG_NUM		 <= { 1'b0, OPCODE_REG[5:4] };			// Decode reg set 0 - BC/DE/HL/IX/IY/SP
			FSM_NEXT_STATE.T <= STATE_T2H;
		end

		STATE_GN1T2L: begin
			`REG_WZ			 <= REG.R16[REG16_INDEX];				// Value to add
			FSM_NEXT_STATE.T <= STATE_T3H;
		end

		STATE_GN1T3L: begin
			ALU_OPCODE		 <= ALU_ADC;							//Add low bytes
			ALU_OP1			 <= `CUR_L;
			ALU_OP2			 <= `REG_Z;
			ALU_INFLAGS		 <= 8'd0;
			FSM_NEXT_STATE.T <= STATE_T4H;
		end

		STATE_GN1T4L: begin
			`CUR_L			<= ALU_RESULT;							// Save low byte result
			FSM_NEXT_STATE	<= STATE_GN2T1H;
		end



		STATE_GN2T1L: begin											// MG(3)
			ALU_OP1			 <= `CUR_H;
			ALU_OP2			 <= `REG_W;
			ALU_INFLAGS		 <= ALU_OUTFLAGS;
			FSM_NEXT_STATE.T <= STATE_T2H;
		end

		STATE_GN2T2L: begin
		   `CUR_H			 <= ALU_RESULT;
		   `CUR_F[FLAG_H]	 <= ALU_OUTFLAGS[FLAG_H];				// Only these flags affected
		   `CUR_F[FLAG_N]	 <= ALU_OUTFLAGS[FLAG_N];
		   `CUR_F[FLAG_C]	 <= ALU_OUTFLAGS[FLAG_C];
			FSM_NEXT_STATE.T <= STATE_T3H;
		end

		STATE_GN2T3L: begin
			FSM_LAST_M		 = TRUE;
		end

		endcase
	end

	PLA_ASHL_RR: begin												// M1(4) ADC HL,rr (bit3=0)/SBC HL,rr (bit3=1)
		case(FSM_STATE)

		STATE_M1T4L: begin
			FSM_NEXT_STATE	<= STATE_GN1T1H;						// Start general purpose cycle for addition
		end



		STATE_GN1T1L: begin											// MG(4)
			CPU_REG_NUM		 <= { 1'b0, OPCODE_REG[5:4] };			// Decode reg set 0 - BC/DE/HL/IX/IY/SP
			FSM_NEXT_STATE.T <= STATE_T2H;
		end

		STATE_GN1T2L: begin
			`REG_WZ			 <= REG.R16[REG16_INDEX];				// Save value in temp reg
			FSM_NEXT_STATE.T <= STATE_T3H;
		end

		STATE_GN1T3L: begin
			ALU_OPCODE		 <= OPCODE_REG[3] ? ALU_ADC : ALU_SBC;
			ALU_OP1			 <= `CUR_L;
			ALU_OP2			 <= `REG_Z;
			ALU_INFLAGS		 <= `CUR_F;
			FSM_NEXT_STATE.T <= STATE_T4H;
		end

		STATE_GN1T4L: begin
			`CUR_L			<= ALU_RESULT;							// Save low byte result
			FSM_NEXT_STATE	<= STATE_GN2T1H;
		end



		STATE_GN2T1L: begin											// MG(3)
			ALU_OP1			 <= `CUR_H;								// Now the high byte - same opcode
			ALU_OP2			 <= `REG_W;
			ALU_INFLAGS		 <= ALU_OUTFLAGS;
			FSM_NEXT_STATE.T <= STATE_T2H;
		end

		STATE_GN2T2L: begin
		   `CUR_H			 <= ALU_RESULT;
		   `CUR_F			 <= { ALU_OUTFLAGS[7], ALU_OUTFLAGS[6] & ALU_INFLAGS[6], ALU_OUTFLAGS[5:0] };
			FSM_NEXT_STATE.T <= STATE_T3H;
		end

		STATE_GN2T3L: begin
			FSM_LAST_M	= TRUE;
		end

		endcase
		
		end

	PLA_IDC_RR: begin												// M1(6) INC (bit3=0)/DEC (bit3=1) BC/DE/HL/IX/IY/SP

		case(FSM_STATE)

		STATE_M1T4L: begin											// This takes 6 T states
			CPU_REG_NUM		 <= { 1'b0, OPCODE_REG[5:4] };			// Decode reg set 0 (BC/DE/HL/IX/IY/SP)
			FSM_NEXT_STATE.T <= STATE_T5H;
		end

		STATE_M1T5L: begin											// As the Z80's incrementer is in use T1-T4
			ADDRESS_BUS		 <= REG.R16[REG16_INDEX];
			INC_DIR			 <= ~OPCODE_REG[3];						// Set incrementer add/sub for INC/DEC
			INC_BITS		 <= TRUE;
			FSM_NEXT_STATE.T <= STATE_T6H;
		end

		STATE_M1T6L: begin
			REG.R16[REG16_INDEX] <= INC_OUT;
			FSM_LAST_M			  = TRUE;
		end

		endcase
	end

	////////////////////////////////////////////////////////////////////////////
	// Jump group

	PLA_JP_HXY: begin												// M1(4) JP (HL/IX/IY)

		if (FSM_STATE == STATE_M1T4L) begin
		   `REG_PC	   <= `CUR_HL;
			FSM_LAST_M	= TRUE;
		end
	end

	PLA_JP_NN,														// M1(4) JP nn
	PLA_JPCC_NN: begin												// M1(4) JP cc,nn

		case(FSM_STATE)

		STATE_M1T4L: begin
			CC_INDEX		<= OPCODE_REG[5:3];						// Begin decoding CC
			CC_INFLAGS		<= `CUR_F;
			FSM_NEXT_STATE	<= STATE_MR1T1H;						// We need to pick up the 2 byte address
		end



		STATE_MR1T1H: begin											// MR(3) Read immediate low byte
			ADDRESS_BUS		<= `REG_PC;
			INC_DIR			<= TRUE;								// Set incrementer add
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3H: begin
		   `REG_Z			<= DATA_IN;								// Store in temp reg
			ADDRESS_BUS		<= INC_OUT;								// Update address
		end

		STATE_MR1T3L: begin
			FSM_NEXT_STATE	<= STATE_MR2T1H;						// Another read for the high byte
		end



		STATE_MR2T3H: begin											// MR(3) Temp reg now holds address
			`REG_W			<= DATA_IN;
			`REG_PC			<= INC_OUT;								// Update PC
		end

		STATE_MR2T3L: begin											// Take the jump : continue
			if (OPCODE_REG[0] | CC_RESULT) `REG_PC <= `REG_WZ;
			FSM_LAST_M		 = TRUE;
		end

		endcase
	end

	PLA_DJNZ_N: begin												// M1(5) DJNZ n

		case(FSM_STATE)

		STATE_M1T4L: begin
			FSM_NEXT_STATE.T <= STATE_T5H;							// We need to pick up the 1 byte displacement
		end

		STATE_M1T5H: begin											// Prepare for DEC B
			ALU_OPCODE	<= ALU_SUB;
			ALU_OP1		<= `CUR_B;									// Value of B reg
			ALU_OP2		<= 1;										// Subtract 1
		end

		STATE_M1T5L: begin
		   `CUR_B			<= ALU_RESULT;							// Result back to B
			FSM_NEXT_STATE	<= STATE_MR1T1H;						// We need to pick up the 1 byte displacement
		end



		STATE_MR1T1H: begin											// MR(3) Read the displacement
			ADDRESS_BUS		<= `REG_PC;
			INC_DIR			<= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3L: begin											// Take jump if NZ, do not save flags
		   `REG_PC			<= INC_OUT;								// Update PC
		   `REG_Z			<= DATA_IN;								// And read displacement into temp reg
			if (ALU_OUTFLAGS[FLAG_Z])
				FSM_LAST_M		 = TRUE;							// If Z then instruction is complete
			else
				FSM_NEXT_STATE	<= STATE_GN1T1H;					// Start a general cycle to do calculation
		end



		STATE_GN1T1H:begin											// MG(5) Add displacement to PC
			ALU_OPCODE		<= ALU_ADC;								// Initialize ALU for addition
			ALU_OP1			<=`REG_PCL;
			ALU_OP2			<=`REG_Z;
			ALU_INFLAGS		<= 8'd0;
		end

		STATE_GN1T1L: begin
		   `REG_PCL			 <= ALU_RESULT;							// Low byte result
			FSM_NEXT_STATE.T <= STATE_T2H;
		end

		STATE_GN1T2H: begin
			ALU_OP1			<=`REG_PCH;
			ALU_OP2			<= {8{ ALU_OP2[7] }};					// This is 255 or 0 depending on the sign of OP2
			ALU_INFLAGS		<= ALU_OUTFLAGS;						// Also need the flags for any carry
		end

		STATE_GN1T2L: begin
		   `REG_PCH			 <= ALU_RESULT;							// High byte result to W - Ignore flags
			FSM_NEXT_STATE.T <= STATE_T3H;
		end

		STATE_GN1T3L: FSM_NEXT_STATE.T <= STATE_T4H;

		STATE_GN1T4L: FSM_NEXT_STATE.T <= STATE_T5H;

		STATE_GN1T5L: begin
		   FSM_LAST_M		 = TRUE;
		end

		endcase
	end

	PLA_JR_N,														// M1(4) JR n
	PLA_JRCC_N: begin												// M1(4) JR cc,n

		case(FSM_STATE)

		STATE_M1T4L: begin
			CC_INDEX		<= { 1'b0, OPCODE_REG[4:3] };			// Begin decoding CC
			CC_INFLAGS		<= `CUR_F;
			FSM_NEXT_STATE	<= STATE_MR1T1H;						// We need to pick up the 1 byte displacement
		end



		STATE_MR1T1H: begin											// MR(3) Read data byte
			ADDRESS_BUS		<= `REG_PC;
			INC_DIR			<= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3H: begin
		   `REG_PC			<= INC_OUT;								// Update PC
		   `REG_Z 			<= DATA_IN;								// Save displacement in temp reg
		end

		STATE_MR1T3L: begin
			if (~OPCODE_REG[5] | CC_RESULT)							// If taking the jump
				FSM_NEXT_STATE	<= STATE_GN1T1H;					// Start a general cycle to do calculation
			else
			   FSM_LAST_M		 = TRUE;							// else instruction is complete
		end



		STATE_GN1T1H:begin											// MG(5) Add displacement to PC
			ALU_OPCODE		<= ALU_ADC;								// Initialize ALU for addition
			ALU_OP1			<=`REG_PCL;
			ALU_OP2			<=`REG_Z;
			ALU_INFLAGS		<= 8'd0;
		end

		STATE_GN1T1L: begin
		   `REG_PCL			 <= ALU_RESULT;							// Low byte result
			FSM_NEXT_STATE.T <= STATE_T2H;
		end

		STATE_GN1T2H: begin
			ALU_OP1			<=`REG_PCH;
			ALU_OP2			<= {8{ ALU_OP2[7] }};					// This is 255 or 0 depending on the sign of OP2
			ALU_INFLAGS		<= ALU_OUTFLAGS;						// Also need the flags for any carry
		end

		STATE_GN1T2L: begin
		   `REG_PCH			 <= ALU_RESULT;							// High byte result to W - Ignore flags
			FSM_NEXT_STATE.T <= STATE_T3H;
		end

		STATE_GN1T3L: FSM_NEXT_STATE.T <= STATE_T4H;

		STATE_GN1T4L: FSM_NEXT_STATE.T <= STATE_T5H;

		STATE_GN1T5L: begin
		   FSM_LAST_M		 = TRUE;
		end

		endcase
	end

	////////////////////////////////////////////////////////////////////////////
	// Call/Return group

	PLA_CALL_NN,													// M1(4) CALL nn
	PLA_CLCC_NN: begin												// M1(4) CALL cc,nn

		case(FSM_STATE)

		STATE_M1T4L: begin
			CC_INDEX		<= OPCODE_REG[5:3];						// Begin decoding CC
			CC_INFLAGS		<= `CUR_F;
			FSM_NEXT_STATE	<= STATE_MR1T1H;						// We need to pick up the 2 byte address
		end



		STATE_MR1T1H: begin											// MR(3) Read immediate low byte
			ADDRESS_BUS		<= `REG_PC;
			INC_DIR			<= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3H: begin
			`REG_Z			<= DATA_IN;								// Store in temp reg
		end

		STATE_MR1T3L: begin
			FSM_NEXT_STATE	<= STATE_MR2T1H;						// Another read for the high byte
		end



		STATE_MR2T1H: begin											// MR(3/4) Read immediate high byte
			ADDRESS_BUS		<= INC_OUT;
		end

		STATE_MR2T3H: begin											// Temp reg now holds address
			`REG_W			<= DATA_IN;
			`REG_PC			<= INC_OUT;
		end

		STATE_MR2T3L: begin											// Take jump, move on to stack return address
			if(OPCODE_REG[0] | CC_RESULT)
				FSM_NEXT_STATE.T <= STATE_T4H;						// One more cycle if taking jump for timing
			else
				FSM_LAST_M		 = TRUE;							// Or mark as complete
		end

		STATE_MR2T4L: begin
			ADDRESS_BUS		<= `REG_SP;								// Stack pointer to incrementer
			INC_DIR			<= FALSE;								// Set to SUB
			FSM_NEXT_STATE	<= STATE_MW1T1H;						// Now begin stacking the return address
		end



		STATE_MW1T1H: begin											// MW(3)
			ADDRESS_BUS		<= INC_OUT;								// Stack high byte
			DATA_OUT		<= `REG_PCH;
		end

		STATE_MW1T3L: begin											// Now write the high byte
			FSM_NEXT_STATE	<= STATE_MW2T1H;
		end		



		STATE_MW2T1H: begin											// MW(3)
			ADDRESS_BUS		<= INC_OUT;								// Stack low byte
			DATA_OUT		<= `REG_PCL;
		end

		STATE_MW2T3L: begin											// Now write the high byte
			`REG_SP			<= ADDRESS_BUS;
			`REG_PC			<= `REG_WZ;								// Take the jump
			FSM_LAST_M		 = TRUE;
		end		

		endcase
	end

	PLA_RET,														// M1(4) RET
	PLA_RET_CC,														// M1(4) RETN/RETI
	PLA_RET_NI: begin												// M1(5) RET cc

		case(FSM_STATE)

		STATE_M1T4L: begin											// If no condition, return immediately else start extra cycle
			FSM_NEXT_STATE <= OPCODE_REG[0] ? STATE_MR1T1H : STATE_M1T5H;
		end

		STATE_M1T5H: begin
			CC_INDEX		<= OPCODE_REG[5:3];						// Begin decoding CC
			CC_INFLAGS		<= `CUR_F;
		end

		STATE_M1T5L: begin
			if (OPCODE_REG[0] | CC_RESULT)							// If taking the return
				FSM_NEXT_STATE	<= STATE_MR1T1H;					// We need to pick up the 2 byte address
			else
				FSM_LAST_M		 = TRUE;							// else we're done
		end



		STATE_MR1T1H: begin											// MR(3) Read low byte
			ADDRESS_BUS		<=`REG_SP;
			INC_DIR			<= TRUE;								// Set incrementer to add 16 bits
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3H: begin
			`REG_PCL		<= DATA_IN;								// Save in temp reg
		end

		STATE_MR1T3L: begin
			FSM_NEXT_STATE	<= STATE_MR2T1H;						// Another read for the high byte
		end



		STATE_MR2T1H: begin											// MR(3)
			ADDRESS_BUS		<= INC_OUT;
		end

		STATE_MR2T3H: begin
			`REG_PCH		<= DATA_IN;								// Read high byte
			`REG_SP			<= INC_OUT;								// Stack pointer updated
		end

		STATE_MR2T3L: begin											// Now do return jump
			if (~OPCODE_REG[2:1] == 2'b01 ) IFF1 <= IFF2;			// Restore INT enable state for RETN		
			FSM_LAST_M		 = TRUE;
		end	

		endcase
	end

	PLA_RST_N: begin												// M1(5) RST n

		case(FSM_STATE)

		STATE_M1T4L: begin
			FSM_NEXT_STATE	<= STATE_M1T5H;							// Extra cycle to calc the address
		end

		STATE_M1T5L: begin
			`REG_WZ			<= { 10'b0, OPCODE_REG[5:3], 3'b0 };
			FSM_NEXT_STATE	<= STATE_MW1T1H;						// Now stack the return address
		end



		STATE_MW1T1H: begin											// MW(3)
			ADDRESS_BUS		<= `REG_SP - 16'd1;							// Stack high byte
			DATA_OUT		<= `REG_PCH;
		end

		STATE_MW1T3L: begin											// Now write the high byte
			FSM_NEXT_STATE	<= STATE_MW2T1H;
		end		



		STATE_MW2T1H: begin											// MW(3)
			ADDRESS_BUS		<= ADDRESS_BUS - 16'd1;						// Stack low byte
			DATA_OUT		<= `REG_PCL;
		end

		STATE_MW2T3L: begin											// Now write the high byte
		   `REG_SP			<= ADDRESS_BUS;							// Update SP
		   `REG_PC			<=`REG_WZ;								// Take the jump
			FSM_LAST_M		 = TRUE;
		end		

		endcase
	end

////////////////////////////////////////////////////////////////////////////
	// Shift/Rotate and BIT/SET/RES group

	PLA_RRLC_A: begin												// M1(4) RLCA/RLA/RRCA/RRA

		case(FSM_STATE)

		STATE_M1T4H: begin
			ALU_OPCODE		<= { 2'b01, OPCODE_REG[5:3] };			// Shift/rotate opcodes 01zzz
			ALU_OP1		<= `CUR_A;
			ALU_INFLAGS	<= `CUR_F;
		end
		
		STATE_M1T4L: begin
		   `CUR_A		<= ALU_RESULT;								// Store result and flags
		   `CUR_F[1:0]	<= ALU_OUTFLAGS[1:0];						// Set only N and C
			FSM_LAST_M	 = TRUE;
		end

		endcase		
	end

	PLA_SHR_HXY: begin												// M1(4/5) RLC/RL/RRC/RR/SLA/SRA/SLL/SRL (HL/IX+n/IY+n)

		case(FSM_STATE)

		STATE_M1T3L: begin
		   `REG_WZ				<= `CUR_HL;							// Base address to temp reg
		end
		
		STATE_M1T4H: begin
			if (IX|IY) begin
				ALU_OPCODE		<= ALU_ADC;							// Prepare to add displacement (already in OP2)
				ALU_OP1			<=`REG_Z;							// To temp reg
				ALU_INFLAGS		<= 8'd0;							// Clear carry
			end
		end

		STATE_M1T4L: begin
			if (IX|IY) begin
			   `REG_Z			 <= ALU_RESULT;						// Low byte result to Z
				FSM_NEXT_STATE.T <= STATE_T5H;						// Continue addition for (IX/IY)
			end else begin
				FSM_NEXT_STATE	 <= STATE_MR1T1H;					// Go to mem read for (HL)
			end
		end

		STATE_M1T5H: begin
			ALU_OP1				<=`REG_W;
			ALU_OP2				<= {8{ ALU_OP2[7] }};				// This is 255 or 0 depending on the sign of OP2
			ALU_INFLAGS			<= ALU_OUTFLAGS;					// Also need the flags for any carry
		end

		STATE_M1T5L: begin											// Extra cycle to add displacement
		   `REG_W				<= ALU_RESULT;						// High byte result to W - Ignore flags
			FSM_NEXT_STATE		<= STATE_MR1T1H;
		end



		STATE_MR1T1H: begin											// MR(4)
			ADDRESS_BUS			<= `REG_WZ;
		end

		STATE_MR1T3L: begin
			ALU_OP1			 <= DATA_IN;							// Byte read into DATA_IN
			ALU_OPCODE		 <= { 2'b01, OPCODE_REG[5:3] };
			ALU_INFLAGS		 <= `CUR_F;
			FSM_NEXT_STATE.T <= STATE_T4H;							// Extra cycle for timing
		end

		STATE_MR1T4L: begin
			FSM_NEXT_STATE	<= STATE_MW1T1H;						// Begin write back
		end



		STATE_MW1T1H: begin											// MW(3) ADDRESS_BUS still holds correct address
			DATA_OUT	<= ALU_RESULT;
		   `CUR_F		<= ALU_OUTFLAGS;
		end

		STATE_MW1T3L: begin
			FSM_LAST_M		 = TRUE;
		end

		endcase
	end

	PLA_BIT_HXY: begin												// M1(4/5) BIT n,(HL/IX+n/IY+n)

		case(FSM_STATE)

		STATE_M1T3L: begin
		   `REG_WZ				<= `CUR_HL;							// Base address to temp reg
		end
		
		STATE_M1T4H: begin
			if (IX|IY) begin
				ALU_OPCODE		<= ALU_ADC;							// Prepare to add displacement (already in OP2)
				ALU_OP1			<=`REG_Z;							// To temp reg
				ALU_INFLAGS		<= 8'd0;							// Clear carry
			end
		end

		STATE_M1T4L: begin
			if (IX|IY) begin
			   `REG_Z			 <= ALU_RESULT;						// Low byte result to Z
				FSM_NEXT_STATE.T <= STATE_T5H;						// Continue addition for (IX/IY)
			end else begin
				FSM_NEXT_STATE	<= STATE_MR1T1H;					// Go to mem read for (HL)
			end
		end

		STATE_M1T5H: begin
			ALU_OP1				<=`REG_W;
			ALU_OP2				<= {8{ ALU_OP2[7] }};				// This is 255 or 0 depending on the sign of OP2
			ALU_INFLAGS			<= ALU_OUTFLAGS;					// Also need the flags for any carry
		end

		STATE_M1T5L: begin											// Extra cycle to add displacement
		   `REG_W				<= ALU_RESULT;						// High byte result to W - Ignore flags
			FSM_NEXT_STATE		<= STATE_MR1T1H;
		end



		STATE_MR1T1H: begin											// MR(4)
			ADDRESS_BUS			<= `REG_WZ;
		end

		STATE_MR1T3L: begin
			`REG_Z			 <= DATA_IN;
			FSM_NEXT_STATE.T <= STATE_T4H;							// Extra cycle to set flag
		end
		
		STATE_MR1T4H: begin
			`CUR_F[FLAG_Z]	<= ~`REG_Z[OPCODE_REG[5:3]];			// Set Z flag
		end

		STATE_MR1T4L: begin
			FSM_LAST_M		 = TRUE;								// All done
		end

		endcase
	end

	PLA_SET_HXY,													// M1(4/5) SET n,(HL/IX+n/IY+n)
	PLA_RES_HXY: begin												// M1(4/5) RES n,(HL/IX+n/IY+n)

		case(FSM_STATE)

		STATE_M1T3L: begin
		   `REG_WZ				<= `CUR_HL;							// Base address to temp reg
		end
		
		STATE_M1T4H: begin
			if (IX|IY) begin
				ALU_OPCODE		<= ALU_ADC;							// Prepare to add displacement (already in OP2)
				ALU_OP1			<=`REG_Z;							// To temp reg
				ALU_INFLAGS		<= 8'd0;							// Clear carry
			end
		end

		STATE_M1T4L: begin
			if (IX|IY) begin
			   `REG_Z			 <= ALU_RESULT;						// Low byte result to Z
				FSM_NEXT_STATE.T <= STATE_T5H;						// Continue addition for (IX/IY)
			end else begin
				FSM_NEXT_STATE	 <= STATE_MR1T1H;					// Go to mem read for (HL)
			end
		end

		STATE_M1T5H: begin
			ALU_OP1				<=`REG_W;
			ALU_OP2				<= {8{ ALU_OP2[7] }};				// This is 255 or 0 depending on the sign of OP2
			ALU_INFLAGS			<= ALU_OUTFLAGS;					// Also need the flags for any carry
		end

		STATE_M1T5L: begin											// Extra cycle to add displacement
		   `REG_W				<= ALU_RESULT;						// High byte result to W - Ignore flags
			FSM_NEXT_STATE		<= STATE_MR1T1H;
		end



		STATE_MR1T1H: begin											// MR(4)
			ADDRESS_BUS			<= `REG_WZ;
		end

		STATE_MR1T3L: begin
			DATA_OUT		<= DATA_IN;								// Read byte then write back
			FSM_NEXT_STATE	<= STATE_MR1T4H;						// Extra cycle to set/res bit
		end

		STATE_MR1T4L: begin
			DATA_OUT[OPCODE_REG[5:3]] <= OPCODE_REG[6];				// Set/Clear the bit
			FSM_NEXT_STATE	<= STATE_MW1T1H;						// Write back value
		end



		STATE_MW1T3L: begin											// MW(3)
			FSM_LAST_M		 = TRUE;
		end
		
		endcase
	end

	PLA_SHR_R: begin												// RLC/RL/RRC/RR/SLA/SRA/SLL/SRL r

		case(FSM_STATE)

		STATE_M1T3L: begin
			CPU_REG_NUM	<= OPCODE_REG[2:0];							// Decode reg
		end

		STATE_M1T4H: begin
			ALU_OPCODE	<= { 2'b01, OPCODE_REG[5:3] };				// Shift/rotate opcodes 01zzz
			ALU_OP1		<= REG.R8[REG8_INDEX];
			ALU_INFLAGS	<= `CUR_F;
		end

		STATE_M1T4L: begin
			REG.R8[REG8_INDEX]	<= ALU_RESULT;						// Store result and flags
		   `CUR_F				<= ALU_OUTFLAGS;
			FSM_LAST_M			 = TRUE;
		end
		endcase
	end

	PLA_BIT_R: begin												// BIT n,r

		case(FSM_STATE)

		STATE_M1T3L: begin
			CPU_REG_NUM	<= OPCODE_REG[2:0];							// Decode reg
		end

		STATE_M1T4H: begin											// Set Z flag
		   `CUR_F[FLAG_Z] <= ~REG.R8[REG8_INDEX][OPCODE_REG[5:3]];
		end

		STATE_M1T4L: begin
			FSM_LAST_M			 = TRUE;
		end
		endcase
	end

	PLA_SET_R,														// SET n,r
	PLA_RES_R: begin												// RES n,r

		case(FSM_STATE)
		STATE_M1T3L: begin
			CPU_REG_NUM	<= OPCODE_REG[2:0];							// Decode reg
		end

		STATE_M1T4H: begin											// Set bit in reg
			REG.R8[REG8_INDEX][OPCODE_REG[5:3]] <= OPCODE_REG[6];
		end

		STATE_M1T4L: begin
			FSM_LAST_M			 = TRUE;
		end
		endcase
	end
	
	PLA_RLRD: begin													// M1(4) RLD/RRD

		case(FSM_STATE)
		
		STATE_M1T4L: begin
			FSM_NEXT_STATE	<= STATE_MR1T1H;						// Begin read cycle
		end



		STATE_MR1T1H: begin											// MR(3)
			ADDRESS_BUS		<= `CUR_HL;								// Read from HL
		end

		STATE_MR1T3L: begin											// Read to temp reg
			`REG_Z			<= DATA_IN;
			FSM_NEXT_STATE	<= STATE_GN1T1H;						// General cycle for manipulation
		end



		STATE_GN1T1H: begin											// MG(4)
			if (OPCODE_REG[3]) begin
			   `CUR_A[3:0] 		<= `REG_Z[7:4];						// RLD
				DATA_OUT[7:4]	<= `REG_Z[3:0];
				DATA_OUT[3:0]	<= `CUR_A[3:0];
			end else begin
			   `CUR_A[3:0] 		<= `REG_Z[3:0];						// RRD
				DATA_OUT[3:0]	<= `REG_Z[7:4];
				DATA_OUT[7:4]	<= `CUR_A[3:0];
			end
		end

		STATE_GN1T1L: begin	
			ALU_OPCODE		 <= ALU_FLG;							// Now use the ALU to set the flags
			ALU_OP1			 <= `CUR_A;
			ALU_INFLAGS		 <= `CUR_F;
			FSM_NEXT_STATE.T <= STATE_T2H;
		end

		STATE_GN1T2L: begin
		   `CUR_F			 <= ALU_OUTFLAGS;						// Set flags except C (pass thru)
			FSM_NEXT_STATE.T <= STATE_T3H;
		end

		STATE_GN1T3L: FSM_NEXT_STATE.T	<= STATE_T4H;				// Timing 4 cycles

		STATE_GN1T4L: FSM_NEXT_STATE	<= STATE_MW1T1H;



		STATE_MW1T3L: begin											// ME(3) write complete
			FSM_LAST_M		 = TRUE;
		end

		endcase
	end

	////////////////////////////////////////////////////////////////////////////
	// I/O group

	PLA_IO_A_N: begin												// M1(4) IN A,(n)/OUT (n),A

		case(FSM_STATE)

			STATE_M1T4L: begin				
				FSM_NEXT_STATE	<= STATE_MR1T1H;					// Begin read cycle for immediate
			end



			STATE_MR1T1H: begin										// MR(3)
				ADDRESS_BUS		<= `REG_PC;							// Read from this address
				INC_DIR			<= TRUE;
				INC_BITS		<= TRUE;
			end

			STATE_MR1T3H: begin
				`REG_PC			<= INC_OUT;							// Step past immediate
			end

			STATE_MR1T3L: begin
				ADDRESS_BUS		<= { `CUR_A, DATA_IN };				// Set IO port address
				FSM_NEXT_STATE	<= OPCODE_REG[3] ? STATE_IRT1H : STATE_IWT1H;
			end



			STATE_IRT4H: begin										// IR(4)
			   `CUR_A			<= DATA_IN;							// Read value to A
			end

			STATE_IRT4L: begin										// OR ...
			   FSM_LAST_M		 = TRUE;
			end



			STATE_IWT1H: begin										// IW(4)
				DATA_OUT		<= `CUR_A;							// Write value in A
			end

			STATE_IWT4L: begin
			   FSM_LAST_M		 = TRUE;
			end

		endcase
	end

	PLA_IO_R_C: begin												// M1(4) IN r,(c)/OUT (c),r

		case(FSM_STATE)

			STATE_M1T4L: begin
				ADDRESS_BUS		<= `CUR_BC;
				CPU_REG_NUM		<= OPCODE_REG[5:3];					// Reg decode
				FSM_NEXT_STATE	<= OPCODE_REG[0] ? STATE_IWT1H : STATE_IRT1H;
			end



			STATE_IRT4H: begin										// IR(4)
				ALU_OPCODE		<= ALU_FLG;							// Set flags only
				ALU_OP1		<= DATA_IN;
				ALU_INFLAGS	<= `CUR_F;
			end

			STATE_IRT4L: begin
				REG.R8[REG8_INDEX]	<= ALU_OP1;
			   `CUR_F				<= ALU_OUTFLAGS;				// Set flags except C (passed thru from inflags)
			   FSM_LAST_M			 = TRUE;
			end



			STATE_IWT1H: begin										// IW(4)
				DATA_OUT		<= REG.R8[REG8_INDEX];
			end

			STATE_IWT4L: begin
			   FSM_LAST_M		 = TRUE;
			end

		endcase
	end

	PLA_INIDR: begin												// M1(5) INI/INIR/IND/INDR
		case(FSM_STATE)
		
		STATE_M1T4L: begin
			FSM_NEXT_STATE.T <= STATE_T5H;							// Extra M1 cycle for something
		end
		
		STATE_M1T5L: begin											// Begin IO read
			FSM_NEXT_STATE	<= STATE_IRT1H;
		end



		STATE_IRT1H: begin											// IR(4)
			ADDRESS_BUS		<= `CUR_BC;								// IO port address
		end

		STATE_IRT4H: begin
			DATA_OUT		<= DATA_IN;
		end

		STATE_IRT4L: begin
			FSM_NEXT_STATE	<= STATE_MW1T1H;						// Now write the byte to memory
		end



		STATE_MW1T1H: begin											// MW(3)
			ADDRESS_BUS		<= `CUR_HL;								// Write at address held in HL
			INC_DIR			<= ~OPCODE_REG[3];
			INC_BITS		<= TRUE;
			ALU_OPCODE		<= ALU_SUB;
			ALU_OP1			<=`CUR_B;								// Value of B reg
			ALU_OP2			<= 1;									// Subtract 1
		end

		STATE_MW1T3H: begin
		   `CUR_B			<= ALU_RESULT;
		   `CUR_F[7:1]		<= ALU_OUTFLAGS[7:1];					// Set flags except C
		   `CUR_HL			<= INC_OUT;								// Update HL
		end

		STATE_MW1T3L: begin
			if (OPCODE_REG[4] & ~`CUR_F[FLAG_Z])					// If repeat ...
				FSM_NEXT_STATE	<= STATE_GN1T1H;
			else
				FSM_LAST_M		 = TRUE;
		end


		STATE_GN1T1L: begin
			ADDRESS_BUS		 <= `REG_PC;							// Step back and do the instruction again
			FSM_NEXT_STATE.T <= STATE_T2H;
		end

		STATE_GN1T2L: begin
			ADDRESS_BUS		 <= INC_OUT;							// PC - 1
			FSM_NEXT_STATE.T <= STATE_T3H;
		end

		STATE_GN1T3L: begin
		   `REG_PC			 <= INC_OUT;							// PC - 2
			FSM_NEXT_STATE.T <= STATE_T4H;
		end 

		STATE_GN1T4L: FSM_NEXT_STATE.T <= STATE_T5H;

		STATE_GN1T5L: begin
			FSM_LAST_M		= TRUE;									// Instruction complete
		end

		endcase
	end

	PLA_OUTIDR: begin												// M1(5) OUTI/OTIR/OUTD/OTDR

		case(FSM_STATE)
		
		STATE_M1T4L: begin
			FSM_NEXT_STATE.T <= STATE_T5H;							// Extra M1 cycle for something
		end
		
		STATE_M1T5L: begin											// Begin memory read
			FSM_NEXT_STATE	<= STATE_MR1T1H;
		end


		STATE_MR1T1H: begin											// MR(3)
			ADDRESS_BUS		<= `CUR_HL;								// HL to address bus
			INC_DIR			<= ~OPCODE_REG[3];						// Set direction INC/DEC
			INC_BITS		<= TRUE;
		end

		STATE_MR1T3H: begin
			DATA_OUT		<= DATA_IN;								// Data read is output
			ALU_OPCODE		<= ALU_SUB;
			ALU_OP1			<=`CUR_B;								// Value of B reg
			ALU_OP2			<= 1;									// Subtract 1
		end

		STATE_MR1T3L: begin
		   `CUR_B			<= ALU_RESULT;
		   `CUR_HL			<= INC_OUT;								// Need to update HL before address bus used for IO
		   `CUR_F[7:1]		<= ALU_OUTFLAGS[7:1];					// Set flags except C
			FSM_NEXT_STATE	<= STATE_IWT1H;							// Now write the byte to IO
		end


		STATE_IWT1H: begin											// IW(4)
			ADDRESS_BUS		<=`CUR_BC;								// IO Port address
		end

		STATE_IWT4L: begin
			if (OPCODE_REG[4] & ~`CUR_F[FLAG_Z])					// If repeat ...
				FSM_NEXT_STATE	<= STATE_GN1T1H;
			else
				FSM_LAST_M		 = TRUE;
		end

		
		STATE_GN1T1L: begin
			ADDRESS_BUS		 <= `REG_PC;							// Step back and do the instruction again
			INC_DIR			 <= FALSE;
			FSM_NEXT_STATE.T <= STATE_T2H;
		end

		STATE_GN1T2L: begin
			ADDRESS_BUS		 <= INC_OUT;							// PC - 1
			FSM_NEXT_STATE.T <= STATE_T3H;
		end

		STATE_GN1T3L: begin
		   `REG_PC			 <= INC_OUT;							// PC - 2
			FSM_NEXT_STATE.T <= STATE_T4H;
		end

		STATE_GN1T4L: FSM_NEXT_STATE.T	<= STATE_T5H;

		STATE_GN1T5L: begin
			FSM_LAST_M		= TRUE;								// Instruction complete
		end
		endcase
	end

	////////////////////////////////////////////////////////////////////////////
	// Interrupt acknowledge

	PLA_I1_NMI: begin												// Interrupt acknowledge NMI/INT1

		case(FSM_STATE)

		STATE_M1T4L: begin											// Pseudo M1 Cycle complete. Begin stacking PC
			ADDRESS_BUS		<=`REG_SP;
			INC_DIR			<= FALSE;
			INC_BITS		<= TRUE;
			FSM_NEXT_STATE	<= STATE_MW1T1H;
		end



		STATE_MW1T1H: begin											// MW(4)
			ADDRESS_BUS		<= INC_OUT;								// SP - 1
			DATA_OUT		<=`REG_PCH;								// Stack PC high byte
		end

		STATE_MW1T3L: begin
			FSM_NEXT_STATE	<= STATE_MW2T1H;
		end		



		STATE_MW2T1H: begin											// MW(4)
			ADDRESS_BUS		<= INC_OUT;								// SP - 2
			DATA_OUT		<=`REG_PCL;								// Stack low byte
		end

		STATE_MW2T3L: begin
		   `REG_SP			<= ADDRESS_BUS;							// Update SP
		   `REG_PC			<=`REG_WZ;								// Take the jump
			FSM_LAST_M		 = TRUE;
		end	

		endcase
	end

	default: begin													// NOP etc - start a new instruction
		if ( FSM_STATE == STATE_M1T4L) begin
			FSM_LAST_M		 = TRUE;
		end
	end

	endcase

	///////////////////////////////////////////////////////////////////////////
	// Instruction execution complete, check for NMI/INT and prepare next instruction

	if (FSM_LAST_M) begin

		IX				<= FALSE;								// Clear prefixes
		IY			 	<= FALSE;
		BITS			<= FALSE;
		FSM_LAST_M		 = FALSE;

		if (~NMI) begin

            EXTD            <= TRUE;                            // STATE for interrupt cycle
			OPCODE_REG 		<= 8'hFF;
		   `REG_WZ			<= 16'h0066;						// NMI handler address
			FSM_NEXT_STATE	<= STATE_NIT1H;						// NMI ack cycle

		end else if (~INT & IFF1) begin

            IFF1            <= FALSE;
            EXTD            <= TRUE;                            // STATE for interrupt cycle
			OPCODE_REG		<= 8'hFE;
		   `REG_WZ			<= 16'h0038;						// INT 1 handler address
			FSM_NEXT_STATE	<= STATE_NIT1H;						// INT 1 ack cycle

		end else begin

            EXTD			<= FALSE;
			FSM_NEXT_STATE	<= STATE_M1T1H;						// Start next M1 cycle

		end
	end

end

endmodule





