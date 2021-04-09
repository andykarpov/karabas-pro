# Инструкция по прошивке Karabas-Pro для Kalantaj

## Как прошить FPGA и CPLD в карабас-про

0) Воткни USB Blaster в 10-контактный разъем
1) Открой в Quartus Programmer файл karabas_pro_tda1543.cdf или karabas_pro_tda1543a.cdf (зависит от того, какой у тебя ЦАП на плате)
2) Отметь галочками, какие чипы (все) шьешь (EPM3128, EP4CE6, EPCS16 итп), затем жмякай на Program button

## Как прошить мегу:

Воткни свой программатор в 6-контактный разъем

Шей файл karabas_pro.hex, если у тебя ревизия платы C.
Шей файл karabas_pro_revA.hex, если у тебя старая revA без доделок.
Шей файл karabas_pro_revD.hex, если у тебя новая rev.D с кучей светиков.

**Фьюзы**

(Если у тебя не дудка, а другой софт - просто выставляй фьюзы)

- Low: 0xFF
- High: 0xDE
- Extended: 0xFD

### Пример вызова дудки:

`avrdude -c usbasp -p m328p -U flash:w:karabas_pro.hex -U lfuse:w:0xFF:m -U hfuse:w:0xDE:m -U efuse:w:0xFD:m`

Важно: efuse можно не шить, с ним бывают траблы.
Тогда так: `avrdude -c usbasp -p m328p -U flash:w:karabas_pro.hex -U lfuse:w:0xFF:m -U hfuse:w:0xDE:m`

После шитья - передерни. питание.

Все :)
