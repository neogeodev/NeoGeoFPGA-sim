# NeoGeoFPGA-sim
Simulation project for a NeoGeo hardware definition. This does not go in a FPGA yet :)

![Diagram](ngfpgad1.png)

Red is what this project is all about. Yellow is simulation/testbench files. Grey are results from simulation.

Converted ROM files for the cartridge model aren't provided for obvious reasons, get them from any ROM download website and convert them with rom2verilog.c. I'm using joyjoy for now (small, simple game).

Top file is neogeo_mvs.v, currently used testbench is testbench_1.v .

# Cartridge model (MVS for now)

* cha_board.v : MVS cartridge model CHA board (C ROMs, S ROM, M ROM)
* prog_board.v : MVS cartridge model PROG board (V ROMs, P ROM)
* mvs_cart.v : Just wires both CHA and PROG boards into a cartridge model

# NeoGeo model

* linebuffer.v : Raster line buffer (used by NEO-B1)
* neo_273.v : NEO-273 chip used in cartridge
* neo_b1.v : NEO-B1 graphics buffer chip
* neo_zmc2.v : NEO-ZMC2 graphics chip
* palram.v : Palette RAM chip
* rom_*.v : ROM chips filled with ROM files
* vram_l.v : Slow VRAM chip
* vram_u.v : Fast VRAM chip
