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

-- Descripcion:
--   This test reads one block byte y byte and show it in LSB display (hex format)
--   The SDCARD block is set in the switches and start asserting r_block signal
--   The current block read is showed in MSB display

-- BTN 0  is global reset
-- BTN 2  start to read new block
-- BTN 3  is to read byte by byte
-- SWITCHES select sd card block to read

-- LEDS: 
--   0: sdhost_busy
--   1: sdhost_err
--   7: ON when test FSM is at ERROR state
--

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.digilent_peripherals_pk.all;

entity test1 is
port(
  clk      : in   std_logic;
  leds_out : out  std_logic_vector (7 downto 0);
  seg_out  : out  std_logic_vector (6 downto 0);
  dp_out   : out  std_logic;
  an_out   : out  std_logic_vector (3 downto 0);
  sw_in    : in   std_logic_vector (7 downto 0);
  btn_in   : in   std_logic_vector (3 downto 0);
    
  miso : in  std_logic; -- PMOD SD 
  mosi : out std_logic;
  sclk : out std_logic;
  ss   : out std_logic);
end test1;

architecture Behavioral of test1 is

  component sdspihost
   port(
   clk        : in  std_logic;
   reset      : in  std_logic;      
   busy       : out std_logic;
   err        : out std_logic;
   
   r_block    : in std_logic;
   r_byte     : in std_logic; -- each byte is gotten asserting nb and waiting to fall of busy signal
   block_addr : in std_logic_vector(31 downto 0); -- 512 sd block address
   data_out   : out std_logic_vector (7 downto 0);
        
   miso      : in  std_logic;  -- sd card pin
   mosi      : out std_logic;  -- sd card pin
   sclk      : out std_logic;  -- sd card pin
   ss        : out std_logic   -- sd card pin
    );
  end component;

signal reset : std_logic;

signal btn_synced: std_logic_vector(7 downto 0);
signal display_enable,display_w_msb,display_w_lsb  : std_logic;
signal display_digit_in: std_logic_vector(7 downto 0);

signal leds_w,leds_enable : std_logic;
signal leds_in : std_logic_vector(7 downto 0);

signal sdhost_reset,sdhost_busy,sdhost_err,sdhost_r_block,sdhost_r_byte : std_logic;
signal sdhost_dout : std_logic_vector (7 downto 0);
signal sdhost_block_addr : std_logic_vector (31 downto 0);

type state_type is (
  ST_INIT,ST_WAIT_READY,
  ST_WAITBYTE,
  ST_WAIT_BUTTON_DOWN,
  ST_WAIT_BUTTON_3_UP,ST_WAIT_BUTTON_2_UP,
  ST_ERR
   );
  
signal current_st,next_st: state_type;

signal debug_counter:unsigned(31 downto 0);

begin

-- Global reset
reset <= btn_synced(0) or btn_synced(1); -- No warnings

-- Display control
display_enable   <= '1';

-- Leds control
leds_w     <= '1';
leds_enable<= '1';
leds_in(0) <= sdhost_busy;
leds_in(1) <= sdhost_err;

-- Block addr came from switches
sdhost_block_addr <= X"000000" & sw_in;

-- Units
  u_sync_buttons : port_buttons_dig port map (
    clk            => clk,
    r              => '1',
    enable         => '1',
    port_out       => btn_synced,
    buttons_in     => btn_in
  );
  u_port_display_basys2: port_display_dig port map(
    clk      => clk,
    enable   => display_enable,
    digit_in => display_digit_in,
    w_msb    => display_w_msb,
    w_lsb    => display_w_lsb,
      
    seg_out  => seg_out, -- io pins
    dp_out   => dp_out,
    an_out   => an_out 
  );
   
  u_port_leds_basys2: port_leds_dig port map(
    clk     => clk,
    w       => leds_w,
    enable  => leds_enable,
    port_in => leds_in,
      
    leds_out => leds_out -- io pins
  );

   u_sdspihost: sdspihost PORT MAP(
    clk      => clk,
    reset    => sdhost_reset,
    busy     => sdhost_busy,
    err      => sdhost_err,
    r_block  => sdhost_r_block,
    r_byte   => sdhost_r_byte,
    block_addr  => sdhost_block_addr,
    data_out => sdhost_dout ,
      
    miso => miso, --io pins
    mosi => mosi,
    sclk => sclk,
    ss   => ss
  );

-- State machine for debug

process (clk, reset)
  begin
  if (rising_edge(clk)) then
   if (reset='1') then
      current_st <= ST_INIT;  -- default state on reset
   else
      current_st <= next_st;   -- state change
   end if;
  end if;
end process;

process (current_st,sdhost_busy,sdhost_err,btn_synced,reset,sdhost_dout,sw_in)
begin
  display_digit_in <= sdhost_dout;
  leds_in(7 downto 2) <= "000000";
  display_w_msb  <= '0';
  display_w_lsb  <= '0';
  sdhost_reset   <= '0';
  sdhost_r_block <= '0'; 
  sdhost_r_byte  <= '0'; 
  case current_st is
  
    when ST_INIT =>        -- Wait SDHOST INIT
     sdhost_reset <= '1';
     debug_counter <= (others => '0');
     next_st <= ST_WAIT_READY;

    when ST_WAIT_READY =>       -- Wait for SDHOST ready
      display_w_msb <=  '1';    -- switches to display
      display_digit_in <= sw_in;
      if sdhost_busy= '1' then 
        next_st <= ST_WAIT_READY;
      elsif sdhost_err='1' then 
        next_st <= ST_ERR;
      else
        sdhost_r_block <= '1'; -- Read block set in switches
        next_st <= ST_WAITBYTE;
      end if;
            
     when ST_WAITBYTE =>      -- Wait byte
       sdhost_r_block <= '1';
       if sdhost_busy= '1' then 
         next_st <= ST_WAITBYTE;
       elsif sdhost_err='1' then 
         next_st <= ST_ERR;
       else -- Byte ready
         display_w_lsb <=  '1'; 
         next_st  <= ST_WAIT_BUTTON_DOWN;
       end if;
            
    when ST_WAIT_BUTTON_DOWN   =>  -- Wait for some button 
      sdhost_r_block <= '1';       -- Keep asserted to get other byte on same block
      if btn_synced(3) = '1'  then -- Read next byte      
        next_st <= ST_WAIT_BUTTON_3_UP;  
      elsif btn_synced(2) = '1' then   -- Start with new block
        next_st <= ST_WAIT_BUTTON_2_UP;   
      else
        next_st <= ST_WAIT_BUTTON_DOWN ;
      end if;
      
    when ST_WAIT_BUTTON_3_UP =>  -- wait button up to read next byte on same block
      sdhost_r_block <= '1';     -- not abort read
      if btn_synced(3) = '1' then
        next_st <=   ST_WAIT_BUTTON_3_UP;
      else        
        sdhost_r_byte <= '1';      -- RBYTE pulse
        next_st <= ST_WAITBYTE;
      end if;
      
    when ST_WAIT_BUTTON_2_UP => -- wait button up
      sdhost_r_block <= '0'; -- abort read
      if btn_synced(2) = '1' then
        next_st <= ST_WAIT_BUTTON_2_UP;
      else
        next_st <= ST_WAIT_READY; -- Wait abort read
      end if;
               
     when ST_ERR =>
       display_w_lsb <=  '1'; 
       leds_in(7) <= '1';
       next_st <= ST_ERR;
       
  end case;
end process;
end Behavioral;

