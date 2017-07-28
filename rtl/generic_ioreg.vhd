--------------------------------------------------------------------------------
-- This file is part of the "Minimalistic SDHC HOST Reader"
-- It is distributed under GNU General Public License
-- See at http://www.gnu.org/licenses/gpl.html
-- Copyright (C) 2013 Paulino Ruiz de Clavijo Vázquez <paulino@dte.us.es>
-- You can get more info at http://www.dte.us.es/id2
--------------------------------------------------------------------------------
-- Date:    31-04-2014
-- Version: 1.1

--*--------------------------------- End auto header, don't touch this line -*--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity generic_ioreg is
  
  generic ( width : integer );
  
  port(
     clk   : in std_logic;
     w     : in std_logic;
     din   : in std_logic_vector(width-1 downto 0);
     dout  : out std_logic_vector(width-1 downto 0)
      );
end entity;

architecture Behavioral of generic_ioreg is

signal mem : std_logic_vector(width-1 downto 0);

begin

dout <= mem;

process (clk)
begin
   if rising_edge(clk) then
     if w='1' then 
       mem  <= din;
     end if;
   end if;
end process;

end Behavioral;

