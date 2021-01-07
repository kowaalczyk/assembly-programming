all: pollution

pollution.o: pollution.asm
	nasm -f elf64 -F dwarf $<

pollution: pollution-main.c pollution.o
	gcc -no-pie -o $@ $^

clean:
	rm -f *.o pollution
