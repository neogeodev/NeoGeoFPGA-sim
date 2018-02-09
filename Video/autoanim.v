`timescale 1ns/1ns

module autoanim(
	input CLK,
	input RESETP,
	input [7:0] AA_SPEED,
	output [2:0] AA_COUNT
);

	wire [3:0] D151_Q;

	// Used for test mode
	assign E95A_OUT = ~|{E117_CO, 1'b0};
	assign E149_OUT = ~^{CLK, 1'b0};
	
	C43 B91(E149_OUT, ~AA_SPEED[3:0], E95A_OUT, 1'b1, 1'b1, 1'b1, , B91_CO);
	C43 E117(E149_OUT, ~AA_SPEED[7:4], E95A_OUT, 1'b1, B91_CO, 1'b1, , E117_CO);
	
	C43 D151(E149_OUT, 4'b0000, 1'b1, 1'b1, E117_CO, RESETP, D151_Q, );
	
	assign AA_COUNT = D151_Q[2:0];

endmodule
