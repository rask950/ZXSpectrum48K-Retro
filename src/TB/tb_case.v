`timescale 1ns / 1ps

module top(
	input sys_clk
);

reg 		data;
reg 		[1:0] cnt;

initial begin
	data = 1'b0;
	cnt = 0;
	$monitor("data = %b, cnt = %b", data, cnt);

end

always @(*) begin

	case(data)
		1'b0: cnt = cnt + 2'b01;
		1'b1: cnt = cnt + 2'b11;
		1'b0: cnt = cnt + 2'b10;
	endcase

end

endmodule
