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

-- Descripcion:
--   This test reads one block (512-byte) and computes xor of all read bytes,
--   To read new block use the button 3. 
--    MSB display number of block readed
--    LSB displays parity of 512-byte (XOR)
--
--  A script 'test3.c' is available in 'utils' dir to check the result

-- Board controls:
--  BTN 0  is global reset
--  BTN 3  is used to read next block
--  LEDS: 
--   0: sdhost_busy
--   1: sdhost_err
--   6: Loop flag
--   7: ON when test FSM is in ERROR state

library ieee;
use ieee.std_logic_1164.all;
use work.sdspihost_pk.all;
use work.digilent_peripherals_pk.all;

entity test3_basys2 is
port(
  clk      : in   std_logic;
  leds_out : out  std_logic_vector (7 downto 0);
  seg_out  : out  std_logic_vector (6 downto 0);
  dp_out   : out  std_logic;
  an_out   : out  std_logic_vector (3 downto 0);
  btn_in   : in   std_logic_vector(3 downto 0);
    
  miso : in  std_logic; -- PMOD SD
  mosi : out std_logic;
  sclk : out std_logic;
  ss   : out std_logic);
end test3_basys2;

architecture Behavioral of test3_basys2 is

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
        
   miso       : in  std_logic;  -- sd card pin
   mosi       : out std_logic;  -- sd card pin
   sclk       : out std_logic;  -- sd card pin
   ss         : out std_logic   -- sd card pin
    );
  end component;
  
  component xor_reg
  port(
    d_in  : in std_logic_vector(7 downto 0);
    clk   : in std_logic;
    wx    : in std_logic;
    clear : in std_logic;          
    d_out : out std_logic_vector(7 downto 0)
    );
  end component;

signal reset : std_logic;

signal display_enable,display_w_msb,display_w_lsb  : std_logic;
signal display_digit_in: std_logic_vector(7 downto 0);
signal btn_synced: std_logic_vector(7 downto 0);

signal leds_w,leds_enable : std_logic;
signal leds_in : std_logic_vector(7 downto 0);

signal sdhost_reset,sdhost_busy,sdhost_err,sdhost_r_block,sdhost_r_byte : std_logic;
signal sdhost_dout : std_logic_vector (7 downto 0);

-- Blocks/Bytes counter signals
signal block_counter_reset, block_counter_up:std_logic;
signal sdhost_block_addr : std_logic_vector (31 downto 0);
signal byte_counter_reset, byte_counter_up:std_logic;
signal byte_counter_dout : std_logic_vector (8 downto 0); -- 512 bytes/block

-- XOR Register
signal xreg_w,xreg_clear : std_logic;
signal xreg_dout : std_logic_vector (7 downto 0);

type state_type is (
   ST_INIT ,
   ST_WAITBYTE,ST_LOOP,
   ST_WAIT_SD_READY,
   ST_IDLE,ST_WAIT_BUTTON_UP,ST_ERR
   );
  
signal current_st,next_st: state_type;

begin

-- Global reset
reset <= btn_synced(0) or btn_synced(1) or btn_synced(2);

-- Display control
display_enable   <= '1';

-- Leds control
leds_w     <= '1';
leds_enable<= '1';
leds_in(0) <= sdhost_busy;
leds_in(1) <= sdhost_err;

