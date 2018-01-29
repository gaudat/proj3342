library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Tested, must be working

entity fuel_pump_logic is
	port (ignition: in std_logic;
			reset: in std_logic;
			brake: in std_logic;
			hidden_sw: in std_logic;
			fuel_pump_power: out std_logic);
end fuel_pump_logic;

architecture a of fuel_pump_logic is
signal ignition_latch: std_logic; -- Latched on after fuel pump power
begin
ignition_latch <= '0' when reset = '1' else (ignition and ignition_latch) or (ignition and brake and hidden_sw);
fuel_pump_power <= ignition_latch;
end architecture a;
