#! /usr/bin/env python

import math
import random
from optparse import OptionParser

# minimum unit of transfer to RAID
BLOCKSIZE = 4096

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

class disk:
    def __init__(self, seekTime=10, xferTime=0.1, queueLen=8):
        # these are both in milliseconds
        # seek is the time to seek (simple constant amount)
        # transfer is the time to read one block
        self.seekTime = seekTime
        self.xferTime = xferTime

        # length of scheduling queue
        self.queueLen = queueLen

        # current location: make it negative so that whatever
        # the first read is, it causes a seek 
        self.currAddr = -10000

        # queue
        self.queue    = []

        # disk geometry
        self.numTracks      = 100
        self.blocksPerTrack = 100
        self.blocksPerDisk  = self.numTracks * self.blocksPerTrack

        # stats
        self.countIO   = 0
        self.countSeq  = 0
        self.countNseq = 0
        self.countRand = 0
        self.utilTime  = 0

    def stats(self):
        return (self.countIO, self.countSeq, self.countNseq, self.countRand, self.utilTime)

    def enqueue(self, addr):
        assert(addr < self.blocksPerDisk)
        self.countIO += 1

        # check if this is on the same track, or a different one
        currTrack = self.currAddr / self.numTracks
        newTrack  = addr / self.numTracks

        # absolute diff
        diff = addr - self.currAddr

        # if on the same track...
        if currTrack == newTrack or diff < self.blocksPerTrack:
            if diff == 1:
                self.countSeq += 1
            else:
                self.countNseq += 1
            self.utilTime += (diff * self.xferTime)
        else:
            self.countRand += 1
            self.utilTime += (self.seekTime + self.xferTime)
        self.currAddr = addr

    def go(self):
        return self.utilTime

