--------------------------------------------------------------------------------
-- This file is part of the "Minimalistic SDHC HOST Reader"
-- It is distributed under GNU General Public License
-- See at http://www.gnu.org/licenses/gpl.html
-- Copyright (C) 2013 Paulino Ruiz de Clavijo Vázquez <paulino@dte.us.es>
-- You can get more info at http://www.dte.us.es/id2
--------------------------------------------------------------------------------
-- Date:    26-02-2013
-- Version: 1.0-pre
--*--------------------------------- End auto header, don't touch this line -*--


-- This ROM contains 6 bytes SD CMD commands
-- Command must be read byte by byte out byte by byte

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity sdcmd_rom is
port (
      addr    : in std_logic_vector(4 downto 0);
      data_out: out std_logic_vector(7 downto 0));
end sdcmd_rom;

architecture async of sdcmd_rom is
    type rom_type is array (0 to 6*5-1) of std_logic_vector (7 downto 0);                
    signal rom : rom_type:= (
      X"40",X"00",X"00",X"00",X"00",X"95", -- CMD0, response expected 0x01
      X"48",X"00",X"00",X"01",X"AA",X"87", -- CMD8, response expected 0x01
      X"77",X"00",X"00",X"00",X"00",X"00", -- CMD55 , crc is ignored , 
      X"69",X"40",X"00",X"00",X"00",X"00", -- ACMD41, crc ignored, res expected 0x00 (bit idle cleared)
														               --         0x4140000000XX (40 => HCS=1 only SDHC supported)
      X"4C",X"00",X"00",X"00",X"00",X"00"  -- CMD12 Used to abort read procress
      );                        
      
    
begin

    data_out <= rom(conv_integer(addr));

end async;

				