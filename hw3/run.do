vlog -cover sbcef +acc mtx_interface.sv mtx_mul_unit.sv tb_mtx_pkg.sv tb_mtx_mul_unit.sv
vopt work.tb_mtx_mul_unit -o tb_mtx_mult_unit_opt +acc
vsim -coverage tb_mtx_mult_unit_opt
run -all
