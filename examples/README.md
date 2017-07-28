# Examples for Minimalistic SDHC-SPI Host Reader

Examples to run some tests/demos into several [Digilent FPGA Boards](https://www.digilentinc.com):

* [Basys2](https://reference.digilentinc.com/reference/programmable-logic/basys-2/start) and [Nexys 2](https://reference.digilentinc.com/reference/programmable-logic/nexys-2/start) using Xilinx ISE.
* [Nexys4](https://reference.digilentinc.com/reference/programmable-logic/nexys-4/start) using Vivado.

Basys2 and Nexys2 don't include an SD slot into the board. An SD card can be 
connected using the [Pmod SD](https://reference.digilentinc.com/reference/pmod/pmodsd/start)
The connection with PmodSD may be done as is shown in 
[basys2-PmodSD image](./basys2-pmodsd.jpg), due an existents 
errors in the pinout of this product.

For Nexys2 the connections are:

* SS  → JA1
* MOSI → JA2
* MISO → JA3
* SCLK → JA4


## Test 1

This demo reads the first byte of a block and display it in the LSB display
(hexadecimal format). The button 3 gets the next byte of the current block of
the SD card. The SD card block number to be read is selected in the switches 
and the button 2 starts a new read operation at the block selected. The 
current block number is showed in MSB display.

The demo is available for:

* ISE (v14.7) project for Basys 2 at directory `test1-ise`
* ISE (v14.7) project for Nexys 2 at directory `test1-ise`
* Vivado (v16.4) project for Nexys 4 at directory `test1-vivado`. 

Controls in Basys2 and Nexys2:

* BTN0 is global reset
* BTN2 start to read new block, (block-no is selected using the switches)
* BTN3 is to read byte by byte
* SWITCHES select the SD card block to be read

Controls in Nexys4:

* BTNC  is global reset
* BTNL  start to read new block, (block-no is selected using the switches)
* BTNR  is to read byte by byte
* SWITCHES select the SD card block to be read

LEDS (for all boards): 

* LED0: *sdhost_busy* signal
* LED1: *sdhost_err* signal
* LED7: ON when test FSM is at ERROR state, initialization/read error

## Test 3

This test reads one block (512 bytes) and computes XOR of all bytes read. It starts at block number 0 and using BTN3  reads and process the next block. The 
display shows following data:

* MSB displays the number of block read
* LSB displays parity of the 512-byte block (XOR)

The test runs in Basys2 board using the SD PMOD connected
at JB port. Before run the test you can fill the SD card with some random data
and check results displayed using the `test3.c` available in `utils` dir.
The test is at directory `test3-basys2` for ISE v14.7.

Board controls:

* BTN0 is global reset
* BTN3 is used to read and process the next block

LEDS:

* LED0: *sdhost_busy* signal
* LED1: *sdhost_err* signal
* LED6: loop indicator
* LED7: ON when test FSM is in ERROR state

## Test 4

This test reads one block (512 bytes) and computes XOR of all read bytes,
the constant BLOCK_END is the last block and it can be changed in the source 
code. To verify the results the `utils/test4.c` can be used.

The test is at directory `test4-basys2` for ISE v14.7 and runs in Basys2 board.

Board controls:

* BTN0 is global reset
* BTN3 is used to read next block

LEDS: 

* LED0: *sdhost_busy* signal
* LED1: *sdhost_err* signal
* LED6: Loop flag
* LED7: ON when test FSM is in ERROR state

