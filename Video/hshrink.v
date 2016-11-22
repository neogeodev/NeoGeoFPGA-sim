`timescale 1ns/1ns

module hshrink(
	input [3:0] SHRINK,	// Shrink value
	input [3:0] N,			// Pixel number
	output USE
);

	// Thanks MAME :)
	
	reg [15:0] BITMAP;
	
	always@(*)
	begin
		case (SHRINK)
			4'h0: BITMAP <= 16'b0000000010000000;
			4'h1: BITMAP <= 16'b0000100010000000;
			4'h2: BITMAP <= 16'b0000100010001000;
			4'h3: BITMAP <= 16'b0010100010001000;
			4'h4: BITMAP <= 16'b0010100010001010;
			4'h5: BITMAP <= 16'b0010101010001010;
			4'h6: BITMAP <= 16'b0010101010101010;
			4'h7: BITMAP <= 16'b1010101010101010;
			4'h8: BITMAP <= 16'b1010101011101010;
			4'h9: BITMAP <= 16'b1011101011101010;
			4'hA: BITMAP <= 16'b1011101011101011;
			4'hB: BITMAP <= 16'b1011101111101011;
			4'hC: BITMAP <= 16'b1011101111101111;
			4'hD: BITMAP <= 16'b1111101111101111;
			4'hE: BITMAP <= 16'b1111101111111111;
			4'hF: BITMAP <= 16'b1111111111111111;
		endcase
	end
	
	assign USE = BITMAP[N];

endmodule
