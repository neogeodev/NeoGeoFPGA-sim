`timescale 10ns/10ns

module lspc_a2(
	input CLK_24M,
	input nRESET,
	inout [23:0] PBUS,
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

	parameter VIDEO_MODE = 1;	// PAL

	assign CLK_24MB = ~CLK_24M;
	
	wire [8:0] VCOUNT;
	wire [8:0] HCOUNT;
	
	reg [31:0] TIMERLOAD;
	reg [31:0] TIMER;
	
	// VBL, HBL, COLDBOOT
	reg [2:0] nIRQS;
	
	// VRAM CPU I/O
	reg CPU_PENDING;
	reg CPU_RW;
	reg CPU_VRAM_ZONE;						// Top bit of VRAM address (low/high indicator)
	reg [14:0] CPU_VRAM_ADDR;
	wire [15:0] CPU_VRAM_READ_BUFFER;	// Are those two the same ?
	reg [15:0] CPU_VRAM_WRITE_BUFFER;
	
	// Config, write only. Is this actually 15 bit only ?
	reg [15:0] REG_VRAMMOD;
	// REG_LSPCMODE:
	reg [7:0] AASPEED;
	reg [2:0] TIMERINT_MODE;
	reg TIMERINT_EN;
	reg AA_DISABLE;
	
	reg TIMERSTOP;
	
	wire [19:0] SPR_TILENB_OUT;		// SPR_ATTR_TILENB after AA
	wire [2:0] AACOUNT;
	wire VBLANK;
	
	// This goes in fast_cycle:
	reg [11:0] SPR_ATTR_SHRINK;
	reg [8:0] SPR_ATTR_YPOS;
	reg SPR_ATTR_STICKY;
	reg [5:0] SPR_ATTR_SIZE;			// 4 ?
	reg [8:0] SPR_ATTR_XPOS;
	
	wire [1:0] SPR_ATTR_AA;
	
	reg [3:0] SPR_PIXELCNT;
	wire WR_PIXEL;
	
	wire [7:0] L0_DATA;
	
	irq IRQ(nIRQS, IPL0, IPL1);		// nRESETP ?
	videosync VS(CLK_6M, VCOUNT, HCOUNT, VBLANK, SYNC);
	
	wire [8:0] SPR_NB;
	wire [4:0] SPR_IDX;
	wire [7:0] SPR_TILEPAL;
	wire [1:0] SPR_TILEAA;
	wire [1:0] SPR_TILEFLIP;
	wire [19:0] SPR_TILENB;
	
	wire [11:0] FIX_TILENB;
	wire [3:0] FIX_TILEPAL;
	
	wire [16:0] FIX_ADDR;
	wire [24:0] SPR_ADDR;
	
	// 6 MHz = 166ns > 120ns
	slow_cycle SCY(CLK_6M, HCOUNT[8:3], VCOUNT[7:3], SPR_NB, SPR_IDX,	SPR_TILENB, SPR_TILEPAL,
					SPR_TILEAA, SPR_TILEFLIP, FIX_TILENB, FIX_TILEPAL,
					CPU_VRAM_ADDR, CPU_VRAM_READ_BUFFER, CPU_VRAM_WRITE_BUFFER, CPU_PENDING, CPU_VRAM_ZONE, CPU_RW);
	
	// 24 MHz = 41ns > 35ns
	// This needs to give SPR_NB, SPR_IDX, SPR_XPOS, L0_ADDR
	// This needs L0_DATA
	fast_cycle FCY(CLK_24M,
					CPU_VRAM_ADDR[10:0], CPU_VRAM_READ_BUFFER, CPU_VRAM_WRITE_BUFFER, CPU_PENDING, CPU_VRAM_ZONE, CPU_RW);
	
	assign FIX_ADDR = {FIX_TILENB, 5'b00000};			// Todo {half, S2H1, line} S2H1:1 then 0, half: 0 then 1
	assign SPR_ADDR = {SPR_TILENB_OUT, 5'b00000};	// Todo {CA4, line} CA4:1 then 0
	
	// This needs SPR_XPOS, L0_ADDR
	p_cycle PCY(CLK_24M, FIX_ADDR, FIX_TILEPAL, SPR_ADDR, SPR_TILEPAL, SPR_XPOS, L0_ADDR,
					PCK1, PCK2, LOAD, nVCS, L0_DATA, PBUS);
	
	autoanim AA(VBLANK, AASPEED, SPR_TILENB, AA_DISABLE, SPR_ATTR_AA, SPR_TILENB_OUT, AACOUNT);
	hshrink HSHRINK(SPR_ATTR_SHRINK[11:8], SPR_PIXELCNT, WR_PIXEL);
	
	// -------------------------------- Register access --------------------------------
	
	// Read only
	assign REG_LSPCMODE = {VCOUNT, 3'b000, VIDEO_MODE, AACOUNT};
	
	// Read
	assign M68K_DATA = (nLSPOE | ~nLSPWE) ? 16'bzzzzzzzzzzzzzzzz :
								(M68K_ADDR[2:0] == 3'b000) ? CPU_VRAM_READ_BUFFER :	// 3C0000
								(M68K_ADDR[2:0] == 3'b001) ? CPU_VRAM_READ_BUFFER :	// 3C0002
								(M68K_ADDR[2:0] == 3'b010) ? REG_VRAMMOD :				// 3C0004
								(M68K_ADDR[2:0] == 3'b011) ? REG_LSPCMODE :				// 3C0006
								16'bzzzzzzzzzzzzzzzz;
	
	// Write
	always @(negedge nLSPWE or negedge nRESET)	// ?
	begin
		if (!nRESET)
			nIRQS <= 3'b111;
		else
		begin
			case (M68K_ADDR[2:0])
				// 3C0000
				3'b000 :
				begin
					// Read happens as soon as address is set
					{CPU_VRAM_ZONE, CPU_VRAM_ADDR} <= M68K_DATA;
					CPU_PENDING <= 1'b1;
					CPU_RW <= 1'b1;
				end
				// 3C0002
				3'b001 :
				begin
					CPU_VRAM_WRITE_BUFFER <= M68K_DATA;
					CPU_VRAM_ADDR <= CPU_VRAM_ADDR + REG_VRAMMOD[14:0];	// ?
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
				// 3C000C: Interrupt ack
				3'b110 : nIRQS <= nIRQS | M68K_DATA[2:0];
				// 3C000E
				3'b111 : TIMERSTOP <= M68K_DATA[0];
			endcase
		end
	end

	// -------------------------------- Timer counter --------------------------------
	
	//					PAL	PALSTOP	NTSC
	// F8 ~ FF		0		0			0			011111000	011111111
	// 100 ~ 10F	1		0			1			100000000	100001111
	// 110 ~ 1EF	1		1			1			100010000	111101111
	// 1F0 ~ 1FF	1		0			1			111110000	111111111
	assign VPALSTOP = VIDEO_MODE & TIMERSTOP;
	assign BORDER_TOP = ~(VCOUNT[7] + VCOUNT[6] + VCOUNT[5] + VCOUNT[4]);
	assign BORDER_BOT = VCOUNT[7] & VCOUNT[6] & VCOUNT[5] & VCOUNT[4];
	assign BORDERS = BORDER_TOP + BORDER_BOT;
	assign nTIMERRUN = (VPALSTOP & BORDERS) | ~VCOUNT[8];
	
	// TIMERINT_MODE[1] is used in vblank !
	
	// Pixel timer
	always @(posedge CLK_6M)
	begin
		if (!nTIMERRUN)
		begin
			if (TIMER)
				TIMER <= TIMER - 1;
			else
			begin
				if (TIMERINT_EN) nIRQS[1] <= 1'b0;	// IRQ2 plz
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
	
endmodule
