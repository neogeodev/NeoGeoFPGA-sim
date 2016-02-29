`timescale 10ns/10ns

module lspc_a2(
	input CLK_24M,
	input nRESET,
	input [23:0] PBUS,
	input [2:0] M68K_ADDR,
	inout [15:0] M68K_DATA,
	input nLSPOE, nLSPWE,
	input DOTA, DOTB,
	output CA4, S2H1,
	output S1H1,
	output LOAD, H, EVEN1, EVEN2,
	output IPL0, IPL1,
	output CHG,
	output LD1, LD2,
	output PCK1, PCK2,
	output [3:0] WE,
	output [3:0] CK,
	input SS1,
	input SS2,
	output nRESETP,
	output SYNC,
	output CHBL,
	output nBNKB,
	output nVCS,
	output CLK_6M
);

	parameter VIDEOMODE = 1;	// PAL

	assign CLK_24MB = ~CLK_24M;
	
	assign PCK2 = (CYCLE_NEG == 0) ? 1 : 0;
	assign PCK1 = (CYCLE_NEG == 8) ? 1 : 0;
	assign LOAD = CYCLE_POS[2] & CYCLE_POS[1];	// 6 & 7
	assign nVCS = (CYCLE_POS[2] & CYCLE_POS[1]) | ~CYCLE_POS[3];	// 9 ~ 13

	reg [3:0] CYCLE_POS;		// 0 ~ 15
	reg [3:0] CYCLE_NEG;		// 0 ~ 15
	
	reg [8:0] HCOUNT;			// 0 ~ 17F (is this really clocked by 24M ?)
	reg [8:0] VCOUNT;			// F8 ~ 1FF
	
	reg [7:0] AATIMER;
	reg [2:0] AACOUNT;
	
	wire VBLANK;
	
	// Auto animation
	always @(posedge VBLANK)
	begin
		if (AATIMER)
			AATIMER <= AATIMER + 1;
		else
		begin
			AATIMER <= AASPEED;
			AACOUNT <= AACOUNT + 1;
		end
	end
	
	wire [15:0] SPR_TILEATTR;
	
	assign SPR_TILEATTR = E;
	
	wire [19:0] SPR_TILENB;	// Wire ? Concat 4 bits from SPR_TILEATTR
	
	assign SPR_TILENB = AA_DISABLE ? SPR_TILENB :
								SPR_TILEATTR[4] ? {SPR_TILENB[19:3], AACOUNT} :
								SPR_TILEATTR[3] ? {SPR_TILENB[19:2], AACOUNT[1:0]} :
								SPR_TILENB;
	
	reg [31:0] TIMERLOAD;
	reg [31:0] TIMER;
	
	// VBL, HBL, COLDBOOT
	reg [2:0] IRQ;
	
	// Interrupt priority encoder
	// xx1: 11
	// x10: 10
	// 100: 01
	// 000: 00
	assign IPL0 = (IRQ[2] & ~IRQ[1]) + IRQ[0];
	assign IPL1 = IRQ[1] + IRQ[0];
	
	// VRAM CPU I/O
	reg VRAMADDR_U;					// Top bit of VRAM address (low/high indicator)
	reg [14:0] VRAMADDR_L;
	reg [15:0] VRAM_READ_BUFFER;	// Are those two the same ?
	reg [15:0] VRAM_WRITE_BUFFER;
	wire [15:0] VRAMADDR;
	assign VRAMADDR = {VRAMADDR_U, VRAMADDR_L};
	
	// Config, write only
	reg [15:0] REG_VRAMMOD;
	// REG_LSPCMODE:
	reg [7:0] AASPEED;
	reg [2:0] TIMERINT_MODE;
	reg TIMERINT_EN;
	reg AA_DISABLE;
	
	reg TIMERSTOP;
	
	// Read only
	assign REG_LSPCMODE = {VCOUNT, 3'b000, VIDEOMODE, AACOUNT};
	
	/*
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
	*/
	
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
	assign HSYNC = &{HCOUNT[4:2]} | |{HCOUNT[8:5]};
	assign VSYNC = ~VCOUNT[8];
	assign SYNC = VSYNC ^ HSYNC;
	// Stuff happens 14px after HSYNC rises: VSYNC and nBNKB
	// Not sure about this at all...
	assign HTRIG = (HSYNC == 42) ? 1 : 0;
	/*always @(posedge HTRIG)
	begin
	end*/

	// -------------------------------- Cycle gen / sequencing --------------------------------
 
	always @(posedge CLK_24M)
	begin
		CYCLE_POS <= CYCLE_POS + 1;
	end
	
	always @(negedge CLK_24M)
	begin
		CYCLE_NEG <= CYCLE_NEG + 1;
	end
	
	// -------------------------------- Register access --------------------------------
	// Read
	assign M68K_DATA = (nLSPOE | ~nLSPWE) ? 16'bzzzzzzzzzzzzzzzz :
								(M68K_ADDR[2:0] == 3'b000) ? VRAM_READ_BUFFER :	// 3C0000
								(M68K_ADDR[2:0] == 3'b001) ? VRAM_READ_BUFFER :	// 3C0002
								(M68K_ADDR[2:0] == 3'b010) ? REG_VRAMMOD :		// 3C0004
								(M68K_ADDR[2:0] == 3'b011) ? REG_LSPCMODE :		// 3C0006
								16'bzzzzzzzzzzzzzzzz;
	
	// Write
	always @(negedge nLSPWE)
	begin
		case (M68K_ADDR[2:0])
			// 3C0000
			3'b000 :
			begin
				{VRAMADDR_U, VRAMADDR_L} <= M68K_DATA;
				//VRAM_READ_BUFFER <= VRAMDATA;		// TODO
			end
			// 3C0002
			3'b001 :
			begin
				VRAM_WRITE_BUFFER <= M68K_DATA;
				VRAMADDR_L <= VRAMADDR_L + REG_VRAMMOD;
			end
			// 3C0004
			3'b010 : REG_VRAMMOD <= M68K_DATA;
			// 3C0006
			3'b011 :
			begin
				AASPEED <= M68K_DATA[15:8];
				TIMERINT_MODE <= M68K_DATA[7:5];
				TIMERINT_EN <= M68K_DATA[4];
				AA_DISABLE <= M68K_DATA[3];
			end
			// 3C0008
			3'b100 : TIMERLOAD[31:16] <= M68K_DATA;
			// 3C000A
			3'b101 :
			begin
				TIMERLOAD[15:0] <= M68K_DATA;
				if (TIMERINT_MODE[0]) TIMER <= TIMERLOAD;
			end
			// 3C000C
			3'b110 : IRQ <= IRQ & ~(M68K_DATA[2:0]);
			// 3C000E
			3'b111 : TIMERSTOP <= M68K_DATA[0];
		endcase
	end

	// -------------------------------- Timer counter --------------------------------
	
	//					PAL	PALSTOP	NTSC
	// F8 ~ FF		0		0			0			011111000	011111111
	// 100 ~ 10F	1		0			1			100000000	100001111
	// 110 ~ 1EF	1		1			1			100010000	111101111
	// 1F0 ~ 1FF	1		0			1			111110000	111111111
	assign VPALSTOP = VIDEOMODE & TIMERSTOP;
	assign BORDER_TOP = ~(VCOUNT[7] + VCOUNT[6] + VCOUNT[5] + VCOUNT[4]);
	assign BORDER_BOT = VCOUNT[7] & VCOUNT[6] & VCOUNT[5] & VCOUNT[4];
	assign BORDERS = BORDER_TOP + BORDER_BOT;
	assign TIMERRUNn = (VPALSTOP & BORDERS) | ~VCOUNT[8];
	
	// TIMERINT_MODE[1] is used in vblank !
	
	// Pixel timer
	always @(posedge CLK_6M)
	begin
		if (!TIMERRUNn)
		begin
			if (TIMER)
				TIMER <= TIMER - 1;
			else
			begin
				if (TIMERINT_EN) IRQ[1] = 1;	// IRQ2 plz
				if (TIMERINT_MODE[2]) TIMER <= TIMERLOAD;
			end
		end
	end
	
	
	// -------------------------------- Pixel clock --------------------------------
	
	reg [1:0] CLKDIV;
	
	assign CLK_6M = CLKDIV[1];
	
	always @(posedge CLK_24M)
	begin
		CLKDIV <= CLKDIV + 1;
	end
	
	// VRAM
	wire [14:0] B;		// Low VRAM address
	wire [10:0] C;		// High VRAM address
	wire [15:0] E;		// Low VRAM data
	wire [15:0] F;		// High VRAM data

	vram_l VRAMLL(B, E[7:0], nBWE, nBOE, 0);
	vram_l VRAMLU(B, E[15:8], nBWE, nBOE, 0);
	vram_u VRAMUL(C, F[7:0], nCWE, 0, 0);
	vram_u VRAMUU(C, F[15:8], nCWE, 0, 0);
	
endmodule
