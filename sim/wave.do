onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {Top Level} /tb/DUT/clk
add wave -noupdate -expand -group {Top Level} /tb/DUT/rst
add wave -noupdate -expand -group {Top Level} -radix unsigned /tb/DUT/packet_data
add wave -noupdate -expand -group {Top Level} /tb/DUT/start_of_packet
add wave -noupdate -expand -group {Top Level} -radix unsigned /tb/DUT/location_data
add wave -noupdate -expand -group {Top Level} /tb/DUT/location_data_valid
add wave -noupdate -expand -group {Top Level} -radix unsigned /tb/DUT/ones_count_out
add wave -noupdate -expand -group {Top Level} /tb/DUT/ones_count_valid
add wave -noupdate -expand -group {Top Level} /tb/DUT/last_data_of_packet_valid
add wave -noupdate -expand -group {Top Level} /tb/DUT/wt_err
add wave -noupdate -radix unsigned /tb/DUT/packet_count
add wave -noupdate -expand -group Sync_fifo1 /tb/DUT/sync_fifo_80_inst/wr
add wave -noupdate -expand -group Sync_fifo1 -radix unsigned /tb/DUT/sync_fifo_80_inst/data_in
add wave -noupdate -expand -group Sync_fifo1 /tb/DUT/sync_fifo_80_inst/rd
add wave -noupdate -expand -group Sync_fifo1 -radix unsigned /tb/DUT/sync_fifo_80_inst/data_out
add wave -noupdate -expand -group Sync_fifo2 /tb/DUT/sync_fifo_inst/wr
add wave -noupdate -expand -group Sync_fifo2 -radix unsigned /tb/DUT/sync_fifo_inst/data_in
add wave -noupdate -expand -group Sync_fifo2 /tb/DUT/sync_fifo_inst/rd
add wave -noupdate -expand -group Sync_fifo2 -radix unsigned /tb/DUT/sync_fifo_inst/data_out
add wave -noupdate /tb/DUT/rd_location_unpak_fifo
add wave -noupdate -radix unsigned /tb/DUT/extr_count
add wave -noupdate -radix unsigned /tb/DUT/ones_count_loc_num
add wave -noupdate /tb/DUT/location_unpak_fifo_empty
add wave -noupdate /tb/DUT/push_zero_location
add wave -noupdate /tb/DUT/wr_location_unpak_fifo
add wave -noupdate /tb/DUT/location_unpak_din
add wave -noupdate /tb/DUT/unpk_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {38909 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 213
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {25351 ps} {26881 ps}
