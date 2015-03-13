all:pmboot
pmboot.s: pmboot.S
	gcc  -E  pmboot.S > pmboot.s
pmboot.o: pmboot.s
	as -o pmboot.o pmboot.s
pmboot: pmboot.o	
	ld --oformat binary -N -e start -Ttext 0x7c00 -o pmboot pmboot.o
run: pmboot
	qemu-system-i386 -fda pmboot
.PHONY: clean
clean:
	rm pmboot.o pmboot pmboot.s
