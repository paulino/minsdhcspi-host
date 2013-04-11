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

-- NOTES:
--   CLK valid config values are 001,010,100
--   Data is captured by slave at rising edge

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity spi is
    Port ( clk      : in   std_logic;
           data_in  : in   STD_LOGIC_VECTOR (7 downto 0);
			  data_out : out  STD_LOGIC_VECTOR (7 downto 0);
			  w_data   : in  std_logic; 	-- 0: read / 1: write
           w_conf   : in  std_logic;   -- 1: write_config, 0: write data
           ss_in    : in  std_logic;    -- SPI SS            
           
           busy    : out std_logic;   -- Data ready when not busy
           
			  miso    : in  std_logic;    -- SPI external connections 
			  mosi    : out std_logic;
			  sclk    : out std_logic;
			  ss      : out std_logic);
end spi;


architecture Behavioral of spi is

constant CDIV_MSB_F  : positive := 2; -- bits (2:0), clk divisor
signal clkdiv	: std_logic_vector (CDIV_MSB_F downto 0); 

signal sclk_flag    : std_logic; 
signal busy_flag    : std_logic; 

-- IO regs
signal data_out_reg : std_logic_vector (7 downto 0); -- serial output register
signal data_in_reg  : std_logic_vector (7 downto 0); -- serial input  register



-- Internal counters

signal counter8    : unsigned (2 downto 0); -- bit send counter
signal counter_div : unsigned (7 downto 0); -- CLK Divider

begin

-- Always read 

data_out <= data_in_reg;
busy     <= busy_flag;

-- IO Conections
mosi <= data_out_reg(7);
ss   <= ss_in;
sclk <= sclk_flag;


-- Sending process
send_proc : process (clk)
begin	
	--if falling_edge(clk) then
  if rising_edge(clk) then
		if w_conf='1' then    -- Writing config, break current sending process
         busy_flag <= '0';
			clkdiv        <= data_in(CDIV_MSB_F downto 0);
			sclk_flag     <='1';			
			counter8      <= "000";
			counter_div   <= "00000000";
		elsif w_data='1' then
			data_out_reg  <= data_in;
         busy_flag     <= '1';
			counter8      <= "000";
			counter_div   <= "00000000";
			sclk_flag          <= '0'; -- start clock
		elsif busy_flag='1' then
			counter_div  <= counter_div + 1;
			if (clkdiv(2)='1' and counter_div(6)='1') or
				(clkdiv(1)='1' and counter_div(2)='1') or
				(clkdiv(0)='1' and counter_div(0)='1')	then
				counter_div <= "00000000";
				if sclk_flag='0' then -- Data is captured by slave at rising edge
					data_in_reg  <= data_in_reg(6 downto 0) & miso;
					sclk_flag <='1';
				else 
					if counter8 = "111" then
						busy_flag <= '0';
						sclk_flag <='1';
					else
						sclk_flag <='0';
					end if; 					  
					counter8     <= counter8 + 1;			
					data_out_reg <= data_out_reg(6 downto 0) & data_out_reg(0);					
				end if;
			end if;		
		end if;
	end if;
end process;
end Behavioral;

