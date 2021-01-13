all: karabas-pro

player.bin:
	sjasmplus vtpl.asm

karabas-pro: *.asm font.bin player.bin
	sjasmplus -DUNO -DTRDOS main.asm

clean: 
	rm ugophy.?c player.bin