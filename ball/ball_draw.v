module ball_draw(
	input resetn,
	input clk,
	
	input go,			//loads when 1
	input draw,			//draws when 0
	input [7:0] x_in,
	input [6:0] y_in, size,
	
	output writeEn,
	output [7:0] x_out,
	output [6:0] y_out
	);
	
	wire ld_x, ld_y, inc_x, inc_y;
	wire finished_col, finished_all;
	
	control c0(
		.clk(clk),
		.resetn(resetn),
		.go(go),				
		.draw(draw),
		.finished_col(finished_col),
		.finished_all(finished_all),
		.ld_x(ld_x),
		.ld_y(ld_y),
		.inc_x(inc_x),
		.inc_y(inc_y),
		.wren(writeEn)
	);
	
	datapath D0(
		.clk(clk),
		.resetn(resetn),
		.x_in(x_in),
		.y_in(y_in),
		.size(size),
		.finished_col(finished_col),
		.finished_all(finished_all),
		.ld_x(ld_x),
		.ld_y(ld_y),
		.inc_x(inc_x),
		.inc_y(inc_y),
		.x_out(x),
		.y_out(y)
	);

endmodule

module control(
	input clk,
	input resetn,
	input go,
	input draw,
	input finished_all,
	input finished_col,
	output reg ld_x, ld_y, inc_x, inc_y,
	output reg wren
	);
	
	reg [1:0] current_state, next_state;

	localparam 	S_LOAD_XY			= 2'd0,
					S_LOAD_XY_WAIT	= 2'd1,
					S_DRAW_COL     = 2'd2,
					S_INC_COL      = 2'd3;
					
	always @(*)
   begin: state_table 
			case (current_state)
					S_LOAD_XY: next_state = go ? S_LOAD_XY_WAIT : S_LOAD_XY; // Loop in current state until value is input
					S_LOAD_XY_WAIT: next_state = draw ? S_LOAD_XY_WAIT : S_DRAW_COL; // Loop in current state until go signal goes low
					S_DRAW_COL: next_state = finished_col ? S_INC_COL : S_DRAW_COL;// Keep incrementing and drawing the column until finished.
               S_INC_COL: next_state = finished_all ? S_LOAD_XY : S_DRAW_COL; // we will be done our operations, start over after
            default:     next_state = S_LOAD_XY;
        endcase
    end // state_table
	 
	 always @(*)
    begin: enable_signals
        // By default make all our signals 0
		  ld_x  = 0;
		  ld_y  = 0;
		  inc_x = 0;
		  inc_y = 0;
		  wren  = 0;

        case (current_state)
            S_LOAD_XY: begin
					ld_x  = 1'b1;
					ld_y  = 1'b1;
					end
				S_DRAW_COL: begin
					wren = 1;
					inc_y = 1;
					end
				S_INC_COL: begin
					inc_x = 1;
					end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
	 
	 // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_XY;
        else
            current_state <= next_state;
    end // state_FFS
	 
endmodule

module datapath(
	input clk,
	input resetn,
	input [7:0]x_in,
	input [6:0]y_in,
	input ld_x, ld_y, inc_x, inc_y,
	input [6:0]size,
	output reg [7:0]x_out,
	output reg [6:0]y_out,
	output reg finished_col,
	output reg finished_all
	);
	
	reg [7:0] x, qx;
	reg [6:0] y, qy;
	
	always @ (posedge clk) begin
		if(!resetn) begin
			x  <= 8'b0;
			y  <= 7'b0;
			qx <= 8'b0;
			qy <= 7'b0;
			finished_col <= 0;
			finished_all <= 0;
		end
		else begin
			if(ld_x)begin
				x  <= x_in;
				qx <= {1'b0, size} - 1;
				finished_col <= 0;
				finished_all <= 0;
			end
			
			if(ld_y)begin
				y  <= y_in;
				qy <= size - 1;
				finished_col <= 0;
				finished_all <= 0;
			end
			
			if(inc_x)begin
				qx <= qx - 1;
				qy <= size - 1;
				if(qx - 1 == 8'd0)
					finished_all <= 1;
				
				finished_col <= 0;
			end
			
			if(inc_y)begin
				qy <= qy - 1;
				if(qy - 1 == 7'd0)
					finished_col <= 1;
			end
		end
	end
	
	always @ (*) begin
		x_out = x + qx;
		y_out = y + qy;
	end
	
endmodule
