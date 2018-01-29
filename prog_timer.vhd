library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Programmable timer
-- Verified working

entity prog_timer is
port (pps: in std_logic; -- rising edge
		load_timer: in std_logic; -- Shift time_in when 1, higher priority than start_timer
		start_timer: in std_logic; -- Count down when 1
		expired: out std_logic;
		reset: in std_logic; -- Set expired to 0 and internal count to 0
		time_in: in std_logic_vector(3 downto 0); -- 0 to 15 seconds
		dbg_output: out std_logic_Vector(3 downto 0)); -- debug output of count
end entity prog_timer;

architecture a of prog_timer is
signal expired_int: std_logic; -- Internal expired signal
signal count: integer range 0 to (2**4)-1 := 0;
begin

process(reset,load_timer,start_timer,pps) 
begin
	if (reset = '1') then
		expired_int <= '0';
		count <= 0;
	elsif (load_timer = '1') then
		count <= to_integer(unsigned(time_in));
	elsif (rising_edge(pps) and start_timer = '1' and count > 0) then
		count <= count - 1;
	end if;
end process;
expired <= '1' when count = 0 else '0';
dbg_output <= std_logic_vector(to_unsigned(count,dbg_output'length));
end architecture a;
			