vlog MUL_package.sv FA.sv HA.sv RCA.sv ece593w26_mul.sv ece593w26_acc.sv ece593w26_mac.sv mac_tb.sv
vopt work.mac_tb -o mac_tb_opt +acc
vsim mac_tb_opt
add wave *
run -all
