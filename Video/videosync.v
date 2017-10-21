`timescale 1ns/1ns

module videosync(
	input CLK_24M,
	input nRESETP,
	output [8:0] V_COUNT,				// 0~263
	output reg [8:0] H_COUNT = 9'd0,	// 0~383
	output reg TMS0,
	output VBLANK,
	output reg nVSYNC,
	output reg HSYNC,
	output nBNKB,
	output CHBL
);

	wire MASKING;
	reg [3:0] FOURTEEN_CNT = 4'd0;
	reg [1:0] LSPC_DIV = 2'd0;
	reg [7:0] FT_CNT = 8'd0;
	reg ACTIVE = 1'b0;
	
	reg [2:0] DIV_LINE_LOW = 3'd0;
	reg [4:0] DIV_LINE_HIGH = 5'd0;
	
	assign V_COUNT = {ACTIVE, DIV_LINE_HIGH, DIV_LINE_LOW};
	
	// D-latch clocked by H_COUNT[1] on the Alpha68k
	always @(posedge H_COUNT[1])
		TMS0 <= V_COUNT[0];
	
	// No blanking during 320 pixels
	// Blanking for the remaining 64 pixels
	assign CHBL = H_COUNT[8] & |{H_COUNT[7:6]};

	// Do not reset CHBL between (NTSC):
	// x 0000 0000 ~ x 0000 1111
	// x 1111 0000 ~ x 1111 1111
	assign MASKING = ~|{V_COUNT[7:4]} | &{V_COUNT[7:4]};
	
	assign nBNKB = |{DIV_LINE_HIGH[4:1]} & ~&{DIV_LINE_HIGH[4:1]};
	
	assign VBLANK = ~|{V_COUNT[7:3]};

	// Video sync must always run (even during reset) since nBNKB is the watchdog clock
	always @(negedge CLK_24M)
	begin
		if (!nRESETP)
		begin
			H_COUNT <= 9'd0;
			DIV_LINE_LOW <= 3'd0;
			DIV_LINE_HIGH <= 5'd0;
			FOURTEEN_CNT <= 4'd0;
			LSPC_DIV <= 0;
			ACTIVE <= 1'b1;
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
					nVSYNC <= V_COUNT[8];		// Good ?
					//nBNKB <= ~MASKING;
				end

				if (FT_CNT == 7'd16)				// 15 ?
				begin
					//if (!MASKING)
					//	CHBL <= 1'b0;				// NTSC Good ?
				end
			end
			else
				FOURTEEN_CNT <= FOURTEEN_CNT + 1'b1;
			
			// To check: this must match posedge of CLK_6MB
			// H_COUNT is the pixel counter in SNKCLK
			if (LSPC_DIV == 2'd1)
			begin
				if (H_COUNT == 9'd383)
				begin
					H_COUNT <= 9'd0;
					
					FOURTEEN_CNT <= 4'd0;		// Force reset each new line
					FT_CNT <= 7'd0;

					if (DIV_LINE_LOW == 3'b111)
					begin
						DIV_LINE_LOW <= 3'd0;
						if (DIV_LINE_HIGH == 5'b11111)
						begin
							if (!ACTIVE)	// Must start at 1
							begin
								DIV_LINE_HIGH <= 5'd0;
								//DIV_HSYNC <= 5'd5;		// Value on reset ?
							end
							ACTIVE <= ~ACTIVE;
						end
						else
							DIV_LINE_HIGH <= DIV_LINE_HIGH + 1'b1;
					end
					else
						DIV_LINE_LOW <= DIV_LINE_LOW + 1'b1;

				end
				else
					H_COUNT <= H_COUNT + 1'b1;

				//if (H_COUNT == 9'd375)
				//	CHBL <= 1'b1;			// This is wrong ! See Alpha68k /E signal of J12, H12 and H9
			end
			
			LSPC_DIV <= LSPC_DIV + 1'b1;
		end
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

endmodule
