`timescale 1ns/1ps


module ukp(
    input 				RESET,
    input 				USB_CLK,					// 12MHz clock

    inout 				USB_Dp,						// D+, D-
    inout 				USB_Dm,
    output 				USB_OE,

    output reg 			DATA_READY, 				// data frame is outputing
    output 				DATA_STROBE,				// strobe for a byte within the frame

    output reg 	[ 7: 0] DATA_OUT,					// output data when DATA_STROBE=1

    output reg			SAVE,						// save: regs[save_r] <= dat[save_b]
    output reg	[ 3: 0] SAVE_R,
    output reg	[ 3: 0] SAVE_B,

    output reg 			CONNECTED,
    output 				CON_ERROR
);

    parameter			S_OPCODE	=  0;			// FSM STATEs
    parameter			S_LDI0		=  1;
    parameter			S_LDI1		=  2;
    parameter			S_B0		=  3;
    parameter			S_B1		=  4;
    parameter			S_B2		=  5;
    parameter			S_S0 		=  6;
    parameter			S_S1 		=  7;
    parameter			S_S2 		=  8;
    parameter			S_TOGGLE0	=  9;
    parameter			S_TOGGLE1	= 10;

    wire		[ 3: 0]	INST;
    reg			[ 3: 0] INST_H;

    wire 				SAMPLE;						// 1: an IN sample is available

    reg 				INST_READY	= 0;
    reg 				USB_DATA_p	= 0;
    reg 				USB_DATA_m	= 0;
    reg					COND		= 0;
    reg					NAK			= 0;
    reg					DMIS		= 0;

    reg                 OE          = 0;    		// OE=1: output enabled, 0: hi-Z
    reg                 OE_W        = 0;
    reg					NRZON		= 0;

    reg					BANK		= 0;
    reg					RECORD1		= 0;

    reg			[ 1: 0]	MBIT        = 0;			// 1: out4/outb is transmitting
    
	reg			[ 3: 0] STATE       = 0;
    reg			[ 3: 0] STATED;

    reg			[ 7: 0] WK          = 0;		    // W register
    reg			[ 7: 0] SB          = 0;		    // out value
    reg			[ 3: 0] SADR;						// out4/outb write ptr
    
	reg         [13: 0] PC          = 0;
    reg         [13: 0] NEXT_PC;					// program counter, wpc = next pc

    reg			[ 2: 0] TIMING		= 0;			// T register (0~7)
    
	reg			[ 3: 0] LB4			= 0;
    reg			[ 3: 0] LB4W;

    reg			[13: 0] INTERVAL	= 0;

    reg			[ 6: 0] BITADR		= 0;			// 0~127
    reg			[ 7: 0] DATA = 0;					// received data

    reg			[ 2: 0] NRZI_TX_CNT;				// NRZI trans/recv count for bit stuffing
	reg			[ 2: 0] NRZI_RX_CNT;

    wire				INTERVAL_CY = INTERVAL == 12001;

    wire 				NEXT =  ~(STATE == S_OPCODE &
									(INST == 2  &
									 DMI |												// start
									(INST == 4  || INST==5) & 
									TIMING != 0 |										// out0/hiz
									INST == 13 & (~SAMPLE | (DPI | DMI) & WK != 1) |	// in 
									INST == 14 &
									~INTERVAL_CY)										// wait
    							);

    wire				BRANCH = STATE == S_B1 & COND;
    wire 				RETPC  = STATE == S_OPCODE && INST==7  ? 1 : 0;
    wire 				JMPPC  = STATE == S_OPCODE && INST==15 ? 1 : 0;
    wire				DBIT   = SB[7-SADR[2:0]];

    wire				RECORD;

    reg					DMID;
    reg			[23: 0] CONCT;

    reg					DPI; 
	reg					DMI; 
    reg					DATA_READY_D;
    reg					NAKD;

    assign				CON_ERROR = CONCT[23] || ~RESET;

    usb_hid_host_rom ukprom(.clk(USB_CLK), .adr(PC), .data(INST));

    always @(posedge USB_CLK) begin

        if(~RESET) begin 

            PC			<= 0;
			CONNECTED	<= 0;
			COND		<= 0;
			INST_READY	<= 0;
			STATE		<= S_OPCODE;
			TIMING		<= 0; 
            MBIT		<= 0;
			BITADR		<= 0;
			NAK			<= 1;
			OE			<= 0;

        end else begin

            DPI			<= USB_Dp;
			DMI 		<= USB_Dm;
            SAVE 		<= 0;													// ensure pulse

            if (INST_READY) begin												// Instruction decoding

                case(STATE)

                    S_OPCODE: begin

                        INST_H		<= INST;                        
						if (INST == 1) STATE <= S_LDI0;							// op=ldi

                        if (INST == 3 ) begin									// op=out4
							SADR	<= 3;
							STATE	<= S_S0;
						 end

                        if (INST == 4) begin 
							OE			<= 1'b1;
							USB_DATA_p	<= 0;
							USB_DATA_m	<= 0;
						 end

                        if (INST == 5) OE	<= 0;

                        if (INST == 6) begin									// op=outb
							SADR	<= 7;
							STATE	<= S_S0;
						end

                        if (INST[3:2]==2'b10) begin								// op=10xx(BZ,BC,BNAK,DJNZ)
                            STATE <= S_B0;
                            case (INST[1:0])
                                2'b00: COND <= ~DMI;
                                2'b01: COND <= CONNECTED;
                                2'b10: COND <= NAK;
                                2'b11: COND <= WK != 1;
                            endcase
                        end

                        if (INST == 11 | INST == 13 & SAMPLE) WK <= WK - 8'd1;	// op=DJNZ,IN

                        if (INST == 15) begin									// op=jmp
							STATE <= S_B2;
							COND <= 1;
						 end

                        if (INST == 12) STATE <= S_TOGGLE0;
                    end

                    // Instructions with operands
                    
				    S_LDI0: begin												// ldi (low nibble)
						WK[3:0] <= INST;
						STATE <= S_LDI1;
					end
                
				    S_LDI1: begin												// ldi (high nibble)
						WK[7:4] <= INST;
						STATE <= S_OPCODE;
					end
                    					
                    S_B2: begin													// branch/jmp
						LB4W <= INST;
						STATE <= S_B0; 
					end

                    S_B0: begin
						LB4  <= INST;
						STATE <= S_B1; 
					end
                    
					S_B1: begin
						STATE <= S_OPCODE;
					end
                    
					// out
                    S_S0: begin
						SB[3:0] <= INST;
						STATE <= S_S1;
					end

                    S_S1: begin
						SB[7:4] <= INST;
						STATE <= S_S2;
						MBIT <= 1;
					end
                    
					S_TOGGLE0: begin											// toggle and save
                        if (INST == 15)
							CONNECTED	<= ~CONNECTED;							// toggle
                        else
							SAVE_R		<= INST;								// save

                        STATE <= S_TOGGLE1;
                    end

                    S_TOGGLE1: begin
                        if (INST != 15) begin
                            SAVE_B	<= INST;
                            SAVE	<= 1;
                        end

                        STATE <= S_OPCODE;
                    end
                
				endcase

                // pc control
                if (MBIT == 0) begin 
					
                    if (JMPPC) NEXT_PC <= PC + 4;
                    
					if (NEXT | BRANCH | RETPC) begin

                        if (RETPC)
							PC <= NEXT_PC;									// ret
						else if (BRANCH)
                            if (INST_H == 15)								// jmp
                                PC <= { INST, LB4, LB4W, 2'b00 };
                            else											// branch
                                PC <= { 4'b0000, INST, LB4, 2'b00 };
                        else
							PC <= PC + 1;									// next
                        
						INST_READY <= 0;
                    end
                end

			end else begin
			
				INST_READY <= 1;

			end

            // bit transmission (out4/outb)
            if (MBIT == 1 && TIMING == 0) begin

                if(OE==0)
					NRZI_TX_CNT <= 0;
                else
                    if(DBIT)
						NRZI_TX_CNT <= NRZI_TX_CNT + 1;
                    else
					    NRZI_TX_CNT <= 0;

				if (INST_H == 4'd6) begin

					if (NRZI_TX_CNT != 6) begin
					
						USB_DATA_p <= DBIT ?  USB_DATA_p : ~USB_DATA_p;
						USB_DATA_m <= DBIT ? ~USB_DATA_p :  USB_DATA_p;
					
					end	else begin

						USB_DATA_p <= ~USB_DATA_p;
						USB_DATA_m <=  USB_DATA_p;

						NRZI_TX_CNT <= 0;

					end

				end else begin

					USB_DATA_p <=  SB[{1'b1,SADR[1:0]}];
					USB_DATA_m <= SB[SADR[2:0]];

				end

                OE <= 1'b1; 

                if (NRZI_TX_CNT != 6) SADR <= SADR - 4'd1;

                if (SADR == 0) begin
					MBIT <= 0;
					STATE <= S_OPCODE;
				end

            end

            // start instruction
            DMID <= DMI;

            if (INST_READY & STATE == S_OPCODE & INST == 4'b0010) begin 	// op=start 

                BITADR		<= 0; 
				NAK			<= 1;
				NRZI_RX_CNT <= 0;

			end else begin 

                if (OE == 0 && DMI != DMID)
					TIMING <= 1;
                else
					TIMING <= TIMING + 1;

			end

            // IN instruction
            if (SAMPLE) begin

                if (BITADR == 8) NAK <= DMI;

                if (NRZI_RX_CNT != 6) begin

                    DATA[6:0]	<= DATA[7:1]; 
                    DATA[7]		<= DMIS ~^ DMI;		    			// ~^/^~ is XNOR, testing bit equality
                    BITADR		<= BITADR + 1;
					NRZON		<= 0;

				end else begin

					NRZON <= 1;

				end

                DMIS <= DMI;
				
                if (DMIS ~^ DMI)
					NRZI_RX_CNT <= NRZI_RX_CNT + 1;
                else
				    NRZI_RX_CNT <= 0;

                if (~DMI && ~DPI) DATA_READY <= 0;      			// SE0: packet is finished. Mouses send length 4 reports.
            end

            if (OE == 0) begin
                if (BITADR == 24) DATA_READY <= 1;					// ignore first 3 bytes
                if (BITADR == 88) DATA_READY <= 0;					// output next 8 bytes
            end

            if ((BITADR > 11 & BITADR[2:0] == 3'b000) & (TIMING == 2)) DATA_OUT <= DATA;

            // Timing
            INTERVAL <= INTERVAL_CY ? 0 : INTERVAL + 1;
            RECORD1	 <= RECORD;
            if (~RECORD & RECORD1) BANK <= ~BANK;

            // Connection status & WDT
            DATA_READY_D <= DATA_READY;

            NAKD <= NAK;

            if (DATA_READY && ~DATA_READY_D || INST_READY && STATE == S_OPCODE && INST == 4'b0010) begin
            
			    CONCT <= 0;											// reset watchdog on data received or START instruction
			
			end else begin 
            
			    if (CONCT[23:22] != 2'b11) begin
					CONCT <= CONCT + 24'd1;
				end else begin 
					PC <= 0; 
					CONCT <= 0;
				end		// !! WDT ON
            
			end 
        end
    end

    assign USB_Dp = OE ? USB_DATA_p : 1'bZ;
    assign USB_Dm = OE ? USB_DATA_m : 1'bZ;
    assign USB_OE = OE;

    assign SAMPLE = INST_READY & STATE == S_OPCODE & INST == 4'b1101 & TIMING == 4; // IN

    assign RECORD = CONNECTED & ~NAK;

    assign DATA_STROBE = ~NRZON & DATA_READY & (BITADR[2:0] == 3'b100) & (TIMING == 2);

endmodule