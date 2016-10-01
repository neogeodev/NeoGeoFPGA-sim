`timescale 1ns/1ns

module syslatch(
	input [4:1] M68K_ADDR,
	input nBITW1,
	input nRESET,
	output SHADOW, nVEC, nCARDWEN, CARDWENB, nREGEN, nSYSTEM, nSRAMWEN, PALBNK
);

	reg [7:0] SLATCH;
	
	assign SHADOW = SLATCH[0];
	assign nVEC = SLATCH[1];
	assign nCARDWEN = SLATCH[2];
	assign CARDWENB = SLATCH[3];
	assign nREGEN = SLATCH[4];
	assign nSYSTEM = SLATCH[5];
	assign nSRAMWEN = ~SLATCH[6];		// See MVS schematics page 3
	assign PALBNK = SLATCH[7];
	
	// System latch
	always @(M68K_ADDR[4:1] or nBITW1 or nRESET)
	begin
		if (!nRESET)
		begin
			if (nBITW1)
				SLATCH <= 8'b0;	// Clear
			else
			begin						// Demux mode
				case (M68K_ADDR[3:1])
					0: SLATCH <= {7'b0000000, M68K_ADDR[4]};
					1: SLATCH <= {6'b000000, M68K_ADDR[4], 1'b0};
					2: SLATCH <= {5'b00000, M68K_ADDR[4], 2'b00};
					3: SLATCH <= {4'b0000, M68K_ADDR[4], 3'b000};
					4: SLATCH <= {3'b000, M68K_ADDR[4], 4'b0000};
					5: SLATCH <= {2'b00, M68K_ADDR[4], 5'b00000};
					6: SLATCH <= {1'b0, M68K_ADDR[4], 6'b000000};
					7: SLATCH <= {M68K_ADDR[4], 7'b0000000};
				endcase
			end
		end
		else if (!nBITW1)
		begin							// Latch mode
			$display("Wrote %B to syslatch %d", M68K_ADDR[4], M68K_ADDR[3:1]);	// DEBUG
			SLATCH[M68K_ADDR[3:1]] <= M68K_ADDR[4];
		end
	end
	
endmodule
