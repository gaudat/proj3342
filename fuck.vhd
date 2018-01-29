ENTITY FSM IS
	PORT (
	ignit_sw, drv_door, pass_door:	IN STD_LOGIC;	--ignition switch, driver's door and passenger's door
	
	clk27:	IN STD_LOGIC;
	
	status_ind:	OUT STD_LOGIC_VECTOR (3 downto 0);	--status index, display on LED for dbg purpose
	time_param_sel: OUT STD_LOGIC_VECTOR(1 downto 0);
	timer_reprogram:	OUT STD_LOGIC;	--if we need to reprogram the delay value from FSM
	timer_start:	OUT STD_LOGIC;		
	timer_expire:	IN STD_LOGIC;		--timer is finish
	
	led_blink, led_light: OUT STD_LOGIC;
	
	siren_state_run: OUT STD_LOGIC;
	
	reprogram_flag: IN STD_LOGIC;	--if the reprogram button is pressed, go back top "ARMED"
	reset : IN STD_LOGIC
	);
END FSM;