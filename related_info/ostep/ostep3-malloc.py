#! /usr/bin/env python

import random
from optparse import OptionParser

class malloc:
    def __init__(self, size, start, headerSize, policy, order, coalesce, align):
        # size of space
        self.size        = size
        
        # info about pretend headers
        self.headerSize  = headerSize

        # init free list
        self.freelist    = []
        self.freelist.append((start, size))

        # keep track of ptr to size mappings
        self.sizemap     = {}

        # policy
        self.policy       = policy
        assert(self.policy in ['FIRST', 'BEST', 'WORST'])

        # list ordering
        self.returnPolicy = order
        assert(self.returnPolicy in ['ADDRSORT', 'SIZESORT+', 'SIZESORT-', 'INSERT-FRONT', 'INSERT-BACK'])

        # this does a ridiculous full-list coalesce, but that is ok
        self.coalesce     = coalesce

        # alignment (-1 if no alignment)
        self.align        = align
        assert(self.align == -1 or self.align > 0)

    def addToMap(self, addr, size):
        assert(addr not in self.sizemap)
        self.sizemap[addr] = size
        # print 'adding', addr, 'to map of size', size
        
    def malloc(self, size):
        if self.align != -1:
            left = size % self.align
            if left != 0:
                diff = self.align - left
            else:
                diff = 0
            # print 'aligning: adding %d to %d' % (diff, size)
            size += diff

        size += self.headerSize

        bestIdx  = -1
        if self.policy == 'BEST':
            bestSize = self.size + 1
        elif self.policy == 'WORST' or self.policy == 'FIRST':
            bestSize = -1

        count = 0
            
        for i in range(len(self.freelist)):
            eaddr, esize = self.freelist[i][0], self.freelist[i][1]
            count   += 1
            if esize >= size and ((self.policy == 'BEST'  and esize < bestSize) or
                                  (self.policy == 'WORST' and esize > bestSize) or
                                  (self.policy == 'FIRST')):
                bestAddr = eaddr
                bestSize = esize
                bestIdx  = i
                if self.policy == 'FIRST':
                    break

        if bestIdx != -1:
            if bestSize > size:
                # print 'SPLIT', bestAddr, size
                self.freelist[bestIdx] = (bestAddr + size, bestSize - size)
                self.addToMap(bestAddr, size)
            elif bestSize == size:
                # print 'PERFECT MATCH (no split)', bestAddr, size
                self.freelist.pop(bestIdx)
                self.addToMap(bestAddr, size)
            else:
                abort('should never get here')
            return (bestAddr, count)

        # print '*** FAILED TO FIND A SPOT', size
        return (-1, count)

    def free(self, addr):
        # simple back on end of list, no coalesce
        if addr not in self.sizemap:
            return -1
            
        size = self.sizemap[addr]
        if self.returnPolicy == 'INSERT-BACK':
            self.freelist.append((addr, size))
        elif self.returnPolicy == 'INSERT-FRONT':
            self.freelist.insert(0, (addr, size))
        elif self.returnPolicy == 'ADDRSORT':
            self.freelist.append((addr, size))
            self.freelist = sorted(self.freelist, key=lambda e: e[0])
        elif self.returnPolicy == 'SIZESORT+':
            self.freelist.append((addr, size))
            self.freelist = sorted(self.freelist, key=lambda e: e[1], reverse=False)
        elif self.returnPolicy == 'SIZESORT-':
            self.freelist.append((addr, size))
            self.freelist = sorted(self.freelist, key=lambda e: e[1], reverse=True)

        # not meant to be an efficient or realistic coalescing...
        if self.coalesce == True:
            self.newlist = []
            self.curr    = self.freelist[0]
            for i in range(1, len(self.freelist)):
                eaddr, esize = self.freelist[i]
                if eaddr == (self.curr[0] + self.curr[1]):
                    self.curr = (self.curr[0], self.curr[1] + esize)
                else:
                    self.newlist.append(self.curr)
                    self.curr = eaddr, esize
            self.newlist.append(self.curr)
            self.freelist = self.newlist
            
        del self.sizemap[addr]
        return 0

    def dump(self):
        print 'Free List [ Size %d ]: ' % len(self.freelist), 
        for e in self.freelist:
            print '[ addr:%d sz:%d ]' % (e[0], e[1]),
        print ''


