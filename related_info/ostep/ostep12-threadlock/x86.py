#! /usr/bin/env python

import sys
import time
import random
from optparse import OptionParser

#
# HELPER
#
def dospace(howmuch):
    for i in range(howmuch):
        print '%24s' % ' ',

# useful instead of assert
def zassert(cond, str):
    if cond == False:
        print 'ABORT::', str
        exit(1)
    return

class cpu:
    #
    # INIT: how much memory?
    #
    def __init__(self, memory, memtrace, regtrace, cctrace, compute, verbose, printstats, headercount):
        #
        # CONSTANTS
        #
        
        # conditions
        self.COND_GT        = 0
        self.COND_GTE       = 1
        self.COND_LT        = 2
        self.COND_LTE       = 3
        self.COND_EQ        = 4
        self.COND_NEQ       = 5

        # registers in system
        self.REG_ZERO       = 0
        self.REG_AX         = 1
        self.REG_BX         = 2
        self.REG_CX         = 3
        self.REG_DX         = 4
        self.REG_EX         = 5
        self.REG_FX         = 6
        self.REG_SP         = 7
        self.REG_BP         = 8

        # system memory: in KB
        self.max_memory     = memory * 1024

        # which memory addrs and registers to trace?
        self.memtrace       = memtrace
        self.regtrace       = regtrace
        self.cctrace        = cctrace
        self.compute        = compute
        self.verbose        = verbose
        self.printstats     = printstats
        self.headercount    = headercount

        self.PC             = 0
        self.registers      = {}
        self.conditions     = {}
        self.labels         = {}
        self.vars           = {}
        self.memory         = {}
        self.pmemory        = {}  # for printable version of what's in memory (instructions)

        self.condlist       = [self.COND_GTE, self.COND_GT,  self.COND_LTE,
                               self.COND_LT,  self.COND_NEQ, self.COND_EQ]
        self.regnums        = [self.REG_ZERO,
                               self.REG_AX, self.REG_BX, self.REG_CX, 
                               self.REG_DX, self.REG_EX, self.REG_FX,
                               self.REG_SP, self.REG_BP]

        self.regnames         = {}
        self.regnames['zero'] = self.REG_ZERO # hidden zero-valued register
        self.regnames['ax']   = self.REG_AX
        self.regnames['bx']   = self.REG_BX
        self.regnames['cx']   = self.REG_CX
        self.regnames['dx']   = self.REG_DX
        self.regnames['ex']   = self.REG_EX
        self.regnames['fx']   = self.REG_FX
        self.regnames['sp']   = self.REG_SP
        self.regnames['bp']   = self.REG_BP

        tmplist = []
        for r in self.regtrace:
            zassert(r in self.regnames, 'Register %s cannot be traced because it does not exist' % r)
            tmplist.append(self.regnames[r])
        self.regtrace = tmplist

        self.init_memory()
        self.init_registers()
        self.init_condition_codes()

    #
    # BEFORE MACHINE RUNS
    #
    def init_condition_codes(self):
        for c in self.condlist:
            self.conditions[c] = False

    def init_memory(self):
        for i in range(self.max_memory):
            self.memory[i] = 0

    def init_registers(self):
        for i in self.regnums:
            self.registers[i] = 0

    def dump_memory(self):
        print 'MEMORY DUMP'
        for i in range(self.max_memory):
            if i not in self.pmemory and i in self.memory and self.memory[i] != 0:
                print '  m[%d]' % i, self.memory[i]

    #
    # INFORMING ABOUT THE HARDWARE
    #
    def get_regnum(self, name):
        assert(name in self.regnames)
        return self.regnames[name]

    def get_regname(self, num):
        assert(num in self.regnums)
        for rname in self.regnames:
            if self.regnames[rname] == num:
                return rname
        return ''
    
    def get_regnums(self):
        return self.regnums

    def get_condlist(self):
        return self.condlist

    def get_reg(self, reg):
        assert(reg in self.regnums)
        return self.registers[reg]

    def get_cond(self, cond):
        assert(cond in self.condlist)
        return self.conditions[cond]

    def get_pc(self):
        return self.PC
        
    def set_reg(self, reg, value):
        assert(reg in self.regnums)
        self.registers[reg] = value

    def set_cond(self, cond, value):
        assert(cond in self.condlist)
        self.conditions[cond] = value

    def set_pc(self, pc):
        self.PC = pc
        
    #
    # INSTRUCTIONS
    #
    def halt(self):
        return -1

    def iyield(self):
        return -2

    def nop(self):
        return 0

    def rdump(self):
        print 'REGISTERS::',
        print 'ax:', self.registers[self.REG_AX], 
        print 'bx:', self.registers[self.REG_BX], 
        print 'cx:', self.registers[self.REG_CX], 
        print 'dx:', self.registers[self.REG_DX],
        print 'ex:', self.registers[self.REG_EX],
        print 'fx:', self.registers[self.REG_FX],
        return

    def mdump(self, index):
        print 'm[%d] ' % index, self.memory[index]
        return

    # 
    # MEMORY MOVES
    # 
    def move_i_to_r(self, src, dst):
        self.registers[dst] = src
        return 0

    # memory: value, register, register
    def move_i_to_m(self, src, value, reg1, reg2, scale):
        tmp = value + self.registers[reg1] + (scale * self.registers[reg2])
        self.memory[tmp] = src
        return 0

    def move_m_to_r(self, value, reg1, reg2, scale, dst):
        tmp = value + self.registers[reg1] + (scale * self.registers[reg2])
        self.registers[dst] = self.memory[tmp] 

    def move_r_to_m(self, src, value, reg1, reg2, scale):
        tmp = value + self.registers[reg1] + (scale * self.registers[reg2])
        self.memory[tmp] = self.registers[src]
        return 0

    def move_r_to_r(self, src, dst):
        self.registers[dst] = self.registers[src]
        return 0

    #
    # LOAD EFFECTIVE ADDRESS (everything but the final change of memory value)
    #
    def lea_m_to_r(self, value, reg1, reg2, scale, dst):
        tmp = value + self.registers[reg1] + (scale * self.registers[reg2])
        self.registers[dst] = tmp

    #
    # ARITHMETIC INSTRUCTIONS
    # 
    def add_i_to_r(self, src, dst):
        self.registers[dst] += src
        return 0

    def add_r_to_r(self, src, dst):
        self.registers[dst] += self.registers[src]
        return 0

    def mul_i_to_r(self, src, dst):
        self.registers[dst] *= src
        return 0

    def mul_r_to_r(self, src, dst):
        self.registers[dst] *= self.registers[src]
        return 0

    def sub_i_to_r(self, src, dst):
        self.registers[dst] -= src
        return 0

    def sub_r_to_r(self, src, dst):
        self.registers[dst] -= self.registers[src]
        return 0

    def neg_r(self, src):
        self.registers[src] = -self.registers[src]

    #
    # SUPPORT FOR LOCKS
    #
    def atomic_exchange(self, src, value, reg1, reg2):
        tmp                 = value + self.registers[reg1] + self.registers[reg2]
        old                 = self.memory[tmp]
        self.memory[tmp]    = self.registers[src]
        self.registers[src] = old
        return 0

    def fetchadd(self, src, value, reg1, reg2):
        tmp                 = value + self.registers[reg1] + self.registers[reg2]
        old                 = self.memory[tmp]
        self.memory[tmp]    = self.memory[tmp] + self.registers[src] 
        self.registers[src] = old

    #
    # TEST for conditions
    #
    def test_all(self, src, dst):
        self.init_condition_codes()
        if dst > src:
            self.conditions[self.COND_GT]  = True
        if dst >= src:
            self.conditions[self.COND_GTE] = True
        if dst < src:
            self.conditions[self.COND_LT]  = True
        if dst <= src:
            self.conditions[self.COND_LTE] = True
        if dst == src:
            self.conditions[self.COND_EQ]  = True
        if dst != src:
            self.conditions[self.COND_NEQ] = True
        return 0

    def test_i_r(self, src, dst):
        self.init_condition_codes()
        return self.test_all(src, self.registers[dst])

    def test_r_i(self, src, dst):
        self.init_condition_codes()
        return self.test_all(self.registers[src], dst)

    def test_r_r(self, src, dst):
        self.init_condition_codes()
        return self.test_all(self.registers[src], self.registers[dst])

    #
    # JUMPS
    #
    def jump(self, targ):
        self.PC = targ  
        return 0
    
    def jump_notequal(self, targ):
        if self.conditions[self.COND_NEQ] == True:
            self.PC = targ
        return 0

    def jump_equal(self, targ):
        if self.conditions[self.COND_EQ] == True:
            self.PC = targ
        return 0

    def jump_lessthan(self, targ):
        if self.conditions[self.COND_LT] == True:
            self.PC = targ
        return 0

    def jump_lessthanorequal(self, targ):
        if self.conditions[self.COND_LTE] == True:
            self.PC = targ
        return 0

    def jump_greaterthan(self, targ):
        if self.conditions[self.COND_GT] == True:
            self.PC = targ
        return 0

    def jump_greaterthanorequal(self, targ):
        if self.conditions[self.COND_GTE] == True:
            self.PC = targ
        return 0

    #
    # CALL and RETURN
    #
    def call(self, targ):
        self.registers[self.REG_SP] -= 4
        self.memory[self.registers[self.REG_SP]] = self.PC 
        self.PC = targ

    def ret(self):
        self.PC = self.memory[self.registers[self.REG_SP]]
        self.registers[self.REG_SP] += 4

    #
    # STACK and related
    #
    def push_r(self, reg):
        self.registers[self.REG_SP] -= 4
        self.memory[self.registers[self.REG_SP]] = self.registers[reg]
        return 0

    def push_m(self, value, reg1, reg2, scale):
        self.registers[self.REG_SP] -= 4
        tmp = value + self.registers[reg1] + (self.registers[reg2] * scale)
        # push address onto stack, not memory value itself
        self.memory[self.registers[self.REG_SP]] = tmp
        return 0

    def pop(self):
        self.registers[self.REG_SP] += 4

    def pop_r(self, dst):
        self.registers[dst] = self.memory[self.registers[self.REG_SP]]
        self.registers[self.REG_SP] += 4

    #
    # HELPER func for getarg
    #
    def register_translate(self, r):
        if r in self.regnames:
            return self.regnames[r]
        zassert(False, 'Register %s is not a valid register' % r)
        return

    def getregname(self, r):
        t = r.strip()
        if t == '':
            return 'zero'
        zassert(t[0] == '%', 'Expecting a proper register name, got [%s]' % r)
        return r.split('%')[1].strip()

    #
    # HELPER in parsing mov (quite primitive) and other ops
    # returns: (value, type)
    # where type is (TYPE_REGISTER, TYPE_IMMEDIATE, TYPE_MEMORY)
    # 
    # FORMATS
    #    %ax           - register
    #    $10           - immediate
    #    10            - direct memory
    #    10(%ax)       - memory + reg indirect
    #    10(%ax,%bx)   - memory + 2 reg indirect
    #    10(%ax,%bx,4) - XXX (not handled)
    #
    def getarg(self, arg):
        tmp1 = arg.replace(',', ' ')
        tmp  = tmp1.replace(' \t', '')

        if tmp[0] == '$':
            # this is an IMMEDIATE VALUE
            value = tmp.split('$')[1]
            neg = 1
            if value[0] == '-':
                value = value[1:]
                neg = -1
            zassert(value.isdigit(), 'value [%s] must be a digit' % value)
            return neg * int(value), 'TYPE_IMMEDIATE'
        elif tmp[0] == '%':
            # this is a REGISTER
            register = tmp.split('%')[1]
            return self.register_translate(register), 'TYPE_REGISTER'
        elif tmp[0] == '.':
            # this is a LABEL
            targ = tmp
            return targ, 'TYPE_LABEL'
        elif tmp[0].isalpha() and not tmp[0].isdigit():
            # this is a VARIABLE
            zassert(tmp in self.vars, 'Variable %s is not declared' % tmp)
            return '%d,%d,%d,1' % (self.vars[tmp], self.register_translate('zero'), self.register_translate('zero')), 'TYPE_MEMORY'
        elif tmp[0].isdigit() or tmp[0] == '-' or tmp[0] == '(':
            # MOST GENERAL CASE: number(reg,reg) or number(reg) or number(reg,reg,number)
            neg = 1
            if tmp[0] == '-':
                tmp = tmp[1:]
                neg = -1
            s = tmp.split('(')
            if len(s) == 1:
                # no parens -> we just assume that we have a constant value (an address), e.g., mov 10, %ax
                value = neg * int(tmp)
                return '%d,%d,%d,1' % (int(value), self.register_translate('zero'), self.register_translate('zero')), 'TYPE_MEMORY'
            elif len(s) == 2:
                # here we just assume that we have something in parentheses
                # e.g., mov 10(%ax) or mov 10(%ax,%bx) or mov 10(%ax,%bx,10) or mov (%ax,%bx,10) or ...

                # if no leading number exists, first char should be a paren; in that case, value is just made to be 0
                # otherwise we should handle either a number or a negative number
                if tmp[0] != '(':
                    zassert(s[0].strip().isdigit() == True, 'First number should be a digit [%s]' % s[0])
                    value = neg * int(s[0])
                else:
                    value = 0
                t = s[1].split(')')[0].split('__BREAK__')
                if len(t) == 1:
                    register = self.getregname(t[0])
                    return '%d,%d,%d,1' % (int(value), self.register_translate(register), self.register_translate('zero')), 'TYPE_MEMORY'
                elif len(t) == 2:
                    register1 = self.getregname(t[0])
                    register2 = self.getregname(t[1])
                    return '%d,%d,%d,1' % (int(value), self.register_translate(register1), self.register_translate(register2)), 'TYPE_MEMORY'
                elif len(t) == 3:
                    register1 = self.getregname(t[0])
                    register2 = self.getregname(t[1])
                    scale     = int(t[2])
                    return '%d,%d,%d,%d' % (int(value), self.register_translate(register1), self.register_translate(register2), scale), 'TYPE_MEMORY'
                else:
                    print 'mov: bad argument [%s]' % tmp
                    exit(1)
                    return
            else:
                print 'mov: bad argument [%s]' % tmp
                exit(1)
                return
        zassert(True, 'mov: bad argument [%s]' % arg)
        return

    #
    # helper function in parsing complex args to mov/lea instruction
    #
    def removecommas(self, cline, inargs):
        inparen = False
        outargs = ''
        for i in range(len(inargs)):
            if inargs[i] == '(':
                zassert(inparen == False, 'cannot have nested parenthesis in argument [%s]' % cline)
                inparen = True
            if inargs[i] == ')':
                zassert(inparen == True, 'cannot have right parenthesis without first having left one [%s]' % cline)
                inparen = False
            if inparen == True:
                if inargs[i] == ',':
                    outargs += '__BREAK__'
                else:
                    outargs += inargs[i]
            else:
                outargs += inargs[i]
        zassert(inparen == False, 'did not close parentheses [%s]' % cline)
        return outargs

    #
    # LOAD a program into memory
    # make it ready to execute
    #
    def load(self, infile, loadaddr):
        pc   = int(loadaddr)
        fd   = open(infile)

        bpc  = loadaddr
        data = 100

        for line in fd:
            cline = line.rstrip()

            # remove everything after the comment marker
            ctmp = cline.split('#')
            assert(len(ctmp) == 1 or len(ctmp) == 2)
            if len(ctmp) == 2:
                cline = ctmp[0]

            # remove empty lines, and split line by spaces
            tmp = cline.split()
            if len(tmp) == 0:
                continue

            # only pay attention to labels and variables
            if tmp[0] == '.var':
                assert(len(tmp) == 2 or len(tmp) == 3)
                assert(tmp[0] not in self.vars)
                self.vars[tmp[1]] = data
                mul = 1
                if len(tmp) == 3:
                    mul = int(tmp[2])
                data += (4 * mul)
                zassert(data < bpc, 'Load address overrun by static data')
                if self.verbose: print 'ASSIGN VAR', tmp[0], "-->", tmp[1], self.vars[tmp[1]]
            elif tmp[0][0] == '.':
                assert(len(tmp) == 1)
                self.labels[tmp[0]] = int(pc)
                if self.verbose: print 'ASSIGN LABEL', tmp[0], "-->", pc
            else:
                pc += 1
        fd.close()

        if self.verbose: print ''

        # second pass: do everything else
        pc = int(loadaddr)
        fd = open(infile)
        for line in fd:
            cline = line.rstrip()

            # remove everything after the comment marker
            ctmp = cline.split('#')
            assert(len(ctmp) == 1 or len(ctmp) == 2)
            if len(ctmp) == 2:
                cline = ctmp[0]

            # remove empty lines, and split line by spaces
            tmp = cline.split()
            if len(tmp) == 0:
                continue

            # skip labels: all else must be instructions
            if cline[0] != '.':
                tmp              = cline.split(None, 1)
                opcode           = tmp[0]
                self.pmemory[pc] = cline.strip()

                if self.verbose == True:
                    print 'opcode', opcode

                # MAIN OPCODE LOOP
                if opcode == 'mov':
                    # most painful one to parse (due to generic form)
                    # could be mov x(r1,r2,4), r3 or mov r1, (r2,r3) or ...
                    outargs = self.removecommas(cline, tmp[1])

                    rtmp = outargs.split(',')
                    zassert(len(rtmp) == 2, 'mov: needs two args, separated by commas [%s]' % cline)
                    arg1 = rtmp[0].strip()
                    arg2 = rtmp[1].strip()
                    (src, stype) = self.getarg(arg1)
                    (dst, dtype) = self.getarg(arg2)
                    # print 'MOV', src, stype, dst, dtype
                    if stype == 'TYPE_MEMORY'      and dtype == 'TYPE_MEMORY':
                        print 'bad mov: two memory arguments'
                        exit(1)
                    elif stype == 'TYPE_IMMEDIATE' and dtype == 'TYPE_IMMEDIATE':
                        print 'bad mov: two immediate arguments'
                        exit(1)
                    elif stype == 'TYPE_IMMEDIATE' and dtype == 'TYPE_REGISTER':
                        self.memory[pc]  = 'self.move_i_to_r(%d, %d)' % (int(src), dst)
                    elif stype == 'TYPE_IMMEDIATE' and dtype == 'TYPE_REGISTER':
                        self.memory[pc]  = 'self.move_i_to_r(%d, %d)' % (int(src), dst)
                    elif stype == 'TYPE_MEMORY'    and dtype == 'TYPE_REGISTER':
                        tmp = src.split(',')
                        assert(len(tmp) == 4)
                        self.memory[pc] = 'self.move_m_to_r(%d, %d, %d, %d, %d)' % (int(tmp[0]), int(tmp[1]), int(tmp[2]), int(tmp[3]), dst)
                    elif stype == 'TYPE_REGISTER'  and dtype == 'TYPE_MEMORY':
                        tmp = dst.split(',')
                        assert(len(tmp) == 4)
                        self.memory[pc] = 'self.move_r_to_m(%d, %d, %d, %d, %d)' % (src, int(tmp[0]), int(tmp[1]), int(tmp[2]), int(tmp[3]))
                    elif stype == 'TYPE_REGISTER'  and dtype == 'TYPE_REGISTER':
                        self.memory[pc] = 'self.move_r_to_r(%d, %d)' % (src, dst)
                    elif stype == 'TYPE_IMMEDIATE' and dtype == 'TYPE_MEMORY':
                        tmp = dst.split(',')
                        assert(len(tmp) == 4)
                        self.memory[pc] = 'self.move_i_to_m(%d, %d, %d, %d, %d)' % (src, int(tmp[0]), int(tmp[1]), int(tmp[2]), int(tmp[3]))
                    else:
                        zassert(False, 'malformed mov instruction')
                elif opcode == 'lea':
                    rtmp = tmp[1].split(',', 1)
                    zassert(len(tmp) == 2 and len(rtmp) == 2, 'lea: needs two args, separated by commas [%s]' % cline)
                    arg1 = rtmp[0].strip()
                    arg2 = rtmp[1].strip()
                    (src, stype) = self.getarg(arg1)
                    (dst, dtype) = self.getarg(arg2)
                    if stype == 'TYPE_MEMORY' and dtype == 'TYPE_REGISTER':
                        tmp = src.split(',')
                        assert(len(tmp) == 4)
                        self.memory[pc] = 'self.lea_m_to_r(%d, %d, %d, %d, %d)' % (int(tmp[0]), int(tmp[1]), int(tmp[2]), int(tmp[3]), dst)
                    else:
                        zassert(False, 'malformed lea instruction (should be memory address source to register destination')
                elif opcode == 'neg':
                    zassert(len(tmp) == 2, 'neg: takes one argument')
                    arg = tmp[1].strip()
                    (dst, dtype) = self.getarg(arg)
                    zassert(dtype == 'TYPE_REGISTER', 'Can only neg a register')
                    self.memory[pc] = 'self.neg_r(%d)' % dst
                elif opcode == 'pop':
                    if len(tmp) == 1:
                        self.memory[pc] = 'self.pop()'
                    elif len(tmp) == 2:
                        arg = tmp[1].strip()
                        (dst, dtype) = self.getarg(arg)
                        zassert(dtype == 'TYPE_REGISTER', 'Can only pop into a register')
                        self.memory[pc] = 'self.pop_r(%d)' % dst
                    else:
                        zassert(False, 'pop instruction must take zero/one args')
                elif opcode == 'push':
                    (src, stype) = self.getarg(tmp[1].strip())
                    if stype == 'TYPE_REGISTER':
                        self.memory[pc] = 'self.push_r(%d)' % (int(src))
                    elif stype == 'TYPE_MEMORY':
                        tmp = src.split(',')
                        assert(len(tmp) == 4)
                        self.memory[pc] = 'self.push_m(%d,%d,%d,%d)' % (int(tmp[0]), int(tmp[1]), int(tmp[2]), int(tmp[3]))
                    else:
                        zassert(False, 'Cannot push anything but registers')
                elif opcode == 'call':
                    (targ, ttype) = self.getarg(tmp[1].strip())
                    if ttype == 'TYPE_LABEL':
                        self.memory[pc] = 'self.call(%d)' % (int(self.labels[targ]))
                    else:
                        zassert(False, 'Cannot call anything but a label')
                elif opcode == 'ret':
                    assert(len(tmp) == 1)
                    self.memory[pc] = 'self.ret()'
                elif opcode == 'mul':
                    rtmp = tmp[1].split(',', 1)
                    zassert(len(tmp) == 2 and len(rtmp) == 2, 'mul: needs two args, separated by commas [%s]' % cline)
                    arg1 = rtmp[0].strip()
                    arg2 = rtmp[1].strip()
                    (src, stype) = self.getarg(arg1)
                    (dst, dtype) = self.getarg(arg2)
                    if stype == 'TYPE_IMMEDIATE' and dtype == 'TYPE_REGISTER':
                        self.memory[pc] = 'self.mul_i_to_r(%d, %d)' % (int(src), dst)
                    elif stype == 'TYPE_REGISTER' and dtype == 'TYPE_REGISTER':
                        self.memory[pc] = 'self.mul_r_to_r(%d, %d)' % (int(src), dst)
                    else:
                        zassert(False, 'malformed usage of add instruction')
                elif opcode == 'add':
                    rtmp = tmp[1].split(',', 1)
                    zassert(len(tmp) == 2 and len(rtmp) == 2, 'add: needs two args, separated by commas [%s]' % cline)
                    arg1 = rtmp[0].strip()
                    arg2 = rtmp[1].strip()
                    (src, stype) = self.getarg(arg1)
                    (dst, dtype) = self.getarg(arg2)
                    if stype == 'TYPE_IMMEDIATE' and dtype == 'TYPE_REGISTER':
                        self.memory[pc] = 'self.add_i_to_r(%d, %d)' % (int(src), dst)
                    elif stype == 'TYPE_REGISTER' and dtype == 'TYPE_REGISTER':
                        self.memory[pc] = 'self.add_r_to_r(%d, %d)' % (int(src), dst)
                    else:
                        zassert(False, 'malformed usage of add instruction')
                elif opcode == 'sub':
                    rtmp = tmp[1].split(',', 1)
                    zassert(len(tmp) == 2 and len(rtmp) == 2, 'sub: needs two args, separated by commas [%s]' % cline)
                    arg1 = rtmp[0].strip()
                    arg2 = rtmp[1].strip()
                    (src, stype) = self.getarg(arg1)
                    (dst, dtype) = self.getarg(arg2)
                    if stype == 'TYPE_IMMEDIATE' and dtype == 'TYPE_REGISTER':
                        self.memory[pc] = 'self.sub_i_to_r(%d, %d)' % (int(src), dst)
                    elif stype == 'TYPE_REGISTER' and dtype == 'TYPE_REGISTER':
                        self.memory[pc] = 'self.sub_r_to_r(%d, %d)' % (int(src), dst)
                    else:
                        zassert(False, 'malformed usage of sub instruction')
                elif opcode == 'fetchadd':
                    rtmp = tmp[1].split(',', 1)
                    zassert(len(tmp) == 2 and len(rtmp) == 2, 'fetchadd: needs two args, separated by commas [%s]' % cline)
                    arg1 = rtmp[0].strip()
                    arg2 = rtmp[1].strip()
                    (src, stype) = self.getarg(arg1)
                    (dst, dtype) = self.getarg(arg2)
                    tmp = dst.split(',')
                    assert(len(tmp) == 4)
                    if stype == 'TYPE_REGISTER' and dtype == 'TYPE_MEMORY':
                        self.memory[pc] = 'self.fetchadd(%d, %d, %d, %d)' % (src, int(tmp[0]), int(tmp[1]), int(tmp[2]))
                    else:
                        zassert(False, 'poorly specified fetch and add')
                elif opcode == 'xchg':
                    rtmp = tmp[1].split(',', 1)
                    zassert(len(tmp) == 2 and len(rtmp) == 2, 'xchg: needs two args, separated by commas [%s]' % cline)
                    arg1 = rtmp[0].strip()
                    arg2 = rtmp[1].strip()
                    (src, stype) = self.getarg(arg1)
                    (dst, dtype) = self.getarg(arg2)
                    tmp = dst.split(',')
                    assert(len(tmp) == 4)
                    if stype == 'TYPE_REGISTER' and dtype == 'TYPE_MEMORY':
                        self.memory[pc] = 'self.atomic_exchange(%d, %d, %d, %d)' % (src, int(tmp[0]), int(tmp[1]), int(tmp[2]))
                    else:
                        zassert(False, 'poorly specified atomic exchange')
                elif opcode == 'test':
                    rtmp = tmp[1].split(',', 1)
                    zassert(len(tmp) == 2 and len(rtmp) == 2, 'test: needs two args, separated by commas [%s]' % cline)
                    arg1 = rtmp[0].strip()
                    arg2 = rtmp[1].strip()
                    (src, stype) = self.getarg(arg1)
                    (dst, dtype) = self.getarg(arg2)
                    if stype == 'TYPE_IMMEDIATE' and dtype == 'TYPE_REGISTER':
                        self.memory[pc] = 'self.test_i_r(%d, %d)' % (int(src), dst)
                    elif stype == 'TYPE_REGISTER' and dtype == 'TYPE_REGISTER':
                        self.memory[pc] = 'self.test_r_r(%d, %d)' % (int(src), dst)
                    elif stype == 'TYPE_REGISTER' and dtype == 'TYPE_IMMEDIATE':
                        self.memory[pc] = 'self.test_r_i(%d, %d)' % (int(src), dst)
                    else:
                        zassert(False, 'malformed usage of test instruction')
                elif opcode == 'j':
                    (targ, ttype) = self.getarg(tmp[1].strip())
                    zassert(ttype == 'TYPE_LABEL', 'bad jump target [%s]' % tmp[1].strip())
                    self.memory[pc] = 'self.jump(%d)' % int(self.labels[targ])
                elif opcode == 'jne':
                    (targ, ttype) = self.getarg(tmp[1].strip())
                    zassert(ttype == 'TYPE_LABEL', 'bad jump target [%s]' % tmp[1].strip())
                    self.memory[pc] = 'self.jump_notequal(%d)' % int(self.labels[targ])
                elif opcode == 'je':
                    (targ, ttype) = self.getarg(tmp[1].strip())
                    zassert(ttype == 'TYPE_LABEL', 'bad jump target [%s]' % tmp[1].strip())
                    self.memory[pc] = 'self.jump_equal(%d)' % self.labels[targ]
                elif opcode == 'jlt':
                    (targ, ttype) = self.getarg(tmp[1].strip())
                    zassert(ttype == 'TYPE_LABEL', 'bad jump target [%s]' % tmp[1].strip())
                    self.memory[pc] = 'self.jump_lessthan(%d)' % int(self.labels[targ])
                elif opcode == 'jlte':
                    (targ, ttype) = self.getarg(tmp[1].strip())
                    zassert(ttype == 'TYPE_LABEL', 'bad jump target [%s]' % tmp[1].strip())
                    self.memory[pc] = 'self.jump_lessthanorequal(%s)' % self.labels[targ]
                elif opcode == 'jgt':
                    (targ, ttype) = self.getarg(tmp[1].strip())
                    zassert(ttype == 'TYPE_LABEL', 'bad jump target [%s]' % tmp[1].strip())
                    self.memory[pc] = 'self.jump_greaterthan(%d)' % int(self.labels[targ])
                elif opcode == 'jgte':
                    (targ, ttype) = self.getarg(tmp[1].strip())
                    zassert(ttype == 'TYPE_LABEL', 'bad jump target [%s]' % tmp[1].strip())
                    self.memory[pc] = 'self.jump_greaterthanorequal(%s)' % self.labels[targ]
                elif opcode == 'nop':
                    self.memory[pc] = 'self.nop()'
                elif opcode == 'halt':
                    self.memory[pc] = 'self.halt()'
                elif opcode == 'yield':
                    self.memory[pc] = 'self.iyield()'
                elif opcode == 'rdump':
                    self.memory[pc] = 'self.rdump()'
                elif opcode == 'mdump':
                    self.memory[pc] = 'self.mdump(%s)' % tmp[1]
                else:
                    print 'illegal opcode: ', opcode
                    exit(1)

                if self.verbose: print 'pc:%d LOADING %20s --> %s' % (pc, self.pmemory[pc], self.memory[pc])
                
                # INCREMENT PC for loader
                pc += 1
        # END: loop over file
        fd.close()
        if self.verbose: print ''
        return
    # END: load

    def print_headers(self, procs):
        # print some headers
        if self.printstats == True:
            print 'icount',
        if len(self.memtrace) > 0:
            for m in self.memtrace:
                if m[0].isdigit():
                    print '%5d' % int(m),
                else:
                    zassert(m in self.vars, 'Traced variable %s not declared' % m)
                    print '%5s' % m,
            print ' ',
        if len(self.regtrace) > 0:
            for r in self.regtrace:
                print '%5s' % self.get_regname(r),
            print ' ',
        if cctrace == True:
            print '>= >  <= <  != ==', 

        # and per thread
        for i in range(procs.getnum()):
            print '       Thread %d        ' % i,
        print ''
        return

    def print_trace(self, newline):
        if self.printstats == True:
            print '%6d' % self.icount, 
        if len(self.memtrace) > 0:
            for m in self.memtrace:
                if self.compute:
                    if m[0].isdigit():
                        print '%5d' % self.memory[int(m)],
                    else:
                        zassert(m in self.vars, 'Traced variable %s not declared' % m)
                        print '%5d' % self.memory[self.vars[m]],
                else:
                    print '%5s' % '?',
            print ' ',
        if len(self.regtrace) > 0:
            for r in self.regtrace:
                if self.compute:
                    print '%5d' % self.registers[r],
                else:
                    print '%5s' % '?',
            print ' ',
        if cctrace == True:
            for c in self.condlist:
                if self.compute:
                    if self.conditions[c]:
                        print '1 ',
                    else:
                        print '0 ',
                else:
                    print '? ',
        if (len(self.memtrace) > 0 or len(self.regtrace) > 0 or cctrace == True) and newline == True:
            print ''
        return

    def setint(self, intfreq, intrand):
        if intrand == False:
            return intfreq
        return int(random.random() * intfreq) + 1

    def run(self, procs, intfreq, intrand):
        # hw init: cc's, interrupt frequency, etc.
        if procs.ismanual() == True:
            intfreq   = 1
            interrupt = 1
            intrand   = False

        interrupt   = self.setint(intfreq, intrand)
        self.icount = 0

        # you always get one printing
        print ''
        self.print_headers(procs)
        print ''
        self.print_trace(True)
        
        while True:
            if self.headercount > 0 and self.icount % self.headercount == 0 and self.icount > 0:
                print ''
                self.print_headers(procs)
                print ''
                self.print_trace(True)
            
            # need thread ID of current process
            tid = procs.getcurr().gettid()

            # FETCH
            prevPC       = self.PC
            instruction  = self.memory[self.PC]
            self.PC     += 1

            # DECODE and EXECUTE
            # key: self.PC may be changed during eval; thus MUST be incremented BEFORE eval
            rc = eval(instruction)

            # tracing details: ALWAYS AFTER EXECUTION OF INSTRUCTION
            self.print_trace(False)

            # output: thread-proportional spacing followed by PC and instruction
            dospace(tid)
            print prevPC, self.pmemory[prevPC]
            self.icount += 1

            # halt instruction issued
            if rc == -1:
                procs.done()
                # finish execution by returning from run()
                if procs.numdone() == procs.getnum():
                    return self.icount
                procs.next()
                procs.restore()

                self.print_trace(False)
                for i in range(procs.getnum()):
                    print '----- Halt;Switch ----- ',
                print ''

            # do interrupt processing
            # just counts down the interrupt counter to zero
            # when it gets to 0, or when the 'yield' instruction is issued (rc=-2)
            # a switch takes place
            # key thing: if manual scheduling is done (procsched), interrupt
            # must take place every instruction for this to work
            interrupt -= 1
            if interrupt == 0 or rc == -2:
                interrupt = self.setint(intfreq, intrand)
                curr = procs.getcurr()
                procs.save()
                procs.next()
                procs.restore()
                next = procs.getcurr()

                if procs.ismanual() == False or (procs.ismanual() == True and curr != next):
                    self.print_trace(False)
                    for i in range(procs.getnum()):
                        print '------ Interrupt ------ ',
                    print ''
                
        # END: while
        return

