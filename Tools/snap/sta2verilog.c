#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <unistd.h>

// This tool outputs verilog memory initialization files from a MAME savestate
// Part of the NeoGeo FPGA project
// Last mod: furrtek 03/2018

#define HEADER_LENGTH 	32
#define SLOW_VRAM_START	0x4B51
#define FAST_VRAM_START 0x14B51
#define PALETTES_START 0x50775

int main(int argc, char *argv[]) {
	unsigned int line = 0;
	unsigned short int pixel;
	unsigned long int ng_color;
	char rd[8];
	FILE * file_ptr;
	char * in_buffer;
	unsigned long int in_size;
	
	if (argc != 2) {
		puts("usage: sta2verilog input.sta\n");
		return 1;
	}
	
	file_ptr = fopen(argv[1], "r");
	if (file_ptr == NULL)
		return 1;
	fseek(file_ptr, 0, SEEK_END);
	in_size = ftell(file_ptr);
	rewind(file_ptr);
	
	in_buffer = (char*)malloc(in_size);
	
	fread(in_buffer, in_size, 1, file_ptr);
	fclose(file_ptr);
	
	file_ptr = fopen("sta_raw.bin", "wb");
	fwrite(in_buffer + HEADER_LENGTH, in_size - HEADER_LENGTH, 1, file_ptr);
	fclose(file_ptr);
	
	remove("sta_raw_unpack.bin");
	system("offzip sta_raw.bin");
	
	file_ptr = fopen("sta_raw_unpack.bin", "r");
	fseek(file_ptr, 0, SEEK_END);
	in_size = ftell(file_ptr);
	rewind(file_ptr);
	
	printf("%lu", in_size);
	
	free(in_buffer);
	in_buffer = (char*)malloc(in_size);

	fread(in_buffer, in_size, 1, file_ptr);
	fclose(file_ptr);
	
	file_ptr = fopen("slow_vram.bin", "wb");
	fwrite(in_buffer + SLOW_VRAM_START, 0x10000, 1, file_ptr);
	fclose(file_ptr);
	file_ptr = fopen("fast_vram.bin", "wb");
	fwrite(in_buffer + FAST_VRAM_START, 0x1000, 1, file_ptr);
	fclose(file_ptr);
	file_ptr = fopen("palettes.bin", "wb");
	fwrite(in_buffer + PALETTES_START, 0x4000, 1, file_ptr);
	fclose(file_ptr);

	free(in_buffer);
	
	return 0;
}

