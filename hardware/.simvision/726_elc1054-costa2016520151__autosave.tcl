
# NC-Sim Command File
# TOOL:	ncsim	15.20-s075
#

set tcl_prompt1 {puts -nonewline "ncsim> "}
set tcl_prompt2 {puts -nonewline "> "}
set vlog_format %h
set vhdl_format %v
set real_precision 6
set display_unit auto
set time_unit module
set heap_garbage_size -200
set heap_garbage_time 0
set assert_report_level note
set assert_stop_level error
set autoscope yes
set assert_1164_warnings yes
set pack_assert_off {}
set severity_pack_assert_off {note warning}
set assert_output_stop_level failed
set tcl_debug_level 0
set relax_path_name 1
set vhdl_vcdmap XX01ZX01X
set intovf_severity_level ERROR
set probe_screen_format 0
set rangecnst_severity_level ERROR
set textio_severity_level ERROR
set vital_timing_checks_on 1
set vlog_code_show_force 0
set assert_count_attempts 1
set tcl_all64 false
set tcl_runerror_exit false
set assert_report_incompletes 0
set show_force 1
set force_reset_by_reinvoke 0
set tcl_relaxed_literal 0
set probe_exclude_patterns {}
set probe_packed_limit 4k
set probe_unpacked_limit 16k
set assert_internal_msg no
set svseed 1
set assert_reporting_mode 0
alias . run
alias iprof profile
alias quit exit
database -open -shm -into waves.shm waves -default
probe -create -database waves :clk :rst :start :data :distance :expected_output :op :ready :DUV:start_i :DUV:op_i :DUV:data_i :DUV:distance_o :DUV:ready_o :DUV:reg_state_s :DUV:reg_shapelet_length_s :DUV:shapelet_length_float_s :DUV:buffer_pivot_s :DUV:buffer_target_s :DUV:block_sel_inc_s :DUV:accumulators_rst_s :DUV:accumulators_wr_s :DUV:add_or_sub_s :DUV:addsub_start_s :DUV:div_start_s :DUV:mul_start_s :DUV:sqrt_start_s :DUV:fp_ready_s :DUV:cycle_counter:start_i :DUV:cycle_counter:rst :DUV:cycle_counter:mode_i :DUV:addsub_opa_s :DUV:addsub_opb_s :DUV:addsub_out_s :DUV:div_opa_s :DUV:div_opb_s :DUV:div_out_s :DUV:sqrt_op_s :DUV:sqrt_out_s :DUV:mul_operator_s :DUV:mul_out_s :DUV:acc_sum_opa_s :DUV:acc_sum_opb_s :DUV:acc_sum_out_s :DUV:reg_accumulators_s :DUV:reg_acc_counter_s :DUV:reg_block_sel_s :DUV:reg_buf_counter_s :DUV:reg_distance_s :DUV:reg_op_s

simvision -input /home/elc1054/elc1054-costa2016520151/shapelet_distance_hardware_accelerator/hardware/.simvision/726_elc1054-costa2016520151__autosave.tcl.svcf
