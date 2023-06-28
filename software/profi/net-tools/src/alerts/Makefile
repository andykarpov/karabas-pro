all:
	@echo "To make alerts please select target"
	@echo ""
	@echo "make karabaspro - to make TR-DOS version for karabas-pro with UNO UART"
	@echo "make karabaspro-zifi - to make TR-DOS version for karabas-pro with ZIFI UART"

karabaspro: *.asm
	sjasmplus -DUNO -DPROFISCR main.asm

karabaspro-zifi: *.asm
	sjasmplus -DZIFI -DPROFISCR main.asm

karabaspro-spec: *.asm
	sjasmplus -DUNO main.asm

karabaspro-zifi-spec: *.asm
	sjasmplus -DZIFI main.asm

karabaspro-debug: *.asm
	sjasmplus -DDEBUG -DZIFI -DPROFISCR main.asm
	wine /home/andy/Downloads/unreal/unreal.exe alerts.sna

karabaspro-debug-spec: *.asm
	sjasmplus -DDEBUG -DZIFI main.asm
	wine /home/andy/Downloads/unreal/unreal.exe alerts.sna

clean:
	rm alerts.bin *.tap alerts.?c alerts.sna

