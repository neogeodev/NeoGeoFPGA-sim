`timescale 1ns/1ns

module fast_cycle(
	input CLK_24M,
	input LSPC_12M,
	input LSPC_1_5M,
	input RESETP,
	input VRAM_WRITE_REQ,
	input [15:0] VRAM_ADDR,
	input [15:0] VRAM_WRITE,
	input [15:0] VRAM_ADDR_RAW,	// Only bit 15 is needed ?
	input H287_Q,
	input H287_nQ,
	input [8:0] PIXELC,
	input [8:0] RASTERC,
	input P50_CO,
	output N93_Q,
	output K260B_OUT,
	output [3:0] HSHRINK,
	output [15:0] PIPE_C,
	output [15:0] VRAM_HIGH_READ,
	output [7:0] ACTIVE_RD,
	output R91_nQ
);

	wire [10:0] C;
	wire [15:0] F;
	wire [8:0] PARSE_Y;
	wire [5:0] PARSE_SIZE;
	wire [15:0] F_OUT_MUX;
	wire [3:0] J102_Q;
	wire [3:0] E175_Q;
	wire [8:0] SPR_Y;
	wire [7:0] ACTIVE_RD_PRE;
	wire [7:0] YSHRINK;
	wire [3:0] J127_Q;
	wire [8:0] ACTIVE_WR_D;
	wire [3:0] T102_Q;
	wire [7:0] PARSE_LOOKAHEAD;
	wire [8:0] PARSE_ADD_Y;
	wire [5:0] PARSE_ADD_SIZE;
	wire [3:0] I189_Q;
	wire [3:0] J151_Q;
	wire [3:0] I151_Q;
	wire [3:0] N98_Q;
	wire [15:0] PIPE_A;
	wire [15:0] PIPE_B;
	wire [3:0] O141_Q;
	wire [3:0] G152_Q;
	wire [3:0] J87_Q;
	wire [3:0] H198_Q;
	
	// CPU read
	// L251 L269 L233 K249
	FDS16bit L251(~CLK_CPU_READ_HIGH, F, VRAM_HIGH_READ);

	// Y-parsing read
	// N214 M214 M178 L190
	FDS16bit N214(O109A_OUT, F, {PARSE_Y, PARSE_CHAIN, PARSE_SIZE});

	// Y Rendering read
	FDSCell M250(N98_QD, F[15:12], SPR_Y[8:5]);
	FDSCell M269(N98_QD, F[11:8], SPR_Y[4:1]);
	FDSCell M233(N98_QD, {F[7:5], F[0]}, {SPR_Y[0], SPR_CHAIN, SPR_SIZE5, SPR_SIZE0});

	// Active list read
	FDSCell J117(H125A_OUT, F[7:4], ACTIVE_RD_PRE[7:4]);
	FDSCell J178(H125A_OUT, F[3:0], ACTIVE_RD_PRE[3:0]);
	// Next step
	FDSCell I32(H124B_OUT, ACTIVE_RD_PRE[7:4], ACTIVE_RD[7:4]);
	FDSCell H165(H124B_OUT, ACTIVE_RD_PRE[3:0], ACTIVE_RD[3:0]);
	
	// Shrink read
	FDSCell O141(K142A_OUT, F[11:8], O141_Q);
	FDSCell O123(K142A_OUT, F[7:4], YSHRINK[7:4]);
	FDSCell K178(K142A_OUT, F[3:0], YSHRINK[3:0]);
	
	// Data output
	// O171B O171A O173B O173A
	// B178B B173B B171B C180B
	// C146B C144B C142B C149B
	// E207B E207A E209B E209A
	assign F_OUT_MUX = CLK_CPU_READ_HIGH ? VRAM_WRITE : {7'b0000000, J194_Q, J102_Q, E175_Q};	// Might be swapped 
	
	FDRCell E175(O109A_OUT, G152_Q, Q110A_OUT, E175_Q);
	FDRCell J102(O109A_OUT, J87_Q, Q110A_OUT, J102_Q);
	
	FDSCell G152(O105B_OUT, ACTIVE_WR_D[3:0], G152_Q);
	FDSCell J87(O105B_OUT, ACTIVE_WR_D[7:4], J87_Q);
	
	FDPCell J194(O112B_OUT, J231_Q, 1'b1, Q110A_OUT, J194_Q, );
	FDM J231(O105B_OUT, ACTIVE_WR_D[8], J231_Q, );
	
	assign F = CWE ? F_OUT_MUX : 16'bzzzzzzzzzzzzzzzz;
	
	// CWE output
	assign CWE = ~R145A_OUT;
	assign R145A_OUT = O107A_OUT | T146A_OUT;
	assign O107A_OUT = O103A_OUT & N93_Q;
	assign T146A_OUT = ~|{T129A_nQ, T148_Q};
	assign O103A_OUT = ~&{R103_Q, O98_Q};
	FDPCell O98(T125A_OUT, M95B_1, 1'b1, RESETP, O98_Q, O98_nQ);
	FDPCell N93(O98_nQ, F58A_OUT, O98_Q, 1'b1, N93_Q, );
	assign F58A_OUT = ~VRAM_ADDR_RAW[15] | VRAM_WRITE_REQ;
	FDM I148(H125A_OUT, F[8], I148_Q, );
	FDPCell R103(O109A_OUT, T95A_OUT, R107A_OUT, S109A_OUT, R103_Q, );
	assign T95A_OUT = T162B_OUT & T102_Q[0];
	assign R107A_OUT = R109_Q | S111_nQ;
	assign S109A_OUT = S111_Q & S107A_OUT;
	FDPCell R109(O109A_OUT, R113A_OUT, S107A_OUT, 1'b1, R109_Q, );
	FDPCell S111(O109A_OUT, S109B_OUT, S107A_OUT, 1'b1, S111_Q, S111_nQ);
	assign R113A_OUT = I145_OUT & R109_Q;
	assign I145_OUT = &{ACTIVE_WR_D[6:1], ACTIVE_WR_D[8]};
	assign S109B_OUT = S111_Q & J100B_OUT;
	FD2 T129A(CLK_24M, T126B_OUT, , T129A_nQ);
	FDM T148(CLK_24M, T128B_OUT, T148_Q, );
	assign T162B_OUT = PARSE_CHAIN ? T90A_OUT : M176A_OUT;
	assign M176A_OUT = PARSE_MATCH | PARSE_SIZE[5];
	FDRCell T102(O109A_OUT, {1'b0, T102_Q[1], T102_Q[0], O103A_OUT}, S107A_OUT, T102_Q);
	assign T90A_OUT = ~&{T94_OUT, T92_OUT};
	assign T94_OUT = ~&{T102_Q[1:0], O102B_OUT};
	assign T92_OUT = ~&{T102_Q[2], ~T102_Q[1], T102_Q[0], O103A_OUT};
	assign J100B_OUT = ~|{I189_Q[2:1]};
	C43 I189(O110B_OUT, 4'b0000, 1'b1, 1'b1, H222A_OUT, ~H198_CO, I189_Q, );
	C43 H198(O110B_OUT, 4'b0000, 1'b1, 1'b1, 1'b1, ~H198_CO, H198_Q, H198_CO);
	
	FS3 N98(T125A_OUT, 4'b0000, R91_nQ, RESETP, N98_Q);
	
	FDM R91(LSPC_12M, LSPC_1_5M, R91_Q, R91_nQ);
	
	// Address mux
	// I213 I218 G169A G164 G182A G194A G200 G205A I175A I182A
	// J62 J72A I104 I109A J205A J200 J49 J54A H28A H34 I13 I18A
	assign A_TOP = {N98_QD, J36_OUT, I148_Q, ACTIVE_RD_PRE};
	assign B_TOP = {3'b110, H293B_OUT, J151_Q[2:0], I151_Q};
	assign C_TOP = {3'b110, H293B_OUT, J151_Q[2:0], I151_Q};
	assign D_TOP = {N98_QD, J36_OUT, I148_Q, ACTIVE_RD_PRE};
	
	assign A_BOT = {3'b110, I237A_OUT, I189_Q[2:0], H198_Q};
	assign B_BOT = VRAM_ADDR;
	assign C_BOT = VRAM_ADDR;
	assign D_BOT = {2'b01, ACTIVE_WR_D};
	
	assign I237A_OUT = ~H287_nQ;
	assign K260B_OUT = ~H287_nQ;
	assign J36_OUT = N98_Q[0] ^ N98_Q[3];
	assign H293B_OUT = ~H287_Q;
	assign O55B_OUT = ~PIXELC[6];
	assign P39A_OUT = ~PIXELC[7];
	
	C43 J151(~K131B_OUT, 4'b0000, O55A_OUT, 1'b1, J176A_OUT, 1'b1, J151_Q, );
	C43 I151(~K131B_OUT, 4'b0000, O55A_OUT, 1'b1, 1'b1, 1'b1, I151_Q, I151_CO);
	assign O55A_OUT = ~&{O55B_OUT, P50_CO, P39A_OUT};
	
	// Used for test mode
	assign J176A_OUT = I151_Q | 1'b0;
	
	
	// Active list stuff
	C43 H127(O105B_OUT, 4'b0000, 1'b1, 1'b1, 1'b1, S107A_OUT, ACTIVE_WR_D[3:0]);
	C43 I121(O105B_OUT, 4'b0000, 1'b1, H125B_OUT, 1'b1, S107A_OUT, ACTIVE_WR_D[7:4], I121_CO);
	C43 J127(O105B_OUT, 4'b0000, 1'b1, H125B_OUT, I121_CO, S107A_OUT, J127_Q);
	assign ACTIVE_WR_D[8] = J127_Q[0];
	
	assign O105B_OUT = O102B_OUT | O109A_OUT;
	assign O102B_OUT = R103_Q & O98_Q;
	assign O109A_OUT = T125A_OUT | O98_Q;
	
	
	// Y parse matching
	// L200 O200
	assign PARSE_LOOKAHEAD = 5'd2 + {RASTERC[7:1], K260B_OUT};
	// M190 N190
	assign PARSE_ADD_Y = PARSE_LOOKAHEAD + PARSE_Y[7:0];
	assign N186_OUT = ~^{PARSE_ADD_Y[8], PARSE_Y};
	// K195 M151
	assign PARSE_ADD_SIZE = {N186_OUT, ~PARSE_ADD_Y[7:4]} + PARSE_SIZE[4:0];
	assign PARSE_MATCH = PARSE_ADD_SIZE[5];
	
	
	// Pipe for x position and h-shrink
	// O159 P131 O87 N131
	FDS16bit O159(M95B_1, {2'b00, SPR_CHAIN, O141_Q, F[15:7]}, PIPE_A);
	// P165 P121 P87 N121
	FDS16bit P165(M95B_1, PIPE_A, PIPE_B);
	// P155 P141 P104 N141
	FDS16bit P155(M95B_1, PIPE_B, PIPE_C);
	
	assign HSHRINK = PIPE_C[12:9];
	
	vram_fast_u VRAMUU(C, F[15:8], 1'b0, 1'b0, nCWE);
	vram_fast_l VRAMUL(C, F[7:0], 1'b0, 1'b0, nCWE);

endmodule