#
# main program
#
parser = OptionParser()

parser.add_option('-s', '--seed',        default=0,          help='the random seed',                             action='store', type='int',    dest='seed')
parser.add_option('-S', '--size',        default=100,        help='size of the heap',                            action='store', type='int',    dest='heapSize') 
parser.add_option('-b', '--baseAddr',    default=1000,       help='base address of heap',                        action='store', type='int',    dest='baseAddr') 
parser.add_option('-H', '--headerSize',  default=0,          help='size of the header',                          action='store', type='int',    dest='headerSize')
parser.add_option('-a', '--alignment',   default=-1,         help='align allocated units to size; -1->no align', action='store', type='int',    dest='alignment')
parser.add_option('-p', '--policy',      default='BEST',     help='list search (BEST, WORST, FIRST)',            action='store', type='string', dest='policy') 
parser.add_option('-l', '--listOrder',   default='ADDRSORT', help='list order (ADDRSORT, SIZESORT+, SIZESORT-, INSERT-FRONT, INSERT-BACK)', action='store', type='string', dest='order') 
parser.add_option('-C', '--coalesce',    default=False,      help='coalesce the free list?',                     action='store_true',           dest='coalesce')
parser.add_option('-n', '--numOps',      default=10,         help='number of random ops to generate',            action='store', type='int',    dest='opsNum')
parser.add_option('-r', '--range',       default=10,         help='max alloc size',                              action='store', type='int',    dest='opsRange')
parser.add_option('-P', '--percentAlloc',default=50,         help='percent of ops that are allocs',              action='store', type='int',    dest='opsPAlloc')
parser.add_option('-A', '--allocList',   default='',         help='instead of random, list of ops (+10,-0,etc)', action='store', type='string', dest='opsList')
parser.add_option('-c', '--compute',     default=False,      help='compute answers for me',                      action='store_true',           dest='solve')

(options, args) = parser.parse_args()

m = malloc(int(options.heapSize), int(options.baseAddr), int(options.headerSize),
           options.policy, options.order, options.coalesce, options.alignment)

percent = int(options.opsPAlloc) / 100.0

random.seed(int(options.seed))
p = {}
L = []
assert(percent > 0)

if options.opsList == '':
    c = 0
    j = 0
    while j < int(options.opsNum):
        pr = False
        if random.random() < percent:
            size     = int(random.random() * int(options.opsRange)) + 1
            ptr, cnt = m.malloc(size)
            if ptr != -1:
                p[c] = ptr
                L.append(c)
            print 'ptr[%d] = Alloc(%d)' % (c, size),
            if options.solve == True:
                print ' returned %d (searched %d elements)' % (ptr + options.headerSize, cnt)
            else:
                print ' returned ?'
            c += 1
            j += 1
            pr = True
        else:
            if len(p) > 0:
                # pick random one to delete
                d = int(random.random() * len(L))
                rc = m.free(p[L[d]])
                print 'Free(ptr[%d])' % L[d], 
                if options.solve == True:
                    print 'returned %d' % rc
                else:
                    print 'returned ?'
                del p[L[d]]
                del L[d]
                # print 'DEBUG p', p
                # print 'DEBUG L', L
                pr = True
                j += 1
        if pr:
            if options.solve == True:
                m.dump()
            else:
                print 'List? '
            print ''
else:
    c = 0
    for op in options.opsList.split(','):
        if op[0] == '+':
            # allocation!
            size     = int(op.split('+')[1])
            ptr, cnt = m.malloc(size)
            if ptr != -1:
                p[c] = ptr
            print 'ptr[%d] = Alloc(%d)' % (c, size),
            if options.solve == True:
                print ' returned %d (searched %d elements)' % (ptr, cnt)
            else:
                print ' returned ?'
            c += 1
        elif op[0] == '-':
            # free
            index = int(op.split('-')[1])
            if index >= len(p):
                print 'Invalid Free: Skipping'
                continue
            print 'Free(ptr[%d])' % index, 
            rc = m.free(p[index])
            if options.solve == True:
                print 'returned %d' % rc
            else:
                print 'returned ?'
        else:
            abort('badly specified operand: must be +Size or -Index')
        if options.solve == True:
            m.dump()
        else:
            print 'List?'
        print ''
