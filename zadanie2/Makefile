all: pollution

pollution.o: pollution.asm
	nasm -f elf64 -F dwarf -g $<

pollution: pollution-main.c pollution.o
	gcc -o $@ $^ -no-pie -g

clean:
	rm -f *.o pollution
