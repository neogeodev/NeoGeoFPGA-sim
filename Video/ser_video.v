`timescale 1ns/1ns

module ser_video(
	input CLK_SERVID,
	input CLK_6MB,
	input [6:0] VIDEO_R,
	input [6:0] VIDEO_G,
	input [6:0] VIDEO_B,
	output VIDEO_R_SER,
	output VIDEO_G_SER,
	output VIDEO_B_SER,
	output VIDEO_CLK_SER,
	output VIDEO_RES_SER
);

	reg [6:0] R_SR;
	reg [6:0] G_SR;
	reg [6:0] B_SR;
	
	reg [1:0] VIDEO_LOAD;
	
	assign VIDEO_CLK = CLK_SERVID;
	assign VIDEO_RES = 1'b0;			// Todo
	
	assign VIDEO_R_SER = R_SR[6];
	assign VIDEO_G_SER = G_SR[6];
	assign VIDEO_B_SER = B_SR[6];
	
	always @(posedge CLK_SERVID)
	begin
		VIDEO_LOAD <= {VIDEO_LOAD[0], CLK_6MB};
		if (VIDEO_LOAD == 2'b01)			// Rising edge
		begin
			R_SR <= VIDEO_R;					// Load SRs
			G_SR <= VIDEO_G;
			B_SR <= VIDEO_B;
		end
		else
		begin
			R_SR <= {R_SR[5:0], 1'b0};		// Shift
			G_SR <= {G_SR[5:0], 1'b0};
			B_SR <= {B_SR[5:0], 1'b0};
		end
	end

endmodule