-- Units

  u_sync_buttons : port_buttons_dig port map (
    clk        => clk,
    enable     => '1',
    r          => '1',
    port_out   => btn_synced,
    buttons_in => btn_in
  );

  u_port_display_basys2: port_display_dig port map(
    clk      => clk,
    enable   => display_enable,
    digit_in => display_digit_in,
    w_msb    => display_w_msb,
    w_lsb    => display_w_lsb,
      
    seg_out  => seg_out, --io pins
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
    
  -- counter for block sd read
  u_block_counter: generic_counter 
  generic map (width => 32) 
  port map(
    clk    =>  clk,
    reset  =>  block_counter_reset,
    up     =>  block_counter_up,
    dout   =>  sdhost_block_addr
  );
  
  -- counter for 512bytes per block
  u_byte_counter: generic_counter 
  generic map (width => 9) 
  port map(
    clk    =>  clk,
    reset  =>  byte_counter_reset,
    up     =>  byte_counter_up,
    dout   =>  byte_counter_dout
  );
  -- Parity register
  u_xor_reg: xor_reg port map(
    clk   => clk,
    d_in  => sdhost_dout,
    d_out => xreg_dout,
    wx    => xreg_w,
    clear => xreg_clear
  );


  u_sdspihost: sdspihost port map(
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
      current_st <=  ST_INIT ;  -- default state on reset.
   else
      current_st <= next_st;    -- state change.
   end if;
  end if;
end process;

process (current_st,sdhost_busy,sdhost_err,btn_synced,reset,byte_counter_dout,
         sdhost_block_addr,xreg_dout,sdhost_dout)
begin
  display_digit_in <= xreg_dout; -- Default display connected to xor register
  leds_in(7 downto 2) <= "000000";
  display_w_msb  <= '0';
  display_w_lsb  <= '0';  
  byte_counter_reset <= '0';
  byte_counter_up    <= '0';
  block_counter_reset  <= '0';
  block_counter_up     <= '0';
  sdhost_reset   <= '0';
  sdhost_r_block <= '0'; 
  sdhost_r_byte  <= '0'; 
  xreg_clear <= '0';
  xreg_w <= '0';
  
  case current_st is

    when ST_INIT  =>              -- Wait SDHOST INIT
      sdhost_reset <= '1';
      block_counter_reset <= '1'; -- Start reading from block 0x00000000
      byte_counter_reset <= '1';
      xreg_clear <= '1';
      next_st <= ST_WAIT_SD_READY;
      
    when ST_WAIT_SD_READY =>
      display_w_msb <=  '1';  -- MSB block readed to display
      display_digit_in <= sdhost_block_addr (7 downto 0); -- Block to MSB display
      if sdhost_busy= '1' then 
        next_st <= ST_WAIT_SD_READY;
      elsif sdhost_err='1' then 
        next_st <= ST_ERR;
      else
        sdhost_r_block <= '1'; -- Read block
        next_st <= ST_WAITBYTE;
      end if;

     when ST_WAITBYTE => -- Wait for byte
       sdhost_r_block <= '1'; 
       leds_in(5) <= '1'; -- loop indicator
       if sdhost_busy= '1' then 
         next_st <= ST_WAITBYTE;
       elsif sdhost_err='1' then 
         next_st <= ST_ERR;
       else              -- Byte ready
         xreg_w  <= '1';  -- Load and xor    
         next_st <= ST_LOOP;
       end if;
       
      when ST_LOOP =>          -- Loop to read 512 Bytes from SDCARD
      sdhost_r_block  <= '1';  -- keep asserted to get other byte on same block
      leds_in(6) <= '1';       -- loop indicator
      if (byte_counter_dout = b"111111111") then -- 512 bytes read
      --if (byte_counter_dout = b"000000000") then -- 512 bytes read
        next_st <= ST_IDLE;
      else
        byte_counter_up <= '1';
        sdhost_r_byte  <= '1'; -- Rbyte pulse
        next_st <= ST_WAITBYTE;
      end if;

     when ST_IDLE =>           -- Wait button 3 down       
       sdhost_r_block <= '1';  
       display_digit_in <= xreg_dout;
       display_w_lsb  <= '1';   -- Update display lsb (XOR)
       if btn_synced(3) = '1'  then
         next_st <= ST_WAIT_BUTTON_UP; -- read next block
         sdhost_r_block <= '0'; -- abort read
       else
         next_st <= ST_IDLE;
       end if;
     when ST_WAIT_BUTTON_UP =>  -- wait button up to read new block
       if btn_synced(3) = '1' then
         next_st <= ST_WAIT_BUTTON_UP;
       else
         block_counter_up <= '1';   -- next block
         xreg_clear <= '1';
         byte_counter_reset <= '1';
         next_st <= ST_WAIT_SD_READY;
       end if;
             
     when ST_ERR =>
       leds_in(7) <= '1';
       next_st <= ST_ERR;
       
  end case;
end process;
end Behavioral;

