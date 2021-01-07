all: pollution

pollution.o: pollution.asm
	nasm -f elf64 -F dwarf -g $<

# main executable:
pollution: pollution-main.c pollution.o
	gcc -no-pie -g -o $@ $^

# extra - run tests:
test: pollution
	./test.sh

# extra - run quick benchmarks (requires external dependencies to be installed):
bench: pollution
	./bench.sh > bench.log

# extra - run all benchmarks (requires external dependencies to be installed):
long-bench: pollution
	LONG=1 ./bench.sh > long-bench.log

clean:
	rm -f *.o pollution
