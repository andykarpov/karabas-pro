# описание входных клоков
#create_clock -period 50MHz -name {CLK_50MHZ} [get_ports {CLK_50MHZ}]
#create_clock -period 30MHz -name {MCU_SCK} [get_ports {MCU_SCK}]

# pll-ные клоки сгенерятся сами
derive_pll_clocks

# clock uncertainty
derive_clock_uncertainty

# описание отношений между клоками
#set_clock_groups -exclusive -group {CLK_50MHZ} -group {MCU_SCK}
