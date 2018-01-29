library IEEE;
use IEEE.std_logic_1164.all;

entity blinker is
port (clk1: in std_logic; -- 1hz clock
		reset: in std_logic; -- reset
		blink: in std_logic; -- blink?
		light: in std_logic; -- always light? take precedence
		ledout: out std_logic);
end blinker;

architecture a of blinker is
	signal blinking: std_logic; -- on for 1 sec, off for 2 sec
begin
	process(clk1,reset)
		variable divider: integer range 0 to 3; -- divide by 3
	begin
		if (reset = '1') then
			divider := 0;
		elsif (rising_edge(clk1)) then
			divider := divider + 1;
			if divider >= 3 then
				divider := 0;
			end if;
		end if;
		if divider /= 0 then
			blinking <= '0';
		else 
			blinking <= '1';
		end if;
	end process;
	
	ledout <= '0' when reset = '1' else '1' when light = '1' else blinking when blink = '1' else '0';
end architecture a;