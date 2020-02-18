// Event-Driven FIFO, to capture NU data and output data uniformly
// Uses synchronizer and extra DFF to pass pointers
// Output (75-bit) = 8 samples (8*9-bit) + nsamp (3-bit) after barrel shifting

module asyncfifo #(
	parameter fifo_depth = 8, // max no. of NUS possible within 1 resample period
	parameter bit_cnt = 3, // no. of counter bits = log2(fifo_depth)
	parameter word_size = 9 // size of input = 9-bit time code
	)(
	input pulse_in, // nonunirom clock
	input [word_size-1:0] data_in, // input data [8:0]
	input clk_in, //resample clock
	input resetb, // global asynchronous reset
	output reg [74:0] data_out_lumped // 8 samples (8*9-bit) + nsamp (3-bit)
	);

	// Internal wires
	wire pulse_demuxed [0:fifo_depth-1]; // [0:7] demux output = 3-bit pulse_in, 1 of which is 1, others are all 0
	wire [bit_cnt-1:0] sel_demux; // [2:0] demux control bits
	wire [bit_cnt-1:0] e, em1, s; // output of asf_pointersync
	wire [word_size-1:0] data_out_async_dff [0:fifo_depth-1]; // [8:0]x[0:7] outputs from async_dffbank, which go to sync dff bank
	wire [word_size-1:0] data_out_sync_dff [0:fifo_depth-1]; // [8:0]x[0:7] outputs from sync dffbank, which go to barrel shifter
	wire [word_size-1:0] data_out_barrelshift [0:fifo_depth-1]; // [8:0]x[0:7] temporarily store all outputs of barrel shifter
	wire [word_size-1:0] data_out [0:fifo_depth-1]; // [8:0]x[0:7], bank of outputs
	wire [bit_cnt-1:0] nsamp; // [2:0] No. of valid samples. This is between 1 and 8.
	
	// Module instantiations => Functionality starts here
	asf_pointersync #(.bit_cnt(bit_cnt)) asyncfifo_pointer (.pulse(pulse_in), .clk(clk_in), .resetb(resetb), .count_gray(sel_demux), .e(e), .em1(em1), .s(s)); // sel_demux changes at the falling edge of pulse_in
	
	demux_gray_1to8 pulse_demux (.i(pulse_in), .sel(sel_demux), .i_demuxed(pulse_demuxed)); // 8 outputs, 1 of which is selected, others are 0

	generate // async_dffbank [8:0]x[0:7]
		genvar async_index;
		for (async_index = 0; async_index<fifo_depth; async_index++) begin : async_dffbank // async_index = 0 to 7
			dffbus #(.word_size(word_size)) async_dffbank (.d(data_in), .clk(pulse_demuxed[async_index]), .resetb(resetb), .q(data_out_async_dff[async_index])); 
			// non-uniform data is latched by the rising edge of pulse_in, need to take care of the setup time in analog. This solves the issue of counter and data change at the same time
		end
	endgenerate


	generate // sync_dffbank [8:0]x[0:7], first resampling, resmpling[n]
		genvar sync_index;
		for (sync_index = 0; sync_index<fifo_depth; sync_index++) begin : sync_dffbank // sync_index = 0 to 7
			dffbus #(.word_size(word_size)) sync_dffbank (.d(data_out_async_dff[sync_index]), .clk(clk_in), .resetb(resetb), .q(data_out_sync_dff[sync_index])); // resample entire async_dffbank into sync_dffbank, no matter data is new or old
		end
	endgenerate

	/*At first respmpling[n], FIRST "POSSIBLE" VALID sample in sync_FIFO data is e[n].
	Left shift, i.e. against the direction of vector growth is done.
	So if we shift them by e[n], => FIRST "POSSIBLE" VALID sample begins at 0 always */
	barrelshift_multi #(.bit_shift(bit_cnt),.word_size(word_size)) barrelshifter (.in(data_out_sync_dff), .sh(e), .out(data_out_barrelshift));

	generate // sync2_dffbank [8:0]x[0:7]
		genvar sync2_index;
		for (sync2_index = 0; sync2_index<fifo_depth; sync2_index++) begin : sync2_dffbank // sync2_index = 0 to 7
			dffbus #(.word_size(word_size)) sync2_dffbank (.d(data_out_barrelshift[sync2_index]), .clk(clk_in), .resetb(resetb), .q(data_out[sync2_index]));
		end
	endgenerate

	// Find no. of valid samples = nsamp.
	assign nsamp = em1 - s; // Before sync2_dffbank, at first resmpling[n], # of new samples are (em1[n+1] - s[n+1]). After sync2_dffbank, at first resmpling[n], # of new samples are (em1[n] - s[n])

	// Data lumped and masked
	always @ (posedge clk_in or negedge resetb) begin
		if (~resetb)
			data_out_lumped = {75{1'b0}};
		else if (nsamp==3'b001)
			data_out_lumped = {{63{1'b0}}, data_out[0], nsamp};
		else if (nsamp==3'b010)
			data_out_lumped = {{54{1'b0}}, data_out[1], data_out[0], nsamp};
		else if (nsamp==3'b011)
			data_out_lumped = {{45{1'b0}}, data_out[2], data_out[1], data_out[0], nsamp};
		else if (nsamp==3'b100)
			data_out_lumped = {{36{1'b0}}, data_out[3], data_out[2], data_out[1], data_out[0], nsamp};
		else if (nsamp==3'b101)
			data_out_lumped = {{27{1'b0}}, data_out[4], data_out[3], data_out[2], data_out[1], data_out[0], nsamp};
		else if (nsamp==3'b110)
			data_out_lumped = {{18{1'b0}}, data_out[5], data_out[4], data_out[3], data_out[2], data_out[1], data_out[0], nsamp};
		else if (nsamp==3'b111)
			data_out_lumped = {{9{1'b0}}, data_out[6], data_out[5], data_out[4], data_out[3], data_out[2], data_out[1], data_out[0], nsamp};
		else
			data_out_lumped = {data_out[7], data_out[6], data_out[5], data_out[4], data_out[3], data_out[2], data_out[1], data_out[0], nsamp};
	end	
	
endmodule
