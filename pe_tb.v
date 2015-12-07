//Testbench

`timescale 1ns / 1ps

module pe_testbench();

	parameter HalfClkPeriod = 5;
	localparam ClkPeriod = 2*HalfClkPeriod;
	localparam num_processors = 1;
	reg Clk;
	
	parameter num_pixels = 4;

	// BG REMOVAL VARIABLES
	reg [7:0] red_exp;
	reg [7:0] green_exp;
	reg [7:0] blue_exp;
	reg [7:0] threshold;
	reg [7:0] desired_bg_r, desired_bg_g, desired_bg_b;
	reg Start_Sum, Start_BgRemoval, Reset, Ack;
	reg [7:0] output_red, output_green, output_blue;

	wire Qi, Qbgi, Qbg, Qbgd, Qsi, Qs, Qsd;

	// INCOMING / OUTGOING PIXEL VALUE VARIABLES
	reg [8*num_pixels-1:0] red_in; // array to hold incoming pixel red values, 2D array mapped to 1D
	reg [8*num_pixels-1:0] green_in;
	reg [8*num_pixels-1:0] blue_in;

	wire [8*num_pixels-1:0] red_out; // array to hold outgoing pixel red values, 2D array mapped to 1D
	wire [8*num_pixels-1:0] green_out;
	wire [8*num_pixels-1:0] blue_out;
	
	wire [8*num_pixels-1:0] red_sum;
	wire [8*num_pixels-1:0] green_sum;
	wire [8*num_pixels-1:0] blue_sum;
	
	integer i;

	pe processor1(Clk, Ack, Reset, red_exp, green_exp, blue_exp, threshold, desired_bg_r, desired_bg_g, desired_bg_b, Start_Sum, Start_BgRemoval,
					red_in, green_in, blue_in, red_out, green_out, blue_out,
					Qi, Qbgi, Qbg, Qbgd, Qsi, Qs, Qsd, red_sum, green_sum, blue_sum);
	
	// Generate Clock
	initial Clk = 0;
	always #(HalfClkPeriod) Clk = ~Clk;
	
	//Run tests
	initial begin	
	
		Reset = 1; // perform reset 
		#(5*ClkPeriod+HalfClkPeriod); 
		Reset = 0;
		#(ClkPeriod);
		
		red_in <= {8'd61,8'd61,8'd61,8'd204};
		green_in <= {8'd133,8'd133,8'd133,8'd0};
		blue_in <= {8'd198,8'd198,8'd198,8'd0};
		Start_Sum <= 1;
		Start_BgRemoval <= 0;
		Reset <= 0;
		Ack <= 0;
		
		#(ClkPeriod);
		
		Ack <= 1;
		Start_Sum <= 0;

		// don't know how long summing will take, so loop until you enter done state
		while(~Qsd)
		begin
			#(HalfClkPeriod);
		end
		
		// TEST: blue, blue, blue, red
		// set values for background removal
		red_in <= {8'd61,8'd61,8'd61,8'd204};
		green_in <= {8'd133,8'd133,8'd133,8'd0};
		blue_in <= {8'd198,8'd198,8'd198,8'd0};
		threshold <= 60; // threshold value

		red_exp <= red_sum / num_processors; // TODO: red_sum1 + red_sum2 for the different processors
		green_exp <= green_sum / num_processors;
		blue_exp <= blue_sum / num_processors;

		desired_bg_r <= 8'd106; // new background rgb (light green)
		desired_bg_g <= 8'd168;
		desired_bg_b <= 8'd79;

		Start_BgRemoval <= 1; // signal bg removal to start
		#(ClkPeriod);
		Start_BgRemoval <= 0;
		
		while(~Qbgd)
		begin
			#(HalfClkPeriod);
		end

		$display("Pixels after background replacement are: ");
		for(i = 0; i < num_pixels; i = i + 1) begin
			output_red = {red_out[i*8+7], red_out[i*8+6], red_out[i*8+5], red_out[i*8+4], red_out[i*8+3], red_out[i*8+2], red_out[i*8+1], red_out[i*8]};
			output_green = {green_out[i*8+7], green_out[i*8+6], green_out[i*8+5], green_out[i*8+4], green_out[i*8+3], green_out[i*8+2], green_out[i*8+1], green_out[i*8]};
			output_blue = {blue_out[i*8+7], blue_out[i*8+6], blue_out[i*8+5], blue_out[i*8+4], blue_out[i*8+3], blue_out[i*8+2], blue_out[i*8+1], blue_out[i*8]};
			$display("%d,%d,%d;", output_red, output_green, output_blue);
		end
	
	
		#(ClkPeriod);
	
	end
	
	
endmodule