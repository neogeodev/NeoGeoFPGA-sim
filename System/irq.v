`timescale 1ns/1ns

module irq(
	input WR_ACK,
	input [2:0] ACK_BITS,
	input BNK,
	input CLK,
	output IPL0, IPL1
);

	wire [2:0] ACK;
	wire [3:0] B32_Q;

	assign ACK[0] = ~&{~WR_ACK, ACK_BITS[0]};
	assign ACK[1] = ~&{~WR_ACK, ACK_BITS[1]};
	assign ACK[2] = ~&{~WR_ACK, ACK_BITS[2]};
	
	FDPCell B56(, 1'b1, , ACK[0], B56_Q, B56_nQ);
	FDPCell B52(, 1'b1, , ACK[1], B52_Q, B52_nQ);
	FDPCell C52(BNK, 1'b1, , ACK[2], C52_Q, C52_nQ);
	
	// B49
	assign B49_OUT = B52_nQ | B56_Q;
	
	// B50A
	assign B50A_OUT = &{C52_nQ, B56_Q, B52_Q};
	
	FDSCell B32(CLK, {1'b0, B50A_OUT, B49_OUT, B56_nQ}, B32_Q);
	
	assign IPL0 = ~|{~B32_Q[0], B32_Q[2]};
	assign IPL1 = ~|{~B32_Q[1], ~B32_Q[0]};
	
	// Interrupt priority encoder (is priority right ?)
	// IRQ  IPL
	// xx1:  00 COLDBOOT
	// x10:  01 HBL
	// 100:  10 VBL
	// 000:  11 No interrupt

endmodule
