`timescale 10ns/10ns

// 100ns 8bit ROM

module rom_s1(
	input [16:0] ADDR,
	output [7:0] OUT
);

	reg [7:0] ROMDATA[0:131071];

	initial begin
		$readmemh("rom_s1.txt", ROMDATA);
	end

	assign #10 OUT = ROMDATA[ADDR];

endmodule
