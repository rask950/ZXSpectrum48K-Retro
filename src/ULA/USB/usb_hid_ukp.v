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

    parameter			S_OPCODE	=  0;			// FSM states
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

    reg 				INST_READY = 0;
    reg 				USB_DATA_p = 0;
    reg 				USB_DATA_m = 0;
    reg cond = 0;
    reg nak = 0;
    reg dmis = 0;

    reg OE = 0;										// ug=1: output enabled, 0: hi-Z
    reg OE_W = 0;
    reg nrzon = 0;

    reg bank = 0;
    reg record1 = 0;

    reg [1:0] mbit = 0;					// 1: out4/outb is transmitting
    
	reg [3:0] state = 0;
    reg [3:0] stated;

    reg [7:0] wk = 0;					// W register
    reg [7:0] sb = 0;					// out value
    reg [3:0] sadr;						// out4/outb write ptr
    
	reg [13:0] PC = 0;
    reg [13:0] NEXT_PC;					// program counter, wpc = next pc

    reg [2:0] timing = 0;				// T register (0~7)
    
	reg [3:0] lb4 = 0;
    reg [3:0] lb4w;

    reg [13:0] interval = 0;

    reg [6:0] bitadr = 0;				// 0~127
    reg [7:0] data = 0;					// received data

    reg [2:0] NRZI_TX_CNT;					// NRZI trans/recv count for bit stuffing
	reg [2:0] NRZI_RX_CNT;

    wire interval_cy = interval == 12001;

    wire next =  ~(state == S_OPCODE & (
					INST == 2  &  dmi |									// start
				   (INST == 4  || INST==5) & timing != 0 |				// out0/hiz
					INST == 13 & (~SAMPLE | (dpi | dmi) & wk != 1) |	// in 
					INST == 14 &  ~interval_cy							// wait
    ));

    wire branch = state == S_B1 & cond;
    wire retpc  = state == S_OPCODE && INST==7  ? 1 : 0;
    wire jmppc  = state == S_OPCODE && INST==15 ? 1 : 0;
    wire dbit   = sb[7-sadr[2:0]];

    wire record;

    reg  dmid;
    reg [23:0] conct;

    reg		dpi; 
	reg		dmi; 
    reg		DATA_READYd;
    reg		nakd;

    assign CON_ERROR = conct[23] || ~RESET;

    usb_hid_host_rom ukprom(.clk(USB_CLK), .adr(PC), .data(INST));

    always @(posedge USB_CLK) begin

        if(~RESET) begin 

            PC			<= 0;
			CONNECTED	<= 0;
			cond		<= 0;
			INST_READY	<= 0;
			state		<= S_OPCODE;
			timing		<= 0; 
            mbit		<= 0;
			bitadr		<= 0;
			nak			<= 1;
			OE			<= 0;

        end else begin

            dpi			<= USB_Dp;
			dmi 		<= USB_Dm;
            SAVE 		<= 0;													// ensure pulse

            if (INST_READY) begin												// Instruction decoding

                case(state)

                    S_OPCODE: begin

                        INST_H		<= INST;                        
						if (INST == 1) state <= S_LDI0;							// op=ldi

                        if (INST == 3 ) begin									// op=out4
							sadr	<= 3;
							state	<= S_S0;
						 end

                        if (INST == 4) begin 
							OE			<= 9;
							USB_DATA_p	<= 0;
							USB_DATA_m	<= 0;
						 end

                        if (INST == 5) OE	<= 0;

                        if (INST == 6) begin									// op=outb
							sadr	<= 7;
							state	<= S_S0;
						end

                        if (INST[3:2]==2'b10) begin								// op=10xx(BZ,BC,BNAK,DJNZ)
                            state <= S_B0;
                            case (INST[1:0])
                                2'b00: cond <= ~dmi;
                                2'b01: cond <= CONNECTED;
                                2'b10: cond <= nak;
                                2'b11: cond <= wk != 1;
                            endcase
                        end

                        if (INST == 11 | INST == 13 & SAMPLE) wk <= wk - 8'd1;	// op=DJNZ,IN

                        if (INST == 15) begin									// op=jmp
							state <= S_B2;
							cond <= 1;
						 end

                        if (INST == 12) state <= S_TOGGLE0;
                    end

                    // Instructions with operands
                    
				    S_LDI0: begin												// ldi (low nibble)
						wk[3:0] <= INST;
						state <= S_LDI1;
					end
                
				    S_LDI1: begin												// ldi (high nibble)
						wk[7:4] <= INST;
						state <= S_OPCODE;
					end
                    					
                    S_B2: begin													// branch/jmp
						lb4w <= INST;
						state <= S_B0; 
					end

                    S_B0: begin
						lb4  <= INST;
						state <= S_B1; 
					end
                    
					S_B1: begin
						state <= S_OPCODE;
					end
                    
					// out
                    S_S0: begin
						sb[3:0] <= INST;
						state <= S_S1;
					end

                    S_S1: begin
						sb[7:4] <= INST;
						state <= S_S2;
						mbit <= 1;
					end
                    
					S_TOGGLE0: begin											// toggle and save
                        if (INST == 15)
							CONNECTED	<= ~CONNECTED;							// toggle
                        else
							SAVE_R		<= INST;								// save

                        state <= S_TOGGLE1;
                    end

                    S_TOGGLE1: begin
                        if (INST != 15) begin
                            SAVE_B	<= INST;
                            SAVE	<= 1;
                        end

                        state <= S_OPCODE;
                    end
                
				endcase

                // pc control
                if (mbit == 0) begin 
					
                    if (jmppc) NEXT_PC <= PC + 4;
                    
					if (next | branch | retpc) begin

                        if (retpc)
							PC <= NEXT_PC;									// ret
						else if (branch)
                            if (INST_H == 15)								// jmp
                                PC <= { INST, lb4, lb4w, 2'b00 };
                            else											// branch
                                PC <= { 4'b0000, INST, lb4, 2'b00 };
                        else
							PC <= PC + 1;									// next
                        
						INST_READY <= 0;
                    end
                end

			end else begin
			
				INST_READY <= 1;

			end

            // bit transmission (out4/outb)
            if (mbit == 1 && timing == 0) begin

                if(OE==0)
					NRZI_TX_CNT <= 0;
                else
                    if(dbit)
						NRZI_TX_CNT <= NRZI_TX_CNT + 1;
                    else
					    NRZI_TX_CNT <= 0;

				if (INST_H == 4'd6) begin

					if (NRZI_TX_CNT != 6) begin
					
						USB_DATA_p <= dbit ?  USB_DATA_p : ~USB_DATA_p;
						USB_DATA_m <= dbit ? ~USB_DATA_p :  USB_DATA_p;
					
					end	else begin
						USB_DATA_p <= ~USB_DATA_p;
						USB_DATA_m <=  USB_DATA_p;
						NRZI_TX_CNT <= 0;
					end

				end else begin

					USB_DATA_p <=  sb[{1'b1,sadr[1:0]}]; USB_DATA_m <= sb[sadr[2:0]];

				end

                OE <= 1'b1; 

                if (NRZI_TX_CNT != 6) sadr <= sadr - 4'd1;

                if (sadr == 0) begin
					mbit <= 0;
					state <= S_OPCODE;
				end

            end

            // start instruction
            dmid <= dmi;

            if (INST_READY & state == S_OPCODE & INST == 4'b0010) begin 	// op=start 

                bitadr		<= 0; 
				nak			<= 1;
				NRZI_RX_CNT <= 0;

			end else begin 

                if (OE == 0 && dmi != dmid)
					timing <= 1;
                else
					timing <= timing + 1;

			end

            // IN instruction
            if (SAMPLE) begin

                if (bitadr == 8) nak <= dmi;

                if (NRZI_RX_CNT != 6) begin

                    data[6:0]	<= data[7:1]; 
                    data[7]		<= dmis ~^ dmi;		    			// ~^/^~ is XNOR, testing bit equality
                    bitadr		<= bitadr + 1;
					nrzon		<= 0;

				end else begin

					nrzon <= 1;

				end

                dmis <= dmi;
				
                if (dmis ~^ dmi)
					NRZI_RX_CNT <= NRZI_RX_CNT + 1;
                else
				    NRZI_RX_CNT <= 0;

                if (~dmi && ~dpi) DATA_READY <= 0;      			// SE0: packet is finished. Mouses send length 4 reports.
            end

            if (OE == 0) begin
                if (bitadr == 24) DATA_READY <= 1;					// ignore first 3 bytes
                if (bitadr == 88) DATA_READY <= 0;					// output next 8 bytes
            end

            if ((bitadr > 11 & bitadr[2:0] == 3'b000) & (timing == 2)) DATA_OUT <= data;

            // Timing
            interval <= interval_cy ? 0 : interval + 1;
            record1	 <= record;
            if (~record & record1) bank <= ~bank;

            // Connection status & WDT
            DATA_READYd <= DATA_READY;

            nakd <= nak;

            if (DATA_READY && ~DATA_READYd || INST_READY && state == S_OPCODE && INST == 4'b0010) begin
            
			    conct <= 0;											// reset watchdog on data received or START instruction
			
			end else begin 
            
			    if (conct[23:22] != 2'b11) begin
					conct <= conct + 1;
				end else begin 
					PC <= 0; 
					conct <= 0;
				end		// !! WDT ON
            
			end 
        end
    end

    assign USB_Dp = OE ? USB_DATA_p : 1'bZ;
    assign USB_Dm = OE ? USB_DATA_m : 1'bZ;
    assign USB_OE = OE;

    assign SAMPLE = INST_READY & state == S_OPCODE & INST == 4'b1101 & timing == 4; // IN

    assign record = CONNECTED & ~nak;

    assign DATA_STROBE = ~nrzon & DATA_READY & (bitadr[2:0] == 3'b100) & (timing == 2);

endmodule