vlog -cover sbcef +acc code_cov.sv code_cov_tb.sv
vopt work.code_cov_tb -o code_cov_tb_opt +acc
vsim -coverage code_cov_tb_opt
run -all
