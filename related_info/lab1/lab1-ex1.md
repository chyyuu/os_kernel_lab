# 
Try below command

```
echo "compile and watch the syscalls from lab1-ex1"
gcc -o lab1-ex1.exe lab1-ex1.c
strace -c ./lab1-ex1.exe
echo "watch the interrupts in linux"
more /proc/interrupts
```

Try to analysis the means of these output log. 
