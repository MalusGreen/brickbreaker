//`include "ball/ball_pos.v"
//`include "ball/ball_draw.v"
//`include "ball/ball_logic.v"
//`include "delay_counter.v"
//`include "platform.v"
//`include "load_data.v"
//`include "memory.v"
//`include "bricks/address_xy.v"
//`include "bricks/brick_memory.v"
//`include "bricks/brick_draw.v"
//`include "pic_memory.v"
//`include "win_checker.v"
//`include "lose_checker.v"

`include "macros.v"

module brickbreaker(
		CLOCK_50,						//	On Board 50 MHz
	// Your inputs and outputs here
	  KEY,
	  SW,
	  LEDR,
	// The ports below are for the VGA output.  Do not change.
	VGA_CLK,   						//	VGA Clock
	VGA_HS,							//	VGA H_SYNC
	VGA_VS,							//	VGA V_SYNC
	VGA_BLANK_N,						//	VGA BLANK
	VGA_SYNC_N,						//	VGA SYNC
	VGA_R,   						//	VGA Red[9:0]
	VGA_G,	 						//	VGA Green[9:0]
	VGA_B   						//	VGA Blue[9:0]
	);
	
	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	output  [9:0]	 LEDR;
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	//Inputs
	wire resetn, loading, start;
	wire x_du, y_du;
	wire left, right;
	
	wire logic_go;
	wire opening;
	assign resetn = KEY[0];
	assign start = KEY[1];
	assign left = ~KEY[3];
	assign right = ~KEY[2];
	
	//load variables
	wire load_draw;
	wire [9:0] load_x, load_y;
	wire [9:0] load_address;
	wire [1:0] load_data;
	wire load_write;
	
	
	wire delay_enable;
	wire [9:0] load_dx, load_dy;
	wire load_wren;
	wire [2:0] load_colour;
	
	//Constants and connective wires.
	wire enable, inc_enable;
	wire [9:0]ball_x, screen_x;
	wire [9:0]ball_y, screen_y;
	wire [9:0]size;
	wire [39:0]delay;
	
	wire go_ball, go_bricks, go_plat;
	wire [1:0]draw_mux;
	wire iscolour;

	//collision wires
	wire [9:0]platx;
	
	wire vgareset;
	
	assign screen_x = 10'd160 - 10'd1;
	assign screen_y = 10'd120 - 10'd1;
	assign delay = 40'd833333;
//	assign delay = 40'd1666666;
//	assign delay = 40'd19200;
	assign size = 10'd2;
	
	wire [9:0] mem_x_in, mem_y_in, mem_x_out, mem_y_out ,game_x_in, game_y_in;
	wire mem_write, game_write;
	wire [1:0]mem_in_health, mem_out_health, game_health;
	wire win_occurred, loss_occurred;
	wire [9:0]total_health;
	
	assign mem_in_health = (loading) ? game_health : load_data;
	assign mem_x_in = (loading) ? game_x_in : load_x;
	assign mem_y_in = (loading) ? game_y_in : load_y;
	assign mem_write = (loading) ? game_write : load_write;
	
	assign LEDR[0] = win_occurred;
	//assign LEDR[1] = loss_occurred;
	//assign LEDR[2] = opening;
	
	wire [9:0]health_counter;
	assign LEDR[9:1] = health_counter[8:0];
	
	load_data ld(
		.resetn(resetn),
		.clk(CLOCK_50),
		.selection(SW[1:0]),
		
		.load_draw(load_draw),
		.loading(loading),
		.writeEn(load_write),
		.x_out(load_x),
		.y_out(load_y),
		.address(load_address),
		.health(load_data),
		.total_health(total_health)
	);
	
	win_checker w_check(
		.clk(CLOCK_50),
		.resetn(resetn),
		.game_write(game_write),
		.total_health(total_health),
			
		.win_occurred(win_occurred),
		
		.health_counter(health_counter)
		
	);
	
	lose_checker l_check(
		.clk(CLOCK_50),
		.resetn(resetn),
		.ball_y(ball_y),
		.starting_health(10'd3),
		
		.loss_occurred(loss_occurred)
	);
	
	
	brick_memory bm(
		.clk(CLOCK_50),
		.x_in(mem_x_in),
		.y_in(mem_y_in),
		.wren(mem_write),
		.health_in(mem_in_health),
		
		.health(mem_out_health),
		.x(mem_x_out),
		.y(mem_y_out)
	);
	
	//draw fsm
	draw_fsm FSM(
		.enable(enable),
		.resetn(resetn),
		.clk(CLOCK_50),
		
		.go_ball(go_ball),
		.go_bricks(go_bricks),
		.go_plat(go_plat),
		
		.logic_go(logic_go),
		.draw_mux(draw_mux),
		.iscolour(iscolour),
		.inc_enable(inc_enable)
	);
	
	wire test_col_1, test_col_2, test_col_3;
	
	wire [9:0] col_x1, col_x2, col_y1, col_y2;
	wire [1:0] col_health1, col_health2;
	wire collided_1, collided_2;
	wire plat_col;
	//game_logic
	ball_logic balllogic(
		.logic_go(logic_go),
		.resetn(resetn),
		.clk(CLOCK_50),
		
		.x(ball_x),
		.x_max(screen_x),
		.y(ball_y),
		.y_max(screen_y),
		.size(size),
		.brickx_in(mem_x_out),
		.bricky_in(mem_y_out),
		.platx(platx),
		.health(mem_out_health),
		
		.x_du(x_du),
		.y_du(y_du),
//		
		.game_health(game_health),
		.game_write(game_write),
		
		.memx(game_x_in),
		.memy(game_y_in),
		
	
		.col_x1(col_x1), 
		.col_x2(col_x2), 
		.col_y1(col_y1), 
		.col_y2(col_y2),
		
		.col_health1(col_health1),
		.col_health2(col_health2),
	
		.collided_1(collided_1), 
		.collided_2(collided_2),
		.plat_collided(plat_col)
	);
	
	ball_pos ballpos(
		.enable(inc_enable),
		.resetn(resetn),
		.clk(CLOCK_50),
		.plat_col(plat_col),
		.platx(platx),
		
		.x_du(x_du),
		.y_du(y_du),
		.x(ball_x),
		.y(ball_y)
	);
	
//	wire [9:0] test_address, test_x, test_y;
//	
//	address_xy fuck(
//		.x_in(ball_y),
//		.y_in(ball_x),
//		.address_in(test_address),
//		.address_out(test_address),
//		.x_out(test_x),
//		.y_out(test_y)
//	);
	
	//Wires for draw values.
	wire [9:0]ball_dx,brick_dx,plat_dx,ball_dy,brick_dy,plat_dy;
	wire [2:0]ball_colour,brick_colour,plat_colour;
	wire ball_en, brick_en, plat_en;
	
	wire [9:0]x_vga,y_vga;
	wire [2:0]colour_vga;
	wire writeEn_vga;
	
	//drawfunctions
	ball_draw balldraw(
		.resetn(resetn),
		.clk(CLOCK_50),
		
		.go(go_ball),
		.x_in(ball_x),
		.y_in(ball_y),
		
		.writeEn(ball_en),
		.x_out(ball_dx),
		.y_out(ball_dy),
		.colour(ball_colour)
	);
	
	//drawing bricks
	brick_draw loaddraw(
		.resetn(resetn),
		.clk(CLOCK_50),
		.go(load_draw),
		.health(load_data),
		.x_in(load_x),
		.y_in(load_y),
		
		.writeEn(load_wren),
		.x_out(load_dx),
		.y_out(load_dy),
		.color(load_colour)
	);
	
	wire [9:0] fsm_brick_x, fsm_brick_y;
	wire [1:0] fsm_brick_health;
	wire fsm_brick_draw;
	
	brick_fsm bfsm(
		.resetn(resetn),
		.clk(CLOCK_50),
		.go(go_bricks),
		
		.col_x1(col_x1), 
		.col_x2(col_x2), 
		.col_y1(col_y1), 
		.col_y2(col_y2),
		
		.col_health1(col_health1),
		.col_health2(col_health2),
		
		.collided_1(collided_1), 
		.collided_2(collided_2),
		
		.brickhealth(fsm_brick_health),
		.brickx(fsm_brick_x), 
		.bricky(fsm_brick_y),
		.go_draw(fsm_brick_draw)
	);
	
		brick_draw bd(
			.resetn(resetn),
			.clk(CLOCK_50),
			.go(fsm_brick_draw),
//			.go(1'b0),
			.health(fsm_brick_health),
			.x_in(fsm_brick_x),
			.y_in(fsm_brick_y),
			
			
			.writeEn(brick_en),
			.x_out(brick_dx),
			.y_out(brick_dy),
			.color(brick_colour)
		);
	
	platform platlog(
		.clk(CLOCK_50),
		.resetn(resetn),
		.left(left),
		.right(right),
		.enable(inc_enable),
		.draw(go_plat),
		
		.x(plat_dx),
		.y(plat_dy),
		.colour(plat_colour),
		.writeEn(plat_en),
		
		.d_x(platx)
	);
	
	reg [1:0]flags;
	always @(*)begin
		if(opening)begin
			flags = 2'd0;
		end
		else if(win_occurred)begin
			flags = 2'd1;
		end
		else if(loss_occurred)begin
			flags = 2'd2;
		end
	end
	
	wire [9:0] screen_dx, screen_dy;
	wire [2:0] screen_colour;
	wire screen_en;
	
	pic_memory pm(
		.resetn(resetn),
		.clk(CLOCK_50),
		.frame(delay_enable),
		
		.enable(opening | win_occurred | loss_occurred),
		.screen_select(flags),
		
		.drawing(screen_en),
		.x(screen_dx), 
		.y(screen_dy),
		.colour(screen_colour)
	);
	
	//MUX
	draw_mux drawmux(
		.opening(opening),
		.win(win_occurred),
		.lose(loss_occurred),
	
		.ball_x(ball_dx),
		.brick_x(brick_dx),
		.plat_x(plat_dx),
		.ball_y(ball_dy),
		.brick_y(brick_dy),
		.plat_y(plat_dy),
		.load_x(load_dx),
		.load_y(load_dy),
		.screen_x(screen_dx),
		.screen_y(screen_dy),
		
		.ball_colour(ball_colour),
		.brick_colour(brick_colour),
		.plat_colour(plat_colour),
		.load_colour(load_colour),
		.screen_colour(screen_colour),
		
		.ball_en(ball_en), 
		.brick_en(brick_en), 
		.plat_en(plat_en),
		.load_en(load_wren),
		.screen_en(screen_en),
		
		.draw_mux(draw_mux),
		
		.iscolour(iscolour),
		.isloading(loading),
		
		.x(x_vga),
		.y(y_vga),
		.writeEn(writeEn_vga),
		.colour(colour_vga)
	);
	
	//draw
	draw draw(
		.resetn(vgareset),
		.clk(CLOCK_50),
		
		.x(x_vga),
		.y(y_vga),
		.writeEn(writeEn_vga),
		.colour(colour_vga),
		
		// The ports below are for the VGA output.  Do not change.
		.VGA_CLK(VGA_CLK),   						//	VGA Clock
		.VGA_HS(VGA_HS),							//	VGA H_SYNC
		.VGA_VS(VGA_VS),							//	VGA V_SYNC
		.VGA_BLANK_N(VGA_BLANK_N),						//	VGA BLANK
		.VGA_SYNC_N(VGA_SYNC_N),						//	VGA SYNC
		.VGA_R(VGA_R),   						//	VGA Red[9:0]
		.VGA_G(VGA_G),	 						//	VGA Green[9:0]
		.VGA_B(VGA_B)   						   //	VGA Blue[9:0]
	);
	//delay
	delay_counter delaycounter(
		.clk(CLOCK_50),
		.resetn(resetn),
		.delay(delay),
		
		.d_enable(delay_enable)
	);
	
	assign vgareset = SW[9];
	
	reg resetonce;
	always @(posedge CLOCK_50)begin
		if(!vgareset)
			resetonce = 0;
		else if(!resetn)
			resetonce = 1;
	end
	reg go;
	always @(posedge CLOCK_50)begin
		if(!resetn)
			go = 0;
		else if(!start)
			go = 1;
	end
	
	assign opening = ~resetonce;
	assign enable = delay_enable & go & ~(opening | win_occurred | loss_occurred);
	
endmodule

//MAIN FSM
module draw_fsm(
	input enable,
	input resetn,
	input clk,
	
	output reg logic_go,
	output reg go_ball, go_bricks, go_plat,
	output reg [1:0] draw_mux,
	output reg iscolour,
	output reg inc_enable
	);
	
	reg [3:0] current_state, next_state;
	
	localparam	S_FSM_WAIT		= 4'd0,
					S_BALL_LOAD 	= 4'd1,
					S_BALL_DRAW 	= 4'd2,
					S_BRICKS_LOAD	= 4'd3,
					S_BRICKS_DRAW	= 4'd4,
					S_PLAT_LOAD		= 4'd5,
					S_PLAT_DRAW		= 4'd6,
					S_INC				= 4'd7,
					S_COL				= 4'd8,
					S_COL_WAIT		= 4'd9,
					S_CHANGE			= 4'd10;
					
	//CONSTANTS AND COUNTER VARIABLES
	reg delay_reset, changecolour;
	wire [19:0] ball_delay, brick_delay, plat_delay, inc_delay;
	reg [19:0] delay;
	
	assign ball_delay 	= 20'd4;
	assign brick_delay	= `BRICKDRAWTWO;
	assign plat_delay 	= 20'd30;
	assign inc_delay		= 20'd30;
	
	wire [19:0]count;
	
	counter drawdelay(
		.enable(1'b1),
		.clk(clk),
		.resetn(delay_reset),
		
		.c_x(count)
	);
	
	always @(*)begin
		case (current_state)
				S_FSM_WAIT: next_state = (enable | iscolour) ? S_BALL_LOAD : S_FSM_WAIT;
				S_BALL_LOAD: next_state = S_BALL_DRAW;
				S_BALL_DRAW:
				begin
					if(iscolour)begin
						next_state = (count == delay) ? S_BRICKS_LOAD : S_BALL_DRAW;
					end
					else
						next_state = S_PLAT_LOAD;
				end
				S_BRICKS_LOAD: next_state = S_BRICKS_DRAW;
				S_BRICKS_DRAW: next_state = (count == delay) ? S_PLAT_LOAD : S_BRICKS_DRAW;
				S_PLAT_LOAD: next_state = S_PLAT_DRAW;
				S_PLAT_DRAW:
				begin
					if((count == delay))begin
						if(iscolour)begin
							next_state = S_INC;
						end
						else begin 
							next_state = S_COL;
						end
					end
					else begin
						next_state = S_PLAT_DRAW;
					end
				end
				S_COL: next_state = S_COL_WAIT;
				S_COL_WAIT: next_state = (count == delay) ? S_INC : S_COL_WAIT;
				S_INC: next_state = S_CHANGE;
				S_CHANGE: next_state = S_FSM_WAIT;
				default: next_state = S_FSM_WAIT;
		endcase
	end
	
	always @(*)begin
		go_ball = 0;
		go_bricks = 0;
		go_plat = 0;
		draw_mux = 0;
		
		delay = 20'd0 - 20'd1;
		delay_reset = 1;
		
		inc_enable = 0;
		changecolour = 0;
		logic_go = 0;
		
		case (current_state)
			S_BALL_LOAD: begin 
				go_ball = 1;
				draw_mux = 2'd0;
				delay_reset = 0;
				delay = ball_delay;
			end
			S_BALL_DRAW: begin 
				delay = ball_delay;
				draw_mux = 2'd0;
			end
			S_BRICKS_LOAD: begin 
				go_bricks = 1;
				draw_mux = 2'd1;
				delay_reset = 0;
				delay = brick_delay;
			end
			S_BRICKS_DRAW: begin 
				delay = brick_delay;
				draw_mux = 2'd1;
			end
			S_PLAT_LOAD: begin 
				go_plat = 1;
				draw_mux = 2'd2;
				delay_reset = 0;
			end
			S_PLAT_DRAW: begin 
				delay = plat_delay;
				draw_mux = 2'd2;
			end
			S_INC: begin
				if(~iscolour)
					inc_enable = 1;
			end
			S_COL:begin
				if(~iscolour)
					logic_go = 1;
				delay_reset = 0;
			end
			S_COL_WAIT:begin
				delay = inc_delay;
			end
			S_CHANGE: begin
				changecolour = 1;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if(!resetn)
			iscolour <= 0;
		if(changecolour)
			iscolour <= ~iscolour;
	end
	 	 
   // current_state registers
   always@(posedge clk)
   begin: state_FFs
       if(!resetn)
           current_state <= S_FSM_WAIT;
       else
           current_state <= next_state;
   end // state_FFS
	
endmodule

module draw(
	input resetn,
	input clk,

	input [9:0]x,
	input [9:0]y,
	input [2:0]colour,
	input writeEn,
	
	output			VGA_CLK,   				//	VGA Clock
	output			VGA_HS,					//	VGA H_SYNC
	output			VGA_VS,					//	VGA V_SYNC
	output			VGA_BLANK_N,				//	VGA BLANK
	output			VGA_SYNC_N,				//	VGA SYNC
	output	[9:0]	VGA_R,   				//	VGA Red[9:0]
	output	[9:0]	VGA_G,	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B   					//	VGA Blue[9:0]
	);
	
	
	vga_adapter VGA(
		.resetn(resetn),
		.clock(clk),
		.colour(colour),
		.x(x),
		.y(y),
		.plot(writeEn),
		
		/* Signals for the DAC to drive the monitor. */
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK(VGA_BLANK_N),
		.VGA_SYNC(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK));
	defparam VGA.RESOLUTION = "160x120";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";
	
endmodule

module draw_mux(
	input [9:0]ball_x,brick_x,plat_x,ball_y,brick_y,plat_y,load_x,load_y, screen_x, screen_y,
	input [2:0]ball_colour,brick_colour,plat_colour,load_colour, screen_colour,
	input ball_en, brick_en, plat_en, load_en, screen_en,
	input [1:0]draw_mux,
	input iscolour,
	input isloading,
	
	input opening,
	input win,
	input lose,
	
	output reg [9:0]x,y,
	output reg [2:0]colour,
	output reg writeEn
	);
	
	localparam BLACK = 3'b000;
	
	always @(*)begin
		if(opening | win | lose)begin
			x = screen_x;
			y = screen_y;
			colour = screen_colour;
			writeEn = screen_en;
		end
		else if(isloading)begin
			case(draw_mux)
				2'd0:begin 
					x = ball_x;
					y = ball_y;
					colour = (iscolour) ? ball_colour : BLACK;
					writeEn = ball_en;
				end
				2'd1:begin 
					x = brick_x;
					y = brick_y;
					colour = (iscolour) ? brick_colour : BLACK;
					writeEn = brick_en;
				end
				2'd2:begin 
					x = plat_x;
					y = plat_y;
					colour = (iscolour) ? plat_colour : BLACK;
					writeEn = plat_en;
				end
				default: begin
					x = ball_x;
					y = ball_y;
					colour = (iscolour) ? ball_colour : BLACK;
					writeEn = ball_en;
				end
			endcase
		end
		else begin
			x = load_x;
			y = load_y;
			colour = load_colour;
			writeEn = load_en;
		end
	end
	
endmodule

module counter(
	input enable,
	input clk,
	input resetn,
	
	output reg [19:0]c_x
	);
	
	always @ (posedge clk) begin
		if(!resetn)
			c_x <= 20'b0;
			
		else begin
			if(enable)begin 
				c_x <= c_x + 20'b1;
			end
		end
	end

endmodule
