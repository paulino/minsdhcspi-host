
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.sdspihost_pk.all;

-- Some notes:
-- Commands are gotten from ROM. It containts 6 bytes sequence commands.
-- Start command ROM address is defined in package definition
-- Read command needs to send 0x00 while data is retrieved for SD card,
-- for this command, w_byte must be asserted. 
-- After command response when w_byte is asserted, SS is not deasserted and data_in 
-- byte is sent to SPI.

entity sdcmd is
  Port ( 
    clk       : in  std_logic;
    reset     : in  std_logic;
    argument  : in  std_logic_vector (31 downto 0);
    data_in   : in  std_logic_vector (7 downto 0); 
		data_out  : out std_logic_vector (7 downto 0);
    w_cmd     : in  std_logic; -- Send cmd
		w_byte    : in  std_logic; -- Send byte, byte is sent when w_cmd='1' and w_byte='1'
    w_arg     : in  std_logic; -- Send command: data_in&argument&00
		busy      : out std_logic;
      
		miso      : in  std_logic;  -- SD Card pin
		mosi      : out std_logic;  -- SD Card pin
		sclk      : out std_logic;  -- SD Card pin
		ss        : out std_logic   -- SD Card pin
           );

end sdcmd;

architecture Behavioral of sdcmd is

-- SPI signals
signal spi_data_in  :std_logic_vector(7 downto 0);
signal spi_data_out :std_logic_vector(7 downto 0);
signal spi_w_data,spi_busy,spi_w_conf,spi_ss_in: std_logic;

-- ROM signals
signal rom_data: std_logic_vector(7 downto 0);
signal rom_addr: std_logic_vector(4 downto 0);

-- Internal counters signals
signal counter_reset,counter_up: std_logic;
signal cmd_counter_reset,cmd_counter_up,cmd_counter_load : std_logic;
signal cmd_counter_dout: std_logic_vector(7 downto 0);
signal counter_dout: std_logic_vector(7 downto 0);

-- State machine signals

type state_type is (
	ST_INIT_0,ST_INIT_1,ST_INIT_2,
   ST_WAITCMD_0,ST_WAITCMD_1,
   ST_CMDSEND_0,ST_CMDSEND_1,ST_WAITRES_0,ST_WAITRES_1,
   ST_CMDSENDARG_0,
   ST_SEND_BYTE_0,ST_SEND_BYTE_1
   ); 

signal current_st,next_st: state_type; 

begin

-- Some components
u_counter: generic_counter 
generic map (width => 8) 
PORT MAP(
		clk    =>  clk,
		reset  =>  counter_reset,
		up     =>  counter_up,
		dout   =>  counter_dout
	);
   
u_cmd_code: generic_paracont 
generic map (width => 8) 
port map(
     clk   => clk , 
     reset => cmd_counter_reset,
     up    => cmd_counter_up,
     load  => cmd_counter_load,
     din   => data_in, 
     dout  => cmd_counter_dout
   );

u_sdcmd_rom: sdcmd_rom port map(
		addr => rom_addr,
		data_out => rom_data
	);
   
u_spi: spi
    port map ( 
		clk       => clk,
    data_in   => spi_data_in,
		data_out  => spi_data_out,
    w_data    => spi_w_data,
		w_conf    => spi_w_conf,
    ss_in     => spi_ss_in,
		busy		  => spi_busy,

		miso      => miso,
		mosi      => mosi,
		sclk      => sclk,
		ss        => ss);

-- Some direct connections

data_out <= spi_data_out ;
rom_addr <= cmd_counter_dout(4 downto 0);

-- State machine

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

