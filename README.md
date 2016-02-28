# NeoGeoFPGA-sim
Simulation files for the NeoGeo hardware definition

Converted ROM files aren't provided for obvious reasons, get them on any ROM download website and convert them with rom2verilog.c. I'm using joyjoy for now.

Top file is neogeo_mvs.v

* cha_board.v : MVS cartridge model CHA board (C ROMs, S ROM, M ROM)
* prog_board.v : MVS cartridge model PROG board (V ROMs, P ROM)
* mvs_cart.v : Just wires both CHA and PROG boards into a cartridge model
* linebuffer.v : Raster line buffer (used by NEO-B1)
* neo_273.v : NEO-273 chip used in cartridge
* neo_b1.v : NEO-B1 graphics buffer chip
* neo_zmc2.v : NEO-ZMC2 graphics chip
* palram.v : Palette RAM chip
* rom_*.v : ROM chips filled with ROM files
* vram_l.v : Slow VRAM chip
* vram_u.v : Fast VRAM chip
