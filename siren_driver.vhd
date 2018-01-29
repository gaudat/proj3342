-- MCLK 24.576 MHz
-- DSP, 2nd rising edge

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity siren_driver is
port (
	clk24: in std_logic; -- 24 MHz clock
	run: in std_logic; -- Drop the beat
	reset: in std_logic;
	mclk: out std_logic; -- Always on
	bclk: out std_logic; -- Gated and synched to lr
	daclrc: out std_logic;
	dacdat: out std_logic
);
end siren_driver;

architecture a of siren_driver is
	constant mclk_freq: integer := 24_000_000;
	constant sample_rate: integer := 8_000;
	type int_array is array(0 to 63) of integer;
	constant sine: int_array := (0, 804, 1607, 2410, 3211, 4011, 4808, 5602,
		6392, 7179, 7961, 8739, 9512, 10278, 11039, 11793,
		12539, 13278, 14010, 14732, 15446, 16151, 16846, 17530,
		18204, 18868, 19519, 20159, 20787, 21403, 22005, 22594,
		23170, 23732, 24279, 24812, 25330, 25832, 26319, 26790,
		27245, 27684, 28106, 28511, 28898, 29269, 29621, 29956,
		30273, 30572, 30852, 31114, 31357, 31581, 31785, 31971,
		32138, 32285, 32413, 32521, 32610, 32679, 32728, 32758);
 	signal clk12: std_logic := '0'; -- 12 MHz is under BCLK limit
	signal new_sample: std_logic; -- On when new sample
	signal o_sample: std_logic_vector(15 downto 0); -- Always generated
	signal l_sample: std_logic_vector(15 downto 0); -- Switched
	signal r_sample: std_logic_vector(15 downto 0);
begin
	process(new_sample) 
		variable sine_idx: integer range 0 to 255 := 0;
		variable sine_add: integer range 0 to 15 := 0;
		variable divider: integer range 0 to 1023 := 0;
		variable sine_dir: std_logic;
	begin
		if falling_edge(new_sample) then
			if divider = 0 then
				if sine_add < 3 then
					sine_add := 3;
					sine_dir := '1';
				elsif sine_add > 14 then
					sine_add := 14;
					sine_dir := '0';
				end if;
				divider := 100;
				if sine_dir = '1' then
					sine_add := sine_add + 1;
				else
					sine_add := sine_add - 1;
				end if;
			end if;
			divider := divider - 1;
			if (sine_idx >= 255) then
				sine_idx := 0;
			else
				sine_idx := sine_idx + sine_add;
					case sine_idx is
						when 0 to 63 => 
							o_sample <= std_logic_vector(to_signed(sine(sine_idx),16));
						when 64 => 
							o_sample <= std_logic_vector(to_signed(32767,16));
						when 65 to 128 =>
							o_sample <= std_logic_vector(to_signed(sine(128-sine_idx),16));
						when 129 to 191 =>
							o_sample <= std_logic_vector(to_signed(0-sine(sine_idx-128),16));
						when 192 =>
							o_sample <= std_logic_vector(to_signed(-32767,16));
						when 193 to 255 =>
							o_sample <= std_logic_vector(to_signed(0-sine(256-sine_idx),16));
					end case;
			end if;
		end if;
	end process;
	
	process(reset,clk12) 
		type states is (s_Wait, s_Up_LRC, s_push_L, s_push_R);
		variable divider: integer range 0 to (mclk_freq/sample_rate) := 0;
		variable state : states;
		variable cur_sample: integer range 0 to 15;
	begin
		if (reset = '1') then -- Reset
			divider := 0;
		elsif falling_edge(clk12) then
			case state is
				when s_Wait =>
					divider := divider + 1;
					if divider >= (12_000_000/8000) then
						divider := 0;
						new_sample <= '1';
						state := s_Up_LRC;
					end if;
				when s_Up_LRC =>
					daclrc <= '1';
					state := s_push_L;
					cur_sample := 15;
				when s_push_L =>
					daclrc <= '0';
					dacdat <= l_sample(cur_sample);
					if cur_sample = 0 then
						cur_sample := 15;
						state := s_push_R;
					else
						cur_sample := cur_sample - 1;
					end if;
				when s_push_R =>
					daclrc <= '0';
					dacdat <= r_sample(cur_sample);
					if cur_sample = 0 then
						cur_sample := 15;
						new_sample <= '0';
						state := s_Wait;
					else
						cur_sample := cur_sample - 1;
					end if;
				end case;
			end if;
	end process;
		
	process(clk24) begin
		if (rising_edge(clk24)) then -- BCLK divider
			clk12 <= not clk12;
		end if;
	end process;
	bclk <= '0' when reset = '1' else clk12;
	mclk <= clk24;
	l_sample <= "0000000000000000" when run = '0' else o_sample;
	r_sample <= "0000000000000000" when run = '0' else o_sample;
end architecture a;