# 
# END: class cpu
# 


#
# PROCESS LIST class
#
# Tracks all running processes in the program
# Also deals with manual scheduling as specified by user
#
class proclist:
    def __init__(self):
        self.plist     = []      # list of process objects
        self.active    = 0       # tracks how many processes are active
        self.manual    = False
        self.procsched = []      # list of which processes to run in what order (by ID)
        self.curr      = 0       # currently running process (index into procsched list)

    def finalize(self, procsched):
        if procsched == '':
            for i in range(len(self.plist)):
                self.procsched.append(i)
            self.curr = 0
            self.restore()
            return

        # in this case, user has passed in schedule
        self.manual = True
        for i in range(len(procsched)):
            p = int(procsched[i])
            if p >= self.getnum():
                print 'bad schedule: cannot include a thread that does not exist (%d)' % p
                exit(1)
            self.procsched.append(p)
        check = []
        for p in self.procsched:
            if p not in check:
                check.append(p)
        if len(check) != self.active:
            print 'bad schedule: does not include ALL processes', self.procsched
            exit(1)
        self.curr = 0
        self.restore()
        return
            
    def addproc(self, p):
        self.active += 1
        self.plist.append(p)
        return

    def ismanual(self):
        return self.manual

    def done(self):
        p = self.procsched[self.curr]
        self.plist[p].setdone()
        self.active -= 1
        return

    def numdone(self):
        return len(self.plist) - self.active

    def getnum(self):
        return len(self.plist)

    def getcurr(self):
        return self.plist[self.procsched[self.curr]]

    def save(self):
        self.plist[self.procsched[self.curr]].save()
        return

    def restore(self):
        self.plist[self.procsched[self.curr]].restore()
        return

    def next(self):
        while True:
            self.curr += 1
            if self.curr == len(self.procsched):
                self.curr = 0
            p = self.procsched[self.curr]
            if self.plist[p].isdone() == False:
                return
        return

            
