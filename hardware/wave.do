onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider TB
add wave -noupdate /tb_shapelet_distance/clk
add wave -noupdate /tb_shapelet_distance/rst
add wave -noupdate /tb_shapelet_distance/start
add wave -noupdate /tb_shapelet_distance/ready
add wave -noupdate /tb_shapelet_distance/op
add wave -noupdate /tb_shapelet_distance/data
add wave -noupdate /tb_shapelet_distance/distance
add wave -noupdate /tb_shapelet_distance/expected_output
add wave -noupdate /tb_shapelet_distance/index
add wave -noupdate -divider DUV
add wave -noupdate /tb_shapelet_distance/DUV/op_i
add wave -noupdate /tb_shapelet_distance/DUV/data_i
add wave -noupdate /tb_shapelet_distance/DUV/start_i
add wave -noupdate /tb_shapelet_distance/DUV/ready_o
add wave -noupdate /tb_shapelet_distance/DUV/distance_o
add wave -noupdate /tb_shapelet_distance/DUV/reg_op_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_shapelet_length_s
add wave -noupdate /tb_shapelet_distance/DUV/dec_shapelet_length_s
add wave -noupdate /tb_shapelet_distance/DUV/shapelet_length_float_s
add wave -noupdate /tb_shapelet_distance/DUV/dec_shapelet_length_float_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_position_validity_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_distance_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_state_s
add wave -noupdate -divider Buffers
add wave -noupdate /tb_shapelet_distance/DUV/reg_buf_counter_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_acc_counter_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_block_sel_s
add wave -noupdate /tb_shapelet_distance/DUV/buffer_pivot_s
add wave -noupdate /tb_shapelet_distance/DUV/buffer_target_s
add wave -noupdate /tb_shapelet_distance/DUV/shapelet_elements_mux_s
add wave -noupdate -divider FPUs
add wave -noupdate /tb_shapelet_distance/DUV/fp_ready_s
add wave -noupdate -divider .addsub
add wave -noupdate /tb_shapelet_distance/DUV/addsub_start_s
add wave -noupdate /tb_shapelet_distance/DUV/add_or_sub_s
add wave -noupdate /tb_shapelet_distance/DUV/addsub_opa_s
add wave -noupdate /tb_shapelet_distance/DUV/addsub_opb_s
add wave -noupdate /tb_shapelet_distance/DUV/addsub_out_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_addsub_out_s
add wave -noupdate -divider .mul
add wave -noupdate /tb_shapelet_distance/DUV/mul_start_s
add wave -noupdate /tb_shapelet_distance/DUV/mul_operator_s
add wave -noupdate /tb_shapelet_distance/DUV/mul_out_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_mul_out_s
add wave -noupdate -divider .div
add wave -noupdate /tb_shapelet_distance/DUV/div_start_s
add wave -noupdate /tb_shapelet_distance/DUV/div_opa_s
add wave -noupdate /tb_shapelet_distance/DUV/div_opb_s
add wave -noupdate /tb_shapelet_distance/DUV/div_out_s
add wave -noupdate /tb_shapelet_distance/DUV/div_out_mean_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_div_out_s
add wave -noupdate -divider .sqrt
add wave -noupdate /tb_shapelet_distance/DUV/sqrt_start_s
add wave -noupdate /tb_shapelet_distance/DUV/sqrt_op_s
add wave -noupdate /tb_shapelet_distance/DUV/sqrt_out_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_sqrt_out_s
add wave -noupdate -divider en/wr/rst
add wave -noupdate /tb_shapelet_distance/DUV/en_pivot_load_s
add wave -noupdate /tb_shapelet_distance/DUV/pivot_buf_rst_s
add wave -noupdate /tb_shapelet_distance/DUV/en_pivot_wb_norm_s
add wave -noupdate /tb_shapelet_distance/DUV/en_pivot_wb_sub_s
add wave -noupdate /tb_shapelet_distance/DUV/target_buf_rst_s
add wave -noupdate /tb_shapelet_distance/DUV/en_target_load_s
add wave -noupdate /tb_shapelet_distance/DUV/en_target_wb_sub_s
add wave -noupdate -divider Accumulators
add wave -noupdate /tb_shapelet_distance/DUV/accumulators_wr_s
add wave -noupdate /tb_shapelet_distance/DUV/accumulators_rst_s
add wave -noupdate /tb_shapelet_distance/DUV/acc_sum_opa_s
add wave -noupdate /tb_shapelet_distance/DUV/acc_sum_opb_s
add wave -noupdate /tb_shapelet_distance/DUV/acc_sum_out_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_accumulators_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_acc_sum_out_s
add wave -noupdate -divider {Cycle counter}
add wave -noupdate /tb_shapelet_distance/DUV/counter_start_s
add wave -noupdate /tb_shapelet_distance/DUV/counter_mode_s
add wave -noupdate /tb_shapelet_distance/DUV/fp_ready_s
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {115736 ns} 0}
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
WaveRestoreZoom {56284 ns} {59745 ns}
