`timescale 1ns / 1ns

module testbench_1();
	 
	reg MCLK;
	reg nRESET_BTN;

	neogeo_mvs NG(
		nRESET_BTN,
		1'b1,				// TEST_BTN
		MCLK,
		8'b11111111,	// DIPSW
		
		10'b1111111111,
		10'b1111111111,
		P1_OUT,
		P2_OUT,
		
		CDA,			// Memcard address
		CDD,			// Memcard data
		
		EL_OUT,			// Clock, 3x data
		LED_OUT1,		// Clock, 8x data
		LED_OUT2,		// Clock, 8x data
		
		VIDEO_R,
		VIDEO_G,
		VIDEO_B,
		VIDEO_SYNC
	);
	
	initial
	begin
		nRESET_BTN = 1;
		MCLK = 0;
	end
	
	always
		#42 MCLK = !MCLK;
		
	initial
	begin
		#500
		nRESET_BTN = 0;
		#500
		nRESET_BTN = 1;
	end
	
endmodule