#
# PROCESS class
#
class process:
    def __init__(self, cpu, tid, pc, stackbottom, reginit):
        self.cpu   = cpu  # object reference
        self.tid   = tid
        self.pc    = pc
        self.regs  = {}
        self.cc    = {}
        self.done  = False
        self.stack = stackbottom

        # init regs: all 0 or specially set to something
        for r in self.cpu.get_regnums():
            self.regs[r] = 0
        if reginit != '':
            # form: ax=1,bx=2 (for some subset of registers)
            for r in reginit.split(':'):
                tmp = r.split('=')
                assert(len(tmp) == 2)
                self.regs[self.cpu.get_regnum(tmp[0])] = int(tmp[1])

        # init CCs
        for c in self.cpu.get_condlist():
            self.cc[c] = False

        # stack
        self.regs[self.cpu.get_regnum('sp')] = stackbottom

        return

    def gettid(self):
        return self.tid

    def save(self):
        self.pc = self.cpu.get_pc()
        for c in self.cpu.get_condlist():
            self.cc[c] = self.cpu.get_cond(c)
        for r in self.cpu.get_regnums():
            self.regs[r] = self.cpu.get_reg(r)

    def restore(self):
        self.cpu.set_pc(self.pc)
        for c in self.cpu.get_condlist():
            self.cpu.set_cond(c, self.cc[c])
        for r in self.cpu.get_regnums():
            self.cpu.set_reg(r, self.regs[r])

    def setdone(self):
        self.done = True

    def isdone(self):
        return self.done == True

