#!/usr/bin/python
#
# Small text processor to insert headers license and revision
#
# Command line options:
# - n   Run in dry mode, not touch anything
# 
# Written by Paulino Ruiz de Clavijo Vazquez <paulino@dte.us.es>

from datetime import datetime
import os,sys
import fnmatch

ConfigFile="insertheaders.conf"
DryMode=False;

#Options
if len(sys.argv) > 2:
  print >> sys.stderr, "***Error: only -n option allowed in command line"
  exit(255)
elif len(sys.argv)==2:
  if sys.argv[1]=="-n": # Run in dry mode
    DryMode=True;
    print "Running script drymode, any file will be modified!"
  else:
    print >> sys.stderr, "***Error: only -n option allowed in command line"
    exit(255)
    
# Reading config file
step=1
print "%d. Read config file %s" % (step,ConfigFile)
lines=""
try:
  f=file(ConfigFile)
  lines=f.read()
  f.close()
except:
  print >> sys.stderr , "***Error: Configuration file %s not found: " % config
  exit(255)
exec(lines)
del lines


def process_tpl_file(replaces,tpl_file):
  """ returns lines processed"""
  res=()
  f=file(tpl_file)
  lines=f.readlines()
  f.close();
  for l in lines:
    new_line=l
    for v in replaces.keys():
       new_line=new_line.replace(v,str(replaces[v]))
    print new_line,
    res=res + (new_line,)
  print ""
  return res

def process_file(header,header_delimiter,file_in,file_out):
  """ return true on sucess """  
  header_pos=-1;
  f=file(file_in)
  lines=f.readlines()
  f.close()
  # Locate Header Delimiter
  for i in range(len(lines)):
    pos=lines[i].find(header_delimiter)
    if pos == 0 and header_pos >=0:
       print >> sys.stderr , "*** Error: Double header delimiter found at line %d and line %d in file %s" % (header_pos,i,file_in)
       return False;
    elif pos == 0 :
      header_pos=i
      print " - Found header delimiter at line %d" % i
  # Replace header in file
  if header_pos == -1:
    print " - Header not found, inserting new header"
    header_pos=0;
  else:
    header_pos=header_pos+1
  
  f=open(file_out,"w")
  print " - Writing new header"
  for line in header:
    f.write(line)
  f.write(header_delimiter); # Writing delimiter
  f.write("\n")
  print " - Writing body"
  for line in range(header_pos,len(lines)):
     f.write(lines[line])
  f.close()
  return True


def find_files(base_path,pattern):
    """ Find files in recursive mode"""
    res=()
    for root, dirs, files in os.walk(base_path, topdown=True):
        for f_name in fnmatch.filter(files, pattern):
          res= res + (os.path.join(root, f_name),)
    return res;
    

""" Start process """


step=step+1
print "%d. Read tpl file" % step
header_lines=process_tpl_file(Replaces,TplFileIn)


step=step+1
print "%d. Building files list" % step

full_list=()
for f in Files:
  if f.find("*"):
    dir_name=os.path.dirname(f)
    pattern=os.path.basename(f)
    full_list = full_list + find_files(dir_name,pattern)
  else:
    full_list = full_list + (f,)
  

for f in full_list:
  step=step+1
  if f in Excludes:
    print "%d. Excluding file %s" % (step,f)
    continue
  
  print "%d. Process file %s" % (step,f)
  if DryMode:
    continue
  
  res=process_file(header_lines,HeaderDelimiter,f,f+".tmp")
  if res:
    os.rename(f,f+"~")
    print " - Backup file at %s" % (f+"~")
    os.rename(f+".tmp",f)
  else:
    print >> sys.stderr , "** Error processing file %s" % f
step=step+1    
print "%d. Script finished" % step