class raid:
    def __init__(self, chunkSize='4k', numDisks=4, level=0, timing=False, reverse=False, solve=False, raid5type='LS'):
        chunkSize      = int(convert(chunkSize))
        self.chunkSize = chunkSize / BLOCKSIZE
        self.numDisks  = numDisks
        self.raidLevel = level
        self.timing    = timing
        self.reverse   = reverse
        self.solve     = solve
        self.raid5type = raid5type

        if (chunkSize % BLOCKSIZE) != 0:
            print 'chunksize (%d) must be multiple of blocksize (%d): %d' % (chunkSize, BLOCKSIZE, self.chunkSize % BLOCKSIZE)
            exit(1)
        if self.raidLevel == 1 and numDisks % 2 != 0:
            print 'raid1: disks (%d) must be a multiple of two' % numDisks
            exit(1)

        if self.raidLevel == 4:
            self.blocksInStripe = (self.numDisks - 1) * self.chunkSize
            self.pdisk = self.numDisks - 1
        if self.raidLevel == 5:
            self.blocksInStripe = (self.numDisks - 1) * self.chunkSize
            self.pdisk = -1

        self.disks = []
        for i in range(self.numDisks):
            self.disks.append(disk())

    # print per-disk stats
    def stats(self, totalTime):
        for d in range(self.numDisks):
            s = self.disks[d].stats()
            if s[4] == totalTime:
                print 'disk:%d  busy: %.2f  I/Os: %5d (sequential:%d nearly:%d random:%d)' % (d, (100.0*float(s[4])/totalTime), s[0], s[1], s[2], s[3])
            elif s[4] == 0:
                print 'disk:%d  busy:   %.2f  I/Os: %5d (sequential:%d nearly:%d random:%d)' % (d, (100.0*float(s[4])/totalTime), s[0], s[1], s[2], s[3])
            else:
                print 'disk:%d  busy:  %.2f  I/Os: %5d (sequential:%d nearly:%d random:%d)' % (d, (100.0*float(s[4])/totalTime), s[0], s[1], s[2], s[3])

    # global enqueue function
    def enqueue(self, addr, size, isWrite):
        # should we print out the logical operation?
        if self.timing == False:
            if self.solve or self.reverse==False:
                if isWrite:
                    print 'LOGICAL WRITE to  addr:%d size:%d' % (addr, size * BLOCKSIZE)
                else:
                    print 'LOGICAL READ from addr:%d size:%d' % (addr, size * BLOCKSIZE)
                if self.solve == False:
                    print '  Physical reads/writes?\n'
            else:
                print 'LOGICAL OPERATION is ?'

        # should we print out the physical operations?
        if self.timing == False and (self.solve or self.reverse==True):
            self.printPhysical = True
        else:
            self.printPhysical = False

        if self.raidLevel == 0:
            self.enqueue0(addr, size, isWrite)
        elif self.raidLevel == 1:
            self.enqueue1(addr, size, isWrite)
        elif self.raidLevel == 4 or self.raidLevel == 5:
            self.enqueue45(addr, size, isWrite)

    # process disk workloads one at a time, returning final completion time
    def go(self):
        tmax = 0
        for d in range(self.numDisks):
            # print '**** disk ****', d
            t = self.disks[d].go()
            if t > tmax:
                tmax = t
        return tmax

    # helper functions
    def doSingleRead(self, disk, off, doNewline=False):
        if self.printPhysical:
            print '  read  [disk %d, offset %d]  ' % (disk, off),
            if doNewline:
                print ''
        self.disks[disk].enqueue(off)

    def doSingleWrite(self, disk, off, doNewline=False):
        if self.printPhysical:
            print '  write [disk %d, offset %d]  ' % (disk, off),
            if doNewline:
                print ''
        self.disks[disk].enqueue(off)

    # 
    # mapping for RAID 0 (striping)
    #
    def bmap0(self, bnum):
        cnum = bnum / self.chunkSize
        coff = bnum % self.chunkSize
        return (cnum % self.numDisks, (cnum / self.numDisks) * self.chunkSize + coff)

    def enqueue0(self, addr, size, isWrite):
        # can ignore isWrite, as I/O pattern is the same for striping
        for b in range(addr, addr+size):
            (disk, off) = self.bmap0(b)
            if isWrite:
                self.doSingleWrite(disk, off, True)
            else:
                self.doSingleRead(disk, off, True)
        if self.timing == False and self.printPhysical:
            print ''

    #
    # mapping for RAID 1 (mirroring)
    # 
    def bmap1(self, bnum):
        cnum = bnum / self.chunkSize
        coff = bnum % self.chunkSize
        disk = 2 * (cnum % (self.numDisks / 2))
        return (disk, disk + 1, (cnum / (self.numDisks / 2)) * self.chunkSize + coff)

    def enqueue1(self, addr, size, isWrite):
        for b in range(addr, addr+size):
            (disk1, disk2, off) = self.bmap1(b)
            # print 'enqueue:', addr, size, '-->', m
            if isWrite:
                self.doSingleWrite(disk1, off, False)
                self.doSingleWrite(disk2, off, True)
            else:
                # the raid-1 read balancing algorithm is here;
                # could be something more intelligent -- 
                # instead, it is just based on the disk offset
                # to produce something easily reproducible
                if off % 2 == 0:
                    self.doSingleRead(disk1, off, True)
                else:
                    self.doSingleRead(disk2, off, True)
        if self.timing == False and self.printPhysical:
            print ''

    # 
    # mapping for RAID 4 (parity disk)
    # 
    # assumes (for now) that there is just one parity disk
    #
    def bmap4(self, bnum):
        cnum = bnum / self.chunkSize
        coff = bnum % self.chunkSize
        return (cnum % (self.numDisks - 1), (cnum / (self.numDisks - 1)) * self.chunkSize + coff)

    def pmap4(self, snum):
        return self.pdisk

    # 
    # mapping for RAID 5 (rotated parity)
    #
    def __bmap5(self, bnum):
        cnum = bnum / self.chunkSize
        coff = bnum % self.chunkSize
        ddsk = cnum / (self.numDisks - 1)
        doff = (ddsk * self.chunkSize) + coff
        disk = cnum % (self.numDisks - 1)
        col  = (ddsk % self.numDisks)
        pdsk = (self.numDisks - 1) - col

        # supports left-asymmetric and left-symmetric layouts
        if self.raid5type == 'LA':
            if disk >= pdisk:
                disk += 1
        elif self.raid5type == 'LS':
            disk = (disk - col) % (self.numDisks)
        else:
            print 'error: no such RAID scheme'
            exit(1)
        assert(disk != pdsk)
        return (disk, pdsk, doff)

    # yes this is lame (redundant call to __bmap5 is serious programmer laziness)
    def bmap5(self, bnum):
        (disk, pdisk, off) = self.__bmap5(bnum)
        return (disk, off)

    # this too is lame (redundant call to __bmap5 is serious programmer laziness)
    def pmap5(self, snum):
        (disk, pdisk, off) = self.__bmap5(snum * self.blocksInStripe)
        return pdisk

    # RAID 4/5 helper routine to write out some blocks in a stripe
    def doPartialWrite(self, stripe, begin, end, bmap, pmap):
        numWrites = end - begin
        pdisk     = pmap(stripe)
        if (numWrites + 1) <= (self.blocksInStripe - numWrites):
            # SUBTRACTIVE PARITY
            # print 'SUBTRACTIVE'
            offList = []
            for voff in range(begin, end):
                (disk, off) = bmap(voff)
                self.doSingleRead(disk, off)
                if off not in offList:
                    offList.append(off)
            for i in range(len(offList)):
                self.doSingleRead(pdisk, offList[i], i == (len(offList) - 1))
        else:
            # ADDITIVE PARITY 
            # print 'ADDITIVE'
            stripeBegin = stripe * self.blocksInStripe
            stripeEnd   = stripeBegin + self.blocksInStripe
            for voff in range(stripeBegin, begin):
                (disk, off) = bmap(voff)
                self.doSingleRead(disk, off, (voff == (begin - 1)) and (end == stripeEnd))
            for voff in range(end, stripeEnd):
                (disk, off) = bmap(voff)
                self.doSingleRead(disk, off, voff == (stripeEnd - 1))

        # WRITES: same for additive or subtractive parity
        offList = []
        for voff in range(begin, end):
            (disk, off) = bmap(voff)
            self.doSingleWrite(disk, off)
            if off not in offList:
                offList.append(off)
        for i in range(len(offList)):
            self.doSingleWrite(pdisk, offList[i], i == (len(offList) - 1))

    # RAID 4/5 enqueue routine
    def enqueue45(self, addr, size, isWrite):
        if self.raidLevel == 4:
            (bmap, pmap) = (self.bmap4, self.pmap4)
        elif self.raidLevel == 5:
            (bmap, pmap) = (self.bmap5, self.pmap5)

        if isWrite == False:
            for b in range(addr, addr+size):
                (disk, off) = bmap(b)
                self.doSingleRead(disk, off)
        else:
            # process the write request, one stripe at a time
            initStripe     = (addr)            / self.blocksInStripe
            finalStripe    = (addr + size - 1) / self.blocksInStripe

            left  = size
            begin = addr
            for stripe in range(initStripe, finalStripe + 1):
                endOfStripe = (stripe * self.blocksInStripe) + self.blocksInStripe

                if left >= self.blocksInStripe:
                    end = begin + self.blocksInStripe
                else:
                    end = begin + left

                if end >= endOfStripe:
                    end = endOfStripe
                        
                self.doPartialWrite(stripe, begin, end, bmap, pmap)

                left -= (end - begin)
                begin = end
                    
        # for all cases, print this for pretty-ness in mapping mode
        if self.timing == False and self.printPhysical:
            print ''

