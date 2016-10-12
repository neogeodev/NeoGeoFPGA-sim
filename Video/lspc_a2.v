`timescale 1ns/1ns

module lspc_a2(
	// All pins listed ok. REF, DIVI and DIVO only used on AES for video PLL hack
	input CLK_24M,
	input nRESET,
	output [15:0] PBUS_OUT,
	inout [23:16] PBUS_IO,
	input [3:1] M68K_ADDR,
	inout [15:0] M68K_DATA,
	input nLSPOE, nLSPWE,
	input DOTA, DOTB,
	output CA4, S2H1,
	output S1H1,						// ?
	output LOAD, H, EVEN1, EVEN2,	// For ZMC2
	output IPL0, IPL1,
	output TMS0,						// Also called SCH and CHG
	output LD1, LD2,
	output PCK1, PCK2,
	output [3:0] WE,
	output [3:0] CK,
	input SS1, SS2,
	output nRESETP,
	output SYNC,
	output CHBL,
	output nBNKB,
	output nVCS,
	output CLK_8M,
	output CLK_4M,
	output [8:0] HCOUNT					// TODO: REMOVE, it's only used for debug in videout and as a hack in B1
);

	parameter VIDEO_MODE = 0;			// NTSC
	
	assign HCOUNT = MAIN_CNT[10:2];	// TODO: REMOVE

	// Todo: Merge VRAM cycle counters together if possible ? Even with P bus ?
	
	wire [15:0] REG_LSPCMODE;

	assign CLK_24MB = ~CLK_24M;
	
	wire [8:0] VCOUNT;
	//wire [8:0] HCOUNT;
	
	// Pixel timer
	reg [31:0] TIMERLOAD;		// Reload value
	reg [31:0] TIMER;				// Actual timer
	reg [2:0] TIMERINT_MODE;	// Timer interrupt mode
	reg TIMERINT_EN;				// Timer interrupt enable
	reg TIMERSTOP;					// Timer pause in top and bottom of display in PAL mode (LSPC2)
	
	// VRAM CPU I/O
	reg CPU_RW;										// Direction
	reg CPU_VRAM_ZONE;							// Top bit of VRAM address (low/high indicator)
	reg [14:0] CPU_VRAM_ADDR;
	reg [14:0] CPU_VRAM_ADDRESS_BUFFER;
	reg [15:0] REG_VRAMMOD;
	reg [15:0] CPU_VRAM_WRITE_BUFFER;
	wire [15:0] CPU_VRAM_READ_BUFFER_SCY;	// Are these all the same ?
	wire [15:0] CPU_VRAM_READ_BUFFER_FCY;
	wire [15:0] CPU_VRAM_READ_BUFFER;
	
	// Auto-animation
	reg [7:0] AASPEED;			// Auto-animation speed
	reg AA_DISABLE;				// Auto-animation disable
	wire [2:0] AACOUNT;			// Auto-animation counter
	
	wire [19:0] SPR_TILENB_OUT;		// SPR_ATTR_TILENB after auto-animation applied
	wire VBLANK;
	
	wire [1:0] SPR_ATTR_AA;
	
	reg [3:0] SPR_PIXELCNT;				// Sprite render pixel counter for H-shrink
	wire WR_PIXEL;
	
	wire [7:0] L0_DATA;
	
	wire nVSYNC;
	wire HSYNC;
	
	wire [11:0] MAIN_CNT;
	
	wire [11:0] SPR_ATTR_SHRINK;
	
	wire [8:0] SPR_NB;
	wire [4:0] SPR_TILEIDX;
	wire [7:0] SPR_TILEPAL;
	wire [1:0] SPR_TILEAA;
	wire [1:0] SPR_TILEFLIP;
	wire [19:0] SPR_TILENB;
	
	wire [11:0] FIX_TILENB;
	wire [3:0] FIX_TILEPAL;
	
	wire [16:0] FIX_ADDR;
	wire [24:0] SPR_ADDR;
	
	wire [7:0] SPR_XPOS;
	wire [15:0] L0_ADDR;
	
	reg IRQ_S1, IRQ_R1, IRQ_S2, IRQ_R2, IRQ_R3;
	wire IRQ_S3;
	
	resetp RSTP(CLK_24M, nRESET, nRESETP);
	
	assign IRQ_S3 = VBLANK;	// TODO: Verify
	irq IRQ(IRQ_S1, IRQ_R1, IRQ_S2, IRQ_R2, IRQ_S3, IRQ_R3, IPL0, IPL1);		// Probably uses nRESETP
	
	videosync VS(CLK_24M, nRESETP, VCOUNT, MAIN_CNT, TMS0, VBLANK, nVSYNC, HSYNC, nBNKB);

	odd_clk ODDCLK(CLK_24M, nRESETP, CLK_8M, CLK_4M, CLK_4MB);
	
	slow_cycle SCY(CLK_24M, nRESETP,
					HCOUNT[8:0], VCOUNT[7:3], SPR_NB, SPR_TILEIDX,	SPR_TILENB, SPR_TILEPAL,
					SPR_TILEAA, SPR_TILEFLIP, FIX_TILENB, FIX_TILEPAL,
					CPU_VRAM_ADDRESS_BUFFER, CPU_VRAM_ADDR, CPU_VRAM_READ_BUFFER_SCY, CPU_VRAM_WRITE_BUFFER,
					CPU_VRAM_ZONE, CPU_RW);
	
	// Todo: this needs to give SPR_NB, SPR_TILEIDX, SPR_XPOS, L0_ADDR, SPR_ATTR_SHRINK
	// Todo: this needs L0_DATA (from P bus)
	fast_cycle FCY(CLK_24M, nRESETP,
					CPU_VRAM_ADDRESS_BUFFER[10:0], CPU_VRAM_ADDR[10:0], CPU_VRAM_READ_BUFFER_FCY, CPU_VRAM_WRITE_BUFFER,
					CPU_VRAM_ZONE, CPU_RW);
	
	assign CPU_VRAM_READ_BUFFER = CPU_VRAM_ZONE ? CPU_VRAM_READ_BUFFER_FCY : CPU_VRAM_READ_BUFFER_SCY;

	// - -------- ---10000 HCOUNT for first fix address latch would be 4 ?
	// n nnnnnnnn nnnHHvvv
	// 6M: PCK2 = 4 pixels
	// 4: Latch from P, has 2 pixels
	// 5: Nothing
	// 6: S2H1 changes, has 2 pixels
	// 7: Nothing
	
	// Todo: Hack. Should just be HCOUNT[2:1]
	assign FIX_ADDR = {FIX_TILENB, (HCOUNT[2:1] - 1'b1), VCOUNT[2:0]};
		
	assign SPR_ADDR = {SPR_TILENB_OUT, 5'b00000};
	// Todo: assign CA4 = SPR_ADDR[4]; ?
	
	// This needs SPR_XPOS, L0_ADDR
	p_cycle PCY(nRESET, CLK_24M, HSYNC, FIX_ADDR, FIX_TILEPAL, SPR_ADDR, SPR_TILEPAL, SPR_XPOS, L0_ADDR,
					PCK1, PCK2, LOAD, S1H1, S2H1, nVCS, L0_DATA, {PBUS_IO, PBUS_OUT});
	
	autoanim AA(VBLANK, AASPEED, SPR_TILENB, AA_DISABLE, SPR_ATTR_AA, SPR_TILENB_OUT, AACOUNT);
	hshrink HSHRINK(SPR_ATTR_SHRINK[11:8], SPR_PIXELCNT, WR_PIXEL);
	
	assign SYNC = nVSYNC ^ HSYNC;
	
	// -------------------------------- Register access --------------------------------
	
	// Read only
	assign REG_LSPCMODE = {VCOUNT, 3'b000, VIDEO_MODE, AACOUNT};
	
	// Read - Todo: See if M68K_ADDR[3] is used or not (MAME says yes and should be = 0, no mirroring)
	assign M68K_DATA = (nLSPOE | ~nLSPWE) ? 16'bzzzzzzzzzzzzzzzz :
								(M68K_ADDR[2:1] == 2'b00) ? CPU_VRAM_READ_BUFFER :	// 3C0000/3C0008
								(M68K_ADDR[2:1] == 2'b01) ? CPU_VRAM_READ_BUFFER :	// 3C0002/3C000A
								(M68K_ADDR[2:1] == 2'b10) ? REG_VRAMMOD :				// 3C0004/3C000C
								REG_LSPCMODE;													// 3C0006/3C000E
	
	// Write
	always @(nLSPWE or nRESET)
	begin
		if (!nRESET)
		begin
			{IRQ_R3, IRQ_R2, IRQ_R1} <= 3'b111;		// TODO: Cold boot starts off with IRQ3
			{IRQ_S2, IRQ_S1} <= 2'b00;
		end
		else
		begin
			// 3C000C: Interrupt ack
			if ((!nLSPWE) && (M68K_ADDR[3:1] == 3'b110))
				{IRQ_R3, IRQ_R2, IRQ_R1} <= M68K_DATA[2:0];
			else
				{IRQ_R3, IRQ_R2, IRQ_R1} <= 3'b000;
		end
	end
	
	always @(negedge nLSPWE or negedge nRESET)	// ?
	begin
		if (!nRESET)
		begin
			// Something ?
		end
		else
		begin
			case (M68K_ADDR[3:1])
				// 3C0000
				3'b000 :
				begin
					// Read happens as soon as address is set (CPU access slot defaults to "read" all the time ?)
					//$display("VRAM set address to 0x%H", M68K_DATA);	// DEBUG
					{CPU_VRAM_ZONE, CPU_VRAM_ADDR} <= M68K_DATA;			// Ugly, probably simpler
					CPU_VRAM_ADDRESS_BUFFER <= M68K_DATA;					// Ugly, probably simpler
					//CPU_PENDING <= 1'b1;
					CPU_RW <= 1'b1;		// Reading
				end
				// 3C0002
				3'b001 :
				begin
					//$display("VRAM write data 0x%H @ 0x%H", M68K_DATA, {CPU_VRAM_ZONE, CPU_VRAM_ADDR});	// DEBUG
					CPU_VRAM_WRITE_BUFFER <= M68K_DATA;
					CPU_VRAM_ADDRESS_BUFFER <= CPU_VRAM_ADDR;
					CPU_VRAM_ADDR <= CPU_VRAM_ADDR + REG_VRAMMOD[14:0];
					CPU_RW <= 1'b0;		// Writing
				end
				// 3C0004
				3'b010 : 
				begin
					$display("VRAM set mod to 0x%H", M68K_DATA);		// DEBUG
					REG_VRAMMOD <= M68K_DATA;
				end
				// 3C0006
				3'b011 :
				begin
					$display("LSPC set mode to 0x%H", M68K_DATA);	// DEBUG
					AASPEED <= M68K_DATA[15:8];
					TIMERINT_MODE <= M68K_DATA[7:5];
					TIMERINT_EN <= M68K_DATA[4];
					AA_DISABLE <= M68K_DATA[3];
				end
				// 3C0008
				3'b100 :
				begin
					$display("LSPC set timer reload MSB to 0x%H", M68K_DATA);	// DEBUG
					TIMERLOAD[31:16] <= M68K_DATA;
				end
				// 3C000A
				3'b101 :
				begin
					$display("LSPC set timer reload LSB to 0x%H", M68K_DATA);	// DEBUG
					TIMERLOAD[15:0] <= M68K_DATA;
					// if (TIMERINT_MODE[0]) TIMER <= TIMERLOAD;
				end
				// 3C000C: Interrupt ack
				3'b110 :
				begin
					$display("LSPC ack interrupt 0x%H", M68K_DATA[2:0]);	// DEBUG
					// Done in combi. logic above
				end
				// 3C000E
				3'b111 :
				begin
					$display("LSPC set timer stop (PAL) to %B", M68K_DATA[0]);	// DEBUG
					TIMERSTOP <= M68K_DATA[0];
				end
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
	always @(negedge MAIN_CNT[2])	// posedge ? pixel clock
	begin
		if (!nRESET)
		begin
			TIMER <= 0;
		end
		else
		begin
			if (!nTIMERRUN)
			begin
				if (TIMER)
					TIMER <= TIMER - 1'b1;
				else
				begin
					//if (TIMERINT_EN) nIRQS[1] <= 1'b0;	// IRQ2 plz
					if (TIMERINT_MODE[2]) TIMER <= TIMERLOAD;
				end
			end
		end
	end
	
endmodule
