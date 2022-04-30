//`include "config.vh"
//`timescale 1ns/1ns

module lab_7_testbench;

    reg     clk;
    reg     reset_n;
    
    reg		BTNC;
    reg		BTNU;
    reg		BTNL;
    reg		BTNR;
    reg		BTND;
    
//    reg [3:0] key_sw;
    
   	wire [7:0] abcdefgh;

    lab_7_top
    i_top
    (
        .clk      ( clk      ),
        .reset_n  ( reset_n  ),
        .abcdefgh ( abcdefgh ),
//        .key_sw   ( key_sw ),
        .BTNC	  ( BTNC ),
        .BTNU	  ( BTNU ),
        .BTNL	  ( BTNL ),
        .BTNR	  ( BTNR ),
        .BTND	  ( BTND )
    );

    initial
    begin
    	# 1
        clk = 1'b0;

        forever
            # 10 clk = ! clk;
    end

    initial
    begin
    	# 1
        reset_n <= 1'bx;
        repeat (2) @ (posedge clk);
        reset_n <= 1'b0;
        repeat (2) @ (posedge clk);
        reset_n <= 1'b1;
    end

    initial
    begin
        # 1
        $dumpvars;
        
        BTNC <= 0;
        BTNU <= 0;
        BTNL <= 0;
        BTNR <= 0;
        BTND <= 0;

        @ (posedge reset_n);

        repeat (10000)
        begin
            @ (posedge clk);
			# 50
			BTNL <= $random;
			# 25
			BTNR <= $random;
			# 25
			BTND <= $random;
			# 25
			BTNC <= $random;
			# 25
			BTNU <= $random;         
        end

        `ifdef MODEL_TECH  // Mentor ModelSim and Questa
            $stop;
        `else
            $finish;
        `endif
    end

endmodule

//module lab_7_testbench;

//    reg    	clk;
//    reg		reset_n;
    
//    reg		BTNC;
//    reg		BTNU;
//    reg		BTNL;
//    reg		BTNR;
//    reg		BTND;
    
    
    
//    button_debouncer btn_deb
//    (
//    	.clk_i 		(clk),
//    	.rst_i 		(~reset_n),
//    	.sw_i  		(BTNC),
//    	.sw_down_ro (o)
//    );
    
//	initial
//	begin
//		clk = 1'b0;
		
//		forever
//			# 10 clk = ! clk;
//	end
	
//	initial
//	begin
//		reset_n <= 1'bx;
//		repeat (2) @ (posedge clk);
//		reset_n <= 1'b0;
//		repeat (2) @ (posedge clk);
//		reset_n <= 1'b1;
//	end

//	initial
//	begin
//		#100 BTNC <= 1;
//		#200 BTNC <= 0;
//		#200 BTNC <= 1;
//		#5   BTNC <= 0;
//	end

//endmodule
