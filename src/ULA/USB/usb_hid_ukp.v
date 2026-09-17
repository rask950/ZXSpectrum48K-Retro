`timescale 1ns/1ps


module ukp(
    input 				RESET,
    input 				USB_CLK,					// 12MHz clock

    inout 				USB_P_EXT,					// USB external connection D+, D-
    inout 				USB_N_EXT,
    output 				USB_OE_EXT,

    output reg 			DATA_READY, 				// data frame is outputing
    output 				DATA_STROBE,				// strobe for a byte within the frame
    output reg 	[ 7: 0] DATA_OUT,					// output data when DATA_STROBE=1

    output reg			SAVE,						// save: regs[save_r] <= dat[save_b]
    output reg	[ 3: 0] SAVE_R,
    output reg	[ 3: 0] SAVE_B,

    output reg 			CONNECTED,
    output 				CON_ERROR
);

    localparam			S_OPCODE	=  0;			// FSM STATEs
    localparam			S_LDI0		=  1;
    localparam			S_LDI1		=  2;
    localparam			S_B0		=  3;
    localparam			S_B1		=  4;
    localparam			S_B2		=  5;
    localparam			S_S0 		=  6;
    localparam			S_S1 		=  7;
    localparam			S_S2 		=  8;
    localparam			S_TOGGLE0	=  9;
    localparam			S_TOGGLE1	= 10;

	localparam			I_NOP		= 4'h0;
    localparam			I_LDI		= 4'h1;
    localparam			I_START		= 4'h2;
    localparam			I_OUT4		= 4'h3;
    localparam			I_OUT0		= 4'h4;
    localparam			I_HIZ		= 4'h5;
    localparam			I_OUTB		= 4'h6;
    localparam			I_RET		= 4'h7;
    localparam			I_BZ		= 4'h8;
    localparam			I_BC		= 4'h9;
    localparam			I_BNAK		= 4'hA;
    localparam			I_DJNZ		= 4'hB;
    localparam			I_TOGSAV	= 4'hC;
    localparam			I_IN		= 4'hD;
    localparam			I_WAIT		= 4'hE;
    localparam			I_JMP		= 4'hF;

    wire		[ 3: 0]	INST;						// Current instruction AND PARAMETER from ROM
    reg			[ 3: 0] INST_H;						// Stored instruction from ROM
    reg 				INST_READY	= 0;			// Instruction from ROM is ready

    reg 				USB_OUT_P	= 0;			// USB data output and input
    reg 				USB_OUT_N	= 0;
    reg					USB_IN_P; 
	reg					USB_IN_N; 
	reg					USB_IN_NS	= 0;
    reg					USB_IN_ND;

    wire 				SAMPLE;						// IN sample is available

    reg					NAK			= 0;			// NAK signal for USB communication
    reg					NAKD;						// NAK delay

    reg                 OE          = 0;    		// Output enable

    reg					BANK		= 0;
    reg					RECORD1		= 0;

    reg					MBIT        = 0;			// OUT4/OUTB is transmitting
    
	reg			[ 3: 0] STATE       = 0;			// State machine current state
    reg			[ 3: 0] STATED;						// Delayed state

    reg			[ 7: 0] WK          = 0;		    // W register
    reg			[ 7: 0] OUT_BYTE    = 0;		    // Out value byte being written
    reg			[ 2: 0] OUT_IND;					// Index in above of current bit being written
    
	reg         [13: 0] PC          = 0;			// program counter, next pc
    reg         [13: 0] NEXT_PC;

    reg			[ 2: 0] TIMING		= 0;			// T register (0~7)
    
	reg			[ 3: 0] LB4			= 0;			// Jump/branch address stores
    reg			[ 3: 0] LB4W;
    reg					COND		= 0;			// Branch condition state

    reg			[13: 0] INTERVAL	= 0;

    reg			[ 6: 0] BITADR		= 0;			// 0~127
    reg			[ 7: 0] DATA = 0;					// received data

    reg			[ 2: 0] NRZI_TX_CNT;				// NRZI trans/recv count for bit stuffing
	reg			[ 2: 0] NRZI_RX_CNT;
    reg					NRZON		= 0;

    wire				INTERVAL_CY = INTERVAL == 12001;			// Interval counter has reached its maximum value

    wire 				NEXT 		=  ~(STATE == S_OPCODE &
											(INST  == I_START & USB_IN_N |										// start
											(INST  == I_OUT0 || INST == I_HIZ) & TIMING != 0 |					// out0/hiz
											 INST  == I_IN	  & (~SAMPLE | (USB_IN_P | USB_IN_N) & WK != 1) |	// in 
											 INST  == I_WAIT  & ~INTERVAL_CY)									// wait
										);

    wire				BRANCH		= STATE == S_B1 & COND;									// Branch condition met
    wire 				RETPC		= STATE == S_OPCODE && INST == I_RET;					// Return from subroutine
    wire 				JMPPC		= STATE == S_OPCODE && INST == I_JMP;					// Jump to subroutine

    wire				OUT_BIT		= OUT_BYTE[ 7 - OUT_IND ];								// The bit to be transmitted from the output byte

    wire				RECORD;

    reg					DATA_READY_D;						// Delayed version for edge detection

    reg			[23: 0] CONCT;								// Connection counter for error detection

    assign				CON_ERROR = CONCT[23] || ~RESET;	// Connection error indicator

USB_HID_HOST_ROM 	UKPROM(
	.CLK(				USB_CLK), 
	.ADDRESS(			PC),
	.DATA(				INST)
);

    always @(posedge USB_CLK) begin

        if(~RESET) begin 

            PC						<= 0;
			CONNECTED				<= 0;
			COND					<= 0;
			INST_READY				<= 0;
			STATE					<= S_OPCODE;
			TIMING					<= 0; 
            MBIT					<= 0;
			BITADR					<= 0;
			NAK						<= 1;
			OE						<= 0;

        end else begin

            USB_IN_P				<= USB_P_EXT;								// USB physical connections
			USB_IN_N 				<= USB_N_EXT;

            SAVE 					<= 0;										// ensure pulse

            if (INST_READY) begin												// Instruction decoding

                case(STATE)

                    S_OPCODE: begin

                        INST_H		    <= INST;                                // Make a copy of the instruction

						case (INST)

						I_LDI: begin											// 1 - LDI
							STATE       <= S_LDI0;								// Collect the following 2 nibbles into WK
						end

						I_OUT0: begin											// 4 - Output to zero
							OE			<= 1'b1;								// Enable output and set both USB data lines to 0
							USB_OUT_P	<= 0;
							USB_OUT_N	<= 0;
						end

						I_OUT4: begin											// 3 - Output 4 bits
							OUT_IND	    <= 3;
							STATE       <= S_S0;
						end

						I_OUTB: begin											// 6 - Output byte
							OUT_IND		<= 7;
							STATE		<= S_S0;
						end

						I_HIZ: begin											// 5 - High impedance state
							OE			<= 0;
						end

						I_BZ: begin												// 8 - Branch if zero
							STATE		<= S_B0;
							COND 		<= ~USB_IN_N;
						end
						
						I_BC: begin												// 9 - Branch if connected
							STATE		<= S_B0;
							COND 		<= CONNECTED;
						end
						
						I_BNAK: begin											// 10 - Branch if NAK
							STATE		<= S_B0;
							COND 		<= NAK;
						end

						I_DJNZ: begin											// 11 - Decrement and jump if not zero
							STATE		<= S_B0;
							WK 			<= WK - 8'd1;
							COND 		<= WK != 1;
						end
						
						I_JMP: begin											// 15 - Jump to subroutine
							STATE		<= S_B2;
							COND		<= 1;
						 end

                        I_TOGSAV: begin
							STATE		<= S_TOGGLE0;
						end

                        I_IN: begin
							if (SAMPLE) WK <= WK - 8'd1;
						end

						endcase

                    end

                    // Instructions with operands
                    
				    S_LDI0: begin												// ldi (low nibble)
						WK[3:0] 	<= INST;
						STATE		<= S_LDI1;
					end
                
				    S_LDI1: begin												// ldi (high nibble)
						WK[7:4] 	<= INST;
						STATE		<= S_OPCODE;
					end


                    S_B2: begin													// jmp collects 2 nibbles
						LB4W		<= INST;
						STATE		<= S_B0; 
					end

                    S_B0: begin													// branch/jmp collects 1 nibble
						LB4 		<= INST;
						STATE		<= S_B1; 
					end
                    
					S_B1: begin													// Branch/jmp done
						STATE		<= S_OPCODE;
					end
                    

                    S_S0: begin													// OutputB/4 collects low nibble
						OUT_BYTE[3:0]	<= INST;
						STATE			<= S_S1;
					end

                    S_S1: begin													// OutputB/4 collects high nibble even though OUT4 only uses low nibble
						OUT_BYTE[7:4]	<= INST;
						STATE			<= S_S2;
						MBIT			<= 1;									// Indicates bit transmission
					end


					S_TOGGLE0: begin											// toggle and save
                        if (INST == 15)											// The 1st nibble following the opcode
							CONNECTED	<= ~CONNECTED;							// $F for toggle
                        else
							SAVE_R		<= INST;								// anything else is the save destination index

                        STATE <= S_TOGGLE1;
                    end

                    S_TOGGLE1: begin
                        if (INST != 15) begin									// The 2nd nibble following the opcode
                            SAVE_B	<= INST;									// Both SAVE_R and SAVE_B have been set
                            SAVE	<= 1;										// Indicate SAVE
                        end

                        STATE <= S_OPCODE;
                    end
                
				endcase

                // pc control
                if (MBIT == 0) begin 											// If NOT transmitting
					
                    if (JMPPC) NEXT_PC	<= PC + 14'd4;							// JMP is actually CALL and this is the return address
                    
					if (NEXT | BRANCH | RETPC) begin

                        if (RETPC)
							PC 			<= NEXT_PC;								// RETurn from JMP
						else
							if (BRANCH)
	                            if (INST_H == I_JMP)							// jmp
	                                PC	<= { INST, LB4, LB4W, 2'b00 };			// 3 nibbles (INST, LB4, LB4W) * 4
	                            else											// branch
	                                PC	<= { 4'b0000, INST, LB4, 2'b00 };		// 2 nibbles (0000, INST, LB4) * 4
	                        else
								PC		<= PC + 14'd1;							// next PC
                        
						INST_READY		<= 0;									// Wait 1 cycle for the next instruction
                    end
                end

			end else begin
			
				INST_READY 				<= 1;

			end

            // bit transmission (out4/outb)
            if (MBIT == 1 && TIMING == 0) begin

                if (OE == 0) begin												// If output NOT enabled, clear TX counter
					NRZI_TX_CNT		<= 0;
                end else begin
                    if (OUT_BIT) begin											// If output bit is 1 (no transition) incremement count
						NRZI_TX_CNT <= NRZI_TX_CNT + 3'd1;
                    end else begin
					    NRZI_TX_CNT <= 0;
                    end
                end

				if (INST_H == I_OUTB) begin										// OUTB

					if (NRZI_TX_CNT != 6) begin									// No but stuffing needed encode the next bit
					
						USB_OUT_P	<= OUT_BIT ?  USB_OUT_P : ~USB_OUT_P;
						USB_OUT_N	<= OUT_BIT ? ~USB_OUT_P :  USB_OUT_P;
					
					end	else begin

						USB_OUT_P	<= ~USB_OUT_P;								// Bit stuffing - force a transition
						USB_OUT_N	<=  USB_OUT_P;

						NRZI_TX_CNT <= 0;										// Reset the counter

					end

				end else begin													// OUT4 only used for EOP

					USB_OUT_P		<= OUT_BYTE[ {1'b1, OUT_IND[1:0]} ];		// This is 7, 6, 5, 4 - 0000
					USB_OUT_N		<= OUT_BYTE[ 		OUT_IND ];				// This is 3, 2, 1, 0 - 0011

				end

                OE <= 1'b1; 													// Now enable the bit to be output

                if (NRZI_TX_CNT != 6)											// Move on to the next bit unless stuffed
					OUT_IND 		<= OUT_IND - 3'd1;

                if (OUT_IND == 0) begin											// All bits transmitted
					MBIT			<= 0;										// Turn off transmission
					STATE			<= S_OPCODE;								// Collect next opcode
				end

            end

            // start instruction
            USB_IN_ND <= USB_IN_N;

            if (INST_READY & 
				STATE == S_OPCODE & 
				INST  == I_START) begin 							// op=start 

                BITADR				<= 0; 
				NAK					<= 1;
				NRZI_RX_CNT			<= 0;

			end else begin 

                if (OE == 0 && 
					USB_IN_N		!= USB_IN_ND)
					TIMING			<= 1;
                else
					TIMING 			<= TIMING + 3'd1;

			end

            // IN instruction
            if (SAMPLE) begin

                if (BITADR == 8) NAK <= USB_IN_N;

                if (NRZI_RX_CNT		!= 6) begin

                    DATA[6:0]		<= DATA[7:1]; 
                    DATA[7]			<= USB_IN_NS ~^ USB_IN_N;		// ~^/^~ is XNOR, testing bit equality
                    BITADR			<= BITADR + 7'd1;
					NRZON			<= 0;

				end else begin

					NRZON			<= 1;

				end

                USB_IN_NS			<= USB_IN_N;
				
                if (USB_IN_NS ~^ USB_IN_N)
					NRZI_RX_CNT		<= NRZI_RX_CNT + 3'd1;
                else
				    NRZI_RX_CNT		<= 0;

                if (~USB_IN_N && ~USB_IN_P) DATA_READY <= 0;      			// SE0: packet is finished. Mouses send length 4 reports.
            end

            if (OE == 0) begin
                if (BITADR == 24) DATA_READY <= 1;					// ignore first 3 bytes
                if (BITADR == 88) DATA_READY <= 0;					// output next 8 bytes
            end

            if ((BITADR > 11 & BITADR[2:0] == 3'b000) & (TIMING == 2)) DATA_OUT <= DATA;

            // Timing
            INTERVAL				<=	INTERVAL_CY ? 14'd0 :
										INTERVAL	+ 14'd1;

            RECORD1					<= RECORD;
            if (~RECORD & RECORD1) BANK <= ~BANK;

            // Connection status & WDT
            DATA_READY_D			<= DATA_READY;

            NAKD					<= NAK;

            if (DATA_READY && ~DATA_READY_D || INST_READY && STATE == S_OPCODE && INST == I_START) begin
            
			    CONCT 				<= 0;							// reset watchdog on data received or START instruction
			
			end else begin 
            
			    if (CONCT[23:22] 	!= 2'b11) begin
					CONCT			<= CONCT + 24'd1;
				end else begin 
					PC				<= 0; 
					CONCT			<= 0;
				end		// !! WDT ON
            
			end 
        end
    end

    assign USB_P_EXT	= OE ? USB_OUT_P : 1'bZ;					// Tri-state control for USB data
    assign USB_N_EXT	= OE ? USB_OUT_N : 1'bZ;

    assign USB_OE_EXT	= OE;										// Output enable for USB data lines

    assign SAMPLE		= INST_READY &								// Sample condition for IN instruction
						  STATE == S_OPCODE &
						  INST == I_IN &
						  TIMING == 4;

    assign RECORD 		= CONNECTED & ~NAK;							// Record condition: connected and not NAK

    assign DATA_STROBE	=  ~NRZON & 								// Data strobe condition
							DATA_READY & 
							BITADR[2:0] == 3'b100 &
							TIMING == 2;

endmodule