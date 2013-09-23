all: hello.c
	echo "compile and watch the syscalls from hello"
	gcc -o hello hello.c
	strace -c ./hello
	echo "watch the interrupts in linux"
	more /proc/interrupts
clean:
	rm ./hello
