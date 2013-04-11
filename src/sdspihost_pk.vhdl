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

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package sdspihost_pk is

-- Commands for entity sdspihost

constant SDHOST_INIT      : std_logic_vector (3 downto 0) := X"0"; -- Init SD
constant SDHOST_READFIRST : std_logic_vector (3 downto 0) := X"1"; -- Read first byte, data_in <= blockno
constant SDHOST_READNEXT  : std_logic_vector (3 downto 0) := X"2"; -- Read next byte

-- Address of SD CMD commands in ROM

constant CMD0_ROMADDR   : std_logic_vector(7 downto 0) := X"00";
constant CMD8_ROMADDR   : std_logic_vector(7 downto 0) := X"06";
constant CMD55_ROMADDR  : std_logic_vector(7 downto 0) := X"0C";
constant ACMD41_ROMADDR : std_logic_vector(7 downto 0) := X"12";
constant CMD12_ROMADDR  : std_logic_vector(7 downto 0) := X"18";

-- Components

COMPONENT generic_counter
generic ( width : integer );      
PORT(
		clk : IN std_logic;
		reset : IN std_logic;
		up : IN std_logic;          
		dout : OUT std_logic_vector(width-1 downto 0)
		);
END COMPONENT;

COMPONENT generic_paracont
generic ( width : integer );      
PORT(
		clk : IN std_logic;
		reset : IN std_logic;
		up : IN std_logic;
		load : IN std_logic;
		din : IN std_logic_vector(width-1 downto 0);          
		dout : OUT std_logic_vector(width-1 downto 0)
		);
END COMPONENT;

component spi
    Port ( clk      : in   std_logic;
           data_in  : in   std_logic_vector (7 downto 0);
			  data_out : out  std_logic_vector (7 downto 0);
			  w_data   : in   std_logic; 	-- 0: read / 1: write
           w_conf   : in   std_logic;   -- 1: write_config, 0: write data
           ss_in    : in   std_logic;    -- SPI SS            
           
           busy    : out   std_logic;   -- Data ready when not busy
           
			  miso    : in    std_logic;    -- SPI external connections 
			  mosi    : out   std_logic;
			  sclk    : out   std_logic;
			  ss      : out   std_logic);
end component;

component sdcmd_rom
	port(
		addr     : IN std_logic_vector(4 downto 0);          
		data_out : OUT std_logic_vector(7 downto 0)
		);
end component;

end sdspihost_pk;

package body sdspihost_pk is


 
end sdspihost_pk;
