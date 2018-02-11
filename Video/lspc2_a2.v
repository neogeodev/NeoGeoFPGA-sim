`timescale 1ns/1ns

// All pins listed ok. REF, DIVI and DIVO only used on AES for video PLL hack
// Video mode pin is the VMODE parameter

module lspc2_a2(
	input CLK_24M,
	input RESET,
	output [15:0] PBUS_OUT,
	inout [23:16] PBUS_IO,
	input [3:1] M68K_ADDR,
	inout [15:0] M68K_DATA,
	input LSPOE, LSPWE,
	input DOTA, DOTB,
	output CA4,
	output S2H1,
	output S1H1,
	output reg LOAD,
	output H, EVEN1, EVEN2,			// For ZMC2
	output IPL0, IPL1,
	output CHG,							// Also called TMS0
	output LD1, LD2,					// Buffer address load
	output PCK1, PCK2,
	output [3:0] WE,
	output [3:0] CK,
	output SS1, SS2,					// Buffer pair selection for B1
	output RESETP,
	output SYNC,
	output CHBL,
	output BNKB,
	output VCS,							// LO ROM output enable
	output LSPC_8M,
	output LSPC_4M
);

	parameter VMODE = 1'b0;	// NTSC
	
	wire [8:0] PIXELC;
	wire [3:0] PIXEL_HPLUS;
	wire [8:0] RASTERC;
	wire [7:0] AA_SPEED;
	wire [2:0] AA_COUNT;				// Auto-animation tile #
	reg [7:0] WR_DECODED;
	wire [15:0] CPU_DATA_MUX;
	wire [15:0] CPU_DATA_OUT;
	wire [15:0] VRAM_ADDR_RAW;
	wire [15:0] VRAM_READ_LOW;
	wire [15:0] VRAM_READ_HIGH;
	wire [15:0] VRAM_ADDR_MUX;
	wire [15:0] VRAM_ADDR_AUTOINC;
	
	wire [15:0] REG_VRAMMOD;
	wire [15:0] REG_LSPCMODE;
	
	wire [2:0] TIMER_MODE;
	
	wire [3:0] T31_P;
	wire [3:0] U24_P;
	wire [3:0] PIPE_A;
	wire [3:0] PIPE_B;
	wire [3:0] PIPE_C;
	
	
	
	assign S1H1 = LSPC_3M;
	assign S2H1 = LSPC_1_5M;
	
	assign CA4 = T172_Q ^ LSPC_1_5M;
	FDM T172(T168A_nQ, SPR_TILE_HFLIP, T172_Q, );
	FD2 T168A(CLK_24M, T160A_OUT, T168A_Q, T168A_nQ);
	
	FD2 U167(~T162A_Q, T172_Q, H, );
	FD2 T162A(CLK_24M, T160B_OUT, T162A_Q, );
	
	assign PCK1 = T168A_Q;
	assign PCK2 = T162A_Q;
	
	FD2 U144A(CLK_24M, U112_OUT, EVEN2, );
	assign U112_OUT = ~&{U105A_OUT, U107_OUT, U109_OUT};
	assign EVEN1 = U112_OUT;
	assign U105A_OUT = ~&{U110A_OUT, U111B_OUT, U74A_nQ};
	assign U107_OUT = ~&{U110A_OUT, U74A_Q, HSHRINK_B};
	assign U109_OUT = ~&{U110A_OUT, U74A_nQ, HSHRINK_A};
	FD2 U74A(~U68A_nQ, U56A_OUT, U74A_Q, U74A_nQ);
	
	assign U110A_OUT = ~HSHRINK_A;
	assign U111B_OUT = ~HSHRINK_B;
	
	// C27: CPU write decode
	always @(*)
	begin
		if (~LSPWE)
		begin
			case (M68K_ADDR)
				3'h0 : WR_DECODED <= 8'b11111110;
				3'h1 : WR_DECODED <= 8'b11111101;
				3'h2 : WR_DECODED <= 8'b11111011;
				3'h3 : WR_DECODED <= 8'b11110111;
				3'h4 : WR_DECODED <= 8'b11101111;
				3'h5 : WR_DECODED <= 8'b11011111;
				3'h6 : WR_DECODED <= 8'b10111111;
				3'h7 : WR_DECODED <= 8'b01111111;
			endcase
		end
		else
			WR_DECODED <= 8'b11111111;
	end
	
	assign WR_VRAM_ADDR = WR_DECODED[0];
	assign WR_VRAM_RW = WR_DECODED[1];
	assign WR_VRAM_MOD = WR_DECODED[2];
	assign WR_LSPC_MODE = WR_DECODED[3];
	assign WR_TIMER_HIGH = WR_DECODED[4];
	assign WR_TIMER_LOW = WR_DECODED[5];
	assign WR_IRQ_ACK = WR_DECODED[6];
	assign WR_TIMER_STOP = WR_DECODED[7];
	
	// CPU reads
	
	assign REG_LSPCMODE = {RASTERC, 3'b0, VMODE, AA_COUNT};
	
	assign CPU_READ = ~|{~|{M68K_ADDR[1], ~M68K_ADDR[2]}, ~|{VRAM_ADDR_RAW[15], M68K_ADDR[2]}};
	
	assign CPU_DATA_MUX = M68K_ADDR[2] ? 
							CPU_READ ? REG_VRAMMOD : REG_LSPCMODE			// Maybe swapped
							:
							CPU_READ ? VRAM_READ_LOW : VRAM_READ_HIGH;	// Maybe swapped
	
	assign C22A_OUT = ~&{WR_VRAM_RW, WR_VRAM_ADDR};
	FDM B18(C22A_OUT, M68K_ADDR[1], B18_Q, );
	
	// B138 A123 A68 A28
	FDS16bit B138(~B18_Q, CPU_DATA_MUX, CPU_DATA_OUT);
	
	// This is strange
	assign M68K_DATA[1:0] = LSPOE ? 2'bzz : CPU_DATA_OUT[1:0];
	assign B71_OUT = ~&{~LSPOE, C71_nQ};
	assign M68K_DATA[7:2] = B71_OUT ? 6'bzzzzzz : CPU_DATA_OUT[7:2];
	assign B75A_OUT = ~&{~LSPOE, C68_nQ};
	assign M68K_DATA[9:8] = B75A_OUT ? 2'bzz : CPU_DATA_OUT[9:8];
	assign B74_OUT = ~&{~LSPOE, C75_nQ};
	assign M68K_DATA[15:10] = B74_OUT ? 6'bzzzzzz : CPU_DATA_OUT[15:10];
	
	FDM C71(CLK_24M, LSPOE, C71_Q, C71_nQ);
	FDM C68(CLK_24MB, C71_Q, C68_Q, C68_nQ);
	FDM C75(CLK_24M, C68_Q, , C75_nQ);
	
	
	// CPU write to REG_VRAMMOD
	// H105 G105 F81 G123
	FDS16bit H105(~WR_VRAM_MOD, M68K_DATA, REG_VRAMMOD);
	
	
	// CPU write to REG_VRAMADDR
	// F47 D87 A79 C123
	FDS16bit F47(~WR_VRAM_ADDR, M68K_DATA, VRAM_ADDR_RAW);
	
	// CPU VRAM address update mux (new REG_VRAMADDR value, or auto-inc)
	// C144A C142A C140B C138B
	// A112B A111A A109A A110B
	// D110B D106B D108B D85A
	// F10A F12A F26A F12B
	assign VRAM_ADDR_MUX = B18_Q ? VRAM_ADDR_RAW : VRAM_ADDR_AUTOINC;	// Maybe swapped ?
	
	// F14 D48 C105 C164
	FDS16bit F14(D112B_OUT, VRAM_ADDR_MUX, VRAM_ADDR);
	
	// G18 G81 F91 F127
	assign VRAM_ADDR_AUTOINC = REG_VRAMMOD + VRAM_ADDR;
	
	
	
	// CPU write to REG_VRAMRW
	// F155 D131 D121 E154
	FDS16bit F155(~WR_VRAM_RW, M68K_DATA, VRAM_RW_FIRST);
	
	// F165 D178 D141 E196   
	FDS16bit E196(O108B_OUT, VRAM_RW_FIRST, VRAM_WRITE);
	
	assign F58B_OUT = VRAM_ADDR_RAW[15] | VRAM_WRITE_REQ;
	
	FDPCell Q106(~LSPC_1_5M, F58B_OUT, ~Q174A_OUT, 1'b1, Q106_Q, );
	assign O108B_OUT = ~&{N93_Q, Q106_Q};
	assign D112B_OUT = ~|{~WR_VRAM_ADDR, O108B_OUT};
	
	FDPCell D38(~WR_VRAM_RW, 1'b1, 1'b1, D32A_OUT, VRAM_WRITE_REQ, D38_nQ);
	FDPCell D28(D112B_OUT, 1'b1, 1'b1, D38_nQ, D28_Q, );
	
	// Used for test mode
	assign D32A_OUT = D28_Q & 1'b1;
	
	
	// CPU write to REG_LSPCMODE
	
	FDPCell D34(WR_TIMER_STOP, M68K_DATA[0], 1'b1, RESETP, , D34_nQ);
	FDRCell E61(WR_LSPC_MODE, M68K_DATA[6:3], RESET, {TIMER_MODE[1:0], TIMER_IRQ_EN, AA_DISABLE});
	FDPCell E74(WR_LSPC_MODE, M68K_DATA[7], 1'b1, RESET, TIMER_MODE[2], );
	FDSCell C87(WR_LSPC_MODE, M68K_DATA[11:8], AA_SPEED[3:0]);
	FDSCell E105(WR_LSPC_MODE, M68K_DATA[15:12], AA_SPEED[7:4]);
	
	
	// Clock divider in timing stuff
	
	FDPCell T69(LSPC_12M, LSPC_3M, 1'b1, RESETP, , T69_nQ);
	assign T73A_OUT = LSPC_3M | T69_nQ;
	FJD T140(CLK_24M, T134_nQ, 1'b1, T73A_OUT, T140_Q, );
	FJD T134(CLK_24M, T140_Q, 1'b1, T73A_OUT, , T134_nQ);
	
	FD2 U129A(CLK_24M, T134_nQ, U129A_Q, );
	assign T125A_OUT = T140_Q | U129A_Q;
	
	
	
	// NEO-B1 control signals
	
	LT4 T31(LSPC_12M, {T38A_OUT, T28_OUT, T29A_OUT, T20B}, T31_P);
	LT4 U24(LSPC_12M, {U37B_OUT, U21B_OUT, U35A_OUT, U31A_OUT}, U24_P);
	
	assign WE1 = ~&{T31_P[1], LSPC_12M};
	assign WE2 = ~&{T31_P[0], LSPC_12M};
	assign WE3 = ~&{U24_P[3], LSPC_12M};
	assign WE4 = ~&{U24_P[2], LSPC_12M};
	
	assign CK1 = ~&{T31_P[3], LSPC_12M};
	assign CK2 = ~&{T31_P[2], LSPC_12M};
	assign CK3 = ~&{U24_P[1], LSPC_12M};
	assign CK4 = ~&{U24_P[0], LSPC_12M};
	
	// Most of the following NAND gates are probably making 2:1 muxes like on the Alpha68k
	assign T20B_OUT = ~&{T22A_OUT, T17A_OUT};
	assign T29A_OUT = ~&{T40B_OUT, T22B_OUT};
	assign T38A_OUT = ~&{T40B_OUT, T40A_OUT, R40A_OUT};
	assign T28_OUT = ~&{T22A_OUT, R40A_OUT, T50A_OUT};
	
	assign U37B_OUT = ~&{U33B_OUT, U33A_OUT};
	assign U21B_OUT = ~&{T20A_OUT, U18A_OUT};
	assign U31A_OUT = ~&{R40B_OUT, T20A_OUT, U51B_OUT};
	assign U35A_OUT = ~&{R40B_OUT, U33B_OUT, U39B_OUT};
	
	assign T22A_OUT = ~&{T50B_OUT, SS1};
	assign T17A_OUT = ~&{DOTA, ~T50A_OUT};
	assign T22B_OUT = ~&{DOTB, ~T40A_OUT};
	assign T40B_OUT = ~&{T48A_OUT, SS1};
	
	assign U33B_OUT = ~&{T48A_OUT, SS2};
	assign U33A_OUT = ~&{~U39B_OUT, DOTB};
	assign U18A_OUT = ~&{~U51B_OUT, DOTA};
	assign T20A_OUT = ~&{T50B_OUT, SS2};
	
	assign T50A_OUT = ~&{R63_Q, T82A_Q};
	assign T40A_OUT = ~&{T86_Q, R63_Q};
	assign U39B_OUT = ~&{LSPC_3M, R63_nQ};
	assign U51B_OUT = ~&{T82A_Q, R63_nQ};
	
	assign T48A_OUT = ~LSPC_3M & LSPC_6M;
	assign T50B_OUT = LSPC_6M & LSPC_3M;
	assign T56A_OUT = ~&{LSPC_6M, LSPC_3M};
	assign T58A_OUT = ~&{LSPC_6M, LSPC_3M};
	
	assign SS1 = ~|{S48_nQ, R63_Q};
	assign SS2 = ~|{R63_nQ, S48_nQ};
	
	FD2 T82A(CLK_24M, U85_OUT, T82A_Q, );
	FD2 T86(CLK_24M, U86A_OUT, T86_Q, );
	
	FDM S48(LSPC_3M, R15_QD, , S48_nQ);
	
	FD2 R35A(CLK_24MB, S53A_OUT, LOAD, );
	FD2 R32(CLK_24MB, R40A_OUT, LD1, );
	FD2 R28A(CLK_24MB, R40B_OUT, LD2, );
	
	// Most of the following NAND gates are probably making 2:1 muxes like on the Alpha68k
	assign R40A_OUT = ~&{R42B_OUT, S53A_OUT};
	assign R40B_OUT = ~&{R46B_OUT, S53A_OUT};
	
	assign R42B_OUT = ~&{R44B_OUT, R48B_OUT};
	assign R46B_OUT = ~&{R44A_OUT, R46A_OUT};
	
	assign R44B_OUT = ~&{R50_nQ, R53_Q};
	assign R48B_OUT = ~&{R72B_OUT, R50_Q};
	assign R44A_OUT = ~&{R53_Q, R50_Q};
	assign R46A_OUT = ~&{R50_nQ, R72B_OUT};
	
	assign R72B_OUT = ~|{PIPE_C[13], R69_nQ};
	assign S53A_OUT = S55_Q & LSPC_6M;
	FDM R50(LSPC_3M, O69_Q, R50_Q, R50_nQ);
	FDM R53(LSPC_3M, R67A_OUT, R53_Q, );
	FDM S55(LSPC_12M, LSPC_3M, S55_Q, );
	FDM R69(LSPC_3M, LSPC_1_5M, R69_q, R69_nQ);
	
	
	
	
	// CHG output
	FDPCell S137(LSPC_1_5M, R63_Q, 1'b1, RESETP, CHG, );
	
	FDPCell R63(PIXELC[2], O69_nQ, 1'b1, RESETP, R63_Q, R63_nQ);
	FDPCell O69(CLK_24MB, ~H287_Q, RESETP, 1'b1, , O69_nQ);
	
	
	// 16-pixel lookahead for fix tiles
	// I51
	assign PIXEL_HPLUS = 5'd15 + {~J20A_OUT, PIXELC[6:4]} + PIXELC[3];
	assign J20A_OUT = ~&{PIXELC[8:7]};
	
	/*lspc_regs REGS(RESET, CLK_24M, M68K_ADDR, M68K_DATA, nLSPOE, nLSPWE, PCK1, AA_COUNT, V_COUNT[7:0],
					VIDEO_MODE, REG_LSPCMODE,
					CPU_VRAM_ZONE, CPU_WRITE_REQ, CPU_VRAM_ADDR, CPU_VRAM_WRITE_BUFFER,
					RELOAD_REQ_SLOW, RELOAD_REQ_FAST,
					TIMER_LOAD, TIMER_PAL_STOP, REG_VRAMMOD, TIMER_MODE, TIMER_IRQ_EN,
					AA_SPEED, AA_DISABLE,
					IRQ_S1, IRQ_R1, IRQ_S2, IRQ_R2, IRQ_R3);*/
	
	lspc_timer TIMER(~LSPC_6M, M68K_DATA, WR_TIMER_HIGH, WR_TIMER_LOW, VMODE, TIMER_STOP, RASTERC);
	
	resetp RSTP(CLK_24MB, RESET, RESETP);
	
	irq IRQ(WR_IRQ_ACK, M68K_DATA[2:0], RESET, 1'b0, BNK, LSPC_6M, IPL0, IPL1);
	
	videosync VS(CLK_24MB, LSPC_1_5M, Q53_CO, RESETP, VMODE, PIXELC, RASTERC, SYNC, BNK, BNKB, CHBL,
						R15_QD, H287_Q);

	lspc2_clk LSPCCLK(CLK_24M, RESETP, CLK_24MB, LSPC_12M, LSPC_8M, LSPC_6M, LSPC_4M, LSPC_3M, LSPC_1_5M,
							Q53_CO);
	
	slow_cycle SCY();
	fast_cycle FCY(N93_Q);
	
	// This needs L0_ADDR
	//p_cycle PCY(RESET, CLK_24M, PBUS_S_ADDR, FIX_ATTR_PAL, PBUS_C_ADDR, SPR_TILE_PAL, XPOS,
	//				L0_ROM_ADDR, nVCS, L0_ROM_DATA, {PBUS_IO, PBUS_OUT});
	
	autoanim AA(RASTERC[8], RESETP, AA_SPEED, AA_COUNT);
	
	hshrink HSH(, , , HSHRINK_A, HSHRINK_B);
	
endmodule
