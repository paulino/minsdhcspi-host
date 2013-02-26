Minimalistic SDHC HOST reader (in SPI mode)
===========================================

Detailed information can be found in doc directory

Some notes:

 - Tested on Digilent basys2 board with pmod SD
 - SD Cards tested: kingstom, lexmark
 - Only SDHC cards are supported
 
Files and modules:

- sdspihost.vhdl: top module
- test1_basys2.vhdl: test for basys2 board

How to use sdspihost:

  After reset, busy signal is asserted during SD initialization. If SD is not detected or the initialization file ERR signal is asserted. When initialization has success, the BUSY signal and ERR signal are deasserted and SDHOST and SDHOST is in idle state.
  
  The read process is carry out selecting block number in BLOCK_ADDR input and sending one pulse on R_BLOCK signal. The BLOCK_ADDR value must be hold while BUSY signal is asserted. When BUSY signal is deasserted the bytes can be read. Each byte is gotten sending a pulse in R_BYTE signal and waiting for BUSY signal is deassert. Be carefull of not read more of 512 Bytes in each block.
  
  The block read process can be aborted in any byte by requiring new block, with a pulse is R_BLOCK signal, current read process is aborted. See deails about reading process below.

Notes about SD CMD commands:

  This implementation uses minimal CMD commands. 
  CMD12 is not implemented, the read process is aborted waiting for all bytes in block
  



 
 

