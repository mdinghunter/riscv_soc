run 0
puts "=== PC trace ==="
for {set cyc 0} {$cyc < 20} {incr cyc} {
    run 2ns
    set pc   [get_value [get_nets -hierarchical {*dp/PCF_o}]]
    set instr [get_value [get_nets -hierarchical {*dp/InstrD}]]
    set br   [get_value [get_nets -hierarchical {*dp/BranchTakenE_o}]]
    set mp   [get_value [get_nets -hierarchical {*dp/MisspredictE_o}]]
    set je   [get_value [get_nets -hierarchical {*dp/JumpE_i}]]
    set f3e  [get_value [get_nets -hierarchical {*dp/funct3E}]]
    puts "cyc=$cyc  PC=$pc  InstrD=$instr  f3E=$f3e  BrTaken=$br  MP=$mp  JE=$je"
}
exit
