all: brightness

brightness: brightness-main.c ppm.o brightness.o
	gcc -g -o $@ $^

brightness.o: brightness.s
	as -g -o $@ $<

ppm.o: ppm.c ppm.h
	gcc -c -g -o $@ $<

clean:
	rm -vf brightness *.o

# [extra]: run all tests
test: brightness
	./test.sh
