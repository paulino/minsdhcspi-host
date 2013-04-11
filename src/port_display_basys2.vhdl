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
use IEEE.numeric_std.all;



entity port_display_basys2 is
    Port ( clk : in  STD_LOGIC;
     enable : in std_logic;
           digit_in : in  STD_LOGIC_VECTOR (7 downto 0);
           w_msb : in  STD_LOGIC;
           w_lsb : in  STD_LOGIC;
           seg_out : out  STD_LOGIC_VECTOR (6 downto 0);
           dp_out : out  STD_LOGIC;
           an_out : out  STD_LOGIC_VECTOR (3 downto 0));
end port_display_basys2;


architecture Behavioral of port_display_basys2 is

signal counter : unsigned (23 downto 0);
signal counter4: unsigned (1 downto 0);

signal digit_lsb : std_logic_vector (7 downto 0);
signal digit_msb : std_logic_vector (7 downto 0);

signal conv_in : std_logic_vector (3 downto 0);
signal divider :std_logic;

begin
-- Writer process
write_proc : process (clk)
begin 
 if falling_edge(clk) and enable='1' then 
  if w_msb='1' then
   digit_msb <= digit_in;
  end if;
  if w_lsb='1' then
   digit_lsb <= digit_in;
  end if;
 
 end if;
end process;

-- Clock divider process
div_proc : process (clk,counter)
begin
 if falling_edge(clk) then
  if(counter > x"0000ffff") then 
   counter <= x"000000";
   divider <= '1';
  else
   counter <= counter + 1;
   divider <= '0';
  end if;
 end if;
end process;

div2_proc : process(clk,divider)
begin 
 if falling_edge(clk) then
  if divider='1' then
   counter4 <= counter4 +1;
  end if;
 end if;
end process;

-- Anode control
mux_proc:  process (counter4,digit_lsb,digit_msb) 
  begin
    case counter4 is
    when "00" =>
      an_out <= "1110";
  conv_in <= digit_lsb(3 downto 0);
    when "01" =>
      an_out <= "1101";
  conv_in <= digit_lsb(7 downto 4);
    when "10" =>
      an_out <= "1011";
  conv_in <= digit_msb(3 downto 0);
    when others => 
      an_out <= "0111";
  conv_in <= digit_msb(7 downto 4);
    end case;
  end process;
  
 -- Binary to seven seg converter
 with conv_in select 
 seg_out <= "1000000" when "0000", --0 
  "1111001" when "0001",         --1 
  "0100100" when "0010",    --2 
  "0110000" when "0011",  --3 
  "0011001" when "0100",  --4 
  "0010010" when "0101",  --5 
  "0000010" when "0110",  --6 
  "1111000" when "0111",  --7 
  "0000000" when "1000",  --8 
  "0010000" when "1001",  --9 
  "0001000" when "1010",  --A 
  "0000011" when "1011",  --b 
  "1000110" when "1100",  --C 
  "0100001" when "1101",  --d 
  "0000110" when "1110",  --E 
  "0001110" when others;  --F 
dp_out <= '1';
end Behavioral;

