# Initialze the library search path
set_db init_lib_search_path {/home/install/FOUNDRY/digital/90nm/dig/lib}

#Read the library, RTL, and SDC Files
set_db library "slow.lib"
set DESIGN audio_packet_processor
read_hdl "${DESIGN}.v"
elaborate $DESIGN
check_design -unresolved
read_sdc constraint_top.sdc

#Synthesis effort levels
set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

#Run generic synthesis, mapping and optimization
syn_generic
syn_map
syn_opt

#Write output files
write_hdl > ${DESIGN}_netlist.v
write_sdc > ${DESIGN}_sdc.sdc

#Generate reports
report_power > ${DESIGN}_power.rpt
report_gates > ${DESIGN}_gatescount.rpt
report_timing > ${DESIGN}_timing.rpt
report_area > ${DESIGN}_area.rpt

#Show GUI for result visualization
gui_show

