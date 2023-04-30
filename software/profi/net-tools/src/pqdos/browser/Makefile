SOURCES=$(shell find . -type f -iname  "*.asm")
BINARY=moonr.com
ZIBINARY=zimoonr.com
LST=main.lst
all: $(BINARY) $(ZIBINARY)

$(ZIBINARY):
	sjasmplus -DZIFI main.asm --lst=main.lst

$(BINARY): $(SOURCES)
	sjasmplus -DUNO main.asm --lst=main.lst

clean:
	rm $(BINARY) $(ZIBINARY) $(LST)
