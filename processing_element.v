module pe(Clk, Ack, Reset, red_exp, green_exp, blue_exp, threshold, desired_bg_r, desired_bg_g, desired_bg_b,
	Start_Sum, Start_BgRemoval, red_in, green_in, blue_in, red_out, green_out, blue_out,
	Qi, Qbgi, Qbg, Qbgd, Qsi, Qs, Qsd, red_sum, green_sum, blue_sum);

parameter num_pixels = 1; // number of pixels that each processing element analyzes

// BG REMOVAL VARIABLES
input [7:0] red_exp;
input [7:0] green_exp;
input [7:0] blue_exp;
input [7:0] threshold;
input [7:0] desired_bg_r, desired_bg_g, desired_bg_b;
input Start_Sum, Start_BgRemoval, Clk, Reset, Ack;

output Qi, Qbgi, Qbg, Qbgd, Qsi, Qs, Qsd;

// INCOMING / OUTGOING PIXEL VALUE VARIABLES
input [8*num_pixels-1:0] red_in; // array to hold incoming pixel red values, 2D array mapped to 1D
input [8*num_pixels-1:0] green_in;
input [8*num_pixels-1:0] blue_in;

output [8*num_pixels-1:0] red_out; // array to hold outgoing pixel red values, 2D array mapped to 1D
output [8*num_pixels-1:0] green_out;
output [8*num_pixels-1:0] blue_out;

output [8*num_pixels-1:0] red_sum;
output [8*num_pixels-1:0] green_sum;
output [8*num_pixels-1:0] blue_sum;

reg [8*num_pixels-1:0] red_out; // array to hold outgoing pixel red values, 2D array mapped to 1D
reg [8*num_pixels-1:0] green_out;
reg [8*num_pixels-1:0] blue_out;

reg [7:0] red[0:num_pixels-1]; // array to hold pixel red values - 2D version, num pixels cells of size 8 bits
reg [7:0] green[0:num_pixels-1];
reg [7:0] blue[0:num_pixels-1];

reg [num_pixels-1:0] counter = 0;
reg [8*num_pixels-1:0] red_sum;
reg [8*num_pixels-1:0] green_sum;
reg [8*num_pixels-1:0] blue_sum;

reg [7:0] temp_r;
reg [7:0] temp_g;
reg [7:0] temp_b;
reg [17:0] distance; // 256*256*3 is maximum possible

// STATE VARIABLES
localparam
IDLE = 7'b0000001, // idle, do nothing
SUM_INIT = 7'b0000010, // sum
SUM_ADD = 7'b0000100,
SUM_DONE = 7'b0001000,
BG_INIT = 7'b0010000, // background subtract and replace
BG_REPLACE = 7'b0100000,
BG_DONE = 7'b1000000;

reg [6:0] state;
assign {Qbgd, Qbg, Qbgi, Qsd, Qs, Qsi, Qi} = state;

always @(posedge Clk, posedge Start_Sum)
begin
 	state <= SUM_INIT;
end 

always @(posedge Clk, posedge Start_BgRemoval)
begin
 	state <= BG_INIT;
end 

