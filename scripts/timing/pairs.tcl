# Worst slack for every pair of clocks, slow and fast models, setup and hold,
# plus every failing path (one per endpoint) in the slow model.
#
# Usage: quartus_sta -t pairs.tcl <project> <pairs_out> <failing_out>
#
# pairs_out line:   <model> <setup|hold> <to_clock> <- <from_clock> <slack>  <from_node> -> <to_node>
# failing_out line: <setup|hold>\t<to_clock>\t<from_clock>\t<slack>\t<from_node>\t<to_node>
# PLL clock names are shortened to clk[N].
set prj [lindex $quartus(args) 0]
set out [lindex $quartus(args) 1]
set fail [lindex $quartus(args) 2]
project_open $prj

proc short {c} {
  regsub -all {U2\|altpll_component\|auto_generated\|pll1\|} $c "" c
  return $c
}

set fh [open $out w]
set ff [open $fail w]
foreach model {slow fast} {
  create_timing_netlist -model $model
  read_sdc
  update_timing_netlist
  set cl {}
  foreach_in_collection c [get_clocks *] { lappend cl [get_clock_info -name $c] }
  foreach kind {setup hold} {
    foreach t $cl {
      foreach f $cl {
        foreach_in_collection x [get_timing_paths -$kind -from_clock $f -to_clock $t -npaths 1] {
          puts $fh [format "%-4s %-5s %-8s <- %-8s %8.3f  %s -> %s" $model $kind [short $t] [short $f] \
            [get_path_info -slack $x] [get_node_info -name [get_path_info -from $x]] [get_node_info -name [get_path_info -to $x]]]
        }
      }
      if {$model eq "slow"} {
        foreach_in_collection x [get_timing_paths -$kind -to_clock $t -npaths 1000 -nworst 1 -less_than_slack 0] {
          puts $ff "$kind\t[short $t]\t[short [get_clock_info -name [get_path_info -from_clock $x]]]\t[get_path_info -slack $x]\t[get_node_info -name [get_path_info -from $x]]\t[get_node_info -name [get_path_info -to $x]]"
        }
      }
    }
  }
  delete_timing_netlist
}
close $fh
close $ff