#
# main program
#
parser = OptionParser()

parser.add_option('-s', '--seed',        default=0,      help='the random seed',                                action='store',       type='int',    dest='seed')
parser.add_option('-D', '--numDisks',    default=4,      help='number of disks in RAID',                        action='store',       type='int',    dest='numDisks') 
parser.add_option('-C', '--chunkSize',   default='4k',   help='chunk size of the RAID',                         action='store',       type='string', dest='chunkSize') 
parser.add_option('-n', '--numRequests', default=10,     help='number of requests to simulate',                 action='store',       type='int',    dest='numRequests')
parser.add_option('-S', '--reqSize',     default='4k',   help='size of requests',                               action='store',       type='string', dest='size')
parser.add_option('-W', '--workload',    default='rand', help='either "rand" or "seq" workloads',               action='store',       type='string', dest='workload')
parser.add_option('-w', '--writeFrac',   default=0,      help='write fraction (100->all writes, 0->all reads)', action='store',       type='int',    dest='writeFrac')
parser.add_option('-R', '--randRange',   default=10000,  help='range of requests (when using "rand" workload)', action='store',       type='int',    dest='range')
parser.add_option('-L', '--level',       default=0,      help='RAID level (0, 1, 4, 5)',                        action='store',       type='int',    dest='level')
parser.add_option('-5', '--raid5',       default='LS',   help='RAID-5 left-symmetric "LS" or left-asym "LA"',   action='store',       type='string', dest='raid5type')
parser.add_option('-r', '--reverse',     default=False,  help='instead of showing logical ops, show physical',  action='store_true',                 dest='reverse')
parser.add_option('-t', '--timing',      default=False,  help='use timing mode, instead of mapping mode',       action='store_true',                 dest='timing')
parser.add_option('-c', '--compute',     default=False,  help='compute answers for me',                         action='store_true',                 dest='solve')

