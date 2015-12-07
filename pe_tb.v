//Testbench

`timescale 1ns / 1ps

module pe_testbench();

	parameter HalfClkPeriod = 5;
	localparam ClkPeriod = 2*HalfClkPeriod;
	reg Clk;
	
	parameter num_pixels = 1;

	// BG REMOVAL VARIABLES
	reg [8:0] red_exp;
	reg [8:0] green_exp;
	reg [8:0] blue_exp;
	reg threshold;
	reg [8:0] desired_bg;
	reg Start_Sum, Start_BgRemoval, Reset, Ack;

	//reg Qi, Qbgi, Qbg, Qbgd, Qbad, Qsi, Qs, Qsd;

	// INCOMING / OUTGOING PIXEL VALUE VARIABLES
	reg [8*num_pixels:0] red_in; // array to hold incoming pixel red values, 2D array mapped to 1D
	reg [8*num_pixels:0] green_in;
	reg [8*num_pixels:0] blue_in;

	wire [8*num_pixels:0] red_out; // array to hold outgoing pixel red values, 2D array mapped to 1D
	wire [8*num_pixels:0] green_out;
	wire [8*num_pixels:0] blue_out;
	
	wire [8*num_pixels:0] red_sum;
	wire [8*num_pixels:0] green_sum;
	wire [8*num_pixels:0] blue_sum;
	
	integer i;

	pe processor1(Clk, Ack, Reset, red_exp, green_exp, blue_exp, threshold, desired_bg, Start_Sum, Start_BgRemoval,
					red_in, green_in, blue_in, red_out, green_out, blue_out,
					Qi, Qbgi, Qbg, Qbgd, Qbad, Qsi, Qs, Qsd, red_sum, green_sum, blue_sum);
	
	// Generate Clock
	initial Clk = 0;
	always #(HalfClkPeriod) Clk = ~Clk;
	
	//Run tests
	initial begin	
	
		Reset = 1; // perform reset 
		#(5*ClkPeriod+HalfClkPeriod); 
		Reset = 0;
		#(ClkPeriod);
		
		red_in <= 61;
		green_in <= 133;
		blue_in <= 198;
		red_exp <= 61;
		green_exp <= 133;
		blue_exp <= 198;
		Start_Sum <= 1;
		Start_BgRemoval <= 0;
		Reset <= 0;
		Ack <= 0;
		desired_bg <= 10;
		
		#(ClkPeriod);
		
		Ack <= 1;
		Start_Sum <= 0;
		
		#50;
		
		Start_BgRemoval <= 1;
		#(ClkPeriod);
		Start_BgRemoval <= 0;
		
		#50;

		$display("Pixels after background replacement are: ");
		for(i = 0; i < 25; i = i + 1) begin
			$display("%d, %d, %d; ", red_out, green_out, blue_out);
		end
	
	
		#(ClkPeriod);
	
	end
	
	
endmodule