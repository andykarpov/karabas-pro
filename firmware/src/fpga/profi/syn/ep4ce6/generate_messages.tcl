set input [open ../../rtl/video/messages.txt rb]
set fp [open ../../rtl/video/messages.mif w]

set timestamp_decimal [clock format [clock seconds] -format {%y %m %d %H}]
set fields [split $timestamp_decimal " "]
set year [split [lindex $fields 0] ""]
set month [split [lindex $fields 1] ""]
set day [split [lindex $fields 2] ""]
set hour [split [lindex $fields 3] ""]
set romsize 248

puts $fp "-- VERSION = $year $month $day $hour"
puts $fp "-- messsages.mif file"
puts $fp "DEPTH = 256;                  -- The size of memory in words"
puts $fp "WIDTH = 8;                    -- The size of data in bits"
puts $fp "ADDRESS_RADIX = DEC;          -- The radix for address values"
puts $fp "DATA_RADIX = HEX;             -- The radix for data values"
puts $fp "CONTENT                       -- start of (address : data pairs)"
puts $fp "BEGIN"
puts $fp ""
puts $fp "                        -- memory address : data"

# read messages.txt file into $bytes
set bytes [read $input $romsize]

# dump messages.txt into mif file as hex values
for {set i 0} { $i < $romsize} {incr i} {
	binary scan [string index $bytes $i] H2 cc
	puts $fp "$i : $cc;"
}

# dump timestamp into mif as hex values (ascii digits started from index 48)
puts $fp "248 : [format %02x [expr [lindex $year 0] + 48]];"
puts $fp "249 : [format %02x [expr [lindex $year 1] + 48]];"
puts $fp "250 : [format %02x [expr [lindex $month 0] + 48]];"
puts $fp "251 : [format %02x [expr [lindex $month 1] + 48]];"
puts $fp "252 : [format %02x [expr [lindex $day 0] + 48]];"
puts $fp "253 : [format %02x [expr [lindex $day 1] + 48]];"
puts $fp "254 : [format %02x [expr [lindex $hour 0] + 48]];"
puts $fp "255 : [format %02x [expr [lindex $hour 1] + 48]];"

puts $fp ""
puts $fp "END;"

close $fp
close $input
