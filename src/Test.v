

STATE_M1T3L: begin
	CPU_REG_NUM			<= { 1'b0, OPCODE_REG[5:4] };			// Decode reg set 0 - BC/DE/HL/IX/IY/SP
	FSM_NEXT_STATE		<= STATE_M1T4H;
end

STATE_M1T4H: begin
	`REG_WZ				<= REG.R16[REG16_INDEX];				// Value to add
end

STATE_M1T4L: begin
	ALU_OPCODE			<= ALU_ADC;								//Add low bytes
	ALU_OP1				<= `CUR_L;
	ALU_OP2				<= `REG_Z;
	ALU_INFLAGS			<= 8'd0;
	FSM_NEXT_STATE		<= STATE_GN1T1H;
end


STATE_GN1T1H: begin												// ALU cycle 1
end

STATE_GN1T1L: begin												// ALU cycle 2
	FSM_NEXT_STATE.T	<= STATE_T2H;
end

STATE_GN1T2H: begin												// ALU cycle 3
end

STATE_GN1T2L: begin												// Low byte result ready
	`CUR_L				<= ALU_RESULT;
	FSM_NEXT_STATE.T	<= STATE_T3H;
end

STATE_GN1T3H: begin
end

STATE_GN1T3L: begin
	FSM_NEXT_STATE.T	<= STATE_T4H;
end

STATE_GN1T4H: begin
end

STATE_GN1T4L: begin
	FSM_NEXT_STATE.T	<= STATE_GN1T1H;
end



STATE_GN2T1H: begin
end

STATE_GN2T1L: begin
	FSM_NEXT_STATE.T	<= STATE_T2H;
end

STATE_GN2T2H: begin
end

STATE_GN2T2L: begin
	FSM_NEXT_STATE.T	<= STATE_T3H;
end

STATE_GN2T3H: begin
end

STATE_GN2T3L: begin
	FSM_LAST_M			<= TRUE;
end
