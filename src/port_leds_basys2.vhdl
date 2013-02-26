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
-------------------------------------------------------------------------------
-- This file is part of the Basys2 peripherals project
-- It is distributed under GNU General Public License
-- See at http://www.gnu.org/licenses/gpl.html 
-- Copyright (C) 2012 Paulino Ruiz de Clavijo Vázquez <paulino@dte.us.es>
-- You can get more info at http://www.dte.us.es/id2
--------------------------------------------------------------------------------
-- Date:     29-04-2012
-- Revision: 1
--*--------------------------------------------------------------------------*--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity port_leds_basys2 is
    Port ( clk      : in std_logic;
			  w        : in  STD_LOGIC;
			  enable   : in std_logic;
           port_in  : in  STD_LOGIC_VECTOR (7 downto 0);
           leds_out : out  STD_LOGIC_VECTOR (7 downto 0));
end port_leds_basys2;

architecture Behavioral of port_leds_basys2 is

signal mem : std_logic_vector (7 downto 0);

begin

write_proc: process (clk) 
begin
	if falling_edge(clk) and w='1' and enable='1' then
		mem <= port_in;
	end if;
end process;

leds_out <= mem;

end Behavioral;

