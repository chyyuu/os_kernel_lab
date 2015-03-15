#!/usr/bin/env python

import os, sys
import re

if len(sys.argv) < 5:
    print 'Usage: formatter.py <section name> <result-dir> <repo> <tid>'
    sys.exit()

tid_regex = re.compile('([a-z0-9]+)-.*')
lab_title = re.compile('=* (lab[0-9]) =*')
test_entry_title = re.compile('^([\w][\w -]+)(:.*)')

section = sys.argv[1]
result_dir = sys.argv[2]
repo = sys.argv[3]
tid = sys.argv[4]
m = tid_regex.match(tid)
if not m:
    print 'Invalid tid'
    sys.exit()
commit = m.group(1)

lab = ''
while True:
    l = sys.stdin.readline()
    if not l:
        break
    line = l.rstrip('\n')
    output = line
    m = test_entry_title.match(line)
    if m and lab:
        test_entry = m.group(1).lower().replace(' ', '_')
        test_log = os.path.join(result_dir, repo, commit, lab, test_entry + ".error")
        if os.path.exists(test_log):
            rest = m.group(2)
            output = '<a href="/repo/' + '/'.join([repo, commit, lab, test_entry]) + '">' + m.group(1) + '</a>' + rest
    m = lab_title.match(line)
    if m:
        lab = m.group(1)

    sys.stdout.write(output + '<br>')

sys.stdout.flush()
