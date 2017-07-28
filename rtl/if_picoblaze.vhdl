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
-- Description: Glue logic for picoblaze interface
-- ADDR select internal registers/operations as follow:
--   WRITE_STROBE=1     ADDR  Desc.
--                        X   Start operation or byte is received (see operation 0x01)
--   READ_STROBE=1      ADDR  Desc.
--                        0   Read STATUS_REG
--                        1   Read SDCARD byte out
--
--               +---bit2-----+----bit1----+-----bit0----+
--  STATUS_REG:  |sdhost_busy | sdhost_err | byte_ready  | 
--               +------------+------------+-------------+
--               
--  Operations:   VAL  Operation
--                0x01 Start send 32-bit ADDR, after this 4 bytes are 
--                     expected in the next 4 writes on port
--                0x02 Start read new block using internal ADDR[31:0] reg
--                0x04 Read the next byte of the same block
--
--   Operation sequence: 0x01, 0xAA, 0xAA, 0xAA, 0xAA, 0x02 (wait byte_ready),
--                       0x04, (wait byte_ready) ...


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.sdspihost_pk.ALL;

entity if_picoblaze is
  port (
    clk             : in std_logic;
    reset           : in std_logic;
    --read_strobe_in  : in std_logic; -- picoblaze readport not necessary
    addr_in         : in std_logic;
    write_strobe_in : in std_logic;   -- picoblaze writeport
    dout            : out std_logic_vector(7 downto 0);
    din             : in  std_logic_vector(7 downto 0);
  
    miso      : in  std_logic;  -- SD Card pin
    mosi      : out std_logic;  -- SD Card pin
    sclk      : out std_logic;  -- SD Card pin
    ss        : out std_logic   -- SD Card pin
);


end if_picoblaze;

architecture Behavioral of if_picoblaze is
 
  -- internal register for ADDR  
  signal sdcard_addr : std_logic_vector(31 downto 0);
  
  -- sdhost signals
  signal sdhost_reset,sdhost_busy,sdhost_err : std_logic;
  signal sdhost_r_block,sdhost_r_byte : std_logic;
  signal sdhost_dout : std_logic_vector (7 downto 0);
  
  -- internal counter
  signal cnt3 : std_logic_vector(2 downto 0);
  signal byte_ready : std_logic; -- byte ready flag

begin

  -- Byte ready
  byte_ready <= not sdhost_err and not sdhost_busy and sdhost_r_block;
  
  -- Multiplexed out
  with addr_in select dout <= 
    sdhost_dout when '1',
    "00000" & sdhost_busy & sdhost_err & byte_ready when others;
    
   
   -- sdhc host unit
   u_sdspihost: sdspihost PORT MAP(
    clk         => clk,
    reset       => sdhost_reset,
    busy        => sdhost_busy,
    err         => sdhost_err,
    r_block     => sdhost_r_block,
    r_byte      => sdhost_r_byte,
    block_addr  => sdcard_addr,
    data_out    => sdhost_dout ,
      
    miso => miso, --io pins
    mosi => mosi,
    sclk => sclk,
    ss   => ss
  );
  
  -- process for port writes
  proc_write : process (clk,reset,write_strobe_in,addr_in,din)
  begin
    if rising_edge(clk) then
      sdhost_r_byte <= '0'; 
      if reset = '1' then
        sdcard_addr <= X"00000000";
        sdhost_reset <= '1';
        sdhost_r_block <= '0';
      elsif write_strobe_in = '1' then
       if din(0)='1' then -- OP=0x01 -> start send 32 bits addr
          cnt3 <= "000";
          sdhost_r_block <= '0';
       elsif cnt3(2)='0' then -- Receiving ADDR32 byte by byte
         -- receiving 32 bits (MSB first)
         cnt3 <= cnt3 + 1;
         case cnt3 is
           when  "000" => sdcard_addr(31 downto 24) <= din;
           when  "001" => sdcard_addr(23 downto 16) <= din;
           when  "010" => sdcard_addr(15 downto  8) <= din;
           when  "011" => sdcard_addr(7  downto  0) <= din;
           when others => 
          end case;
        elsif din(1) = '1' then -- OP=0x02 -> start read of a new block
          sdhost_r_block <= '1';
        elsif din(2) = '1' then -- OP=0x04 -> Read next byte of block
          sdhost_r_byte <= '1';
        end if;
      end if;
    end if;
  end process;
end Behavioral;