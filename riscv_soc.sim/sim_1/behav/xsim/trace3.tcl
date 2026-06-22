run 0
puts "Starting trace..."
for {set c 0} {$c < 30} {incr c} {
    run 2ns
    set pc  [get_value -radix hex [get_nets -hierarchical {*dp/PCF_o}]]
    set stF [get_value [get_nets -hierarchical {*dp/StallF_i}]]
    set mpE [get_value [get_nets -hierarchical {*dp/MisspredictE_o}]]
    set f3E [get_value -radix hex [get_nets -hierarchical {*dp/funct3E}]]
    set btE [get_value [get_nets -hierarchical {*dp/BranchTakenE_o}]]
    set brE [get_value [get_nets -hierarchical {*dp/BranchE_i}]]
    set jeE [get_value [get_nets -hierarchical {*dp/JumpE_i}]]
    puts "c=$c PC=$pc stF=$stF mpE=$mpE f3E=$f3E btE=$btE brE=$brE jeE=$jeE"
}
exit
