`timescale 1ns/1ns

module ym2610(
	input PHI_S,
	
	inout [7:0] SDD,
	input [1:0] SDA,
	output nIRQ,
	input nCS,
	input nWR,
	input nRD,
	
	inout [7:0] SDRAD,
	output [9:8] SDRA_L,
	output [23:20] SDRA_U,
	output SDRMPX, nSDROE,
	
	inout [7:0] SDPAD,
	output [11:8] SDPA,
	output SDPMPX, nSDPOE,
	
	output [5:0] ANA,					// How many levels ?
	
	output SH1, SH2, OP0, PHI_M	// YM3016 stuff
);

	// Timer
	reg [9:0] YMTIMER_TA_LOAD;
	reg [7:0] YMTIMER_TB_LOAD;
	reg [7:0] YMTIMER_CONFIG;

	// SSG
	reg [11:0] SSG_FREQ_A;
	reg [11:0] SSG_FREQ_B;
	reg [11:0] SSG_FREQ_C;
	reg [4:0] SSG_NOISE;
	reg [5:0] SSG_EN;
	reg [4:0] SSG_VOL_A;
	reg [4:0] SSG_VOL_B;
	reg [4:0] SSG_VOL_C;
	reg [15:0] SSG_ENV_FREQ;
	reg [3:0] SSG_ENV;
	
	// FM
	reg [3:0] FM_LFO;
	reg [7:0] FM_KEYON;
	reg [6:0] FM_DTMUL[3:0];
	reg [6:0] FM_TL[3:0];
	reg [7:0] FM_KSAR[3:0];
	reg [7:0] FM_AMDR[3:0];
	reg [4:0] FM_SR[3:0];
	reg [7:0] FM_SLRR[3:0];
	reg [3:0] FM_SSGEG[3:0];
	reg [13:0] FM_FNUM13;
	reg [13:0] FM_FNUM24;
	reg [13:0] FM_2FNUM13;
	reg [13:0] FM_2FNUM24;
	reg [5:0] FM_FBALGO13;
	reg [5:0] FM_FBALGO24;
	reg [7:0] FM_PAN13;
	reg [7:0] FM_PAN24;
	
	// ADPCM-A
	reg [7:0] PCMA_KEYON;
	reg [5:0] PCMA_MVOL;
	reg [7:0] PCMA_VOLPAN[5:0];
	reg [15:0] PCMA_START[5:0];
	reg [15:0] PCMA_STOP[5:0];
	
	// ADPCM-B
	reg [7:0] PCMB_TRIG;
	reg [7:6] PCMB_PAN;
	reg [15:0] PCMB_START;
	reg [15:0] PCMB_STOP;
	reg [15:0] PCMB_DELTA;
	reg [7:0] PCMB_VOL;
	reg [7:0] PCM_FLAGS;
	
	// Internal
	reg [7:0] REG1_ADDR;
	reg [7:0] REG2_ADDR;
	wire [2:0] PCMA_CH;
	
	assign PCMA_CH = REG2_ADDR[2:0];
	
	always @(nWR, nCS)
	begin
		if (!(nWR | nCS | ~nRD))
		begin
			if (!SDA[0])			// Set register address
			begin
				if (!(SDA[1]))		// Common address register for both zones ?
					REG1_ADDR <= SDD;
				else
					REG2_ADDR <= SDD;
			end
			else						// Set register data
			begin
				if (!(SDA[1]))
				begin
					case (REG1_ADDR)
						8'h00: SSG_FREQ_A[7:0] <= SDD;
						8'h01: SSG_FREQ_A[11:8] <= SDD[3:0];
						8'h02: SSG_FREQ_B[7:0] <= SDD;
						8'h03: SSG_FREQ_B[11:8] <= SDD[3:0];
						8'h04: SSG_FREQ_C[7:0] <= SDD;
						8'h05: SSG_FREQ_C[11:8] <= SDD[3:0];
						8'h06: SSG_NOISE <= SDD[4:0];
						8'h07: SSG_EN <= SDD[5:0];
						8'h08: SSG_VOL_A <= SDD[4:0];
						8'h09: SSG_VOL_B <= SDD[4:0];
						8'h0A: SSG_VOL_C <= SDD[4:0];
						8'h0B: SSG_ENV_FREQ[7:0] <= SDD;
						8'h0C: SSG_ENV_FREQ[15:8] <= SDD;
						8'h0D: SSG_ENV <= SDD[4:0];
	
						8'h10: PCMB_TRIG <= SDD;
						8'h11: PCMB_PAN <= SDD[7:6];
						8'h12: PCMB_START[7:0] <= SDD;
						8'h13: PCMB_START[15:8] <= SDD;
						8'h14: PCMB_STOP[7:0] <= SDD;
						8'h15: PCMB_STOP[15:8] <= SDD;
						8'h19: PCMB_DELTA[7:0] <= SDD;
						8'h1A: PCMB_DELTA[15:8] <= SDD;
						8'h1B: PCMB_VOL <= SDD;
						8'h1C: PCM_FLAGS <= SDD;
						
						8'h22: FM_LFO <= SDD[3:0];
						8'h24: YMTIMER_TA_LOAD[7:0] <= SDD;
						8'h25: YMTIMER_TA_LOAD[9:8] <= SDD[1:0];
						8'h26: YMTIMER_TB_LOAD <= SDD;
						8'h27: YMTIMER_CONFIG <= SDD;
						
						// Default needed
					endcase
				end
				else
				begin
					casez (REG2_ADDR)
						8'h00: PCMA_KEYON <= SDD;
						8'h01: PCMA_MVOL <= SDD[5:0];
						8'b00001zzz: PCMA_VOLPAN[PCMA_CH] <= SDD;
						8'b00010zzz: PCMA_START[PCMA_CH][7:0] <= SDD;
						8'b00011zzz: PCMA_START[PCMA_CH][15:8] <= SDD;
						8'b00100zzz: PCMA_STOP[PCMA_CH][7:0] <= SDD;
						8'b00101zzz: PCMA_STOP[PCMA_CH][15:8] <= SDD;
						
						// Default needed
					endcase
				end
			end
		end
	end
	
	ym_timer YMTIMER(PHI_S, YMTIMER_TA_LOAD, YMTIMER_TB_LOAD, YMTIMER_CONFIG, nIRQ);
	ym_ssg YMSSG(PHI_S, ANA, SSG_FREQ_A, SSG_FREQ_B, SSG_FREQ_C, SSG_NOISE, SSG_EN, SSG_VOL_A, SSG_VOL_B, SSG_VOL_C,
						SSG_ENV_FREQ, SSG_ENV);
	//ym_fm YMFM(PHI_S);
	ym_pcma YMPCMA(PHI_S, SDRAD, SDRA_L, SDRA_U, SDRMPX, nSDROE);
	ym_pcmb YMPCMB(PHI_S, SDPAD, SDPA, SDPMPX, nSDPOE);

endmodule
