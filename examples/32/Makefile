all: trzy array_sum

trzy: trzymain.c trzy.o
	gcc -m32 -o trzy trzymain.c trzy.o

array_sum: array_sum.c array_fsum.o
	gcc -m32 -o array_sum array_sum.c array_fsum.o

.SECONDARY:

%.o: %.asm
	nasm -f elf32 $<


%: %.o
	ld -m elf_i386 $< -o $@ -lc --dynamic-linker=/lib/ld-linux.so.2


clean:
	rm -f *.o

