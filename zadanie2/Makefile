all: pollution

pollution.o: pollution.asm
	nasm -f elf64 -F dwarf -g $<

pollution: pollution-main.c pollution.o
	gcc -no-pie -g -o $@ $^

clean:
	rm -f *.o pollution
