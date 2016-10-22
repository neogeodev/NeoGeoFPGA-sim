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
			// Datasheet says UP is 1, opposite in Proteus model...
			if (UP)
				CNT_REG <= CNT_REG + 1'b1;
			else
				CNT_REG <= CNT_REG - 1'b1;
		end
	end

endmodule
