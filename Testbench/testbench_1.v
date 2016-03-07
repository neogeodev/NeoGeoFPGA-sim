`timescale 1ns / 1ns

module testbench_1();
	 
	reg MCLK;
	reg nRESET_BTN;
	
	wire [2:0] P1_OUT;
	wire [2:0] P2_OUT;
	
	wire [23:0] CDA;
	wire [15:0] CDD;

	wire [3:0] EL_OUT;
	wire [8:0] LED_OUT1;
	wire [8:0] LED_OUT2;
	
	wire [6:0] VIDEO_R;
	wire [6:0] VIDEO_G;
	wire [6:0] VIDEO_B;

	neogeo_mvs NGMVS(
		nRESET_BTN,
		MCLK,
		
		10'b1111111111,	// P1 in
		10'b1111111111,	// P2 in
		P1_OUT,
		P2_OUT,
		
		CDA,					// Memcard address
		CDD,					// Memcard data
		
		1'b1,					// TEST_BTN
		8'b11111111,		// DIPSW
		EL_OUT,				// Cab stuff
		LED_OUT1,
		LED_OUT2,
		
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
