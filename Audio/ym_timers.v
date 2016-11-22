`timescale 1ns/1ns

module ym_timers(
	input CLK,
	input TICK_144,
	input nRESET,
	input [9:0] YMTIMER_TA_LOAD,
	input [7:0] YMTIMER_TB_LOAD,
	input [5:0] YMTIMER_CONFIG,
	input clr_run_A, set_run_A, clr_run_B, set_run_B,
	output FLAG_A, FLAG_B,
	output nIRQ
);
	
	// Z80 IRQ gen
	assign nIRQ = ~((FLAG_A & YMTIMER_CONFIG[2]) | (FLAG_B & YMTIMER_CONFIG[3]));
	
	ym_timer	#(.mult_width(1), .cnt_width(10)) timer_A (
		.CLK			( CLK ),
		.TICK_144	( TICK_144 ),
		.nRESET		( nRESET ),
		.LOAD_VALUE	( YMTIMER_TA_LOAD	),	
		.LOAD			( YMTIMER_CONFIG[0] ),
		.CLR_FLAG   ( YMTIMER_CONFIG[4] ),
		.SET_RUN		( set_run_A	),
		.CLR_RUN		( clr_run_A ),
		.OVF_FLAG	( FLAG_A	),
		.OVF			(  )		// Todo overflow_A
	);

	ym_timer #(.mult_width(4), .cnt_width(8)) timer_B (
		.CLK			( CLK ),
		.TICK_144	( TICK_144 ),
		.nRESET		( nRESET ),
		.LOAD_VALUE	( YMTIMER_TB_LOAD	),
		.LOAD			( YMTIMER_CONFIG[1] ),
		.CLR_FLAG   ( YMTIMER_CONFIG[5] ),
		.SET_RUN		( set_run_B	),
		.CLR_RUN		( clr_run_B ),
		.OVF_FLAG	( FLAG_B	),
		.OVF			(	)		// Unused in YM2610 ?
	);
	
endmodule
