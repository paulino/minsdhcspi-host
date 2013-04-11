--------------------------------------------------------------------------------
-- This file is part of the "Minimalistic SDHC HOST Reader"
-- It is distributed under GNU General Public License
-- See at http://www.gnu.org/licenses/gpl.html
-- Copyright (C) 2013 Paulino Ruiz de Clavijo Vázquez <paulino@dte.us.es>
-- You can get more info at http://www.dte.us.es/id2
--------------------------------------------------------------------------------
-- Date:    11-04-2013
-- Version: 1.1

--*--------------------------------- End auto header, don't touch this line -*--

-- Generic counter with parallel load
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity generic_paracont is

  generic ( width : integer );            
  
  port(
     clk   : in std_logic;
     reset : in std_logic;
     up    : in std_logic;
     load  : in std_logic;
     din   : in std_logic_vector(width-1 downto 0);
     dout  : out std_logic_vector(width-1 downto 0)
      );

end generic_paracont;

architecture Behavioral of generic_paracont is

signal count : unsigned(width-1 downto 0);

begin

dout <= std_logic_vector(count);

process (clk)
begin
   if rising_edge(clk) then
     if reset='1' then 
       count  <= (others => '0');
     elsif load = '1' then
       count <= unsigned(din);
     elsif up = '1' then
       count <= count +1;
     end if;
   end if;
end process;


end Behavioral;

