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


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
 
ENTITY spi_tb IS
END spi_tb;
 
ARCHITECTURE behavior OF spi_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT spi
    PORT(
         clk : IN  std_logic;
         data_in : IN  std_logic_vector(7 downto 0);
         data_out : OUT  std_logic_vector(7 downto 0);
         w_data : IN  std_logic;
         w_conf : IN  std_logic;
         ss_in : IN  std_logic;
         busy : OUT  std_logic;
         miso : IN  std_logic;
         mosi : OUT  std_logic;
         sclk : OUT  std_logic;
         ss : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal data_in : std_logic_vector(7 downto 0) := (others => '0');
   signal w_data : std_logic := '0';
   signal w_conf : std_logic := '0';
   signal ss_in : std_logic := '0';
   signal miso : std_logic := '0';

   --Outputs
   signal data_out : std_logic_vector(7 downto 0);
   signal busy : std_logic;
   signal mosi : std_logic;
   signal sclk : std_logic;
   signal ss : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   constant sclk_period : time := 10 ns;
 
BEGIN
 
  -- Instantiate the Unit Under Test (UUT)
   uut: spi PORT MAP (
          clk => clk,
          data_in => data_in,
          data_out => data_out,
          w_data => w_data,
          w_conf => w_conf,
          ss_in => ss_in,
          busy => busy,
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
      miso <= '1';
      data_in <= X"01";
      w_conf  <= '1';
      w_data  <= '0';
      ss_in   <= '1';
      wait for 100 ns;  
      w_conf  <= '0';
      w_data  <= '1';
      data_in <= X"99";
      wait for clk_period*2;
      w_data  <='0';

      -- insert stimulus here 

      wait;
   end process;

END;
