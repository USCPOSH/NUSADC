module asf_pointersync #(
	parameter bit_cnt = 3 // number of bit in counter
	)(
	input pulse, // nonuniform pulse
	input clk, // Resampling clock
	input resetb, // resets all DFFbus values to zero
	output [2:0] count_gray, // counter value (gray), it changes at the falling edge of the pulse.
							 // For pulse[n], it will trigger count_gray[n] at the falling edge, which means at the rising edge, the count value will be (count_gray[n] - 1). 
	                         //(count_gray[n] - 1) will be the async_FIFO address of the nonuniform data[n] (changes at rising edge) written in.
	output [2:0] e, // count_gray sampled by resampling clk (TWICE) and converted to binary. 
	output [2:0] em1, // e minus one (bin).
	output [2:0] s // em1 (bin) delayed by resampling clk (ONECE). s[n] = em1[n-1].
	);

	wire [2:0] count_bin, // counter value (gray) converted to binary
		count_next_bin, // counter incremented by 1 (binary)
		count_next_gray, //incremented counter value converted back to gray
		count_gray_sync, // retimed by resampling clock
		count_gray_sync2; // one delay from count_gray_sync
		
	wire [2:0] e_temp;

	dffbus #(.word_size(bit_cnt)) gray_counter (.d(count_next_gray), .clk(~pulse), .resetb(resetb), .q(count_gray)); // actual counter, falling edge triggered by pulse

	gray3badd1 grayadd (.gray(count_gray), .grayadd1(count_next_gray)); // generate next count

	dffbus #(.word_size(bit_cnt)) sync1_count_gray (.d(count_gray), .clk(clk), .resetb(resetb), .q(count_gray_sync)); 
	// At first resmpling[n], generate count_gray_sync[n] and data_out_sync_dff[n]. 
	// (count_gray_sync[n] - 1 ) is the LAST VALID sample of data_out_sync_dff[n].
	// retime once: count_gray_sync2[n] = count_gray_sync[n-1]
	// gray to binary: e[n] = count_gray_sync2[n] = count_gray_sync[n-1]
	// By looking at (e[n] - 1) = (count_gray_sync[n-1] - 1), it is the LAST VALID sample of data_out_sync_dff[n-1].
	// ******In other words, e[n] is the FIRST "POSSIBLE" VALID sample in data_out_sync_dff[n].*****
	// em1[n] = e[n] - 1 is the LAST VALID sample of data_out_sync_dff[n-1].
	// em1[n+1] is the LAST VALID sample of data_out_sync_dff[n].
	// retime em1: s[n] = em1[n-1] is the LAST VALID sample of data_out_sync_dff[n-2].
	// Therefore, at first resmpling[n], # of new samples are "LAST VALID sample of data_out_sync_dff[n]" - "FIRST POSSIBLE VALID sample of data_out_sync_dff[n]" + 1 = em1[n+1] - e[n] + 1
	// = em1[n+1] - (e[n] -1) = em1[n+1] - em1[n] = em1[n+1] - s[n+1]	
	// If e[n] > em1[n+1], it is NOT valid yet => nsamp = 0.
	
	dffbus #(.word_size(bit_cnt)) sync2_count_gray (.d(count_gray_sync), .clk(clk), .resetb(resetb), .q(count_gray_sync2)); // second resampling, count_gray_sync2[n] = count_gray_sync[n-1]
	
	gray3btobin count_gray_sync2_to_bin (.gray(count_gray_sync2), .bin(e_temp));
	
	assign e = e_temp; 
	
	assign em1 = e - {{(bit_cnt-1){1'b0}},1'b1};

	dffbus #(.word_size(bit_cnt)) sync1_em1 (.d(em1), .clk(clk), .resetb(resetb), .q(s)); // s[n] = em1[n-1]

endmodule
