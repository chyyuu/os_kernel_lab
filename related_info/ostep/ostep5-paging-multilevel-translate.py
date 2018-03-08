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

def roundup(size):
    value = 1.0
    while value < size:
        value = value * 2.0
    return value

    
class OS:
    def __init__(self):
        # 4k phys memory (128 pages)
        self.pageSize  = 32
        self.physPages = 128
        self.physMem   = self.pageSize * self.physPages
        self.vaPages   = 1024
        self.vaSize    = self.pageSize * self.vaPages
        self.pteSize   = 1
        self.pageBits  = 5 # log of page size

        # os tracks
        self.usedPages      = []
        self.usedPagesCount = 0
        self.maxPageCount   = self.physMem / self.pageSize

        # no pages used (yet)
        for i in range(0, self.maxPageCount):
            self.usedPages.append(0)

        # set contents of memory to 0, too
        self.memory = []
        for i in range(0, self.physMem):
            self.memory.append(0)

        # associative array of pdbr's (indexed by PID)
        self.pdbr = {}

        # mask is 11111 00000 00000 --> 0111 1100 0000 0000 
        self.PDE_MASK    = 0x7c00
        self.PDE_SHIFT   = 10

        # 00000 11111 00000 -> 000 0011 1110 0000
        self.PTE_MASK    = 0x03e0
        self.PTE_SHIFT   = 5

        self.VPN_MASK    = self.PDE_MASK | self.PTE_MASK
        self.VPN_SHIFT   = self.PTE_SHIFT

        # grabs the last five bits of a virtual address
        self.OFFSET_MASK = 0x1f

    def findFree(self):
        assert(self.usedPagesCount < self.maxPageCount)
        look = int(random.random() * self.maxPageCount)
        while self.usedPages[look] == 1:
            look = int(random.random() * self.maxPageCount)
        self.usedPagesCount = self.usedPagesCount + 1
        self.usedPages[look] = 1
        return look

    def initPageDir(self, whichPage):
        whichByte = whichPage << self.pageBits
        for i in range(whichByte, whichByte + self.pageSize):
            self.memory[i] = 0x7f

    def initPageTablePage(self, whichPage):
        self.initPageDir(whichPage)

    def getPageTableEntry(self, virtualAddr, ptePage, printStuff):
        pteBits = (virtualAddr & self.PTE_MASK) >> self.PTE_SHIFT
        pteAddr = (ptePage << self.pageBits) | pteBits
        pte     = self.memory[pteAddr]
        valid   = (pte & 0x80) >> 7
        pfn     = (pte & 0x7f)
        if printStuff == True:
            print '    --> pte index:0x%x  pte contents:(valid %d, pfn 0x%02x)' % (pteBits, valid, pfn)
        return (valid, pfn, pteAddr)

    def getPageDirEntry(self, pid, virtualAddr, printStuff):
        pageDir = self.pdbr[pid]
        pdeBits = (virtualAddr & self.PDE_MASK) >> self.PDE_SHIFT
        pdeAddr = (pageDir << self.pageBits) | pdeBits
        pde     = self.memory[pdeAddr]
        valid   = (pde & 0x80) >> 7
        ptPtr   = (pde & 0x7f)
        if printStuff == True:
            print '  --> pde index:0x%x  pde contents:(valid %d, pfn 0x%02x)' % (pdeBits, valid, ptPtr)
        return (valid, ptPtr, pdeAddr)

    def setPageTableEntry(self, pteAddr, physicalPage):
        self.memory[pteAddr] = 0x80 | physicalPage

    def setPageDirEntry(self, pdeAddr, physicalPage):
        self.memory[pdeAddr] = 0x80 | physicalPage
        
    def allocVirtualPage(self, pid, virtualPage, physicalPage):
        # make it into a virtual address, as everything uses this (and not VPN)
        virtualAddr = virtualPage << self.pageBits
        (valid, ptPtr, pdeAddr) = self.getPageDirEntry(pid, virtualAddr, False)
        if valid == 0:
            # must allocate a page of the page table now, and have the PD point to it
            assert(ptPtr == 127)
            ptePage = self.findFree()
            self.setPageDirEntry(pdeAddr, ptePage)
            self.initPageTablePage(ptePage)
        else:
            # otherwise, just extract page number of page table page
            ptePage = ptPtr
        # now, look up page table entry too, and mark it valid and fill in translation
        (valid, pfn, pteAddr) = self.getPageTableEntry(virtualAddr, ptePage, False)
        assert(valid == 0)
        assert(pfn == 127)
        self.setPageTableEntry(pteAddr, physicalPage)

    # -2 -> PTE fault, -1 means PDE fault
    def translate(self, pid, virtualAddr):
        (valid, ptPtr, pdeAddr) = self.getPageDirEntry(pid, virtualAddr, True)
        if valid == 1:
            ptePage = ptPtr
            (valid, pfn, pteAddr) = self.getPageTableEntry(virtualAddr, ptePage, True)
            if valid == 1:
                offset = (virtualAddr & self.OFFSET_MASK)
                paddr  = (pfn << self.pageBits) | offset
		# print '     --> pfn: %02x  offset: %x' % (pfn, offset)
                return paddr
            else:
                return -2
        return -1

    def fillPage(self, whichPage):
        for j in range(0, self.pageSize):
            self.memory[(whichPage * self.pageSize) + j] = int(random.random() * 31)

    def procAlloc(self, pid, numPages):
        # need a PDBR: find one somewhere in memory
        pageDir = self.findFree()
        # print '**ALLOCATE** page dir', pageDir
        self.pdbr[pid] = pageDir
        self.initPageDir(pageDir)

        used = {}
        for vp in range(0, self.vaPages):
            used[vp] = 0
        allocatedVPs = []
        
        for vp in range(0, numPages):
            vp = int(random.random() * self.vaPages)
            while used[vp] == 1:
                vp = int(random.random() * self.vaPages)
            assert(used[vp] == 0)
            used[vp] = 1
            allocatedVPs.append(vp)
            pp = self.findFree()
            # print '**ALLOCATE** page', pp
            # print '  trying to map vp:%08x to pp:%08x' % (vp, pp)
            self.allocVirtualPage(pid, vp, pp)
            self.fillPage(pp)
        return allocatedVPs

    def dumpPage(self, whichPage):
        i = whichPage
        for j in range(0, self.pageSize):
            print self.memory[(i * self.pageSize) + j],
        print ''

    def memoryDump(self):
        for i in range(0, self.physMem / self.pageSize):
            print 'page %3d:' %  i, 
            for j in range(0, self.pageSize):
                print '%02x' % self.memory[(i * self.pageSize) + j],
            print ''

    def getPDBR(self, pid):
        return self.pdbr[pid]

    def getValue(self, addr):
        return self.memory[addr]

