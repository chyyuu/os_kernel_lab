all: lab1-ex0.exe lab1-ex1.exe lab1-ex3.s

lab1-ex0.exe: defines.h lab1-ex0.s
	gcc  -m32 -g  -o lab1-ex0.exe lab1-ex0.s
	strace -f ./lab1-ex0.exe
	
lab1-ex1.exe: lab1-ex1.c
	echo "compile and watch the syscalls from lab1-ex1"
	gcc -m32 -o lab1-ex1.exe lab1-ex1.c
	strace -c ./lab1-ex1.exe
	echo "watch the interrupts in linux"
	more /proc/interrupts

lab1-ex3.s: lab1-ex3.c
	echo "show .s files"
	gcc -m32 -S lab1-ex3.c
	
clean:
	rm  lab1-ex0.exe lab1-ex1.exe lab1-ex3.s
