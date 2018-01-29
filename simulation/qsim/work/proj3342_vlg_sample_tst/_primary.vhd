library verilog;
use verilog.vl_types.all;
entity proj3342_vlg_sample_tst is
    port(
        KEY             : in     vl_logic_vector(3 downto 0);
        sampler_tx      : out    vl_logic
    );
end proj3342_vlg_sample_tst;
