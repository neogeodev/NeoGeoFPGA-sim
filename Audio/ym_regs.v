`timescale 1ns/1ns

module ym_regs(
	input PHI_S,
	input nRESET,
	input nWRITE_S,
	input [1:0] ADDR_S,
	input [7:0] DATA_S,
	output reg BUSY_MMR,
	
	// SSG
	output reg [11:0] SSG_FREQ_A,
	output reg [11:0] SSG_FREQ_B,
	output reg [11:0] SSG_FREQ_C,
	output reg [4:0] SSG_NOISE,
	output reg [5:0] SSG_EN,
	output reg [4:0] SSG_VOL_A,
	output reg [4:0] SSG_VOL_B,
	output reg [4:0] SSG_VOL_C,
	output reg [15:0] SSG_ENV_FREQ,
	output reg [3:0] SSG_ENV,
	
	// Timer
	output reg [9:0] YMTIMER_TA_LOAD,
	output reg [7:0] YMTIMER_TB_LOAD,
	output reg [7:0] YMTIMER_CONFIG,
	
	// ADPCM-A
	output reg [7:0] PCMA_KEYON,
	output reg [5:0] PCMA_MVOL,
	output reg [7:0] PCMA_VOLPAN_A,
	output reg [7:0] PCMA_VOLPAN_B,
	output reg [7:0] PCMA_VOLPAN_C,
	output reg [7:0] PCMA_VOLPAN_D,
	output reg [7:0] PCMA_VOLPAN_E,
	output reg [7:0] PCMA_VOLPAN_F,
	output reg [15:0] PCMA_START_A,
	output reg [15:0] PCMA_START_B,
	output reg [15:0] PCMA_START_C,
	output reg [15:0] PCMA_START_D,
	output reg [15:0] PCMA_START_E,
	output reg [15:0] PCMA_START_F,
	output reg [15:0] PCMA_STOP_A,
	output reg [15:0] PCMA_STOP_B,
	output reg [15:0] PCMA_STOP_C,
	output reg [15:0] PCMA_STOP_D,
	output reg [15:0] PCMA_STOP_E,
	output reg [15:0] PCMA_STOP_F,
	
	// ADPCM-B
	output reg [7:0] PCMB_TRIG,
	output reg [7:6] PCMB_PAN,
	output reg [15:0] PCMB_START,
	output reg [15:0] PCMB_STOP,
	output reg [15:0] PCMB_DELTA,
	output reg [7:0] PCMB_VOL,
	output reg [7:0] PCM_FLAGS
);

	// Internal
	reg [7:0] REG1_ADDR;
	reg [7:0] REG2_ADDR;
	
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
	

	always @(posedge PHI_S)
	begin
		if (!nRESET)
		begin
			// Registers init
			REG1_ADDR <= 8'h0;
			BUSY_MMR <= 1'b0;
			// Todo: See timers...
		end
		else
		begin
			if (!nWRITE_S && !BUSY_MMR)
			begin
				// CPU write
				BUSY_MMR <= 1'b1;
				if (!ADDR_S[0])			// Set register address
				begin
					if (!ADDR_S[1])		// Common address register for both parts ?
					begin
						$display("YM2610 part A address register %H", DATA_S);	// DEBUG
						REG1_ADDR <= DATA_S;
					end
					else
					begin
						$display("YM2610 part B address register %H", DATA_S);	// DEBUG
						REG2_ADDR <= DATA_S;
					end
				end
				else							// Set register data
				begin
					if (!ADDR_S[1])
					begin
						$display("YM2610 part A set register %H to %H", REG1_ADDR, DATA_S);	// DEBUG
						case (REG1_ADDR)
							8'h00: SSG_FREQ_A[7:0] <= DATA_S;
							8'h01: SSG_FREQ_A[11:8] <= DATA_S[3:0];
							8'h02: SSG_FREQ_B[7:0] <= DATA_S;
							8'h03: SSG_FREQ_B[11:8] <= DATA_S[3:0];
							8'h04: SSG_FREQ_C[7:0] <= DATA_S;
							8'h05: SSG_FREQ_C[11:8] <= DATA_S[3:0];
							8'h06: SSG_NOISE <= DATA_S[4:0];
							8'h07: SSG_EN <= DATA_S[5:0];
							8'h08: SSG_VOL_A <= DATA_S[4:0];
							8'h09: SSG_VOL_B <= DATA_S[4:0];
							8'h0A: SSG_VOL_C <= DATA_S[4:0];
							8'h0B: SSG_ENV_FREQ[7:0] <= DATA_S;
							8'h0C: SSG_ENV_FREQ[15:8] <= DATA_S;
							8'h0D: SSG_ENV <= DATA_S[4:0];
		
							8'h10: PCMB_TRIG <= DATA_S;
							8'h11: PCMB_PAN <= DATA_S[7:6];
							8'h12: PCMB_START[7:0] <= DATA_S;
							8'h13: PCMB_START[15:8] <= DATA_S;
							8'h14: PCMB_STOP[7:0] <= DATA_S;
							8'h15: PCMB_STOP[15:8] <= DATA_S;
							8'h19: PCMB_DELTA[7:0] <= DATA_S;
							8'h1A: PCMB_DELTA[15:8] <= DATA_S;
							8'h1B: PCMB_VOL <= DATA_S;
							8'h1C: PCM_FLAGS <= DATA_S;
							
							8'h22: FM_LFO <= DATA_S[3:0];
							8'h24: YMTIMER_TA_LOAD[7:0] <= DATA_S;
							8'h25: YMTIMER_TA_LOAD[9:8] <= DATA_S[1:0];
							8'h26: YMTIMER_TB_LOAD <= DATA_S;
							8'h27: YMTIMER_CONFIG <= DATA_S;
							
							// FM: Todo
							
							// Default needed
						endcase
					end
					else
					begin
						$display("YM2610 part B set register %H to %H", REG2_ADDR, DATA_S);	// DEBUG
						casez (REG2_ADDR)
							8'h00: PCMA_KEYON <= DATA_S;
							8'h01: PCMA_MVOL <= DATA_S[5:0];
							
							8'b00001000: PCMA_VOLPAN_A <= DATA_S;
							8'b00001001: PCMA_VOLPAN_B <= DATA_S;
							8'b00001010: PCMA_VOLPAN_C <= DATA_S;
							8'b00001011: PCMA_VOLPAN_D <= DATA_S;
							8'b00001100: PCMA_VOLPAN_E <= DATA_S;
							8'b00001101: PCMA_VOLPAN_F <= DATA_S;
							
							8'b00010000: PCMA_START_A[7:0] <= DATA_S;
							8'b00010001: PCMA_START_A[7:0] <= DATA_S;
							8'b00010010: PCMA_START_A[7:0] <= DATA_S;
							8'b00010011: PCMA_START_A[7:0] <= DATA_S;
							8'b00010100: PCMA_START_A[7:0] <= DATA_S;
							8'b00010101: PCMA_START_A[7:0] <= DATA_S;
							
							8'b00011000: PCMA_START_A[15:8] <= DATA_S;
							8'b00011001: PCMA_START_B[15:8] <= DATA_S;
							8'b00011010: PCMA_START_C[15:8] <= DATA_S;
							8'b00011011: PCMA_START_D[15:8] <= DATA_S;
							8'b00011100: PCMA_START_E[15:8] <= DATA_S;
							8'b00011101: PCMA_START_F[15:8] <= DATA_S;
							
							8'b00100000: PCMA_STOP_A[7:0] <= DATA_S;
							8'b00100001: PCMA_STOP_B[7:0] <= DATA_S;
							8'b00100010: PCMA_STOP_C[7:0] <= DATA_S;
							8'b00100011: PCMA_STOP_D[7:0] <= DATA_S;
							8'b00100100: PCMA_STOP_E[7:0] <= DATA_S;
							8'b00100101: PCMA_STOP_F[7:0] <= DATA_S;
							
							8'b00101000: PCMA_STOP_A[15:8] <= DATA_S;
							8'b00101001: PCMA_STOP_B[15:8] <= DATA_S;
							8'b00101010: PCMA_STOP_C[15:8] <= DATA_S;
							8'b00101011: PCMA_STOP_D[15:8] <= DATA_S;
							8'b00101100: PCMA_STOP_E[15:8] <= DATA_S;
							8'b00101101: PCMA_STOP_F[15:8] <= DATA_S;
							
							// Default needed
						endcase
					end
				end
			end
			else
			begin
				BUSY_MMR	<= 1'b0;	// DEBUG
			end
		end
	end
	
endmodule
