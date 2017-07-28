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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
 
entity spi_tb is
end spi_tb;
 
architecture behavior of spi_tb is 
 
    -- component declaration for the unit under test (uut)
 
    component spi
    port(
         clk : in  std_logic;
         data_in : in  std_logic_vector(7 downto 0);
         data_out : out  std_logic_vector(7 downto 0);
         w_data : in  std_logic;
         w_conf : in  std_logic;
         ss_in : in  std_logic;
         busy : out  std_logic;
         miso : in  std_logic;
         mosi : out  std_logic;
         sclk : out  std_logic;
         ss : out  std_logic
        );
    end component;
    

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
      
      data_in <= "00001000"; -- 50Mhz/512 on basys 2
--    data_in <= "00000100"; -- 50Mhz/64
--    data_in <= X"02"; -- fast clock speed
      w_conf  <= '0';
      w_data  <= '0';
      ss_in   <= '1';
      miso <= '1';
      wait until rising_edge(clk);
      w_conf  <= '1';               -- Write conf
      wait until rising_edge(clk);
      w_conf  <= '0';
      wait for 200ns;
      wait until rising_edge(clk);
      ss_in   <= '0';               -- Select slave
      wait until rising_edge(clk);
      w_conf  <= '0';
      w_data  <= '1';
      data_in <= X"99";
      wait until rising_edge(clk);
      w_data  <='0';
      
      wait until falling_edge(busy); -- end of transmision
      wait until rising_edge(clk);  -- glitch on SS
      ss_in <= '1';
      wait until rising_edge(clk);
      ss_in <= '0';
      wait until rising_edge(clk);      
      miso <= '1';
      w_data  <= '1';
      data_in <= X"AA";
      wait until rising_edge(clk);      
      w_data  <= '0';
      
      -- Testing writes
      wait for 200ns;
      wait until rising_edge(clk);
      data_in <= X"11"; 
      w_data  <= '1';
      wait until rising_edge(clk);
      w_data  <= '0';
      wait until falling_edge(busy);
      wait until rising_edge(clk);
      data_in <= X"22"; 
      w_data  <= '1';
      wait until rising_edge(clk);
      w_data  <= '0';
      wait until falling_edge(busy);
      wait until rising_edge(clk);
      data_in <= X"33"; 
      w_data  <= '1';
      wait until rising_edge(clk);
      w_data  <= '0';
      wait until falling_edge(busy);
      wait until rising_edge(clk);
      
      

      wait;
   end process;

END;
