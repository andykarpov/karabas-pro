# Pin timing (tsu / th / tco at the pins) of a project, slow and fast models.
# For the external interfaces, which have no set_input_delay / set_output_delay:
# the times are relative to the input clock pin, so ports can be compared with
# each other (e.g. SD against CPLD_CLK) and with the other chip's own report.
#
# Usage (in the project directory, after a build):
#   quartus_sta -t <repo>/scripts/timing/datasheet.tcl <project>
# Writes datasheet_slow.txt and datasheet_fast.txt.
set prj [lindex $quartus(args) 0]
project_open $prj
foreach m {slow fast} {
  create_timing_netlist -model $m
  read_sdc
  update_timing_netlist
  report_datasheet -file datasheet_$m.txt
  delete_timing_netlist
}
