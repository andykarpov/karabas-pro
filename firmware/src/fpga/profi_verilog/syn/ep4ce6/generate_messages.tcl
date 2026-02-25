set fp [open ../../rtl/video/messages.mif w]

set timestamp_decimal [clock format [clock seconds] -format {%y %m %d %H}]
set fields [split $timestamp_decimal " "]
set year [split [lindex $fields 0] ""]
set month [split [lindex $fields 1] ""]
set day [split [lindex $fields 2] ""]
set hour [split [lindex $fields 3] ""]

puts $fp "-- VERSION = $year $month $day $hour"
puts $fp "-- messsages.mif file"
puts $fp "DEPTH = 8;                  -- The size of memory in words"
puts $fp "WIDTH = 8;                    -- The size of data in bits"
puts $fp "ADDRESS_RADIX = DEC;          -- The radix for address values"
puts $fp "DATA_RADIX = HEX;             -- The radix for data values"
puts $fp "CONTENT                       -- start of (address : data pairs)"
puts $fp "BEGIN"
puts $fp ""
puts $fp "                        -- memory address : data"

# dump timestamp into mif as hex values
puts $fp "0 : [format %02x [expr [lindex $year 0] + 48]];"
puts $fp "1 : [format %02x [expr [lindex $year 1] + 48]];"
puts $fp "2 : [format %02x [expr [lindex $month 0] + 48]];"
puts $fp "3 : [format %02x [expr [lindex $month 1] + 48]];"
puts $fp "4 : [format %02x [expr [lindex $day 0] + 48]];"
puts $fp "5 : [format %02x [expr [lindex $day 1] + 48]];"
puts $fp "6 : [format %02x [expr [lindex $hour 0] + 48]];"
puts $fp "7 : [format %02x [expr [lindex $hour 1] + 48]];"

puts $fp ""
puts $fp "END;"

close $fp