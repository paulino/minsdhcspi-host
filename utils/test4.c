/**
 * 
 * SDCARD: Data 512Bytes CRC is is the ITU-T V.41 16 bit CRC with polynomial 0x1021
 * */

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/fs.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include "xor.c" // Ugly ...

static const char *info="test4 for sdspi reader\n"\
"\tReads N blocks of 512 bytes doing XOR byt by byte";

int main(int argv,char *args[])
{
	int fd=-1,i,end,res;
	if(argv!=3)
	{
		printf("Usage: xor DEVICE BLOCKS\n");
		return 255;
	}
	else
	{
		 fd=open_dev(args[1]);
	}
	
	if(fd>=0)
	{
		end=atoi(args[2]);
		printf(" - Processing %d blocks of 512 bytes\n",end);
		res=xor(fd,end << 9);
		printf(" - XOR of %d blocks [range 0-%x]: 0x%2.2X\n",end,end-1,res);
	}
	
}

