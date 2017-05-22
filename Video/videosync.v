`timescale 1ns/1ns

module videosync(
	input CLK_24M,
	input nRESETP,
	output reg [8:0] V_COUNT,		// 0~263
	output reg [8:0] H_COUNT,		// 0~383
	output TMS0,
	output VBLANK,
	output reg nVSYNC,
	output reg HSYNC,
	output reg nBNKB,
	output reg CHBL,
	output reg [5:0] FIX_MAP_COL	// 0~47
);

	wire MASKING;
	reg [3:0] FOURTEEN_CNT = 4'd0;
	reg [1:0] LSPC_DIV = 2'd0;
	reg [7:0] FT_CNT = 8'd0;
	
	// Do not reset CHBL between (NTSC):
	// x 0000 0000 ~ x 0000 1111
	// x 1111 0000 ~ x 1111 1111
	assign MASKING = ~|{V_COUNT[7:4]} | &{V_COUNT[7:4]};
	
	assign VBLANK = ~|{V_COUNT[7:3]};

	// Video sync must always run (even during reset) since nBNKB is the watchdog clock
	always @(negedge CLK_24M)
	begin
		if (!nRESETP)
		begin
			H_COUNT <= 0;
			FOURTEEN_CNT <= 4'd0;
			LSPC_DIV <= 0;
		end
		else
		begin
			if (FOURTEEN_CNT == 4'd14)
			begin
				FOURTEEN_CNT <= 4'd0;
				FT_CNT <= FT_CNT + 1'b1;
				HSYNC <= |{FT_CNT[7:3]};		// Good ?	HSYNC low (112mclk, 0~28px)
				if (FT_CNT == 7'd12)				// 11 ?
				begin
					nVSYNC <= V_COUNT[8];			// Good ?
					nBNKB <= ~MASKING;
				end

				if (FT_CNT == 7'd16)				// 15 ?
				begin
					if (!MASKING)
						CHBL <= 1'b0;				// NTSC Good ?
				end
			end
			else
				FOURTEEN_CNT <= FOURTEEN_CNT + 1'b1;
			
			if (LSPC_DIV == 2'd1)
			begin
				if (H_COUNT < 9'd383)
					H_COUNT <= H_COUNT + 1'b1;
				else
				begin
					H_COUNT <= 9'd0;
					FOURTEEN_CNT <= 4'd0;		// Force reset each new line
					FT_CNT <= 7'd0;
					if (V_COUNT < 9'd263)
						V_COUNT <= V_COUNT + 1'b1;
					else
						V_COUNT <= 0;
				end
				if (H_COUNT == 9'd48)
					FIX_MAP_COL <= 6'd0;	// This probably isn't done that way
				if (&{H_COUNT[2:0]})
					FIX_MAP_COL <= FIX_MAP_COL + 1'b1;	// This probably isn't done that way
				if (H_COUNT == 9'd375)
					CHBL <= 1'b1;			// This probably isn't done that way
			end
			LSPC_DIV <= LSPC_DIV + 1'b1;
		end
	end
	
	// Certainly wrong:
	//assign TMS0 = MAIN_CNT[11] | (MAIN_CNT[10] & MAIN_CNT[9]);
	
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
	
	// Stuff happens 14px after HSYNC rises: VSYNC and nBNKB
	// Not sure about this at all...
	//assign HTRIG = (HSYNC == 42) ? 1 : 0;

endmodule