#
# main program
#
parser = OptionParser()
parser.add_option('-s', '--seed',      default=0,          help='the random seed',                  action='store',      type='int',    dest='seed')
parser.add_option('-t', '--threads',   default=2,          help='number of threads',                action='store',      type='int',    dest='numthreads')
parser.add_option('-p', '--program',   default='',         help='source program (in .s)',           action='store',      type='string', dest='progfile')
parser.add_option('-i', '--interrupt', default=50,         help='interrupt frequency',              action='store',      type='int',    dest='intfreq')
parser.add_option('-P', '--procsched', default='',         help='control exactly which thread runs when',
                                                                                                    action='store',      type='string', dest='procsched')
parser.add_option('-r', '--randints',  default=False,      help='if interrupts are random',         action='store_true',                dest='intrand')
parser.add_option('-a', '--argv',      default='',
                  help='comma-separated per-thread args (e.g., ax=1,ax=2 sets thread 0 ax reg to 1 and thread 1 ax reg to 2); specify multiple regs per thread via colon-separated list (e.g., ax=1:bx=2,cx=3 sets thread 0 ax and bx and just cx for thread 1)',
                  action='store',      type='string', dest='argv')
parser.add_option('-L', '--loadaddr',  default=1000,       help='address where to load code',       action='store',      type='int',    dest='loadaddr')
parser.add_option('-m', '--memsize',   default=128,        help='size of address space (KB)',       action='store',      type='int',    dest='memsize')
parser.add_option('-M', '--memtrace',  default='',         help='comma-separated list of addrs to trace (e.g., 20000,20001)', action='store',
                  type='string', dest='memtrace')
