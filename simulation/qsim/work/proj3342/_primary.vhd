library verilog;
use verilog.vl_types.all;
entity proj3342 is
    port(
        KEY             : in     vl_logic_vector(3 downto 0);
        LEDR            : out    vl_logic_vector(9 downto 0)
    );
end proj3342;
