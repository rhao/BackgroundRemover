module pe(Clk, Ack, Reset, red_exp, green_exp, blue_exp, threshold, desired_bg, Start_Sum, Start_BgRemoval,
	red_in, green_in, blue_in, red_out, green_out, blue_out,
	Qi, Qbgi, Qbg, Qbgd, Qbad, Qsi, Qs, Qsd, red_sum, green_sum, blue_sum);

parameter num_pixels = 1; // number of pixels that each processing element analyzes

// BG REMOVAL VARIABLES
input [8:0] red_exp;
input [8:0] green_exp;
input [8:0] blue_exp;
input threshold;
input [8:0] desired_bg;
input Start_Sum, Start_BgRemoval, Clk, Reset, Ack;

output Qi, Qbgi, Qbg, Qbgd, Qbad, Qsi, Qs, Qsd;

// INCOMING / OUTGOING PIXEL VALUE VARIABLES
input [8*num_pixels:0] red_in; // array to hold incoming pixel red values, 2D array mapped to 1D
input [8*num_pixels:0] green_in;
input [8*num_pixels:0] blue_in;

output [8*num_pixels:0] red_out; // array to hold outgoing pixel red values, 2D array mapped to 1D
output [8*num_pixels:0] green_out;
output [8*num_pixels:0] blue_out;

output [8*num_pixels:0] red_sum;
output [8*num_pixels:0] green_sum;
output [8*num_pixels:0] blue_sum;

reg [8*num_pixels:0] red_out; // array to hold outgoing pixel red values, 2D array mapped to 1D
reg [8*num_pixels:0] green_out;
reg [8*num_pixels:0] blue_out;

reg [8:0] red[0:num_pixels]; // array to hold pixel red values - 2D version
reg [8:0] green[0:num_pixels];
reg [8:0] blue[0:num_pixels];

reg [num_pixels:0] counter = 0;
reg [8*num_pixels:0] red_sum;
reg [8*num_pixels:0] green_sum;
reg [8*num_pixels:0] blue_sum;
 
//reg [8*num_pixels:0] index;

integer i;	//For for loop
integer index;

reg [7:0] temp;
reg [17:0] distance; // 256*256*3 is maximum possible

// STATE VARIABLES
localparam
IDLE = 8'b00000001, // idle, do nothing
SUM_INIT = 8'b00000010, // sum
SUM_ADD = 8'b00000100,
SUM_DONE = 8'b00001000,
BG_INIT = 8'b00010000, // background subtract and replace
BG_REPLACE = 8'b00100000,
BG_ALMOST_DONE = 8'b01000000,
BG_DONE = 8'b10000000;

