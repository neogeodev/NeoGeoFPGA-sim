#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <unistd.h>

// This tool outputs a sequence of .bmp images from a .txt video simulation output
// Part of the NeoGeo FPGA project
// Last mod: furrtek 08/2017

#define PIXELS_PER_LINE 384
#define LINES_PER_FRAME 264

#pragma pack(push)
#pragma pack(1)
typedef struct {
   unsigned short int type;			// Magic 'BM'
   unsigned int size;				// File size
   unsigned short int reserved1, reserved2;
   unsigned int offset;				// Offset to image data
} header_t;
#pragma pack(pop)

typedef struct {
   unsigned int size;				// Header size
   int width, height;				// Width and height in px
   unsigned short int planes;
   unsigned short int bits;			// Bits per pixel
   unsigned int compression;
   unsigned int imagesize;
   int xresolution, yresolution;
   unsigned int ncolours;
   unsigned int importantcolors;
} infoheader_t;

header_t bmp_header = {
	0x4D42,		// "BM"
	0,			// Set later
	0,
	0x36
};

infoheader_t bmp_info = {
	sizeof(infoheader_t),
	PIXELS_PER_LINE, LINES_PER_FRAME,	// Dimensions
	1,
	24,
	0,
	0,			// Set later
	3780, 3780,
	0,
	0
};

unsigned int frame = 0;
unsigned long int pixels[LINES_PER_FRAME][PIXELS_PER_LINE];

void save_bitmap() {
	unsigned char filename[256];
	FILE * file_out;
	unsigned int wr_line, wr_pixel;
	unsigned char full_color[3];
	unsigned long int ng_color;
	unsigned int bmp_size;
	
	sprintf(filename, "frame%04u.bmp", frame);
	file_out = fopen(filename, "wb");
	fwrite(&bmp_header, 1, sizeof(bmp_header), file_out);
	fseek(file_out, 14, SEEK_SET);
	fwrite(&bmp_info, 1, sizeof(bmp_info), file_out);
	for (wr_line = 0; wr_line < LINES_PER_FRAME; wr_line++) {
		for (wr_pixel = 0; wr_pixel < PIXELS_PER_LINE; wr_pixel++) {
			ng_color = pixels[LINES_PER_FRAME - 1 - wr_line][wr_pixel];
			full_color[0] = (ng_color & 0x00007F) << 2;			// Blue
			full_color[1] = ((ng_color & 0x007F00) >> 8) << 2;	// Green
			full_color[2] = ((ng_color & 0x7F0000) >> 16) << 2;	// Red
			fwrite(&full_color, 1, sizeof(full_color), file_out);
		}
	}
	bmp_size = ftell(file_out);
	fseek(file_out, 2, SEEK_SET);
	fwrite(&bmp_size, 1, sizeof(bmp_size), file_out);
	fclose(file_out);
	
	// Fill with grey
	memset(pixels, 0x7F, 4 * LINES_PER_FRAME * PIXELS_PER_LINE);
}

int main(int argc, char *argv[]) {
	unsigned int line = 0;
	unsigned short int pixel;
	unsigned long int ng_color;
	char rd[5];
	FILE * file_in;
	int res;
	unsigned long int in_size;
	
	if (argc != 2) {
		puts("usage: log2frames input.txt\n");
		return 1;
	}
	
	file_in = fopen(argv[1], "r");
	
	fseek(file_in, 0, SEEK_END);
	in_size = ftell(file_in);
	rewind(file_in);
	
	for (;;) {
		res = fscanf(file_in, "%x ", &ng_color);
		if (!res) {
			// Not a color
			res = fread(rd, 1, 6, file_in);
			if (res != 6) {
				//printf("Couldn't read from input file !\n");
				printf("Saving partial frame (%u lines) - File position: %u\n", line, ftell(file_in));
				save_bitmap();
				break;
			} else {
				if (rd[0] == 'Y') {
					// End of raster line marker
					if (line < LINES_PER_FRAME - 1) {
						line++;
					} else {
						printf("Saving full frame - File position: %u\n", ftell(file_in));
						save_bitmap();
						frame++;
						line = 0;
					}
					pixel = 0;
				} else if ((rd[0] == 'x') || (rd[0] == 'X')) {
					// Undefined pixel: full green
					pixels[line][pixel++] = 0x00FF00;
				}
			}
		} else {
			// Normal color
			pixels[line][pixel++] = ng_color;
		}
		
		if (ftell(file_in) == in_size) {
			if (line) {
				printf("Saving partial frame (%u lines) - File position: %u\n", line, ftell(file_in));
				save_bitmap();
				break;
			}
			
			printf("Parsed %u bytes\n", ftell(file_in));
			break;
		}
	}
	
	fclose(file_in);

	return 0;
}
