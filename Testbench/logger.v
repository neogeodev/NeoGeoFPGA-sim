`timescale 1ns/1ns

// Sim only

module logger(
	input CLK_6MB,
	input nBNKB,
	input SHADOW,
	input [15:0] PC,
	input [8:0] HCOUNT,
	input [7:0] LED_DATA,
	input [2:0] LED_LATCH,
	input COUNTER1, COUNTER2, LOCKOUT1, LOCKOUT2
);

	wire [6:0] LOG_VIDEO_R;
	wire [6:0] LOG_VIDEO_G;
	wire [6:0] LOG_VIDEO_B;
	
	reg [5:0] MARQUEE;
	reg [7:0] LED1;
	reg [7:0] LED2;

	integer sim_line;
	integer sim_frame;
	integer f_video;
	integer f_cab_io;
	
	initial
	begin
		sim_line = 0;
		sim_frame = 0;
		f_video = $fopen("log_video.txt", "w");
		f_cab_io = $fopen("log_cab_io.txt", "w");
		#500000000			// Run for 500ms
		$fclose(f_video);
		$fclose(f_cab_io);
		$stop;
	end
	
	// Simulates MV-ELA board
	always @(negedge LED_LATCH[0])
		MARQUEE <= LED_DATA[5:0];
		
	// Simulates MV-LED boards
	always @(negedge LED_LATCH[1])
		LED1 <= LED_DATA;
	always @(negedge LED_LATCH[2])
		LED2 <= LED_DATA;
	
	assign LOG_VIDEO_R = nBNKB ? {SHADOW, PC[11:8], PC[14], PC[15]} : 7'b0000000;
	assign LOG_VIDEO_G = nBNKB ? {SHADOW, PC[7:4], PC[13], PC[15]} : 7'b0000000;
	assign LOG_VIDEO_B = nBNKB ? {SHADOW, PC[3:0], PC[12], PC[15]} : 7'b0000000;
	
	always @(posedge CLK_6MB)
	begin
		if (HCOUNT < 383)
		begin
			// Write each pixel
			$fwrite(f_video, "%05X ", {LOG_VIDEO_R, LOG_VIDEO_G, LOG_VIDEO_B});
		end
		else
		begin
			$fwrite(f_video, "YYYYY ");
			// $display("Line %d rendered", sim_line);
			if (sim_line == 263)
			begin
				sim_line = 0;
				$display("Frame %d rendered", sim_frame);
				
				// Write cab I/O data each frame
				// MM MMMMCCKK LLLLLLLL llllllll
				$fwrite(f_cab_io, "%08X ", {MARQUEE, COUNTER1, COUNTER2, LOCKOUT1, LOCKOUT2, LED2, LED1});
				
				sim_frame = sim_frame + 1;
			end
			else
				sim_line = sim_line + 1;
		end
	end

endmodule
