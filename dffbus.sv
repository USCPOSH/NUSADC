module dffbus #(
	parameter word_size = 9)(
	input [word_size-1:0] d,
	input clk,
	input resetb,
	output reg [word_size-1:0] q
	);

	always @(posedge clk, negedge resetb) begin
		q <= (resetb == 1'b0) ? {word_size{1'b0}} : d;
	end
	
endmodule
