all: lec7_1.c
	@echo "====================================="
	@echo "compile and analysis lec7_2"
	@echo "====================================="
	gcc -g -o lec7_2 lec7_2-fork.c
	@echo "====================================="
	@echo "compile and analysis lec7_1"
	@echo "====================================="
	gcc -g -o lec7_1 lec7_1.c
	@echo "====================================="
	@echo "using objdump to decompile lec7_1"
	@echo "====================================="
	objdump -S lec7_1
	@echo "====================================="
	@echo "using readelf to analyze lec7_1"
	@echo "====================================="
	readelf -a lec7_1
	@echo "====================================="
	@echo "using nm to analyze lec7_1"
	@echo "====================================="
	nm lec7_1
process_state:
	top
clean:
	rm ./lec7_1 ./lec7_2
