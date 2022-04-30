parameter [7:0]	NONE	= 8'b11111111,
				ZERO	= 8'b00000011,
				ONE		= 8'b10011111,
				TWO		= 8'b00100101,
				THREE	= 8'b00001101,
				FOUR	= 8'b10011001,
				IVE		= 8'b01001001,
				U		= 8'b10000011,
				n		= 8'b11010101,
				L		= 8'b11100011,
				O		= 8'b00000011,
				C		= 8'b01100011,
				K		= 8'b10010001;

parameter [1:0]	INPUT 	= 2'b00,
				LOCK   	= 2'b01,
				UNLOCK 	= 2'b10;

module lab_7_top
(
    input      		clk,
    input      		reset_n,
    input [3:0]		key_sw,
    
    input			BTNC,
    input			BTNU,
    input			BTNL,
    input			BTNR,
    input			BTND,
    
    output [3:0] 	led,
    output [7:0] 	abcdefgh,
    output [7:0] 	digit,
    
    output       	buzzer,
    output       	hsync,
    output       	vsync,
    output [2:0] 	rgb
);

    assign buzzer = 1'b0;
    assign hsync  = 1'b1;
    assign vsync  = 1'b1;
    assign rgb    = 3'b0;
    
    wire reset = ~ reset_n;
    
    wire BTNC_strobe;
    wire BTNU_strobe;
    wire BTNL_strobe;
    wire BTNR_strobe;
    wire BTND_strobe;
    
    wire [7:0]  symbols [0:5];
    wire [2:0]  digit_cnt;
    wire [1:0]	state;
    
    button_debouncer BTNC_debouncer
    (
    	.clk_i (clk),
    	.rst_i (reset),
    	.sw_i  (BTNC),
    	
    	.sw_down_ro (BTNC_strobe)
    );
    
    button_debouncer BTNU_debouncer
	(
		.clk_i (clk),
		.rst_i (reset),
		.sw_i  (BTNU),
		
		.sw_down_ro (BTNU_strobe)
	);
     
    button_debouncer BTNL_debouncer
	(
		.clk_i (clk),
		.rst_i (reset),
		.sw_i  (BTNL),
		
		.sw_down_ro (BTNL_strobe)
	); 
	
	button_debouncer BTNR_debouncer
	(
		.clk_i (clk),
		.rst_i (reset),
		.sw_i  (BTNR),
		
		.sw_down_ro (BTNR_strobe)
	);
		
	button_debouncer BTND_debouncer
	(
		.clk_i (clk),
		.rst_i (reset),
		.sw_i  (BTND),
		
		.sw_down_ro (BTND_strobe)
	);
    
    dial_memory dial_memory_0
	(
		.clk	(clk),
		.reset	(reset),
		.state	(state),
		
		.BTNU_strobe 	(BTNU_strobe),
		.BTNL_strobe 	(BTNL_strobe),
		.BTND_strobe 	(BTND_strobe),
		.BTNR_strobe 	(BTNR_strobe),
		.BTNC_strobe 	(BTNC_strobe),
		
		.symbols 		(symbols),
		.digit_cnt		(digit_cnt)
	);
    
    state_handler state_handler_0
    (
    	.clk		(clk),
    	.reset		(reset),
    	.symbols	(symbols),
    	.digit_cnt	(digit_cnt),
    	
    	.state		(state)
    );
    
    dial_handler dial_handler_0
    (
    	.clk		(clk),
    	.reset		(reset),
    	.symbols	(symbols),
    	
    	.abcdefgh	(abcdefgh),
    	.digit		(digit)
    );
    
endmodule

module dial_handler
(
	input clk,
	input reset,
	input [7:0] symbols [0:5],
	
	output [7:0] abcdefgh,
	output [7:0] digit
);

	wire [7:0]	lighting_digit;
	
	shift_reg shift_digit
	(
		.clk   (clk),
		.reset (reset),
		
		.value (lighting_digit)
	);
	
	reg [7:0] curr_char;
	    
	always @(lighting_digit)
		case (lighting_digit)
			8'b10000000: curr_char = symbols[0];
			8'b01000000: curr_char = symbols[1];
			8'b00100000: curr_char = symbols[2];
			8'b00010000: curr_char = symbols[3];
			8'b00001000: curr_char = symbols[4];
			8'b00000100: curr_char = symbols[5];
			default: curr_char = NONE;
		endcase
	
	assign abcdefgh = curr_char;
	assign digit = ~lighting_digit;

endmodule

