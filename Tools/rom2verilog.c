#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// This tool converts binary dumps (ROMs, RAM snaps...) to files which can be loaded with verilog $readmemh's
// Part of the NeoGeo FPGA project
// Last mod: furrtek 07/2017

unsigned char nibble_dec(unsigned char nibble) {
	if (nibble > 9) nibble += 7;
	return nibble + 0x30;
}

int main(int argc, char *argv[]) {
    FILE * in_file, * out_file_lower, * out_file_upper;
    unsigned long c, in_size, i, j;
    unsigned int mode;
    unsigned char ch;
    unsigned char * in_data;
	unsigned char * out_data_lower, * out_data_upper;
	unsigned char file_stem[256];
	unsigned char file_name[256];
	
	if (argc != 3) {
		puts("usage: rom2verilog [byte/word/half] input.bin\n");
		return 1;
	}
    
    in_file = fopen(argv[2], "rb");
    fseek(in_file, 0, SEEK_END);
	in_size = ftell(in_file);
	
    strcpy(file_stem, argv[2]);
    *strrchr(file_stem, '.') = 0;		// Doesn't seem very safe
    
    if (!strcmp(argv[1], "byte")) {
    	mode = 0;
    	strcpy(file_name, file_stem);
    	strcat(file_name, "_8.txt");
    	out_file_lower = fopen(file_name, "wb");				// One file
		out_data_lower = (unsigned char *)malloc(in_size * 3);	// Bytes
    } else if (!strcmp(argv[1], "word")) {
    	mode = 1;
    	strcpy(file_name, file_stem);
    	strcat(file_name, "_16.txt");
    	out_file_lower = fopen(file_name, "wb");				// One file
		out_data_lower = (unsigned char *)malloc(in_size * 5);	// Words
    } else if (!strcmp(argv[1], "half")) {
    	mode = 2;
    	strcpy(file_name, file_stem);
    	strcat(file_name, "_L.txt");
	    out_file_lower = fopen(file_name, "wb");				// L/U files
    	strcpy(file_name, file_stem);
    	strcat(file_name, "_U.txt");
	    out_file_upper = fopen(file_name, "wb");
		out_data_lower = (unsigned char *)malloc(in_size * 3);	// Bytes
		out_data_upper = (unsigned char *)malloc(in_size * 3);	// Bytes
	}
	
	//outdata = (unsigned char *)malloc(in_size * 3);		// Bytes
	//outdata = (unsigned char *)malloc(in_size * 4);		// Bytes COE
	
	in_data = (unsigned char *)malloc(in_size);

    fseek(in_file, 0, SEEK_SET);
    fread(in_data, 1, in_size, in_file);
    fclose(in_file);
    
    i = 0;
    j = 0;
	if (mode == 0) {
		// Bytes
	    for (c = 0; c < in_size; c++) {
			ch = in_data[c];
			out_data_lower[i++] = nibble_dec(ch >> 4);
	    	out_data_lower[i++] = nibble_dec(ch & 15);
	    	//outdata[i++] = ',';			// COE
	    	out_data_lower[i++] = 0x0A;		// Line feed
		}
		fwrite(out_data_lower, 1, in_size * 3, out_file_lower);
	    fclose(out_file_lower);
	    free(out_data_lower);
	} else if (mode == 1) {
	    // Words
	    for (c = 0; c < in_size; c += 2) {
			ch = in_data[c];
			out_data_lower[i++] = nibble_dec(ch >> 4);
	    	out_data_lower[i++] = nibble_dec(ch & 15);
			ch = in_data[c + 1];
			out_data_lower[i++] = nibble_dec(ch >> 4);
	    	out_data_lower[i++] = nibble_dec(ch & 15);
	    	out_data_lower[i++] = 0x0A;		// Line feed
		}
		fwrite(out_data_lower, 1, in_size * 5, out_file_lower);
	    fclose(out_file_lower);
	    free(out_data_lower);
	} else if (mode == 2) {
		// L/U
	    for (c = 0; c < in_size; c += 2) {
			ch = in_data[c];
			out_data_lower[i++] = nibble_dec(ch >> 4);
	    	out_data_lower[i++] = nibble_dec(ch & 15);
	    	out_data_lower[i++] = 0x0A;		// Line feed
			ch = in_data[c+1];
			out_data_upper[j++] = nibble_dec(ch >> 4);
	    	out_data_upper[j++] = nibble_dec(ch & 15);
	    	out_data_upper[j++] = 0x0A;		// Line feed
		}
		fwrite(out_data_lower, 1, in_size * 3, out_file_lower);
		fwrite(out_data_upper, 1, in_size * 3, out_file_upper);
	    fclose(out_file_lower);
	    fclose(out_file_upper);
	    free(out_data_lower);
	    free(out_data_upper);
	}
	
	//fwrite(outdata, 1, sz * 3, out_file_lower);		// Bytes
	//fwrite(outdata, 1, sz * 4, out_file_lower);		// Bytes COE

	free(in_data);
	
    return 0;  
}
