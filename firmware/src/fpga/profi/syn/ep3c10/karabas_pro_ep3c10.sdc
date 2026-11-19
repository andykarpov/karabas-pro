# описание входных клоков
create_clock -period 50MHz -name {CLK_50MHZ} [get_ports {CLK_50MHZ}]
# AVR_SCK: up to 8 MHz (fosc/2 of the ATmega328P), docs/AVR_LINK_V2.md
create_clock -period 8MHz -name {AVR_SCK} [get_ports {AVR_SCK}]

# pll-ные клоки сгенерятся сами
derive_pll_clocks

# clock uncertainty
derive_clock_uncertainty

# клоки, порожденные дизайном: нет (clk_div2 и clk_div4 — только сигналы разрешения)
# TODO: стробы CPU, используемые как клоки (T80a M1_n, WR_n_i, MREQ), пока не описаны


# описание отношений между клоками
# Режимы тактирования (ds80 переключает оба altclkctrl одновременно):
#   ds80=0: clk_bus = 28 МГц (pll c2), clk_bus_port = 84 МГц (pll c0)
#   ds80=1: clk_bus = 24 МГц (pll c3), clk_bus_port = 72 МГц (pll c1)
# Клоки разных режимов никогда не работают одновременно, пути между ними
# не существуют (например 72 <- 28 или 84 <- 24).
set_clock_groups -exclusive \
	-group {U2|altpll_component|auto_generated|pll1|clk[0] U2|altpll_component|auto_generated|pll1|clk[2]} \
	-group {U2|altpll_component|auto_generated|pll1|clk[1] U2|altpll_component|auto_generated|pll1|clk[3]}

# AVR_SCK асинхронен всем внутренним клокам. Обмен с SPI-доменом avr_link.v (как
# kg_l2_link Karabas Go): байт держится в byte_hold 8 периодов SCK, в clk_bus его
# видно по переключателю byte_tgl через три триггера; ответ di clk_bus пишет после
# этого, а в сдвиговый регистр он грузится по спаду SCK в конце следующего байта.
set_clock_groups -asynchronous \
	-group {AVR_SCK} \
	-group {CLK_50MHZ U2|altpll_component|auto_generated|pll1|clk[*]}

# описание путей, которые не нужно анализировать
set_false_path -from [get_registers {port_dffd_reg[*]}] -to *
set_false_path -from * -to [get_ports {VGA_*}]
set_false_path -from * -to [get_ports {SND_*}]
set_false_path -from * -to [get_ports {UART_TX}]
set_false_path -from * -to [get_ports {UART_CTS}]
set_false_path -from [get_ports {UART_RX}] -to *

