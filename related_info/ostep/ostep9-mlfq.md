
This program, mlfq.py, allows you to see how the MLFQ scheduler
presented in this chapter behaves. As before, you can use this to generate
problems for yourself using random seeds, or use it to construct a
carefully-designed experiment to see how MLFQ works under different
circumstances. To run the program, type:

prompt> ./mlfq.py

Use the help flag (-h) to see the options:

Usage: mlfq.py [options]
Options:
  -h, --help            show this help message and exit
  -s SEED, --seed=SEED  the random seed
  -n NUMQUEUES, --numQueues=NUMQUEUES
                        number of queues in MLFQ (if not using -Q)
  -q QUANTUM, --quantum=QUANTUM
                        length of time slice (if not using -Q)
  -Q QUANTUMLIST, --quantumList=QUANTUMLIST
                        length of time slice per queue level, 
                        specified as x,y,z,... where x is the 
                        quantum length for the highest-priority 
                        queue, y the next highest, and so forth
  -j NUMJOBS, --numJobs=NUMJOBS
                        number of jobs in the system
  -m MAXLEN, --maxlen=MAXLEN
                        max run-time of a job (if random)
  -M MAXIO, --maxio=MAXIO
                        max I/O frequency of a job (if random)
  -B BOOST, --boost=BOOST
                        how often to boost the priority of all 
                        jobs back to high priority (0 means never)
  -i IOTIME, --iotime=IOTIME
                        how long an I/O should last (fixed constant)
  -S, --stay            reset and stay at same priority level 
                        when issuing I/O
  -l JLIST, --jlist=JLIST
                        a comma-separated list of jobs to run, 
                        in the form x1,y1,z1:x2,y2,z2:... where 
                        x is start time, y is run time, and z 
                        is how often the job issues an I/O request
  -c                    compute answers for me
]

There are a few different ways to use the simulator. One way is to generate
some random jobs and see if you can figure out how they will behave given the
MLFQ scheduler. For example, if you wanted to create a randomly-generated
three-job workload, you would simply type:

prompt> ./mlfq.py -j 3

What you would then see is the specific problem definition:

Here is the list of inputs:
OPTIONS jobs 3
OPTIONS queues 3
OPTIONS quantum length for queue  2 is  10
OPTIONS quantum length for queue  1 is  10
OPTIONS quantum length for queue  0 is  10
OPTIONS boost 0
OPTIONS ioTime 0
OPTIONS stayAfterIO False


For each job, three defining characteristics are given:
  startTime : at what time does the job enter the system
  runTime   : the total CPU time needed by the job to finish
  ioFreq    : every ioFreq time units, the job issues an I/O
              (the I/O takes ioTime units to complete)

Job List:
  Job  0: startTime   0 - runTime  84 - ioFreq   7
  Job  1: startTime   0 - runTime  42 - ioFreq   2
  Job  2: startTime   0 - runTime  51 - ioFreq   4

Compute the execution trace for the given workloads.
If you would like, also compute the response and turnaround
times for each of the jobs.

Use the -c flag to get the exact results when you are finished.

This generates a random workload of three jobs (as specified), on the default
number of queues with a number of default settings. If you run again with the
solve flag on (-c), you'll see the same print out as above, plus the
following:

Execution Trace:

