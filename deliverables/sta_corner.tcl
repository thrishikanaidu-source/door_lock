set lib_dir $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib
read_liberty $lib_dir/$::env(LIBFILE)
read_lef results/cts/merged_unpadded.lef
read_def results/routing/door_lock.def
read_spef results/routing/door_lock.spef
create_clock -name clk -period 10 [get_ports clk]
set_propagated_clock [all_clocks]
puts "==== CORNER $::env(CORNER) ===="
report_checks -path_delay max -format full_clock_expanded
report_checks -path_delay min -format full_clock_expanded
report_wns
report_tns
exit