(options, args) = parser.parse_args()

print 'ARG blockSize',   BLOCKSIZE
print 'ARG seed',        options.seed
print 'ARG numDisks',    options.numDisks
print 'ARG chunkSize',   options.chunkSize
print 'ARG numRequests', options.numRequests
print 'ARG reqSize',     options.size
print 'ARG workload',    options.workload
print 'ARG writeFrac',   options.writeFrac
print 'ARG randRange',   options.range
print 'ARG level',       options.level
print 'ARG raid5',       options.raid5type
print 'ARG reverse',     options.reverse
print 'ARG timing',      options.timing

print ''

writeFrac = float(options.writeFrac) / 100.0
assert(writeFrac >= 0.0 and writeFrac <= 1.0)

random.seed(options.seed)

size = convert(options.size)
if size % BLOCKSIZE != 0:
    print 'error: request size (%d) must be a multiple of BLOCKSIZE (%d)' % (size, BLOCKSIZE)
    exit(1)
size = size / BLOCKSIZE

if options.workload == 'seq' or options.workload == 's' or options.workload == 'sequential':
    workloadIsSequential = True
elif options.workload == 'rand' or options.workload == 'r' or options.workload == 'random':
    workloadIsSequential = False
else:
    print 'error: workload must be either r/rand/random or s/seq/sequential'
    exit(1)

assert(options.level == 0 or options.level == 1 or options.level == 4 or options.level == 5)
if options.level != 0 and options.numDisks < 2:
    print 'RAID-4 and RAID-5 need more than 1 disk'
    exit(1)

if options.level == 5 and options.raid5type != 'LA' and options.raid5type != 'LS':
    print 'Only two types of RAID-5 supported: left-asymmetric (LA) and left-symmetric (LS) (%s is not)' % options.raid5type
    exit(1)

# instantiate RAID
r = raid(chunkSize=options.chunkSize, numDisks=options.numDisks, level=options.level, timing=options.timing,
         reverse=options.reverse, solve=options.solve, raid5type=options.raid5type)

# generate requests
off = 0
for i in range(options.numRequests):
    if workloadIsSequential == True:
        blk = off
        off += size
    else:
        blk = int(random.random() * options.range)
    if random.random() < writeFrac:
        r.enqueue(blk, size, True)
    else:
        r.enqueue(blk, size, False)

# process requests
t = r.go()

# print out some final info, if needed
if options.timing == False:
    print ''
    exit(0)

if options.solve:
    print ''
    r.stats(t)
    print ''
    print 'STAT totalTime', t
    print ''
else:
    print ''
    print 'Estimate how long the workload should take to complete.'
    print '- Roughly how many requests should each disk receive?'
    print '- How many requests are random, how many sequential?'
    print ''
