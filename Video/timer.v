`timescale 1ns/1ns

module lspc_timer(
	input nRESET,
	
	input  VIDEO_MODE,
	input  TIMERSTOP,
	input  [8:0] VCOUNT
);
	
	reg [31:0] TIMER;				// Pixel timer
	
	//					PAL	PALSTOP	NTSC
	// F8 ~ FF		0		0			0			011111000	011111111
	// 100 ~ 10F	1		0			1			100000000	100001111
	// 110 ~ 1EF	1		1			1			100010000	111101111
	// 1F0 ~ 1FF	1		0			1			111110000	111111111
	assign VPALSTOP = VIDEO_MODE & TIMERSTOP;
	assign BORDER_TOP = ~(VCOUNT[7] + VCOUNT[6] + VCOUNT[5] + VCOUNT[4]);
	assign BORDER_BOT = VCOUNT[7] & VCOUNT[6] & VCOUNT[5] & VCOUNT[4];
	assign BORDERS = BORDER_TOP + BORDER_BOT;
	assign nTIMERRUN = (VPALSTOP & BORDERS) | ~VCOUNT[8];
	
	// TIMERINT_MODE[1] is used in vblank !

	// Pixel timer
	always @(negedge MAIN_CNT[2] or negedge nRESET)		// posedge ? pixel clock
	begin
		if (!nRESET)
		begin
			TIMER <= 0;
		end
		else
		begin
			if (!nTIMERRUN)
			begin
				if (TIMER)
					TIMER <= TIMER - 1'b1;
				else
				begin
					//if (TIMERINT_EN) nIRQS[1] <= 1'b0;	// IRQ2 plz
					if (TIMERINT_MODE[2]) TIMER <= TIMERLOAD;
				end
			end
		end
	end

endmodule
