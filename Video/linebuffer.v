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

module linebuffer(
	input [7:0] ADDR,
	input [11:0] DATA_IN,
	output [11:0] DATA_OUT,
	input RE,
	input WE
);

	reg [11:0] LB_RAM[0:255];	// TODO: Add a check, should never go over 191

	// Read
	assign #10 DATA_OUT = RE ? LB_RAM[ADDR] : 12'bzzzzzzzzzzzz;

	// Write
	always @(*)
		if (WE)
			LB_RAM[ADDR] <= DATA_IN;	// #10

endmodule
