module barrelshift_multi #(
	parameter bit_shift = 3, // size of shift amount
	parameter n_word = 2**bit_shift, // number of words
	parameter word_size = 9 // no. of bits in each word
	)(
	input [word_size-1:0] in [n_word-1:0], // ABCD (external) => DCBA (internal), bottom to top
	input [bit_shift-1:0] sh, // [2:0], shifted by 0 ~ 7
	output reg [word_size-1:0] out [n_word-1:0] // CBAD (internal) => DABC (external), bottom to top, if sh =3
	);

	wire [n_word-1:0] in_trans [word_size-1:0]; // Holds transpose of input matrix, ABCD (internal), left to right
	wire [n_word-1:0] out_trans [word_size-1:0]; // Holds transpose of output matrix, DABC (internal), left to right, if sh =3

	// Transpose input and output
	generate
		genvar i,j;
		for (i = word_size - 1; i>=0; i--) begin : transpose_outer
			for (j = n_word-1; j>=0; j--) begin : transpose_inner
				assign in_trans[i][j] = in[j][i];
				assign out[j][i] = out_trans[i][j];
			end
		end
	endgenerate

	// Actual shifting
	generate
		genvar k;
		for (k = word_size - 1; k>=0; k--) begin : barrelshifters
			barrelshift_single #(.bit_shift(bit_shift)) barrelshifter_1b (.in(in_trans[k]), .sh(sh), .out(out_trans[k]));
		end
	endgenerate

endmodule
