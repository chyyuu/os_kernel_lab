#! /usr/bin/env python

import sys
from optparse import OptionParser
import random

parser = OptionParser()
parser.add_option('-s', '--seed', default=0, help='the random seed',              action='store', type='int', dest='seed')
parser.add_option('-j', '--jobs', default=3, help='number of jobs in the system', action='store', type='int', dest='jobs')
parser.add_option('-l', '--jlist', default='', help='instead of random jobs, provide a comma-separated list of run times and ticket values (e.g., 10:100,20:100 would have two jobs with run-times of 10 and 20, each with 100 tickets)',  action='store', type='string', dest='jlist')
parser.add_option('-m', '--maxlen',  default=10,  help='max length of job',         action='store', type='int', dest='maxlen')
parser.add_option('-T', '--maxticket', default=100, help='maximum ticket value, if randomly assigned',          action='store', type='int', dest='maxticket')
parser.add_option('-q', '--quantum', default=1,   help='length of time slice', action='store', type='int', dest='quantum')
parser.add_option('-c', '--compute', help='compute answers for me', action='store_true', default=False, dest='solve')

(options, args) = parser.parse_args()

random.seed(options.seed)

print 'ARG jlist', options.jlist
print 'ARG jobs', options.jobs
print 'ARG maxlen', options.maxlen
print 'ARG maxticket', options.maxticket
print 'ARG quantum', options.quantum
print 'ARG seed', options.seed
print ''

print 'Here is the job list, with the run time of each job: '

import operator


tickTotal = 0
runTotal  = 0
joblist = []
if options.jlist == '':
    for jobnum in range(0,options.jobs):
        runtime = int(options.maxlen * random.random())
        tickets = int(options.maxticket * random.random())
        runTotal += runtime
        tickTotal += tickets
        joblist.append([jobnum, runtime, tickets])
        print '  Job %d ( length = %d, tickets = %d )' % (jobnum, runtime, tickets)
else:
    jobnum = 0
    for entry in options.jlist.split(','):
        (runtime, tickets) = entry.split(':')
        joblist.append([jobnum, int(runtime), int(tickets)])
        runTotal += int(runtime)
        tickTotal += int(tickets)
        jobnum += 1
    for job in joblist:
        print '  Job %d ( length = %d, tickets = %d )' % (job[0], job[1], job[2])
print '\n'

if options.solve == False:
    print 'Here is the set of random numbers you will need (at most):'
    for i in range(runTotal):
        r = int(random.random() * 1000001)
        print 'Random', r

if options.solve == True:
    print '** Solutions **\n'

    jobs  = len(joblist)
    clock = 0
    for i in range(runTotal):
        r = int(random.random() * 1000001)
        winner = int(r % tickTotal)

        current = 0
        for (job, runtime, tickets) in joblist:
            current += tickets
            if current > winner:
                (wjob, wrun, wtix) = (job, runtime, tickets)
                break

        print 'Random', r, '-> Winning ticket %d (of %d) -> Run %d' % (winner, tickTotal, wjob)
        # print 'Winning ticket %d (of %d) -> Run %d' % (winner, tickTotal, wjob)

        print '  Jobs:',
        for (job, runtime, tickets) in joblist:
            if wjob == job:
                wstr = '*'
            else:
                wstr = ' '

            if runtime > 0:
                tstr = tickets
            else:
                tstr = '---'
            print ' (%s job:%d timeleft:%d tix:%s ) ' % (wstr, job, runtime, tstr), 
        print ''

        # now do the accounting
        if wrun >= options.quantum:
            wrun -= options.quantum
        else:
            wrun = 0

        clock += options.quantum

        # job completed!
        if wrun == 0:
            print '--> JOB %d DONE at time %d' % (wjob, clock)
            tickTotal -= wtix
            wtix = 0
            jobs -= 1

        # update job list
        joblist[wjob] = (wjob, wrun, wtix)

        if jobs == 0:
            print ''
            break




