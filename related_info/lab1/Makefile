all: lab1-ex0.exe lab1-ex1.exe

lab1-ex0.exe: defines.h lab1-ex0.s
	gcc -g  -o lab1-ex0.exe lab1-ex0.s
	
lab1-ex1.exe: lab1-ex1.c
	echo "compile and watch the syscalls from lab1-ex1"
	gcc -o lab1-ex1.exe lab1-ex1.c
	strace -c ./lab1-ex1.exe
	echo "watch the interrupts in linux"
	more /proc/interrupts
	
clean:
	rm  lab1-ex0.exe lab1-ex1.exe
