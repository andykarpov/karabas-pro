# описание входных клоков
create_clock -period 50MHz -name {CLK_50MHZ} [get_ports {CLK_50MHZ}]
create_clock -period 1MHz -name {AVR_SCK} [get_ports {AVR_SCK}]

# pll-ные клоки сгенерятся сами
derive_pll_clocks

# clock uncertainty
derive_clock_uncertainty

# клоки, порожденные дизайном
# TODO:
# T80aw:U5|T80a:u0|T80:u0|M1_n
# T80aw:U5|T80a:u0|WR_n_i
# VGA_PAL:U9|VIDEO_H[8]
# VGA_PAL:U9|VGA_H[7]

create_generated_clock -name {clk_14} -divide_by 2 -source [get_pins {U2|altpll_component|auto_generated|pll1|clk[2]}] [get_registers {clk_div2}]
create_generated_clock -name {clk_7} -divide_by 4 -source [get_pins {U2|altpll_component|auto_generated|pll1|clk[2]}] [get_registers {clk_div4}]
create_generated_clock -name {clk_12} -divide_by 2 -source [get_pins {U2|altpll_component|auto_generated|pll1|clk[3]}] [get_registers {clk_div2}] -add
create_generated_clock -name {clk_6} -divide_by 4 -source [get_pins {U2|altpll_component|auto_generated|pll1|clk[3]}] [get_registers {clk_div4}] -add

# описание отношений между клоками
set_clock_groups -exclusive -group {CLK_50MHZ} -group {AVR_SCK}
set_clock_groups -exclusive -group {clk_14} -group {clk_12}
set_clock_groups -exclusive -group {clk_7} -group {clk_6}
set_clock_groups -exclusive -group {U2|altpll_component|auto_generated|pll1|clk[0]} -group {U2|altpll_component|auto_generated|pll1|clk[1]}
set_clock_groups -exclusive -group {U2|altpll_component|auto_generated|pll1|clk[2]} -group {U2|altpll_component|auto_generated|pll1|clk[3]}

# описание путей, которые не нужно анализировать
set_false_path -from [get_registers {port_dffd_reg[*]}] -to *
set_false_path -from [get_registers {port_008b_reg[*]}] -to *
set_false_path -from [get_registers {port_018b_reg[*]}] -to *
set_false_path -from [get_registers {port_028b_reg[*]}] -to *
set_false_path -from * -to [get_ports {VGA_*}]
set_false_path -from * -to [get_ports {SND_*}]
set_false_path -from [get_ports {SW3[*]}] -to *
set_false_path -from * -to [get_ports {UART_TX}]
set_false_path -from * -to [get_ports {UART_CTS}]
set_false_path -from [get_ports {UART_RX}] -to *
set_false_path -from [get_ports {avr:U15|SOFT_SW[*]}] -to *
set_false_path -from [get_registers {osd:U8|line2[*]}] -to *

