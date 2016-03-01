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
	
	wire [15:0] SPR_TILEATTR;
	assign SPR_TILEATTR = E;
	
	wire [8:0] VCOUNT;
	
	reg [31:0] TIMERLOAD;
	reg [31:0] TIMER;
	
	// VBL, HBL, COLDBOOT
	reg [2:0] IRQS;
	
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
	
	wire [19:0] SPR_TILENB_OUT;
	wire [19:0] SPR_TILENB_IN;
	wire [2:0] AACOUNT;
	
	autoanim AA(VBLANK, AASPEED, SPR_TILENB_IN, AA_DISABLE, SPR_TILEATTR[4:3], SPR_TILENB_OUT, AACOUNT);
	irq IRQ(IRQS, IPL0, IPL1);
	videosync VS(CLK_6M, VCOUNT, SYNC);
	videocycle VC(CLK_24M, PCK1, PCK2, LOAD, nVCS);
	
	// -------------------------------- Register access --------------------------------
	
	// Read only
	assign REG_LSPCMODE = {VCOUNT, 3'b000, VIDEO_MODE, AACOUNT};
	
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
			3'b110 : IRQS <= IRQS & ~(M68K_DATA[2:0]);
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
				if (TIMERINT_EN) IRQS[1] = 1;	// IRQ2 plz
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

	vram_l VRAMLL(B, E[7:0], nBWE, nBOE, 1'b0);
	vram_l VRAMLU(B, E[15:8], nBWE, nBOE, 1'b0);
	vram_u VRAMUL(C, F[7:0], nCWE, 1'b0, 1'b0);
	vram_u VRAMUU(C, F[15:8], nCWE, 1'b0, 1'b0);
	
endmodule
