/* Simple XOR routine
 *  
 * 
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


/** 
 * @return fd or -1 on fail
 * */
int open_dev(char *dev)
{
	uint64_t size;
	int fd=open(dev,O_RDONLY);
	int err=0;
	unsigned char buf[512],res;
	int i1,i2;
	struct stat file_info;

	printf("Reading device %s\n",dev);

	// Is it a block device or regular a file?
	
	if (fd==-1)
	{
		fprintf(stderr,"** Error device open failed: %s\n",strerror(errno));
	}

	if(fd >= 0 && fstat(fd, &file_info) < 0)
	{
		fprintf(stderr,"** Error cannot get info for device/file using fstat(): %s\n",strerror(errno));
		err=1;
	}

	if(fd >= 0 && err == 0)
	{
		if (S_ISREG(file_info.st_mode))
		{ // Regular file
			size = file_info.st_size;
			printf(" - Regular file size: %ldMiB\n",size/(1024*1024));
		}
		else if(S_ISBLK(file_info.st_mode)) // Block device
		{
			if (ioctl(fd,BLKGETSIZE64,&size)==-1) {
			fprintf(stderr,"**Error cannot get device size: %s\n",strerror(errno));
			err=1;
			}
			printf(" - Block device size: %ldMiB\n",size/(1024*1024));
		}
		else
		{
			fprintf(stderr,"**Error: Only can work over block device or regular file %s\n",strerror(errno));
			err=1;
		}
	}
	if(err==1)
	{
		close(fd);
		fd=-1;
	}
	return fd;
}


/** 
 * @return XOR of bytes  
 * @param len bytes to process
 */

unsigned char xor(int fd,int len)
{
	unsigned char res=0;
	int i;
	unsigned char buf[4096]; // Unix page size
	int bytes_left=len,read_size;
	while (bytes_left > 0)
	{
		if(bytes_left>4096)
		{
			read_size=4096;
			bytes_left-=4096;
		} 
		else
		{
			read_size=bytes_left;
			bytes_left=0;
		}
		if(read(fd,buf,read_size)!=read_size)
		{
			fprintf(stderr,"**Error reading %d bytes: %s\n",read_size,strerror(errno));
			return res;
		}
		for(i=0;i<read_size;i++)
		{
			res=res ^ buf[i];
		}

	}
	return res;
}
// ITU-T V.41 16 bit CRC



