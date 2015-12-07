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
	reg Start_Sum, Start_BgRemoval, Clk, Reset, Ack;

	output Qi, Qbgi, Qbg, Qbgd, Qbad, Qsi, Qs, Qsd;

	// INCOMING / OUTGOING PIXEL VALUE VARIABLES
	reg [8*num_pixels:0] red_in; // array to hold incoming pixel red values, 2D array mapped to 1D
	reg [8*num_pixels:0] green_in;
	reg [8*num_pixels:0] blue_in;

	reg [8*num_pixels:0] red_out; // array to hold outgoing pixel red values, 2D array mapped to 1D
	reg [8*num_pixels:0] green_out;
	reg [8*num_pixels:0] blue_out;

	pe processor1(Clk, Ack, Reset, red_exp, green_exp, blue_exp, threshold, desired_bg, Start_Sum, Start_BgRemoval,
					red_in, green_in, blue_in, red_out, green_out, blue_out,
					Qi, Qbgi, Qbg, Qbgd, Qbad, Qsi, Qs, Qsd);
	
	// Generate Clock
	initial Clk = 0;
	always #(HalfClkPeriod) Clk = ~Clk;
	
	//Run tests
	initial begin	
	
	#(ClkPeriod);

	$display("Pixels after background replacement are: ");
	for(i = 0; i < 25; i = i + 1) begin
		$display("%d, %d, %d; ", red_out);
	
	end
	
	
endmodule