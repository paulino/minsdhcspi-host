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
-------------------------------------------------------------------------------

-- NOTES:
--   Data is send from MSB to LSB
--   CLK valid config values are 001,010,100, SCLK frecs are:
--     0001 -> SCLK = CLK / 2
--     0010 -> SCLK = CLK / 4
--     0100 -> SCLK = CLK / 64
--     1000 -> SCLK = CLK / 512
--   Data is captured by slave at rising edge
--   SS glitchs are filtered, min width is SCLK

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi is
    port (  clk      : in  std_logic;
            data_in  : in  std_logic_vector (7 downto 0);
            data_out : out std_logic_vector (7 downto 0);
            w_data   : in  std_logic;   -- 0: read / 1: write
            w_conf   : in  std_logic;   -- 1: write_config, 0: write data
            ss_in    : in  std_logic;   -- SPI SS            
           
            busy     : out std_logic;   -- Data ready when not busy
           
            miso     : in  std_logic;   -- SPI external connections 
            mosi     : out std_logic;
            sclk     : out std_logic;
            ss       : out std_logic);
end spi;


architecture Behavioral of spi is

constant CDIV_MSB_F  : positive := 3; -- bits (2:0), clk divisor
signal clkdiv  : std_logic_vector (CDIV_MSB_F downto 0); 

signal sclk_flag    : std_logic; 
signal busy_flag    : std_logic; 
signal ss_busy      : std_logic;
signal ss_flag      : std_logic; 

-- IO regs
signal data_out_reg : std_logic_vector (7 downto 0); -- serial output register
signal data_in_reg  : std_logic_vector (7 downto 0); -- serial input  register

signal clk_scaled : std_logic;

-- Internal counters
signal counter8       : unsigned (3 downto 0); -- bit send counter
signal counter_scaler : unsigned (9 downto 0); 

begin

-- Always read 

data_out <= data_in_reg;
busy     <= busy_flag;

-- IO Conections
mosi <= data_out_reg(7); -- Send first MSB
ss   <= ss_flag; -- Pulses on SS are enlarged
sclk <= sclk_flag;

-- CLK scaler, it is a pulse generator
clk_scaler_proc : process(clk)
begin
  if rising_edge(clk) then
    if w_conf='1' then
      clkdiv         <= data_in(CDIV_MSB_F downto 0);
      counter_scaler <= (others => '0');
      clk_scaled <= '0';
    elsif w_data='1' then -- Glitch detector
      counter_scaler <= (others => '0');
    elsif (clkdiv(3)='1' and counter_scaler(9)='1') or  -- clk/512
          (clkdiv(2)='1' and counter_scaler(6)='1') or
          (clkdiv(1)='1' and counter_scaler(2)='1') or 
          (clkdiv(0)='1' and counter_scaler(0)='1') then
      counter_scaler <= (others => '0');
      clk_scaled <= '1';
    elsif busy_flag = '1' or ss_busy = '1' then
      clk_scaled <= '0';
      counter_scaler<=counter_scaler+1;
    end if;
  end if;
end process;


-- SS glitch control
ss_proc : process (clk)
begin
  if rising_edge(clk) then
    if w_conf='1' then
      ss_busy <= '0';
      ss_flag <= ss_in;
    elsif ss_busy ='1' then
      if clk_scaled='1' then -- wait for scaled pulse          
        ss_busy <= '0';
      end if;
    elsif ss_flag /= ss_in then -- New SS edge
      ss_busy <= '1';
      ss_flag <= ss_in;
    end if;
  end if;
end process;

-- Sending process
send_proc : process (clk)
begin  
  if rising_edge(clk) then
    if w_conf='1' then    -- Writing config, break current sending process
      busy_flag <= '0';
      sclk_flag <= '1';
      counter8  <= "0000";
    elsif w_data='1' then
      data_out_reg <= data_in;
      busy_flag    <= '1';
      counter8     <= "0000"; 
    elsif ss_busy = '0' and busy_flag='1' and clk_scaled='1' then
      if sclk_flag='0' then -- Data is captured by slave at rising edge
        data_in_reg <= data_in_reg(6 downto 0) & miso;
        sclk_flag   <='1';
      else 
        if counter8 = "1000" then -- end sending
          busy_flag <= '0';
          sclk_flag <='1';
        else
          sclk_flag <='0';
        end if;
        counter8     <= counter8 + 1;
        if counter8 /= "0000" then
          data_out_reg <= data_out_reg(6 downto 0) & data_out_reg(0);
        end if;
      end if;
    end if;
  end if;
end process;
end Behavioral;

