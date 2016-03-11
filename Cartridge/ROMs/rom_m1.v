`timescale 10ns/10ns

// 100ns 128k*8bit ROM

module rom_m1(
	input [16:0] ADDR,
	output [7:0] OUT,
	input nOE
);

	reg [7:0] ROMDATA[0:131071];

	initial begin
		$readmemh("rom_m1.txt", ROMDATA);
	end

	assign #10 OUT = nOE ? 8'bzzzzzzzz : ROMDATA[ADDR];

endmodule