reg [7:0] state;
assign {Qbgd, Qbad, Qbg, Qbgi, Qsd, Qs, Qsi, Qi} = state;

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
        red_out <= 8'bXXXXXXXX; // change based on num_pixels (should be of size 8 * num_pixels)
        green_out <= 8'bXXXXXXXX; // change based on num_pixels
        blue_out <= 8'bXXXXXXXX; // change based on num_pixels

        counter <= 1'bX; // 8 * num_pixels

        red_sum <= 8'bXXXXXXXX; // change based on num_pixels (should be of size 8 * num_pixels)
        green_sum <= 8'bXXXXXXXX; // change based on num_pixels
        blue_sum <= 8'bXXXXXXXX; // change based on num_pixels

		temp <= 8'bXXXXXXXX;
		distance <= 18'bXXXXXXXXXXXXXXXXXX;
	end
	case (state)
		IDLE:
		begin
			state <= IDLE;

	        // set all values to XXX to avoid recirculating mux from keeping track of unecessary values
	        red_out <= 8'bXXXXXXXX; // change based on num_pixels (should be of size 8 * num_pixels)
	        green_out <= 8'bXXXXXXXX; // change based on num_pixels
	        blue_out <= 8'bXXXXXXXX; // change based on num_pixels

	        counter <= 1'bX; // 8 * num_pixels

	        red_sum <= 8'bXXXXXXXX; // change based on num_pixels (should be of size 8 * num_pixels)
	        green_sum <= 8'bXXXXXXXX; // change based on num_pixels
	        blue_sum <= 8'bXXXXXXXX; // change based on num_pixels

			temp <= 8'bXXXXXXXX;
			distance <= 18'bXXXXXXXXXXXXXXXXXX;
		end
	    SUM_INIT: 
	      begin
	        state <= SUM_ADD;
	        counter <= 0;
	        red_sum <= 0;
	        green_sum <= 0;
	        blue_sum <= 0;
	        index <= 0;
	        i <= 0;

	        // map 1D vector to 2D vector
	        for(i = 0; i < num_pixels * 8; i=i+8)
	        begin
	        	red[index] <= 9'd61; //{red_in[i+7], red_in[i+6], red_in[i+5], red_in[i+4], red_in[i+3], red_in[i+1], red_in[i]};
	        	green[index] <= 9'd133; //{green_in[i+7], green_in[i+6], green_in[i+5], green_in[i+4], green_in[i+3], green_in[i+1], green_in[i]};
	        	blue[index] <= 9'd198; //{blue_in[i+7], blue_in[i+6], blue_in[i+5], blue_in[i+4], blue_in[i+3], blue_in[i+1], blue_in[i]};
	        	index = index + 1;
	        end
	      end
	    SUM_ADD: 
	      begin
	        if(counter == num_pixels)
	        	state <= SUM_DONE;
	        else begin
	        	state <= SUM_ADD;
	        end

	        red_sum <= red_sum + red[counter];
	        green_sum <= green_sum + green[counter];
	        blue_sum <= blue_sum + blue[counter];
	        counter <= counter + 1;

	      end
		SUM_DONE:
		begin  
		 // state transitions in the control unit
		 if (Ack)
		   state <= IDLE;
		end    
	    BG_INIT: 
	      begin
	        state <= BG_REPLACE;
	        counter <= 0;
	        i <= 0;
	        index <= 0;
	        distance <= 18'b00000000;

	        // map 1D vector to 2D vector
	        for(i = 0; i < num_pixels * 8; i=i+8)
	        begin
				red[index] <= 9'd61; //{red_in[i+7], red_in[i+6], red_in[i+5], red_in[i+4], red_in[i+3], red_in[i+1], red_in[i]};
	        	green[index] <= 9'd133; //{green_in[i+7], green_in[i+6], green_in[i+5], green_in[i+4], green_in[i+3], green_in[i+1], green_in[i]};
	        	blue[index] <= 9'd198; //{blue_in[i+7], blue_in[i+6], blue_in[i+5], blue_in[i+4], blue_in[i+3], blue_in[i+1], blue_in[i]};
	        end
	      end
	    BG_REPLACE: 
	      begin
	        if(counter == num_pixels)
	        	state <= BG_ALMOST_DONE;
	        else begin
	        	state <= BG_REPLACE;
	        end

	        // calculate distance squared from expected RGB (to avoid square root operation)
	        distance <= (red_exp - red[counter]) * (red_exp - red[counter]);
	        distance <= distance + ((green_exp - green[counter]) * (green_exp - green[counter]));
	        distance <= distance + ((blue_exp - blue[counter]) * (blue_exp - blue[counter]));
	        
	        // compare to threshold
	        if(distance > threshold) // if true, foreground --> same value
	        	red[counter] <= red[counter];
	        else begin
	        	red[counter] <= desired_bg;
	        end
	        counter <= counter + 1;
	      end
	    BG_ALMOST_DONE: // format as 1D array to return
	      begin
			state <= BG_DONE;
	      	for(index = 0; index < num_pixels; index=index+1)
	        begin
	        	temp <= red[index];
	        	red_out[i] = temp[0];
	        	red_out[i+1] = temp[1];
	        	red_out[i+2] = temp[2];
	        	red_out[i+3] = temp[3];
	        	red_out[i+4] = temp[4];
	        	red_out[i+5] = temp[5];
	        	red_out[i+6] = temp[6];
	        	red_out[i+7] = temp[7];

	        	temp <= green[index];
	        	green_out[i] = temp[0];
	        	green_out[i+1] = temp[1];
	        	green_out[i+2] = temp[2];
	        	green_out[i+3] = temp[3];
	        	green_out[i+4] = temp[4];
	        	green_out[i+5] = temp[5];
	        	green_out[i+6] = temp[6];
	        	green_out[i+7] = temp[7];

	        	temp <= blue[index];
	        	blue_out[i] = temp[0];
	        	blue_out[i+1] = temp[1];
	        	blue_out[i+2] = temp[2];
	        	blue_out[i+3] = temp[3];
	        	blue_out[i+4] = temp[4];
	        	blue_out[i+5] = temp[5];
	        	blue_out[i+6] = temp[6];
	        	blue_out[i+7] = temp[7];

	        	i = i+8;
	        end
	      end
	    BG_DONE:
	      begin  
	         // state transitions in the control unit
	         if (Ack)
	           state <= IDLE;
	       end    
	endcase

end



endmodule