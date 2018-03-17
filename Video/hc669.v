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

`timescale 1ns / 1ns

module hc669_dual(
	input CLK,
	input nLOAD,
	input UP,
	input [7:0] LOAD_DATA,
	output reg [7:0] CNT_REG
	);
	
	// Enable inputs are more complex, but chip is used in a simple way

	//assign CARRY = UP ? ~&{CNT_REG} : |{CNT_REG};
	
	always @(posedge CLK)
	begin
		if (!nLOAD)
			CNT_REG <= LOAD_DATA;
		else
		begin
			// Datasheet says UP is +1, opposite in Proteus model...
			//if (UP)
				CNT_REG <= CNT_REG + 1'b1;
			//else
			//	CNT_REG <= CNT_REG - 1'b1;
		end
	end

endmodule
