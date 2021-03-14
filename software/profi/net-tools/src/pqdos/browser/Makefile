SOURCES=$(shell find . -type f -iname  "*.asm")
BINARY=moonr.com
LST=main.lst
all: $(BINARY)

	
$(BINARY): $(SOURCES)
	sjasmplus main.asm --lst=main.lst

clean:
	rm $(BINARY) $(LST)