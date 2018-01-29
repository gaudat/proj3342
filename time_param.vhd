library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Tested working

entity time_param is
	port(
time_param_sel: in std_logic_vector(1 downto 0);
time_value: in std_logic_vector(3 downto 0);
interval_sel: in std_logic_vector(1 downto 0);
interval_value: out std_logic_vector(3 downto 0);
reprogram: in std_logic;
reset: in std_logic);
end time_param;

architecture a of time_param is
	signal arm_delay: std_logic_vector(3 downto 0) := "0110";
	signal driver_delay: std_logic_vector(3 downto 0) := "1000";
	signal passenger_delay: std_logic_vector(3 downto 0) := "1111";
	signal alarm_on: std_logic_vector(3 downto 0) := "1010";
begin
	process(reprogram,reset)
	begin

		if reset = '1' then
			arm_delay <= "0110";
			driver_delay <= "1000";
			passenger_delay <= "1111";
			alarm_on <= "1010";
		elsif rising_edge(reprogram) then
			-- Reprogram button pressed
			case (time_param_sel) is
				when "00" => arm_delay <= time_value;
				when "01" => driver_delay <= time_value;
				when "10" => passenger_delay <= time_value;
				when "11" => alarm_on <= time_value;
			end case;
		end if;
	end process;
	
	interval_value <= arm_delay when interval_sel = "00" else
			driver_delay when interval_sel = "01" else
			passenger_delay when interval_sel = "10" else
			alarm_on when interval_sel = "11";
		
end architecture a;