process (current_st,w_cmd,w_arg,w_byte,spi_data_out,spi_busy,data_in,rom_data,counter_dout,argument,cmd_counter_dout)
begin
  busy <= '0';
  counter_reset  <= '0';  
  counter_up     <= '0';

  cmd_counter_reset <= '0';
  cmd_counter_up    <= '0';
  cmd_counter_load  <= '0';

  spi_ss_in   <= '1';   -- default slave not selected
  spi_data_in <= X"FF"; -- default spi 
  spi_w_data  <= '0';
  spi_w_conf  <= '0';
  
  next_st <= ST_INIT_0; -- BUG there is some case without this assigment
  
  case current_st is
     when ST_INIT_0 =>  -- up SS and reset SPI
       busy <= '1';
       spi_w_conf <= '1';
       spi_data_in(3 downto 0) <= "0100";  -- set clock speed
       counter_reset <= '1';
       next_st <= ST_INIT_1;    
     when ST_INIT_1 =>
       busy <= '1';

       spi_data_in <=  X"0A"; -- send ff 80 spi cycles
       spi_ss_in   <= '1';
       counter_up  <= '1';
       if counter_dout >= X"0F" then
         next_st <= ST_WAITCMD_0;
       else
         spi_w_data  <= '1';
         next_st <= ST_INIT_2;
       end if;
      when ST_INIT_2 =>
        busy <= '1';
        spi_ss_in <= '1'; 
        if spi_busy = '1' then
           next_st <= ST_INIT_2;
        else 
           next_st <= ST_INIT_1;
        end if;
       
     when ST_WAITCMD_0 =>   -- Wait for external command
         busy <= '0';
         spi_ss_in <= '1'; -- Deassert Slave
         if w_cmd = '0' then
            next_st   <= ST_WAITCMD_0;
         else 
            if w_arg = '1' then -- Send command with arguments
              spi_w_data    <= '1'; -- Send FF before command
              counter_reset <= '1';    
              cmd_counter_load <= '1';  -- Capture input byte in data_in             
              next_st     <= ST_CMDSENDARG_0;
            else
              spi_w_data  <= '1'; -- Send 8 sclk cycles before send command with ss deassert to sync SD card
              cmd_counter_load <= '1'; 
              counter_reset    <= '1';
              next_st          <= ST_WAITCMD_1;
            end if;
         end if;
         
     when ST_WAITCMD_1 => -- Send 8 sclk cycles before send command with ss deassert to sync SD card
        busy      <= '1';
        spi_ss_in <= '1'; -- Deassert Slave
        if spi_busy = '1' then
            next_st <= ST_WAITCMD_1;
        elsif w_arg = '1' then -- Send command with arguments
        else
            next_st <= ST_CMDSEND_0;
        end if;
        
     -- Send CMD
     when ST_CMDSEND_0 => -- SPI send one byte of SD CMD
         busy <= '1';
         counter_up     <= '1';
         cmd_counter_up <= '1'; -- Next CMD byte (conneted to ROM)
         spi_ss_in      <= '0'; -- Select slave        
         spi_data_in    <= rom_data;         
         if counter_dout >= X"06" then
            counter_reset <= '1';            
            next_st <= ST_WAITRES_0;
         else
            spi_w_data     <= '1';
            next_st <= ST_CMDSEND_1;
         end if;
     when ST_CMDSEND_1 => -- loop sending 6 bytes
        busy <= '1';
        spi_ss_in <= '0'; 
        if spi_busy = '1' then
           next_st <= ST_CMDSEND_1;
        else 
           next_st <= ST_CMDSEND_0;
        end if;
     
     when ST_WAITRES_0 =>     -- Wait response sending FF or timeout
          busy          <= '1';
          counter_up    <= '1';
          spi_data_in   <= X"FF";
          spi_ss_in     <= '0'; -- Select slave
          if counter_dout = X"FF" then -- time out
             next_st <= ST_WAITCMD_0;
          else if spi_data_out = X"FF" then 
              spi_w_data  <= '1';
              next_st     <= ST_WAITRES_1;
             else
				  if w_byte = '1' then -- Command with extra bytes (read command)				    
				    next_st <= ST_SEND_BYTE_0;
				  else
                next_st <= ST_WAITCMD_0; -- ok
				  end if;
             end if;
          end if;
		when ST_WAITRES_1 => 
		    busy <= '1';
          spi_ss_in <= '0'; 
          if spi_busy = '1' then
            next_st <= ST_WAITRES_1;
          else 
            next_st <= ST_WAITRES_0;
          end if;
          
    when ST_SEND_BYTE_0 =>
        busy      <= '0';
        spi_ss_in <= '0'; -- Keep slave selected
        if w_byte = '0' then 
          next_st <= ST_WAITCMD_0;
        elsif w_cmd = '1' then
          spi_data_in <= data_in;
          spi_w_data  <= '1';       
          next_st <= ST_SEND_BYTE_1;          
        else
          next_st <= ST_SEND_BYTE_0; -- wait to send byte
        end if;
		when ST_SEND_BYTE_1 =>
         busy      <= '1';
         spi_ss_in <= '0'; -- Keep slave selected
         if spi_busy = '1' then
           next_st <= ST_SEND_BYTE_1;
         else 
           next_st <= ST_SEND_BYTE_0;
         end if;
         
    -- Send command with argument     
    when ST_CMDSENDARG_0 =>
          busy          <= '1';
          spi_ss_in     <= '0'; -- Select slave
          if spi_busy = '1' then
            if counter_dout(2 downto 0) = "000" then -- First place send FF with slave not selected
              spi_ss_in     <= '1'; -- Unselect slave
            end if;
            next_st <= ST_CMDSENDARG_0;
          else
            spi_w_data  <= '1';
            counter_up  <= '1';
            case counter_dout(2 downto 0) is -- send 4 bytes argument
              when "000" =>
                 spi_data_in <= cmd_counter_dout; -- Send first byte captured from data_in previously
                 next_st     <= ST_CMDSENDARG_0;
              when "001" =>
                 spi_data_in <= argument(31 downto 24);
                 next_st     <= ST_CMDSENDARG_0;
              when "010"=>
                 spi_data_in <= argument(23 downto 16);
                 next_st     <= ST_CMDSENDARG_0;
              when "011"=>
                 spi_data_in <= argument(15 downto 8);
                 next_st     <= ST_CMDSENDARG_0;
              when "100"=>
                 spi_data_in <= argument(7 downto 0);
                 next_st     <= ST_CMDSENDARG_0;
              when "101"=>
                 spi_data_in <= X"00";
                 next_st     <= ST_CMDSENDARG_0;
              when others =>                
                 spi_w_data  <= '0';
                 if w_byte = '1' then
                   next_st     <= ST_SEND_BYTE_0;
                 else
                   next_st     <= ST_WAITCMD_0;
                 end if;                 
            end case;
           end if;
    
		 
  end case;
end process;

end Behavioral;