parser.add_option('-R', '--regtrace',  default='',         help='comma-separated list of regs to trace (e.g., ax,bx,cx,dx)',  action='store',
                  type='string', dest='regtrace')
parser.add_option('-C', '--cctrace',   default=False,      help='should we trace condition codes',  action='store_true', dest='cctrace')
parser.add_option('-S', '--printstats',default=False,      help='print some extra stats',           action='store_true', dest='printstats')
parser.add_option('-v', '--verbose',   default=False,      help='print some extra info',            action='store_true', dest='verbose')
parser.add_option('-H', '--headercount',default=-1,        help='how often to print a row header',  action='store',      type='int',    dest='headercount')
parser.add_option('-c', '--compute',   default=False,      help='compute answers for me',           action='store_true', dest='solve')
(options, args) = parser.parse_args()

print 'ARG seed',                options.seed
print 'ARG numthreads',          options.numthreads
print 'ARG program',             options.progfile
print 'ARG interrupt frequency', options.intfreq
print 'ARG interrupt randomness',options.intrand
print 'ARG procsched',           options.procsched
print 'ARG argv',                options.argv
print 'ARG load address',        options.loadaddr
print 'ARG memsize',             options.memsize
print 'ARG memtrace',            options.memtrace
print 'ARG regtrace',            options.regtrace
print 'ARG cctrace',             options.cctrace
print 'ARG printstats',          options.printstats
print 'ARG verbose',             options.verbose
print ''

