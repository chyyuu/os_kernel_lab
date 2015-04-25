all:bt
buddy2.o: buddy2.c buddy2.h
	gcc -c -o buddy2.o buddy2.c
buddy2_test.o: buddy2_test.c buddy2.h
	gcc -c -o buddy2_test.o buddy2_test.c
bt: buddy2.o buddy2_test.o
	gcc -o bt buddy2_test.o buddy2.o
.PHONY: clean
clean:
	rm bt *.o
