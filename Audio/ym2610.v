`timescale 10ns/10ns

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
	
	output [3:0] ANA,					// How many levels ?
	
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
	reg [6:0] FM_DTMUL[4:1];
	reg [6:0] FM_TL[4:1];
	reg [7:0] FM_KSAR[4:1];
	reg [7:0] FM_AMDR[4:1];
	reg [4:0] FM_SR[4:1];
	reg [7:0] FM_SLRR[4:1];
	reg [3:0] FM_SSGEG[4:1];
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
	reg [7:0] PCMA_VOLPAN[6:1];
	reg [15:0] PCMA_START[6:1];
	reg [15:0] PCMA_STOP[6:1];
	
	// ADPCM-B
	reg [7:0] PCMB_TRIG;
	reg [7:6] PCMB_PAN;
	reg [15:0] PCMB_START;
	reg [15:0] PCMB_STOP;
	reg [15:0] PCMB_DELTA;
	reg [7:0] PCMB_VOL;
	
	reg [7:0] PCM_FLAGS;
	
	ym_timer YMTIMER(PHI_S, YMTIMER_TA_LOAD, YMTIMER_TB_LOAD, YMTIMER_CONFIG, nIRQ);
	ym_ssg YMSSG(PHI_S, ANA);
	//ym_fm YMFM(PHI_S);
	ym_pcma YMPCMA(PHI_S, SDRAD, SDRA_L, SDRA_U, SDRMPX, nSDROE);
	ym_pcmb YMPCMB(PHI_S, SDPAD, SDPA, SDPMPX, nSDPOE);

endmodule
