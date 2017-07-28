#!/usr/bin/python
help=""" This script converts a binary file into integers, byte by byte
It's necessary to use it due to VHDL textio problems in ISIM when dealing with binaries files
"""
import sys

COLS=16

if len(sys.argv) < 2 :
  print help;
  print "Usage: raw2int input_file"
  exit(255)

i=COLS
f = open(sys.argv[1], "rb")
try:
    byte = f.read(1)
    while byte != "":
        print "%3.3d " % ord(byte) ,
        byte = f.read(1)
        i=i-1
        if i<=0:
	  i=COLS
	  print ""
        
finally:
    f.close()  
