// Barrel shifter shifting bits of a single word

module barrelshift_single #(
	parameter bit_shift = 3, // bits of shift amount
	parameter n_word = 2**bit_shift // 8, size of word whose bits will be shifted can be thought of as n_word 1bit words
	)(
	input [n_word-1:0] in, // [7:0], ABCD (internal), left to right
	input [bit_shift-1:0] sh, // [2:0] No. of bits to be shifted, 0 ~ 7
	output reg [n_word-1:0] out // [7:0], DABC (internal), left to right, if sh =3
	);

	reg [2*n_word-1:0] out_temp; // [15:0]

	always @(in, sh) begin
		out_temp = {in,in} << sh; 
		out = out_temp[2*n_word-1:n_word]; // [15:8]
		// For example, ABCDABCD => sh = 3 => DABCD000 => DABC (internal), left to right
	end

endmodule
