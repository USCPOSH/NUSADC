module gray3btobin (
	input [2:0] gray,
	output reg [2:0] bin
	);

	always @(gray) begin
		case (gray)
			3'b000: bin = 3'b000;
			3'b001: bin = 3'b001;
			3'b011: bin = 3'b010;
			3'b010: bin = 3'b011;
			3'b110: bin = 3'b100;
			3'b111: bin = 3'b101;
			3'b101: bin = 3'b110;
			3'b100: bin = 3'b111;			
		endcase
	end

endmodule
