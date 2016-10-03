`timescale 1ns/1ns

module ssg_ch(
	input PHI_S,
	input [11:0] FREQ,
	output reg OSC_OUT
	);
	
	reg [11:0] CNT;
	
	always @(posedge PHI_S)		// ?
	begin
		if (CNT)
			CNT <= CNT - 1'b1;
		else
		begin
			CNT <= FREQ;
			OSC_OUT <= ~OSC_OUT;
		end
	end
	
endmodule
