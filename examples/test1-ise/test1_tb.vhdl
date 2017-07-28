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


library ieee;
use ieee.std_logic_1164.all;
  
entity test_basys2_tb is
end test_basys2_tb;
 
architecture behavior of test1_basys2_tb is 
 
    -- component declaration for the unit under test (uut)
 
    component test_basys2
    port(
         clk : in  std_logic;
         leds_out : out  std_logic_vector(7 downto 0);
         seg_out : out  std_logic_vector(6 downto 0);
         dp_out : out  std_logic;
         an_out : out  std_logic_vector(3 downto 0);
         sw_in : in  std_logic_vector(7 downto 0);
         btn_in : in  std_logic_vector(3 downto 0);
         miso : in  std_logic;
         mosi : out  std_logic;
         sclk : out  std_logic;
         ss : out  std_logic
        );
    end component;
    

   --Inputs
   signal clk : std_logic := '0';
   signal sw_in : std_logic_vector(7 downto 0) := (others => '0');
   signal btn_in : std_logic_vector(3 downto 0) := (others => '0');
   signal miso : std_logic := '0';

 	--Outputs
   signal leds_out : std_logic_vector(7 downto 0);
   signal seg_out : std_logic_vector(6 downto 0);
   signal dp_out : std_logic;
   signal an_out : std_logic_vector(3 downto 0);
   signal mosi : std_logic;
   signal sclk : std_logic;
   signal ss : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   constant sclk_period : time := 10 ns;
 
begin
 
	-- Instantiate the Unit Under Test (UUT)
   uut: test1_basys2 PORT MAP (
          clk => clk,
          leds_out => leds_out,
          seg_out => seg_out,
          dp_out => dp_out,
          an_out => an_out,
          sw_in => sw_in,
          btn_in => btn_in,
          miso => miso,
          mosi => mosi,
          sclk => sclk,
          ss => ss
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process; 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      btn_in <= "0001";
      miso <= '1';
      wait for 100 ns;	
      btn_in <= "0000";

      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
