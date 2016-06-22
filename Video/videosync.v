`timescale 1ns/1ns

module videosync(
	input CLK_24M,
	input nRESETP,
	output reg [8:0] VCOUNT = 9'hF8,	// F8 ~ 1FF
	output reg [11:0] MAIN_CNT = 12'h0,
	output TMS0,
	output reg VBLANK = 1'b0,
	output nVSYNC,
	output HSYNC,
	output reg nBNKB
);
	
	// CSYNC low 56px (224mclk) before TMS0, high 28px (112mclk) before TMS0
	
	// CSYNC falls with TMS0 on RESET
	// TMS0 stays low for 87mclk
	// CSYNC stays low for 1399mclk
	// CSYNC stays high for 112mclk = 28px
	
	always @(posedge CLK_24M)
	begin
		if (MAIN_CNT == 12'd55)		// 56 (14px)
		begin
			if (VCOUNT == 9'h1F0) nBNKB <= 1'b0;
			if (VCOUNT == 9'h110) nBNKB <= 1'b1;
		end
	end

	always @(negedge CLK_24M or negedge nRESETP)
	begin
		if (!nRESETP)
			MAIN_CNT <= 12'b0;
		else
		begin
			if (MAIN_CNT < 12'hBFF)		// (1536*2)-1 = 2 full lines
				MAIN_CNT <= MAIN_CNT + 1'b1;
			else
				MAIN_CNT <= 12'b0;
			
			if (MAIN_CNT == 12'd1535) VCOUNT <= VCOUNT + 1'b1;
			
			if (MAIN_CNT == 12'd3071)
			begin
				if (VCOUNT == 9'h1FF)
				begin
					// End of frame
					VCOUNT <= 9'hF8;				// VSSTART	F8:VSync start
				end
				else
				begin
					if (VCOUNT == 9'h0FF)		// VBEND		100:VSync/VBlank end
						VBLANK <= 0;
					if (VCOUNT == 9'h1F0)		// VBSTART	1F0:VBlank start
						VBLANK <= 1;
				
					VCOUNT <= VCOUNT + 1'b1;
				end
			end
		end

	end
	
	assign TMS0 = MAIN_CNT[11] | (MAIN_CNT[10] & MAIN_CNT[9]);
	assign nVSYNC = VCOUNT[8];
	
	// -------------------------------- Unreadable notes follow --------------------------------
	// HSYNC = 0 28	0~1B		000000000	000011011
	// HSYNC = 1 356	1C~17F	000011100	101111111
	// HSYNC = 1 		29
	// HSYNC = (2&3&4)|5|6|7|8
	// VSYNC = 1 F8~FF
	// CHBL = 0			38~177	000111000	101110111
	//                              |0
	//			    118     1280     27  111
	// nHSYNC  |''''''''''''''''''''|_____|''''''''''''''''''''|______
	// nHBLANK ______|'''''''''''|______________|'''''''''''|_________
	//													nHSYNC	nHBLANK
	// 0~110:		00000000000 00001101110		0			0
	// 111~228:		00001101111 00011100100		1			0
	// 229~1508:	00011100101	10111100100		1			1
	// 1509~1535:	10111100101	10111111111		1			0
	
	// Probably wrong:
	// 0~327: 	H
	// 328~355: L
	// 356~383: H
	// F0 = (A)(C)(D'+F')(D'+E')(D+E+F)(D'+G');
/*	assign HSYNC = ((HCOUNT[8]&HCOUNT[6]) & 
							(~HCOUNT[5]|~HCOUNT[3]) &
							(~HCOUNT[5]|~HCOUNT[4]) &
							(|{HCOUNT[5:3]}) &
							(~HCOUNT[5]|~HCOUNT[2]));*/
							
	assign HSYNC = 1'b0;
	
	// Stuff happens 14px after HSYNC rises: VSYNC and nBNKB
	// Not sure about this at all...
	//assign HTRIG = (HSYNC == 42) ? 1 : 0;
	/*always @(posedge HTRIG)
	begin
	end*/

endmodule
