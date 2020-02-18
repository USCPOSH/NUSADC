module demux_gray_1to8 (
	input i, // pulse
	input [2:0] sel, // Selector bits, (gray)
	output i_demuxed [0:7] // demux parallel pulse
	);

	assign i_demuxed[0]  = (sel == 3'b000) ? i : 0;
	assign i_demuxed[1]  = (sel == 3'b001) ? i : 0;
	assign i_demuxed[2]  = (sel == 3'b011) ? i : 0;
	assign i_demuxed[3]  = (sel == 3'b010) ? i : 0;
	assign i_demuxed[4]  = (sel == 3'b110) ? i : 0;
	assign i_demuxed[5]  = (sel == 3'b111) ? i : 0;
	assign i_demuxed[6]  = (sel == 3'b101) ? i : 0;
	assign i_demuxed[7]  = (sel == 3'b100) ? i : 0;
	
endmodule
