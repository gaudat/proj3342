library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Tested, must be working

entity one_second_clock is
	port(
	PPS: out std_logic;
	RESET: in std_logic;
	CLOCK_27: in std_logic);
end one_second_clock;

architecture a of one_second_clock is
	signal one_second: std_logic := '1';
	shared variable count: integer range 0 to (2**30)-1 := 0; -- Should be enough
begin
	process(CLOCK_27,one_second,reset) 
	begin
		if rising_edge(CLOCK_27) then
			count := count + 1;
		end if;
		if one_second = '1' then
			one_second <= '0';
		end if;
		if count >= 27000000 then
			count := 0;
			one_second <= '1';
		end if;
		if reset = '1' then
			count := 0;
			one_second <= '0';
		end if;
	end process;
	PPS <= one_second;
end architecture a;