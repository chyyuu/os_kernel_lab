#! /usr/bin/env python

import sys
from optparse import OptionParser
import random
import math

def convert(size):
    length = len(size)
    lastchar = size[length-1]
    if (lastchar == 'k') or (lastchar == 'K'):
        m = 1024
        nsize = int(size[0:length-1]) * m
    elif (lastchar == 'm') or (lastchar == 'M'):
        m = 1024*1024
        nsize = int(size[0:length-1]) * m
    elif (lastchar == 'g') or (lastchar == 'G'):
        m = 1024*1024*1024
        nsize = int(size[0:length-1]) * m
    else:
        nsize = int(size)
    return nsize


#
# main program
#
parser = OptionParser()
parser.add_option('-s', '--seed',      default=0,     help='the random seed',                                action='store', type='int', dest='seed')
parser.add_option('-a', '--asize',     default='1k',  help='address space size (e.g., 16, 64k, 32m, 1g)',    action='store', type='string', dest='asize')
parser.add_option('-p', '--physmem',   default='16k', help='physical memory size (e.g., 16, 64k, 32m, 1g)',  action='store', type='string', dest='psize')
parser.add_option('-n', '--addresses', default=5,     help='number of virtual addresses to generate',        action='store', type='int', dest='num')
parser.add_option('-b', '--b',         default='-1',  help='value of base register',                         action='store', type='string', dest='base')
parser.add_option('-l', '--l',         default='-1',  help='value of limit register',                        action='store', type='string', dest='limit')
parser.add_option('-c', '--compute',   default=False, help='compute answers for me',                         action='store_true', dest='solve')


(options, args) = parser.parse_args()

print ''
print 'ARG seed', options.seed
print 'ARG address space size', options.asize
print 'ARG phys mem size', options.psize
print ''

random.seed(options.seed)
asize = convert(options.asize)
psize = convert(options.psize)

if psize <= 1:
    print 'Error: must specify a non-zero physical memory size.'
    exit(1)

if asize == 0:
    print 'Error: must specify a non-zero address-space size.'
    exit(1)

if psize <= asize:
    print 'Error: physical memory size must be GREATER than address space size (for this simulation)'
    exit(1)

#
# need to generate base, bounds for segment registers
#
limit = convert(options.limit)
base  = convert(options.base)

if limit == -1:
    limit = int(asize/4.0 + (asize/4.0 * random.random()))

# now have to find room for them
if base == -1:
    done = 0
    while done == 0:
        base = int(psize * random.random())
        if (base + limit) < psize:
            done = 1

print 'Base-and-Bounds register information:'
print ''
print '  Base   : 0x%08x (decimal %d)' % (base, base)
print '  Limit  : %d' % (limit)
print ''

if base + limit > psize:
    print 'Error: address space does not fit into physical memory with those base/bounds values.'
    print 'Base + Limit:', base + limit, '  Psize:', psize
    exit(1)

#
# now, need to generate virtual address trace
#
print 'Virtual Address Trace'
for i in range(0,options.num):
    vaddr = int(asize * random.random())
    if options.solve == False:
        print '  VA %2d: 0x%08x (decimal: %4d) --> PA or segmentation violation?' % (i, vaddr, vaddr)
    else:
        paddr = 0
        if (vaddr >= limit):
            print '  VA %2d: 0x%08x (decimal: %4d) --> SEGMENTATION VIOLATION' % (i, vaddr, vaddr)
        else:
            paddr = vaddr + base
            print '  VA %2d: 0x%08x (decimal: %4d) --> VALID: 0x%08x (decimal: %4d)' % (i, vaddr, vaddr, paddr, paddr)


print ''

if options.solve == False:
    print 'For each virtual address, either write down the physical address it translates to'
    print 'OR write down that it is an out-of-bounds address (a segmentation violation). For'
    print 'this problem, you should assume a simple virtual address space of a given size.'
    print ''




