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

--
-- Desc: Architecture for simulation, this SDCARD fake used for simulation
--       data is fetched from a file in specific format
--   See doc to use it

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.sdspihost_pk.ALL;


use std.textio.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

architecture simulation of sdspihost is

constant SDCARD_FILENAME : string :="sdcard.txt";
constant SDCARD_BLOCKS : integer := 10;
type sdcard_t is array (0 to 512*SDCARD_BLOCKS) of std_logic_vector(7 downto 0);
signal sdcard_raw : sdcard_t;  

begin

  mosi <= '0';
  sclk <= '0';
  ss  <= '0';

  proc_fake : process --(clk,reset,r_block,r_byte,block_addr)
    variable busy_cnt : integer := 5;
    variable wait_byte : boolean := false;
    variable reading_block : boolean := false;
    variable block_addr_v : std_logic_vector(31 downto 0);
    variable byte_offset : integer:=0;
    variable offset: integer := 0;
    
  begin
    wait until rising_edge(clk);
    
    if reset = '1' then 
       busy_cnt := 5;
       byte_offset := 0;
       wait_byte:=false;
       reading_block:=false;
       busy <= '1';
    elsif busy_cnt > 0 then
      busy <= '1';
      busy_cnt := busy_cnt - 1;
    else
      busy <= '0'; 
      if r_block = '0' then -- abort reading
        if reading_block then
          busy_cnt := 40;
          busy <= '1'; 
          data_out <= X"FF";
        end if;
        reading_block:= false;
        wait_byte:= false;
      end if;
    end if;
    
    if busy_cnt = 0 and r_block = '1' and not reading_block then -- start reading block
     reading_block:=true;
     busy_cnt := 16;
     block_addr_v := block_addr;
     byte_offset := 0;
     busy <= '1';
    end if;
      
    if busy_cnt = 0 and r_block = '1' and r_byte = '1' then -- start reading byte
      busy_cnt := 8;
      wait_byte:=true;
      busy <= '1';
    end if;
                
    if busy_cnt = 0 and wait_byte then
      wait_byte := false;
      offset := conv_integer(block_addr_v)*512+byte_offset;
      data_out <= sdcard_raw(offset);
      byte_offset := byte_offset+1; -- next byte
    end if;        
            
    -- error conditions
    if r_block='0' and r_byte='1' then
      err <= 'U';
    elsif byte_offset > 512 then
      err <= '1';
    else
      err <= '0';
    end if; 
   
  end process;

  -- Fill sdcard from file in text format, see scripts for generate this file.
  proc_fill : process
    
    file file_handle: text;
    variable line_buf : line;
    variable good : boolean:=true;
    variable input_int : integer;
    variable index,column : integer;
    
  begin
    file_open(file_handle, SDCARD_FILENAME, READ_MODE);
    index:=0;
    while not endfile(file_handle) loop
      readline(file_handle,line_buf);  -- Read the whole line from the file
      column := 16; -- the file must have 16 integers columns
      while column > 0 loop
        column := column-1;
        read(line_buf, input_int, good);          
        sdcard_raw(index) <= conv_std_logic_vector(input_int,8);
        index:=index +1;
        if index >= 512*SDCARD_BLOCKS then       
          exit;
        end if;
      end loop;
      if index >= 512*SDCARD_BLOCKS then       
          exit;
      end if;
    end loop;
    file_close(file_handle);
    wait;
  end process;
end simulation;