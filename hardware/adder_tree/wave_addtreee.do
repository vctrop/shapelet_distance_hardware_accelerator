onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_adder_tree/DUV/NUM_INPUTS
add wave -noupdate /tb_adder_tree/DUV/NUM_CYCLES
add wave -noupdate /tb_adder_tree/DUV/clk_i
add wave -noupdate /tb_adder_tree/DUV/rst_i
add wave -noupdate /tb_adder_tree/DUV/operands_i
add wave -noupdate /tb_adder_tree/DUV/start_i
add wave -noupdate /tb_adder_tree/DUV/sum_o
add wave -noupdate /tb_adder_tree/DUV/ready_o
add wave -noupdate /tb_adder_tree/DUV/reg_initialized_s
add wave -noupdate /tb_adder_tree/DUV/reg_inputs_s
add wave -noupdate /tb_adder_tree/DUV/adder_outputs_s
add wave -noupdate /tb_adder_tree/DUV/reg_cycle_counter_s
add wave -noupdate /tb_adder_tree/DUV/reg_iterations_counter_s
add wave -noupdate /tb_adder_tree/DUV/AmountOfAdders
add wave -noupdate /tb_adder_tree/DUV/AmountOfIterations
add wave -noupdate /tb_adder_tree/DUV/LastIteration
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {67 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
WaveRestoreZoom {0 ns} {1 us}
