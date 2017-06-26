#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <unistd.h>

typedef struct {
   unsigned short int type;                 /* Magic identifier            */
   unsigned int size;                       /* File size in bytes          */
   unsigned short int reserved1, reserved2;
   unsigned int offset;                     /* Offset to image data, bytes */
} header_t;

typedef struct {
   unsigned int size;               /* Header size in bytes      */
   int width, height;                /* Width and height of image */
   unsigned short int planes;       /* Number of colour planes   */
   unsigned short int bits;         /* Bits per pixel            */
   unsigned int compression;        /* Compression type          */
   unsigned int imagesize;          /* Image size in bytes       */
   int xresolution, yresolution;    /* Pixels per meter          */
   unsigned int ncolours;           /* Number of colours         */
   unsigned int importantcolors;   	/* Important colours         */
} infoheader_t;

#pragma pack(push)
#pragma pack(1)
header_t bmp_header = {
	0x4D42,		// "BM"
	0,			// Set later
	0,
	0x36
};
#pragma pack(pop)

infoheader_t bmp_info = {
	sizeof(infoheader_t),
	384, 264,
	1,
	24,
	0,
	0,			// Set later
	3780, 3780,
	0,
	0
};

int main(int argc, char *argv[]) {
	unsigned int frame = 0, line = 0;
	unsigned short int raster_lines[264][385];
	char rd[5];
	FILE * f;
	FILE * fout;

	int res;
	unsigned long int fsize;
	unsigned short int ng_color, pixel;
	unsigned int bmp_size;
	unsigned char full_color[3];
	
	unsigned int wr_line, wr_pixel;
	
	f = fopen("C:\\Users\\furrtek\\Documents\\Electro\\Neosim\\video_output.txt", "r");
	
	fseek(f, 0, SEEK_END);
	fsize = ftell(f);
	rewind(f);
	
	for (;;) {
		res = fscanf(f, "%x ", &ng_color);
		if (!res) {
			// Not a color
			res = fread(rd, 1, 5, f);
			if (res != 5) {
				// Couldn't read from file
				printf("Error !\n");
				break;
			} else {
				if (rd[0] == 'Y') {
					// End of raster line marker
					line++;
					if (line == 264) {
						printf("Pixels: %u - Frame %u - File position: %u\n", pixel, frame, ftell(f));
						
						// Save bitmap
						fout = fopen("C:\\Users\\furrtek\\Documents\\Electro\\Neosim\\output.bmp", "wb");
						fwrite(&bmp_header, 1, sizeof(bmp_header), fout);
						fseek(fout, 14, SEEK_SET);
						fwrite(&bmp_info, 1, sizeof(bmp_info), fout);
						for (wr_line = 0; wr_line < 264; wr_line++) {
							for (wr_pixel = 0; wr_pixel < 384; wr_pixel++) {
								ng_color = raster_lines[263 - wr_line][wr_pixel];
								full_color[0] = (ng_color & 0x000F) << 4;	// Blue
								full_color[1] = (ng_color & 0x00F0);		// Green
								full_color[2] = (ng_color & 0x0F00) >> 4;	// Red
								fwrite(&full_color, 1, sizeof(full_color), fout);
								
							}
						}
						bmp_size = ftell(fout);
						fseek(fout, 2, SEEK_SET);
						fwrite(&bmp_size, 1, sizeof(bmp_size), fout);
						fseek(fout, 10, SEEK_SET);
						ng_color = 0x36;
						fwrite(&ng_color, 1, sizeof(ng_color), fout);
						fclose(fout);
						
						frame++;
						line = 0;
					}
					pixel = 0;
				} else if (rd[0] == 'x') {
					// Undefined pixel: full green
					raster_lines[line][pixel++] = 0x20F0;
				}
			}
		} else {
			raster_lines[line][pixel++] = ng_color;
		}
		
		if (ftell(f) == fsize) {
			printf("Parsed %u bytes\n", ftell(f));
			break;
		}
	}
	
	fclose(f);

	return 0;
}
