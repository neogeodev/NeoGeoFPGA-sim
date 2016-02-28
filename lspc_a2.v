`timescale 10ns/10ns

module lspc_a2(
	input CLK_24M,
	input nRESET,
	input [23:0] PBUS,
	input [2:0] M68K_ADDR,
	input [15:0] M68K_DATA,
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

	assign CLK_24MB = ~CLK_24M;
	
	assign PCK2 = (CYCLE_NEG == 0) ? 1 : 0;
	assign PCK1 = (CYCLE_NEG == 8) ? 1 : 0;
	assign LOAD = CYCLE_POS[2] & CYCLE_POS[1];	// 6 & 7
	assign nVCS = (CYCLE_POS[2] & CYCLE_POS[1]) | ~CYCLE_POS[3];	// 9 ~ 13

	reg [3:0] CYCLE_POS;		// 0 ~ 15
	reg [3:0] CYCLE_NEG;		// 0 ~ 15
	
	reg [8:0] HCOUNT;			// 0 ~ 17F
	reg [8:0] VCOUNT;			// F8 ~ 1FF
	reg [2:0] AACOUNT;
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
	
	// Write only
	reg [15:0] REG_VRAMMOD;
	reg TIMERSTOP;
	reg [7:0] AASPEED;
	reg [2:0] TIMERINT_MODE;
	reg TIMERINT_EN;
	reg AA_DISABLE;
	
	// Read/write
	reg [15:0] VRAMADDR;
	
	// Read only
	assign REG_LSPCMODE = {VCOUNT, 3'b000, VIDEOMODE, AACOUNT};
	
	/*
		if (VCOUNT == 9'h1FF)
			VCOUNT <= 9'hF8;
		else
			VCOUNT <= VCOUNT + 1;
	*/

	// Cycle gen
	always @(posedge CLK_24M)
	begin
		CYCLE_POS <= CYCLE_POS + 1;
	end
	
	always @(negedge CLK_24M)
	begin
		CYCLE_NEG <= CYCLE_NEG + 1;
	end
	
	
	// Register access
	always @(nLSPOE, nLSPWE)
	begin
		if (~nLSPOE & nLSPWE)
		begin
			case (M68K_ADDR[2:0])
				3'b000 :	M68K_DATA <= REG_VRAMRW;
				3'b001 : M68K_DATA <= REG_VRAMRW;
				3'b010 : M68K_DATA <= REG_VRAMMOD;
				3'b011 : M68K_DATA <= REG_LSPCMODE;
			endcase
		end
	end
	
	always @(negedge nLSPWE)
	begin
		case (M68K_ADDR[2:0])
			3'b000 :	REG_VRAMADDR <= M68K_DATA;
			3'b001 : REG_VRAMRW <= M68K_DATA;
			3'b010 : REG_VRAMMOD <= M68K_DATA;
			3'b011 :
			begin
				AASPEED <= M68K_DATA[15:8];
				TIMERINT_MODE <= M68K_DATA[7:5];
				TIMERINT_EN <= M68K_DATA[4];
				AA_DISABLE <= M68K_DATA[3];
			end
			3'b100 : TIMERLOAD[31:16] <= M68K_DATA;
			3'b101 :
			begin
				TIMERLOAD[15:0] <= M68K_DATA;
				if (TIMERINT_MODE[0]) TIMER <= TIMERLOAD;
			end
			3'b110 : IRQ <= IRQ & ~(M68K_DATA[2:0]);
			3'b111 : TIMERSTOP <= M68K_DATA[0];
		endcase
	end
	
	//					PAL	PALSTOP	NTSC
	// F8 ~ FF		0		0			0			011111000	011111111
	// 100 ~ 10F	1		0			1			100000000	100001111
	// 110 ~ 1EF	1		1			1			100010000	111101111
	// 1F0 ~ 1FF	1		0			1			111110000	111111111
	// OUT = (STOP & (~(B+C+D+E) + (B&C&D&E))) | ~A;
	assign VPALSTOP = VPAL & TIMERSTOP;
	assign BORDER_TOP = ~(VCOUNT[7] + VCOUNT[6] + VCOUNT[5] + VCOUNT[4]);
	assign BORDER_BOT = VCOUNT[7] & VCOUNT[6] & VCOUNT[5] & VCOUNT[4];
	assign BORDERS = BORDER_TOP + BORDER_BOT;
	assign TIMERRUNn = (VPALSTOP & BORDERS) | ~VCOUNT[8];
	
	// TIMERINT_MODE[1] is used in vblank !
	
	// Pixel timer
	always @(posedge CLK_6M)
	begin
		if (TIMER)
			TIMER <= TIMER - 1;
		else
		begin
			if (TIMERINT_EN) IRQ[1] = 1;	// IRQ2
			if (TIMERINT_MODE[2]) TIMER <= TIMERLOAD;
		end
	end
	
	// Pixel clock gen (polarity ?)
	reg [1:0] CLKDIV;
	
	assign CLK_6M = CLKDIV[1];
	
	always @(posedge CLK_24M)
	begin
		CLKDIV <= CLKDIV + 1;
	end
	
	wire [14:0] B;		// Low VRAM address
	wire [10:0] C;		// High VRAM address
	wire [15:0] E;		// Low VRAM data
	wire [15:0] F;		// High VRAM data

	vram_l VRAMLL(B, E[7:0], nBWE, nBOE, 0);
	vram_l VRAMLU(B, E[15:8], nBWE, nBOE, 0);
	vram_u VRAMUL(C, F[7:0], nCWE, 0, 0);
	vram_u VRAMUU(C, F[15:8], nCWE, 0, 0);
	
endmodule
