;
; Copyright (c) 2010, Stefan Lankes, RWTH Aachen University
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;    * Redistributions of source code must retain the above copyright
;      notice, this list of conditions and the following disclaimer.
;    * Redistributions in binary form must reproduce the above copyright
;      notice, this list of conditions and the following disclaimer in the
;      documentation and/or other materials provided with the distribution.
;    * Neither the name of the University nor the names of its contributors
;      may be used to endorse or promote products derived from this software
;      without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[BITS 32]
; We use a special name to map this section at the begin of our kernel
; =>  Multiboot needs its magic number at the begin of the kernel
SECTION .mboot
global start
start:
    jmp stublet

; This part MUST be 4byte aligned, so we solve that issue using 'ALIGN 4'
ALIGN 4
mboot:
    ; Multiboot macros to make a few lines more readable later
    MULTIBOOT_PAGE_ALIGN	equ 1<<0
    MULTIBOOT_MEMORY_INFO	equ 1<<1
    MULTIBOOT_HEADER_MAGIC	equ 0x1BADB002
    MULTIBOOT_HEADER_FLAGS	equ MULTIBOOT_PAGE_ALIGN | MULTIBOOT_MEMORY_INFO
    MULTIBOOT_CHECKSUM		equ -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)

    ; This is the GRUB Multiboot header. A boot signature
    dd MULTIBOOT_HEADER_MAGIC
    dd MULTIBOOT_HEADER_FLAGS
    dd MULTIBOOT_CHECKSUM
    dd 0, 0, 0, 0, 0 ; address fields

SECTION .text
ALIGN 4
stublet:
; initialize stack pointer.
    mov esp, default_stack_pointer
; initialize cpu features
    call cpu_init
; interpret multiboot information
    extern multiboot_init
    push ebx
    call multiboot_init
    add esp, 4

; jump to the boot processors's C code
    extern kern_init 
    call kern_init
    jmp $

global cpu_init
cpu_init:
    mov eax, cr0
; enable caching, disable paging and fpu emulation
    and eax, 0x1ffffffb
; ...and turn on FPU exceptions
    or eax, 0x22
    mov cr0, eax
; clears the current pgd entry
    xor eax, eax
    mov cr3, eax
; at this stage, we disable the SSE support
    mov eax, cr4
    and eax, 0xfffbf9ff
    mov cr4, eax
    ret

; Here is the definition of our stack. Remember that a stack actually grows
; downwards, so we declare the size of the data before declaring
; the identifier 'default_stack_pointer'
SECTION .data
    resb 8192               ; This reserves 8KBytes of memory here
default_stack_pointer:

SECTION .note.GNU-stack noalloc noexec nowrite progbits
