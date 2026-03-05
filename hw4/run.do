# =============================================================================
# run.do
# Usage (default full test):
#   vsim -do run_uvm.do
#
# Usage (corner-case test only):
#   vsim -do run_uvm.do -g UVM_TESTNAME=mtx_corner_test
#
# Or override from command line:
#   vsim -do run_uvm.do +UVM_TESTNAME=mtx_corner_test
# =============================================================================
vlog -cover sbcef +acc \
     -sv \
     mtx_interface.sv \
     mtx_mul_unit.sv \
     tb_mtx_pkg.sv \
     tb_mtx_mul_unit.sv
vopt work.tb_mtx_mul_unit_uvm -o tb_uvm_opt +acc
vsim -coverage \
     -sv_seed random \
     +UVM_TESTNAME=mtx_full_test \
     +UVM_VERBOSITY=UVM_MEDIUM \
     tb_uvm_opt

# Add signals to waveform viewer
add wave -divider "Clock / Reset / Control"
add wave -radix binary   sim:/tb_mtx_mul_unit_uvm/mif/clk
add wave -radix binary   sim:/tb_mtx_mul_unit_uvm/mif/rst
add wave -radix binary   sim:/tb_mtx_mul_unit_uvm/mif/start
add wave -radix binary   sim:/tb_mtx_mul_unit_uvm/mif/done

add wave -divider "Matrix A (row0)"
add wave -radix hex      sim:/tb_mtx_mul_unit_uvm/mif/A[0][0]
add wave -radix hex      sim:/tb_mtx_mul_unit_uvm/mif/A[0][1]
add wave -radix hex      sim:/tb_mtx_mul_unit_uvm/mif/A[0][2]

add wave -divider "Matrix B (col0)"
add wave -radix hex      sim:/tb_mtx_mul_unit_uvm/mif/B[0][0]
add wave -radix hex      sim:/tb_mtx_mul_unit_uvm/mif/B[1][0]
add wave -radix hex      sim:/tb_mtx_mul_unit_uvm/mif/B[2][0]

add wave -divider "Matrix C (row0) – valid 3 cycles after done"
add wave -radix hex      sim:/tb_mtx_mul_unit_uvm/mif/C[0][0]
add wave -radix hex      sim:/tb_mtx_mul_unit_uvm/mif/C[0][1]
add wave -radix hex      sim:/tb_mtx_mul_unit_uvm/mif/C[0][2]

run -all

# ---- Coverage report --------------------------------------------------------
coverage report -detail -cvg -directive -comments -output coverage_report.txt
quit -sim
