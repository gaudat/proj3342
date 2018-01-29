onerror {quit -f}
vlib work
vlog -work work proj3342.vo
vlog -work work proj3342.vt
vsim -novopt -c -t 1ps -L cycloneii_ver -L altera_ver -L altera_mf_ver -L 220model_ver -L sgate work.proj3342_vlg_vec_tst
vcd file -direction proj3342.msim.vcd
vcd add -internal proj3342_vlg_vec_tst/*
vcd add -internal proj3342_vlg_vec_tst/i1/*
add wave /*
run -all
