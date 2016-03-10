`timescale 1ns/1ns

module hshrink(
	input [3:0] SHRINK,
	input [3:0] N,
	output USE
);

	// Thanks MAME and Logic Friday :)
	// Is this really a LUT in LSPC ?
	
	assign USE = 	(SHRINK == 15) ? &{N[2:0]} | N[3] :
						(SHRINK == 14) ? &{N[3:1]} | &{N[3:2], N[0]} :
						(SHRINK == 13) ? &{N[1:0]} | |{N[3:2]} :
						(SHRINK == 12) ? N[3] & |{N[2:0]} :
						(SHRINK == 11) ? |{N[3:0]} :
						(SHRINK == 10) ? &{N[3:0]} :
						(SHRINK == 9) ? (N[2] & |{N[1:0]}) | N[3] :
						(SHRINK == 8) ? N[3] & (&{N[1:0]} | N[2]) :
						(SHRINK == 7) ? 1'b1 :
						(SHRINK == 6) ? N[3] :
						(SHRINK == 5) ? &{N[2:1]} | N[3] :
						(SHRINK == 4) ? &{N[3:1]} :
						(SHRINK == 3) ? |{N[3:1]} :
						(SHRINK == 2) ? &{N[3:2]} :
						(SHRINK == 1) ? |{N[3:2]} :
						N[3] & |{N[2:1]};

endmodule
