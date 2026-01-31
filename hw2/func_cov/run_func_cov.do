vlog +acc func_cov.sv func_cov_tb.sv
vsim -coverage work.func_cov_tb -voptargs="+cover=bcesfx"
run -all
coverage report -details -cvg
coverage save func_cov.ucdb

