`timescale 10ns/10ns

module irq(
	input [2:0] IRQ,
	output IPL0, IPL1
);

	// Interrupt priority encoder
	// xx1: 11
	// x10: 10
	// 100: 01
	// 000: 00
	assign IPL0 = (IRQ[2] & ~IRQ[1]) + IRQ[0];
	assign IPL1 = IRQ[1] + IRQ[0];

endmodule


