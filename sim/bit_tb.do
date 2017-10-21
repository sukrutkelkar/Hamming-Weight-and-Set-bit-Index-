vlog  -sv +define+SIM_DEBUG            ../tb/tb.sv
vlog  -sv +define+SIM_DEBUG            ../tb/ref_design.sv

vlog  -sv +define+SIM_DEBUG            ../src/hamming_wt_check.sv
vlog  -sv +define+SIM_DEBUG            ../src/sync_fifo.sv
vlog  -sv +define+SIM_DEBUG            ../src/sync_fifo_80.sv

view structure
vsim -novopt -t 1ps \
   tb
do wave.do
run -all