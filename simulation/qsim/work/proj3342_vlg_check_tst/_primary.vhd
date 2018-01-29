library verilog;
use verilog.vl_types.all;
entity proj3342_vlg_check_tst is
    port(
        LEDR            : in     vl_logic_vector(9 downto 0);
        sampler_rx      : in     vl_logic
    );
end proj3342_vlg_check_tst;
