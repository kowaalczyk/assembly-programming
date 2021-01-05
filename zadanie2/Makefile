all: pollution

pollution.o: pollution.asm
	nasm -f elf64 -F dwarf -g $<

pollution: pollution-main.c pollution.o
	gcc -o $@ $^ -no-pie

clean:
	rm -f *.o pollution
