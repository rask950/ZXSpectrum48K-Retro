PLA_SHR_HXY: begin														// M1 RLC/RL/RRC/RR/SLA/SRA/SLL/SRL (HL/IX+n/IY+n) [4,4,4,3]

	case(FSM_STATE)

		STATE_M1T3L: begin												// M1 (4)
		   `REG_WZ				<= `CUR_HL;								// Base address to temp reg
		end
	
		STATE_MR1T1H: begin												// MR(4) - read value from memory
			ADDRESS_BUS			<= `REG_WZ;
		end

		STATE_MR1T3L: begin
			ALU_OPCODE			<= { 2'b10, OPCODE_REG[5:3] };
			ALU_OP1				<= DATA_BUS;							// Byte read from DATA_BUS to ALU
			ALU_INFLAGS			<= `CUR_F;
			ALU_ENABLED			<= TRUE;								// Low nibble
		end

		STATE_MR1T4H: begin
			ALU_ENABLED		<= FALSE;									// High nibble
		end

		STATE_MR1T4L: begin
			FSM_NEXT_STATE		<= STATE_MW1T1H;						// Begin write back
		end



		STATE_MW1T1H: begin												// MW(3) ADDRESS_BUS still holds correct address
			DATA_OUT			<= ALU_RESULT;
		   `CUR_F				<= ALU_OUTFLAGS;
		end

		STATE_MW1T3L: begin
			FSM_LAST_M			<= TRUE;
		end

	endcase
end

PLA_SHR_HXY: begin														// M1(4/5) RLC/RL/RRC/RR/SLA/SRA/SLL/SRL (HL/IX+n/IY+n) [{4,4,3},5,4,3]

	case(FSM_STATE)

		STATE_M1T3L: begin												// MG(5) For displacement and timing purposes
		   `REG_WZ				<=`CUR_HL;								// Base address to temp reg
			ALU_OPCODE			<= ALU_ADC;								// Prepare to add displacement
			ALU_OP1				<=`CUR_L;								// To temp reg
			ALU_INFLAGS			<= 8'd0;								// Clear carry
			ALU_ENABLE			<= TRUE;								// Add low nibble
		end

		STATE_M1T4H: begin
			ALU_ENABLE			<= FALSE;								// Add high nibble
		end

		STATE_M1T4L: begin
		   `REG_Z				<= ALU_RESULT;							// Low byte result to Z
			ALU_OP1				<=`CUR_H;								// High byte of base address
			ALU_OP2				<= { 8 { ALU_OP2[7] }};					// This is 255 or 0 depending on the sign of OP2
			ALU_INFLAGS			<= ALU_OUTFLAGS;						// Also need the flags for any carry
			ALU_ENABLE			<= TRUE;								// Add low nibble
			FSM_NEXT_STATE.T	<= STATE_T5H;
		end

		STATE_M1T5H: begin
			ALU_ENABLE			<= FALSE;								// Add high nibble
		end	

		STATE_M1T5L: begin
		   `REG_W				<= ALU_RESULT;							// High byte result to W - Ignore flags
			FSM_NEXT_STATE		<= STATE_MR1T1H;
		end


	
		STATE_MR1T1H: begin												// MR(4) - read value from memory
			ADDRESS_BUS			<= `REG_WZ;
		end

		STATE_MR1T3L: begin
			ALU_OPCODE			<= { 2'b10, OPCODE_REG[5:3] };
			ALU_OP1				<= DATA_BUS;							// Byte read from DATA_BUS to ALU
			ALU_INFLAGS			<= `CUR_F;
			ALU_ENABLED			<= TRUE;								// Low nibble
		end

		STATE_MR1T4H: begin
			ALU_ENABLED		<= FALSE;									// High nibble
		end

		STATE_MR1T4L: begin
			FSM_NEXT_STATE		<= STATE_MW1T1H;						// Begin write back
		end



		STATE_MW1T1H: begin												// MW(3) ADDRESS_BUS still holds correct address
			DATA_OUT			<= ALU_RESULT;
		   `CUR_F				<= ALU_OUTFLAGS;
		end

		STATE_MW1T3L: begin
			FSM_LAST_M			<= TRUE;
		end

	endcase
end
