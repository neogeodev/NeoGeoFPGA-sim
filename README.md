# NeoGeoFPGA-sim
Simulation project for a SNK NeoGeo hardware definition. This does not go in a FPGA *yet* :)

This is being made possible by neogeodev contributors and Patreon donators: **Alexis Bezverkhyy, Alexis Huet, Ange Albertini, Artemio Urbina, Arthur Lemoine, Blastar, Charly, Cyrille Jouineau, Jonathan Bayle, Laurent Lieben, Lewis Waddington, Mahen, Marshall H. (Retroactive), Maxime Mouflard, Valérianne Lagrange, ...**.

![Diagram](Doc/ngfpgad1.png)

Green is what this project is all about. Yellow is simulation/testbench files. Grey are results from simulation.

ROM initialization files aren't provided for obvious reasons. You can get them from any ROM download website and convert them with tools/rom2verilog.c. I'm mostly using mslug (Metal Slug I) for now since it uses lots of moving sprites.

The system's top file is neogeo.v, currently used testbench is testbench_1.v .

Take a look in **LSPC2RE** for porn (main video chip's schematics). This was made possible by John McMaster.

# Progress

|Part|Progress|Notes|
|----|-----|-----|
|CPUs|100%|Using 68000 and Z80 open cores for now, wrappers are working|
|IRQs|90%|Logic is there, timer IRQ needs precise testing|
|ROMs|100%|System ROM, S1 and M1 are working|
|RAMs|100%|Work RAM, Backup RAM, VRAM and memory card are working|
|I/O|80%|Logic is there, no RTC for now, needs testing|
|Video|95%|LSPC is pretty much done, NEO-B1 still has a few issues|
|Audio|5%|Lots of work needed on YM2610, no audio output at all for now|

# Cartridge model (MVS for now)

* mvs_cart.v : Just wires both CHA and PROG boards into a cartridge model
* prog_board.v : MVS cartridge model PROG board (V ROMs, P ROM)
 * rom_p1.v : 68k program ROM
 * rom_v1.v : Sound ROM
 * rom_v2.v : Sound ROM
* cha_board.v : MVS cartridge model CHA board (C ROMs, S ROM, M ROM)
 * rom_c1.v : Sprite graphics ROM
 * rom_c2.v : Sprite graphics ROM
 * rom_s1.v : Fix graphics ROM
 * rom_m1.v : Z80 program ROM
 * neo_273.v : SNK latch chip
 * zmc.v : Z80 Memory Controller (can be part of ZMC2)

# External memory

* memcard.v : Memory card
* rom_l0.v : Shrink lookup table (L0) ROM
* rom_sp.v : System program (SP-S2 BIOS) ROM
* rom_sfix.v : Embeded fix graphics (SFIX) ROM

# NeoGeo model

* cpu_68k.v : Wrapper for TG68K
 * tg68k.vhd : TG68K Motorola 68000 CPU core (VHDL)
* cpu_z80.v : Wrapper for TVZ80
 * tv80_core.v : TV80 Z80 CPU core
* neo_c1.v : SNK address decoding, joypad inputs, system maestro chip
 * c1_regs.v : On-chip registers
 * c1_wait.v : Wait state generator
 * c1_inputs.v : Player inputs
* neo_d0.v : SNK memory card, clock and joypad outputs chip
 * clocks.v : Clock divider
 * z80ctrl.v : Z80 controller
* neo_e0.v : SNK memory card I/O chip
* neo_f0.v : SNK MVS cab I/O chip
* neo_i0.v : SNK MVS cab I/O chip
* syslatch.v : System latch/register
* lspc_a2.v : Where the magic lives
 * resetp.v : Reset pulse generator
 * irq.v : 68000 IRQ gen/ack
 * videosync.v : Video sync and "ticks" generator
 * slow_cycle.v : Slow VRAM access sequencer
  * vram_slow_l.v : Slow VRAM chip LSBs
  * vram_slow_u.v : Slow VRAM chip MSBs
 * fast_cycle.v : Fast VRAM access sequencer
  * vram_fast_l.v : Fast VRAM chip LSBs
  * vram_fast_u.v : Fast VRAM chip MSBs
 * p_cycle.v : P bus sequencer
 * autoanim.v : Auto-animation specifics
 * hshrink.v : Sprite horizontal shrink logic
* neo_b1.v : SNK graphics buffer chip
 * watchdog.v : Watchdog timer part
 * linebuffer.v : Pixel line buffers (x4)
* m68kram.v : 68k work RAM helper
 * ram68k_l.v : 68k work RAM LSBs
 * ram68k_u.v : 68k work RAM MSBs
* zram.v : Z80 work RAM
* palram.v : Palette RAM helper
 * palram_l.v : Palette RAM LSBs
 * palram_u.v : Palette RAM MSBs
* sram.v : Backup RAM (MVS) helper
 * sram_l.v : Backup RAM LSBs
 * sram_u.v : Backup RAM MSBs
* ym2610.v : Yamaha YM2610 sound chip
 * ym_timer.v : Timer and IRQ part
 * ym_ssg.v : Simple Sound Generator part
  * ssg_ch.v : SSG channel
 * ym_pcma.v : ADPCM-A voices part
 * ym_pcmb.v : ADPCM-B voice part
* upd4990.v : NEC uPD4990 interface to some modern RTC chip
* neo_zmc2.v : SNK graphics chip (most of it done by Kyuusaku)
 * zmc2_dot.v : Graphics serializer part
* videout.v : Video output latch
* ser_video.v : Video serial interface
* ym2i2s.v : Sound serial interface
