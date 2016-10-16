`timescale 1ns / 1ns

module hc669(
	input CLK,
	input nENABLE,
	input nLOAD,
	input UP,
	input [3:0] LOAD_DATA,
	output reg [3:0] CNT_REG,
	output CARRY
	);
	
	// Enable inputs are more complex, but chip is used in a simple way

	assign CARRY = UP ? ~&{CNT_REG} : |{CNT_REG};
	always @(posedge CLK)
	begin
		if (!nLOAD)
			CNT_REG <= LOAD_DATA;
		else
		begin
			if (!nENABLE)
			begin
				// Datasheet says UP is 1, opposite in Proteus model...
				if (UP)
					CNT_REG <= CNT_REG + 1'b1;
				else
					CNT_REG <= CNT_REG - 1'b1;
			end
		end
	end

endmodule
