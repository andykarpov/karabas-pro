BINARY=wget.com
ZIBINARY=ziwget.com

all: $(BINARY) $(ZIBINARY)

$(BINARY):
	sjasmplus -DUNO main.asm

$(ZIBINARY):
	sjasmplus -DZIFI main.asm

clean:
	rm $(BINARY) $(ZIBINARY)
