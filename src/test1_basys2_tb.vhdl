--------------------------------------------------------------------------------
-- This file is part of the Basys2 peripherals project
-- It is distributed under GNU General Public License
-- See at http://www.gnu.org/licenses/gpl.html
-- Copyright (C) 2013 Paulino Ruiz de Clavijo Vázquez <paulino@dte.us.es>
-- You can get more info at http://www.dte.us.es/id2
--------------------------------------------------------------------------------
-- Date:     25-02-2013
-- Revision: 1.0
--*--------------------------------- End auto header, don't touch this line -*--


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
  
ENTITY test_basys2_tb IS
END test_basys2_tb;
 
ARCHITECTURE behavior OF test1_basys2_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT test_basys2
    PORT(
         clk : IN  std_logic;
         leds_out : OUT  std_logic_vector(7 downto 0);
         seg_out : OUT  std_logic_vector(6 downto 0);
         dp_out : OUT  std_logic;
         an_out : OUT  std_logic_vector(3 downto 0);
         sw_in : IN  std_logic_vector(7 downto 0);
         btn_in : IN  std_logic_vector(3 downto 0);
         miso : IN  std_logic;
         mosi : OUT  std_logic;
         sclk : OUT  std_logic;
         ss : OUT  std_logic
        );
    END COMPONENT;
    

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
 
BEGIN
 
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
