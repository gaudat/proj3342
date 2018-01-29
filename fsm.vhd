library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fsm is
port( reset: in std_logic;
		ignition_sw: in std_logic;
		driver_door: in std_logic; -- High when open
		passenger_door: in std_logic; -- High when open
		
		clk27: in std_logic;
		dbg_state_out: out std_logic_vector(2 downto 0); -- State out
		
		tp_param_sel: out std_logic_vector(1 downto 0);
		pt_load_timer: out std_logic; -- Timer load
		pt_start_timer: out std_logic; -- Timer start (active high)
		pt_expired: in std_logic; -- Timer expired
		
		led_blink: out std_logic;
		led_light: out std_logic; -- Takes precedence
		
		sr_run: out std_logic); -- Siren run
end fsm;

architecture a of fsm is

type STATES is (ARMED,DISARMED,DISARMED_WAIT,D_OPEN,ALARM,ALARM_WAIT);
signal state: STATES;
begin

process(clk27,reset) begin
	if (reset = '1') then
		state <= ARMED;
		tp_param_sel <= "00";
		pt_load_timer <= '0';
		pt_start_timer <= '0';
		led_blink <= '0';
		led_light <= '0';
		sr_run <= '0';
	elsif rising_edge(clk27) then
		case state is
			when ARMED =>
				led_blink <= '1';
				led_light <= '0';
				sr_run <= '0';
				pt_start_timer <= '0';
				if (driver_door = '1') then
					tp_param_sel <= "01";
					pt_load_timer <= '1';
					state <= D_OPEN;
				elsif (passenger_door = '1') then
					tp_param_sel <= "10";
					pt_load_timer <= '1';
					state <= D_OPEN;
				end if;
			when DISARMED =>
				pt_load_timer <= '0';
				led_blink <= '0';
				led_light <= '0';
				sr_run <= '0';
				pt_start_timer <= '0';
				if (ignition_sw = '0' and driver_door = '0' and passenger_door = '0') then
					tp_param_sel <= "00";
					pt_load_timer <= '1';
					state <= DISARMED_WAIT;
				end if;
			when DISARMED_WAIT =>
				pt_load_timer <= '0';
				led_blink <= '0';
				led_light <= '0';
				sr_run <= '0';
				pt_start_timer <= '1';
				if driver_door = '1' or passenger_door = '1' then
					pt_load_timer <= '1';
				end if;
				if pt_expired = '1' then
					state <= ARMED;
				end if;
			when D_OPEN =>
				pt_load_timer <= '0';
				led_blink <= '0';
				led_light <= '1';
				sr_run <= '0';
				pt_start_timer <= '1';
				if (ignition_sw = '1') then
					pt_start_timer <= '0';
					state <= DISARMED;
				elsif (pt_expired = '1') then
					state <= ALARM;
				end if;
			when ALARM =>
				pt_load_timer <= '0';
				led_blink <= '0';
				led_light <= '1';
				sr_run <= '1';
				pt_start_timer <= '0';
				if (ignition_sw = '1') then
					state <= DISARMED;
				elsif (driver_door = '0' and passenger_door = '0') then
					tp_param_sel <= "11";
					pt_load_timer <= '1';
					state <= ALARM_WAIT;
				end if;
			when ALARM_WAIT =>
				pt_load_timer <= '0';
				led_blink <= '0';
				led_light <= '1';
				sr_run <= '1';
				pt_start_timer <= '1';
				if (ignition_sw = '1') then
					state <= DISARMED;
				elsif (pt_expired = '1') then
					state <= ARMED;
				end if;
		end case;
	end if;
end process;

dbg_state_out <= std_logic_vector(to_unsigned(STATES'pos(state), 3)); -- Output current state

end architecture a;