[time 0] JOB BEGINS by JOB 0
[time 0] JOB BEGINS by JOB 1
[time 0] JOB BEGINS by JOB 2
[time 0] Run JOB 0 at PRI 2 [TICKSLEFT 9 RUNTIME 84 TIMELEFT 83]
[time 1] Run JOB 0 at PRI 2 [TICKSLEFT 8 RUNTIME 84 TIMELEFT 82]
[time 2] Run JOB 0 at PRI 2 [TICKSLEFT 7 RUNTIME 84 TIMELEFT 81]
[time 3] Run JOB 0 at PRI 2 [TICKSLEFT 6 RUNTIME 84 TIMELEFT 80]
[time 4] Run JOB 0 at PRI 2 [TICKSLEFT 5 RUNTIME 84 TIMELEFT 79]
[time 5] Run JOB 0 at PRI 2 [TICKSLEFT 4 RUNTIME 84 TIMELEFT 78]
[time 6] Run JOB 0 at PRI 2 [TICKSLEFT 3 RUNTIME 84 TIMELEFT 77]
[time 7] IO_START by JOB 0
[time 7] Run JOB 1 at PRI 2 [TICKSLEFT 9 RUNTIME 42 TIMELEFT 41]
[time 8] Run JOB 1 at PRI 2 [TICKSLEFT 8 RUNTIME 42 TIMELEFT 40]
[time 9] IO_START by JOB 1

...

Final statistics:
  Job  0: startTime   0 - response   0 - turnaround 175
  Job  1: startTime   0 - response   7 - turnaround 191
  Job  2: startTime   0 - response   9 - turnaround 168

  Avg  2: startTime n/a - response 5.33 - turnaround 178.00
]

The trace shows exactly, on a millisecond-by-millisecond time scale, what the
scheduler decided to do. In this example, it begins by running Job 0 for 7 ms
until Job 0 issues an I/O; this is entirely predictable, as Job 0's I/O
frequency is set to 7 ms, meaning that every 7 ms it runs, it will issue an
I/O and wait for it to complete before continuing. At that point, the
scheduler switches to Job 1, which only runs 2 ms before issuing an I/O. 
The scheduler prints the entire execution trace in this manner, and 
finally also computes the response and turnaround times for each job
as well as an average.

You can also control various other aspects of the simulation. For example, you
can specify how many queues you'd like to have in the system (-n) and what the
quantum length should be for all of those queues (-q); if you want even more
control and varied quanta length per queue, you can instead specify the length
of the quantum for each queue with -Q, e.g., -Q 10,20,30] simulates a
scheduler with three queues, with the highest-priority queue having a 10-ms
time slice, the next-highest a 20-ms time-slice, and the low-priority queue a
30-ms time slice.

If you are randomly generating jobs, you can also control how long they might
run for (-m), or how often they generate I/O (-M). If you, however, want more
control over the exact characteristics of the jobs running in the system, you
can use -l (lower-case L) or --jlist, which allows you to specify the exact
set of jobs you wish to simulate. The list is of the form:
x1,y1,z1:x2,y2,z2:... where x is the start time of the job, y is the run time
(i.e., how much CPU time it needs), and z the I/O frequency (i.e., after
running z ms, the job issues an I/O; if z is 0, no I/Os are issued).

For example, if you wanted to recreate the example in Figure 8.3
you would specify a job list as follows:

prompt> ./mlfq.py --jlist 0,180,0:100,20,0 -Q 10,10,10

Running the simulator in this way creates a three-level MLFQ, with each level
having a 10-ms time slice. Two jobs are created: Job 0 which starts at time 0,
runs for 180 ms total, and never issues an I/O; Job 1 starts at 100 ms, needs
only 20 ms of CPU time to complete, and also never issues I/Os.

Finally, there are three more parameters of interest. The -B flag, if set to a
non-zero value, boosts all jobs to the highest-priority queue every N
milliseconds, when invoked as such: 
  prompt> ./mlfq.py -B N 
The scheduler uses this feature to avoid starvation as discussed in the
chapter. However, it is off by default.

The -S flag invokes older Rules 4a and 4b, which means that if a job issues an
I/O before completing its time slice, it will return to that same priority
queue when it resumes execution, with its full time-slice intact.  This
enables gaming of the scheduler.

Finally, you can easily change how long an I/O lasts by using the -i flag. By
default in this simplistic model, each I/O takes a fixed amount of time of 5
milliseconds or whatever you set it to with this flag. 

You can also play around with whether jobs that just complete an I/O are moved
to the head of the queue they are in or to the back, with the -I flag. Check
it out.



