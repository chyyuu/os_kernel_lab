#README
analysis lab0_ex5
```
echo "compile and analysis lab0_ex5"
echo "====================================="
gcc -m32 -g -o lab0_ex5.exe lab0_ex5.c
echo "====================================="
echo "using objdump to decompile lab0_ex5"
echo "====================================="
objdump -S lab0_ex5.exe 
echo "====================================="
echo "using readelf to analyze lab0_ex5"
echo "====================================="
readelf -a lab0_ex5.exe
echo "====================================="
echo "using nm to analyze lab0_ex5"
echo "====================================="
nm lab0_ex5.exe
```
