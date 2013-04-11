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


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
 
ENTITY sdcmd_tb IS
END sdcmd_tb;
 
ARCHITECTURE behavior OF sdcmd_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT sdcmd
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         argument : IN  std_logic_vector(31 downto 0);
         data_in : IN  std_logic_vector(7 downto 0);
         data_out : OUT  std_logic_vector(7 downto 0);
         w_cmd : IN  std_logic;
         w_byte : IN  std_logic;
         w_arg : IN  std_logic;
         busy : OUT  std_logic;
         miso : IN  std_logic;
         mosi : OUT  std_logic;
         sclk : OUT  std_logic;
         ss : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal argument : std_logic_vector(31 downto 0) := (others => '0');
   signal data_in : std_logic_vector(7 downto 0) := (others => '0');
   signal w_cmd : std_logic := '0';
   signal w_byte : std_logic := '0';
   signal w_arg : std_logic := '0';
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
   uut: sdcmd PORT MAP (
          clk => clk,
          reset => reset,
          argument => argument,
          data_in => data_in,
          data_out => data_out,
          w_cmd => w_cmd,
          w_byte => w_byte,
          w_arg => w_arg,
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
      reset <= '1';
      wait for clk_period*2;
      reset <= '0';
      argument <= X"12345678";
      data_in <= X"51";
      wait until busy = '0';
      w_arg  <= '1';
      w_byte <= '1';
      w_cmd  <= '1';
      wait until busy = '0';
      w_arg  <= '0';
      w_byte <= '1';
      w_cmd  <= '0';
      --data_in <= X"00";
      --wait for clk_period;
      --w_cmd  <= '1';
      --wait for clk_period;
      --w_cmd  <= '0';
      
      
      
      wait for 200us;
         
   end process;

END;
