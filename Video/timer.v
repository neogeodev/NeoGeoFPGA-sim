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

module lspc_timer(
	input LSPC_6M,
	input [15:0] M68K_DATA,
	input WR_TIMER_HIGH,
	input WR_TIMER_LOW,
	input VMODE,
	input [2:0] TIMER_MODE,
	input TIMER_STOP,
	input [8:0] RASTERC,
	input TIMER_IRQ_EN,
	output D46A_OUT
);
	
	wire [15:0] REG_TIMERHIGH;
	wire [15:0] REG_TIMERLOW;
	
	/*FDSCell K58(WR_TIMER_HIGH, M68K_DATA[3:0], K58_Q);
	FDSCell K48(WR_TIMER_HIGH, M68K_DATA[7:4], K48_Q);
	FDSCell G50(WR_TIMER_HIGH, M68K_DATA[11:8], G50_Q);
	FDSCell K31(WR_TIMER_HIGH, M68K_DATA[15:12], K31_Q);*/
	
	// K31 G50 K48 K58
	FDS16bit(WR_TIMER_HIGH, M68K_DATA, REG_TIMERHIGH);
	
	C43 N50(~LSPC_6M, ~REG_TIMERHIGH[3:0], E49A_OUT, L106A_OUT, L76_OUT, ~N90B_OUT, , N50_CO);
	C43 M18(~LSPC_6M, ~REG_TIMERHIGH[7:4], E49A_OUT, L106A_OUT, N50_CO, ~N90B_OUT, , M18_CO);
	
	// Used for test mode
	assign K29_OUT = M18_CO ^ 1'b0;
	
	C43 L51(~LSPC_6M, ~REG_TIMERHIGH[11:8], E49A_OUT, L106A_OUT, K29_OUT, ~N90B_OUT, , L51_CO);
	C43 L16(~LSPC_6M, ~REG_TIMERHIGH[15:12], E49A_OUT, L106A_OUT, L51_CO, ~N90B_OUT, , TIMER_CO);
	
	
	/*FDSCell K121(WR_TIMER_LOW, M68K_DATA[3:0], K121_Q);
	FDSCell K87(WR_TIMER_LOW, M68K_DATA[7:4], K87_Q);
	FDSCell K68(WR_TIMER_LOW, M68K_DATA[11:8], K68_Q);
	FDSCell K104(WR_TIMER_LOW, M68K_DATA[15:12], K104_Q);*/
	
	// K104 K68 K87 K121
	FDS16bit(WR_TIMER_LOW, M68K_DATA, REG_TIMERLOW);
	
	C43 L127(~LSPC_6M, ~REG_TIMERLOW[3:0], E49A_OUT, J69_nQ, J69_nQ, ~N90B_OUT, , L127_CO);
	C43 M125(~LSPC_6M, ~REG_TIMERLOW[7:4], E49A_OUT, L127_CO, J69_nQ, ~N90B_OUT, , M125_CO);
	
	// Used for test mode
	assign M52_OUT = M125_CO ^ 1'b0;
	
	C43 M54(~LSPC_6M, ~REG_TIMERLOW[11:8], E49A_OUT, L107A_OUT, M52_OUT, ~N90B_OUT, , M54_CO);
	C43 L81(~LSPC_6M, ~REG_TIMERLOW[15:12], E49A_OUT, L107A_OUT, M54_CO, ~N90B_OUT, , L81_CO);
	
	// Used for test mode
	assign L76_OUT = L81_CO ^ 1'b0;
	
	
	// Reload logic
	
	assign E49A_OUT = ~|{E40A_OUT, E51_OUT, E57A_OUT};
	assign E40A_OUT = ~|{E32_nQ, ~TIMER_MODE[0], E20_nQ};
	assign E57A_OUT = TIMER_MODE[2] & K22A_OUT;
	assign K22A_OUT = L127_CO & TIMER_CO;
	assign E51_OUT = ~|{~TIMER_MODE[1], E46_nQ, E36_Q};
	FDPCell E36(~LSPC_6M, E16_Q, O82B_OUT, 1'b1, E36_Q, );
	FDPCell E32(~LSPC_6M, E20_Q, 1'b1, O82B_OUT, , E32_nQ);
	FDPCell E20(~LSPC_6M, E10_Q, 1'b1, E20_Q, E20_nQ);
	FDPCell E10(WR_TIMER_LOW, 1'b0, E14A_OUT, 1'b1, E10_Q, );
	FDPCell E16(LSPC_6M, K18_Q, RESETP, 1'b1, E16_Q, );
	FDPCell K18(R74_nQ, BNKB, RESETP, 1'b1, K18_Q, );
	assign E14A_OUT = ~&{E20_nQ, E32_nQ};
	FDM E46_Q(~LSPC_6M, E36_Q, , E46_nQ);
	
	// Stop option
	
	assign J257A_OUT = ~|{RASTERC[5:4]};
	assign I234_OUT = |{RASTERC[8], ~VMODE, TIMER_STOP};
	assign J238B_OUT = ~|{J257A_OUT, I234_OUT};
	FDM J69(LSPC_6M, J238B_OUT, , J69_nQ);
	
	
	// IRQ generation
	
	assign D46A_OUT = ~|{~TIMER_IRQ_EN, E43_nQ};
	FDM E43(~LSPC_6M, K22A_OUT, , E43_nQ);

endmodule
