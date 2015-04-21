#!/usr/bin/env python
#
# Note: This script is intended to be executed at labcodes/labX

import sys, os
import re

if len(sys.argv) < 2:
    print 'Usage: split_score_log.py <raw log file> <lab>'
    sys.exit()

raw_log_f = sys.argv[1]
test_entry_title = re.compile('^([\w][\w -]+): *\([0-9.]*s\)')

raw_log = open(raw_log_f, 'r')
current_test = ''
for line in raw_log.readlines():
    line = line.strip('\n')
    m = test_entry_title.match(line)
    if m:
        print line
        current_test = m.group(1)
        error_log = open('.' + current_test.lower().replace(' ', '_') + '.error', 'w+')
        print >> error_log, line
        continue
    if (not line or line[0] == ' ') and current_test != '':
        print >> error_log, line
    if (line and line[0] != ' ') or line.find('-check') >= 0:
        print line
