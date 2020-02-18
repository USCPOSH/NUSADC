module data_parse (
	input clk_sys, //resample clock
	input resetb, // asynchronous reset
	input [74:0] data_out_asyncfifo,
	output reg [74:0] data_out_parsed, // 8 samples (8*9-bit) + nsamp (2-bit)
	output [6:0] delta_t_out [0:7]
	);
	
	reg [8:0] data_last1_old_temp;
	
	reg [8:0] data_last1_old;
	reg [8:0] data_first1_now;
	reg [8:0] data_last1_now;	
	
	reg [74:0] data_out_parsed_after_add;
	
	reg [8:0] data0_now, data1_now, data2_now, data3_now, data4_now, data5_now, data6_now, data7_now;
	reg [2:0] nus_now;
	
	reg [8:0] delta_t [0:7];
	
	always @ (*) begin
		nus_now = data_out_asyncfifo[2:0];
		data0_now = data_out_asyncfifo[11:3];
		data1_now = data_out_asyncfifo[20:12];
		data2_now = data_out_asyncfifo[29:21];
		data3_now = data_out_asyncfifo[38:30];
		data4_now = data_out_asyncfifo[47:39];
		data5_now = data_out_asyncfifo[56:48];
		data6_now = data_out_asyncfifo[65:57];
		data7_now = data_out_asyncfifo[74:66];
	end
	
	always @ (*) begin
		data_first1_now = data_out_asyncfifo[11:3];
	end
	
	// data_out_asyncfifo_LSB: earlist NUS,  data_out_asyncfifo_MSB: latest 
	// last1 = latest sample of NUS, last2 = latest - 1 sample of NUS, last1 > last 2 
	// early----------------------------------------------------------------------late
	// last2_old < last1_old > first1_now < first2_now < last2_now < last1_now > first1_next < first2_next
	always @ (*) begin
		case (nus_now)
			3'b001: begin
				data_last1_now = data_out_asyncfifo[11:3];
				end

			3'b010: begin
				data_last1_now = data_out_asyncfifo[20:12];
				end			
		
			3'b011: begin
				data_last1_now = data_out_asyncfifo[29:21];
				end	

			3'b100: begin
				data_last1_now = data_out_asyncfifo[38:30];
				end	
				
			3'b101: begin
				data_last1_now = data_out_asyncfifo[47:39];
				end			
		
			3'b110: begin
				data_last1_now = data_out_asyncfifo[56:48];
				end			

			3'b111: begin
				data_last1_now = data_out_asyncfifo[65:57];
				end					
		
			3'b000: begin
				data_last1_now = data_out_asyncfifo[74:66];
				end				
		endcase
	end
	
	assign data_last1_old_temp = data_last1_now;	
	
	always @ (posedge clk_sys, negedge resetb) begin
		if (~resetb) begin
			data_last1_old <= 9'b0;
		end else begin
			data_last1_old <= data_last1_old_temp;
		end
	end
	
		
	/*
	always @ (posedge clk_sys, negedge resetb) begin
		if (~resetb) begin
			data_out_parsed_after_add <= 75'b0;
		end
	end	
	*/


	reg [8:0] data0_parsed_after_add, data1_parsed_after_add, data2_parsed_after_add, data3_parsed_after_add, data4_parsed_after_add, data5_parsed_after_add, data6_parsed_after_add, data7_parsed_after_add;
	reg [2:0] nus_parsed_after_add;
	
	always @ (*) begin
		nus_parsed_after_add = data_out_parsed_after_add[2:0];
		data0_parsed_after_add = data_out_parsed_after_add[11:3];
		data1_parsed_after_add = data_out_parsed_after_add[20:12];
		data2_parsed_after_add = data_out_parsed_after_add[29:21];
		data3_parsed_after_add = data_out_parsed_after_add[38:30];
		data4_parsed_after_add = data_out_parsed_after_add[47:39];
		data5_parsed_after_add = data_out_parsed_after_add[56:48];
		data6_parsed_after_add = data_out_parsed_after_add[65:57];
		data7_parsed_after_add = data_out_parsed_after_add[74:66];
	end
	
	
	// fvco_max = 2.8G, delta_t_min = 48 => MSB will not be the same
	// fvco_min = 357MHz, delta_t_max = 383
	
	// Case 1: clk_sys later than code<0>, some samples may locate in the previous cycle, some current samples may need to remove
	// Data push to the next cycle due to metastability is also be solved 
	// IF last1_old_MSB < first1_now_MSB => last1_old always valid (*)
	// IF last1_old_MSB = first1_now_MSB => last1_old always invalid
	// IF last1_old_MSB > first1_now_MSB => last1_old always invalid
	

	always @ (posedge clk_sys, negedge resetb) begin
		if (~resetb) begin
			data_out_parsed_after_add <= 75'b0;
		end	
		else if (data_last1_old[8:5] < data_first1_now[8:5]) begin //last1_old is valid, attach last1_old at the LSB of data_now
			if (nus_now==3'b001) begin //1 -> 2
				data_out_parsed_after_add <= {data_out_asyncfifo[65:3], data_last1_old, 3'b010};
			end
			else if (nus_now==3'b010) begin //2 -> 3
				data_out_parsed_after_add <= {data_out_asyncfifo[65:3], data_last1_old, 3'b011};
			end
			else if (nus_now==3'b011) begin //3 -> 4
				data_out_parsed_after_add <= {data_out_asyncfifo[65:3], data_last1_old, 3'b100};
			end
			else if (nus_now==3'b100) begin //4 -> 5
				data_out_parsed_after_add <= {data_out_asyncfifo[65:3], data_last1_old, 3'b101};
			end
			else if (nus_now==3'b101) begin //5 -> 6
				data_out_parsed_after_add <= {data_out_asyncfifo[65:3], data_last1_old, 3'b110};
			end
			else if (nus_now==3'b110) begin //6 -> 7
				data_out_parsed_after_add <= {data_out_asyncfifo[65:3], data_last1_old, 3'b111};
			end
			else if (nus_now==3'b111) begin //7 -> 0
				data_out_parsed_after_add <= {data_out_asyncfifo[65:3], data_last1_old, 3'b000};
			end		
			else begin// if FIFO already has 8 samples, push out data7 and keep nus = 0, data7 should be invalid becaus max NUS = 8
				data_out_parsed_after_add <= {data_out_asyncfifo[65:3], data_last1_old, 3'b000};
			end	
		end 
		else begin
			data_out_parsed_after_add <= data_out_asyncfifo;
		end
	end
	
	
	reg [3:0] data0_parsed_after_add_MSB, data1_parsed_after_add_MSB, data2_parsed_after_add_MSB, data3_parsed_after_add_MSB, data4_parsed_after_add_MSB, data5_parsed_after_add_MSB, data6_parsed_after_add_MSB, data7_parsed_after_add_MSB;
	always @(*) begin
		data0_parsed_after_add_MSB = data0_parsed_after_add [8:5];
		data1_parsed_after_add_MSB = data1_parsed_after_add [8:5];
		data2_parsed_after_add_MSB = data2_parsed_after_add [8:5];
		data3_parsed_after_add_MSB = data3_parsed_after_add [8:5];
		data4_parsed_after_add_MSB = data4_parsed_after_add [8:5];
		data5_parsed_after_add_MSB = data5_parsed_after_add [8:5];
		data6_parsed_after_add_MSB = data6_parsed_after_add [8:5];
		data7_parsed_after_add_MSB = data7_parsed_after_add [8:5];
	end
	
	
	reg [8:0] data_last1_parsed;
	//reg [2:0] nus_out;
	// Remove data, from data7
	always @ (posedge clk_sys) begin
		case (nus_parsed_after_add)
			3'b001: begin // do not need to remove
				data_out_parsed <= data_out_parsed_after_add;
				data_last1_parsed <= data_out_parsed_after_add[11:3];
				//nus_out <= 3'b001; // 1 -> 1
				end

			3'b010: begin
					if (data1_parsed_after_add_MSB <= data0_parsed_after_add_MSB) begin //remove data1
						//nus_out <= 3'b001; // 2 -> 1
						data_out_parsed <= {data_out_parsed_after_add[74:21]>>9, data_out_parsed_after_add[11:3], 3'b001};
						data_last1_parsed <= data_out_parsed_after_add[11:3];
					end			
					else begin
						data_out_parsed <= data_out_parsed_after_add;
						data_last1_parsed <= data_out_parsed_after_add[20:12];
						//nus_out <= nus_parsed_after_add;
					end
				end
				
			3'b011: begin
					if (data2_parsed_after_add_MSB <= data1_parsed_after_add_MSB) begin // remove data2
						//nus_out <= 3'b010; // 3 -> 2
						data_out_parsed <= {data_out_parsed_after_add[74:30]>>9, data_out_parsed_after_add[20:3], 3'b010};
						data_last1_parsed <= data_out_parsed_after_add[20:12];
					end			
					else begin
						data_out_parsed <= data_out_parsed_after_add;
						data_last1_parsed <= data_out_parsed_after_add[29:21];
						//nus_out <= nus_parsed_after_add;
					end
				end
				
			3'b100: begin
					if (data3_parsed_after_add_MSB <= data2_parsed_after_add_MSB) begin // remove data3
						//nus_out <= 3'b011; // 4 -> 3
						data_out_parsed <= {data_out_parsed_after_add[74:39]>>9, data_out_parsed_after_add[29:3], 3'b011};
						data_last1_parsed <= data_out_parsed_after_add[29:21];
					end			
					else begin
						data_out_parsed <= data_out_parsed_after_add;
						data_last1_parsed <= data_out_parsed_after_add[38:30];
						//nus_out <= nus_parsed_after_add;
					end
				end
				
			3'b101: begin
					if (data4_parsed_after_add_MSB <= data3_parsed_after_add_MSB) begin // remove data4
						//nus_out <= 3'b100; // 5 -> 4
						data_out_parsed <= {data_out_parsed_after_add[74:48]>>9, data_out_parsed_after_add[38:3], 3'b100};
						data_last1_parsed <= data_out_parsed_after_add[38:30];
					end			
					else begin
						data_out_parsed <= data_out_parsed_after_add;
						data_last1_parsed <= data_out_parsed_after_add[47:39];
						//nus_out <= nus_parsed_after_add;
					end
				end		
		
			3'b110: begin
					if (data5_parsed_after_add_MSB <= data4_parsed_after_add_MSB) begin // remove data5
						//nus_out <= 3'b101; // 6 -> 5
						data_out_parsed <= {data_out_parsed_after_add[74:57]>>9, data_out_parsed_after_add[47:3], 3'b101};
						data_last1_parsed <= data_out_parsed_after_add[47:39];
					end			
					else begin
						data_out_parsed <= data_out_parsed_after_add;
						data_last1_parsed <= data_out_parsed_after_add[56:48];
						//nus_out <= nus_parsed_after_add;
					end
				end			

			3'b111: begin
					if (data6_parsed_after_add_MSB <= data5_parsed_after_add_MSB) begin // remove data6
						//nus_out <= 3'b110; // 7 -> 6
						data_out_parsed <= {data_out_parsed_after_add[74:66]>>9, data_out_parsed_after_add[56:3], 3'b110};
						data_last1_parsed <= data_out_parsed_after_add[56:48];
					end			
					else begin
						data_out_parsed <= data_out_parsed_after_add;
						data_last1_parsed <= data_out_parsed_after_add[65:57];
						//nus_out <= nus_parsed_after_add;
					end
				end					
		
			3'b000: begin
					if (data7_parsed_after_add_MSB <= data6_parsed_after_add_MSB) begin // remove data7
						//nus_out <= 3'b111; // 0 -> 7
						data_out_parsed <= {{9{1'b0}}, data_out_parsed_after_add[65:3], 3'b111};
						data_last1_parsed <= data_out_parsed_after_add[65:57];
					end			
					else begin
						data_out_parsed <= data_out_parsed_after_add;
						data_last1_parsed <= data_out_parsed_after_add[74:66];
						//nus_out <= nus_parsed_after_add;
					end
				end	

		endcase
		
		
	end
	
	// Calculte delta t
	reg [8:0] data_last1_parsed_delay;
	always @ (posedge clk_sys, negedge resetb) begin
		if (~resetb) begin
			delta_t[0] <= 9'b0;
			delta_t[1] <= 9'b0;
			delta_t[2] <= 9'b0;
			delta_t[3] <= 9'b0;
			delta_t[4] <= 9'b0;
			delta_t[5] <= 9'b0;
			delta_t[6] <= 9'b0;
			delta_t[7] <= 9'b0;
			data_last1_parsed_delay <= 9'b0;
		end
		else begin 
			data_last1_parsed_delay <= data_last1_parsed;
			
			if (data_out_parsed[11:3] != data_last1_parsed_delay) begin // Check MSB
				delta_t[0] <= data_out_parsed[11:3] + 9'd384 - data_last1_parsed_delay;
			end else begin
				delta_t[0] <= 8'd0;
			end
			
			if (data_out_parsed[20:17] > data_out_parsed[11:8]) begin // Check MSB
				delta_t[1] <= data_out_parsed[20:12] - data_out_parsed[11:3];
			end else begin
				delta_t[1] <= 8'd0;
			end
			
			if (data_out_parsed[29:26] > data_out_parsed[20:17]) begin
				delta_t[2] <= data_out_parsed[29:21] - data_out_parsed[20:12];
			end else begin
				delta_t[2] <= 8'd0;
			end
			
			if (data_out_parsed[38:35] > data_out_parsed[29:26]) begin
				delta_t[3] <= data_out_parsed[38:30] - data_out_parsed[29:21];
			end else begin
				delta_t[3] <= 8'd0;
			end
			
			if (data_out_parsed[47:44] > data_out_parsed[38:35]) begin
				delta_t[4] <= data_out_parsed[47:39] - data_out_parsed[38:30];
			end else begin
				delta_t[4] <= 8'd0;
			end
			
			if (data_out_parsed[56:53] > data_out_parsed[47:44]) begin
				delta_t[5] <= data_out_parsed[56:48] - data_out_parsed[47:39];
			end else begin
				delta_t[5] <= 8'd0;
			end
			
			if (data_out_parsed[65:62] > data_out_parsed[56:53]) begin
				delta_t[6] <= data_out_parsed[65:57] - data_out_parsed[56:48];
			end else begin
				delta_t[6] <= 8'd0;
			end
			
			if (data_out_parsed[74:71] > data_out_parsed[65:62]) begin
				delta_t[7] <= data_out_parsed[74:66] - data_out_parsed[65:57];
			end else begin
				delta_t[7] <= 8'd0;
			end
			
		end
	end
			
	assign delta_t_out[0] = delta_t[0][6:0];
	assign delta_t_out[1] = delta_t[1][6:0];
	assign delta_t_out[2] = delta_t[2][6:0];
	assign delta_t_out[3] = delta_t[3][6:0];
	assign delta_t_out[4] = delta_t[4][6:0];
	assign delta_t_out[5] = delta_t[5][6:0];
	assign delta_t_out[6] = delta_t[6][6:0];
	assign delta_t_out[7] = delta_t[7][6:0];
	
endmodule
