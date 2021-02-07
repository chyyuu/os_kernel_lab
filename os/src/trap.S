.altmacro
.macro SAVE_GP n
    sd x\n, \n*8(sp)
.endm
.macro LOAD_GP n
    ld x\n, \n*8(sp)
.endm

    # Note: sstatus CSR -------------
    #       The SPP bit indicates the privilege level at which a hart was executing
    #       before entering supervisor mode. When a trap is taken, SPP is set to 0
    #       if the trap originated from user mode, or 1 otherwise. When an SRET
    #       instruction (see Section [otherpriv]) is executed to return from the
    #       trap handler, the privilege level is set to user mode if the SPP bit is 0,
    #       or supervisor mode if the SPP bit is 1; SPP is then set to 0.
    #
    #       The SIE bit enables or disables all interrupts in supervisor mode. When
    #       SIE is clear, interrupts are not taken while in supervisor mode. When the
    #       hart is running in user-mode, the value in SIE is ignored, and supervisor
    #       -level interrupts are enabled. The supervisor can disable individual interrupt
    #       sources using the sie CSR.
    #
    #       The SPIE bit indicates whether supervisor interrupts were enabled prior to
    #       trapping into supervisor mode. When a trap is taken into supervisor mode,
    #       SPIE is set to SIE, and SIE is set to 0. When an SRET instruction is executed,
    #       SIE is set to SPIE, then SPIE is set to 1.
    #
    #       sepc CSR -------------
    #       When a trap is taken into S-mode, sepc is written with the virtual address of
    #       the instruction that was interrupted or that encountered the exception. Otherwise,
    #       sepc is never written by the implementation, though it may be explicitly written by software.
    #
    #       stval CSR (Supervisor Trap Value) -------------
    #       When a hardware breakpoint is triggered, or an instruction, load, or store
    #       address-misaligned, access-fault, or page-fault exception occurs, stval is written
    #       with the faulting virtual address. On an illegal instruction trap, stval may be
    #       written with the first XLEN or ILEN bits of the faulting instruction as described
    #       below. For other exceptions, stval is set to zero, but a future standard may redefine
    #       stval’s setting for other exceptions.
    #       For misaligned loads and stores that cause access-fault or page-fault exceptions,
    #       stval will contain the virtual address of the portion of the access that caused the fault.
    #       For instruction access-fault or page-fault exceptions on systems with variable-length
    #       instructions, stval will contain the virtual address of the portion of the instruction that
    #       caused the fault while sepc will point to the beginning of the instruction.
    #
    #       scause CSR ----------------
    #       The Interrupt bit in the scause register is set if the trap was caused by an interrupt.
    #       The Exception Code field contains a code identifying the last exception or interrupt. T
    #       The Exception Code is a WLRL field. It is required to hold the values 0–31 (bits 4–0
    #       must be implemented), but otherwise it is only guaranteed to hold supported exception codes.
    #
    #       sip and sie CSR ---------------
    #       The sip register is an SXLEN-bit read/write register containing information on pending interrupts,
    #       while sie is the corresponding SXLEN-bit read/write register containing interrupt enable bits.
    #       Bits sip.SEIP/SEIE are the interrupt-pending/enable bits for supervisor-level external interrupts.
    #       Bits sip.STIP/STIE are the interrupt-pending/enable bits for supervisor-level timer interrupts.
    #       Bits sip.SSIP/SSIE are the interrupt-pending/enable bits for supervisor-level software interrupts.

    .section .text
    .globl __alltraps
    .globl __restore
    .align 2
    # The entry procedure for a interrupt I /exception E into supervisor mode
    # (Assuming mideleg[I] /medeleg[E] is set):
    # I: scause.interrupt = 1; scause.exception_code = I
    # E: scause.interrupt = 0; scause.exception_code = E
    # E: stval = faulting virtual address WHEN a hardware breakpoint is triggered,
    #            or an instruction, load, or store address-misaligned, access-fault,
    #            or page-fault exception occurs; other ZERO
    # sstatus.spie = 1, save previous interrupt enable. (See ISR stack.)
    # sstatus.sie = 0, interrupts are disabled unless the ISR re-writes this.
    # sstatus.spp = Previous privilege mode (S:1 or U:0). set privilege mode to S
    # sepc = Interrupted PC, save the return address.
    # IF stvec.mode == Direct THEN; PC = (stvec.Base & ~0xF) + (I/E * 4)

__alltraps:
    # case1: from  U to K sp ->user stack  , sscratch ->kernel stack
    # case2: from  K to K sp ->kernel stack, sscratch ->0
    csrrw sp, sscratch, sp
    bnez sp, __save_context     # if U to K, goto  __save_context
__restore_kernel_sp:            # if K to K, then
    csrr sp, sscratch           # sscratch = kernel stack
__save_context:
    # now sp->kernel stack, sscratch-> kernel stack (S-->S) OR user stack (U-->S) 
    # allocate a TrapContext on kernel stack
    addi sp, sp, -34*8
    # save general-purpose registers
    sd x1, 1*8(sp)
    # skip sp(x2), we will save it later
    sd x3, 3*8(sp)
    # skip tp(x4), application does not use it
    # save x5~x31
    .set n, 5
    .rept 27
        SAVE_GP %n
        .set n, n+1
    .endr
    # we can use t0/t1/t2 freely, because they were saved on kernel stack
    csrr t0, sstatus
    sd t0, 32*8(sp)
    csrr t1, sepc
    sd t1, 33*8(sp)
    # now TrapContext.sstatus ->sstatus CSR, TrapContext.sepc ->sepc CSR

    # Set sscratch to 0, so that if a recursive
    # exception occurs, we know it came from the kernel
    # read kernel stack OR user stack from sscratch and save it on the kernel stack
    csrrw t2, sscratch, x0
    # now sscratch=0
    sd t2, 2*8(sp)          # store kernel stack (S-->S) OR user stack (U-->S) on trapcontext
    # now TrapContext was filled (34*8 bytes)
    # set input argument of trap_handler(cx: &mut TrapContext)
    mv a0, sp
    call trap_handler

__restore:
    # case1: back to S after handling trap
    # case2: back to U after handling trap
    # case3: start running app by __restore
    mv sp, a0
    # now sp->kernel stack(after allocated), sscratch=0
    # restore sstatus/sepc
    ld t0, 32*8(sp)  # t0=sstatus
    ld t1, 33*8(sp)
    csrw sstatus, t0            # restore sstatus
    csrw sepc, t1               # restore sepc

    andi t1, t0, 256            # SSTATUS_SPP bit=2^8=256
    bnez t1, __restore_context  # SPP==1 means previous mode is S mode, sscratch should be 0
__save_kernel_sp:               # SPP==0, means previous mode is U mode
    addi t1, sp, 34 * 8         # get kernel stack
    csrw sscratch, t1           # sscratch should be kernel stack
__restore_context:

    # sscratch =kernel stack(for previous mode is U mode) or 0 (for previous mode is S mode)
    # restore general-purpuse registers except sp/tp
    ld x1, 1*8(sp)
    ld x3, 3*8(sp)
    .set n, 5
    .rept 27
        LOAD_GP %n
        .set n, n+1
    .endr
    ld x2, 2*8(sp)     # restore sp
    # The exit procedure for a supervisor interrupt/exception when sret is executed.
    # sstatus.sie = sstatus.spie, restore interrupt enable
    # Privilege mode = sstatus.spp, restore privilege
    # sstatus.spp = sstatus.spie = 0
    # PC = sepc
    sret


