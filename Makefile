CC = gcc
ASM = nasm
ASMFLAGS = -f elf64
LDFLAGS = -no-pie

all: xtea-gui

xtea-gui: main.o xtea.o
	$(CC) $(LDFLAGS) main.o xtea.o -o xtea-gui

main.o: main.asm
	$(ASM) $(ASMFLAGS) main.asm

xtea.o: xtea.asm
	$(ASM) $(ASMFLAGS) xtea.asm

clean:
	rm -f *.o xtea-gui