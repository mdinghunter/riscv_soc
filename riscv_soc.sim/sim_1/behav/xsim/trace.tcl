# Print the PC and imem output at each negedge for 20 cycles
run 3ns
for {set i 0} {$i < 15} {incr i} {
    run 2ns
    set pc [get_value {/top_tb/current_pc}]
    set instr [get_value {/top_tb/top/imem/a_rd_o}]
    set stall [get_value {/top_tb/top/riscv/dp/StallF_i}]
    puts "t=[current_time] pc=$pc instr=$instr stall=$stall"
}
