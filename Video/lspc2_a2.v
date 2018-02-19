// NeoGeo logic definition (simulation only)
// Copyright (C) 2018 Sean Gonsalves
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
	output LOAD,
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

	parameter VMODE = 1'b0;			// NTSC
	
	wire [8:0] PIXELC;
	wire [3:0] PIXEL_HPLUS;
	wire [8:0] RASTERC;
	wire [7:0] AA_SPEED;
	wire [2:0] AA_COUNT;				// Auto-animation tile #
	reg [7:0] WR_DECODED;
	wire [15:0] CPU_DATA_MUX;
	wire [15:0] CPU_DATA_OUT;
	wire [15:0] VRAM_ADDR_RAW;
	wire [15:0] VRAM_LOW_READ;
	wire [15:0] VRAM_HIGH_READ;
	wire [15:0] VRAM_ADDR_MUX;
	wire [15:0] VRAM_ADDR_AUTOINC;
	wire [15:0] VRAM_ADDR;
	wire [15:0] VRAM_RW_FIRST;
	wire [15:0] VRAM_WRITE;
	
	wire [15:0] REG_VRAMMOD;
	wire [15:0] REG_LSPCMODE;
	
	wire [2:0] TIMER_MODE;
	
	wire [3:0] T31_P;
	wire [3:0] U24_P;
	wire [3:0] O227_Q;
	
	wire [7:0] P_MUX_X_YSH;
	wire [7:0] P_MUX_SPRLINE;
	wire [23:0] P_OUT_MUX;
	
	wire [3:0] VSHRINK_INDEX;
	wire [3:0] VSHRINK_LINE;
	wire [8:0] XPOS;
	wire [2:0] SPR_TILE_AA;
	wire [3:0] G233_Q;
	wire [7:0] SPR_Y_LOOKAHEAD;
	wire [8:0] SPR_Y_ADD;
	wire [7:0] SPR_TILE_A;		// This should be called SPR_Y_RENDER or something similar
	wire [7:0] SPR_TILE_AB;		// This should be called SPR_Y_RENDER_LOOP or something similar
	wire [8:0] SPR_Y_SHRINK;
	wire [3:0] SPR_LINE;
	wire [19:0] SPR_TILE;
	wire [7:0] YSHRINK;
	wire [8:0] SPR_Y;
	wire [7:0] SPR_PAL;
	wire [3:0] FIX_PAL;
	wire [5:0] SPR_SIZE;
	wire [11:0] FIX_TILE;
	wire [3:0] HSHRINK;
	wire [15:0] PIPE_C;
	wire [3:0] SPR_TILEMAP;
	wire [7:0] ACTIVE_RD;
	wire [3:0] P201_Q;
	

	
	assign S1H1 = LSPC_3M;
	assign S2H1 = LSPC_1_5M;
	assign CA4 = T172_Q ^ LSPC_1_5M;
	
	// PCK1, PCK2, H
	FD2 T168A(CLK_24M, T160A_OUT, PCK1, nPCK1);
	FD2 T162A(CLK_24M, T160B_OUT, PCK2, );
	FD2 U167(~PCK2, T172_Q, H, );
	
	// EVEN1, EVEN2
	assign U112_OUT = ~&{U105A_OUT, U107_OUT, U109_OUT};
	assign U105A_OUT = ~&{nHSHRINK_OUT_A, nHSHRINK_OUT_B, U74A_nQ};
	assign U107_OUT = ~&{nHSHRINK_OUT_A, U74A_Q, HSHRINK_OUT_B};
	assign U109_OUT = ~&{nHSHRINK_OUT_A, U74A_nQ, HSHRINK_OUT_A};
	assign EVEN1 = U112_OUT;
	FD2 U144A(CLK_24M, U112_OUT, EVEN2, );
	
	assign nHSHRINK_OUT_A = ~HSHRINK_OUT_A;
	assign nHSHRINK_OUT_B = ~HSHRINK_OUT_B;
	
	FDM T172(nPCK1, SPR_TILE_HFLIP, T172_Q, );
	FD2 U74A(~U68A_nQ, U56A_OUT, U74A_Q, U74A_nQ);
	
	
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
							CPU_READ ? VRAM_HIGH_READ : VRAM_LOW_READ;	// Order OK
	
	// B138 A123 A68 A28
	FDS16bit B138(~LSPOE, CPU_DATA_MUX, CPU_DATA_OUT);
	
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
	
	assign C22A_OUT = ~&{WR_VRAM_RW, WR_VRAM_ADDR};
	FDM B18(C22A_OUT, M68K_ADDR[1], VRAM_ADDR_UPD_TYPE, );
	
	// CPU VRAM address update mux (new REG_VRAMADDR value, or auto-inc)
	// C144A C142A C140B C138B
	// A112B A111A A109A A110B
	// D110B D106B D108B D85A
	// F10A F12A F26A F12B
	assign VRAM_ADDR_MUX = VRAM_ADDR_UPD_TYPE ? VRAM_ADDR_AUTOINC : VRAM_ADDR_RAW;
	
	// F14 D48 C105 C164
	FDS16bit F14(D112B_OUT, VRAM_ADDR_MUX, VRAM_ADDR);
	
	// G18 G81 F91 F127
	assign VRAM_ADDR_AUTOINC = REG_VRAMMOD + VRAM_ADDR;
	
	
	
	// CPU write to REG_VRAMRW
	// F155 D131 D121 E154
	FDS16bit F155(~WR_VRAM_RW, M68K_DATA, VRAM_RW_FIRST);
	
	// F165 D178 D141 E196   
	FDS16bit E196(O108B_OUT, VRAM_RW_FIRST, VRAM_WRITE);
	
	// Write to VRAM ack
	assign F58B_OUT = VRAM_ADDR_RAW[15] | nVRAM_WRITE_REQ;
	FDPCell Q106(~LSPC_1_5M, F58B_OUT, CLK_CPU_READ_LOW, 1'b1, nCPU_WR_LOW, );
	assign O108B_OUT = ~&{nCPU_WR_HIGH, nCPU_WR_LOW};
	assign D112B_OUT = ~|{~WR_VRAM_ADDR, O108B_OUT};
	
	FDPCell D38(~WR_VRAM_RW, 1'b1, 1'b1, D32A_OUT, D38_Q, nVRAM_WRITE_REQ);
	FDPCell D28(D112B_OUT, 1'b1, 1'b1, D38_Q, , D28_nQ);
	
	// Used for test mode
	assign D32A_OUT = D28_nQ & 1'b1;
	
	
	
	// CPU write to REG_LSPCMODE
	
	FDPCell D34(WR_TIMER_STOP, M68K_DATA[0], RESETP, 1'b1, , TIMER_STOP);	// TODO: Use TIMER_STOP
	FDRCell E61(WR_LSPC_MODE, M68K_DATA[6:3], RESET, {TIMER_MODE[1:0], TIMER_IRQ_EN, AA_DISABLE});
	FDPCell E74(WR_LSPC_MODE, M68K_DATA[7], 1'b1, RESET, TIMER_MODE[2], );
	FDSCell C87(WR_LSPC_MODE, M68K_DATA[11:8], AA_SPEED[3:0]);
	FDSCell E105(WR_LSPC_MODE, M68K_DATA[15:12], AA_SPEED[7:4]);
	// C184A
	assign AUTOANIM3_EN = SPR_AA_3 & ~AA_DISABLE;
	assign C186A_OUT = SPR_AA_2 & ~AA_DISABLE;
	// B180B
	assign AUTOANIM2_EN = AUTOANIM3_EN | C186A_OUT;
	
	
	// Clock divider in timing stuff
	
	FDPCell T69(LSPC_12M, LSPC_3M, RESETP, 1'b1, , T69_nQ);
	assign T73A_OUT = LSPC_3M | T69_nQ;
	FJD T140(CLK_24M, T134_nQ, 1'b1, T73A_OUT, T140_Q, );
	FJD T134(CLK_24M, T140_Q, 1'b1, T73A_OUT, , T134_nQ);
	
	FD2 U129A(CLK_24M, T134_nQ, U129A_Q, U129A_nQ);
	assign T125A_OUT = U129A_nQ | T140_Q;
	
	
	
	// NEO-B1 control signals
	
	LT4 T31(LSPC_12M, {T38A_OUT, T28_OUT, T29A_OUT, T20B_OUT}, T31_P);
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
	assign T38A_OUT = ~&{T40B_OUT, T40A_OUT, LD1_D};
	assign T28_OUT = ~&{T22A_OUT, LD1_D, T50A_OUT};
	
	assign U37B_OUT = ~&{U33B_OUT, U33A_OUT};
	assign U21B_OUT = ~&{T20A_OUT, U18A_OUT};
	assign U31A_OUT = ~&{LD2_D, T20A_OUT, U51B_OUT};
	assign U35A_OUT = ~&{LD2_D, U33B_OUT, U39B_OUT};
	
	assign T22A_OUT = ~&{T50B_OUT, SS1};
	assign T17A_OUT = ~&{DOTA, ~T50A_OUT};
	assign T22B_OUT = ~&{DOTB, ~T40A_OUT};
	assign T40B_OUT = ~&{T48A_OUT, SS1};
	
	assign U33B_OUT = ~&{T48A_OUT, SS2};
	assign U33A_OUT = ~&{~U39B_OUT, DOTB};
	assign U18A_OUT = ~&{~U51B_OUT, DOTA};
	assign T20A_OUT = ~&{T50B_OUT, SS2};
	
	assign T50A_OUT = ~&{CHG_D, WRITEPX_A};
	assign T40A_OUT = ~&{WRITEPX_B, CHG_D};
	assign U39B_OUT = ~&{WRITEPX_B, nCHG_D};
	assign U51B_OUT = ~&{nCHG_D, WRITEPX_A};
	
	// Clocks
	assign T48A_OUT = ~LSPC_3M & LSPC_6M;
	assign T50B_OUT = LSPC_6M & LSPC_3M;
	
	assign T56A_OUT = ~&{LSPC_6M, LSPC_3M};
	assign T58A_OUT = ~&{LSPC_6M, LSPC_3M};
	
	FD2 T82A(CLK_24M, U85_OUT, WRITEPX_A, );
	FD2 T86(CLK_24M, U86A_OUT, WRITEPX_B, );
	assign U85_OUT = &{U89A_OUT, U92A_OUT, U88B_OUT};
	assign U86A_OUT = &{U88B_OUT, U94_OUT, U91_OUT};
	assign U89A_OUT = ~&{nHSHRINK_OUT_B, U74A_nQ, HSHRINK_OUT_A};
	assign U92A_OUT = ~&{nHSHRINK_OUT_A, U74A_nQ, HSHRINK_OUT_B};
	assign U91_OUT = ~&{nHSHRINK_OUT_B, U74A_Q, HSHRINK_OUT_A};
	assign U94_OUT = ~&{nHSHRINK_OUT_A, U74A_Q, HSHRINK_OUT_B};
	assign U88B_OUT = HSHRINK_OUT_A | HSHRINK_OUT_B;
	
	// LOAD, LD1, LD2 output
	FD2 R35A(CLK_24MB, S53A_OUT, LOAD, );
	FD2 R32(CLK_24MB, LD1_D, LD1, );
	FD2 R28A(CLK_24MB, LD2_D, LD2, );
	
	// Most of the following NAND gates are probably making 2:1 muxes like on the Alpha68k
	assign LD1_D = ~&{R42B_OUT, S53A_OUT};
	assign LD2_D = ~&{R46B_OUT, S53A_OUT};
	
	assign R42B_OUT = ~&{R44B_OUT, R48B_OUT};
	assign R46B_OUT = ~&{R44A_OUT, R46A_OUT};
	
	assign R44B_OUT = ~&{R50_nQ, R53_Q};
	assign R48B_OUT = ~&{R72B_OUT, R50_Q};
	assign R44A_OUT = ~&{R53_Q, R50_Q};
	assign R46A_OUT = ~&{R50_nQ, R72B_OUT};
	
	assign R72B_OUT = ~|{PIPE_C[13], R69_nQ};
	assign S53A_OUT = S55_Q & LSPC_6M;
	FDM R50(LSPC_3M, nFLIP_Q, R50_Q, R50_nQ);
	FDM R53(LSPC_3M, R67A_OUT, R53_Q, );
	FDM S55(LSPC_12M, LSPC_3M, S55_Q, );
	FDM R69(LSPC_3M, U74A_nQ, R69_Q, R69_nQ);
	assign R67A_OUT = R74_nQ & P74_Q;
	FDPCell R74(LSPC_1_5M, P74_Q, 1'b1, RESETP, , R74_nQ);
	FDPCell P74(PIXELC[2], O62_Q, 1'b1, RESETP, P74_Q, );
	FDPCell O62(PIXELC[3], PIXELC[8], 1'b1, RESETP, O62_Q);
	
	assign R48A_OUT = ~{S53A_OUT, R69_Q};
	FD2 R56A(CLK_24MB, R48A_OUT, LD_HSHRINK_REG, );		// TODO: Use LD_HSHRINK_REG
	
	
	// CHG output
	FDPCell S137(LSPC_1_5M, CHG_D, 1'b1, RESETP, CHG, );
	
	// SS1, SS2 output
	FDPCell R63(PIXELC[2], nFLIP_Q, 1'b1, RESETP, CHG_D, nCHG_D);
	FDPCell O69(CLK_24MB, nFLIP, RESETP, 1'b1, , nFLIP_Q);
	FDM S48(LSPC_3M, R15_QD, , S48_nQ);
	// S40A
	assign SS1 = ~|{S48_nQ, CHG_D};
	// S39
	assign SS2 = ~|{nCHG_D, S48_nQ};
	
	
	// 16-pixel lookahead for fix tiles
	// I51
	assign PIXEL_HPLUS = 5'd15 + {~J20A_OUT, PIXELC[6:4]} + PIXELC[3];
	assign J20A_OUT = ~&{PIXELC[8:7]};
	
	
	// Y-shrink stuff
	FDM R179(VCS, SPR_CONTINUOUS, R179_Q);
	assign S186_OUT = ~(~P235_OUT ^ R179_Q);
	assign SPRITEMAP_ADDR_MSB = ~S186_OUT;
	assign S166_OUT = VSHRINK_LINE[3] ^ ~S186_OUT;
	assign S164_OUT = VSHRINK_LINE[2] ^ ~S186_OUT;
	assign S162_OUT = VSHRINK_LINE[1] ^ ~S186_OUT;
	assign S168_OUT = VSHRINK_LINE[0] ^ ~S186_OUT;
	FDSCell O227(P222A_OUT, {S166_OUT, S164_OUT, S162_OUT, S168_OUT}, O227_Q);
	FDSCell G233(P210A_OUT, O227_Q, G233_Q);
	assign SPR_LINE[0] = SPR_TILE_VFLIP ^ G233_Q[0];
	assign SPR_LINE[1] = SPR_TILE_VFLIP ^ G233_Q[1];
	assign SPR_LINE[2] = SPR_TILE_VFLIP ^ G233_Q[2];
	assign SPR_LINE[3] = SPR_TILE_VFLIP ^ G233_Q[3];
	assign Q184_OUT = VSHRINK_INDEX[3] ^ ~S186_OUT;
	assign Q182_OUT = VSHRINK_INDEX[2] ^ ~S186_OUT;
	assign Q186_OUT = VSHRINK_INDEX[1] ^ ~S186_OUT;
	assign Q172_OUT = VSHRINK_INDEX[0] ^ ~S186_OUT;
	FDSCell O175(P222A_OUT, {Q184_OUT, Q182_OUT, Q186_OUT, Q172_OUT}, SPR_TILEMAP);
	
	
	// P bus stuff
	assign PBUS_IO = U51A_OUT ? P_OUT_MUX[23:16] : 8'bzzzzzzzz;
	assign PBUS_OUT = P_OUT_MUX[15:0];
	
	FDSCell Q87(VCS, PBUS_IO[23:20], VSHRINK_INDEX);
	FDSCell S141(VCS, PBUS_IO[19:16], VSHRINK_LINE);
	
	FDM R88(CLK_24M, R94A_OUT, R88_Q, R88_nQ);
	assign VCS = ~R88_nQ;
	assign R94A_OUT = ~&{P201_Q[2], R91_Q};
	FS1 P201(LSPC_12M, Q174B_OUT, P201_Q);
	
	FDM S183(T185B_OUT, S171_Q, S183_Q, );
	FDM S171(U53_Q, LSPC_1_5M, S171_Q, S171_nQ);
	assign T185B_OUT = PCK1 | PCK2;
	
	assign XPOS = PIPE_C[8:0];
	
	// C250 A238A A232 A234A
	// E271 E273A E268A D255
	assign P_OUT_MUX[23:16] = ~S183_Q ? 
										~S171_nQ ? {4'b0000, FIX_PAL} : {SPR_TILE[19:16], SPR_LINE}
										:
										~S171_nQ ? {8'b00000000} : {SPR_PAL};
	
	assign P_OUT_MUX[15:0] = ~S183_Q ?
										~S171_nQ ? {8'b00000000, 8'b00000000} : {SPR_TILE[15:8], SPR_TILE[7:3], SPR_TILE_AA}
										:
										~S171_nQ ? {PIXELC[2], RASTERC[2:1], FLIP, FIX_TILE[11:8], FIX_TILE[7:0]} : {P_MUX_X_YSH, P_MUX_SPRLINE};
	
	assign SPR_TILE_AA[2] = AUTOANIM3_EN ? AA_COUNT[2] : SPR_TILE[2];
	assign SPR_TILE_AA[1] = AUTOANIM2_EN ? AA_COUNT[1] : SPR_TILE[1];
	assign SPR_TILE_AA[0] = AUTOANIM2_EN ? AA_COUNT[0] : SPR_TILE[0];
	
	assign P_MUX_X_YSH = R88_nQ ? XPOS[8:1] : YSHRINK;		// Might be swapped
	assign P_MUX_SPRLINE = SPR_CONTINUOUS ? SPR_TILE_A : SPR_TILE_AB;		// Might be swapped
	
	assign U51A_OUT = U53_Q & T53_Q;
	FDM U53(CLK_24M, T53_Q, U53_Q, );
	FDM T53(LSPC_12M, T56A_OUT, T53_Q, );
	
	
	// Y coordinate stuff
	
	// O268 O237
	assign SPR_Y_LOOKAHEAD = {RASTERC[7:1], FLIP} + 1'b1;
	// P261 P237
	assign SPR_Y_ADD = SPR_Y_LOOKAHEAD + SPR_Y[7:0];
	// R216 R218 R238 R241
	// R281 R283 Q289 Q291
	assign SPR_TILE_A = SPR_Y_ADD ^ {8{!P235_OUT}};
	assign P235_OUT = ~(SPR_Y[8] ^ SPR_Y_ADD[8]);
	// Q237 R189
	assign SPR_Y_SHRINK = SPR_TILE_A + YSHRINK;
	// Q265 R151
	assign SPR_TILE_AB = SPR_TILE_A + {YSHRINK[6:0], 1'b0};
	
	// R222A
	assign SPR_CONTINUOUS = &{SPR_SIZE[0], SPR_SIZE[5], SPR_Y_SHRINK[8]};
	
	assign D208B_OUT = ~P201_Q[3];
	
	/*lspc_regs REGS(RESET, CLK_24M, M68K_ADDR, M68K_DATA, nLSPOE, nLSPWE, PCK1, AA_COUNT, V_COUNT[7:0],
					VIDEO_MODE, REG_LSPCMODE,
					CPU_VRAM_ZONE, CPU_WRITE_REQ, CPU_VRAM_ADDR, CPU_VRAM_WRITE_BUFFER,
					RELOAD_REQ_SLOW, RELOAD_REQ_FAST,
					TIMER_LOAD, TIMER_PAL_STOP, REG_VRAMMOD, TIMER_MODE, TIMER_IRQ_EN,
					AA_SPEED, AA_DISABLE,
					IRQ_S1, IRQ_R1, IRQ_S2, IRQ_R2, IRQ_R3);*/
	
	lspc_timer TIMER(LSPC_6M, M68K_DATA, WR_TIMER_HIGH, WR_TIMER_LOW, VMODE, TIMER_MODE, TIMER_STOP, RASTERC,
							TIMER_IRQ_EN, D46A_OUT);
	
	resetp RSTP(CLK_24MB, RESET, RESETP);
	
	irq IRQ(WR_IRQ_ACK, M68K_DATA[2:0], RESET, D46A_OUT, BNK, LSPC_6M, IPL0, IPL1);
	
	videosync VS(CLK_24MB, LSPC_1_5M, Q53_CO, RESETP, VMODE, PIXELC, RASTERC, SYNC, BNK, BNKB, CHBL,
						R15_QD, FLIP, nFLIP, P50_CO);

	lspc2_clk LSPCCLK(CLK_24M, RESETP, CLK_24MB, LSPC_12M, LSPC_8M, LSPC_6M, LSPC_4M, LSPC_3M, LSPC_1_5M,
							Q53_CO);
	
	slow_cycle SCY(CLK_24M, CLK_24MB, LSPC_12M, LSPC_6M, LSPC_3M, RESETP, VRAM_ADDR[14:0], VRAM_WRITE,
							RASTERC[7:3], PIXEL_HPLUS, ACTIVE_RD,
							SPR_TILEMAP, SPR_TILE_VFLIP, SPR_TILE_HFLIP, SPR_AA_3, SPR_AA_2, FIX_TILE,
							FIX_PAL, SPR_TILE, SPR_PAL, VRAM_LOW_READ, nCPU_WR_LOW, R91_nQ, CLK_CPU_READ_LOW,
							T160A_OUT, T160B_OUT, CLK_ACTIVE_RD, ACTIVE_RD_PRE8, Q174B_OUT, D208B_OUT, SPRITEMAP_ADDR_MSB);
	
	fast_cycle FCY(CLK_24M, LSPC_12M, LSPC_6M, LSPC_3M, LSPC_1_5M, RESETP, nVRAM_WRITE_REQ,
							VRAM_ADDR, VRAM_WRITE, VRAM_ADDR_RAW, FLIP, nFLIP,
							PIXELC, RASTERC, P50_CO, nCPU_WR_HIGH, HSHRINK, PIPE_C, VRAM_HIGH_READ,
							ACTIVE_RD, R91_Q, R91_nQ, T140_Q, T58A_OUT, T73A_OUT, U129A_Q, T125A_OUT,
							CLK_ACTIVE_RD, ACTIVE_RD_PRE8);
	
	//p_cycle PCY(RESET, CLK_24M, PBUS_S_ADDR, FIX_ATTR_PAL, PBUS_C_ADDR, SPR_TILE_PAL, XPOS,
	//				L0_ROM_ADDR, nVCS, L0_ROM_DATA, {PBUS_IO, PBUS_OUT});
	
	autoanim AA(RASTERC[8], RESETP, AA_SPEED, AA_COUNT);
	
	hshrink HSH(HSHRINK, U68A_Q, ~R56B_OUT, HSHRINK_OUT_A, HSHRINK_OUT_B);
	assign nHSHRINK_OUT_A = ~HSHRINK_OUT_A;
	assign nHSHRINK_OUT_B = ~HSHRINK_OUT_B;
	
endmodule
