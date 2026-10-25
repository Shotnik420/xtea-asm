all:
	nasm -f elf64 main.asm -o main.o
	gcc main.o -no-pie -o xtea_app

clean:
	rm -f main.o xtea_app
