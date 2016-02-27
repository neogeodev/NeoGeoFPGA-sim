`timescale 10ns/10ns

// 100ns 128k*8bit ROM

module rom_sfix(
	input [16:0] ADDR,
	output [7:0] OUT
);

	reg [7:0] ROMDATA[0:131071];

	initial begin
		$readmemh("rom_sfix.txt", ROMDATA);
	end

	assign #10 OUT = ROMDATA[ADDR];

endmodule
