`timescale 10ns/10ns

module videout(
	input CLK_6MB,
	input nBNKB,
	input SHADOW,
	input [15:0] PC,
	output reg VIDEO_R,
	output reg VIDEO_G,
	output reg VIDEO_B
);

	// Color data latch/blanking
	always @(posedge CLK_6MB)
	begin
		VIDEO_R <= nBNKB ? {SHADOW, PC[11:8], PC[14], PC[15]} : 7'b0000000;
		VIDEO_G <= nBNKB ? {SHADOW, PC[7:4], PC[13], PC[15]} : 7'b0000000;
		VIDEO_B <= nBNKB ? {SHADOW, PC[3:0], PC[12], PC[15]} : 7'b0000000;
	end
	
endmodule
