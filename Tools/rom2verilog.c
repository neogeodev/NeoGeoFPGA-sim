#include <stdio.h>
#include <string.h>
#include <stdlib.h>

unsigned char hexi(unsigned char ind) {
	if (ind > 9) ind += 7;
	return ind + 0x30;
}

int main(int argc, char *argv[]) {
    FILE *inf, *outf, *outfl, *outfu;
    unsigned long c, sz, i, j;
    unsigned char ch;
    unsigned char * indata;
	unsigned char * outdata, * outdatal, * outdatau;

    inf = fopen(argv[1], "rb");
    
    outf = fopen("out.txt", "wb");		// One file
    //outfl = fopen("outl.txt", "wb");		// L/U files
    //outfu = fopen("outu.txt", "wb");		// L/U files

    fseek(inf, 0, SEEK_END);
	sz = ftell(inf);
	
	indata = (unsigned char *)malloc(sz);
	//outdata = (unsigned char *)malloc(sz * 5);		// Words
	outdata = (unsigned char *)malloc(sz * 3);		// Bytes
	//outdatal = (unsigned char *)malloc(sz * 3);		// L/U
	//outdatau = (unsigned char *)malloc(sz * 3);		// L/U

    fseek(inf, 0, SEEK_SET);
    fread(indata, 1, sz, inf);
    fclose(inf);
    
    i = 0;
    j = 0;
    // Words
    /*for (c = 0; c < sz; c += 2) {
		ch = indata[c];
		outdata[i++] = hexi(ch >> 4);
    	outdata[i++] = hexi(ch & 15);
		ch = indata[c+1];
		outdata[i++] = hexi(ch >> 4);
    	outdata[i++] = hexi(ch & 15);
    	outdata[i++] = 0x0A;
	}*/
	// Bytes
    for (c = 0; c < sz; c++) {
		ch = indata[c];
		outdata[i++] = hexi(ch >> 4);
    	outdata[i++] = hexi(ch & 15);
    	outdata[i++] = 0x0A;
	}
	// L/U
    /*for (c = 0; c < sz; c += 2) {
		ch = indata[c];
		outdatau[i++] = hexi(ch >> 4);
    	outdatau[i++] = hexi(ch & 15);
    	outdatau[i++] = 0x0A;
		ch = indata[c+1];
		outdatal[j++] = hexi(ch >> 4);
    	outdatal[j++] = hexi(ch & 15);
    	outdatal[j++] = 0x0A;
	}*/
	
	//fwrite(outdata, 1, sz * 5, outf);		// Words
	fwrite(outdata, 1, sz * 3, outf);		// Bytes
	
	//fwrite(outdatal, 1, sz * 3, outfl);		// L/U
	//fwrite(outdatau, 1, sz * 3, outfu);		// L/U
	
    fclose(outf);
    //fclose(outfl);
    //fclose(outfu);
    free(indata);
    free(outdata);

    return 0;  
}
