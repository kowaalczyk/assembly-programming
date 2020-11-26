all: conway

conway.o: conway.asm
	nasm -f elf64 -F dwarf -g $<

conway: conwaymain.c conway.o
	gcc -o conway conwaymain.c conway.o -no-pie -g

clean:
	rm -f *.o
