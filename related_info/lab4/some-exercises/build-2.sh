as  -gstabs --32 -o callee.o callee.s
gcc -m32 -g -c -fno-stack-protector caller.c
gcc -m32 -g -o caller caller.o callee.o
