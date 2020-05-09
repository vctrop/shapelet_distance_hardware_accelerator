onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider TB
add wave -noupdate /tb_shapelet_distance_timing/clk
add wave -noupdate /tb_shapelet_distance_timing/rst
add wave -noupdate /tb_shapelet_distance_timing/start
add wave -noupdate /tb_shapelet_distance_timing/ready
add wave -noupdate /tb_shapelet_distance_timing/op
add wave -noupdate /tb_shapelet_distance_timing/data
add wave -noupdate /tb_shapelet_distance_timing/distance
add wave -noupdate /tb_shapelet_distance_timing/expected_output
add wave -noupdate /tb_shapelet_distance_timing/index
add wave -noupdate -divider DUV
add wave -noupdate /tb_shapelet_distance_timing/DUV/op_i
add wave -noupdate /tb_shapelet_distance_timing/DUV/data_i
add wave -noupdate /tb_shapelet_distance_timing/DUV/start_i
add wave -noupdate /tb_shapelet_distance_timing/DUV/ready_o
add wave -noupdate /tb_shapelet_distance_timing/DUV/distance_o
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_op_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_shapelet_length_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/shapelet_length_float_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/dec_shapelet_length_float_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_position_validity_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_distance_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_state_s
add wave -noupdate -divider Buffers
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_buf_counter_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_acc_counter_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_block_sel_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/buffer_pivot_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/buffer_target_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/shapelet_elements_mux_s
add wave -noupdate -divider FPUs
add wave -noupdate /tb_shapelet_distance_timing/DUV/fp_ready_s
add wave -noupdate -divider .addsub
add wave -noupdate /tb_shapelet_distance_timing/DUV/addsub_start_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/add_or_sub_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/addsub_opa_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/addsub_opb_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/addsub_out_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_addsub_out_s
add wave -noupdate -divider .mul
add wave -noupdate /tb_shapelet_distance_timing/DUV/mul_start_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/mul_operator_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/mul_out_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_mul_out_s
add wave -noupdate -divider .div
add wave -noupdate /tb_shapelet_distance_timing/DUV/div_start_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/div_opa_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/div_opb_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/div_out_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/div_out_mean_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_div_out_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/div_opb_zero_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/div_by_zero_s
add wave -noupdate -divider .sqrt
add wave -noupdate /tb_shapelet_distance_timing/DUV/sqrt_start_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/sqrt_op_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/sqrt_out_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_sqrt_out_s
add wave -noupdate -divider en/wr/rst
add wave -noupdate /tb_shapelet_distance_timing/DUV/en_pivot_load_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/pivot_buf_rst_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/en_pivot_wb_norm_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/en_pivot_wb_sub_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/target_buf_rst_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/en_target_load_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/en_target_wb_sub_s
add wave -noupdate -divider Accumulators
add wave -noupdate /tb_shapelet_distance_timing/DUV/accumulators_wr_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/accumulators_rst_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_accumulators_s
add wave -noupdate -divider {Early abandon}
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_exp_minimum_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/addsub_out_exp_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/exp_acc_greater_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/any_acc_greater_s
add wave -noupdate -divider {Adder Tree}
add wave -noupdate /tb_shapelet_distance_timing/DUV/adder_tree_start_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/adder_tree_out_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/adder_tree_ready_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/reg_adder_tree_out_s
add wave -noupdate -divider {Cycle counter}
add wave -noupdate /tb_shapelet_distance_timing/DUV/counter_start_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/counter_mode_s
add wave -noupdate /tb_shapelet_distance_timing/DUV/fp_ready_s
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {176 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 388
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ns} {561 ns}
