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

module cpu_68k(
	input CLK_68KCLK,
	input nRESET,
	input IPL1, IPL0,
	input nDTACK,
	output [23:1] M68K_ADDR,
	inout [15:0] M68K_DATA,
	output nLDS, nUDS,
	output nAS,
	output M68K_RW
);

wire [15:0] M68K_DATA_BYTE_MASK;
wire [15:0] TG68K_DATAIN;
wire [15:0] TG68K_DATAOUT;
wire [31:0] TG68K_ADDR;
wire [23:0] DEBUG_ADDR;							// TODO: Remove
wire [15:0] REG_D6;								// TODO: Remove

assign M68K_DATA_BYTE_MASK = (~|{nLDS, nUDS}) ? M68K_DATA :
										(~nLDS) ? {8'h00, M68K_DATA[7:0]} :
										(~nUDS) ? {M68K_DATA[15:8], 8'h00} :
										16'bzzzzzzzzzzzzzzzz;

assign M68K_DATA = M68K_RW ? 16'bzzzzzzzzzzzzzzzz : TG68K_DATAOUT;
assign TG68K_DATAIN = M68K_RW ? M68K_DATA_BYTE_MASK : 16'bzzzzzzzzzzzzzzzz;

assign M68K_ADDR = TG68K_ADDR[23:1];

assign DEBUG_ADDR = {M68K_ADDR, 1'b0};		// TODO: Remove
always @(DEBUG_ADDR)								// TODO: Remove
begin
	if (DEBUG_ADDR == 24'hC18F74)
	begin
		$display("Going to BIOS menu !");
		$stop;
	end
	
	if (DEBUG_ADDR == 24'hC11002) $display("Reset procedure !");
	if (DEBUG_ADDR == 24'hC11046) $display("Clearing WRAM...");
	if (DEBUG_ADDR == 24'hC11080) $display("Clearing Palettes...");
	if (DEBUG_ADDR == 24'hC11B04) $display("WRAM check passed");
	if (DEBUG_ADDR == 24'hC11B16) $display("BRAM check passed");
	if (DEBUG_ADDR == 24'hC11B2C) $display("PAL BANK 1 check passed");
	if (DEBUG_ADDR == 24'hC11B3E) $display("PAL BANK 0 check passed");
	if (DEBUG_ADDR == 24'hC11B5C) $display("VRAM LOW check passed");
	if (DEBUG_ADDR == 24'hC11B6A) $display("VRAM FAST check passed");
	if (DEBUG_ADDR == 24'hC11BD6) $display("Testing RTC...");
	if (DEBUG_ADDR == 24'hC11C66) $display("BIOS CRC check passed");
	if (DEBUG_ADDR == 24'hC11F76) $display("Cart detected OK");
	if (DEBUG_ADDR == 24'hC125E6) $display("Formatting BRAM...");
	if (DEBUG_ADDR == 24'hC1835E) $display("Call: FIX_CLEAR");
	if (DEBUG_ADDR == 24'hC1839A) $display("Call: LSP_1ST");
	/*if (DEBUG_ADDR == 24'hC1806C)
	begin
		$display("Eye-catch going to step 2 !");
		$stop;
	end
	if (DEBUG_ADDR == 24'hC1807A)
	begin
		$display("Eye-catch going to step 3 !");
		$stop;
	end
	if (DEBUG_ADDR == 24'hC180BA)
	begin
		$display("Eye-catch going to step 4 !");
		$stop;
	end
	if (DEBUG_ADDR == 24'hC18112)
	begin
		$display("Eye-catch going to step 5 !");
		$stop;
	end*/
	//if (DEBUG_ADDR == 24'hC11BEA) $stop;
end

tg68 TG68K(
		.clk(CLK_68KCLK),
		.reset(nRESET),
		.clkena_in(1'b1),
		.data_in(TG68K_DATAIN),
		.IPL({1'b1, IPL1, IPL0}),
		.dtack(nDTACK),
		.addr(TG68K_ADDR),
		.data_out(TG68K_DATAOUT),
		.as(nAS),
		.uds(nUDS),
		.lds(nLDS),
		.rw(M68K_RW),
		.REG_D6(REG_D6)
		);
	
endmodule
