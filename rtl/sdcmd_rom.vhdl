--------------------------------------------------------------------------------
-- This file is part of the 'Minimalistic SDHC Host Reader'
-- Copyright (C) 2016 Paulino Ruiz-de-Clavijo Vázquez <paulino@dte.us.es>
-- Licensed under the Apache License 2.0, you may obtain a copy of 
-- the License at https://www.apache.org/licenses/LICENSE-2.0
--
-- You can get more info at https://github.com/paulino/minsdhcspi-host
--------------------------------------------------------------------------------
-- Date:    28-07-2017
-- Version: 1.1
--*--------------------------------- End auto header, don't touch this line -*--


-- This ROM contains 6 bytes SD CMD commands
-- Command must be read byte by byte out byte by byte

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdcmd_rom is
port (
      addr    : in std_logic_vector(4 downto 0);
      data_out: out std_logic_vector(7 downto 0));
end sdcmd_rom;

architecture async of sdcmd_rom is
    type rom_type is array (0 to 6*4-1) of std_logic_vector (7 downto 0);                
    signal rom : rom_type:= (
      X"40",X"00",X"00",X"00",X"00",X"95", -- CMD0, response expected 0x01
      X"48",X"00",X"00",X"01",X"AA",X"87", -- CMD8, response expected 0x01
      X"77",X"00",X"00",X"00",X"00",X"00", -- CMD55 , crc is ignored , 
      X"69",X"40",X"00",X"00",X"00",X"00"  -- ACMD41, crc ignored, res expected 0x00 (bit idle cleared)
														               --         0x4140000000XX (40 => HCS=1 only SDHC supported)
      --X"4C",X"00",X"00",X"00",X"00",X"00"  -- CMD12 Used to abort read procress
      );                        
      
    
begin

    data_out <= rom(to_integer(unsigned(addr)));

end async;

				