# allocate some processes in memory
# allocate some multi-level page tables in memory
# make a bit of a mystery:
# can examine PDBR (PFN of current proc's page directory)
# can examine contents of any page
# fill pages with values too
# ask: when given
#   LOAD VA, R1
# what will final value will be loaded into R1?

#
# main program
#
parser = OptionParser()
parser.add_option('-s', '--seed', default=0, help='the random seed', action='store', type='int', dest='seed')
parser.add_option('-a', '--allocated', default=64, help='number of virtual pages allocated',
                  action='store', type='int', dest='allocated')
parser.add_option('-n', '--addresses', default=10, help='number of virtual addresses to generate',
                  action='store', type='int', dest='num')
parser.add_option('-c', '--solve', help='compute answers for me', action='store_true', default=False, dest='solve')


(options, args) = parser.parse_args()

print 'ARG seed', options.seed
print 'ARG allocated',  options.allocated
print 'ARG num',  options.num
print ""

random.seed(options.seed)

# do the work now
os = OS()
used = os.procAlloc(1, options.allocated)

os.memoryDump()

print '\nPDBR:', os.getPDBR(1), ' (decimal) [This means the page directory is held in this page]\n'

for i in range(0, options.num):
    if (random.random() * 100) > 50.0 or i >= len(used):
        vaddr = int(random.random() * 1024 * 32)
    else:
        vaddr = (used[i] << 5) | int(random.random() * 32)
    if options.solve == True:
        print 'Virtual Address %04x:' % vaddr
        r = os.translate(1, vaddr)
        if r > -1:
            print '      --> Translates to Physical Address 0x%03x --> Value: %02x' % (r, os.getValue(r))
        elif r == -1:
            print '      --> Fault (page directory entry not valid)'
        else:
            print '      --> Fault (page table entry not valid)'
    else:
        print 'Virtual Address %04x: Translates To What Physical Address (And Fetches what Value)? Or Fault?' % vaddr

print ''

exit(0)





