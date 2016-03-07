`timescale 10ns/10ns

module videosync(
	input CLK_6M,
	output reg [8:0] VCOUNT,	// F8 ~ 1FF
	output reg [8:0] HCOUNT,	// 0 ~ 17F
	output reg VBLANK,
	output SYNC
);

	reg VSYNC;

	always @(posedge CLK_6M)
	begin
		if (HCOUNT == 9'h17F)
		begin
			if (VCOUNT == 9'h1FF)
			begin
				VCOUNT <= 9'hF8;				// VSSTART	F8:VSync start
				VSYNC <= 1;
			end
			else
				VCOUNT <= VCOUNT + 1;
			
			if (VCOUNT == 9'h100)			// VBEND		100:VBlank end
				VBLANK <= 0;
			if (VCOUNT == 9'h1F0)			// VBSTART	1F0:VBlank start
				VBLANK <= 1;
		end
		else
			HCOUNT <= HCOUNT + 1;
	end
	
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
	
	assign nVSYNC = ~VCOUNT[8];
	
	// Probably wrong:
	assign HSYNC = &{HCOUNT[4:2]} | |{HCOUNT[8:5]};
	assign SYNC = nVSYNC ^ HSYNC;
	// Stuff happens 14px after HSYNC rises: VSYNC and nBNKB
	// Not sure about this at all...
	assign HTRIG = (HSYNC == 42) ? 1 : 0;
	/*always @(posedge HTRIG)
	begin
	end*/

endmodule


