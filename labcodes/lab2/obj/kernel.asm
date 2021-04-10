
bin/kernel:     file format elf32-i386


Disassembly of section .text:

c0100000 <kern_entry>:

.text
.globl kern_entry
kern_entry:
    # load pa of boot pgdir
    movl $REALLOC(__boot_pgdir), %eax
c0100000:	b8 00 80 11 00       	mov    $0x118000,%eax
    movl %eax, %cr3
c0100005:	0f 22 d8             	mov    %eax,%cr3

    # enable paging
    movl %cr0, %eax
c0100008:	0f 20 c0             	mov    %cr0,%eax
    orl $(CR0_PE | CR0_PG | CR0_AM | CR0_WP | CR0_NE | CR0_TS | CR0_EM | CR0_MP), %eax
c010000b:	0d 2f 00 05 80       	or     $0x8005002f,%eax
    andl $~(CR0_TS | CR0_EM), %eax
c0100010:	83 e0 f3             	and    $0xfffffff3,%eax
    movl %eax, %cr0
c0100013:	0f 22 c0             	mov    %eax,%cr0

    # update eip
    # now, eip = 0x1.....
    leal next, %eax
c0100016:	8d 05 1e 00 10 c0    	lea    0xc010001e,%eax
    # set eip = KERNBASE + 0x1.....
    jmp *%eax
c010001c:	ff e0                	jmp    *%eax

c010001e <next>:
next:

    # unmap va 0 ~ 4M, it's temporary mapping
    xorl %eax, %eax
c010001e:	31 c0                	xor    %eax,%eax
    movl %eax, __boot_pgdir
c0100020:	a3 00 80 11 c0       	mov    %eax,0xc0118000

    # set ebp, esp
    movl $0x0, %ebp
c0100025:	bd 00 00 00 00       	mov    $0x0,%ebp
    # the kernel stack region is from bootstack -- bootstacktop,
    # the kernel stack size is KSTACKSIZE (8KB)defined in memlayout.h
    movl $bootstacktop, %esp
c010002a:	bc 00 70 11 c0       	mov    $0xc0117000,%esp
    # now kernel stack is ready , call the first C function
    call kern_init
c010002f:	e8 02 00 00 00       	call   c0100036 <kern_init>

c0100034 <spin>:

# should never get here
spin:
    jmp spin
c0100034:	eb fe                	jmp    c0100034 <spin>

c0100036 <kern_init>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);
static void lab1_switch_test(void);

int
kern_init(void) {
c0100036:	55                   	push   %ebp
c0100037:	89 e5                	mov    %esp,%ebp
c0100039:	83 ec 28             	sub    $0x28,%esp
    extern char edata[], end[];
    memset(edata, 0, end - edata);
c010003c:	ba 28 af 11 c0       	mov    $0xc011af28,%edx
c0100041:	b8 00 a0 11 c0       	mov    $0xc011a000,%eax
c0100046:	29 c2                	sub    %eax,%edx
c0100048:	89 d0                	mov    %edx,%eax
c010004a:	89 44 24 08          	mov    %eax,0x8(%esp)
c010004e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0100055:	00 
c0100056:	c7 04 24 00 a0 11 c0 	movl   $0xc011a000,(%esp)
c010005d:	e8 41 54 00 00       	call   c01054a3 <memset>

    cons_init();                // init the console
c0100062:	e8 be 14 00 00       	call   c0101525 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
c0100067:	c7 45 f4 a0 5c 10 c0 	movl   $0xc0105ca0,-0xc(%ebp)
    cprintf("%s\n\n", message);
c010006e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100071:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100075:	c7 04 24 bc 5c 10 c0 	movl   $0xc0105cbc,(%esp)
c010007c:	e8 11 02 00 00       	call   c0100292 <cprintf>

    print_kerninfo();
c0100081:	e8 b2 08 00 00       	call   c0100938 <print_kerninfo>

    grade_backtrace();
c0100086:	e8 89 00 00 00       	call   c0100114 <grade_backtrace>

    pmm_init();                 // init physical memory management
c010008b:	e8 86 2e 00 00       	call   c0102f16 <pmm_init>

    pic_init();                 // init interrupt controller
c0100090:	e8 f4 15 00 00       	call   c0101689 <pic_init>
    idt_init();                 // init interrupt descriptor table
c0100095:	e8 4d 17 00 00       	call   c01017e7 <idt_init>

    clock_init();               // init clock interrupt
c010009a:	e8 39 0c 00 00       	call   c0100cd8 <clock_init>
    intr_enable();              // enable irq interrupt
c010009f:	e8 18 17 00 00       	call   c01017bc <intr_enable>
    //LAB1: CAHLLENGE 1 If you try to do it, uncomment lab1_switch_test()
    // user/kernel mode switch test
    //lab1_switch_test();

    /* do nothing */
    while (1);
c01000a4:	eb fe                	jmp    c01000a4 <kern_init+0x6e>

c01000a6 <grade_backtrace2>:
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
c01000a6:	55                   	push   %ebp
c01000a7:	89 e5                	mov    %esp,%ebp
c01000a9:	83 ec 18             	sub    $0x18,%esp
    mon_backtrace(0, NULL, NULL);
c01000ac:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01000b3:	00 
c01000b4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c01000bb:	00 
c01000bc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c01000c3:	e8 fe 0b 00 00       	call   c0100cc6 <mon_backtrace>
}
c01000c8:	90                   	nop
c01000c9:	c9                   	leave  
c01000ca:	c3                   	ret    

c01000cb <grade_backtrace1>:

void __attribute__((noinline))
grade_backtrace1(int arg0, int arg1) {
c01000cb:	55                   	push   %ebp
c01000cc:	89 e5                	mov    %esp,%ebp
c01000ce:	53                   	push   %ebx
c01000cf:	83 ec 14             	sub    $0x14,%esp
    grade_backtrace2(arg0, (int)&arg0, arg1, (int)&arg1);
c01000d2:	8d 4d 0c             	lea    0xc(%ebp),%ecx
c01000d5:	8b 55 0c             	mov    0xc(%ebp),%edx
c01000d8:	8d 5d 08             	lea    0x8(%ebp),%ebx
c01000db:	8b 45 08             	mov    0x8(%ebp),%eax
c01000de:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
c01000e2:	89 54 24 08          	mov    %edx,0x8(%esp)
c01000e6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
c01000ea:	89 04 24             	mov    %eax,(%esp)
c01000ed:	e8 b4 ff ff ff       	call   c01000a6 <grade_backtrace2>
}
c01000f2:	90                   	nop
c01000f3:	83 c4 14             	add    $0x14,%esp
c01000f6:	5b                   	pop    %ebx
c01000f7:	5d                   	pop    %ebp
c01000f8:	c3                   	ret    

c01000f9 <grade_backtrace0>:

void __attribute__((noinline))
grade_backtrace0(int arg0, int arg1, int arg2) {
c01000f9:	55                   	push   %ebp
c01000fa:	89 e5                	mov    %esp,%ebp
c01000fc:	83 ec 18             	sub    $0x18,%esp
    grade_backtrace1(arg0, arg2);
c01000ff:	8b 45 10             	mov    0x10(%ebp),%eax
c0100102:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100106:	8b 45 08             	mov    0x8(%ebp),%eax
c0100109:	89 04 24             	mov    %eax,(%esp)
c010010c:	e8 ba ff ff ff       	call   c01000cb <grade_backtrace1>
}
c0100111:	90                   	nop
c0100112:	c9                   	leave  
c0100113:	c3                   	ret    

c0100114 <grade_backtrace>:

void
grade_backtrace(void) {
c0100114:	55                   	push   %ebp
c0100115:	89 e5                	mov    %esp,%ebp
c0100117:	83 ec 18             	sub    $0x18,%esp
    grade_backtrace0(0, (int)kern_init, 0xffff0000);
c010011a:	b8 36 00 10 c0       	mov    $0xc0100036,%eax
c010011f:	c7 44 24 08 00 00 ff 	movl   $0xffff0000,0x8(%esp)
c0100126:	ff 
c0100127:	89 44 24 04          	mov    %eax,0x4(%esp)
c010012b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c0100132:	e8 c2 ff ff ff       	call   c01000f9 <grade_backtrace0>
}
c0100137:	90                   	nop
c0100138:	c9                   	leave  
c0100139:	c3                   	ret    

c010013a <lab1_print_cur_status>:

static void
lab1_print_cur_status(void) {
c010013a:	55                   	push   %ebp
c010013b:	89 e5                	mov    %esp,%ebp
c010013d:	83 ec 28             	sub    $0x28,%esp
    static int round = 0;
    uint16_t reg1, reg2, reg3, reg4;
    asm volatile (
c0100140:	8c 4d f6             	mov    %cs,-0xa(%ebp)
c0100143:	8c 5d f4             	mov    %ds,-0xc(%ebp)
c0100146:	8c 45 f2             	mov    %es,-0xe(%ebp)
c0100149:	8c 55 f0             	mov    %ss,-0x10(%ebp)
            "mov %%cs, %0;"
            "mov %%ds, %1;"
            "mov %%es, %2;"
            "mov %%ss, %3;"
            : "=m"(reg1), "=m"(reg2), "=m"(reg3), "=m"(reg4));
    cprintf("%d: @ring %d\n", round, reg1 & 3);
c010014c:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100150:	83 e0 03             	and    $0x3,%eax
c0100153:	89 c2                	mov    %eax,%edx
c0100155:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c010015a:	89 54 24 08          	mov    %edx,0x8(%esp)
c010015e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100162:	c7 04 24 c1 5c 10 c0 	movl   $0xc0105cc1,(%esp)
c0100169:	e8 24 01 00 00       	call   c0100292 <cprintf>
    cprintf("%d:  cs = %x\n", round, reg1);
c010016e:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100172:	89 c2                	mov    %eax,%edx
c0100174:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c0100179:	89 54 24 08          	mov    %edx,0x8(%esp)
c010017d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100181:	c7 04 24 cf 5c 10 c0 	movl   $0xc0105ccf,(%esp)
c0100188:	e8 05 01 00 00       	call   c0100292 <cprintf>
    cprintf("%d:  ds = %x\n", round, reg2);
c010018d:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
c0100191:	89 c2                	mov    %eax,%edx
c0100193:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c0100198:	89 54 24 08          	mov    %edx,0x8(%esp)
c010019c:	89 44 24 04          	mov    %eax,0x4(%esp)
c01001a0:	c7 04 24 dd 5c 10 c0 	movl   $0xc0105cdd,(%esp)
c01001a7:	e8 e6 00 00 00       	call   c0100292 <cprintf>
    cprintf("%d:  es = %x\n", round, reg3);
c01001ac:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c01001b0:	89 c2                	mov    %eax,%edx
c01001b2:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c01001b7:	89 54 24 08          	mov    %edx,0x8(%esp)
c01001bb:	89 44 24 04          	mov    %eax,0x4(%esp)
c01001bf:	c7 04 24 eb 5c 10 c0 	movl   $0xc0105ceb,(%esp)
c01001c6:	e8 c7 00 00 00       	call   c0100292 <cprintf>
    cprintf("%d:  ss = %x\n", round, reg4);
c01001cb:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
c01001cf:	89 c2                	mov    %eax,%edx
c01001d1:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c01001d6:	89 54 24 08          	mov    %edx,0x8(%esp)
c01001da:	89 44 24 04          	mov    %eax,0x4(%esp)
c01001de:	c7 04 24 f9 5c 10 c0 	movl   $0xc0105cf9,(%esp)
c01001e5:	e8 a8 00 00 00       	call   c0100292 <cprintf>
    round ++;
c01001ea:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c01001ef:	40                   	inc    %eax
c01001f0:	a3 00 a0 11 c0       	mov    %eax,0xc011a000
}
c01001f5:	90                   	nop
c01001f6:	c9                   	leave  
c01001f7:	c3                   	ret    

c01001f8 <lab1_switch_to_user>:

static void
lab1_switch_to_user(void) {
c01001f8:	55                   	push   %ebp
c01001f9:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 : TODO
}
c01001fb:	90                   	nop
c01001fc:	5d                   	pop    %ebp
c01001fd:	c3                   	ret    

c01001fe <lab1_switch_to_kernel>:

static void
lab1_switch_to_kernel(void) {
c01001fe:	55                   	push   %ebp
c01001ff:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 :  TODO
}
c0100201:	90                   	nop
c0100202:	5d                   	pop    %ebp
c0100203:	c3                   	ret    

c0100204 <lab1_switch_test>:

static void
lab1_switch_test(void) {
c0100204:	55                   	push   %ebp
c0100205:	89 e5                	mov    %esp,%ebp
c0100207:	83 ec 18             	sub    $0x18,%esp
    lab1_print_cur_status();
c010020a:	e8 2b ff ff ff       	call   c010013a <lab1_print_cur_status>
    cprintf("+++ switch to  user  mode +++\n");
c010020f:	c7 04 24 08 5d 10 c0 	movl   $0xc0105d08,(%esp)
c0100216:	e8 77 00 00 00       	call   c0100292 <cprintf>
    lab1_switch_to_user();
c010021b:	e8 d8 ff ff ff       	call   c01001f8 <lab1_switch_to_user>
    lab1_print_cur_status();
c0100220:	e8 15 ff ff ff       	call   c010013a <lab1_print_cur_status>
    cprintf("+++ switch to kernel mode +++\n");
c0100225:	c7 04 24 28 5d 10 c0 	movl   $0xc0105d28,(%esp)
c010022c:	e8 61 00 00 00       	call   c0100292 <cprintf>
    lab1_switch_to_kernel();
c0100231:	e8 c8 ff ff ff       	call   c01001fe <lab1_switch_to_kernel>
    lab1_print_cur_status();
c0100236:	e8 ff fe ff ff       	call   c010013a <lab1_print_cur_status>
}
c010023b:	90                   	nop
c010023c:	c9                   	leave  
c010023d:	c3                   	ret    

c010023e <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
c010023e:	55                   	push   %ebp
c010023f:	89 e5                	mov    %esp,%ebp
c0100241:	83 ec 18             	sub    $0x18,%esp
    cons_putc(c);
c0100244:	8b 45 08             	mov    0x8(%ebp),%eax
c0100247:	89 04 24             	mov    %eax,(%esp)
c010024a:	e8 03 13 00 00       	call   c0101552 <cons_putc>
    (*cnt) ++;
c010024f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100252:	8b 00                	mov    (%eax),%eax
c0100254:	8d 50 01             	lea    0x1(%eax),%edx
c0100257:	8b 45 0c             	mov    0xc(%ebp),%eax
c010025a:	89 10                	mov    %edx,(%eax)
}
c010025c:	90                   	nop
c010025d:	c9                   	leave  
c010025e:	c3                   	ret    

c010025f <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
c010025f:	55                   	push   %ebp
c0100260:	89 e5                	mov    %esp,%ebp
c0100262:	83 ec 28             	sub    $0x28,%esp
    int cnt = 0;
c0100265:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
c010026c:	8b 45 0c             	mov    0xc(%ebp),%eax
c010026f:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0100273:	8b 45 08             	mov    0x8(%ebp),%eax
c0100276:	89 44 24 08          	mov    %eax,0x8(%esp)
c010027a:	8d 45 f4             	lea    -0xc(%ebp),%eax
c010027d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100281:	c7 04 24 3e 02 10 c0 	movl   $0xc010023e,(%esp)
c0100288:	e8 69 55 00 00       	call   c01057f6 <vprintfmt>
    return cnt;
c010028d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0100290:	c9                   	leave  
c0100291:	c3                   	ret    

c0100292 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
c0100292:	55                   	push   %ebp
c0100293:	89 e5                	mov    %esp,%ebp
c0100295:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
c0100298:	8d 45 0c             	lea    0xc(%ebp),%eax
c010029b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vcprintf(fmt, ap);
c010029e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01002a1:	89 44 24 04          	mov    %eax,0x4(%esp)
c01002a5:	8b 45 08             	mov    0x8(%ebp),%eax
c01002a8:	89 04 24             	mov    %eax,(%esp)
c01002ab:	e8 af ff ff ff       	call   c010025f <vcprintf>
c01002b0:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
c01002b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01002b6:	c9                   	leave  
c01002b7:	c3                   	ret    

c01002b8 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
c01002b8:	55                   	push   %ebp
c01002b9:	89 e5                	mov    %esp,%ebp
c01002bb:	83 ec 18             	sub    $0x18,%esp
    cons_putc(c);
c01002be:	8b 45 08             	mov    0x8(%ebp),%eax
c01002c1:	89 04 24             	mov    %eax,(%esp)
c01002c4:	e8 89 12 00 00       	call   c0101552 <cons_putc>
}
c01002c9:	90                   	nop
c01002ca:	c9                   	leave  
c01002cb:	c3                   	ret    

c01002cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
c01002cc:	55                   	push   %ebp
c01002cd:	89 e5                	mov    %esp,%ebp
c01002cf:	83 ec 28             	sub    $0x28,%esp
    int cnt = 0;
c01002d2:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    char c;
    while ((c = *str ++) != '\0') {
c01002d9:	eb 13                	jmp    c01002ee <cputs+0x22>
        cputch(c, &cnt);
c01002db:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c01002df:	8d 55 f0             	lea    -0x10(%ebp),%edx
c01002e2:	89 54 24 04          	mov    %edx,0x4(%esp)
c01002e6:	89 04 24             	mov    %eax,(%esp)
c01002e9:	e8 50 ff ff ff       	call   c010023e <cputch>
 * */
int
cputs(const char *str) {
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
c01002ee:	8b 45 08             	mov    0x8(%ebp),%eax
c01002f1:	8d 50 01             	lea    0x1(%eax),%edx
c01002f4:	89 55 08             	mov    %edx,0x8(%ebp)
c01002f7:	0f b6 00             	movzbl (%eax),%eax
c01002fa:	88 45 f7             	mov    %al,-0x9(%ebp)
c01002fd:	80 7d f7 00          	cmpb   $0x0,-0x9(%ebp)
c0100301:	75 d8                	jne    c01002db <cputs+0xf>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
c0100303:	8d 45 f0             	lea    -0x10(%ebp),%eax
c0100306:	89 44 24 04          	mov    %eax,0x4(%esp)
c010030a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
c0100311:	e8 28 ff ff ff       	call   c010023e <cputch>
    return cnt;
c0100316:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
c0100319:	c9                   	leave  
c010031a:	c3                   	ret    

c010031b <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
c010031b:	55                   	push   %ebp
c010031c:	89 e5                	mov    %esp,%ebp
c010031e:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = cons_getc()) == 0)
c0100321:	e8 69 12 00 00       	call   c010158f <cons_getc>
c0100326:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0100329:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c010032d:	74 f2                	je     c0100321 <getchar+0x6>
        /* do nothing */;
    return c;
c010032f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0100332:	c9                   	leave  
c0100333:	c3                   	ret    

c0100334 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
c0100334:	55                   	push   %ebp
c0100335:	89 e5                	mov    %esp,%ebp
c0100337:	83 ec 28             	sub    $0x28,%esp
    if (prompt != NULL) {
c010033a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c010033e:	74 13                	je     c0100353 <readline+0x1f>
        cprintf("%s", prompt);
c0100340:	8b 45 08             	mov    0x8(%ebp),%eax
c0100343:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100347:	c7 04 24 47 5d 10 c0 	movl   $0xc0105d47,(%esp)
c010034e:	e8 3f ff ff ff       	call   c0100292 <cprintf>
    }
    int i = 0, c;
c0100353:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        c = getchar();
c010035a:	e8 bc ff ff ff       	call   c010031b <getchar>
c010035f:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (c < 0) {
c0100362:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0100366:	79 07                	jns    c010036f <readline+0x3b>
            return NULL;
c0100368:	b8 00 00 00 00       	mov    $0x0,%eax
c010036d:	eb 78                	jmp    c01003e7 <readline+0xb3>
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
c010036f:	83 7d f0 1f          	cmpl   $0x1f,-0x10(%ebp)
c0100373:	7e 28                	jle    c010039d <readline+0x69>
c0100375:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
c010037c:	7f 1f                	jg     c010039d <readline+0x69>
            cputchar(c);
c010037e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100381:	89 04 24             	mov    %eax,(%esp)
c0100384:	e8 2f ff ff ff       	call   c01002b8 <cputchar>
            buf[i ++] = c;
c0100389:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010038c:	8d 50 01             	lea    0x1(%eax),%edx
c010038f:	89 55 f4             	mov    %edx,-0xc(%ebp)
c0100392:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100395:	88 90 20 a0 11 c0    	mov    %dl,-0x3fee5fe0(%eax)
c010039b:	eb 45                	jmp    c01003e2 <readline+0xae>
        }
        else if (c == '\b' && i > 0) {
c010039d:	83 7d f0 08          	cmpl   $0x8,-0x10(%ebp)
c01003a1:	75 16                	jne    c01003b9 <readline+0x85>
c01003a3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01003a7:	7e 10                	jle    c01003b9 <readline+0x85>
            cputchar(c);
c01003a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01003ac:	89 04 24             	mov    %eax,(%esp)
c01003af:	e8 04 ff ff ff       	call   c01002b8 <cputchar>
            i --;
c01003b4:	ff 4d f4             	decl   -0xc(%ebp)
c01003b7:	eb 29                	jmp    c01003e2 <readline+0xae>
        }
        else if (c == '\n' || c == '\r') {
c01003b9:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
c01003bd:	74 06                	je     c01003c5 <readline+0x91>
c01003bf:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
c01003c3:	75 95                	jne    c010035a <readline+0x26>
            cputchar(c);
c01003c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01003c8:	89 04 24             	mov    %eax,(%esp)
c01003cb:	e8 e8 fe ff ff       	call   c01002b8 <cputchar>
            buf[i] = '\0';
c01003d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01003d3:	05 20 a0 11 c0       	add    $0xc011a020,%eax
c01003d8:	c6 00 00             	movb   $0x0,(%eax)
            return buf;
c01003db:	b8 20 a0 11 c0       	mov    $0xc011a020,%eax
c01003e0:	eb 05                	jmp    c01003e7 <readline+0xb3>
        }
    }
c01003e2:	e9 73 ff ff ff       	jmp    c010035a <readline+0x26>
}
c01003e7:	c9                   	leave  
c01003e8:	c3                   	ret    

c01003e9 <__panic>:
/* *
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
c01003e9:	55                   	push   %ebp
c01003ea:	89 e5                	mov    %esp,%ebp
c01003ec:	83 ec 28             	sub    $0x28,%esp
    if (is_panic) {
c01003ef:	a1 20 a4 11 c0       	mov    0xc011a420,%eax
c01003f4:	85 c0                	test   %eax,%eax
c01003f6:	75 5b                	jne    c0100453 <__panic+0x6a>
        goto panic_dead;
    }
    is_panic = 1;
c01003f8:	c7 05 20 a4 11 c0 01 	movl   $0x1,0xc011a420
c01003ff:	00 00 00 

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
c0100402:	8d 45 14             	lea    0x14(%ebp),%eax
c0100405:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
c0100408:	8b 45 0c             	mov    0xc(%ebp),%eax
c010040b:	89 44 24 08          	mov    %eax,0x8(%esp)
c010040f:	8b 45 08             	mov    0x8(%ebp),%eax
c0100412:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100416:	c7 04 24 4a 5d 10 c0 	movl   $0xc0105d4a,(%esp)
c010041d:	e8 70 fe ff ff       	call   c0100292 <cprintf>
    vcprintf(fmt, ap);
c0100422:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100425:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100429:	8b 45 10             	mov    0x10(%ebp),%eax
c010042c:	89 04 24             	mov    %eax,(%esp)
c010042f:	e8 2b fe ff ff       	call   c010025f <vcprintf>
    cprintf("\n");
c0100434:	c7 04 24 66 5d 10 c0 	movl   $0xc0105d66,(%esp)
c010043b:	e8 52 fe ff ff       	call   c0100292 <cprintf>
    
    cprintf("stack trackback:\n");
c0100440:	c7 04 24 68 5d 10 c0 	movl   $0xc0105d68,(%esp)
c0100447:	e8 46 fe ff ff       	call   c0100292 <cprintf>
    print_stackframe();
c010044c:	e8 32 06 00 00       	call   c0100a83 <print_stackframe>
c0100451:	eb 01                	jmp    c0100454 <__panic+0x6b>
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
        goto panic_dead;
c0100453:	90                   	nop
    print_stackframe();
    
    va_end(ap);

panic_dead:
    intr_disable();
c0100454:	e8 6a 13 00 00       	call   c01017c3 <intr_disable>
    while (1) {
        kmonitor(NULL);
c0100459:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c0100460:	e8 94 07 00 00       	call   c0100bf9 <kmonitor>
    }
c0100465:	eb f2                	jmp    c0100459 <__panic+0x70>

c0100467 <__warn>:
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
c0100467:	55                   	push   %ebp
c0100468:	89 e5                	mov    %esp,%ebp
c010046a:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    va_start(ap, fmt);
c010046d:	8d 45 14             	lea    0x14(%ebp),%eax
c0100470:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
c0100473:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100476:	89 44 24 08          	mov    %eax,0x8(%esp)
c010047a:	8b 45 08             	mov    0x8(%ebp),%eax
c010047d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100481:	c7 04 24 7a 5d 10 c0 	movl   $0xc0105d7a,(%esp)
c0100488:	e8 05 fe ff ff       	call   c0100292 <cprintf>
    vcprintf(fmt, ap);
c010048d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100490:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100494:	8b 45 10             	mov    0x10(%ebp),%eax
c0100497:	89 04 24             	mov    %eax,(%esp)
c010049a:	e8 c0 fd ff ff       	call   c010025f <vcprintf>
    cprintf("\n");
c010049f:	c7 04 24 66 5d 10 c0 	movl   $0xc0105d66,(%esp)
c01004a6:	e8 e7 fd ff ff       	call   c0100292 <cprintf>
    va_end(ap);
}
c01004ab:	90                   	nop
c01004ac:	c9                   	leave  
c01004ad:	c3                   	ret    

c01004ae <is_kernel_panic>:

bool
is_kernel_panic(void) {
c01004ae:	55                   	push   %ebp
c01004af:	89 e5                	mov    %esp,%ebp
    return is_panic;
c01004b1:	a1 20 a4 11 c0       	mov    0xc011a420,%eax
}
c01004b6:	5d                   	pop    %ebp
c01004b7:	c3                   	ret    

c01004b8 <stab_binsearch>:
 *      stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
 * will exit setting left = 118, right = 554.
 * */
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
c01004b8:	55                   	push   %ebp
c01004b9:	89 e5                	mov    %esp,%ebp
c01004bb:	83 ec 20             	sub    $0x20,%esp
    int l = *region_left, r = *region_right, any_matches = 0;
c01004be:	8b 45 0c             	mov    0xc(%ebp),%eax
c01004c1:	8b 00                	mov    (%eax),%eax
c01004c3:	89 45 fc             	mov    %eax,-0x4(%ebp)
c01004c6:	8b 45 10             	mov    0x10(%ebp),%eax
c01004c9:	8b 00                	mov    (%eax),%eax
c01004cb:	89 45 f8             	mov    %eax,-0x8(%ebp)
c01004ce:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

    while (l <= r) {
c01004d5:	e9 ca 00 00 00       	jmp    c01005a4 <stab_binsearch+0xec>
        int true_m = (l + r) / 2, m = true_m;
c01004da:	8b 55 fc             	mov    -0x4(%ebp),%edx
c01004dd:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01004e0:	01 d0                	add    %edx,%eax
c01004e2:	89 c2                	mov    %eax,%edx
c01004e4:	c1 ea 1f             	shr    $0x1f,%edx
c01004e7:	01 d0                	add    %edx,%eax
c01004e9:	d1 f8                	sar    %eax
c01004eb:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01004ee:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01004f1:	89 45 f0             	mov    %eax,-0x10(%ebp)

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
c01004f4:	eb 03                	jmp    c01004f9 <stab_binsearch+0x41>
            m --;
c01004f6:	ff 4d f0             	decl   -0x10(%ebp)

    while (l <= r) {
        int true_m = (l + r) / 2, m = true_m;

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
c01004f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01004fc:	3b 45 fc             	cmp    -0x4(%ebp),%eax
c01004ff:	7c 1f                	jl     c0100520 <stab_binsearch+0x68>
c0100501:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100504:	89 d0                	mov    %edx,%eax
c0100506:	01 c0                	add    %eax,%eax
c0100508:	01 d0                	add    %edx,%eax
c010050a:	c1 e0 02             	shl    $0x2,%eax
c010050d:	89 c2                	mov    %eax,%edx
c010050f:	8b 45 08             	mov    0x8(%ebp),%eax
c0100512:	01 d0                	add    %edx,%eax
c0100514:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c0100518:	0f b6 c0             	movzbl %al,%eax
c010051b:	3b 45 14             	cmp    0x14(%ebp),%eax
c010051e:	75 d6                	jne    c01004f6 <stab_binsearch+0x3e>
            m --;
        }
        if (m < l) {    // no match in [l, m]
c0100520:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100523:	3b 45 fc             	cmp    -0x4(%ebp),%eax
c0100526:	7d 09                	jge    c0100531 <stab_binsearch+0x79>
            l = true_m + 1;
c0100528:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010052b:	40                   	inc    %eax
c010052c:	89 45 fc             	mov    %eax,-0x4(%ebp)
            continue;
c010052f:	eb 73                	jmp    c01005a4 <stab_binsearch+0xec>
        }

        // actual binary search
        any_matches = 1;
c0100531:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
        if (stabs[m].n_value < addr) {
c0100538:	8b 55 f0             	mov    -0x10(%ebp),%edx
c010053b:	89 d0                	mov    %edx,%eax
c010053d:	01 c0                	add    %eax,%eax
c010053f:	01 d0                	add    %edx,%eax
c0100541:	c1 e0 02             	shl    $0x2,%eax
c0100544:	89 c2                	mov    %eax,%edx
c0100546:	8b 45 08             	mov    0x8(%ebp),%eax
c0100549:	01 d0                	add    %edx,%eax
c010054b:	8b 40 08             	mov    0x8(%eax),%eax
c010054e:	3b 45 18             	cmp    0x18(%ebp),%eax
c0100551:	73 11                	jae    c0100564 <stab_binsearch+0xac>
            *region_left = m;
c0100553:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100556:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100559:	89 10                	mov    %edx,(%eax)
            l = true_m + 1;
c010055b:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010055e:	40                   	inc    %eax
c010055f:	89 45 fc             	mov    %eax,-0x4(%ebp)
c0100562:	eb 40                	jmp    c01005a4 <stab_binsearch+0xec>
        } else if (stabs[m].n_value > addr) {
c0100564:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100567:	89 d0                	mov    %edx,%eax
c0100569:	01 c0                	add    %eax,%eax
c010056b:	01 d0                	add    %edx,%eax
c010056d:	c1 e0 02             	shl    $0x2,%eax
c0100570:	89 c2                	mov    %eax,%edx
c0100572:	8b 45 08             	mov    0x8(%ebp),%eax
c0100575:	01 d0                	add    %edx,%eax
c0100577:	8b 40 08             	mov    0x8(%eax),%eax
c010057a:	3b 45 18             	cmp    0x18(%ebp),%eax
c010057d:	76 14                	jbe    c0100593 <stab_binsearch+0xdb>
            *region_right = m - 1;
c010057f:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100582:	8d 50 ff             	lea    -0x1(%eax),%edx
c0100585:	8b 45 10             	mov    0x10(%ebp),%eax
c0100588:	89 10                	mov    %edx,(%eax)
            r = m - 1;
c010058a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010058d:	48                   	dec    %eax
c010058e:	89 45 f8             	mov    %eax,-0x8(%ebp)
c0100591:	eb 11                	jmp    c01005a4 <stab_binsearch+0xec>
        } else {
            // exact match for 'addr', but continue loop to find
            // *region_right
            *region_left = m;
c0100593:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100596:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100599:	89 10                	mov    %edx,(%eax)
            l = m;
c010059b:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010059e:	89 45 fc             	mov    %eax,-0x4(%ebp)
            addr ++;
c01005a1:	ff 45 18             	incl   0x18(%ebp)
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
    int l = *region_left, r = *region_right, any_matches = 0;

    while (l <= r) {
c01005a4:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01005a7:	3b 45 f8             	cmp    -0x8(%ebp),%eax
c01005aa:	0f 8e 2a ff ff ff    	jle    c01004da <stab_binsearch+0x22>
            l = m;
            addr ++;
        }
    }

    if (!any_matches) {
c01005b0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01005b4:	75 0f                	jne    c01005c5 <stab_binsearch+0x10d>
        *region_right = *region_left - 1;
c01005b6:	8b 45 0c             	mov    0xc(%ebp),%eax
c01005b9:	8b 00                	mov    (%eax),%eax
c01005bb:	8d 50 ff             	lea    -0x1(%eax),%edx
c01005be:	8b 45 10             	mov    0x10(%ebp),%eax
c01005c1:	89 10                	mov    %edx,(%eax)
        l = *region_right;
        for (; l > *region_left && stabs[l].n_type != type; l --)
            /* do nothing */;
        *region_left = l;
    }
}
c01005c3:	eb 3e                	jmp    c0100603 <stab_binsearch+0x14b>
    if (!any_matches) {
        *region_right = *region_left - 1;
    }
    else {
        // find rightmost region containing 'addr'
        l = *region_right;
c01005c5:	8b 45 10             	mov    0x10(%ebp),%eax
c01005c8:	8b 00                	mov    (%eax),%eax
c01005ca:	89 45 fc             	mov    %eax,-0x4(%ebp)
        for (; l > *region_left && stabs[l].n_type != type; l --)
c01005cd:	eb 03                	jmp    c01005d2 <stab_binsearch+0x11a>
c01005cf:	ff 4d fc             	decl   -0x4(%ebp)
c01005d2:	8b 45 0c             	mov    0xc(%ebp),%eax
c01005d5:	8b 00                	mov    (%eax),%eax
c01005d7:	3b 45 fc             	cmp    -0x4(%ebp),%eax
c01005da:	7d 1f                	jge    c01005fb <stab_binsearch+0x143>
c01005dc:	8b 55 fc             	mov    -0x4(%ebp),%edx
c01005df:	89 d0                	mov    %edx,%eax
c01005e1:	01 c0                	add    %eax,%eax
c01005e3:	01 d0                	add    %edx,%eax
c01005e5:	c1 e0 02             	shl    $0x2,%eax
c01005e8:	89 c2                	mov    %eax,%edx
c01005ea:	8b 45 08             	mov    0x8(%ebp),%eax
c01005ed:	01 d0                	add    %edx,%eax
c01005ef:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c01005f3:	0f b6 c0             	movzbl %al,%eax
c01005f6:	3b 45 14             	cmp    0x14(%ebp),%eax
c01005f9:	75 d4                	jne    c01005cf <stab_binsearch+0x117>
            /* do nothing */;
        *region_left = l;
c01005fb:	8b 45 0c             	mov    0xc(%ebp),%eax
c01005fe:	8b 55 fc             	mov    -0x4(%ebp),%edx
c0100601:	89 10                	mov    %edx,(%eax)
    }
}
c0100603:	90                   	nop
c0100604:	c9                   	leave  
c0100605:	c3                   	ret    

c0100606 <debuginfo_eip>:
 * the specified instruction address, @addr.  Returns 0 if information
 * was found, and negative if not.  But even if it returns negative it
 * has stored some information into '*info'.
 * */
int
debuginfo_eip(uintptr_t addr, struct eipdebuginfo *info) {
c0100606:	55                   	push   %ebp
c0100607:	89 e5                	mov    %esp,%ebp
c0100609:	83 ec 58             	sub    $0x58,%esp
    const struct stab *stabs, *stab_end;
    const char *stabstr, *stabstr_end;

    info->eip_file = "<unknown>";
c010060c:	8b 45 0c             	mov    0xc(%ebp),%eax
c010060f:	c7 00 98 5d 10 c0    	movl   $0xc0105d98,(%eax)
    info->eip_line = 0;
c0100615:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100618:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
    info->eip_fn_name = "<unknown>";
c010061f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100622:	c7 40 08 98 5d 10 c0 	movl   $0xc0105d98,0x8(%eax)
    info->eip_fn_namelen = 9;
c0100629:	8b 45 0c             	mov    0xc(%ebp),%eax
c010062c:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
    info->eip_fn_addr = addr;
c0100633:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100636:	8b 55 08             	mov    0x8(%ebp),%edx
c0100639:	89 50 10             	mov    %edx,0x10(%eax)
    info->eip_fn_narg = 0;
c010063c:	8b 45 0c             	mov    0xc(%ebp),%eax
c010063f:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

    stabs = __STAB_BEGIN__;
c0100646:	c7 45 f4 b8 6f 10 c0 	movl   $0xc0106fb8,-0xc(%ebp)
    stab_end = __STAB_END__;
c010064d:	c7 45 f0 14 1c 11 c0 	movl   $0xc0111c14,-0x10(%ebp)
    stabstr = __STABSTR_BEGIN__;
c0100654:	c7 45 ec 15 1c 11 c0 	movl   $0xc0111c15,-0x14(%ebp)
    stabstr_end = __STABSTR_END__;
c010065b:	c7 45 e8 cd 46 11 c0 	movl   $0xc01146cd,-0x18(%ebp)

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0) {
c0100662:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0100665:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0100668:	76 0b                	jbe    c0100675 <debuginfo_eip+0x6f>
c010066a:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010066d:	48                   	dec    %eax
c010066e:	0f b6 00             	movzbl (%eax),%eax
c0100671:	84 c0                	test   %al,%al
c0100673:	74 0a                	je     c010067f <debuginfo_eip+0x79>
        return -1;
c0100675:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c010067a:	e9 b7 02 00 00       	jmp    c0100936 <debuginfo_eip+0x330>
    // 'eip'.  First, we find the basic source file containing 'eip'.
    // Then, we look in that source file for the function.  Then we look
    // for the line number.

    // Search the entire set of stabs for the source file (type N_SO).
    int lfile = 0, rfile = (stab_end - stabs) - 1;
c010067f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
c0100686:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100689:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010068c:	29 c2                	sub    %eax,%edx
c010068e:	89 d0                	mov    %edx,%eax
c0100690:	c1 f8 02             	sar    $0x2,%eax
c0100693:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
c0100699:	48                   	dec    %eax
c010069a:	89 45 e0             	mov    %eax,-0x20(%ebp)
    stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
c010069d:	8b 45 08             	mov    0x8(%ebp),%eax
c01006a0:	89 44 24 10          	mov    %eax,0x10(%esp)
c01006a4:	c7 44 24 0c 64 00 00 	movl   $0x64,0xc(%esp)
c01006ab:	00 
c01006ac:	8d 45 e0             	lea    -0x20(%ebp),%eax
c01006af:	89 44 24 08          	mov    %eax,0x8(%esp)
c01006b3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
c01006b6:	89 44 24 04          	mov    %eax,0x4(%esp)
c01006ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01006bd:	89 04 24             	mov    %eax,(%esp)
c01006c0:	e8 f3 fd ff ff       	call   c01004b8 <stab_binsearch>
    if (lfile == 0)
c01006c5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01006c8:	85 c0                	test   %eax,%eax
c01006ca:	75 0a                	jne    c01006d6 <debuginfo_eip+0xd0>
        return -1;
c01006cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c01006d1:	e9 60 02 00 00       	jmp    c0100936 <debuginfo_eip+0x330>

    // Search within that file's stabs for the function definition
    // (N_FUN).
    int lfun = lfile, rfun = rfile;
c01006d6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01006d9:	89 45 dc             	mov    %eax,-0x24(%ebp)
c01006dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01006df:	89 45 d8             	mov    %eax,-0x28(%ebp)
    int lline, rline;
    stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
c01006e2:	8b 45 08             	mov    0x8(%ebp),%eax
c01006e5:	89 44 24 10          	mov    %eax,0x10(%esp)
c01006e9:	c7 44 24 0c 24 00 00 	movl   $0x24,0xc(%esp)
c01006f0:	00 
c01006f1:	8d 45 d8             	lea    -0x28(%ebp),%eax
c01006f4:	89 44 24 08          	mov    %eax,0x8(%esp)
c01006f8:	8d 45 dc             	lea    -0x24(%ebp),%eax
c01006fb:	89 44 24 04          	mov    %eax,0x4(%esp)
c01006ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100702:	89 04 24             	mov    %eax,(%esp)
c0100705:	e8 ae fd ff ff       	call   c01004b8 <stab_binsearch>

    if (lfun <= rfun) {
c010070a:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010070d:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0100710:	39 c2                	cmp    %eax,%edx
c0100712:	7f 7c                	jg     c0100790 <debuginfo_eip+0x18a>
        // stabs[lfun] points to the function name
        // in the string table, but check bounds just in case.
        if (stabs[lfun].n_strx < stabstr_end - stabstr) {
c0100714:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100717:	89 c2                	mov    %eax,%edx
c0100719:	89 d0                	mov    %edx,%eax
c010071b:	01 c0                	add    %eax,%eax
c010071d:	01 d0                	add    %edx,%eax
c010071f:	c1 e0 02             	shl    $0x2,%eax
c0100722:	89 c2                	mov    %eax,%edx
c0100724:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100727:	01 d0                	add    %edx,%eax
c0100729:	8b 00                	mov    (%eax),%eax
c010072b:	8b 4d e8             	mov    -0x18(%ebp),%ecx
c010072e:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0100731:	29 d1                	sub    %edx,%ecx
c0100733:	89 ca                	mov    %ecx,%edx
c0100735:	39 d0                	cmp    %edx,%eax
c0100737:	73 22                	jae    c010075b <debuginfo_eip+0x155>
            info->eip_fn_name = stabstr + stabs[lfun].n_strx;
c0100739:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010073c:	89 c2                	mov    %eax,%edx
c010073e:	89 d0                	mov    %edx,%eax
c0100740:	01 c0                	add    %eax,%eax
c0100742:	01 d0                	add    %edx,%eax
c0100744:	c1 e0 02             	shl    $0x2,%eax
c0100747:	89 c2                	mov    %eax,%edx
c0100749:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010074c:	01 d0                	add    %edx,%eax
c010074e:	8b 10                	mov    (%eax),%edx
c0100750:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100753:	01 c2                	add    %eax,%edx
c0100755:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100758:	89 50 08             	mov    %edx,0x8(%eax)
        }
        info->eip_fn_addr = stabs[lfun].n_value;
c010075b:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010075e:	89 c2                	mov    %eax,%edx
c0100760:	89 d0                	mov    %edx,%eax
c0100762:	01 c0                	add    %eax,%eax
c0100764:	01 d0                	add    %edx,%eax
c0100766:	c1 e0 02             	shl    $0x2,%eax
c0100769:	89 c2                	mov    %eax,%edx
c010076b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010076e:	01 d0                	add    %edx,%eax
c0100770:	8b 50 08             	mov    0x8(%eax),%edx
c0100773:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100776:	89 50 10             	mov    %edx,0x10(%eax)
        addr -= info->eip_fn_addr;
c0100779:	8b 45 0c             	mov    0xc(%ebp),%eax
c010077c:	8b 40 10             	mov    0x10(%eax),%eax
c010077f:	29 45 08             	sub    %eax,0x8(%ebp)
        // Search within the function definition for the line number.
        lline = lfun;
c0100782:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100785:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfun;
c0100788:	8b 45 d8             	mov    -0x28(%ebp),%eax
c010078b:	89 45 d0             	mov    %eax,-0x30(%ebp)
c010078e:	eb 15                	jmp    c01007a5 <debuginfo_eip+0x19f>
    } else {
        // Couldn't find function stab!  Maybe we're in an assembly
        // file.  Search the whole file for the line number.
        info->eip_fn_addr = addr;
c0100790:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100793:	8b 55 08             	mov    0x8(%ebp),%edx
c0100796:	89 50 10             	mov    %edx,0x10(%eax)
        lline = lfile;
c0100799:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010079c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfile;
c010079f:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01007a2:	89 45 d0             	mov    %eax,-0x30(%ebp)
    }
    info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
c01007a5:	8b 45 0c             	mov    0xc(%ebp),%eax
c01007a8:	8b 40 08             	mov    0x8(%eax),%eax
c01007ab:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
c01007b2:	00 
c01007b3:	89 04 24             	mov    %eax,(%esp)
c01007b6:	e8 64 4b 00 00       	call   c010531f <strfind>
c01007bb:	89 c2                	mov    %eax,%edx
c01007bd:	8b 45 0c             	mov    0xc(%ebp),%eax
c01007c0:	8b 40 08             	mov    0x8(%eax),%eax
c01007c3:	29 c2                	sub    %eax,%edx
c01007c5:	8b 45 0c             	mov    0xc(%ebp),%eax
c01007c8:	89 50 0c             	mov    %edx,0xc(%eax)

    // Search within [lline, rline] for the line number stab.
    // If found, set info->eip_line to the right line number.
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
c01007cb:	8b 45 08             	mov    0x8(%ebp),%eax
c01007ce:	89 44 24 10          	mov    %eax,0x10(%esp)
c01007d2:	c7 44 24 0c 44 00 00 	movl   $0x44,0xc(%esp)
c01007d9:	00 
c01007da:	8d 45 d0             	lea    -0x30(%ebp),%eax
c01007dd:	89 44 24 08          	mov    %eax,0x8(%esp)
c01007e1:	8d 45 d4             	lea    -0x2c(%ebp),%eax
c01007e4:	89 44 24 04          	mov    %eax,0x4(%esp)
c01007e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01007eb:	89 04 24             	mov    %eax,(%esp)
c01007ee:	e8 c5 fc ff ff       	call   c01004b8 <stab_binsearch>
    if (lline <= rline) {
c01007f3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01007f6:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01007f9:	39 c2                	cmp    %eax,%edx
c01007fb:	7f 23                	jg     c0100820 <debuginfo_eip+0x21a>
        info->eip_line = stabs[rline].n_desc;
c01007fd:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0100800:	89 c2                	mov    %eax,%edx
c0100802:	89 d0                	mov    %edx,%eax
c0100804:	01 c0                	add    %eax,%eax
c0100806:	01 d0                	add    %edx,%eax
c0100808:	c1 e0 02             	shl    $0x2,%eax
c010080b:	89 c2                	mov    %eax,%edx
c010080d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100810:	01 d0                	add    %edx,%eax
c0100812:	0f b7 40 06          	movzwl 0x6(%eax),%eax
c0100816:	89 c2                	mov    %eax,%edx
c0100818:	8b 45 0c             	mov    0xc(%ebp),%eax
c010081b:	89 50 04             	mov    %edx,0x4(%eax)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
c010081e:	eb 11                	jmp    c0100831 <debuginfo_eip+0x22b>
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
    if (lline <= rline) {
        info->eip_line = stabs[rline].n_desc;
    } else {
        return -1;
c0100820:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c0100825:	e9 0c 01 00 00       	jmp    c0100936 <debuginfo_eip+0x330>
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
           && stabs[lline].n_type != N_SOL
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
        lline --;
c010082a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010082d:	48                   	dec    %eax
c010082e:	89 45 d4             	mov    %eax,-0x2c(%ebp)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
c0100831:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0100834:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100837:	39 c2                	cmp    %eax,%edx
c0100839:	7c 56                	jl     c0100891 <debuginfo_eip+0x28b>
           && stabs[lline].n_type != N_SOL
c010083b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010083e:	89 c2                	mov    %eax,%edx
c0100840:	89 d0                	mov    %edx,%eax
c0100842:	01 c0                	add    %eax,%eax
c0100844:	01 d0                	add    %edx,%eax
c0100846:	c1 e0 02             	shl    $0x2,%eax
c0100849:	89 c2                	mov    %eax,%edx
c010084b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010084e:	01 d0                	add    %edx,%eax
c0100850:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c0100854:	3c 84                	cmp    $0x84,%al
c0100856:	74 39                	je     c0100891 <debuginfo_eip+0x28b>
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
c0100858:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010085b:	89 c2                	mov    %eax,%edx
c010085d:	89 d0                	mov    %edx,%eax
c010085f:	01 c0                	add    %eax,%eax
c0100861:	01 d0                	add    %edx,%eax
c0100863:	c1 e0 02             	shl    $0x2,%eax
c0100866:	89 c2                	mov    %eax,%edx
c0100868:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010086b:	01 d0                	add    %edx,%eax
c010086d:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c0100871:	3c 64                	cmp    $0x64,%al
c0100873:	75 b5                	jne    c010082a <debuginfo_eip+0x224>
c0100875:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100878:	89 c2                	mov    %eax,%edx
c010087a:	89 d0                	mov    %edx,%eax
c010087c:	01 c0                	add    %eax,%eax
c010087e:	01 d0                	add    %edx,%eax
c0100880:	c1 e0 02             	shl    $0x2,%eax
c0100883:	89 c2                	mov    %eax,%edx
c0100885:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100888:	01 d0                	add    %edx,%eax
c010088a:	8b 40 08             	mov    0x8(%eax),%eax
c010088d:	85 c0                	test   %eax,%eax
c010088f:	74 99                	je     c010082a <debuginfo_eip+0x224>
        lline --;
    }
    if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr) {
c0100891:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0100894:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100897:	39 c2                	cmp    %eax,%edx
c0100899:	7c 46                	jl     c01008e1 <debuginfo_eip+0x2db>
c010089b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010089e:	89 c2                	mov    %eax,%edx
c01008a0:	89 d0                	mov    %edx,%eax
c01008a2:	01 c0                	add    %eax,%eax
c01008a4:	01 d0                	add    %edx,%eax
c01008a6:	c1 e0 02             	shl    $0x2,%eax
c01008a9:	89 c2                	mov    %eax,%edx
c01008ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01008ae:	01 d0                	add    %edx,%eax
c01008b0:	8b 00                	mov    (%eax),%eax
c01008b2:	8b 4d e8             	mov    -0x18(%ebp),%ecx
c01008b5:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01008b8:	29 d1                	sub    %edx,%ecx
c01008ba:	89 ca                	mov    %ecx,%edx
c01008bc:	39 d0                	cmp    %edx,%eax
c01008be:	73 21                	jae    c01008e1 <debuginfo_eip+0x2db>
        info->eip_file = stabstr + stabs[lline].n_strx;
c01008c0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01008c3:	89 c2                	mov    %eax,%edx
c01008c5:	89 d0                	mov    %edx,%eax
c01008c7:	01 c0                	add    %eax,%eax
c01008c9:	01 d0                	add    %edx,%eax
c01008cb:	c1 e0 02             	shl    $0x2,%eax
c01008ce:	89 c2                	mov    %eax,%edx
c01008d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01008d3:	01 d0                	add    %edx,%eax
c01008d5:	8b 10                	mov    (%eax),%edx
c01008d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01008da:	01 c2                	add    %eax,%edx
c01008dc:	8b 45 0c             	mov    0xc(%ebp),%eax
c01008df:	89 10                	mov    %edx,(%eax)
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
c01008e1:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01008e4:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01008e7:	39 c2                	cmp    %eax,%edx
c01008e9:	7d 46                	jge    c0100931 <debuginfo_eip+0x32b>
        for (lline = lfun + 1;
c01008eb:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01008ee:	40                   	inc    %eax
c01008ef:	89 45 d4             	mov    %eax,-0x2c(%ebp)
c01008f2:	eb 16                	jmp    c010090a <debuginfo_eip+0x304>
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
            info->eip_fn_narg ++;
c01008f4:	8b 45 0c             	mov    0xc(%ebp),%eax
c01008f7:	8b 40 14             	mov    0x14(%eax),%eax
c01008fa:	8d 50 01             	lea    0x1(%eax),%edx
c01008fd:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100900:	89 50 14             	mov    %edx,0x14(%eax)
    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
c0100903:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100906:	40                   	inc    %eax
c0100907:	89 45 d4             	mov    %eax,-0x2c(%ebp)

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM;
c010090a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c010090d:	8b 45 d8             	mov    -0x28(%ebp),%eax
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
c0100910:	39 c2                	cmp    %eax,%edx
c0100912:	7d 1d                	jge    c0100931 <debuginfo_eip+0x32b>
             lline < rfun && stabs[lline].n_type == N_PSYM;
c0100914:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100917:	89 c2                	mov    %eax,%edx
c0100919:	89 d0                	mov    %edx,%eax
c010091b:	01 c0                	add    %eax,%eax
c010091d:	01 d0                	add    %edx,%eax
c010091f:	c1 e0 02             	shl    $0x2,%eax
c0100922:	89 c2                	mov    %eax,%edx
c0100924:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100927:	01 d0                	add    %edx,%eax
c0100929:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c010092d:	3c a0                	cmp    $0xa0,%al
c010092f:	74 c3                	je     c01008f4 <debuginfo_eip+0x2ee>
             lline ++) {
            info->eip_fn_narg ++;
        }
    }
    return 0;
c0100931:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100936:	c9                   	leave  
c0100937:	c3                   	ret    

c0100938 <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void
print_kerninfo(void) {
c0100938:	55                   	push   %ebp
c0100939:	89 e5                	mov    %esp,%ebp
c010093b:	83 ec 18             	sub    $0x18,%esp
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
c010093e:	c7 04 24 a2 5d 10 c0 	movl   $0xc0105da2,(%esp)
c0100945:	e8 48 f9 ff ff       	call   c0100292 <cprintf>
    cprintf("  entry  0x%08x (phys)\n", kern_init);
c010094a:	c7 44 24 04 36 00 10 	movl   $0xc0100036,0x4(%esp)
c0100951:	c0 
c0100952:	c7 04 24 bb 5d 10 c0 	movl   $0xc0105dbb,(%esp)
c0100959:	e8 34 f9 ff ff       	call   c0100292 <cprintf>
    cprintf("  etext  0x%08x (phys)\n", etext);
c010095e:	c7 44 24 04 9d 5c 10 	movl   $0xc0105c9d,0x4(%esp)
c0100965:	c0 
c0100966:	c7 04 24 d3 5d 10 c0 	movl   $0xc0105dd3,(%esp)
c010096d:	e8 20 f9 ff ff       	call   c0100292 <cprintf>
    cprintf("  edata  0x%08x (phys)\n", edata);
c0100972:	c7 44 24 04 00 a0 11 	movl   $0xc011a000,0x4(%esp)
c0100979:	c0 
c010097a:	c7 04 24 eb 5d 10 c0 	movl   $0xc0105deb,(%esp)
c0100981:	e8 0c f9 ff ff       	call   c0100292 <cprintf>
    cprintf("  end    0x%08x (phys)\n", end);
c0100986:	c7 44 24 04 28 af 11 	movl   $0xc011af28,0x4(%esp)
c010098d:	c0 
c010098e:	c7 04 24 03 5e 10 c0 	movl   $0xc0105e03,(%esp)
c0100995:	e8 f8 f8 ff ff       	call   c0100292 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n", (end - kern_init + 1023)/1024);
c010099a:	b8 28 af 11 c0       	mov    $0xc011af28,%eax
c010099f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
c01009a5:	b8 36 00 10 c0       	mov    $0xc0100036,%eax
c01009aa:	29 c2                	sub    %eax,%edx
c01009ac:	89 d0                	mov    %edx,%eax
c01009ae:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
c01009b4:	85 c0                	test   %eax,%eax
c01009b6:	0f 48 c2             	cmovs  %edx,%eax
c01009b9:	c1 f8 0a             	sar    $0xa,%eax
c01009bc:	89 44 24 04          	mov    %eax,0x4(%esp)
c01009c0:	c7 04 24 1c 5e 10 c0 	movl   $0xc0105e1c,(%esp)
c01009c7:	e8 c6 f8 ff ff       	call   c0100292 <cprintf>
}
c01009cc:	90                   	nop
c01009cd:	c9                   	leave  
c01009ce:	c3                   	ret    

c01009cf <print_debuginfo>:
/* *
 * print_debuginfo - read and print the stat information for the address @eip,
 * and info.eip_fn_addr should be the first address of the related function.
 * */
void
print_debuginfo(uintptr_t eip) {
c01009cf:	55                   	push   %ebp
c01009d0:	89 e5                	mov    %esp,%ebp
c01009d2:	81 ec 48 01 00 00    	sub    $0x148,%esp
    struct eipdebuginfo info;
    if (debuginfo_eip(eip, &info) != 0) {
c01009d8:	8d 45 dc             	lea    -0x24(%ebp),%eax
c01009db:	89 44 24 04          	mov    %eax,0x4(%esp)
c01009df:	8b 45 08             	mov    0x8(%ebp),%eax
c01009e2:	89 04 24             	mov    %eax,(%esp)
c01009e5:	e8 1c fc ff ff       	call   c0100606 <debuginfo_eip>
c01009ea:	85 c0                	test   %eax,%eax
c01009ec:	74 15                	je     c0100a03 <print_debuginfo+0x34>
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
c01009ee:	8b 45 08             	mov    0x8(%ebp),%eax
c01009f1:	89 44 24 04          	mov    %eax,0x4(%esp)
c01009f5:	c7 04 24 46 5e 10 c0 	movl   $0xc0105e46,(%esp)
c01009fc:	e8 91 f8 ff ff       	call   c0100292 <cprintf>
        }
        fnname[j] = '\0';
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
                fnname, eip - info.eip_fn_addr);
    }
}
c0100a01:	eb 6c                	jmp    c0100a6f <print_debuginfo+0xa0>
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
c0100a03:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0100a0a:	eb 1b                	jmp    c0100a27 <print_debuginfo+0x58>
            fnname[j] = info.eip_fn_name[j];
c0100a0c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0100a0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a12:	01 d0                	add    %edx,%eax
c0100a14:	0f b6 00             	movzbl (%eax),%eax
c0100a17:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
c0100a1d:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100a20:	01 ca                	add    %ecx,%edx
c0100a22:	88 02                	mov    %al,(%edx)
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
c0100a24:	ff 45 f4             	incl   -0xc(%ebp)
c0100a27:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0100a2a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0100a2d:	7f dd                	jg     c0100a0c <print_debuginfo+0x3d>
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
c0100a2f:	8d 95 dc fe ff ff    	lea    -0x124(%ebp),%edx
c0100a35:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a38:	01 d0                	add    %edx,%eax
c0100a3a:	c6 00 00             	movb   $0x0,(%eax)
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
                fnname, eip - info.eip_fn_addr);
c0100a3d:	8b 45 ec             	mov    -0x14(%ebp),%eax
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
c0100a40:	8b 55 08             	mov    0x8(%ebp),%edx
c0100a43:	89 d1                	mov    %edx,%ecx
c0100a45:	29 c1                	sub    %eax,%ecx
c0100a47:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0100a4a:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100a4d:	89 4c 24 10          	mov    %ecx,0x10(%esp)
c0100a51:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
c0100a57:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
c0100a5b:	89 54 24 08          	mov    %edx,0x8(%esp)
c0100a5f:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100a63:	c7 04 24 62 5e 10 c0 	movl   $0xc0105e62,(%esp)
c0100a6a:	e8 23 f8 ff ff       	call   c0100292 <cprintf>
                fnname, eip - info.eip_fn_addr);
    }
}
c0100a6f:	90                   	nop
c0100a70:	c9                   	leave  
c0100a71:	c3                   	ret    

c0100a72 <read_eip>:

static __noinline uint32_t
read_eip(void) {
c0100a72:	55                   	push   %ebp
c0100a73:	89 e5                	mov    %esp,%ebp
c0100a75:	83 ec 10             	sub    $0x10,%esp
    uint32_t eip;
    asm volatile("movl 4(%%ebp), %0" : "=r" (eip));
c0100a78:	8b 45 04             	mov    0x4(%ebp),%eax
c0100a7b:	89 45 fc             	mov    %eax,-0x4(%ebp)
    return eip;
c0100a7e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0100a81:	c9                   	leave  
c0100a82:	c3                   	ret    

c0100a83 <print_stackframe>:
 *
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the boundary.
 * */
void
print_stackframe(void) {
c0100a83:	55                   	push   %ebp
c0100a84:	89 e5                	mov    %esp,%ebp
      *    (3.4) call print_debuginfo(eip-1) to print the C calling function name and line number, etc.
      *    (3.5) popup a calling stackframe
      *           NOTICE: the calling funciton's return addr eip  = ss:[ebp+4]
      *                   the calling funciton's ebp = ss:[ebp]
      */
}
c0100a86:	90                   	nop
c0100a87:	5d                   	pop    %ebp
c0100a88:	c3                   	ret    

c0100a89 <parse>:
#define MAXARGS         16
#define WHITESPACE      " \t\n\r"

/* parse - parse the command buffer into whitespace-separated arguments */
static int
parse(char *buf, char **argv) {
c0100a89:	55                   	push   %ebp
c0100a8a:	89 e5                	mov    %esp,%ebp
c0100a8c:	83 ec 28             	sub    $0x28,%esp
    int argc = 0;
c0100a8f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
c0100a96:	eb 0c                	jmp    c0100aa4 <parse+0x1b>
            *buf ++ = '\0';
c0100a98:	8b 45 08             	mov    0x8(%ebp),%eax
c0100a9b:	8d 50 01             	lea    0x1(%eax),%edx
c0100a9e:	89 55 08             	mov    %edx,0x8(%ebp)
c0100aa1:	c6 00 00             	movb   $0x0,(%eax)
static int
parse(char *buf, char **argv) {
    int argc = 0;
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
c0100aa4:	8b 45 08             	mov    0x8(%ebp),%eax
c0100aa7:	0f b6 00             	movzbl (%eax),%eax
c0100aaa:	84 c0                	test   %al,%al
c0100aac:	74 1d                	je     c0100acb <parse+0x42>
c0100aae:	8b 45 08             	mov    0x8(%ebp),%eax
c0100ab1:	0f b6 00             	movzbl (%eax),%eax
c0100ab4:	0f be c0             	movsbl %al,%eax
c0100ab7:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100abb:	c7 04 24 f4 5e 10 c0 	movl   $0xc0105ef4,(%esp)
c0100ac2:	e8 26 48 00 00       	call   c01052ed <strchr>
c0100ac7:	85 c0                	test   %eax,%eax
c0100ac9:	75 cd                	jne    c0100a98 <parse+0xf>
            *buf ++ = '\0';
        }
        if (*buf == '\0') {
c0100acb:	8b 45 08             	mov    0x8(%ebp),%eax
c0100ace:	0f b6 00             	movzbl (%eax),%eax
c0100ad1:	84 c0                	test   %al,%al
c0100ad3:	74 69                	je     c0100b3e <parse+0xb5>
            break;
        }

        // save and scan past next arg
        if (argc == MAXARGS - 1) {
c0100ad5:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
c0100ad9:	75 14                	jne    c0100aef <parse+0x66>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
c0100adb:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
c0100ae2:	00 
c0100ae3:	c7 04 24 f9 5e 10 c0 	movl   $0xc0105ef9,(%esp)
c0100aea:	e8 a3 f7 ff ff       	call   c0100292 <cprintf>
        }
        argv[argc ++] = buf;
c0100aef:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100af2:	8d 50 01             	lea    0x1(%eax),%edx
c0100af5:	89 55 f4             	mov    %edx,-0xc(%ebp)
c0100af8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0100aff:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100b02:	01 c2                	add    %eax,%edx
c0100b04:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b07:	89 02                	mov    %eax,(%edx)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
c0100b09:	eb 03                	jmp    c0100b0e <parse+0x85>
            buf ++;
c0100b0b:	ff 45 08             	incl   0x8(%ebp)
        // save and scan past next arg
        if (argc == MAXARGS - 1) {
            cprintf("Too many arguments (max %d).\n", MAXARGS);
        }
        argv[argc ++] = buf;
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
c0100b0e:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b11:	0f b6 00             	movzbl (%eax),%eax
c0100b14:	84 c0                	test   %al,%al
c0100b16:	0f 84 7a ff ff ff    	je     c0100a96 <parse+0xd>
c0100b1c:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b1f:	0f b6 00             	movzbl (%eax),%eax
c0100b22:	0f be c0             	movsbl %al,%eax
c0100b25:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100b29:	c7 04 24 f4 5e 10 c0 	movl   $0xc0105ef4,(%esp)
c0100b30:	e8 b8 47 00 00       	call   c01052ed <strchr>
c0100b35:	85 c0                	test   %eax,%eax
c0100b37:	74 d2                	je     c0100b0b <parse+0x82>
            buf ++;
        }
    }
c0100b39:	e9 58 ff ff ff       	jmp    c0100a96 <parse+0xd>
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
            *buf ++ = '\0';
        }
        if (*buf == '\0') {
            break;
c0100b3e:	90                   	nop
        argv[argc ++] = buf;
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
            buf ++;
        }
    }
    return argc;
c0100b3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0100b42:	c9                   	leave  
c0100b43:	c3                   	ret    

c0100b44 <runcmd>:
/* *
 * runcmd - parse the input string, split it into separated arguments
 * and then lookup and invoke some related commands/
 * */
static int
runcmd(char *buf, struct trapframe *tf) {
c0100b44:	55                   	push   %ebp
c0100b45:	89 e5                	mov    %esp,%ebp
c0100b47:	53                   	push   %ebx
c0100b48:	83 ec 64             	sub    $0x64,%esp
    char *argv[MAXARGS];
    int argc = parse(buf, argv);
c0100b4b:	8d 45 b0             	lea    -0x50(%ebp),%eax
c0100b4e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100b52:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b55:	89 04 24             	mov    %eax,(%esp)
c0100b58:	e8 2c ff ff ff       	call   c0100a89 <parse>
c0100b5d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if (argc == 0) {
c0100b60:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0100b64:	75 0a                	jne    c0100b70 <runcmd+0x2c>
        return 0;
c0100b66:	b8 00 00 00 00       	mov    $0x0,%eax
c0100b6b:	e9 83 00 00 00       	jmp    c0100bf3 <runcmd+0xaf>
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100b70:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0100b77:	eb 5a                	jmp    c0100bd3 <runcmd+0x8f>
        if (strcmp(commands[i].name, argv[0]) == 0) {
c0100b79:	8b 4d b0             	mov    -0x50(%ebp),%ecx
c0100b7c:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100b7f:	89 d0                	mov    %edx,%eax
c0100b81:	01 c0                	add    %eax,%eax
c0100b83:	01 d0                	add    %edx,%eax
c0100b85:	c1 e0 02             	shl    $0x2,%eax
c0100b88:	05 00 70 11 c0       	add    $0xc0117000,%eax
c0100b8d:	8b 00                	mov    (%eax),%eax
c0100b8f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
c0100b93:	89 04 24             	mov    %eax,(%esp)
c0100b96:	e8 b5 46 00 00       	call   c0105250 <strcmp>
c0100b9b:	85 c0                	test   %eax,%eax
c0100b9d:	75 31                	jne    c0100bd0 <runcmd+0x8c>
            return commands[i].func(argc - 1, argv + 1, tf);
c0100b9f:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100ba2:	89 d0                	mov    %edx,%eax
c0100ba4:	01 c0                	add    %eax,%eax
c0100ba6:	01 d0                	add    %edx,%eax
c0100ba8:	c1 e0 02             	shl    $0x2,%eax
c0100bab:	05 08 70 11 c0       	add    $0xc0117008,%eax
c0100bb0:	8b 10                	mov    (%eax),%edx
c0100bb2:	8d 45 b0             	lea    -0x50(%ebp),%eax
c0100bb5:	83 c0 04             	add    $0x4,%eax
c0100bb8:	8b 4d f0             	mov    -0x10(%ebp),%ecx
c0100bbb:	8d 59 ff             	lea    -0x1(%ecx),%ebx
c0100bbe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
c0100bc1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c0100bc5:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100bc9:	89 1c 24             	mov    %ebx,(%esp)
c0100bcc:	ff d2                	call   *%edx
c0100bce:	eb 23                	jmp    c0100bf3 <runcmd+0xaf>
    int argc = parse(buf, argv);
    if (argc == 0) {
        return 0;
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100bd0:	ff 45 f4             	incl   -0xc(%ebp)
c0100bd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100bd6:	83 f8 02             	cmp    $0x2,%eax
c0100bd9:	76 9e                	jbe    c0100b79 <runcmd+0x35>
        if (strcmp(commands[i].name, argv[0]) == 0) {
            return commands[i].func(argc - 1, argv + 1, tf);
        }
    }
    cprintf("Unknown command '%s'\n", argv[0]);
c0100bdb:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0100bde:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100be2:	c7 04 24 17 5f 10 c0 	movl   $0xc0105f17,(%esp)
c0100be9:	e8 a4 f6 ff ff       	call   c0100292 <cprintf>
    return 0;
c0100bee:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100bf3:	83 c4 64             	add    $0x64,%esp
c0100bf6:	5b                   	pop    %ebx
c0100bf7:	5d                   	pop    %ebp
c0100bf8:	c3                   	ret    

c0100bf9 <kmonitor>:

/***** Implementations of basic kernel monitor commands *****/

void
kmonitor(struct trapframe *tf) {
c0100bf9:	55                   	push   %ebp
c0100bfa:	89 e5                	mov    %esp,%ebp
c0100bfc:	83 ec 28             	sub    $0x28,%esp
    cprintf("Welcome to the kernel debug monitor!!\n");
c0100bff:	c7 04 24 30 5f 10 c0 	movl   $0xc0105f30,(%esp)
c0100c06:	e8 87 f6 ff ff       	call   c0100292 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
c0100c0b:	c7 04 24 58 5f 10 c0 	movl   $0xc0105f58,(%esp)
c0100c12:	e8 7b f6 ff ff       	call   c0100292 <cprintf>

    if (tf != NULL) {
c0100c17:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0100c1b:	74 0b                	je     c0100c28 <kmonitor+0x2f>
        print_trapframe(tf);
c0100c1d:	8b 45 08             	mov    0x8(%ebp),%eax
c0100c20:	89 04 24             	mov    %eax,(%esp)
c0100c23:	e8 0b 0c 00 00       	call   c0101833 <print_trapframe>
    }

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
c0100c28:	c7 04 24 7d 5f 10 c0 	movl   $0xc0105f7d,(%esp)
c0100c2f:	e8 00 f7 ff ff       	call   c0100334 <readline>
c0100c34:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0100c37:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0100c3b:	74 eb                	je     c0100c28 <kmonitor+0x2f>
            if (runcmd(buf, tf) < 0) {
c0100c3d:	8b 45 08             	mov    0x8(%ebp),%eax
c0100c40:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100c44:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100c47:	89 04 24             	mov    %eax,(%esp)
c0100c4a:	e8 f5 fe ff ff       	call   c0100b44 <runcmd>
c0100c4f:	85 c0                	test   %eax,%eax
c0100c51:	78 02                	js     c0100c55 <kmonitor+0x5c>
                break;
            }
        }
    }
c0100c53:	eb d3                	jmp    c0100c28 <kmonitor+0x2f>

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
            if (runcmd(buf, tf) < 0) {
                break;
c0100c55:	90                   	nop
            }
        }
    }
}
c0100c56:	90                   	nop
c0100c57:	c9                   	leave  
c0100c58:	c3                   	ret    

c0100c59 <mon_help>:

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
c0100c59:	55                   	push   %ebp
c0100c5a:	89 e5                	mov    %esp,%ebp
c0100c5c:	83 ec 28             	sub    $0x28,%esp
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100c5f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0100c66:	eb 3d                	jmp    c0100ca5 <mon_help+0x4c>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
c0100c68:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100c6b:	89 d0                	mov    %edx,%eax
c0100c6d:	01 c0                	add    %eax,%eax
c0100c6f:	01 d0                	add    %edx,%eax
c0100c71:	c1 e0 02             	shl    $0x2,%eax
c0100c74:	05 04 70 11 c0       	add    $0xc0117004,%eax
c0100c79:	8b 08                	mov    (%eax),%ecx
c0100c7b:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100c7e:	89 d0                	mov    %edx,%eax
c0100c80:	01 c0                	add    %eax,%eax
c0100c82:	01 d0                	add    %edx,%eax
c0100c84:	c1 e0 02             	shl    $0x2,%eax
c0100c87:	05 00 70 11 c0       	add    $0xc0117000,%eax
c0100c8c:	8b 00                	mov    (%eax),%eax
c0100c8e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c0100c92:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100c96:	c7 04 24 81 5f 10 c0 	movl   $0xc0105f81,(%esp)
c0100c9d:	e8 f0 f5 ff ff       	call   c0100292 <cprintf>

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100ca2:	ff 45 f4             	incl   -0xc(%ebp)
c0100ca5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100ca8:	83 f8 02             	cmp    $0x2,%eax
c0100cab:	76 bb                	jbe    c0100c68 <mon_help+0xf>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
    }
    return 0;
c0100cad:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100cb2:	c9                   	leave  
c0100cb3:	c3                   	ret    

c0100cb4 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
c0100cb4:	55                   	push   %ebp
c0100cb5:	89 e5                	mov    %esp,%ebp
c0100cb7:	83 ec 08             	sub    $0x8,%esp
    print_kerninfo();
c0100cba:	e8 79 fc ff ff       	call   c0100938 <print_kerninfo>
    return 0;
c0100cbf:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100cc4:	c9                   	leave  
c0100cc5:	c3                   	ret    

c0100cc6 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
c0100cc6:	55                   	push   %ebp
c0100cc7:	89 e5                	mov    %esp,%ebp
c0100cc9:	83 ec 08             	sub    $0x8,%esp
    print_stackframe();
c0100ccc:	e8 b2 fd ff ff       	call   c0100a83 <print_stackframe>
    return 0;
c0100cd1:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100cd6:	c9                   	leave  
c0100cd7:	c3                   	ret    

c0100cd8 <clock_init>:
/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void
clock_init(void) {
c0100cd8:	55                   	push   %ebp
c0100cd9:	89 e5                	mov    %esp,%ebp
c0100cdb:	83 ec 28             	sub    $0x28,%esp
c0100cde:	66 c7 45 f6 43 00    	movw   $0x43,-0xa(%ebp)
c0100ce4:	c6 45 ef 34          	movb   $0x34,-0x11(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100ce8:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
c0100cec:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100cf0:	ee                   	out    %al,(%dx)
c0100cf1:	66 c7 45 f4 40 00    	movw   $0x40,-0xc(%ebp)
c0100cf7:	c6 45 f0 9c          	movb   $0x9c,-0x10(%ebp)
c0100cfb:	0f b6 45 f0          	movzbl -0x10(%ebp),%eax
c0100cff:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100d02:	ee                   	out    %al,(%dx)
c0100d03:	66 c7 45 f2 40 00    	movw   $0x40,-0xe(%ebp)
c0100d09:	c6 45 f1 2e          	movb   $0x2e,-0xf(%ebp)
c0100d0d:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c0100d11:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0100d15:	ee                   	out    %al,(%dx)
    outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
    outb(IO_TIMER1, TIMER_DIV(100) % 256);
    outb(IO_TIMER1, TIMER_DIV(100) / 256);

    // initialize time counter 'ticks' to zero
    ticks = 0;
c0100d16:	c7 05 0c af 11 c0 00 	movl   $0x0,0xc011af0c
c0100d1d:	00 00 00 

    cprintf("++ setup timer interrupts\n");
c0100d20:	c7 04 24 8a 5f 10 c0 	movl   $0xc0105f8a,(%esp)
c0100d27:	e8 66 f5 ff ff       	call   c0100292 <cprintf>
    pic_enable(IRQ_TIMER);
c0100d2c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c0100d33:	e8 1e 09 00 00       	call   c0101656 <pic_enable>
}
c0100d38:	90                   	nop
c0100d39:	c9                   	leave  
c0100d3a:	c3                   	ret    

c0100d3b <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
c0100d3b:	55                   	push   %ebp
c0100d3c:	89 e5                	mov    %esp,%ebp
c0100d3e:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c0100d41:	9c                   	pushf  
c0100d42:	58                   	pop    %eax
c0100d43:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c0100d46:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
c0100d49:	25 00 02 00 00       	and    $0x200,%eax
c0100d4e:	85 c0                	test   %eax,%eax
c0100d50:	74 0c                	je     c0100d5e <__intr_save+0x23>
        intr_disable();
c0100d52:	e8 6c 0a 00 00       	call   c01017c3 <intr_disable>
        return 1;
c0100d57:	b8 01 00 00 00       	mov    $0x1,%eax
c0100d5c:	eb 05                	jmp    c0100d63 <__intr_save+0x28>
    }
    return 0;
c0100d5e:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100d63:	c9                   	leave  
c0100d64:	c3                   	ret    

c0100d65 <__intr_restore>:

static inline void
__intr_restore(bool flag) {
c0100d65:	55                   	push   %ebp
c0100d66:	89 e5                	mov    %esp,%ebp
c0100d68:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c0100d6b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0100d6f:	74 05                	je     c0100d76 <__intr_restore+0x11>
        intr_enable();
c0100d71:	e8 46 0a 00 00       	call   c01017bc <intr_enable>
    }
}
c0100d76:	90                   	nop
c0100d77:	c9                   	leave  
c0100d78:	c3                   	ret    

c0100d79 <delay>:
#include <memlayout.h>
#include <sync.h>

/* stupid I/O delay routine necessitated by historical PC design flaws */
static void
delay(void) {
c0100d79:	55                   	push   %ebp
c0100d7a:	89 e5                	mov    %esp,%ebp
c0100d7c:	83 ec 10             	sub    $0x10,%esp
c0100d7f:	66 c7 45 fe 84 00    	movw   $0x84,-0x2(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100d85:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
c0100d89:	89 c2                	mov    %eax,%edx
c0100d8b:	ec                   	in     (%dx),%al
c0100d8c:	88 45 f4             	mov    %al,-0xc(%ebp)
c0100d8f:	66 c7 45 fc 84 00    	movw   $0x84,-0x4(%ebp)
c0100d95:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100d98:	89 c2                	mov    %eax,%edx
c0100d9a:	ec                   	in     (%dx),%al
c0100d9b:	88 45 f5             	mov    %al,-0xb(%ebp)
c0100d9e:	66 c7 45 fa 84 00    	movw   $0x84,-0x6(%ebp)
c0100da4:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c0100da8:	89 c2                	mov    %eax,%edx
c0100daa:	ec                   	in     (%dx),%al
c0100dab:	88 45 f6             	mov    %al,-0xa(%ebp)
c0100dae:	66 c7 45 f8 84 00    	movw   $0x84,-0x8(%ebp)
c0100db4:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0100db7:	89 c2                	mov    %eax,%edx
c0100db9:	ec                   	in     (%dx),%al
c0100dba:	88 45 f7             	mov    %al,-0x9(%ebp)
    inb(0x84);
    inb(0x84);
    inb(0x84);
    inb(0x84);
}
c0100dbd:	90                   	nop
c0100dbe:	c9                   	leave  
c0100dbf:	c3                   	ret    

c0100dc0 <cga_init>:
static uint16_t addr_6845;

/* TEXT-mode CGA/VGA display output */

static void
cga_init(void) {
c0100dc0:	55                   	push   %ebp
c0100dc1:	89 e5                	mov    %esp,%ebp
c0100dc3:	83 ec 20             	sub    $0x20,%esp
    volatile uint16_t *cp = (uint16_t *)(CGA_BUF + KERNBASE);
c0100dc6:	c7 45 fc 00 80 0b c0 	movl   $0xc00b8000,-0x4(%ebp)
    uint16_t was = *cp;
c0100dcd:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100dd0:	0f b7 00             	movzwl (%eax),%eax
c0100dd3:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
    *cp = (uint16_t) 0xA55A;
c0100dd7:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100dda:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
    if (*cp != 0xA55A) {
c0100ddf:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100de2:	0f b7 00             	movzwl (%eax),%eax
c0100de5:	0f b7 c0             	movzwl %ax,%eax
c0100de8:	3d 5a a5 00 00       	cmp    $0xa55a,%eax
c0100ded:	74 12                	je     c0100e01 <cga_init+0x41>
        cp = (uint16_t*)(MONO_BUF + KERNBASE);
c0100def:	c7 45 fc 00 00 0b c0 	movl   $0xc00b0000,-0x4(%ebp)
        addr_6845 = MONO_BASE;
c0100df6:	66 c7 05 46 a4 11 c0 	movw   $0x3b4,0xc011a446
c0100dfd:	b4 03 
c0100dff:	eb 13                	jmp    c0100e14 <cga_init+0x54>
    } else {
        *cp = was;
c0100e01:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100e04:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c0100e08:	66 89 10             	mov    %dx,(%eax)
        addr_6845 = CGA_BASE;
c0100e0b:	66 c7 05 46 a4 11 c0 	movw   $0x3d4,0xc011a446
c0100e12:	d4 03 
    }

    // Extract cursor location
    uint32_t pos;
    outb(addr_6845, 14);
c0100e14:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c0100e1b:	66 89 45 f8          	mov    %ax,-0x8(%ebp)
c0100e1f:	c6 45 ea 0e          	movb   $0xe,-0x16(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100e23:	0f b6 45 ea          	movzbl -0x16(%ebp),%eax
c0100e27:	8b 55 f8             	mov    -0x8(%ebp),%edx
c0100e2a:	ee                   	out    %al,(%dx)
    pos = inb(addr_6845 + 1) << 8;
c0100e2b:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c0100e32:	40                   	inc    %eax
c0100e33:	0f b7 c0             	movzwl %ax,%eax
c0100e36:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100e3a:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c0100e3e:	89 c2                	mov    %eax,%edx
c0100e40:	ec                   	in     (%dx),%al
c0100e41:	88 45 eb             	mov    %al,-0x15(%ebp)
    return data;
c0100e44:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
c0100e48:	0f b6 c0             	movzbl %al,%eax
c0100e4b:	c1 e0 08             	shl    $0x8,%eax
c0100e4e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    outb(addr_6845, 15);
c0100e51:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c0100e58:	66 89 45 f0          	mov    %ax,-0x10(%ebp)
c0100e5c:	c6 45 ec 0f          	movb   $0xf,-0x14(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100e60:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
c0100e64:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100e67:	ee                   	out    %al,(%dx)
    pos |= inb(addr_6845 + 1);
c0100e68:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c0100e6f:	40                   	inc    %eax
c0100e70:	0f b7 c0             	movzwl %ax,%eax
c0100e73:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100e77:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
c0100e7b:	89 c2                	mov    %eax,%edx
c0100e7d:	ec                   	in     (%dx),%al
c0100e7e:	88 45 ed             	mov    %al,-0x13(%ebp)
    return data;
c0100e81:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c0100e85:	0f b6 c0             	movzbl %al,%eax
c0100e88:	09 45 f4             	or     %eax,-0xc(%ebp)

    crt_buf = (uint16_t*) cp;
c0100e8b:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100e8e:	a3 40 a4 11 c0       	mov    %eax,0xc011a440
    crt_pos = pos;
c0100e93:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100e96:	0f b7 c0             	movzwl %ax,%eax
c0100e99:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
}
c0100e9f:	90                   	nop
c0100ea0:	c9                   	leave  
c0100ea1:	c3                   	ret    

c0100ea2 <serial_init>:

static bool serial_exists = 0;

static void
serial_init(void) {
c0100ea2:	55                   	push   %ebp
c0100ea3:	89 e5                	mov    %esp,%ebp
c0100ea5:	83 ec 38             	sub    $0x38,%esp
c0100ea8:	66 c7 45 f6 fa 03    	movw   $0x3fa,-0xa(%ebp)
c0100eae:	c6 45 da 00          	movb   $0x0,-0x26(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100eb2:	0f b6 45 da          	movzbl -0x26(%ebp),%eax
c0100eb6:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100eba:	ee                   	out    %al,(%dx)
c0100ebb:	66 c7 45 f4 fb 03    	movw   $0x3fb,-0xc(%ebp)
c0100ec1:	c6 45 db 80          	movb   $0x80,-0x25(%ebp)
c0100ec5:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
c0100ec9:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100ecc:	ee                   	out    %al,(%dx)
c0100ecd:	66 c7 45 f2 f8 03    	movw   $0x3f8,-0xe(%ebp)
c0100ed3:	c6 45 dc 0c          	movb   $0xc,-0x24(%ebp)
c0100ed7:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
c0100edb:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0100edf:	ee                   	out    %al,(%dx)
c0100ee0:	66 c7 45 f0 f9 03    	movw   $0x3f9,-0x10(%ebp)
c0100ee6:	c6 45 dd 00          	movb   $0x0,-0x23(%ebp)
c0100eea:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
c0100eee:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100ef1:	ee                   	out    %al,(%dx)
c0100ef2:	66 c7 45 ee fb 03    	movw   $0x3fb,-0x12(%ebp)
c0100ef8:	c6 45 de 03          	movb   $0x3,-0x22(%ebp)
c0100efc:	0f b6 45 de          	movzbl -0x22(%ebp),%eax
c0100f00:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c0100f04:	ee                   	out    %al,(%dx)
c0100f05:	66 c7 45 ec fc 03    	movw   $0x3fc,-0x14(%ebp)
c0100f0b:	c6 45 df 00          	movb   $0x0,-0x21(%ebp)
c0100f0f:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
c0100f13:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0100f16:	ee                   	out    %al,(%dx)
c0100f17:	66 c7 45 ea f9 03    	movw   $0x3f9,-0x16(%ebp)
c0100f1d:	c6 45 e0 01          	movb   $0x1,-0x20(%ebp)
c0100f21:	0f b6 45 e0          	movzbl -0x20(%ebp),%eax
c0100f25:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c0100f29:	ee                   	out    %al,(%dx)
c0100f2a:	66 c7 45 e8 fd 03    	movw   $0x3fd,-0x18(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100f30:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0100f33:	89 c2                	mov    %eax,%edx
c0100f35:	ec                   	in     (%dx),%al
c0100f36:	88 45 e1             	mov    %al,-0x1f(%ebp)
    return data;
c0100f39:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
    // Enable rcv interrupts
    outb(COM1 + COM_IER, COM_IER_RDI);

    // Clear any preexisting overrun indications and interrupts
    // Serial port doesn't exist if COM_LSR returns 0xFF
    serial_exists = (inb(COM1 + COM_LSR) != 0xFF);
c0100f3d:	3c ff                	cmp    $0xff,%al
c0100f3f:	0f 95 c0             	setne  %al
c0100f42:	0f b6 c0             	movzbl %al,%eax
c0100f45:	a3 48 a4 11 c0       	mov    %eax,0xc011a448
c0100f4a:	66 c7 45 e6 fa 03    	movw   $0x3fa,-0x1a(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100f50:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax
c0100f54:	89 c2                	mov    %eax,%edx
c0100f56:	ec                   	in     (%dx),%al
c0100f57:	88 45 e2             	mov    %al,-0x1e(%ebp)
c0100f5a:	66 c7 45 e4 f8 03    	movw   $0x3f8,-0x1c(%ebp)
c0100f60:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100f63:	89 c2                	mov    %eax,%edx
c0100f65:	ec                   	in     (%dx),%al
c0100f66:	88 45 e3             	mov    %al,-0x1d(%ebp)
    (void) inb(COM1+COM_IIR);
    (void) inb(COM1+COM_RX);

    if (serial_exists) {
c0100f69:	a1 48 a4 11 c0       	mov    0xc011a448,%eax
c0100f6e:	85 c0                	test   %eax,%eax
c0100f70:	74 0c                	je     c0100f7e <serial_init+0xdc>
        pic_enable(IRQ_COM1);
c0100f72:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
c0100f79:	e8 d8 06 00 00       	call   c0101656 <pic_enable>
    }
}
c0100f7e:	90                   	nop
c0100f7f:	c9                   	leave  
c0100f80:	c3                   	ret    

c0100f81 <lpt_putc_sub>:

static void
lpt_putc_sub(int c) {
c0100f81:	55                   	push   %ebp
c0100f82:	89 e5                	mov    %esp,%ebp
c0100f84:	83 ec 10             	sub    $0x10,%esp
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
c0100f87:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c0100f8e:	eb 08                	jmp    c0100f98 <lpt_putc_sub+0x17>
        delay();
c0100f90:	e8 e4 fd ff ff       	call   c0100d79 <delay>
}

static void
lpt_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
c0100f95:	ff 45 fc             	incl   -0x4(%ebp)
c0100f98:	66 c7 45 f4 79 03    	movw   $0x379,-0xc(%ebp)
c0100f9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100fa1:	89 c2                	mov    %eax,%edx
c0100fa3:	ec                   	in     (%dx),%al
c0100fa4:	88 45 f3             	mov    %al,-0xd(%ebp)
    return data;
c0100fa7:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0100fab:	84 c0                	test   %al,%al
c0100fad:	78 09                	js     c0100fb8 <lpt_putc_sub+0x37>
c0100faf:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
c0100fb6:	7e d8                	jle    c0100f90 <lpt_putc_sub+0xf>
        delay();
    }
    outb(LPTPORT + 0, c);
c0100fb8:	8b 45 08             	mov    0x8(%ebp),%eax
c0100fbb:	0f b6 c0             	movzbl %al,%eax
c0100fbe:	66 c7 45 f8 78 03    	movw   $0x378,-0x8(%ebp)
c0100fc4:	88 45 f0             	mov    %al,-0x10(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100fc7:	0f b6 45 f0          	movzbl -0x10(%ebp),%eax
c0100fcb:	8b 55 f8             	mov    -0x8(%ebp),%edx
c0100fce:	ee                   	out    %al,(%dx)
c0100fcf:	66 c7 45 f6 7a 03    	movw   $0x37a,-0xa(%ebp)
c0100fd5:	c6 45 f1 0d          	movb   $0xd,-0xf(%ebp)
c0100fd9:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c0100fdd:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100fe1:	ee                   	out    %al,(%dx)
c0100fe2:	66 c7 45 fa 7a 03    	movw   $0x37a,-0x6(%ebp)
c0100fe8:	c6 45 f2 08          	movb   $0x8,-0xe(%ebp)
c0100fec:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
c0100ff0:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c0100ff4:	ee                   	out    %al,(%dx)
    outb(LPTPORT + 2, 0x08 | 0x04 | 0x01);
    outb(LPTPORT + 2, 0x08);
}
c0100ff5:	90                   	nop
c0100ff6:	c9                   	leave  
c0100ff7:	c3                   	ret    

c0100ff8 <lpt_putc>:

/* lpt_putc - copy console output to parallel port */
static void
lpt_putc(int c) {
c0100ff8:	55                   	push   %ebp
c0100ff9:	89 e5                	mov    %esp,%ebp
c0100ffb:	83 ec 04             	sub    $0x4,%esp
    if (c != '\b') {
c0100ffe:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
c0101002:	74 0d                	je     c0101011 <lpt_putc+0x19>
        lpt_putc_sub(c);
c0101004:	8b 45 08             	mov    0x8(%ebp),%eax
c0101007:	89 04 24             	mov    %eax,(%esp)
c010100a:	e8 72 ff ff ff       	call   c0100f81 <lpt_putc_sub>
    else {
        lpt_putc_sub('\b');
        lpt_putc_sub(' ');
        lpt_putc_sub('\b');
    }
}
c010100f:	eb 24                	jmp    c0101035 <lpt_putc+0x3d>
lpt_putc(int c) {
    if (c != '\b') {
        lpt_putc_sub(c);
    }
    else {
        lpt_putc_sub('\b');
c0101011:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
c0101018:	e8 64 ff ff ff       	call   c0100f81 <lpt_putc_sub>
        lpt_putc_sub(' ');
c010101d:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
c0101024:	e8 58 ff ff ff       	call   c0100f81 <lpt_putc_sub>
        lpt_putc_sub('\b');
c0101029:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
c0101030:	e8 4c ff ff ff       	call   c0100f81 <lpt_putc_sub>
    }
}
c0101035:	90                   	nop
c0101036:	c9                   	leave  
c0101037:	c3                   	ret    

c0101038 <cga_putc>:

/* cga_putc - print character to console */
static void
cga_putc(int c) {
c0101038:	55                   	push   %ebp
c0101039:	89 e5                	mov    %esp,%ebp
c010103b:	53                   	push   %ebx
c010103c:	83 ec 24             	sub    $0x24,%esp
    // set black on white
    if (!(c & ~0xFF)) {
c010103f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101042:	25 00 ff ff ff       	and    $0xffffff00,%eax
c0101047:	85 c0                	test   %eax,%eax
c0101049:	75 07                	jne    c0101052 <cga_putc+0x1a>
        c |= 0x0700;
c010104b:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)
    }

    switch (c & 0xff) {
c0101052:	8b 45 08             	mov    0x8(%ebp),%eax
c0101055:	0f b6 c0             	movzbl %al,%eax
c0101058:	83 f8 0a             	cmp    $0xa,%eax
c010105b:	74 54                	je     c01010b1 <cga_putc+0x79>
c010105d:	83 f8 0d             	cmp    $0xd,%eax
c0101060:	74 62                	je     c01010c4 <cga_putc+0x8c>
c0101062:	83 f8 08             	cmp    $0x8,%eax
c0101065:	0f 85 93 00 00 00    	jne    c01010fe <cga_putc+0xc6>
    case '\b':
        if (crt_pos > 0) {
c010106b:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c0101072:	85 c0                	test   %eax,%eax
c0101074:	0f 84 ae 00 00 00    	je     c0101128 <cga_putc+0xf0>
            crt_pos --;
c010107a:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c0101081:	48                   	dec    %eax
c0101082:	0f b7 c0             	movzwl %ax,%eax
c0101085:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
c010108b:	a1 40 a4 11 c0       	mov    0xc011a440,%eax
c0101090:	0f b7 15 44 a4 11 c0 	movzwl 0xc011a444,%edx
c0101097:	01 d2                	add    %edx,%edx
c0101099:	01 c2                	add    %eax,%edx
c010109b:	8b 45 08             	mov    0x8(%ebp),%eax
c010109e:	98                   	cwtl   
c010109f:	25 00 ff ff ff       	and    $0xffffff00,%eax
c01010a4:	98                   	cwtl   
c01010a5:	83 c8 20             	or     $0x20,%eax
c01010a8:	98                   	cwtl   
c01010a9:	0f b7 c0             	movzwl %ax,%eax
c01010ac:	66 89 02             	mov    %ax,(%edx)
        }
        break;
c01010af:	eb 77                	jmp    c0101128 <cga_putc+0xf0>
    case '\n':
        crt_pos += CRT_COLS;
c01010b1:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c01010b8:	83 c0 50             	add    $0x50,%eax
c01010bb:	0f b7 c0             	movzwl %ax,%eax
c01010be:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
    case '\r':
        crt_pos -= (crt_pos % CRT_COLS);
c01010c4:	0f b7 1d 44 a4 11 c0 	movzwl 0xc011a444,%ebx
c01010cb:	0f b7 0d 44 a4 11 c0 	movzwl 0xc011a444,%ecx
c01010d2:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
c01010d7:	89 c8                	mov    %ecx,%eax
c01010d9:	f7 e2                	mul    %edx
c01010db:	c1 ea 06             	shr    $0x6,%edx
c01010de:	89 d0                	mov    %edx,%eax
c01010e0:	c1 e0 02             	shl    $0x2,%eax
c01010e3:	01 d0                	add    %edx,%eax
c01010e5:	c1 e0 04             	shl    $0x4,%eax
c01010e8:	29 c1                	sub    %eax,%ecx
c01010ea:	89 c8                	mov    %ecx,%eax
c01010ec:	0f b7 c0             	movzwl %ax,%eax
c01010ef:	29 c3                	sub    %eax,%ebx
c01010f1:	89 d8                	mov    %ebx,%eax
c01010f3:	0f b7 c0             	movzwl %ax,%eax
c01010f6:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
        break;
c01010fc:	eb 2b                	jmp    c0101129 <cga_putc+0xf1>
    default:
        crt_buf[crt_pos ++] = c;     // write the character
c01010fe:	8b 0d 40 a4 11 c0    	mov    0xc011a440,%ecx
c0101104:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c010110b:	8d 50 01             	lea    0x1(%eax),%edx
c010110e:	0f b7 d2             	movzwl %dx,%edx
c0101111:	66 89 15 44 a4 11 c0 	mov    %dx,0xc011a444
c0101118:	01 c0                	add    %eax,%eax
c010111a:	8d 14 01             	lea    (%ecx,%eax,1),%edx
c010111d:	8b 45 08             	mov    0x8(%ebp),%eax
c0101120:	0f b7 c0             	movzwl %ax,%eax
c0101123:	66 89 02             	mov    %ax,(%edx)
        break;
c0101126:	eb 01                	jmp    c0101129 <cga_putc+0xf1>
    case '\b':
        if (crt_pos > 0) {
            crt_pos --;
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
        }
        break;
c0101128:	90                   	nop
        crt_buf[crt_pos ++] = c;     // write the character
        break;
    }

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
c0101129:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c0101130:	3d cf 07 00 00       	cmp    $0x7cf,%eax
c0101135:	76 5d                	jbe    c0101194 <cga_putc+0x15c>
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
c0101137:	a1 40 a4 11 c0       	mov    0xc011a440,%eax
c010113c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
c0101142:	a1 40 a4 11 c0       	mov    0xc011a440,%eax
c0101147:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
c010114e:	00 
c010114f:	89 54 24 04          	mov    %edx,0x4(%esp)
c0101153:	89 04 24             	mov    %eax,(%esp)
c0101156:	e8 88 43 00 00       	call   c01054e3 <memmove>
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
c010115b:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
c0101162:	eb 14                	jmp    c0101178 <cga_putc+0x140>
            crt_buf[i] = 0x0700 | ' ';
c0101164:	a1 40 a4 11 c0       	mov    0xc011a440,%eax
c0101169:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010116c:	01 d2                	add    %edx,%edx
c010116e:	01 d0                	add    %edx,%eax
c0101170:	66 c7 00 20 07       	movw   $0x720,(%eax)

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
c0101175:	ff 45 f4             	incl   -0xc(%ebp)
c0101178:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
c010117f:	7e e3                	jle    c0101164 <cga_putc+0x12c>
            crt_buf[i] = 0x0700 | ' ';
        }
        crt_pos -= CRT_COLS;
c0101181:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c0101188:	83 e8 50             	sub    $0x50,%eax
c010118b:	0f b7 c0             	movzwl %ax,%eax
c010118e:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
    }

    // move that little blinky thing
    outb(addr_6845, 14);
c0101194:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c010119b:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
c010119f:	c6 45 e8 0e          	movb   $0xe,-0x18(%ebp)
c01011a3:	0f b6 45 e8          	movzbl -0x18(%ebp),%eax
c01011a7:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c01011ab:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos >> 8);
c01011ac:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c01011b3:	c1 e8 08             	shr    $0x8,%eax
c01011b6:	0f b7 c0             	movzwl %ax,%eax
c01011b9:	0f b6 c0             	movzbl %al,%eax
c01011bc:	0f b7 15 46 a4 11 c0 	movzwl 0xc011a446,%edx
c01011c3:	42                   	inc    %edx
c01011c4:	0f b7 d2             	movzwl %dx,%edx
c01011c7:	66 89 55 f0          	mov    %dx,-0x10(%ebp)
c01011cb:	88 45 e9             	mov    %al,-0x17(%ebp)
c01011ce:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c01011d2:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01011d5:	ee                   	out    %al,(%dx)
    outb(addr_6845, 15);
c01011d6:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c01011dd:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
c01011e1:	c6 45 ea 0f          	movb   $0xf,-0x16(%ebp)
c01011e5:	0f b6 45 ea          	movzbl -0x16(%ebp),%eax
c01011e9:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c01011ed:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos);
c01011ee:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c01011f5:	0f b6 c0             	movzbl %al,%eax
c01011f8:	0f b7 15 46 a4 11 c0 	movzwl 0xc011a446,%edx
c01011ff:	42                   	inc    %edx
c0101200:	0f b7 d2             	movzwl %dx,%edx
c0101203:	66 89 55 ec          	mov    %dx,-0x14(%ebp)
c0101207:	88 45 eb             	mov    %al,-0x15(%ebp)
c010120a:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
c010120e:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0101211:	ee                   	out    %al,(%dx)
}
c0101212:	90                   	nop
c0101213:	83 c4 24             	add    $0x24,%esp
c0101216:	5b                   	pop    %ebx
c0101217:	5d                   	pop    %ebp
c0101218:	c3                   	ret    

c0101219 <serial_putc_sub>:

static void
serial_putc_sub(int c) {
c0101219:	55                   	push   %ebp
c010121a:	89 e5                	mov    %esp,%ebp
c010121c:	83 ec 10             	sub    $0x10,%esp
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
c010121f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c0101226:	eb 08                	jmp    c0101230 <serial_putc_sub+0x17>
        delay();
c0101228:	e8 4c fb ff ff       	call   c0100d79 <delay>
}

static void
serial_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
c010122d:	ff 45 fc             	incl   -0x4(%ebp)
c0101230:	66 c7 45 f8 fd 03    	movw   $0x3fd,-0x8(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0101236:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0101239:	89 c2                	mov    %eax,%edx
c010123b:	ec                   	in     (%dx),%al
c010123c:	88 45 f7             	mov    %al,-0x9(%ebp)
    return data;
c010123f:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
c0101243:	0f b6 c0             	movzbl %al,%eax
c0101246:	83 e0 20             	and    $0x20,%eax
c0101249:	85 c0                	test   %eax,%eax
c010124b:	75 09                	jne    c0101256 <serial_putc_sub+0x3d>
c010124d:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
c0101254:	7e d2                	jle    c0101228 <serial_putc_sub+0xf>
        delay();
    }
    outb(COM1 + COM_TX, c);
c0101256:	8b 45 08             	mov    0x8(%ebp),%eax
c0101259:	0f b6 c0             	movzbl %al,%eax
c010125c:	66 c7 45 fa f8 03    	movw   $0x3f8,-0x6(%ebp)
c0101262:	88 45 f6             	mov    %al,-0xa(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0101265:	0f b6 45 f6          	movzbl -0xa(%ebp),%eax
c0101269:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c010126d:	ee                   	out    %al,(%dx)
}
c010126e:	90                   	nop
c010126f:	c9                   	leave  
c0101270:	c3                   	ret    

c0101271 <serial_putc>:

/* serial_putc - print character to serial port */
static void
serial_putc(int c) {
c0101271:	55                   	push   %ebp
c0101272:	89 e5                	mov    %esp,%ebp
c0101274:	83 ec 04             	sub    $0x4,%esp
    if (c != '\b') {
c0101277:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
c010127b:	74 0d                	je     c010128a <serial_putc+0x19>
        serial_putc_sub(c);
c010127d:	8b 45 08             	mov    0x8(%ebp),%eax
c0101280:	89 04 24             	mov    %eax,(%esp)
c0101283:	e8 91 ff ff ff       	call   c0101219 <serial_putc_sub>
    else {
        serial_putc_sub('\b');
        serial_putc_sub(' ');
        serial_putc_sub('\b');
    }
}
c0101288:	eb 24                	jmp    c01012ae <serial_putc+0x3d>
serial_putc(int c) {
    if (c != '\b') {
        serial_putc_sub(c);
    }
    else {
        serial_putc_sub('\b');
c010128a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
c0101291:	e8 83 ff ff ff       	call   c0101219 <serial_putc_sub>
        serial_putc_sub(' ');
c0101296:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
c010129d:	e8 77 ff ff ff       	call   c0101219 <serial_putc_sub>
        serial_putc_sub('\b');
c01012a2:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
c01012a9:	e8 6b ff ff ff       	call   c0101219 <serial_putc_sub>
    }
}
c01012ae:	90                   	nop
c01012af:	c9                   	leave  
c01012b0:	c3                   	ret    

c01012b1 <cons_intr>:
/* *
 * cons_intr - called by device interrupt routines to feed input
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
c01012b1:	55                   	push   %ebp
c01012b2:	89 e5                	mov    %esp,%ebp
c01012b4:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = (*proc)()) != -1) {
c01012b7:	eb 33                	jmp    c01012ec <cons_intr+0x3b>
        if (c != 0) {
c01012b9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01012bd:	74 2d                	je     c01012ec <cons_intr+0x3b>
            cons.buf[cons.wpos ++] = c;
c01012bf:	a1 64 a6 11 c0       	mov    0xc011a664,%eax
c01012c4:	8d 50 01             	lea    0x1(%eax),%edx
c01012c7:	89 15 64 a6 11 c0    	mov    %edx,0xc011a664
c01012cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01012d0:	88 90 60 a4 11 c0    	mov    %dl,-0x3fee5ba0(%eax)
            if (cons.wpos == CONSBUFSIZE) {
c01012d6:	a1 64 a6 11 c0       	mov    0xc011a664,%eax
c01012db:	3d 00 02 00 00       	cmp    $0x200,%eax
c01012e0:	75 0a                	jne    c01012ec <cons_intr+0x3b>
                cons.wpos = 0;
c01012e2:	c7 05 64 a6 11 c0 00 	movl   $0x0,0xc011a664
c01012e9:	00 00 00 
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
    int c;
    while ((c = (*proc)()) != -1) {
c01012ec:	8b 45 08             	mov    0x8(%ebp),%eax
c01012ef:	ff d0                	call   *%eax
c01012f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01012f4:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
c01012f8:	75 bf                	jne    c01012b9 <cons_intr+0x8>
            if (cons.wpos == CONSBUFSIZE) {
                cons.wpos = 0;
            }
        }
    }
}
c01012fa:	90                   	nop
c01012fb:	c9                   	leave  
c01012fc:	c3                   	ret    

c01012fd <serial_proc_data>:

/* serial_proc_data - get data from serial port */
static int
serial_proc_data(void) {
c01012fd:	55                   	push   %ebp
c01012fe:	89 e5                	mov    %esp,%ebp
c0101300:	83 ec 10             	sub    $0x10,%esp
c0101303:	66 c7 45 f8 fd 03    	movw   $0x3fd,-0x8(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0101309:	8b 45 f8             	mov    -0x8(%ebp),%eax
c010130c:	89 c2                	mov    %eax,%edx
c010130e:	ec                   	in     (%dx),%al
c010130f:	88 45 f7             	mov    %al,-0x9(%ebp)
    return data;
c0101312:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
    if (!(inb(COM1 + COM_LSR) & COM_LSR_DATA)) {
c0101316:	0f b6 c0             	movzbl %al,%eax
c0101319:	83 e0 01             	and    $0x1,%eax
c010131c:	85 c0                	test   %eax,%eax
c010131e:	75 07                	jne    c0101327 <serial_proc_data+0x2a>
        return -1;
c0101320:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c0101325:	eb 2a                	jmp    c0101351 <serial_proc_data+0x54>
c0101327:	66 c7 45 fa f8 03    	movw   $0x3f8,-0x6(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c010132d:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c0101331:	89 c2                	mov    %eax,%edx
c0101333:	ec                   	in     (%dx),%al
c0101334:	88 45 f6             	mov    %al,-0xa(%ebp)
    return data;
c0101337:	0f b6 45 f6          	movzbl -0xa(%ebp),%eax
    }
    int c = inb(COM1 + COM_RX);
c010133b:	0f b6 c0             	movzbl %al,%eax
c010133e:	89 45 fc             	mov    %eax,-0x4(%ebp)
    if (c == 127) {
c0101341:	83 7d fc 7f          	cmpl   $0x7f,-0x4(%ebp)
c0101345:	75 07                	jne    c010134e <serial_proc_data+0x51>
        c = '\b';
c0101347:	c7 45 fc 08 00 00 00 	movl   $0x8,-0x4(%ebp)
    }
    return c;
c010134e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0101351:	c9                   	leave  
c0101352:	c3                   	ret    

c0101353 <serial_intr>:

/* serial_intr - try to feed input characters from serial port */
void
serial_intr(void) {
c0101353:	55                   	push   %ebp
c0101354:	89 e5                	mov    %esp,%ebp
c0101356:	83 ec 18             	sub    $0x18,%esp
    if (serial_exists) {
c0101359:	a1 48 a4 11 c0       	mov    0xc011a448,%eax
c010135e:	85 c0                	test   %eax,%eax
c0101360:	74 0c                	je     c010136e <serial_intr+0x1b>
        cons_intr(serial_proc_data);
c0101362:	c7 04 24 fd 12 10 c0 	movl   $0xc01012fd,(%esp)
c0101369:	e8 43 ff ff ff       	call   c01012b1 <cons_intr>
    }
}
c010136e:	90                   	nop
c010136f:	c9                   	leave  
c0101370:	c3                   	ret    

c0101371 <kbd_proc_data>:
 *
 * The kbd_proc_data() function gets data from the keyboard.
 * If we finish a character, return it, else 0. And return -1 if no data.
 * */
static int
kbd_proc_data(void) {
c0101371:	55                   	push   %ebp
c0101372:	89 e5                	mov    %esp,%ebp
c0101374:	83 ec 28             	sub    $0x28,%esp
c0101377:	66 c7 45 ec 64 00    	movw   $0x64,-0x14(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c010137d:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0101380:	89 c2                	mov    %eax,%edx
c0101382:	ec                   	in     (%dx),%al
c0101383:	88 45 eb             	mov    %al,-0x15(%ebp)
    return data;
c0101386:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
    int c;
    uint8_t data;
    static uint32_t shift;

    if ((inb(KBSTATP) & KBS_DIB) == 0) {
c010138a:	0f b6 c0             	movzbl %al,%eax
c010138d:	83 e0 01             	and    $0x1,%eax
c0101390:	85 c0                	test   %eax,%eax
c0101392:	75 0a                	jne    c010139e <kbd_proc_data+0x2d>
        return -1;
c0101394:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c0101399:	e9 56 01 00 00       	jmp    c01014f4 <kbd_proc_data+0x183>
c010139e:	66 c7 45 f0 60 00    	movw   $0x60,-0x10(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c01013a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01013a7:	89 c2                	mov    %eax,%edx
c01013a9:	ec                   	in     (%dx),%al
c01013aa:	88 45 ea             	mov    %al,-0x16(%ebp)
    return data;
c01013ad:	0f b6 45 ea          	movzbl -0x16(%ebp),%eax
    }

    data = inb(KBDATAP);
c01013b1:	88 45 f3             	mov    %al,-0xd(%ebp)

    if (data == 0xE0) {
c01013b4:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
c01013b8:	75 17                	jne    c01013d1 <kbd_proc_data+0x60>
        // E0 escape character
        shift |= E0ESC;
c01013ba:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c01013bf:	83 c8 40             	or     $0x40,%eax
c01013c2:	a3 68 a6 11 c0       	mov    %eax,0xc011a668
        return 0;
c01013c7:	b8 00 00 00 00       	mov    $0x0,%eax
c01013cc:	e9 23 01 00 00       	jmp    c01014f4 <kbd_proc_data+0x183>
    } else if (data & 0x80) {
c01013d1:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c01013d5:	84 c0                	test   %al,%al
c01013d7:	79 45                	jns    c010141e <kbd_proc_data+0xad>
        // Key released
        data = (shift & E0ESC ? data : data & 0x7F);
c01013d9:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c01013de:	83 e0 40             	and    $0x40,%eax
c01013e1:	85 c0                	test   %eax,%eax
c01013e3:	75 08                	jne    c01013ed <kbd_proc_data+0x7c>
c01013e5:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c01013e9:	24 7f                	and    $0x7f,%al
c01013eb:	eb 04                	jmp    c01013f1 <kbd_proc_data+0x80>
c01013ed:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c01013f1:	88 45 f3             	mov    %al,-0xd(%ebp)
        shift &= ~(shiftcode[data] | E0ESC);
c01013f4:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c01013f8:	0f b6 80 40 70 11 c0 	movzbl -0x3fee8fc0(%eax),%eax
c01013ff:	0c 40                	or     $0x40,%al
c0101401:	0f b6 c0             	movzbl %al,%eax
c0101404:	f7 d0                	not    %eax
c0101406:	89 c2                	mov    %eax,%edx
c0101408:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c010140d:	21 d0                	and    %edx,%eax
c010140f:	a3 68 a6 11 c0       	mov    %eax,0xc011a668
        return 0;
c0101414:	b8 00 00 00 00       	mov    $0x0,%eax
c0101419:	e9 d6 00 00 00       	jmp    c01014f4 <kbd_proc_data+0x183>
    } else if (shift & E0ESC) {
c010141e:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c0101423:	83 e0 40             	and    $0x40,%eax
c0101426:	85 c0                	test   %eax,%eax
c0101428:	74 11                	je     c010143b <kbd_proc_data+0xca>
        // Last character was an E0 escape; or with 0x80
        data |= 0x80;
c010142a:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
        shift &= ~E0ESC;
c010142e:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c0101433:	83 e0 bf             	and    $0xffffffbf,%eax
c0101436:	a3 68 a6 11 c0       	mov    %eax,0xc011a668
    }

    shift |= shiftcode[data];
c010143b:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c010143f:	0f b6 80 40 70 11 c0 	movzbl -0x3fee8fc0(%eax),%eax
c0101446:	0f b6 d0             	movzbl %al,%edx
c0101449:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c010144e:	09 d0                	or     %edx,%eax
c0101450:	a3 68 a6 11 c0       	mov    %eax,0xc011a668
    shift ^= togglecode[data];
c0101455:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101459:	0f b6 80 40 71 11 c0 	movzbl -0x3fee8ec0(%eax),%eax
c0101460:	0f b6 d0             	movzbl %al,%edx
c0101463:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c0101468:	31 d0                	xor    %edx,%eax
c010146a:	a3 68 a6 11 c0       	mov    %eax,0xc011a668

    c = charcode[shift & (CTL | SHIFT)][data];
c010146f:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c0101474:	83 e0 03             	and    $0x3,%eax
c0101477:	8b 14 85 40 75 11 c0 	mov    -0x3fee8ac0(,%eax,4),%edx
c010147e:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101482:	01 d0                	add    %edx,%eax
c0101484:	0f b6 00             	movzbl (%eax),%eax
c0101487:	0f b6 c0             	movzbl %al,%eax
c010148a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (shift & CAPSLOCK) {
c010148d:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c0101492:	83 e0 08             	and    $0x8,%eax
c0101495:	85 c0                	test   %eax,%eax
c0101497:	74 22                	je     c01014bb <kbd_proc_data+0x14a>
        if ('a' <= c && c <= 'z')
c0101499:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
c010149d:	7e 0c                	jle    c01014ab <kbd_proc_data+0x13a>
c010149f:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
c01014a3:	7f 06                	jg     c01014ab <kbd_proc_data+0x13a>
            c += 'A' - 'a';
c01014a5:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
c01014a9:	eb 10                	jmp    c01014bb <kbd_proc_data+0x14a>
        else if ('A' <= c && c <= 'Z')
c01014ab:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
c01014af:	7e 0a                	jle    c01014bb <kbd_proc_data+0x14a>
c01014b1:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
c01014b5:	7f 04                	jg     c01014bb <kbd_proc_data+0x14a>
            c += 'a' - 'A';
c01014b7:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
    }

    // Process special keys
    // Ctrl-Alt-Del: reboot
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
c01014bb:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c01014c0:	f7 d0                	not    %eax
c01014c2:	83 e0 06             	and    $0x6,%eax
c01014c5:	85 c0                	test   %eax,%eax
c01014c7:	75 28                	jne    c01014f1 <kbd_proc_data+0x180>
c01014c9:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
c01014d0:	75 1f                	jne    c01014f1 <kbd_proc_data+0x180>
        cprintf("Rebooting!\n");
c01014d2:	c7 04 24 a5 5f 10 c0 	movl   $0xc0105fa5,(%esp)
c01014d9:	e8 b4 ed ff ff       	call   c0100292 <cprintf>
c01014de:	66 c7 45 ee 92 00    	movw   $0x92,-0x12(%ebp)
c01014e4:	c6 45 e9 03          	movb   $0x3,-0x17(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c01014e8:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c01014ec:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c01014f0:	ee                   	out    %al,(%dx)
        outb(0x92, 0x3); // courtesy of Chris Frost
    }
    return c;
c01014f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01014f4:	c9                   	leave  
c01014f5:	c3                   	ret    

c01014f6 <kbd_intr>:

/* kbd_intr - try to feed input characters from keyboard */
static void
kbd_intr(void) {
c01014f6:	55                   	push   %ebp
c01014f7:	89 e5                	mov    %esp,%ebp
c01014f9:	83 ec 18             	sub    $0x18,%esp
    cons_intr(kbd_proc_data);
c01014fc:	c7 04 24 71 13 10 c0 	movl   $0xc0101371,(%esp)
c0101503:	e8 a9 fd ff ff       	call   c01012b1 <cons_intr>
}
c0101508:	90                   	nop
c0101509:	c9                   	leave  
c010150a:	c3                   	ret    

c010150b <kbd_init>:

static void
kbd_init(void) {
c010150b:	55                   	push   %ebp
c010150c:	89 e5                	mov    %esp,%ebp
c010150e:	83 ec 18             	sub    $0x18,%esp
    // drain the kbd buffer
    kbd_intr();
c0101511:	e8 e0 ff ff ff       	call   c01014f6 <kbd_intr>
    pic_enable(IRQ_KBD);
c0101516:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010151d:	e8 34 01 00 00       	call   c0101656 <pic_enable>
}
c0101522:	90                   	nop
c0101523:	c9                   	leave  
c0101524:	c3                   	ret    

c0101525 <cons_init>:

/* cons_init - initializes the console devices */
void
cons_init(void) {
c0101525:	55                   	push   %ebp
c0101526:	89 e5                	mov    %esp,%ebp
c0101528:	83 ec 18             	sub    $0x18,%esp
    cga_init();
c010152b:	e8 90 f8 ff ff       	call   c0100dc0 <cga_init>
    serial_init();
c0101530:	e8 6d f9 ff ff       	call   c0100ea2 <serial_init>
    kbd_init();
c0101535:	e8 d1 ff ff ff       	call   c010150b <kbd_init>
    if (!serial_exists) {
c010153a:	a1 48 a4 11 c0       	mov    0xc011a448,%eax
c010153f:	85 c0                	test   %eax,%eax
c0101541:	75 0c                	jne    c010154f <cons_init+0x2a>
        cprintf("serial port does not exist!!\n");
c0101543:	c7 04 24 b1 5f 10 c0 	movl   $0xc0105fb1,(%esp)
c010154a:	e8 43 ed ff ff       	call   c0100292 <cprintf>
    }
}
c010154f:	90                   	nop
c0101550:	c9                   	leave  
c0101551:	c3                   	ret    

c0101552 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void
cons_putc(int c) {
c0101552:	55                   	push   %ebp
c0101553:	89 e5                	mov    %esp,%ebp
c0101555:	83 ec 28             	sub    $0x28,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
c0101558:	e8 de f7 ff ff       	call   c0100d3b <__intr_save>
c010155d:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        lpt_putc(c);
c0101560:	8b 45 08             	mov    0x8(%ebp),%eax
c0101563:	89 04 24             	mov    %eax,(%esp)
c0101566:	e8 8d fa ff ff       	call   c0100ff8 <lpt_putc>
        cga_putc(c);
c010156b:	8b 45 08             	mov    0x8(%ebp),%eax
c010156e:	89 04 24             	mov    %eax,(%esp)
c0101571:	e8 c2 fa ff ff       	call   c0101038 <cga_putc>
        serial_putc(c);
c0101576:	8b 45 08             	mov    0x8(%ebp),%eax
c0101579:	89 04 24             	mov    %eax,(%esp)
c010157c:	e8 f0 fc ff ff       	call   c0101271 <serial_putc>
    }
    local_intr_restore(intr_flag);
c0101581:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101584:	89 04 24             	mov    %eax,(%esp)
c0101587:	e8 d9 f7 ff ff       	call   c0100d65 <__intr_restore>
}
c010158c:	90                   	nop
c010158d:	c9                   	leave  
c010158e:	c3                   	ret    

c010158f <cons_getc>:
/* *
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int
cons_getc(void) {
c010158f:	55                   	push   %ebp
c0101590:	89 e5                	mov    %esp,%ebp
c0101592:	83 ec 28             	sub    $0x28,%esp
    int c = 0;
c0101595:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
c010159c:	e8 9a f7 ff ff       	call   c0100d3b <__intr_save>
c01015a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        // poll for any pending input characters,
        // so that this function works even when interrupts are disabled
        // (e.g., when called from the kernel monitor).
        serial_intr();
c01015a4:	e8 aa fd ff ff       	call   c0101353 <serial_intr>
        kbd_intr();
c01015a9:	e8 48 ff ff ff       	call   c01014f6 <kbd_intr>

        // grab the next character from the input buffer.
        if (cons.rpos != cons.wpos) {
c01015ae:	8b 15 60 a6 11 c0    	mov    0xc011a660,%edx
c01015b4:	a1 64 a6 11 c0       	mov    0xc011a664,%eax
c01015b9:	39 c2                	cmp    %eax,%edx
c01015bb:	74 31                	je     c01015ee <cons_getc+0x5f>
            c = cons.buf[cons.rpos ++];
c01015bd:	a1 60 a6 11 c0       	mov    0xc011a660,%eax
c01015c2:	8d 50 01             	lea    0x1(%eax),%edx
c01015c5:	89 15 60 a6 11 c0    	mov    %edx,0xc011a660
c01015cb:	0f b6 80 60 a4 11 c0 	movzbl -0x3fee5ba0(%eax),%eax
c01015d2:	0f b6 c0             	movzbl %al,%eax
c01015d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
            if (cons.rpos == CONSBUFSIZE) {
c01015d8:	a1 60 a6 11 c0       	mov    0xc011a660,%eax
c01015dd:	3d 00 02 00 00       	cmp    $0x200,%eax
c01015e2:	75 0a                	jne    c01015ee <cons_getc+0x5f>
                cons.rpos = 0;
c01015e4:	c7 05 60 a6 11 c0 00 	movl   $0x0,0xc011a660
c01015eb:	00 00 00 
            }
        }
    }
    local_intr_restore(intr_flag);
c01015ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01015f1:	89 04 24             	mov    %eax,(%esp)
c01015f4:	e8 6c f7 ff ff       	call   c0100d65 <__intr_restore>
    return c;
c01015f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01015fc:	c9                   	leave  
c01015fd:	c3                   	ret    

c01015fe <pic_setmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static uint16_t irq_mask = 0xFFFF & ~(1 << IRQ_SLAVE);
static bool did_init = 0;

static void
pic_setmask(uint16_t mask) {
c01015fe:	55                   	push   %ebp
c01015ff:	89 e5                	mov    %esp,%ebp
c0101601:	83 ec 14             	sub    $0x14,%esp
c0101604:	8b 45 08             	mov    0x8(%ebp),%eax
c0101607:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
    irq_mask = mask;
c010160b:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010160e:	66 a3 50 75 11 c0    	mov    %ax,0xc0117550
    if (did_init) {
c0101614:	a1 6c a6 11 c0       	mov    0xc011a66c,%eax
c0101619:	85 c0                	test   %eax,%eax
c010161b:	74 36                	je     c0101653 <pic_setmask+0x55>
        outb(IO_PIC1 + 1, mask);
c010161d:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0101620:	0f b6 c0             	movzbl %al,%eax
c0101623:	66 c7 45 fe 21 00    	movw   $0x21,-0x2(%ebp)
c0101629:	88 45 fa             	mov    %al,-0x6(%ebp)
c010162c:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
c0101630:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
c0101634:	ee                   	out    %al,(%dx)
        outb(IO_PIC2 + 1, mask >> 8);
c0101635:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
c0101639:	c1 e8 08             	shr    $0x8,%eax
c010163c:	0f b7 c0             	movzwl %ax,%eax
c010163f:	0f b6 c0             	movzbl %al,%eax
c0101642:	66 c7 45 fc a1 00    	movw   $0xa1,-0x4(%ebp)
c0101648:	88 45 fb             	mov    %al,-0x5(%ebp)
c010164b:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
c010164f:	8b 55 fc             	mov    -0x4(%ebp),%edx
c0101652:	ee                   	out    %al,(%dx)
    }
}
c0101653:	90                   	nop
c0101654:	c9                   	leave  
c0101655:	c3                   	ret    

c0101656 <pic_enable>:

void
pic_enable(unsigned int irq) {
c0101656:	55                   	push   %ebp
c0101657:	89 e5                	mov    %esp,%ebp
c0101659:	83 ec 04             	sub    $0x4,%esp
    pic_setmask(irq_mask & ~(1 << irq));
c010165c:	8b 45 08             	mov    0x8(%ebp),%eax
c010165f:	ba 01 00 00 00       	mov    $0x1,%edx
c0101664:	88 c1                	mov    %al,%cl
c0101666:	d3 e2                	shl    %cl,%edx
c0101668:	89 d0                	mov    %edx,%eax
c010166a:	98                   	cwtl   
c010166b:	f7 d0                	not    %eax
c010166d:	0f bf d0             	movswl %ax,%edx
c0101670:	0f b7 05 50 75 11 c0 	movzwl 0xc0117550,%eax
c0101677:	98                   	cwtl   
c0101678:	21 d0                	and    %edx,%eax
c010167a:	98                   	cwtl   
c010167b:	0f b7 c0             	movzwl %ax,%eax
c010167e:	89 04 24             	mov    %eax,(%esp)
c0101681:	e8 78 ff ff ff       	call   c01015fe <pic_setmask>
}
c0101686:	90                   	nop
c0101687:	c9                   	leave  
c0101688:	c3                   	ret    

c0101689 <pic_init>:

/* pic_init - initialize the 8259A interrupt controllers */
void
pic_init(void) {
c0101689:	55                   	push   %ebp
c010168a:	89 e5                	mov    %esp,%ebp
c010168c:	83 ec 34             	sub    $0x34,%esp
    did_init = 1;
c010168f:	c7 05 6c a6 11 c0 01 	movl   $0x1,0xc011a66c
c0101696:	00 00 00 
c0101699:	66 c7 45 fe 21 00    	movw   $0x21,-0x2(%ebp)
c010169f:	c6 45 d6 ff          	movb   $0xff,-0x2a(%ebp)
c01016a3:	0f b6 45 d6          	movzbl -0x2a(%ebp),%eax
c01016a7:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
c01016ab:	ee                   	out    %al,(%dx)
c01016ac:	66 c7 45 fc a1 00    	movw   $0xa1,-0x4(%ebp)
c01016b2:	c6 45 d7 ff          	movb   $0xff,-0x29(%ebp)
c01016b6:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
c01016ba:	8b 55 fc             	mov    -0x4(%ebp),%edx
c01016bd:	ee                   	out    %al,(%dx)
c01016be:	66 c7 45 fa 20 00    	movw   $0x20,-0x6(%ebp)
c01016c4:	c6 45 d8 11          	movb   $0x11,-0x28(%ebp)
c01016c8:	0f b6 45 d8          	movzbl -0x28(%ebp),%eax
c01016cc:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c01016d0:	ee                   	out    %al,(%dx)
c01016d1:	66 c7 45 f8 21 00    	movw   $0x21,-0x8(%ebp)
c01016d7:	c6 45 d9 20          	movb   $0x20,-0x27(%ebp)
c01016db:	0f b6 45 d9          	movzbl -0x27(%ebp),%eax
c01016df:	8b 55 f8             	mov    -0x8(%ebp),%edx
c01016e2:	ee                   	out    %al,(%dx)
c01016e3:	66 c7 45 f6 21 00    	movw   $0x21,-0xa(%ebp)
c01016e9:	c6 45 da 04          	movb   $0x4,-0x26(%ebp)
c01016ed:	0f b6 45 da          	movzbl -0x26(%ebp),%eax
c01016f1:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c01016f5:	ee                   	out    %al,(%dx)
c01016f6:	66 c7 45 f4 21 00    	movw   $0x21,-0xc(%ebp)
c01016fc:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
c0101700:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
c0101704:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0101707:	ee                   	out    %al,(%dx)
c0101708:	66 c7 45 f2 a0 00    	movw   $0xa0,-0xe(%ebp)
c010170e:	c6 45 dc 11          	movb   $0x11,-0x24(%ebp)
c0101712:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
c0101716:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c010171a:	ee                   	out    %al,(%dx)
c010171b:	66 c7 45 f0 a1 00    	movw   $0xa1,-0x10(%ebp)
c0101721:	c6 45 dd 28          	movb   $0x28,-0x23(%ebp)
c0101725:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
c0101729:	8b 55 f0             	mov    -0x10(%ebp),%edx
c010172c:	ee                   	out    %al,(%dx)
c010172d:	66 c7 45 ee a1 00    	movw   $0xa1,-0x12(%ebp)
c0101733:	c6 45 de 02          	movb   $0x2,-0x22(%ebp)
c0101737:	0f b6 45 de          	movzbl -0x22(%ebp),%eax
c010173b:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c010173f:	ee                   	out    %al,(%dx)
c0101740:	66 c7 45 ec a1 00    	movw   $0xa1,-0x14(%ebp)
c0101746:	c6 45 df 03          	movb   $0x3,-0x21(%ebp)
c010174a:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
c010174e:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0101751:	ee                   	out    %al,(%dx)
c0101752:	66 c7 45 ea 20 00    	movw   $0x20,-0x16(%ebp)
c0101758:	c6 45 e0 68          	movb   $0x68,-0x20(%ebp)
c010175c:	0f b6 45 e0          	movzbl -0x20(%ebp),%eax
c0101760:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c0101764:	ee                   	out    %al,(%dx)
c0101765:	66 c7 45 e8 20 00    	movw   $0x20,-0x18(%ebp)
c010176b:	c6 45 e1 0a          	movb   $0xa,-0x1f(%ebp)
c010176f:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
c0101773:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0101776:	ee                   	out    %al,(%dx)
c0101777:	66 c7 45 e6 a0 00    	movw   $0xa0,-0x1a(%ebp)
c010177d:	c6 45 e2 68          	movb   $0x68,-0x1e(%ebp)
c0101781:	0f b6 45 e2          	movzbl -0x1e(%ebp),%eax
c0101785:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
c0101789:	ee                   	out    %al,(%dx)
c010178a:	66 c7 45 e4 a0 00    	movw   $0xa0,-0x1c(%ebp)
c0101790:	c6 45 e3 0a          	movb   $0xa,-0x1d(%ebp)
c0101794:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
c0101798:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c010179b:	ee                   	out    %al,(%dx)
    outb(IO_PIC1, 0x0a);    // read IRR by default

    outb(IO_PIC2, 0x68);    // OCW3
    outb(IO_PIC2, 0x0a);    // OCW3

    if (irq_mask != 0xFFFF) {
c010179c:	0f b7 05 50 75 11 c0 	movzwl 0xc0117550,%eax
c01017a3:	3d ff ff 00 00       	cmp    $0xffff,%eax
c01017a8:	74 0f                	je     c01017b9 <pic_init+0x130>
        pic_setmask(irq_mask);
c01017aa:	0f b7 05 50 75 11 c0 	movzwl 0xc0117550,%eax
c01017b1:	89 04 24             	mov    %eax,(%esp)
c01017b4:	e8 45 fe ff ff       	call   c01015fe <pic_setmask>
    }
}
c01017b9:	90                   	nop
c01017ba:	c9                   	leave  
c01017bb:	c3                   	ret    

c01017bc <intr_enable>:
#include <x86.h>
#include <intr.h>

/* intr_enable - enable irq interrupt */
void
intr_enable(void) {
c01017bc:	55                   	push   %ebp
c01017bd:	89 e5                	mov    %esp,%ebp
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
}

static inline void
sti(void) {
    asm volatile ("sti");
c01017bf:	fb                   	sti    
    sti();
}
c01017c0:	90                   	nop
c01017c1:	5d                   	pop    %ebp
c01017c2:	c3                   	ret    

c01017c3 <intr_disable>:

/* intr_disable - disable irq interrupt */
void
intr_disable(void) {
c01017c3:	55                   	push   %ebp
c01017c4:	89 e5                	mov    %esp,%ebp
}

static inline void
cli(void) {
    asm volatile ("cli" ::: "memory");
c01017c6:	fa                   	cli    
    cli();
}
c01017c7:	90                   	nop
c01017c8:	5d                   	pop    %ebp
c01017c9:	c3                   	ret    

c01017ca <print_ticks>:
#include <console.h>
#include <kdebug.h>

#define TICK_NUM 100

static void print_ticks() {
c01017ca:	55                   	push   %ebp
c01017cb:	89 e5                	mov    %esp,%ebp
c01017cd:	83 ec 18             	sub    $0x18,%esp
    cprintf("%d ticks\n",TICK_NUM);
c01017d0:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
c01017d7:	00 
c01017d8:	c7 04 24 e0 5f 10 c0 	movl   $0xc0105fe0,(%esp)
c01017df:	e8 ae ea ff ff       	call   c0100292 <cprintf>
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}
c01017e4:	90                   	nop
c01017e5:	c9                   	leave  
c01017e6:	c3                   	ret    

c01017e7 <idt_init>:
    sizeof(idt) - 1, (uintptr_t)idt
};

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S */
void
idt_init(void) {
c01017e7:	55                   	push   %ebp
c01017e8:	89 e5                	mov    %esp,%ebp
      *     Can you see idt[256] in this file? Yes, it's IDT! you can use SETGATE macro to setup each item of IDT
      * (3) After setup the contents of IDT, you will let CPU know where is the IDT by using 'lidt' instruction.
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
}
c01017ea:	90                   	nop
c01017eb:	5d                   	pop    %ebp
c01017ec:	c3                   	ret    

c01017ed <trapname>:

static const char *
trapname(int trapno) {
c01017ed:	55                   	push   %ebp
c01017ee:	89 e5                	mov    %esp,%ebp
        "Alignment Check",
        "Machine-Check",
        "SIMD Floating-Point Exception"
    };

    if (trapno < sizeof(excnames)/sizeof(const char * const)) {
c01017f0:	8b 45 08             	mov    0x8(%ebp),%eax
c01017f3:	83 f8 13             	cmp    $0x13,%eax
c01017f6:	77 0c                	ja     c0101804 <trapname+0x17>
        return excnames[trapno];
c01017f8:	8b 45 08             	mov    0x8(%ebp),%eax
c01017fb:	8b 04 85 40 63 10 c0 	mov    -0x3fef9cc0(,%eax,4),%eax
c0101802:	eb 18                	jmp    c010181c <trapname+0x2f>
    }
    if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16) {
c0101804:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
c0101808:	7e 0d                	jle    c0101817 <trapname+0x2a>
c010180a:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
c010180e:	7f 07                	jg     c0101817 <trapname+0x2a>
        return "Hardware Interrupt";
c0101810:	b8 ea 5f 10 c0       	mov    $0xc0105fea,%eax
c0101815:	eb 05                	jmp    c010181c <trapname+0x2f>
    }
    return "(unknown trap)";
c0101817:	b8 fd 5f 10 c0       	mov    $0xc0105ffd,%eax
}
c010181c:	5d                   	pop    %ebp
c010181d:	c3                   	ret    

c010181e <trap_in_kernel>:

/* trap_in_kernel - test if trap happened in kernel */
bool
trap_in_kernel(struct trapframe *tf) {
c010181e:	55                   	push   %ebp
c010181f:	89 e5                	mov    %esp,%ebp
    return (tf->tf_cs == (uint16_t)KERNEL_CS);
c0101821:	8b 45 08             	mov    0x8(%ebp),%eax
c0101824:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101828:	83 f8 08             	cmp    $0x8,%eax
c010182b:	0f 94 c0             	sete   %al
c010182e:	0f b6 c0             	movzbl %al,%eax
}
c0101831:	5d                   	pop    %ebp
c0101832:	c3                   	ret    

c0101833 <print_trapframe>:
    "TF", "IF", "DF", "OF", NULL, NULL, "NT", NULL,
    "RF", "VM", "AC", "VIF", "VIP", "ID", NULL, NULL,
};

void
print_trapframe(struct trapframe *tf) {
c0101833:	55                   	push   %ebp
c0101834:	89 e5                	mov    %esp,%ebp
c0101836:	83 ec 28             	sub    $0x28,%esp
    cprintf("trapframe at %p\n", tf);
c0101839:	8b 45 08             	mov    0x8(%ebp),%eax
c010183c:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101840:	c7 04 24 3e 60 10 c0 	movl   $0xc010603e,(%esp)
c0101847:	e8 46 ea ff ff       	call   c0100292 <cprintf>
    print_regs(&tf->tf_regs);
c010184c:	8b 45 08             	mov    0x8(%ebp),%eax
c010184f:	89 04 24             	mov    %eax,(%esp)
c0101852:	e8 91 01 00 00       	call   c01019e8 <print_regs>
    cprintf("  ds   0x----%04x\n", tf->tf_ds);
c0101857:	8b 45 08             	mov    0x8(%ebp),%eax
c010185a:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
c010185e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101862:	c7 04 24 4f 60 10 c0 	movl   $0xc010604f,(%esp)
c0101869:	e8 24 ea ff ff       	call   c0100292 <cprintf>
    cprintf("  es   0x----%04x\n", tf->tf_es);
c010186e:	8b 45 08             	mov    0x8(%ebp),%eax
c0101871:	0f b7 40 28          	movzwl 0x28(%eax),%eax
c0101875:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101879:	c7 04 24 62 60 10 c0 	movl   $0xc0106062,(%esp)
c0101880:	e8 0d ea ff ff       	call   c0100292 <cprintf>
    cprintf("  fs   0x----%04x\n", tf->tf_fs);
c0101885:	8b 45 08             	mov    0x8(%ebp),%eax
c0101888:	0f b7 40 24          	movzwl 0x24(%eax),%eax
c010188c:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101890:	c7 04 24 75 60 10 c0 	movl   $0xc0106075,(%esp)
c0101897:	e8 f6 e9 ff ff       	call   c0100292 <cprintf>
    cprintf("  gs   0x----%04x\n", tf->tf_gs);
c010189c:	8b 45 08             	mov    0x8(%ebp),%eax
c010189f:	0f b7 40 20          	movzwl 0x20(%eax),%eax
c01018a3:	89 44 24 04          	mov    %eax,0x4(%esp)
c01018a7:	c7 04 24 88 60 10 c0 	movl   $0xc0106088,(%esp)
c01018ae:	e8 df e9 ff ff       	call   c0100292 <cprintf>
    cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
c01018b3:	8b 45 08             	mov    0x8(%ebp),%eax
c01018b6:	8b 40 30             	mov    0x30(%eax),%eax
c01018b9:	89 04 24             	mov    %eax,(%esp)
c01018bc:	e8 2c ff ff ff       	call   c01017ed <trapname>
c01018c1:	89 c2                	mov    %eax,%edx
c01018c3:	8b 45 08             	mov    0x8(%ebp),%eax
c01018c6:	8b 40 30             	mov    0x30(%eax),%eax
c01018c9:	89 54 24 08          	mov    %edx,0x8(%esp)
c01018cd:	89 44 24 04          	mov    %eax,0x4(%esp)
c01018d1:	c7 04 24 9b 60 10 c0 	movl   $0xc010609b,(%esp)
c01018d8:	e8 b5 e9 ff ff       	call   c0100292 <cprintf>
    cprintf("  err  0x%08x\n", tf->tf_err);
c01018dd:	8b 45 08             	mov    0x8(%ebp),%eax
c01018e0:	8b 40 34             	mov    0x34(%eax),%eax
c01018e3:	89 44 24 04          	mov    %eax,0x4(%esp)
c01018e7:	c7 04 24 ad 60 10 c0 	movl   $0xc01060ad,(%esp)
c01018ee:	e8 9f e9 ff ff       	call   c0100292 <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
c01018f3:	8b 45 08             	mov    0x8(%ebp),%eax
c01018f6:	8b 40 38             	mov    0x38(%eax),%eax
c01018f9:	89 44 24 04          	mov    %eax,0x4(%esp)
c01018fd:	c7 04 24 bc 60 10 c0 	movl   $0xc01060bc,(%esp)
c0101904:	e8 89 e9 ff ff       	call   c0100292 <cprintf>
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
c0101909:	8b 45 08             	mov    0x8(%ebp),%eax
c010190c:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101910:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101914:	c7 04 24 cb 60 10 c0 	movl   $0xc01060cb,(%esp)
c010191b:	e8 72 e9 ff ff       	call   c0100292 <cprintf>
    cprintf("  flag 0x%08x ", tf->tf_eflags);
c0101920:	8b 45 08             	mov    0x8(%ebp),%eax
c0101923:	8b 40 40             	mov    0x40(%eax),%eax
c0101926:	89 44 24 04          	mov    %eax,0x4(%esp)
c010192a:	c7 04 24 de 60 10 c0 	movl   $0xc01060de,(%esp)
c0101931:	e8 5c e9 ff ff       	call   c0100292 <cprintf>

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
c0101936:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c010193d:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
c0101944:	eb 3d                	jmp    c0101983 <print_trapframe+0x150>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
c0101946:	8b 45 08             	mov    0x8(%ebp),%eax
c0101949:	8b 50 40             	mov    0x40(%eax),%edx
c010194c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010194f:	21 d0                	and    %edx,%eax
c0101951:	85 c0                	test   %eax,%eax
c0101953:	74 28                	je     c010197d <print_trapframe+0x14a>
c0101955:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101958:	8b 04 85 80 75 11 c0 	mov    -0x3fee8a80(,%eax,4),%eax
c010195f:	85 c0                	test   %eax,%eax
c0101961:	74 1a                	je     c010197d <print_trapframe+0x14a>
            cprintf("%s,", IA32flags[i]);
c0101963:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101966:	8b 04 85 80 75 11 c0 	mov    -0x3fee8a80(,%eax,4),%eax
c010196d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101971:	c7 04 24 ed 60 10 c0 	movl   $0xc01060ed,(%esp)
c0101978:	e8 15 e9 ff ff       	call   c0100292 <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
    cprintf("  flag 0x%08x ", tf->tf_eflags);

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
c010197d:	ff 45 f4             	incl   -0xc(%ebp)
c0101980:	d1 65 f0             	shll   -0x10(%ebp)
c0101983:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101986:	83 f8 17             	cmp    $0x17,%eax
c0101989:	76 bb                	jbe    c0101946 <print_trapframe+0x113>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
            cprintf("%s,", IA32flags[i]);
        }
    }
    cprintf("IOPL=%d\n", (tf->tf_eflags & FL_IOPL_MASK) >> 12);
c010198b:	8b 45 08             	mov    0x8(%ebp),%eax
c010198e:	8b 40 40             	mov    0x40(%eax),%eax
c0101991:	25 00 30 00 00       	and    $0x3000,%eax
c0101996:	c1 e8 0c             	shr    $0xc,%eax
c0101999:	89 44 24 04          	mov    %eax,0x4(%esp)
c010199d:	c7 04 24 f1 60 10 c0 	movl   $0xc01060f1,(%esp)
c01019a4:	e8 e9 e8 ff ff       	call   c0100292 <cprintf>

    if (!trap_in_kernel(tf)) {
c01019a9:	8b 45 08             	mov    0x8(%ebp),%eax
c01019ac:	89 04 24             	mov    %eax,(%esp)
c01019af:	e8 6a fe ff ff       	call   c010181e <trap_in_kernel>
c01019b4:	85 c0                	test   %eax,%eax
c01019b6:	75 2d                	jne    c01019e5 <print_trapframe+0x1b2>
        cprintf("  esp  0x%08x\n", tf->tf_esp);
c01019b8:	8b 45 08             	mov    0x8(%ebp),%eax
c01019bb:	8b 40 44             	mov    0x44(%eax),%eax
c01019be:	89 44 24 04          	mov    %eax,0x4(%esp)
c01019c2:	c7 04 24 fa 60 10 c0 	movl   $0xc01060fa,(%esp)
c01019c9:	e8 c4 e8 ff ff       	call   c0100292 <cprintf>
        cprintf("  ss   0x----%04x\n", tf->tf_ss);
c01019ce:	8b 45 08             	mov    0x8(%ebp),%eax
c01019d1:	0f b7 40 48          	movzwl 0x48(%eax),%eax
c01019d5:	89 44 24 04          	mov    %eax,0x4(%esp)
c01019d9:	c7 04 24 09 61 10 c0 	movl   $0xc0106109,(%esp)
c01019e0:	e8 ad e8 ff ff       	call   c0100292 <cprintf>
    }
}
c01019e5:	90                   	nop
c01019e6:	c9                   	leave  
c01019e7:	c3                   	ret    

c01019e8 <print_regs>:

void
print_regs(struct pushregs *regs) {
c01019e8:	55                   	push   %ebp
c01019e9:	89 e5                	mov    %esp,%ebp
c01019eb:	83 ec 18             	sub    $0x18,%esp
    cprintf("  edi  0x%08x\n", regs->reg_edi);
c01019ee:	8b 45 08             	mov    0x8(%ebp),%eax
c01019f1:	8b 00                	mov    (%eax),%eax
c01019f3:	89 44 24 04          	mov    %eax,0x4(%esp)
c01019f7:	c7 04 24 1c 61 10 c0 	movl   $0xc010611c,(%esp)
c01019fe:	e8 8f e8 ff ff       	call   c0100292 <cprintf>
    cprintf("  esi  0x%08x\n", regs->reg_esi);
c0101a03:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a06:	8b 40 04             	mov    0x4(%eax),%eax
c0101a09:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101a0d:	c7 04 24 2b 61 10 c0 	movl   $0xc010612b,(%esp)
c0101a14:	e8 79 e8 ff ff       	call   c0100292 <cprintf>
    cprintf("  ebp  0x%08x\n", regs->reg_ebp);
c0101a19:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a1c:	8b 40 08             	mov    0x8(%eax),%eax
c0101a1f:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101a23:	c7 04 24 3a 61 10 c0 	movl   $0xc010613a,(%esp)
c0101a2a:	e8 63 e8 ff ff       	call   c0100292 <cprintf>
    cprintf("  oesp 0x%08x\n", regs->reg_oesp);
c0101a2f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a32:	8b 40 0c             	mov    0xc(%eax),%eax
c0101a35:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101a39:	c7 04 24 49 61 10 c0 	movl   $0xc0106149,(%esp)
c0101a40:	e8 4d e8 ff ff       	call   c0100292 <cprintf>
    cprintf("  ebx  0x%08x\n", regs->reg_ebx);
c0101a45:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a48:	8b 40 10             	mov    0x10(%eax),%eax
c0101a4b:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101a4f:	c7 04 24 58 61 10 c0 	movl   $0xc0106158,(%esp)
c0101a56:	e8 37 e8 ff ff       	call   c0100292 <cprintf>
    cprintf("  edx  0x%08x\n", regs->reg_edx);
c0101a5b:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a5e:	8b 40 14             	mov    0x14(%eax),%eax
c0101a61:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101a65:	c7 04 24 67 61 10 c0 	movl   $0xc0106167,(%esp)
c0101a6c:	e8 21 e8 ff ff       	call   c0100292 <cprintf>
    cprintf("  ecx  0x%08x\n", regs->reg_ecx);
c0101a71:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a74:	8b 40 18             	mov    0x18(%eax),%eax
c0101a77:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101a7b:	c7 04 24 76 61 10 c0 	movl   $0xc0106176,(%esp)
c0101a82:	e8 0b e8 ff ff       	call   c0100292 <cprintf>
    cprintf("  eax  0x%08x\n", regs->reg_eax);
c0101a87:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a8a:	8b 40 1c             	mov    0x1c(%eax),%eax
c0101a8d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101a91:	c7 04 24 85 61 10 c0 	movl   $0xc0106185,(%esp)
c0101a98:	e8 f5 e7 ff ff       	call   c0100292 <cprintf>
}
c0101a9d:	90                   	nop
c0101a9e:	c9                   	leave  
c0101a9f:	c3                   	ret    

c0101aa0 <trap_dispatch>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static void
trap_dispatch(struct trapframe *tf) {
c0101aa0:	55                   	push   %ebp
c0101aa1:	89 e5                	mov    %esp,%ebp
c0101aa3:	83 ec 28             	sub    $0x28,%esp
    char c;

    switch (tf->tf_trapno) {
c0101aa6:	8b 45 08             	mov    0x8(%ebp),%eax
c0101aa9:	8b 40 30             	mov    0x30(%eax),%eax
c0101aac:	83 f8 2f             	cmp    $0x2f,%eax
c0101aaf:	77 1e                	ja     c0101acf <trap_dispatch+0x2f>
c0101ab1:	83 f8 2e             	cmp    $0x2e,%eax
c0101ab4:	0f 83 bc 00 00 00    	jae    c0101b76 <trap_dispatch+0xd6>
c0101aba:	83 f8 21             	cmp    $0x21,%eax
c0101abd:	74 40                	je     c0101aff <trap_dispatch+0x5f>
c0101abf:	83 f8 24             	cmp    $0x24,%eax
c0101ac2:	74 15                	je     c0101ad9 <trap_dispatch+0x39>
c0101ac4:	83 f8 20             	cmp    $0x20,%eax
c0101ac7:	0f 84 ac 00 00 00    	je     c0101b79 <trap_dispatch+0xd9>
c0101acd:	eb 72                	jmp    c0101b41 <trap_dispatch+0xa1>
c0101acf:	83 e8 78             	sub    $0x78,%eax
c0101ad2:	83 f8 01             	cmp    $0x1,%eax
c0101ad5:	77 6a                	ja     c0101b41 <trap_dispatch+0xa1>
c0101ad7:	eb 4c                	jmp    c0101b25 <trap_dispatch+0x85>
         * (2) Every TICK_NUM cycle, you can print some info using a funciton, such as print_ticks().
         * (3) Too Simple? Yes, I think so!
         */
        break;
    case IRQ_OFFSET + IRQ_COM1:
        c = cons_getc();
c0101ad9:	e8 b1 fa ff ff       	call   c010158f <cons_getc>
c0101ade:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("serial [%03d] %c\n", c, c);
c0101ae1:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
c0101ae5:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c0101ae9:	89 54 24 08          	mov    %edx,0x8(%esp)
c0101aed:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101af1:	c7 04 24 94 61 10 c0 	movl   $0xc0106194,(%esp)
c0101af8:	e8 95 e7 ff ff       	call   c0100292 <cprintf>
        break;
c0101afd:	eb 7b                	jmp    c0101b7a <trap_dispatch+0xda>
    case IRQ_OFFSET + IRQ_KBD:
        c = cons_getc();
c0101aff:	e8 8b fa ff ff       	call   c010158f <cons_getc>
c0101b04:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("kbd [%03d] %c\n", c, c);
c0101b07:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
c0101b0b:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c0101b0f:	89 54 24 08          	mov    %edx,0x8(%esp)
c0101b13:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101b17:	c7 04 24 a6 61 10 c0 	movl   $0xc01061a6,(%esp)
c0101b1e:	e8 6f e7 ff ff       	call   c0100292 <cprintf>
        break;
c0101b23:	eb 55                	jmp    c0101b7a <trap_dispatch+0xda>
    //LAB1 CHALLENGE 1 : YOUR CODE you should modify below codes.
    case T_SWITCH_TOU:
    case T_SWITCH_TOK:
        panic("T_SWITCH_** ??\n");
c0101b25:	c7 44 24 08 b5 61 10 	movl   $0xc01061b5,0x8(%esp)
c0101b2c:	c0 
c0101b2d:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
c0101b34:	00 
c0101b35:	c7 04 24 c5 61 10 c0 	movl   $0xc01061c5,(%esp)
c0101b3c:	e8 a8 e8 ff ff       	call   c01003e9 <__panic>
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
    default:
        // in kernel, it must be a mistake
        if ((tf->tf_cs & 3) == 0) {
c0101b41:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b44:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101b48:	83 e0 03             	and    $0x3,%eax
c0101b4b:	85 c0                	test   %eax,%eax
c0101b4d:	75 2b                	jne    c0101b7a <trap_dispatch+0xda>
            print_trapframe(tf);
c0101b4f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b52:	89 04 24             	mov    %eax,(%esp)
c0101b55:	e8 d9 fc ff ff       	call   c0101833 <print_trapframe>
            panic("unexpected trap in kernel.\n");
c0101b5a:	c7 44 24 08 d6 61 10 	movl   $0xc01061d6,0x8(%esp)
c0101b61:	c0 
c0101b62:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
c0101b69:	00 
c0101b6a:	c7 04 24 c5 61 10 c0 	movl   $0xc01061c5,(%esp)
c0101b71:	e8 73 e8 ff ff       	call   c01003e9 <__panic>
        panic("T_SWITCH_** ??\n");
        break;
    case IRQ_OFFSET + IRQ_IDE1:
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
c0101b76:	90                   	nop
c0101b77:	eb 01                	jmp    c0101b7a <trap_dispatch+0xda>
        /* handle the timer interrupt */
        /* (1) After a timer interrupt, you should record this event using a global variable (increase it), such as ticks in kern/driver/clock.c
         * (2) Every TICK_NUM cycle, you can print some info using a funciton, such as print_ticks().
         * (3) Too Simple? Yes, I think so!
         */
        break;
c0101b79:	90                   	nop
        if ((tf->tf_cs & 3) == 0) {
            print_trapframe(tf);
            panic("unexpected trap in kernel.\n");
        }
    }
}
c0101b7a:	90                   	nop
c0101b7b:	c9                   	leave  
c0101b7c:	c3                   	ret    

c0101b7d <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
c0101b7d:	55                   	push   %ebp
c0101b7e:	89 e5                	mov    %esp,%ebp
c0101b80:	83 ec 18             	sub    $0x18,%esp
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
c0101b83:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b86:	89 04 24             	mov    %eax,(%esp)
c0101b89:	e8 12 ff ff ff       	call   c0101aa0 <trap_dispatch>
}
c0101b8e:	90                   	nop
c0101b8f:	c9                   	leave  
c0101b90:	c3                   	ret    

c0101b91 <vector0>:
# handler
.text
.globl __alltraps
.globl vector0
vector0:
  pushl $0
c0101b91:	6a 00                	push   $0x0
  pushl $0
c0101b93:	6a 00                	push   $0x0
  jmp __alltraps
c0101b95:	e9 69 0a 00 00       	jmp    c0102603 <__alltraps>

c0101b9a <vector1>:
.globl vector1
vector1:
  pushl $0
c0101b9a:	6a 00                	push   $0x0
  pushl $1
c0101b9c:	6a 01                	push   $0x1
  jmp __alltraps
c0101b9e:	e9 60 0a 00 00       	jmp    c0102603 <__alltraps>

c0101ba3 <vector2>:
.globl vector2
vector2:
  pushl $0
c0101ba3:	6a 00                	push   $0x0
  pushl $2
c0101ba5:	6a 02                	push   $0x2
  jmp __alltraps
c0101ba7:	e9 57 0a 00 00       	jmp    c0102603 <__alltraps>

c0101bac <vector3>:
.globl vector3
vector3:
  pushl $0
c0101bac:	6a 00                	push   $0x0
  pushl $3
c0101bae:	6a 03                	push   $0x3
  jmp __alltraps
c0101bb0:	e9 4e 0a 00 00       	jmp    c0102603 <__alltraps>

c0101bb5 <vector4>:
.globl vector4
vector4:
  pushl $0
c0101bb5:	6a 00                	push   $0x0
  pushl $4
c0101bb7:	6a 04                	push   $0x4
  jmp __alltraps
c0101bb9:	e9 45 0a 00 00       	jmp    c0102603 <__alltraps>

c0101bbe <vector5>:
.globl vector5
vector5:
  pushl $0
c0101bbe:	6a 00                	push   $0x0
  pushl $5
c0101bc0:	6a 05                	push   $0x5
  jmp __alltraps
c0101bc2:	e9 3c 0a 00 00       	jmp    c0102603 <__alltraps>

c0101bc7 <vector6>:
.globl vector6
vector6:
  pushl $0
c0101bc7:	6a 00                	push   $0x0
  pushl $6
c0101bc9:	6a 06                	push   $0x6
  jmp __alltraps
c0101bcb:	e9 33 0a 00 00       	jmp    c0102603 <__alltraps>

c0101bd0 <vector7>:
.globl vector7
vector7:
  pushl $0
c0101bd0:	6a 00                	push   $0x0
  pushl $7
c0101bd2:	6a 07                	push   $0x7
  jmp __alltraps
c0101bd4:	e9 2a 0a 00 00       	jmp    c0102603 <__alltraps>

c0101bd9 <vector8>:
.globl vector8
vector8:
  pushl $8
c0101bd9:	6a 08                	push   $0x8
  jmp __alltraps
c0101bdb:	e9 23 0a 00 00       	jmp    c0102603 <__alltraps>

c0101be0 <vector9>:
.globl vector9
vector9:
  pushl $0
c0101be0:	6a 00                	push   $0x0
  pushl $9
c0101be2:	6a 09                	push   $0x9
  jmp __alltraps
c0101be4:	e9 1a 0a 00 00       	jmp    c0102603 <__alltraps>

c0101be9 <vector10>:
.globl vector10
vector10:
  pushl $10
c0101be9:	6a 0a                	push   $0xa
  jmp __alltraps
c0101beb:	e9 13 0a 00 00       	jmp    c0102603 <__alltraps>

c0101bf0 <vector11>:
.globl vector11
vector11:
  pushl $11
c0101bf0:	6a 0b                	push   $0xb
  jmp __alltraps
c0101bf2:	e9 0c 0a 00 00       	jmp    c0102603 <__alltraps>

c0101bf7 <vector12>:
.globl vector12
vector12:
  pushl $12
c0101bf7:	6a 0c                	push   $0xc
  jmp __alltraps
c0101bf9:	e9 05 0a 00 00       	jmp    c0102603 <__alltraps>

c0101bfe <vector13>:
.globl vector13
vector13:
  pushl $13
c0101bfe:	6a 0d                	push   $0xd
  jmp __alltraps
c0101c00:	e9 fe 09 00 00       	jmp    c0102603 <__alltraps>

c0101c05 <vector14>:
.globl vector14
vector14:
  pushl $14
c0101c05:	6a 0e                	push   $0xe
  jmp __alltraps
c0101c07:	e9 f7 09 00 00       	jmp    c0102603 <__alltraps>

c0101c0c <vector15>:
.globl vector15
vector15:
  pushl $0
c0101c0c:	6a 00                	push   $0x0
  pushl $15
c0101c0e:	6a 0f                	push   $0xf
  jmp __alltraps
c0101c10:	e9 ee 09 00 00       	jmp    c0102603 <__alltraps>

c0101c15 <vector16>:
.globl vector16
vector16:
  pushl $0
c0101c15:	6a 00                	push   $0x0
  pushl $16
c0101c17:	6a 10                	push   $0x10
  jmp __alltraps
c0101c19:	e9 e5 09 00 00       	jmp    c0102603 <__alltraps>

c0101c1e <vector17>:
.globl vector17
vector17:
  pushl $17
c0101c1e:	6a 11                	push   $0x11
  jmp __alltraps
c0101c20:	e9 de 09 00 00       	jmp    c0102603 <__alltraps>

c0101c25 <vector18>:
.globl vector18
vector18:
  pushl $0
c0101c25:	6a 00                	push   $0x0
  pushl $18
c0101c27:	6a 12                	push   $0x12
  jmp __alltraps
c0101c29:	e9 d5 09 00 00       	jmp    c0102603 <__alltraps>

c0101c2e <vector19>:
.globl vector19
vector19:
  pushl $0
c0101c2e:	6a 00                	push   $0x0
  pushl $19
c0101c30:	6a 13                	push   $0x13
  jmp __alltraps
c0101c32:	e9 cc 09 00 00       	jmp    c0102603 <__alltraps>

c0101c37 <vector20>:
.globl vector20
vector20:
  pushl $0
c0101c37:	6a 00                	push   $0x0
  pushl $20
c0101c39:	6a 14                	push   $0x14
  jmp __alltraps
c0101c3b:	e9 c3 09 00 00       	jmp    c0102603 <__alltraps>

c0101c40 <vector21>:
.globl vector21
vector21:
  pushl $0
c0101c40:	6a 00                	push   $0x0
  pushl $21
c0101c42:	6a 15                	push   $0x15
  jmp __alltraps
c0101c44:	e9 ba 09 00 00       	jmp    c0102603 <__alltraps>

c0101c49 <vector22>:
.globl vector22
vector22:
  pushl $0
c0101c49:	6a 00                	push   $0x0
  pushl $22
c0101c4b:	6a 16                	push   $0x16
  jmp __alltraps
c0101c4d:	e9 b1 09 00 00       	jmp    c0102603 <__alltraps>

c0101c52 <vector23>:
.globl vector23
vector23:
  pushl $0
c0101c52:	6a 00                	push   $0x0
  pushl $23
c0101c54:	6a 17                	push   $0x17
  jmp __alltraps
c0101c56:	e9 a8 09 00 00       	jmp    c0102603 <__alltraps>

c0101c5b <vector24>:
.globl vector24
vector24:
  pushl $0
c0101c5b:	6a 00                	push   $0x0
  pushl $24
c0101c5d:	6a 18                	push   $0x18
  jmp __alltraps
c0101c5f:	e9 9f 09 00 00       	jmp    c0102603 <__alltraps>

c0101c64 <vector25>:
.globl vector25
vector25:
  pushl $0
c0101c64:	6a 00                	push   $0x0
  pushl $25
c0101c66:	6a 19                	push   $0x19
  jmp __alltraps
c0101c68:	e9 96 09 00 00       	jmp    c0102603 <__alltraps>

c0101c6d <vector26>:
.globl vector26
vector26:
  pushl $0
c0101c6d:	6a 00                	push   $0x0
  pushl $26
c0101c6f:	6a 1a                	push   $0x1a
  jmp __alltraps
c0101c71:	e9 8d 09 00 00       	jmp    c0102603 <__alltraps>

c0101c76 <vector27>:
.globl vector27
vector27:
  pushl $0
c0101c76:	6a 00                	push   $0x0
  pushl $27
c0101c78:	6a 1b                	push   $0x1b
  jmp __alltraps
c0101c7a:	e9 84 09 00 00       	jmp    c0102603 <__alltraps>

c0101c7f <vector28>:
.globl vector28
vector28:
  pushl $0
c0101c7f:	6a 00                	push   $0x0
  pushl $28
c0101c81:	6a 1c                	push   $0x1c
  jmp __alltraps
c0101c83:	e9 7b 09 00 00       	jmp    c0102603 <__alltraps>

c0101c88 <vector29>:
.globl vector29
vector29:
  pushl $0
c0101c88:	6a 00                	push   $0x0
  pushl $29
c0101c8a:	6a 1d                	push   $0x1d
  jmp __alltraps
c0101c8c:	e9 72 09 00 00       	jmp    c0102603 <__alltraps>

c0101c91 <vector30>:
.globl vector30
vector30:
  pushl $0
c0101c91:	6a 00                	push   $0x0
  pushl $30
c0101c93:	6a 1e                	push   $0x1e
  jmp __alltraps
c0101c95:	e9 69 09 00 00       	jmp    c0102603 <__alltraps>

c0101c9a <vector31>:
.globl vector31
vector31:
  pushl $0
c0101c9a:	6a 00                	push   $0x0
  pushl $31
c0101c9c:	6a 1f                	push   $0x1f
  jmp __alltraps
c0101c9e:	e9 60 09 00 00       	jmp    c0102603 <__alltraps>

c0101ca3 <vector32>:
.globl vector32
vector32:
  pushl $0
c0101ca3:	6a 00                	push   $0x0
  pushl $32
c0101ca5:	6a 20                	push   $0x20
  jmp __alltraps
c0101ca7:	e9 57 09 00 00       	jmp    c0102603 <__alltraps>

c0101cac <vector33>:
.globl vector33
vector33:
  pushl $0
c0101cac:	6a 00                	push   $0x0
  pushl $33
c0101cae:	6a 21                	push   $0x21
  jmp __alltraps
c0101cb0:	e9 4e 09 00 00       	jmp    c0102603 <__alltraps>

c0101cb5 <vector34>:
.globl vector34
vector34:
  pushl $0
c0101cb5:	6a 00                	push   $0x0
  pushl $34
c0101cb7:	6a 22                	push   $0x22
  jmp __alltraps
c0101cb9:	e9 45 09 00 00       	jmp    c0102603 <__alltraps>

c0101cbe <vector35>:
.globl vector35
vector35:
  pushl $0
c0101cbe:	6a 00                	push   $0x0
  pushl $35
c0101cc0:	6a 23                	push   $0x23
  jmp __alltraps
c0101cc2:	e9 3c 09 00 00       	jmp    c0102603 <__alltraps>

c0101cc7 <vector36>:
.globl vector36
vector36:
  pushl $0
c0101cc7:	6a 00                	push   $0x0
  pushl $36
c0101cc9:	6a 24                	push   $0x24
  jmp __alltraps
c0101ccb:	e9 33 09 00 00       	jmp    c0102603 <__alltraps>

c0101cd0 <vector37>:
.globl vector37
vector37:
  pushl $0
c0101cd0:	6a 00                	push   $0x0
  pushl $37
c0101cd2:	6a 25                	push   $0x25
  jmp __alltraps
c0101cd4:	e9 2a 09 00 00       	jmp    c0102603 <__alltraps>

c0101cd9 <vector38>:
.globl vector38
vector38:
  pushl $0
c0101cd9:	6a 00                	push   $0x0
  pushl $38
c0101cdb:	6a 26                	push   $0x26
  jmp __alltraps
c0101cdd:	e9 21 09 00 00       	jmp    c0102603 <__alltraps>

c0101ce2 <vector39>:
.globl vector39
vector39:
  pushl $0
c0101ce2:	6a 00                	push   $0x0
  pushl $39
c0101ce4:	6a 27                	push   $0x27
  jmp __alltraps
c0101ce6:	e9 18 09 00 00       	jmp    c0102603 <__alltraps>

c0101ceb <vector40>:
.globl vector40
vector40:
  pushl $0
c0101ceb:	6a 00                	push   $0x0
  pushl $40
c0101ced:	6a 28                	push   $0x28
  jmp __alltraps
c0101cef:	e9 0f 09 00 00       	jmp    c0102603 <__alltraps>

c0101cf4 <vector41>:
.globl vector41
vector41:
  pushl $0
c0101cf4:	6a 00                	push   $0x0
  pushl $41
c0101cf6:	6a 29                	push   $0x29
  jmp __alltraps
c0101cf8:	e9 06 09 00 00       	jmp    c0102603 <__alltraps>

c0101cfd <vector42>:
.globl vector42
vector42:
  pushl $0
c0101cfd:	6a 00                	push   $0x0
  pushl $42
c0101cff:	6a 2a                	push   $0x2a
  jmp __alltraps
c0101d01:	e9 fd 08 00 00       	jmp    c0102603 <__alltraps>

c0101d06 <vector43>:
.globl vector43
vector43:
  pushl $0
c0101d06:	6a 00                	push   $0x0
  pushl $43
c0101d08:	6a 2b                	push   $0x2b
  jmp __alltraps
c0101d0a:	e9 f4 08 00 00       	jmp    c0102603 <__alltraps>

c0101d0f <vector44>:
.globl vector44
vector44:
  pushl $0
c0101d0f:	6a 00                	push   $0x0
  pushl $44
c0101d11:	6a 2c                	push   $0x2c
  jmp __alltraps
c0101d13:	e9 eb 08 00 00       	jmp    c0102603 <__alltraps>

c0101d18 <vector45>:
.globl vector45
vector45:
  pushl $0
c0101d18:	6a 00                	push   $0x0
  pushl $45
c0101d1a:	6a 2d                	push   $0x2d
  jmp __alltraps
c0101d1c:	e9 e2 08 00 00       	jmp    c0102603 <__alltraps>

c0101d21 <vector46>:
.globl vector46
vector46:
  pushl $0
c0101d21:	6a 00                	push   $0x0
  pushl $46
c0101d23:	6a 2e                	push   $0x2e
  jmp __alltraps
c0101d25:	e9 d9 08 00 00       	jmp    c0102603 <__alltraps>

c0101d2a <vector47>:
.globl vector47
vector47:
  pushl $0
c0101d2a:	6a 00                	push   $0x0
  pushl $47
c0101d2c:	6a 2f                	push   $0x2f
  jmp __alltraps
c0101d2e:	e9 d0 08 00 00       	jmp    c0102603 <__alltraps>

c0101d33 <vector48>:
.globl vector48
vector48:
  pushl $0
c0101d33:	6a 00                	push   $0x0
  pushl $48
c0101d35:	6a 30                	push   $0x30
  jmp __alltraps
c0101d37:	e9 c7 08 00 00       	jmp    c0102603 <__alltraps>

c0101d3c <vector49>:
.globl vector49
vector49:
  pushl $0
c0101d3c:	6a 00                	push   $0x0
  pushl $49
c0101d3e:	6a 31                	push   $0x31
  jmp __alltraps
c0101d40:	e9 be 08 00 00       	jmp    c0102603 <__alltraps>

c0101d45 <vector50>:
.globl vector50
vector50:
  pushl $0
c0101d45:	6a 00                	push   $0x0
  pushl $50
c0101d47:	6a 32                	push   $0x32
  jmp __alltraps
c0101d49:	e9 b5 08 00 00       	jmp    c0102603 <__alltraps>

c0101d4e <vector51>:
.globl vector51
vector51:
  pushl $0
c0101d4e:	6a 00                	push   $0x0
  pushl $51
c0101d50:	6a 33                	push   $0x33
  jmp __alltraps
c0101d52:	e9 ac 08 00 00       	jmp    c0102603 <__alltraps>

c0101d57 <vector52>:
.globl vector52
vector52:
  pushl $0
c0101d57:	6a 00                	push   $0x0
  pushl $52
c0101d59:	6a 34                	push   $0x34
  jmp __alltraps
c0101d5b:	e9 a3 08 00 00       	jmp    c0102603 <__alltraps>

c0101d60 <vector53>:
.globl vector53
vector53:
  pushl $0
c0101d60:	6a 00                	push   $0x0
  pushl $53
c0101d62:	6a 35                	push   $0x35
  jmp __alltraps
c0101d64:	e9 9a 08 00 00       	jmp    c0102603 <__alltraps>

c0101d69 <vector54>:
.globl vector54
vector54:
  pushl $0
c0101d69:	6a 00                	push   $0x0
  pushl $54
c0101d6b:	6a 36                	push   $0x36
  jmp __alltraps
c0101d6d:	e9 91 08 00 00       	jmp    c0102603 <__alltraps>

c0101d72 <vector55>:
.globl vector55
vector55:
  pushl $0
c0101d72:	6a 00                	push   $0x0
  pushl $55
c0101d74:	6a 37                	push   $0x37
  jmp __alltraps
c0101d76:	e9 88 08 00 00       	jmp    c0102603 <__alltraps>

c0101d7b <vector56>:
.globl vector56
vector56:
  pushl $0
c0101d7b:	6a 00                	push   $0x0
  pushl $56
c0101d7d:	6a 38                	push   $0x38
  jmp __alltraps
c0101d7f:	e9 7f 08 00 00       	jmp    c0102603 <__alltraps>

c0101d84 <vector57>:
.globl vector57
vector57:
  pushl $0
c0101d84:	6a 00                	push   $0x0
  pushl $57
c0101d86:	6a 39                	push   $0x39
  jmp __alltraps
c0101d88:	e9 76 08 00 00       	jmp    c0102603 <__alltraps>

c0101d8d <vector58>:
.globl vector58
vector58:
  pushl $0
c0101d8d:	6a 00                	push   $0x0
  pushl $58
c0101d8f:	6a 3a                	push   $0x3a
  jmp __alltraps
c0101d91:	e9 6d 08 00 00       	jmp    c0102603 <__alltraps>

c0101d96 <vector59>:
.globl vector59
vector59:
  pushl $0
c0101d96:	6a 00                	push   $0x0
  pushl $59
c0101d98:	6a 3b                	push   $0x3b
  jmp __alltraps
c0101d9a:	e9 64 08 00 00       	jmp    c0102603 <__alltraps>

c0101d9f <vector60>:
.globl vector60
vector60:
  pushl $0
c0101d9f:	6a 00                	push   $0x0
  pushl $60
c0101da1:	6a 3c                	push   $0x3c
  jmp __alltraps
c0101da3:	e9 5b 08 00 00       	jmp    c0102603 <__alltraps>

c0101da8 <vector61>:
.globl vector61
vector61:
  pushl $0
c0101da8:	6a 00                	push   $0x0
  pushl $61
c0101daa:	6a 3d                	push   $0x3d
  jmp __alltraps
c0101dac:	e9 52 08 00 00       	jmp    c0102603 <__alltraps>

c0101db1 <vector62>:
.globl vector62
vector62:
  pushl $0
c0101db1:	6a 00                	push   $0x0
  pushl $62
c0101db3:	6a 3e                	push   $0x3e
  jmp __alltraps
c0101db5:	e9 49 08 00 00       	jmp    c0102603 <__alltraps>

c0101dba <vector63>:
.globl vector63
vector63:
  pushl $0
c0101dba:	6a 00                	push   $0x0
  pushl $63
c0101dbc:	6a 3f                	push   $0x3f
  jmp __alltraps
c0101dbe:	e9 40 08 00 00       	jmp    c0102603 <__alltraps>

c0101dc3 <vector64>:
.globl vector64
vector64:
  pushl $0
c0101dc3:	6a 00                	push   $0x0
  pushl $64
c0101dc5:	6a 40                	push   $0x40
  jmp __alltraps
c0101dc7:	e9 37 08 00 00       	jmp    c0102603 <__alltraps>

c0101dcc <vector65>:
.globl vector65
vector65:
  pushl $0
c0101dcc:	6a 00                	push   $0x0
  pushl $65
c0101dce:	6a 41                	push   $0x41
  jmp __alltraps
c0101dd0:	e9 2e 08 00 00       	jmp    c0102603 <__alltraps>

c0101dd5 <vector66>:
.globl vector66
vector66:
  pushl $0
c0101dd5:	6a 00                	push   $0x0
  pushl $66
c0101dd7:	6a 42                	push   $0x42
  jmp __alltraps
c0101dd9:	e9 25 08 00 00       	jmp    c0102603 <__alltraps>

c0101dde <vector67>:
.globl vector67
vector67:
  pushl $0
c0101dde:	6a 00                	push   $0x0
  pushl $67
c0101de0:	6a 43                	push   $0x43
  jmp __alltraps
c0101de2:	e9 1c 08 00 00       	jmp    c0102603 <__alltraps>

c0101de7 <vector68>:
.globl vector68
vector68:
  pushl $0
c0101de7:	6a 00                	push   $0x0
  pushl $68
c0101de9:	6a 44                	push   $0x44
  jmp __alltraps
c0101deb:	e9 13 08 00 00       	jmp    c0102603 <__alltraps>

c0101df0 <vector69>:
.globl vector69
vector69:
  pushl $0
c0101df0:	6a 00                	push   $0x0
  pushl $69
c0101df2:	6a 45                	push   $0x45
  jmp __alltraps
c0101df4:	e9 0a 08 00 00       	jmp    c0102603 <__alltraps>

c0101df9 <vector70>:
.globl vector70
vector70:
  pushl $0
c0101df9:	6a 00                	push   $0x0
  pushl $70
c0101dfb:	6a 46                	push   $0x46
  jmp __alltraps
c0101dfd:	e9 01 08 00 00       	jmp    c0102603 <__alltraps>

c0101e02 <vector71>:
.globl vector71
vector71:
  pushl $0
c0101e02:	6a 00                	push   $0x0
  pushl $71
c0101e04:	6a 47                	push   $0x47
  jmp __alltraps
c0101e06:	e9 f8 07 00 00       	jmp    c0102603 <__alltraps>

c0101e0b <vector72>:
.globl vector72
vector72:
  pushl $0
c0101e0b:	6a 00                	push   $0x0
  pushl $72
c0101e0d:	6a 48                	push   $0x48
  jmp __alltraps
c0101e0f:	e9 ef 07 00 00       	jmp    c0102603 <__alltraps>

c0101e14 <vector73>:
.globl vector73
vector73:
  pushl $0
c0101e14:	6a 00                	push   $0x0
  pushl $73
c0101e16:	6a 49                	push   $0x49
  jmp __alltraps
c0101e18:	e9 e6 07 00 00       	jmp    c0102603 <__alltraps>

c0101e1d <vector74>:
.globl vector74
vector74:
  pushl $0
c0101e1d:	6a 00                	push   $0x0
  pushl $74
c0101e1f:	6a 4a                	push   $0x4a
  jmp __alltraps
c0101e21:	e9 dd 07 00 00       	jmp    c0102603 <__alltraps>

c0101e26 <vector75>:
.globl vector75
vector75:
  pushl $0
c0101e26:	6a 00                	push   $0x0
  pushl $75
c0101e28:	6a 4b                	push   $0x4b
  jmp __alltraps
c0101e2a:	e9 d4 07 00 00       	jmp    c0102603 <__alltraps>

c0101e2f <vector76>:
.globl vector76
vector76:
  pushl $0
c0101e2f:	6a 00                	push   $0x0
  pushl $76
c0101e31:	6a 4c                	push   $0x4c
  jmp __alltraps
c0101e33:	e9 cb 07 00 00       	jmp    c0102603 <__alltraps>

c0101e38 <vector77>:
.globl vector77
vector77:
  pushl $0
c0101e38:	6a 00                	push   $0x0
  pushl $77
c0101e3a:	6a 4d                	push   $0x4d
  jmp __alltraps
c0101e3c:	e9 c2 07 00 00       	jmp    c0102603 <__alltraps>

c0101e41 <vector78>:
.globl vector78
vector78:
  pushl $0
c0101e41:	6a 00                	push   $0x0
  pushl $78
c0101e43:	6a 4e                	push   $0x4e
  jmp __alltraps
c0101e45:	e9 b9 07 00 00       	jmp    c0102603 <__alltraps>

c0101e4a <vector79>:
.globl vector79
vector79:
  pushl $0
c0101e4a:	6a 00                	push   $0x0
  pushl $79
c0101e4c:	6a 4f                	push   $0x4f
  jmp __alltraps
c0101e4e:	e9 b0 07 00 00       	jmp    c0102603 <__alltraps>

c0101e53 <vector80>:
.globl vector80
vector80:
  pushl $0
c0101e53:	6a 00                	push   $0x0
  pushl $80
c0101e55:	6a 50                	push   $0x50
  jmp __alltraps
c0101e57:	e9 a7 07 00 00       	jmp    c0102603 <__alltraps>

c0101e5c <vector81>:
.globl vector81
vector81:
  pushl $0
c0101e5c:	6a 00                	push   $0x0
  pushl $81
c0101e5e:	6a 51                	push   $0x51
  jmp __alltraps
c0101e60:	e9 9e 07 00 00       	jmp    c0102603 <__alltraps>

c0101e65 <vector82>:
.globl vector82
vector82:
  pushl $0
c0101e65:	6a 00                	push   $0x0
  pushl $82
c0101e67:	6a 52                	push   $0x52
  jmp __alltraps
c0101e69:	e9 95 07 00 00       	jmp    c0102603 <__alltraps>

c0101e6e <vector83>:
.globl vector83
vector83:
  pushl $0
c0101e6e:	6a 00                	push   $0x0
  pushl $83
c0101e70:	6a 53                	push   $0x53
  jmp __alltraps
c0101e72:	e9 8c 07 00 00       	jmp    c0102603 <__alltraps>

c0101e77 <vector84>:
.globl vector84
vector84:
  pushl $0
c0101e77:	6a 00                	push   $0x0
  pushl $84
c0101e79:	6a 54                	push   $0x54
  jmp __alltraps
c0101e7b:	e9 83 07 00 00       	jmp    c0102603 <__alltraps>

c0101e80 <vector85>:
.globl vector85
vector85:
  pushl $0
c0101e80:	6a 00                	push   $0x0
  pushl $85
c0101e82:	6a 55                	push   $0x55
  jmp __alltraps
c0101e84:	e9 7a 07 00 00       	jmp    c0102603 <__alltraps>

c0101e89 <vector86>:
.globl vector86
vector86:
  pushl $0
c0101e89:	6a 00                	push   $0x0
  pushl $86
c0101e8b:	6a 56                	push   $0x56
  jmp __alltraps
c0101e8d:	e9 71 07 00 00       	jmp    c0102603 <__alltraps>

c0101e92 <vector87>:
.globl vector87
vector87:
  pushl $0
c0101e92:	6a 00                	push   $0x0
  pushl $87
c0101e94:	6a 57                	push   $0x57
  jmp __alltraps
c0101e96:	e9 68 07 00 00       	jmp    c0102603 <__alltraps>

c0101e9b <vector88>:
.globl vector88
vector88:
  pushl $0
c0101e9b:	6a 00                	push   $0x0
  pushl $88
c0101e9d:	6a 58                	push   $0x58
  jmp __alltraps
c0101e9f:	e9 5f 07 00 00       	jmp    c0102603 <__alltraps>

c0101ea4 <vector89>:
.globl vector89
vector89:
  pushl $0
c0101ea4:	6a 00                	push   $0x0
  pushl $89
c0101ea6:	6a 59                	push   $0x59
  jmp __alltraps
c0101ea8:	e9 56 07 00 00       	jmp    c0102603 <__alltraps>

c0101ead <vector90>:
.globl vector90
vector90:
  pushl $0
c0101ead:	6a 00                	push   $0x0
  pushl $90
c0101eaf:	6a 5a                	push   $0x5a
  jmp __alltraps
c0101eb1:	e9 4d 07 00 00       	jmp    c0102603 <__alltraps>

c0101eb6 <vector91>:
.globl vector91
vector91:
  pushl $0
c0101eb6:	6a 00                	push   $0x0
  pushl $91
c0101eb8:	6a 5b                	push   $0x5b
  jmp __alltraps
c0101eba:	e9 44 07 00 00       	jmp    c0102603 <__alltraps>

c0101ebf <vector92>:
.globl vector92
vector92:
  pushl $0
c0101ebf:	6a 00                	push   $0x0
  pushl $92
c0101ec1:	6a 5c                	push   $0x5c
  jmp __alltraps
c0101ec3:	e9 3b 07 00 00       	jmp    c0102603 <__alltraps>

c0101ec8 <vector93>:
.globl vector93
vector93:
  pushl $0
c0101ec8:	6a 00                	push   $0x0
  pushl $93
c0101eca:	6a 5d                	push   $0x5d
  jmp __alltraps
c0101ecc:	e9 32 07 00 00       	jmp    c0102603 <__alltraps>

c0101ed1 <vector94>:
.globl vector94
vector94:
  pushl $0
c0101ed1:	6a 00                	push   $0x0
  pushl $94
c0101ed3:	6a 5e                	push   $0x5e
  jmp __alltraps
c0101ed5:	e9 29 07 00 00       	jmp    c0102603 <__alltraps>

c0101eda <vector95>:
.globl vector95
vector95:
  pushl $0
c0101eda:	6a 00                	push   $0x0
  pushl $95
c0101edc:	6a 5f                	push   $0x5f
  jmp __alltraps
c0101ede:	e9 20 07 00 00       	jmp    c0102603 <__alltraps>

c0101ee3 <vector96>:
.globl vector96
vector96:
  pushl $0
c0101ee3:	6a 00                	push   $0x0
  pushl $96
c0101ee5:	6a 60                	push   $0x60
  jmp __alltraps
c0101ee7:	e9 17 07 00 00       	jmp    c0102603 <__alltraps>

c0101eec <vector97>:
.globl vector97
vector97:
  pushl $0
c0101eec:	6a 00                	push   $0x0
  pushl $97
c0101eee:	6a 61                	push   $0x61
  jmp __alltraps
c0101ef0:	e9 0e 07 00 00       	jmp    c0102603 <__alltraps>

c0101ef5 <vector98>:
.globl vector98
vector98:
  pushl $0
c0101ef5:	6a 00                	push   $0x0
  pushl $98
c0101ef7:	6a 62                	push   $0x62
  jmp __alltraps
c0101ef9:	e9 05 07 00 00       	jmp    c0102603 <__alltraps>

c0101efe <vector99>:
.globl vector99
vector99:
  pushl $0
c0101efe:	6a 00                	push   $0x0
  pushl $99
c0101f00:	6a 63                	push   $0x63
  jmp __alltraps
c0101f02:	e9 fc 06 00 00       	jmp    c0102603 <__alltraps>

c0101f07 <vector100>:
.globl vector100
vector100:
  pushl $0
c0101f07:	6a 00                	push   $0x0
  pushl $100
c0101f09:	6a 64                	push   $0x64
  jmp __alltraps
c0101f0b:	e9 f3 06 00 00       	jmp    c0102603 <__alltraps>

c0101f10 <vector101>:
.globl vector101
vector101:
  pushl $0
c0101f10:	6a 00                	push   $0x0
  pushl $101
c0101f12:	6a 65                	push   $0x65
  jmp __alltraps
c0101f14:	e9 ea 06 00 00       	jmp    c0102603 <__alltraps>

c0101f19 <vector102>:
.globl vector102
vector102:
  pushl $0
c0101f19:	6a 00                	push   $0x0
  pushl $102
c0101f1b:	6a 66                	push   $0x66
  jmp __alltraps
c0101f1d:	e9 e1 06 00 00       	jmp    c0102603 <__alltraps>

c0101f22 <vector103>:
.globl vector103
vector103:
  pushl $0
c0101f22:	6a 00                	push   $0x0
  pushl $103
c0101f24:	6a 67                	push   $0x67
  jmp __alltraps
c0101f26:	e9 d8 06 00 00       	jmp    c0102603 <__alltraps>

c0101f2b <vector104>:
.globl vector104
vector104:
  pushl $0
c0101f2b:	6a 00                	push   $0x0
  pushl $104
c0101f2d:	6a 68                	push   $0x68
  jmp __alltraps
c0101f2f:	e9 cf 06 00 00       	jmp    c0102603 <__alltraps>

c0101f34 <vector105>:
.globl vector105
vector105:
  pushl $0
c0101f34:	6a 00                	push   $0x0
  pushl $105
c0101f36:	6a 69                	push   $0x69
  jmp __alltraps
c0101f38:	e9 c6 06 00 00       	jmp    c0102603 <__alltraps>

c0101f3d <vector106>:
.globl vector106
vector106:
  pushl $0
c0101f3d:	6a 00                	push   $0x0
  pushl $106
c0101f3f:	6a 6a                	push   $0x6a
  jmp __alltraps
c0101f41:	e9 bd 06 00 00       	jmp    c0102603 <__alltraps>

c0101f46 <vector107>:
.globl vector107
vector107:
  pushl $0
c0101f46:	6a 00                	push   $0x0
  pushl $107
c0101f48:	6a 6b                	push   $0x6b
  jmp __alltraps
c0101f4a:	e9 b4 06 00 00       	jmp    c0102603 <__alltraps>

c0101f4f <vector108>:
.globl vector108
vector108:
  pushl $0
c0101f4f:	6a 00                	push   $0x0
  pushl $108
c0101f51:	6a 6c                	push   $0x6c
  jmp __alltraps
c0101f53:	e9 ab 06 00 00       	jmp    c0102603 <__alltraps>

c0101f58 <vector109>:
.globl vector109
vector109:
  pushl $0
c0101f58:	6a 00                	push   $0x0
  pushl $109
c0101f5a:	6a 6d                	push   $0x6d
  jmp __alltraps
c0101f5c:	e9 a2 06 00 00       	jmp    c0102603 <__alltraps>

c0101f61 <vector110>:
.globl vector110
vector110:
  pushl $0
c0101f61:	6a 00                	push   $0x0
  pushl $110
c0101f63:	6a 6e                	push   $0x6e
  jmp __alltraps
c0101f65:	e9 99 06 00 00       	jmp    c0102603 <__alltraps>

c0101f6a <vector111>:
.globl vector111
vector111:
  pushl $0
c0101f6a:	6a 00                	push   $0x0
  pushl $111
c0101f6c:	6a 6f                	push   $0x6f
  jmp __alltraps
c0101f6e:	e9 90 06 00 00       	jmp    c0102603 <__alltraps>

c0101f73 <vector112>:
.globl vector112
vector112:
  pushl $0
c0101f73:	6a 00                	push   $0x0
  pushl $112
c0101f75:	6a 70                	push   $0x70
  jmp __alltraps
c0101f77:	e9 87 06 00 00       	jmp    c0102603 <__alltraps>

c0101f7c <vector113>:
.globl vector113
vector113:
  pushl $0
c0101f7c:	6a 00                	push   $0x0
  pushl $113
c0101f7e:	6a 71                	push   $0x71
  jmp __alltraps
c0101f80:	e9 7e 06 00 00       	jmp    c0102603 <__alltraps>

c0101f85 <vector114>:
.globl vector114
vector114:
  pushl $0
c0101f85:	6a 00                	push   $0x0
  pushl $114
c0101f87:	6a 72                	push   $0x72
  jmp __alltraps
c0101f89:	e9 75 06 00 00       	jmp    c0102603 <__alltraps>

c0101f8e <vector115>:
.globl vector115
vector115:
  pushl $0
c0101f8e:	6a 00                	push   $0x0
  pushl $115
c0101f90:	6a 73                	push   $0x73
  jmp __alltraps
c0101f92:	e9 6c 06 00 00       	jmp    c0102603 <__alltraps>

c0101f97 <vector116>:
.globl vector116
vector116:
  pushl $0
c0101f97:	6a 00                	push   $0x0
  pushl $116
c0101f99:	6a 74                	push   $0x74
  jmp __alltraps
c0101f9b:	e9 63 06 00 00       	jmp    c0102603 <__alltraps>

c0101fa0 <vector117>:
.globl vector117
vector117:
  pushl $0
c0101fa0:	6a 00                	push   $0x0
  pushl $117
c0101fa2:	6a 75                	push   $0x75
  jmp __alltraps
c0101fa4:	e9 5a 06 00 00       	jmp    c0102603 <__alltraps>

c0101fa9 <vector118>:
.globl vector118
vector118:
  pushl $0
c0101fa9:	6a 00                	push   $0x0
  pushl $118
c0101fab:	6a 76                	push   $0x76
  jmp __alltraps
c0101fad:	e9 51 06 00 00       	jmp    c0102603 <__alltraps>

c0101fb2 <vector119>:
.globl vector119
vector119:
  pushl $0
c0101fb2:	6a 00                	push   $0x0
  pushl $119
c0101fb4:	6a 77                	push   $0x77
  jmp __alltraps
c0101fb6:	e9 48 06 00 00       	jmp    c0102603 <__alltraps>

c0101fbb <vector120>:
.globl vector120
vector120:
  pushl $0
c0101fbb:	6a 00                	push   $0x0
  pushl $120
c0101fbd:	6a 78                	push   $0x78
  jmp __alltraps
c0101fbf:	e9 3f 06 00 00       	jmp    c0102603 <__alltraps>

c0101fc4 <vector121>:
.globl vector121
vector121:
  pushl $0
c0101fc4:	6a 00                	push   $0x0
  pushl $121
c0101fc6:	6a 79                	push   $0x79
  jmp __alltraps
c0101fc8:	e9 36 06 00 00       	jmp    c0102603 <__alltraps>

c0101fcd <vector122>:
.globl vector122
vector122:
  pushl $0
c0101fcd:	6a 00                	push   $0x0
  pushl $122
c0101fcf:	6a 7a                	push   $0x7a
  jmp __alltraps
c0101fd1:	e9 2d 06 00 00       	jmp    c0102603 <__alltraps>

c0101fd6 <vector123>:
.globl vector123
vector123:
  pushl $0
c0101fd6:	6a 00                	push   $0x0
  pushl $123
c0101fd8:	6a 7b                	push   $0x7b
  jmp __alltraps
c0101fda:	e9 24 06 00 00       	jmp    c0102603 <__alltraps>

c0101fdf <vector124>:
.globl vector124
vector124:
  pushl $0
c0101fdf:	6a 00                	push   $0x0
  pushl $124
c0101fe1:	6a 7c                	push   $0x7c
  jmp __alltraps
c0101fe3:	e9 1b 06 00 00       	jmp    c0102603 <__alltraps>

c0101fe8 <vector125>:
.globl vector125
vector125:
  pushl $0
c0101fe8:	6a 00                	push   $0x0
  pushl $125
c0101fea:	6a 7d                	push   $0x7d
  jmp __alltraps
c0101fec:	e9 12 06 00 00       	jmp    c0102603 <__alltraps>

c0101ff1 <vector126>:
.globl vector126
vector126:
  pushl $0
c0101ff1:	6a 00                	push   $0x0
  pushl $126
c0101ff3:	6a 7e                	push   $0x7e
  jmp __alltraps
c0101ff5:	e9 09 06 00 00       	jmp    c0102603 <__alltraps>

c0101ffa <vector127>:
.globl vector127
vector127:
  pushl $0
c0101ffa:	6a 00                	push   $0x0
  pushl $127
c0101ffc:	6a 7f                	push   $0x7f
  jmp __alltraps
c0101ffe:	e9 00 06 00 00       	jmp    c0102603 <__alltraps>

c0102003 <vector128>:
.globl vector128
vector128:
  pushl $0
c0102003:	6a 00                	push   $0x0
  pushl $128
c0102005:	68 80 00 00 00       	push   $0x80
  jmp __alltraps
c010200a:	e9 f4 05 00 00       	jmp    c0102603 <__alltraps>

c010200f <vector129>:
.globl vector129
vector129:
  pushl $0
c010200f:	6a 00                	push   $0x0
  pushl $129
c0102011:	68 81 00 00 00       	push   $0x81
  jmp __alltraps
c0102016:	e9 e8 05 00 00       	jmp    c0102603 <__alltraps>

c010201b <vector130>:
.globl vector130
vector130:
  pushl $0
c010201b:	6a 00                	push   $0x0
  pushl $130
c010201d:	68 82 00 00 00       	push   $0x82
  jmp __alltraps
c0102022:	e9 dc 05 00 00       	jmp    c0102603 <__alltraps>

c0102027 <vector131>:
.globl vector131
vector131:
  pushl $0
c0102027:	6a 00                	push   $0x0
  pushl $131
c0102029:	68 83 00 00 00       	push   $0x83
  jmp __alltraps
c010202e:	e9 d0 05 00 00       	jmp    c0102603 <__alltraps>

c0102033 <vector132>:
.globl vector132
vector132:
  pushl $0
c0102033:	6a 00                	push   $0x0
  pushl $132
c0102035:	68 84 00 00 00       	push   $0x84
  jmp __alltraps
c010203a:	e9 c4 05 00 00       	jmp    c0102603 <__alltraps>

c010203f <vector133>:
.globl vector133
vector133:
  pushl $0
c010203f:	6a 00                	push   $0x0
  pushl $133
c0102041:	68 85 00 00 00       	push   $0x85
  jmp __alltraps
c0102046:	e9 b8 05 00 00       	jmp    c0102603 <__alltraps>

c010204b <vector134>:
.globl vector134
vector134:
  pushl $0
c010204b:	6a 00                	push   $0x0
  pushl $134
c010204d:	68 86 00 00 00       	push   $0x86
  jmp __alltraps
c0102052:	e9 ac 05 00 00       	jmp    c0102603 <__alltraps>

c0102057 <vector135>:
.globl vector135
vector135:
  pushl $0
c0102057:	6a 00                	push   $0x0
  pushl $135
c0102059:	68 87 00 00 00       	push   $0x87
  jmp __alltraps
c010205e:	e9 a0 05 00 00       	jmp    c0102603 <__alltraps>

c0102063 <vector136>:
.globl vector136
vector136:
  pushl $0
c0102063:	6a 00                	push   $0x0
  pushl $136
c0102065:	68 88 00 00 00       	push   $0x88
  jmp __alltraps
c010206a:	e9 94 05 00 00       	jmp    c0102603 <__alltraps>

c010206f <vector137>:
.globl vector137
vector137:
  pushl $0
c010206f:	6a 00                	push   $0x0
  pushl $137
c0102071:	68 89 00 00 00       	push   $0x89
  jmp __alltraps
c0102076:	e9 88 05 00 00       	jmp    c0102603 <__alltraps>

c010207b <vector138>:
.globl vector138
vector138:
  pushl $0
c010207b:	6a 00                	push   $0x0
  pushl $138
c010207d:	68 8a 00 00 00       	push   $0x8a
  jmp __alltraps
c0102082:	e9 7c 05 00 00       	jmp    c0102603 <__alltraps>

c0102087 <vector139>:
.globl vector139
vector139:
  pushl $0
c0102087:	6a 00                	push   $0x0
  pushl $139
c0102089:	68 8b 00 00 00       	push   $0x8b
  jmp __alltraps
c010208e:	e9 70 05 00 00       	jmp    c0102603 <__alltraps>

c0102093 <vector140>:
.globl vector140
vector140:
  pushl $0
c0102093:	6a 00                	push   $0x0
  pushl $140
c0102095:	68 8c 00 00 00       	push   $0x8c
  jmp __alltraps
c010209a:	e9 64 05 00 00       	jmp    c0102603 <__alltraps>

c010209f <vector141>:
.globl vector141
vector141:
  pushl $0
c010209f:	6a 00                	push   $0x0
  pushl $141
c01020a1:	68 8d 00 00 00       	push   $0x8d
  jmp __alltraps
c01020a6:	e9 58 05 00 00       	jmp    c0102603 <__alltraps>

c01020ab <vector142>:
.globl vector142
vector142:
  pushl $0
c01020ab:	6a 00                	push   $0x0
  pushl $142
c01020ad:	68 8e 00 00 00       	push   $0x8e
  jmp __alltraps
c01020b2:	e9 4c 05 00 00       	jmp    c0102603 <__alltraps>

c01020b7 <vector143>:
.globl vector143
vector143:
  pushl $0
c01020b7:	6a 00                	push   $0x0
  pushl $143
c01020b9:	68 8f 00 00 00       	push   $0x8f
  jmp __alltraps
c01020be:	e9 40 05 00 00       	jmp    c0102603 <__alltraps>

c01020c3 <vector144>:
.globl vector144
vector144:
  pushl $0
c01020c3:	6a 00                	push   $0x0
  pushl $144
c01020c5:	68 90 00 00 00       	push   $0x90
  jmp __alltraps
c01020ca:	e9 34 05 00 00       	jmp    c0102603 <__alltraps>

c01020cf <vector145>:
.globl vector145
vector145:
  pushl $0
c01020cf:	6a 00                	push   $0x0
  pushl $145
c01020d1:	68 91 00 00 00       	push   $0x91
  jmp __alltraps
c01020d6:	e9 28 05 00 00       	jmp    c0102603 <__alltraps>

c01020db <vector146>:
.globl vector146
vector146:
  pushl $0
c01020db:	6a 00                	push   $0x0
  pushl $146
c01020dd:	68 92 00 00 00       	push   $0x92
  jmp __alltraps
c01020e2:	e9 1c 05 00 00       	jmp    c0102603 <__alltraps>

c01020e7 <vector147>:
.globl vector147
vector147:
  pushl $0
c01020e7:	6a 00                	push   $0x0
  pushl $147
c01020e9:	68 93 00 00 00       	push   $0x93
  jmp __alltraps
c01020ee:	e9 10 05 00 00       	jmp    c0102603 <__alltraps>

c01020f3 <vector148>:
.globl vector148
vector148:
  pushl $0
c01020f3:	6a 00                	push   $0x0
  pushl $148
c01020f5:	68 94 00 00 00       	push   $0x94
  jmp __alltraps
c01020fa:	e9 04 05 00 00       	jmp    c0102603 <__alltraps>

c01020ff <vector149>:
.globl vector149
vector149:
  pushl $0
c01020ff:	6a 00                	push   $0x0
  pushl $149
c0102101:	68 95 00 00 00       	push   $0x95
  jmp __alltraps
c0102106:	e9 f8 04 00 00       	jmp    c0102603 <__alltraps>

c010210b <vector150>:
.globl vector150
vector150:
  pushl $0
c010210b:	6a 00                	push   $0x0
  pushl $150
c010210d:	68 96 00 00 00       	push   $0x96
  jmp __alltraps
c0102112:	e9 ec 04 00 00       	jmp    c0102603 <__alltraps>

c0102117 <vector151>:
.globl vector151
vector151:
  pushl $0
c0102117:	6a 00                	push   $0x0
  pushl $151
c0102119:	68 97 00 00 00       	push   $0x97
  jmp __alltraps
c010211e:	e9 e0 04 00 00       	jmp    c0102603 <__alltraps>

c0102123 <vector152>:
.globl vector152
vector152:
  pushl $0
c0102123:	6a 00                	push   $0x0
  pushl $152
c0102125:	68 98 00 00 00       	push   $0x98
  jmp __alltraps
c010212a:	e9 d4 04 00 00       	jmp    c0102603 <__alltraps>

c010212f <vector153>:
.globl vector153
vector153:
  pushl $0
c010212f:	6a 00                	push   $0x0
  pushl $153
c0102131:	68 99 00 00 00       	push   $0x99
  jmp __alltraps
c0102136:	e9 c8 04 00 00       	jmp    c0102603 <__alltraps>

c010213b <vector154>:
.globl vector154
vector154:
  pushl $0
c010213b:	6a 00                	push   $0x0
  pushl $154
c010213d:	68 9a 00 00 00       	push   $0x9a
  jmp __alltraps
c0102142:	e9 bc 04 00 00       	jmp    c0102603 <__alltraps>

c0102147 <vector155>:
.globl vector155
vector155:
  pushl $0
c0102147:	6a 00                	push   $0x0
  pushl $155
c0102149:	68 9b 00 00 00       	push   $0x9b
  jmp __alltraps
c010214e:	e9 b0 04 00 00       	jmp    c0102603 <__alltraps>

c0102153 <vector156>:
.globl vector156
vector156:
  pushl $0
c0102153:	6a 00                	push   $0x0
  pushl $156
c0102155:	68 9c 00 00 00       	push   $0x9c
  jmp __alltraps
c010215a:	e9 a4 04 00 00       	jmp    c0102603 <__alltraps>

c010215f <vector157>:
.globl vector157
vector157:
  pushl $0
c010215f:	6a 00                	push   $0x0
  pushl $157
c0102161:	68 9d 00 00 00       	push   $0x9d
  jmp __alltraps
c0102166:	e9 98 04 00 00       	jmp    c0102603 <__alltraps>

c010216b <vector158>:
.globl vector158
vector158:
  pushl $0
c010216b:	6a 00                	push   $0x0
  pushl $158
c010216d:	68 9e 00 00 00       	push   $0x9e
  jmp __alltraps
c0102172:	e9 8c 04 00 00       	jmp    c0102603 <__alltraps>

c0102177 <vector159>:
.globl vector159
vector159:
  pushl $0
c0102177:	6a 00                	push   $0x0
  pushl $159
c0102179:	68 9f 00 00 00       	push   $0x9f
  jmp __alltraps
c010217e:	e9 80 04 00 00       	jmp    c0102603 <__alltraps>

c0102183 <vector160>:
.globl vector160
vector160:
  pushl $0
c0102183:	6a 00                	push   $0x0
  pushl $160
c0102185:	68 a0 00 00 00       	push   $0xa0
  jmp __alltraps
c010218a:	e9 74 04 00 00       	jmp    c0102603 <__alltraps>

c010218f <vector161>:
.globl vector161
vector161:
  pushl $0
c010218f:	6a 00                	push   $0x0
  pushl $161
c0102191:	68 a1 00 00 00       	push   $0xa1
  jmp __alltraps
c0102196:	e9 68 04 00 00       	jmp    c0102603 <__alltraps>

c010219b <vector162>:
.globl vector162
vector162:
  pushl $0
c010219b:	6a 00                	push   $0x0
  pushl $162
c010219d:	68 a2 00 00 00       	push   $0xa2
  jmp __alltraps
c01021a2:	e9 5c 04 00 00       	jmp    c0102603 <__alltraps>

c01021a7 <vector163>:
.globl vector163
vector163:
  pushl $0
c01021a7:	6a 00                	push   $0x0
  pushl $163
c01021a9:	68 a3 00 00 00       	push   $0xa3
  jmp __alltraps
c01021ae:	e9 50 04 00 00       	jmp    c0102603 <__alltraps>

c01021b3 <vector164>:
.globl vector164
vector164:
  pushl $0
c01021b3:	6a 00                	push   $0x0
  pushl $164
c01021b5:	68 a4 00 00 00       	push   $0xa4
  jmp __alltraps
c01021ba:	e9 44 04 00 00       	jmp    c0102603 <__alltraps>

c01021bf <vector165>:
.globl vector165
vector165:
  pushl $0
c01021bf:	6a 00                	push   $0x0
  pushl $165
c01021c1:	68 a5 00 00 00       	push   $0xa5
  jmp __alltraps
c01021c6:	e9 38 04 00 00       	jmp    c0102603 <__alltraps>

c01021cb <vector166>:
.globl vector166
vector166:
  pushl $0
c01021cb:	6a 00                	push   $0x0
  pushl $166
c01021cd:	68 a6 00 00 00       	push   $0xa6
  jmp __alltraps
c01021d2:	e9 2c 04 00 00       	jmp    c0102603 <__alltraps>

c01021d7 <vector167>:
.globl vector167
vector167:
  pushl $0
c01021d7:	6a 00                	push   $0x0
  pushl $167
c01021d9:	68 a7 00 00 00       	push   $0xa7
  jmp __alltraps
c01021de:	e9 20 04 00 00       	jmp    c0102603 <__alltraps>

c01021e3 <vector168>:
.globl vector168
vector168:
  pushl $0
c01021e3:	6a 00                	push   $0x0
  pushl $168
c01021e5:	68 a8 00 00 00       	push   $0xa8
  jmp __alltraps
c01021ea:	e9 14 04 00 00       	jmp    c0102603 <__alltraps>

c01021ef <vector169>:
.globl vector169
vector169:
  pushl $0
c01021ef:	6a 00                	push   $0x0
  pushl $169
c01021f1:	68 a9 00 00 00       	push   $0xa9
  jmp __alltraps
c01021f6:	e9 08 04 00 00       	jmp    c0102603 <__alltraps>

c01021fb <vector170>:
.globl vector170
vector170:
  pushl $0
c01021fb:	6a 00                	push   $0x0
  pushl $170
c01021fd:	68 aa 00 00 00       	push   $0xaa
  jmp __alltraps
c0102202:	e9 fc 03 00 00       	jmp    c0102603 <__alltraps>

c0102207 <vector171>:
.globl vector171
vector171:
  pushl $0
c0102207:	6a 00                	push   $0x0
  pushl $171
c0102209:	68 ab 00 00 00       	push   $0xab
  jmp __alltraps
c010220e:	e9 f0 03 00 00       	jmp    c0102603 <__alltraps>

c0102213 <vector172>:
.globl vector172
vector172:
  pushl $0
c0102213:	6a 00                	push   $0x0
  pushl $172
c0102215:	68 ac 00 00 00       	push   $0xac
  jmp __alltraps
c010221a:	e9 e4 03 00 00       	jmp    c0102603 <__alltraps>

c010221f <vector173>:
.globl vector173
vector173:
  pushl $0
c010221f:	6a 00                	push   $0x0
  pushl $173
c0102221:	68 ad 00 00 00       	push   $0xad
  jmp __alltraps
c0102226:	e9 d8 03 00 00       	jmp    c0102603 <__alltraps>

c010222b <vector174>:
.globl vector174
vector174:
  pushl $0
c010222b:	6a 00                	push   $0x0
  pushl $174
c010222d:	68 ae 00 00 00       	push   $0xae
  jmp __alltraps
c0102232:	e9 cc 03 00 00       	jmp    c0102603 <__alltraps>

c0102237 <vector175>:
.globl vector175
vector175:
  pushl $0
c0102237:	6a 00                	push   $0x0
  pushl $175
c0102239:	68 af 00 00 00       	push   $0xaf
  jmp __alltraps
c010223e:	e9 c0 03 00 00       	jmp    c0102603 <__alltraps>

c0102243 <vector176>:
.globl vector176
vector176:
  pushl $0
c0102243:	6a 00                	push   $0x0
  pushl $176
c0102245:	68 b0 00 00 00       	push   $0xb0
  jmp __alltraps
c010224a:	e9 b4 03 00 00       	jmp    c0102603 <__alltraps>

c010224f <vector177>:
.globl vector177
vector177:
  pushl $0
c010224f:	6a 00                	push   $0x0
  pushl $177
c0102251:	68 b1 00 00 00       	push   $0xb1
  jmp __alltraps
c0102256:	e9 a8 03 00 00       	jmp    c0102603 <__alltraps>

c010225b <vector178>:
.globl vector178
vector178:
  pushl $0
c010225b:	6a 00                	push   $0x0
  pushl $178
c010225d:	68 b2 00 00 00       	push   $0xb2
  jmp __alltraps
c0102262:	e9 9c 03 00 00       	jmp    c0102603 <__alltraps>

c0102267 <vector179>:
.globl vector179
vector179:
  pushl $0
c0102267:	6a 00                	push   $0x0
  pushl $179
c0102269:	68 b3 00 00 00       	push   $0xb3
  jmp __alltraps
c010226e:	e9 90 03 00 00       	jmp    c0102603 <__alltraps>

c0102273 <vector180>:
.globl vector180
vector180:
  pushl $0
c0102273:	6a 00                	push   $0x0
  pushl $180
c0102275:	68 b4 00 00 00       	push   $0xb4
  jmp __alltraps
c010227a:	e9 84 03 00 00       	jmp    c0102603 <__alltraps>

c010227f <vector181>:
.globl vector181
vector181:
  pushl $0
c010227f:	6a 00                	push   $0x0
  pushl $181
c0102281:	68 b5 00 00 00       	push   $0xb5
  jmp __alltraps
c0102286:	e9 78 03 00 00       	jmp    c0102603 <__alltraps>

c010228b <vector182>:
.globl vector182
vector182:
  pushl $0
c010228b:	6a 00                	push   $0x0
  pushl $182
c010228d:	68 b6 00 00 00       	push   $0xb6
  jmp __alltraps
c0102292:	e9 6c 03 00 00       	jmp    c0102603 <__alltraps>

c0102297 <vector183>:
.globl vector183
vector183:
  pushl $0
c0102297:	6a 00                	push   $0x0
  pushl $183
c0102299:	68 b7 00 00 00       	push   $0xb7
  jmp __alltraps
c010229e:	e9 60 03 00 00       	jmp    c0102603 <__alltraps>

c01022a3 <vector184>:
.globl vector184
vector184:
  pushl $0
c01022a3:	6a 00                	push   $0x0
  pushl $184
c01022a5:	68 b8 00 00 00       	push   $0xb8
  jmp __alltraps
c01022aa:	e9 54 03 00 00       	jmp    c0102603 <__alltraps>

c01022af <vector185>:
.globl vector185
vector185:
  pushl $0
c01022af:	6a 00                	push   $0x0
  pushl $185
c01022b1:	68 b9 00 00 00       	push   $0xb9
  jmp __alltraps
c01022b6:	e9 48 03 00 00       	jmp    c0102603 <__alltraps>

c01022bb <vector186>:
.globl vector186
vector186:
  pushl $0
c01022bb:	6a 00                	push   $0x0
  pushl $186
c01022bd:	68 ba 00 00 00       	push   $0xba
  jmp __alltraps
c01022c2:	e9 3c 03 00 00       	jmp    c0102603 <__alltraps>

c01022c7 <vector187>:
.globl vector187
vector187:
  pushl $0
c01022c7:	6a 00                	push   $0x0
  pushl $187
c01022c9:	68 bb 00 00 00       	push   $0xbb
  jmp __alltraps
c01022ce:	e9 30 03 00 00       	jmp    c0102603 <__alltraps>

c01022d3 <vector188>:
.globl vector188
vector188:
  pushl $0
c01022d3:	6a 00                	push   $0x0
  pushl $188
c01022d5:	68 bc 00 00 00       	push   $0xbc
  jmp __alltraps
c01022da:	e9 24 03 00 00       	jmp    c0102603 <__alltraps>

c01022df <vector189>:
.globl vector189
vector189:
  pushl $0
c01022df:	6a 00                	push   $0x0
  pushl $189
c01022e1:	68 bd 00 00 00       	push   $0xbd
  jmp __alltraps
c01022e6:	e9 18 03 00 00       	jmp    c0102603 <__alltraps>

c01022eb <vector190>:
.globl vector190
vector190:
  pushl $0
c01022eb:	6a 00                	push   $0x0
  pushl $190
c01022ed:	68 be 00 00 00       	push   $0xbe
  jmp __alltraps
c01022f2:	e9 0c 03 00 00       	jmp    c0102603 <__alltraps>

c01022f7 <vector191>:
.globl vector191
vector191:
  pushl $0
c01022f7:	6a 00                	push   $0x0
  pushl $191
c01022f9:	68 bf 00 00 00       	push   $0xbf
  jmp __alltraps
c01022fe:	e9 00 03 00 00       	jmp    c0102603 <__alltraps>

c0102303 <vector192>:
.globl vector192
vector192:
  pushl $0
c0102303:	6a 00                	push   $0x0
  pushl $192
c0102305:	68 c0 00 00 00       	push   $0xc0
  jmp __alltraps
c010230a:	e9 f4 02 00 00       	jmp    c0102603 <__alltraps>

c010230f <vector193>:
.globl vector193
vector193:
  pushl $0
c010230f:	6a 00                	push   $0x0
  pushl $193
c0102311:	68 c1 00 00 00       	push   $0xc1
  jmp __alltraps
c0102316:	e9 e8 02 00 00       	jmp    c0102603 <__alltraps>

c010231b <vector194>:
.globl vector194
vector194:
  pushl $0
c010231b:	6a 00                	push   $0x0
  pushl $194
c010231d:	68 c2 00 00 00       	push   $0xc2
  jmp __alltraps
c0102322:	e9 dc 02 00 00       	jmp    c0102603 <__alltraps>

c0102327 <vector195>:
.globl vector195
vector195:
  pushl $0
c0102327:	6a 00                	push   $0x0
  pushl $195
c0102329:	68 c3 00 00 00       	push   $0xc3
  jmp __alltraps
c010232e:	e9 d0 02 00 00       	jmp    c0102603 <__alltraps>

c0102333 <vector196>:
.globl vector196
vector196:
  pushl $0
c0102333:	6a 00                	push   $0x0
  pushl $196
c0102335:	68 c4 00 00 00       	push   $0xc4
  jmp __alltraps
c010233a:	e9 c4 02 00 00       	jmp    c0102603 <__alltraps>

c010233f <vector197>:
.globl vector197
vector197:
  pushl $0
c010233f:	6a 00                	push   $0x0
  pushl $197
c0102341:	68 c5 00 00 00       	push   $0xc5
  jmp __alltraps
c0102346:	e9 b8 02 00 00       	jmp    c0102603 <__alltraps>

c010234b <vector198>:
.globl vector198
vector198:
  pushl $0
c010234b:	6a 00                	push   $0x0
  pushl $198
c010234d:	68 c6 00 00 00       	push   $0xc6
  jmp __alltraps
c0102352:	e9 ac 02 00 00       	jmp    c0102603 <__alltraps>

c0102357 <vector199>:
.globl vector199
vector199:
  pushl $0
c0102357:	6a 00                	push   $0x0
  pushl $199
c0102359:	68 c7 00 00 00       	push   $0xc7
  jmp __alltraps
c010235e:	e9 a0 02 00 00       	jmp    c0102603 <__alltraps>

c0102363 <vector200>:
.globl vector200
vector200:
  pushl $0
c0102363:	6a 00                	push   $0x0
  pushl $200
c0102365:	68 c8 00 00 00       	push   $0xc8
  jmp __alltraps
c010236a:	e9 94 02 00 00       	jmp    c0102603 <__alltraps>

c010236f <vector201>:
.globl vector201
vector201:
  pushl $0
c010236f:	6a 00                	push   $0x0
  pushl $201
c0102371:	68 c9 00 00 00       	push   $0xc9
  jmp __alltraps
c0102376:	e9 88 02 00 00       	jmp    c0102603 <__alltraps>

c010237b <vector202>:
.globl vector202
vector202:
  pushl $0
c010237b:	6a 00                	push   $0x0
  pushl $202
c010237d:	68 ca 00 00 00       	push   $0xca
  jmp __alltraps
c0102382:	e9 7c 02 00 00       	jmp    c0102603 <__alltraps>

c0102387 <vector203>:
.globl vector203
vector203:
  pushl $0
c0102387:	6a 00                	push   $0x0
  pushl $203
c0102389:	68 cb 00 00 00       	push   $0xcb
  jmp __alltraps
c010238e:	e9 70 02 00 00       	jmp    c0102603 <__alltraps>

c0102393 <vector204>:
.globl vector204
vector204:
  pushl $0
c0102393:	6a 00                	push   $0x0
  pushl $204
c0102395:	68 cc 00 00 00       	push   $0xcc
  jmp __alltraps
c010239a:	e9 64 02 00 00       	jmp    c0102603 <__alltraps>

c010239f <vector205>:
.globl vector205
vector205:
  pushl $0
c010239f:	6a 00                	push   $0x0
  pushl $205
c01023a1:	68 cd 00 00 00       	push   $0xcd
  jmp __alltraps
c01023a6:	e9 58 02 00 00       	jmp    c0102603 <__alltraps>

c01023ab <vector206>:
.globl vector206
vector206:
  pushl $0
c01023ab:	6a 00                	push   $0x0
  pushl $206
c01023ad:	68 ce 00 00 00       	push   $0xce
  jmp __alltraps
c01023b2:	e9 4c 02 00 00       	jmp    c0102603 <__alltraps>

c01023b7 <vector207>:
.globl vector207
vector207:
  pushl $0
c01023b7:	6a 00                	push   $0x0
  pushl $207
c01023b9:	68 cf 00 00 00       	push   $0xcf
  jmp __alltraps
c01023be:	e9 40 02 00 00       	jmp    c0102603 <__alltraps>

c01023c3 <vector208>:
.globl vector208
vector208:
  pushl $0
c01023c3:	6a 00                	push   $0x0
  pushl $208
c01023c5:	68 d0 00 00 00       	push   $0xd0
  jmp __alltraps
c01023ca:	e9 34 02 00 00       	jmp    c0102603 <__alltraps>

c01023cf <vector209>:
.globl vector209
vector209:
  pushl $0
c01023cf:	6a 00                	push   $0x0
  pushl $209
c01023d1:	68 d1 00 00 00       	push   $0xd1
  jmp __alltraps
c01023d6:	e9 28 02 00 00       	jmp    c0102603 <__alltraps>

c01023db <vector210>:
.globl vector210
vector210:
  pushl $0
c01023db:	6a 00                	push   $0x0
  pushl $210
c01023dd:	68 d2 00 00 00       	push   $0xd2
  jmp __alltraps
c01023e2:	e9 1c 02 00 00       	jmp    c0102603 <__alltraps>

c01023e7 <vector211>:
.globl vector211
vector211:
  pushl $0
c01023e7:	6a 00                	push   $0x0
  pushl $211
c01023e9:	68 d3 00 00 00       	push   $0xd3
  jmp __alltraps
c01023ee:	e9 10 02 00 00       	jmp    c0102603 <__alltraps>

c01023f3 <vector212>:
.globl vector212
vector212:
  pushl $0
c01023f3:	6a 00                	push   $0x0
  pushl $212
c01023f5:	68 d4 00 00 00       	push   $0xd4
  jmp __alltraps
c01023fa:	e9 04 02 00 00       	jmp    c0102603 <__alltraps>

c01023ff <vector213>:
.globl vector213
vector213:
  pushl $0
c01023ff:	6a 00                	push   $0x0
  pushl $213
c0102401:	68 d5 00 00 00       	push   $0xd5
  jmp __alltraps
c0102406:	e9 f8 01 00 00       	jmp    c0102603 <__alltraps>

c010240b <vector214>:
.globl vector214
vector214:
  pushl $0
c010240b:	6a 00                	push   $0x0
  pushl $214
c010240d:	68 d6 00 00 00       	push   $0xd6
  jmp __alltraps
c0102412:	e9 ec 01 00 00       	jmp    c0102603 <__alltraps>

c0102417 <vector215>:
.globl vector215
vector215:
  pushl $0
c0102417:	6a 00                	push   $0x0
  pushl $215
c0102419:	68 d7 00 00 00       	push   $0xd7
  jmp __alltraps
c010241e:	e9 e0 01 00 00       	jmp    c0102603 <__alltraps>

c0102423 <vector216>:
.globl vector216
vector216:
  pushl $0
c0102423:	6a 00                	push   $0x0
  pushl $216
c0102425:	68 d8 00 00 00       	push   $0xd8
  jmp __alltraps
c010242a:	e9 d4 01 00 00       	jmp    c0102603 <__alltraps>

c010242f <vector217>:
.globl vector217
vector217:
  pushl $0
c010242f:	6a 00                	push   $0x0
  pushl $217
c0102431:	68 d9 00 00 00       	push   $0xd9
  jmp __alltraps
c0102436:	e9 c8 01 00 00       	jmp    c0102603 <__alltraps>

c010243b <vector218>:
.globl vector218
vector218:
  pushl $0
c010243b:	6a 00                	push   $0x0
  pushl $218
c010243d:	68 da 00 00 00       	push   $0xda
  jmp __alltraps
c0102442:	e9 bc 01 00 00       	jmp    c0102603 <__alltraps>

c0102447 <vector219>:
.globl vector219
vector219:
  pushl $0
c0102447:	6a 00                	push   $0x0
  pushl $219
c0102449:	68 db 00 00 00       	push   $0xdb
  jmp __alltraps
c010244e:	e9 b0 01 00 00       	jmp    c0102603 <__alltraps>

c0102453 <vector220>:
.globl vector220
vector220:
  pushl $0
c0102453:	6a 00                	push   $0x0
  pushl $220
c0102455:	68 dc 00 00 00       	push   $0xdc
  jmp __alltraps
c010245a:	e9 a4 01 00 00       	jmp    c0102603 <__alltraps>

c010245f <vector221>:
.globl vector221
vector221:
  pushl $0
c010245f:	6a 00                	push   $0x0
  pushl $221
c0102461:	68 dd 00 00 00       	push   $0xdd
  jmp __alltraps
c0102466:	e9 98 01 00 00       	jmp    c0102603 <__alltraps>

c010246b <vector222>:
.globl vector222
vector222:
  pushl $0
c010246b:	6a 00                	push   $0x0
  pushl $222
c010246d:	68 de 00 00 00       	push   $0xde
  jmp __alltraps
c0102472:	e9 8c 01 00 00       	jmp    c0102603 <__alltraps>

c0102477 <vector223>:
.globl vector223
vector223:
  pushl $0
c0102477:	6a 00                	push   $0x0
  pushl $223
c0102479:	68 df 00 00 00       	push   $0xdf
  jmp __alltraps
c010247e:	e9 80 01 00 00       	jmp    c0102603 <__alltraps>

c0102483 <vector224>:
.globl vector224
vector224:
  pushl $0
c0102483:	6a 00                	push   $0x0
  pushl $224
c0102485:	68 e0 00 00 00       	push   $0xe0
  jmp __alltraps
c010248a:	e9 74 01 00 00       	jmp    c0102603 <__alltraps>

c010248f <vector225>:
.globl vector225
vector225:
  pushl $0
c010248f:	6a 00                	push   $0x0
  pushl $225
c0102491:	68 e1 00 00 00       	push   $0xe1
  jmp __alltraps
c0102496:	e9 68 01 00 00       	jmp    c0102603 <__alltraps>

c010249b <vector226>:
.globl vector226
vector226:
  pushl $0
c010249b:	6a 00                	push   $0x0
  pushl $226
c010249d:	68 e2 00 00 00       	push   $0xe2
  jmp __alltraps
c01024a2:	e9 5c 01 00 00       	jmp    c0102603 <__alltraps>

c01024a7 <vector227>:
.globl vector227
vector227:
  pushl $0
c01024a7:	6a 00                	push   $0x0
  pushl $227
c01024a9:	68 e3 00 00 00       	push   $0xe3
  jmp __alltraps
c01024ae:	e9 50 01 00 00       	jmp    c0102603 <__alltraps>

c01024b3 <vector228>:
.globl vector228
vector228:
  pushl $0
c01024b3:	6a 00                	push   $0x0
  pushl $228
c01024b5:	68 e4 00 00 00       	push   $0xe4
  jmp __alltraps
c01024ba:	e9 44 01 00 00       	jmp    c0102603 <__alltraps>

c01024bf <vector229>:
.globl vector229
vector229:
  pushl $0
c01024bf:	6a 00                	push   $0x0
  pushl $229
c01024c1:	68 e5 00 00 00       	push   $0xe5
  jmp __alltraps
c01024c6:	e9 38 01 00 00       	jmp    c0102603 <__alltraps>

c01024cb <vector230>:
.globl vector230
vector230:
  pushl $0
c01024cb:	6a 00                	push   $0x0
  pushl $230
c01024cd:	68 e6 00 00 00       	push   $0xe6
  jmp __alltraps
c01024d2:	e9 2c 01 00 00       	jmp    c0102603 <__alltraps>

c01024d7 <vector231>:
.globl vector231
vector231:
  pushl $0
c01024d7:	6a 00                	push   $0x0
  pushl $231
c01024d9:	68 e7 00 00 00       	push   $0xe7
  jmp __alltraps
c01024de:	e9 20 01 00 00       	jmp    c0102603 <__alltraps>

c01024e3 <vector232>:
.globl vector232
vector232:
  pushl $0
c01024e3:	6a 00                	push   $0x0
  pushl $232
c01024e5:	68 e8 00 00 00       	push   $0xe8
  jmp __alltraps
c01024ea:	e9 14 01 00 00       	jmp    c0102603 <__alltraps>

c01024ef <vector233>:
.globl vector233
vector233:
  pushl $0
c01024ef:	6a 00                	push   $0x0
  pushl $233
c01024f1:	68 e9 00 00 00       	push   $0xe9
  jmp __alltraps
c01024f6:	e9 08 01 00 00       	jmp    c0102603 <__alltraps>

c01024fb <vector234>:
.globl vector234
vector234:
  pushl $0
c01024fb:	6a 00                	push   $0x0
  pushl $234
c01024fd:	68 ea 00 00 00       	push   $0xea
  jmp __alltraps
c0102502:	e9 fc 00 00 00       	jmp    c0102603 <__alltraps>

c0102507 <vector235>:
.globl vector235
vector235:
  pushl $0
c0102507:	6a 00                	push   $0x0
  pushl $235
c0102509:	68 eb 00 00 00       	push   $0xeb
  jmp __alltraps
c010250e:	e9 f0 00 00 00       	jmp    c0102603 <__alltraps>

c0102513 <vector236>:
.globl vector236
vector236:
  pushl $0
c0102513:	6a 00                	push   $0x0
  pushl $236
c0102515:	68 ec 00 00 00       	push   $0xec
  jmp __alltraps
c010251a:	e9 e4 00 00 00       	jmp    c0102603 <__alltraps>

c010251f <vector237>:
.globl vector237
vector237:
  pushl $0
c010251f:	6a 00                	push   $0x0
  pushl $237
c0102521:	68 ed 00 00 00       	push   $0xed
  jmp __alltraps
c0102526:	e9 d8 00 00 00       	jmp    c0102603 <__alltraps>

c010252b <vector238>:
.globl vector238
vector238:
  pushl $0
c010252b:	6a 00                	push   $0x0
  pushl $238
c010252d:	68 ee 00 00 00       	push   $0xee
  jmp __alltraps
c0102532:	e9 cc 00 00 00       	jmp    c0102603 <__alltraps>

c0102537 <vector239>:
.globl vector239
vector239:
  pushl $0
c0102537:	6a 00                	push   $0x0
  pushl $239
c0102539:	68 ef 00 00 00       	push   $0xef
  jmp __alltraps
c010253e:	e9 c0 00 00 00       	jmp    c0102603 <__alltraps>

c0102543 <vector240>:
.globl vector240
vector240:
  pushl $0
c0102543:	6a 00                	push   $0x0
  pushl $240
c0102545:	68 f0 00 00 00       	push   $0xf0
  jmp __alltraps
c010254a:	e9 b4 00 00 00       	jmp    c0102603 <__alltraps>

c010254f <vector241>:
.globl vector241
vector241:
  pushl $0
c010254f:	6a 00                	push   $0x0
  pushl $241
c0102551:	68 f1 00 00 00       	push   $0xf1
  jmp __alltraps
c0102556:	e9 a8 00 00 00       	jmp    c0102603 <__alltraps>

c010255b <vector242>:
.globl vector242
vector242:
  pushl $0
c010255b:	6a 00                	push   $0x0
  pushl $242
c010255d:	68 f2 00 00 00       	push   $0xf2
  jmp __alltraps
c0102562:	e9 9c 00 00 00       	jmp    c0102603 <__alltraps>

c0102567 <vector243>:
.globl vector243
vector243:
  pushl $0
c0102567:	6a 00                	push   $0x0
  pushl $243
c0102569:	68 f3 00 00 00       	push   $0xf3
  jmp __alltraps
c010256e:	e9 90 00 00 00       	jmp    c0102603 <__alltraps>

c0102573 <vector244>:
.globl vector244
vector244:
  pushl $0
c0102573:	6a 00                	push   $0x0
  pushl $244
c0102575:	68 f4 00 00 00       	push   $0xf4
  jmp __alltraps
c010257a:	e9 84 00 00 00       	jmp    c0102603 <__alltraps>

c010257f <vector245>:
.globl vector245
vector245:
  pushl $0
c010257f:	6a 00                	push   $0x0
  pushl $245
c0102581:	68 f5 00 00 00       	push   $0xf5
  jmp __alltraps
c0102586:	e9 78 00 00 00       	jmp    c0102603 <__alltraps>

c010258b <vector246>:
.globl vector246
vector246:
  pushl $0
c010258b:	6a 00                	push   $0x0
  pushl $246
c010258d:	68 f6 00 00 00       	push   $0xf6
  jmp __alltraps
c0102592:	e9 6c 00 00 00       	jmp    c0102603 <__alltraps>

c0102597 <vector247>:
.globl vector247
vector247:
  pushl $0
c0102597:	6a 00                	push   $0x0
  pushl $247
c0102599:	68 f7 00 00 00       	push   $0xf7
  jmp __alltraps
c010259e:	e9 60 00 00 00       	jmp    c0102603 <__alltraps>

c01025a3 <vector248>:
.globl vector248
vector248:
  pushl $0
c01025a3:	6a 00                	push   $0x0
  pushl $248
c01025a5:	68 f8 00 00 00       	push   $0xf8
  jmp __alltraps
c01025aa:	e9 54 00 00 00       	jmp    c0102603 <__alltraps>

c01025af <vector249>:
.globl vector249
vector249:
  pushl $0
c01025af:	6a 00                	push   $0x0
  pushl $249
c01025b1:	68 f9 00 00 00       	push   $0xf9
  jmp __alltraps
c01025b6:	e9 48 00 00 00       	jmp    c0102603 <__alltraps>

c01025bb <vector250>:
.globl vector250
vector250:
  pushl $0
c01025bb:	6a 00                	push   $0x0
  pushl $250
c01025bd:	68 fa 00 00 00       	push   $0xfa
  jmp __alltraps
c01025c2:	e9 3c 00 00 00       	jmp    c0102603 <__alltraps>

c01025c7 <vector251>:
.globl vector251
vector251:
  pushl $0
c01025c7:	6a 00                	push   $0x0
  pushl $251
c01025c9:	68 fb 00 00 00       	push   $0xfb
  jmp __alltraps
c01025ce:	e9 30 00 00 00       	jmp    c0102603 <__alltraps>

c01025d3 <vector252>:
.globl vector252
vector252:
  pushl $0
c01025d3:	6a 00                	push   $0x0
  pushl $252
c01025d5:	68 fc 00 00 00       	push   $0xfc
  jmp __alltraps
c01025da:	e9 24 00 00 00       	jmp    c0102603 <__alltraps>

c01025df <vector253>:
.globl vector253
vector253:
  pushl $0
c01025df:	6a 00                	push   $0x0
  pushl $253
c01025e1:	68 fd 00 00 00       	push   $0xfd
  jmp __alltraps
c01025e6:	e9 18 00 00 00       	jmp    c0102603 <__alltraps>

c01025eb <vector254>:
.globl vector254
vector254:
  pushl $0
c01025eb:	6a 00                	push   $0x0
  pushl $254
c01025ed:	68 fe 00 00 00       	push   $0xfe
  jmp __alltraps
c01025f2:	e9 0c 00 00 00       	jmp    c0102603 <__alltraps>

c01025f7 <vector255>:
.globl vector255
vector255:
  pushl $0
c01025f7:	6a 00                	push   $0x0
  pushl $255
c01025f9:	68 ff 00 00 00       	push   $0xff
  jmp __alltraps
c01025fe:	e9 00 00 00 00       	jmp    c0102603 <__alltraps>

c0102603 <__alltraps>:
.text
.globl __alltraps
__alltraps:
    # push registers to build a trap frame
    # therefore make the stack look like a struct trapframe
    pushl %ds
c0102603:	1e                   	push   %ds
    pushl %es
c0102604:	06                   	push   %es
    pushl %fs
c0102605:	0f a0                	push   %fs
    pushl %gs
c0102607:	0f a8                	push   %gs
    pushal
c0102609:	60                   	pusha  

    # load GD_KDATA into %ds and %es to set up data segments for kernel
    movl $GD_KDATA, %eax
c010260a:	b8 10 00 00 00       	mov    $0x10,%eax
    movw %ax, %ds
c010260f:	8e d8                	mov    %eax,%ds
    movw %ax, %es
c0102611:	8e c0                	mov    %eax,%es

    # push %esp to pass a pointer to the trapframe as an argument to trap()
    pushl %esp
c0102613:	54                   	push   %esp

    # call trap(tf), where tf=%esp
    call trap
c0102614:	e8 64 f5 ff ff       	call   c0101b7d <trap>

    # pop the pushed stack pointer
    popl %esp
c0102619:	5c                   	pop    %esp

c010261a <__trapret>:

    # return falls through to trapret...
.globl __trapret
__trapret:
    # restore registers from stack
    popal
c010261a:	61                   	popa   

    # restore %ds, %es, %fs and %gs
    popl %gs
c010261b:	0f a9                	pop    %gs
    popl %fs
c010261d:	0f a1                	pop    %fs
    popl %es
c010261f:	07                   	pop    %es
    popl %ds
c0102620:	1f                   	pop    %ds

    # get rid of the trap number and error code
    addl $0x8, %esp
c0102621:	83 c4 08             	add    $0x8,%esp
    iret
c0102624:	cf                   	iret   

c0102625 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
c0102625:	55                   	push   %ebp
c0102626:	89 e5                	mov    %esp,%ebp
    return page - pages;
c0102628:	8b 45 08             	mov    0x8(%ebp),%eax
c010262b:	8b 15 18 af 11 c0    	mov    0xc011af18,%edx
c0102631:	29 d0                	sub    %edx,%eax
c0102633:	c1 f8 02             	sar    $0x2,%eax
c0102636:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
c010263c:	5d                   	pop    %ebp
c010263d:	c3                   	ret    

c010263e <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
c010263e:	55                   	push   %ebp
c010263f:	89 e5                	mov    %esp,%ebp
c0102641:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
c0102644:	8b 45 08             	mov    0x8(%ebp),%eax
c0102647:	89 04 24             	mov    %eax,(%esp)
c010264a:	e8 d6 ff ff ff       	call   c0102625 <page2ppn>
c010264f:	c1 e0 0c             	shl    $0xc,%eax
}
c0102652:	c9                   	leave  
c0102653:	c3                   	ret    

c0102654 <pa2page>:

static inline struct Page *
pa2page(uintptr_t pa) {
c0102654:	55                   	push   %ebp
c0102655:	89 e5                	mov    %esp,%ebp
c0102657:	83 ec 18             	sub    $0x18,%esp
    if (PPN(pa) >= npage) {
c010265a:	8b 45 08             	mov    0x8(%ebp),%eax
c010265d:	c1 e8 0c             	shr    $0xc,%eax
c0102660:	89 c2                	mov    %eax,%edx
c0102662:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0102667:	39 c2                	cmp    %eax,%edx
c0102669:	72 1c                	jb     c0102687 <pa2page+0x33>
        panic("pa2page called with invalid pa");
c010266b:	c7 44 24 08 90 63 10 	movl   $0xc0106390,0x8(%esp)
c0102672:	c0 
c0102673:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
c010267a:	00 
c010267b:	c7 04 24 af 63 10 c0 	movl   $0xc01063af,(%esp)
c0102682:	e8 62 dd ff ff       	call   c01003e9 <__panic>
    }
    return &pages[PPN(pa)];
c0102687:	8b 0d 18 af 11 c0    	mov    0xc011af18,%ecx
c010268d:	8b 45 08             	mov    0x8(%ebp),%eax
c0102690:	c1 e8 0c             	shr    $0xc,%eax
c0102693:	89 c2                	mov    %eax,%edx
c0102695:	89 d0                	mov    %edx,%eax
c0102697:	c1 e0 02             	shl    $0x2,%eax
c010269a:	01 d0                	add    %edx,%eax
c010269c:	c1 e0 02             	shl    $0x2,%eax
c010269f:	01 c8                	add    %ecx,%eax
}
c01026a1:	c9                   	leave  
c01026a2:	c3                   	ret    

c01026a3 <page2kva>:

static inline void *
page2kva(struct Page *page) {
c01026a3:	55                   	push   %ebp
c01026a4:	89 e5                	mov    %esp,%ebp
c01026a6:	83 ec 28             	sub    $0x28,%esp
    return KADDR(page2pa(page));
c01026a9:	8b 45 08             	mov    0x8(%ebp),%eax
c01026ac:	89 04 24             	mov    %eax,(%esp)
c01026af:	e8 8a ff ff ff       	call   c010263e <page2pa>
c01026b4:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01026b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01026ba:	c1 e8 0c             	shr    $0xc,%eax
c01026bd:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01026c0:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01026c5:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c01026c8:	72 23                	jb     c01026ed <page2kva+0x4a>
c01026ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01026cd:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01026d1:	c7 44 24 08 c0 63 10 	movl   $0xc01063c0,0x8(%esp)
c01026d8:	c0 
c01026d9:	c7 44 24 04 61 00 00 	movl   $0x61,0x4(%esp)
c01026e0:	00 
c01026e1:	c7 04 24 af 63 10 c0 	movl   $0xc01063af,(%esp)
c01026e8:	e8 fc dc ff ff       	call   c01003e9 <__panic>
c01026ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01026f0:	2d 00 00 00 40       	sub    $0x40000000,%eax
}
c01026f5:	c9                   	leave  
c01026f6:	c3                   	ret    

c01026f7 <pte2page>:
kva2page(void *kva) {
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte) {
c01026f7:	55                   	push   %ebp
c01026f8:	89 e5                	mov    %esp,%ebp
c01026fa:	83 ec 18             	sub    $0x18,%esp
    if (!(pte & PTE_P)) {
c01026fd:	8b 45 08             	mov    0x8(%ebp),%eax
c0102700:	83 e0 01             	and    $0x1,%eax
c0102703:	85 c0                	test   %eax,%eax
c0102705:	75 1c                	jne    c0102723 <pte2page+0x2c>
        panic("pte2page called with invalid pte");
c0102707:	c7 44 24 08 e4 63 10 	movl   $0xc01063e4,0x8(%esp)
c010270e:	c0 
c010270f:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
c0102716:	00 
c0102717:	c7 04 24 af 63 10 c0 	movl   $0xc01063af,(%esp)
c010271e:	e8 c6 dc ff ff       	call   c01003e9 <__panic>
    }
    return pa2page(PTE_ADDR(pte));
c0102723:	8b 45 08             	mov    0x8(%ebp),%eax
c0102726:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c010272b:	89 04 24             	mov    %eax,(%esp)
c010272e:	e8 21 ff ff ff       	call   c0102654 <pa2page>
}
c0102733:	c9                   	leave  
c0102734:	c3                   	ret    

c0102735 <pde2page>:

static inline struct Page *
pde2page(pde_t pde) {
c0102735:	55                   	push   %ebp
c0102736:	89 e5                	mov    %esp,%ebp
c0102738:	83 ec 18             	sub    $0x18,%esp
    return pa2page(PDE_ADDR(pde));
c010273b:	8b 45 08             	mov    0x8(%ebp),%eax
c010273e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0102743:	89 04 24             	mov    %eax,(%esp)
c0102746:	e8 09 ff ff ff       	call   c0102654 <pa2page>
}
c010274b:	c9                   	leave  
c010274c:	c3                   	ret    

c010274d <page_ref>:

static inline int
page_ref(struct Page *page) {
c010274d:	55                   	push   %ebp
c010274e:	89 e5                	mov    %esp,%ebp
    return page->ref;
c0102750:	8b 45 08             	mov    0x8(%ebp),%eax
c0102753:	8b 00                	mov    (%eax),%eax
}
c0102755:	5d                   	pop    %ebp
c0102756:	c3                   	ret    

c0102757 <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
c0102757:	55                   	push   %ebp
c0102758:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c010275a:	8b 45 08             	mov    0x8(%ebp),%eax
c010275d:	8b 55 0c             	mov    0xc(%ebp),%edx
c0102760:	89 10                	mov    %edx,(%eax)
}
c0102762:	90                   	nop
c0102763:	5d                   	pop    %ebp
c0102764:	c3                   	ret    

c0102765 <page_ref_inc>:

static inline int
page_ref_inc(struct Page *page) {
c0102765:	55                   	push   %ebp
c0102766:	89 e5                	mov    %esp,%ebp
    page->ref += 1;
c0102768:	8b 45 08             	mov    0x8(%ebp),%eax
c010276b:	8b 00                	mov    (%eax),%eax
c010276d:	8d 50 01             	lea    0x1(%eax),%edx
c0102770:	8b 45 08             	mov    0x8(%ebp),%eax
c0102773:	89 10                	mov    %edx,(%eax)
    return page->ref;
c0102775:	8b 45 08             	mov    0x8(%ebp),%eax
c0102778:	8b 00                	mov    (%eax),%eax
}
c010277a:	5d                   	pop    %ebp
c010277b:	c3                   	ret    

c010277c <page_ref_dec>:

static inline int
page_ref_dec(struct Page *page) {
c010277c:	55                   	push   %ebp
c010277d:	89 e5                	mov    %esp,%ebp
    page->ref -= 1;
c010277f:	8b 45 08             	mov    0x8(%ebp),%eax
c0102782:	8b 00                	mov    (%eax),%eax
c0102784:	8d 50 ff             	lea    -0x1(%eax),%edx
c0102787:	8b 45 08             	mov    0x8(%ebp),%eax
c010278a:	89 10                	mov    %edx,(%eax)
    return page->ref;
c010278c:	8b 45 08             	mov    0x8(%ebp),%eax
c010278f:	8b 00                	mov    (%eax),%eax
}
c0102791:	5d                   	pop    %ebp
c0102792:	c3                   	ret    

c0102793 <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
c0102793:	55                   	push   %ebp
c0102794:	89 e5                	mov    %esp,%ebp
c0102796:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c0102799:	9c                   	pushf  
c010279a:	58                   	pop    %eax
c010279b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c010279e:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
c01027a1:	25 00 02 00 00       	and    $0x200,%eax
c01027a6:	85 c0                	test   %eax,%eax
c01027a8:	74 0c                	je     c01027b6 <__intr_save+0x23>
        intr_disable();
c01027aa:	e8 14 f0 ff ff       	call   c01017c3 <intr_disable>
        return 1;
c01027af:	b8 01 00 00 00       	mov    $0x1,%eax
c01027b4:	eb 05                	jmp    c01027bb <__intr_save+0x28>
    }
    return 0;
c01027b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01027bb:	c9                   	leave  
c01027bc:	c3                   	ret    

c01027bd <__intr_restore>:

static inline void
__intr_restore(bool flag) {
c01027bd:	55                   	push   %ebp
c01027be:	89 e5                	mov    %esp,%ebp
c01027c0:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c01027c3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c01027c7:	74 05                	je     c01027ce <__intr_restore+0x11>
        intr_enable();
c01027c9:	e8 ee ef ff ff       	call   c01017bc <intr_enable>
    }
}
c01027ce:	90                   	nop
c01027cf:	c9                   	leave  
c01027d0:	c3                   	ret    

c01027d1 <lgdt>:
/* *
 * lgdt - load the global descriptor table register and reset the
 * data/code segement registers for kernel.
 * */
static inline void
lgdt(struct pseudodesc *pd) {
c01027d1:	55                   	push   %ebp
c01027d2:	89 e5                	mov    %esp,%ebp
    asm volatile ("lgdt (%0)" :: "r" (pd));
c01027d4:	8b 45 08             	mov    0x8(%ebp),%eax
c01027d7:	0f 01 10             	lgdtl  (%eax)
    asm volatile ("movw %%ax, %%gs" :: "a" (USER_DS));
c01027da:	b8 23 00 00 00       	mov    $0x23,%eax
c01027df:	8e e8                	mov    %eax,%gs
    asm volatile ("movw %%ax, %%fs" :: "a" (USER_DS));
c01027e1:	b8 23 00 00 00       	mov    $0x23,%eax
c01027e6:	8e e0                	mov    %eax,%fs
    asm volatile ("movw %%ax, %%es" :: "a" (KERNEL_DS));
c01027e8:	b8 10 00 00 00       	mov    $0x10,%eax
c01027ed:	8e c0                	mov    %eax,%es
    asm volatile ("movw %%ax, %%ds" :: "a" (KERNEL_DS));
c01027ef:	b8 10 00 00 00       	mov    $0x10,%eax
c01027f4:	8e d8                	mov    %eax,%ds
    asm volatile ("movw %%ax, %%ss" :: "a" (KERNEL_DS));
c01027f6:	b8 10 00 00 00       	mov    $0x10,%eax
c01027fb:	8e d0                	mov    %eax,%ss
    // reload cs
    asm volatile ("ljmp %0, $1f\n 1:\n" :: "i" (KERNEL_CS));
c01027fd:	ea 04 28 10 c0 08 00 	ljmp   $0x8,$0xc0102804
}
c0102804:	90                   	nop
c0102805:	5d                   	pop    %ebp
c0102806:	c3                   	ret    

c0102807 <load_esp0>:
 * load_esp0 - change the ESP0 in default task state segment,
 * so that we can use different kernel stack when we trap frame
 * user to kernel.
 * */
void
load_esp0(uintptr_t esp0) {
c0102807:	55                   	push   %ebp
c0102808:	89 e5                	mov    %esp,%ebp
    ts.ts_esp0 = esp0;
c010280a:	8b 45 08             	mov    0x8(%ebp),%eax
c010280d:	a3 a4 ae 11 c0       	mov    %eax,0xc011aea4
}
c0102812:	90                   	nop
c0102813:	5d                   	pop    %ebp
c0102814:	c3                   	ret    

c0102815 <gdt_init>:

/* gdt_init - initialize the default GDT and TSS */
static void
gdt_init(void) {
c0102815:	55                   	push   %ebp
c0102816:	89 e5                	mov    %esp,%ebp
c0102818:	83 ec 14             	sub    $0x14,%esp
    // set boot kernel stack and default SS0
    load_esp0((uintptr_t)bootstacktop);
c010281b:	b8 00 70 11 c0       	mov    $0xc0117000,%eax
c0102820:	89 04 24             	mov    %eax,(%esp)
c0102823:	e8 df ff ff ff       	call   c0102807 <load_esp0>
    ts.ts_ss0 = KERNEL_DS;
c0102828:	66 c7 05 a8 ae 11 c0 	movw   $0x10,0xc011aea8
c010282f:	10 00 

    // initialize the TSS filed of the gdt
    gdt[SEG_TSS] = SEGTSS(STS_T32A, (uintptr_t)&ts, sizeof(ts), DPL_KERNEL);
c0102831:	66 c7 05 28 7a 11 c0 	movw   $0x68,0xc0117a28
c0102838:	68 00 
c010283a:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c010283f:	0f b7 c0             	movzwl %ax,%eax
c0102842:	66 a3 2a 7a 11 c0    	mov    %ax,0xc0117a2a
c0102848:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c010284d:	c1 e8 10             	shr    $0x10,%eax
c0102850:	a2 2c 7a 11 c0       	mov    %al,0xc0117a2c
c0102855:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c010285c:	24 f0                	and    $0xf0,%al
c010285e:	0c 09                	or     $0x9,%al
c0102860:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102865:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c010286c:	24 ef                	and    $0xef,%al
c010286e:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102873:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c010287a:	24 9f                	and    $0x9f,%al
c010287c:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102881:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c0102888:	0c 80                	or     $0x80,%al
c010288a:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c010288f:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102896:	24 f0                	and    $0xf0,%al
c0102898:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c010289d:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c01028a4:	24 ef                	and    $0xef,%al
c01028a6:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c01028ab:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c01028b2:	24 df                	and    $0xdf,%al
c01028b4:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c01028b9:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c01028c0:	0c 40                	or     $0x40,%al
c01028c2:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c01028c7:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c01028ce:	24 7f                	and    $0x7f,%al
c01028d0:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c01028d5:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c01028da:	c1 e8 18             	shr    $0x18,%eax
c01028dd:	a2 2f 7a 11 c0       	mov    %al,0xc0117a2f

    // reload all segment registers
    lgdt(&gdt_pd);
c01028e2:	c7 04 24 30 7a 11 c0 	movl   $0xc0117a30,(%esp)
c01028e9:	e8 e3 fe ff ff       	call   c01027d1 <lgdt>
c01028ee:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
    asm volatile ("cli" ::: "memory");
}

static inline void
ltr(uint16_t sel) {
    asm volatile ("ltr %0" :: "r" (sel) : "memory");
c01028f4:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
c01028f8:	0f 00 d8             	ltr    %ax

    // load the TSS
    ltr(GD_TSS);
}
c01028fb:	90                   	nop
c01028fc:	c9                   	leave  
c01028fd:	c3                   	ret    

c01028fe <init_pmm_manager>:

//init_pmm_manager - initialize a pmm_manager instance
static void
init_pmm_manager(void) {
c01028fe:	55                   	push   %ebp
c01028ff:	89 e5                	mov    %esp,%ebp
c0102901:	83 ec 18             	sub    $0x18,%esp
    pmm_manager = &default_pmm_manager;
c0102904:	c7 05 10 af 11 c0 a0 	movl   $0xc0106da0,0xc011af10
c010290b:	6d 10 c0 
    cprintf("memory management: %s\n", pmm_manager->name);
c010290e:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102913:	8b 00                	mov    (%eax),%eax
c0102915:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102919:	c7 04 24 10 64 10 c0 	movl   $0xc0106410,(%esp)
c0102920:	e8 6d d9 ff ff       	call   c0100292 <cprintf>
    pmm_manager->init();
c0102925:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c010292a:	8b 40 04             	mov    0x4(%eax),%eax
c010292d:	ff d0                	call   *%eax
}
c010292f:	90                   	nop
c0102930:	c9                   	leave  
c0102931:	c3                   	ret    

c0102932 <init_memmap>:

//init_memmap - call pmm->init_memmap to build Page struct for free memory  
static void
init_memmap(struct Page *base, size_t n) {
c0102932:	55                   	push   %ebp
c0102933:	89 e5                	mov    %esp,%ebp
c0102935:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->init_memmap(base, n);
c0102938:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c010293d:	8b 40 08             	mov    0x8(%eax),%eax
c0102940:	8b 55 0c             	mov    0xc(%ebp),%edx
c0102943:	89 54 24 04          	mov    %edx,0x4(%esp)
c0102947:	8b 55 08             	mov    0x8(%ebp),%edx
c010294a:	89 14 24             	mov    %edx,(%esp)
c010294d:	ff d0                	call   *%eax
}
c010294f:	90                   	nop
c0102950:	c9                   	leave  
c0102951:	c3                   	ret    

c0102952 <alloc_pages>:

//alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory 
struct Page *
alloc_pages(size_t n) {
c0102952:	55                   	push   %ebp
c0102953:	89 e5                	mov    %esp,%ebp
c0102955:	83 ec 28             	sub    $0x28,%esp
    struct Page *page=NULL;
c0102958:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
c010295f:	e8 2f fe ff ff       	call   c0102793 <__intr_save>
c0102964:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        page = pmm_manager->alloc_pages(n);
c0102967:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c010296c:	8b 40 0c             	mov    0xc(%eax),%eax
c010296f:	8b 55 08             	mov    0x8(%ebp),%edx
c0102972:	89 14 24             	mov    %edx,(%esp)
c0102975:	ff d0                	call   *%eax
c0102977:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }
    local_intr_restore(intr_flag);
c010297a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010297d:	89 04 24             	mov    %eax,(%esp)
c0102980:	e8 38 fe ff ff       	call   c01027bd <__intr_restore>
    return page;
c0102985:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0102988:	c9                   	leave  
c0102989:	c3                   	ret    

c010298a <free_pages>:

//free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory 
void
free_pages(struct Page *base, size_t n) {
c010298a:	55                   	push   %ebp
c010298b:	89 e5                	mov    %esp,%ebp
c010298d:	83 ec 28             	sub    $0x28,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
c0102990:	e8 fe fd ff ff       	call   c0102793 <__intr_save>
c0102995:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        pmm_manager->free_pages(base, n);
c0102998:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c010299d:	8b 40 10             	mov    0x10(%eax),%eax
c01029a0:	8b 55 0c             	mov    0xc(%ebp),%edx
c01029a3:	89 54 24 04          	mov    %edx,0x4(%esp)
c01029a7:	8b 55 08             	mov    0x8(%ebp),%edx
c01029aa:	89 14 24             	mov    %edx,(%esp)
c01029ad:	ff d0                	call   *%eax
    }
    local_intr_restore(intr_flag);
c01029af:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01029b2:	89 04 24             	mov    %eax,(%esp)
c01029b5:	e8 03 fe ff ff       	call   c01027bd <__intr_restore>
}
c01029ba:	90                   	nop
c01029bb:	c9                   	leave  
c01029bc:	c3                   	ret    

c01029bd <nr_free_pages>:

//nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE) 
//of current free memory
size_t
nr_free_pages(void) {
c01029bd:	55                   	push   %ebp
c01029be:	89 e5                	mov    %esp,%ebp
c01029c0:	83 ec 28             	sub    $0x28,%esp
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
c01029c3:	e8 cb fd ff ff       	call   c0102793 <__intr_save>
c01029c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        ret = pmm_manager->nr_free_pages();
c01029cb:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c01029d0:	8b 40 14             	mov    0x14(%eax),%eax
c01029d3:	ff d0                	call   *%eax
c01029d5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    }
    local_intr_restore(intr_flag);
c01029d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01029db:	89 04 24             	mov    %eax,(%esp)
c01029de:	e8 da fd ff ff       	call   c01027bd <__intr_restore>
    return ret;
c01029e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
c01029e6:	c9                   	leave  
c01029e7:	c3                   	ret    

c01029e8 <page_init>:

/* pmm_init - initialize the physical memory management */
static void
page_init(void) {
c01029e8:	55                   	push   %ebp
c01029e9:	89 e5                	mov    %esp,%ebp
c01029eb:	57                   	push   %edi
c01029ec:	56                   	push   %esi
c01029ed:	53                   	push   %ebx
c01029ee:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
c01029f4:	c7 45 c4 00 80 00 c0 	movl   $0xc0008000,-0x3c(%ebp)
    uint64_t maxpa = 0;
c01029fb:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
c0102a02:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

    cprintf("e820map:\n");
c0102a09:	c7 04 24 27 64 10 c0 	movl   $0xc0106427,(%esp)
c0102a10:	e8 7d d8 ff ff       	call   c0100292 <cprintf>
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
c0102a15:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102a1c:	e9 22 01 00 00       	jmp    c0102b43 <page_init+0x15b>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
c0102a21:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102a24:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102a27:	89 d0                	mov    %edx,%eax
c0102a29:	c1 e0 02             	shl    $0x2,%eax
c0102a2c:	01 d0                	add    %edx,%eax
c0102a2e:	c1 e0 02             	shl    $0x2,%eax
c0102a31:	01 c8                	add    %ecx,%eax
c0102a33:	8b 50 08             	mov    0x8(%eax),%edx
c0102a36:	8b 40 04             	mov    0x4(%eax),%eax
c0102a39:	89 45 b8             	mov    %eax,-0x48(%ebp)
c0102a3c:	89 55 bc             	mov    %edx,-0x44(%ebp)
c0102a3f:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102a42:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102a45:	89 d0                	mov    %edx,%eax
c0102a47:	c1 e0 02             	shl    $0x2,%eax
c0102a4a:	01 d0                	add    %edx,%eax
c0102a4c:	c1 e0 02             	shl    $0x2,%eax
c0102a4f:	01 c8                	add    %ecx,%eax
c0102a51:	8b 48 0c             	mov    0xc(%eax),%ecx
c0102a54:	8b 58 10             	mov    0x10(%eax),%ebx
c0102a57:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0102a5a:	8b 55 bc             	mov    -0x44(%ebp),%edx
c0102a5d:	01 c8                	add    %ecx,%eax
c0102a5f:	11 da                	adc    %ebx,%edx
c0102a61:	89 45 b0             	mov    %eax,-0x50(%ebp)
c0102a64:	89 55 b4             	mov    %edx,-0x4c(%ebp)
        cprintf("  memory: %08llx, [%08llx, %08llx], type = %d.\n",
c0102a67:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102a6a:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102a6d:	89 d0                	mov    %edx,%eax
c0102a6f:	c1 e0 02             	shl    $0x2,%eax
c0102a72:	01 d0                	add    %edx,%eax
c0102a74:	c1 e0 02             	shl    $0x2,%eax
c0102a77:	01 c8                	add    %ecx,%eax
c0102a79:	83 c0 14             	add    $0x14,%eax
c0102a7c:	8b 00                	mov    (%eax),%eax
c0102a7e:	89 45 84             	mov    %eax,-0x7c(%ebp)
c0102a81:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0102a84:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0102a87:	83 c0 ff             	add    $0xffffffff,%eax
c0102a8a:	83 d2 ff             	adc    $0xffffffff,%edx
c0102a8d:	89 85 78 ff ff ff    	mov    %eax,-0x88(%ebp)
c0102a93:	89 95 7c ff ff ff    	mov    %edx,-0x84(%ebp)
c0102a99:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102a9c:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102a9f:	89 d0                	mov    %edx,%eax
c0102aa1:	c1 e0 02             	shl    $0x2,%eax
c0102aa4:	01 d0                	add    %edx,%eax
c0102aa6:	c1 e0 02             	shl    $0x2,%eax
c0102aa9:	01 c8                	add    %ecx,%eax
c0102aab:	8b 48 0c             	mov    0xc(%eax),%ecx
c0102aae:	8b 58 10             	mov    0x10(%eax),%ebx
c0102ab1:	8b 55 84             	mov    -0x7c(%ebp),%edx
c0102ab4:	89 54 24 1c          	mov    %edx,0x1c(%esp)
c0102ab8:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
c0102abe:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
c0102ac4:	89 44 24 14          	mov    %eax,0x14(%esp)
c0102ac8:	89 54 24 18          	mov    %edx,0x18(%esp)
c0102acc:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0102acf:	8b 55 bc             	mov    -0x44(%ebp),%edx
c0102ad2:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0102ad6:	89 54 24 10          	mov    %edx,0x10(%esp)
c0102ada:	89 4c 24 04          	mov    %ecx,0x4(%esp)
c0102ade:	89 5c 24 08          	mov    %ebx,0x8(%esp)
c0102ae2:	c7 04 24 34 64 10 c0 	movl   $0xc0106434,(%esp)
c0102ae9:	e8 a4 d7 ff ff       	call   c0100292 <cprintf>
                memmap->map[i].size, begin, end - 1, memmap->map[i].type);
        if (memmap->map[i].type == E820_ARM) {
c0102aee:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102af1:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102af4:	89 d0                	mov    %edx,%eax
c0102af6:	c1 e0 02             	shl    $0x2,%eax
c0102af9:	01 d0                	add    %edx,%eax
c0102afb:	c1 e0 02             	shl    $0x2,%eax
c0102afe:	01 c8                	add    %ecx,%eax
c0102b00:	83 c0 14             	add    $0x14,%eax
c0102b03:	8b 00                	mov    (%eax),%eax
c0102b05:	83 f8 01             	cmp    $0x1,%eax
c0102b08:	75 36                	jne    c0102b40 <page_init+0x158>
            if (maxpa < end && begin < KMEMSIZE) {
c0102b0a:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0102b0d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0102b10:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
c0102b13:	77 2b                	ja     c0102b40 <page_init+0x158>
c0102b15:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
c0102b18:	72 05                	jb     c0102b1f <page_init+0x137>
c0102b1a:	3b 45 b0             	cmp    -0x50(%ebp),%eax
c0102b1d:	73 21                	jae    c0102b40 <page_init+0x158>
c0102b1f:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
c0102b23:	77 1b                	ja     c0102b40 <page_init+0x158>
c0102b25:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
c0102b29:	72 09                	jb     c0102b34 <page_init+0x14c>
c0102b2b:	81 7d b8 ff ff ff 37 	cmpl   $0x37ffffff,-0x48(%ebp)
c0102b32:	77 0c                	ja     c0102b40 <page_init+0x158>
                maxpa = end;
c0102b34:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0102b37:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0102b3a:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0102b3d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
    uint64_t maxpa = 0;

    cprintf("e820map:\n");
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
c0102b40:	ff 45 dc             	incl   -0x24(%ebp)
c0102b43:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0102b46:	8b 00                	mov    (%eax),%eax
c0102b48:	3b 45 dc             	cmp    -0x24(%ebp),%eax
c0102b4b:	0f 8f d0 fe ff ff    	jg     c0102a21 <page_init+0x39>
            if (maxpa < end && begin < KMEMSIZE) {
                maxpa = end;
            }
        }
    }
    if (maxpa > KMEMSIZE) {
c0102b51:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0102b55:	72 1d                	jb     c0102b74 <page_init+0x18c>
c0102b57:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0102b5b:	77 09                	ja     c0102b66 <page_init+0x17e>
c0102b5d:	81 7d e0 00 00 00 38 	cmpl   $0x38000000,-0x20(%ebp)
c0102b64:	76 0e                	jbe    c0102b74 <page_init+0x18c>
        maxpa = KMEMSIZE;
c0102b66:	c7 45 e0 00 00 00 38 	movl   $0x38000000,-0x20(%ebp)
c0102b6d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    }

    extern char end[];

    npage = maxpa / PGSIZE;
c0102b74:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0102b77:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0102b7a:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c0102b7e:	c1 ea 0c             	shr    $0xc,%edx
c0102b81:	a3 80 ae 11 c0       	mov    %eax,0xc011ae80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
c0102b86:	c7 45 ac 00 10 00 00 	movl   $0x1000,-0x54(%ebp)
c0102b8d:	b8 28 af 11 c0       	mov    $0xc011af28,%eax
c0102b92:	8d 50 ff             	lea    -0x1(%eax),%edx
c0102b95:	8b 45 ac             	mov    -0x54(%ebp),%eax
c0102b98:	01 d0                	add    %edx,%eax
c0102b9a:	89 45 a8             	mov    %eax,-0x58(%ebp)
c0102b9d:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0102ba0:	ba 00 00 00 00       	mov    $0x0,%edx
c0102ba5:	f7 75 ac             	divl   -0x54(%ebp)
c0102ba8:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0102bab:	29 d0                	sub    %edx,%eax
c0102bad:	a3 18 af 11 c0       	mov    %eax,0xc011af18

    for (i = 0; i < npage; i ++) {
c0102bb2:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102bb9:	eb 2e                	jmp    c0102be9 <page_init+0x201>
        SetPageReserved(pages + i);
c0102bbb:	8b 0d 18 af 11 c0    	mov    0xc011af18,%ecx
c0102bc1:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102bc4:	89 d0                	mov    %edx,%eax
c0102bc6:	c1 e0 02             	shl    $0x2,%eax
c0102bc9:	01 d0                	add    %edx,%eax
c0102bcb:	c1 e0 02             	shl    $0x2,%eax
c0102bce:	01 c8                	add    %ecx,%eax
c0102bd0:	83 c0 04             	add    $0x4,%eax
c0102bd3:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
c0102bda:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0102bdd:	8b 45 8c             	mov    -0x74(%ebp),%eax
c0102be0:	8b 55 90             	mov    -0x70(%ebp),%edx
c0102be3:	0f ab 10             	bts    %edx,(%eax)
    extern char end[];

    npage = maxpa / PGSIZE;
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    for (i = 0; i < npage; i ++) {
c0102be6:	ff 45 dc             	incl   -0x24(%ebp)
c0102be9:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102bec:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0102bf1:	39 c2                	cmp    %eax,%edx
c0102bf3:	72 c6                	jb     c0102bbb <page_init+0x1d3>
        SetPageReserved(pages + i);
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);
c0102bf5:	8b 15 80 ae 11 c0    	mov    0xc011ae80,%edx
c0102bfb:	89 d0                	mov    %edx,%eax
c0102bfd:	c1 e0 02             	shl    $0x2,%eax
c0102c00:	01 d0                	add    %edx,%eax
c0102c02:	c1 e0 02             	shl    $0x2,%eax
c0102c05:	89 c2                	mov    %eax,%edx
c0102c07:	a1 18 af 11 c0       	mov    0xc011af18,%eax
c0102c0c:	01 d0                	add    %edx,%eax
c0102c0e:	89 45 a4             	mov    %eax,-0x5c(%ebp)
c0102c11:	81 7d a4 ff ff ff bf 	cmpl   $0xbfffffff,-0x5c(%ebp)
c0102c18:	77 23                	ja     c0102c3d <page_init+0x255>
c0102c1a:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0102c1d:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0102c21:	c7 44 24 08 64 64 10 	movl   $0xc0106464,0x8(%esp)
c0102c28:	c0 
c0102c29:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
c0102c30:	00 
c0102c31:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0102c38:	e8 ac d7 ff ff       	call   c01003e9 <__panic>
c0102c3d:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0102c40:	05 00 00 00 40       	add    $0x40000000,%eax
c0102c45:	89 45 a0             	mov    %eax,-0x60(%ebp)

    for (i = 0; i < memmap->nr_map; i ++) {
c0102c48:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102c4f:	e9 61 01 00 00       	jmp    c0102db5 <page_init+0x3cd>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
c0102c54:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102c57:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102c5a:	89 d0                	mov    %edx,%eax
c0102c5c:	c1 e0 02             	shl    $0x2,%eax
c0102c5f:	01 d0                	add    %edx,%eax
c0102c61:	c1 e0 02             	shl    $0x2,%eax
c0102c64:	01 c8                	add    %ecx,%eax
c0102c66:	8b 50 08             	mov    0x8(%eax),%edx
c0102c69:	8b 40 04             	mov    0x4(%eax),%eax
c0102c6c:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0102c6f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0102c72:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102c75:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102c78:	89 d0                	mov    %edx,%eax
c0102c7a:	c1 e0 02             	shl    $0x2,%eax
c0102c7d:	01 d0                	add    %edx,%eax
c0102c7f:	c1 e0 02             	shl    $0x2,%eax
c0102c82:	01 c8                	add    %ecx,%eax
c0102c84:	8b 48 0c             	mov    0xc(%eax),%ecx
c0102c87:	8b 58 10             	mov    0x10(%eax),%ebx
c0102c8a:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102c8d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0102c90:	01 c8                	add    %ecx,%eax
c0102c92:	11 da                	adc    %ebx,%edx
c0102c94:	89 45 c8             	mov    %eax,-0x38(%ebp)
c0102c97:	89 55 cc             	mov    %edx,-0x34(%ebp)
        if (memmap->map[i].type == E820_ARM) {
c0102c9a:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102c9d:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102ca0:	89 d0                	mov    %edx,%eax
c0102ca2:	c1 e0 02             	shl    $0x2,%eax
c0102ca5:	01 d0                	add    %edx,%eax
c0102ca7:	c1 e0 02             	shl    $0x2,%eax
c0102caa:	01 c8                	add    %ecx,%eax
c0102cac:	83 c0 14             	add    $0x14,%eax
c0102caf:	8b 00                	mov    (%eax),%eax
c0102cb1:	83 f8 01             	cmp    $0x1,%eax
c0102cb4:	0f 85 f8 00 00 00    	jne    c0102db2 <page_init+0x3ca>
            if (begin < freemem) {
c0102cba:	8b 45 a0             	mov    -0x60(%ebp),%eax
c0102cbd:	ba 00 00 00 00       	mov    $0x0,%edx
c0102cc2:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0102cc5:	72 17                	jb     c0102cde <page_init+0x2f6>
c0102cc7:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0102cca:	77 05                	ja     c0102cd1 <page_init+0x2e9>
c0102ccc:	3b 45 d0             	cmp    -0x30(%ebp),%eax
c0102ccf:	76 0d                	jbe    c0102cde <page_init+0x2f6>
                begin = freemem;
c0102cd1:	8b 45 a0             	mov    -0x60(%ebp),%eax
c0102cd4:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0102cd7:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
            }
            if (end > KMEMSIZE) {
c0102cde:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c0102ce2:	72 1d                	jb     c0102d01 <page_init+0x319>
c0102ce4:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c0102ce8:	77 09                	ja     c0102cf3 <page_init+0x30b>
c0102cea:	81 7d c8 00 00 00 38 	cmpl   $0x38000000,-0x38(%ebp)
c0102cf1:	76 0e                	jbe    c0102d01 <page_init+0x319>
                end = KMEMSIZE;
c0102cf3:	c7 45 c8 00 00 00 38 	movl   $0x38000000,-0x38(%ebp)
c0102cfa:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
            }
            if (begin < end) {
c0102d01:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102d04:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0102d07:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0102d0a:	0f 87 a2 00 00 00    	ja     c0102db2 <page_init+0x3ca>
c0102d10:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0102d13:	72 09                	jb     c0102d1e <page_init+0x336>
c0102d15:	3b 45 c8             	cmp    -0x38(%ebp),%eax
c0102d18:	0f 83 94 00 00 00    	jae    c0102db2 <page_init+0x3ca>
                begin = ROUNDUP(begin, PGSIZE);
c0102d1e:	c7 45 9c 00 10 00 00 	movl   $0x1000,-0x64(%ebp)
c0102d25:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0102d28:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0102d2b:	01 d0                	add    %edx,%eax
c0102d2d:	48                   	dec    %eax
c0102d2e:	89 45 98             	mov    %eax,-0x68(%ebp)
c0102d31:	8b 45 98             	mov    -0x68(%ebp),%eax
c0102d34:	ba 00 00 00 00       	mov    $0x0,%edx
c0102d39:	f7 75 9c             	divl   -0x64(%ebp)
c0102d3c:	8b 45 98             	mov    -0x68(%ebp),%eax
c0102d3f:	29 d0                	sub    %edx,%eax
c0102d41:	ba 00 00 00 00       	mov    $0x0,%edx
c0102d46:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0102d49:	89 55 d4             	mov    %edx,-0x2c(%ebp)
                end = ROUNDDOWN(end, PGSIZE);
c0102d4c:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0102d4f:	89 45 94             	mov    %eax,-0x6c(%ebp)
c0102d52:	8b 45 94             	mov    -0x6c(%ebp),%eax
c0102d55:	ba 00 00 00 00       	mov    $0x0,%edx
c0102d5a:	89 c3                	mov    %eax,%ebx
c0102d5c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
c0102d62:	89 de                	mov    %ebx,%esi
c0102d64:	89 d0                	mov    %edx,%eax
c0102d66:	83 e0 00             	and    $0x0,%eax
c0102d69:	89 c7                	mov    %eax,%edi
c0102d6b:	89 75 c8             	mov    %esi,-0x38(%ebp)
c0102d6e:	89 7d cc             	mov    %edi,-0x34(%ebp)
                if (begin < end) {
c0102d71:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102d74:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0102d77:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0102d7a:	77 36                	ja     c0102db2 <page_init+0x3ca>
c0102d7c:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0102d7f:	72 05                	jb     c0102d86 <page_init+0x39e>
c0102d81:	3b 45 c8             	cmp    -0x38(%ebp),%eax
c0102d84:	73 2c                	jae    c0102db2 <page_init+0x3ca>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
c0102d86:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0102d89:	8b 55 cc             	mov    -0x34(%ebp),%edx
c0102d8c:	2b 45 d0             	sub    -0x30(%ebp),%eax
c0102d8f:	1b 55 d4             	sbb    -0x2c(%ebp),%edx
c0102d92:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c0102d96:	c1 ea 0c             	shr    $0xc,%edx
c0102d99:	89 c3                	mov    %eax,%ebx
c0102d9b:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102d9e:	89 04 24             	mov    %eax,(%esp)
c0102da1:	e8 ae f8 ff ff       	call   c0102654 <pa2page>
c0102da6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
c0102daa:	89 04 24             	mov    %eax,(%esp)
c0102dad:	e8 80 fb ff ff       	call   c0102932 <init_memmap>
        SetPageReserved(pages + i);
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);

    for (i = 0; i < memmap->nr_map; i ++) {
c0102db2:	ff 45 dc             	incl   -0x24(%ebp)
c0102db5:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0102db8:	8b 00                	mov    (%eax),%eax
c0102dba:	3b 45 dc             	cmp    -0x24(%ebp),%eax
c0102dbd:	0f 8f 91 fe ff ff    	jg     c0102c54 <page_init+0x26c>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
                }
            }
        }
    }
}
c0102dc3:	90                   	nop
c0102dc4:	81 c4 9c 00 00 00    	add    $0x9c,%esp
c0102dca:	5b                   	pop    %ebx
c0102dcb:	5e                   	pop    %esi
c0102dcc:	5f                   	pop    %edi
c0102dcd:	5d                   	pop    %ebp
c0102dce:	c3                   	ret    

c0102dcf <boot_map_segment>:
//  la:   linear address of this memory need to map (after x86 segment map)
//  size: memory size
//  pa:   physical address of this memory
//  perm: permission of this memory  
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
c0102dcf:	55                   	push   %ebp
c0102dd0:	89 e5                	mov    %esp,%ebp
c0102dd2:	83 ec 38             	sub    $0x38,%esp
    assert(PGOFF(la) == PGOFF(pa));
c0102dd5:	8b 45 0c             	mov    0xc(%ebp),%eax
c0102dd8:	33 45 14             	xor    0x14(%ebp),%eax
c0102ddb:	25 ff 0f 00 00       	and    $0xfff,%eax
c0102de0:	85 c0                	test   %eax,%eax
c0102de2:	74 24                	je     c0102e08 <boot_map_segment+0x39>
c0102de4:	c7 44 24 0c 96 64 10 	movl   $0xc0106496,0xc(%esp)
c0102deb:	c0 
c0102dec:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0102df3:	c0 
c0102df4:	c7 44 24 04 06 01 00 	movl   $0x106,0x4(%esp)
c0102dfb:	00 
c0102dfc:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0102e03:	e8 e1 d5 ff ff       	call   c01003e9 <__panic>
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
c0102e08:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
c0102e0f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0102e12:	25 ff 0f 00 00       	and    $0xfff,%eax
c0102e17:	89 c2                	mov    %eax,%edx
c0102e19:	8b 45 10             	mov    0x10(%ebp),%eax
c0102e1c:	01 c2                	add    %eax,%edx
c0102e1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0102e21:	01 d0                	add    %edx,%eax
c0102e23:	48                   	dec    %eax
c0102e24:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0102e27:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0102e2a:	ba 00 00 00 00       	mov    $0x0,%edx
c0102e2f:	f7 75 f0             	divl   -0x10(%ebp)
c0102e32:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0102e35:	29 d0                	sub    %edx,%eax
c0102e37:	c1 e8 0c             	shr    $0xc,%eax
c0102e3a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    la = ROUNDDOWN(la, PGSIZE);
c0102e3d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0102e40:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0102e43:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0102e46:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0102e4b:	89 45 0c             	mov    %eax,0xc(%ebp)
    pa = ROUNDDOWN(pa, PGSIZE);
c0102e4e:	8b 45 14             	mov    0x14(%ebp),%eax
c0102e51:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0102e54:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0102e57:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0102e5c:	89 45 14             	mov    %eax,0x14(%ebp)
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
c0102e5f:	eb 68                	jmp    c0102ec9 <boot_map_segment+0xfa>
        pte_t *ptep = get_pte(pgdir, la, 1);
c0102e61:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
c0102e68:	00 
c0102e69:	8b 45 0c             	mov    0xc(%ebp),%eax
c0102e6c:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102e70:	8b 45 08             	mov    0x8(%ebp),%eax
c0102e73:	89 04 24             	mov    %eax,(%esp)
c0102e76:	e8 81 01 00 00       	call   c0102ffc <get_pte>
c0102e7b:	89 45 e0             	mov    %eax,-0x20(%ebp)
        assert(ptep != NULL);
c0102e7e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c0102e82:	75 24                	jne    c0102ea8 <boot_map_segment+0xd9>
c0102e84:	c7 44 24 0c c2 64 10 	movl   $0xc01064c2,0xc(%esp)
c0102e8b:	c0 
c0102e8c:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0102e93:	c0 
c0102e94:	c7 44 24 04 0c 01 00 	movl   $0x10c,0x4(%esp)
c0102e9b:	00 
c0102e9c:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0102ea3:	e8 41 d5 ff ff       	call   c01003e9 <__panic>
        *ptep = pa | PTE_P | perm;
c0102ea8:	8b 45 14             	mov    0x14(%ebp),%eax
c0102eab:	0b 45 18             	or     0x18(%ebp),%eax
c0102eae:	83 c8 01             	or     $0x1,%eax
c0102eb1:	89 c2                	mov    %eax,%edx
c0102eb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0102eb6:	89 10                	mov    %edx,(%eax)
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
    assert(PGOFF(la) == PGOFF(pa));
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
c0102eb8:	ff 4d f4             	decl   -0xc(%ebp)
c0102ebb:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
c0102ec2:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
c0102ec9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0102ecd:	75 92                	jne    c0102e61 <boot_map_segment+0x92>
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pa | PTE_P | perm;
    }
}
c0102ecf:	90                   	nop
c0102ed0:	c9                   	leave  
c0102ed1:	c3                   	ret    

c0102ed2 <boot_alloc_page>:

//boot_alloc_page - allocate one page using pmm->alloc_pages(1) 
// return value: the kernel virtual address of this allocated page
//note: this function is used to get the memory for PDT(Page Directory Table)&PT(Page Table)
static void *
boot_alloc_page(void) {
c0102ed2:	55                   	push   %ebp
c0102ed3:	89 e5                	mov    %esp,%ebp
c0102ed5:	83 ec 28             	sub    $0x28,%esp
    struct Page *p = alloc_page();
c0102ed8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0102edf:	e8 6e fa ff ff       	call   c0102952 <alloc_pages>
c0102ee4:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (p == NULL) {
c0102ee7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0102eeb:	75 1c                	jne    c0102f09 <boot_alloc_page+0x37>
        panic("boot_alloc_page failed.\n");
c0102eed:	c7 44 24 08 cf 64 10 	movl   $0xc01064cf,0x8(%esp)
c0102ef4:	c0 
c0102ef5:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
c0102efc:	00 
c0102efd:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0102f04:	e8 e0 d4 ff ff       	call   c01003e9 <__panic>
    }
    return page2kva(p);
c0102f09:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102f0c:	89 04 24             	mov    %eax,(%esp)
c0102f0f:	e8 8f f7 ff ff       	call   c01026a3 <page2kva>
}
c0102f14:	c9                   	leave  
c0102f15:	c3                   	ret    

c0102f16 <pmm_init>:

//pmm_init - setup a pmm to manage physical memory, build PDT&PT to setup paging mechanism 
//         - check the correctness of pmm & paging mechanism, print PDT&PT
void
pmm_init(void) {
c0102f16:	55                   	push   %ebp
c0102f17:	89 e5                	mov    %esp,%ebp
c0102f19:	83 ec 38             	sub    $0x38,%esp
    // We've already enabled paging
    boot_cr3 = PADDR(boot_pgdir);
c0102f1c:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0102f21:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0102f24:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
c0102f2b:	77 23                	ja     c0102f50 <pmm_init+0x3a>
c0102f2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102f30:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0102f34:	c7 44 24 08 64 64 10 	movl   $0xc0106464,0x8(%esp)
c0102f3b:	c0 
c0102f3c:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
c0102f43:	00 
c0102f44:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0102f4b:	e8 99 d4 ff ff       	call   c01003e9 <__panic>
c0102f50:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102f53:	05 00 00 00 40       	add    $0x40000000,%eax
c0102f58:	a3 14 af 11 c0       	mov    %eax,0xc011af14
    //We need to alloc/free the physical memory (granularity is 4KB or other size). 
    //So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    //First we should init a physical memory manager(pmm) based on the framework.
    //Then pmm can alloc/free the physical memory. 
    //Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();
c0102f5d:	e8 9c f9 ff ff       	call   c01028fe <init_pmm_manager>

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();
c0102f62:	e8 81 fa ff ff       	call   c01029e8 <page_init>

    //use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();
c0102f67:	e8 56 03 00 00       	call   c01032c2 <check_alloc_page>

    check_pgdir();
c0102f6c:	e8 70 03 00 00       	call   c01032e1 <check_pgdir>

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // recursively insert boot_pgdir in itself
    // to form a virtual page table at virtual address VPT
    boot_pgdir[PDX(VPT)] = PADDR(boot_pgdir) | PTE_P | PTE_W;
c0102f71:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0102f76:	8d 90 ac 0f 00 00    	lea    0xfac(%eax),%edx
c0102f7c:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0102f81:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0102f84:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
c0102f8b:	77 23                	ja     c0102fb0 <pmm_init+0x9a>
c0102f8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0102f90:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0102f94:	c7 44 24 08 64 64 10 	movl   $0xc0106464,0x8(%esp)
c0102f9b:	c0 
c0102f9c:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
c0102fa3:	00 
c0102fa4:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0102fab:	e8 39 d4 ff ff       	call   c01003e9 <__panic>
c0102fb0:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0102fb3:	05 00 00 00 40       	add    $0x40000000,%eax
c0102fb8:	83 c8 03             	or     $0x3,%eax
c0102fbb:	89 02                	mov    %eax,(%edx)

    // map all physical memory to linear memory with base linear addr KERNBASE
    // linear_addr KERNBASE ~ KERNBASE + KMEMSIZE = phy_addr 0 ~ KMEMSIZE
    boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, 0, PTE_W);
c0102fbd:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0102fc2:	c7 44 24 10 02 00 00 	movl   $0x2,0x10(%esp)
c0102fc9:	00 
c0102fca:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
c0102fd1:	00 
c0102fd2:	c7 44 24 08 00 00 00 	movl   $0x38000000,0x8(%esp)
c0102fd9:	38 
c0102fda:	c7 44 24 04 00 00 00 	movl   $0xc0000000,0x4(%esp)
c0102fe1:	c0 
c0102fe2:	89 04 24             	mov    %eax,(%esp)
c0102fe5:	e8 e5 fd ff ff       	call   c0102dcf <boot_map_segment>

    // Since we are using bootloader's GDT,
    // we should reload gdt (second time, the last time) to get user segments and the TSS
    // map virtual_addr 0 ~ 4G = linear_addr 0 ~ 4G
    // then set kernel stack (ss:esp) in TSS, setup TSS in gdt, load TSS
    gdt_init();
c0102fea:	e8 26 f8 ff ff       	call   c0102815 <gdt_init>

    //now the basic virtual memory map(see memalyout.h) is established.
    //check the correctness of the basic virtual memory map.
    check_boot_pgdir();
c0102fef:	e8 89 09 00 00       	call   c010397d <check_boot_pgdir>

    print_pgdir();
c0102ff4:	e8 02 0e 00 00       	call   c0103dfb <print_pgdir>

}
c0102ff9:	90                   	nop
c0102ffa:	c9                   	leave  
c0102ffb:	c3                   	ret    

c0102ffc <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *
get_pte(pde_t *pgdir, uintptr_t la, bool create) {
c0102ffc:	55                   	push   %ebp
c0102ffd:	89 e5                	mov    %esp,%ebp
c0102fff:	83 ec 38             	sub    $0x38,%esp
                          // (7) set page directory entry's permission
    }
    return NULL;          // (8) return page table entry
#endif
    // Get the page directory entry by adding offset(the index) and the base address of page direcotry table.
    pde_t *entry = pgdir + PDX(la) * sizeof(pde_t);
c0103002:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103005:	c1 e8 16             	shr    $0x16,%eax
c0103008:	c1 e0 04             	shl    $0x4,%eax
c010300b:	89 c2                	mov    %eax,%edx
c010300d:	8b 45 08             	mov    0x8(%ebp),%eax
c0103010:	01 d0                	add    %edx,%eax
c0103012:	89 45 f4             	mov    %eax,-0xc(%ebp)
    
    if (!(*entry & PTE_P)) {
c0103015:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103018:	8b 00                	mov    (%eax),%eax
c010301a:	83 e0 01             	and    $0x1,%eax
c010301d:	85 c0                	test   %eax,%eax
c010301f:	0f 85 b4 00 00 00    	jne    c01030d9 <get_pte+0xdd>
        // Not present in the table? We need to allocate the page table.
        struct Page *page = 
            (create ? 
                            alloc_page() : NULL);
c0103025:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0103029:	74 0e                	je     c0103039 <get_pte+0x3d>
c010302b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0103032:	e8 1b f9 ff ff       	call   c0102952 <alloc_pages>
c0103037:	eb 05                	jmp    c010303e <get_pte+0x42>
c0103039:	b8 00 00 00 00       	mov    $0x0,%eax
    // Get the page directory entry by adding offset(the index) and the base address of page direcotry table.
    pde_t *entry = pgdir + PDX(la) * sizeof(pde_t);
    
    if (!(*entry & PTE_P)) {
        // Not present in the table? We need to allocate the page table.
        struct Page *page = 
c010303e:	89 45 f0             	mov    %eax,-0x10(%ebp)
            (create ? 
                            alloc_page() : NULL);

        if (NULL == page) {
c0103041:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0103045:	75 08                	jne    c010304f <get_pte+0x53>
            return page;
c0103047:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010304a:	e9 b8 00 00 00       	jmp    c0103107 <get_pte+0x10b>
        }

        // Initialize the page.
        set_page_ref(page, 1);
c010304f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0103056:	00 
c0103057:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010305a:	89 04 24             	mov    %eax,(%esp)
c010305d:	e8 f5 f6 ff ff       	call   c0102757 <set_page_ref>
        // Get the physical address for next step.
        // ? uintptr_t seems to be unsigned int...
        uintptr_t page_addr = page2pa(page);
c0103062:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103065:	89 04 24             	mov    %eax,(%esp)
c0103068:	e8 d1 f5 ff ff       	call   c010263e <page2pa>
c010306d:	89 45 ec             	mov    %eax,-0x14(%ebp)
        // Set the page to be empty in the kernel.
        memset(KADDR(page_addr), 0, sizeof(uintptr_t) * (PGSIZE));
c0103070:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103073:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0103076:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103079:	c1 e8 0c             	shr    $0xc,%eax
c010307c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c010307f:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103084:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
c0103087:	72 23                	jb     c01030ac <get_pte+0xb0>
c0103089:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010308c:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0103090:	c7 44 24 08 c0 63 10 	movl   $0xc01063c0,0x8(%esp)
c0103097:	c0 
c0103098:	c7 44 24 04 89 01 00 	movl   $0x189,0x4(%esp)
c010309f:	00 
c01030a0:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c01030a7:	e8 3d d3 ff ff       	call   c01003e9 <__panic>
c01030ac:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01030af:	2d 00 00 00 40       	sub    $0x40000000,%eax
c01030b4:	c7 44 24 08 00 40 00 	movl   $0x4000,0x8(%esp)
c01030bb:	00 
c01030bc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c01030c3:	00 
c01030c4:	89 04 24             	mov    %eax,(%esp)
c01030c7:	e8 d7 23 00 00       	call   c01054a3 <memset>
        *entry = page_addr |
                 PTE_P     |
                 PTE_W     |
c01030cc:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01030cf:	83 c8 07             	or     $0x7,%eax
c01030d2:	89 c2                	mov    %eax,%edx
        // Get the physical address for next step.
        // ? uintptr_t seems to be unsigned int...
        uintptr_t page_addr = page2pa(page);
        // Set the page to be empty in the kernel.
        memset(KADDR(page_addr), 0, sizeof(uintptr_t) * (PGSIZE));
        *entry = page_addr |
c01030d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01030d7:	89 10                	mov    %edx,(%eax)
                 PTE_P     |
                 PTE_W     |
                 PTE_U     ;
    }

    uintptr_t page_table_index = PTX(la);
c01030d9:	8b 45 0c             	mov    0xc(%ebp),%eax
c01030dc:	c1 e8 0c             	shr    $0xc,%eax
c01030df:	25 ff 03 00 00       	and    $0x3ff,%eax
c01030e4:	89 45 e0             	mov    %eax,-0x20(%ebp)
    // Page directory table's entry is just a pointer to the page table itself.
    uintptr_t page_table_addr = PTE_ADDR(*entry);
c01030e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01030ea:	8b 00                	mov    (%eax),%eax
c01030ec:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c01030f1:	89 45 dc             	mov    %eax,-0x24(%ebp)

    pte_t *page_table_entry = 
            (pte_t *)(page_table_addr) + page_table_index * sizeof(pte_t);
c01030f4:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01030f7:	c1 e0 04             	shl    $0x4,%eax
c01030fa:	89 c2                	mov    %eax,%edx
c01030fc:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01030ff:	01 d0                	add    %edx,%eax

    uintptr_t page_table_index = PTX(la);
    // Page directory table's entry is just a pointer to the page table itself.
    uintptr_t page_table_addr = PTE_ADDR(*entry);

    pte_t *page_table_entry = 
c0103101:	89 45 d8             	mov    %eax,-0x28(%ebp)
            (pte_t *)(page_table_addr) + page_table_index * sizeof(pte_t);
    return page_table_entry;
c0103104:	8b 45 d8             	mov    -0x28(%ebp),%eax
}
c0103107:	c9                   	leave  
c0103108:	c3                   	ret    

c0103109 <get_page>:

//get_page - get related Page struct for linear address la using PDT pgdir
struct Page *
get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
c0103109:	55                   	push   %ebp
c010310a:	89 e5                	mov    %esp,%ebp
c010310c:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
c010310f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0103116:	00 
c0103117:	8b 45 0c             	mov    0xc(%ebp),%eax
c010311a:	89 44 24 04          	mov    %eax,0x4(%esp)
c010311e:	8b 45 08             	mov    0x8(%ebp),%eax
c0103121:	89 04 24             	mov    %eax,(%esp)
c0103124:	e8 d3 fe ff ff       	call   c0102ffc <get_pte>
c0103129:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep_store != NULL) {
c010312c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0103130:	74 08                	je     c010313a <get_page+0x31>
        *ptep_store = ptep;
c0103132:	8b 45 10             	mov    0x10(%ebp),%eax
c0103135:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0103138:	89 10                	mov    %edx,(%eax)
    }
    if (ptep != NULL && *ptep & PTE_P) {
c010313a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c010313e:	74 1b                	je     c010315b <get_page+0x52>
c0103140:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103143:	8b 00                	mov    (%eax),%eax
c0103145:	83 e0 01             	and    $0x1,%eax
c0103148:	85 c0                	test   %eax,%eax
c010314a:	74 0f                	je     c010315b <get_page+0x52>
        return pte2page(*ptep);
c010314c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010314f:	8b 00                	mov    (%eax),%eax
c0103151:	89 04 24             	mov    %eax,(%esp)
c0103154:	e8 9e f5 ff ff       	call   c01026f7 <pte2page>
c0103159:	eb 05                	jmp    c0103160 <get_page+0x57>
    }
    return NULL;
c010315b:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0103160:	c9                   	leave  
c0103161:	c3                   	ret    

c0103162 <page_remove_pte>:

//page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
//note: PT is changed, so the TLB need to be invalidate 
static inline void
page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
c0103162:	55                   	push   %ebp
c0103163:	89 e5                	mov    %esp,%ebp
                                  //(4) and free this page when page reference reachs 0
                                  //(5) clear second page table entry
                                  //(6) flush tlb
    }
#endif
}
c0103165:	90                   	nop
c0103166:	5d                   	pop    %ebp
c0103167:	c3                   	ret    

c0103168 <page_remove>:

//page_remove - free an Page which is related linear address la and has an validated pte
void
page_remove(pde_t *pgdir, uintptr_t la) {
c0103168:	55                   	push   %ebp
c0103169:	89 e5                	mov    %esp,%ebp
c010316b:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
c010316e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0103175:	00 
c0103176:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103179:	89 44 24 04          	mov    %eax,0x4(%esp)
c010317d:	8b 45 08             	mov    0x8(%ebp),%eax
c0103180:	89 04 24             	mov    %eax,(%esp)
c0103183:	e8 74 fe ff ff       	call   c0102ffc <get_pte>
c0103188:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep != NULL) {
c010318b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c010318f:	74 19                	je     c01031aa <page_remove+0x42>
        page_remove_pte(pgdir, la, ptep);
c0103191:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103194:	89 44 24 08          	mov    %eax,0x8(%esp)
c0103198:	8b 45 0c             	mov    0xc(%ebp),%eax
c010319b:	89 44 24 04          	mov    %eax,0x4(%esp)
c010319f:	8b 45 08             	mov    0x8(%ebp),%eax
c01031a2:	89 04 24             	mov    %eax,(%esp)
c01031a5:	e8 b8 ff ff ff       	call   c0103162 <page_remove_pte>
    }
}
c01031aa:	90                   	nop
c01031ab:	c9                   	leave  
c01031ac:	c3                   	ret    

c01031ad <page_insert>:
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
//note: PT is changed, so the TLB need to be invalidate 
int
page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
c01031ad:	55                   	push   %ebp
c01031ae:	89 e5                	mov    %esp,%ebp
c01031b0:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 1);
c01031b3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
c01031ba:	00 
c01031bb:	8b 45 10             	mov    0x10(%ebp),%eax
c01031be:	89 44 24 04          	mov    %eax,0x4(%esp)
c01031c2:	8b 45 08             	mov    0x8(%ebp),%eax
c01031c5:	89 04 24             	mov    %eax,(%esp)
c01031c8:	e8 2f fe ff ff       	call   c0102ffc <get_pte>
c01031cd:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep == NULL) {
c01031d0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01031d4:	75 0a                	jne    c01031e0 <page_insert+0x33>
        return -E_NO_MEM;
c01031d6:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
c01031db:	e9 84 00 00 00       	jmp    c0103264 <page_insert+0xb7>
    }
    page_ref_inc(page);
c01031e0:	8b 45 0c             	mov    0xc(%ebp),%eax
c01031e3:	89 04 24             	mov    %eax,(%esp)
c01031e6:	e8 7a f5 ff ff       	call   c0102765 <page_ref_inc>
    if (*ptep & PTE_P) {
c01031eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01031ee:	8b 00                	mov    (%eax),%eax
c01031f0:	83 e0 01             	and    $0x1,%eax
c01031f3:	85 c0                	test   %eax,%eax
c01031f5:	74 3e                	je     c0103235 <page_insert+0x88>
        struct Page *p = pte2page(*ptep);
c01031f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01031fa:	8b 00                	mov    (%eax),%eax
c01031fc:	89 04 24             	mov    %eax,(%esp)
c01031ff:	e8 f3 f4 ff ff       	call   c01026f7 <pte2page>
c0103204:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (p == page) {
c0103207:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010320a:	3b 45 0c             	cmp    0xc(%ebp),%eax
c010320d:	75 0d                	jne    c010321c <page_insert+0x6f>
            page_ref_dec(page);
c010320f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103212:	89 04 24             	mov    %eax,(%esp)
c0103215:	e8 62 f5 ff ff       	call   c010277c <page_ref_dec>
c010321a:	eb 19                	jmp    c0103235 <page_insert+0x88>
        }
        else {
            page_remove_pte(pgdir, la, ptep);
c010321c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010321f:	89 44 24 08          	mov    %eax,0x8(%esp)
c0103223:	8b 45 10             	mov    0x10(%ebp),%eax
c0103226:	89 44 24 04          	mov    %eax,0x4(%esp)
c010322a:	8b 45 08             	mov    0x8(%ebp),%eax
c010322d:	89 04 24             	mov    %eax,(%esp)
c0103230:	e8 2d ff ff ff       	call   c0103162 <page_remove_pte>
        }
    }
    *ptep = page2pa(page) | PTE_P | perm;
c0103235:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103238:	89 04 24             	mov    %eax,(%esp)
c010323b:	e8 fe f3 ff ff       	call   c010263e <page2pa>
c0103240:	0b 45 14             	or     0x14(%ebp),%eax
c0103243:	83 c8 01             	or     $0x1,%eax
c0103246:	89 c2                	mov    %eax,%edx
c0103248:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010324b:	89 10                	mov    %edx,(%eax)
    tlb_invalidate(pgdir, la);
c010324d:	8b 45 10             	mov    0x10(%ebp),%eax
c0103250:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103254:	8b 45 08             	mov    0x8(%ebp),%eax
c0103257:	89 04 24             	mov    %eax,(%esp)
c010325a:	e8 07 00 00 00       	call   c0103266 <tlb_invalidate>
    return 0;
c010325f:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0103264:	c9                   	leave  
c0103265:	c3                   	ret    

c0103266 <tlb_invalidate>:

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void
tlb_invalidate(pde_t *pgdir, uintptr_t la) {
c0103266:	55                   	push   %ebp
c0103267:	89 e5                	mov    %esp,%ebp
c0103269:	83 ec 28             	sub    $0x28,%esp
}

static inline uintptr_t
rcr3(void) {
    uintptr_t cr3;
    asm volatile ("mov %%cr3, %0" : "=r" (cr3) :: "memory");
c010326c:	0f 20 d8             	mov    %cr3,%eax
c010326f:	89 45 ec             	mov    %eax,-0x14(%ebp)
    return cr3;
c0103272:	8b 55 ec             	mov    -0x14(%ebp),%edx
    if (rcr3() == PADDR(pgdir)) {
c0103275:	8b 45 08             	mov    0x8(%ebp),%eax
c0103278:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010327b:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
c0103282:	77 23                	ja     c01032a7 <tlb_invalidate+0x41>
c0103284:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103287:	89 44 24 0c          	mov    %eax,0xc(%esp)
c010328b:	c7 44 24 08 64 64 10 	movl   $0xc0106464,0x8(%esp)
c0103292:	c0 
c0103293:	c7 44 24 04 f0 01 00 	movl   $0x1f0,0x4(%esp)
c010329a:	00 
c010329b:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c01032a2:	e8 42 d1 ff ff       	call   c01003e9 <__panic>
c01032a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01032aa:	05 00 00 00 40       	add    $0x40000000,%eax
c01032af:	39 c2                	cmp    %eax,%edx
c01032b1:	75 0c                	jne    c01032bf <tlb_invalidate+0x59>
        invlpg((void *)la);
c01032b3:	8b 45 0c             	mov    0xc(%ebp),%eax
c01032b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static inline void
invlpg(void *addr) {
    asm volatile ("invlpg (%0)" :: "r" (addr) : "memory");
c01032b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01032bc:	0f 01 38             	invlpg (%eax)
    }
}
c01032bf:	90                   	nop
c01032c0:	c9                   	leave  
c01032c1:	c3                   	ret    

c01032c2 <check_alloc_page>:

static void
check_alloc_page(void) {
c01032c2:	55                   	push   %ebp
c01032c3:	89 e5                	mov    %esp,%ebp
c01032c5:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->check();
c01032c8:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c01032cd:	8b 40 18             	mov    0x18(%eax),%eax
c01032d0:	ff d0                	call   *%eax
    cprintf("check_alloc_page() succeeded!\n");
c01032d2:	c7 04 24 e8 64 10 c0 	movl   $0xc01064e8,(%esp)
c01032d9:	e8 b4 cf ff ff       	call   c0100292 <cprintf>
}
c01032de:	90                   	nop
c01032df:	c9                   	leave  
c01032e0:	c3                   	ret    

c01032e1 <check_pgdir>:

static void
check_pgdir(void) {
c01032e1:	55                   	push   %ebp
c01032e2:	89 e5                	mov    %esp,%ebp
c01032e4:	83 ec 38             	sub    $0x38,%esp
    assert(npage <= KMEMSIZE / PGSIZE);
c01032e7:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01032ec:	3d 00 80 03 00       	cmp    $0x38000,%eax
c01032f1:	76 24                	jbe    c0103317 <check_pgdir+0x36>
c01032f3:	c7 44 24 0c 07 65 10 	movl   $0xc0106507,0xc(%esp)
c01032fa:	c0 
c01032fb:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103302:	c0 
c0103303:	c7 44 24 04 fd 01 00 	movl   $0x1fd,0x4(%esp)
c010330a:	00 
c010330b:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103312:	e8 d2 d0 ff ff       	call   c01003e9 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
c0103317:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010331c:	85 c0                	test   %eax,%eax
c010331e:	74 0e                	je     c010332e <check_pgdir+0x4d>
c0103320:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103325:	25 ff 0f 00 00       	and    $0xfff,%eax
c010332a:	85 c0                	test   %eax,%eax
c010332c:	74 24                	je     c0103352 <check_pgdir+0x71>
c010332e:	c7 44 24 0c 24 65 10 	movl   $0xc0106524,0xc(%esp)
c0103335:	c0 
c0103336:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c010333d:	c0 
c010333e:	c7 44 24 04 fe 01 00 	movl   $0x1fe,0x4(%esp)
c0103345:	00 
c0103346:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c010334d:	e8 97 d0 ff ff       	call   c01003e9 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
c0103352:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103357:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c010335e:	00 
c010335f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0103366:	00 
c0103367:	89 04 24             	mov    %eax,(%esp)
c010336a:	e8 9a fd ff ff       	call   c0103109 <get_page>
c010336f:	85 c0                	test   %eax,%eax
c0103371:	74 24                	je     c0103397 <check_pgdir+0xb6>
c0103373:	c7 44 24 0c 5c 65 10 	movl   $0xc010655c,0xc(%esp)
c010337a:	c0 
c010337b:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103382:	c0 
c0103383:	c7 44 24 04 ff 01 00 	movl   $0x1ff,0x4(%esp)
c010338a:	00 
c010338b:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103392:	e8 52 d0 ff ff       	call   c01003e9 <__panic>

    struct Page *p1, *p2;
    p1 = alloc_page();
c0103397:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010339e:	e8 af f5 ff ff       	call   c0102952 <alloc_pages>
c01033a3:	89 45 f4             	mov    %eax,-0xc(%ebp)
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
c01033a6:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01033ab:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
c01033b2:	00 
c01033b3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01033ba:	00 
c01033bb:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01033be:	89 54 24 04          	mov    %edx,0x4(%esp)
c01033c2:	89 04 24             	mov    %eax,(%esp)
c01033c5:	e8 e3 fd ff ff       	call   c01031ad <page_insert>
c01033ca:	85 c0                	test   %eax,%eax
c01033cc:	74 24                	je     c01033f2 <check_pgdir+0x111>
c01033ce:	c7 44 24 0c 84 65 10 	movl   $0xc0106584,0xc(%esp)
c01033d5:	c0 
c01033d6:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c01033dd:	c0 
c01033de:	c7 44 24 04 03 02 00 	movl   $0x203,0x4(%esp)
c01033e5:	00 
c01033e6:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c01033ed:	e8 f7 cf ff ff       	call   c01003e9 <__panic>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
c01033f2:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01033f7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01033fe:	00 
c01033ff:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0103406:	00 
c0103407:	89 04 24             	mov    %eax,(%esp)
c010340a:	e8 ed fb ff ff       	call   c0102ffc <get_pte>
c010340f:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103412:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0103416:	75 24                	jne    c010343c <check_pgdir+0x15b>
c0103418:	c7 44 24 0c b0 65 10 	movl   $0xc01065b0,0xc(%esp)
c010341f:	c0 
c0103420:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103427:	c0 
c0103428:	c7 44 24 04 06 02 00 	movl   $0x206,0x4(%esp)
c010342f:	00 
c0103430:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103437:	e8 ad cf ff ff       	call   c01003e9 <__panic>
    assert(pte2page(*ptep) == p1);
c010343c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010343f:	8b 00                	mov    (%eax),%eax
c0103441:	89 04 24             	mov    %eax,(%esp)
c0103444:	e8 ae f2 ff ff       	call   c01026f7 <pte2page>
c0103449:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010344c:	74 24                	je     c0103472 <check_pgdir+0x191>
c010344e:	c7 44 24 0c dd 65 10 	movl   $0xc01065dd,0xc(%esp)
c0103455:	c0 
c0103456:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c010345d:	c0 
c010345e:	c7 44 24 04 07 02 00 	movl   $0x207,0x4(%esp)
c0103465:	00 
c0103466:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c010346d:	e8 77 cf ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p1) == 1);
c0103472:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103475:	89 04 24             	mov    %eax,(%esp)
c0103478:	e8 d0 f2 ff ff       	call   c010274d <page_ref>
c010347d:	83 f8 01             	cmp    $0x1,%eax
c0103480:	74 24                	je     c01034a6 <check_pgdir+0x1c5>
c0103482:	c7 44 24 0c f3 65 10 	movl   $0xc01065f3,0xc(%esp)
c0103489:	c0 
c010348a:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103491:	c0 
c0103492:	c7 44 24 04 08 02 00 	movl   $0x208,0x4(%esp)
c0103499:	00 
c010349a:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c01034a1:	e8 43 cf ff ff       	call   c01003e9 <__panic>

    ptep = &((pte_t *)KADDR(PDE_ADDR(boot_pgdir[0])))[1];
c01034a6:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01034ab:	8b 00                	mov    (%eax),%eax
c01034ad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c01034b2:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01034b5:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01034b8:	c1 e8 0c             	shr    $0xc,%eax
c01034bb:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01034be:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01034c3:	39 45 e8             	cmp    %eax,-0x18(%ebp)
c01034c6:	72 23                	jb     c01034eb <check_pgdir+0x20a>
c01034c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01034cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01034cf:	c7 44 24 08 c0 63 10 	movl   $0xc01063c0,0x8(%esp)
c01034d6:	c0 
c01034d7:	c7 44 24 04 0a 02 00 	movl   $0x20a,0x4(%esp)
c01034de:	00 
c01034df:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c01034e6:	e8 fe ce ff ff       	call   c01003e9 <__panic>
c01034eb:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01034ee:	2d 00 00 00 40       	sub    $0x40000000,%eax
c01034f3:	83 c0 04             	add    $0x4,%eax
c01034f6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
c01034f9:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01034fe:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0103505:	00 
c0103506:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c010350d:	00 
c010350e:	89 04 24             	mov    %eax,(%esp)
c0103511:	e8 e6 fa ff ff       	call   c0102ffc <get_pte>
c0103516:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c0103519:	74 24                	je     c010353f <check_pgdir+0x25e>
c010351b:	c7 44 24 0c 08 66 10 	movl   $0xc0106608,0xc(%esp)
c0103522:	c0 
c0103523:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c010352a:	c0 
c010352b:	c7 44 24 04 0b 02 00 	movl   $0x20b,0x4(%esp)
c0103532:	00 
c0103533:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c010353a:	e8 aa ce ff ff       	call   c01003e9 <__panic>

    p2 = alloc_page();
c010353f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0103546:	e8 07 f4 ff ff       	call   c0102952 <alloc_pages>
c010354b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
c010354e:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103553:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
c010355a:	00 
c010355b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
c0103562:	00 
c0103563:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0103566:	89 54 24 04          	mov    %edx,0x4(%esp)
c010356a:	89 04 24             	mov    %eax,(%esp)
c010356d:	e8 3b fc ff ff       	call   c01031ad <page_insert>
c0103572:	85 c0                	test   %eax,%eax
c0103574:	74 24                	je     c010359a <check_pgdir+0x2b9>
c0103576:	c7 44 24 0c 30 66 10 	movl   $0xc0106630,0xc(%esp)
c010357d:	c0 
c010357e:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103585:	c0 
c0103586:	c7 44 24 04 0e 02 00 	movl   $0x20e,0x4(%esp)
c010358d:	00 
c010358e:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103595:	e8 4f ce ff ff       	call   c01003e9 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
c010359a:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010359f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01035a6:	00 
c01035a7:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c01035ae:	00 
c01035af:	89 04 24             	mov    %eax,(%esp)
c01035b2:	e8 45 fa ff ff       	call   c0102ffc <get_pte>
c01035b7:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01035ba:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01035be:	75 24                	jne    c01035e4 <check_pgdir+0x303>
c01035c0:	c7 44 24 0c 68 66 10 	movl   $0xc0106668,0xc(%esp)
c01035c7:	c0 
c01035c8:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c01035cf:	c0 
c01035d0:	c7 44 24 04 0f 02 00 	movl   $0x20f,0x4(%esp)
c01035d7:	00 
c01035d8:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c01035df:	e8 05 ce ff ff       	call   c01003e9 <__panic>
    assert(*ptep & PTE_U);
c01035e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01035e7:	8b 00                	mov    (%eax),%eax
c01035e9:	83 e0 04             	and    $0x4,%eax
c01035ec:	85 c0                	test   %eax,%eax
c01035ee:	75 24                	jne    c0103614 <check_pgdir+0x333>
c01035f0:	c7 44 24 0c 98 66 10 	movl   $0xc0106698,0xc(%esp)
c01035f7:	c0 
c01035f8:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c01035ff:	c0 
c0103600:	c7 44 24 04 10 02 00 	movl   $0x210,0x4(%esp)
c0103607:	00 
c0103608:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c010360f:	e8 d5 cd ff ff       	call   c01003e9 <__panic>
    assert(*ptep & PTE_W);
c0103614:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103617:	8b 00                	mov    (%eax),%eax
c0103619:	83 e0 02             	and    $0x2,%eax
c010361c:	85 c0                	test   %eax,%eax
c010361e:	75 24                	jne    c0103644 <check_pgdir+0x363>
c0103620:	c7 44 24 0c a6 66 10 	movl   $0xc01066a6,0xc(%esp)
c0103627:	c0 
c0103628:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c010362f:	c0 
c0103630:	c7 44 24 04 11 02 00 	movl   $0x211,0x4(%esp)
c0103637:	00 
c0103638:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c010363f:	e8 a5 cd ff ff       	call   c01003e9 <__panic>
    assert(boot_pgdir[0] & PTE_U);
c0103644:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103649:	8b 00                	mov    (%eax),%eax
c010364b:	83 e0 04             	and    $0x4,%eax
c010364e:	85 c0                	test   %eax,%eax
c0103650:	75 24                	jne    c0103676 <check_pgdir+0x395>
c0103652:	c7 44 24 0c b4 66 10 	movl   $0xc01066b4,0xc(%esp)
c0103659:	c0 
c010365a:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103661:	c0 
c0103662:	c7 44 24 04 12 02 00 	movl   $0x212,0x4(%esp)
c0103669:	00 
c010366a:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103671:	e8 73 cd ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p2) == 1);
c0103676:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103679:	89 04 24             	mov    %eax,(%esp)
c010367c:	e8 cc f0 ff ff       	call   c010274d <page_ref>
c0103681:	83 f8 01             	cmp    $0x1,%eax
c0103684:	74 24                	je     c01036aa <check_pgdir+0x3c9>
c0103686:	c7 44 24 0c ca 66 10 	movl   $0xc01066ca,0xc(%esp)
c010368d:	c0 
c010368e:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103695:	c0 
c0103696:	c7 44 24 04 13 02 00 	movl   $0x213,0x4(%esp)
c010369d:	00 
c010369e:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c01036a5:	e8 3f cd ff ff       	call   c01003e9 <__panic>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
c01036aa:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01036af:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
c01036b6:	00 
c01036b7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
c01036be:	00 
c01036bf:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01036c2:	89 54 24 04          	mov    %edx,0x4(%esp)
c01036c6:	89 04 24             	mov    %eax,(%esp)
c01036c9:	e8 df fa ff ff       	call   c01031ad <page_insert>
c01036ce:	85 c0                	test   %eax,%eax
c01036d0:	74 24                	je     c01036f6 <check_pgdir+0x415>
c01036d2:	c7 44 24 0c dc 66 10 	movl   $0xc01066dc,0xc(%esp)
c01036d9:	c0 
c01036da:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c01036e1:	c0 
c01036e2:	c7 44 24 04 15 02 00 	movl   $0x215,0x4(%esp)
c01036e9:	00 
c01036ea:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c01036f1:	e8 f3 cc ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p1) == 2);
c01036f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01036f9:	89 04 24             	mov    %eax,(%esp)
c01036fc:	e8 4c f0 ff ff       	call   c010274d <page_ref>
c0103701:	83 f8 02             	cmp    $0x2,%eax
c0103704:	74 24                	je     c010372a <check_pgdir+0x449>
c0103706:	c7 44 24 0c 08 67 10 	movl   $0xc0106708,0xc(%esp)
c010370d:	c0 
c010370e:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103715:	c0 
c0103716:	c7 44 24 04 16 02 00 	movl   $0x216,0x4(%esp)
c010371d:	00 
c010371e:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103725:	e8 bf cc ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p2) == 0);
c010372a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010372d:	89 04 24             	mov    %eax,(%esp)
c0103730:	e8 18 f0 ff ff       	call   c010274d <page_ref>
c0103735:	85 c0                	test   %eax,%eax
c0103737:	74 24                	je     c010375d <check_pgdir+0x47c>
c0103739:	c7 44 24 0c 1a 67 10 	movl   $0xc010671a,0xc(%esp)
c0103740:	c0 
c0103741:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103748:	c0 
c0103749:	c7 44 24 04 17 02 00 	movl   $0x217,0x4(%esp)
c0103750:	00 
c0103751:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103758:	e8 8c cc ff ff       	call   c01003e9 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
c010375d:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103762:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0103769:	00 
c010376a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c0103771:	00 
c0103772:	89 04 24             	mov    %eax,(%esp)
c0103775:	e8 82 f8 ff ff       	call   c0102ffc <get_pte>
c010377a:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010377d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0103781:	75 24                	jne    c01037a7 <check_pgdir+0x4c6>
c0103783:	c7 44 24 0c 68 66 10 	movl   $0xc0106668,0xc(%esp)
c010378a:	c0 
c010378b:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103792:	c0 
c0103793:	c7 44 24 04 18 02 00 	movl   $0x218,0x4(%esp)
c010379a:	00 
c010379b:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c01037a2:	e8 42 cc ff ff       	call   c01003e9 <__panic>
    assert(pte2page(*ptep) == p1);
c01037a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01037aa:	8b 00                	mov    (%eax),%eax
c01037ac:	89 04 24             	mov    %eax,(%esp)
c01037af:	e8 43 ef ff ff       	call   c01026f7 <pte2page>
c01037b4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01037b7:	74 24                	je     c01037dd <check_pgdir+0x4fc>
c01037b9:	c7 44 24 0c dd 65 10 	movl   $0xc01065dd,0xc(%esp)
c01037c0:	c0 
c01037c1:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c01037c8:	c0 
c01037c9:	c7 44 24 04 19 02 00 	movl   $0x219,0x4(%esp)
c01037d0:	00 
c01037d1:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c01037d8:	e8 0c cc ff ff       	call   c01003e9 <__panic>
    assert((*ptep & PTE_U) == 0);
c01037dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01037e0:	8b 00                	mov    (%eax),%eax
c01037e2:	83 e0 04             	and    $0x4,%eax
c01037e5:	85 c0                	test   %eax,%eax
c01037e7:	74 24                	je     c010380d <check_pgdir+0x52c>
c01037e9:	c7 44 24 0c 2c 67 10 	movl   $0xc010672c,0xc(%esp)
c01037f0:	c0 
c01037f1:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c01037f8:	c0 
c01037f9:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
c0103800:	00 
c0103801:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103808:	e8 dc cb ff ff       	call   c01003e9 <__panic>

    page_remove(boot_pgdir, 0x0);
c010380d:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103812:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0103819:	00 
c010381a:	89 04 24             	mov    %eax,(%esp)
c010381d:	e8 46 f9 ff ff       	call   c0103168 <page_remove>
    assert(page_ref(p1) == 1);
c0103822:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103825:	89 04 24             	mov    %eax,(%esp)
c0103828:	e8 20 ef ff ff       	call   c010274d <page_ref>
c010382d:	83 f8 01             	cmp    $0x1,%eax
c0103830:	74 24                	je     c0103856 <check_pgdir+0x575>
c0103832:	c7 44 24 0c f3 65 10 	movl   $0xc01065f3,0xc(%esp)
c0103839:	c0 
c010383a:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103841:	c0 
c0103842:	c7 44 24 04 1d 02 00 	movl   $0x21d,0x4(%esp)
c0103849:	00 
c010384a:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103851:	e8 93 cb ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p2) == 0);
c0103856:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103859:	89 04 24             	mov    %eax,(%esp)
c010385c:	e8 ec ee ff ff       	call   c010274d <page_ref>
c0103861:	85 c0                	test   %eax,%eax
c0103863:	74 24                	je     c0103889 <check_pgdir+0x5a8>
c0103865:	c7 44 24 0c 1a 67 10 	movl   $0xc010671a,0xc(%esp)
c010386c:	c0 
c010386d:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103874:	c0 
c0103875:	c7 44 24 04 1e 02 00 	movl   $0x21e,0x4(%esp)
c010387c:	00 
c010387d:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103884:	e8 60 cb ff ff       	call   c01003e9 <__panic>

    page_remove(boot_pgdir, PGSIZE);
c0103889:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010388e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c0103895:	00 
c0103896:	89 04 24             	mov    %eax,(%esp)
c0103899:	e8 ca f8 ff ff       	call   c0103168 <page_remove>
    assert(page_ref(p1) == 0);
c010389e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01038a1:	89 04 24             	mov    %eax,(%esp)
c01038a4:	e8 a4 ee ff ff       	call   c010274d <page_ref>
c01038a9:	85 c0                	test   %eax,%eax
c01038ab:	74 24                	je     c01038d1 <check_pgdir+0x5f0>
c01038ad:	c7 44 24 0c 41 67 10 	movl   $0xc0106741,0xc(%esp)
c01038b4:	c0 
c01038b5:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c01038bc:	c0 
c01038bd:	c7 44 24 04 21 02 00 	movl   $0x221,0x4(%esp)
c01038c4:	00 
c01038c5:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c01038cc:	e8 18 cb ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p2) == 0);
c01038d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01038d4:	89 04 24             	mov    %eax,(%esp)
c01038d7:	e8 71 ee ff ff       	call   c010274d <page_ref>
c01038dc:	85 c0                	test   %eax,%eax
c01038de:	74 24                	je     c0103904 <check_pgdir+0x623>
c01038e0:	c7 44 24 0c 1a 67 10 	movl   $0xc010671a,0xc(%esp)
c01038e7:	c0 
c01038e8:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c01038ef:	c0 
c01038f0:	c7 44 24 04 22 02 00 	movl   $0x222,0x4(%esp)
c01038f7:	00 
c01038f8:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c01038ff:	e8 e5 ca ff ff       	call   c01003e9 <__panic>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
c0103904:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103909:	8b 00                	mov    (%eax),%eax
c010390b:	89 04 24             	mov    %eax,(%esp)
c010390e:	e8 22 ee ff ff       	call   c0102735 <pde2page>
c0103913:	89 04 24             	mov    %eax,(%esp)
c0103916:	e8 32 ee ff ff       	call   c010274d <page_ref>
c010391b:	83 f8 01             	cmp    $0x1,%eax
c010391e:	74 24                	je     c0103944 <check_pgdir+0x663>
c0103920:	c7 44 24 0c 54 67 10 	movl   $0xc0106754,0xc(%esp)
c0103927:	c0 
c0103928:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c010392f:	c0 
c0103930:	c7 44 24 04 24 02 00 	movl   $0x224,0x4(%esp)
c0103937:	00 
c0103938:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c010393f:	e8 a5 ca ff ff       	call   c01003e9 <__panic>
    free_page(pde2page(boot_pgdir[0]));
c0103944:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103949:	8b 00                	mov    (%eax),%eax
c010394b:	89 04 24             	mov    %eax,(%esp)
c010394e:	e8 e2 ed ff ff       	call   c0102735 <pde2page>
c0103953:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c010395a:	00 
c010395b:	89 04 24             	mov    %eax,(%esp)
c010395e:	e8 27 f0 ff ff       	call   c010298a <free_pages>
    boot_pgdir[0] = 0;
c0103963:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103968:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_pgdir() succeeded!\n");
c010396e:	c7 04 24 7b 67 10 c0 	movl   $0xc010677b,(%esp)
c0103975:	e8 18 c9 ff ff       	call   c0100292 <cprintf>
}
c010397a:	90                   	nop
c010397b:	c9                   	leave  
c010397c:	c3                   	ret    

c010397d <check_boot_pgdir>:

static void
check_boot_pgdir(void) {
c010397d:	55                   	push   %ebp
c010397e:	89 e5                	mov    %esp,%ebp
c0103980:	83 ec 38             	sub    $0x38,%esp
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
c0103983:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c010398a:	e9 ca 00 00 00       	jmp    c0103a59 <check_boot_pgdir+0xdc>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
c010398f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103992:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103995:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103998:	c1 e8 0c             	shr    $0xc,%eax
c010399b:	89 45 ec             	mov    %eax,-0x14(%ebp)
c010399e:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01039a3:	39 45 ec             	cmp    %eax,-0x14(%ebp)
c01039a6:	72 23                	jb     c01039cb <check_boot_pgdir+0x4e>
c01039a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01039ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01039af:	c7 44 24 08 c0 63 10 	movl   $0xc01063c0,0x8(%esp)
c01039b6:	c0 
c01039b7:	c7 44 24 04 30 02 00 	movl   $0x230,0x4(%esp)
c01039be:	00 
c01039bf:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c01039c6:	e8 1e ca ff ff       	call   c01003e9 <__panic>
c01039cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01039ce:	2d 00 00 00 40       	sub    $0x40000000,%eax
c01039d3:	89 c2                	mov    %eax,%edx
c01039d5:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01039da:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01039e1:	00 
c01039e2:	89 54 24 04          	mov    %edx,0x4(%esp)
c01039e6:	89 04 24             	mov    %eax,(%esp)
c01039e9:	e8 0e f6 ff ff       	call   c0102ffc <get_pte>
c01039ee:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01039f1:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c01039f5:	75 24                	jne    c0103a1b <check_boot_pgdir+0x9e>
c01039f7:	c7 44 24 0c 98 67 10 	movl   $0xc0106798,0xc(%esp)
c01039fe:	c0 
c01039ff:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103a06:	c0 
c0103a07:	c7 44 24 04 30 02 00 	movl   $0x230,0x4(%esp)
c0103a0e:	00 
c0103a0f:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103a16:	e8 ce c9 ff ff       	call   c01003e9 <__panic>
        assert(PTE_ADDR(*ptep) == i);
c0103a1b:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103a1e:	8b 00                	mov    (%eax),%eax
c0103a20:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103a25:	89 c2                	mov    %eax,%edx
c0103a27:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103a2a:	39 c2                	cmp    %eax,%edx
c0103a2c:	74 24                	je     c0103a52 <check_boot_pgdir+0xd5>
c0103a2e:	c7 44 24 0c d5 67 10 	movl   $0xc01067d5,0xc(%esp)
c0103a35:	c0 
c0103a36:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103a3d:	c0 
c0103a3e:	c7 44 24 04 31 02 00 	movl   $0x231,0x4(%esp)
c0103a45:	00 
c0103a46:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103a4d:	e8 97 c9 ff ff       	call   c01003e9 <__panic>

static void
check_boot_pgdir(void) {
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
c0103a52:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
c0103a59:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0103a5c:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103a61:	39 c2                	cmp    %eax,%edx
c0103a63:	0f 82 26 ff ff ff    	jb     c010398f <check_boot_pgdir+0x12>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }

    assert(PDE_ADDR(boot_pgdir[PDX(VPT)]) == PADDR(boot_pgdir));
c0103a69:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103a6e:	05 ac 0f 00 00       	add    $0xfac,%eax
c0103a73:	8b 00                	mov    (%eax),%eax
c0103a75:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103a7a:	89 c2                	mov    %eax,%edx
c0103a7c:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103a81:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103a84:	81 7d e4 ff ff ff bf 	cmpl   $0xbfffffff,-0x1c(%ebp)
c0103a8b:	77 23                	ja     c0103ab0 <check_boot_pgdir+0x133>
c0103a8d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103a90:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0103a94:	c7 44 24 08 64 64 10 	movl   $0xc0106464,0x8(%esp)
c0103a9b:	c0 
c0103a9c:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
c0103aa3:	00 
c0103aa4:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103aab:	e8 39 c9 ff ff       	call   c01003e9 <__panic>
c0103ab0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103ab3:	05 00 00 00 40       	add    $0x40000000,%eax
c0103ab8:	39 c2                	cmp    %eax,%edx
c0103aba:	74 24                	je     c0103ae0 <check_boot_pgdir+0x163>
c0103abc:	c7 44 24 0c ec 67 10 	movl   $0xc01067ec,0xc(%esp)
c0103ac3:	c0 
c0103ac4:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103acb:	c0 
c0103acc:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
c0103ad3:	00 
c0103ad4:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103adb:	e8 09 c9 ff ff       	call   c01003e9 <__panic>

    assert(boot_pgdir[0] == 0);
c0103ae0:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103ae5:	8b 00                	mov    (%eax),%eax
c0103ae7:	85 c0                	test   %eax,%eax
c0103ae9:	74 24                	je     c0103b0f <check_boot_pgdir+0x192>
c0103aeb:	c7 44 24 0c 20 68 10 	movl   $0xc0106820,0xc(%esp)
c0103af2:	c0 
c0103af3:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103afa:	c0 
c0103afb:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
c0103b02:	00 
c0103b03:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103b0a:	e8 da c8 ff ff       	call   c01003e9 <__panic>

    struct Page *p;
    p = alloc_page();
c0103b0f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0103b16:	e8 37 ee ff ff       	call   c0102952 <alloc_pages>
c0103b1b:	89 45 e0             	mov    %eax,-0x20(%ebp)
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W) == 0);
c0103b1e:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103b23:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
c0103b2a:	00 
c0103b2b:	c7 44 24 08 00 01 00 	movl   $0x100,0x8(%esp)
c0103b32:	00 
c0103b33:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0103b36:	89 54 24 04          	mov    %edx,0x4(%esp)
c0103b3a:	89 04 24             	mov    %eax,(%esp)
c0103b3d:	e8 6b f6 ff ff       	call   c01031ad <page_insert>
c0103b42:	85 c0                	test   %eax,%eax
c0103b44:	74 24                	je     c0103b6a <check_boot_pgdir+0x1ed>
c0103b46:	c7 44 24 0c 34 68 10 	movl   $0xc0106834,0xc(%esp)
c0103b4d:	c0 
c0103b4e:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103b55:	c0 
c0103b56:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
c0103b5d:	00 
c0103b5e:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103b65:	e8 7f c8 ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p) == 1);
c0103b6a:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103b6d:	89 04 24             	mov    %eax,(%esp)
c0103b70:	e8 d8 eb ff ff       	call   c010274d <page_ref>
c0103b75:	83 f8 01             	cmp    $0x1,%eax
c0103b78:	74 24                	je     c0103b9e <check_boot_pgdir+0x221>
c0103b7a:	c7 44 24 0c 62 68 10 	movl   $0xc0106862,0xc(%esp)
c0103b81:	c0 
c0103b82:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103b89:	c0 
c0103b8a:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
c0103b91:	00 
c0103b92:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103b99:	e8 4b c8 ff ff       	call   c01003e9 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W) == 0);
c0103b9e:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103ba3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
c0103baa:	00 
c0103bab:	c7 44 24 08 00 11 00 	movl   $0x1100,0x8(%esp)
c0103bb2:	00 
c0103bb3:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0103bb6:	89 54 24 04          	mov    %edx,0x4(%esp)
c0103bba:	89 04 24             	mov    %eax,(%esp)
c0103bbd:	e8 eb f5 ff ff       	call   c01031ad <page_insert>
c0103bc2:	85 c0                	test   %eax,%eax
c0103bc4:	74 24                	je     c0103bea <check_boot_pgdir+0x26d>
c0103bc6:	c7 44 24 0c 74 68 10 	movl   $0xc0106874,0xc(%esp)
c0103bcd:	c0 
c0103bce:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103bd5:	c0 
c0103bd6:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
c0103bdd:	00 
c0103bde:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103be5:	e8 ff c7 ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p) == 2);
c0103bea:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103bed:	89 04 24             	mov    %eax,(%esp)
c0103bf0:	e8 58 eb ff ff       	call   c010274d <page_ref>
c0103bf5:	83 f8 02             	cmp    $0x2,%eax
c0103bf8:	74 24                	je     c0103c1e <check_boot_pgdir+0x2a1>
c0103bfa:	c7 44 24 0c ab 68 10 	movl   $0xc01068ab,0xc(%esp)
c0103c01:	c0 
c0103c02:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103c09:	c0 
c0103c0a:	c7 44 24 04 3d 02 00 	movl   $0x23d,0x4(%esp)
c0103c11:	00 
c0103c12:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103c19:	e8 cb c7 ff ff       	call   c01003e9 <__panic>

    const char *str = "ucore: Hello world!!";
c0103c1e:	c7 45 dc bc 68 10 c0 	movl   $0xc01068bc,-0x24(%ebp)
    strcpy((void *)0x100, str);
c0103c25:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0103c28:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103c2c:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
c0103c33:	e8 a1 15 00 00       	call   c01051d9 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
c0103c38:	c7 44 24 04 00 11 00 	movl   $0x1100,0x4(%esp)
c0103c3f:	00 
c0103c40:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
c0103c47:	e8 04 16 00 00       	call   c0105250 <strcmp>
c0103c4c:	85 c0                	test   %eax,%eax
c0103c4e:	74 24                	je     c0103c74 <check_boot_pgdir+0x2f7>
c0103c50:	c7 44 24 0c d4 68 10 	movl   $0xc01068d4,0xc(%esp)
c0103c57:	c0 
c0103c58:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103c5f:	c0 
c0103c60:	c7 44 24 04 41 02 00 	movl   $0x241,0x4(%esp)
c0103c67:	00 
c0103c68:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103c6f:	e8 75 c7 ff ff       	call   c01003e9 <__panic>

    *(char *)(page2kva(p) + 0x100) = '\0';
c0103c74:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103c77:	89 04 24             	mov    %eax,(%esp)
c0103c7a:	e8 24 ea ff ff       	call   c01026a3 <page2kva>
c0103c7f:	05 00 01 00 00       	add    $0x100,%eax
c0103c84:	c6 00 00             	movb   $0x0,(%eax)
    assert(strlen((const char *)0x100) == 0);
c0103c87:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
c0103c8e:	e8 f0 14 00 00       	call   c0105183 <strlen>
c0103c93:	85 c0                	test   %eax,%eax
c0103c95:	74 24                	je     c0103cbb <check_boot_pgdir+0x33e>
c0103c97:	c7 44 24 0c 0c 69 10 	movl   $0xc010690c,0xc(%esp)
c0103c9e:	c0 
c0103c9f:	c7 44 24 08 ad 64 10 	movl   $0xc01064ad,0x8(%esp)
c0103ca6:	c0 
c0103ca7:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
c0103cae:	00 
c0103caf:	c7 04 24 88 64 10 c0 	movl   $0xc0106488,(%esp)
c0103cb6:	e8 2e c7 ff ff       	call   c01003e9 <__panic>

    free_page(p);
c0103cbb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0103cc2:	00 
c0103cc3:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103cc6:	89 04 24             	mov    %eax,(%esp)
c0103cc9:	e8 bc ec ff ff       	call   c010298a <free_pages>
    free_page(pde2page(boot_pgdir[0]));
c0103cce:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103cd3:	8b 00                	mov    (%eax),%eax
c0103cd5:	89 04 24             	mov    %eax,(%esp)
c0103cd8:	e8 58 ea ff ff       	call   c0102735 <pde2page>
c0103cdd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0103ce4:	00 
c0103ce5:	89 04 24             	mov    %eax,(%esp)
c0103ce8:	e8 9d ec ff ff       	call   c010298a <free_pages>
    boot_pgdir[0] = 0;
c0103ced:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103cf2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_boot_pgdir() succeeded!\n");
c0103cf8:	c7 04 24 30 69 10 c0 	movl   $0xc0106930,(%esp)
c0103cff:	e8 8e c5 ff ff       	call   c0100292 <cprintf>
}
c0103d04:	90                   	nop
c0103d05:	c9                   	leave  
c0103d06:	c3                   	ret    

c0103d07 <perm2str>:

//perm2str - use string 'u,r,w,-' to present the permission
static const char *
perm2str(int perm) {
c0103d07:	55                   	push   %ebp
c0103d08:	89 e5                	mov    %esp,%ebp
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
c0103d0a:	8b 45 08             	mov    0x8(%ebp),%eax
c0103d0d:	83 e0 04             	and    $0x4,%eax
c0103d10:	85 c0                	test   %eax,%eax
c0103d12:	74 04                	je     c0103d18 <perm2str+0x11>
c0103d14:	b0 75                	mov    $0x75,%al
c0103d16:	eb 02                	jmp    c0103d1a <perm2str+0x13>
c0103d18:	b0 2d                	mov    $0x2d,%al
c0103d1a:	a2 08 af 11 c0       	mov    %al,0xc011af08
    str[1] = 'r';
c0103d1f:	c6 05 09 af 11 c0 72 	movb   $0x72,0xc011af09
    str[2] = (perm & PTE_W) ? 'w' : '-';
c0103d26:	8b 45 08             	mov    0x8(%ebp),%eax
c0103d29:	83 e0 02             	and    $0x2,%eax
c0103d2c:	85 c0                	test   %eax,%eax
c0103d2e:	74 04                	je     c0103d34 <perm2str+0x2d>
c0103d30:	b0 77                	mov    $0x77,%al
c0103d32:	eb 02                	jmp    c0103d36 <perm2str+0x2f>
c0103d34:	b0 2d                	mov    $0x2d,%al
c0103d36:	a2 0a af 11 c0       	mov    %al,0xc011af0a
    str[3] = '\0';
c0103d3b:	c6 05 0b af 11 c0 00 	movb   $0x0,0xc011af0b
    return str;
c0103d42:	b8 08 af 11 c0       	mov    $0xc011af08,%eax
}
c0103d47:	5d                   	pop    %ebp
c0103d48:	c3                   	ret    

c0103d49 <get_pgtable_items>:
//  table:       the beginning addr of table
//  left_store:  the pointer of the high side of table's next range
//  right_store: the pointer of the low side of table's next range
// return value: 0 - not a invalid item range, perm - a valid item range with perm permission 
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
c0103d49:	55                   	push   %ebp
c0103d4a:	89 e5                	mov    %esp,%ebp
c0103d4c:	83 ec 10             	sub    $0x10,%esp
    if (start >= right) {
c0103d4f:	8b 45 10             	mov    0x10(%ebp),%eax
c0103d52:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103d55:	72 0d                	jb     c0103d64 <get_pgtable_items+0x1b>
        return 0;
c0103d57:	b8 00 00 00 00       	mov    $0x0,%eax
c0103d5c:	e9 98 00 00 00       	jmp    c0103df9 <get_pgtable_items+0xb0>
    }
    while (start < right && !(table[start] & PTE_P)) {
        start ++;
c0103d61:	ff 45 10             	incl   0x10(%ebp)
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
    if (start >= right) {
        return 0;
    }
    while (start < right && !(table[start] & PTE_P)) {
c0103d64:	8b 45 10             	mov    0x10(%ebp),%eax
c0103d67:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103d6a:	73 18                	jae    c0103d84 <get_pgtable_items+0x3b>
c0103d6c:	8b 45 10             	mov    0x10(%ebp),%eax
c0103d6f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103d76:	8b 45 14             	mov    0x14(%ebp),%eax
c0103d79:	01 d0                	add    %edx,%eax
c0103d7b:	8b 00                	mov    (%eax),%eax
c0103d7d:	83 e0 01             	and    $0x1,%eax
c0103d80:	85 c0                	test   %eax,%eax
c0103d82:	74 dd                	je     c0103d61 <get_pgtable_items+0x18>
        start ++;
    }
    if (start < right) {
c0103d84:	8b 45 10             	mov    0x10(%ebp),%eax
c0103d87:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103d8a:	73 68                	jae    c0103df4 <get_pgtable_items+0xab>
        if (left_store != NULL) {
c0103d8c:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
c0103d90:	74 08                	je     c0103d9a <get_pgtable_items+0x51>
            *left_store = start;
c0103d92:	8b 45 18             	mov    0x18(%ebp),%eax
c0103d95:	8b 55 10             	mov    0x10(%ebp),%edx
c0103d98:	89 10                	mov    %edx,(%eax)
        }
        int perm = (table[start ++] & PTE_USER);
c0103d9a:	8b 45 10             	mov    0x10(%ebp),%eax
c0103d9d:	8d 50 01             	lea    0x1(%eax),%edx
c0103da0:	89 55 10             	mov    %edx,0x10(%ebp)
c0103da3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103daa:	8b 45 14             	mov    0x14(%ebp),%eax
c0103dad:	01 d0                	add    %edx,%eax
c0103daf:	8b 00                	mov    (%eax),%eax
c0103db1:	83 e0 07             	and    $0x7,%eax
c0103db4:	89 45 fc             	mov    %eax,-0x4(%ebp)
        while (start < right && (table[start] & PTE_USER) == perm) {
c0103db7:	eb 03                	jmp    c0103dbc <get_pgtable_items+0x73>
            start ++;
c0103db9:	ff 45 10             	incl   0x10(%ebp)
    if (start < right) {
        if (left_store != NULL) {
            *left_store = start;
        }
        int perm = (table[start ++] & PTE_USER);
        while (start < right && (table[start] & PTE_USER) == perm) {
c0103dbc:	8b 45 10             	mov    0x10(%ebp),%eax
c0103dbf:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103dc2:	73 1d                	jae    c0103de1 <get_pgtable_items+0x98>
c0103dc4:	8b 45 10             	mov    0x10(%ebp),%eax
c0103dc7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103dce:	8b 45 14             	mov    0x14(%ebp),%eax
c0103dd1:	01 d0                	add    %edx,%eax
c0103dd3:	8b 00                	mov    (%eax),%eax
c0103dd5:	83 e0 07             	and    $0x7,%eax
c0103dd8:	89 c2                	mov    %eax,%edx
c0103dda:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103ddd:	39 c2                	cmp    %eax,%edx
c0103ddf:	74 d8                	je     c0103db9 <get_pgtable_items+0x70>
            start ++;
        }
        if (right_store != NULL) {
c0103de1:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
c0103de5:	74 08                	je     c0103def <get_pgtable_items+0xa6>
            *right_store = start;
c0103de7:	8b 45 1c             	mov    0x1c(%ebp),%eax
c0103dea:	8b 55 10             	mov    0x10(%ebp),%edx
c0103ded:	89 10                	mov    %edx,(%eax)
        }
        return perm;
c0103def:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103df2:	eb 05                	jmp    c0103df9 <get_pgtable_items+0xb0>
    }
    return 0;
c0103df4:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0103df9:	c9                   	leave  
c0103dfa:	c3                   	ret    

c0103dfb <print_pgdir>:

//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
c0103dfb:	55                   	push   %ebp
c0103dfc:	89 e5                	mov    %esp,%ebp
c0103dfe:	57                   	push   %edi
c0103dff:	56                   	push   %esi
c0103e00:	53                   	push   %ebx
c0103e01:	83 ec 4c             	sub    $0x4c,%esp
    cprintf("-------------------- BEGIN --------------------\n");
c0103e04:	c7 04 24 50 69 10 c0 	movl   $0xc0106950,(%esp)
c0103e0b:	e8 82 c4 ff ff       	call   c0100292 <cprintf>
    size_t left, right = 0, perm;
c0103e10:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
c0103e17:	e9 fa 00 00 00       	jmp    c0103f16 <print_pgdir+0x11b>
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
c0103e1c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103e1f:	89 04 24             	mov    %eax,(%esp)
c0103e22:	e8 e0 fe ff ff       	call   c0103d07 <perm2str>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
c0103e27:	8b 4d dc             	mov    -0x24(%ebp),%ecx
c0103e2a:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0103e2d:	29 d1                	sub    %edx,%ecx
c0103e2f:	89 ca                	mov    %ecx,%edx
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
c0103e31:	89 d6                	mov    %edx,%esi
c0103e33:	c1 e6 16             	shl    $0x16,%esi
c0103e36:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0103e39:	89 d3                	mov    %edx,%ebx
c0103e3b:	c1 e3 16             	shl    $0x16,%ebx
c0103e3e:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0103e41:	89 d1                	mov    %edx,%ecx
c0103e43:	c1 e1 16             	shl    $0x16,%ecx
c0103e46:	8b 7d dc             	mov    -0x24(%ebp),%edi
c0103e49:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0103e4c:	29 d7                	sub    %edx,%edi
c0103e4e:	89 fa                	mov    %edi,%edx
c0103e50:	89 44 24 14          	mov    %eax,0x14(%esp)
c0103e54:	89 74 24 10          	mov    %esi,0x10(%esp)
c0103e58:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
c0103e5c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c0103e60:	89 54 24 04          	mov    %edx,0x4(%esp)
c0103e64:	c7 04 24 81 69 10 c0 	movl   $0xc0106981,(%esp)
c0103e6b:	e8 22 c4 ff ff       	call   c0100292 <cprintf>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
c0103e70:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103e73:	c1 e0 0a             	shl    $0xa,%eax
c0103e76:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
c0103e79:	eb 54                	jmp    c0103ecf <print_pgdir+0xd4>
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
c0103e7b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103e7e:	89 04 24             	mov    %eax,(%esp)
c0103e81:	e8 81 fe ff ff       	call   c0103d07 <perm2str>
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
c0103e86:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
c0103e89:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0103e8c:	29 d1                	sub    %edx,%ecx
c0103e8e:	89 ca                	mov    %ecx,%edx
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
c0103e90:	89 d6                	mov    %edx,%esi
c0103e92:	c1 e6 0c             	shl    $0xc,%esi
c0103e95:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0103e98:	89 d3                	mov    %edx,%ebx
c0103e9a:	c1 e3 0c             	shl    $0xc,%ebx
c0103e9d:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0103ea0:	89 d1                	mov    %edx,%ecx
c0103ea2:	c1 e1 0c             	shl    $0xc,%ecx
c0103ea5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
c0103ea8:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0103eab:	29 d7                	sub    %edx,%edi
c0103ead:	89 fa                	mov    %edi,%edx
c0103eaf:	89 44 24 14          	mov    %eax,0x14(%esp)
c0103eb3:	89 74 24 10          	mov    %esi,0x10(%esp)
c0103eb7:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
c0103ebb:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c0103ebf:	89 54 24 04          	mov    %edx,0x4(%esp)
c0103ec3:	c7 04 24 a0 69 10 c0 	movl   $0xc01069a0,(%esp)
c0103eca:	e8 c3 c3 ff ff       	call   c0100292 <cprintf>
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
c0103ecf:	be 00 00 c0 fa       	mov    $0xfac00000,%esi
c0103ed4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0103ed7:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0103eda:	89 d3                	mov    %edx,%ebx
c0103edc:	c1 e3 0a             	shl    $0xa,%ebx
c0103edf:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0103ee2:	89 d1                	mov    %edx,%ecx
c0103ee4:	c1 e1 0a             	shl    $0xa,%ecx
c0103ee7:	8d 55 d4             	lea    -0x2c(%ebp),%edx
c0103eea:	89 54 24 14          	mov    %edx,0x14(%esp)
c0103eee:	8d 55 d8             	lea    -0x28(%ebp),%edx
c0103ef1:	89 54 24 10          	mov    %edx,0x10(%esp)
c0103ef5:	89 74 24 0c          	mov    %esi,0xc(%esp)
c0103ef9:	89 44 24 08          	mov    %eax,0x8(%esp)
c0103efd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
c0103f01:	89 0c 24             	mov    %ecx,(%esp)
c0103f04:	e8 40 fe ff ff       	call   c0103d49 <get_pgtable_items>
c0103f09:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103f0c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0103f10:	0f 85 65 ff ff ff    	jne    c0103e7b <print_pgdir+0x80>
//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
c0103f16:	b9 00 b0 fe fa       	mov    $0xfafeb000,%ecx
c0103f1b:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0103f1e:	8d 55 dc             	lea    -0x24(%ebp),%edx
c0103f21:	89 54 24 14          	mov    %edx,0x14(%esp)
c0103f25:	8d 55 e0             	lea    -0x20(%ebp),%edx
c0103f28:	89 54 24 10          	mov    %edx,0x10(%esp)
c0103f2c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
c0103f30:	89 44 24 08          	mov    %eax,0x8(%esp)
c0103f34:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
c0103f3b:	00 
c0103f3c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c0103f43:	e8 01 fe ff ff       	call   c0103d49 <get_pgtable_items>
c0103f48:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103f4b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0103f4f:	0f 85 c7 fe ff ff    	jne    c0103e1c <print_pgdir+0x21>
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
        }
    }
    cprintf("--------------------- END ---------------------\n");
c0103f55:	c7 04 24 c4 69 10 c0 	movl   $0xc01069c4,(%esp)
c0103f5c:	e8 31 c3 ff ff       	call   c0100292 <cprintf>
}
c0103f61:	90                   	nop
c0103f62:	83 c4 4c             	add    $0x4c,%esp
c0103f65:	5b                   	pop    %ebx
c0103f66:	5e                   	pop    %esi
c0103f67:	5f                   	pop    %edi
c0103f68:	5d                   	pop    %ebp
c0103f69:	c3                   	ret    

c0103f6a <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
c0103f6a:	55                   	push   %ebp
c0103f6b:	89 e5                	mov    %esp,%ebp
    return page - pages;
c0103f6d:	8b 45 08             	mov    0x8(%ebp),%eax
c0103f70:	8b 15 18 af 11 c0    	mov    0xc011af18,%edx
c0103f76:	29 d0                	sub    %edx,%eax
c0103f78:	c1 f8 02             	sar    $0x2,%eax
c0103f7b:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
c0103f81:	5d                   	pop    %ebp
c0103f82:	c3                   	ret    

c0103f83 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
c0103f83:	55                   	push   %ebp
c0103f84:	89 e5                	mov    %esp,%ebp
c0103f86:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
c0103f89:	8b 45 08             	mov    0x8(%ebp),%eax
c0103f8c:	89 04 24             	mov    %eax,(%esp)
c0103f8f:	e8 d6 ff ff ff       	call   c0103f6a <page2ppn>
c0103f94:	c1 e0 0c             	shl    $0xc,%eax
}
c0103f97:	c9                   	leave  
c0103f98:	c3                   	ret    

c0103f99 <page_ref>:
pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
}

static inline int
page_ref(struct Page *page) {
c0103f99:	55                   	push   %ebp
c0103f9a:	89 e5                	mov    %esp,%ebp
    return page->ref;
c0103f9c:	8b 45 08             	mov    0x8(%ebp),%eax
c0103f9f:	8b 00                	mov    (%eax),%eax
}
c0103fa1:	5d                   	pop    %ebp
c0103fa2:	c3                   	ret    

c0103fa3 <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
c0103fa3:	55                   	push   %ebp
c0103fa4:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c0103fa6:	8b 45 08             	mov    0x8(%ebp),%eax
c0103fa9:	8b 55 0c             	mov    0xc(%ebp),%edx
c0103fac:	89 10                	mov    %edx,(%eax)
}
c0103fae:	90                   	nop
c0103faf:	5d                   	pop    %ebp
c0103fb0:	c3                   	ret    

c0103fb1 <default_init>:

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
c0103fb1:	55                   	push   %ebp
c0103fb2:	89 e5                	mov    %esp,%ebp
c0103fb4:	83 ec 10             	sub    $0x10,%esp
c0103fb7:	c7 45 fc 1c af 11 c0 	movl   $0xc011af1c,-0x4(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c0103fbe:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103fc1:	8b 55 fc             	mov    -0x4(%ebp),%edx
c0103fc4:	89 50 04             	mov    %edx,0x4(%eax)
c0103fc7:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103fca:	8b 50 04             	mov    0x4(%eax),%edx
c0103fcd:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103fd0:	89 10                	mov    %edx,(%eax)
     * Because at first there is no free block to add, so we just let the prev and next pointers to point to itself.
     * This is done through:
     *      free_list->next = free_list->prev = free_list;
     */
    list_init(&free_list);
    nr_free = 0;
c0103fd2:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c0103fd9:	00 00 00 
}
c0103fdc:	90                   	nop
c0103fdd:	c9                   	leave  
c0103fde:	c3                   	ret    

c0103fdf <default_init_memmap>:
 * Page has been referenced, etc.
 * 
 * This function is used to initilize each page within a free memory block and then link it to the free list.
 */
static void
default_init_memmap(struct Page *base, size_t n) {
c0103fdf:	55                   	push   %ebp
c0103fe0:	89 e5                	mov    %esp,%ebp
c0103fe2:	83 ec 48             	sub    $0x48,%esp
    // For Paging mechanism.
    assert(n > 0);
c0103fe5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0103fe9:	75 24                	jne    c010400f <default_init_memmap+0x30>
c0103feb:	c7 44 24 0c f8 69 10 	movl   $0xc01069f8,0xc(%esp)
c0103ff2:	c0 
c0103ff3:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0103ffa:	c0 
c0103ffb:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
c0104002:	00 
c0104003:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c010400a:	e8 da c3 ff ff       	call   c01003e9 <__panic>
    struct Page *p = base;
c010400f:	8b 45 08             	mov    0x8(%ebp),%eax
c0104012:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
c0104015:	eb 7d                	jmp    c0104094 <default_init_memmap+0xb5>
        // Initialize the page within the block.
        assert(PageReserved(p));
c0104017:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010401a:	83 c0 04             	add    $0x4,%eax
c010401d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
c0104024:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104027:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010402a:	8b 55 e8             	mov    -0x18(%ebp),%edx
c010402d:	0f a3 10             	bt     %edx,(%eax)
c0104030:	19 c0                	sbb    %eax,%eax
c0104032:	89 45 e0             	mov    %eax,-0x20(%ebp)
    return oldbit != 0;
c0104035:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c0104039:	0f 95 c0             	setne  %al
c010403c:	0f b6 c0             	movzbl %al,%eax
c010403f:	85 c0                	test   %eax,%eax
c0104041:	75 24                	jne    c0104067 <default_init_memmap+0x88>
c0104043:	c7 44 24 0c 29 6a 10 	movl   $0xc0106a29,0xc(%esp)
c010404a:	c0 
c010404b:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104052:	c0 
c0104053:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
c010405a:	00 
c010405b:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104062:	e8 82 c3 ff ff       	call   c01003e9 <__panic>
        p->flags = p->property = 0;
c0104067:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010406a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
c0104071:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104074:	8b 50 08             	mov    0x8(%eax),%edx
c0104077:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010407a:	89 50 04             	mov    %edx,0x4(%eax)
        set_page_ref(p, 0);
c010407d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0104084:	00 
c0104085:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104088:	89 04 24             	mov    %eax,(%esp)
c010408b:	e8 13 ff ff ff       	call   c0103fa3 <set_page_ref>
static void
default_init_memmap(struct Page *base, size_t n) {
    // For Paging mechanism.
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
c0104090:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
c0104094:	8b 55 0c             	mov    0xc(%ebp),%edx
c0104097:	89 d0                	mov    %edx,%eax
c0104099:	c1 e0 02             	shl    $0x2,%eax
c010409c:	01 d0                	add    %edx,%eax
c010409e:	c1 e0 02             	shl    $0x2,%eax
c01040a1:	89 c2                	mov    %eax,%edx
c01040a3:	8b 45 08             	mov    0x8(%ebp),%eax
c01040a6:	01 d0                	add    %edx,%eax
c01040a8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01040ab:	0f 85 66 ff ff ff    	jne    c0104017 <default_init_memmap+0x38>
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    // If the page is free and is the first page of the block, the property should be the size of the (required) block.
    base->property = n;
c01040b1:	8b 45 08             	mov    0x8(%ebp),%eax
c01040b4:	8b 55 0c             	mov    0xc(%ebp),%edx
c01040b7:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
c01040ba:	8b 45 08             	mov    0x8(%ebp),%eax
c01040bd:	83 c0 04             	add    $0x4,%eax
c01040c0:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
c01040c7:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c01040ca:	8b 45 cc             	mov    -0x34(%ebp),%eax
c01040cd:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01040d0:	0f ab 10             	bts    %edx,(%eax)
    nr_free += n;
c01040d3:	8b 15 24 af 11 c0    	mov    0xc011af24,%edx
c01040d9:	8b 45 0c             	mov    0xc(%ebp),%eax
c01040dc:	01 d0                	add    %edx,%eax
c01040de:	a3 24 af 11 c0       	mov    %eax,0xc011af24
    // Order by address.
    list_add_before(&free_list, &(base->page_link));
c01040e3:	8b 45 08             	mov    0x8(%ebp),%eax
c01040e6:	83 c0 0c             	add    $0xc,%eax
c01040e9:	c7 45 f0 1c af 11 c0 	movl   $0xc011af1c,-0x10(%ebp)
c01040f0:	89 45 dc             	mov    %eax,-0x24(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
c01040f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01040f6:	8b 00                	mov    (%eax),%eax
c01040f8:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01040fb:	89 55 d8             	mov    %edx,-0x28(%ebp)
c01040fe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
c0104101:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104104:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c0104107:	8b 45 d0             	mov    -0x30(%ebp),%eax
c010410a:	8b 55 d8             	mov    -0x28(%ebp),%edx
c010410d:	89 10                	mov    %edx,(%eax)
c010410f:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104112:	8b 10                	mov    (%eax),%edx
c0104114:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0104117:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c010411a:	8b 45 d8             	mov    -0x28(%ebp),%eax
c010411d:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0104120:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0104123:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104126:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104129:	89 10                	mov    %edx,(%eax)
}
c010412b:	90                   	nop
c010412c:	c9                   	leave  
c010412d:	c3                   	ret    

c010412e <default_alloc_pages>:

static struct Page *
default_alloc_pages(size_t n) {
c010412e:	55                   	push   %ebp
c010412f:	89 e5                	mov    %esp,%ebp
c0104131:	83 ec 68             	sub    $0x68,%esp
    assert(n > 0);
c0104134:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0104138:	75 24                	jne    c010415e <default_alloc_pages+0x30>
c010413a:	c7 44 24 0c f8 69 10 	movl   $0xc01069f8,0xc(%esp)
c0104141:	c0 
c0104142:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104149:	c0 
c010414a:	c7 44 24 04 b0 00 00 	movl   $0xb0,0x4(%esp)
c0104151:	00 
c0104152:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104159:	e8 8b c2 ff ff       	call   c01003e9 <__panic>
    /*
     * The required size n cannot be allocated, because there is no more free memory block.
     */
    if (n > nr_free) {
c010415e:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104163:	3b 45 08             	cmp    0x8(%ebp),%eax
c0104166:	73 0a                	jae    c0104172 <default_alloc_pages+0x44>
        return NULL;
c0104168:	b8 00 00 00 00       	mov    $0x0,%eax
c010416d:	e9 3d 01 00 00       	jmp    c01042af <default_alloc_pages+0x181>
    }
    struct Page *page = NULL; // <- This is the base page of the block, i.e., the identifier of the block.
c0104172:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    list_entry_t *le = &free_list;
c0104179:	c7 45 f0 1c af 11 c0 	movl   $0xc011af1c,-0x10(%ebp)
    /* 
     * Haobin Chen.
     * Traverse the free list.
     * If the next memory block to find is the head of the free list, then it means we cannot find any available block.
     */
    while ((le = list_next(le)) != &free_list) {
c0104180:	eb 1c                	jmp    c010419e <default_alloc_pages+0x70>
        struct Page *p = le2page(le, page_link);
c0104182:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104185:	83 e8 0c             	sub    $0xc,%eax
c0104188:	89 45 e8             	mov    %eax,-0x18(%ebp)
        if (p->property >= n) {
c010418b:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010418e:	8b 40 08             	mov    0x8(%eax),%eax
c0104191:	3b 45 08             	cmp    0x8(%ebp),%eax
c0104194:	72 08                	jb     c010419e <default_alloc_pages+0x70>
            page = p;
c0104196:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0104199:	89 45 f4             	mov    %eax,-0xc(%ebp)
            break;
c010419c:	eb 18                	jmp    c01041b6 <default_alloc_pages+0x88>
c010419e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01041a1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c01041a4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01041a7:	8b 40 04             	mov    0x4(%eax),%eax
    /* 
     * Haobin Chen.
     * Traverse the free list.
     * If the next memory block to find is the head of the free list, then it means we cannot find any available block.
     */
    while ((le = list_next(le)) != &free_list) {
c01041aa:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01041ad:	81 7d f0 1c af 11 c0 	cmpl   $0xc011af1c,-0x10(%ebp)
c01041b4:	75 cc                	jne    c0104182 <default_alloc_pages+0x54>
            page = p;
            break;
        }
    }

    if (page != NULL) {
c01041b6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01041ba:	0f 84 ec 00 00 00    	je     c01042ac <default_alloc_pages+0x17e>
        // Adjust the allocation step by split block into two.
        // list_del(&(page->page_link));
        if (page->property > n) {
c01041c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01041c3:	8b 40 08             	mov    0x8(%eax),%eax
c01041c6:	3b 45 08             	cmp    0x8(%ebp),%eax
c01041c9:	0f 86 8c 00 00 00    	jbe    c010425b <default_alloc_pages+0x12d>
            struct Page *p = page + n;
c01041cf:	8b 55 08             	mov    0x8(%ebp),%edx
c01041d2:	89 d0                	mov    %edx,%eax
c01041d4:	c1 e0 02             	shl    $0x2,%eax
c01041d7:	01 d0                	add    %edx,%eax
c01041d9:	c1 e0 02             	shl    $0x2,%eax
c01041dc:	89 c2                	mov    %eax,%edx
c01041de:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01041e1:	01 d0                	add    %edx,%eax
c01041e3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            p->property = page->property - n;
c01041e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01041e9:	8b 40 08             	mov    0x8(%eax),%eax
c01041ec:	2b 45 08             	sub    0x8(%ebp),%eax
c01041ef:	89 c2                	mov    %eax,%edx
c01041f1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01041f4:	89 50 08             	mov    %edx,0x8(%eax)
            // Apply the property.
            SetPageProperty(p);
c01041f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01041fa:	83 c0 04             	add    $0x4,%eax
c01041fd:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
c0104204:	89 45 c0             	mov    %eax,-0x40(%ebp)
c0104207:	8b 45 c0             	mov    -0x40(%ebp),%eax
c010420a:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010420d:	0f ab 10             	bts    %edx,(%eax)
            // Split the memory block and append the remainder right behind the current block.
            list_add_after(&(page->page_link), &(p->page_link));
c0104210:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104213:	83 c0 0c             	add    $0xc,%eax
c0104216:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0104219:	83 c2 0c             	add    $0xc,%edx
c010421c:	89 55 ec             	mov    %edx,-0x14(%ebp)
c010421f:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
c0104222:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104225:	8b 40 04             	mov    0x4(%eax),%eax
c0104228:	8b 55 d0             	mov    -0x30(%ebp),%edx
c010422b:	89 55 cc             	mov    %edx,-0x34(%ebp)
c010422e:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0104231:	89 55 c8             	mov    %edx,-0x38(%ebp)
c0104234:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c0104237:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c010423a:	8b 55 cc             	mov    -0x34(%ebp),%edx
c010423d:	89 10                	mov    %edx,(%eax)
c010423f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104242:	8b 10                	mov    (%eax),%edx
c0104244:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0104247:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c010424a:	8b 45 cc             	mov    -0x34(%ebp),%eax
c010424d:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c0104250:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0104253:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0104256:	8b 55 c8             	mov    -0x38(%ebp),%edx
c0104259:	89 10                	mov    %edx,(%eax)
        }

        list_del(&(page->page_link));
c010425b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010425e:	83 c0 0c             	add    $0xc,%eax
c0104261:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c0104264:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104267:	8b 40 04             	mov    0x4(%eax),%eax
c010426a:	8b 55 d8             	mov    -0x28(%ebp),%edx
c010426d:	8b 12                	mov    (%edx),%edx
c010426f:	89 55 b8             	mov    %edx,-0x48(%ebp)
c0104272:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c0104275:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0104278:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c010427b:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c010427e:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c0104281:	8b 55 b8             	mov    -0x48(%ebp),%edx
c0104284:	89 10                	mov    %edx,(%eax)
        nr_free -= n;
c0104286:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c010428b:	2b 45 08             	sub    0x8(%ebp),%eax
c010428e:	a3 24 af 11 c0       	mov    %eax,0xc011af24
        ClearPageProperty(page);
c0104293:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104296:	83 c0 04             	add    $0x4,%eax
c0104299:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
c01042a0:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c01042a3:	8b 45 bc             	mov    -0x44(%ebp),%eax
c01042a6:	8b 55 e0             	mov    -0x20(%ebp),%edx
c01042a9:	0f b3 10             	btr    %edx,(%eax)
    }
    return page;
c01042ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01042af:	c9                   	leave  
c01042b0:	c3                   	ret    

c01042b1 <default_free_pages>:

static void
default_free_pages(struct Page *base, size_t n) {
c01042b1:	55                   	push   %ebp
c01042b2:	89 e5                	mov    %esp,%ebp
c01042b4:	81 ec 98 00 00 00    	sub    $0x98,%esp
    assert(n > 0);
c01042ba:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c01042be:	75 24                	jne    c01042e4 <default_free_pages+0x33>
c01042c0:	c7 44 24 0c f8 69 10 	movl   $0xc01069f8,0xc(%esp)
c01042c7:	c0 
c01042c8:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c01042cf:	c0 
c01042d0:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
c01042d7:	00 
c01042d8:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c01042df:	e8 05 c1 ff ff       	call   c01003e9 <__panic>
    struct Page *p = base;
c01042e4:	8b 45 08             	mov    0x8(%ebp),%eax
c01042e7:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
c01042ea:	e9 9d 00 00 00       	jmp    c010438c <default_free_pages+0xdb>
        // Reset the pages within the block.
        assert(!PageReserved(p) && !PageProperty(p));
c01042ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01042f2:	83 c0 04             	add    $0x4,%eax
c01042f5:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
c01042fc:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c01042ff:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c0104302:	8b 55 b8             	mov    -0x48(%ebp),%edx
c0104305:	0f a3 10             	bt     %edx,(%eax)
c0104308:	19 c0                	sbb    %eax,%eax
c010430a:	89 45 b0             	mov    %eax,-0x50(%ebp)
    return oldbit != 0;
c010430d:	83 7d b0 00          	cmpl   $0x0,-0x50(%ebp)
c0104311:	0f 95 c0             	setne  %al
c0104314:	0f b6 c0             	movzbl %al,%eax
c0104317:	85 c0                	test   %eax,%eax
c0104319:	75 2c                	jne    c0104347 <default_free_pages+0x96>
c010431b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010431e:	83 c0 04             	add    $0x4,%eax
c0104321:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
c0104328:	89 45 ac             	mov    %eax,-0x54(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c010432b:	8b 45 ac             	mov    -0x54(%ebp),%eax
c010432e:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0104331:	0f a3 10             	bt     %edx,(%eax)
c0104334:	19 c0                	sbb    %eax,%eax
c0104336:	89 45 a8             	mov    %eax,-0x58(%ebp)
    return oldbit != 0;
c0104339:	83 7d a8 00          	cmpl   $0x0,-0x58(%ebp)
c010433d:	0f 95 c0             	setne  %al
c0104340:	0f b6 c0             	movzbl %al,%eax
c0104343:	85 c0                	test   %eax,%eax
c0104345:	74 24                	je     c010436b <default_free_pages+0xba>
c0104347:	c7 44 24 0c 3c 6a 10 	movl   $0xc0106a3c,0xc(%esp)
c010434e:	c0 
c010434f:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104356:	c0 
c0104357:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
c010435e:	00 
c010435f:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104366:	e8 7e c0 ff ff       	call   c01003e9 <__panic>
        p->flags = 0;
c010436b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010436e:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
        set_page_ref(p, 0);
c0104375:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c010437c:	00 
c010437d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104380:	89 04 24             	mov    %eax,(%esp)
c0104383:	e8 1b fc ff ff       	call   c0103fa3 <set_page_ref>

static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
c0104388:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
c010438c:	8b 55 0c             	mov    0xc(%ebp),%edx
c010438f:	89 d0                	mov    %edx,%eax
c0104391:	c1 e0 02             	shl    $0x2,%eax
c0104394:	01 d0                	add    %edx,%eax
c0104396:	c1 e0 02             	shl    $0x2,%eax
c0104399:	89 c2                	mov    %eax,%edx
c010439b:	8b 45 08             	mov    0x8(%ebp),%eax
c010439e:	01 d0                	add    %edx,%eax
c01043a0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01043a3:	0f 85 46 ff ff ff    	jne    c01042ef <default_free_pages+0x3e>
        // Reset the pages within the block.
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
c01043a9:	8b 45 08             	mov    0x8(%ebp),%eax
c01043ac:	8b 55 0c             	mov    0xc(%ebp),%edx
c01043af:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
c01043b2:	8b 45 08             	mov    0x8(%ebp),%eax
c01043b5:	83 c0 04             	add    $0x4,%eax
c01043b8:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
c01043bf:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c01043c2:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c01043c5:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01043c8:	0f ab 10             	bts    %edx,(%eax)
c01043cb:	c7 45 e4 1c af 11 c0 	movl   $0xc011af1c,-0x1c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c01043d2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01043d5:	8b 40 04             	mov    0x4(%eax),%eax

    list_entry_t *le = list_next(&free_list);
c01043d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
c01043db:	e9 08 01 00 00       	jmp    c01044e8 <default_free_pages+0x237>
        // Get the next block and fetch its property by tranforming it to a page pointer.
        p = le2page(le, page_link);
c01043e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01043e3:	83 e8 0c             	sub    $0xc,%eax
c01043e6:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01043e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01043ec:	89 45 e0             	mov    %eax,-0x20(%ebp)
c01043ef:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01043f2:	8b 40 04             	mov    0x4(%eax),%eax
        le = list_next(le);
c01043f5:	89 45 f0             	mov    %eax,-0x10(%ebp)

        // Do merge.
        if (base + base->property == p) {
c01043f8:	8b 45 08             	mov    0x8(%ebp),%eax
c01043fb:	8b 50 08             	mov    0x8(%eax),%edx
c01043fe:	89 d0                	mov    %edx,%eax
c0104400:	c1 e0 02             	shl    $0x2,%eax
c0104403:	01 d0                	add    %edx,%eax
c0104405:	c1 e0 02             	shl    $0x2,%eax
c0104408:	89 c2                	mov    %eax,%edx
c010440a:	8b 45 08             	mov    0x8(%ebp),%eax
c010440d:	01 d0                	add    %edx,%eax
c010440f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104412:	75 5a                	jne    c010446e <default_free_pages+0x1bd>
            // Merge with the next block.
            base->property += p->property;
c0104414:	8b 45 08             	mov    0x8(%ebp),%eax
c0104417:	8b 50 08             	mov    0x8(%eax),%edx
c010441a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010441d:	8b 40 08             	mov    0x8(%eax),%eax
c0104420:	01 c2                	add    %eax,%edx
c0104422:	8b 45 08             	mov    0x8(%ebp),%eax
c0104425:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(p);
c0104428:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010442b:	83 c0 04             	add    $0x4,%eax
c010442e:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
c0104435:	89 45 98             	mov    %eax,-0x68(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0104438:	8b 45 98             	mov    -0x68(%ebp),%eax
c010443b:	8b 55 d0             	mov    -0x30(%ebp),%edx
c010443e:	0f b3 10             	btr    %edx,(%eax)
            list_del(&(p->page_link));
c0104441:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104444:	83 c0 0c             	add    $0xc,%eax
c0104447:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c010444a:	8b 45 d8             	mov    -0x28(%ebp),%eax
c010444d:	8b 40 04             	mov    0x4(%eax),%eax
c0104450:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0104453:	8b 12                	mov    (%edx),%edx
c0104455:	89 55 a0             	mov    %edx,-0x60(%ebp)
c0104458:	89 45 9c             	mov    %eax,-0x64(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c010445b:	8b 45 a0             	mov    -0x60(%ebp),%eax
c010445e:	8b 55 9c             	mov    -0x64(%ebp),%edx
c0104461:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c0104464:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0104467:	8b 55 a0             	mov    -0x60(%ebp),%edx
c010446a:	89 10                	mov    %edx,(%eax)
c010446c:	eb 7a                	jmp    c01044e8 <default_free_pages+0x237>
        }
        else if (p + p->property == base) {
c010446e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104471:	8b 50 08             	mov    0x8(%eax),%edx
c0104474:	89 d0                	mov    %edx,%eax
c0104476:	c1 e0 02             	shl    $0x2,%eax
c0104479:	01 d0                	add    %edx,%eax
c010447b:	c1 e0 02             	shl    $0x2,%eax
c010447e:	89 c2                	mov    %eax,%edx
c0104480:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104483:	01 d0                	add    %edx,%eax
c0104485:	3b 45 08             	cmp    0x8(%ebp),%eax
c0104488:	75 5e                	jne    c01044e8 <default_free_pages+0x237>
            // Merge with the previous block.
            p->property += base->property;
c010448a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010448d:	8b 50 08             	mov    0x8(%eax),%edx
c0104490:	8b 45 08             	mov    0x8(%ebp),%eax
c0104493:	8b 40 08             	mov    0x8(%eax),%eax
c0104496:	01 c2                	add    %eax,%edx
c0104498:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010449b:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(base);
c010449e:	8b 45 08             	mov    0x8(%ebp),%eax
c01044a1:	83 c0 04             	add    $0x4,%eax
c01044a4:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
c01044ab:	89 45 8c             	mov    %eax,-0x74(%ebp)
c01044ae:	8b 45 8c             	mov    -0x74(%ebp),%eax
c01044b1:	8b 55 c8             	mov    -0x38(%ebp),%edx
c01044b4:	0f b3 10             	btr    %edx,(%eax)
            base = p;
c01044b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01044ba:	89 45 08             	mov    %eax,0x8(%ebp)
            list_del(&(p->page_link));
c01044bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01044c0:	83 c0 0c             	add    $0xc,%eax
c01044c3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c01044c6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01044c9:	8b 40 04             	mov    0x4(%eax),%eax
c01044cc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01044cf:	8b 12                	mov    (%edx),%edx
c01044d1:	89 55 94             	mov    %edx,-0x6c(%ebp)
c01044d4:	89 45 90             	mov    %eax,-0x70(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c01044d7:	8b 45 94             	mov    -0x6c(%ebp),%eax
c01044da:	8b 55 90             	mov    -0x70(%ebp),%edx
c01044dd:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c01044e0:	8b 45 90             	mov    -0x70(%ebp),%eax
c01044e3:	8b 55 94             	mov    -0x6c(%ebp),%edx
c01044e6:	89 10                	mov    %edx,(%eax)
    }
    base->property = n;
    SetPageProperty(base);

    list_entry_t *le = list_next(&free_list);
    while (le != &free_list) {
c01044e8:	81 7d f0 1c af 11 c0 	cmpl   $0xc011af1c,-0x10(%ebp)
c01044ef:	0f 85 eb fe ff ff    	jne    c01043e0 <default_free_pages+0x12f>
c01044f5:	c7 45 cc 1c af 11 c0 	movl   $0xc011af1c,-0x34(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c01044fc:	8b 45 cc             	mov    -0x34(%ebp),%eax
c01044ff:	8b 40 04             	mov    0x4(%eax),%eax
    /*
     * Haobin Chen.
     * 
     * Find the right place to insert.
     */
    list_entry_t *ptr = list_next(&free_list);
c0104502:	89 45 ec             	mov    %eax,-0x14(%ebp)
    while (ptr != &free_list) {
c0104505:	eb 34                	jmp    c010453b <default_free_pages+0x28a>
         * le2page receives two parameters to convert a struct to another. The second parameter
         * means the member to be the first parameter.
         * 
         * E.g. Current page's page_link member will be the first parameter: ptr (which is the current block to be accessed).
         */
        struct Page *cur = le2page(ptr, page_link);
c0104507:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010450a:	83 e8 0c             	sub    $0xc,%eax
c010450d:	89 45 c0             	mov    %eax,-0x40(%ebp)
        if (base + base->property < cur) {
c0104510:	8b 45 08             	mov    0x8(%ebp),%eax
c0104513:	8b 50 08             	mov    0x8(%eax),%edx
c0104516:	89 d0                	mov    %edx,%eax
c0104518:	c1 e0 02             	shl    $0x2,%eax
c010451b:	01 d0                	add    %edx,%eax
c010451d:	c1 e0 02             	shl    $0x2,%eax
c0104520:	89 c2                	mov    %eax,%edx
c0104522:	8b 45 08             	mov    0x8(%ebp),%eax
c0104525:	01 d0                	add    %edx,%eax
c0104527:	3b 45 c0             	cmp    -0x40(%ebp),%eax
c010452a:	72 1a                	jb     c0104546 <default_free_pages+0x295>
c010452c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010452f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
c0104532:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104535:	8b 40 04             	mov    0x4(%eax),%eax
            break;
        }
        ptr = list_next(ptr);
c0104538:	89 45 ec             	mov    %eax,-0x14(%ebp)
     * Haobin Chen.
     * 
     * Find the right place to insert.
     */
    list_entry_t *ptr = list_next(&free_list);
    while (ptr != &free_list) {
c010453b:	81 7d ec 1c af 11 c0 	cmpl   $0xc011af1c,-0x14(%ebp)
c0104542:	75 c3                	jne    c0104507 <default_free_pages+0x256>
c0104544:	eb 01                	jmp    c0104547 <default_free_pages+0x296>
         * 
         * E.g. Current page's page_link member will be the first parameter: ptr (which is the current block to be accessed).
         */
        struct Page *cur = le2page(ptr, page_link);
        if (base + base->property < cur) {
            break;
c0104546:	90                   	nop
        }
        ptr = list_next(ptr);
    }

    list_add_before(ptr, &(base->page_link));
c0104547:	8b 45 08             	mov    0x8(%ebp),%eax
c010454a:	8d 50 0c             	lea    0xc(%eax),%edx
c010454d:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104550:	89 45 bc             	mov    %eax,-0x44(%ebp)
c0104553:	89 55 88             	mov    %edx,-0x78(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
c0104556:	8b 45 bc             	mov    -0x44(%ebp),%eax
c0104559:	8b 00                	mov    (%eax),%eax
c010455b:	8b 55 88             	mov    -0x78(%ebp),%edx
c010455e:	89 55 84             	mov    %edx,-0x7c(%ebp)
c0104561:	89 45 80             	mov    %eax,-0x80(%ebp)
c0104564:	8b 45 bc             	mov    -0x44(%ebp),%eax
c0104567:	89 85 7c ff ff ff    	mov    %eax,-0x84(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c010456d:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
c0104573:	8b 55 84             	mov    -0x7c(%ebp),%edx
c0104576:	89 10                	mov    %edx,(%eax)
c0104578:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
c010457e:	8b 10                	mov    (%eax),%edx
c0104580:	8b 45 80             	mov    -0x80(%ebp),%eax
c0104583:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c0104586:	8b 45 84             	mov    -0x7c(%ebp),%eax
c0104589:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
c010458f:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0104592:	8b 45 84             	mov    -0x7c(%ebp),%eax
c0104595:	8b 55 80             	mov    -0x80(%ebp),%edx
c0104598:	89 10                	mov    %edx,(%eax)
    nr_free += n;
c010459a:	8b 15 24 af 11 c0    	mov    0xc011af24,%edx
c01045a0:	8b 45 0c             	mov    0xc(%ebp),%eax
c01045a3:	01 d0                	add    %edx,%eax
c01045a5:	a3 24 af 11 c0       	mov    %eax,0xc011af24

    //list_add_before(&free_list, &(base->page_link));
}
c01045aa:	90                   	nop
c01045ab:	c9                   	leave  
c01045ac:	c3                   	ret    

c01045ad <default_nr_free_pages>:

static size_t
default_nr_free_pages(void) {
c01045ad:	55                   	push   %ebp
c01045ae:	89 e5                	mov    %esp,%ebp
    return nr_free;
c01045b0:	a1 24 af 11 c0       	mov    0xc011af24,%eax
}
c01045b5:	5d                   	pop    %ebp
c01045b6:	c3                   	ret    

c01045b7 <basic_check>:

static void
basic_check(void) {
c01045b7:	55                   	push   %ebp
c01045b8:	89 e5                	mov    %esp,%ebp
c01045ba:	83 ec 48             	sub    $0x48,%esp
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
c01045bd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c01045c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01045c7:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01045ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01045cd:	89 45 ec             	mov    %eax,-0x14(%ebp)
    assert((p0 = alloc_page()) != NULL);
c01045d0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01045d7:	e8 76 e3 ff ff       	call   c0102952 <alloc_pages>
c01045dc:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01045df:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c01045e3:	75 24                	jne    c0104609 <basic_check+0x52>
c01045e5:	c7 44 24 0c 61 6a 10 	movl   $0xc0106a61,0xc(%esp)
c01045ec:	c0 
c01045ed:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c01045f4:	c0 
c01045f5:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
c01045fc:	00 
c01045fd:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104604:	e8 e0 bd ff ff       	call   c01003e9 <__panic>
    assert((p1 = alloc_page()) != NULL);
c0104609:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104610:	e8 3d e3 ff ff       	call   c0102952 <alloc_pages>
c0104615:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104618:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010461c:	75 24                	jne    c0104642 <basic_check+0x8b>
c010461e:	c7 44 24 0c 7d 6a 10 	movl   $0xc0106a7d,0xc(%esp)
c0104625:	c0 
c0104626:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c010462d:	c0 
c010462e:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
c0104635:	00 
c0104636:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c010463d:	e8 a7 bd ff ff       	call   c01003e9 <__panic>
    assert((p2 = alloc_page()) != NULL);
c0104642:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104649:	e8 04 e3 ff ff       	call   c0102952 <alloc_pages>
c010464e:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0104651:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0104655:	75 24                	jne    c010467b <basic_check+0xc4>
c0104657:	c7 44 24 0c 99 6a 10 	movl   $0xc0106a99,0xc(%esp)
c010465e:	c0 
c010465f:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104666:	c0 
c0104667:	c7 44 24 04 23 01 00 	movl   $0x123,0x4(%esp)
c010466e:	00 
c010466f:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104676:	e8 6e bd ff ff       	call   c01003e9 <__panic>

    assert(p0 != p1 && p0 != p2 && p1 != p2);
c010467b:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010467e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c0104681:	74 10                	je     c0104693 <basic_check+0xdc>
c0104683:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104686:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104689:	74 08                	je     c0104693 <basic_check+0xdc>
c010468b:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010468e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104691:	75 24                	jne    c01046b7 <basic_check+0x100>
c0104693:	c7 44 24 0c b8 6a 10 	movl   $0xc0106ab8,0xc(%esp)
c010469a:	c0 
c010469b:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c01046a2:	c0 
c01046a3:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
c01046aa:	00 
c01046ab:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c01046b2:	e8 32 bd ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
c01046b7:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01046ba:	89 04 24             	mov    %eax,(%esp)
c01046bd:	e8 d7 f8 ff ff       	call   c0103f99 <page_ref>
c01046c2:	85 c0                	test   %eax,%eax
c01046c4:	75 1e                	jne    c01046e4 <basic_check+0x12d>
c01046c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01046c9:	89 04 24             	mov    %eax,(%esp)
c01046cc:	e8 c8 f8 ff ff       	call   c0103f99 <page_ref>
c01046d1:	85 c0                	test   %eax,%eax
c01046d3:	75 0f                	jne    c01046e4 <basic_check+0x12d>
c01046d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01046d8:	89 04 24             	mov    %eax,(%esp)
c01046db:	e8 b9 f8 ff ff       	call   c0103f99 <page_ref>
c01046e0:	85 c0                	test   %eax,%eax
c01046e2:	74 24                	je     c0104708 <basic_check+0x151>
c01046e4:	c7 44 24 0c dc 6a 10 	movl   $0xc0106adc,0xc(%esp)
c01046eb:	c0 
c01046ec:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c01046f3:	c0 
c01046f4:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
c01046fb:	00 
c01046fc:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104703:	e8 e1 bc ff ff       	call   c01003e9 <__panic>

    assert(page2pa(p0) < npage * PGSIZE);
c0104708:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010470b:	89 04 24             	mov    %eax,(%esp)
c010470e:	e8 70 f8 ff ff       	call   c0103f83 <page2pa>
c0104713:	8b 15 80 ae 11 c0    	mov    0xc011ae80,%edx
c0104719:	c1 e2 0c             	shl    $0xc,%edx
c010471c:	39 d0                	cmp    %edx,%eax
c010471e:	72 24                	jb     c0104744 <basic_check+0x18d>
c0104720:	c7 44 24 0c 18 6b 10 	movl   $0xc0106b18,0xc(%esp)
c0104727:	c0 
c0104728:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c010472f:	c0 
c0104730:	c7 44 24 04 28 01 00 	movl   $0x128,0x4(%esp)
c0104737:	00 
c0104738:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c010473f:	e8 a5 bc ff ff       	call   c01003e9 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
c0104744:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104747:	89 04 24             	mov    %eax,(%esp)
c010474a:	e8 34 f8 ff ff       	call   c0103f83 <page2pa>
c010474f:	8b 15 80 ae 11 c0    	mov    0xc011ae80,%edx
c0104755:	c1 e2 0c             	shl    $0xc,%edx
c0104758:	39 d0                	cmp    %edx,%eax
c010475a:	72 24                	jb     c0104780 <basic_check+0x1c9>
c010475c:	c7 44 24 0c 35 6b 10 	movl   $0xc0106b35,0xc(%esp)
c0104763:	c0 
c0104764:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c010476b:	c0 
c010476c:	c7 44 24 04 29 01 00 	movl   $0x129,0x4(%esp)
c0104773:	00 
c0104774:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c010477b:	e8 69 bc ff ff       	call   c01003e9 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
c0104780:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104783:	89 04 24             	mov    %eax,(%esp)
c0104786:	e8 f8 f7 ff ff       	call   c0103f83 <page2pa>
c010478b:	8b 15 80 ae 11 c0    	mov    0xc011ae80,%edx
c0104791:	c1 e2 0c             	shl    $0xc,%edx
c0104794:	39 d0                	cmp    %edx,%eax
c0104796:	72 24                	jb     c01047bc <basic_check+0x205>
c0104798:	c7 44 24 0c 52 6b 10 	movl   $0xc0106b52,0xc(%esp)
c010479f:	c0 
c01047a0:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c01047a7:	c0 
c01047a8:	c7 44 24 04 2a 01 00 	movl   $0x12a,0x4(%esp)
c01047af:	00 
c01047b0:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c01047b7:	e8 2d bc ff ff       	call   c01003e9 <__panic>

    list_entry_t free_list_store = free_list;
c01047bc:	a1 1c af 11 c0       	mov    0xc011af1c,%eax
c01047c1:	8b 15 20 af 11 c0    	mov    0xc011af20,%edx
c01047c7:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01047ca:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c01047cd:	c7 45 e4 1c af 11 c0 	movl   $0xc011af1c,-0x1c(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c01047d4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01047d7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01047da:	89 50 04             	mov    %edx,0x4(%eax)
c01047dd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01047e0:	8b 50 04             	mov    0x4(%eax),%edx
c01047e3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01047e6:	89 10                	mov    %edx,(%eax)
c01047e8:	c7 45 d8 1c af 11 c0 	movl   $0xc011af1c,-0x28(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
c01047ef:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01047f2:	8b 40 04             	mov    0x4(%eax),%eax
c01047f5:	39 45 d8             	cmp    %eax,-0x28(%ebp)
c01047f8:	0f 94 c0             	sete   %al
c01047fb:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
c01047fe:	85 c0                	test   %eax,%eax
c0104800:	75 24                	jne    c0104826 <basic_check+0x26f>
c0104802:	c7 44 24 0c 6f 6b 10 	movl   $0xc0106b6f,0xc(%esp)
c0104809:	c0 
c010480a:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104811:	c0 
c0104812:	c7 44 24 04 2e 01 00 	movl   $0x12e,0x4(%esp)
c0104819:	00 
c010481a:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104821:	e8 c3 bb ff ff       	call   c01003e9 <__panic>

    unsigned int nr_free_store = nr_free;
c0104826:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c010482b:	89 45 e0             	mov    %eax,-0x20(%ebp)
    nr_free = 0;
c010482e:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c0104835:	00 00 00 

    assert(alloc_page() == NULL);
c0104838:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010483f:	e8 0e e1 ff ff       	call   c0102952 <alloc_pages>
c0104844:	85 c0                	test   %eax,%eax
c0104846:	74 24                	je     c010486c <basic_check+0x2b5>
c0104848:	c7 44 24 0c 86 6b 10 	movl   $0xc0106b86,0xc(%esp)
c010484f:	c0 
c0104850:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104857:	c0 
c0104858:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
c010485f:	00 
c0104860:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104867:	e8 7d bb ff ff       	call   c01003e9 <__panic>

    free_page(p0);
c010486c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104873:	00 
c0104874:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104877:	89 04 24             	mov    %eax,(%esp)
c010487a:	e8 0b e1 ff ff       	call   c010298a <free_pages>
    free_page(p1);
c010487f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104886:	00 
c0104887:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010488a:	89 04 24             	mov    %eax,(%esp)
c010488d:	e8 f8 e0 ff ff       	call   c010298a <free_pages>
    free_page(p2);
c0104892:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104899:	00 
c010489a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010489d:	89 04 24             	mov    %eax,(%esp)
c01048a0:	e8 e5 e0 ff ff       	call   c010298a <free_pages>
    assert(nr_free == 3);
c01048a5:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c01048aa:	83 f8 03             	cmp    $0x3,%eax
c01048ad:	74 24                	je     c01048d3 <basic_check+0x31c>
c01048af:	c7 44 24 0c 9b 6b 10 	movl   $0xc0106b9b,0xc(%esp)
c01048b6:	c0 
c01048b7:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c01048be:	c0 
c01048bf:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
c01048c6:	00 
c01048c7:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c01048ce:	e8 16 bb ff ff       	call   c01003e9 <__panic>

    assert((p0 = alloc_page()) != NULL);
c01048d3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01048da:	e8 73 e0 ff ff       	call   c0102952 <alloc_pages>
c01048df:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01048e2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c01048e6:	75 24                	jne    c010490c <basic_check+0x355>
c01048e8:	c7 44 24 0c 61 6a 10 	movl   $0xc0106a61,0xc(%esp)
c01048ef:	c0 
c01048f0:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c01048f7:	c0 
c01048f8:	c7 44 24 04 3a 01 00 	movl   $0x13a,0x4(%esp)
c01048ff:	00 
c0104900:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104907:	e8 dd ba ff ff       	call   c01003e9 <__panic>
    assert((p1 = alloc_page()) != NULL);
c010490c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104913:	e8 3a e0 ff ff       	call   c0102952 <alloc_pages>
c0104918:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010491b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010491f:	75 24                	jne    c0104945 <basic_check+0x38e>
c0104921:	c7 44 24 0c 7d 6a 10 	movl   $0xc0106a7d,0xc(%esp)
c0104928:	c0 
c0104929:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104930:	c0 
c0104931:	c7 44 24 04 3b 01 00 	movl   $0x13b,0x4(%esp)
c0104938:	00 
c0104939:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104940:	e8 a4 ba ff ff       	call   c01003e9 <__panic>
    assert((p2 = alloc_page()) != NULL);
c0104945:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010494c:	e8 01 e0 ff ff       	call   c0102952 <alloc_pages>
c0104951:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0104954:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0104958:	75 24                	jne    c010497e <basic_check+0x3c7>
c010495a:	c7 44 24 0c 99 6a 10 	movl   $0xc0106a99,0xc(%esp)
c0104961:	c0 
c0104962:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104969:	c0 
c010496a:	c7 44 24 04 3c 01 00 	movl   $0x13c,0x4(%esp)
c0104971:	00 
c0104972:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104979:	e8 6b ba ff ff       	call   c01003e9 <__panic>

    assert(alloc_page() == NULL);
c010497e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104985:	e8 c8 df ff ff       	call   c0102952 <alloc_pages>
c010498a:	85 c0                	test   %eax,%eax
c010498c:	74 24                	je     c01049b2 <basic_check+0x3fb>
c010498e:	c7 44 24 0c 86 6b 10 	movl   $0xc0106b86,0xc(%esp)
c0104995:	c0 
c0104996:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c010499d:	c0 
c010499e:	c7 44 24 04 3e 01 00 	movl   $0x13e,0x4(%esp)
c01049a5:	00 
c01049a6:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c01049ad:	e8 37 ba ff ff       	call   c01003e9 <__panic>

    free_page(p0);
c01049b2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c01049b9:	00 
c01049ba:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01049bd:	89 04 24             	mov    %eax,(%esp)
c01049c0:	e8 c5 df ff ff       	call   c010298a <free_pages>
c01049c5:	c7 45 e8 1c af 11 c0 	movl   $0xc011af1c,-0x18(%ebp)
c01049cc:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01049cf:	8b 40 04             	mov    0x4(%eax),%eax
c01049d2:	39 45 e8             	cmp    %eax,-0x18(%ebp)
c01049d5:	0f 94 c0             	sete   %al
c01049d8:	0f b6 c0             	movzbl %al,%eax
    assert(!list_empty(&free_list));
c01049db:	85 c0                	test   %eax,%eax
c01049dd:	74 24                	je     c0104a03 <basic_check+0x44c>
c01049df:	c7 44 24 0c a8 6b 10 	movl   $0xc0106ba8,0xc(%esp)
c01049e6:	c0 
c01049e7:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c01049ee:	c0 
c01049ef:	c7 44 24 04 41 01 00 	movl   $0x141,0x4(%esp)
c01049f6:	00 
c01049f7:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c01049fe:	e8 e6 b9 ff ff       	call   c01003e9 <__panic>

    struct Page *p;
    assert((p = alloc_page()) == p0);
c0104a03:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104a0a:	e8 43 df ff ff       	call   c0102952 <alloc_pages>
c0104a0f:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104a12:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104a15:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0104a18:	74 24                	je     c0104a3e <basic_check+0x487>
c0104a1a:	c7 44 24 0c c0 6b 10 	movl   $0xc0106bc0,0xc(%esp)
c0104a21:	c0 
c0104a22:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104a29:	c0 
c0104a2a:	c7 44 24 04 44 01 00 	movl   $0x144,0x4(%esp)
c0104a31:	00 
c0104a32:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104a39:	e8 ab b9 ff ff       	call   c01003e9 <__panic>
    assert(alloc_page() == NULL);
c0104a3e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104a45:	e8 08 df ff ff       	call   c0102952 <alloc_pages>
c0104a4a:	85 c0                	test   %eax,%eax
c0104a4c:	74 24                	je     c0104a72 <basic_check+0x4bb>
c0104a4e:	c7 44 24 0c 86 6b 10 	movl   $0xc0106b86,0xc(%esp)
c0104a55:	c0 
c0104a56:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104a5d:	c0 
c0104a5e:	c7 44 24 04 45 01 00 	movl   $0x145,0x4(%esp)
c0104a65:	00 
c0104a66:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104a6d:	e8 77 b9 ff ff       	call   c01003e9 <__panic>

    assert(nr_free == 0);
c0104a72:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104a77:	85 c0                	test   %eax,%eax
c0104a79:	74 24                	je     c0104a9f <basic_check+0x4e8>
c0104a7b:	c7 44 24 0c d9 6b 10 	movl   $0xc0106bd9,0xc(%esp)
c0104a82:	c0 
c0104a83:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104a8a:	c0 
c0104a8b:	c7 44 24 04 47 01 00 	movl   $0x147,0x4(%esp)
c0104a92:	00 
c0104a93:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104a9a:	e8 4a b9 ff ff       	call   c01003e9 <__panic>
    free_list = free_list_store;
c0104a9f:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104aa2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104aa5:	a3 1c af 11 c0       	mov    %eax,0xc011af1c
c0104aaa:	89 15 20 af 11 c0    	mov    %edx,0xc011af20
    nr_free = nr_free_store;
c0104ab0:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0104ab3:	a3 24 af 11 c0       	mov    %eax,0xc011af24

    free_page(p);
c0104ab8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104abf:	00 
c0104ac0:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104ac3:	89 04 24             	mov    %eax,(%esp)
c0104ac6:	e8 bf de ff ff       	call   c010298a <free_pages>
    free_page(p1);
c0104acb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104ad2:	00 
c0104ad3:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104ad6:	89 04 24             	mov    %eax,(%esp)
c0104ad9:	e8 ac de ff ff       	call   c010298a <free_pages>
    free_page(p2);
c0104ade:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104ae5:	00 
c0104ae6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104ae9:	89 04 24             	mov    %eax,(%esp)
c0104aec:	e8 99 de ff ff       	call   c010298a <free_pages>
}
c0104af1:	90                   	nop
c0104af2:	c9                   	leave  
c0104af3:	c3                   	ret    

c0104af4 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
c0104af4:	55                   	push   %ebp
c0104af5:	89 e5                	mov    %esp,%ebp
c0104af7:	81 ec 98 00 00 00    	sub    $0x98,%esp
    int count = 0, total = 0;
c0104afd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0104b04:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    list_entry_t *le = &free_list;
c0104b0b:	c7 45 ec 1c af 11 c0 	movl   $0xc011af1c,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
c0104b12:	eb 6a                	jmp    c0104b7e <default_check+0x8a>
        struct Page *p = le2page(le, page_link);
c0104b14:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104b17:	83 e8 0c             	sub    $0xc,%eax
c0104b1a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        assert(PageProperty(p));
c0104b1d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104b20:	83 c0 04             	add    $0x4,%eax
c0104b23:	c7 45 b0 01 00 00 00 	movl   $0x1,-0x50(%ebp)
c0104b2a:	89 45 ac             	mov    %eax,-0x54(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104b2d:	8b 45 ac             	mov    -0x54(%ebp),%eax
c0104b30:	8b 55 b0             	mov    -0x50(%ebp),%edx
c0104b33:	0f a3 10             	bt     %edx,(%eax)
c0104b36:	19 c0                	sbb    %eax,%eax
c0104b38:	89 45 a8             	mov    %eax,-0x58(%ebp)
    return oldbit != 0;
c0104b3b:	83 7d a8 00          	cmpl   $0x0,-0x58(%ebp)
c0104b3f:	0f 95 c0             	setne  %al
c0104b42:	0f b6 c0             	movzbl %al,%eax
c0104b45:	85 c0                	test   %eax,%eax
c0104b47:	75 24                	jne    c0104b6d <default_check+0x79>
c0104b49:	c7 44 24 0c e6 6b 10 	movl   $0xc0106be6,0xc(%esp)
c0104b50:	c0 
c0104b51:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104b58:	c0 
c0104b59:	c7 44 24 04 58 01 00 	movl   $0x158,0x4(%esp)
c0104b60:	00 
c0104b61:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104b68:	e8 7c b8 ff ff       	call   c01003e9 <__panic>
        count ++, total += p->property;
c0104b6d:	ff 45 f4             	incl   -0xc(%ebp)
c0104b70:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104b73:	8b 50 08             	mov    0x8(%eax),%edx
c0104b76:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104b79:	01 d0                	add    %edx,%eax
c0104b7b:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104b7e:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104b81:	89 45 e0             	mov    %eax,-0x20(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0104b84:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0104b87:	8b 40 04             	mov    0x4(%eax),%eax
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c0104b8a:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0104b8d:	81 7d ec 1c af 11 c0 	cmpl   $0xc011af1c,-0x14(%ebp)
c0104b94:	0f 85 7a ff ff ff    	jne    c0104b14 <default_check+0x20>
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());
c0104b9a:	e8 1e de ff ff       	call   c01029bd <nr_free_pages>
c0104b9f:	89 c2                	mov    %eax,%edx
c0104ba1:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104ba4:	39 c2                	cmp    %eax,%edx
c0104ba6:	74 24                	je     c0104bcc <default_check+0xd8>
c0104ba8:	c7 44 24 0c f6 6b 10 	movl   $0xc0106bf6,0xc(%esp)
c0104baf:	c0 
c0104bb0:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104bb7:	c0 
c0104bb8:	c7 44 24 04 5b 01 00 	movl   $0x15b,0x4(%esp)
c0104bbf:	00 
c0104bc0:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104bc7:	e8 1d b8 ff ff       	call   c01003e9 <__panic>

    basic_check();
c0104bcc:	e8 e6 f9 ff ff       	call   c01045b7 <basic_check>

    struct Page *p0 = alloc_pages(5), *p1, *p2;
c0104bd1:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
c0104bd8:	e8 75 dd ff ff       	call   c0102952 <alloc_pages>
c0104bdd:	89 45 dc             	mov    %eax,-0x24(%ebp)
    assert(p0 != NULL);
c0104be0:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0104be4:	75 24                	jne    c0104c0a <default_check+0x116>
c0104be6:	c7 44 24 0c 0f 6c 10 	movl   $0xc0106c0f,0xc(%esp)
c0104bed:	c0 
c0104bee:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104bf5:	c0 
c0104bf6:	c7 44 24 04 60 01 00 	movl   $0x160,0x4(%esp)
c0104bfd:	00 
c0104bfe:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104c05:	e8 df b7 ff ff       	call   c01003e9 <__panic>
    assert(!PageProperty(p0));
c0104c0a:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104c0d:	83 c0 04             	add    $0x4,%eax
c0104c10:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
c0104c17:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104c1a:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0104c1d:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0104c20:	0f a3 10             	bt     %edx,(%eax)
c0104c23:	19 c0                	sbb    %eax,%eax
c0104c25:	89 45 a0             	mov    %eax,-0x60(%ebp)
    return oldbit != 0;
c0104c28:	83 7d a0 00          	cmpl   $0x0,-0x60(%ebp)
c0104c2c:	0f 95 c0             	setne  %al
c0104c2f:	0f b6 c0             	movzbl %al,%eax
c0104c32:	85 c0                	test   %eax,%eax
c0104c34:	74 24                	je     c0104c5a <default_check+0x166>
c0104c36:	c7 44 24 0c 1a 6c 10 	movl   $0xc0106c1a,0xc(%esp)
c0104c3d:	c0 
c0104c3e:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104c45:	c0 
c0104c46:	c7 44 24 04 61 01 00 	movl   $0x161,0x4(%esp)
c0104c4d:	00 
c0104c4e:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104c55:	e8 8f b7 ff ff       	call   c01003e9 <__panic>

    list_entry_t free_list_store = free_list;
c0104c5a:	a1 1c af 11 c0       	mov    0xc011af1c,%eax
c0104c5f:	8b 15 20 af 11 c0    	mov    0xc011af20,%edx
c0104c65:	89 45 80             	mov    %eax,-0x80(%ebp)
c0104c68:	89 55 84             	mov    %edx,-0x7c(%ebp)
c0104c6b:	c7 45 d0 1c af 11 c0 	movl   $0xc011af1c,-0x30(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c0104c72:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104c75:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0104c78:	89 50 04             	mov    %edx,0x4(%eax)
c0104c7b:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104c7e:	8b 50 04             	mov    0x4(%eax),%edx
c0104c81:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104c84:	89 10                	mov    %edx,(%eax)
c0104c86:	c7 45 d8 1c af 11 c0 	movl   $0xc011af1c,-0x28(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
c0104c8d:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104c90:	8b 40 04             	mov    0x4(%eax),%eax
c0104c93:	39 45 d8             	cmp    %eax,-0x28(%ebp)
c0104c96:	0f 94 c0             	sete   %al
c0104c99:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
c0104c9c:	85 c0                	test   %eax,%eax
c0104c9e:	75 24                	jne    c0104cc4 <default_check+0x1d0>
c0104ca0:	c7 44 24 0c 6f 6b 10 	movl   $0xc0106b6f,0xc(%esp)
c0104ca7:	c0 
c0104ca8:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104caf:	c0 
c0104cb0:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
c0104cb7:	00 
c0104cb8:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104cbf:	e8 25 b7 ff ff       	call   c01003e9 <__panic>
    assert(alloc_page() == NULL);
c0104cc4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104ccb:	e8 82 dc ff ff       	call   c0102952 <alloc_pages>
c0104cd0:	85 c0                	test   %eax,%eax
c0104cd2:	74 24                	je     c0104cf8 <default_check+0x204>
c0104cd4:	c7 44 24 0c 86 6b 10 	movl   $0xc0106b86,0xc(%esp)
c0104cdb:	c0 
c0104cdc:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104ce3:	c0 
c0104ce4:	c7 44 24 04 66 01 00 	movl   $0x166,0x4(%esp)
c0104ceb:	00 
c0104cec:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104cf3:	e8 f1 b6 ff ff       	call   c01003e9 <__panic>

    unsigned int nr_free_store = nr_free;
c0104cf8:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104cfd:	89 45 cc             	mov    %eax,-0x34(%ebp)
    nr_free = 0;
c0104d00:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c0104d07:	00 00 00 

    free_pages(p0 + 2, 3);
c0104d0a:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104d0d:	83 c0 28             	add    $0x28,%eax
c0104d10:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
c0104d17:	00 
c0104d18:	89 04 24             	mov    %eax,(%esp)
c0104d1b:	e8 6a dc ff ff       	call   c010298a <free_pages>
    assert(alloc_pages(4) == NULL);
c0104d20:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
c0104d27:	e8 26 dc ff ff       	call   c0102952 <alloc_pages>
c0104d2c:	85 c0                	test   %eax,%eax
c0104d2e:	74 24                	je     c0104d54 <default_check+0x260>
c0104d30:	c7 44 24 0c 2c 6c 10 	movl   $0xc0106c2c,0xc(%esp)
c0104d37:	c0 
c0104d38:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104d3f:	c0 
c0104d40:	c7 44 24 04 6c 01 00 	movl   $0x16c,0x4(%esp)
c0104d47:	00 
c0104d48:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104d4f:	e8 95 b6 ff ff       	call   c01003e9 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
c0104d54:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104d57:	83 c0 28             	add    $0x28,%eax
c0104d5a:	83 c0 04             	add    $0x4,%eax
c0104d5d:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
c0104d64:	89 45 9c             	mov    %eax,-0x64(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104d67:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0104d6a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104d6d:	0f a3 10             	bt     %edx,(%eax)
c0104d70:	19 c0                	sbb    %eax,%eax
c0104d72:	89 45 98             	mov    %eax,-0x68(%ebp)
    return oldbit != 0;
c0104d75:	83 7d 98 00          	cmpl   $0x0,-0x68(%ebp)
c0104d79:	0f 95 c0             	setne  %al
c0104d7c:	0f b6 c0             	movzbl %al,%eax
c0104d7f:	85 c0                	test   %eax,%eax
c0104d81:	74 0e                	je     c0104d91 <default_check+0x29d>
c0104d83:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104d86:	83 c0 28             	add    $0x28,%eax
c0104d89:	8b 40 08             	mov    0x8(%eax),%eax
c0104d8c:	83 f8 03             	cmp    $0x3,%eax
c0104d8f:	74 24                	je     c0104db5 <default_check+0x2c1>
c0104d91:	c7 44 24 0c 44 6c 10 	movl   $0xc0106c44,0xc(%esp)
c0104d98:	c0 
c0104d99:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104da0:	c0 
c0104da1:	c7 44 24 04 6d 01 00 	movl   $0x16d,0x4(%esp)
c0104da8:	00 
c0104da9:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104db0:	e8 34 b6 ff ff       	call   c01003e9 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
c0104db5:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
c0104dbc:	e8 91 db ff ff       	call   c0102952 <alloc_pages>
c0104dc1:	89 45 c4             	mov    %eax,-0x3c(%ebp)
c0104dc4:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
c0104dc8:	75 24                	jne    c0104dee <default_check+0x2fa>
c0104dca:	c7 44 24 0c 70 6c 10 	movl   $0xc0106c70,0xc(%esp)
c0104dd1:	c0 
c0104dd2:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104dd9:	c0 
c0104dda:	c7 44 24 04 6e 01 00 	movl   $0x16e,0x4(%esp)
c0104de1:	00 
c0104de2:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104de9:	e8 fb b5 ff ff       	call   c01003e9 <__panic>
    assert(alloc_page() == NULL);
c0104dee:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104df5:	e8 58 db ff ff       	call   c0102952 <alloc_pages>
c0104dfa:	85 c0                	test   %eax,%eax
c0104dfc:	74 24                	je     c0104e22 <default_check+0x32e>
c0104dfe:	c7 44 24 0c 86 6b 10 	movl   $0xc0106b86,0xc(%esp)
c0104e05:	c0 
c0104e06:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104e0d:	c0 
c0104e0e:	c7 44 24 04 6f 01 00 	movl   $0x16f,0x4(%esp)
c0104e15:	00 
c0104e16:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104e1d:	e8 c7 b5 ff ff       	call   c01003e9 <__panic>
    assert(p0 + 2 == p1);
c0104e22:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104e25:	83 c0 28             	add    $0x28,%eax
c0104e28:	3b 45 c4             	cmp    -0x3c(%ebp),%eax
c0104e2b:	74 24                	je     c0104e51 <default_check+0x35d>
c0104e2d:	c7 44 24 0c 8e 6c 10 	movl   $0xc0106c8e,0xc(%esp)
c0104e34:	c0 
c0104e35:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104e3c:	c0 
c0104e3d:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
c0104e44:	00 
c0104e45:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104e4c:	e8 98 b5 ff ff       	call   c01003e9 <__panic>

    p2 = p0 + 1;
c0104e51:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104e54:	83 c0 14             	add    $0x14,%eax
c0104e57:	89 45 c0             	mov    %eax,-0x40(%ebp)
    free_page(p0);
c0104e5a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104e61:	00 
c0104e62:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104e65:	89 04 24             	mov    %eax,(%esp)
c0104e68:	e8 1d db ff ff       	call   c010298a <free_pages>
    free_pages(p1, 3);
c0104e6d:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
c0104e74:	00 
c0104e75:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104e78:	89 04 24             	mov    %eax,(%esp)
c0104e7b:	e8 0a db ff ff       	call   c010298a <free_pages>
    assert(PageProperty(p0) && p0->property == 1);
c0104e80:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104e83:	83 c0 04             	add    $0x4,%eax
c0104e86:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
c0104e8d:	89 45 94             	mov    %eax,-0x6c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104e90:	8b 45 94             	mov    -0x6c(%ebp),%eax
c0104e93:	8b 55 c8             	mov    -0x38(%ebp),%edx
c0104e96:	0f a3 10             	bt     %edx,(%eax)
c0104e99:	19 c0                	sbb    %eax,%eax
c0104e9b:	89 45 90             	mov    %eax,-0x70(%ebp)
    return oldbit != 0;
c0104e9e:	83 7d 90 00          	cmpl   $0x0,-0x70(%ebp)
c0104ea2:	0f 95 c0             	setne  %al
c0104ea5:	0f b6 c0             	movzbl %al,%eax
c0104ea8:	85 c0                	test   %eax,%eax
c0104eaa:	74 0b                	je     c0104eb7 <default_check+0x3c3>
c0104eac:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104eaf:	8b 40 08             	mov    0x8(%eax),%eax
c0104eb2:	83 f8 01             	cmp    $0x1,%eax
c0104eb5:	74 24                	je     c0104edb <default_check+0x3e7>
c0104eb7:	c7 44 24 0c 9c 6c 10 	movl   $0xc0106c9c,0xc(%esp)
c0104ebe:	c0 
c0104ebf:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104ec6:	c0 
c0104ec7:	c7 44 24 04 75 01 00 	movl   $0x175,0x4(%esp)
c0104ece:	00 
c0104ecf:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104ed6:	e8 0e b5 ff ff       	call   c01003e9 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
c0104edb:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104ede:	83 c0 04             	add    $0x4,%eax
c0104ee1:	c7 45 bc 01 00 00 00 	movl   $0x1,-0x44(%ebp)
c0104ee8:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104eeb:	8b 45 8c             	mov    -0x74(%ebp),%eax
c0104eee:	8b 55 bc             	mov    -0x44(%ebp),%edx
c0104ef1:	0f a3 10             	bt     %edx,(%eax)
c0104ef4:	19 c0                	sbb    %eax,%eax
c0104ef6:	89 45 88             	mov    %eax,-0x78(%ebp)
    return oldbit != 0;
c0104ef9:	83 7d 88 00          	cmpl   $0x0,-0x78(%ebp)
c0104efd:	0f 95 c0             	setne  %al
c0104f00:	0f b6 c0             	movzbl %al,%eax
c0104f03:	85 c0                	test   %eax,%eax
c0104f05:	74 0b                	je     c0104f12 <default_check+0x41e>
c0104f07:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104f0a:	8b 40 08             	mov    0x8(%eax),%eax
c0104f0d:	83 f8 03             	cmp    $0x3,%eax
c0104f10:	74 24                	je     c0104f36 <default_check+0x442>
c0104f12:	c7 44 24 0c c4 6c 10 	movl   $0xc0106cc4,0xc(%esp)
c0104f19:	c0 
c0104f1a:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104f21:	c0 
c0104f22:	c7 44 24 04 76 01 00 	movl   $0x176,0x4(%esp)
c0104f29:	00 
c0104f2a:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104f31:	e8 b3 b4 ff ff       	call   c01003e9 <__panic>

    assert((p0 = alloc_page()) == p2 - 1);
c0104f36:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104f3d:	e8 10 da ff ff       	call   c0102952 <alloc_pages>
c0104f42:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104f45:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0104f48:	83 e8 14             	sub    $0x14,%eax
c0104f4b:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c0104f4e:	74 24                	je     c0104f74 <default_check+0x480>
c0104f50:	c7 44 24 0c ea 6c 10 	movl   $0xc0106cea,0xc(%esp)
c0104f57:	c0 
c0104f58:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104f5f:	c0 
c0104f60:	c7 44 24 04 78 01 00 	movl   $0x178,0x4(%esp)
c0104f67:	00 
c0104f68:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104f6f:	e8 75 b4 ff ff       	call   c01003e9 <__panic>
    free_page(p0);
c0104f74:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104f7b:	00 
c0104f7c:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104f7f:	89 04 24             	mov    %eax,(%esp)
c0104f82:	e8 03 da ff ff       	call   c010298a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
c0104f87:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
c0104f8e:	e8 bf d9 ff ff       	call   c0102952 <alloc_pages>
c0104f93:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104f96:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0104f99:	83 c0 14             	add    $0x14,%eax
c0104f9c:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c0104f9f:	74 24                	je     c0104fc5 <default_check+0x4d1>
c0104fa1:	c7 44 24 0c 08 6d 10 	movl   $0xc0106d08,0xc(%esp)
c0104fa8:	c0 
c0104fa9:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0104fb0:	c0 
c0104fb1:	c7 44 24 04 7a 01 00 	movl   $0x17a,0x4(%esp)
c0104fb8:	00 
c0104fb9:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0104fc0:	e8 24 b4 ff ff       	call   c01003e9 <__panic>

    free_pages(p0, 2);
c0104fc5:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
c0104fcc:	00 
c0104fcd:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104fd0:	89 04 24             	mov    %eax,(%esp)
c0104fd3:	e8 b2 d9 ff ff       	call   c010298a <free_pages>
    free_page(p2);
c0104fd8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104fdf:	00 
c0104fe0:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0104fe3:	89 04 24             	mov    %eax,(%esp)
c0104fe6:	e8 9f d9 ff ff       	call   c010298a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
c0104feb:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
c0104ff2:	e8 5b d9 ff ff       	call   c0102952 <alloc_pages>
c0104ff7:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104ffa:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0104ffe:	75 24                	jne    c0105024 <default_check+0x530>
c0105000:	c7 44 24 0c 28 6d 10 	movl   $0xc0106d28,0xc(%esp)
c0105007:	c0 
c0105008:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c010500f:	c0 
c0105010:	c7 44 24 04 7f 01 00 	movl   $0x17f,0x4(%esp)
c0105017:	00 
c0105018:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c010501f:	e8 c5 b3 ff ff       	call   c01003e9 <__panic>
    assert(alloc_page() == NULL);
c0105024:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010502b:	e8 22 d9 ff ff       	call   c0102952 <alloc_pages>
c0105030:	85 c0                	test   %eax,%eax
c0105032:	74 24                	je     c0105058 <default_check+0x564>
c0105034:	c7 44 24 0c 86 6b 10 	movl   $0xc0106b86,0xc(%esp)
c010503b:	c0 
c010503c:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0105043:	c0 
c0105044:	c7 44 24 04 80 01 00 	movl   $0x180,0x4(%esp)
c010504b:	00 
c010504c:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0105053:	e8 91 b3 ff ff       	call   c01003e9 <__panic>

    assert(nr_free == 0);
c0105058:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c010505d:	85 c0                	test   %eax,%eax
c010505f:	74 24                	je     c0105085 <default_check+0x591>
c0105061:	c7 44 24 0c d9 6b 10 	movl   $0xc0106bd9,0xc(%esp)
c0105068:	c0 
c0105069:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0105070:	c0 
c0105071:	c7 44 24 04 82 01 00 	movl   $0x182,0x4(%esp)
c0105078:	00 
c0105079:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0105080:	e8 64 b3 ff ff       	call   c01003e9 <__panic>
    nr_free = nr_free_store;
c0105085:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0105088:	a3 24 af 11 c0       	mov    %eax,0xc011af24

    free_list = free_list_store;
c010508d:	8b 45 80             	mov    -0x80(%ebp),%eax
c0105090:	8b 55 84             	mov    -0x7c(%ebp),%edx
c0105093:	a3 1c af 11 c0       	mov    %eax,0xc011af1c
c0105098:	89 15 20 af 11 c0    	mov    %edx,0xc011af20
    free_pages(p0, 5);
c010509e:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
c01050a5:	00 
c01050a6:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01050a9:	89 04 24             	mov    %eax,(%esp)
c01050ac:	e8 d9 d8 ff ff       	call   c010298a <free_pages>

    le = &free_list;
c01050b1:	c7 45 ec 1c af 11 c0 	movl   $0xc011af1c,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
c01050b8:	eb 5a                	jmp    c0105114 <default_check+0x620>
        assert(le->next->prev == le && le->prev->next == le);
c01050ba:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01050bd:	8b 40 04             	mov    0x4(%eax),%eax
c01050c0:	8b 00                	mov    (%eax),%eax
c01050c2:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c01050c5:	75 0d                	jne    c01050d4 <default_check+0x5e0>
c01050c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01050ca:	8b 00                	mov    (%eax),%eax
c01050cc:	8b 40 04             	mov    0x4(%eax),%eax
c01050cf:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c01050d2:	74 24                	je     c01050f8 <default_check+0x604>
c01050d4:	c7 44 24 0c 48 6d 10 	movl   $0xc0106d48,0xc(%esp)
c01050db:	c0 
c01050dc:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c01050e3:	c0 
c01050e4:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
c01050eb:	00 
c01050ec:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c01050f3:	e8 f1 b2 ff ff       	call   c01003e9 <__panic>
        struct Page *p = le2page(le, page_link);
c01050f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01050fb:	83 e8 0c             	sub    $0xc,%eax
c01050fe:	89 45 b4             	mov    %eax,-0x4c(%ebp)
        count --, total -= p->property;
c0105101:	ff 4d f4             	decl   -0xc(%ebp)
c0105104:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0105107:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c010510a:	8b 40 08             	mov    0x8(%eax),%eax
c010510d:	29 c2                	sub    %eax,%edx
c010510f:	89 d0                	mov    %edx,%eax
c0105111:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105114:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105117:	89 45 b8             	mov    %eax,-0x48(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c010511a:	8b 45 b8             	mov    -0x48(%ebp),%eax
c010511d:	8b 40 04             	mov    0x4(%eax),%eax

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c0105120:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105123:	81 7d ec 1c af 11 c0 	cmpl   $0xc011af1c,-0x14(%ebp)
c010512a:	75 8e                	jne    c01050ba <default_check+0x5c6>
        assert(le->next->prev == le && le->prev->next == le);
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
c010512c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0105130:	74 24                	je     c0105156 <default_check+0x662>
c0105132:	c7 44 24 0c 75 6d 10 	movl   $0xc0106d75,0xc(%esp)
c0105139:	c0 
c010513a:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c0105141:	c0 
c0105142:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
c0105149:	00 
c010514a:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c0105151:	e8 93 b2 ff ff       	call   c01003e9 <__panic>
    assert(total == 0);
c0105156:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010515a:	74 24                	je     c0105180 <default_check+0x68c>
c010515c:	c7 44 24 0c 80 6d 10 	movl   $0xc0106d80,0xc(%esp)
c0105163:	c0 
c0105164:	c7 44 24 08 fe 69 10 	movl   $0xc01069fe,0x8(%esp)
c010516b:	c0 
c010516c:	c7 44 24 04 8f 01 00 	movl   $0x18f,0x4(%esp)
c0105173:	00 
c0105174:	c7 04 24 13 6a 10 c0 	movl   $0xc0106a13,(%esp)
c010517b:	e8 69 b2 ff ff       	call   c01003e9 <__panic>
}
c0105180:	90                   	nop
c0105181:	c9                   	leave  
c0105182:	c3                   	ret    

c0105183 <strlen>:
 * @s:      the input string
 *
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
c0105183:	55                   	push   %ebp
c0105184:	89 e5                	mov    %esp,%ebp
c0105186:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
c0105189:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (*s ++ != '\0') {
c0105190:	eb 03                	jmp    c0105195 <strlen+0x12>
        cnt ++;
c0105192:	ff 45 fc             	incl   -0x4(%ebp)
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
c0105195:	8b 45 08             	mov    0x8(%ebp),%eax
c0105198:	8d 50 01             	lea    0x1(%eax),%edx
c010519b:	89 55 08             	mov    %edx,0x8(%ebp)
c010519e:	0f b6 00             	movzbl (%eax),%eax
c01051a1:	84 c0                	test   %al,%al
c01051a3:	75 ed                	jne    c0105192 <strlen+0xf>
        cnt ++;
    }
    return cnt;
c01051a5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c01051a8:	c9                   	leave  
c01051a9:	c3                   	ret    

c01051aa <strnlen>:
 * The return value is strlen(s), if that is less than @len, or
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
c01051aa:	55                   	push   %ebp
c01051ab:	89 e5                	mov    %esp,%ebp
c01051ad:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
c01051b0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (cnt < len && *s ++ != '\0') {
c01051b7:	eb 03                	jmp    c01051bc <strnlen+0x12>
        cnt ++;
c01051b9:	ff 45 fc             	incl   -0x4(%ebp)
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
c01051bc:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01051bf:	3b 45 0c             	cmp    0xc(%ebp),%eax
c01051c2:	73 10                	jae    c01051d4 <strnlen+0x2a>
c01051c4:	8b 45 08             	mov    0x8(%ebp),%eax
c01051c7:	8d 50 01             	lea    0x1(%eax),%edx
c01051ca:	89 55 08             	mov    %edx,0x8(%ebp)
c01051cd:	0f b6 00             	movzbl (%eax),%eax
c01051d0:	84 c0                	test   %al,%al
c01051d2:	75 e5                	jne    c01051b9 <strnlen+0xf>
        cnt ++;
    }
    return cnt;
c01051d4:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c01051d7:	c9                   	leave  
c01051d8:	c3                   	ret    

c01051d9 <strcpy>:
 * To avoid overflows, the size of array pointed by @dst should be long enough to
 * contain the same string as @src (including the terminating null character), and
 * should not overlap in memory with @src.
 * */
char *
strcpy(char *dst, const char *src) {
c01051d9:	55                   	push   %ebp
c01051da:	89 e5                	mov    %esp,%ebp
c01051dc:	57                   	push   %edi
c01051dd:	56                   	push   %esi
c01051de:	83 ec 20             	sub    $0x20,%esp
c01051e1:	8b 45 08             	mov    0x8(%ebp),%eax
c01051e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01051e7:	8b 45 0c             	mov    0xc(%ebp),%eax
c01051ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCPY
#define __HAVE_ARCH_STRCPY
static inline char *
__strcpy(char *dst, const char *src) {
    int d0, d1, d2;
    asm volatile (
c01051ed:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01051f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01051f3:	89 d1                	mov    %edx,%ecx
c01051f5:	89 c2                	mov    %eax,%edx
c01051f7:	89 ce                	mov    %ecx,%esi
c01051f9:	89 d7                	mov    %edx,%edi
c01051fb:	ac                   	lods   %ds:(%esi),%al
c01051fc:	aa                   	stos   %al,%es:(%edi)
c01051fd:	84 c0                	test   %al,%al
c01051ff:	75 fa                	jne    c01051fb <strcpy+0x22>
c0105201:	89 fa                	mov    %edi,%edx
c0105203:	89 f1                	mov    %esi,%ecx
c0105205:	89 4d ec             	mov    %ecx,-0x14(%ebp)
c0105208:	89 55 e8             	mov    %edx,-0x18(%ebp)
c010520b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        "stosb;"
        "testb %%al, %%al;"
        "jne 1b;"
        : "=&S" (d0), "=&D" (d1), "=&a" (d2)
        : "0" (src), "1" (dst) : "memory");
    return dst;
c010520e:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
c0105211:	90                   	nop
    char *p = dst;
    while ((*p ++ = *src ++) != '\0')
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
c0105212:	83 c4 20             	add    $0x20,%esp
c0105215:	5e                   	pop    %esi
c0105216:	5f                   	pop    %edi
c0105217:	5d                   	pop    %ebp
c0105218:	c3                   	ret    

c0105219 <strncpy>:
 * @len:    maximum number of characters to be copied from @src
 *
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
c0105219:	55                   	push   %ebp
c010521a:	89 e5                	mov    %esp,%ebp
c010521c:	83 ec 10             	sub    $0x10,%esp
    char *p = dst;
c010521f:	8b 45 08             	mov    0x8(%ebp),%eax
c0105222:	89 45 fc             	mov    %eax,-0x4(%ebp)
    while (len > 0) {
c0105225:	eb 1e                	jmp    c0105245 <strncpy+0x2c>
        if ((*p = *src) != '\0') {
c0105227:	8b 45 0c             	mov    0xc(%ebp),%eax
c010522a:	0f b6 10             	movzbl (%eax),%edx
c010522d:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0105230:	88 10                	mov    %dl,(%eax)
c0105232:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0105235:	0f b6 00             	movzbl (%eax),%eax
c0105238:	84 c0                	test   %al,%al
c010523a:	74 03                	je     c010523f <strncpy+0x26>
            src ++;
c010523c:	ff 45 0c             	incl   0xc(%ebp)
        }
        p ++, len --;
c010523f:	ff 45 fc             	incl   -0x4(%ebp)
c0105242:	ff 4d 10             	decl   0x10(%ebp)
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
    char *p = dst;
    while (len > 0) {
c0105245:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0105249:	75 dc                	jne    c0105227 <strncpy+0xe>
        if ((*p = *src) != '\0') {
            src ++;
        }
        p ++, len --;
    }
    return dst;
c010524b:	8b 45 08             	mov    0x8(%ebp),%eax
}
c010524e:	c9                   	leave  
c010524f:	c3                   	ret    

c0105250 <strcmp>:
 * - A value greater than zero indicates that the first character that does
 *   not match has a greater value in @s1 than in @s2;
 * - And a value less than zero indicates the opposite.
 * */
int
strcmp(const char *s1, const char *s2) {
c0105250:	55                   	push   %ebp
c0105251:	89 e5                	mov    %esp,%ebp
c0105253:	57                   	push   %edi
c0105254:	56                   	push   %esi
c0105255:	83 ec 20             	sub    $0x20,%esp
c0105258:	8b 45 08             	mov    0x8(%ebp),%eax
c010525b:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010525e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105261:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCMP
#define __HAVE_ARCH_STRCMP
static inline int
__strcmp(const char *s1, const char *s2) {
    int d0, d1, ret;
    asm volatile (
c0105264:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105267:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010526a:	89 d1                	mov    %edx,%ecx
c010526c:	89 c2                	mov    %eax,%edx
c010526e:	89 ce                	mov    %ecx,%esi
c0105270:	89 d7                	mov    %edx,%edi
c0105272:	ac                   	lods   %ds:(%esi),%al
c0105273:	ae                   	scas   %es:(%edi),%al
c0105274:	75 08                	jne    c010527e <strcmp+0x2e>
c0105276:	84 c0                	test   %al,%al
c0105278:	75 f8                	jne    c0105272 <strcmp+0x22>
c010527a:	31 c0                	xor    %eax,%eax
c010527c:	eb 04                	jmp    c0105282 <strcmp+0x32>
c010527e:	19 c0                	sbb    %eax,%eax
c0105280:	0c 01                	or     $0x1,%al
c0105282:	89 fa                	mov    %edi,%edx
c0105284:	89 f1                	mov    %esi,%ecx
c0105286:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105289:	89 4d e8             	mov    %ecx,-0x18(%ebp)
c010528c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
        "orb $1, %%al;"
        "3:"
        : "=a" (ret), "=&S" (d0), "=&D" (d1)
        : "1" (s1), "2" (s2)
        : "memory");
    return ret;
c010528f:	8b 45 ec             	mov    -0x14(%ebp),%eax
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
c0105292:	90                   	nop
    while (*s1 != '\0' && *s1 == *s2) {
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
#endif /* __HAVE_ARCH_STRCMP */
}
c0105293:	83 c4 20             	add    $0x20,%esp
c0105296:	5e                   	pop    %esi
c0105297:	5f                   	pop    %edi
c0105298:	5d                   	pop    %ebp
c0105299:	c3                   	ret    

c010529a <strncmp>:
 * they are equal to each other, it continues with the following pairs until
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
c010529a:	55                   	push   %ebp
c010529b:	89 e5                	mov    %esp,%ebp
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
c010529d:	eb 09                	jmp    c01052a8 <strncmp+0xe>
        n --, s1 ++, s2 ++;
c010529f:	ff 4d 10             	decl   0x10(%ebp)
c01052a2:	ff 45 08             	incl   0x8(%ebp)
c01052a5:	ff 45 0c             	incl   0xc(%ebp)
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
c01052a8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01052ac:	74 1a                	je     c01052c8 <strncmp+0x2e>
c01052ae:	8b 45 08             	mov    0x8(%ebp),%eax
c01052b1:	0f b6 00             	movzbl (%eax),%eax
c01052b4:	84 c0                	test   %al,%al
c01052b6:	74 10                	je     c01052c8 <strncmp+0x2e>
c01052b8:	8b 45 08             	mov    0x8(%ebp),%eax
c01052bb:	0f b6 10             	movzbl (%eax),%edx
c01052be:	8b 45 0c             	mov    0xc(%ebp),%eax
c01052c1:	0f b6 00             	movzbl (%eax),%eax
c01052c4:	38 c2                	cmp    %al,%dl
c01052c6:	74 d7                	je     c010529f <strncmp+0x5>
        n --, s1 ++, s2 ++;
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
c01052c8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01052cc:	74 18                	je     c01052e6 <strncmp+0x4c>
c01052ce:	8b 45 08             	mov    0x8(%ebp),%eax
c01052d1:	0f b6 00             	movzbl (%eax),%eax
c01052d4:	0f b6 d0             	movzbl %al,%edx
c01052d7:	8b 45 0c             	mov    0xc(%ebp),%eax
c01052da:	0f b6 00             	movzbl (%eax),%eax
c01052dd:	0f b6 c0             	movzbl %al,%eax
c01052e0:	29 c2                	sub    %eax,%edx
c01052e2:	89 d0                	mov    %edx,%eax
c01052e4:	eb 05                	jmp    c01052eb <strncmp+0x51>
c01052e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01052eb:	5d                   	pop    %ebp
c01052ec:	c3                   	ret    

c01052ed <strchr>:
 *
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
c01052ed:	55                   	push   %ebp
c01052ee:	89 e5                	mov    %esp,%ebp
c01052f0:	83 ec 04             	sub    $0x4,%esp
c01052f3:	8b 45 0c             	mov    0xc(%ebp),%eax
c01052f6:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
c01052f9:	eb 13                	jmp    c010530e <strchr+0x21>
        if (*s == c) {
c01052fb:	8b 45 08             	mov    0x8(%ebp),%eax
c01052fe:	0f b6 00             	movzbl (%eax),%eax
c0105301:	3a 45 fc             	cmp    -0x4(%ebp),%al
c0105304:	75 05                	jne    c010530b <strchr+0x1e>
            return (char *)s;
c0105306:	8b 45 08             	mov    0x8(%ebp),%eax
c0105309:	eb 12                	jmp    c010531d <strchr+0x30>
        }
        s ++;
c010530b:	ff 45 08             	incl   0x8(%ebp)
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
c010530e:	8b 45 08             	mov    0x8(%ebp),%eax
c0105311:	0f b6 00             	movzbl (%eax),%eax
c0105314:	84 c0                	test   %al,%al
c0105316:	75 e3                	jne    c01052fb <strchr+0xe>
        if (*s == c) {
            return (char *)s;
        }
        s ++;
    }
    return NULL;
c0105318:	b8 00 00 00 00       	mov    $0x0,%eax
}
c010531d:	c9                   	leave  
c010531e:	c3                   	ret    

c010531f <strfind>:
 * The strfind() function is like strchr() except that if @c is
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
c010531f:	55                   	push   %ebp
c0105320:	89 e5                	mov    %esp,%ebp
c0105322:	83 ec 04             	sub    $0x4,%esp
c0105325:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105328:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
c010532b:	eb 0e                	jmp    c010533b <strfind+0x1c>
        if (*s == c) {
c010532d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105330:	0f b6 00             	movzbl (%eax),%eax
c0105333:	3a 45 fc             	cmp    -0x4(%ebp),%al
c0105336:	74 0f                	je     c0105347 <strfind+0x28>
            break;
        }
        s ++;
c0105338:	ff 45 08             	incl   0x8(%ebp)
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
    while (*s != '\0') {
c010533b:	8b 45 08             	mov    0x8(%ebp),%eax
c010533e:	0f b6 00             	movzbl (%eax),%eax
c0105341:	84 c0                	test   %al,%al
c0105343:	75 e8                	jne    c010532d <strfind+0xe>
c0105345:	eb 01                	jmp    c0105348 <strfind+0x29>
        if (*s == c) {
            break;
c0105347:	90                   	nop
        }
        s ++;
    }
    return (char *)s;
c0105348:	8b 45 08             	mov    0x8(%ebp),%eax
}
c010534b:	c9                   	leave  
c010534c:	c3                   	ret    

c010534d <strtol>:
 * an optional "0x" or "0X" prefix.
 *
 * The strtol() function returns the converted integral number as a long int value.
 * */
long
strtol(const char *s, char **endptr, int base) {
c010534d:	55                   	push   %ebp
c010534e:	89 e5                	mov    %esp,%ebp
c0105350:	83 ec 10             	sub    $0x10,%esp
    int neg = 0;
c0105353:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    long val = 0;
c010535a:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
c0105361:	eb 03                	jmp    c0105366 <strtol+0x19>
        s ++;
c0105363:	ff 45 08             	incl   0x8(%ebp)
strtol(const char *s, char **endptr, int base) {
    int neg = 0;
    long val = 0;

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
c0105366:	8b 45 08             	mov    0x8(%ebp),%eax
c0105369:	0f b6 00             	movzbl (%eax),%eax
c010536c:	3c 20                	cmp    $0x20,%al
c010536e:	74 f3                	je     c0105363 <strtol+0x16>
c0105370:	8b 45 08             	mov    0x8(%ebp),%eax
c0105373:	0f b6 00             	movzbl (%eax),%eax
c0105376:	3c 09                	cmp    $0x9,%al
c0105378:	74 e9                	je     c0105363 <strtol+0x16>
        s ++;
    }

    // plus/minus sign
    if (*s == '+') {
c010537a:	8b 45 08             	mov    0x8(%ebp),%eax
c010537d:	0f b6 00             	movzbl (%eax),%eax
c0105380:	3c 2b                	cmp    $0x2b,%al
c0105382:	75 05                	jne    c0105389 <strtol+0x3c>
        s ++;
c0105384:	ff 45 08             	incl   0x8(%ebp)
c0105387:	eb 14                	jmp    c010539d <strtol+0x50>
    }
    else if (*s == '-') {
c0105389:	8b 45 08             	mov    0x8(%ebp),%eax
c010538c:	0f b6 00             	movzbl (%eax),%eax
c010538f:	3c 2d                	cmp    $0x2d,%al
c0105391:	75 0a                	jne    c010539d <strtol+0x50>
        s ++, neg = 1;
c0105393:	ff 45 08             	incl   0x8(%ebp)
c0105396:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)
    }

    // hex or octal base prefix
    if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x')) {
c010539d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01053a1:	74 06                	je     c01053a9 <strtol+0x5c>
c01053a3:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
c01053a7:	75 22                	jne    c01053cb <strtol+0x7e>
c01053a9:	8b 45 08             	mov    0x8(%ebp),%eax
c01053ac:	0f b6 00             	movzbl (%eax),%eax
c01053af:	3c 30                	cmp    $0x30,%al
c01053b1:	75 18                	jne    c01053cb <strtol+0x7e>
c01053b3:	8b 45 08             	mov    0x8(%ebp),%eax
c01053b6:	40                   	inc    %eax
c01053b7:	0f b6 00             	movzbl (%eax),%eax
c01053ba:	3c 78                	cmp    $0x78,%al
c01053bc:	75 0d                	jne    c01053cb <strtol+0x7e>
        s += 2, base = 16;
c01053be:	83 45 08 02          	addl   $0x2,0x8(%ebp)
c01053c2:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
c01053c9:	eb 29                	jmp    c01053f4 <strtol+0xa7>
    }
    else if (base == 0 && s[0] == '0') {
c01053cb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01053cf:	75 16                	jne    c01053e7 <strtol+0x9a>
c01053d1:	8b 45 08             	mov    0x8(%ebp),%eax
c01053d4:	0f b6 00             	movzbl (%eax),%eax
c01053d7:	3c 30                	cmp    $0x30,%al
c01053d9:	75 0c                	jne    c01053e7 <strtol+0x9a>
        s ++, base = 8;
c01053db:	ff 45 08             	incl   0x8(%ebp)
c01053de:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
c01053e5:	eb 0d                	jmp    c01053f4 <strtol+0xa7>
    }
    else if (base == 0) {
c01053e7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01053eb:	75 07                	jne    c01053f4 <strtol+0xa7>
        base = 10;
c01053ed:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

    // digits
    while (1) {
        int dig;

        if (*s >= '0' && *s <= '9') {
c01053f4:	8b 45 08             	mov    0x8(%ebp),%eax
c01053f7:	0f b6 00             	movzbl (%eax),%eax
c01053fa:	3c 2f                	cmp    $0x2f,%al
c01053fc:	7e 1b                	jle    c0105419 <strtol+0xcc>
c01053fe:	8b 45 08             	mov    0x8(%ebp),%eax
c0105401:	0f b6 00             	movzbl (%eax),%eax
c0105404:	3c 39                	cmp    $0x39,%al
c0105406:	7f 11                	jg     c0105419 <strtol+0xcc>
            dig = *s - '0';
c0105408:	8b 45 08             	mov    0x8(%ebp),%eax
c010540b:	0f b6 00             	movzbl (%eax),%eax
c010540e:	0f be c0             	movsbl %al,%eax
c0105411:	83 e8 30             	sub    $0x30,%eax
c0105414:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105417:	eb 48                	jmp    c0105461 <strtol+0x114>
        }
        else if (*s >= 'a' && *s <= 'z') {
c0105419:	8b 45 08             	mov    0x8(%ebp),%eax
c010541c:	0f b6 00             	movzbl (%eax),%eax
c010541f:	3c 60                	cmp    $0x60,%al
c0105421:	7e 1b                	jle    c010543e <strtol+0xf1>
c0105423:	8b 45 08             	mov    0x8(%ebp),%eax
c0105426:	0f b6 00             	movzbl (%eax),%eax
c0105429:	3c 7a                	cmp    $0x7a,%al
c010542b:	7f 11                	jg     c010543e <strtol+0xf1>
            dig = *s - 'a' + 10;
c010542d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105430:	0f b6 00             	movzbl (%eax),%eax
c0105433:	0f be c0             	movsbl %al,%eax
c0105436:	83 e8 57             	sub    $0x57,%eax
c0105439:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010543c:	eb 23                	jmp    c0105461 <strtol+0x114>
        }
        else if (*s >= 'A' && *s <= 'Z') {
c010543e:	8b 45 08             	mov    0x8(%ebp),%eax
c0105441:	0f b6 00             	movzbl (%eax),%eax
c0105444:	3c 40                	cmp    $0x40,%al
c0105446:	7e 3b                	jle    c0105483 <strtol+0x136>
c0105448:	8b 45 08             	mov    0x8(%ebp),%eax
c010544b:	0f b6 00             	movzbl (%eax),%eax
c010544e:	3c 5a                	cmp    $0x5a,%al
c0105450:	7f 31                	jg     c0105483 <strtol+0x136>
            dig = *s - 'A' + 10;
c0105452:	8b 45 08             	mov    0x8(%ebp),%eax
c0105455:	0f b6 00             	movzbl (%eax),%eax
c0105458:	0f be c0             	movsbl %al,%eax
c010545b:	83 e8 37             	sub    $0x37,%eax
c010545e:	89 45 f4             	mov    %eax,-0xc(%ebp)
        }
        else {
            break;
        }
        if (dig >= base) {
c0105461:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105464:	3b 45 10             	cmp    0x10(%ebp),%eax
c0105467:	7d 19                	jge    c0105482 <strtol+0x135>
            break;
        }
        s ++, val = (val * base) + dig;
c0105469:	ff 45 08             	incl   0x8(%ebp)
c010546c:	8b 45 f8             	mov    -0x8(%ebp),%eax
c010546f:	0f af 45 10          	imul   0x10(%ebp),%eax
c0105473:	89 c2                	mov    %eax,%edx
c0105475:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105478:	01 d0                	add    %edx,%eax
c010547a:	89 45 f8             	mov    %eax,-0x8(%ebp)
        // we don't properly detect overflow!
    }
c010547d:	e9 72 ff ff ff       	jmp    c01053f4 <strtol+0xa7>
        }
        else {
            break;
        }
        if (dig >= base) {
            break;
c0105482:	90                   	nop
        }
        s ++, val = (val * base) + dig;
        // we don't properly detect overflow!
    }

    if (endptr) {
c0105483:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0105487:	74 08                	je     c0105491 <strtol+0x144>
        *endptr = (char *) s;
c0105489:	8b 45 0c             	mov    0xc(%ebp),%eax
c010548c:	8b 55 08             	mov    0x8(%ebp),%edx
c010548f:	89 10                	mov    %edx,(%eax)
    }
    return (neg ? -val : val);
c0105491:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
c0105495:	74 07                	je     c010549e <strtol+0x151>
c0105497:	8b 45 f8             	mov    -0x8(%ebp),%eax
c010549a:	f7 d8                	neg    %eax
c010549c:	eb 03                	jmp    c01054a1 <strtol+0x154>
c010549e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
c01054a1:	c9                   	leave  
c01054a2:	c3                   	ret    

c01054a3 <memset>:
 * @n:      number of bytes to be set to the value
 *
 * The memset() function returns @s.
 * */
void *
memset(void *s, char c, size_t n) {
c01054a3:	55                   	push   %ebp
c01054a4:	89 e5                	mov    %esp,%ebp
c01054a6:	57                   	push   %edi
c01054a7:	83 ec 24             	sub    $0x24,%esp
c01054aa:	8b 45 0c             	mov    0xc(%ebp),%eax
c01054ad:	88 45 d8             	mov    %al,-0x28(%ebp)
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
c01054b0:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
c01054b4:	8b 55 08             	mov    0x8(%ebp),%edx
c01054b7:	89 55 f8             	mov    %edx,-0x8(%ebp)
c01054ba:	88 45 f7             	mov    %al,-0x9(%ebp)
c01054bd:	8b 45 10             	mov    0x10(%ebp),%eax
c01054c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_MEMSET
#define __HAVE_ARCH_MEMSET
static inline void *
__memset(void *s, char c, size_t n) {
    int d0, d1;
    asm volatile (
c01054c3:	8b 4d f0             	mov    -0x10(%ebp),%ecx
c01054c6:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
c01054ca:	8b 55 f8             	mov    -0x8(%ebp),%edx
c01054cd:	89 d7                	mov    %edx,%edi
c01054cf:	f3 aa                	rep stos %al,%es:(%edi)
c01054d1:	89 fa                	mov    %edi,%edx
c01054d3:	89 4d ec             	mov    %ecx,-0x14(%ebp)
c01054d6:	89 55 e8             	mov    %edx,-0x18(%ebp)
        "rep; stosb;"
        : "=&c" (d0), "=&D" (d1)
        : "0" (n), "a" (c), "1" (s)
        : "memory");
    return s;
c01054d9:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01054dc:	90                   	nop
    while (n -- > 0) {
        *p ++ = c;
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
c01054dd:	83 c4 24             	add    $0x24,%esp
c01054e0:	5f                   	pop    %edi
c01054e1:	5d                   	pop    %ebp
c01054e2:	c3                   	ret    

c01054e3 <memmove>:
 * @n:      number of bytes to copy
 *
 * The memmove() function returns @dst.
 * */
void *
memmove(void *dst, const void *src, size_t n) {
c01054e3:	55                   	push   %ebp
c01054e4:	89 e5                	mov    %esp,%ebp
c01054e6:	57                   	push   %edi
c01054e7:	56                   	push   %esi
c01054e8:	53                   	push   %ebx
c01054e9:	83 ec 30             	sub    $0x30,%esp
c01054ec:	8b 45 08             	mov    0x8(%ebp),%eax
c01054ef:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01054f2:	8b 45 0c             	mov    0xc(%ebp),%eax
c01054f5:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01054f8:	8b 45 10             	mov    0x10(%ebp),%eax
c01054fb:	89 45 e8             	mov    %eax,-0x18(%ebp)

#ifndef __HAVE_ARCH_MEMMOVE
#define __HAVE_ARCH_MEMMOVE
static inline void *
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
c01054fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105501:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0105504:	73 42                	jae    c0105548 <memmove+0x65>
c0105506:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105509:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c010550c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010550f:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0105512:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105515:	89 45 dc             	mov    %eax,-0x24(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c0105518:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010551b:	c1 e8 02             	shr    $0x2,%eax
c010551e:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
c0105520:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0105523:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105526:	89 d7                	mov    %edx,%edi
c0105528:	89 c6                	mov    %eax,%esi
c010552a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c010552c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
c010552f:	83 e1 03             	and    $0x3,%ecx
c0105532:	74 02                	je     c0105536 <memmove+0x53>
c0105534:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c0105536:	89 f0                	mov    %esi,%eax
c0105538:	89 fa                	mov    %edi,%edx
c010553a:	89 4d d8             	mov    %ecx,-0x28(%ebp)
c010553d:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0105540:	89 45 d0             	mov    %eax,-0x30(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
c0105543:	8b 45 e4             	mov    -0x1c(%ebp),%eax
#ifdef __HAVE_ARCH_MEMMOVE
    return __memmove(dst, src, n);
c0105546:	eb 36                	jmp    c010557e <memmove+0x9b>
    asm volatile (
        "std;"
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
c0105548:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010554b:	8d 50 ff             	lea    -0x1(%eax),%edx
c010554e:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105551:	01 c2                	add    %eax,%edx
c0105553:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105556:	8d 48 ff             	lea    -0x1(%eax),%ecx
c0105559:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010555c:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
        return __memcpy(dst, src, n);
    }
    int d0, d1, d2;
    asm volatile (
c010555f:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105562:	89 c1                	mov    %eax,%ecx
c0105564:	89 d8                	mov    %ebx,%eax
c0105566:	89 d6                	mov    %edx,%esi
c0105568:	89 c7                	mov    %eax,%edi
c010556a:	fd                   	std    
c010556b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c010556d:	fc                   	cld    
c010556e:	89 f8                	mov    %edi,%eax
c0105570:	89 f2                	mov    %esi,%edx
c0105572:	89 4d cc             	mov    %ecx,-0x34(%ebp)
c0105575:	89 55 c8             	mov    %edx,-0x38(%ebp)
c0105578:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
        : "memory");
    return dst;
c010557b:	8b 45 f0             	mov    -0x10(%ebp),%eax
            *d ++ = *s ++;
        }
    }
    return dst;
#endif /* __HAVE_ARCH_MEMMOVE */
}
c010557e:	83 c4 30             	add    $0x30,%esp
c0105581:	5b                   	pop    %ebx
c0105582:	5e                   	pop    %esi
c0105583:	5f                   	pop    %edi
c0105584:	5d                   	pop    %ebp
c0105585:	c3                   	ret    

c0105586 <memcpy>:
 * it always copies exactly @n bytes. To avoid overflows, the size of arrays pointed
 * by both @src and @dst, should be at least @n bytes, and should not overlap
 * (for overlapping memory area, memmove is a safer approach).
 * */
void *
memcpy(void *dst, const void *src, size_t n) {
c0105586:	55                   	push   %ebp
c0105587:	89 e5                	mov    %esp,%ebp
c0105589:	57                   	push   %edi
c010558a:	56                   	push   %esi
c010558b:	83 ec 20             	sub    $0x20,%esp
c010558e:	8b 45 08             	mov    0x8(%ebp),%eax
c0105591:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105594:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105597:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010559a:	8b 45 10             	mov    0x10(%ebp),%eax
c010559d:	89 45 ec             	mov    %eax,-0x14(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c01055a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01055a3:	c1 e8 02             	shr    $0x2,%eax
c01055a6:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
c01055a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01055ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01055ae:	89 d7                	mov    %edx,%edi
c01055b0:	89 c6                	mov    %eax,%esi
c01055b2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c01055b4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
c01055b7:	83 e1 03             	and    $0x3,%ecx
c01055ba:	74 02                	je     c01055be <memcpy+0x38>
c01055bc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c01055be:	89 f0                	mov    %esi,%eax
c01055c0:	89 fa                	mov    %edi,%edx
c01055c2:	89 4d e8             	mov    %ecx,-0x18(%ebp)
c01055c5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
c01055c8:	89 45 e0             	mov    %eax,-0x20(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
c01055cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
c01055ce:	90                   	nop
    while (n -- > 0) {
        *d ++ = *s ++;
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
c01055cf:	83 c4 20             	add    $0x20,%esp
c01055d2:	5e                   	pop    %esi
c01055d3:	5f                   	pop    %edi
c01055d4:	5d                   	pop    %ebp
c01055d5:	c3                   	ret    

c01055d6 <memcmp>:
 *   match in both memory blocks has a greater value in @v1 than in @v2
 *   as if evaluated as unsigned char values;
 * - And a value less than zero indicates the opposite.
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
c01055d6:	55                   	push   %ebp
c01055d7:	89 e5                	mov    %esp,%ebp
c01055d9:	83 ec 10             	sub    $0x10,%esp
    const char *s1 = (const char *)v1;
c01055dc:	8b 45 08             	mov    0x8(%ebp),%eax
c01055df:	89 45 fc             	mov    %eax,-0x4(%ebp)
    const char *s2 = (const char *)v2;
c01055e2:	8b 45 0c             	mov    0xc(%ebp),%eax
c01055e5:	89 45 f8             	mov    %eax,-0x8(%ebp)
    while (n -- > 0) {
c01055e8:	eb 2e                	jmp    c0105618 <memcmp+0x42>
        if (*s1 != *s2) {
c01055ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01055ed:	0f b6 10             	movzbl (%eax),%edx
c01055f0:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01055f3:	0f b6 00             	movzbl (%eax),%eax
c01055f6:	38 c2                	cmp    %al,%dl
c01055f8:	74 18                	je     c0105612 <memcmp+0x3c>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
c01055fa:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01055fd:	0f b6 00             	movzbl (%eax),%eax
c0105600:	0f b6 d0             	movzbl %al,%edx
c0105603:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0105606:	0f b6 00             	movzbl (%eax),%eax
c0105609:	0f b6 c0             	movzbl %al,%eax
c010560c:	29 c2                	sub    %eax,%edx
c010560e:	89 d0                	mov    %edx,%eax
c0105610:	eb 18                	jmp    c010562a <memcmp+0x54>
        }
        s1 ++, s2 ++;
c0105612:	ff 45 fc             	incl   -0x4(%ebp)
c0105615:	ff 45 f8             	incl   -0x8(%ebp)
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
c0105618:	8b 45 10             	mov    0x10(%ebp),%eax
c010561b:	8d 50 ff             	lea    -0x1(%eax),%edx
c010561e:	89 55 10             	mov    %edx,0x10(%ebp)
c0105621:	85 c0                	test   %eax,%eax
c0105623:	75 c5                	jne    c01055ea <memcmp+0x14>
        if (*s1 != *s2) {
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
    }
    return 0;
c0105625:	b8 00 00 00 00       	mov    $0x0,%eax
}
c010562a:	c9                   	leave  
c010562b:	c3                   	ret    

c010562c <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
c010562c:	55                   	push   %ebp
c010562d:	89 e5                	mov    %esp,%ebp
c010562f:	83 ec 58             	sub    $0x58,%esp
c0105632:	8b 45 10             	mov    0x10(%ebp),%eax
c0105635:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0105638:	8b 45 14             	mov    0x14(%ebp),%eax
c010563b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    unsigned long long result = num;
c010563e:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0105641:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0105644:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0105647:	89 55 ec             	mov    %edx,-0x14(%ebp)
    unsigned mod = do_div(result, base);
c010564a:	8b 45 18             	mov    0x18(%ebp),%eax
c010564d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0105650:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105653:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0105656:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0105659:	89 55 f0             	mov    %edx,-0x10(%ebp)
c010565c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010565f:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105662:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0105666:	74 1c                	je     c0105684 <printnum+0x58>
c0105668:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010566b:	ba 00 00 00 00       	mov    $0x0,%edx
c0105670:	f7 75 e4             	divl   -0x1c(%ebp)
c0105673:	89 55 f4             	mov    %edx,-0xc(%ebp)
c0105676:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105679:	ba 00 00 00 00       	mov    $0x0,%edx
c010567e:	f7 75 e4             	divl   -0x1c(%ebp)
c0105681:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105684:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105687:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010568a:	f7 75 e4             	divl   -0x1c(%ebp)
c010568d:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0105690:	89 55 dc             	mov    %edx,-0x24(%ebp)
c0105693:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105696:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0105699:	89 45 e8             	mov    %eax,-0x18(%ebp)
c010569c:	89 55 ec             	mov    %edx,-0x14(%ebp)
c010569f:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01056a2:	89 45 d8             	mov    %eax,-0x28(%ebp)

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
c01056a5:	8b 45 18             	mov    0x18(%ebp),%eax
c01056a8:	ba 00 00 00 00       	mov    $0x0,%edx
c01056ad:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c01056b0:	77 56                	ja     c0105708 <printnum+0xdc>
c01056b2:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c01056b5:	72 05                	jb     c01056bc <printnum+0x90>
c01056b7:	3b 45 d0             	cmp    -0x30(%ebp),%eax
c01056ba:	77 4c                	ja     c0105708 <printnum+0xdc>
        printnum(putch, putdat, result, base, width - 1, padc);
c01056bc:	8b 45 1c             	mov    0x1c(%ebp),%eax
c01056bf:	8d 50 ff             	lea    -0x1(%eax),%edx
c01056c2:	8b 45 20             	mov    0x20(%ebp),%eax
c01056c5:	89 44 24 18          	mov    %eax,0x18(%esp)
c01056c9:	89 54 24 14          	mov    %edx,0x14(%esp)
c01056cd:	8b 45 18             	mov    0x18(%ebp),%eax
c01056d0:	89 44 24 10          	mov    %eax,0x10(%esp)
c01056d4:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01056d7:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01056da:	89 44 24 08          	mov    %eax,0x8(%esp)
c01056de:	89 54 24 0c          	mov    %edx,0xc(%esp)
c01056e2:	8b 45 0c             	mov    0xc(%ebp),%eax
c01056e5:	89 44 24 04          	mov    %eax,0x4(%esp)
c01056e9:	8b 45 08             	mov    0x8(%ebp),%eax
c01056ec:	89 04 24             	mov    %eax,(%esp)
c01056ef:	e8 38 ff ff ff       	call   c010562c <printnum>
c01056f4:	eb 1b                	jmp    c0105711 <printnum+0xe5>
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
            putch(padc, putdat);
c01056f6:	8b 45 0c             	mov    0xc(%ebp),%eax
c01056f9:	89 44 24 04          	mov    %eax,0x4(%esp)
c01056fd:	8b 45 20             	mov    0x20(%ebp),%eax
c0105700:	89 04 24             	mov    %eax,(%esp)
c0105703:	8b 45 08             	mov    0x8(%ebp),%eax
c0105706:	ff d0                	call   *%eax
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
c0105708:	ff 4d 1c             	decl   0x1c(%ebp)
c010570b:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
c010570f:	7f e5                	jg     c01056f6 <printnum+0xca>
            putch(padc, putdat);
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
c0105711:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0105714:	05 3c 6e 10 c0       	add    $0xc0106e3c,%eax
c0105719:	0f b6 00             	movzbl (%eax),%eax
c010571c:	0f be c0             	movsbl %al,%eax
c010571f:	8b 55 0c             	mov    0xc(%ebp),%edx
c0105722:	89 54 24 04          	mov    %edx,0x4(%esp)
c0105726:	89 04 24             	mov    %eax,(%esp)
c0105729:	8b 45 08             	mov    0x8(%ebp),%eax
c010572c:	ff d0                	call   *%eax
}
c010572e:	90                   	nop
c010572f:	c9                   	leave  
c0105730:	c3                   	ret    

c0105731 <getuint>:
 * getuint - get an unsigned int of various possible sizes from a varargs list
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static unsigned long long
getuint(va_list *ap, int lflag) {
c0105731:	55                   	push   %ebp
c0105732:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
c0105734:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
c0105738:	7e 14                	jle    c010574e <getuint+0x1d>
        return va_arg(*ap, unsigned long long);
c010573a:	8b 45 08             	mov    0x8(%ebp),%eax
c010573d:	8b 00                	mov    (%eax),%eax
c010573f:	8d 48 08             	lea    0x8(%eax),%ecx
c0105742:	8b 55 08             	mov    0x8(%ebp),%edx
c0105745:	89 0a                	mov    %ecx,(%edx)
c0105747:	8b 50 04             	mov    0x4(%eax),%edx
c010574a:	8b 00                	mov    (%eax),%eax
c010574c:	eb 30                	jmp    c010577e <getuint+0x4d>
    }
    else if (lflag) {
c010574e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0105752:	74 16                	je     c010576a <getuint+0x39>
        return va_arg(*ap, unsigned long);
c0105754:	8b 45 08             	mov    0x8(%ebp),%eax
c0105757:	8b 00                	mov    (%eax),%eax
c0105759:	8d 48 04             	lea    0x4(%eax),%ecx
c010575c:	8b 55 08             	mov    0x8(%ebp),%edx
c010575f:	89 0a                	mov    %ecx,(%edx)
c0105761:	8b 00                	mov    (%eax),%eax
c0105763:	ba 00 00 00 00       	mov    $0x0,%edx
c0105768:	eb 14                	jmp    c010577e <getuint+0x4d>
    }
    else {
        return va_arg(*ap, unsigned int);
c010576a:	8b 45 08             	mov    0x8(%ebp),%eax
c010576d:	8b 00                	mov    (%eax),%eax
c010576f:	8d 48 04             	lea    0x4(%eax),%ecx
c0105772:	8b 55 08             	mov    0x8(%ebp),%edx
c0105775:	89 0a                	mov    %ecx,(%edx)
c0105777:	8b 00                	mov    (%eax),%eax
c0105779:	ba 00 00 00 00       	mov    $0x0,%edx
    }
}
c010577e:	5d                   	pop    %ebp
c010577f:	c3                   	ret    

c0105780 <getint>:
 * getint - same as getuint but signed, we can't use getuint because of sign extension
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static long long
getint(va_list *ap, int lflag) {
c0105780:	55                   	push   %ebp
c0105781:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
c0105783:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
c0105787:	7e 14                	jle    c010579d <getint+0x1d>
        return va_arg(*ap, long long);
c0105789:	8b 45 08             	mov    0x8(%ebp),%eax
c010578c:	8b 00                	mov    (%eax),%eax
c010578e:	8d 48 08             	lea    0x8(%eax),%ecx
c0105791:	8b 55 08             	mov    0x8(%ebp),%edx
c0105794:	89 0a                	mov    %ecx,(%edx)
c0105796:	8b 50 04             	mov    0x4(%eax),%edx
c0105799:	8b 00                	mov    (%eax),%eax
c010579b:	eb 28                	jmp    c01057c5 <getint+0x45>
    }
    else if (lflag) {
c010579d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c01057a1:	74 12                	je     c01057b5 <getint+0x35>
        return va_arg(*ap, long);
c01057a3:	8b 45 08             	mov    0x8(%ebp),%eax
c01057a6:	8b 00                	mov    (%eax),%eax
c01057a8:	8d 48 04             	lea    0x4(%eax),%ecx
c01057ab:	8b 55 08             	mov    0x8(%ebp),%edx
c01057ae:	89 0a                	mov    %ecx,(%edx)
c01057b0:	8b 00                	mov    (%eax),%eax
c01057b2:	99                   	cltd   
c01057b3:	eb 10                	jmp    c01057c5 <getint+0x45>
    }
    else {
        return va_arg(*ap, int);
c01057b5:	8b 45 08             	mov    0x8(%ebp),%eax
c01057b8:	8b 00                	mov    (%eax),%eax
c01057ba:	8d 48 04             	lea    0x4(%eax),%ecx
c01057bd:	8b 55 08             	mov    0x8(%ebp),%edx
c01057c0:	89 0a                	mov    %ecx,(%edx)
c01057c2:	8b 00                	mov    (%eax),%eax
c01057c4:	99                   	cltd   
    }
}
c01057c5:	5d                   	pop    %ebp
c01057c6:	c3                   	ret    

c01057c7 <printfmt>:
 * @putch:      specified putch function, print a single character
 * @putdat:     used by @putch function
 * @fmt:        the format string to use
 * */
void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
c01057c7:	55                   	push   %ebp
c01057c8:	89 e5                	mov    %esp,%ebp
c01057ca:	83 ec 28             	sub    $0x28,%esp
    va_list ap;

    va_start(ap, fmt);
c01057cd:	8d 45 14             	lea    0x14(%ebp),%eax
c01057d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
    vprintfmt(putch, putdat, fmt, ap);
c01057d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01057d6:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01057da:	8b 45 10             	mov    0x10(%ebp),%eax
c01057dd:	89 44 24 08          	mov    %eax,0x8(%esp)
c01057e1:	8b 45 0c             	mov    0xc(%ebp),%eax
c01057e4:	89 44 24 04          	mov    %eax,0x4(%esp)
c01057e8:	8b 45 08             	mov    0x8(%ebp),%eax
c01057eb:	89 04 24             	mov    %eax,(%esp)
c01057ee:	e8 03 00 00 00       	call   c01057f6 <vprintfmt>
    va_end(ap);
}
c01057f3:	90                   	nop
c01057f4:	c9                   	leave  
c01057f5:	c3                   	ret    

c01057f6 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
c01057f6:	55                   	push   %ebp
c01057f7:	89 e5                	mov    %esp,%ebp
c01057f9:	56                   	push   %esi
c01057fa:	53                   	push   %ebx
c01057fb:	83 ec 40             	sub    $0x40,%esp
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c01057fe:	eb 17                	jmp    c0105817 <vprintfmt+0x21>
            if (ch == '\0') {
c0105800:	85 db                	test   %ebx,%ebx
c0105802:	0f 84 bf 03 00 00    	je     c0105bc7 <vprintfmt+0x3d1>
                return;
            }
            putch(ch, putdat);
c0105808:	8b 45 0c             	mov    0xc(%ebp),%eax
c010580b:	89 44 24 04          	mov    %eax,0x4(%esp)
c010580f:	89 1c 24             	mov    %ebx,(%esp)
c0105812:	8b 45 08             	mov    0x8(%ebp),%eax
c0105815:	ff d0                	call   *%eax
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c0105817:	8b 45 10             	mov    0x10(%ebp),%eax
c010581a:	8d 50 01             	lea    0x1(%eax),%edx
c010581d:	89 55 10             	mov    %edx,0x10(%ebp)
c0105820:	0f b6 00             	movzbl (%eax),%eax
c0105823:	0f b6 d8             	movzbl %al,%ebx
c0105826:	83 fb 25             	cmp    $0x25,%ebx
c0105829:	75 d5                	jne    c0105800 <vprintfmt+0xa>
            }
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
c010582b:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
        width = precision = -1;
c010582f:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
c0105836:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105839:	89 45 e8             	mov    %eax,-0x18(%ebp)
        lflag = altflag = 0;
c010583c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0105843:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105846:	89 45 e0             	mov    %eax,-0x20(%ebp)

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
c0105849:	8b 45 10             	mov    0x10(%ebp),%eax
c010584c:	8d 50 01             	lea    0x1(%eax),%edx
c010584f:	89 55 10             	mov    %edx,0x10(%ebp)
c0105852:	0f b6 00             	movzbl (%eax),%eax
c0105855:	0f b6 d8             	movzbl %al,%ebx
c0105858:	8d 43 dd             	lea    -0x23(%ebx),%eax
c010585b:	83 f8 55             	cmp    $0x55,%eax
c010585e:	0f 87 37 03 00 00    	ja     c0105b9b <vprintfmt+0x3a5>
c0105864:	8b 04 85 60 6e 10 c0 	mov    -0x3fef91a0(,%eax,4),%eax
c010586b:	ff e0                	jmp    *%eax

        // flag to pad on the right
        case '-':
            padc = '-';
c010586d:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
            goto reswitch;
c0105871:	eb d6                	jmp    c0105849 <vprintfmt+0x53>

        // flag to pad with 0's instead of spaces
        case '0':
            padc = '0';
c0105873:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
            goto reswitch;
c0105877:	eb d0                	jmp    c0105849 <vprintfmt+0x53>

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
c0105879:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
                precision = precision * 10 + ch - '0';
c0105880:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0105883:	89 d0                	mov    %edx,%eax
c0105885:	c1 e0 02             	shl    $0x2,%eax
c0105888:	01 d0                	add    %edx,%eax
c010588a:	01 c0                	add    %eax,%eax
c010588c:	01 d8                	add    %ebx,%eax
c010588e:	83 e8 30             	sub    $0x30,%eax
c0105891:	89 45 e4             	mov    %eax,-0x1c(%ebp)
                ch = *fmt;
c0105894:	8b 45 10             	mov    0x10(%ebp),%eax
c0105897:	0f b6 00             	movzbl (%eax),%eax
c010589a:	0f be d8             	movsbl %al,%ebx
                if (ch < '0' || ch > '9') {
c010589d:	83 fb 2f             	cmp    $0x2f,%ebx
c01058a0:	7e 38                	jle    c01058da <vprintfmt+0xe4>
c01058a2:	83 fb 39             	cmp    $0x39,%ebx
c01058a5:	7f 33                	jg     c01058da <vprintfmt+0xe4>
            padc = '0';
            goto reswitch;

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
c01058a7:	ff 45 10             	incl   0x10(%ebp)
                precision = precision * 10 + ch - '0';
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
c01058aa:	eb d4                	jmp    c0105880 <vprintfmt+0x8a>
            goto process_precision;

        case '*':
            precision = va_arg(ap, int);
c01058ac:	8b 45 14             	mov    0x14(%ebp),%eax
c01058af:	8d 50 04             	lea    0x4(%eax),%edx
c01058b2:	89 55 14             	mov    %edx,0x14(%ebp)
c01058b5:	8b 00                	mov    (%eax),%eax
c01058b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            goto process_precision;
c01058ba:	eb 1f                	jmp    c01058db <vprintfmt+0xe5>

        case '.':
            if (width < 0)
c01058bc:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c01058c0:	79 87                	jns    c0105849 <vprintfmt+0x53>
                width = 0;
c01058c2:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
            goto reswitch;
c01058c9:	e9 7b ff ff ff       	jmp    c0105849 <vprintfmt+0x53>

        case '#':
            altflag = 1;
c01058ce:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
            goto reswitch;
c01058d5:	e9 6f ff ff ff       	jmp    c0105849 <vprintfmt+0x53>
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
            goto process_precision;
c01058da:	90                   	nop
        case '#':
            altflag = 1;
            goto reswitch;

        process_precision:
            if (width < 0)
c01058db:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c01058df:	0f 89 64 ff ff ff    	jns    c0105849 <vprintfmt+0x53>
                width = precision, precision = -1;
c01058e5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01058e8:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01058eb:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
            goto reswitch;
c01058f2:	e9 52 ff ff ff       	jmp    c0105849 <vprintfmt+0x53>

        // long flag (doubled for long long)
        case 'l':
            lflag ++;
c01058f7:	ff 45 e0             	incl   -0x20(%ebp)
            goto reswitch;
c01058fa:	e9 4a ff ff ff       	jmp    c0105849 <vprintfmt+0x53>

        // character
        case 'c':
            putch(va_arg(ap, int), putdat);
c01058ff:	8b 45 14             	mov    0x14(%ebp),%eax
c0105902:	8d 50 04             	lea    0x4(%eax),%edx
c0105905:	89 55 14             	mov    %edx,0x14(%ebp)
c0105908:	8b 00                	mov    (%eax),%eax
c010590a:	8b 55 0c             	mov    0xc(%ebp),%edx
c010590d:	89 54 24 04          	mov    %edx,0x4(%esp)
c0105911:	89 04 24             	mov    %eax,(%esp)
c0105914:	8b 45 08             	mov    0x8(%ebp),%eax
c0105917:	ff d0                	call   *%eax
            break;
c0105919:	e9 a4 02 00 00       	jmp    c0105bc2 <vprintfmt+0x3cc>

        // error message
        case 'e':
            err = va_arg(ap, int);
c010591e:	8b 45 14             	mov    0x14(%ebp),%eax
c0105921:	8d 50 04             	lea    0x4(%eax),%edx
c0105924:	89 55 14             	mov    %edx,0x14(%ebp)
c0105927:	8b 18                	mov    (%eax),%ebx
            if (err < 0) {
c0105929:	85 db                	test   %ebx,%ebx
c010592b:	79 02                	jns    c010592f <vprintfmt+0x139>
                err = -err;
c010592d:	f7 db                	neg    %ebx
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
c010592f:	83 fb 06             	cmp    $0x6,%ebx
c0105932:	7f 0b                	jg     c010593f <vprintfmt+0x149>
c0105934:	8b 34 9d 20 6e 10 c0 	mov    -0x3fef91e0(,%ebx,4),%esi
c010593b:	85 f6                	test   %esi,%esi
c010593d:	75 23                	jne    c0105962 <vprintfmt+0x16c>
                printfmt(putch, putdat, "error %d", err);
c010593f:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
c0105943:	c7 44 24 08 4d 6e 10 	movl   $0xc0106e4d,0x8(%esp)
c010594a:	c0 
c010594b:	8b 45 0c             	mov    0xc(%ebp),%eax
c010594e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105952:	8b 45 08             	mov    0x8(%ebp),%eax
c0105955:	89 04 24             	mov    %eax,(%esp)
c0105958:	e8 6a fe ff ff       	call   c01057c7 <printfmt>
            }
            else {
                printfmt(putch, putdat, "%s", p);
            }
            break;
c010595d:	e9 60 02 00 00       	jmp    c0105bc2 <vprintfmt+0x3cc>
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
                printfmt(putch, putdat, "error %d", err);
            }
            else {
                printfmt(putch, putdat, "%s", p);
c0105962:	89 74 24 0c          	mov    %esi,0xc(%esp)
c0105966:	c7 44 24 08 56 6e 10 	movl   $0xc0106e56,0x8(%esp)
c010596d:	c0 
c010596e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105971:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105975:	8b 45 08             	mov    0x8(%ebp),%eax
c0105978:	89 04 24             	mov    %eax,(%esp)
c010597b:	e8 47 fe ff ff       	call   c01057c7 <printfmt>
            }
            break;
c0105980:	e9 3d 02 00 00       	jmp    c0105bc2 <vprintfmt+0x3cc>

        // string
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
c0105985:	8b 45 14             	mov    0x14(%ebp),%eax
c0105988:	8d 50 04             	lea    0x4(%eax),%edx
c010598b:	89 55 14             	mov    %edx,0x14(%ebp)
c010598e:	8b 30                	mov    (%eax),%esi
c0105990:	85 f6                	test   %esi,%esi
c0105992:	75 05                	jne    c0105999 <vprintfmt+0x1a3>
                p = "(null)";
c0105994:	be 59 6e 10 c0       	mov    $0xc0106e59,%esi
            }
            if (width > 0 && padc != '-') {
c0105999:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c010599d:	7e 76                	jle    c0105a15 <vprintfmt+0x21f>
c010599f:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
c01059a3:	74 70                	je     c0105a15 <vprintfmt+0x21f>
                for (width -= strnlen(p, precision); width > 0; width --) {
c01059a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01059a8:	89 44 24 04          	mov    %eax,0x4(%esp)
c01059ac:	89 34 24             	mov    %esi,(%esp)
c01059af:	e8 f6 f7 ff ff       	call   c01051aa <strnlen>
c01059b4:	8b 55 e8             	mov    -0x18(%ebp),%edx
c01059b7:	29 c2                	sub    %eax,%edx
c01059b9:	89 d0                	mov    %edx,%eax
c01059bb:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01059be:	eb 16                	jmp    c01059d6 <vprintfmt+0x1e0>
                    putch(padc, putdat);
c01059c0:	0f be 45 db          	movsbl -0x25(%ebp),%eax
c01059c4:	8b 55 0c             	mov    0xc(%ebp),%edx
c01059c7:	89 54 24 04          	mov    %edx,0x4(%esp)
c01059cb:	89 04 24             	mov    %eax,(%esp)
c01059ce:	8b 45 08             	mov    0x8(%ebp),%eax
c01059d1:	ff d0                	call   *%eax
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
                p = "(null)";
            }
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
c01059d3:	ff 4d e8             	decl   -0x18(%ebp)
c01059d6:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c01059da:	7f e4                	jg     c01059c0 <vprintfmt+0x1ca>
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
c01059dc:	eb 37                	jmp    c0105a15 <vprintfmt+0x21f>
                if (altflag && (ch < ' ' || ch > '~')) {
c01059de:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c01059e2:	74 1f                	je     c0105a03 <vprintfmt+0x20d>
c01059e4:	83 fb 1f             	cmp    $0x1f,%ebx
c01059e7:	7e 05                	jle    c01059ee <vprintfmt+0x1f8>
c01059e9:	83 fb 7e             	cmp    $0x7e,%ebx
c01059ec:	7e 15                	jle    c0105a03 <vprintfmt+0x20d>
                    putch('?', putdat);
c01059ee:	8b 45 0c             	mov    0xc(%ebp),%eax
c01059f1:	89 44 24 04          	mov    %eax,0x4(%esp)
c01059f5:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
c01059fc:	8b 45 08             	mov    0x8(%ebp),%eax
c01059ff:	ff d0                	call   *%eax
c0105a01:	eb 0f                	jmp    c0105a12 <vprintfmt+0x21c>
                }
                else {
                    putch(ch, putdat);
c0105a03:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105a06:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105a0a:	89 1c 24             	mov    %ebx,(%esp)
c0105a0d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105a10:	ff d0                	call   *%eax
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
c0105a12:	ff 4d e8             	decl   -0x18(%ebp)
c0105a15:	89 f0                	mov    %esi,%eax
c0105a17:	8d 70 01             	lea    0x1(%eax),%esi
c0105a1a:	0f b6 00             	movzbl (%eax),%eax
c0105a1d:	0f be d8             	movsbl %al,%ebx
c0105a20:	85 db                	test   %ebx,%ebx
c0105a22:	74 27                	je     c0105a4b <vprintfmt+0x255>
c0105a24:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0105a28:	78 b4                	js     c01059de <vprintfmt+0x1e8>
c0105a2a:	ff 4d e4             	decl   -0x1c(%ebp)
c0105a2d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0105a31:	79 ab                	jns    c01059de <vprintfmt+0x1e8>
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
c0105a33:	eb 16                	jmp    c0105a4b <vprintfmt+0x255>
                putch(' ', putdat);
c0105a35:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105a38:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105a3c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
c0105a43:	8b 45 08             	mov    0x8(%ebp),%eax
c0105a46:	ff d0                	call   *%eax
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
c0105a48:	ff 4d e8             	decl   -0x18(%ebp)
c0105a4b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0105a4f:	7f e4                	jg     c0105a35 <vprintfmt+0x23f>
                putch(' ', putdat);
            }
            break;
c0105a51:	e9 6c 01 00 00       	jmp    c0105bc2 <vprintfmt+0x3cc>

        // (signed) decimal
        case 'd':
            num = getint(&ap, lflag);
c0105a56:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105a59:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105a5d:	8d 45 14             	lea    0x14(%ebp),%eax
c0105a60:	89 04 24             	mov    %eax,(%esp)
c0105a63:	e8 18 fd ff ff       	call   c0105780 <getint>
c0105a68:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105a6b:	89 55 f4             	mov    %edx,-0xc(%ebp)
            if ((long long)num < 0) {
c0105a6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105a71:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105a74:	85 d2                	test   %edx,%edx
c0105a76:	79 26                	jns    c0105a9e <vprintfmt+0x2a8>
                putch('-', putdat);
c0105a78:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105a7b:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105a7f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
c0105a86:	8b 45 08             	mov    0x8(%ebp),%eax
c0105a89:	ff d0                	call   *%eax
                num = -(long long)num;
c0105a8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105a8e:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105a91:	f7 d8                	neg    %eax
c0105a93:	83 d2 00             	adc    $0x0,%edx
c0105a96:	f7 da                	neg    %edx
c0105a98:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105a9b:	89 55 f4             	mov    %edx,-0xc(%ebp)
            }
            base = 10;
c0105a9e:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
c0105aa5:	e9 a8 00 00 00       	jmp    c0105b52 <vprintfmt+0x35c>

        // unsigned decimal
        case 'u':
            num = getuint(&ap, lflag);
c0105aaa:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105aad:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105ab1:	8d 45 14             	lea    0x14(%ebp),%eax
c0105ab4:	89 04 24             	mov    %eax,(%esp)
c0105ab7:	e8 75 fc ff ff       	call   c0105731 <getuint>
c0105abc:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105abf:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 10;
c0105ac2:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
c0105ac9:	e9 84 00 00 00       	jmp    c0105b52 <vprintfmt+0x35c>

        // (unsigned) octal
        case 'o':
            num = getuint(&ap, lflag);
c0105ace:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105ad1:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105ad5:	8d 45 14             	lea    0x14(%ebp),%eax
c0105ad8:	89 04 24             	mov    %eax,(%esp)
c0105adb:	e8 51 fc ff ff       	call   c0105731 <getuint>
c0105ae0:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105ae3:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 8;
c0105ae6:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
            goto number;
c0105aed:	eb 63                	jmp    c0105b52 <vprintfmt+0x35c>

        // pointer
        case 'p':
            putch('0', putdat);
c0105aef:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105af2:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105af6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
c0105afd:	8b 45 08             	mov    0x8(%ebp),%eax
c0105b00:	ff d0                	call   *%eax
            putch('x', putdat);
c0105b02:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105b05:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105b09:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
c0105b10:	8b 45 08             	mov    0x8(%ebp),%eax
c0105b13:	ff d0                	call   *%eax
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
c0105b15:	8b 45 14             	mov    0x14(%ebp),%eax
c0105b18:	8d 50 04             	lea    0x4(%eax),%edx
c0105b1b:	89 55 14             	mov    %edx,0x14(%ebp)
c0105b1e:	8b 00                	mov    (%eax),%eax
c0105b20:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105b23:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
            base = 16;
c0105b2a:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
            goto number;
c0105b31:	eb 1f                	jmp    c0105b52 <vprintfmt+0x35c>

        // (unsigned) hexadecimal
        case 'x':
            num = getuint(&ap, lflag);
c0105b33:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105b36:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105b3a:	8d 45 14             	lea    0x14(%ebp),%eax
c0105b3d:	89 04 24             	mov    %eax,(%esp)
c0105b40:	e8 ec fb ff ff       	call   c0105731 <getuint>
c0105b45:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105b48:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 16;
c0105b4b:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
        number:
            printnum(putch, putdat, num, base, width, padc);
c0105b52:	0f be 55 db          	movsbl -0x25(%ebp),%edx
c0105b56:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105b59:	89 54 24 18          	mov    %edx,0x18(%esp)
c0105b5d:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0105b60:	89 54 24 14          	mov    %edx,0x14(%esp)
c0105b64:	89 44 24 10          	mov    %eax,0x10(%esp)
c0105b68:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105b6b:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105b6e:	89 44 24 08          	mov    %eax,0x8(%esp)
c0105b72:	89 54 24 0c          	mov    %edx,0xc(%esp)
c0105b76:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105b79:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105b7d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105b80:	89 04 24             	mov    %eax,(%esp)
c0105b83:	e8 a4 fa ff ff       	call   c010562c <printnum>
            break;
c0105b88:	eb 38                	jmp    c0105bc2 <vprintfmt+0x3cc>

        // escaped '%' character
        case '%':
            putch(ch, putdat);
c0105b8a:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105b8d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105b91:	89 1c 24             	mov    %ebx,(%esp)
c0105b94:	8b 45 08             	mov    0x8(%ebp),%eax
c0105b97:	ff d0                	call   *%eax
            break;
c0105b99:	eb 27                	jmp    c0105bc2 <vprintfmt+0x3cc>

        // unrecognized escape sequence - just print it literally
        default:
            putch('%', putdat);
c0105b9b:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105b9e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105ba2:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
c0105ba9:	8b 45 08             	mov    0x8(%ebp),%eax
c0105bac:	ff d0                	call   *%eax
            for (fmt --; fmt[-1] != '%'; fmt --)
c0105bae:	ff 4d 10             	decl   0x10(%ebp)
c0105bb1:	eb 03                	jmp    c0105bb6 <vprintfmt+0x3c0>
c0105bb3:	ff 4d 10             	decl   0x10(%ebp)
c0105bb6:	8b 45 10             	mov    0x10(%ebp),%eax
c0105bb9:	48                   	dec    %eax
c0105bba:	0f b6 00             	movzbl (%eax),%eax
c0105bbd:	3c 25                	cmp    $0x25,%al
c0105bbf:	75 f2                	jne    c0105bb3 <vprintfmt+0x3bd>
                /* do nothing */;
            break;
c0105bc1:	90                   	nop
        }
    }
c0105bc2:	e9 37 fc ff ff       	jmp    c01057fe <vprintfmt+0x8>
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
            if (ch == '\0') {
                return;
c0105bc7:	90                   	nop
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
c0105bc8:	83 c4 40             	add    $0x40,%esp
c0105bcb:	5b                   	pop    %ebx
c0105bcc:	5e                   	pop    %esi
c0105bcd:	5d                   	pop    %ebp
c0105bce:	c3                   	ret    

c0105bcf <sprintputch>:
 * sprintputch - 'print' a single character in a buffer
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
c0105bcf:	55                   	push   %ebp
c0105bd0:	89 e5                	mov    %esp,%ebp
    b->cnt ++;
c0105bd2:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105bd5:	8b 40 08             	mov    0x8(%eax),%eax
c0105bd8:	8d 50 01             	lea    0x1(%eax),%edx
c0105bdb:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105bde:	89 50 08             	mov    %edx,0x8(%eax)
    if (b->buf < b->ebuf) {
c0105be1:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105be4:	8b 10                	mov    (%eax),%edx
c0105be6:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105be9:	8b 40 04             	mov    0x4(%eax),%eax
c0105bec:	39 c2                	cmp    %eax,%edx
c0105bee:	73 12                	jae    c0105c02 <sprintputch+0x33>
        *b->buf ++ = ch;
c0105bf0:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105bf3:	8b 00                	mov    (%eax),%eax
c0105bf5:	8d 48 01             	lea    0x1(%eax),%ecx
c0105bf8:	8b 55 0c             	mov    0xc(%ebp),%edx
c0105bfb:	89 0a                	mov    %ecx,(%edx)
c0105bfd:	8b 55 08             	mov    0x8(%ebp),%edx
c0105c00:	88 10                	mov    %dl,(%eax)
    }
}
c0105c02:	90                   	nop
c0105c03:	5d                   	pop    %ebp
c0105c04:	c3                   	ret    

c0105c05 <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
c0105c05:	55                   	push   %ebp
c0105c06:	89 e5                	mov    %esp,%ebp
c0105c08:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
c0105c0b:	8d 45 14             	lea    0x14(%ebp),%eax
c0105c0e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vsnprintf(str, size, fmt, ap);
c0105c11:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105c14:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0105c18:	8b 45 10             	mov    0x10(%ebp),%eax
c0105c1b:	89 44 24 08          	mov    %eax,0x8(%esp)
c0105c1f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105c22:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105c26:	8b 45 08             	mov    0x8(%ebp),%eax
c0105c29:	89 04 24             	mov    %eax,(%esp)
c0105c2c:	e8 08 00 00 00       	call   c0105c39 <vsnprintf>
c0105c31:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
c0105c34:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0105c37:	c9                   	leave  
c0105c38:	c3                   	ret    

c0105c39 <vsnprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
c0105c39:	55                   	push   %ebp
c0105c3a:	89 e5                	mov    %esp,%ebp
c0105c3c:	83 ec 28             	sub    $0x28,%esp
    struct sprintbuf b = {str, str + size - 1, 0};
c0105c3f:	8b 45 08             	mov    0x8(%ebp),%eax
c0105c42:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105c45:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105c48:	8d 50 ff             	lea    -0x1(%eax),%edx
c0105c4b:	8b 45 08             	mov    0x8(%ebp),%eax
c0105c4e:	01 d0                	add    %edx,%eax
c0105c50:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105c53:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if (str == NULL || b.buf > b.ebuf) {
c0105c5a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0105c5e:	74 0a                	je     c0105c6a <vsnprintf+0x31>
c0105c60:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0105c63:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105c66:	39 c2                	cmp    %eax,%edx
c0105c68:	76 07                	jbe    c0105c71 <vsnprintf+0x38>
        return -E_INVAL;
c0105c6a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
c0105c6f:	eb 2a                	jmp    c0105c9b <vsnprintf+0x62>
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
c0105c71:	8b 45 14             	mov    0x14(%ebp),%eax
c0105c74:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0105c78:	8b 45 10             	mov    0x10(%ebp),%eax
c0105c7b:	89 44 24 08          	mov    %eax,0x8(%esp)
c0105c7f:	8d 45 ec             	lea    -0x14(%ebp),%eax
c0105c82:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105c86:	c7 04 24 cf 5b 10 c0 	movl   $0xc0105bcf,(%esp)
c0105c8d:	e8 64 fb ff ff       	call   c01057f6 <vprintfmt>
    // null terminate the buffer
    *b.buf = '\0';
c0105c92:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105c95:	c6 00 00             	movb   $0x0,(%eax)
    return b.cnt;
c0105c98:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0105c9b:	c9                   	leave  
c0105c9c:	c3                   	ret    
