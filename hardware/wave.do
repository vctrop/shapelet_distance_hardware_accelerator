onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_shapelet_distance/clk
add wave -noupdate /tb_shapelet_distance/rst
add wave -noupdate /tb_shapelet_distance/start
add wave -noupdate /tb_shapelet_distance/ready
add wave -noupdate /tb_shapelet_distance/op
add wave -noupdate /tb_shapelet_distance/data
add wave -noupdate /tb_shapelet_distance/distance
add wave -noupdate /tb_shapelet_distance/expected_output
add wave -noupdate /tb_shapelet_distance/index
add wave -noupdate -divider duv
add wave -noupdate /tb_shapelet_distance/DUV/op_i
add wave -noupdate /tb_shapelet_distance/DUV/data_i
add wave -noupdate /tb_shapelet_distance/DUV/start_i
add wave -noupdate /tb_shapelet_distance/DUV/ready_o
add wave -noupdate /tb_shapelet_distance/DUV/distance_o
add wave -noupdate /tb_shapelet_distance/DUV/reg_op_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_shapelet_length_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_distance_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_state_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_buf_counter_s
add wave -noupdate /tb_shapelet_distance/DUV/reg_acc_counter_s
add wave -noupdate /tb_shapelet_distance/DUV/pivot_buf_rst_s
add wave -noupdate /tb_shapelet_distance/DUV/target_buf_rst_s
add wave -noupdate /tb_shapelet_distance/DUV/accumulators_wr_s
add wave -noupdate /tb_shapelet_distance/DUV/fp_ready_s
add wave -noupdate /tb_shapelet_distance/DUV/add_or_sub_s
add wave -noupdate /tb_shapelet_distance/DUV/div_opb_s(0)
add wave -noupdate /tb_shapelet_distance/DUV/reg_block_sel_s
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {110 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 213
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
WaveRestoreZoom {89 ns} {147 ns}
