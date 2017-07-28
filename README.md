# Minimalistic SDHC Host Reader (SPI mode)

Minimalistic SDHC HOST reader is an SD host controller useful for bootloaders 
operations. It implements the SD card protocol in a Finite States Machine 
written in VHDL. No additional microcontroller/software is required to read data 
from the SD card. This module can be used as a peripheral for some 
microcontroller or used alone to read raw data from an SD card.

Additional documentation can be found at doc directory in 
[minsdhcspi-host.pdf](doc/minsdhcspi-host.pdf) document. Also, the 
`examples` directory contains demos for some prototype boards based
in Xilinx FPGAs devices.


## Features and limitations
 
* Only SDHC cards are supported
* Four SPI speeds are supported: 25MHz, 12MHz, 780KHz and 97KHz
* A Picoblaze-3 interface is available

## Download

    git clone https://github.com/paulino/minsdhcspi-host

The examples require an external repository with a set of peripherals for
Digilent Inc. Boards, be sure you clone the repository including all submodules
with the command

    git clone --recursive https://github.com/paulino/minsdhcspi-host

## Demos

The examples directory contains some projects for Xilinx ISE and Vivado and them
have been tested in Spartan3 and Virtex7 FPGAs. The tests run at Digilent Inc.
prototype boards. 

See [examples/README.md](examples/README.md) for more info.


## About SPI speed

SD card initialization runs at ~80KHz, after the initialization success SPI
speed changes to a pre-programmed speed in the source code. This part is not 
finished in this version and the read speed is set to 12MHz by default. Anyway
it can be changed at file `rtl/sdcmd.vhdl` in the state
`ST_INIT_1` about line 181:

```vhdl
spi_data_in(3 downto 0) <= "0010";  -- set SPI clock speed to CLK/4 = 12MHz
```

Valid values are: 

Value|Div      | Frec. 
-----|-------- |:------
1000 | clk/2   |  25MHz
0100 | clk/4   |  12MHz
0010 | clk/64  | 780KHz
0001 | clk/512 |  97KHz

This will be improved in future versions.

## Picoblaze interface

This core can be added easely to Picoblaze microcontroller as a peripheral. 
The file `rtl/if_picoblaze.vhdl` has glue logic for Picoblaze.

Detailed info about this is at doc directory.

## Simulation alternative architecture

At directory `bench` there is a simulation architecture for the top module
in the file `sdspihost_sim.vhd`.

To use this architecture the SD card raw data must be converted to a 16 columns 
text file format. A script to do it is suplied in scripts directory and the next 
commands show how to use it

    $ dd if=/dev/sdX of=sdcard.raw bs=1024 count=200
    $ ./raw2int.py sdcard.raw > sdcard.txt

The script `raw2int.py` converts binary data to a integer sequence of numbers 
in text mode. It is necessary to use it due detected problems while reading
binary files directly from VHDL code with ISIM.

The file `sdcard.txt` is used in SDHOST simulation architecture as data source.
Be carefully with size of this file!

## Authors

This module is published and maintained by Paulino Ruiz-de-Clavijo Vázquez 
<<paulino@dte.us.es>>, Departamento de Tecnología Electrónica, 
Universidad de Sevilla.

If you use the module we are grateful, and you can use the following 
biblatex entries to cite us:

```bibtex
# BibLaTex entries
@online{minsdhcspi-host,
  title={{Minimalistic SDHC HOST reader}},
  author={Paulino Ruiz-de-Clavijo},
  organization={{Dpto. Tecnología Electrónica, Universidad de Sevilla}},
  year={2017},
  url={https://github.com/paulino/sdspihost},
  urldate={2017-04-19}
}

@article{ruiz2017,
  title = "Minimalistic SDHC-SPI hardware reader module for boot loader applications ",
  journal = "Microelectronics Journal ",
  volume = "67",
  pages = "32 - 37",
  year = "2017",
  issn = "0026-2692",
  doi = "https://doi.org/10.1016/j.mejo.2017.07.007",
  url = "http://www.sciencedirect.com/science/article/pii/S0026269216305183",
  author = "Paulino Ruiz-de-Clavijo and Enrique Ostúa and Manuel-J. Bellido and Jorge Juan and Julián Viejo and David Guerrero",

}
```
