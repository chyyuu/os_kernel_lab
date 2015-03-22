malloc
======
WHAT THIS IS: This revisit of the K&R classic of systems programming was inspired by recent problems in concurrent programming.

TO ELABORATE: The malloc code is, more or less, but an implementation of what I saw described in the K&R C bible and is written in Ansi C.  Conceptually this is textbook K&R stuff though much nicer than the snippet of code K&R include.  So it's merely a starting point or a baseline over which one might want to optimize the allocator.  However, it is the context that is interesting.

CONTEXT: This was in the context of looking at Google's TCMalloc and thinking about when it might be worth it to implement a custom memory allocator and what optimization techniques in this space might look like.  But even if you use TCMalloc for concurrent programming, TCMalloc uses mmap and so, if you want to use your own memory mapper, e.g. something like this -- http://eurosys2013.tudos.org/wp-content/uploads/2013/paper/Merryfield.pdf -- you'd have to either modify TCMalloc or build your own allocator.

NOTES: I get memory from the system using the standard malloc call in the C library and then manage that memory myself.  But if for some reason you wanted to bypass malloc entirely, see the Malloc Tutorial below.

REFERENCES:
K&R: http://en.wikipedia.org/wiki/File:The_C_Programming_Language_cover.svg,
Malloc Tutorial: http://www.inf.udec.cl/~leo/Malloc_tutorial.pdf,
For further pondering, see http://www.stanford.edu/~hlitz/papers/asplos-litz.pdf
