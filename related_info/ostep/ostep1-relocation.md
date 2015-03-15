
This program allows you to see how address translations are performed in a
system with base and bounds registers. As before, there are two steps to
running the program to test out your understanding of base and bounds. First,
run without the -c flag to generate a set of translations and see if you can
correctly perform the address translations yourself. Then, when done, run with
the -c flag to check your answers.

In this homework, we will assume a slightly different address space than our
canonical one with a heap and stack at opposite ends of the space. Rather, we
will assume that the address space has a code section, then a fixed-sized
(small) stack, and a heap that grows downward right after, looking something
like you see in the Figure below. In this configuration, there is only one
direction of growth, towards higher regions of the address space.

  -------------- 0KB
  |    Code    |
  -------------- 2KB
  |   Stack    |
  -------------- 4KB
  |    Heap    |
  |     |      |
  |     v      |
  -------------- 7KB
  |   (free)   |
  |     ...    |

In the figure, the bounds register would be set to 7~KB, as that represents
the end of the address space. References to any address within the bounds
would be considered legal; references above this value are out of bounds and
thus the hardware would raise an exception.

To run with the default flags, type relocation.py at the command line. The
result should be something like this:

prompt> ./relocation.py 
...
Base-and-Bounds register information:

  Base   : 0x00003082 (decimal 12418)
  Limit  : 472

Virtual Address Trace
  VA  0: 0x01ae (decimal:430) -> PA or violation?
  VA  1: 0x0109 (decimal:265) -> PA or violation?
  VA  2: 0x020b (decimal:523) -> PA or violation?
  VA  3: 0x019e (decimal:414) -> PA or violation?
  VA  4: 0x0322 (decimal:802) -> PA or violation?

For each virtual address, either write down the physical address it 
translates to OR write down that it is an out-of-bounds address 
(a segmentation violation). For this problem, you should assume a 
simple virtual address space of a given size.

As you can see, the homework simply generates randomized virtual
addresses. For each, you should determine whether it is in bounds, and if so,
determine to which physical address it translates. Running with -c (the
"compute this for me" flag) gives us the results of these translations, i.e.,
whether they are valid or not, and if valid, the resulting physical
addresses. For convenience, all numbers are given both in hex and decimal.

prompt> ./relocation.py -c
...
Virtual Address Trace
  VA  0: 0x01ae (decimal:430) -> VALID: 0x00003230 (dec:12848)
  VA  1: 0x0109 (decimal:265) -> VALID: 0x0000318b (dec:12683)
  VA  2: 0x020b (decimal:523) -> SEGMENTATION VIOLATION
  VA  3: 0x019e (decimal:414) -> VALID: 0x00003220 (dec:12832)
  VA  4: 0x0322 (decimal:802) -> SEGMENTATION VIOLATION
]

With a base address of 12418 (decimal), address 430 is within bounds (i.e., it
is less than the limit register of 472) and thus translates to 430 added to
12418 or 12848. A few of the addresses shown above are out of bounds (523,
802), as they are in excess of the bounds. Pretty simple, no? Indeed, that is
one of the beauties of base and bounds: it's so darn simple!

There are a few flags you can use to control what's going on better:

prompt> ./relocation.py -h
Usage: relocation.py [options]

Options:
  -h, --help            show this help message and exit
  -s SEED, --seed=SEED  the random seed
  -a ASIZE, --asize=ASIZE address space size (e.g., 16, 64k, 32m)
  -p PSIZE, --physmem=PSIZE physical memory size (e.g., 16, 64k)
  -n NUM, --addresses=NUM # of virtual addresses to generate
  -b BASE, --b=BASE     value of base register
  -l LIMIT, --l=LIMIT   value of limit register
  -c, --compute         compute answers for me
]

In particular, you can control the virtual address-space size (-a), the size
of physical memory (-p), the number of virtual addresses to generate (-n), and
the values of the base and bounds registers for this process (-b and -l,
respectively).