always @(posedge Clk, posedge Reset) 
begin
	if(Reset)
	begin
        state <= IDLE;
        // set all values to XXX to avoid recirculating mux from keeping track of unecessary values
		temp_r <= 8'bXXXXXXXX;
		temp_g <= 8'bXXXXXXXX;
		temp_b <= 8'bXXXXXXXX;
		distance <= 18'bXXXXXXXXXXXXXXXXXX;
	end
	case (state)
		IDLE:
		begin
			state <= IDLE;
	        // set all values to XXX to avoid recirculating mux from keeping track of unecessary values
			temp_r <= 8'bXXXXXXXX;
			temp_g <= 8'bXXXXXXXX;
			temp_b <= 8'bXXXXXXXX;
			distance <= 18'bXXXXXXXXXXXXXXXXXX;
		end
	    SUM_INIT: 
	      begin
	        state <= SUM_ADD;
	        counter <= 0;
	        red_sum <= 0;
	        green_sum <= 0;
	        blue_sum <= 0;
	      end
	    SUM_ADD: 
	      begin
	        if(counter == (num_pixels - 1))
	        	state <= SUM_DONE;
	        else begin
	        	state <= SUM_ADD;
	        end
	        red_sum <= red_sum + {red_in[counter*8+7], red_in[counter*8+6], red_in[counter*8+5], red_in[counter*8+4], red_in[counter*8+3], red_in[counter*8+2], red_in[counter*8+1], red_in[counter*8]};
	        green_sum <= green_sum + {green_in[counter*8+7], green_in[counter*8+6], green_in[counter*8+5], green_in[counter*8+4], green_in[counter*8+3], green_in[counter*8+2], green_in[counter*8+1], green_in[counter*8]};
	        blue_sum <= blue_sum + {blue_in[counter*8+7], blue_in[counter*8+6], blue_in[counter*8+5], blue_in[counter*8+4], blue_in[counter*8+3], blue_in[counter*8+2], blue_in[counter*8+1], blue_in[counter*8]};
	        counter <= counter + 1;
	      end
		SUM_DONE:
		begin  
		 if (Ack)
		   state <= IDLE;
		end    
	    BG_INIT: 
	      begin
	        state <= BG_REPLACE;
	        counter <= 0;
	        distance <= 18'b00000000;
	      end
	    BG_REPLACE: 
	      begin
	        if(counter == (num_pixels - 1))
	        	state <= BG_DONE;
	        else begin
	        	state <= BG_REPLACE;
	        end

	        temp_r <= {red_in[counter*8+7], red_in[counter*8+6], red_in[counter*8+5], red_in[counter*8+4], red_in[counter*8+3], red_in[counter*8+2], red_in[counter*8+1], red_in[counter*8]};
	        temp_g <= {green_in[counter*8+7], green_in[counter*8+6], red_in[counter*8+5], green_in[counter*8+4], green_in[counter*8+3], green_in[counter*8+2], green_in[counter*8+1], green_in[counter*8]};
	        temp_b <= {blue_in[counter*8+7], blue_in[counter*8+6], blue_in[counter*8+5], blue_in[counter*8+4], blue_in[counter*8+3], blue_in[counter*8+2], blue_in[counter*8+1], blue_in[counter*8]};

	        // calculate distance squared from expected RGB (to avoid square root operation)
	        distance <= (red_exp - temp_r) * (red_exp - temp_r);
	        distance <= distance + ((green_exp - temp_g) * (green_exp - temp_g));
	        distance <= distance + ((blue_exp - temp_b) * (blue_exp - temp_b));
	        
	        // compare to threshold
	        if(distance > threshold)begin // if true, foreground --> same value
	        	red_out[counter*8] <= temp_r[0]; // temp_r is holding red_in
	        	red_out[counter*8+1] <= temp_r[1];
	        	red_out[counter*8+2] <= temp_r[2];
	        	red_out[counter*8+3] <= temp_r[3];
	        	red_out[counter*8+4] <= temp_r[4];
	        	red_out[counter*8+5] <= temp_r[5];
	        	red_out[counter*8+6] <= temp_r[6];
	        	red_out[counter*8+7] <= temp_r[7];

	        	green_out[counter*8] <= temp_g[0];
	        	green_out[counter*8+1] <= temp_g[1];
	        	green_out[counter*8+2] <= temp_g[2];
	        	green_out[counter*8+3] <= temp_g[3];
	        	green_out[counter*8+4] <= temp_g[4];
	        	green_out[counter*8+5] <= temp_g[5];
	        	green_out[counter*8+6] <= temp_g[6];
	        	green_out[counter*8+7] <= temp_g[7];

	        	blue_out[counter*8] <= temp_b[0];
	        	blue_out[counter*8+1] <= temp_b[1];
	        	blue_out[counter*8+2] <= temp_b[2];
	        	blue_out[counter*8+3] <= temp_b[3];
	        	blue_out[counter*8+4] <= temp_b[4];
	        	blue_out[counter*8+5] <= temp_b[5];
	        	blue_out[counter*8+6] <= temp_b[6];
	        	blue_out[counter*8+7] <= temp_b[7];
			end
	        else begin
	        	{red_out[counter*8],red_out[counter*8+1],red_out[counter*8+2],red_out[counter*8+3],red_out[counter*8+4],red_out[counter*8+5],red_out[counter*8+6],red_out[counter*8+7]} <= desired_bg_r;

	        	green_out[counter*8] <= desired_bg_g[0];
	        	green_out[counter*8+1] <= desired_bg_g[1];
	        	green_out[counter*8+2] <= desired_bg_g[2];
	        	green_out[counter*8+3] <= desired_bg_g[3];
	        	green_out[counter*8+4] <= desired_bg_g[4];
	        	green_out[counter*8+5] <= desired_bg_g[5];
	        	green_out[counter*8+6] <= desired_bg_g[6];
	        	green_out[counter*8+7] <= desired_bg_g[7];

	        	blue_out[counter*8] <= desired_bg_b[0];
	        	blue_out[counter*8+1] <= desired_bg_b[1];
	        	blue_out[counter*8+2] <= desired_bg_b[2];
	        	blue_out[counter*8+3] <= desired_bg_b[3];
	        	blue_out[counter*8+4] <= desired_bg_b[4];
	        	blue_out[counter*8+5] <= desired_bg_b[5];
	        	blue_out[counter*8+6] <= desired_bg_b[6];
	        	blue_out[counter*8+7] <= desired_bg_b[7];
	        	// red_out[counter*8] <= desired_bg_r[0];
	        	// red_out[counter*8+1] <= desired_bg_r[1];
	        	// red_out[counter*8+2] <= desired_bg_r[2];
	        	// red_out[counter*8+3] <= desired_bg_r[3];
	        	// red_out[counter*8+4] <= desired_bg_r[4];
	        	// red_out[counter*8+5] <= desired_bg_r[5];
	        	// red_out[counter*8+6] <= desired_bg_r[6];
	        	// red_out[counter*8+7] <= desired_bg_r[7];

	        	// green_out[counter*8] <= desired_bg_g[0];
	        	// green_out[counter*8+1] <= desired_bg_g[1];
	        	// green_out[counter*8+2] <= desired_bg_g[2];
	        	// green_out[counter*8+3] <= desired_bg_g[3];
	        	// green_out[counter*8+4] <= desired_bg_g[4];
	        	// green_out[counter*8+5] <= desired_bg_g[5];
	        	// green_out[counter*8+6] <= desired_bg_g[6];
	        	// green_out[counter*8+7] <= desired_bg_g[7];

	        	// blue_out[counter*8] <= desired_bg_b[0];
	        	// blue_out[counter*8+1] <= desired_bg_b[1];
	        	// blue_out[counter*8+2] <= desired_bg_b[2];
	        	// blue_out[counter*8+3] <= desired_bg_b[3];
	        	// blue_out[counter*8+4] <= desired_bg_b[4];
	        	// blue_out[counter*8+5] <= desired_bg_b[5];
	        	// blue_out[counter*8+6] <= desired_bg_b[6];
	        	// blue_out[counter*8+7] <= desired_bg_b[7];
	        end
	        counter <= counter + 1;
	      end
	    BG_DONE:
	      begin  
	         if (Ack)
	           state <= IDLE;
	       end    
	endcase
end

endmodule