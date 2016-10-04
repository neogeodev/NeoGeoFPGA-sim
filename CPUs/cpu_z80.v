`timescale 1ns/1ns

// Z80 CPU plug into TV80 core

module cpu_z80(
	input CLK_4M,
	input nRESET,
	inout [7:0] SDD,
	output [15:0] SDA,
	output reg nIORQ, nMREQ,
	output reg nRD, nWR,
	input nINT, nNMI
);

	reg [7:0] SDD_IN_REG;

	wire [7:0] SDD_IN;
	wire [7:0] SDD_OUT;
	
	wire [6:0] T_STATE;
	wire [6:0] M_CYCLE;
	wire nINTCYCLE;
	wire NO_READ;
	wire WRITE;
	wire IORQ;
	
	assign SDD = nWR ? 8'bzzzzzzzz : SDD_OUT;
	assign SDD_IN = nRD ? 8'bzzzzzzzz : SDD;

	tv80_core TV80( , IORQ, NO_READ, WRITE, , , , SDA, SDD_OUT, M_CYCLE,
							T_STATE, nINTCYCLE, , , nRESET, CLK_4M, 1'b1, 1'b1,
							nINT, nNMI, 1'b1, SDD_IN, SDD_IN_REG);
	
	always @(posedge CLK_4M)
	begin
		if (!nRESET)
		begin
			nRD <= #1 1'b1;
			nWR <= #1 1'b1;
			nIORQ <= #1 1'b1;
			nMREQ <= #1 1'b1;
			SDD_IN_REG <= #1 8'b00000000;
		end
		else
		begin
			nRD <= #1 1'b1;
			nWR <= #1 1'b1;
			nIORQ <= #1 1'b1;
			nMREQ <= #1 1'b1;
			if (M_CYCLE[0])
			begin
				if (T_STATE[1])
				begin
					nRD <= #1 ~nINTCYCLE;
					nMREQ <= #1 ~nINTCYCLE;
					nIORQ <= #1 nINTCYCLE;
				end
			end
			else
			begin
				if ((T_STATE[1]) && NO_READ == 1'b0 && WRITE == 1'b0)
				begin
					nRD <= #1 1'b0;
					nIORQ <= #1 ~IORQ;
					nMREQ <= #1 IORQ;
				end
				if ((T_STATE[1]) && WRITE == 1'b1)
				begin
					nWR <= #1 1'b0;
					nIORQ <= #1 ~IORQ;
					nMREQ <= #1 IORQ;
				end
			end
			if (T_STATE[2]) SDD_IN_REG <= #1 SDD_IN;
		end
	end
	
endmodule
