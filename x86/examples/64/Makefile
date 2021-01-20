all: trzy array_sum array_sum_sse quad_roots dmax quad_roots_sse

trzy: trzymain.c trzy.o
	gcc -o trzy trzymain.c trzy.o

dmax: dmaxmain.c dmax.o
	gcc -o dmax dmaxmain.c dmax.o

array_sum: array_sum.c array_fsum.o
	gcc -o array_sum array_sum.c array_fsum.o

array_sum_sse: array_sum.c array_fsum_sse.o
	gcc -o array_sum_sse array_sum.c array_fsum_sse.o

quad_roots: quad_roots_test.c quad_roots.o
	gcc -g -o quad_roots quad_roots_test.c quad_roots.o

quad_roots_sse: quad_roots_test.c quad_roots_sse.o
	gcc -g -o quad_roots_sse quad_roots_test.c quad_roots_sse.o

.SECONDARY:

%.o: %.asm
	nasm -f elf64 -F dwarf -g $<


%: %.o
	ld $< -o $@ -lc --dynamic-linker=/lib64/ld-linux-x86-64.so.2


clean:
	rm -f *.o

