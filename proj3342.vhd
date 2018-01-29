library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity proj3342 is
	port(
	SW: in std_logic_vector(9 downto 0);
	KEY: in std_logic_vector(3 downto 0); -- Keys are active low beware
	LEDR: out std_logic_vector(9 downto 0);
	LEDG: out std_logic_vector(7 downto 0);
	CLOCK_27: in std_logic_vector(1 downto 0);
	CLOCK_24: in std_logic_vector(1 downto 0);
	GPIO_0: out std_logic_vector(35 downto 0);
	I2C_SCLK: inout std_logic;
	I2C_SDAT: inout std_logic;
	AUD_DACLRCK: out std_logic;
	AUD_DACDAT: out std_logic;
	AUD_XCK: out std_logic;
	AUD_BCLK: out std_logic;
	
	pps: inout std_logic; -- Cannot be signal or it gets buggy
	
	key2_d, key3_d: inout std_LOGIC; -- Used in KEY(2) and KEY(3) toggling
	key2_d_Q, key3_d_Q: inout std_LOGIC;
	
	hidden_sw, brake, ignition, reprogram : inout std_logic; -- rebounced signal
	door_driver: inout std_LOGIC; -- '0' when closed, '1' when open
	door_passenger: inout std_logic); -- '0' when closed, '1' when open
end proj3342;

architecture arch3342 of proj3342 is
	component time_param is 
	port(
		time_param_sel: in std_logic_vector(1 downto 0);
		time_value: in std_logic_vector(3 downto 0);
		interval_sel: in std_logic_vector(1 downto 0);
		interval_value: out std_logic_vector(3 downto 0);
		reprogram: in std_logic;
		reset: in std_logic);
	end component;
	
	component one_second_clock is
	port(
		PPS: out std_logic; -- pulse per second
		RESET: in std_logic; -- reset
		CLOCK_27: in std_logic); -- 27MHz
	end component;

component prog_timer is
port (pps: in std_logic;
		load_timer: in std_logic;
		start_timer: in std_logic; -- Shift time_in at rising edge
		expired: out std_logic;
		reset: in std_logic; -- Set expired to 0 and internal count to 0
		dbg_output: out std_logic_vector(3 downto 0);
		time_in: in std_logic_vector(3 downto 0)); -- 0 to 15 seconds
end component;

component audio_codec_initial is
	PORT (
		reset: in std_logic;
		clk27 	: IN STD_LOGIC; 											--Master clock
		SDINin 	: INOUT STD_LOGIC; 										--Serial data on I2C
		SCLKin 	: INOUT STD_LOGIC;											--Serial clock on I2C bus
		done: out std_logic
		);                
	end component;
	
component siren_driver is
port (
	clk24: in std_logic; -- 24 MHz clock
	run: in std_logic; -- Drop the beat
	reset: in std_logic;
	mclk: out std_logic; -- Always on
	bclk: out std_logic; -- Gated and synched to lr
	daclrc: out std_logic;
	dacdat: out std_logic
);
end component;

component blinker is
port (reset: in std_logic;
		clk1: in std_logic; -- 1hz clock
		blink: in std_logic; -- blink?
		light: in std_logic; -- always light? take precedence
		ledout: out std_logic);
end component;

component fsm is
port( reset: in std_logic;
		ignition_sw: in std_logic;
		driver_door: in std_logic;
		passenger_door: in std_logic;
		
		clk27: in std_logic;
		dbg_state_out: out std_logic_vector(2 downto 0);
		
		tp_param_sel: out std_logic_vector(1 downto 0);
		pt_load_timer: out std_logic;
		pt_start_timer: out std_logic;
		pt_expired: in std_logic;
		
		led_blink: out std_logic;
		led_light: out std_logic;
		
		sr_run: out std_logic); -- Run the siren
end component;


component fuel_pump_logic is
	port (ignition: in std_logic; -- Ignition switch
			reset: in std_logic; -- Reset
			brake: in std_logic; -- Brake switch
			hidden_sw: in std_logic; -- Hidden switch
			fuel_pump_power: out std_logic); -- Output
end component;

component debounce IS
	generic( counter_size  :  INTEGER ); --counter size (18 bits gives 10ms with 27MHz clock)
	port( clk     : IN  STD_LOGIC;  --input clock
			button  : IN  STD_LOGIC;  --input signal to be debounced
			result  : OUT STD_LOGIC); --debounced signal
end component;

-- Reset and codec
signal reset: std_logic;
signal sda: std_logic;
signal scl: std_logic;
signal mclk: std_logic;
signal bclk: std_logic;
signal daclrc: std_logic;
signal dacdat: std_logic;