module state_handler
# (
	parameter CNT_WIDTH = 4
)
(
	input	clk,
	input	reset,
	input	[7:0] symbols [0:5],
	input	[2:0] digit_cnt,

	output reg [1:0] state
);
	reg [CNT_WIDTH:0] delay_cnt;

	always @(posedge clk or posedge reset)
		if (reset)
		begin
			state <= INPUT;
			delay_cnt <= 0;
		end
		else if (state == INPUT && digit_cnt == 3'b110)
		begin
			if
			(
				symbols[0] == THREE	&&
				symbols[1] == TWO 	&&
				symbols[2] == ONE 	&&
				symbols[3] == ZERO 	&&
				symbols[4] == ONE 	&&
				symbols[5] == TWO
			)
				state <= UNLOCK;
			else
				state <= LOCK;
		end
		else if (state == LOCK || state == UNLOCK)
		begin
			delay_cnt <= delay_cnt + 1;
			if (&delay_cnt)
			begin
				delay_cnt <= 0;
				state <= INPUT;
			end
		end
endmodule

module dial_memory
(
	input clk,
	input reset,
	
	input [1:0] state,

	input BTNU_strobe,
	input BTNL_strobe,
	input BTND_strobe,
	input BTNR_strobe,
	input BTNC_strobe,
	
	output reg [7:0] symbols [0:5],
	output reg [2:0] digit_cnt
);

	always @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            symbols[0] <= NONE;
            symbols[1] <= NONE;
            symbols[2] <= NONE;
            symbols[3] <= NONE;
            symbols[4] <= NONE;
            symbols[5] <= NONE;
        end
        else if (state == INPUT)
		begin
			if (BTNU_strobe)
				symbols[digit_cnt] <= ZERO;
			else if (BTNL_strobe)
				symbols[digit_cnt] <= ONE;
			else if (BTND_strobe)
				symbols[digit_cnt] <= TWO;
			else if (BTNR_strobe)
				symbols[digit_cnt] <= THREE;
			else if (BTNC_strobe)
				symbols[digit_cnt] <= FOUR;
		end
        else if (state == LOCK)
        begin
        	symbols[0] <= L;
			symbols[1] <= O;
			symbols[2] <= C;
			symbols[3] <= K;
			symbols[4] <= NONE;
			symbols[5] <= NONE;
        end
        else if (state == UNLOCK)
        begin
        	symbols[0] <= U;
			symbols[1] <= n;
			symbols[2] <= L;
			symbols[3] <= O;
			symbols[4] <= C;
			symbols[5] <= K;
        end
    end
    
    always @(posedge clk or posedge reset)
    begin
    	if (reset || state != INPUT)
    		digit_cnt <= 3'b0;
    	else if (state == INPUT && (BTNU_strobe || BTNL_strobe || BTND_strobe || BTNR_strobe || BTNC_strobe))
    		digit_cnt <= digit_cnt + 3'b1;
   	end

endmodule

module button_debouncer
# (
	parameter	CNT_WIDTH = 3
)
(
	input clk_i,
	input rst_i,
	input sw_i,
	
	output reg sw_down_ro
);

	reg sw_r;
	reg sw_state_r;
	
	always @(posedge clk_i or posedge rst_i)
		if (rst_i)
			sw_r <= 1'b0;
		else
			sw_r <= sw_i;
			
	reg [ CNT_WIDTH-1 : 0 ] sw_cnt_r;
	
	wire sw_change = (sw_state_r != sw_r);
	wire sw_cnt_max  = & sw_cnt_r;
	
	always @(posedge clk_i or posedge rst_i)
		if (rst_i)
		begin
			sw_cnt_r <= 0;
			sw_state_r <= 0;
		end
		else if (sw_change)
		begin
			sw_cnt_r <= sw_cnt_r + 1;
			if (sw_cnt_max)
				sw_state_r <= ~sw_state_r;
		end
		else
			sw_cnt_r <= 0;

	always @(posedge clk_i)
		sw_down_ro <= sw_change & sw_cnt_max & ~sw_state_r;

endmodule

module shift_reg
# (
	parameter CNT_WIDTH = 2
)
(
    input clk,
    input reset,
    
    output reg [7:0] value
);
	
	reg [CNT_WIDTH:0] cnt;
	
	wire cnt_max = &cnt;
	
	always @(posedge clk or posedge reset)
		if (reset)
			cnt <= 0;
		else
			cnt <= cnt + 1;
	
    always @(posedge cnt_max or posedge reset)
    	if (reset)
    		value <= 1;
    	else		
    		value <= { value[6:0], value[7] };
            
endmodule

