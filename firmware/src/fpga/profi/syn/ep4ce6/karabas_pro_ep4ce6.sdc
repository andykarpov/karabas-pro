# описание входных клоков
create_clock -period 50MHz -name {CLK_50MHZ} [get_ports {CLK_50MHZ}]
create_clock -period 1MHz -name {AVR_SCK} [get_ports {AVR_SCK}]

# pll-ные клоки сгенерятся сами
derive_pll_clocks

# clock uncertainty
derive_clock_uncertainty

# клоки, порожденные дизайном
# TODO: стробы CPU, используемые как клоки (T80a M1_n, WR_n_i, MREQ), пока не описаны

create_generated_clock -name {clk_14} -divide_by 2 -source [get_pins {U2|altpll_component|auto_generated|pll1|clk[2]}] [get_registers {clk_div2}]
create_generated_clock -name {clk_12} -divide_by 2 -source [get_pins {U2|altpll_component|auto_generated|pll1|clk[3]}] [get_registers {clk_div2}] -add

# описание отношений между клоками
# Режимы тактирования (ds80 переключает оба altclkctrl одновременно):
#   ds80=0: clk_bus = 28 МГц (pll c2) -> clk_14;  clk_bus_port = 84 МГц (pll c0)
#   ds80=1: clk_bus = 24 МГц (pll c3) -> clk_12;  clk_bus_port = 72 МГц (pll c1)
# Клоки разных режимов никогда не работают одновременно, пути между ними
# не существуют (например 72 <- 28 или 24 <- 14).
set_clock_groups -exclusive \
	-group {U2|altpll_component|auto_generated|pll1|clk[0] U2|altpll_component|auto_generated|pll1|clk[2] clk_14} \
	-group {U2|altpll_component|auto_generated|pll1|clk[1] U2|altpll_component|auto_generated|pll1|clk[3] clk_12}

# AVR_SCK асинхронен всем внутренним клокам. Обмен с SPI-доменом идёт через
# синхронизаторы spi_slave (do_valid_A..D, di_req_o_A..D, wren_*): данные
# do_buffer_reg / di_reg стабильны всё время, пока строб проходит синхронизатор.
set_clock_groups -asynchronous \
	-group {AVR_SCK} \
	-group {CLK_50MHZ U2|altpll_component|auto_generated|pll1|clk[*] clk_14 clk_12}

# описание путей, которые не нужно анализировать
set_false_path -from [get_registers {port_dffd_reg[*]}] -to *
#set_false_path -from * -to [get_ports {VGA_*}]
set_false_path -from * -to [get_ports {SND_*}]
set_false_path -from * -to [get_ports {UART_TX}]
set_false_path -from * -to [get_ports {UART_CTS}]
set_false_path -from [get_ports {UART_RX}] -to *

