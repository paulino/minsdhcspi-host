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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- BTN 0  is global reset
-- BTN 2  start to read new block
-- BTN 3  is to read byte by byte
-- SWITCHES select sd card block

entity test1_basys2 is
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
end test1_basys2;

architecture Behavioral of test1_basys2 is

  COMPONENT port_display_basys2
  PORT(
    clk : IN std_logic;
    enable : IN std_logic;
    digit_in : IN std_logic_vector(7 downto 0);
    w_msb : IN std_logic;
    w_lsb : IN std_logic;          
    seg_out : OUT std_logic_vector(6 downto 0);
    dp_out : OUT std_logic;
    an_out : OUT std_logic_vector(3 downto 0)
    );
  END COMPONENT;


  COMPONENT port_leds_basys2
  PORT(
    clk : IN std_logic;
    w : IN std_logic;
    enable : IN std_logic;
    port_in : IN std_logic_vector(7 downto 0);          
    leds_out : OUT std_logic_vector(7 downto 0)
    );
  END COMPONENT;

  COMPONENT sdspihost
   PORT(
   clk        : in  std_logic;
   reset      : in  std_logic;      
   busy       : out std_logic;
   err        : out std_logic;
   
   r_block    : in std_logic;
   r_byte     : in std_logic; -- each byte is gotten asserting nb and waiting to fall of busy signal
   block_addr : in std_logic_vector(31 downto 0); -- 512 SD block address
   data_out   : out STD_LOGIC_VECTOR (7 downto 0);
        
   miso      : in  std_logic;  -- SD Card pin
   mosi      : out std_logic;  -- SD Card pin
   sclk      : out std_logic;  -- SD Card pin
   ss        : out std_logic   -- SD Card pin
    );
  END COMPONENT;

signal reset : std_logic;

signal display_enable,display_w_msb,display_w_lsb  : std_logic;
signal display_digit_in: std_logic_vector(7 downto 0);

signal leds_w,leds_enable : std_logic;
signal leds_in : std_logic_vector(7 downto 0);

signal sdhost_reset,sdhost_busy,sdhost_err,sdhost_r_block,sdhost_r_byte : std_logic;
signal sdhost_dout : std_logic_vector (7 downto 0);
signal sdhost_block_addr : std_logic_vector (31 downto 0);

type state_type is (
  ST_INIT_0,ST_READBLOCK,ST_READBYTE,ST_WAITBYTE,
  ST_IDLE1,ST_IDLE2,ST_IDLE3,ST_ERR
   );
  
signal current_st,next_st: state_type;

begin

-- Global reset
reset <= btn_in(0);

-- Display control
display_enable   <= '1';
with display_w_lsb select display_digit_in <= 
  sdhost_dout when '1',
  sw_in when others;

-- Leds control
leds_w     <= '1';
leds_enable<= '1';
leds_in(0) <= sdhost_busy;
leds_in(1) <= sdhost_err;


-- Block addr came from switches
sdhost_block_addr <= X"000000" & sw_in;

-- Units

  u_port_display_basys2: port_display_basys2 PORT MAP(
    clk      => clk,
    enable   => display_enable,
    digit_in => display_digit_in,
    w_msb    => display_w_msb,
    w_lsb    => display_w_lsb,
      
    seg_out  => seg_out, --io pins
    dp_out   => dp_out,
    an_out   => an_out 
  );
   
  u_port_leds_basys2: port_leds_basys2 PORT MAP(
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
      current_st <= ST_INIT_0;  --default state on reset.
   else
      current_st <= next_st;   --state change.
   end if;
  end if;
end process;

process (current_st,sdhost_busy,sdhost_err,btn_in,reset)
begin
  leds_in(7 downto 2) <= "000000";
  display_w_msb <= '0';
  display_w_lsb <= '0';
  sdhost_reset <= '0';
  sdhost_r_block <= '0'; 
  sdhost_r_byte  <= '0'; 
  case current_st is
     when ST_INIT_0 =>  -- Wait SDHOST INIT
      sdhost_reset <= '1';
      next_st <= ST_READBLOCK;
     when ST_READBLOCK =>  -- Wait SDHOST INIT
     display_w_msb <=  '1'; -- sw to display
       if sdhost_busy= '1' then 
        next_st <= ST_READBLOCK;
       elsif sdhost_err='1' then 
        next_st <= ST_ERR;
       else
        sdhost_r_block <= '1'; -- Read block        
        next_st <= ST_READBYTE;
       end if;
       
     when ST_READBYTE => -- Wait for block ready
       sdhost_r_block <= '1'; 
       
       if sdhost_busy= '1' then 
        next_st <= ST_READBYTE;
       elsif sdhost_err='1' then 
        next_st <= ST_ERR;
       else 
        sdhost_r_byte <= '1'; -- Read byte pulse
        next_st  <= ST_WAITBYTE;
       end if;
     when ST_WAITBYTE =>       -- Wait byte
       sdhost_r_block <= '1'; 
       if sdhost_busy= '1' then 
         next_st <= ST_WAITBYTE;
       elsif sdhost_err='1' then 
         next_st <= ST_ERR;
       else -- Byte ready
         display_w_lsb <=  '1'; 
         next_st  <= ST_IDLE1;
       end if;
      
     
     when ST_IDLE1 => -- Wait button
     sdhost_r_block <= '1'; 
       if btn_in(3) = '1'  then
        next_st <= ST_IDLE2;  -- read next byte
       elsif btn_in(2) = '1' then
        next_st <= ST_IDLE3;  -- start with new block
       else
        next_st <= ST_IDLE1;
       end if;
     when ST_IDLE2 =>
       sdhost_r_block <= '1'; 
       if btn_in(3) = '1' then
        next_st <= ST_IDLE2;
       else        
        next_st <= ST_READBYTE;
       end if;
     when ST_IDLE3 =>
       sdhost_r_block <= '0';  -- abort read block
       if btn_in(2) = '1' then
        next_st <= ST_IDLE3;
       else
        next_st <= ST_READBLOCK;
       end if;
       
        
     when ST_ERR =>
       display_w_lsb <=  '1'; 
       leds_in(7) <= '1';
       next_st <= ST_ERR;
       
  end case;
end process;
end Behavioral;

