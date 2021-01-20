all: conway conway-test

conway.o: conway.asm
	nasm -f elf64 -F dwarf -g $<

conway: conwaymain.c conway.o
	gcc -o $@ $^ -no-pie

conway-test: conwaytest.c conway.o
	gcc -o $@ $^ -no-pie -g

clean:
	rm -f *.o conway conway-test
