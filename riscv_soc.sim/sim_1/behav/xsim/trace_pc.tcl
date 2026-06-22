open_wave_database top_behav.wdb
set ns [get_nets -hierarchical -filter {NAME =~ */dp/PCF_o}]
puts "PC net: $ns"
set filt [filter $ns {VALUE != x}]
puts "Total signals: [llength $ns]"

# Print waveform samples every 10ns for first 100ns
for {set t 0} {$t < 200} {incr t 10} {
    set pc [get_value -time "${t}ns" [lindex $ns 0]]
    puts "t=${t}ns  PC=$pc"
}
