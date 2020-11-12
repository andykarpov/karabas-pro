# ERRATA rev.C

1) Some SD cards seems conflicts with SPI flash.
Solution: cut a wire from SD card pin 2 (CMD) to ASDO, reroute that SD card pin 2 (CMD) to the FPGA PIN_115.
2) CF card power supply should be changed to 3.3V by cutting 5V track and reroute it to the 3.3V rail.
3) CF card pin 44 (/REG) should be pulled up to 3.3V.

