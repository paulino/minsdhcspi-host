

-- Parity load register

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity xor_reg is
    port ( d_in  : in  std_logic_vector (7 downto 0);
           d_out : out std_logic_vector (7 downto 0);
           clk   : in  std_logic;
           wx    : in  std_logic;
           clear : in  std_logic);
end xor_reg;

architecture Behavioral of xor_reg is

signal mem : std_logic_vector (7 downto 0);

begin

d_out <= mem;

write_proc: process (clk) 
begin
	if rising_edge(clk) then 
    if clear = '1' then
      mem <= X"00";
    elsif wx='1' then
      mem <= mem xor d_in;      
    end if;
	end if;
end process;

end Behavioral;

