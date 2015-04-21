binaries=memory.o main.o

all:
	gcc -g -ansi -c *.c main.c #-m32: this makes a 32-bit build, but you might have to "sudo apt-get install libc6-dev-i386" first
	echo Compiling done

	gcc -g -ansi *.o -o main
	echo Linking done

	#make clean #uncomment this if you don't care to debug, symbols and all

clean:
	rm -f $(binaries)
	echo Clean done 