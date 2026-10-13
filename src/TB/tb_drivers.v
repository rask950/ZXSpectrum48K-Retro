
module top (
	input clk,
    output [1:0]led
);

wire xx;

reg [31:0]cnt;

initial begin
    cnt = 0;
end

always @(posedge clk) begin

    cnt <= cnt + 1;

end

a a_inst (
    .clk(cnt[26]),
	.outp(xx)
);

a a_inst2 (
    .clk(cnt[27]),
	.outp(xx)
);

endmodule

module a (
    input clk,
	output outp
);

assign outp = clk;

endmodule	