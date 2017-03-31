`timescale 1ns/1ns

module lspc_timer(
	input nRESET,
	input CLK,
	input VBLANK,
	input VIDEO_MODE,
	input [2:0] TIMER_MODE,
	input TIMER_INT_EN,
	input TIMER_LOAD,
	input TIMER_PAL_STOP,
	input [8:0] VCOUNT
);
	
	reg [31:0] TIMER;		// Pixel timer
	
	//					PAL	PALSTOP	NTSC		From			To
	// F8 ~ FF		0		0			0			011111000	011111111
	// 100 ~ 10F	1		0			1			100000000	100001111
	// 110 ~ 1EF	1		1			1			100010000	111101111
	// 1F0 ~ 1FF	1		0			1			111110000	111111111
	assign STOP_EN = VIDEO_MODE & TIMER_PAL_STOP;
	assign STOP_TOP = ~|{VCOUNT[7:4]};	//	x0000xxxx
	assign STOP_BOT = &{VCOUNT[7:4]};	//	x1111xxxx
	assign STOP = STOP_EN & STOP_TOP & STOP_BOT;
	assign RUN = VCOUNT[8] & ~STOP;		// CHECK: Only run during active display ?

	always @(negedge CLK or negedge nRESET)		// posedge ? pixel clock
	begin
		if (!nRESET)
		begin
			TIMER <= 32'd0;
		end
		else
		begin
			if (TIMER_MODE[1] & VBLANK)
				TIMER <= TIMER_LOAD;		// Vblank mode
			
			if (RUN)
			begin
				if (TIMER)
					TIMER <= TIMER - 1'b1;
				else
				begin
					//if (TIMER_INT_EN) nIRQS[1] <= 1'b0;				// IRQ2 plz
					if (TIMER_MODE[2]) TIMER <= TIMER_LOAD;		// Repeat mode
				end
			end
		end
	end

endmodule
