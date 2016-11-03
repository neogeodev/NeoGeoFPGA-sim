`timescale 1ns/1ns

module ym2610(
	input PHI_S,
	input nRESET,
	
	inout [7:0] SDD,
	input [1:0] SDA,
	output nIRQ,
	input nCS,
	input nWR_RAW,
	input nRD_RAW,
	
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

	// nCS gating - Not sure if it's that simple
	assign nWR = nCS | nWR_RAW;
	assign nRD = nCS | nRD_RAW;
	
	// Internal
	reg P1;						// Internal clock
	reg BUSY;
	reg [1:0] BUSY_MMR_SR;	// For edge detection
	reg nWR_COPY;
	reg [1:0] ADDR_COPY;
	reg [7:0] DATA_COPY;
	reg nWRITE_S;
	reg [1:0] ADDR_S;
	reg [7:0] DATA_S;
	
	// Timer
	wire [9:0] YMTIMER_TA_LOAD;
	wire [7:0] YMTIMER_TB_LOAD;
	wire [7:0] YMTIMER_CONFIG;

	// SSG
	wire [11:0] SSG_FREQ_A;
	wire [11:0] SSG_FREQ_B;
	wire [11:0] SSG_FREQ_C;
	wire [4:0] SSG_NOISE;
	wire [5:0] SSG_EN;
	wire [4:0] SSG_VOL_A;
	wire [4:0] SSG_VOL_B;
	wire [4:0] SSG_VOL_C;
	wire [15:0] SSG_ENV_FREQ;
	wire [3:0] SSG_ENV;
	
	// FM
	wire [3:0] FM_LFO;
	wire [7:0] FM_KEYON;
	wire [6:0] FM_DTMUL[3:0];
	wire [6:0] FM_TL[3:0];
	wire [7:0] FM_KSAR[3:0];
	wire [7:0] FM_AMDR[3:0];
	wire [4:0] FM_SR[3:0];
	wire [7:0] FM_SLRR[3:0];
	wire [3:0] FM_SSGEG[3:0];
	wire [13:0] FM_FNUM13;
	wire [13:0] FM_FNUM24;
	wire [13:0] FM_2FNUM13;
	wire [13:0] FM_2FNUM24;
	wire [5:0] FM_FBALGO13;
	wire [5:0] FM_FBALGO24;
	wire [7:0] FM_PAN13;
	wire [7:0] FM_PAN24;
	
	// ADPCM-A
	wire [7:0] PCMA_KEYON;
	wire [5:0] PCMA_MVOL;
	wire [7:0] PCMA_VOLPAN_A;
	wire [7:0] PCMA_VOLPAN_B;
	wire [7:0] PCMA_VOLPAN_C;
	wire [7:0] PCMA_VOLPAN_D;
	wire [7:0] PCMA_VOLPAN_E;
	wire [7:0] PCMA_VOLPAN_F;
	wire [15:0] PCMA_START_A;
	wire [15:0] PCMA_START_B;
	wire [15:0] PCMA_START_C;
	wire [15:0] PCMA_START_D;
	wire [15:0] PCMA_START_E;
	wire [15:0] PCMA_START_F;
	wire [15:0] PCMA_STOP_A;
	wire [15:0] PCMA_STOP_B;
	wire [15:0] PCMA_STOP_C;
	wire [15:0] PCMA_STOP_D;
	wire [15:0] PCMA_STOP_E;
	wire [15:0] PCMA_STOP_F;
	
	// ADPCM-B
	wire [7:0] PCMB_TRIG;
	wire [7:6] PCMB_PAN;
	wire [15:0] PCMB_START;
	wire [15:0] PCMB_STOP;
	wire [15:0] PCMB_DELTA;
	wire [7:0] PCMB_VOL;
	wire [7:0] PCM_FLAGS;
	
	// Internal clock generation
	// assign RESET = !nRESET;
	always @(posedge PHI_S or negedge nRESET)
	begin
		if (!nRESET)
			P1 <= 1'b0;
		else
			P1 <= ~P1;
	end
	
	// CPU interface
	always @(posedge PHI_S)
	begin
		if (!nRESET)
		begin
			BUSY <= 1'b0;
		end
		else
		begin
			BUSY_MMR_SR <= {BUSY_MMR_SR[0], BUSY_MMR};
			if (!nWR && !BUSY)
			begin
				// Do write
				BUSY <= 1'b1;
				nWR_COPY <= 1'b0;
				ADDR_COPY <= SDA;
				DATA_COPY <= SDD;
			end
			else
			begin
				if (BUSY_MMR) nWR_COPY <= 1'b1;
				if (BUSY && BUSY_MMR_SR == 2'b10) nWR_COPY <= 1'b1;
			end
		end
	end
	
	always @(posedge P1)
		{nWRITE_S, ADDR_S, DATA_S} <= {nWR_COPY, ADDR_COPY, DATA_COPY};

   ym_regs 	YMREGS(PHI_S, nRESET, nWRITE_S, ADDR_S, DATA_S, BUSY_MMR,
						SSG_FREQ_A, SSG_FREQ_B, SSG_FREQ_C, SSG_NOISE, SSG_EN, SSG_VOL_A, SSG_VOL_B, SSG_VOL_C,
						SSG_ENV_FREQ, SSG_ENV,
						YMTIMER_TA_LOAD, YMTIMER_TB_LOAD, YMTIMER_CONFIG,
						PCMA_KEYON, PCMA_MVOL,
						PCMA_VOLPAN_A, PCMA_VOLPAN_B, PCMA_VOLPAN_C, PCMA_VOLPAN_D, PCMA_VOLPAN_E, PCMA_VOLPAN_F,
						PCMA_START_A, PCMA_START_B, PCMA_START_C, PCMA_START_D, PCMA_START_E, PCMA_START_F,
						PCMA_STOP_A, PCMA_STOP_B, PCMA_STOP_C, PCMA_STOP_D, PCMA_STOP_E, PCMA_STOP_F,
						PCMB_TRIG, PCMB_PAN, PCMB_START, PCMB_STOP, PCMB_DELTA, PCMB_VOL, PCM_FLAGS
						);
	ym_timer YMTIMER(PHI_S, YMTIMER_TA_LOAD, YMTIMER_TB_LOAD, YMTIMER_CONFIG, nIRQ);
	ym_ssg 	YMSSG(PHI_S, ANA, SSG_FREQ_A, SSG_FREQ_B, SSG_FREQ_C, SSG_NOISE, SSG_EN, SSG_VOL_A, SSG_VOL_B, SSG_VOL_C,
						SSG_ENV_FREQ, SSG_ENV);
	ym_fm 	YMFM(PHI_S);
	ym_pcma 	YMPCMA(PHI_S, SDRAD, SDRA_L, SDRA_U, SDRMPX, nSDROE);
	ym_pcmb 	YMPCMB(PHI_S, SDPAD, SDPA, SDPMPX, nSDPOE);

endmodule