-- State machine to other modules
signal interval_value: std_logic_vector(3 downto 0);
signal tp_param_sel: std_logic_vector(1 downto 0);
signal dbg_state_out: std_logic_vector(2 downto 0);
signal pt_load_timer, pt_start_timer, pt_expired, led_blink, led_light, sr_run: std_logic;

begin

-- SW(9): Reset
-- SW(8): Reprogram
-- SW(7): Ignition
-- SW(6):
-- SW(5): Time param (1)
-- SW(4): Time param (0)
-- SW(3): Time value (3)
-- SW(2): Time value (2)
-- SW(1): Time value (1)
-- SW(0): Time value (0)

-- KEY(3): Passenger_door
-- KEY(2): Driver_door
-- KEY(1): Brake
-- KEY(0): Hidden switch

-- LEDR(2:0): FSM current state
-- LEDG(3:0): Keys pressed

-- LEDR(9): Driver_door
-- LEDR(8): Passenger_door
-- LEDG(7): Fuel_pump_power
-- LEDG(5): Status light

	LEDG(3 downto 0) <= not KEY; -- Keys pressed
	reset <= SW(9);
	LEDR(2 downto 0) <= dbg_state_out; -- Current state

	-- Debouncers
	DB_key0: debounce generic map (counter_size => 18) port map (clock_27(0), key(0), hidden_sw);
	DB_key1: debounce generic map (counter_size => 18) port map (clock_27(0), key(1), brake);
	DB_key2: debounce generic map (counter_size => 18) port map (clock_27(0), key(2), key2_d);
	DB_key3: debounce generic map (counter_size => 18) port map (clock_27(0), key(3), key3_d);
	DB_ignition:	debounce generic map (counter_size => 18) port map (clock_27(0), sw(7), ignition);
	DB_reprog: 		debounce generic map (counter_size => 18) port map (clock_27(0), sw(8), reprogram);

	-- Modules
	CLK: one_second_clock port map (pps => pps, reset => reset, clock_27 => CLOCK_27(0));
	FPL: fuel_pump_logic port map (ignition => ignition, reset => reset, brake => not brake, hidden_sw => not hidden_sw, fuel_pump_power => LEDG(7));
	TP: time_param port map (time_param_sel => SW(5 downto 4), time_value => SW(3 downto 0), interval_sel => tp_param_sel, interval_value => interval_value, reprogram => reprogram, reset => reset);
	PT: prog_timer port map (pps => pps,start_timer => pt_start_timer,load_timer => pt_load_timer, expired => pt_expired, reset => reset, time_in => interval_value);
	DACCMD: audio_codec_initial port map (reset => reset, clk27 => CLOCK_27(0), SDINin => sda, SCLKin => scl);
	DACDRV: siren_driver port map(clk24 => CLOCK_24(0),run => sr_run,reset => reset,mclk => mclk, bclk => bclk, daclrc => daclrc, dacdat => dacdat);
	BLINK: blinker port map(reset => reset, clk1 => pps, blink => led_blink, light => led_light, ledout => LEDG(5));
	SM: fsm port map(reset => reset or SW(8), ignition_sw => ignition, driver_door => door_driver, passenger_door => door_passenger, clk27 => CLOCK_27(0), dbg_state_out => dbg_state_out, tp_param_sel => tp_param_sel,
			pt_load_timer => pt_load_timer, pt_start_timer => pt_start_timer, pt_expired => pt_expired, led_blink => led_blink, led_light => led_light, sr_run => sr_run);

	-- Routing internal signals to codec
	I2C_SDAT <= sda;
	I2C_SCLK <= scl;
	AUD_XCK <= mclk;
	AUD_BCLK <= bclk;
	AUD_DACLRCK <= daclrc;
	AUD_DACDAT <= dacdat;
	
	-- Make KEY(2) and KEY(3) toggling
	process(clock_27(0), sw(9)) begin
		if sw(9) = '1' then
			key2_d_Q <= '0';
			key3_d_Q <= '0';
		elsif rising_edge(clock_27(0)) then
			key2_d_Q <= key2_d;
			key3_d_Q <= key3_d;
		end if;
		if sw(9) = '1' then 
			door_driver <= '0';
			ledr(8) <= '0';
		elsif rising_edge(clock_27(0)) and (key2_d_Q='1' and key2_d='0') then
			door_driver <= not door_driver;
			ledr(8) <= not door_driver;
		end if;
		if sw(9) = '1' then 
			door_passenger <= '0';
			ledr(9) <= '0';
		elsif rising_edge(clock_27(0)) and (key3_d_Q='1' and key3_d='0') then
			door_passenger <= not door_passenger;
			ledr(9) <= not door_passenger;
		end if;
	end process;
end architecture arch3342;
