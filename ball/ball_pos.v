`include "macros.v"

module ball_pos(
	input enable,
	input clk,
	input resetn,
	
	input x_du,
	input y_du,
	
	output [9:0]x,
	output [9:0]y
	);
	
	x_counter xc(
		.enable(enable),
		.clk(clk),
		.resetn(resetn),
		
		.updown(x_du),
		.c_x(x)
	);
	
	y_counter yc(
		.enable(enable),
		.clk(clk),
		.resetn(resetn),
		
		.updown(y_du),
		.c_y(y)
		);
	
endmodule

module x_counter(
	input enable,
	input clk,
	input resetn,
	input updown,
	
	output reg [9:0]c_x
	);
	
	always @ (posedge clk) begin
		if(!resetn)
			c_x <= `BALLX;
			
		else begin
			if(enable)begin 
				if(updown)
					c_x <= c_x + 10'd1;
				else
					c_x <= c_x - 10'd1;
			end
		end
	end

endmodule

module y_counter(
	input enable,
	input resetn,
	input clk,
	input updown,
	
	output reg [9:0]c_y
	);
	
	always @ (posedge clk) begin
		if(!resetn)
			c_y <= `BALLY;
			
		else begin
			if(enable)begin 
				if(updown)
					c_y <= c_y + 10'd1;
				else
					c_y <= c_y - 10'd1;
			end
		end
	end

endmodule
