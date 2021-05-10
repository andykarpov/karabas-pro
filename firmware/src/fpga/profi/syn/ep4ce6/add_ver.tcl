project_open karabas_pro_ep4ce6

set now [clock seconds]
set timestr [clock format $now -format "%y%m%d%H"]
set_parameter -name build_version $timestr

project_close
