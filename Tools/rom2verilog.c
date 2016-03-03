#include <stdio.h>
#include <string.h>
#include <stdlib.h>

unsigned char hexi(unsigned char ind) {
	if (ind > 9) ind += 7;
	return ind + 0x30;
}

int main(int argc, char *argv[]) {
    FILE *inf, *outf;
    unsigned long c, sz, i;
    unsigned char ch;
    unsigned char * indata;
	unsigned char * outdata;

    inf = fopen(argv[1],"rb");
    outf = fopen("out.txt","wb");

    fseek(inf, 0, SEEK_END);
	sz = ftell(inf);
	
	indata = (unsigned char *)malloc(sz);
	//outdata = (unsigned char *)malloc(sz * 5);
	outdata = (unsigned char *)malloc(sz * 3);

    fseek(inf, 0, SEEK_SET);
    fread(indata, 1, sz, inf);
    fclose(inf);
    
    i = 0;
    /*for (c = 0; c < sz; c += 2) {
		ch = indata[c];
		outdata[i++] = hexi(ch >> 4);
    	outdata[i++] = hexi(ch & 15);
		ch = indata[c+1];
		outdata[i++] = hexi(ch >> 4);
    	outdata[i++] = hexi(ch & 15);
    	outdata[i++] = 0x0A;
	}*/
    for (c = 0; c < sz; c++) {
		ch = indata[c];
		outdata[i++] = hexi(ch >> 4);
    	outdata[i++] = hexi(ch & 15);
    	outdata[i++] = 0x0A;
	}
	
	//fwrite(outdata, 1, sz * 5, outf);
	fwrite(outdata, 1, sz * 3, outf);
	
    fclose(outf);
    free(indata);
    free(outdata);

    return 0;  
}
