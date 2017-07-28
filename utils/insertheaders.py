#!/usr/bin/python
#
# Small text processor to insert headers license and revision
# 
# Command line usage: insertheaders.py [options] config_file
#  Valid options:
#   -n   Run in dry mode, not touch anything
#   -v   Increase verbosity
# 
# Written by Paulino Ruiz de Clavijo Vazquez <paulino@dte.us.es>
#
# Changes v6:
#  - File time stamp kept after header insert


VERSION = 6 # Used to track changes

from datetime import datetime
import os,sys
import fnmatch

CONFIGFILE="insertheaders.conf"
DRYMODE=False
VERBOSE=0

if not 'EXCLUDES' in globals():
  EXCLUDES=()

# Command line parser
if len(sys.argv) > 1:
  for param in sys.argv[1:]:
    if param[0] == '-' :
      if param[1] == 'n':
        DRYMODE=True;
        print "Running script drymode, any file will be modified!"
      elif param[1] == 'v':
        VERBOSE=VERBOSE+1
      else:
        print >> sys.stderr, "** Error: only -n and -v options are allowed in command line"
        exit(255)
    else:
      CONFIGFILE=param
      
      
#utils
def print_verbose(level,string):
  global VERBOSE
  if VERBOSE >= level:
    print string
    
# Reading config file
step=1
print_verbose(1, "%d. Read config file %s" % (step,CONFIGFILE))
lines=""
try:
  f=file(CONFIGFILE)
  lines=f.read()
  f.close()
except:
  print >> sys.stderr , "** Error: Configuration file '%s' not found " % CONFIGFILE
  exit(255)
try:
  exec(lines)
except  Exception as e:
  print >> sys.stderr , "** Error: Configuration file '%s' has errors:  " % CONFIGFILE , e
  exit(255)
del lines

#Check basedir to add a end slash
if len(BASEDIR) > 0 and BASEDIR[len(BASEDIR)-1] != '/':
	BASEDIR=BASEDIR+"/"


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
    if VERBOSE > 0: print new_line,
    res=res + (new_line,)
  if VERBOSE > 0: print ""
  return res

def process_file(header,header_delimiter,file_in,file_out):
  """ return True if file has been changed """  
  header_pos=-1;
  file_stat = os.stat(file_in)
  f=file(file_in)
  lines=f.readlines()
  f.close()
  header_match=True
  # Locate Header Delimiter
  for i in range(len(lines)):
    pos=lines[i].find(header_delimiter)
    if pos == 0 and header_pos >=0:
       print >> sys.stderr , "*** Error: Double header delimiter found at line %d and line %d in file %s" % (header_pos,i,file_in)
       return False;
    elif pos == 0 :
      header_pos=i
      print_verbose(1,  " - Found header delimiter at line %d" % i)
    elif header_match and i < len(header):
       header_match = lines[i].rstrip('\n') == header[i].rstrip('\n')

      
  # Replace header in file
  if header_pos == -1:
    print_verbose(1, " - Header not found, inserting new header")
    header_pos=0;
  else:
    header_pos=header_pos+1
  
  if header_match:
    if VERBOSE==0: print "Not changed\t" , file_in
    return False
  if header_pos == 0:
    if VERBOSE==0: print "Added\t\t" , file_in
  else:
    if VERBOSE==0: print "Updated\t\t" , file_in
  f=open(file_out,"w")
  # Writing new header"
  for line in header:
    f.write(line)
  f.write(header_delimiter+"\n"); # Writing delimiter
  # Writing body
  for line in range(header_pos,len(lines)):
     f.write(lines[line])
  f.close()
  os.utime(file_out,(file_stat.st_atime,file_stat.st_mtime))
  return True


def find_files(base_path,pattern):
    """ Find files in recursive mode"""
    res=()
    print_verbose(2,"\t> Recursive search: Base path = %s, pattern = %s" %(base_path,pattern))
    for root, dirs, files in os.walk(base_path, topdown=True):
        for f_name in fnmatch.filter(files, pattern):
          res= res + (os.path.join(root, f_name),)
    return res;
    

""" Start process """


step=step+1
print_verbose(1,  "%d. Read tpl file" % step)
header_lines=process_tpl_file(REPLACES,TPLFILEIN)


step=step+1
print_verbose(1,  "%d. Building files list" % step)

full_list=()
for f in FILES:
  if f.find("*") >= 0:
    dir_name=os.path.dirname(BASEDIR+f)
    pattern=os.path.basename(BASEDIR+f)
    sub_list= find_files(dir_name,pattern)
    full_list = full_list + sub_list
    print_verbose(2,"\t> Files for pattern %s:%s" %(f,sub_list))
  else:
    full_list = full_list + (f,)

print_verbose(2,"\t> Full list of files: %s" % str(full_list))

for f in full_list:
  step=step+1
  if f in EXCLUDES:
    print_verbose(1, "%d. Excluding file %s" % (step,f))
    continue
  
  print_verbose(1, "%d. Process file %s" % (step,f))
  if DRYMODE:
    continue
  
  file_changed=process_file(header_lines,HEADERDELIMITER,f,f+".tmp")
  if file_changed:
    os.rename(f,f+"~")
    print_verbose(1,  " - Backup file at %s" % (f+"~"))
    os.rename(f+".tmp",f)

step=step+1    
print_verbose(1, "%d. Script finished" % step)

