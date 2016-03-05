`timescale 10ns/10ns

// 100ns 512k*8bit ROM

module rom_v1(
	input [18:0] ADDR,
	output [7:0] OUT
);

	reg [7:0] ROMDATA[0:524287];

	/* initial begin
		$readmemh("rom_v1.txt", ROMDATA);
	end */

	assign #10 OUT = ROMDATA[ADDR];

endmodule
