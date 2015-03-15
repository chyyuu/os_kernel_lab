
This simulator, paging-policy.py, allows you to play around with different
page-replacement policies. For example, let's examine how LRU performs with a
series of page references with a cache of size 3:

  0 1 2 0 1 3 0 3 1 2 1

To do so, run the simulator as follows:

prompt> ./paging-policy.py --addresses=0,1,2,0,1,3,0,3,1,2,1 
                           --policy=LRU --cachesize=3 -c

And what you would see is:

ARG addresses 0,1,2,0,1,3,0,3,1,2,1
ARG numaddrs 10
ARG policy LRU
ARG cachesize 3
ARG maxpage 10
ARG seed 0

Solving...

Access: 0 MISS LRU->      [br 0]<-MRU Replace:- [br Hits:0 Misses:1]
Access: 1 MISS LRU->   [br 0, 1]<-MRU Replace:- [br Hits:0 Misses:2]
Access: 2 MISS LRU->[br 0, 1, 2]<-MRU Replace:- [br Hits:0 Misses:3]
Access: 0 HIT  LRU->[br 1, 2, 0]<-MRU Replace:- [br Hits:1 Misses:3]
Access: 1 HIT  LRU->[br 2, 0, 1]<-MRU Replace:- [br Hits:2 Misses:3]
Access: 3 MISS LRU->[br 0, 1, 3]<-MRU Replace:2 [br Hits:2 Misses:4]
Access: 0 HIT  LRU->[br 1, 3, 0]<-MRU Replace:2 [br Hits:3 Misses:4]
Access: 3 HIT  LRU->[br 1, 0, 3]<-MRU Replace:2 [br Hits:4 Misses:4]
Access: 1 HIT  LRU->[br 0, 3, 1]<-MRU Replace:2 [br Hits:5 Misses:4]
Access: 2 MISS LRU->[br 3, 1, 2]<-MRU Replace:0 [br Hits:5 Misses:5]
Access: 1 HIT  LRU->[br 3, 2, 1]<-MRU Replace:0 [br Hits:6 Misses:5]
]
  
The complete set of possible arguments for paging-policy is listed on the
following page, and includes a number of options for varying the policy, how
addresses are specified/generated, and other important parameters such as the
size of the cache. 

prompt> ./paging-policy.py --help
Usage: paging-policy.py [options]

Options:
-h, --help      show this help message and exit
-a ADDRESSES, --addresses=ADDRESSES
                a set of comma-separated pages to access; 
                -1 means randomly generate
-f ADDRESSFILE, --addressfile=ADDRESSFILE
                a file with a bunch of addresses in it
-n NUMADDRS, --numaddrs=NUMADDRS
                if -a (--addresses) is -1, this is the 
                number of addrs to generate
-p POLICY, --policy=POLICY
                replacement policy: FIFO, LRU, LFU, OPT, 
                                    UNOPT, RAND, CLOCK
-b CLOCKBITS, --clockbits=CLOCKBITS
                for CLOCK policy, how many clock bits to use
-C CACHESIZE, --cachesize=CACHESIZE
                size of the page cache, in pages
-m MAXPAGE, --maxpage=MAXPAGE
                if randomly generating page accesses, 
                this is the max page number
-s SEED, --seed=SEED  random number seed
-N, --notrace   do not print out a detailed trace
-c, --compute   compute answers for me
]
  
As usual, "-c" is used to solve a particular problem, whereas without it, the
accesses are just listed (and the program does not tell you whether or not a
particular access is a hit or miss).

To generate a random problem, instead of using "-a/--addresses" to pass in
some page references, you can instead pass in "-n/--numaddrs" as the number of
addresses the program should randomly generate, with "-s/--seed" used to
specify a different random seed. For example:

prompt> ./paging-policy.py -s 10 -n 3
.. .
Assuming a replacement policy of FIFO, and a cache of size 3 pages,
figure out whether each of the following page references hit or miss
in the page cache.
  
Access: 5  Hit/Miss?  State of Memory?
Access: 4  Hit/Miss?  State of Memory?
Access: 5  Hit/Miss?  State of Memory?
]
  
As you can see, in this example, we specify "-n 3" which means the program
should generate 3 random page references, which it does: 5, 7, and 5. The
random seed is also specified (10), which is what gets us those particular
numbers. After working this out yourself, have the program solve the problem
for you by passing in the same arguments but with "-c" (showing just the
relevant part here):

prompt> ./paging-policy.py -s 10 -n 3 -c
...
Solving...

Access: 5 MISS FirstIn->   [br 5] <-Lastin Replace:- [br Hits:0 Misses:1]
Access: 4 MISS FirstIn->[br 5, 4] <-Lastin Replace:- [br Hits:0 Misses:2]
Access: 5 HIT  FirstIn->[br 5, 4] <-Lastin Replace:- [br Hits:1 Misses:2]
]

The default policy is FIFO, though others are available, including LRU, MRU,
OPT (the optimal replacement policy, which peeks into the future to see what
is best to replace), UNOPT (which is the pessimal replacement), RAND (which
does random replacement), and CLOCK (which does the clock algorithm). The
CLOCK algorithm also takes another argument (-b), which states how many bits
should be kept per page; the more clock bits there are, the better the
algorithm should be at determining which pages to keep in memory.

Other options include: "-C/--cachesize" which changes the size of the page
cache; "-m/--maxpage" which is the largest page number that will be used if
the simulator is generating references for you; and "-f/--addressfile" which
lets you specify a file with addresses in them, in case you wish to get traces
from a real application or otherwise use a long trace as input.

