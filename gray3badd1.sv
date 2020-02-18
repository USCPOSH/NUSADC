module gray3badd1 (
	input [2:0] gray,
	output reg [2:0] grayadd1
	);

	always @(gray) begin
		case (gray)
			3'b000: grayadd1 = 3'b001; // 0 -> 1
			3'b001: grayadd1 = 3'b011; // 1 -> 2
			3'b011: grayadd1 = 3'b010; // 2 -> 3
			3'b010: grayadd1 = 3'b110; // 3 -> 4
			3'b110: grayadd1 = 3'b111; // 4 -> 5
			3'b111: grayadd1 = 3'b101; // 5 -> 6
			3'b101: grayadd1 = 3'b100; // 6 -> 7
			3'b100: grayadd1 = 3'b000; // 7 -> 0
		endcase
	end

endmodule