seed       = int(options.seed)
numthreads = int(options.numthreads)
intfreq    = int(options.intfreq)
zassert(intfreq > 0, 'Interrupt frequency must be greater than 0')
intrand    = int(options.intrand)
progfile   = options.progfile
zassert(progfile != '', 'Program file must be specified')
argv       = options.argv.split(',')
zassert(len(argv) == numthreads or len(argv) == 1, 'argv: must be one per-thread or just one set of values for all threads')
procsched  = options.procsched

loadaddr   = options.loadaddr
memsize    = options.memsize

memtrace   = []
if options.memtrace != '':
    for m in options.memtrace.split(','):
        memtrace.append(m)

regtrace   = []
if options.regtrace != '':
    for r in options.regtrace.split(','):
        regtrace.append(r)

cctrace    = options.cctrace

printstats = options.printstats
verbose    = options.verbose
hdrcount   = options.headercount
        
#
# MAIN program
#
debug = False
debug = False

cpu = cpu(memsize, memtrace, regtrace, cctrace, options.solve, verbose, printstats, hdrcount)

# load a program
cpu.load(progfile, loadaddr)

# process list
procs = proclist()
pid   = 0
stack = memsize * 1000
for t in range(numthreads):
    if len(argv) > 1:
        arg = argv[pid]
    else:
        arg = argv[0]
    procs.addproc(process(cpu, pid, loadaddr, stack, arg))
    stack -= 1000
    pid += 1

# get first process ready to run
procs.finalize(procsched)    

# run it
t1 = time.clock()
ic = cpu.run(procs, intfreq, intrand)
t2 = time.clock()

if printstats:
    print ''
    print 'STATS:: Instructions    %d' % ic
    print 'STATS:: Emulation Rate  %.2f kinst/sec' % (float(ic) / float(t2 - t1) / 1000.0)

# use this for profiling
# import cProfile
# cProfile.run('run()')




