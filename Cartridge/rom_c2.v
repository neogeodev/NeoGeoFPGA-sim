`timescale 10ns/10ns

// 250ns 16bit ROM

module rom_c2(
	input [17:0] ADDR,
	output [15:0] OUT
);

	reg [15:0] ROMDATA[0:262143];

	initial begin
		$readmemh("rom_c2.txt", ROMDATA);
	end

	assign #25 OUT = ROMDATA[ADDR];

endmodule
