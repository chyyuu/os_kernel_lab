all:toy
toy.o: toy.S
	as -o toy.o toy.S
toy: toy.o	
	ld --oformat binary -N -e start -Ttext 0x7c00 -o toy toy.o
run: toy
	qemu-system-i386 -fda toy
clean:
	rm toy.o toy
