
bin/kernel_nopage:     file format elf32-i386


Disassembly of section .text:

00100000 <kern_entry>:

.text
.globl kern_entry
kern_entry:
    # load pa of boot pgdir
    movl $REALLOC(__boot_pgdir), %eax
  100000:	b8 00 80 11 40       	mov    $0x40118000,%eax
    movl %eax, %cr3
  100005:	0f 22 d8             	mov    %eax,%cr3

    # enable paging
    movl %cr0, %eax
  100008:	0f 20 c0             	mov    %cr0,%eax
    orl $(CR0_PE | CR0_PG | CR0_AM | CR0_WP | CR0_NE | CR0_TS | CR0_EM | CR0_MP), %eax
  10000b:	0d 2f 00 05 80       	or     $0x8005002f,%eax
    andl $~(CR0_TS | CR0_EM), %eax
  100010:	83 e0 f3             	and    $0xfffffff3,%eax
    movl %eax, %cr0
  100013:	0f 22 c0             	mov    %eax,%cr0

    # update eip
    # now, eip = 0x1.....
    leal next, %eax
  100016:	8d 05 1e 00 10 00    	lea    0x10001e,%eax
    # set eip = KERNBASE + 0x1.....
    jmp *%eax
  10001c:	ff e0                	jmp    *%eax

0010001e <next>:
next:

    # unmap va 0 ~ 4M, it's temporary mapping
    xorl %eax, %eax
  10001e:	31 c0                	xor    %eax,%eax
    movl %eax, __boot_pgdir
  100020:	a3 00 80 11 00       	mov    %eax,0x118000

    # set ebp, esp
    movl $0x0, %ebp
  100025:	bd 00 00 00 00       	mov    $0x0,%ebp
    # the kernel stack region is from bootstack -- bootstacktop,
    # the kernel stack size is KSTACKSIZE (8KB)defined in memlayout.h
    movl $bootstacktop, %esp
  10002a:	bc 00 70 11 00       	mov    $0x117000,%esp
    # now kernel stack is ready , call the first C function
    call kern_init
  10002f:	e8 02 00 00 00       	call   100036 <kern_init>

00100034 <spin>:

# should never get here
spin:
    jmp spin
  100034:	eb fe                	jmp    100034 <spin>

00100036 <kern_init>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);
static void lab1_switch_test(void);

int
kern_init(void) {
  100036:	55                   	push   %ebp
  100037:	89 e5                	mov    %esp,%ebp
  100039:	83 ec 28             	sub    $0x28,%esp
    extern char edata[], end[];
    memset(edata, 0, end - edata);
  10003c:	ba 28 af 11 00       	mov    $0x11af28,%edx
  100041:	b8 36 7a 11 00       	mov    $0x117a36,%eax
  100046:	29 c2                	sub    %eax,%edx
  100048:	89 d0                	mov    %edx,%eax
  10004a:	89 44 24 08          	mov    %eax,0x8(%esp)
  10004e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100055:	00 
  100056:	c7 04 24 36 7a 11 00 	movl   $0x117a36,(%esp)
  10005d:	e8 41 54 00 00       	call   1054a3 <memset>

    cons_init();                // init the console
  100062:	e8 be 14 00 00       	call   101525 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
  100067:	c7 45 f4 a0 5c 10 00 	movl   $0x105ca0,-0xc(%ebp)
    cprintf("%s\n\n", message);
  10006e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100071:	89 44 24 04          	mov    %eax,0x4(%esp)
  100075:	c7 04 24 bc 5c 10 00 	movl   $0x105cbc,(%esp)
  10007c:	e8 11 02 00 00       	call   100292 <cprintf>

    print_kerninfo();
  100081:	e8 b2 08 00 00       	call   100938 <print_kerninfo>

    grade_backtrace();
  100086:	e8 89 00 00 00       	call   100114 <grade_backtrace>

    pmm_init();                 // init physical memory management
  10008b:	e8 86 2e 00 00       	call   102f16 <pmm_init>

    pic_init();                 // init interrupt controller
  100090:	e8 f4 15 00 00       	call   101689 <pic_init>
    idt_init();                 // init interrupt descriptor table
  100095:	e8 4d 17 00 00       	call   1017e7 <idt_init>

    clock_init();               // init clock interrupt
  10009a:	e8 39 0c 00 00       	call   100cd8 <clock_init>
    intr_enable();              // enable irq interrupt
  10009f:	e8 18 17 00 00       	call   1017bc <intr_enable>
    //LAB1: CAHLLENGE 1 If you try to do it, uncomment lab1_switch_test()
    // user/kernel mode switch test
    //lab1_switch_test();

    /* do nothing */
    while (1);
  1000a4:	eb fe                	jmp    1000a4 <kern_init+0x6e>

001000a6 <grade_backtrace2>:
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
  1000a6:	55                   	push   %ebp
  1000a7:	89 e5                	mov    %esp,%ebp
  1000a9:	83 ec 18             	sub    $0x18,%esp
    mon_backtrace(0, NULL, NULL);
  1000ac:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1000b3:	00 
  1000b4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000bb:	00 
  1000bc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1000c3:	e8 fe 0b 00 00       	call   100cc6 <mon_backtrace>
}
  1000c8:	90                   	nop
  1000c9:	c9                   	leave  
  1000ca:	c3                   	ret    

001000cb <grade_backtrace1>:

void __attribute__((noinline))
grade_backtrace1(int arg0, int arg1) {
  1000cb:	55                   	push   %ebp
  1000cc:	89 e5                	mov    %esp,%ebp
  1000ce:	53                   	push   %ebx
  1000cf:	83 ec 14             	sub    $0x14,%esp
    grade_backtrace2(arg0, (int)&arg0, arg1, (int)&arg1);
  1000d2:	8d 4d 0c             	lea    0xc(%ebp),%ecx
  1000d5:	8b 55 0c             	mov    0xc(%ebp),%edx
  1000d8:	8d 5d 08             	lea    0x8(%ebp),%ebx
  1000db:	8b 45 08             	mov    0x8(%ebp),%eax
  1000de:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  1000e2:	89 54 24 08          	mov    %edx,0x8(%esp)
  1000e6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  1000ea:	89 04 24             	mov    %eax,(%esp)
  1000ed:	e8 b4 ff ff ff       	call   1000a6 <grade_backtrace2>
}
  1000f2:	90                   	nop
  1000f3:	83 c4 14             	add    $0x14,%esp
  1000f6:	5b                   	pop    %ebx
  1000f7:	5d                   	pop    %ebp
  1000f8:	c3                   	ret    

001000f9 <grade_backtrace0>:

void __attribute__((noinline))
grade_backtrace0(int arg0, int arg1, int arg2) {
  1000f9:	55                   	push   %ebp
  1000fa:	89 e5                	mov    %esp,%ebp
  1000fc:	83 ec 18             	sub    $0x18,%esp
    grade_backtrace1(arg0, arg2);
  1000ff:	8b 45 10             	mov    0x10(%ebp),%eax
  100102:	89 44 24 04          	mov    %eax,0x4(%esp)
  100106:	8b 45 08             	mov    0x8(%ebp),%eax
  100109:	89 04 24             	mov    %eax,(%esp)
  10010c:	e8 ba ff ff ff       	call   1000cb <grade_backtrace1>
}
  100111:	90                   	nop
  100112:	c9                   	leave  
  100113:	c3                   	ret    

00100114 <grade_backtrace>:

void
grade_backtrace(void) {
  100114:	55                   	push   %ebp
  100115:	89 e5                	mov    %esp,%ebp
  100117:	83 ec 18             	sub    $0x18,%esp
    grade_backtrace0(0, (int)kern_init, 0xffff0000);
  10011a:	b8 36 00 10 00       	mov    $0x100036,%eax
  10011f:	c7 44 24 08 00 00 ff 	movl   $0xffff0000,0x8(%esp)
  100126:	ff 
  100127:	89 44 24 04          	mov    %eax,0x4(%esp)
  10012b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  100132:	e8 c2 ff ff ff       	call   1000f9 <grade_backtrace0>
}
  100137:	90                   	nop
  100138:	c9                   	leave  
  100139:	c3                   	ret    

0010013a <lab1_print_cur_status>:

static void
lab1_print_cur_status(void) {
  10013a:	55                   	push   %ebp
  10013b:	89 e5                	mov    %esp,%ebp
  10013d:	83 ec 28             	sub    $0x28,%esp
    static int round = 0;
    uint16_t reg1, reg2, reg3, reg4;
    asm volatile (
  100140:	8c 4d f6             	mov    %cs,-0xa(%ebp)
  100143:	8c 5d f4             	mov    %ds,-0xc(%ebp)
  100146:	8c 45 f2             	mov    %es,-0xe(%ebp)
  100149:	8c 55 f0             	mov    %ss,-0x10(%ebp)
            "mov %%cs, %0;"
            "mov %%ds, %1;"
            "mov %%es, %2;"
            "mov %%ss, %3;"
            : "=m"(reg1), "=m"(reg2), "=m"(reg3), "=m"(reg4));
    cprintf("%d: @ring %d\n", round, reg1 & 3);
  10014c:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  100150:	83 e0 03             	and    $0x3,%eax
  100153:	89 c2                	mov    %eax,%edx
  100155:	a1 00 a0 11 00       	mov    0x11a000,%eax
  10015a:	89 54 24 08          	mov    %edx,0x8(%esp)
  10015e:	89 44 24 04          	mov    %eax,0x4(%esp)
  100162:	c7 04 24 c1 5c 10 00 	movl   $0x105cc1,(%esp)
  100169:	e8 24 01 00 00       	call   100292 <cprintf>
    cprintf("%d:  cs = %x\n", round, reg1);
  10016e:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  100172:	89 c2                	mov    %eax,%edx
  100174:	a1 00 a0 11 00       	mov    0x11a000,%eax
  100179:	89 54 24 08          	mov    %edx,0x8(%esp)
  10017d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100181:	c7 04 24 cf 5c 10 00 	movl   $0x105ccf,(%esp)
  100188:	e8 05 01 00 00       	call   100292 <cprintf>
    cprintf("%d:  ds = %x\n", round, reg2);
  10018d:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
  100191:	89 c2                	mov    %eax,%edx
  100193:	a1 00 a0 11 00       	mov    0x11a000,%eax
  100198:	89 54 24 08          	mov    %edx,0x8(%esp)
  10019c:	89 44 24 04          	mov    %eax,0x4(%esp)
  1001a0:	c7 04 24 dd 5c 10 00 	movl   $0x105cdd,(%esp)
  1001a7:	e8 e6 00 00 00       	call   100292 <cprintf>
    cprintf("%d:  es = %x\n", round, reg3);
  1001ac:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
  1001b0:	89 c2                	mov    %eax,%edx
  1001b2:	a1 00 a0 11 00       	mov    0x11a000,%eax
  1001b7:	89 54 24 08          	mov    %edx,0x8(%esp)
  1001bb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1001bf:	c7 04 24 eb 5c 10 00 	movl   $0x105ceb,(%esp)
  1001c6:	e8 c7 00 00 00       	call   100292 <cprintf>
    cprintf("%d:  ss = %x\n", round, reg4);
  1001cb:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
  1001cf:	89 c2                	mov    %eax,%edx
  1001d1:	a1 00 a0 11 00       	mov    0x11a000,%eax
  1001d6:	89 54 24 08          	mov    %edx,0x8(%esp)
  1001da:	89 44 24 04          	mov    %eax,0x4(%esp)
  1001de:	c7 04 24 f9 5c 10 00 	movl   $0x105cf9,(%esp)
  1001e5:	e8 a8 00 00 00       	call   100292 <cprintf>
    round ++;
  1001ea:	a1 00 a0 11 00       	mov    0x11a000,%eax
  1001ef:	40                   	inc    %eax
  1001f0:	a3 00 a0 11 00       	mov    %eax,0x11a000
}
  1001f5:	90                   	nop
  1001f6:	c9                   	leave  
  1001f7:	c3                   	ret    

001001f8 <lab1_switch_to_user>:

static void
lab1_switch_to_user(void) {
  1001f8:	55                   	push   %ebp
  1001f9:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 : TODO
}
  1001fb:	90                   	nop
  1001fc:	5d                   	pop    %ebp
  1001fd:	c3                   	ret    

001001fe <lab1_switch_to_kernel>:

static void
lab1_switch_to_kernel(void) {
  1001fe:	55                   	push   %ebp
  1001ff:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 :  TODO
}
  100201:	90                   	nop
  100202:	5d                   	pop    %ebp
  100203:	c3                   	ret    

00100204 <lab1_switch_test>:

static void
lab1_switch_test(void) {
  100204:	55                   	push   %ebp
  100205:	89 e5                	mov    %esp,%ebp
  100207:	83 ec 18             	sub    $0x18,%esp
    lab1_print_cur_status();
  10020a:	e8 2b ff ff ff       	call   10013a <lab1_print_cur_status>
    cprintf("+++ switch to  user  mode +++\n");
  10020f:	c7 04 24 08 5d 10 00 	movl   $0x105d08,(%esp)
  100216:	e8 77 00 00 00       	call   100292 <cprintf>
    lab1_switch_to_user();
  10021b:	e8 d8 ff ff ff       	call   1001f8 <lab1_switch_to_user>
    lab1_print_cur_status();
  100220:	e8 15 ff ff ff       	call   10013a <lab1_print_cur_status>
    cprintf("+++ switch to kernel mode +++\n");
  100225:	c7 04 24 28 5d 10 00 	movl   $0x105d28,(%esp)
  10022c:	e8 61 00 00 00       	call   100292 <cprintf>
    lab1_switch_to_kernel();
  100231:	e8 c8 ff ff ff       	call   1001fe <lab1_switch_to_kernel>
    lab1_print_cur_status();
  100236:	e8 ff fe ff ff       	call   10013a <lab1_print_cur_status>
}
  10023b:	90                   	nop
  10023c:	c9                   	leave  
  10023d:	c3                   	ret    

0010023e <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  10023e:	55                   	push   %ebp
  10023f:	89 e5                	mov    %esp,%ebp
  100241:	83 ec 18             	sub    $0x18,%esp
    cons_putc(c);
  100244:	8b 45 08             	mov    0x8(%ebp),%eax
  100247:	89 04 24             	mov    %eax,(%esp)
  10024a:	e8 03 13 00 00       	call   101552 <cons_putc>
    (*cnt) ++;
  10024f:	8b 45 0c             	mov    0xc(%ebp),%eax
  100252:	8b 00                	mov    (%eax),%eax
  100254:	8d 50 01             	lea    0x1(%eax),%edx
  100257:	8b 45 0c             	mov    0xc(%ebp),%eax
  10025a:	89 10                	mov    %edx,(%eax)
}
  10025c:	90                   	nop
  10025d:	c9                   	leave  
  10025e:	c3                   	ret    

0010025f <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
  10025f:	55                   	push   %ebp
  100260:	89 e5                	mov    %esp,%ebp
  100262:	83 ec 28             	sub    $0x28,%esp
    int cnt = 0;
  100265:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  10026c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10026f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  100273:	8b 45 08             	mov    0x8(%ebp),%eax
  100276:	89 44 24 08          	mov    %eax,0x8(%esp)
  10027a:	8d 45 f4             	lea    -0xc(%ebp),%eax
  10027d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100281:	c7 04 24 3e 02 10 00 	movl   $0x10023e,(%esp)
  100288:	e8 69 55 00 00       	call   1057f6 <vprintfmt>
    return cnt;
  10028d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100290:	c9                   	leave  
  100291:	c3                   	ret    

00100292 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  100292:	55                   	push   %ebp
  100293:	89 e5                	mov    %esp,%ebp
  100295:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
  100298:	8d 45 0c             	lea    0xc(%ebp),%eax
  10029b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vcprintf(fmt, ap);
  10029e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1002a1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1002a5:	8b 45 08             	mov    0x8(%ebp),%eax
  1002a8:	89 04 24             	mov    %eax,(%esp)
  1002ab:	e8 af ff ff ff       	call   10025f <vcprintf>
  1002b0:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
  1002b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1002b6:	c9                   	leave  
  1002b7:	c3                   	ret    

001002b8 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
  1002b8:	55                   	push   %ebp
  1002b9:	89 e5                	mov    %esp,%ebp
  1002bb:	83 ec 18             	sub    $0x18,%esp
    cons_putc(c);
  1002be:	8b 45 08             	mov    0x8(%ebp),%eax
  1002c1:	89 04 24             	mov    %eax,(%esp)
  1002c4:	e8 89 12 00 00       	call   101552 <cons_putc>
}
  1002c9:	90                   	nop
  1002ca:	c9                   	leave  
  1002cb:	c3                   	ret    

001002cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
  1002cc:	55                   	push   %ebp
  1002cd:	89 e5                	mov    %esp,%ebp
  1002cf:	83 ec 28             	sub    $0x28,%esp
    int cnt = 0;
  1002d2:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    char c;
    while ((c = *str ++) != '\0') {
  1002d9:	eb 13                	jmp    1002ee <cputs+0x22>
        cputch(c, &cnt);
  1002db:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  1002df:	8d 55 f0             	lea    -0x10(%ebp),%edx
  1002e2:	89 54 24 04          	mov    %edx,0x4(%esp)
  1002e6:	89 04 24             	mov    %eax,(%esp)
  1002e9:	e8 50 ff ff ff       	call   10023e <cputch>
 * */
int
cputs(const char *str) {
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
  1002ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1002f1:	8d 50 01             	lea    0x1(%eax),%edx
  1002f4:	89 55 08             	mov    %edx,0x8(%ebp)
  1002f7:	0f b6 00             	movzbl (%eax),%eax
  1002fa:	88 45 f7             	mov    %al,-0x9(%ebp)
  1002fd:	80 7d f7 00          	cmpb   $0x0,-0x9(%ebp)
  100301:	75 d8                	jne    1002db <cputs+0xf>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
  100303:	8d 45 f0             	lea    -0x10(%ebp),%eax
  100306:	89 44 24 04          	mov    %eax,0x4(%esp)
  10030a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
  100311:	e8 28 ff ff ff       	call   10023e <cputch>
    return cnt;
  100316:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  100319:	c9                   	leave  
  10031a:	c3                   	ret    

0010031b <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
  10031b:	55                   	push   %ebp
  10031c:	89 e5                	mov    %esp,%ebp
  10031e:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = cons_getc()) == 0)
  100321:	e8 69 12 00 00       	call   10158f <cons_getc>
  100326:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100329:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10032d:	74 f2                	je     100321 <getchar+0x6>
        /* do nothing */;
    return c;
  10032f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100332:	c9                   	leave  
  100333:	c3                   	ret    

00100334 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
  100334:	55                   	push   %ebp
  100335:	89 e5                	mov    %esp,%ebp
  100337:	83 ec 28             	sub    $0x28,%esp
    if (prompt != NULL) {
  10033a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  10033e:	74 13                	je     100353 <readline+0x1f>
        cprintf("%s", prompt);
  100340:	8b 45 08             	mov    0x8(%ebp),%eax
  100343:	89 44 24 04          	mov    %eax,0x4(%esp)
  100347:	c7 04 24 47 5d 10 00 	movl   $0x105d47,(%esp)
  10034e:	e8 3f ff ff ff       	call   100292 <cprintf>
    }
    int i = 0, c;
  100353:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        c = getchar();
  10035a:	e8 bc ff ff ff       	call   10031b <getchar>
  10035f:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (c < 0) {
  100362:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  100366:	79 07                	jns    10036f <readline+0x3b>
            return NULL;
  100368:	b8 00 00 00 00       	mov    $0x0,%eax
  10036d:	eb 78                	jmp    1003e7 <readline+0xb3>
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
  10036f:	83 7d f0 1f          	cmpl   $0x1f,-0x10(%ebp)
  100373:	7e 28                	jle    10039d <readline+0x69>
  100375:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
  10037c:	7f 1f                	jg     10039d <readline+0x69>
            cputchar(c);
  10037e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100381:	89 04 24             	mov    %eax,(%esp)
  100384:	e8 2f ff ff ff       	call   1002b8 <cputchar>
            buf[i ++] = c;
  100389:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10038c:	8d 50 01             	lea    0x1(%eax),%edx
  10038f:	89 55 f4             	mov    %edx,-0xc(%ebp)
  100392:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100395:	88 90 20 a0 11 00    	mov    %dl,0x11a020(%eax)
  10039b:	eb 45                	jmp    1003e2 <readline+0xae>
        }
        else if (c == '\b' && i > 0) {
  10039d:	83 7d f0 08          	cmpl   $0x8,-0x10(%ebp)
  1003a1:	75 16                	jne    1003b9 <readline+0x85>
  1003a3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1003a7:	7e 10                	jle    1003b9 <readline+0x85>
            cputchar(c);
  1003a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1003ac:	89 04 24             	mov    %eax,(%esp)
  1003af:	e8 04 ff ff ff       	call   1002b8 <cputchar>
            i --;
  1003b4:	ff 4d f4             	decl   -0xc(%ebp)
  1003b7:	eb 29                	jmp    1003e2 <readline+0xae>
        }
        else if (c == '\n' || c == '\r') {
  1003b9:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
  1003bd:	74 06                	je     1003c5 <readline+0x91>
  1003bf:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
  1003c3:	75 95                	jne    10035a <readline+0x26>
            cputchar(c);
  1003c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1003c8:	89 04 24             	mov    %eax,(%esp)
  1003cb:	e8 e8 fe ff ff       	call   1002b8 <cputchar>
            buf[i] = '\0';
  1003d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1003d3:	05 20 a0 11 00       	add    $0x11a020,%eax
  1003d8:	c6 00 00             	movb   $0x0,(%eax)
            return buf;
  1003db:	b8 20 a0 11 00       	mov    $0x11a020,%eax
  1003e0:	eb 05                	jmp    1003e7 <readline+0xb3>
        }
    }
  1003e2:	e9 73 ff ff ff       	jmp    10035a <readline+0x26>
}
  1003e7:	c9                   	leave  
  1003e8:	c3                   	ret    

001003e9 <__panic>:
/* *
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
  1003e9:	55                   	push   %ebp
  1003ea:	89 e5                	mov    %esp,%ebp
  1003ec:	83 ec 28             	sub    $0x28,%esp
    if (is_panic) {
  1003ef:	a1 20 a4 11 00       	mov    0x11a420,%eax
  1003f4:	85 c0                	test   %eax,%eax
  1003f6:	75 5b                	jne    100453 <__panic+0x6a>
        goto panic_dead;
    }
    is_panic = 1;
  1003f8:	c7 05 20 a4 11 00 01 	movl   $0x1,0x11a420
  1003ff:	00 00 00 

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
  100402:	8d 45 14             	lea    0x14(%ebp),%eax
  100405:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
  100408:	8b 45 0c             	mov    0xc(%ebp),%eax
  10040b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10040f:	8b 45 08             	mov    0x8(%ebp),%eax
  100412:	89 44 24 04          	mov    %eax,0x4(%esp)
  100416:	c7 04 24 4a 5d 10 00 	movl   $0x105d4a,(%esp)
  10041d:	e8 70 fe ff ff       	call   100292 <cprintf>
    vcprintf(fmt, ap);
  100422:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100425:	89 44 24 04          	mov    %eax,0x4(%esp)
  100429:	8b 45 10             	mov    0x10(%ebp),%eax
  10042c:	89 04 24             	mov    %eax,(%esp)
  10042f:	e8 2b fe ff ff       	call   10025f <vcprintf>
    cprintf("\n");
  100434:	c7 04 24 66 5d 10 00 	movl   $0x105d66,(%esp)
  10043b:	e8 52 fe ff ff       	call   100292 <cprintf>
    
    cprintf("stack trackback:\n");
  100440:	c7 04 24 68 5d 10 00 	movl   $0x105d68,(%esp)
  100447:	e8 46 fe ff ff       	call   100292 <cprintf>
    print_stackframe();
  10044c:	e8 32 06 00 00       	call   100a83 <print_stackframe>
  100451:	eb 01                	jmp    100454 <__panic+0x6b>
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
        goto panic_dead;
  100453:	90                   	nop
    print_stackframe();
    
    va_end(ap);

panic_dead:
    intr_disable();
  100454:	e8 6a 13 00 00       	call   1017c3 <intr_disable>
    while (1) {
        kmonitor(NULL);
  100459:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  100460:	e8 94 07 00 00       	call   100bf9 <kmonitor>
    }
  100465:	eb f2                	jmp    100459 <__panic+0x70>

00100467 <__warn>:
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
  100467:	55                   	push   %ebp
  100468:	89 e5                	mov    %esp,%ebp
  10046a:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    va_start(ap, fmt);
  10046d:	8d 45 14             	lea    0x14(%ebp),%eax
  100470:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
  100473:	8b 45 0c             	mov    0xc(%ebp),%eax
  100476:	89 44 24 08          	mov    %eax,0x8(%esp)
  10047a:	8b 45 08             	mov    0x8(%ebp),%eax
  10047d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100481:	c7 04 24 7a 5d 10 00 	movl   $0x105d7a,(%esp)
  100488:	e8 05 fe ff ff       	call   100292 <cprintf>
    vcprintf(fmt, ap);
  10048d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100490:	89 44 24 04          	mov    %eax,0x4(%esp)
  100494:	8b 45 10             	mov    0x10(%ebp),%eax
  100497:	89 04 24             	mov    %eax,(%esp)
  10049a:	e8 c0 fd ff ff       	call   10025f <vcprintf>
    cprintf("\n");
  10049f:	c7 04 24 66 5d 10 00 	movl   $0x105d66,(%esp)
  1004a6:	e8 e7 fd ff ff       	call   100292 <cprintf>
    va_end(ap);
}
  1004ab:	90                   	nop
  1004ac:	c9                   	leave  
  1004ad:	c3                   	ret    

001004ae <is_kernel_panic>:

bool
is_kernel_panic(void) {
  1004ae:	55                   	push   %ebp
  1004af:	89 e5                	mov    %esp,%ebp
    return is_panic;
  1004b1:	a1 20 a4 11 00       	mov    0x11a420,%eax
}
  1004b6:	5d                   	pop    %ebp
  1004b7:	c3                   	ret    

001004b8 <stab_binsearch>:
 *      stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
 * will exit setting left = 118, right = 554.
 * */
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
  1004b8:	55                   	push   %ebp
  1004b9:	89 e5                	mov    %esp,%ebp
  1004bb:	83 ec 20             	sub    $0x20,%esp
    int l = *region_left, r = *region_right, any_matches = 0;
  1004be:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004c1:	8b 00                	mov    (%eax),%eax
  1004c3:	89 45 fc             	mov    %eax,-0x4(%ebp)
  1004c6:	8b 45 10             	mov    0x10(%ebp),%eax
  1004c9:	8b 00                	mov    (%eax),%eax
  1004cb:	89 45 f8             	mov    %eax,-0x8(%ebp)
  1004ce:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

    while (l <= r) {
  1004d5:	e9 ca 00 00 00       	jmp    1005a4 <stab_binsearch+0xec>
        int true_m = (l + r) / 2, m = true_m;
  1004da:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1004dd:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1004e0:	01 d0                	add    %edx,%eax
  1004e2:	89 c2                	mov    %eax,%edx
  1004e4:	c1 ea 1f             	shr    $0x1f,%edx
  1004e7:	01 d0                	add    %edx,%eax
  1004e9:	d1 f8                	sar    %eax
  1004eb:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1004ee:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1004f1:	89 45 f0             	mov    %eax,-0x10(%ebp)

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
  1004f4:	eb 03                	jmp    1004f9 <stab_binsearch+0x41>
            m --;
  1004f6:	ff 4d f0             	decl   -0x10(%ebp)

    while (l <= r) {
        int true_m = (l + r) / 2, m = true_m;

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
  1004f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1004fc:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  1004ff:	7c 1f                	jl     100520 <stab_binsearch+0x68>
  100501:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100504:	89 d0                	mov    %edx,%eax
  100506:	01 c0                	add    %eax,%eax
  100508:	01 d0                	add    %edx,%eax
  10050a:	c1 e0 02             	shl    $0x2,%eax
  10050d:	89 c2                	mov    %eax,%edx
  10050f:	8b 45 08             	mov    0x8(%ebp),%eax
  100512:	01 d0                	add    %edx,%eax
  100514:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  100518:	0f b6 c0             	movzbl %al,%eax
  10051b:	3b 45 14             	cmp    0x14(%ebp),%eax
  10051e:	75 d6                	jne    1004f6 <stab_binsearch+0x3e>
            m --;
        }
        if (m < l) {    // no match in [l, m]
  100520:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100523:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  100526:	7d 09                	jge    100531 <stab_binsearch+0x79>
            l = true_m + 1;
  100528:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10052b:	40                   	inc    %eax
  10052c:	89 45 fc             	mov    %eax,-0x4(%ebp)
            continue;
  10052f:	eb 73                	jmp    1005a4 <stab_binsearch+0xec>
        }

        // actual binary search
        any_matches = 1;
  100531:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
        if (stabs[m].n_value < addr) {
  100538:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10053b:	89 d0                	mov    %edx,%eax
  10053d:	01 c0                	add    %eax,%eax
  10053f:	01 d0                	add    %edx,%eax
  100541:	c1 e0 02             	shl    $0x2,%eax
  100544:	89 c2                	mov    %eax,%edx
  100546:	8b 45 08             	mov    0x8(%ebp),%eax
  100549:	01 d0                	add    %edx,%eax
  10054b:	8b 40 08             	mov    0x8(%eax),%eax
  10054e:	3b 45 18             	cmp    0x18(%ebp),%eax
  100551:	73 11                	jae    100564 <stab_binsearch+0xac>
            *region_left = m;
  100553:	8b 45 0c             	mov    0xc(%ebp),%eax
  100556:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100559:	89 10                	mov    %edx,(%eax)
            l = true_m + 1;
  10055b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10055e:	40                   	inc    %eax
  10055f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  100562:	eb 40                	jmp    1005a4 <stab_binsearch+0xec>
        } else if (stabs[m].n_value > addr) {
  100564:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100567:	89 d0                	mov    %edx,%eax
  100569:	01 c0                	add    %eax,%eax
  10056b:	01 d0                	add    %edx,%eax
  10056d:	c1 e0 02             	shl    $0x2,%eax
  100570:	89 c2                	mov    %eax,%edx
  100572:	8b 45 08             	mov    0x8(%ebp),%eax
  100575:	01 d0                	add    %edx,%eax
  100577:	8b 40 08             	mov    0x8(%eax),%eax
  10057a:	3b 45 18             	cmp    0x18(%ebp),%eax
  10057d:	76 14                	jbe    100593 <stab_binsearch+0xdb>
            *region_right = m - 1;
  10057f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100582:	8d 50 ff             	lea    -0x1(%eax),%edx
  100585:	8b 45 10             	mov    0x10(%ebp),%eax
  100588:	89 10                	mov    %edx,(%eax)
            r = m - 1;
  10058a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10058d:	48                   	dec    %eax
  10058e:	89 45 f8             	mov    %eax,-0x8(%ebp)
  100591:	eb 11                	jmp    1005a4 <stab_binsearch+0xec>
        } else {
            // exact match for 'addr', but continue loop to find
            // *region_right
            *region_left = m;
  100593:	8b 45 0c             	mov    0xc(%ebp),%eax
  100596:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100599:	89 10                	mov    %edx,(%eax)
            l = m;
  10059b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10059e:	89 45 fc             	mov    %eax,-0x4(%ebp)
            addr ++;
  1005a1:	ff 45 18             	incl   0x18(%ebp)
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
    int l = *region_left, r = *region_right, any_matches = 0;

    while (l <= r) {
  1005a4:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1005a7:	3b 45 f8             	cmp    -0x8(%ebp),%eax
  1005aa:	0f 8e 2a ff ff ff    	jle    1004da <stab_binsearch+0x22>
            l = m;
            addr ++;
        }
    }

    if (!any_matches) {
  1005b0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1005b4:	75 0f                	jne    1005c5 <stab_binsearch+0x10d>
        *region_right = *region_left - 1;
  1005b6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005b9:	8b 00                	mov    (%eax),%eax
  1005bb:	8d 50 ff             	lea    -0x1(%eax),%edx
  1005be:	8b 45 10             	mov    0x10(%ebp),%eax
  1005c1:	89 10                	mov    %edx,(%eax)
        l = *region_right;
        for (; l > *region_left && stabs[l].n_type != type; l --)
            /* do nothing */;
        *region_left = l;
    }
}
  1005c3:	eb 3e                	jmp    100603 <stab_binsearch+0x14b>
    if (!any_matches) {
        *region_right = *region_left - 1;
    }
    else {
        // find rightmost region containing 'addr'
        l = *region_right;
  1005c5:	8b 45 10             	mov    0x10(%ebp),%eax
  1005c8:	8b 00                	mov    (%eax),%eax
  1005ca:	89 45 fc             	mov    %eax,-0x4(%ebp)
        for (; l > *region_left && stabs[l].n_type != type; l --)
  1005cd:	eb 03                	jmp    1005d2 <stab_binsearch+0x11a>
  1005cf:	ff 4d fc             	decl   -0x4(%ebp)
  1005d2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005d5:	8b 00                	mov    (%eax),%eax
  1005d7:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  1005da:	7d 1f                	jge    1005fb <stab_binsearch+0x143>
  1005dc:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1005df:	89 d0                	mov    %edx,%eax
  1005e1:	01 c0                	add    %eax,%eax
  1005e3:	01 d0                	add    %edx,%eax
  1005e5:	c1 e0 02             	shl    $0x2,%eax
  1005e8:	89 c2                	mov    %eax,%edx
  1005ea:	8b 45 08             	mov    0x8(%ebp),%eax
  1005ed:	01 d0                	add    %edx,%eax
  1005ef:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  1005f3:	0f b6 c0             	movzbl %al,%eax
  1005f6:	3b 45 14             	cmp    0x14(%ebp),%eax
  1005f9:	75 d4                	jne    1005cf <stab_binsearch+0x117>
            /* do nothing */;
        *region_left = l;
  1005fb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005fe:	8b 55 fc             	mov    -0x4(%ebp),%edx
  100601:	89 10                	mov    %edx,(%eax)
    }
}
  100603:	90                   	nop
  100604:	c9                   	leave  
  100605:	c3                   	ret    

00100606 <debuginfo_eip>:
 * the specified instruction address, @addr.  Returns 0 if information
 * was found, and negative if not.  But even if it returns negative it
 * has stored some information into '*info'.
 * */
int
debuginfo_eip(uintptr_t addr, struct eipdebuginfo *info) {
  100606:	55                   	push   %ebp
  100607:	89 e5                	mov    %esp,%ebp
  100609:	83 ec 58             	sub    $0x58,%esp
    const struct stab *stabs, *stab_end;
    const char *stabstr, *stabstr_end;

    info->eip_file = "<unknown>";
  10060c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10060f:	c7 00 98 5d 10 00    	movl   $0x105d98,(%eax)
    info->eip_line = 0;
  100615:	8b 45 0c             	mov    0xc(%ebp),%eax
  100618:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
    info->eip_fn_name = "<unknown>";
  10061f:	8b 45 0c             	mov    0xc(%ebp),%eax
  100622:	c7 40 08 98 5d 10 00 	movl   $0x105d98,0x8(%eax)
    info->eip_fn_namelen = 9;
  100629:	8b 45 0c             	mov    0xc(%ebp),%eax
  10062c:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
    info->eip_fn_addr = addr;
  100633:	8b 45 0c             	mov    0xc(%ebp),%eax
  100636:	8b 55 08             	mov    0x8(%ebp),%edx
  100639:	89 50 10             	mov    %edx,0x10(%eax)
    info->eip_fn_narg = 0;
  10063c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10063f:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

    stabs = __STAB_BEGIN__;
  100646:	c7 45 f4 b8 6f 10 00 	movl   $0x106fb8,-0xc(%ebp)
    stab_end = __STAB_END__;
  10064d:	c7 45 f0 14 1c 11 00 	movl   $0x111c14,-0x10(%ebp)
    stabstr = __STABSTR_BEGIN__;
  100654:	c7 45 ec 15 1c 11 00 	movl   $0x111c15,-0x14(%ebp)
    stabstr_end = __STABSTR_END__;
  10065b:	c7 45 e8 cd 46 11 00 	movl   $0x1146cd,-0x18(%ebp)

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0) {
  100662:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100665:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  100668:	76 0b                	jbe    100675 <debuginfo_eip+0x6f>
  10066a:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10066d:	48                   	dec    %eax
  10066e:	0f b6 00             	movzbl (%eax),%eax
  100671:	84 c0                	test   %al,%al
  100673:	74 0a                	je     10067f <debuginfo_eip+0x79>
        return -1;
  100675:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  10067a:	e9 b7 02 00 00       	jmp    100936 <debuginfo_eip+0x330>
    // 'eip'.  First, we find the basic source file containing 'eip'.
    // Then, we look in that source file for the function.  Then we look
    // for the line number.

    // Search the entire set of stabs for the source file (type N_SO).
    int lfile = 0, rfile = (stab_end - stabs) - 1;
  10067f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  100686:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100689:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10068c:	29 c2                	sub    %eax,%edx
  10068e:	89 d0                	mov    %edx,%eax
  100690:	c1 f8 02             	sar    $0x2,%eax
  100693:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
  100699:	48                   	dec    %eax
  10069a:	89 45 e0             	mov    %eax,-0x20(%ebp)
    stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
  10069d:	8b 45 08             	mov    0x8(%ebp),%eax
  1006a0:	89 44 24 10          	mov    %eax,0x10(%esp)
  1006a4:	c7 44 24 0c 64 00 00 	movl   $0x64,0xc(%esp)
  1006ab:	00 
  1006ac:	8d 45 e0             	lea    -0x20(%ebp),%eax
  1006af:	89 44 24 08          	mov    %eax,0x8(%esp)
  1006b3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
  1006b6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1006ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1006bd:	89 04 24             	mov    %eax,(%esp)
  1006c0:	e8 f3 fd ff ff       	call   1004b8 <stab_binsearch>
    if (lfile == 0)
  1006c5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1006c8:	85 c0                	test   %eax,%eax
  1006ca:	75 0a                	jne    1006d6 <debuginfo_eip+0xd0>
        return -1;
  1006cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1006d1:	e9 60 02 00 00       	jmp    100936 <debuginfo_eip+0x330>

    // Search within that file's stabs for the function definition
    // (N_FUN).
    int lfun = lfile, rfun = rfile;
  1006d6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1006d9:	89 45 dc             	mov    %eax,-0x24(%ebp)
  1006dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1006df:	89 45 d8             	mov    %eax,-0x28(%ebp)
    int lline, rline;
    stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
  1006e2:	8b 45 08             	mov    0x8(%ebp),%eax
  1006e5:	89 44 24 10          	mov    %eax,0x10(%esp)
  1006e9:	c7 44 24 0c 24 00 00 	movl   $0x24,0xc(%esp)
  1006f0:	00 
  1006f1:	8d 45 d8             	lea    -0x28(%ebp),%eax
  1006f4:	89 44 24 08          	mov    %eax,0x8(%esp)
  1006f8:	8d 45 dc             	lea    -0x24(%ebp),%eax
  1006fb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1006ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100702:	89 04 24             	mov    %eax,(%esp)
  100705:	e8 ae fd ff ff       	call   1004b8 <stab_binsearch>

    if (lfun <= rfun) {
  10070a:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10070d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  100710:	39 c2                	cmp    %eax,%edx
  100712:	7f 7c                	jg     100790 <debuginfo_eip+0x18a>
        // stabs[lfun] points to the function name
        // in the string table, but check bounds just in case.
        if (stabs[lfun].n_strx < stabstr_end - stabstr) {
  100714:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100717:	89 c2                	mov    %eax,%edx
  100719:	89 d0                	mov    %edx,%eax
  10071b:	01 c0                	add    %eax,%eax
  10071d:	01 d0                	add    %edx,%eax
  10071f:	c1 e0 02             	shl    $0x2,%eax
  100722:	89 c2                	mov    %eax,%edx
  100724:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100727:	01 d0                	add    %edx,%eax
  100729:	8b 00                	mov    (%eax),%eax
  10072b:	8b 4d e8             	mov    -0x18(%ebp),%ecx
  10072e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100731:	29 d1                	sub    %edx,%ecx
  100733:	89 ca                	mov    %ecx,%edx
  100735:	39 d0                	cmp    %edx,%eax
  100737:	73 22                	jae    10075b <debuginfo_eip+0x155>
            info->eip_fn_name = stabstr + stabs[lfun].n_strx;
  100739:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10073c:	89 c2                	mov    %eax,%edx
  10073e:	89 d0                	mov    %edx,%eax
  100740:	01 c0                	add    %eax,%eax
  100742:	01 d0                	add    %edx,%eax
  100744:	c1 e0 02             	shl    $0x2,%eax
  100747:	89 c2                	mov    %eax,%edx
  100749:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10074c:	01 d0                	add    %edx,%eax
  10074e:	8b 10                	mov    (%eax),%edx
  100750:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100753:	01 c2                	add    %eax,%edx
  100755:	8b 45 0c             	mov    0xc(%ebp),%eax
  100758:	89 50 08             	mov    %edx,0x8(%eax)
        }
        info->eip_fn_addr = stabs[lfun].n_value;
  10075b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10075e:	89 c2                	mov    %eax,%edx
  100760:	89 d0                	mov    %edx,%eax
  100762:	01 c0                	add    %eax,%eax
  100764:	01 d0                	add    %edx,%eax
  100766:	c1 e0 02             	shl    $0x2,%eax
  100769:	89 c2                	mov    %eax,%edx
  10076b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10076e:	01 d0                	add    %edx,%eax
  100770:	8b 50 08             	mov    0x8(%eax),%edx
  100773:	8b 45 0c             	mov    0xc(%ebp),%eax
  100776:	89 50 10             	mov    %edx,0x10(%eax)
        addr -= info->eip_fn_addr;
  100779:	8b 45 0c             	mov    0xc(%ebp),%eax
  10077c:	8b 40 10             	mov    0x10(%eax),%eax
  10077f:	29 45 08             	sub    %eax,0x8(%ebp)
        // Search within the function definition for the line number.
        lline = lfun;
  100782:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100785:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfun;
  100788:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10078b:	89 45 d0             	mov    %eax,-0x30(%ebp)
  10078e:	eb 15                	jmp    1007a5 <debuginfo_eip+0x19f>
    } else {
        // Couldn't find function stab!  Maybe we're in an assembly
        // file.  Search the whole file for the line number.
        info->eip_fn_addr = addr;
  100790:	8b 45 0c             	mov    0xc(%ebp),%eax
  100793:	8b 55 08             	mov    0x8(%ebp),%edx
  100796:	89 50 10             	mov    %edx,0x10(%eax)
        lline = lfile;
  100799:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10079c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfile;
  10079f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1007a2:	89 45 d0             	mov    %eax,-0x30(%ebp)
    }
    info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
  1007a5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1007a8:	8b 40 08             	mov    0x8(%eax),%eax
  1007ab:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
  1007b2:	00 
  1007b3:	89 04 24             	mov    %eax,(%esp)
  1007b6:	e8 64 4b 00 00       	call   10531f <strfind>
  1007bb:	89 c2                	mov    %eax,%edx
  1007bd:	8b 45 0c             	mov    0xc(%ebp),%eax
  1007c0:	8b 40 08             	mov    0x8(%eax),%eax
  1007c3:	29 c2                	sub    %eax,%edx
  1007c5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1007c8:	89 50 0c             	mov    %edx,0xc(%eax)

    // Search within [lline, rline] for the line number stab.
    // If found, set info->eip_line to the right line number.
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
  1007cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1007ce:	89 44 24 10          	mov    %eax,0x10(%esp)
  1007d2:	c7 44 24 0c 44 00 00 	movl   $0x44,0xc(%esp)
  1007d9:	00 
  1007da:	8d 45 d0             	lea    -0x30(%ebp),%eax
  1007dd:	89 44 24 08          	mov    %eax,0x8(%esp)
  1007e1:	8d 45 d4             	lea    -0x2c(%ebp),%eax
  1007e4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1007e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1007eb:	89 04 24             	mov    %eax,(%esp)
  1007ee:	e8 c5 fc ff ff       	call   1004b8 <stab_binsearch>
    if (lline <= rline) {
  1007f3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1007f6:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1007f9:	39 c2                	cmp    %eax,%edx
  1007fb:	7f 23                	jg     100820 <debuginfo_eip+0x21a>
        info->eip_line = stabs[rline].n_desc;
  1007fd:	8b 45 d0             	mov    -0x30(%ebp),%eax
  100800:	89 c2                	mov    %eax,%edx
  100802:	89 d0                	mov    %edx,%eax
  100804:	01 c0                	add    %eax,%eax
  100806:	01 d0                	add    %edx,%eax
  100808:	c1 e0 02             	shl    $0x2,%eax
  10080b:	89 c2                	mov    %eax,%edx
  10080d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100810:	01 d0                	add    %edx,%eax
  100812:	0f b7 40 06          	movzwl 0x6(%eax),%eax
  100816:	89 c2                	mov    %eax,%edx
  100818:	8b 45 0c             	mov    0xc(%ebp),%eax
  10081b:	89 50 04             	mov    %edx,0x4(%eax)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
  10081e:	eb 11                	jmp    100831 <debuginfo_eip+0x22b>
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
    if (lline <= rline) {
        info->eip_line = stabs[rline].n_desc;
    } else {
        return -1;
  100820:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  100825:	e9 0c 01 00 00       	jmp    100936 <debuginfo_eip+0x330>
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
           && stabs[lline].n_type != N_SOL
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
        lline --;
  10082a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10082d:	48                   	dec    %eax
  10082e:	89 45 d4             	mov    %eax,-0x2c(%ebp)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
  100831:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  100834:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100837:	39 c2                	cmp    %eax,%edx
  100839:	7c 56                	jl     100891 <debuginfo_eip+0x28b>
           && stabs[lline].n_type != N_SOL
  10083b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10083e:	89 c2                	mov    %eax,%edx
  100840:	89 d0                	mov    %edx,%eax
  100842:	01 c0                	add    %eax,%eax
  100844:	01 d0                	add    %edx,%eax
  100846:	c1 e0 02             	shl    $0x2,%eax
  100849:	89 c2                	mov    %eax,%edx
  10084b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10084e:	01 d0                	add    %edx,%eax
  100850:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  100854:	3c 84                	cmp    $0x84,%al
  100856:	74 39                	je     100891 <debuginfo_eip+0x28b>
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
  100858:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10085b:	89 c2                	mov    %eax,%edx
  10085d:	89 d0                	mov    %edx,%eax
  10085f:	01 c0                	add    %eax,%eax
  100861:	01 d0                	add    %edx,%eax
  100863:	c1 e0 02             	shl    $0x2,%eax
  100866:	89 c2                	mov    %eax,%edx
  100868:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10086b:	01 d0                	add    %edx,%eax
  10086d:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  100871:	3c 64                	cmp    $0x64,%al
  100873:	75 b5                	jne    10082a <debuginfo_eip+0x224>
  100875:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  100878:	89 c2                	mov    %eax,%edx
  10087a:	89 d0                	mov    %edx,%eax
  10087c:	01 c0                	add    %eax,%eax
  10087e:	01 d0                	add    %edx,%eax
  100880:	c1 e0 02             	shl    $0x2,%eax
  100883:	89 c2                	mov    %eax,%edx
  100885:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100888:	01 d0                	add    %edx,%eax
  10088a:	8b 40 08             	mov    0x8(%eax),%eax
  10088d:	85 c0                	test   %eax,%eax
  10088f:	74 99                	je     10082a <debuginfo_eip+0x224>
        lline --;
    }
    if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr) {
  100891:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  100894:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100897:	39 c2                	cmp    %eax,%edx
  100899:	7c 46                	jl     1008e1 <debuginfo_eip+0x2db>
  10089b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10089e:	89 c2                	mov    %eax,%edx
  1008a0:	89 d0                	mov    %edx,%eax
  1008a2:	01 c0                	add    %eax,%eax
  1008a4:	01 d0                	add    %edx,%eax
  1008a6:	c1 e0 02             	shl    $0x2,%eax
  1008a9:	89 c2                	mov    %eax,%edx
  1008ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1008ae:	01 d0                	add    %edx,%eax
  1008b0:	8b 00                	mov    (%eax),%eax
  1008b2:	8b 4d e8             	mov    -0x18(%ebp),%ecx
  1008b5:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1008b8:	29 d1                	sub    %edx,%ecx
  1008ba:	89 ca                	mov    %ecx,%edx
  1008bc:	39 d0                	cmp    %edx,%eax
  1008be:	73 21                	jae    1008e1 <debuginfo_eip+0x2db>
        info->eip_file = stabstr + stabs[lline].n_strx;
  1008c0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1008c3:	89 c2                	mov    %eax,%edx
  1008c5:	89 d0                	mov    %edx,%eax
  1008c7:	01 c0                	add    %eax,%eax
  1008c9:	01 d0                	add    %edx,%eax
  1008cb:	c1 e0 02             	shl    $0x2,%eax
  1008ce:	89 c2                	mov    %eax,%edx
  1008d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1008d3:	01 d0                	add    %edx,%eax
  1008d5:	8b 10                	mov    (%eax),%edx
  1008d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1008da:	01 c2                	add    %eax,%edx
  1008dc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1008df:	89 10                	mov    %edx,(%eax)
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
  1008e1:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1008e4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1008e7:	39 c2                	cmp    %eax,%edx
  1008e9:	7d 46                	jge    100931 <debuginfo_eip+0x32b>
        for (lline = lfun + 1;
  1008eb:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1008ee:	40                   	inc    %eax
  1008ef:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  1008f2:	eb 16                	jmp    10090a <debuginfo_eip+0x304>
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
            info->eip_fn_narg ++;
  1008f4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1008f7:	8b 40 14             	mov    0x14(%eax),%eax
  1008fa:	8d 50 01             	lea    0x1(%eax),%edx
  1008fd:	8b 45 0c             	mov    0xc(%ebp),%eax
  100900:	89 50 14             	mov    %edx,0x14(%eax)
    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
  100903:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  100906:	40                   	inc    %eax
  100907:	89 45 d4             	mov    %eax,-0x2c(%ebp)

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM;
  10090a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10090d:	8b 45 d8             	mov    -0x28(%ebp),%eax
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
  100910:	39 c2                	cmp    %eax,%edx
  100912:	7d 1d                	jge    100931 <debuginfo_eip+0x32b>
             lline < rfun && stabs[lline].n_type == N_PSYM;
  100914:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  100917:	89 c2                	mov    %eax,%edx
  100919:	89 d0                	mov    %edx,%eax
  10091b:	01 c0                	add    %eax,%eax
  10091d:	01 d0                	add    %edx,%eax
  10091f:	c1 e0 02             	shl    $0x2,%eax
  100922:	89 c2                	mov    %eax,%edx
  100924:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100927:	01 d0                	add    %edx,%eax
  100929:	0f b6 40 04          	movzbl 0x4(%eax),%eax
  10092d:	3c a0                	cmp    $0xa0,%al
  10092f:	74 c3                	je     1008f4 <debuginfo_eip+0x2ee>
             lline ++) {
            info->eip_fn_narg ++;
        }
    }
    return 0;
  100931:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100936:	c9                   	leave  
  100937:	c3                   	ret    

00100938 <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void
print_kerninfo(void) {
  100938:	55                   	push   %ebp
  100939:	89 e5                	mov    %esp,%ebp
  10093b:	83 ec 18             	sub    $0x18,%esp
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
  10093e:	c7 04 24 a2 5d 10 00 	movl   $0x105da2,(%esp)
  100945:	e8 48 f9 ff ff       	call   100292 <cprintf>
    cprintf("  entry  0x%08x (phys)\n", kern_init);
  10094a:	c7 44 24 04 36 00 10 	movl   $0x100036,0x4(%esp)
  100951:	00 
  100952:	c7 04 24 bb 5d 10 00 	movl   $0x105dbb,(%esp)
  100959:	e8 34 f9 ff ff       	call   100292 <cprintf>
    cprintf("  etext  0x%08x (phys)\n", etext);
  10095e:	c7 44 24 04 9d 5c 10 	movl   $0x105c9d,0x4(%esp)
  100965:	00 
  100966:	c7 04 24 d3 5d 10 00 	movl   $0x105dd3,(%esp)
  10096d:	e8 20 f9 ff ff       	call   100292 <cprintf>
    cprintf("  edata  0x%08x (phys)\n", edata);
  100972:	c7 44 24 04 36 7a 11 	movl   $0x117a36,0x4(%esp)
  100979:	00 
  10097a:	c7 04 24 eb 5d 10 00 	movl   $0x105deb,(%esp)
  100981:	e8 0c f9 ff ff       	call   100292 <cprintf>
    cprintf("  end    0x%08x (phys)\n", end);
  100986:	c7 44 24 04 28 af 11 	movl   $0x11af28,0x4(%esp)
  10098d:	00 
  10098e:	c7 04 24 03 5e 10 00 	movl   $0x105e03,(%esp)
  100995:	e8 f8 f8 ff ff       	call   100292 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n", (end - kern_init + 1023)/1024);
  10099a:	b8 28 af 11 00       	mov    $0x11af28,%eax
  10099f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
  1009a5:	b8 36 00 10 00       	mov    $0x100036,%eax
  1009aa:	29 c2                	sub    %eax,%edx
  1009ac:	89 d0                	mov    %edx,%eax
  1009ae:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
  1009b4:	85 c0                	test   %eax,%eax
  1009b6:	0f 48 c2             	cmovs  %edx,%eax
  1009b9:	c1 f8 0a             	sar    $0xa,%eax
  1009bc:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009c0:	c7 04 24 1c 5e 10 00 	movl   $0x105e1c,(%esp)
  1009c7:	e8 c6 f8 ff ff       	call   100292 <cprintf>
}
  1009cc:	90                   	nop
  1009cd:	c9                   	leave  
  1009ce:	c3                   	ret    

001009cf <print_debuginfo>:
/* *
 * print_debuginfo - read and print the stat information for the address @eip,
 * and info.eip_fn_addr should be the first address of the related function.
 * */
void
print_debuginfo(uintptr_t eip) {
  1009cf:	55                   	push   %ebp
  1009d0:	89 e5                	mov    %esp,%ebp
  1009d2:	81 ec 48 01 00 00    	sub    $0x148,%esp
    struct eipdebuginfo info;
    if (debuginfo_eip(eip, &info) != 0) {
  1009d8:	8d 45 dc             	lea    -0x24(%ebp),%eax
  1009db:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009df:	8b 45 08             	mov    0x8(%ebp),%eax
  1009e2:	89 04 24             	mov    %eax,(%esp)
  1009e5:	e8 1c fc ff ff       	call   100606 <debuginfo_eip>
  1009ea:	85 c0                	test   %eax,%eax
  1009ec:	74 15                	je     100a03 <print_debuginfo+0x34>
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
  1009ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1009f1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009f5:	c7 04 24 46 5e 10 00 	movl   $0x105e46,(%esp)
  1009fc:	e8 91 f8 ff ff       	call   100292 <cprintf>
        }
        fnname[j] = '\0';
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
                fnname, eip - info.eip_fn_addr);
    }
}
  100a01:	eb 6c                	jmp    100a6f <print_debuginfo+0xa0>
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
  100a03:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100a0a:	eb 1b                	jmp    100a27 <print_debuginfo+0x58>
            fnname[j] = info.eip_fn_name[j];
  100a0c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100a0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a12:	01 d0                	add    %edx,%eax
  100a14:	0f b6 00             	movzbl (%eax),%eax
  100a17:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
  100a1d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100a20:	01 ca                	add    %ecx,%edx
  100a22:	88 02                	mov    %al,(%edx)
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
  100a24:	ff 45 f4             	incl   -0xc(%ebp)
  100a27:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100a2a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  100a2d:	7f dd                	jg     100a0c <print_debuginfo+0x3d>
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
  100a2f:	8d 95 dc fe ff ff    	lea    -0x124(%ebp),%edx
  100a35:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a38:	01 d0                	add    %edx,%eax
  100a3a:	c6 00 00             	movb   $0x0,(%eax)
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
                fnname, eip - info.eip_fn_addr);
  100a3d:	8b 45 ec             	mov    -0x14(%ebp),%eax
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
  100a40:	8b 55 08             	mov    0x8(%ebp),%edx
  100a43:	89 d1                	mov    %edx,%ecx
  100a45:	29 c1                	sub    %eax,%ecx
  100a47:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100a4a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100a4d:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  100a51:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
  100a57:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  100a5b:	89 54 24 08          	mov    %edx,0x8(%esp)
  100a5f:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a63:	c7 04 24 62 5e 10 00 	movl   $0x105e62,(%esp)
  100a6a:	e8 23 f8 ff ff       	call   100292 <cprintf>
                fnname, eip - info.eip_fn_addr);
    }
}
  100a6f:	90                   	nop
  100a70:	c9                   	leave  
  100a71:	c3                   	ret    

00100a72 <read_eip>:

static __noinline uint32_t
read_eip(void) {
  100a72:	55                   	push   %ebp
  100a73:	89 e5                	mov    %esp,%ebp
  100a75:	83 ec 10             	sub    $0x10,%esp
    uint32_t eip;
    asm volatile("movl 4(%%ebp), %0" : "=r" (eip));
  100a78:	8b 45 04             	mov    0x4(%ebp),%eax
  100a7b:	89 45 fc             	mov    %eax,-0x4(%ebp)
    return eip;
  100a7e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  100a81:	c9                   	leave  
  100a82:	c3                   	ret    

00100a83 <print_stackframe>:
 *
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the boundary.
 * */
void
print_stackframe(void) {
  100a83:	55                   	push   %ebp
  100a84:	89 e5                	mov    %esp,%ebp
      *    (3.4) call print_debuginfo(eip-1) to print the C calling function name and line number, etc.
      *    (3.5) popup a calling stackframe
      *           NOTICE: the calling funciton's return addr eip  = ss:[ebp+4]
      *                   the calling funciton's ebp = ss:[ebp]
      */
}
  100a86:	90                   	nop
  100a87:	5d                   	pop    %ebp
  100a88:	c3                   	ret    

00100a89 <parse>:
#define MAXARGS         16
#define WHITESPACE      " \t\n\r"

/* parse - parse the command buffer into whitespace-separated arguments */
static int
parse(char *buf, char **argv) {
  100a89:	55                   	push   %ebp
  100a8a:	89 e5                	mov    %esp,%ebp
  100a8c:	83 ec 28             	sub    $0x28,%esp
    int argc = 0;
  100a8f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
  100a96:	eb 0c                	jmp    100aa4 <parse+0x1b>
            *buf ++ = '\0';
  100a98:	8b 45 08             	mov    0x8(%ebp),%eax
  100a9b:	8d 50 01             	lea    0x1(%eax),%edx
  100a9e:	89 55 08             	mov    %edx,0x8(%ebp)
  100aa1:	c6 00 00             	movb   $0x0,(%eax)
static int
parse(char *buf, char **argv) {
    int argc = 0;
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
  100aa4:	8b 45 08             	mov    0x8(%ebp),%eax
  100aa7:	0f b6 00             	movzbl (%eax),%eax
  100aaa:	84 c0                	test   %al,%al
  100aac:	74 1d                	je     100acb <parse+0x42>
  100aae:	8b 45 08             	mov    0x8(%ebp),%eax
  100ab1:	0f b6 00             	movzbl (%eax),%eax
  100ab4:	0f be c0             	movsbl %al,%eax
  100ab7:	89 44 24 04          	mov    %eax,0x4(%esp)
  100abb:	c7 04 24 f4 5e 10 00 	movl   $0x105ef4,(%esp)
  100ac2:	e8 26 48 00 00       	call   1052ed <strchr>
  100ac7:	85 c0                	test   %eax,%eax
  100ac9:	75 cd                	jne    100a98 <parse+0xf>
            *buf ++ = '\0';
        }
        if (*buf == '\0') {
  100acb:	8b 45 08             	mov    0x8(%ebp),%eax
  100ace:	0f b6 00             	movzbl (%eax),%eax
  100ad1:	84 c0                	test   %al,%al
  100ad3:	74 69                	je     100b3e <parse+0xb5>
            break;
        }

        // save and scan past next arg
        if (argc == MAXARGS - 1) {
  100ad5:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
  100ad9:	75 14                	jne    100aef <parse+0x66>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
  100adb:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  100ae2:	00 
  100ae3:	c7 04 24 f9 5e 10 00 	movl   $0x105ef9,(%esp)
  100aea:	e8 a3 f7 ff ff       	call   100292 <cprintf>
        }
        argv[argc ++] = buf;
  100aef:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100af2:	8d 50 01             	lea    0x1(%eax),%edx
  100af5:	89 55 f4             	mov    %edx,-0xc(%ebp)
  100af8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  100aff:	8b 45 0c             	mov    0xc(%ebp),%eax
  100b02:	01 c2                	add    %eax,%edx
  100b04:	8b 45 08             	mov    0x8(%ebp),%eax
  100b07:	89 02                	mov    %eax,(%edx)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
  100b09:	eb 03                	jmp    100b0e <parse+0x85>
            buf ++;
  100b0b:	ff 45 08             	incl   0x8(%ebp)
        // save and scan past next arg
        if (argc == MAXARGS - 1) {
            cprintf("Too many arguments (max %d).\n", MAXARGS);
        }
        argv[argc ++] = buf;
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
  100b0e:	8b 45 08             	mov    0x8(%ebp),%eax
  100b11:	0f b6 00             	movzbl (%eax),%eax
  100b14:	84 c0                	test   %al,%al
  100b16:	0f 84 7a ff ff ff    	je     100a96 <parse+0xd>
  100b1c:	8b 45 08             	mov    0x8(%ebp),%eax
  100b1f:	0f b6 00             	movzbl (%eax),%eax
  100b22:	0f be c0             	movsbl %al,%eax
  100b25:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b29:	c7 04 24 f4 5e 10 00 	movl   $0x105ef4,(%esp)
  100b30:	e8 b8 47 00 00       	call   1052ed <strchr>
  100b35:	85 c0                	test   %eax,%eax
  100b37:	74 d2                	je     100b0b <parse+0x82>
            buf ++;
        }
    }
  100b39:	e9 58 ff ff ff       	jmp    100a96 <parse+0xd>
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
            *buf ++ = '\0';
        }
        if (*buf == '\0') {
            break;
  100b3e:	90                   	nop
        argv[argc ++] = buf;
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
            buf ++;
        }
    }
    return argc;
  100b3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100b42:	c9                   	leave  
  100b43:	c3                   	ret    

00100b44 <runcmd>:
/* *
 * runcmd - parse the input string, split it into separated arguments
 * and then lookup and invoke some related commands/
 * */
static int
runcmd(char *buf, struct trapframe *tf) {
  100b44:	55                   	push   %ebp
  100b45:	89 e5                	mov    %esp,%ebp
  100b47:	53                   	push   %ebx
  100b48:	83 ec 64             	sub    $0x64,%esp
    char *argv[MAXARGS];
    int argc = parse(buf, argv);
  100b4b:	8d 45 b0             	lea    -0x50(%ebp),%eax
  100b4e:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b52:	8b 45 08             	mov    0x8(%ebp),%eax
  100b55:	89 04 24             	mov    %eax,(%esp)
  100b58:	e8 2c ff ff ff       	call   100a89 <parse>
  100b5d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if (argc == 0) {
  100b60:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  100b64:	75 0a                	jne    100b70 <runcmd+0x2c>
        return 0;
  100b66:	b8 00 00 00 00       	mov    $0x0,%eax
  100b6b:	e9 83 00 00 00       	jmp    100bf3 <runcmd+0xaf>
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
  100b70:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100b77:	eb 5a                	jmp    100bd3 <runcmd+0x8f>
        if (strcmp(commands[i].name, argv[0]) == 0) {
  100b79:	8b 4d b0             	mov    -0x50(%ebp),%ecx
  100b7c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100b7f:	89 d0                	mov    %edx,%eax
  100b81:	01 c0                	add    %eax,%eax
  100b83:	01 d0                	add    %edx,%eax
  100b85:	c1 e0 02             	shl    $0x2,%eax
  100b88:	05 00 70 11 00       	add    $0x117000,%eax
  100b8d:	8b 00                	mov    (%eax),%eax
  100b8f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  100b93:	89 04 24             	mov    %eax,(%esp)
  100b96:	e8 b5 46 00 00       	call   105250 <strcmp>
  100b9b:	85 c0                	test   %eax,%eax
  100b9d:	75 31                	jne    100bd0 <runcmd+0x8c>
            return commands[i].func(argc - 1, argv + 1, tf);
  100b9f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100ba2:	89 d0                	mov    %edx,%eax
  100ba4:	01 c0                	add    %eax,%eax
  100ba6:	01 d0                	add    %edx,%eax
  100ba8:	c1 e0 02             	shl    $0x2,%eax
  100bab:	05 08 70 11 00       	add    $0x117008,%eax
  100bb0:	8b 10                	mov    (%eax),%edx
  100bb2:	8d 45 b0             	lea    -0x50(%ebp),%eax
  100bb5:	83 c0 04             	add    $0x4,%eax
  100bb8:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  100bbb:	8d 59 ff             	lea    -0x1(%ecx),%ebx
  100bbe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  100bc1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  100bc5:	89 44 24 04          	mov    %eax,0x4(%esp)
  100bc9:	89 1c 24             	mov    %ebx,(%esp)
  100bcc:	ff d2                	call   *%edx
  100bce:	eb 23                	jmp    100bf3 <runcmd+0xaf>
    int argc = parse(buf, argv);
    if (argc == 0) {
        return 0;
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
  100bd0:	ff 45 f4             	incl   -0xc(%ebp)
  100bd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100bd6:	83 f8 02             	cmp    $0x2,%eax
  100bd9:	76 9e                	jbe    100b79 <runcmd+0x35>
        if (strcmp(commands[i].name, argv[0]) == 0) {
            return commands[i].func(argc - 1, argv + 1, tf);
        }
    }
    cprintf("Unknown command '%s'\n", argv[0]);
  100bdb:	8b 45 b0             	mov    -0x50(%ebp),%eax
  100bde:	89 44 24 04          	mov    %eax,0x4(%esp)
  100be2:	c7 04 24 17 5f 10 00 	movl   $0x105f17,(%esp)
  100be9:	e8 a4 f6 ff ff       	call   100292 <cprintf>
    return 0;
  100bee:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100bf3:	83 c4 64             	add    $0x64,%esp
  100bf6:	5b                   	pop    %ebx
  100bf7:	5d                   	pop    %ebp
  100bf8:	c3                   	ret    

00100bf9 <kmonitor>:

/***** Implementations of basic kernel monitor commands *****/

void
kmonitor(struct trapframe *tf) {
  100bf9:	55                   	push   %ebp
  100bfa:	89 e5                	mov    %esp,%ebp
  100bfc:	83 ec 28             	sub    $0x28,%esp
    cprintf("Welcome to the kernel debug monitor!!\n");
  100bff:	c7 04 24 30 5f 10 00 	movl   $0x105f30,(%esp)
  100c06:	e8 87 f6 ff ff       	call   100292 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
  100c0b:	c7 04 24 58 5f 10 00 	movl   $0x105f58,(%esp)
  100c12:	e8 7b f6 ff ff       	call   100292 <cprintf>

    if (tf != NULL) {
  100c17:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  100c1b:	74 0b                	je     100c28 <kmonitor+0x2f>
        print_trapframe(tf);
  100c1d:	8b 45 08             	mov    0x8(%ebp),%eax
  100c20:	89 04 24             	mov    %eax,(%esp)
  100c23:	e8 0b 0c 00 00       	call   101833 <print_trapframe>
    }

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
  100c28:	c7 04 24 7d 5f 10 00 	movl   $0x105f7d,(%esp)
  100c2f:	e8 00 f7 ff ff       	call   100334 <readline>
  100c34:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100c37:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100c3b:	74 eb                	je     100c28 <kmonitor+0x2f>
            if (runcmd(buf, tf) < 0) {
  100c3d:	8b 45 08             	mov    0x8(%ebp),%eax
  100c40:	89 44 24 04          	mov    %eax,0x4(%esp)
  100c44:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100c47:	89 04 24             	mov    %eax,(%esp)
  100c4a:	e8 f5 fe ff ff       	call   100b44 <runcmd>
  100c4f:	85 c0                	test   %eax,%eax
  100c51:	78 02                	js     100c55 <kmonitor+0x5c>
                break;
            }
        }
    }
  100c53:	eb d3                	jmp    100c28 <kmonitor+0x2f>

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
            if (runcmd(buf, tf) < 0) {
                break;
  100c55:	90                   	nop
            }
        }
    }
}
  100c56:	90                   	nop
  100c57:	c9                   	leave  
  100c58:	c3                   	ret    

00100c59 <mon_help>:

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
  100c59:	55                   	push   %ebp
  100c5a:	89 e5                	mov    %esp,%ebp
  100c5c:	83 ec 28             	sub    $0x28,%esp
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
  100c5f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100c66:	eb 3d                	jmp    100ca5 <mon_help+0x4c>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
  100c68:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c6b:	89 d0                	mov    %edx,%eax
  100c6d:	01 c0                	add    %eax,%eax
  100c6f:	01 d0                	add    %edx,%eax
  100c71:	c1 e0 02             	shl    $0x2,%eax
  100c74:	05 04 70 11 00       	add    $0x117004,%eax
  100c79:	8b 08                	mov    (%eax),%ecx
  100c7b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c7e:	89 d0                	mov    %edx,%eax
  100c80:	01 c0                	add    %eax,%eax
  100c82:	01 d0                	add    %edx,%eax
  100c84:	c1 e0 02             	shl    $0x2,%eax
  100c87:	05 00 70 11 00       	add    $0x117000,%eax
  100c8c:	8b 00                	mov    (%eax),%eax
  100c8e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  100c92:	89 44 24 04          	mov    %eax,0x4(%esp)
  100c96:	c7 04 24 81 5f 10 00 	movl   $0x105f81,(%esp)
  100c9d:	e8 f0 f5 ff ff       	call   100292 <cprintf>

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
  100ca2:	ff 45 f4             	incl   -0xc(%ebp)
  100ca5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100ca8:	83 f8 02             	cmp    $0x2,%eax
  100cab:	76 bb                	jbe    100c68 <mon_help+0xf>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
    }
    return 0;
  100cad:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100cb2:	c9                   	leave  
  100cb3:	c3                   	ret    

00100cb4 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
  100cb4:	55                   	push   %ebp
  100cb5:	89 e5                	mov    %esp,%ebp
  100cb7:	83 ec 08             	sub    $0x8,%esp
    print_kerninfo();
  100cba:	e8 79 fc ff ff       	call   100938 <print_kerninfo>
    return 0;
  100cbf:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100cc4:	c9                   	leave  
  100cc5:	c3                   	ret    

00100cc6 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
  100cc6:	55                   	push   %ebp
  100cc7:	89 e5                	mov    %esp,%ebp
  100cc9:	83 ec 08             	sub    $0x8,%esp
    print_stackframe();
  100ccc:	e8 b2 fd ff ff       	call   100a83 <print_stackframe>
    return 0;
  100cd1:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100cd6:	c9                   	leave  
  100cd7:	c3                   	ret    

00100cd8 <clock_init>:
/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void
clock_init(void) {
  100cd8:	55                   	push   %ebp
  100cd9:	89 e5                	mov    %esp,%ebp
  100cdb:	83 ec 28             	sub    $0x28,%esp
  100cde:	66 c7 45 f6 43 00    	movw   $0x43,-0xa(%ebp)
  100ce4:	c6 45 ef 34          	movb   $0x34,-0x11(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  100ce8:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
  100cec:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  100cf0:	ee                   	out    %al,(%dx)
  100cf1:	66 c7 45 f4 40 00    	movw   $0x40,-0xc(%ebp)
  100cf7:	c6 45 f0 9c          	movb   $0x9c,-0x10(%ebp)
  100cfb:	0f b6 45 f0          	movzbl -0x10(%ebp),%eax
  100cff:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100d02:	ee                   	out    %al,(%dx)
  100d03:	66 c7 45 f2 40 00    	movw   $0x40,-0xe(%ebp)
  100d09:	c6 45 f1 2e          	movb   $0x2e,-0xf(%ebp)
  100d0d:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
  100d11:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  100d15:	ee                   	out    %al,(%dx)
    outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
    outb(IO_TIMER1, TIMER_DIV(100) % 256);
    outb(IO_TIMER1, TIMER_DIV(100) / 256);

    // initialize time counter 'ticks' to zero
    ticks = 0;
  100d16:	c7 05 0c af 11 00 00 	movl   $0x0,0x11af0c
  100d1d:	00 00 00 

    cprintf("++ setup timer interrupts\n");
  100d20:	c7 04 24 8a 5f 10 00 	movl   $0x105f8a,(%esp)
  100d27:	e8 66 f5 ff ff       	call   100292 <cprintf>
    pic_enable(IRQ_TIMER);
  100d2c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  100d33:	e8 1e 09 00 00       	call   101656 <pic_enable>
}
  100d38:	90                   	nop
  100d39:	c9                   	leave  
  100d3a:	c3                   	ret    

00100d3b <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
  100d3b:	55                   	push   %ebp
  100d3c:	89 e5                	mov    %esp,%ebp
  100d3e:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
  100d41:	9c                   	pushf  
  100d42:	58                   	pop    %eax
  100d43:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
  100d46:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
  100d49:	25 00 02 00 00       	and    $0x200,%eax
  100d4e:	85 c0                	test   %eax,%eax
  100d50:	74 0c                	je     100d5e <__intr_save+0x23>
        intr_disable();
  100d52:	e8 6c 0a 00 00       	call   1017c3 <intr_disable>
        return 1;
  100d57:	b8 01 00 00 00       	mov    $0x1,%eax
  100d5c:	eb 05                	jmp    100d63 <__intr_save+0x28>
    }
    return 0;
  100d5e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100d63:	c9                   	leave  
  100d64:	c3                   	ret    

00100d65 <__intr_restore>:

static inline void
__intr_restore(bool flag) {
  100d65:	55                   	push   %ebp
  100d66:	89 e5                	mov    %esp,%ebp
  100d68:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
  100d6b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  100d6f:	74 05                	je     100d76 <__intr_restore+0x11>
        intr_enable();
  100d71:	e8 46 0a 00 00       	call   1017bc <intr_enable>
    }
}
  100d76:	90                   	nop
  100d77:	c9                   	leave  
  100d78:	c3                   	ret    

00100d79 <delay>:
#include <memlayout.h>
#include <sync.h>

/* stupid I/O delay routine necessitated by historical PC design flaws */
static void
delay(void) {
  100d79:	55                   	push   %ebp
  100d7a:	89 e5                	mov    %esp,%ebp
  100d7c:	83 ec 10             	sub    $0x10,%esp
  100d7f:	66 c7 45 fe 84 00    	movw   $0x84,-0x2(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  100d85:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
  100d89:	89 c2                	mov    %eax,%edx
  100d8b:	ec                   	in     (%dx),%al
  100d8c:	88 45 f4             	mov    %al,-0xc(%ebp)
  100d8f:	66 c7 45 fc 84 00    	movw   $0x84,-0x4(%ebp)
  100d95:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100d98:	89 c2                	mov    %eax,%edx
  100d9a:	ec                   	in     (%dx),%al
  100d9b:	88 45 f5             	mov    %al,-0xb(%ebp)
  100d9e:	66 c7 45 fa 84 00    	movw   $0x84,-0x6(%ebp)
  100da4:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
  100da8:	89 c2                	mov    %eax,%edx
  100daa:	ec                   	in     (%dx),%al
  100dab:	88 45 f6             	mov    %al,-0xa(%ebp)
  100dae:	66 c7 45 f8 84 00    	movw   $0x84,-0x8(%ebp)
  100db4:	8b 45 f8             	mov    -0x8(%ebp),%eax
  100db7:	89 c2                	mov    %eax,%edx
  100db9:	ec                   	in     (%dx),%al
  100dba:	88 45 f7             	mov    %al,-0x9(%ebp)
    inb(0x84);
    inb(0x84);
    inb(0x84);
    inb(0x84);
}
  100dbd:	90                   	nop
  100dbe:	c9                   	leave  
  100dbf:	c3                   	ret    

00100dc0 <cga_init>:
static uint16_t addr_6845;

/* TEXT-mode CGA/VGA display output */

static void
cga_init(void) {
  100dc0:	55                   	push   %ebp
  100dc1:	89 e5                	mov    %esp,%ebp
  100dc3:	83 ec 20             	sub    $0x20,%esp
    volatile uint16_t *cp = (uint16_t *)(CGA_BUF + KERNBASE);
  100dc6:	c7 45 fc 00 80 0b c0 	movl   $0xc00b8000,-0x4(%ebp)
    uint16_t was = *cp;
  100dcd:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100dd0:	0f b7 00             	movzwl (%eax),%eax
  100dd3:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
    *cp = (uint16_t) 0xA55A;
  100dd7:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100dda:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
    if (*cp != 0xA55A) {
  100ddf:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100de2:	0f b7 00             	movzwl (%eax),%eax
  100de5:	0f b7 c0             	movzwl %ax,%eax
  100de8:	3d 5a a5 00 00       	cmp    $0xa55a,%eax
  100ded:	74 12                	je     100e01 <cga_init+0x41>
        cp = (uint16_t*)(MONO_BUF + KERNBASE);
  100def:	c7 45 fc 00 00 0b c0 	movl   $0xc00b0000,-0x4(%ebp)
        addr_6845 = MONO_BASE;
  100df6:	66 c7 05 46 a4 11 00 	movw   $0x3b4,0x11a446
  100dfd:	b4 03 
  100dff:	eb 13                	jmp    100e14 <cga_init+0x54>
    } else {
        *cp = was;
  100e01:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100e04:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
  100e08:	66 89 10             	mov    %dx,(%eax)
        addr_6845 = CGA_BASE;
  100e0b:	66 c7 05 46 a4 11 00 	movw   $0x3d4,0x11a446
  100e12:	d4 03 
    }

    // Extract cursor location
    uint32_t pos;
    outb(addr_6845, 14);
  100e14:	0f b7 05 46 a4 11 00 	movzwl 0x11a446,%eax
  100e1b:	66 89 45 f8          	mov    %ax,-0x8(%ebp)
  100e1f:	c6 45 ea 0e          	movb   $0xe,-0x16(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  100e23:	0f b6 45 ea          	movzbl -0x16(%ebp),%eax
  100e27:	8b 55 f8             	mov    -0x8(%ebp),%edx
  100e2a:	ee                   	out    %al,(%dx)
    pos = inb(addr_6845 + 1) << 8;
  100e2b:	0f b7 05 46 a4 11 00 	movzwl 0x11a446,%eax
  100e32:	40                   	inc    %eax
  100e33:	0f b7 c0             	movzwl %ax,%eax
  100e36:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  100e3a:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
  100e3e:	89 c2                	mov    %eax,%edx
  100e40:	ec                   	in     (%dx),%al
  100e41:	88 45 eb             	mov    %al,-0x15(%ebp)
    return data;
  100e44:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  100e48:	0f b6 c0             	movzbl %al,%eax
  100e4b:	c1 e0 08             	shl    $0x8,%eax
  100e4e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    outb(addr_6845, 15);
  100e51:	0f b7 05 46 a4 11 00 	movzwl 0x11a446,%eax
  100e58:	66 89 45 f0          	mov    %ax,-0x10(%ebp)
  100e5c:	c6 45 ec 0f          	movb   $0xf,-0x14(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  100e60:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
  100e64:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100e67:	ee                   	out    %al,(%dx)
    pos |= inb(addr_6845 + 1);
  100e68:	0f b7 05 46 a4 11 00 	movzwl 0x11a446,%eax
  100e6f:	40                   	inc    %eax
  100e70:	0f b7 c0             	movzwl %ax,%eax
  100e73:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  100e77:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
  100e7b:	89 c2                	mov    %eax,%edx
  100e7d:	ec                   	in     (%dx),%al
  100e7e:	88 45 ed             	mov    %al,-0x13(%ebp)
    return data;
  100e81:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
  100e85:	0f b6 c0             	movzbl %al,%eax
  100e88:	09 45 f4             	or     %eax,-0xc(%ebp)

    crt_buf = (uint16_t*) cp;
  100e8b:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100e8e:	a3 40 a4 11 00       	mov    %eax,0x11a440
    crt_pos = pos;
  100e93:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100e96:	0f b7 c0             	movzwl %ax,%eax
  100e99:	66 a3 44 a4 11 00    	mov    %ax,0x11a444
}
  100e9f:	90                   	nop
  100ea0:	c9                   	leave  
  100ea1:	c3                   	ret    

00100ea2 <serial_init>:

static bool serial_exists = 0;

static void
serial_init(void) {
  100ea2:	55                   	push   %ebp
  100ea3:	89 e5                	mov    %esp,%ebp
  100ea5:	83 ec 38             	sub    $0x38,%esp
  100ea8:	66 c7 45 f6 fa 03    	movw   $0x3fa,-0xa(%ebp)
  100eae:	c6 45 da 00          	movb   $0x0,-0x26(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  100eb2:	0f b6 45 da          	movzbl -0x26(%ebp),%eax
  100eb6:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  100eba:	ee                   	out    %al,(%dx)
  100ebb:	66 c7 45 f4 fb 03    	movw   $0x3fb,-0xc(%ebp)
  100ec1:	c6 45 db 80          	movb   $0x80,-0x25(%ebp)
  100ec5:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  100ec9:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100ecc:	ee                   	out    %al,(%dx)
  100ecd:	66 c7 45 f2 f8 03    	movw   $0x3f8,-0xe(%ebp)
  100ed3:	c6 45 dc 0c          	movb   $0xc,-0x24(%ebp)
  100ed7:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  100edb:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  100edf:	ee                   	out    %al,(%dx)
  100ee0:	66 c7 45 f0 f9 03    	movw   $0x3f9,-0x10(%ebp)
  100ee6:	c6 45 dd 00          	movb   $0x0,-0x23(%ebp)
  100eea:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
  100eee:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100ef1:	ee                   	out    %al,(%dx)
  100ef2:	66 c7 45 ee fb 03    	movw   $0x3fb,-0x12(%ebp)
  100ef8:	c6 45 de 03          	movb   $0x3,-0x22(%ebp)
  100efc:	0f b6 45 de          	movzbl -0x22(%ebp),%eax
  100f00:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  100f04:	ee                   	out    %al,(%dx)
  100f05:	66 c7 45 ec fc 03    	movw   $0x3fc,-0x14(%ebp)
  100f0b:	c6 45 df 00          	movb   $0x0,-0x21(%ebp)
  100f0f:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
  100f13:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100f16:	ee                   	out    %al,(%dx)
  100f17:	66 c7 45 ea f9 03    	movw   $0x3f9,-0x16(%ebp)
  100f1d:	c6 45 e0 01          	movb   $0x1,-0x20(%ebp)
  100f21:	0f b6 45 e0          	movzbl -0x20(%ebp),%eax
  100f25:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
  100f29:	ee                   	out    %al,(%dx)
  100f2a:	66 c7 45 e8 fd 03    	movw   $0x3fd,-0x18(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  100f30:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100f33:	89 c2                	mov    %eax,%edx
  100f35:	ec                   	in     (%dx),%al
  100f36:	88 45 e1             	mov    %al,-0x1f(%ebp)
    return data;
  100f39:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
    // Enable rcv interrupts
    outb(COM1 + COM_IER, COM_IER_RDI);

    // Clear any preexisting overrun indications and interrupts
    // Serial port doesn't exist if COM_LSR returns 0xFF
    serial_exists = (inb(COM1 + COM_LSR) != 0xFF);
  100f3d:	3c ff                	cmp    $0xff,%al
  100f3f:	0f 95 c0             	setne  %al
  100f42:	0f b6 c0             	movzbl %al,%eax
  100f45:	a3 48 a4 11 00       	mov    %eax,0x11a448
  100f4a:	66 c7 45 e6 fa 03    	movw   $0x3fa,-0x1a(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  100f50:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax
  100f54:	89 c2                	mov    %eax,%edx
  100f56:	ec                   	in     (%dx),%al
  100f57:	88 45 e2             	mov    %al,-0x1e(%ebp)
  100f5a:	66 c7 45 e4 f8 03    	movw   $0x3f8,-0x1c(%ebp)
  100f60:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100f63:	89 c2                	mov    %eax,%edx
  100f65:	ec                   	in     (%dx),%al
  100f66:	88 45 e3             	mov    %al,-0x1d(%ebp)
    (void) inb(COM1+COM_IIR);
    (void) inb(COM1+COM_RX);

    if (serial_exists) {
  100f69:	a1 48 a4 11 00       	mov    0x11a448,%eax
  100f6e:	85 c0                	test   %eax,%eax
  100f70:	74 0c                	je     100f7e <serial_init+0xdc>
        pic_enable(IRQ_COM1);
  100f72:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  100f79:	e8 d8 06 00 00       	call   101656 <pic_enable>
    }
}
  100f7e:	90                   	nop
  100f7f:	c9                   	leave  
  100f80:	c3                   	ret    

00100f81 <lpt_putc_sub>:

static void
lpt_putc_sub(int c) {
  100f81:	55                   	push   %ebp
  100f82:	89 e5                	mov    %esp,%ebp
  100f84:	83 ec 10             	sub    $0x10,%esp
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
  100f87:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  100f8e:	eb 08                	jmp    100f98 <lpt_putc_sub+0x17>
        delay();
  100f90:	e8 e4 fd ff ff       	call   100d79 <delay>
}

static void
lpt_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
  100f95:	ff 45 fc             	incl   -0x4(%ebp)
  100f98:	66 c7 45 f4 79 03    	movw   $0x379,-0xc(%ebp)
  100f9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100fa1:	89 c2                	mov    %eax,%edx
  100fa3:	ec                   	in     (%dx),%al
  100fa4:	88 45 f3             	mov    %al,-0xd(%ebp)
    return data;
  100fa7:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  100fab:	84 c0                	test   %al,%al
  100fad:	78 09                	js     100fb8 <lpt_putc_sub+0x37>
  100faf:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
  100fb6:	7e d8                	jle    100f90 <lpt_putc_sub+0xf>
        delay();
    }
    outb(LPTPORT + 0, c);
  100fb8:	8b 45 08             	mov    0x8(%ebp),%eax
  100fbb:	0f b6 c0             	movzbl %al,%eax
  100fbe:	66 c7 45 f8 78 03    	movw   $0x378,-0x8(%ebp)
  100fc4:	88 45 f0             	mov    %al,-0x10(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  100fc7:	0f b6 45 f0          	movzbl -0x10(%ebp),%eax
  100fcb:	8b 55 f8             	mov    -0x8(%ebp),%edx
  100fce:	ee                   	out    %al,(%dx)
  100fcf:	66 c7 45 f6 7a 03    	movw   $0x37a,-0xa(%ebp)
  100fd5:	c6 45 f1 0d          	movb   $0xd,-0xf(%ebp)
  100fd9:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
  100fdd:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  100fe1:	ee                   	out    %al,(%dx)
  100fe2:	66 c7 45 fa 7a 03    	movw   $0x37a,-0x6(%ebp)
  100fe8:	c6 45 f2 08          	movb   $0x8,-0xe(%ebp)
  100fec:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  100ff0:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
  100ff4:	ee                   	out    %al,(%dx)
    outb(LPTPORT + 2, 0x08 | 0x04 | 0x01);
    outb(LPTPORT + 2, 0x08);
}
  100ff5:	90                   	nop
  100ff6:	c9                   	leave  
  100ff7:	c3                   	ret    

00100ff8 <lpt_putc>:

/* lpt_putc - copy console output to parallel port */
static void
lpt_putc(int c) {
  100ff8:	55                   	push   %ebp
  100ff9:	89 e5                	mov    %esp,%ebp
  100ffb:	83 ec 04             	sub    $0x4,%esp
    if (c != '\b') {
  100ffe:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
  101002:	74 0d                	je     101011 <lpt_putc+0x19>
        lpt_putc_sub(c);
  101004:	8b 45 08             	mov    0x8(%ebp),%eax
  101007:	89 04 24             	mov    %eax,(%esp)
  10100a:	e8 72 ff ff ff       	call   100f81 <lpt_putc_sub>
    else {
        lpt_putc_sub('\b');
        lpt_putc_sub(' ');
        lpt_putc_sub('\b');
    }
}
  10100f:	eb 24                	jmp    101035 <lpt_putc+0x3d>
lpt_putc(int c) {
    if (c != '\b') {
        lpt_putc_sub(c);
    }
    else {
        lpt_putc_sub('\b');
  101011:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  101018:	e8 64 ff ff ff       	call   100f81 <lpt_putc_sub>
        lpt_putc_sub(' ');
  10101d:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101024:	e8 58 ff ff ff       	call   100f81 <lpt_putc_sub>
        lpt_putc_sub('\b');
  101029:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  101030:	e8 4c ff ff ff       	call   100f81 <lpt_putc_sub>
    }
}
  101035:	90                   	nop
  101036:	c9                   	leave  
  101037:	c3                   	ret    

00101038 <cga_putc>:

/* cga_putc - print character to console */
static void
cga_putc(int c) {
  101038:	55                   	push   %ebp
  101039:	89 e5                	mov    %esp,%ebp
  10103b:	53                   	push   %ebx
  10103c:	83 ec 24             	sub    $0x24,%esp
    // set black on white
    if (!(c & ~0xFF)) {
  10103f:	8b 45 08             	mov    0x8(%ebp),%eax
  101042:	25 00 ff ff ff       	and    $0xffffff00,%eax
  101047:	85 c0                	test   %eax,%eax
  101049:	75 07                	jne    101052 <cga_putc+0x1a>
        c |= 0x0700;
  10104b:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)
    }

    switch (c & 0xff) {
  101052:	8b 45 08             	mov    0x8(%ebp),%eax
  101055:	0f b6 c0             	movzbl %al,%eax
  101058:	83 f8 0a             	cmp    $0xa,%eax
  10105b:	74 54                	je     1010b1 <cga_putc+0x79>
  10105d:	83 f8 0d             	cmp    $0xd,%eax
  101060:	74 62                	je     1010c4 <cga_putc+0x8c>
  101062:	83 f8 08             	cmp    $0x8,%eax
  101065:	0f 85 93 00 00 00    	jne    1010fe <cga_putc+0xc6>
    case '\b':
        if (crt_pos > 0) {
  10106b:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  101072:	85 c0                	test   %eax,%eax
  101074:	0f 84 ae 00 00 00    	je     101128 <cga_putc+0xf0>
            crt_pos --;
  10107a:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  101081:	48                   	dec    %eax
  101082:	0f b7 c0             	movzwl %ax,%eax
  101085:	66 a3 44 a4 11 00    	mov    %ax,0x11a444
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
  10108b:	a1 40 a4 11 00       	mov    0x11a440,%eax
  101090:	0f b7 15 44 a4 11 00 	movzwl 0x11a444,%edx
  101097:	01 d2                	add    %edx,%edx
  101099:	01 c2                	add    %eax,%edx
  10109b:	8b 45 08             	mov    0x8(%ebp),%eax
  10109e:	98                   	cwtl   
  10109f:	25 00 ff ff ff       	and    $0xffffff00,%eax
  1010a4:	98                   	cwtl   
  1010a5:	83 c8 20             	or     $0x20,%eax
  1010a8:	98                   	cwtl   
  1010a9:	0f b7 c0             	movzwl %ax,%eax
  1010ac:	66 89 02             	mov    %ax,(%edx)
        }
        break;
  1010af:	eb 77                	jmp    101128 <cga_putc+0xf0>
    case '\n':
        crt_pos += CRT_COLS;
  1010b1:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  1010b8:	83 c0 50             	add    $0x50,%eax
  1010bb:	0f b7 c0             	movzwl %ax,%eax
  1010be:	66 a3 44 a4 11 00    	mov    %ax,0x11a444
    case '\r':
        crt_pos -= (crt_pos % CRT_COLS);
  1010c4:	0f b7 1d 44 a4 11 00 	movzwl 0x11a444,%ebx
  1010cb:	0f b7 0d 44 a4 11 00 	movzwl 0x11a444,%ecx
  1010d2:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
  1010d7:	89 c8                	mov    %ecx,%eax
  1010d9:	f7 e2                	mul    %edx
  1010db:	c1 ea 06             	shr    $0x6,%edx
  1010de:	89 d0                	mov    %edx,%eax
  1010e0:	c1 e0 02             	shl    $0x2,%eax
  1010e3:	01 d0                	add    %edx,%eax
  1010e5:	c1 e0 04             	shl    $0x4,%eax
  1010e8:	29 c1                	sub    %eax,%ecx
  1010ea:	89 c8                	mov    %ecx,%eax
  1010ec:	0f b7 c0             	movzwl %ax,%eax
  1010ef:	29 c3                	sub    %eax,%ebx
  1010f1:	89 d8                	mov    %ebx,%eax
  1010f3:	0f b7 c0             	movzwl %ax,%eax
  1010f6:	66 a3 44 a4 11 00    	mov    %ax,0x11a444
        break;
  1010fc:	eb 2b                	jmp    101129 <cga_putc+0xf1>
    default:
        crt_buf[crt_pos ++] = c;     // write the character
  1010fe:	8b 0d 40 a4 11 00    	mov    0x11a440,%ecx
  101104:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  10110b:	8d 50 01             	lea    0x1(%eax),%edx
  10110e:	0f b7 d2             	movzwl %dx,%edx
  101111:	66 89 15 44 a4 11 00 	mov    %dx,0x11a444
  101118:	01 c0                	add    %eax,%eax
  10111a:	8d 14 01             	lea    (%ecx,%eax,1),%edx
  10111d:	8b 45 08             	mov    0x8(%ebp),%eax
  101120:	0f b7 c0             	movzwl %ax,%eax
  101123:	66 89 02             	mov    %ax,(%edx)
        break;
  101126:	eb 01                	jmp    101129 <cga_putc+0xf1>
    case '\b':
        if (crt_pos > 0) {
            crt_pos --;
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
        }
        break;
  101128:	90                   	nop
        crt_buf[crt_pos ++] = c;     // write the character
        break;
    }

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
  101129:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  101130:	3d cf 07 00 00       	cmp    $0x7cf,%eax
  101135:	76 5d                	jbe    101194 <cga_putc+0x15c>
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
  101137:	a1 40 a4 11 00       	mov    0x11a440,%eax
  10113c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  101142:	a1 40 a4 11 00       	mov    0x11a440,%eax
  101147:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  10114e:	00 
  10114f:	89 54 24 04          	mov    %edx,0x4(%esp)
  101153:	89 04 24             	mov    %eax,(%esp)
  101156:	e8 88 43 00 00       	call   1054e3 <memmove>
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
  10115b:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
  101162:	eb 14                	jmp    101178 <cga_putc+0x140>
            crt_buf[i] = 0x0700 | ' ';
  101164:	a1 40 a4 11 00       	mov    0x11a440,%eax
  101169:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10116c:	01 d2                	add    %edx,%edx
  10116e:	01 d0                	add    %edx,%eax
  101170:	66 c7 00 20 07       	movw   $0x720,(%eax)

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
  101175:	ff 45 f4             	incl   -0xc(%ebp)
  101178:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
  10117f:	7e e3                	jle    101164 <cga_putc+0x12c>
            crt_buf[i] = 0x0700 | ' ';
        }
        crt_pos -= CRT_COLS;
  101181:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  101188:	83 e8 50             	sub    $0x50,%eax
  10118b:	0f b7 c0             	movzwl %ax,%eax
  10118e:	66 a3 44 a4 11 00    	mov    %ax,0x11a444
    }

    // move that little blinky thing
    outb(addr_6845, 14);
  101194:	0f b7 05 46 a4 11 00 	movzwl 0x11a446,%eax
  10119b:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
  10119f:	c6 45 e8 0e          	movb   $0xe,-0x18(%ebp)
  1011a3:	0f b6 45 e8          	movzbl -0x18(%ebp),%eax
  1011a7:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  1011ab:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos >> 8);
  1011ac:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  1011b3:	c1 e8 08             	shr    $0x8,%eax
  1011b6:	0f b7 c0             	movzwl %ax,%eax
  1011b9:	0f b6 c0             	movzbl %al,%eax
  1011bc:	0f b7 15 46 a4 11 00 	movzwl 0x11a446,%edx
  1011c3:	42                   	inc    %edx
  1011c4:	0f b7 d2             	movzwl %dx,%edx
  1011c7:	66 89 55 f0          	mov    %dx,-0x10(%ebp)
  1011cb:	88 45 e9             	mov    %al,-0x17(%ebp)
  1011ce:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
  1011d2:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1011d5:	ee                   	out    %al,(%dx)
    outb(addr_6845, 15);
  1011d6:	0f b7 05 46 a4 11 00 	movzwl 0x11a446,%eax
  1011dd:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
  1011e1:	c6 45 ea 0f          	movb   $0xf,-0x16(%ebp)
  1011e5:	0f b6 45 ea          	movzbl -0x16(%ebp),%eax
  1011e9:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  1011ed:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos);
  1011ee:	0f b7 05 44 a4 11 00 	movzwl 0x11a444,%eax
  1011f5:	0f b6 c0             	movzbl %al,%eax
  1011f8:	0f b7 15 46 a4 11 00 	movzwl 0x11a446,%edx
  1011ff:	42                   	inc    %edx
  101200:	0f b7 d2             	movzwl %dx,%edx
  101203:	66 89 55 ec          	mov    %dx,-0x14(%ebp)
  101207:	88 45 eb             	mov    %al,-0x15(%ebp)
  10120a:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  10120e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  101211:	ee                   	out    %al,(%dx)
}
  101212:	90                   	nop
  101213:	83 c4 24             	add    $0x24,%esp
  101216:	5b                   	pop    %ebx
  101217:	5d                   	pop    %ebp
  101218:	c3                   	ret    

00101219 <serial_putc_sub>:

static void
serial_putc_sub(int c) {
  101219:	55                   	push   %ebp
  10121a:	89 e5                	mov    %esp,%ebp
  10121c:	83 ec 10             	sub    $0x10,%esp
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
  10121f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  101226:	eb 08                	jmp    101230 <serial_putc_sub+0x17>
        delay();
  101228:	e8 4c fb ff ff       	call   100d79 <delay>
}

static void
serial_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
  10122d:	ff 45 fc             	incl   -0x4(%ebp)
  101230:	66 c7 45 f8 fd 03    	movw   $0x3fd,-0x8(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  101236:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101239:	89 c2                	mov    %eax,%edx
  10123b:	ec                   	in     (%dx),%al
  10123c:	88 45 f7             	mov    %al,-0x9(%ebp)
    return data;
  10123f:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  101243:	0f b6 c0             	movzbl %al,%eax
  101246:	83 e0 20             	and    $0x20,%eax
  101249:	85 c0                	test   %eax,%eax
  10124b:	75 09                	jne    101256 <serial_putc_sub+0x3d>
  10124d:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
  101254:	7e d2                	jle    101228 <serial_putc_sub+0xf>
        delay();
    }
    outb(COM1 + COM_TX, c);
  101256:	8b 45 08             	mov    0x8(%ebp),%eax
  101259:	0f b6 c0             	movzbl %al,%eax
  10125c:	66 c7 45 fa f8 03    	movw   $0x3f8,-0x6(%ebp)
  101262:	88 45 f6             	mov    %al,-0xa(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  101265:	0f b6 45 f6          	movzbl -0xa(%ebp),%eax
  101269:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
  10126d:	ee                   	out    %al,(%dx)
}
  10126e:	90                   	nop
  10126f:	c9                   	leave  
  101270:	c3                   	ret    

00101271 <serial_putc>:

/* serial_putc - print character to serial port */
static void
serial_putc(int c) {
  101271:	55                   	push   %ebp
  101272:	89 e5                	mov    %esp,%ebp
  101274:	83 ec 04             	sub    $0x4,%esp
    if (c != '\b') {
  101277:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
  10127b:	74 0d                	je     10128a <serial_putc+0x19>
        serial_putc_sub(c);
  10127d:	8b 45 08             	mov    0x8(%ebp),%eax
  101280:	89 04 24             	mov    %eax,(%esp)
  101283:	e8 91 ff ff ff       	call   101219 <serial_putc_sub>
    else {
        serial_putc_sub('\b');
        serial_putc_sub(' ');
        serial_putc_sub('\b');
    }
}
  101288:	eb 24                	jmp    1012ae <serial_putc+0x3d>
serial_putc(int c) {
    if (c != '\b') {
        serial_putc_sub(c);
    }
    else {
        serial_putc_sub('\b');
  10128a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  101291:	e8 83 ff ff ff       	call   101219 <serial_putc_sub>
        serial_putc_sub(' ');
  101296:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10129d:	e8 77 ff ff ff       	call   101219 <serial_putc_sub>
        serial_putc_sub('\b');
  1012a2:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
  1012a9:	e8 6b ff ff ff       	call   101219 <serial_putc_sub>
    }
}
  1012ae:	90                   	nop
  1012af:	c9                   	leave  
  1012b0:	c3                   	ret    

001012b1 <cons_intr>:
/* *
 * cons_intr - called by device interrupt routines to feed input
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
  1012b1:	55                   	push   %ebp
  1012b2:	89 e5                	mov    %esp,%ebp
  1012b4:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = (*proc)()) != -1) {
  1012b7:	eb 33                	jmp    1012ec <cons_intr+0x3b>
        if (c != 0) {
  1012b9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1012bd:	74 2d                	je     1012ec <cons_intr+0x3b>
            cons.buf[cons.wpos ++] = c;
  1012bf:	a1 64 a6 11 00       	mov    0x11a664,%eax
  1012c4:	8d 50 01             	lea    0x1(%eax),%edx
  1012c7:	89 15 64 a6 11 00    	mov    %edx,0x11a664
  1012cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1012d0:	88 90 60 a4 11 00    	mov    %dl,0x11a460(%eax)
            if (cons.wpos == CONSBUFSIZE) {
  1012d6:	a1 64 a6 11 00       	mov    0x11a664,%eax
  1012db:	3d 00 02 00 00       	cmp    $0x200,%eax
  1012e0:	75 0a                	jne    1012ec <cons_intr+0x3b>
                cons.wpos = 0;
  1012e2:	c7 05 64 a6 11 00 00 	movl   $0x0,0x11a664
  1012e9:	00 00 00 
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
    int c;
    while ((c = (*proc)()) != -1) {
  1012ec:	8b 45 08             	mov    0x8(%ebp),%eax
  1012ef:	ff d0                	call   *%eax
  1012f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1012f4:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  1012f8:	75 bf                	jne    1012b9 <cons_intr+0x8>
            if (cons.wpos == CONSBUFSIZE) {
                cons.wpos = 0;
            }
        }
    }
}
  1012fa:	90                   	nop
  1012fb:	c9                   	leave  
  1012fc:	c3                   	ret    

001012fd <serial_proc_data>:

/* serial_proc_data - get data from serial port */
static int
serial_proc_data(void) {
  1012fd:	55                   	push   %ebp
  1012fe:	89 e5                	mov    %esp,%ebp
  101300:	83 ec 10             	sub    $0x10,%esp
  101303:	66 c7 45 f8 fd 03    	movw   $0x3fd,-0x8(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  101309:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10130c:	89 c2                	mov    %eax,%edx
  10130e:	ec                   	in     (%dx),%al
  10130f:	88 45 f7             	mov    %al,-0x9(%ebp)
    return data;
  101312:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
    if (!(inb(COM1 + COM_LSR) & COM_LSR_DATA)) {
  101316:	0f b6 c0             	movzbl %al,%eax
  101319:	83 e0 01             	and    $0x1,%eax
  10131c:	85 c0                	test   %eax,%eax
  10131e:	75 07                	jne    101327 <serial_proc_data+0x2a>
        return -1;
  101320:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101325:	eb 2a                	jmp    101351 <serial_proc_data+0x54>
  101327:	66 c7 45 fa f8 03    	movw   $0x3f8,-0x6(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  10132d:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
  101331:	89 c2                	mov    %eax,%edx
  101333:	ec                   	in     (%dx),%al
  101334:	88 45 f6             	mov    %al,-0xa(%ebp)
    return data;
  101337:	0f b6 45 f6          	movzbl -0xa(%ebp),%eax
    }
    int c = inb(COM1 + COM_RX);
  10133b:	0f b6 c0             	movzbl %al,%eax
  10133e:	89 45 fc             	mov    %eax,-0x4(%ebp)
    if (c == 127) {
  101341:	83 7d fc 7f          	cmpl   $0x7f,-0x4(%ebp)
  101345:	75 07                	jne    10134e <serial_proc_data+0x51>
        c = '\b';
  101347:	c7 45 fc 08 00 00 00 	movl   $0x8,-0x4(%ebp)
    }
    return c;
  10134e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  101351:	c9                   	leave  
  101352:	c3                   	ret    

00101353 <serial_intr>:

/* serial_intr - try to feed input characters from serial port */
void
serial_intr(void) {
  101353:	55                   	push   %ebp
  101354:	89 e5                	mov    %esp,%ebp
  101356:	83 ec 18             	sub    $0x18,%esp
    if (serial_exists) {
  101359:	a1 48 a4 11 00       	mov    0x11a448,%eax
  10135e:	85 c0                	test   %eax,%eax
  101360:	74 0c                	je     10136e <serial_intr+0x1b>
        cons_intr(serial_proc_data);
  101362:	c7 04 24 fd 12 10 00 	movl   $0x1012fd,(%esp)
  101369:	e8 43 ff ff ff       	call   1012b1 <cons_intr>
    }
}
  10136e:	90                   	nop
  10136f:	c9                   	leave  
  101370:	c3                   	ret    

00101371 <kbd_proc_data>:
 *
 * The kbd_proc_data() function gets data from the keyboard.
 * If we finish a character, return it, else 0. And return -1 if no data.
 * */
static int
kbd_proc_data(void) {
  101371:	55                   	push   %ebp
  101372:	89 e5                	mov    %esp,%ebp
  101374:	83 ec 28             	sub    $0x28,%esp
  101377:	66 c7 45 ec 64 00    	movw   $0x64,-0x14(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  10137d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101380:	89 c2                	mov    %eax,%edx
  101382:	ec                   	in     (%dx),%al
  101383:	88 45 eb             	mov    %al,-0x15(%ebp)
    return data;
  101386:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
    int c;
    uint8_t data;
    static uint32_t shift;

    if ((inb(KBSTATP) & KBS_DIB) == 0) {
  10138a:	0f b6 c0             	movzbl %al,%eax
  10138d:	83 e0 01             	and    $0x1,%eax
  101390:	85 c0                	test   %eax,%eax
  101392:	75 0a                	jne    10139e <kbd_proc_data+0x2d>
        return -1;
  101394:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101399:	e9 56 01 00 00       	jmp    1014f4 <kbd_proc_data+0x183>
  10139e:	66 c7 45 f0 60 00    	movw   $0x60,-0x10(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
  1013a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1013a7:	89 c2                	mov    %eax,%edx
  1013a9:	ec                   	in     (%dx),%al
  1013aa:	88 45 ea             	mov    %al,-0x16(%ebp)
    return data;
  1013ad:	0f b6 45 ea          	movzbl -0x16(%ebp),%eax
    }

    data = inb(KBDATAP);
  1013b1:	88 45 f3             	mov    %al,-0xd(%ebp)

    if (data == 0xE0) {
  1013b4:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
  1013b8:	75 17                	jne    1013d1 <kbd_proc_data+0x60>
        // E0 escape character
        shift |= E0ESC;
  1013ba:	a1 68 a6 11 00       	mov    0x11a668,%eax
  1013bf:	83 c8 40             	or     $0x40,%eax
  1013c2:	a3 68 a6 11 00       	mov    %eax,0x11a668
        return 0;
  1013c7:	b8 00 00 00 00       	mov    $0x0,%eax
  1013cc:	e9 23 01 00 00       	jmp    1014f4 <kbd_proc_data+0x183>
    } else if (data & 0x80) {
  1013d1:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1013d5:	84 c0                	test   %al,%al
  1013d7:	79 45                	jns    10141e <kbd_proc_data+0xad>
        // Key released
        data = (shift & E0ESC ? data : data & 0x7F);
  1013d9:	a1 68 a6 11 00       	mov    0x11a668,%eax
  1013de:	83 e0 40             	and    $0x40,%eax
  1013e1:	85 c0                	test   %eax,%eax
  1013e3:	75 08                	jne    1013ed <kbd_proc_data+0x7c>
  1013e5:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1013e9:	24 7f                	and    $0x7f,%al
  1013eb:	eb 04                	jmp    1013f1 <kbd_proc_data+0x80>
  1013ed:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1013f1:	88 45 f3             	mov    %al,-0xd(%ebp)
        shift &= ~(shiftcode[data] | E0ESC);
  1013f4:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1013f8:	0f b6 80 40 70 11 00 	movzbl 0x117040(%eax),%eax
  1013ff:	0c 40                	or     $0x40,%al
  101401:	0f b6 c0             	movzbl %al,%eax
  101404:	f7 d0                	not    %eax
  101406:	89 c2                	mov    %eax,%edx
  101408:	a1 68 a6 11 00       	mov    0x11a668,%eax
  10140d:	21 d0                	and    %edx,%eax
  10140f:	a3 68 a6 11 00       	mov    %eax,0x11a668
        return 0;
  101414:	b8 00 00 00 00       	mov    $0x0,%eax
  101419:	e9 d6 00 00 00       	jmp    1014f4 <kbd_proc_data+0x183>
    } else if (shift & E0ESC) {
  10141e:	a1 68 a6 11 00       	mov    0x11a668,%eax
  101423:	83 e0 40             	and    $0x40,%eax
  101426:	85 c0                	test   %eax,%eax
  101428:	74 11                	je     10143b <kbd_proc_data+0xca>
        // Last character was an E0 escape; or with 0x80
        data |= 0x80;
  10142a:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
        shift &= ~E0ESC;
  10142e:	a1 68 a6 11 00       	mov    0x11a668,%eax
  101433:	83 e0 bf             	and    $0xffffffbf,%eax
  101436:	a3 68 a6 11 00       	mov    %eax,0x11a668
    }

    shift |= shiftcode[data];
  10143b:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10143f:	0f b6 80 40 70 11 00 	movzbl 0x117040(%eax),%eax
  101446:	0f b6 d0             	movzbl %al,%edx
  101449:	a1 68 a6 11 00       	mov    0x11a668,%eax
  10144e:	09 d0                	or     %edx,%eax
  101450:	a3 68 a6 11 00       	mov    %eax,0x11a668
    shift ^= togglecode[data];
  101455:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101459:	0f b6 80 40 71 11 00 	movzbl 0x117140(%eax),%eax
  101460:	0f b6 d0             	movzbl %al,%edx
  101463:	a1 68 a6 11 00       	mov    0x11a668,%eax
  101468:	31 d0                	xor    %edx,%eax
  10146a:	a3 68 a6 11 00       	mov    %eax,0x11a668

    c = charcode[shift & (CTL | SHIFT)][data];
  10146f:	a1 68 a6 11 00       	mov    0x11a668,%eax
  101474:	83 e0 03             	and    $0x3,%eax
  101477:	8b 14 85 40 75 11 00 	mov    0x117540(,%eax,4),%edx
  10147e:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101482:	01 d0                	add    %edx,%eax
  101484:	0f b6 00             	movzbl (%eax),%eax
  101487:	0f b6 c0             	movzbl %al,%eax
  10148a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (shift & CAPSLOCK) {
  10148d:	a1 68 a6 11 00       	mov    0x11a668,%eax
  101492:	83 e0 08             	and    $0x8,%eax
  101495:	85 c0                	test   %eax,%eax
  101497:	74 22                	je     1014bb <kbd_proc_data+0x14a>
        if ('a' <= c && c <= 'z')
  101499:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
  10149d:	7e 0c                	jle    1014ab <kbd_proc_data+0x13a>
  10149f:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
  1014a3:	7f 06                	jg     1014ab <kbd_proc_data+0x13a>
            c += 'A' - 'a';
  1014a5:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
  1014a9:	eb 10                	jmp    1014bb <kbd_proc_data+0x14a>
        else if ('A' <= c && c <= 'Z')
  1014ab:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
  1014af:	7e 0a                	jle    1014bb <kbd_proc_data+0x14a>
  1014b1:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
  1014b5:	7f 04                	jg     1014bb <kbd_proc_data+0x14a>
            c += 'a' - 'A';
  1014b7:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
    }

    // Process special keys
    // Ctrl-Alt-Del: reboot
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  1014bb:	a1 68 a6 11 00       	mov    0x11a668,%eax
  1014c0:	f7 d0                	not    %eax
  1014c2:	83 e0 06             	and    $0x6,%eax
  1014c5:	85 c0                	test   %eax,%eax
  1014c7:	75 28                	jne    1014f1 <kbd_proc_data+0x180>
  1014c9:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
  1014d0:	75 1f                	jne    1014f1 <kbd_proc_data+0x180>
        cprintf("Rebooting!\n");
  1014d2:	c7 04 24 a5 5f 10 00 	movl   $0x105fa5,(%esp)
  1014d9:	e8 b4 ed ff ff       	call   100292 <cprintf>
  1014de:	66 c7 45 ee 92 00    	movw   $0x92,-0x12(%ebp)
  1014e4:	c6 45 e9 03          	movb   $0x3,-0x17(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
  1014e8:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
  1014ec:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  1014f0:	ee                   	out    %al,(%dx)
        outb(0x92, 0x3); // courtesy of Chris Frost
    }
    return c;
  1014f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1014f4:	c9                   	leave  
  1014f5:	c3                   	ret    

001014f6 <kbd_intr>:

/* kbd_intr - try to feed input characters from keyboard */
static void
kbd_intr(void) {
  1014f6:	55                   	push   %ebp
  1014f7:	89 e5                	mov    %esp,%ebp
  1014f9:	83 ec 18             	sub    $0x18,%esp
    cons_intr(kbd_proc_data);
  1014fc:	c7 04 24 71 13 10 00 	movl   $0x101371,(%esp)
  101503:	e8 a9 fd ff ff       	call   1012b1 <cons_intr>
}
  101508:	90                   	nop
  101509:	c9                   	leave  
  10150a:	c3                   	ret    

0010150b <kbd_init>:

static void
kbd_init(void) {
  10150b:	55                   	push   %ebp
  10150c:	89 e5                	mov    %esp,%ebp
  10150e:	83 ec 18             	sub    $0x18,%esp
    // drain the kbd buffer
    kbd_intr();
  101511:	e8 e0 ff ff ff       	call   1014f6 <kbd_intr>
    pic_enable(IRQ_KBD);
  101516:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10151d:	e8 34 01 00 00       	call   101656 <pic_enable>
}
  101522:	90                   	nop
  101523:	c9                   	leave  
  101524:	c3                   	ret    

00101525 <cons_init>:

/* cons_init - initializes the console devices */
void
cons_init(void) {
  101525:	55                   	push   %ebp
  101526:	89 e5                	mov    %esp,%ebp
  101528:	83 ec 18             	sub    $0x18,%esp
    cga_init();
  10152b:	e8 90 f8 ff ff       	call   100dc0 <cga_init>
    serial_init();
  101530:	e8 6d f9 ff ff       	call   100ea2 <serial_init>
    kbd_init();
  101535:	e8 d1 ff ff ff       	call   10150b <kbd_init>
    if (!serial_exists) {
  10153a:	a1 48 a4 11 00       	mov    0x11a448,%eax
  10153f:	85 c0                	test   %eax,%eax
  101541:	75 0c                	jne    10154f <cons_init+0x2a>
        cprintf("serial port does not exist!!\n");
  101543:	c7 04 24 b1 5f 10 00 	movl   $0x105fb1,(%esp)
  10154a:	e8 43 ed ff ff       	call   100292 <cprintf>
    }
}
  10154f:	90                   	nop
  101550:	c9                   	leave  
  101551:	c3                   	ret    

00101552 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void
cons_putc(int c) {
  101552:	55                   	push   %ebp
  101553:	89 e5                	mov    %esp,%ebp
  101555:	83 ec 28             	sub    $0x28,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
  101558:	e8 de f7 ff ff       	call   100d3b <__intr_save>
  10155d:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        lpt_putc(c);
  101560:	8b 45 08             	mov    0x8(%ebp),%eax
  101563:	89 04 24             	mov    %eax,(%esp)
  101566:	e8 8d fa ff ff       	call   100ff8 <lpt_putc>
        cga_putc(c);
  10156b:	8b 45 08             	mov    0x8(%ebp),%eax
  10156e:	89 04 24             	mov    %eax,(%esp)
  101571:	e8 c2 fa ff ff       	call   101038 <cga_putc>
        serial_putc(c);
  101576:	8b 45 08             	mov    0x8(%ebp),%eax
  101579:	89 04 24             	mov    %eax,(%esp)
  10157c:	e8 f0 fc ff ff       	call   101271 <serial_putc>
    }
    local_intr_restore(intr_flag);
  101581:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101584:	89 04 24             	mov    %eax,(%esp)
  101587:	e8 d9 f7 ff ff       	call   100d65 <__intr_restore>
}
  10158c:	90                   	nop
  10158d:	c9                   	leave  
  10158e:	c3                   	ret    

0010158f <cons_getc>:
/* *
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int
cons_getc(void) {
  10158f:	55                   	push   %ebp
  101590:	89 e5                	mov    %esp,%ebp
  101592:	83 ec 28             	sub    $0x28,%esp
    int c = 0;
  101595:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
  10159c:	e8 9a f7 ff ff       	call   100d3b <__intr_save>
  1015a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        // poll for any pending input characters,
        // so that this function works even when interrupts are disabled
        // (e.g., when called from the kernel monitor).
        serial_intr();
  1015a4:	e8 aa fd ff ff       	call   101353 <serial_intr>
        kbd_intr();
  1015a9:	e8 48 ff ff ff       	call   1014f6 <kbd_intr>

        // grab the next character from the input buffer.
        if (cons.rpos != cons.wpos) {
  1015ae:	8b 15 60 a6 11 00    	mov    0x11a660,%edx
  1015b4:	a1 64 a6 11 00       	mov    0x11a664,%eax
  1015b9:	39 c2                	cmp    %eax,%edx
  1015bb:	74 31                	je     1015ee <cons_getc+0x5f>
            c = cons.buf[cons.rpos ++];
  1015bd:	a1 60 a6 11 00       	mov    0x11a660,%eax
  1015c2:	8d 50 01             	lea    0x1(%eax),%edx
  1015c5:	89 15 60 a6 11 00    	mov    %edx,0x11a660
  1015cb:	0f b6 80 60 a4 11 00 	movzbl 0x11a460(%eax),%eax
  1015d2:	0f b6 c0             	movzbl %al,%eax
  1015d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
            if (cons.rpos == CONSBUFSIZE) {
  1015d8:	a1 60 a6 11 00       	mov    0x11a660,%eax
  1015dd:	3d 00 02 00 00       	cmp    $0x200,%eax
  1015e2:	75 0a                	jne    1015ee <cons_getc+0x5f>
                cons.rpos = 0;
  1015e4:	c7 05 60 a6 11 00 00 	movl   $0x0,0x11a660
  1015eb:	00 00 00 
            }
        }
    }
    local_intr_restore(intr_flag);
  1015ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1015f1:	89 04 24             	mov    %eax,(%esp)
  1015f4:	e8 6c f7 ff ff       	call   100d65 <__intr_restore>
    return c;
  1015f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1015fc:	c9                   	leave  
  1015fd:	c3                   	ret    

001015fe <pic_setmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static uint16_t irq_mask = 0xFFFF & ~(1 << IRQ_SLAVE);
static bool did_init = 0;

static void
pic_setmask(uint16_t mask) {
  1015fe:	55                   	push   %ebp
  1015ff:	89 e5                	mov    %esp,%ebp
  101601:	83 ec 14             	sub    $0x14,%esp
  101604:	8b 45 08             	mov    0x8(%ebp),%eax
  101607:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
    irq_mask = mask;
  10160b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10160e:	66 a3 50 75 11 00    	mov    %ax,0x117550
    if (did_init) {
  101614:	a1 6c a6 11 00       	mov    0x11a66c,%eax
  101619:	85 c0                	test   %eax,%eax
  10161b:	74 36                	je     101653 <pic_setmask+0x55>
        outb(IO_PIC1 + 1, mask);
  10161d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101620:	0f b6 c0             	movzbl %al,%eax
  101623:	66 c7 45 fe 21 00    	movw   $0x21,-0x2(%ebp)
  101629:	88 45 fa             	mov    %al,-0x6(%ebp)
  10162c:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
  101630:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
  101634:	ee                   	out    %al,(%dx)
        outb(IO_PIC2 + 1, mask >> 8);
  101635:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  101639:	c1 e8 08             	shr    $0x8,%eax
  10163c:	0f b7 c0             	movzwl %ax,%eax
  10163f:	0f b6 c0             	movzbl %al,%eax
  101642:	66 c7 45 fc a1 00    	movw   $0xa1,-0x4(%ebp)
  101648:	88 45 fb             	mov    %al,-0x5(%ebp)
  10164b:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  10164f:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101652:	ee                   	out    %al,(%dx)
    }
}
  101653:	90                   	nop
  101654:	c9                   	leave  
  101655:	c3                   	ret    

00101656 <pic_enable>:

void
pic_enable(unsigned int irq) {
  101656:	55                   	push   %ebp
  101657:	89 e5                	mov    %esp,%ebp
  101659:	83 ec 04             	sub    $0x4,%esp
    pic_setmask(irq_mask & ~(1 << irq));
  10165c:	8b 45 08             	mov    0x8(%ebp),%eax
  10165f:	ba 01 00 00 00       	mov    $0x1,%edx
  101664:	88 c1                	mov    %al,%cl
  101666:	d3 e2                	shl    %cl,%edx
  101668:	89 d0                	mov    %edx,%eax
  10166a:	98                   	cwtl   
  10166b:	f7 d0                	not    %eax
  10166d:	0f bf d0             	movswl %ax,%edx
  101670:	0f b7 05 50 75 11 00 	movzwl 0x117550,%eax
  101677:	98                   	cwtl   
  101678:	21 d0                	and    %edx,%eax
  10167a:	98                   	cwtl   
  10167b:	0f b7 c0             	movzwl %ax,%eax
  10167e:	89 04 24             	mov    %eax,(%esp)
  101681:	e8 78 ff ff ff       	call   1015fe <pic_setmask>
}
  101686:	90                   	nop
  101687:	c9                   	leave  
  101688:	c3                   	ret    

00101689 <pic_init>:

/* pic_init - initialize the 8259A interrupt controllers */
void
pic_init(void) {
  101689:	55                   	push   %ebp
  10168a:	89 e5                	mov    %esp,%ebp
  10168c:	83 ec 34             	sub    $0x34,%esp
    did_init = 1;
  10168f:	c7 05 6c a6 11 00 01 	movl   $0x1,0x11a66c
  101696:	00 00 00 
  101699:	66 c7 45 fe 21 00    	movw   $0x21,-0x2(%ebp)
  10169f:	c6 45 d6 ff          	movb   $0xff,-0x2a(%ebp)
  1016a3:	0f b6 45 d6          	movzbl -0x2a(%ebp),%eax
  1016a7:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
  1016ab:	ee                   	out    %al,(%dx)
  1016ac:	66 c7 45 fc a1 00    	movw   $0xa1,-0x4(%ebp)
  1016b2:	c6 45 d7 ff          	movb   $0xff,-0x29(%ebp)
  1016b6:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
  1016ba:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1016bd:	ee                   	out    %al,(%dx)
  1016be:	66 c7 45 fa 20 00    	movw   $0x20,-0x6(%ebp)
  1016c4:	c6 45 d8 11          	movb   $0x11,-0x28(%ebp)
  1016c8:	0f b6 45 d8          	movzbl -0x28(%ebp),%eax
  1016cc:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
  1016d0:	ee                   	out    %al,(%dx)
  1016d1:	66 c7 45 f8 21 00    	movw   $0x21,-0x8(%ebp)
  1016d7:	c6 45 d9 20          	movb   $0x20,-0x27(%ebp)
  1016db:	0f b6 45 d9          	movzbl -0x27(%ebp),%eax
  1016df:	8b 55 f8             	mov    -0x8(%ebp),%edx
  1016e2:	ee                   	out    %al,(%dx)
  1016e3:	66 c7 45 f6 21 00    	movw   $0x21,-0xa(%ebp)
  1016e9:	c6 45 da 04          	movb   $0x4,-0x26(%ebp)
  1016ed:	0f b6 45 da          	movzbl -0x26(%ebp),%eax
  1016f1:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  1016f5:	ee                   	out    %al,(%dx)
  1016f6:	66 c7 45 f4 21 00    	movw   $0x21,-0xc(%ebp)
  1016fc:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
  101700:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101704:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101707:	ee                   	out    %al,(%dx)
  101708:	66 c7 45 f2 a0 00    	movw   $0xa0,-0xe(%ebp)
  10170e:	c6 45 dc 11          	movb   $0x11,-0x24(%ebp)
  101712:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  101716:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
  10171a:	ee                   	out    %al,(%dx)
  10171b:	66 c7 45 f0 a1 00    	movw   $0xa1,-0x10(%ebp)
  101721:	c6 45 dd 28          	movb   $0x28,-0x23(%ebp)
  101725:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
  101729:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10172c:	ee                   	out    %al,(%dx)
  10172d:	66 c7 45 ee a1 00    	movw   $0xa1,-0x12(%ebp)
  101733:	c6 45 de 02          	movb   $0x2,-0x22(%ebp)
  101737:	0f b6 45 de          	movzbl -0x22(%ebp),%eax
  10173b:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  10173f:	ee                   	out    %al,(%dx)
  101740:	66 c7 45 ec a1 00    	movw   $0xa1,-0x14(%ebp)
  101746:	c6 45 df 03          	movb   $0x3,-0x21(%ebp)
  10174a:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
  10174e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  101751:	ee                   	out    %al,(%dx)
  101752:	66 c7 45 ea 20 00    	movw   $0x20,-0x16(%ebp)
  101758:	c6 45 e0 68          	movb   $0x68,-0x20(%ebp)
  10175c:	0f b6 45 e0          	movzbl -0x20(%ebp),%eax
  101760:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
  101764:	ee                   	out    %al,(%dx)
  101765:	66 c7 45 e8 20 00    	movw   $0x20,-0x18(%ebp)
  10176b:	c6 45 e1 0a          	movb   $0xa,-0x1f(%ebp)
  10176f:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
  101773:	8b 55 e8             	mov    -0x18(%ebp),%edx
  101776:	ee                   	out    %al,(%dx)
  101777:	66 c7 45 e6 a0 00    	movw   $0xa0,-0x1a(%ebp)
  10177d:	c6 45 e2 68          	movb   $0x68,-0x1e(%ebp)
  101781:	0f b6 45 e2          	movzbl -0x1e(%ebp),%eax
  101785:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
  101789:	ee                   	out    %al,(%dx)
  10178a:	66 c7 45 e4 a0 00    	movw   $0xa0,-0x1c(%ebp)
  101790:	c6 45 e3 0a          	movb   $0xa,-0x1d(%ebp)
  101794:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101798:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10179b:	ee                   	out    %al,(%dx)
    outb(IO_PIC1, 0x0a);    // read IRR by default

    outb(IO_PIC2, 0x68);    // OCW3
    outb(IO_PIC2, 0x0a);    // OCW3

    if (irq_mask != 0xFFFF) {
  10179c:	0f b7 05 50 75 11 00 	movzwl 0x117550,%eax
  1017a3:	3d ff ff 00 00       	cmp    $0xffff,%eax
  1017a8:	74 0f                	je     1017b9 <pic_init+0x130>
        pic_setmask(irq_mask);
  1017aa:	0f b7 05 50 75 11 00 	movzwl 0x117550,%eax
  1017b1:	89 04 24             	mov    %eax,(%esp)
  1017b4:	e8 45 fe ff ff       	call   1015fe <pic_setmask>
    }
}
  1017b9:	90                   	nop
  1017ba:	c9                   	leave  
  1017bb:	c3                   	ret    

001017bc <intr_enable>:
#include <x86.h>
#include <intr.h>

/* intr_enable - enable irq interrupt */
void
intr_enable(void) {
  1017bc:	55                   	push   %ebp
  1017bd:	89 e5                	mov    %esp,%ebp
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
}

static inline void
sti(void) {
    asm volatile ("sti");
  1017bf:	fb                   	sti    
    sti();
}
  1017c0:	90                   	nop
  1017c1:	5d                   	pop    %ebp
  1017c2:	c3                   	ret    

001017c3 <intr_disable>:

/* intr_disable - disable irq interrupt */
void
intr_disable(void) {
  1017c3:	55                   	push   %ebp
  1017c4:	89 e5                	mov    %esp,%ebp
}

static inline void
cli(void) {
    asm volatile ("cli" ::: "memory");
  1017c6:	fa                   	cli    
    cli();
}
  1017c7:	90                   	nop
  1017c8:	5d                   	pop    %ebp
  1017c9:	c3                   	ret    

001017ca <print_ticks>:
#include <console.h>
#include <kdebug.h>

#define TICK_NUM 100

static void print_ticks() {
  1017ca:	55                   	push   %ebp
  1017cb:	89 e5                	mov    %esp,%ebp
  1017cd:	83 ec 18             	sub    $0x18,%esp
    cprintf("%d ticks\n",TICK_NUM);
  1017d0:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  1017d7:	00 
  1017d8:	c7 04 24 e0 5f 10 00 	movl   $0x105fe0,(%esp)
  1017df:	e8 ae ea ff ff       	call   100292 <cprintf>
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}
  1017e4:	90                   	nop
  1017e5:	c9                   	leave  
  1017e6:	c3                   	ret    

001017e7 <idt_init>:
    sizeof(idt) - 1, (uintptr_t)idt
};

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S */
void
idt_init(void) {
  1017e7:	55                   	push   %ebp
  1017e8:	89 e5                	mov    %esp,%ebp
      *     Can you see idt[256] in this file? Yes, it's IDT! you can use SETGATE macro to setup each item of IDT
      * (3) After setup the contents of IDT, you will let CPU know where is the IDT by using 'lidt' instruction.
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
}
  1017ea:	90                   	nop
  1017eb:	5d                   	pop    %ebp
  1017ec:	c3                   	ret    

001017ed <trapname>:

static const char *
trapname(int trapno) {
  1017ed:	55                   	push   %ebp
  1017ee:	89 e5                	mov    %esp,%ebp
        "Alignment Check",
        "Machine-Check",
        "SIMD Floating-Point Exception"
    };

    if (trapno < sizeof(excnames)/sizeof(const char * const)) {
  1017f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1017f3:	83 f8 13             	cmp    $0x13,%eax
  1017f6:	77 0c                	ja     101804 <trapname+0x17>
        return excnames[trapno];
  1017f8:	8b 45 08             	mov    0x8(%ebp),%eax
  1017fb:	8b 04 85 40 63 10 00 	mov    0x106340(,%eax,4),%eax
  101802:	eb 18                	jmp    10181c <trapname+0x2f>
    }
    if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16) {
  101804:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  101808:	7e 0d                	jle    101817 <trapname+0x2a>
  10180a:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  10180e:	7f 07                	jg     101817 <trapname+0x2a>
        return "Hardware Interrupt";
  101810:	b8 ea 5f 10 00       	mov    $0x105fea,%eax
  101815:	eb 05                	jmp    10181c <trapname+0x2f>
    }
    return "(unknown trap)";
  101817:	b8 fd 5f 10 00       	mov    $0x105ffd,%eax
}
  10181c:	5d                   	pop    %ebp
  10181d:	c3                   	ret    

0010181e <trap_in_kernel>:

/* trap_in_kernel - test if trap happened in kernel */
bool
trap_in_kernel(struct trapframe *tf) {
  10181e:	55                   	push   %ebp
  10181f:	89 e5                	mov    %esp,%ebp
    return (tf->tf_cs == (uint16_t)KERNEL_CS);
  101821:	8b 45 08             	mov    0x8(%ebp),%eax
  101824:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101828:	83 f8 08             	cmp    $0x8,%eax
  10182b:	0f 94 c0             	sete   %al
  10182e:	0f b6 c0             	movzbl %al,%eax
}
  101831:	5d                   	pop    %ebp
  101832:	c3                   	ret    

00101833 <print_trapframe>:
    "TF", "IF", "DF", "OF", NULL, NULL, "NT", NULL,
    "RF", "VM", "AC", "VIF", "VIP", "ID", NULL, NULL,
};

void
print_trapframe(struct trapframe *tf) {
  101833:	55                   	push   %ebp
  101834:	89 e5                	mov    %esp,%ebp
  101836:	83 ec 28             	sub    $0x28,%esp
    cprintf("trapframe at %p\n", tf);
  101839:	8b 45 08             	mov    0x8(%ebp),%eax
  10183c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101840:	c7 04 24 3e 60 10 00 	movl   $0x10603e,(%esp)
  101847:	e8 46 ea ff ff       	call   100292 <cprintf>
    print_regs(&tf->tf_regs);
  10184c:	8b 45 08             	mov    0x8(%ebp),%eax
  10184f:	89 04 24             	mov    %eax,(%esp)
  101852:	e8 91 01 00 00       	call   1019e8 <print_regs>
    cprintf("  ds   0x----%04x\n", tf->tf_ds);
  101857:	8b 45 08             	mov    0x8(%ebp),%eax
  10185a:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10185e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101862:	c7 04 24 4f 60 10 00 	movl   $0x10604f,(%esp)
  101869:	e8 24 ea ff ff       	call   100292 <cprintf>
    cprintf("  es   0x----%04x\n", tf->tf_es);
  10186e:	8b 45 08             	mov    0x8(%ebp),%eax
  101871:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101875:	89 44 24 04          	mov    %eax,0x4(%esp)
  101879:	c7 04 24 62 60 10 00 	movl   $0x106062,(%esp)
  101880:	e8 0d ea ff ff       	call   100292 <cprintf>
    cprintf("  fs   0x----%04x\n", tf->tf_fs);
  101885:	8b 45 08             	mov    0x8(%ebp),%eax
  101888:	0f b7 40 24          	movzwl 0x24(%eax),%eax
  10188c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101890:	c7 04 24 75 60 10 00 	movl   $0x106075,(%esp)
  101897:	e8 f6 e9 ff ff       	call   100292 <cprintf>
    cprintf("  gs   0x----%04x\n", tf->tf_gs);
  10189c:	8b 45 08             	mov    0x8(%ebp),%eax
  10189f:	0f b7 40 20          	movzwl 0x20(%eax),%eax
  1018a3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1018a7:	c7 04 24 88 60 10 00 	movl   $0x106088,(%esp)
  1018ae:	e8 df e9 ff ff       	call   100292 <cprintf>
    cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
  1018b3:	8b 45 08             	mov    0x8(%ebp),%eax
  1018b6:	8b 40 30             	mov    0x30(%eax),%eax
  1018b9:	89 04 24             	mov    %eax,(%esp)
  1018bc:	e8 2c ff ff ff       	call   1017ed <trapname>
  1018c1:	89 c2                	mov    %eax,%edx
  1018c3:	8b 45 08             	mov    0x8(%ebp),%eax
  1018c6:	8b 40 30             	mov    0x30(%eax),%eax
  1018c9:	89 54 24 08          	mov    %edx,0x8(%esp)
  1018cd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1018d1:	c7 04 24 9b 60 10 00 	movl   $0x10609b,(%esp)
  1018d8:	e8 b5 e9 ff ff       	call   100292 <cprintf>
    cprintf("  err  0x%08x\n", tf->tf_err);
  1018dd:	8b 45 08             	mov    0x8(%ebp),%eax
  1018e0:	8b 40 34             	mov    0x34(%eax),%eax
  1018e3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1018e7:	c7 04 24 ad 60 10 00 	movl   $0x1060ad,(%esp)
  1018ee:	e8 9f e9 ff ff       	call   100292 <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
  1018f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1018f6:	8b 40 38             	mov    0x38(%eax),%eax
  1018f9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1018fd:	c7 04 24 bc 60 10 00 	movl   $0x1060bc,(%esp)
  101904:	e8 89 e9 ff ff       	call   100292 <cprintf>
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
  101909:	8b 45 08             	mov    0x8(%ebp),%eax
  10190c:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101910:	89 44 24 04          	mov    %eax,0x4(%esp)
  101914:	c7 04 24 cb 60 10 00 	movl   $0x1060cb,(%esp)
  10191b:	e8 72 e9 ff ff       	call   100292 <cprintf>
    cprintf("  flag 0x%08x ", tf->tf_eflags);
  101920:	8b 45 08             	mov    0x8(%ebp),%eax
  101923:	8b 40 40             	mov    0x40(%eax),%eax
  101926:	89 44 24 04          	mov    %eax,0x4(%esp)
  10192a:	c7 04 24 de 60 10 00 	movl   $0x1060de,(%esp)
  101931:	e8 5c e9 ff ff       	call   100292 <cprintf>

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
  101936:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10193d:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
  101944:	eb 3d                	jmp    101983 <print_trapframe+0x150>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
  101946:	8b 45 08             	mov    0x8(%ebp),%eax
  101949:	8b 50 40             	mov    0x40(%eax),%edx
  10194c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10194f:	21 d0                	and    %edx,%eax
  101951:	85 c0                	test   %eax,%eax
  101953:	74 28                	je     10197d <print_trapframe+0x14a>
  101955:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101958:	8b 04 85 80 75 11 00 	mov    0x117580(,%eax,4),%eax
  10195f:	85 c0                	test   %eax,%eax
  101961:	74 1a                	je     10197d <print_trapframe+0x14a>
            cprintf("%s,", IA32flags[i]);
  101963:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101966:	8b 04 85 80 75 11 00 	mov    0x117580(,%eax,4),%eax
  10196d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101971:	c7 04 24 ed 60 10 00 	movl   $0x1060ed,(%esp)
  101978:	e8 15 e9 ff ff       	call   100292 <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
    cprintf("  flag 0x%08x ", tf->tf_eflags);

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
  10197d:	ff 45 f4             	incl   -0xc(%ebp)
  101980:	d1 65 f0             	shll   -0x10(%ebp)
  101983:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101986:	83 f8 17             	cmp    $0x17,%eax
  101989:	76 bb                	jbe    101946 <print_trapframe+0x113>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
            cprintf("%s,", IA32flags[i]);
        }
    }
    cprintf("IOPL=%d\n", (tf->tf_eflags & FL_IOPL_MASK) >> 12);
  10198b:	8b 45 08             	mov    0x8(%ebp),%eax
  10198e:	8b 40 40             	mov    0x40(%eax),%eax
  101991:	25 00 30 00 00       	and    $0x3000,%eax
  101996:	c1 e8 0c             	shr    $0xc,%eax
  101999:	89 44 24 04          	mov    %eax,0x4(%esp)
  10199d:	c7 04 24 f1 60 10 00 	movl   $0x1060f1,(%esp)
  1019a4:	e8 e9 e8 ff ff       	call   100292 <cprintf>

    if (!trap_in_kernel(tf)) {
  1019a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1019ac:	89 04 24             	mov    %eax,(%esp)
  1019af:	e8 6a fe ff ff       	call   10181e <trap_in_kernel>
  1019b4:	85 c0                	test   %eax,%eax
  1019b6:	75 2d                	jne    1019e5 <print_trapframe+0x1b2>
        cprintf("  esp  0x%08x\n", tf->tf_esp);
  1019b8:	8b 45 08             	mov    0x8(%ebp),%eax
  1019bb:	8b 40 44             	mov    0x44(%eax),%eax
  1019be:	89 44 24 04          	mov    %eax,0x4(%esp)
  1019c2:	c7 04 24 fa 60 10 00 	movl   $0x1060fa,(%esp)
  1019c9:	e8 c4 e8 ff ff       	call   100292 <cprintf>
        cprintf("  ss   0x----%04x\n", tf->tf_ss);
  1019ce:	8b 45 08             	mov    0x8(%ebp),%eax
  1019d1:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  1019d5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1019d9:	c7 04 24 09 61 10 00 	movl   $0x106109,(%esp)
  1019e0:	e8 ad e8 ff ff       	call   100292 <cprintf>
    }
}
  1019e5:	90                   	nop
  1019e6:	c9                   	leave  
  1019e7:	c3                   	ret    

001019e8 <print_regs>:

void
print_regs(struct pushregs *regs) {
  1019e8:	55                   	push   %ebp
  1019e9:	89 e5                	mov    %esp,%ebp
  1019eb:	83 ec 18             	sub    $0x18,%esp
    cprintf("  edi  0x%08x\n", regs->reg_edi);
  1019ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1019f1:	8b 00                	mov    (%eax),%eax
  1019f3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1019f7:	c7 04 24 1c 61 10 00 	movl   $0x10611c,(%esp)
  1019fe:	e8 8f e8 ff ff       	call   100292 <cprintf>
    cprintf("  esi  0x%08x\n", regs->reg_esi);
  101a03:	8b 45 08             	mov    0x8(%ebp),%eax
  101a06:	8b 40 04             	mov    0x4(%eax),%eax
  101a09:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a0d:	c7 04 24 2b 61 10 00 	movl   $0x10612b,(%esp)
  101a14:	e8 79 e8 ff ff       	call   100292 <cprintf>
    cprintf("  ebp  0x%08x\n", regs->reg_ebp);
  101a19:	8b 45 08             	mov    0x8(%ebp),%eax
  101a1c:	8b 40 08             	mov    0x8(%eax),%eax
  101a1f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a23:	c7 04 24 3a 61 10 00 	movl   $0x10613a,(%esp)
  101a2a:	e8 63 e8 ff ff       	call   100292 <cprintf>
    cprintf("  oesp 0x%08x\n", regs->reg_oesp);
  101a2f:	8b 45 08             	mov    0x8(%ebp),%eax
  101a32:	8b 40 0c             	mov    0xc(%eax),%eax
  101a35:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a39:	c7 04 24 49 61 10 00 	movl   $0x106149,(%esp)
  101a40:	e8 4d e8 ff ff       	call   100292 <cprintf>
    cprintf("  ebx  0x%08x\n", regs->reg_ebx);
  101a45:	8b 45 08             	mov    0x8(%ebp),%eax
  101a48:	8b 40 10             	mov    0x10(%eax),%eax
  101a4b:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a4f:	c7 04 24 58 61 10 00 	movl   $0x106158,(%esp)
  101a56:	e8 37 e8 ff ff       	call   100292 <cprintf>
    cprintf("  edx  0x%08x\n", regs->reg_edx);
  101a5b:	8b 45 08             	mov    0x8(%ebp),%eax
  101a5e:	8b 40 14             	mov    0x14(%eax),%eax
  101a61:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a65:	c7 04 24 67 61 10 00 	movl   $0x106167,(%esp)
  101a6c:	e8 21 e8 ff ff       	call   100292 <cprintf>
    cprintf("  ecx  0x%08x\n", regs->reg_ecx);
  101a71:	8b 45 08             	mov    0x8(%ebp),%eax
  101a74:	8b 40 18             	mov    0x18(%eax),%eax
  101a77:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a7b:	c7 04 24 76 61 10 00 	movl   $0x106176,(%esp)
  101a82:	e8 0b e8 ff ff       	call   100292 <cprintf>
    cprintf("  eax  0x%08x\n", regs->reg_eax);
  101a87:	8b 45 08             	mov    0x8(%ebp),%eax
  101a8a:	8b 40 1c             	mov    0x1c(%eax),%eax
  101a8d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a91:	c7 04 24 85 61 10 00 	movl   $0x106185,(%esp)
  101a98:	e8 f5 e7 ff ff       	call   100292 <cprintf>
}
  101a9d:	90                   	nop
  101a9e:	c9                   	leave  
  101a9f:	c3                   	ret    

00101aa0 <trap_dispatch>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static void
trap_dispatch(struct trapframe *tf) {
  101aa0:	55                   	push   %ebp
  101aa1:	89 e5                	mov    %esp,%ebp
  101aa3:	83 ec 28             	sub    $0x28,%esp
    char c;

    switch (tf->tf_trapno) {
  101aa6:	8b 45 08             	mov    0x8(%ebp),%eax
  101aa9:	8b 40 30             	mov    0x30(%eax),%eax
  101aac:	83 f8 2f             	cmp    $0x2f,%eax
  101aaf:	77 1e                	ja     101acf <trap_dispatch+0x2f>
  101ab1:	83 f8 2e             	cmp    $0x2e,%eax
  101ab4:	0f 83 bc 00 00 00    	jae    101b76 <trap_dispatch+0xd6>
  101aba:	83 f8 21             	cmp    $0x21,%eax
  101abd:	74 40                	je     101aff <trap_dispatch+0x5f>
  101abf:	83 f8 24             	cmp    $0x24,%eax
  101ac2:	74 15                	je     101ad9 <trap_dispatch+0x39>
  101ac4:	83 f8 20             	cmp    $0x20,%eax
  101ac7:	0f 84 ac 00 00 00    	je     101b79 <trap_dispatch+0xd9>
  101acd:	eb 72                	jmp    101b41 <trap_dispatch+0xa1>
  101acf:	83 e8 78             	sub    $0x78,%eax
  101ad2:	83 f8 01             	cmp    $0x1,%eax
  101ad5:	77 6a                	ja     101b41 <trap_dispatch+0xa1>
  101ad7:	eb 4c                	jmp    101b25 <trap_dispatch+0x85>
         * (2) Every TICK_NUM cycle, you can print some info using a funciton, such as print_ticks().
         * (3) Too Simple? Yes, I think so!
         */
        break;
    case IRQ_OFFSET + IRQ_COM1:
        c = cons_getc();
  101ad9:	e8 b1 fa ff ff       	call   10158f <cons_getc>
  101ade:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("serial [%03d] %c\n", c, c);
  101ae1:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
  101ae5:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  101ae9:	89 54 24 08          	mov    %edx,0x8(%esp)
  101aed:	89 44 24 04          	mov    %eax,0x4(%esp)
  101af1:	c7 04 24 94 61 10 00 	movl   $0x106194,(%esp)
  101af8:	e8 95 e7 ff ff       	call   100292 <cprintf>
        break;
  101afd:	eb 7b                	jmp    101b7a <trap_dispatch+0xda>
    case IRQ_OFFSET + IRQ_KBD:
        c = cons_getc();
  101aff:	e8 8b fa ff ff       	call   10158f <cons_getc>
  101b04:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("kbd [%03d] %c\n", c, c);
  101b07:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
  101b0b:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  101b0f:	89 54 24 08          	mov    %edx,0x8(%esp)
  101b13:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b17:	c7 04 24 a6 61 10 00 	movl   $0x1061a6,(%esp)
  101b1e:	e8 6f e7 ff ff       	call   100292 <cprintf>
        break;
  101b23:	eb 55                	jmp    101b7a <trap_dispatch+0xda>
    //LAB1 CHALLENGE 1 : YOUR CODE you should modify below codes.
    case T_SWITCH_TOU:
    case T_SWITCH_TOK:
        panic("T_SWITCH_** ??\n");
  101b25:	c7 44 24 08 b5 61 10 	movl   $0x1061b5,0x8(%esp)
  101b2c:	00 
  101b2d:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  101b34:	00 
  101b35:	c7 04 24 c5 61 10 00 	movl   $0x1061c5,(%esp)
  101b3c:	e8 a8 e8 ff ff       	call   1003e9 <__panic>
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
    default:
        // in kernel, it must be a mistake
        if ((tf->tf_cs & 3) == 0) {
  101b41:	8b 45 08             	mov    0x8(%ebp),%eax
  101b44:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101b48:	83 e0 03             	and    $0x3,%eax
  101b4b:	85 c0                	test   %eax,%eax
  101b4d:	75 2b                	jne    101b7a <trap_dispatch+0xda>
            print_trapframe(tf);
  101b4f:	8b 45 08             	mov    0x8(%ebp),%eax
  101b52:	89 04 24             	mov    %eax,(%esp)
  101b55:	e8 d9 fc ff ff       	call   101833 <print_trapframe>
            panic("unexpected trap in kernel.\n");
  101b5a:	c7 44 24 08 d6 61 10 	movl   $0x1061d6,0x8(%esp)
  101b61:	00 
  101b62:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  101b69:	00 
  101b6a:	c7 04 24 c5 61 10 00 	movl   $0x1061c5,(%esp)
  101b71:	e8 73 e8 ff ff       	call   1003e9 <__panic>
        panic("T_SWITCH_** ??\n");
        break;
    case IRQ_OFFSET + IRQ_IDE1:
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
  101b76:	90                   	nop
  101b77:	eb 01                	jmp    101b7a <trap_dispatch+0xda>
        /* handle the timer interrupt */
        /* (1) After a timer interrupt, you should record this event using a global variable (increase it), such as ticks in kern/driver/clock.c
         * (2) Every TICK_NUM cycle, you can print some info using a funciton, such as print_ticks().
         * (3) Too Simple? Yes, I think so!
         */
        break;
  101b79:	90                   	nop
        if ((tf->tf_cs & 3) == 0) {
            print_trapframe(tf);
            panic("unexpected trap in kernel.\n");
        }
    }
}
  101b7a:	90                   	nop
  101b7b:	c9                   	leave  
  101b7c:	c3                   	ret    

00101b7d <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
  101b7d:	55                   	push   %ebp
  101b7e:	89 e5                	mov    %esp,%ebp
  101b80:	83 ec 18             	sub    $0x18,%esp
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
  101b83:	8b 45 08             	mov    0x8(%ebp),%eax
  101b86:	89 04 24             	mov    %eax,(%esp)
  101b89:	e8 12 ff ff ff       	call   101aa0 <trap_dispatch>
}
  101b8e:	90                   	nop
  101b8f:	c9                   	leave  
  101b90:	c3                   	ret    

00101b91 <vector0>:
# handler
.text
.globl __alltraps
.globl vector0
vector0:
  pushl $0
  101b91:	6a 00                	push   $0x0
  pushl $0
  101b93:	6a 00                	push   $0x0
  jmp __alltraps
  101b95:	e9 69 0a 00 00       	jmp    102603 <__alltraps>

00101b9a <vector1>:
.globl vector1
vector1:
  pushl $0
  101b9a:	6a 00                	push   $0x0
  pushl $1
  101b9c:	6a 01                	push   $0x1
  jmp __alltraps
  101b9e:	e9 60 0a 00 00       	jmp    102603 <__alltraps>

00101ba3 <vector2>:
.globl vector2
vector2:
  pushl $0
  101ba3:	6a 00                	push   $0x0
  pushl $2
  101ba5:	6a 02                	push   $0x2
  jmp __alltraps
  101ba7:	e9 57 0a 00 00       	jmp    102603 <__alltraps>

00101bac <vector3>:
.globl vector3
vector3:
  pushl $0
  101bac:	6a 00                	push   $0x0
  pushl $3
  101bae:	6a 03                	push   $0x3
  jmp __alltraps
  101bb0:	e9 4e 0a 00 00       	jmp    102603 <__alltraps>

00101bb5 <vector4>:
.globl vector4
vector4:
  pushl $0
  101bb5:	6a 00                	push   $0x0
  pushl $4
  101bb7:	6a 04                	push   $0x4
  jmp __alltraps
  101bb9:	e9 45 0a 00 00       	jmp    102603 <__alltraps>

00101bbe <vector5>:
.globl vector5
vector5:
  pushl $0
  101bbe:	6a 00                	push   $0x0
  pushl $5
  101bc0:	6a 05                	push   $0x5
  jmp __alltraps
  101bc2:	e9 3c 0a 00 00       	jmp    102603 <__alltraps>

00101bc7 <vector6>:
.globl vector6
vector6:
  pushl $0
  101bc7:	6a 00                	push   $0x0
  pushl $6
  101bc9:	6a 06                	push   $0x6
  jmp __alltraps
  101bcb:	e9 33 0a 00 00       	jmp    102603 <__alltraps>

00101bd0 <vector7>:
.globl vector7
vector7:
  pushl $0
  101bd0:	6a 00                	push   $0x0
  pushl $7
  101bd2:	6a 07                	push   $0x7
  jmp __alltraps
  101bd4:	e9 2a 0a 00 00       	jmp    102603 <__alltraps>

00101bd9 <vector8>:
.globl vector8
vector8:
  pushl $8
  101bd9:	6a 08                	push   $0x8
  jmp __alltraps
  101bdb:	e9 23 0a 00 00       	jmp    102603 <__alltraps>

00101be0 <vector9>:
.globl vector9
vector9:
  pushl $0
  101be0:	6a 00                	push   $0x0
  pushl $9
  101be2:	6a 09                	push   $0x9
  jmp __alltraps
  101be4:	e9 1a 0a 00 00       	jmp    102603 <__alltraps>

00101be9 <vector10>:
.globl vector10
vector10:
  pushl $10
  101be9:	6a 0a                	push   $0xa
  jmp __alltraps
  101beb:	e9 13 0a 00 00       	jmp    102603 <__alltraps>

00101bf0 <vector11>:
.globl vector11
vector11:
  pushl $11
  101bf0:	6a 0b                	push   $0xb
  jmp __alltraps
  101bf2:	e9 0c 0a 00 00       	jmp    102603 <__alltraps>

00101bf7 <vector12>:
.globl vector12
vector12:
  pushl $12
  101bf7:	6a 0c                	push   $0xc
  jmp __alltraps
  101bf9:	e9 05 0a 00 00       	jmp    102603 <__alltraps>

00101bfe <vector13>:
.globl vector13
vector13:
  pushl $13
  101bfe:	6a 0d                	push   $0xd
  jmp __alltraps
  101c00:	e9 fe 09 00 00       	jmp    102603 <__alltraps>

00101c05 <vector14>:
.globl vector14
vector14:
  pushl $14
  101c05:	6a 0e                	push   $0xe
  jmp __alltraps
  101c07:	e9 f7 09 00 00       	jmp    102603 <__alltraps>

00101c0c <vector15>:
.globl vector15
vector15:
  pushl $0
  101c0c:	6a 00                	push   $0x0
  pushl $15
  101c0e:	6a 0f                	push   $0xf
  jmp __alltraps
  101c10:	e9 ee 09 00 00       	jmp    102603 <__alltraps>

00101c15 <vector16>:
.globl vector16
vector16:
  pushl $0
  101c15:	6a 00                	push   $0x0
  pushl $16
  101c17:	6a 10                	push   $0x10
  jmp __alltraps
  101c19:	e9 e5 09 00 00       	jmp    102603 <__alltraps>

00101c1e <vector17>:
.globl vector17
vector17:
  pushl $17
  101c1e:	6a 11                	push   $0x11
  jmp __alltraps
  101c20:	e9 de 09 00 00       	jmp    102603 <__alltraps>

00101c25 <vector18>:
.globl vector18
vector18:
  pushl $0
  101c25:	6a 00                	push   $0x0
  pushl $18
  101c27:	6a 12                	push   $0x12
  jmp __alltraps
  101c29:	e9 d5 09 00 00       	jmp    102603 <__alltraps>

00101c2e <vector19>:
.globl vector19
vector19:
  pushl $0
  101c2e:	6a 00                	push   $0x0
  pushl $19
  101c30:	6a 13                	push   $0x13
  jmp __alltraps
  101c32:	e9 cc 09 00 00       	jmp    102603 <__alltraps>

00101c37 <vector20>:
.globl vector20
vector20:
  pushl $0
  101c37:	6a 00                	push   $0x0
  pushl $20
  101c39:	6a 14                	push   $0x14
  jmp __alltraps
  101c3b:	e9 c3 09 00 00       	jmp    102603 <__alltraps>

00101c40 <vector21>:
.globl vector21
vector21:
  pushl $0
  101c40:	6a 00                	push   $0x0
  pushl $21
  101c42:	6a 15                	push   $0x15
  jmp __alltraps
  101c44:	e9 ba 09 00 00       	jmp    102603 <__alltraps>

00101c49 <vector22>:
.globl vector22
vector22:
  pushl $0
  101c49:	6a 00                	push   $0x0
  pushl $22
  101c4b:	6a 16                	push   $0x16
  jmp __alltraps
  101c4d:	e9 b1 09 00 00       	jmp    102603 <__alltraps>

00101c52 <vector23>:
.globl vector23
vector23:
  pushl $0
  101c52:	6a 00                	push   $0x0
  pushl $23
  101c54:	6a 17                	push   $0x17
  jmp __alltraps
  101c56:	e9 a8 09 00 00       	jmp    102603 <__alltraps>

00101c5b <vector24>:
.globl vector24
vector24:
  pushl $0
  101c5b:	6a 00                	push   $0x0
  pushl $24
  101c5d:	6a 18                	push   $0x18
  jmp __alltraps
  101c5f:	e9 9f 09 00 00       	jmp    102603 <__alltraps>

00101c64 <vector25>:
.globl vector25
vector25:
  pushl $0
  101c64:	6a 00                	push   $0x0
  pushl $25
  101c66:	6a 19                	push   $0x19
  jmp __alltraps
  101c68:	e9 96 09 00 00       	jmp    102603 <__alltraps>

00101c6d <vector26>:
.globl vector26
vector26:
  pushl $0
  101c6d:	6a 00                	push   $0x0
  pushl $26
  101c6f:	6a 1a                	push   $0x1a
  jmp __alltraps
  101c71:	e9 8d 09 00 00       	jmp    102603 <__alltraps>

00101c76 <vector27>:
.globl vector27
vector27:
  pushl $0
  101c76:	6a 00                	push   $0x0
  pushl $27
  101c78:	6a 1b                	push   $0x1b
  jmp __alltraps
  101c7a:	e9 84 09 00 00       	jmp    102603 <__alltraps>

00101c7f <vector28>:
.globl vector28
vector28:
  pushl $0
  101c7f:	6a 00                	push   $0x0
  pushl $28
  101c81:	6a 1c                	push   $0x1c
  jmp __alltraps
  101c83:	e9 7b 09 00 00       	jmp    102603 <__alltraps>

00101c88 <vector29>:
.globl vector29
vector29:
  pushl $0
  101c88:	6a 00                	push   $0x0
  pushl $29
  101c8a:	6a 1d                	push   $0x1d
  jmp __alltraps
  101c8c:	e9 72 09 00 00       	jmp    102603 <__alltraps>

00101c91 <vector30>:
.globl vector30
vector30:
  pushl $0
  101c91:	6a 00                	push   $0x0
  pushl $30
  101c93:	6a 1e                	push   $0x1e
  jmp __alltraps
  101c95:	e9 69 09 00 00       	jmp    102603 <__alltraps>

00101c9a <vector31>:
.globl vector31
vector31:
  pushl $0
  101c9a:	6a 00                	push   $0x0
  pushl $31
  101c9c:	6a 1f                	push   $0x1f
  jmp __alltraps
  101c9e:	e9 60 09 00 00       	jmp    102603 <__alltraps>

00101ca3 <vector32>:
.globl vector32
vector32:
  pushl $0
  101ca3:	6a 00                	push   $0x0
  pushl $32
  101ca5:	6a 20                	push   $0x20
  jmp __alltraps
  101ca7:	e9 57 09 00 00       	jmp    102603 <__alltraps>

00101cac <vector33>:
.globl vector33
vector33:
  pushl $0
  101cac:	6a 00                	push   $0x0
  pushl $33
  101cae:	6a 21                	push   $0x21
  jmp __alltraps
  101cb0:	e9 4e 09 00 00       	jmp    102603 <__alltraps>

00101cb5 <vector34>:
.globl vector34
vector34:
  pushl $0
  101cb5:	6a 00                	push   $0x0
  pushl $34
  101cb7:	6a 22                	push   $0x22
  jmp __alltraps
  101cb9:	e9 45 09 00 00       	jmp    102603 <__alltraps>

00101cbe <vector35>:
.globl vector35
vector35:
  pushl $0
  101cbe:	6a 00                	push   $0x0
  pushl $35
  101cc0:	6a 23                	push   $0x23
  jmp __alltraps
  101cc2:	e9 3c 09 00 00       	jmp    102603 <__alltraps>

00101cc7 <vector36>:
.globl vector36
vector36:
  pushl $0
  101cc7:	6a 00                	push   $0x0
  pushl $36
  101cc9:	6a 24                	push   $0x24
  jmp __alltraps
  101ccb:	e9 33 09 00 00       	jmp    102603 <__alltraps>

00101cd0 <vector37>:
.globl vector37
vector37:
  pushl $0
  101cd0:	6a 00                	push   $0x0
  pushl $37
  101cd2:	6a 25                	push   $0x25
  jmp __alltraps
  101cd4:	e9 2a 09 00 00       	jmp    102603 <__alltraps>

00101cd9 <vector38>:
.globl vector38
vector38:
  pushl $0
  101cd9:	6a 00                	push   $0x0
  pushl $38
  101cdb:	6a 26                	push   $0x26
  jmp __alltraps
  101cdd:	e9 21 09 00 00       	jmp    102603 <__alltraps>

00101ce2 <vector39>:
.globl vector39
vector39:
  pushl $0
  101ce2:	6a 00                	push   $0x0
  pushl $39
  101ce4:	6a 27                	push   $0x27
  jmp __alltraps
  101ce6:	e9 18 09 00 00       	jmp    102603 <__alltraps>

00101ceb <vector40>:
.globl vector40
vector40:
  pushl $0
  101ceb:	6a 00                	push   $0x0
  pushl $40
  101ced:	6a 28                	push   $0x28
  jmp __alltraps
  101cef:	e9 0f 09 00 00       	jmp    102603 <__alltraps>

00101cf4 <vector41>:
.globl vector41
vector41:
  pushl $0
  101cf4:	6a 00                	push   $0x0
  pushl $41
  101cf6:	6a 29                	push   $0x29
  jmp __alltraps
  101cf8:	e9 06 09 00 00       	jmp    102603 <__alltraps>

00101cfd <vector42>:
.globl vector42
vector42:
  pushl $0
  101cfd:	6a 00                	push   $0x0
  pushl $42
  101cff:	6a 2a                	push   $0x2a
  jmp __alltraps
  101d01:	e9 fd 08 00 00       	jmp    102603 <__alltraps>

00101d06 <vector43>:
.globl vector43
vector43:
  pushl $0
  101d06:	6a 00                	push   $0x0
  pushl $43
  101d08:	6a 2b                	push   $0x2b
  jmp __alltraps
  101d0a:	e9 f4 08 00 00       	jmp    102603 <__alltraps>

00101d0f <vector44>:
.globl vector44
vector44:
  pushl $0
  101d0f:	6a 00                	push   $0x0
  pushl $44
  101d11:	6a 2c                	push   $0x2c
  jmp __alltraps
  101d13:	e9 eb 08 00 00       	jmp    102603 <__alltraps>

00101d18 <vector45>:
.globl vector45
vector45:
  pushl $0
  101d18:	6a 00                	push   $0x0
  pushl $45
  101d1a:	6a 2d                	push   $0x2d
  jmp __alltraps
  101d1c:	e9 e2 08 00 00       	jmp    102603 <__alltraps>

00101d21 <vector46>:
.globl vector46
vector46:
  pushl $0
  101d21:	6a 00                	push   $0x0
  pushl $46
  101d23:	6a 2e                	push   $0x2e
  jmp __alltraps
  101d25:	e9 d9 08 00 00       	jmp    102603 <__alltraps>

00101d2a <vector47>:
.globl vector47
vector47:
  pushl $0
  101d2a:	6a 00                	push   $0x0
  pushl $47
  101d2c:	6a 2f                	push   $0x2f
  jmp __alltraps
  101d2e:	e9 d0 08 00 00       	jmp    102603 <__alltraps>

00101d33 <vector48>:
.globl vector48
vector48:
  pushl $0
  101d33:	6a 00                	push   $0x0
  pushl $48
  101d35:	6a 30                	push   $0x30
  jmp __alltraps
  101d37:	e9 c7 08 00 00       	jmp    102603 <__alltraps>

00101d3c <vector49>:
.globl vector49
vector49:
  pushl $0
  101d3c:	6a 00                	push   $0x0
  pushl $49
  101d3e:	6a 31                	push   $0x31
  jmp __alltraps
  101d40:	e9 be 08 00 00       	jmp    102603 <__alltraps>

00101d45 <vector50>:
.globl vector50
vector50:
  pushl $0
  101d45:	6a 00                	push   $0x0
  pushl $50
  101d47:	6a 32                	push   $0x32
  jmp __alltraps
  101d49:	e9 b5 08 00 00       	jmp    102603 <__alltraps>

00101d4e <vector51>:
.globl vector51
vector51:
  pushl $0
  101d4e:	6a 00                	push   $0x0
  pushl $51
  101d50:	6a 33                	push   $0x33
  jmp __alltraps
  101d52:	e9 ac 08 00 00       	jmp    102603 <__alltraps>

00101d57 <vector52>:
.globl vector52
vector52:
  pushl $0
  101d57:	6a 00                	push   $0x0
  pushl $52
  101d59:	6a 34                	push   $0x34
  jmp __alltraps
  101d5b:	e9 a3 08 00 00       	jmp    102603 <__alltraps>

00101d60 <vector53>:
.globl vector53
vector53:
  pushl $0
  101d60:	6a 00                	push   $0x0
  pushl $53
  101d62:	6a 35                	push   $0x35
  jmp __alltraps
  101d64:	e9 9a 08 00 00       	jmp    102603 <__alltraps>

00101d69 <vector54>:
.globl vector54
vector54:
  pushl $0
  101d69:	6a 00                	push   $0x0
  pushl $54
  101d6b:	6a 36                	push   $0x36
  jmp __alltraps
  101d6d:	e9 91 08 00 00       	jmp    102603 <__alltraps>

00101d72 <vector55>:
.globl vector55
vector55:
  pushl $0
  101d72:	6a 00                	push   $0x0
  pushl $55
  101d74:	6a 37                	push   $0x37
  jmp __alltraps
  101d76:	e9 88 08 00 00       	jmp    102603 <__alltraps>

00101d7b <vector56>:
.globl vector56
vector56:
  pushl $0
  101d7b:	6a 00                	push   $0x0
  pushl $56
  101d7d:	6a 38                	push   $0x38
  jmp __alltraps
  101d7f:	e9 7f 08 00 00       	jmp    102603 <__alltraps>

00101d84 <vector57>:
.globl vector57
vector57:
  pushl $0
  101d84:	6a 00                	push   $0x0
  pushl $57
  101d86:	6a 39                	push   $0x39
  jmp __alltraps
  101d88:	e9 76 08 00 00       	jmp    102603 <__alltraps>

00101d8d <vector58>:
.globl vector58
vector58:
  pushl $0
  101d8d:	6a 00                	push   $0x0
  pushl $58
  101d8f:	6a 3a                	push   $0x3a
  jmp __alltraps
  101d91:	e9 6d 08 00 00       	jmp    102603 <__alltraps>

00101d96 <vector59>:
.globl vector59
vector59:
  pushl $0
  101d96:	6a 00                	push   $0x0
  pushl $59
  101d98:	6a 3b                	push   $0x3b
  jmp __alltraps
  101d9a:	e9 64 08 00 00       	jmp    102603 <__alltraps>

00101d9f <vector60>:
.globl vector60
vector60:
  pushl $0
  101d9f:	6a 00                	push   $0x0
  pushl $60
  101da1:	6a 3c                	push   $0x3c
  jmp __alltraps
  101da3:	e9 5b 08 00 00       	jmp    102603 <__alltraps>

00101da8 <vector61>:
.globl vector61
vector61:
  pushl $0
  101da8:	6a 00                	push   $0x0
  pushl $61
  101daa:	6a 3d                	push   $0x3d
  jmp __alltraps
  101dac:	e9 52 08 00 00       	jmp    102603 <__alltraps>

00101db1 <vector62>:
.globl vector62
vector62:
  pushl $0
  101db1:	6a 00                	push   $0x0
  pushl $62
  101db3:	6a 3e                	push   $0x3e
  jmp __alltraps
  101db5:	e9 49 08 00 00       	jmp    102603 <__alltraps>

00101dba <vector63>:
.globl vector63
vector63:
  pushl $0
  101dba:	6a 00                	push   $0x0
  pushl $63
  101dbc:	6a 3f                	push   $0x3f
  jmp __alltraps
  101dbe:	e9 40 08 00 00       	jmp    102603 <__alltraps>

00101dc3 <vector64>:
.globl vector64
vector64:
  pushl $0
  101dc3:	6a 00                	push   $0x0
  pushl $64
  101dc5:	6a 40                	push   $0x40
  jmp __alltraps
  101dc7:	e9 37 08 00 00       	jmp    102603 <__alltraps>

00101dcc <vector65>:
.globl vector65
vector65:
  pushl $0
  101dcc:	6a 00                	push   $0x0
  pushl $65
  101dce:	6a 41                	push   $0x41
  jmp __alltraps
  101dd0:	e9 2e 08 00 00       	jmp    102603 <__alltraps>

00101dd5 <vector66>:
.globl vector66
vector66:
  pushl $0
  101dd5:	6a 00                	push   $0x0
  pushl $66
  101dd7:	6a 42                	push   $0x42
  jmp __alltraps
  101dd9:	e9 25 08 00 00       	jmp    102603 <__alltraps>

00101dde <vector67>:
.globl vector67
vector67:
  pushl $0
  101dde:	6a 00                	push   $0x0
  pushl $67
  101de0:	6a 43                	push   $0x43
  jmp __alltraps
  101de2:	e9 1c 08 00 00       	jmp    102603 <__alltraps>

00101de7 <vector68>:
.globl vector68
vector68:
  pushl $0
  101de7:	6a 00                	push   $0x0
  pushl $68
  101de9:	6a 44                	push   $0x44
  jmp __alltraps
  101deb:	e9 13 08 00 00       	jmp    102603 <__alltraps>

00101df0 <vector69>:
.globl vector69
vector69:
  pushl $0
  101df0:	6a 00                	push   $0x0
  pushl $69
  101df2:	6a 45                	push   $0x45
  jmp __alltraps
  101df4:	e9 0a 08 00 00       	jmp    102603 <__alltraps>

00101df9 <vector70>:
.globl vector70
vector70:
  pushl $0
  101df9:	6a 00                	push   $0x0
  pushl $70
  101dfb:	6a 46                	push   $0x46
  jmp __alltraps
  101dfd:	e9 01 08 00 00       	jmp    102603 <__alltraps>

00101e02 <vector71>:
.globl vector71
vector71:
  pushl $0
  101e02:	6a 00                	push   $0x0
  pushl $71
  101e04:	6a 47                	push   $0x47
  jmp __alltraps
  101e06:	e9 f8 07 00 00       	jmp    102603 <__alltraps>

00101e0b <vector72>:
.globl vector72
vector72:
  pushl $0
  101e0b:	6a 00                	push   $0x0
  pushl $72
  101e0d:	6a 48                	push   $0x48
  jmp __alltraps
  101e0f:	e9 ef 07 00 00       	jmp    102603 <__alltraps>

00101e14 <vector73>:
.globl vector73
vector73:
  pushl $0
  101e14:	6a 00                	push   $0x0
  pushl $73
  101e16:	6a 49                	push   $0x49
  jmp __alltraps
  101e18:	e9 e6 07 00 00       	jmp    102603 <__alltraps>

00101e1d <vector74>:
.globl vector74
vector74:
  pushl $0
  101e1d:	6a 00                	push   $0x0
  pushl $74
  101e1f:	6a 4a                	push   $0x4a
  jmp __alltraps
  101e21:	e9 dd 07 00 00       	jmp    102603 <__alltraps>

00101e26 <vector75>:
.globl vector75
vector75:
  pushl $0
  101e26:	6a 00                	push   $0x0
  pushl $75
  101e28:	6a 4b                	push   $0x4b
  jmp __alltraps
  101e2a:	e9 d4 07 00 00       	jmp    102603 <__alltraps>

00101e2f <vector76>:
.globl vector76
vector76:
  pushl $0
  101e2f:	6a 00                	push   $0x0
  pushl $76
  101e31:	6a 4c                	push   $0x4c
  jmp __alltraps
  101e33:	e9 cb 07 00 00       	jmp    102603 <__alltraps>

00101e38 <vector77>:
.globl vector77
vector77:
  pushl $0
  101e38:	6a 00                	push   $0x0
  pushl $77
  101e3a:	6a 4d                	push   $0x4d
  jmp __alltraps
  101e3c:	e9 c2 07 00 00       	jmp    102603 <__alltraps>

00101e41 <vector78>:
.globl vector78
vector78:
  pushl $0
  101e41:	6a 00                	push   $0x0
  pushl $78
  101e43:	6a 4e                	push   $0x4e
  jmp __alltraps
  101e45:	e9 b9 07 00 00       	jmp    102603 <__alltraps>

00101e4a <vector79>:
.globl vector79
vector79:
  pushl $0
  101e4a:	6a 00                	push   $0x0
  pushl $79
  101e4c:	6a 4f                	push   $0x4f
  jmp __alltraps
  101e4e:	e9 b0 07 00 00       	jmp    102603 <__alltraps>

00101e53 <vector80>:
.globl vector80
vector80:
  pushl $0
  101e53:	6a 00                	push   $0x0
  pushl $80
  101e55:	6a 50                	push   $0x50
  jmp __alltraps
  101e57:	e9 a7 07 00 00       	jmp    102603 <__alltraps>

00101e5c <vector81>:
.globl vector81
vector81:
  pushl $0
  101e5c:	6a 00                	push   $0x0
  pushl $81
  101e5e:	6a 51                	push   $0x51
  jmp __alltraps
  101e60:	e9 9e 07 00 00       	jmp    102603 <__alltraps>

00101e65 <vector82>:
.globl vector82
vector82:
  pushl $0
  101e65:	6a 00                	push   $0x0
  pushl $82
  101e67:	6a 52                	push   $0x52
  jmp __alltraps
  101e69:	e9 95 07 00 00       	jmp    102603 <__alltraps>

00101e6e <vector83>:
.globl vector83
vector83:
  pushl $0
  101e6e:	6a 00                	push   $0x0
  pushl $83
  101e70:	6a 53                	push   $0x53
  jmp __alltraps
  101e72:	e9 8c 07 00 00       	jmp    102603 <__alltraps>

00101e77 <vector84>:
.globl vector84
vector84:
  pushl $0
  101e77:	6a 00                	push   $0x0
  pushl $84
  101e79:	6a 54                	push   $0x54
  jmp __alltraps
  101e7b:	e9 83 07 00 00       	jmp    102603 <__alltraps>

00101e80 <vector85>:
.globl vector85
vector85:
  pushl $0
  101e80:	6a 00                	push   $0x0
  pushl $85
  101e82:	6a 55                	push   $0x55
  jmp __alltraps
  101e84:	e9 7a 07 00 00       	jmp    102603 <__alltraps>

00101e89 <vector86>:
.globl vector86
vector86:
  pushl $0
  101e89:	6a 00                	push   $0x0
  pushl $86
  101e8b:	6a 56                	push   $0x56
  jmp __alltraps
  101e8d:	e9 71 07 00 00       	jmp    102603 <__alltraps>

00101e92 <vector87>:
.globl vector87
vector87:
  pushl $0
  101e92:	6a 00                	push   $0x0
  pushl $87
  101e94:	6a 57                	push   $0x57
  jmp __alltraps
  101e96:	e9 68 07 00 00       	jmp    102603 <__alltraps>

00101e9b <vector88>:
.globl vector88
vector88:
  pushl $0
  101e9b:	6a 00                	push   $0x0
  pushl $88
  101e9d:	6a 58                	push   $0x58
  jmp __alltraps
  101e9f:	e9 5f 07 00 00       	jmp    102603 <__alltraps>

00101ea4 <vector89>:
.globl vector89
vector89:
  pushl $0
  101ea4:	6a 00                	push   $0x0
  pushl $89
  101ea6:	6a 59                	push   $0x59
  jmp __alltraps
  101ea8:	e9 56 07 00 00       	jmp    102603 <__alltraps>

00101ead <vector90>:
.globl vector90
vector90:
  pushl $0
  101ead:	6a 00                	push   $0x0
  pushl $90
  101eaf:	6a 5a                	push   $0x5a
  jmp __alltraps
  101eb1:	e9 4d 07 00 00       	jmp    102603 <__alltraps>

00101eb6 <vector91>:
.globl vector91
vector91:
  pushl $0
  101eb6:	6a 00                	push   $0x0
  pushl $91
  101eb8:	6a 5b                	push   $0x5b
  jmp __alltraps
  101eba:	e9 44 07 00 00       	jmp    102603 <__alltraps>

00101ebf <vector92>:
.globl vector92
vector92:
  pushl $0
  101ebf:	6a 00                	push   $0x0
  pushl $92
  101ec1:	6a 5c                	push   $0x5c
  jmp __alltraps
  101ec3:	e9 3b 07 00 00       	jmp    102603 <__alltraps>

00101ec8 <vector93>:
.globl vector93
vector93:
  pushl $0
  101ec8:	6a 00                	push   $0x0
  pushl $93
  101eca:	6a 5d                	push   $0x5d
  jmp __alltraps
  101ecc:	e9 32 07 00 00       	jmp    102603 <__alltraps>

00101ed1 <vector94>:
.globl vector94
vector94:
  pushl $0
  101ed1:	6a 00                	push   $0x0
  pushl $94
  101ed3:	6a 5e                	push   $0x5e
  jmp __alltraps
  101ed5:	e9 29 07 00 00       	jmp    102603 <__alltraps>

00101eda <vector95>:
.globl vector95
vector95:
  pushl $0
  101eda:	6a 00                	push   $0x0
  pushl $95
  101edc:	6a 5f                	push   $0x5f
  jmp __alltraps
  101ede:	e9 20 07 00 00       	jmp    102603 <__alltraps>

00101ee3 <vector96>:
.globl vector96
vector96:
  pushl $0
  101ee3:	6a 00                	push   $0x0
  pushl $96
  101ee5:	6a 60                	push   $0x60
  jmp __alltraps
  101ee7:	e9 17 07 00 00       	jmp    102603 <__alltraps>

00101eec <vector97>:
.globl vector97
vector97:
  pushl $0
  101eec:	6a 00                	push   $0x0
  pushl $97
  101eee:	6a 61                	push   $0x61
  jmp __alltraps
  101ef0:	e9 0e 07 00 00       	jmp    102603 <__alltraps>

00101ef5 <vector98>:
.globl vector98
vector98:
  pushl $0
  101ef5:	6a 00                	push   $0x0
  pushl $98
  101ef7:	6a 62                	push   $0x62
  jmp __alltraps
  101ef9:	e9 05 07 00 00       	jmp    102603 <__alltraps>

00101efe <vector99>:
.globl vector99
vector99:
  pushl $0
  101efe:	6a 00                	push   $0x0
  pushl $99
  101f00:	6a 63                	push   $0x63
  jmp __alltraps
  101f02:	e9 fc 06 00 00       	jmp    102603 <__alltraps>

00101f07 <vector100>:
.globl vector100
vector100:
  pushl $0
  101f07:	6a 00                	push   $0x0
  pushl $100
  101f09:	6a 64                	push   $0x64
  jmp __alltraps
  101f0b:	e9 f3 06 00 00       	jmp    102603 <__alltraps>

00101f10 <vector101>:
.globl vector101
vector101:
  pushl $0
  101f10:	6a 00                	push   $0x0
  pushl $101
  101f12:	6a 65                	push   $0x65
  jmp __alltraps
  101f14:	e9 ea 06 00 00       	jmp    102603 <__alltraps>

00101f19 <vector102>:
.globl vector102
vector102:
  pushl $0
  101f19:	6a 00                	push   $0x0
  pushl $102
  101f1b:	6a 66                	push   $0x66
  jmp __alltraps
  101f1d:	e9 e1 06 00 00       	jmp    102603 <__alltraps>

00101f22 <vector103>:
.globl vector103
vector103:
  pushl $0
  101f22:	6a 00                	push   $0x0
  pushl $103
  101f24:	6a 67                	push   $0x67
  jmp __alltraps
  101f26:	e9 d8 06 00 00       	jmp    102603 <__alltraps>

00101f2b <vector104>:
.globl vector104
vector104:
  pushl $0
  101f2b:	6a 00                	push   $0x0
  pushl $104
  101f2d:	6a 68                	push   $0x68
  jmp __alltraps
  101f2f:	e9 cf 06 00 00       	jmp    102603 <__alltraps>

00101f34 <vector105>:
.globl vector105
vector105:
  pushl $0
  101f34:	6a 00                	push   $0x0
  pushl $105
  101f36:	6a 69                	push   $0x69
  jmp __alltraps
  101f38:	e9 c6 06 00 00       	jmp    102603 <__alltraps>

00101f3d <vector106>:
.globl vector106
vector106:
  pushl $0
  101f3d:	6a 00                	push   $0x0
  pushl $106
  101f3f:	6a 6a                	push   $0x6a
  jmp __alltraps
  101f41:	e9 bd 06 00 00       	jmp    102603 <__alltraps>

00101f46 <vector107>:
.globl vector107
vector107:
  pushl $0
  101f46:	6a 00                	push   $0x0
  pushl $107
  101f48:	6a 6b                	push   $0x6b
  jmp __alltraps
  101f4a:	e9 b4 06 00 00       	jmp    102603 <__alltraps>

00101f4f <vector108>:
.globl vector108
vector108:
  pushl $0
  101f4f:	6a 00                	push   $0x0
  pushl $108
  101f51:	6a 6c                	push   $0x6c
  jmp __alltraps
  101f53:	e9 ab 06 00 00       	jmp    102603 <__alltraps>

00101f58 <vector109>:
.globl vector109
vector109:
  pushl $0
  101f58:	6a 00                	push   $0x0
  pushl $109
  101f5a:	6a 6d                	push   $0x6d
  jmp __alltraps
  101f5c:	e9 a2 06 00 00       	jmp    102603 <__alltraps>

00101f61 <vector110>:
.globl vector110
vector110:
  pushl $0
  101f61:	6a 00                	push   $0x0
  pushl $110
  101f63:	6a 6e                	push   $0x6e
  jmp __alltraps
  101f65:	e9 99 06 00 00       	jmp    102603 <__alltraps>

00101f6a <vector111>:
.globl vector111
vector111:
  pushl $0
  101f6a:	6a 00                	push   $0x0
  pushl $111
  101f6c:	6a 6f                	push   $0x6f
  jmp __alltraps
  101f6e:	e9 90 06 00 00       	jmp    102603 <__alltraps>

00101f73 <vector112>:
.globl vector112
vector112:
  pushl $0
  101f73:	6a 00                	push   $0x0
  pushl $112
  101f75:	6a 70                	push   $0x70
  jmp __alltraps
  101f77:	e9 87 06 00 00       	jmp    102603 <__alltraps>

00101f7c <vector113>:
.globl vector113
vector113:
  pushl $0
  101f7c:	6a 00                	push   $0x0
  pushl $113
  101f7e:	6a 71                	push   $0x71
  jmp __alltraps
  101f80:	e9 7e 06 00 00       	jmp    102603 <__alltraps>

00101f85 <vector114>:
.globl vector114
vector114:
  pushl $0
  101f85:	6a 00                	push   $0x0
  pushl $114
  101f87:	6a 72                	push   $0x72
  jmp __alltraps
  101f89:	e9 75 06 00 00       	jmp    102603 <__alltraps>

00101f8e <vector115>:
.globl vector115
vector115:
  pushl $0
  101f8e:	6a 00                	push   $0x0
  pushl $115
  101f90:	6a 73                	push   $0x73
  jmp __alltraps
  101f92:	e9 6c 06 00 00       	jmp    102603 <__alltraps>

00101f97 <vector116>:
.globl vector116
vector116:
  pushl $0
  101f97:	6a 00                	push   $0x0
  pushl $116
  101f99:	6a 74                	push   $0x74
  jmp __alltraps
  101f9b:	e9 63 06 00 00       	jmp    102603 <__alltraps>

00101fa0 <vector117>:
.globl vector117
vector117:
  pushl $0
  101fa0:	6a 00                	push   $0x0
  pushl $117
  101fa2:	6a 75                	push   $0x75
  jmp __alltraps
  101fa4:	e9 5a 06 00 00       	jmp    102603 <__alltraps>

00101fa9 <vector118>:
.globl vector118
vector118:
  pushl $0
  101fa9:	6a 00                	push   $0x0
  pushl $118
  101fab:	6a 76                	push   $0x76
  jmp __alltraps
  101fad:	e9 51 06 00 00       	jmp    102603 <__alltraps>

00101fb2 <vector119>:
.globl vector119
vector119:
  pushl $0
  101fb2:	6a 00                	push   $0x0
  pushl $119
  101fb4:	6a 77                	push   $0x77
  jmp __alltraps
  101fb6:	e9 48 06 00 00       	jmp    102603 <__alltraps>

00101fbb <vector120>:
.globl vector120
vector120:
  pushl $0
  101fbb:	6a 00                	push   $0x0
  pushl $120
  101fbd:	6a 78                	push   $0x78
  jmp __alltraps
  101fbf:	e9 3f 06 00 00       	jmp    102603 <__alltraps>

00101fc4 <vector121>:
.globl vector121
vector121:
  pushl $0
  101fc4:	6a 00                	push   $0x0
  pushl $121
  101fc6:	6a 79                	push   $0x79
  jmp __alltraps
  101fc8:	e9 36 06 00 00       	jmp    102603 <__alltraps>

00101fcd <vector122>:
.globl vector122
vector122:
  pushl $0
  101fcd:	6a 00                	push   $0x0
  pushl $122
  101fcf:	6a 7a                	push   $0x7a
  jmp __alltraps
  101fd1:	e9 2d 06 00 00       	jmp    102603 <__alltraps>

00101fd6 <vector123>:
.globl vector123
vector123:
  pushl $0
  101fd6:	6a 00                	push   $0x0
  pushl $123
  101fd8:	6a 7b                	push   $0x7b
  jmp __alltraps
  101fda:	e9 24 06 00 00       	jmp    102603 <__alltraps>

00101fdf <vector124>:
.globl vector124
vector124:
  pushl $0
  101fdf:	6a 00                	push   $0x0
  pushl $124
  101fe1:	6a 7c                	push   $0x7c
  jmp __alltraps
  101fe3:	e9 1b 06 00 00       	jmp    102603 <__alltraps>

00101fe8 <vector125>:
.globl vector125
vector125:
  pushl $0
  101fe8:	6a 00                	push   $0x0
  pushl $125
  101fea:	6a 7d                	push   $0x7d
  jmp __alltraps
  101fec:	e9 12 06 00 00       	jmp    102603 <__alltraps>

00101ff1 <vector126>:
.globl vector126
vector126:
  pushl $0
  101ff1:	6a 00                	push   $0x0
  pushl $126
  101ff3:	6a 7e                	push   $0x7e
  jmp __alltraps
  101ff5:	e9 09 06 00 00       	jmp    102603 <__alltraps>

00101ffa <vector127>:
.globl vector127
vector127:
  pushl $0
  101ffa:	6a 00                	push   $0x0
  pushl $127
  101ffc:	6a 7f                	push   $0x7f
  jmp __alltraps
  101ffe:	e9 00 06 00 00       	jmp    102603 <__alltraps>

00102003 <vector128>:
.globl vector128
vector128:
  pushl $0
  102003:	6a 00                	push   $0x0
  pushl $128
  102005:	68 80 00 00 00       	push   $0x80
  jmp __alltraps
  10200a:	e9 f4 05 00 00       	jmp    102603 <__alltraps>

0010200f <vector129>:
.globl vector129
vector129:
  pushl $0
  10200f:	6a 00                	push   $0x0
  pushl $129
  102011:	68 81 00 00 00       	push   $0x81
  jmp __alltraps
  102016:	e9 e8 05 00 00       	jmp    102603 <__alltraps>

0010201b <vector130>:
.globl vector130
vector130:
  pushl $0
  10201b:	6a 00                	push   $0x0
  pushl $130
  10201d:	68 82 00 00 00       	push   $0x82
  jmp __alltraps
  102022:	e9 dc 05 00 00       	jmp    102603 <__alltraps>

00102027 <vector131>:
.globl vector131
vector131:
  pushl $0
  102027:	6a 00                	push   $0x0
  pushl $131
  102029:	68 83 00 00 00       	push   $0x83
  jmp __alltraps
  10202e:	e9 d0 05 00 00       	jmp    102603 <__alltraps>

00102033 <vector132>:
.globl vector132
vector132:
  pushl $0
  102033:	6a 00                	push   $0x0
  pushl $132
  102035:	68 84 00 00 00       	push   $0x84
  jmp __alltraps
  10203a:	e9 c4 05 00 00       	jmp    102603 <__alltraps>

0010203f <vector133>:
.globl vector133
vector133:
  pushl $0
  10203f:	6a 00                	push   $0x0
  pushl $133
  102041:	68 85 00 00 00       	push   $0x85
  jmp __alltraps
  102046:	e9 b8 05 00 00       	jmp    102603 <__alltraps>

0010204b <vector134>:
.globl vector134
vector134:
  pushl $0
  10204b:	6a 00                	push   $0x0
  pushl $134
  10204d:	68 86 00 00 00       	push   $0x86
  jmp __alltraps
  102052:	e9 ac 05 00 00       	jmp    102603 <__alltraps>

00102057 <vector135>:
.globl vector135
vector135:
  pushl $0
  102057:	6a 00                	push   $0x0
  pushl $135
  102059:	68 87 00 00 00       	push   $0x87
  jmp __alltraps
  10205e:	e9 a0 05 00 00       	jmp    102603 <__alltraps>

00102063 <vector136>:
.globl vector136
vector136:
  pushl $0
  102063:	6a 00                	push   $0x0
  pushl $136
  102065:	68 88 00 00 00       	push   $0x88
  jmp __alltraps
  10206a:	e9 94 05 00 00       	jmp    102603 <__alltraps>

0010206f <vector137>:
.globl vector137
vector137:
  pushl $0
  10206f:	6a 00                	push   $0x0
  pushl $137
  102071:	68 89 00 00 00       	push   $0x89
  jmp __alltraps
  102076:	e9 88 05 00 00       	jmp    102603 <__alltraps>

0010207b <vector138>:
.globl vector138
vector138:
  pushl $0
  10207b:	6a 00                	push   $0x0
  pushl $138
  10207d:	68 8a 00 00 00       	push   $0x8a
  jmp __alltraps
  102082:	e9 7c 05 00 00       	jmp    102603 <__alltraps>

00102087 <vector139>:
.globl vector139
vector139:
  pushl $0
  102087:	6a 00                	push   $0x0
  pushl $139
  102089:	68 8b 00 00 00       	push   $0x8b
  jmp __alltraps
  10208e:	e9 70 05 00 00       	jmp    102603 <__alltraps>

00102093 <vector140>:
.globl vector140
vector140:
  pushl $0
  102093:	6a 00                	push   $0x0
  pushl $140
  102095:	68 8c 00 00 00       	push   $0x8c
  jmp __alltraps
  10209a:	e9 64 05 00 00       	jmp    102603 <__alltraps>

0010209f <vector141>:
.globl vector141
vector141:
  pushl $0
  10209f:	6a 00                	push   $0x0
  pushl $141
  1020a1:	68 8d 00 00 00       	push   $0x8d
  jmp __alltraps
  1020a6:	e9 58 05 00 00       	jmp    102603 <__alltraps>

001020ab <vector142>:
.globl vector142
vector142:
  pushl $0
  1020ab:	6a 00                	push   $0x0
  pushl $142
  1020ad:	68 8e 00 00 00       	push   $0x8e
  jmp __alltraps
  1020b2:	e9 4c 05 00 00       	jmp    102603 <__alltraps>

001020b7 <vector143>:
.globl vector143
vector143:
  pushl $0
  1020b7:	6a 00                	push   $0x0
  pushl $143
  1020b9:	68 8f 00 00 00       	push   $0x8f
  jmp __alltraps
  1020be:	e9 40 05 00 00       	jmp    102603 <__alltraps>

001020c3 <vector144>:
.globl vector144
vector144:
  pushl $0
  1020c3:	6a 00                	push   $0x0
  pushl $144
  1020c5:	68 90 00 00 00       	push   $0x90
  jmp __alltraps
  1020ca:	e9 34 05 00 00       	jmp    102603 <__alltraps>

001020cf <vector145>:
.globl vector145
vector145:
  pushl $0
  1020cf:	6a 00                	push   $0x0
  pushl $145
  1020d1:	68 91 00 00 00       	push   $0x91
  jmp __alltraps
  1020d6:	e9 28 05 00 00       	jmp    102603 <__alltraps>

001020db <vector146>:
.globl vector146
vector146:
  pushl $0
  1020db:	6a 00                	push   $0x0
  pushl $146
  1020dd:	68 92 00 00 00       	push   $0x92
  jmp __alltraps
  1020e2:	e9 1c 05 00 00       	jmp    102603 <__alltraps>

001020e7 <vector147>:
.globl vector147
vector147:
  pushl $0
  1020e7:	6a 00                	push   $0x0
  pushl $147
  1020e9:	68 93 00 00 00       	push   $0x93
  jmp __alltraps
  1020ee:	e9 10 05 00 00       	jmp    102603 <__alltraps>

001020f3 <vector148>:
.globl vector148
vector148:
  pushl $0
  1020f3:	6a 00                	push   $0x0
  pushl $148
  1020f5:	68 94 00 00 00       	push   $0x94
  jmp __alltraps
  1020fa:	e9 04 05 00 00       	jmp    102603 <__alltraps>

001020ff <vector149>:
.globl vector149
vector149:
  pushl $0
  1020ff:	6a 00                	push   $0x0
  pushl $149
  102101:	68 95 00 00 00       	push   $0x95
  jmp __alltraps
  102106:	e9 f8 04 00 00       	jmp    102603 <__alltraps>

0010210b <vector150>:
.globl vector150
vector150:
  pushl $0
  10210b:	6a 00                	push   $0x0
  pushl $150
  10210d:	68 96 00 00 00       	push   $0x96
  jmp __alltraps
  102112:	e9 ec 04 00 00       	jmp    102603 <__alltraps>

00102117 <vector151>:
.globl vector151
vector151:
  pushl $0
  102117:	6a 00                	push   $0x0
  pushl $151
  102119:	68 97 00 00 00       	push   $0x97
  jmp __alltraps
  10211e:	e9 e0 04 00 00       	jmp    102603 <__alltraps>

00102123 <vector152>:
.globl vector152
vector152:
  pushl $0
  102123:	6a 00                	push   $0x0
  pushl $152
  102125:	68 98 00 00 00       	push   $0x98
  jmp __alltraps
  10212a:	e9 d4 04 00 00       	jmp    102603 <__alltraps>

0010212f <vector153>:
.globl vector153
vector153:
  pushl $0
  10212f:	6a 00                	push   $0x0
  pushl $153
  102131:	68 99 00 00 00       	push   $0x99
  jmp __alltraps
  102136:	e9 c8 04 00 00       	jmp    102603 <__alltraps>

0010213b <vector154>:
.globl vector154
vector154:
  pushl $0
  10213b:	6a 00                	push   $0x0
  pushl $154
  10213d:	68 9a 00 00 00       	push   $0x9a
  jmp __alltraps
  102142:	e9 bc 04 00 00       	jmp    102603 <__alltraps>

00102147 <vector155>:
.globl vector155
vector155:
  pushl $0
  102147:	6a 00                	push   $0x0
  pushl $155
  102149:	68 9b 00 00 00       	push   $0x9b
  jmp __alltraps
  10214e:	e9 b0 04 00 00       	jmp    102603 <__alltraps>

00102153 <vector156>:
.globl vector156
vector156:
  pushl $0
  102153:	6a 00                	push   $0x0
  pushl $156
  102155:	68 9c 00 00 00       	push   $0x9c
  jmp __alltraps
  10215a:	e9 a4 04 00 00       	jmp    102603 <__alltraps>

0010215f <vector157>:
.globl vector157
vector157:
  pushl $0
  10215f:	6a 00                	push   $0x0
  pushl $157
  102161:	68 9d 00 00 00       	push   $0x9d
  jmp __alltraps
  102166:	e9 98 04 00 00       	jmp    102603 <__alltraps>

0010216b <vector158>:
.globl vector158
vector158:
  pushl $0
  10216b:	6a 00                	push   $0x0
  pushl $158
  10216d:	68 9e 00 00 00       	push   $0x9e
  jmp __alltraps
  102172:	e9 8c 04 00 00       	jmp    102603 <__alltraps>

00102177 <vector159>:
.globl vector159
vector159:
  pushl $0
  102177:	6a 00                	push   $0x0
  pushl $159
  102179:	68 9f 00 00 00       	push   $0x9f
  jmp __alltraps
  10217e:	e9 80 04 00 00       	jmp    102603 <__alltraps>

00102183 <vector160>:
.globl vector160
vector160:
  pushl $0
  102183:	6a 00                	push   $0x0
  pushl $160
  102185:	68 a0 00 00 00       	push   $0xa0
  jmp __alltraps
  10218a:	e9 74 04 00 00       	jmp    102603 <__alltraps>

0010218f <vector161>:
.globl vector161
vector161:
  pushl $0
  10218f:	6a 00                	push   $0x0
  pushl $161
  102191:	68 a1 00 00 00       	push   $0xa1
  jmp __alltraps
  102196:	e9 68 04 00 00       	jmp    102603 <__alltraps>

0010219b <vector162>:
.globl vector162
vector162:
  pushl $0
  10219b:	6a 00                	push   $0x0
  pushl $162
  10219d:	68 a2 00 00 00       	push   $0xa2
  jmp __alltraps
  1021a2:	e9 5c 04 00 00       	jmp    102603 <__alltraps>

001021a7 <vector163>:
.globl vector163
vector163:
  pushl $0
  1021a7:	6a 00                	push   $0x0
  pushl $163
  1021a9:	68 a3 00 00 00       	push   $0xa3
  jmp __alltraps
  1021ae:	e9 50 04 00 00       	jmp    102603 <__alltraps>

001021b3 <vector164>:
.globl vector164
vector164:
  pushl $0
  1021b3:	6a 00                	push   $0x0
  pushl $164
  1021b5:	68 a4 00 00 00       	push   $0xa4
  jmp __alltraps
  1021ba:	e9 44 04 00 00       	jmp    102603 <__alltraps>

001021bf <vector165>:
.globl vector165
vector165:
  pushl $0
  1021bf:	6a 00                	push   $0x0
  pushl $165
  1021c1:	68 a5 00 00 00       	push   $0xa5
  jmp __alltraps
  1021c6:	e9 38 04 00 00       	jmp    102603 <__alltraps>

001021cb <vector166>:
.globl vector166
vector166:
  pushl $0
  1021cb:	6a 00                	push   $0x0
  pushl $166
  1021cd:	68 a6 00 00 00       	push   $0xa6
  jmp __alltraps
  1021d2:	e9 2c 04 00 00       	jmp    102603 <__alltraps>

001021d7 <vector167>:
.globl vector167
vector167:
  pushl $0
  1021d7:	6a 00                	push   $0x0
  pushl $167
  1021d9:	68 a7 00 00 00       	push   $0xa7
  jmp __alltraps
  1021de:	e9 20 04 00 00       	jmp    102603 <__alltraps>

001021e3 <vector168>:
.globl vector168
vector168:
  pushl $0
  1021e3:	6a 00                	push   $0x0
  pushl $168
  1021e5:	68 a8 00 00 00       	push   $0xa8
  jmp __alltraps
  1021ea:	e9 14 04 00 00       	jmp    102603 <__alltraps>

001021ef <vector169>:
.globl vector169
vector169:
  pushl $0
  1021ef:	6a 00                	push   $0x0
  pushl $169
  1021f1:	68 a9 00 00 00       	push   $0xa9
  jmp __alltraps
  1021f6:	e9 08 04 00 00       	jmp    102603 <__alltraps>

001021fb <vector170>:
.globl vector170
vector170:
  pushl $0
  1021fb:	6a 00                	push   $0x0
  pushl $170
  1021fd:	68 aa 00 00 00       	push   $0xaa
  jmp __alltraps
  102202:	e9 fc 03 00 00       	jmp    102603 <__alltraps>

00102207 <vector171>:
.globl vector171
vector171:
  pushl $0
  102207:	6a 00                	push   $0x0
  pushl $171
  102209:	68 ab 00 00 00       	push   $0xab
  jmp __alltraps
  10220e:	e9 f0 03 00 00       	jmp    102603 <__alltraps>

00102213 <vector172>:
.globl vector172
vector172:
  pushl $0
  102213:	6a 00                	push   $0x0
  pushl $172
  102215:	68 ac 00 00 00       	push   $0xac
  jmp __alltraps
  10221a:	e9 e4 03 00 00       	jmp    102603 <__alltraps>

0010221f <vector173>:
.globl vector173
vector173:
  pushl $0
  10221f:	6a 00                	push   $0x0
  pushl $173
  102221:	68 ad 00 00 00       	push   $0xad
  jmp __alltraps
  102226:	e9 d8 03 00 00       	jmp    102603 <__alltraps>

0010222b <vector174>:
.globl vector174
vector174:
  pushl $0
  10222b:	6a 00                	push   $0x0
  pushl $174
  10222d:	68 ae 00 00 00       	push   $0xae
  jmp __alltraps
  102232:	e9 cc 03 00 00       	jmp    102603 <__alltraps>

00102237 <vector175>:
.globl vector175
vector175:
  pushl $0
  102237:	6a 00                	push   $0x0
  pushl $175
  102239:	68 af 00 00 00       	push   $0xaf
  jmp __alltraps
  10223e:	e9 c0 03 00 00       	jmp    102603 <__alltraps>

00102243 <vector176>:
.globl vector176
vector176:
  pushl $0
  102243:	6a 00                	push   $0x0
  pushl $176
  102245:	68 b0 00 00 00       	push   $0xb0
  jmp __alltraps
  10224a:	e9 b4 03 00 00       	jmp    102603 <__alltraps>

0010224f <vector177>:
.globl vector177
vector177:
  pushl $0
  10224f:	6a 00                	push   $0x0
  pushl $177
  102251:	68 b1 00 00 00       	push   $0xb1
  jmp __alltraps
  102256:	e9 a8 03 00 00       	jmp    102603 <__alltraps>

0010225b <vector178>:
.globl vector178
vector178:
  pushl $0
  10225b:	6a 00                	push   $0x0
  pushl $178
  10225d:	68 b2 00 00 00       	push   $0xb2
  jmp __alltraps
  102262:	e9 9c 03 00 00       	jmp    102603 <__alltraps>

00102267 <vector179>:
.globl vector179
vector179:
  pushl $0
  102267:	6a 00                	push   $0x0
  pushl $179
  102269:	68 b3 00 00 00       	push   $0xb3
  jmp __alltraps
  10226e:	e9 90 03 00 00       	jmp    102603 <__alltraps>

00102273 <vector180>:
.globl vector180
vector180:
  pushl $0
  102273:	6a 00                	push   $0x0
  pushl $180
  102275:	68 b4 00 00 00       	push   $0xb4
  jmp __alltraps
  10227a:	e9 84 03 00 00       	jmp    102603 <__alltraps>

0010227f <vector181>:
.globl vector181
vector181:
  pushl $0
  10227f:	6a 00                	push   $0x0
  pushl $181
  102281:	68 b5 00 00 00       	push   $0xb5
  jmp __alltraps
  102286:	e9 78 03 00 00       	jmp    102603 <__alltraps>

0010228b <vector182>:
.globl vector182
vector182:
  pushl $0
  10228b:	6a 00                	push   $0x0
  pushl $182
  10228d:	68 b6 00 00 00       	push   $0xb6
  jmp __alltraps
  102292:	e9 6c 03 00 00       	jmp    102603 <__alltraps>

00102297 <vector183>:
.globl vector183
vector183:
  pushl $0
  102297:	6a 00                	push   $0x0
  pushl $183
  102299:	68 b7 00 00 00       	push   $0xb7
  jmp __alltraps
  10229e:	e9 60 03 00 00       	jmp    102603 <__alltraps>

001022a3 <vector184>:
.globl vector184
vector184:
  pushl $0
  1022a3:	6a 00                	push   $0x0
  pushl $184
  1022a5:	68 b8 00 00 00       	push   $0xb8
  jmp __alltraps
  1022aa:	e9 54 03 00 00       	jmp    102603 <__alltraps>

001022af <vector185>:
.globl vector185
vector185:
  pushl $0
  1022af:	6a 00                	push   $0x0
  pushl $185
  1022b1:	68 b9 00 00 00       	push   $0xb9
  jmp __alltraps
  1022b6:	e9 48 03 00 00       	jmp    102603 <__alltraps>

001022bb <vector186>:
.globl vector186
vector186:
  pushl $0
  1022bb:	6a 00                	push   $0x0
  pushl $186
  1022bd:	68 ba 00 00 00       	push   $0xba
  jmp __alltraps
  1022c2:	e9 3c 03 00 00       	jmp    102603 <__alltraps>

001022c7 <vector187>:
.globl vector187
vector187:
  pushl $0
  1022c7:	6a 00                	push   $0x0
  pushl $187
  1022c9:	68 bb 00 00 00       	push   $0xbb
  jmp __alltraps
  1022ce:	e9 30 03 00 00       	jmp    102603 <__alltraps>

001022d3 <vector188>:
.globl vector188
vector188:
  pushl $0
  1022d3:	6a 00                	push   $0x0
  pushl $188
  1022d5:	68 bc 00 00 00       	push   $0xbc
  jmp __alltraps
  1022da:	e9 24 03 00 00       	jmp    102603 <__alltraps>

001022df <vector189>:
.globl vector189
vector189:
  pushl $0
  1022df:	6a 00                	push   $0x0
  pushl $189
  1022e1:	68 bd 00 00 00       	push   $0xbd
  jmp __alltraps
  1022e6:	e9 18 03 00 00       	jmp    102603 <__alltraps>

001022eb <vector190>:
.globl vector190
vector190:
  pushl $0
  1022eb:	6a 00                	push   $0x0
  pushl $190
  1022ed:	68 be 00 00 00       	push   $0xbe
  jmp __alltraps
  1022f2:	e9 0c 03 00 00       	jmp    102603 <__alltraps>

001022f7 <vector191>:
.globl vector191
vector191:
  pushl $0
  1022f7:	6a 00                	push   $0x0
  pushl $191
  1022f9:	68 bf 00 00 00       	push   $0xbf
  jmp __alltraps
  1022fe:	e9 00 03 00 00       	jmp    102603 <__alltraps>

00102303 <vector192>:
.globl vector192
vector192:
  pushl $0
  102303:	6a 00                	push   $0x0
  pushl $192
  102305:	68 c0 00 00 00       	push   $0xc0
  jmp __alltraps
  10230a:	e9 f4 02 00 00       	jmp    102603 <__alltraps>

0010230f <vector193>:
.globl vector193
vector193:
  pushl $0
  10230f:	6a 00                	push   $0x0
  pushl $193
  102311:	68 c1 00 00 00       	push   $0xc1
  jmp __alltraps
  102316:	e9 e8 02 00 00       	jmp    102603 <__alltraps>

0010231b <vector194>:
.globl vector194
vector194:
  pushl $0
  10231b:	6a 00                	push   $0x0
  pushl $194
  10231d:	68 c2 00 00 00       	push   $0xc2
  jmp __alltraps
  102322:	e9 dc 02 00 00       	jmp    102603 <__alltraps>

00102327 <vector195>:
.globl vector195
vector195:
  pushl $0
  102327:	6a 00                	push   $0x0
  pushl $195
  102329:	68 c3 00 00 00       	push   $0xc3
  jmp __alltraps
  10232e:	e9 d0 02 00 00       	jmp    102603 <__alltraps>

00102333 <vector196>:
.globl vector196
vector196:
  pushl $0
  102333:	6a 00                	push   $0x0
  pushl $196
  102335:	68 c4 00 00 00       	push   $0xc4
  jmp __alltraps
  10233a:	e9 c4 02 00 00       	jmp    102603 <__alltraps>

0010233f <vector197>:
.globl vector197
vector197:
  pushl $0
  10233f:	6a 00                	push   $0x0
  pushl $197
  102341:	68 c5 00 00 00       	push   $0xc5
  jmp __alltraps
  102346:	e9 b8 02 00 00       	jmp    102603 <__alltraps>

0010234b <vector198>:
.globl vector198
vector198:
  pushl $0
  10234b:	6a 00                	push   $0x0
  pushl $198
  10234d:	68 c6 00 00 00       	push   $0xc6
  jmp __alltraps
  102352:	e9 ac 02 00 00       	jmp    102603 <__alltraps>

00102357 <vector199>:
.globl vector199
vector199:
  pushl $0
  102357:	6a 00                	push   $0x0
  pushl $199
  102359:	68 c7 00 00 00       	push   $0xc7
  jmp __alltraps
  10235e:	e9 a0 02 00 00       	jmp    102603 <__alltraps>

00102363 <vector200>:
.globl vector200
vector200:
  pushl $0
  102363:	6a 00                	push   $0x0
  pushl $200
  102365:	68 c8 00 00 00       	push   $0xc8
  jmp __alltraps
  10236a:	e9 94 02 00 00       	jmp    102603 <__alltraps>

0010236f <vector201>:
.globl vector201
vector201:
  pushl $0
  10236f:	6a 00                	push   $0x0
  pushl $201
  102371:	68 c9 00 00 00       	push   $0xc9
  jmp __alltraps
  102376:	e9 88 02 00 00       	jmp    102603 <__alltraps>

0010237b <vector202>:
.globl vector202
vector202:
  pushl $0
  10237b:	6a 00                	push   $0x0
  pushl $202
  10237d:	68 ca 00 00 00       	push   $0xca
  jmp __alltraps
  102382:	e9 7c 02 00 00       	jmp    102603 <__alltraps>

00102387 <vector203>:
.globl vector203
vector203:
  pushl $0
  102387:	6a 00                	push   $0x0
  pushl $203
  102389:	68 cb 00 00 00       	push   $0xcb
  jmp __alltraps
  10238e:	e9 70 02 00 00       	jmp    102603 <__alltraps>

00102393 <vector204>:
.globl vector204
vector204:
  pushl $0
  102393:	6a 00                	push   $0x0
  pushl $204
  102395:	68 cc 00 00 00       	push   $0xcc
  jmp __alltraps
  10239a:	e9 64 02 00 00       	jmp    102603 <__alltraps>

0010239f <vector205>:
.globl vector205
vector205:
  pushl $0
  10239f:	6a 00                	push   $0x0
  pushl $205
  1023a1:	68 cd 00 00 00       	push   $0xcd
  jmp __alltraps
  1023a6:	e9 58 02 00 00       	jmp    102603 <__alltraps>

001023ab <vector206>:
.globl vector206
vector206:
  pushl $0
  1023ab:	6a 00                	push   $0x0
  pushl $206
  1023ad:	68 ce 00 00 00       	push   $0xce
  jmp __alltraps
  1023b2:	e9 4c 02 00 00       	jmp    102603 <__alltraps>

001023b7 <vector207>:
.globl vector207
vector207:
  pushl $0
  1023b7:	6a 00                	push   $0x0
  pushl $207
  1023b9:	68 cf 00 00 00       	push   $0xcf
  jmp __alltraps
  1023be:	e9 40 02 00 00       	jmp    102603 <__alltraps>

001023c3 <vector208>:
.globl vector208
vector208:
  pushl $0
  1023c3:	6a 00                	push   $0x0
  pushl $208
  1023c5:	68 d0 00 00 00       	push   $0xd0
  jmp __alltraps
  1023ca:	e9 34 02 00 00       	jmp    102603 <__alltraps>

001023cf <vector209>:
.globl vector209
vector209:
  pushl $0
  1023cf:	6a 00                	push   $0x0
  pushl $209
  1023d1:	68 d1 00 00 00       	push   $0xd1
  jmp __alltraps
  1023d6:	e9 28 02 00 00       	jmp    102603 <__alltraps>

001023db <vector210>:
.globl vector210
vector210:
  pushl $0
  1023db:	6a 00                	push   $0x0
  pushl $210
  1023dd:	68 d2 00 00 00       	push   $0xd2
  jmp __alltraps
  1023e2:	e9 1c 02 00 00       	jmp    102603 <__alltraps>

001023e7 <vector211>:
.globl vector211
vector211:
  pushl $0
  1023e7:	6a 00                	push   $0x0
  pushl $211
  1023e9:	68 d3 00 00 00       	push   $0xd3
  jmp __alltraps
  1023ee:	e9 10 02 00 00       	jmp    102603 <__alltraps>

001023f3 <vector212>:
.globl vector212
vector212:
  pushl $0
  1023f3:	6a 00                	push   $0x0
  pushl $212
  1023f5:	68 d4 00 00 00       	push   $0xd4
  jmp __alltraps
  1023fa:	e9 04 02 00 00       	jmp    102603 <__alltraps>

001023ff <vector213>:
.globl vector213
vector213:
  pushl $0
  1023ff:	6a 00                	push   $0x0
  pushl $213
  102401:	68 d5 00 00 00       	push   $0xd5
  jmp __alltraps
  102406:	e9 f8 01 00 00       	jmp    102603 <__alltraps>

0010240b <vector214>:
.globl vector214
vector214:
  pushl $0
  10240b:	6a 00                	push   $0x0
  pushl $214
  10240d:	68 d6 00 00 00       	push   $0xd6
  jmp __alltraps
  102412:	e9 ec 01 00 00       	jmp    102603 <__alltraps>

00102417 <vector215>:
.globl vector215
vector215:
  pushl $0
  102417:	6a 00                	push   $0x0
  pushl $215
  102419:	68 d7 00 00 00       	push   $0xd7
  jmp __alltraps
  10241e:	e9 e0 01 00 00       	jmp    102603 <__alltraps>

00102423 <vector216>:
.globl vector216
vector216:
  pushl $0
  102423:	6a 00                	push   $0x0
  pushl $216
  102425:	68 d8 00 00 00       	push   $0xd8
  jmp __alltraps
  10242a:	e9 d4 01 00 00       	jmp    102603 <__alltraps>

0010242f <vector217>:
.globl vector217
vector217:
  pushl $0
  10242f:	6a 00                	push   $0x0
  pushl $217
  102431:	68 d9 00 00 00       	push   $0xd9
  jmp __alltraps
  102436:	e9 c8 01 00 00       	jmp    102603 <__alltraps>

0010243b <vector218>:
.globl vector218
vector218:
  pushl $0
  10243b:	6a 00                	push   $0x0
  pushl $218
  10243d:	68 da 00 00 00       	push   $0xda
  jmp __alltraps
  102442:	e9 bc 01 00 00       	jmp    102603 <__alltraps>

00102447 <vector219>:
.globl vector219
vector219:
  pushl $0
  102447:	6a 00                	push   $0x0
  pushl $219
  102449:	68 db 00 00 00       	push   $0xdb
  jmp __alltraps
  10244e:	e9 b0 01 00 00       	jmp    102603 <__alltraps>

00102453 <vector220>:
.globl vector220
vector220:
  pushl $0
  102453:	6a 00                	push   $0x0
  pushl $220
  102455:	68 dc 00 00 00       	push   $0xdc
  jmp __alltraps
  10245a:	e9 a4 01 00 00       	jmp    102603 <__alltraps>

0010245f <vector221>:
.globl vector221
vector221:
  pushl $0
  10245f:	6a 00                	push   $0x0
  pushl $221
  102461:	68 dd 00 00 00       	push   $0xdd
  jmp __alltraps
  102466:	e9 98 01 00 00       	jmp    102603 <__alltraps>

0010246b <vector222>:
.globl vector222
vector222:
  pushl $0
  10246b:	6a 00                	push   $0x0
  pushl $222
  10246d:	68 de 00 00 00       	push   $0xde
  jmp __alltraps
  102472:	e9 8c 01 00 00       	jmp    102603 <__alltraps>

00102477 <vector223>:
.globl vector223
vector223:
  pushl $0
  102477:	6a 00                	push   $0x0
  pushl $223
  102479:	68 df 00 00 00       	push   $0xdf
  jmp __alltraps
  10247e:	e9 80 01 00 00       	jmp    102603 <__alltraps>

00102483 <vector224>:
.globl vector224
vector224:
  pushl $0
  102483:	6a 00                	push   $0x0
  pushl $224
  102485:	68 e0 00 00 00       	push   $0xe0
  jmp __alltraps
  10248a:	e9 74 01 00 00       	jmp    102603 <__alltraps>

0010248f <vector225>:
.globl vector225
vector225:
  pushl $0
  10248f:	6a 00                	push   $0x0
  pushl $225
  102491:	68 e1 00 00 00       	push   $0xe1
  jmp __alltraps
  102496:	e9 68 01 00 00       	jmp    102603 <__alltraps>

0010249b <vector226>:
.globl vector226
vector226:
  pushl $0
  10249b:	6a 00                	push   $0x0
  pushl $226
  10249d:	68 e2 00 00 00       	push   $0xe2
  jmp __alltraps
  1024a2:	e9 5c 01 00 00       	jmp    102603 <__alltraps>

001024a7 <vector227>:
.globl vector227
vector227:
  pushl $0
  1024a7:	6a 00                	push   $0x0
  pushl $227
  1024a9:	68 e3 00 00 00       	push   $0xe3
  jmp __alltraps
  1024ae:	e9 50 01 00 00       	jmp    102603 <__alltraps>

001024b3 <vector228>:
.globl vector228
vector228:
  pushl $0
  1024b3:	6a 00                	push   $0x0
  pushl $228
  1024b5:	68 e4 00 00 00       	push   $0xe4
  jmp __alltraps
  1024ba:	e9 44 01 00 00       	jmp    102603 <__alltraps>

001024bf <vector229>:
.globl vector229
vector229:
  pushl $0
  1024bf:	6a 00                	push   $0x0
  pushl $229
  1024c1:	68 e5 00 00 00       	push   $0xe5
  jmp __alltraps
  1024c6:	e9 38 01 00 00       	jmp    102603 <__alltraps>

001024cb <vector230>:
.globl vector230
vector230:
  pushl $0
  1024cb:	6a 00                	push   $0x0
  pushl $230
  1024cd:	68 e6 00 00 00       	push   $0xe6
  jmp __alltraps
  1024d2:	e9 2c 01 00 00       	jmp    102603 <__alltraps>

001024d7 <vector231>:
.globl vector231
vector231:
  pushl $0
  1024d7:	6a 00                	push   $0x0
  pushl $231
  1024d9:	68 e7 00 00 00       	push   $0xe7
  jmp __alltraps
  1024de:	e9 20 01 00 00       	jmp    102603 <__alltraps>

001024e3 <vector232>:
.globl vector232
vector232:
  pushl $0
  1024e3:	6a 00                	push   $0x0
  pushl $232
  1024e5:	68 e8 00 00 00       	push   $0xe8
  jmp __alltraps
  1024ea:	e9 14 01 00 00       	jmp    102603 <__alltraps>

001024ef <vector233>:
.globl vector233
vector233:
  pushl $0
  1024ef:	6a 00                	push   $0x0
  pushl $233
  1024f1:	68 e9 00 00 00       	push   $0xe9
  jmp __alltraps
  1024f6:	e9 08 01 00 00       	jmp    102603 <__alltraps>

001024fb <vector234>:
.globl vector234
vector234:
  pushl $0
  1024fb:	6a 00                	push   $0x0
  pushl $234
  1024fd:	68 ea 00 00 00       	push   $0xea
  jmp __alltraps
  102502:	e9 fc 00 00 00       	jmp    102603 <__alltraps>

00102507 <vector235>:
.globl vector235
vector235:
  pushl $0
  102507:	6a 00                	push   $0x0
  pushl $235
  102509:	68 eb 00 00 00       	push   $0xeb
  jmp __alltraps
  10250e:	e9 f0 00 00 00       	jmp    102603 <__alltraps>

00102513 <vector236>:
.globl vector236
vector236:
  pushl $0
  102513:	6a 00                	push   $0x0
  pushl $236
  102515:	68 ec 00 00 00       	push   $0xec
  jmp __alltraps
  10251a:	e9 e4 00 00 00       	jmp    102603 <__alltraps>

0010251f <vector237>:
.globl vector237
vector237:
  pushl $0
  10251f:	6a 00                	push   $0x0
  pushl $237
  102521:	68 ed 00 00 00       	push   $0xed
  jmp __alltraps
  102526:	e9 d8 00 00 00       	jmp    102603 <__alltraps>

0010252b <vector238>:
.globl vector238
vector238:
  pushl $0
  10252b:	6a 00                	push   $0x0
  pushl $238
  10252d:	68 ee 00 00 00       	push   $0xee
  jmp __alltraps
  102532:	e9 cc 00 00 00       	jmp    102603 <__alltraps>

00102537 <vector239>:
.globl vector239
vector239:
  pushl $0
  102537:	6a 00                	push   $0x0
  pushl $239
  102539:	68 ef 00 00 00       	push   $0xef
  jmp __alltraps
  10253e:	e9 c0 00 00 00       	jmp    102603 <__alltraps>

00102543 <vector240>:
.globl vector240
vector240:
  pushl $0
  102543:	6a 00                	push   $0x0
  pushl $240
  102545:	68 f0 00 00 00       	push   $0xf0
  jmp __alltraps
  10254a:	e9 b4 00 00 00       	jmp    102603 <__alltraps>

0010254f <vector241>:
.globl vector241
vector241:
  pushl $0
  10254f:	6a 00                	push   $0x0
  pushl $241
  102551:	68 f1 00 00 00       	push   $0xf1
  jmp __alltraps
  102556:	e9 a8 00 00 00       	jmp    102603 <__alltraps>

0010255b <vector242>:
.globl vector242
vector242:
  pushl $0
  10255b:	6a 00                	push   $0x0
  pushl $242
  10255d:	68 f2 00 00 00       	push   $0xf2
  jmp __alltraps
  102562:	e9 9c 00 00 00       	jmp    102603 <__alltraps>

00102567 <vector243>:
.globl vector243
vector243:
  pushl $0
  102567:	6a 00                	push   $0x0
  pushl $243
  102569:	68 f3 00 00 00       	push   $0xf3
  jmp __alltraps
  10256e:	e9 90 00 00 00       	jmp    102603 <__alltraps>

00102573 <vector244>:
.globl vector244
vector244:
  pushl $0
  102573:	6a 00                	push   $0x0
  pushl $244
  102575:	68 f4 00 00 00       	push   $0xf4
  jmp __alltraps
  10257a:	e9 84 00 00 00       	jmp    102603 <__alltraps>

0010257f <vector245>:
.globl vector245
vector245:
  pushl $0
  10257f:	6a 00                	push   $0x0
  pushl $245
  102581:	68 f5 00 00 00       	push   $0xf5
  jmp __alltraps
  102586:	e9 78 00 00 00       	jmp    102603 <__alltraps>

0010258b <vector246>:
.globl vector246
vector246:
  pushl $0
  10258b:	6a 00                	push   $0x0
  pushl $246
  10258d:	68 f6 00 00 00       	push   $0xf6
  jmp __alltraps
  102592:	e9 6c 00 00 00       	jmp    102603 <__alltraps>

00102597 <vector247>:
.globl vector247
vector247:
  pushl $0
  102597:	6a 00                	push   $0x0
  pushl $247
  102599:	68 f7 00 00 00       	push   $0xf7
  jmp __alltraps
  10259e:	e9 60 00 00 00       	jmp    102603 <__alltraps>

001025a3 <vector248>:
.globl vector248
vector248:
  pushl $0
  1025a3:	6a 00                	push   $0x0
  pushl $248
  1025a5:	68 f8 00 00 00       	push   $0xf8
  jmp __alltraps
  1025aa:	e9 54 00 00 00       	jmp    102603 <__alltraps>

001025af <vector249>:
.globl vector249
vector249:
  pushl $0
  1025af:	6a 00                	push   $0x0
  pushl $249
  1025b1:	68 f9 00 00 00       	push   $0xf9
  jmp __alltraps
  1025b6:	e9 48 00 00 00       	jmp    102603 <__alltraps>

001025bb <vector250>:
.globl vector250
vector250:
  pushl $0
  1025bb:	6a 00                	push   $0x0
  pushl $250
  1025bd:	68 fa 00 00 00       	push   $0xfa
  jmp __alltraps
  1025c2:	e9 3c 00 00 00       	jmp    102603 <__alltraps>

001025c7 <vector251>:
.globl vector251
vector251:
  pushl $0
  1025c7:	6a 00                	push   $0x0
  pushl $251
  1025c9:	68 fb 00 00 00       	push   $0xfb
  jmp __alltraps
  1025ce:	e9 30 00 00 00       	jmp    102603 <__alltraps>

001025d3 <vector252>:
.globl vector252
vector252:
  pushl $0
  1025d3:	6a 00                	push   $0x0
  pushl $252
  1025d5:	68 fc 00 00 00       	push   $0xfc
  jmp __alltraps
  1025da:	e9 24 00 00 00       	jmp    102603 <__alltraps>

001025df <vector253>:
.globl vector253
vector253:
  pushl $0
  1025df:	6a 00                	push   $0x0
  pushl $253
  1025e1:	68 fd 00 00 00       	push   $0xfd
  jmp __alltraps
  1025e6:	e9 18 00 00 00       	jmp    102603 <__alltraps>

001025eb <vector254>:
.globl vector254
vector254:
  pushl $0
  1025eb:	6a 00                	push   $0x0
  pushl $254
  1025ed:	68 fe 00 00 00       	push   $0xfe
  jmp __alltraps
  1025f2:	e9 0c 00 00 00       	jmp    102603 <__alltraps>

001025f7 <vector255>:
.globl vector255
vector255:
  pushl $0
  1025f7:	6a 00                	push   $0x0
  pushl $255
  1025f9:	68 ff 00 00 00       	push   $0xff
  jmp __alltraps
  1025fe:	e9 00 00 00 00       	jmp    102603 <__alltraps>

00102603 <__alltraps>:
.text
.globl __alltraps
__alltraps:
    # push registers to build a trap frame
    # therefore make the stack look like a struct trapframe
    pushl %ds
  102603:	1e                   	push   %ds
    pushl %es
  102604:	06                   	push   %es
    pushl %fs
  102605:	0f a0                	push   %fs
    pushl %gs
  102607:	0f a8                	push   %gs
    pushal
  102609:	60                   	pusha  

    # load GD_KDATA into %ds and %es to set up data segments for kernel
    movl $GD_KDATA, %eax
  10260a:	b8 10 00 00 00       	mov    $0x10,%eax
    movw %ax, %ds
  10260f:	8e d8                	mov    %eax,%ds
    movw %ax, %es
  102611:	8e c0                	mov    %eax,%es

    # push %esp to pass a pointer to the trapframe as an argument to trap()
    pushl %esp
  102613:	54                   	push   %esp

    # call trap(tf), where tf=%esp
    call trap
  102614:	e8 64 f5 ff ff       	call   101b7d <trap>

    # pop the pushed stack pointer
    popl %esp
  102619:	5c                   	pop    %esp

0010261a <__trapret>:

    # return falls through to trapret...
.globl __trapret
__trapret:
    # restore registers from stack
    popal
  10261a:	61                   	popa   

    # restore %ds, %es, %fs and %gs
    popl %gs
  10261b:	0f a9                	pop    %gs
    popl %fs
  10261d:	0f a1                	pop    %fs
    popl %es
  10261f:	07                   	pop    %es
    popl %ds
  102620:	1f                   	pop    %ds

    # get rid of the trap number and error code
    addl $0x8, %esp
  102621:	83 c4 08             	add    $0x8,%esp
    iret
  102624:	cf                   	iret   

00102625 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
  102625:	55                   	push   %ebp
  102626:	89 e5                	mov    %esp,%ebp
    return page - pages;
  102628:	8b 45 08             	mov    0x8(%ebp),%eax
  10262b:	8b 15 18 af 11 00    	mov    0x11af18,%edx
  102631:	29 d0                	sub    %edx,%eax
  102633:	c1 f8 02             	sar    $0x2,%eax
  102636:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
  10263c:	5d                   	pop    %ebp
  10263d:	c3                   	ret    

0010263e <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
  10263e:	55                   	push   %ebp
  10263f:	89 e5                	mov    %esp,%ebp
  102641:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
  102644:	8b 45 08             	mov    0x8(%ebp),%eax
  102647:	89 04 24             	mov    %eax,(%esp)
  10264a:	e8 d6 ff ff ff       	call   102625 <page2ppn>
  10264f:	c1 e0 0c             	shl    $0xc,%eax
}
  102652:	c9                   	leave  
  102653:	c3                   	ret    

00102654 <pa2page>:

static inline struct Page *
pa2page(uintptr_t pa) {
  102654:	55                   	push   %ebp
  102655:	89 e5                	mov    %esp,%ebp
  102657:	83 ec 18             	sub    $0x18,%esp
    if (PPN(pa) >= npage) {
  10265a:	8b 45 08             	mov    0x8(%ebp),%eax
  10265d:	c1 e8 0c             	shr    $0xc,%eax
  102660:	89 c2                	mov    %eax,%edx
  102662:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  102667:	39 c2                	cmp    %eax,%edx
  102669:	72 1c                	jb     102687 <pa2page+0x33>
        panic("pa2page called with invalid pa");
  10266b:	c7 44 24 08 90 63 10 	movl   $0x106390,0x8(%esp)
  102672:	00 
  102673:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  10267a:	00 
  10267b:	c7 04 24 af 63 10 00 	movl   $0x1063af,(%esp)
  102682:	e8 62 dd ff ff       	call   1003e9 <__panic>
    }
    return &pages[PPN(pa)];
  102687:	8b 0d 18 af 11 00    	mov    0x11af18,%ecx
  10268d:	8b 45 08             	mov    0x8(%ebp),%eax
  102690:	c1 e8 0c             	shr    $0xc,%eax
  102693:	89 c2                	mov    %eax,%edx
  102695:	89 d0                	mov    %edx,%eax
  102697:	c1 e0 02             	shl    $0x2,%eax
  10269a:	01 d0                	add    %edx,%eax
  10269c:	c1 e0 02             	shl    $0x2,%eax
  10269f:	01 c8                	add    %ecx,%eax
}
  1026a1:	c9                   	leave  
  1026a2:	c3                   	ret    

001026a3 <page2kva>:

static inline void *
page2kva(struct Page *page) {
  1026a3:	55                   	push   %ebp
  1026a4:	89 e5                	mov    %esp,%ebp
  1026a6:	83 ec 28             	sub    $0x28,%esp
    return KADDR(page2pa(page));
  1026a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1026ac:	89 04 24             	mov    %eax,(%esp)
  1026af:	e8 8a ff ff ff       	call   10263e <page2pa>
  1026b4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1026b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1026ba:	c1 e8 0c             	shr    $0xc,%eax
  1026bd:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1026c0:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  1026c5:	39 45 f0             	cmp    %eax,-0x10(%ebp)
  1026c8:	72 23                	jb     1026ed <page2kva+0x4a>
  1026ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1026cd:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1026d1:	c7 44 24 08 c0 63 10 	movl   $0x1063c0,0x8(%esp)
  1026d8:	00 
  1026d9:	c7 44 24 04 61 00 00 	movl   $0x61,0x4(%esp)
  1026e0:	00 
  1026e1:	c7 04 24 af 63 10 00 	movl   $0x1063af,(%esp)
  1026e8:	e8 fc dc ff ff       	call   1003e9 <__panic>
  1026ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1026f0:	2d 00 00 00 40       	sub    $0x40000000,%eax
}
  1026f5:	c9                   	leave  
  1026f6:	c3                   	ret    

001026f7 <pte2page>:
kva2page(void *kva) {
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte) {
  1026f7:	55                   	push   %ebp
  1026f8:	89 e5                	mov    %esp,%ebp
  1026fa:	83 ec 18             	sub    $0x18,%esp
    if (!(pte & PTE_P)) {
  1026fd:	8b 45 08             	mov    0x8(%ebp),%eax
  102700:	83 e0 01             	and    $0x1,%eax
  102703:	85 c0                	test   %eax,%eax
  102705:	75 1c                	jne    102723 <pte2page+0x2c>
        panic("pte2page called with invalid pte");
  102707:	c7 44 24 08 e4 63 10 	movl   $0x1063e4,0x8(%esp)
  10270e:	00 
  10270f:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
  102716:	00 
  102717:	c7 04 24 af 63 10 00 	movl   $0x1063af,(%esp)
  10271e:	e8 c6 dc ff ff       	call   1003e9 <__panic>
    }
    return pa2page(PTE_ADDR(pte));
  102723:	8b 45 08             	mov    0x8(%ebp),%eax
  102726:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10272b:	89 04 24             	mov    %eax,(%esp)
  10272e:	e8 21 ff ff ff       	call   102654 <pa2page>
}
  102733:	c9                   	leave  
  102734:	c3                   	ret    

00102735 <pde2page>:

static inline struct Page *
pde2page(pde_t pde) {
  102735:	55                   	push   %ebp
  102736:	89 e5                	mov    %esp,%ebp
  102738:	83 ec 18             	sub    $0x18,%esp
    return pa2page(PDE_ADDR(pde));
  10273b:	8b 45 08             	mov    0x8(%ebp),%eax
  10273e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102743:	89 04 24             	mov    %eax,(%esp)
  102746:	e8 09 ff ff ff       	call   102654 <pa2page>
}
  10274b:	c9                   	leave  
  10274c:	c3                   	ret    

0010274d <page_ref>:

static inline int
page_ref(struct Page *page) {
  10274d:	55                   	push   %ebp
  10274e:	89 e5                	mov    %esp,%ebp
    return page->ref;
  102750:	8b 45 08             	mov    0x8(%ebp),%eax
  102753:	8b 00                	mov    (%eax),%eax
}
  102755:	5d                   	pop    %ebp
  102756:	c3                   	ret    

00102757 <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
  102757:	55                   	push   %ebp
  102758:	89 e5                	mov    %esp,%ebp
    page->ref = val;
  10275a:	8b 45 08             	mov    0x8(%ebp),%eax
  10275d:	8b 55 0c             	mov    0xc(%ebp),%edx
  102760:	89 10                	mov    %edx,(%eax)
}
  102762:	90                   	nop
  102763:	5d                   	pop    %ebp
  102764:	c3                   	ret    

00102765 <page_ref_inc>:

static inline int
page_ref_inc(struct Page *page) {
  102765:	55                   	push   %ebp
  102766:	89 e5                	mov    %esp,%ebp
    page->ref += 1;
  102768:	8b 45 08             	mov    0x8(%ebp),%eax
  10276b:	8b 00                	mov    (%eax),%eax
  10276d:	8d 50 01             	lea    0x1(%eax),%edx
  102770:	8b 45 08             	mov    0x8(%ebp),%eax
  102773:	89 10                	mov    %edx,(%eax)
    return page->ref;
  102775:	8b 45 08             	mov    0x8(%ebp),%eax
  102778:	8b 00                	mov    (%eax),%eax
}
  10277a:	5d                   	pop    %ebp
  10277b:	c3                   	ret    

0010277c <page_ref_dec>:

static inline int
page_ref_dec(struct Page *page) {
  10277c:	55                   	push   %ebp
  10277d:	89 e5                	mov    %esp,%ebp
    page->ref -= 1;
  10277f:	8b 45 08             	mov    0x8(%ebp),%eax
  102782:	8b 00                	mov    (%eax),%eax
  102784:	8d 50 ff             	lea    -0x1(%eax),%edx
  102787:	8b 45 08             	mov    0x8(%ebp),%eax
  10278a:	89 10                	mov    %edx,(%eax)
    return page->ref;
  10278c:	8b 45 08             	mov    0x8(%ebp),%eax
  10278f:	8b 00                	mov    (%eax),%eax
}
  102791:	5d                   	pop    %ebp
  102792:	c3                   	ret    

00102793 <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
  102793:	55                   	push   %ebp
  102794:	89 e5                	mov    %esp,%ebp
  102796:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
  102799:	9c                   	pushf  
  10279a:	58                   	pop    %eax
  10279b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
  10279e:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
  1027a1:	25 00 02 00 00       	and    $0x200,%eax
  1027a6:	85 c0                	test   %eax,%eax
  1027a8:	74 0c                	je     1027b6 <__intr_save+0x23>
        intr_disable();
  1027aa:	e8 14 f0 ff ff       	call   1017c3 <intr_disable>
        return 1;
  1027af:	b8 01 00 00 00       	mov    $0x1,%eax
  1027b4:	eb 05                	jmp    1027bb <__intr_save+0x28>
    }
    return 0;
  1027b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1027bb:	c9                   	leave  
  1027bc:	c3                   	ret    

001027bd <__intr_restore>:

static inline void
__intr_restore(bool flag) {
  1027bd:	55                   	push   %ebp
  1027be:	89 e5                	mov    %esp,%ebp
  1027c0:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
  1027c3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  1027c7:	74 05                	je     1027ce <__intr_restore+0x11>
        intr_enable();
  1027c9:	e8 ee ef ff ff       	call   1017bc <intr_enable>
    }
}
  1027ce:	90                   	nop
  1027cf:	c9                   	leave  
  1027d0:	c3                   	ret    

001027d1 <lgdt>:
/* *
 * lgdt - load the global descriptor table register and reset the
 * data/code segement registers for kernel.
 * */
static inline void
lgdt(struct pseudodesc *pd) {
  1027d1:	55                   	push   %ebp
  1027d2:	89 e5                	mov    %esp,%ebp
    asm volatile ("lgdt (%0)" :: "r" (pd));
  1027d4:	8b 45 08             	mov    0x8(%ebp),%eax
  1027d7:	0f 01 10             	lgdtl  (%eax)
    asm volatile ("movw %%ax, %%gs" :: "a" (USER_DS));
  1027da:	b8 23 00 00 00       	mov    $0x23,%eax
  1027df:	8e e8                	mov    %eax,%gs
    asm volatile ("movw %%ax, %%fs" :: "a" (USER_DS));
  1027e1:	b8 23 00 00 00       	mov    $0x23,%eax
  1027e6:	8e e0                	mov    %eax,%fs
    asm volatile ("movw %%ax, %%es" :: "a" (KERNEL_DS));
  1027e8:	b8 10 00 00 00       	mov    $0x10,%eax
  1027ed:	8e c0                	mov    %eax,%es
    asm volatile ("movw %%ax, %%ds" :: "a" (KERNEL_DS));
  1027ef:	b8 10 00 00 00       	mov    $0x10,%eax
  1027f4:	8e d8                	mov    %eax,%ds
    asm volatile ("movw %%ax, %%ss" :: "a" (KERNEL_DS));
  1027f6:	b8 10 00 00 00       	mov    $0x10,%eax
  1027fb:	8e d0                	mov    %eax,%ss
    // reload cs
    asm volatile ("ljmp %0, $1f\n 1:\n" :: "i" (KERNEL_CS));
  1027fd:	ea 04 28 10 00 08 00 	ljmp   $0x8,$0x102804
}
  102804:	90                   	nop
  102805:	5d                   	pop    %ebp
  102806:	c3                   	ret    

00102807 <load_esp0>:
 * load_esp0 - change the ESP0 in default task state segment,
 * so that we can use different kernel stack when we trap frame
 * user to kernel.
 * */
void
load_esp0(uintptr_t esp0) {
  102807:	55                   	push   %ebp
  102808:	89 e5                	mov    %esp,%ebp
    ts.ts_esp0 = esp0;
  10280a:	8b 45 08             	mov    0x8(%ebp),%eax
  10280d:	a3 a4 ae 11 00       	mov    %eax,0x11aea4
}
  102812:	90                   	nop
  102813:	5d                   	pop    %ebp
  102814:	c3                   	ret    

00102815 <gdt_init>:

/* gdt_init - initialize the default GDT and TSS */
static void
gdt_init(void) {
  102815:	55                   	push   %ebp
  102816:	89 e5                	mov    %esp,%ebp
  102818:	83 ec 14             	sub    $0x14,%esp
    // set boot kernel stack and default SS0
    load_esp0((uintptr_t)bootstacktop);
  10281b:	b8 00 70 11 00       	mov    $0x117000,%eax
  102820:	89 04 24             	mov    %eax,(%esp)
  102823:	e8 df ff ff ff       	call   102807 <load_esp0>
    ts.ts_ss0 = KERNEL_DS;
  102828:	66 c7 05 a8 ae 11 00 	movw   $0x10,0x11aea8
  10282f:	10 00 

    // initialize the TSS filed of the gdt
    gdt[SEG_TSS] = SEGTSS(STS_T32A, (uintptr_t)&ts, sizeof(ts), DPL_KERNEL);
  102831:	66 c7 05 28 7a 11 00 	movw   $0x68,0x117a28
  102838:	68 00 
  10283a:	b8 a0 ae 11 00       	mov    $0x11aea0,%eax
  10283f:	0f b7 c0             	movzwl %ax,%eax
  102842:	66 a3 2a 7a 11 00    	mov    %ax,0x117a2a
  102848:	b8 a0 ae 11 00       	mov    $0x11aea0,%eax
  10284d:	c1 e8 10             	shr    $0x10,%eax
  102850:	a2 2c 7a 11 00       	mov    %al,0x117a2c
  102855:	0f b6 05 2d 7a 11 00 	movzbl 0x117a2d,%eax
  10285c:	24 f0                	and    $0xf0,%al
  10285e:	0c 09                	or     $0x9,%al
  102860:	a2 2d 7a 11 00       	mov    %al,0x117a2d
  102865:	0f b6 05 2d 7a 11 00 	movzbl 0x117a2d,%eax
  10286c:	24 ef                	and    $0xef,%al
  10286e:	a2 2d 7a 11 00       	mov    %al,0x117a2d
  102873:	0f b6 05 2d 7a 11 00 	movzbl 0x117a2d,%eax
  10287a:	24 9f                	and    $0x9f,%al
  10287c:	a2 2d 7a 11 00       	mov    %al,0x117a2d
  102881:	0f b6 05 2d 7a 11 00 	movzbl 0x117a2d,%eax
  102888:	0c 80                	or     $0x80,%al
  10288a:	a2 2d 7a 11 00       	mov    %al,0x117a2d
  10288f:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  102896:	24 f0                	and    $0xf0,%al
  102898:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  10289d:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  1028a4:	24 ef                	and    $0xef,%al
  1028a6:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  1028ab:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  1028b2:	24 df                	and    $0xdf,%al
  1028b4:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  1028b9:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  1028c0:	0c 40                	or     $0x40,%al
  1028c2:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  1028c7:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  1028ce:	24 7f                	and    $0x7f,%al
  1028d0:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  1028d5:	b8 a0 ae 11 00       	mov    $0x11aea0,%eax
  1028da:	c1 e8 18             	shr    $0x18,%eax
  1028dd:	a2 2f 7a 11 00       	mov    %al,0x117a2f

    // reload all segment registers
    lgdt(&gdt_pd);
  1028e2:	c7 04 24 30 7a 11 00 	movl   $0x117a30,(%esp)
  1028e9:	e8 e3 fe ff ff       	call   1027d1 <lgdt>
  1028ee:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
    asm volatile ("cli" ::: "memory");
}

static inline void
ltr(uint16_t sel) {
    asm volatile ("ltr %0" :: "r" (sel) : "memory");
  1028f4:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
  1028f8:	0f 00 d8             	ltr    %ax

    // load the TSS
    ltr(GD_TSS);
}
  1028fb:	90                   	nop
  1028fc:	c9                   	leave  
  1028fd:	c3                   	ret    

001028fe <init_pmm_manager>:

//init_pmm_manager - initialize a pmm_manager instance
static void
init_pmm_manager(void) {
  1028fe:	55                   	push   %ebp
  1028ff:	89 e5                	mov    %esp,%ebp
  102901:	83 ec 18             	sub    $0x18,%esp
    pmm_manager = &default_pmm_manager;
  102904:	c7 05 10 af 11 00 a0 	movl   $0x106da0,0x11af10
  10290b:	6d 10 00 
    cprintf("memory management: %s\n", pmm_manager->name);
  10290e:	a1 10 af 11 00       	mov    0x11af10,%eax
  102913:	8b 00                	mov    (%eax),%eax
  102915:	89 44 24 04          	mov    %eax,0x4(%esp)
  102919:	c7 04 24 10 64 10 00 	movl   $0x106410,(%esp)
  102920:	e8 6d d9 ff ff       	call   100292 <cprintf>
    pmm_manager->init();
  102925:	a1 10 af 11 00       	mov    0x11af10,%eax
  10292a:	8b 40 04             	mov    0x4(%eax),%eax
  10292d:	ff d0                	call   *%eax
}
  10292f:	90                   	nop
  102930:	c9                   	leave  
  102931:	c3                   	ret    

00102932 <init_memmap>:

//init_memmap - call pmm->init_memmap to build Page struct for free memory  
static void
init_memmap(struct Page *base, size_t n) {
  102932:	55                   	push   %ebp
  102933:	89 e5                	mov    %esp,%ebp
  102935:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->init_memmap(base, n);
  102938:	a1 10 af 11 00       	mov    0x11af10,%eax
  10293d:	8b 40 08             	mov    0x8(%eax),%eax
  102940:	8b 55 0c             	mov    0xc(%ebp),%edx
  102943:	89 54 24 04          	mov    %edx,0x4(%esp)
  102947:	8b 55 08             	mov    0x8(%ebp),%edx
  10294a:	89 14 24             	mov    %edx,(%esp)
  10294d:	ff d0                	call   *%eax
}
  10294f:	90                   	nop
  102950:	c9                   	leave  
  102951:	c3                   	ret    

00102952 <alloc_pages>:

//alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory 
struct Page *
alloc_pages(size_t n) {
  102952:	55                   	push   %ebp
  102953:	89 e5                	mov    %esp,%ebp
  102955:	83 ec 28             	sub    $0x28,%esp
    struct Page *page=NULL;
  102958:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
  10295f:	e8 2f fe ff ff       	call   102793 <__intr_save>
  102964:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        page = pmm_manager->alloc_pages(n);
  102967:	a1 10 af 11 00       	mov    0x11af10,%eax
  10296c:	8b 40 0c             	mov    0xc(%eax),%eax
  10296f:	8b 55 08             	mov    0x8(%ebp),%edx
  102972:	89 14 24             	mov    %edx,(%esp)
  102975:	ff d0                	call   *%eax
  102977:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }
    local_intr_restore(intr_flag);
  10297a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10297d:	89 04 24             	mov    %eax,(%esp)
  102980:	e8 38 fe ff ff       	call   1027bd <__intr_restore>
    return page;
  102985:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  102988:	c9                   	leave  
  102989:	c3                   	ret    

0010298a <free_pages>:

//free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory 
void
free_pages(struct Page *base, size_t n) {
  10298a:	55                   	push   %ebp
  10298b:	89 e5                	mov    %esp,%ebp
  10298d:	83 ec 28             	sub    $0x28,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
  102990:	e8 fe fd ff ff       	call   102793 <__intr_save>
  102995:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        pmm_manager->free_pages(base, n);
  102998:	a1 10 af 11 00       	mov    0x11af10,%eax
  10299d:	8b 40 10             	mov    0x10(%eax),%eax
  1029a0:	8b 55 0c             	mov    0xc(%ebp),%edx
  1029a3:	89 54 24 04          	mov    %edx,0x4(%esp)
  1029a7:	8b 55 08             	mov    0x8(%ebp),%edx
  1029aa:	89 14 24             	mov    %edx,(%esp)
  1029ad:	ff d0                	call   *%eax
    }
    local_intr_restore(intr_flag);
  1029af:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1029b2:	89 04 24             	mov    %eax,(%esp)
  1029b5:	e8 03 fe ff ff       	call   1027bd <__intr_restore>
}
  1029ba:	90                   	nop
  1029bb:	c9                   	leave  
  1029bc:	c3                   	ret    

001029bd <nr_free_pages>:

//nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE) 
//of current free memory
size_t
nr_free_pages(void) {
  1029bd:	55                   	push   %ebp
  1029be:	89 e5                	mov    %esp,%ebp
  1029c0:	83 ec 28             	sub    $0x28,%esp
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
  1029c3:	e8 cb fd ff ff       	call   102793 <__intr_save>
  1029c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        ret = pmm_manager->nr_free_pages();
  1029cb:	a1 10 af 11 00       	mov    0x11af10,%eax
  1029d0:	8b 40 14             	mov    0x14(%eax),%eax
  1029d3:	ff d0                	call   *%eax
  1029d5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    }
    local_intr_restore(intr_flag);
  1029d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1029db:	89 04 24             	mov    %eax,(%esp)
  1029de:	e8 da fd ff ff       	call   1027bd <__intr_restore>
    return ret;
  1029e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1029e6:	c9                   	leave  
  1029e7:	c3                   	ret    

001029e8 <page_init>:

/* pmm_init - initialize the physical memory management */
static void
page_init(void) {
  1029e8:	55                   	push   %ebp
  1029e9:	89 e5                	mov    %esp,%ebp
  1029eb:	57                   	push   %edi
  1029ec:	56                   	push   %esi
  1029ed:	53                   	push   %ebx
  1029ee:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
  1029f4:	c7 45 c4 00 80 00 c0 	movl   $0xc0008000,-0x3c(%ebp)
    uint64_t maxpa = 0;
  1029fb:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  102a02:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

    cprintf("e820map:\n");
  102a09:	c7 04 24 27 64 10 00 	movl   $0x106427,(%esp)
  102a10:	e8 7d d8 ff ff       	call   100292 <cprintf>
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
  102a15:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  102a1c:	e9 22 01 00 00       	jmp    102b43 <page_init+0x15b>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
  102a21:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102a24:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102a27:	89 d0                	mov    %edx,%eax
  102a29:	c1 e0 02             	shl    $0x2,%eax
  102a2c:	01 d0                	add    %edx,%eax
  102a2e:	c1 e0 02             	shl    $0x2,%eax
  102a31:	01 c8                	add    %ecx,%eax
  102a33:	8b 50 08             	mov    0x8(%eax),%edx
  102a36:	8b 40 04             	mov    0x4(%eax),%eax
  102a39:	89 45 b8             	mov    %eax,-0x48(%ebp)
  102a3c:	89 55 bc             	mov    %edx,-0x44(%ebp)
  102a3f:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102a42:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102a45:	89 d0                	mov    %edx,%eax
  102a47:	c1 e0 02             	shl    $0x2,%eax
  102a4a:	01 d0                	add    %edx,%eax
  102a4c:	c1 e0 02             	shl    $0x2,%eax
  102a4f:	01 c8                	add    %ecx,%eax
  102a51:	8b 48 0c             	mov    0xc(%eax),%ecx
  102a54:	8b 58 10             	mov    0x10(%eax),%ebx
  102a57:	8b 45 b8             	mov    -0x48(%ebp),%eax
  102a5a:	8b 55 bc             	mov    -0x44(%ebp),%edx
  102a5d:	01 c8                	add    %ecx,%eax
  102a5f:	11 da                	adc    %ebx,%edx
  102a61:	89 45 b0             	mov    %eax,-0x50(%ebp)
  102a64:	89 55 b4             	mov    %edx,-0x4c(%ebp)
        cprintf("  memory: %08llx, [%08llx, %08llx], type = %d.\n",
  102a67:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102a6a:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102a6d:	89 d0                	mov    %edx,%eax
  102a6f:	c1 e0 02             	shl    $0x2,%eax
  102a72:	01 d0                	add    %edx,%eax
  102a74:	c1 e0 02             	shl    $0x2,%eax
  102a77:	01 c8                	add    %ecx,%eax
  102a79:	83 c0 14             	add    $0x14,%eax
  102a7c:	8b 00                	mov    (%eax),%eax
  102a7e:	89 45 84             	mov    %eax,-0x7c(%ebp)
  102a81:	8b 45 b0             	mov    -0x50(%ebp),%eax
  102a84:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  102a87:	83 c0 ff             	add    $0xffffffff,%eax
  102a8a:	83 d2 ff             	adc    $0xffffffff,%edx
  102a8d:	89 85 78 ff ff ff    	mov    %eax,-0x88(%ebp)
  102a93:	89 95 7c ff ff ff    	mov    %edx,-0x84(%ebp)
  102a99:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102a9c:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102a9f:	89 d0                	mov    %edx,%eax
  102aa1:	c1 e0 02             	shl    $0x2,%eax
  102aa4:	01 d0                	add    %edx,%eax
  102aa6:	c1 e0 02             	shl    $0x2,%eax
  102aa9:	01 c8                	add    %ecx,%eax
  102aab:	8b 48 0c             	mov    0xc(%eax),%ecx
  102aae:	8b 58 10             	mov    0x10(%eax),%ebx
  102ab1:	8b 55 84             	mov    -0x7c(%ebp),%edx
  102ab4:	89 54 24 1c          	mov    %edx,0x1c(%esp)
  102ab8:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  102abe:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  102ac4:	89 44 24 14          	mov    %eax,0x14(%esp)
  102ac8:	89 54 24 18          	mov    %edx,0x18(%esp)
  102acc:	8b 45 b8             	mov    -0x48(%ebp),%eax
  102acf:	8b 55 bc             	mov    -0x44(%ebp),%edx
  102ad2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  102ad6:	89 54 24 10          	mov    %edx,0x10(%esp)
  102ada:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  102ade:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  102ae2:	c7 04 24 34 64 10 00 	movl   $0x106434,(%esp)
  102ae9:	e8 a4 d7 ff ff       	call   100292 <cprintf>
                memmap->map[i].size, begin, end - 1, memmap->map[i].type);
        if (memmap->map[i].type == E820_ARM) {
  102aee:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102af1:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102af4:	89 d0                	mov    %edx,%eax
  102af6:	c1 e0 02             	shl    $0x2,%eax
  102af9:	01 d0                	add    %edx,%eax
  102afb:	c1 e0 02             	shl    $0x2,%eax
  102afe:	01 c8                	add    %ecx,%eax
  102b00:	83 c0 14             	add    $0x14,%eax
  102b03:	8b 00                	mov    (%eax),%eax
  102b05:	83 f8 01             	cmp    $0x1,%eax
  102b08:	75 36                	jne    102b40 <page_init+0x158>
            if (maxpa < end && begin < KMEMSIZE) {
  102b0a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102b0d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  102b10:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
  102b13:	77 2b                	ja     102b40 <page_init+0x158>
  102b15:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
  102b18:	72 05                	jb     102b1f <page_init+0x137>
  102b1a:	3b 45 b0             	cmp    -0x50(%ebp),%eax
  102b1d:	73 21                	jae    102b40 <page_init+0x158>
  102b1f:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
  102b23:	77 1b                	ja     102b40 <page_init+0x158>
  102b25:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
  102b29:	72 09                	jb     102b34 <page_init+0x14c>
  102b2b:	81 7d b8 ff ff ff 37 	cmpl   $0x37ffffff,-0x48(%ebp)
  102b32:	77 0c                	ja     102b40 <page_init+0x158>
                maxpa = end;
  102b34:	8b 45 b0             	mov    -0x50(%ebp),%eax
  102b37:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  102b3a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  102b3d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
    uint64_t maxpa = 0;

    cprintf("e820map:\n");
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
  102b40:	ff 45 dc             	incl   -0x24(%ebp)
  102b43:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  102b46:	8b 00                	mov    (%eax),%eax
  102b48:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  102b4b:	0f 8f d0 fe ff ff    	jg     102a21 <page_init+0x39>
            if (maxpa < end && begin < KMEMSIZE) {
                maxpa = end;
            }
        }
    }
    if (maxpa > KMEMSIZE) {
  102b51:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  102b55:	72 1d                	jb     102b74 <page_init+0x18c>
  102b57:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  102b5b:	77 09                	ja     102b66 <page_init+0x17e>
  102b5d:	81 7d e0 00 00 00 38 	cmpl   $0x38000000,-0x20(%ebp)
  102b64:	76 0e                	jbe    102b74 <page_init+0x18c>
        maxpa = KMEMSIZE;
  102b66:	c7 45 e0 00 00 00 38 	movl   $0x38000000,-0x20(%ebp)
  102b6d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    }

    extern char end[];

    npage = maxpa / PGSIZE;
  102b74:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102b77:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  102b7a:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
  102b7e:	c1 ea 0c             	shr    $0xc,%edx
  102b81:	a3 80 ae 11 00       	mov    %eax,0x11ae80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
  102b86:	c7 45 ac 00 10 00 00 	movl   $0x1000,-0x54(%ebp)
  102b8d:	b8 28 af 11 00       	mov    $0x11af28,%eax
  102b92:	8d 50 ff             	lea    -0x1(%eax),%edx
  102b95:	8b 45 ac             	mov    -0x54(%ebp),%eax
  102b98:	01 d0                	add    %edx,%eax
  102b9a:	89 45 a8             	mov    %eax,-0x58(%ebp)
  102b9d:	8b 45 a8             	mov    -0x58(%ebp),%eax
  102ba0:	ba 00 00 00 00       	mov    $0x0,%edx
  102ba5:	f7 75 ac             	divl   -0x54(%ebp)
  102ba8:	8b 45 a8             	mov    -0x58(%ebp),%eax
  102bab:	29 d0                	sub    %edx,%eax
  102bad:	a3 18 af 11 00       	mov    %eax,0x11af18

    for (i = 0; i < npage; i ++) {
  102bb2:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  102bb9:	eb 2e                	jmp    102be9 <page_init+0x201>
        SetPageReserved(pages + i);
  102bbb:	8b 0d 18 af 11 00    	mov    0x11af18,%ecx
  102bc1:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102bc4:	89 d0                	mov    %edx,%eax
  102bc6:	c1 e0 02             	shl    $0x2,%eax
  102bc9:	01 d0                	add    %edx,%eax
  102bcb:	c1 e0 02             	shl    $0x2,%eax
  102bce:	01 c8                	add    %ecx,%eax
  102bd0:	83 c0 04             	add    $0x4,%eax
  102bd3:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  102bda:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  102bdd:	8b 45 8c             	mov    -0x74(%ebp),%eax
  102be0:	8b 55 90             	mov    -0x70(%ebp),%edx
  102be3:	0f ab 10             	bts    %edx,(%eax)
    extern char end[];

    npage = maxpa / PGSIZE;
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    for (i = 0; i < npage; i ++) {
  102be6:	ff 45 dc             	incl   -0x24(%ebp)
  102be9:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102bec:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  102bf1:	39 c2                	cmp    %eax,%edx
  102bf3:	72 c6                	jb     102bbb <page_init+0x1d3>
        SetPageReserved(pages + i);
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);
  102bf5:	8b 15 80 ae 11 00    	mov    0x11ae80,%edx
  102bfb:	89 d0                	mov    %edx,%eax
  102bfd:	c1 e0 02             	shl    $0x2,%eax
  102c00:	01 d0                	add    %edx,%eax
  102c02:	c1 e0 02             	shl    $0x2,%eax
  102c05:	89 c2                	mov    %eax,%edx
  102c07:	a1 18 af 11 00       	mov    0x11af18,%eax
  102c0c:	01 d0                	add    %edx,%eax
  102c0e:	89 45 a4             	mov    %eax,-0x5c(%ebp)
  102c11:	81 7d a4 ff ff ff bf 	cmpl   $0xbfffffff,-0x5c(%ebp)
  102c18:	77 23                	ja     102c3d <page_init+0x255>
  102c1a:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  102c1d:	89 44 24 0c          	mov    %eax,0xc(%esp)
  102c21:	c7 44 24 08 64 64 10 	movl   $0x106464,0x8(%esp)
  102c28:	00 
  102c29:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  102c30:	00 
  102c31:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  102c38:	e8 ac d7 ff ff       	call   1003e9 <__panic>
  102c3d:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  102c40:	05 00 00 00 40       	add    $0x40000000,%eax
  102c45:	89 45 a0             	mov    %eax,-0x60(%ebp)

    for (i = 0; i < memmap->nr_map; i ++) {
  102c48:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  102c4f:	e9 61 01 00 00       	jmp    102db5 <page_init+0x3cd>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
  102c54:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102c57:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102c5a:	89 d0                	mov    %edx,%eax
  102c5c:	c1 e0 02             	shl    $0x2,%eax
  102c5f:	01 d0                	add    %edx,%eax
  102c61:	c1 e0 02             	shl    $0x2,%eax
  102c64:	01 c8                	add    %ecx,%eax
  102c66:	8b 50 08             	mov    0x8(%eax),%edx
  102c69:	8b 40 04             	mov    0x4(%eax),%eax
  102c6c:	89 45 d0             	mov    %eax,-0x30(%ebp)
  102c6f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  102c72:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102c75:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102c78:	89 d0                	mov    %edx,%eax
  102c7a:	c1 e0 02             	shl    $0x2,%eax
  102c7d:	01 d0                	add    %edx,%eax
  102c7f:	c1 e0 02             	shl    $0x2,%eax
  102c82:	01 c8                	add    %ecx,%eax
  102c84:	8b 48 0c             	mov    0xc(%eax),%ecx
  102c87:	8b 58 10             	mov    0x10(%eax),%ebx
  102c8a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102c8d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  102c90:	01 c8                	add    %ecx,%eax
  102c92:	11 da                	adc    %ebx,%edx
  102c94:	89 45 c8             	mov    %eax,-0x38(%ebp)
  102c97:	89 55 cc             	mov    %edx,-0x34(%ebp)
        if (memmap->map[i].type == E820_ARM) {
  102c9a:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102c9d:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102ca0:	89 d0                	mov    %edx,%eax
  102ca2:	c1 e0 02             	shl    $0x2,%eax
  102ca5:	01 d0                	add    %edx,%eax
  102ca7:	c1 e0 02             	shl    $0x2,%eax
  102caa:	01 c8                	add    %ecx,%eax
  102cac:	83 c0 14             	add    $0x14,%eax
  102caf:	8b 00                	mov    (%eax),%eax
  102cb1:	83 f8 01             	cmp    $0x1,%eax
  102cb4:	0f 85 f8 00 00 00    	jne    102db2 <page_init+0x3ca>
            if (begin < freemem) {
  102cba:	8b 45 a0             	mov    -0x60(%ebp),%eax
  102cbd:	ba 00 00 00 00       	mov    $0x0,%edx
  102cc2:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  102cc5:	72 17                	jb     102cde <page_init+0x2f6>
  102cc7:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  102cca:	77 05                	ja     102cd1 <page_init+0x2e9>
  102ccc:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102ccf:	76 0d                	jbe    102cde <page_init+0x2f6>
                begin = freemem;
  102cd1:	8b 45 a0             	mov    -0x60(%ebp),%eax
  102cd4:	89 45 d0             	mov    %eax,-0x30(%ebp)
  102cd7:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
            }
            if (end > KMEMSIZE) {
  102cde:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  102ce2:	72 1d                	jb     102d01 <page_init+0x319>
  102ce4:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  102ce8:	77 09                	ja     102cf3 <page_init+0x30b>
  102cea:	81 7d c8 00 00 00 38 	cmpl   $0x38000000,-0x38(%ebp)
  102cf1:	76 0e                	jbe    102d01 <page_init+0x319>
                end = KMEMSIZE;
  102cf3:	c7 45 c8 00 00 00 38 	movl   $0x38000000,-0x38(%ebp)
  102cfa:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
            }
            if (begin < end) {
  102d01:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102d04:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  102d07:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  102d0a:	0f 87 a2 00 00 00    	ja     102db2 <page_init+0x3ca>
  102d10:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  102d13:	72 09                	jb     102d1e <page_init+0x336>
  102d15:	3b 45 c8             	cmp    -0x38(%ebp),%eax
  102d18:	0f 83 94 00 00 00    	jae    102db2 <page_init+0x3ca>
                begin = ROUNDUP(begin, PGSIZE);
  102d1e:	c7 45 9c 00 10 00 00 	movl   $0x1000,-0x64(%ebp)
  102d25:	8b 55 d0             	mov    -0x30(%ebp),%edx
  102d28:	8b 45 9c             	mov    -0x64(%ebp),%eax
  102d2b:	01 d0                	add    %edx,%eax
  102d2d:	48                   	dec    %eax
  102d2e:	89 45 98             	mov    %eax,-0x68(%ebp)
  102d31:	8b 45 98             	mov    -0x68(%ebp),%eax
  102d34:	ba 00 00 00 00       	mov    $0x0,%edx
  102d39:	f7 75 9c             	divl   -0x64(%ebp)
  102d3c:	8b 45 98             	mov    -0x68(%ebp),%eax
  102d3f:	29 d0                	sub    %edx,%eax
  102d41:	ba 00 00 00 00       	mov    $0x0,%edx
  102d46:	89 45 d0             	mov    %eax,-0x30(%ebp)
  102d49:	89 55 d4             	mov    %edx,-0x2c(%ebp)
                end = ROUNDDOWN(end, PGSIZE);
  102d4c:	8b 45 c8             	mov    -0x38(%ebp),%eax
  102d4f:	89 45 94             	mov    %eax,-0x6c(%ebp)
  102d52:	8b 45 94             	mov    -0x6c(%ebp),%eax
  102d55:	ba 00 00 00 00       	mov    $0x0,%edx
  102d5a:	89 c3                	mov    %eax,%ebx
  102d5c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  102d62:	89 de                	mov    %ebx,%esi
  102d64:	89 d0                	mov    %edx,%eax
  102d66:	83 e0 00             	and    $0x0,%eax
  102d69:	89 c7                	mov    %eax,%edi
  102d6b:	89 75 c8             	mov    %esi,-0x38(%ebp)
  102d6e:	89 7d cc             	mov    %edi,-0x34(%ebp)
                if (begin < end) {
  102d71:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102d74:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  102d77:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  102d7a:	77 36                	ja     102db2 <page_init+0x3ca>
  102d7c:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  102d7f:	72 05                	jb     102d86 <page_init+0x39e>
  102d81:	3b 45 c8             	cmp    -0x38(%ebp),%eax
  102d84:	73 2c                	jae    102db2 <page_init+0x3ca>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
  102d86:	8b 45 c8             	mov    -0x38(%ebp),%eax
  102d89:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102d8c:	2b 45 d0             	sub    -0x30(%ebp),%eax
  102d8f:	1b 55 d4             	sbb    -0x2c(%ebp),%edx
  102d92:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
  102d96:	c1 ea 0c             	shr    $0xc,%edx
  102d99:	89 c3                	mov    %eax,%ebx
  102d9b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102d9e:	89 04 24             	mov    %eax,(%esp)
  102da1:	e8 ae f8 ff ff       	call   102654 <pa2page>
  102da6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  102daa:	89 04 24             	mov    %eax,(%esp)
  102dad:	e8 80 fb ff ff       	call   102932 <init_memmap>
        SetPageReserved(pages + i);
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);

    for (i = 0; i < memmap->nr_map; i ++) {
  102db2:	ff 45 dc             	incl   -0x24(%ebp)
  102db5:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  102db8:	8b 00                	mov    (%eax),%eax
  102dba:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  102dbd:	0f 8f 91 fe ff ff    	jg     102c54 <page_init+0x26c>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
                }
            }
        }
    }
}
  102dc3:	90                   	nop
  102dc4:	81 c4 9c 00 00 00    	add    $0x9c,%esp
  102dca:	5b                   	pop    %ebx
  102dcb:	5e                   	pop    %esi
  102dcc:	5f                   	pop    %edi
  102dcd:	5d                   	pop    %ebp
  102dce:	c3                   	ret    

00102dcf <boot_map_segment>:
//  la:   linear address of this memory need to map (after x86 segment map)
//  size: memory size
//  pa:   physical address of this memory
//  perm: permission of this memory  
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
  102dcf:	55                   	push   %ebp
  102dd0:	89 e5                	mov    %esp,%ebp
  102dd2:	83 ec 38             	sub    $0x38,%esp
    assert(PGOFF(la) == PGOFF(pa));
  102dd5:	8b 45 0c             	mov    0xc(%ebp),%eax
  102dd8:	33 45 14             	xor    0x14(%ebp),%eax
  102ddb:	25 ff 0f 00 00       	and    $0xfff,%eax
  102de0:	85 c0                	test   %eax,%eax
  102de2:	74 24                	je     102e08 <boot_map_segment+0x39>
  102de4:	c7 44 24 0c 96 64 10 	movl   $0x106496,0xc(%esp)
  102deb:	00 
  102dec:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  102df3:	00 
  102df4:	c7 44 24 04 06 01 00 	movl   $0x106,0x4(%esp)
  102dfb:	00 
  102dfc:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  102e03:	e8 e1 d5 ff ff       	call   1003e9 <__panic>
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
  102e08:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
  102e0f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102e12:	25 ff 0f 00 00       	and    $0xfff,%eax
  102e17:	89 c2                	mov    %eax,%edx
  102e19:	8b 45 10             	mov    0x10(%ebp),%eax
  102e1c:	01 c2                	add    %eax,%edx
  102e1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e21:	01 d0                	add    %edx,%eax
  102e23:	48                   	dec    %eax
  102e24:	89 45 ec             	mov    %eax,-0x14(%ebp)
  102e27:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102e2a:	ba 00 00 00 00       	mov    $0x0,%edx
  102e2f:	f7 75 f0             	divl   -0x10(%ebp)
  102e32:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102e35:	29 d0                	sub    %edx,%eax
  102e37:	c1 e8 0c             	shr    $0xc,%eax
  102e3a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    la = ROUNDDOWN(la, PGSIZE);
  102e3d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102e40:	89 45 e8             	mov    %eax,-0x18(%ebp)
  102e43:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102e46:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102e4b:	89 45 0c             	mov    %eax,0xc(%ebp)
    pa = ROUNDDOWN(pa, PGSIZE);
  102e4e:	8b 45 14             	mov    0x14(%ebp),%eax
  102e51:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  102e54:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102e57:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102e5c:	89 45 14             	mov    %eax,0x14(%ebp)
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
  102e5f:	eb 68                	jmp    102ec9 <boot_map_segment+0xfa>
        pte_t *ptep = get_pte(pgdir, la, 1);
  102e61:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  102e68:	00 
  102e69:	8b 45 0c             	mov    0xc(%ebp),%eax
  102e6c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e70:	8b 45 08             	mov    0x8(%ebp),%eax
  102e73:	89 04 24             	mov    %eax,(%esp)
  102e76:	e8 81 01 00 00       	call   102ffc <get_pte>
  102e7b:	89 45 e0             	mov    %eax,-0x20(%ebp)
        assert(ptep != NULL);
  102e7e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  102e82:	75 24                	jne    102ea8 <boot_map_segment+0xd9>
  102e84:	c7 44 24 0c c2 64 10 	movl   $0x1064c2,0xc(%esp)
  102e8b:	00 
  102e8c:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  102e93:	00 
  102e94:	c7 44 24 04 0c 01 00 	movl   $0x10c,0x4(%esp)
  102e9b:	00 
  102e9c:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  102ea3:	e8 41 d5 ff ff       	call   1003e9 <__panic>
        *ptep = pa | PTE_P | perm;
  102ea8:	8b 45 14             	mov    0x14(%ebp),%eax
  102eab:	0b 45 18             	or     0x18(%ebp),%eax
  102eae:	83 c8 01             	or     $0x1,%eax
  102eb1:	89 c2                	mov    %eax,%edx
  102eb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102eb6:	89 10                	mov    %edx,(%eax)
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
    assert(PGOFF(la) == PGOFF(pa));
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
  102eb8:	ff 4d f4             	decl   -0xc(%ebp)
  102ebb:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
  102ec2:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  102ec9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102ecd:	75 92                	jne    102e61 <boot_map_segment+0x92>
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pa | PTE_P | perm;
    }
}
  102ecf:	90                   	nop
  102ed0:	c9                   	leave  
  102ed1:	c3                   	ret    

00102ed2 <boot_alloc_page>:

//boot_alloc_page - allocate one page using pmm->alloc_pages(1) 
// return value: the kernel virtual address of this allocated page
//note: this function is used to get the memory for PDT(Page Directory Table)&PT(Page Table)
static void *
boot_alloc_page(void) {
  102ed2:	55                   	push   %ebp
  102ed3:	89 e5                	mov    %esp,%ebp
  102ed5:	83 ec 28             	sub    $0x28,%esp
    struct Page *p = alloc_page();
  102ed8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  102edf:	e8 6e fa ff ff       	call   102952 <alloc_pages>
  102ee4:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (p == NULL) {
  102ee7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102eeb:	75 1c                	jne    102f09 <boot_alloc_page+0x37>
        panic("boot_alloc_page failed.\n");
  102eed:	c7 44 24 08 cf 64 10 	movl   $0x1064cf,0x8(%esp)
  102ef4:	00 
  102ef5:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
  102efc:	00 
  102efd:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  102f04:	e8 e0 d4 ff ff       	call   1003e9 <__panic>
    }
    return page2kva(p);
  102f09:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f0c:	89 04 24             	mov    %eax,(%esp)
  102f0f:	e8 8f f7 ff ff       	call   1026a3 <page2kva>
}
  102f14:	c9                   	leave  
  102f15:	c3                   	ret    

00102f16 <pmm_init>:

//pmm_init - setup a pmm to manage physical memory, build PDT&PT to setup paging mechanism 
//         - check the correctness of pmm & paging mechanism, print PDT&PT
void
pmm_init(void) {
  102f16:	55                   	push   %ebp
  102f17:	89 e5                	mov    %esp,%ebp
  102f19:	83 ec 38             	sub    $0x38,%esp
    // We've already enabled paging
    boot_cr3 = PADDR(boot_pgdir);
  102f1c:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  102f21:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102f24:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
  102f2b:	77 23                	ja     102f50 <pmm_init+0x3a>
  102f2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f30:	89 44 24 0c          	mov    %eax,0xc(%esp)
  102f34:	c7 44 24 08 64 64 10 	movl   $0x106464,0x8(%esp)
  102f3b:	00 
  102f3c:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
  102f43:	00 
  102f44:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  102f4b:	e8 99 d4 ff ff       	call   1003e9 <__panic>
  102f50:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f53:	05 00 00 00 40       	add    $0x40000000,%eax
  102f58:	a3 14 af 11 00       	mov    %eax,0x11af14
    //We need to alloc/free the physical memory (granularity is 4KB or other size). 
    //So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    //First we should init a physical memory manager(pmm) based on the framework.
    //Then pmm can alloc/free the physical memory. 
    //Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();
  102f5d:	e8 9c f9 ff ff       	call   1028fe <init_pmm_manager>

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();
  102f62:	e8 81 fa ff ff       	call   1029e8 <page_init>

    //use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();
  102f67:	e8 56 03 00 00       	call   1032c2 <check_alloc_page>

    check_pgdir();
  102f6c:	e8 70 03 00 00       	call   1032e1 <check_pgdir>

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // recursively insert boot_pgdir in itself
    // to form a virtual page table at virtual address VPT
    boot_pgdir[PDX(VPT)] = PADDR(boot_pgdir) | PTE_P | PTE_W;
  102f71:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  102f76:	8d 90 ac 0f 00 00    	lea    0xfac(%eax),%edx
  102f7c:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  102f81:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102f84:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
  102f8b:	77 23                	ja     102fb0 <pmm_init+0x9a>
  102f8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102f90:	89 44 24 0c          	mov    %eax,0xc(%esp)
  102f94:	c7 44 24 08 64 64 10 	movl   $0x106464,0x8(%esp)
  102f9b:	00 
  102f9c:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
  102fa3:	00 
  102fa4:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  102fab:	e8 39 d4 ff ff       	call   1003e9 <__panic>
  102fb0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102fb3:	05 00 00 00 40       	add    $0x40000000,%eax
  102fb8:	83 c8 03             	or     $0x3,%eax
  102fbb:	89 02                	mov    %eax,(%edx)

    // map all physical memory to linear memory with base linear addr KERNBASE
    // linear_addr KERNBASE ~ KERNBASE + KMEMSIZE = phy_addr 0 ~ KMEMSIZE
    boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, 0, PTE_W);
  102fbd:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  102fc2:	c7 44 24 10 02 00 00 	movl   $0x2,0x10(%esp)
  102fc9:	00 
  102fca:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  102fd1:	00 
  102fd2:	c7 44 24 08 00 00 00 	movl   $0x38000000,0x8(%esp)
  102fd9:	38 
  102fda:	c7 44 24 04 00 00 00 	movl   $0xc0000000,0x4(%esp)
  102fe1:	c0 
  102fe2:	89 04 24             	mov    %eax,(%esp)
  102fe5:	e8 e5 fd ff ff       	call   102dcf <boot_map_segment>

    // Since we are using bootloader's GDT,
    // we should reload gdt (second time, the last time) to get user segments and the TSS
    // map virtual_addr 0 ~ 4G = linear_addr 0 ~ 4G
    // then set kernel stack (ss:esp) in TSS, setup TSS in gdt, load TSS
    gdt_init();
  102fea:	e8 26 f8 ff ff       	call   102815 <gdt_init>

    //now the basic virtual memory map(see memalyout.h) is established.
    //check the correctness of the basic virtual memory map.
    check_boot_pgdir();
  102fef:	e8 89 09 00 00       	call   10397d <check_boot_pgdir>

    print_pgdir();
  102ff4:	e8 02 0e 00 00       	call   103dfb <print_pgdir>

}
  102ff9:	90                   	nop
  102ffa:	c9                   	leave  
  102ffb:	c3                   	ret    

00102ffc <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *
get_pte(pde_t *pgdir, uintptr_t la, bool create) {
  102ffc:	55                   	push   %ebp
  102ffd:	89 e5                	mov    %esp,%ebp
  102fff:	83 ec 38             	sub    $0x38,%esp
                          // (7) set page directory entry's permission
    }
    return NULL;          // (8) return page table entry
#endif
    // Get the page directory entry by adding offset(the index) and the base address of page direcotry table.
    pde_t *entry = pgdir + PDX(la) * sizeof(pde_t);
  103002:	8b 45 0c             	mov    0xc(%ebp),%eax
  103005:	c1 e8 16             	shr    $0x16,%eax
  103008:	c1 e0 04             	shl    $0x4,%eax
  10300b:	89 c2                	mov    %eax,%edx
  10300d:	8b 45 08             	mov    0x8(%ebp),%eax
  103010:	01 d0                	add    %edx,%eax
  103012:	89 45 f4             	mov    %eax,-0xc(%ebp)
    
    if (!(*entry & PTE_P)) {
  103015:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103018:	8b 00                	mov    (%eax),%eax
  10301a:	83 e0 01             	and    $0x1,%eax
  10301d:	85 c0                	test   %eax,%eax
  10301f:	0f 85 b4 00 00 00    	jne    1030d9 <get_pte+0xdd>
        // Not present in the table? We need to allocate the page table.
        struct Page *page = 
            (create ? 
                            alloc_page() : NULL);
  103025:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  103029:	74 0e                	je     103039 <get_pte+0x3d>
  10302b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  103032:	e8 1b f9 ff ff       	call   102952 <alloc_pages>
  103037:	eb 05                	jmp    10303e <get_pte+0x42>
  103039:	b8 00 00 00 00       	mov    $0x0,%eax
    // Get the page directory entry by adding offset(the index) and the base address of page direcotry table.
    pde_t *entry = pgdir + PDX(la) * sizeof(pde_t);
    
    if (!(*entry & PTE_P)) {
        // Not present in the table? We need to allocate the page table.
        struct Page *page = 
  10303e:	89 45 f0             	mov    %eax,-0x10(%ebp)
            (create ? 
                            alloc_page() : NULL);

        if (NULL == page) {
  103041:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  103045:	75 08                	jne    10304f <get_pte+0x53>
            return page;
  103047:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10304a:	e9 b8 00 00 00       	jmp    103107 <get_pte+0x10b>
        }

        // Initialize the page.
        set_page_ref(page, 1);
  10304f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103056:	00 
  103057:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10305a:	89 04 24             	mov    %eax,(%esp)
  10305d:	e8 f5 f6 ff ff       	call   102757 <set_page_ref>
        // Get the physical address for next step.
        // ? uintptr_t seems to be unsigned int...
        uintptr_t page_addr = page2pa(page);
  103062:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103065:	89 04 24             	mov    %eax,(%esp)
  103068:	e8 d1 f5 ff ff       	call   10263e <page2pa>
  10306d:	89 45 ec             	mov    %eax,-0x14(%ebp)
        // Set the page to be empty in the kernel.
        memset(KADDR(page_addr), 0, sizeof(uintptr_t) * (PGSIZE));
  103070:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103073:	89 45 e8             	mov    %eax,-0x18(%ebp)
  103076:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103079:	c1 e8 0c             	shr    $0xc,%eax
  10307c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  10307f:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  103084:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
  103087:	72 23                	jb     1030ac <get_pte+0xb0>
  103089:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10308c:	89 44 24 0c          	mov    %eax,0xc(%esp)
  103090:	c7 44 24 08 c0 63 10 	movl   $0x1063c0,0x8(%esp)
  103097:	00 
  103098:	c7 44 24 04 89 01 00 	movl   $0x189,0x4(%esp)
  10309f:	00 
  1030a0:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  1030a7:	e8 3d d3 ff ff       	call   1003e9 <__panic>
  1030ac:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1030af:	2d 00 00 00 40       	sub    $0x40000000,%eax
  1030b4:	c7 44 24 08 00 40 00 	movl   $0x4000,0x8(%esp)
  1030bb:	00 
  1030bc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1030c3:	00 
  1030c4:	89 04 24             	mov    %eax,(%esp)
  1030c7:	e8 d7 23 00 00       	call   1054a3 <memset>
        *entry = page_addr |
                 PTE_P     |
                 PTE_W     |
  1030cc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1030cf:	83 c8 07             	or     $0x7,%eax
  1030d2:	89 c2                	mov    %eax,%edx
        // Get the physical address for next step.
        // ? uintptr_t seems to be unsigned int...
        uintptr_t page_addr = page2pa(page);
        // Set the page to be empty in the kernel.
        memset(KADDR(page_addr), 0, sizeof(uintptr_t) * (PGSIZE));
        *entry = page_addr |
  1030d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030d7:	89 10                	mov    %edx,(%eax)
                 PTE_P     |
                 PTE_W     |
                 PTE_U     ;
    }

    uintptr_t page_table_index = PTX(la);
  1030d9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1030dc:	c1 e8 0c             	shr    $0xc,%eax
  1030df:	25 ff 03 00 00       	and    $0x3ff,%eax
  1030e4:	89 45 e0             	mov    %eax,-0x20(%ebp)
    // Page directory table's entry is just a pointer to the page table itself.
    uintptr_t page_table_addr = PTE_ADDR(*entry);
  1030e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030ea:	8b 00                	mov    (%eax),%eax
  1030ec:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1030f1:	89 45 dc             	mov    %eax,-0x24(%ebp)

    pte_t *page_table_entry = 
            (pte_t *)(page_table_addr) + page_table_index * sizeof(pte_t);
  1030f4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1030f7:	c1 e0 04             	shl    $0x4,%eax
  1030fa:	89 c2                	mov    %eax,%edx
  1030fc:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1030ff:	01 d0                	add    %edx,%eax

    uintptr_t page_table_index = PTX(la);
    // Page directory table's entry is just a pointer to the page table itself.
    uintptr_t page_table_addr = PTE_ADDR(*entry);

    pte_t *page_table_entry = 
  103101:	89 45 d8             	mov    %eax,-0x28(%ebp)
            (pte_t *)(page_table_addr) + page_table_index * sizeof(pte_t);
    return page_table_entry;
  103104:	8b 45 d8             	mov    -0x28(%ebp),%eax
}
  103107:	c9                   	leave  
  103108:	c3                   	ret    

00103109 <get_page>:

//get_page - get related Page struct for linear address la using PDT pgdir
struct Page *
get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
  103109:	55                   	push   %ebp
  10310a:	89 e5                	mov    %esp,%ebp
  10310c:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
  10310f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103116:	00 
  103117:	8b 45 0c             	mov    0xc(%ebp),%eax
  10311a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10311e:	8b 45 08             	mov    0x8(%ebp),%eax
  103121:	89 04 24             	mov    %eax,(%esp)
  103124:	e8 d3 fe ff ff       	call   102ffc <get_pte>
  103129:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep_store != NULL) {
  10312c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  103130:	74 08                	je     10313a <get_page+0x31>
        *ptep_store = ptep;
  103132:	8b 45 10             	mov    0x10(%ebp),%eax
  103135:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103138:	89 10                	mov    %edx,(%eax)
    }
    if (ptep != NULL && *ptep & PTE_P) {
  10313a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10313e:	74 1b                	je     10315b <get_page+0x52>
  103140:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103143:	8b 00                	mov    (%eax),%eax
  103145:	83 e0 01             	and    $0x1,%eax
  103148:	85 c0                	test   %eax,%eax
  10314a:	74 0f                	je     10315b <get_page+0x52>
        return pte2page(*ptep);
  10314c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10314f:	8b 00                	mov    (%eax),%eax
  103151:	89 04 24             	mov    %eax,(%esp)
  103154:	e8 9e f5 ff ff       	call   1026f7 <pte2page>
  103159:	eb 05                	jmp    103160 <get_page+0x57>
    }
    return NULL;
  10315b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  103160:	c9                   	leave  
  103161:	c3                   	ret    

00103162 <page_remove_pte>:

//page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
//note: PT is changed, so the TLB need to be invalidate 
static inline void
page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
  103162:	55                   	push   %ebp
  103163:	89 e5                	mov    %esp,%ebp
                                  //(4) and free this page when page reference reachs 0
                                  //(5) clear second page table entry
                                  //(6) flush tlb
    }
#endif
}
  103165:	90                   	nop
  103166:	5d                   	pop    %ebp
  103167:	c3                   	ret    

00103168 <page_remove>:

//page_remove - free an Page which is related linear address la and has an validated pte
void
page_remove(pde_t *pgdir, uintptr_t la) {
  103168:	55                   	push   %ebp
  103169:	89 e5                	mov    %esp,%ebp
  10316b:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
  10316e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103175:	00 
  103176:	8b 45 0c             	mov    0xc(%ebp),%eax
  103179:	89 44 24 04          	mov    %eax,0x4(%esp)
  10317d:	8b 45 08             	mov    0x8(%ebp),%eax
  103180:	89 04 24             	mov    %eax,(%esp)
  103183:	e8 74 fe ff ff       	call   102ffc <get_pte>
  103188:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep != NULL) {
  10318b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10318f:	74 19                	je     1031aa <page_remove+0x42>
        page_remove_pte(pgdir, la, ptep);
  103191:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103194:	89 44 24 08          	mov    %eax,0x8(%esp)
  103198:	8b 45 0c             	mov    0xc(%ebp),%eax
  10319b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10319f:	8b 45 08             	mov    0x8(%ebp),%eax
  1031a2:	89 04 24             	mov    %eax,(%esp)
  1031a5:	e8 b8 ff ff ff       	call   103162 <page_remove_pte>
    }
}
  1031aa:	90                   	nop
  1031ab:	c9                   	leave  
  1031ac:	c3                   	ret    

001031ad <page_insert>:
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
//note: PT is changed, so the TLB need to be invalidate 
int
page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
  1031ad:	55                   	push   %ebp
  1031ae:	89 e5                	mov    %esp,%ebp
  1031b0:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 1);
  1031b3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  1031ba:	00 
  1031bb:	8b 45 10             	mov    0x10(%ebp),%eax
  1031be:	89 44 24 04          	mov    %eax,0x4(%esp)
  1031c2:	8b 45 08             	mov    0x8(%ebp),%eax
  1031c5:	89 04 24             	mov    %eax,(%esp)
  1031c8:	e8 2f fe ff ff       	call   102ffc <get_pte>
  1031cd:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep == NULL) {
  1031d0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1031d4:	75 0a                	jne    1031e0 <page_insert+0x33>
        return -E_NO_MEM;
  1031d6:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
  1031db:	e9 84 00 00 00       	jmp    103264 <page_insert+0xb7>
    }
    page_ref_inc(page);
  1031e0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1031e3:	89 04 24             	mov    %eax,(%esp)
  1031e6:	e8 7a f5 ff ff       	call   102765 <page_ref_inc>
    if (*ptep & PTE_P) {
  1031eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1031ee:	8b 00                	mov    (%eax),%eax
  1031f0:	83 e0 01             	and    $0x1,%eax
  1031f3:	85 c0                	test   %eax,%eax
  1031f5:	74 3e                	je     103235 <page_insert+0x88>
        struct Page *p = pte2page(*ptep);
  1031f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1031fa:	8b 00                	mov    (%eax),%eax
  1031fc:	89 04 24             	mov    %eax,(%esp)
  1031ff:	e8 f3 f4 ff ff       	call   1026f7 <pte2page>
  103204:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (p == page) {
  103207:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10320a:	3b 45 0c             	cmp    0xc(%ebp),%eax
  10320d:	75 0d                	jne    10321c <page_insert+0x6f>
            page_ref_dec(page);
  10320f:	8b 45 0c             	mov    0xc(%ebp),%eax
  103212:	89 04 24             	mov    %eax,(%esp)
  103215:	e8 62 f5 ff ff       	call   10277c <page_ref_dec>
  10321a:	eb 19                	jmp    103235 <page_insert+0x88>
        }
        else {
            page_remove_pte(pgdir, la, ptep);
  10321c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10321f:	89 44 24 08          	mov    %eax,0x8(%esp)
  103223:	8b 45 10             	mov    0x10(%ebp),%eax
  103226:	89 44 24 04          	mov    %eax,0x4(%esp)
  10322a:	8b 45 08             	mov    0x8(%ebp),%eax
  10322d:	89 04 24             	mov    %eax,(%esp)
  103230:	e8 2d ff ff ff       	call   103162 <page_remove_pte>
        }
    }
    *ptep = page2pa(page) | PTE_P | perm;
  103235:	8b 45 0c             	mov    0xc(%ebp),%eax
  103238:	89 04 24             	mov    %eax,(%esp)
  10323b:	e8 fe f3 ff ff       	call   10263e <page2pa>
  103240:	0b 45 14             	or     0x14(%ebp),%eax
  103243:	83 c8 01             	or     $0x1,%eax
  103246:	89 c2                	mov    %eax,%edx
  103248:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10324b:	89 10                	mov    %edx,(%eax)
    tlb_invalidate(pgdir, la);
  10324d:	8b 45 10             	mov    0x10(%ebp),%eax
  103250:	89 44 24 04          	mov    %eax,0x4(%esp)
  103254:	8b 45 08             	mov    0x8(%ebp),%eax
  103257:	89 04 24             	mov    %eax,(%esp)
  10325a:	e8 07 00 00 00       	call   103266 <tlb_invalidate>
    return 0;
  10325f:	b8 00 00 00 00       	mov    $0x0,%eax
}
  103264:	c9                   	leave  
  103265:	c3                   	ret    

00103266 <tlb_invalidate>:

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void
tlb_invalidate(pde_t *pgdir, uintptr_t la) {
  103266:	55                   	push   %ebp
  103267:	89 e5                	mov    %esp,%ebp
  103269:	83 ec 28             	sub    $0x28,%esp
}

static inline uintptr_t
rcr3(void) {
    uintptr_t cr3;
    asm volatile ("mov %%cr3, %0" : "=r" (cr3) :: "memory");
  10326c:	0f 20 d8             	mov    %cr3,%eax
  10326f:	89 45 ec             	mov    %eax,-0x14(%ebp)
    return cr3;
  103272:	8b 55 ec             	mov    -0x14(%ebp),%edx
    if (rcr3() == PADDR(pgdir)) {
  103275:	8b 45 08             	mov    0x8(%ebp),%eax
  103278:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10327b:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
  103282:	77 23                	ja     1032a7 <tlb_invalidate+0x41>
  103284:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103287:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10328b:	c7 44 24 08 64 64 10 	movl   $0x106464,0x8(%esp)
  103292:	00 
  103293:	c7 44 24 04 f0 01 00 	movl   $0x1f0,0x4(%esp)
  10329a:	00 
  10329b:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  1032a2:	e8 42 d1 ff ff       	call   1003e9 <__panic>
  1032a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1032aa:	05 00 00 00 40       	add    $0x40000000,%eax
  1032af:	39 c2                	cmp    %eax,%edx
  1032b1:	75 0c                	jne    1032bf <tlb_invalidate+0x59>
        invlpg((void *)la);
  1032b3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1032b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static inline void
invlpg(void *addr) {
    asm volatile ("invlpg (%0)" :: "r" (addr) : "memory");
  1032b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1032bc:	0f 01 38             	invlpg (%eax)
    }
}
  1032bf:	90                   	nop
  1032c0:	c9                   	leave  
  1032c1:	c3                   	ret    

001032c2 <check_alloc_page>:

static void
check_alloc_page(void) {
  1032c2:	55                   	push   %ebp
  1032c3:	89 e5                	mov    %esp,%ebp
  1032c5:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->check();
  1032c8:	a1 10 af 11 00       	mov    0x11af10,%eax
  1032cd:	8b 40 18             	mov    0x18(%eax),%eax
  1032d0:	ff d0                	call   *%eax
    cprintf("check_alloc_page() succeeded!\n");
  1032d2:	c7 04 24 e8 64 10 00 	movl   $0x1064e8,(%esp)
  1032d9:	e8 b4 cf ff ff       	call   100292 <cprintf>
}
  1032de:	90                   	nop
  1032df:	c9                   	leave  
  1032e0:	c3                   	ret    

001032e1 <check_pgdir>:

static void
check_pgdir(void) {
  1032e1:	55                   	push   %ebp
  1032e2:	89 e5                	mov    %esp,%ebp
  1032e4:	83 ec 38             	sub    $0x38,%esp
    assert(npage <= KMEMSIZE / PGSIZE);
  1032e7:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  1032ec:	3d 00 80 03 00       	cmp    $0x38000,%eax
  1032f1:	76 24                	jbe    103317 <check_pgdir+0x36>
  1032f3:	c7 44 24 0c 07 65 10 	movl   $0x106507,0xc(%esp)
  1032fa:	00 
  1032fb:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103302:	00 
  103303:	c7 44 24 04 fd 01 00 	movl   $0x1fd,0x4(%esp)
  10330a:	00 
  10330b:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103312:	e8 d2 d0 ff ff       	call   1003e9 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
  103317:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  10331c:	85 c0                	test   %eax,%eax
  10331e:	74 0e                	je     10332e <check_pgdir+0x4d>
  103320:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103325:	25 ff 0f 00 00       	and    $0xfff,%eax
  10332a:	85 c0                	test   %eax,%eax
  10332c:	74 24                	je     103352 <check_pgdir+0x71>
  10332e:	c7 44 24 0c 24 65 10 	movl   $0x106524,0xc(%esp)
  103335:	00 
  103336:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  10333d:	00 
  10333e:	c7 44 24 04 fe 01 00 	movl   $0x1fe,0x4(%esp)
  103345:	00 
  103346:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  10334d:	e8 97 d0 ff ff       	call   1003e9 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
  103352:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103357:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  10335e:	00 
  10335f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103366:	00 
  103367:	89 04 24             	mov    %eax,(%esp)
  10336a:	e8 9a fd ff ff       	call   103109 <get_page>
  10336f:	85 c0                	test   %eax,%eax
  103371:	74 24                	je     103397 <check_pgdir+0xb6>
  103373:	c7 44 24 0c 5c 65 10 	movl   $0x10655c,0xc(%esp)
  10337a:	00 
  10337b:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103382:	00 
  103383:	c7 44 24 04 ff 01 00 	movl   $0x1ff,0x4(%esp)
  10338a:	00 
  10338b:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103392:	e8 52 d0 ff ff       	call   1003e9 <__panic>

    struct Page *p1, *p2;
    p1 = alloc_page();
  103397:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10339e:	e8 af f5 ff ff       	call   102952 <alloc_pages>
  1033a3:	89 45 f4             	mov    %eax,-0xc(%ebp)
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
  1033a6:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1033ab:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1033b2:	00 
  1033b3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1033ba:	00 
  1033bb:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1033be:	89 54 24 04          	mov    %edx,0x4(%esp)
  1033c2:	89 04 24             	mov    %eax,(%esp)
  1033c5:	e8 e3 fd ff ff       	call   1031ad <page_insert>
  1033ca:	85 c0                	test   %eax,%eax
  1033cc:	74 24                	je     1033f2 <check_pgdir+0x111>
  1033ce:	c7 44 24 0c 84 65 10 	movl   $0x106584,0xc(%esp)
  1033d5:	00 
  1033d6:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  1033dd:	00 
  1033de:	c7 44 24 04 03 02 00 	movl   $0x203,0x4(%esp)
  1033e5:	00 
  1033e6:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  1033ed:	e8 f7 cf ff ff       	call   1003e9 <__panic>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
  1033f2:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1033f7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1033fe:	00 
  1033ff:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103406:	00 
  103407:	89 04 24             	mov    %eax,(%esp)
  10340a:	e8 ed fb ff ff       	call   102ffc <get_pte>
  10340f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103412:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  103416:	75 24                	jne    10343c <check_pgdir+0x15b>
  103418:	c7 44 24 0c b0 65 10 	movl   $0x1065b0,0xc(%esp)
  10341f:	00 
  103420:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103427:	00 
  103428:	c7 44 24 04 06 02 00 	movl   $0x206,0x4(%esp)
  10342f:	00 
  103430:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103437:	e8 ad cf ff ff       	call   1003e9 <__panic>
    assert(pte2page(*ptep) == p1);
  10343c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10343f:	8b 00                	mov    (%eax),%eax
  103441:	89 04 24             	mov    %eax,(%esp)
  103444:	e8 ae f2 ff ff       	call   1026f7 <pte2page>
  103449:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  10344c:	74 24                	je     103472 <check_pgdir+0x191>
  10344e:	c7 44 24 0c dd 65 10 	movl   $0x1065dd,0xc(%esp)
  103455:	00 
  103456:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  10345d:	00 
  10345e:	c7 44 24 04 07 02 00 	movl   $0x207,0x4(%esp)
  103465:	00 
  103466:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  10346d:	e8 77 cf ff ff       	call   1003e9 <__panic>
    assert(page_ref(p1) == 1);
  103472:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103475:	89 04 24             	mov    %eax,(%esp)
  103478:	e8 d0 f2 ff ff       	call   10274d <page_ref>
  10347d:	83 f8 01             	cmp    $0x1,%eax
  103480:	74 24                	je     1034a6 <check_pgdir+0x1c5>
  103482:	c7 44 24 0c f3 65 10 	movl   $0x1065f3,0xc(%esp)
  103489:	00 
  10348a:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103491:	00 
  103492:	c7 44 24 04 08 02 00 	movl   $0x208,0x4(%esp)
  103499:	00 
  10349a:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  1034a1:	e8 43 cf ff ff       	call   1003e9 <__panic>

    ptep = &((pte_t *)KADDR(PDE_ADDR(boot_pgdir[0])))[1];
  1034a6:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1034ab:	8b 00                	mov    (%eax),%eax
  1034ad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1034b2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1034b5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1034b8:	c1 e8 0c             	shr    $0xc,%eax
  1034bb:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1034be:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  1034c3:	39 45 e8             	cmp    %eax,-0x18(%ebp)
  1034c6:	72 23                	jb     1034eb <check_pgdir+0x20a>
  1034c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1034cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1034cf:	c7 44 24 08 c0 63 10 	movl   $0x1063c0,0x8(%esp)
  1034d6:	00 
  1034d7:	c7 44 24 04 0a 02 00 	movl   $0x20a,0x4(%esp)
  1034de:	00 
  1034df:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  1034e6:	e8 fe ce ff ff       	call   1003e9 <__panic>
  1034eb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1034ee:	2d 00 00 00 40       	sub    $0x40000000,%eax
  1034f3:	83 c0 04             	add    $0x4,%eax
  1034f6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
  1034f9:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1034fe:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103505:	00 
  103506:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  10350d:	00 
  10350e:	89 04 24             	mov    %eax,(%esp)
  103511:	e8 e6 fa ff ff       	call   102ffc <get_pte>
  103516:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  103519:	74 24                	je     10353f <check_pgdir+0x25e>
  10351b:	c7 44 24 0c 08 66 10 	movl   $0x106608,0xc(%esp)
  103522:	00 
  103523:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  10352a:	00 
  10352b:	c7 44 24 04 0b 02 00 	movl   $0x20b,0x4(%esp)
  103532:	00 
  103533:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  10353a:	e8 aa ce ff ff       	call   1003e9 <__panic>

    p2 = alloc_page();
  10353f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  103546:	e8 07 f4 ff ff       	call   102952 <alloc_pages>
  10354b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
  10354e:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103553:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  10355a:	00 
  10355b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  103562:	00 
  103563:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103566:	89 54 24 04          	mov    %edx,0x4(%esp)
  10356a:	89 04 24             	mov    %eax,(%esp)
  10356d:	e8 3b fc ff ff       	call   1031ad <page_insert>
  103572:	85 c0                	test   %eax,%eax
  103574:	74 24                	je     10359a <check_pgdir+0x2b9>
  103576:	c7 44 24 0c 30 66 10 	movl   $0x106630,0xc(%esp)
  10357d:	00 
  10357e:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103585:	00 
  103586:	c7 44 24 04 0e 02 00 	movl   $0x20e,0x4(%esp)
  10358d:	00 
  10358e:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103595:	e8 4f ce ff ff       	call   1003e9 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
  10359a:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  10359f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1035a6:	00 
  1035a7:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  1035ae:	00 
  1035af:	89 04 24             	mov    %eax,(%esp)
  1035b2:	e8 45 fa ff ff       	call   102ffc <get_pte>
  1035b7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1035ba:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1035be:	75 24                	jne    1035e4 <check_pgdir+0x303>
  1035c0:	c7 44 24 0c 68 66 10 	movl   $0x106668,0xc(%esp)
  1035c7:	00 
  1035c8:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  1035cf:	00 
  1035d0:	c7 44 24 04 0f 02 00 	movl   $0x20f,0x4(%esp)
  1035d7:	00 
  1035d8:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  1035df:	e8 05 ce ff ff       	call   1003e9 <__panic>
    assert(*ptep & PTE_U);
  1035e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1035e7:	8b 00                	mov    (%eax),%eax
  1035e9:	83 e0 04             	and    $0x4,%eax
  1035ec:	85 c0                	test   %eax,%eax
  1035ee:	75 24                	jne    103614 <check_pgdir+0x333>
  1035f0:	c7 44 24 0c 98 66 10 	movl   $0x106698,0xc(%esp)
  1035f7:	00 
  1035f8:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  1035ff:	00 
  103600:	c7 44 24 04 10 02 00 	movl   $0x210,0x4(%esp)
  103607:	00 
  103608:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  10360f:	e8 d5 cd ff ff       	call   1003e9 <__panic>
    assert(*ptep & PTE_W);
  103614:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103617:	8b 00                	mov    (%eax),%eax
  103619:	83 e0 02             	and    $0x2,%eax
  10361c:	85 c0                	test   %eax,%eax
  10361e:	75 24                	jne    103644 <check_pgdir+0x363>
  103620:	c7 44 24 0c a6 66 10 	movl   $0x1066a6,0xc(%esp)
  103627:	00 
  103628:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  10362f:	00 
  103630:	c7 44 24 04 11 02 00 	movl   $0x211,0x4(%esp)
  103637:	00 
  103638:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  10363f:	e8 a5 cd ff ff       	call   1003e9 <__panic>
    assert(boot_pgdir[0] & PTE_U);
  103644:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103649:	8b 00                	mov    (%eax),%eax
  10364b:	83 e0 04             	and    $0x4,%eax
  10364e:	85 c0                	test   %eax,%eax
  103650:	75 24                	jne    103676 <check_pgdir+0x395>
  103652:	c7 44 24 0c b4 66 10 	movl   $0x1066b4,0xc(%esp)
  103659:	00 
  10365a:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103661:	00 
  103662:	c7 44 24 04 12 02 00 	movl   $0x212,0x4(%esp)
  103669:	00 
  10366a:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103671:	e8 73 cd ff ff       	call   1003e9 <__panic>
    assert(page_ref(p2) == 1);
  103676:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103679:	89 04 24             	mov    %eax,(%esp)
  10367c:	e8 cc f0 ff ff       	call   10274d <page_ref>
  103681:	83 f8 01             	cmp    $0x1,%eax
  103684:	74 24                	je     1036aa <check_pgdir+0x3c9>
  103686:	c7 44 24 0c ca 66 10 	movl   $0x1066ca,0xc(%esp)
  10368d:	00 
  10368e:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103695:	00 
  103696:	c7 44 24 04 13 02 00 	movl   $0x213,0x4(%esp)
  10369d:	00 
  10369e:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  1036a5:	e8 3f cd ff ff       	call   1003e9 <__panic>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
  1036aa:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1036af:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1036b6:	00 
  1036b7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1036be:	00 
  1036bf:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1036c2:	89 54 24 04          	mov    %edx,0x4(%esp)
  1036c6:	89 04 24             	mov    %eax,(%esp)
  1036c9:	e8 df fa ff ff       	call   1031ad <page_insert>
  1036ce:	85 c0                	test   %eax,%eax
  1036d0:	74 24                	je     1036f6 <check_pgdir+0x415>
  1036d2:	c7 44 24 0c dc 66 10 	movl   $0x1066dc,0xc(%esp)
  1036d9:	00 
  1036da:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  1036e1:	00 
  1036e2:	c7 44 24 04 15 02 00 	movl   $0x215,0x4(%esp)
  1036e9:	00 
  1036ea:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  1036f1:	e8 f3 cc ff ff       	call   1003e9 <__panic>
    assert(page_ref(p1) == 2);
  1036f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1036f9:	89 04 24             	mov    %eax,(%esp)
  1036fc:	e8 4c f0 ff ff       	call   10274d <page_ref>
  103701:	83 f8 02             	cmp    $0x2,%eax
  103704:	74 24                	je     10372a <check_pgdir+0x449>
  103706:	c7 44 24 0c 08 67 10 	movl   $0x106708,0xc(%esp)
  10370d:	00 
  10370e:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103715:	00 
  103716:	c7 44 24 04 16 02 00 	movl   $0x216,0x4(%esp)
  10371d:	00 
  10371e:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103725:	e8 bf cc ff ff       	call   1003e9 <__panic>
    assert(page_ref(p2) == 0);
  10372a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10372d:	89 04 24             	mov    %eax,(%esp)
  103730:	e8 18 f0 ff ff       	call   10274d <page_ref>
  103735:	85 c0                	test   %eax,%eax
  103737:	74 24                	je     10375d <check_pgdir+0x47c>
  103739:	c7 44 24 0c 1a 67 10 	movl   $0x10671a,0xc(%esp)
  103740:	00 
  103741:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103748:	00 
  103749:	c7 44 24 04 17 02 00 	movl   $0x217,0x4(%esp)
  103750:	00 
  103751:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103758:	e8 8c cc ff ff       	call   1003e9 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
  10375d:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103762:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103769:	00 
  10376a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  103771:	00 
  103772:	89 04 24             	mov    %eax,(%esp)
  103775:	e8 82 f8 ff ff       	call   102ffc <get_pte>
  10377a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10377d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  103781:	75 24                	jne    1037a7 <check_pgdir+0x4c6>
  103783:	c7 44 24 0c 68 66 10 	movl   $0x106668,0xc(%esp)
  10378a:	00 
  10378b:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103792:	00 
  103793:	c7 44 24 04 18 02 00 	movl   $0x218,0x4(%esp)
  10379a:	00 
  10379b:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  1037a2:	e8 42 cc ff ff       	call   1003e9 <__panic>
    assert(pte2page(*ptep) == p1);
  1037a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1037aa:	8b 00                	mov    (%eax),%eax
  1037ac:	89 04 24             	mov    %eax,(%esp)
  1037af:	e8 43 ef ff ff       	call   1026f7 <pte2page>
  1037b4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  1037b7:	74 24                	je     1037dd <check_pgdir+0x4fc>
  1037b9:	c7 44 24 0c dd 65 10 	movl   $0x1065dd,0xc(%esp)
  1037c0:	00 
  1037c1:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  1037c8:	00 
  1037c9:	c7 44 24 04 19 02 00 	movl   $0x219,0x4(%esp)
  1037d0:	00 
  1037d1:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  1037d8:	e8 0c cc ff ff       	call   1003e9 <__panic>
    assert((*ptep & PTE_U) == 0);
  1037dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1037e0:	8b 00                	mov    (%eax),%eax
  1037e2:	83 e0 04             	and    $0x4,%eax
  1037e5:	85 c0                	test   %eax,%eax
  1037e7:	74 24                	je     10380d <check_pgdir+0x52c>
  1037e9:	c7 44 24 0c 2c 67 10 	movl   $0x10672c,0xc(%esp)
  1037f0:	00 
  1037f1:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  1037f8:	00 
  1037f9:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
  103800:	00 
  103801:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103808:	e8 dc cb ff ff       	call   1003e9 <__panic>

    page_remove(boot_pgdir, 0x0);
  10380d:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103812:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103819:	00 
  10381a:	89 04 24             	mov    %eax,(%esp)
  10381d:	e8 46 f9 ff ff       	call   103168 <page_remove>
    assert(page_ref(p1) == 1);
  103822:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103825:	89 04 24             	mov    %eax,(%esp)
  103828:	e8 20 ef ff ff       	call   10274d <page_ref>
  10382d:	83 f8 01             	cmp    $0x1,%eax
  103830:	74 24                	je     103856 <check_pgdir+0x575>
  103832:	c7 44 24 0c f3 65 10 	movl   $0x1065f3,0xc(%esp)
  103839:	00 
  10383a:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103841:	00 
  103842:	c7 44 24 04 1d 02 00 	movl   $0x21d,0x4(%esp)
  103849:	00 
  10384a:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103851:	e8 93 cb ff ff       	call   1003e9 <__panic>
    assert(page_ref(p2) == 0);
  103856:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103859:	89 04 24             	mov    %eax,(%esp)
  10385c:	e8 ec ee ff ff       	call   10274d <page_ref>
  103861:	85 c0                	test   %eax,%eax
  103863:	74 24                	je     103889 <check_pgdir+0x5a8>
  103865:	c7 44 24 0c 1a 67 10 	movl   $0x10671a,0xc(%esp)
  10386c:	00 
  10386d:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103874:	00 
  103875:	c7 44 24 04 1e 02 00 	movl   $0x21e,0x4(%esp)
  10387c:	00 
  10387d:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103884:	e8 60 cb ff ff       	call   1003e9 <__panic>

    page_remove(boot_pgdir, PGSIZE);
  103889:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  10388e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  103895:	00 
  103896:	89 04 24             	mov    %eax,(%esp)
  103899:	e8 ca f8 ff ff       	call   103168 <page_remove>
    assert(page_ref(p1) == 0);
  10389e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1038a1:	89 04 24             	mov    %eax,(%esp)
  1038a4:	e8 a4 ee ff ff       	call   10274d <page_ref>
  1038a9:	85 c0                	test   %eax,%eax
  1038ab:	74 24                	je     1038d1 <check_pgdir+0x5f0>
  1038ad:	c7 44 24 0c 41 67 10 	movl   $0x106741,0xc(%esp)
  1038b4:	00 
  1038b5:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  1038bc:	00 
  1038bd:	c7 44 24 04 21 02 00 	movl   $0x221,0x4(%esp)
  1038c4:	00 
  1038c5:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  1038cc:	e8 18 cb ff ff       	call   1003e9 <__panic>
    assert(page_ref(p2) == 0);
  1038d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1038d4:	89 04 24             	mov    %eax,(%esp)
  1038d7:	e8 71 ee ff ff       	call   10274d <page_ref>
  1038dc:	85 c0                	test   %eax,%eax
  1038de:	74 24                	je     103904 <check_pgdir+0x623>
  1038e0:	c7 44 24 0c 1a 67 10 	movl   $0x10671a,0xc(%esp)
  1038e7:	00 
  1038e8:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  1038ef:	00 
  1038f0:	c7 44 24 04 22 02 00 	movl   $0x222,0x4(%esp)
  1038f7:	00 
  1038f8:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  1038ff:	e8 e5 ca ff ff       	call   1003e9 <__panic>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
  103904:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103909:	8b 00                	mov    (%eax),%eax
  10390b:	89 04 24             	mov    %eax,(%esp)
  10390e:	e8 22 ee ff ff       	call   102735 <pde2page>
  103913:	89 04 24             	mov    %eax,(%esp)
  103916:	e8 32 ee ff ff       	call   10274d <page_ref>
  10391b:	83 f8 01             	cmp    $0x1,%eax
  10391e:	74 24                	je     103944 <check_pgdir+0x663>
  103920:	c7 44 24 0c 54 67 10 	movl   $0x106754,0xc(%esp)
  103927:	00 
  103928:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  10392f:	00 
  103930:	c7 44 24 04 24 02 00 	movl   $0x224,0x4(%esp)
  103937:	00 
  103938:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  10393f:	e8 a5 ca ff ff       	call   1003e9 <__panic>
    free_page(pde2page(boot_pgdir[0]));
  103944:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103949:	8b 00                	mov    (%eax),%eax
  10394b:	89 04 24             	mov    %eax,(%esp)
  10394e:	e8 e2 ed ff ff       	call   102735 <pde2page>
  103953:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10395a:	00 
  10395b:	89 04 24             	mov    %eax,(%esp)
  10395e:	e8 27 f0 ff ff       	call   10298a <free_pages>
    boot_pgdir[0] = 0;
  103963:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103968:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_pgdir() succeeded!\n");
  10396e:	c7 04 24 7b 67 10 00 	movl   $0x10677b,(%esp)
  103975:	e8 18 c9 ff ff       	call   100292 <cprintf>
}
  10397a:	90                   	nop
  10397b:	c9                   	leave  
  10397c:	c3                   	ret    

0010397d <check_boot_pgdir>:

static void
check_boot_pgdir(void) {
  10397d:	55                   	push   %ebp
  10397e:	89 e5                	mov    %esp,%ebp
  103980:	83 ec 38             	sub    $0x38,%esp
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
  103983:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10398a:	e9 ca 00 00 00       	jmp    103a59 <check_boot_pgdir+0xdc>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
  10398f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103992:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103995:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103998:	c1 e8 0c             	shr    $0xc,%eax
  10399b:	89 45 ec             	mov    %eax,-0x14(%ebp)
  10399e:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  1039a3:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  1039a6:	72 23                	jb     1039cb <check_boot_pgdir+0x4e>
  1039a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1039ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1039af:	c7 44 24 08 c0 63 10 	movl   $0x1063c0,0x8(%esp)
  1039b6:	00 
  1039b7:	c7 44 24 04 30 02 00 	movl   $0x230,0x4(%esp)
  1039be:	00 
  1039bf:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  1039c6:	e8 1e ca ff ff       	call   1003e9 <__panic>
  1039cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1039ce:	2d 00 00 00 40       	sub    $0x40000000,%eax
  1039d3:	89 c2                	mov    %eax,%edx
  1039d5:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1039da:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1039e1:	00 
  1039e2:	89 54 24 04          	mov    %edx,0x4(%esp)
  1039e6:	89 04 24             	mov    %eax,(%esp)
  1039e9:	e8 0e f6 ff ff       	call   102ffc <get_pte>
  1039ee:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1039f1:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  1039f5:	75 24                	jne    103a1b <check_boot_pgdir+0x9e>
  1039f7:	c7 44 24 0c 98 67 10 	movl   $0x106798,0xc(%esp)
  1039fe:	00 
  1039ff:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103a06:	00 
  103a07:	c7 44 24 04 30 02 00 	movl   $0x230,0x4(%esp)
  103a0e:	00 
  103a0f:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103a16:	e8 ce c9 ff ff       	call   1003e9 <__panic>
        assert(PTE_ADDR(*ptep) == i);
  103a1b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a1e:	8b 00                	mov    (%eax),%eax
  103a20:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103a25:	89 c2                	mov    %eax,%edx
  103a27:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a2a:	39 c2                	cmp    %eax,%edx
  103a2c:	74 24                	je     103a52 <check_boot_pgdir+0xd5>
  103a2e:	c7 44 24 0c d5 67 10 	movl   $0x1067d5,0xc(%esp)
  103a35:	00 
  103a36:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103a3d:	00 
  103a3e:	c7 44 24 04 31 02 00 	movl   $0x231,0x4(%esp)
  103a45:	00 
  103a46:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103a4d:	e8 97 c9 ff ff       	call   1003e9 <__panic>

static void
check_boot_pgdir(void) {
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
  103a52:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
  103a59:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103a5c:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  103a61:	39 c2                	cmp    %eax,%edx
  103a63:	0f 82 26 ff ff ff    	jb     10398f <check_boot_pgdir+0x12>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }

    assert(PDE_ADDR(boot_pgdir[PDX(VPT)]) == PADDR(boot_pgdir));
  103a69:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103a6e:	05 ac 0f 00 00       	add    $0xfac,%eax
  103a73:	8b 00                	mov    (%eax),%eax
  103a75:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103a7a:	89 c2                	mov    %eax,%edx
  103a7c:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103a81:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  103a84:	81 7d e4 ff ff ff bf 	cmpl   $0xbfffffff,-0x1c(%ebp)
  103a8b:	77 23                	ja     103ab0 <check_boot_pgdir+0x133>
  103a8d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103a90:	89 44 24 0c          	mov    %eax,0xc(%esp)
  103a94:	c7 44 24 08 64 64 10 	movl   $0x106464,0x8(%esp)
  103a9b:	00 
  103a9c:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
  103aa3:	00 
  103aa4:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103aab:	e8 39 c9 ff ff       	call   1003e9 <__panic>
  103ab0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103ab3:	05 00 00 00 40       	add    $0x40000000,%eax
  103ab8:	39 c2                	cmp    %eax,%edx
  103aba:	74 24                	je     103ae0 <check_boot_pgdir+0x163>
  103abc:	c7 44 24 0c ec 67 10 	movl   $0x1067ec,0xc(%esp)
  103ac3:	00 
  103ac4:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103acb:	00 
  103acc:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
  103ad3:	00 
  103ad4:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103adb:	e8 09 c9 ff ff       	call   1003e9 <__panic>

    assert(boot_pgdir[0] == 0);
  103ae0:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103ae5:	8b 00                	mov    (%eax),%eax
  103ae7:	85 c0                	test   %eax,%eax
  103ae9:	74 24                	je     103b0f <check_boot_pgdir+0x192>
  103aeb:	c7 44 24 0c 20 68 10 	movl   $0x106820,0xc(%esp)
  103af2:	00 
  103af3:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103afa:	00 
  103afb:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
  103b02:	00 
  103b03:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103b0a:	e8 da c8 ff ff       	call   1003e9 <__panic>

    struct Page *p;
    p = alloc_page();
  103b0f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  103b16:	e8 37 ee ff ff       	call   102952 <alloc_pages>
  103b1b:	89 45 e0             	mov    %eax,-0x20(%ebp)
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W) == 0);
  103b1e:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103b23:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
  103b2a:	00 
  103b2b:	c7 44 24 08 00 01 00 	movl   $0x100,0x8(%esp)
  103b32:	00 
  103b33:	8b 55 e0             	mov    -0x20(%ebp),%edx
  103b36:	89 54 24 04          	mov    %edx,0x4(%esp)
  103b3a:	89 04 24             	mov    %eax,(%esp)
  103b3d:	e8 6b f6 ff ff       	call   1031ad <page_insert>
  103b42:	85 c0                	test   %eax,%eax
  103b44:	74 24                	je     103b6a <check_boot_pgdir+0x1ed>
  103b46:	c7 44 24 0c 34 68 10 	movl   $0x106834,0xc(%esp)
  103b4d:	00 
  103b4e:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103b55:	00 
  103b56:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
  103b5d:	00 
  103b5e:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103b65:	e8 7f c8 ff ff       	call   1003e9 <__panic>
    assert(page_ref(p) == 1);
  103b6a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103b6d:	89 04 24             	mov    %eax,(%esp)
  103b70:	e8 d8 eb ff ff       	call   10274d <page_ref>
  103b75:	83 f8 01             	cmp    $0x1,%eax
  103b78:	74 24                	je     103b9e <check_boot_pgdir+0x221>
  103b7a:	c7 44 24 0c 62 68 10 	movl   $0x106862,0xc(%esp)
  103b81:	00 
  103b82:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103b89:	00 
  103b8a:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
  103b91:	00 
  103b92:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103b99:	e8 4b c8 ff ff       	call   1003e9 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W) == 0);
  103b9e:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103ba3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
  103baa:	00 
  103bab:	c7 44 24 08 00 11 00 	movl   $0x1100,0x8(%esp)
  103bb2:	00 
  103bb3:	8b 55 e0             	mov    -0x20(%ebp),%edx
  103bb6:	89 54 24 04          	mov    %edx,0x4(%esp)
  103bba:	89 04 24             	mov    %eax,(%esp)
  103bbd:	e8 eb f5 ff ff       	call   1031ad <page_insert>
  103bc2:	85 c0                	test   %eax,%eax
  103bc4:	74 24                	je     103bea <check_boot_pgdir+0x26d>
  103bc6:	c7 44 24 0c 74 68 10 	movl   $0x106874,0xc(%esp)
  103bcd:	00 
  103bce:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103bd5:	00 
  103bd6:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
  103bdd:	00 
  103bde:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103be5:	e8 ff c7 ff ff       	call   1003e9 <__panic>
    assert(page_ref(p) == 2);
  103bea:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103bed:	89 04 24             	mov    %eax,(%esp)
  103bf0:	e8 58 eb ff ff       	call   10274d <page_ref>
  103bf5:	83 f8 02             	cmp    $0x2,%eax
  103bf8:	74 24                	je     103c1e <check_boot_pgdir+0x2a1>
  103bfa:	c7 44 24 0c ab 68 10 	movl   $0x1068ab,0xc(%esp)
  103c01:	00 
  103c02:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103c09:	00 
  103c0a:	c7 44 24 04 3d 02 00 	movl   $0x23d,0x4(%esp)
  103c11:	00 
  103c12:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103c19:	e8 cb c7 ff ff       	call   1003e9 <__panic>

    const char *str = "ucore: Hello world!!";
  103c1e:	c7 45 dc bc 68 10 00 	movl   $0x1068bc,-0x24(%ebp)
    strcpy((void *)0x100, str);
  103c25:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103c28:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c2c:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
  103c33:	e8 a1 15 00 00       	call   1051d9 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
  103c38:	c7 44 24 04 00 11 00 	movl   $0x1100,0x4(%esp)
  103c3f:	00 
  103c40:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
  103c47:	e8 04 16 00 00       	call   105250 <strcmp>
  103c4c:	85 c0                	test   %eax,%eax
  103c4e:	74 24                	je     103c74 <check_boot_pgdir+0x2f7>
  103c50:	c7 44 24 0c d4 68 10 	movl   $0x1068d4,0xc(%esp)
  103c57:	00 
  103c58:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103c5f:	00 
  103c60:	c7 44 24 04 41 02 00 	movl   $0x241,0x4(%esp)
  103c67:	00 
  103c68:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103c6f:	e8 75 c7 ff ff       	call   1003e9 <__panic>

    *(char *)(page2kva(p) + 0x100) = '\0';
  103c74:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103c77:	89 04 24             	mov    %eax,(%esp)
  103c7a:	e8 24 ea ff ff       	call   1026a3 <page2kva>
  103c7f:	05 00 01 00 00       	add    $0x100,%eax
  103c84:	c6 00 00             	movb   $0x0,(%eax)
    assert(strlen((const char *)0x100) == 0);
  103c87:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
  103c8e:	e8 f0 14 00 00       	call   105183 <strlen>
  103c93:	85 c0                	test   %eax,%eax
  103c95:	74 24                	je     103cbb <check_boot_pgdir+0x33e>
  103c97:	c7 44 24 0c 0c 69 10 	movl   $0x10690c,0xc(%esp)
  103c9e:	00 
  103c9f:	c7 44 24 08 ad 64 10 	movl   $0x1064ad,0x8(%esp)
  103ca6:	00 
  103ca7:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
  103cae:	00 
  103caf:	c7 04 24 88 64 10 00 	movl   $0x106488,(%esp)
  103cb6:	e8 2e c7 ff ff       	call   1003e9 <__panic>

    free_page(p);
  103cbb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103cc2:	00 
  103cc3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103cc6:	89 04 24             	mov    %eax,(%esp)
  103cc9:	e8 bc ec ff ff       	call   10298a <free_pages>
    free_page(pde2page(boot_pgdir[0]));
  103cce:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103cd3:	8b 00                	mov    (%eax),%eax
  103cd5:	89 04 24             	mov    %eax,(%esp)
  103cd8:	e8 58 ea ff ff       	call   102735 <pde2page>
  103cdd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103ce4:	00 
  103ce5:	89 04 24             	mov    %eax,(%esp)
  103ce8:	e8 9d ec ff ff       	call   10298a <free_pages>
    boot_pgdir[0] = 0;
  103ced:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103cf2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_boot_pgdir() succeeded!\n");
  103cf8:	c7 04 24 30 69 10 00 	movl   $0x106930,(%esp)
  103cff:	e8 8e c5 ff ff       	call   100292 <cprintf>
}
  103d04:	90                   	nop
  103d05:	c9                   	leave  
  103d06:	c3                   	ret    

00103d07 <perm2str>:

//perm2str - use string 'u,r,w,-' to present the permission
static const char *
perm2str(int perm) {
  103d07:	55                   	push   %ebp
  103d08:	89 e5                	mov    %esp,%ebp
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
  103d0a:	8b 45 08             	mov    0x8(%ebp),%eax
  103d0d:	83 e0 04             	and    $0x4,%eax
  103d10:	85 c0                	test   %eax,%eax
  103d12:	74 04                	je     103d18 <perm2str+0x11>
  103d14:	b0 75                	mov    $0x75,%al
  103d16:	eb 02                	jmp    103d1a <perm2str+0x13>
  103d18:	b0 2d                	mov    $0x2d,%al
  103d1a:	a2 08 af 11 00       	mov    %al,0x11af08
    str[1] = 'r';
  103d1f:	c6 05 09 af 11 00 72 	movb   $0x72,0x11af09
    str[2] = (perm & PTE_W) ? 'w' : '-';
  103d26:	8b 45 08             	mov    0x8(%ebp),%eax
  103d29:	83 e0 02             	and    $0x2,%eax
  103d2c:	85 c0                	test   %eax,%eax
  103d2e:	74 04                	je     103d34 <perm2str+0x2d>
  103d30:	b0 77                	mov    $0x77,%al
  103d32:	eb 02                	jmp    103d36 <perm2str+0x2f>
  103d34:	b0 2d                	mov    $0x2d,%al
  103d36:	a2 0a af 11 00       	mov    %al,0x11af0a
    str[3] = '\0';
  103d3b:	c6 05 0b af 11 00 00 	movb   $0x0,0x11af0b
    return str;
  103d42:	b8 08 af 11 00       	mov    $0x11af08,%eax
}
  103d47:	5d                   	pop    %ebp
  103d48:	c3                   	ret    

00103d49 <get_pgtable_items>:
//  table:       the beginning addr of table
//  left_store:  the pointer of the high side of table's next range
//  right_store: the pointer of the low side of table's next range
// return value: 0 - not a invalid item range, perm - a valid item range with perm permission 
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
  103d49:	55                   	push   %ebp
  103d4a:	89 e5                	mov    %esp,%ebp
  103d4c:	83 ec 10             	sub    $0x10,%esp
    if (start >= right) {
  103d4f:	8b 45 10             	mov    0x10(%ebp),%eax
  103d52:	3b 45 0c             	cmp    0xc(%ebp),%eax
  103d55:	72 0d                	jb     103d64 <get_pgtable_items+0x1b>
        return 0;
  103d57:	b8 00 00 00 00       	mov    $0x0,%eax
  103d5c:	e9 98 00 00 00       	jmp    103df9 <get_pgtable_items+0xb0>
    }
    while (start < right && !(table[start] & PTE_P)) {
        start ++;
  103d61:	ff 45 10             	incl   0x10(%ebp)
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
    if (start >= right) {
        return 0;
    }
    while (start < right && !(table[start] & PTE_P)) {
  103d64:	8b 45 10             	mov    0x10(%ebp),%eax
  103d67:	3b 45 0c             	cmp    0xc(%ebp),%eax
  103d6a:	73 18                	jae    103d84 <get_pgtable_items+0x3b>
  103d6c:	8b 45 10             	mov    0x10(%ebp),%eax
  103d6f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  103d76:	8b 45 14             	mov    0x14(%ebp),%eax
  103d79:	01 d0                	add    %edx,%eax
  103d7b:	8b 00                	mov    (%eax),%eax
  103d7d:	83 e0 01             	and    $0x1,%eax
  103d80:	85 c0                	test   %eax,%eax
  103d82:	74 dd                	je     103d61 <get_pgtable_items+0x18>
        start ++;
    }
    if (start < right) {
  103d84:	8b 45 10             	mov    0x10(%ebp),%eax
  103d87:	3b 45 0c             	cmp    0xc(%ebp),%eax
  103d8a:	73 68                	jae    103df4 <get_pgtable_items+0xab>
        if (left_store != NULL) {
  103d8c:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
  103d90:	74 08                	je     103d9a <get_pgtable_items+0x51>
            *left_store = start;
  103d92:	8b 45 18             	mov    0x18(%ebp),%eax
  103d95:	8b 55 10             	mov    0x10(%ebp),%edx
  103d98:	89 10                	mov    %edx,(%eax)
        }
        int perm = (table[start ++] & PTE_USER);
  103d9a:	8b 45 10             	mov    0x10(%ebp),%eax
  103d9d:	8d 50 01             	lea    0x1(%eax),%edx
  103da0:	89 55 10             	mov    %edx,0x10(%ebp)
  103da3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  103daa:	8b 45 14             	mov    0x14(%ebp),%eax
  103dad:	01 d0                	add    %edx,%eax
  103daf:	8b 00                	mov    (%eax),%eax
  103db1:	83 e0 07             	and    $0x7,%eax
  103db4:	89 45 fc             	mov    %eax,-0x4(%ebp)
        while (start < right && (table[start] & PTE_USER) == perm) {
  103db7:	eb 03                	jmp    103dbc <get_pgtable_items+0x73>
            start ++;
  103db9:	ff 45 10             	incl   0x10(%ebp)
    if (start < right) {
        if (left_store != NULL) {
            *left_store = start;
        }
        int perm = (table[start ++] & PTE_USER);
        while (start < right && (table[start] & PTE_USER) == perm) {
  103dbc:	8b 45 10             	mov    0x10(%ebp),%eax
  103dbf:	3b 45 0c             	cmp    0xc(%ebp),%eax
  103dc2:	73 1d                	jae    103de1 <get_pgtable_items+0x98>
  103dc4:	8b 45 10             	mov    0x10(%ebp),%eax
  103dc7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  103dce:	8b 45 14             	mov    0x14(%ebp),%eax
  103dd1:	01 d0                	add    %edx,%eax
  103dd3:	8b 00                	mov    (%eax),%eax
  103dd5:	83 e0 07             	and    $0x7,%eax
  103dd8:	89 c2                	mov    %eax,%edx
  103dda:	8b 45 fc             	mov    -0x4(%ebp),%eax
  103ddd:	39 c2                	cmp    %eax,%edx
  103ddf:	74 d8                	je     103db9 <get_pgtable_items+0x70>
            start ++;
        }
        if (right_store != NULL) {
  103de1:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
  103de5:	74 08                	je     103def <get_pgtable_items+0xa6>
            *right_store = start;
  103de7:	8b 45 1c             	mov    0x1c(%ebp),%eax
  103dea:	8b 55 10             	mov    0x10(%ebp),%edx
  103ded:	89 10                	mov    %edx,(%eax)
        }
        return perm;
  103def:	8b 45 fc             	mov    -0x4(%ebp),%eax
  103df2:	eb 05                	jmp    103df9 <get_pgtable_items+0xb0>
    }
    return 0;
  103df4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  103df9:	c9                   	leave  
  103dfa:	c3                   	ret    

00103dfb <print_pgdir>:

//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
  103dfb:	55                   	push   %ebp
  103dfc:	89 e5                	mov    %esp,%ebp
  103dfe:	57                   	push   %edi
  103dff:	56                   	push   %esi
  103e00:	53                   	push   %ebx
  103e01:	83 ec 4c             	sub    $0x4c,%esp
    cprintf("-------------------- BEGIN --------------------\n");
  103e04:	c7 04 24 50 69 10 00 	movl   $0x106950,(%esp)
  103e0b:	e8 82 c4 ff ff       	call   100292 <cprintf>
    size_t left, right = 0, perm;
  103e10:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
  103e17:	e9 fa 00 00 00       	jmp    103f16 <print_pgdir+0x11b>
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
  103e1c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103e1f:	89 04 24             	mov    %eax,(%esp)
  103e22:	e8 e0 fe ff ff       	call   103d07 <perm2str>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
  103e27:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  103e2a:	8b 55 e0             	mov    -0x20(%ebp),%edx
  103e2d:	29 d1                	sub    %edx,%ecx
  103e2f:	89 ca                	mov    %ecx,%edx
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
  103e31:	89 d6                	mov    %edx,%esi
  103e33:	c1 e6 16             	shl    $0x16,%esi
  103e36:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103e39:	89 d3                	mov    %edx,%ebx
  103e3b:	c1 e3 16             	shl    $0x16,%ebx
  103e3e:	8b 55 e0             	mov    -0x20(%ebp),%edx
  103e41:	89 d1                	mov    %edx,%ecx
  103e43:	c1 e1 16             	shl    $0x16,%ecx
  103e46:	8b 7d dc             	mov    -0x24(%ebp),%edi
  103e49:	8b 55 e0             	mov    -0x20(%ebp),%edx
  103e4c:	29 d7                	sub    %edx,%edi
  103e4e:	89 fa                	mov    %edi,%edx
  103e50:	89 44 24 14          	mov    %eax,0x14(%esp)
  103e54:	89 74 24 10          	mov    %esi,0x10(%esp)
  103e58:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  103e5c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  103e60:	89 54 24 04          	mov    %edx,0x4(%esp)
  103e64:	c7 04 24 81 69 10 00 	movl   $0x106981,(%esp)
  103e6b:	e8 22 c4 ff ff       	call   100292 <cprintf>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
  103e70:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103e73:	c1 e0 0a             	shl    $0xa,%eax
  103e76:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
  103e79:	eb 54                	jmp    103ecf <print_pgdir+0xd4>
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
  103e7b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103e7e:	89 04 24             	mov    %eax,(%esp)
  103e81:	e8 81 fe ff ff       	call   103d07 <perm2str>
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
  103e86:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  103e89:	8b 55 d8             	mov    -0x28(%ebp),%edx
  103e8c:	29 d1                	sub    %edx,%ecx
  103e8e:	89 ca                	mov    %ecx,%edx
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
  103e90:	89 d6                	mov    %edx,%esi
  103e92:	c1 e6 0c             	shl    $0xc,%esi
  103e95:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103e98:	89 d3                	mov    %edx,%ebx
  103e9a:	c1 e3 0c             	shl    $0xc,%ebx
  103e9d:	8b 55 d8             	mov    -0x28(%ebp),%edx
  103ea0:	89 d1                	mov    %edx,%ecx
  103ea2:	c1 e1 0c             	shl    $0xc,%ecx
  103ea5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  103ea8:	8b 55 d8             	mov    -0x28(%ebp),%edx
  103eab:	29 d7                	sub    %edx,%edi
  103ead:	89 fa                	mov    %edi,%edx
  103eaf:	89 44 24 14          	mov    %eax,0x14(%esp)
  103eb3:	89 74 24 10          	mov    %esi,0x10(%esp)
  103eb7:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  103ebb:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  103ebf:	89 54 24 04          	mov    %edx,0x4(%esp)
  103ec3:	c7 04 24 a0 69 10 00 	movl   $0x1069a0,(%esp)
  103eca:	e8 c3 c3 ff ff       	call   100292 <cprintf>
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
  103ecf:	be 00 00 c0 fa       	mov    $0xfac00000,%esi
  103ed4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  103ed7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103eda:	89 d3                	mov    %edx,%ebx
  103edc:	c1 e3 0a             	shl    $0xa,%ebx
  103edf:	8b 55 e0             	mov    -0x20(%ebp),%edx
  103ee2:	89 d1                	mov    %edx,%ecx
  103ee4:	c1 e1 0a             	shl    $0xa,%ecx
  103ee7:	8d 55 d4             	lea    -0x2c(%ebp),%edx
  103eea:	89 54 24 14          	mov    %edx,0x14(%esp)
  103eee:	8d 55 d8             	lea    -0x28(%ebp),%edx
  103ef1:	89 54 24 10          	mov    %edx,0x10(%esp)
  103ef5:	89 74 24 0c          	mov    %esi,0xc(%esp)
  103ef9:	89 44 24 08          	mov    %eax,0x8(%esp)
  103efd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  103f01:	89 0c 24             	mov    %ecx,(%esp)
  103f04:	e8 40 fe ff ff       	call   103d49 <get_pgtable_items>
  103f09:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  103f0c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  103f10:	0f 85 65 ff ff ff    	jne    103e7b <print_pgdir+0x80>
//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
  103f16:	b9 00 b0 fe fa       	mov    $0xfafeb000,%ecx
  103f1b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103f1e:	8d 55 dc             	lea    -0x24(%ebp),%edx
  103f21:	89 54 24 14          	mov    %edx,0x14(%esp)
  103f25:	8d 55 e0             	lea    -0x20(%ebp),%edx
  103f28:	89 54 24 10          	mov    %edx,0x10(%esp)
  103f2c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  103f30:	89 44 24 08          	mov    %eax,0x8(%esp)
  103f34:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  103f3b:	00 
  103f3c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  103f43:	e8 01 fe ff ff       	call   103d49 <get_pgtable_items>
  103f48:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  103f4b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  103f4f:	0f 85 c7 fe ff ff    	jne    103e1c <print_pgdir+0x21>
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
        }
    }
    cprintf("--------------------- END ---------------------\n");
  103f55:	c7 04 24 c4 69 10 00 	movl   $0x1069c4,(%esp)
  103f5c:	e8 31 c3 ff ff       	call   100292 <cprintf>
}
  103f61:	90                   	nop
  103f62:	83 c4 4c             	add    $0x4c,%esp
  103f65:	5b                   	pop    %ebx
  103f66:	5e                   	pop    %esi
  103f67:	5f                   	pop    %edi
  103f68:	5d                   	pop    %ebp
  103f69:	c3                   	ret    

00103f6a <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
  103f6a:	55                   	push   %ebp
  103f6b:	89 e5                	mov    %esp,%ebp
    return page - pages;
  103f6d:	8b 45 08             	mov    0x8(%ebp),%eax
  103f70:	8b 15 18 af 11 00    	mov    0x11af18,%edx
  103f76:	29 d0                	sub    %edx,%eax
  103f78:	c1 f8 02             	sar    $0x2,%eax
  103f7b:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
  103f81:	5d                   	pop    %ebp
  103f82:	c3                   	ret    

00103f83 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
  103f83:	55                   	push   %ebp
  103f84:	89 e5                	mov    %esp,%ebp
  103f86:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
  103f89:	8b 45 08             	mov    0x8(%ebp),%eax
  103f8c:	89 04 24             	mov    %eax,(%esp)
  103f8f:	e8 d6 ff ff ff       	call   103f6a <page2ppn>
  103f94:	c1 e0 0c             	shl    $0xc,%eax
}
  103f97:	c9                   	leave  
  103f98:	c3                   	ret    

00103f99 <page_ref>:
pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
}

static inline int
page_ref(struct Page *page) {
  103f99:	55                   	push   %ebp
  103f9a:	89 e5                	mov    %esp,%ebp
    return page->ref;
  103f9c:	8b 45 08             	mov    0x8(%ebp),%eax
  103f9f:	8b 00                	mov    (%eax),%eax
}
  103fa1:	5d                   	pop    %ebp
  103fa2:	c3                   	ret    

00103fa3 <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
  103fa3:	55                   	push   %ebp
  103fa4:	89 e5                	mov    %esp,%ebp
    page->ref = val;
  103fa6:	8b 45 08             	mov    0x8(%ebp),%eax
  103fa9:	8b 55 0c             	mov    0xc(%ebp),%edx
  103fac:	89 10                	mov    %edx,(%eax)
}
  103fae:	90                   	nop
  103faf:	5d                   	pop    %ebp
  103fb0:	c3                   	ret    

00103fb1 <default_init>:

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
  103fb1:	55                   	push   %ebp
  103fb2:	89 e5                	mov    %esp,%ebp
  103fb4:	83 ec 10             	sub    $0x10,%esp
  103fb7:	c7 45 fc 1c af 11 00 	movl   $0x11af1c,-0x4(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
  103fbe:	8b 45 fc             	mov    -0x4(%ebp),%eax
  103fc1:	8b 55 fc             	mov    -0x4(%ebp),%edx
  103fc4:	89 50 04             	mov    %edx,0x4(%eax)
  103fc7:	8b 45 fc             	mov    -0x4(%ebp),%eax
  103fca:	8b 50 04             	mov    0x4(%eax),%edx
  103fcd:	8b 45 fc             	mov    -0x4(%ebp),%eax
  103fd0:	89 10                	mov    %edx,(%eax)
     * Because at first there is no free block to add, so we just let the prev and next pointers to point to itself.
     * This is done through:
     *      free_list->next = free_list->prev = free_list;
     */
    list_init(&free_list);
    nr_free = 0;
  103fd2:	c7 05 24 af 11 00 00 	movl   $0x0,0x11af24
  103fd9:	00 00 00 
}
  103fdc:	90                   	nop
  103fdd:	c9                   	leave  
  103fde:	c3                   	ret    

00103fdf <default_init_memmap>:
 * Page has been referenced, etc.
 * 
 * This function is used to initilize each page within a free memory block and then link it to the free list.
 */
static void
default_init_memmap(struct Page *base, size_t n) {
  103fdf:	55                   	push   %ebp
  103fe0:	89 e5                	mov    %esp,%ebp
  103fe2:	83 ec 48             	sub    $0x48,%esp
    // For Paging mechanism.
    assert(n > 0);
  103fe5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  103fe9:	75 24                	jne    10400f <default_init_memmap+0x30>
  103feb:	c7 44 24 0c f8 69 10 	movl   $0x1069f8,0xc(%esp)
  103ff2:	00 
  103ff3:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  103ffa:	00 
  103ffb:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  104002:	00 
  104003:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  10400a:	e8 da c3 ff ff       	call   1003e9 <__panic>
    struct Page *p = base;
  10400f:	8b 45 08             	mov    0x8(%ebp),%eax
  104012:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
  104015:	eb 7d                	jmp    104094 <default_init_memmap+0xb5>
        // Initialize the page within the block.
        assert(PageReserved(p));
  104017:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10401a:	83 c0 04             	add    $0x4,%eax
  10401d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  104024:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104027:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10402a:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10402d:	0f a3 10             	bt     %edx,(%eax)
  104030:	19 c0                	sbb    %eax,%eax
  104032:	89 45 e0             	mov    %eax,-0x20(%ebp)
    return oldbit != 0;
  104035:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  104039:	0f 95 c0             	setne  %al
  10403c:	0f b6 c0             	movzbl %al,%eax
  10403f:	85 c0                	test   %eax,%eax
  104041:	75 24                	jne    104067 <default_init_memmap+0x88>
  104043:	c7 44 24 0c 29 6a 10 	movl   $0x106a29,0xc(%esp)
  10404a:	00 
  10404b:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104052:	00 
  104053:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  10405a:	00 
  10405b:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104062:	e8 82 c3 ff ff       	call   1003e9 <__panic>
        p->flags = p->property = 0;
  104067:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10406a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  104071:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104074:	8b 50 08             	mov    0x8(%eax),%edx
  104077:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10407a:	89 50 04             	mov    %edx,0x4(%eax)
        set_page_ref(p, 0);
  10407d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104084:	00 
  104085:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104088:	89 04 24             	mov    %eax,(%esp)
  10408b:	e8 13 ff ff ff       	call   103fa3 <set_page_ref>
static void
default_init_memmap(struct Page *base, size_t n) {
    // For Paging mechanism.
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
  104090:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
  104094:	8b 55 0c             	mov    0xc(%ebp),%edx
  104097:	89 d0                	mov    %edx,%eax
  104099:	c1 e0 02             	shl    $0x2,%eax
  10409c:	01 d0                	add    %edx,%eax
  10409e:	c1 e0 02             	shl    $0x2,%eax
  1040a1:	89 c2                	mov    %eax,%edx
  1040a3:	8b 45 08             	mov    0x8(%ebp),%eax
  1040a6:	01 d0                	add    %edx,%eax
  1040a8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  1040ab:	0f 85 66 ff ff ff    	jne    104017 <default_init_memmap+0x38>
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    // If the page is free and is the first page of the block, the property should be the size of the (required) block.
    base->property = n;
  1040b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1040b4:	8b 55 0c             	mov    0xc(%ebp),%edx
  1040b7:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
  1040ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1040bd:	83 c0 04             	add    $0x4,%eax
  1040c0:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
  1040c7:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  1040ca:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1040cd:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1040d0:	0f ab 10             	bts    %edx,(%eax)
    nr_free += n;
  1040d3:	8b 15 24 af 11 00    	mov    0x11af24,%edx
  1040d9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1040dc:	01 d0                	add    %edx,%eax
  1040de:	a3 24 af 11 00       	mov    %eax,0x11af24
    // Order by address.
    list_add_before(&free_list, &(base->page_link));
  1040e3:	8b 45 08             	mov    0x8(%ebp),%eax
  1040e6:	83 c0 0c             	add    $0xc,%eax
  1040e9:	c7 45 f0 1c af 11 00 	movl   $0x11af1c,-0x10(%ebp)
  1040f0:	89 45 dc             	mov    %eax,-0x24(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
  1040f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1040f6:	8b 00                	mov    (%eax),%eax
  1040f8:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1040fb:	89 55 d8             	mov    %edx,-0x28(%ebp)
  1040fe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  104101:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104104:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  104107:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10410a:	8b 55 d8             	mov    -0x28(%ebp),%edx
  10410d:	89 10                	mov    %edx,(%eax)
  10410f:	8b 45 d0             	mov    -0x30(%ebp),%eax
  104112:	8b 10                	mov    (%eax),%edx
  104114:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  104117:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  10411a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10411d:	8b 55 d0             	mov    -0x30(%ebp),%edx
  104120:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  104123:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104126:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  104129:	89 10                	mov    %edx,(%eax)
}
  10412b:	90                   	nop
  10412c:	c9                   	leave  
  10412d:	c3                   	ret    

0010412e <default_alloc_pages>:

static struct Page *
default_alloc_pages(size_t n) {
  10412e:	55                   	push   %ebp
  10412f:	89 e5                	mov    %esp,%ebp
  104131:	83 ec 68             	sub    $0x68,%esp
    assert(n > 0);
  104134:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  104138:	75 24                	jne    10415e <default_alloc_pages+0x30>
  10413a:	c7 44 24 0c f8 69 10 	movl   $0x1069f8,0xc(%esp)
  104141:	00 
  104142:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104149:	00 
  10414a:	c7 44 24 04 b0 00 00 	movl   $0xb0,0x4(%esp)
  104151:	00 
  104152:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104159:	e8 8b c2 ff ff       	call   1003e9 <__panic>
    /*
     * The required size n cannot be allocated, because there is no more free memory block.
     */
    if (n > nr_free) {
  10415e:	a1 24 af 11 00       	mov    0x11af24,%eax
  104163:	3b 45 08             	cmp    0x8(%ebp),%eax
  104166:	73 0a                	jae    104172 <default_alloc_pages+0x44>
        return NULL;
  104168:	b8 00 00 00 00       	mov    $0x0,%eax
  10416d:	e9 3d 01 00 00       	jmp    1042af <default_alloc_pages+0x181>
    }
    struct Page *page = NULL; // <- This is the base page of the block, i.e., the identifier of the block.
  104172:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    list_entry_t *le = &free_list;
  104179:	c7 45 f0 1c af 11 00 	movl   $0x11af1c,-0x10(%ebp)
    /* 
     * Haobin Chen.
     * Traverse the free list.
     * If the next memory block to find is the head of the free list, then it means we cannot find any available block.
     */
    while ((le = list_next(le)) != &free_list) {
  104180:	eb 1c                	jmp    10419e <default_alloc_pages+0x70>
        struct Page *p = le2page(le, page_link);
  104182:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104185:	83 e8 0c             	sub    $0xc,%eax
  104188:	89 45 e8             	mov    %eax,-0x18(%ebp)
        if (p->property >= n) {
  10418b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10418e:	8b 40 08             	mov    0x8(%eax),%eax
  104191:	3b 45 08             	cmp    0x8(%ebp),%eax
  104194:	72 08                	jb     10419e <default_alloc_pages+0x70>
            page = p;
  104196:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104199:	89 45 f4             	mov    %eax,-0xc(%ebp)
            break;
  10419c:	eb 18                	jmp    1041b6 <default_alloc_pages+0x88>
  10419e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1041a1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  1041a4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1041a7:	8b 40 04             	mov    0x4(%eax),%eax
    /* 
     * Haobin Chen.
     * Traverse the free list.
     * If the next memory block to find is the head of the free list, then it means we cannot find any available block.
     */
    while ((le = list_next(le)) != &free_list) {
  1041aa:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1041ad:	81 7d f0 1c af 11 00 	cmpl   $0x11af1c,-0x10(%ebp)
  1041b4:	75 cc                	jne    104182 <default_alloc_pages+0x54>
            page = p;
            break;
        }
    }

    if (page != NULL) {
  1041b6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1041ba:	0f 84 ec 00 00 00    	je     1042ac <default_alloc_pages+0x17e>
        // Adjust the allocation step by split block into two.
        // list_del(&(page->page_link));
        if (page->property > n) {
  1041c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1041c3:	8b 40 08             	mov    0x8(%eax),%eax
  1041c6:	3b 45 08             	cmp    0x8(%ebp),%eax
  1041c9:	0f 86 8c 00 00 00    	jbe    10425b <default_alloc_pages+0x12d>
            struct Page *p = page + n;
  1041cf:	8b 55 08             	mov    0x8(%ebp),%edx
  1041d2:	89 d0                	mov    %edx,%eax
  1041d4:	c1 e0 02             	shl    $0x2,%eax
  1041d7:	01 d0                	add    %edx,%eax
  1041d9:	c1 e0 02             	shl    $0x2,%eax
  1041dc:	89 c2                	mov    %eax,%edx
  1041de:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1041e1:	01 d0                	add    %edx,%eax
  1041e3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            p->property = page->property - n;
  1041e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1041e9:	8b 40 08             	mov    0x8(%eax),%eax
  1041ec:	2b 45 08             	sub    0x8(%ebp),%eax
  1041ef:	89 c2                	mov    %eax,%edx
  1041f1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1041f4:	89 50 08             	mov    %edx,0x8(%eax)
            // Apply the property.
            SetPageProperty(p);
  1041f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1041fa:	83 c0 04             	add    $0x4,%eax
  1041fd:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
  104204:	89 45 c0             	mov    %eax,-0x40(%ebp)
  104207:	8b 45 c0             	mov    -0x40(%ebp),%eax
  10420a:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10420d:	0f ab 10             	bts    %edx,(%eax)
            // Split the memory block and append the remainder right behind the current block.
            list_add_after(&(page->page_link), &(p->page_link));
  104210:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104213:	83 c0 0c             	add    $0xc,%eax
  104216:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104219:	83 c2 0c             	add    $0xc,%edx
  10421c:	89 55 ec             	mov    %edx,-0x14(%ebp)
  10421f:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
  104222:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104225:	8b 40 04             	mov    0x4(%eax),%eax
  104228:	8b 55 d0             	mov    -0x30(%ebp),%edx
  10422b:	89 55 cc             	mov    %edx,-0x34(%ebp)
  10422e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104231:	89 55 c8             	mov    %edx,-0x38(%ebp)
  104234:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  104237:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  10423a:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10423d:	89 10                	mov    %edx,(%eax)
  10423f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  104242:	8b 10                	mov    (%eax),%edx
  104244:	8b 45 c8             	mov    -0x38(%ebp),%eax
  104247:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  10424a:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10424d:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  104250:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  104253:	8b 45 cc             	mov    -0x34(%ebp),%eax
  104256:	8b 55 c8             	mov    -0x38(%ebp),%edx
  104259:	89 10                	mov    %edx,(%eax)
        }

        list_del(&(page->page_link));
  10425b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10425e:	83 c0 0c             	add    $0xc,%eax
  104261:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
  104264:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104267:	8b 40 04             	mov    0x4(%eax),%eax
  10426a:	8b 55 d8             	mov    -0x28(%ebp),%edx
  10426d:	8b 12                	mov    (%edx),%edx
  10426f:	89 55 b8             	mov    %edx,-0x48(%ebp)
  104272:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
  104275:	8b 45 b8             	mov    -0x48(%ebp),%eax
  104278:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  10427b:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
  10427e:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  104281:	8b 55 b8             	mov    -0x48(%ebp),%edx
  104284:	89 10                	mov    %edx,(%eax)
        nr_free -= n;
  104286:	a1 24 af 11 00       	mov    0x11af24,%eax
  10428b:	2b 45 08             	sub    0x8(%ebp),%eax
  10428e:	a3 24 af 11 00       	mov    %eax,0x11af24
        ClearPageProperty(page);
  104293:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104296:	83 c0 04             	add    $0x4,%eax
  104299:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
  1042a0:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  1042a3:	8b 45 bc             	mov    -0x44(%ebp),%eax
  1042a6:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1042a9:	0f b3 10             	btr    %edx,(%eax)
    }
    return page;
  1042ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1042af:	c9                   	leave  
  1042b0:	c3                   	ret    

001042b1 <default_free_pages>:

static void
default_free_pages(struct Page *base, size_t n) {
  1042b1:	55                   	push   %ebp
  1042b2:	89 e5                	mov    %esp,%ebp
  1042b4:	81 ec 98 00 00 00    	sub    $0x98,%esp
    assert(n > 0);
  1042ba:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  1042be:	75 24                	jne    1042e4 <default_free_pages+0x33>
  1042c0:	c7 44 24 0c f8 69 10 	movl   $0x1069f8,0xc(%esp)
  1042c7:	00 
  1042c8:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  1042cf:	00 
  1042d0:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  1042d7:	00 
  1042d8:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  1042df:	e8 05 c1 ff ff       	call   1003e9 <__panic>
    struct Page *p = base;
  1042e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1042e7:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
  1042ea:	e9 9d 00 00 00       	jmp    10438c <default_free_pages+0xdb>
        // Reset the pages within the block.
        assert(!PageReserved(p) && !PageProperty(p));
  1042ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1042f2:	83 c0 04             	add    $0x4,%eax
  1042f5:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
  1042fc:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  1042ff:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  104302:	8b 55 b8             	mov    -0x48(%ebp),%edx
  104305:	0f a3 10             	bt     %edx,(%eax)
  104308:	19 c0                	sbb    %eax,%eax
  10430a:	89 45 b0             	mov    %eax,-0x50(%ebp)
    return oldbit != 0;
  10430d:	83 7d b0 00          	cmpl   $0x0,-0x50(%ebp)
  104311:	0f 95 c0             	setne  %al
  104314:	0f b6 c0             	movzbl %al,%eax
  104317:	85 c0                	test   %eax,%eax
  104319:	75 2c                	jne    104347 <default_free_pages+0x96>
  10431b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10431e:	83 c0 04             	add    $0x4,%eax
  104321:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
  104328:	89 45 ac             	mov    %eax,-0x54(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  10432b:	8b 45 ac             	mov    -0x54(%ebp),%eax
  10432e:	8b 55 e8             	mov    -0x18(%ebp),%edx
  104331:	0f a3 10             	bt     %edx,(%eax)
  104334:	19 c0                	sbb    %eax,%eax
  104336:	89 45 a8             	mov    %eax,-0x58(%ebp)
    return oldbit != 0;
  104339:	83 7d a8 00          	cmpl   $0x0,-0x58(%ebp)
  10433d:	0f 95 c0             	setne  %al
  104340:	0f b6 c0             	movzbl %al,%eax
  104343:	85 c0                	test   %eax,%eax
  104345:	74 24                	je     10436b <default_free_pages+0xba>
  104347:	c7 44 24 0c 3c 6a 10 	movl   $0x106a3c,0xc(%esp)
  10434e:	00 
  10434f:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104356:	00 
  104357:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
  10435e:	00 
  10435f:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104366:	e8 7e c0 ff ff       	call   1003e9 <__panic>
        p->flags = 0;
  10436b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10436e:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
        set_page_ref(p, 0);
  104375:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10437c:	00 
  10437d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104380:	89 04 24             	mov    %eax,(%esp)
  104383:	e8 1b fc ff ff       	call   103fa3 <set_page_ref>

static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
  104388:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
  10438c:	8b 55 0c             	mov    0xc(%ebp),%edx
  10438f:	89 d0                	mov    %edx,%eax
  104391:	c1 e0 02             	shl    $0x2,%eax
  104394:	01 d0                	add    %edx,%eax
  104396:	c1 e0 02             	shl    $0x2,%eax
  104399:	89 c2                	mov    %eax,%edx
  10439b:	8b 45 08             	mov    0x8(%ebp),%eax
  10439e:	01 d0                	add    %edx,%eax
  1043a0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  1043a3:	0f 85 46 ff ff ff    	jne    1042ef <default_free_pages+0x3e>
        // Reset the pages within the block.
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
  1043a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1043ac:	8b 55 0c             	mov    0xc(%ebp),%edx
  1043af:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
  1043b2:	8b 45 08             	mov    0x8(%ebp),%eax
  1043b5:	83 c0 04             	add    $0x4,%eax
  1043b8:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
  1043bf:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  1043c2:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  1043c5:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1043c8:	0f ab 10             	bts    %edx,(%eax)
  1043cb:	c7 45 e4 1c af 11 00 	movl   $0x11af1c,-0x1c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  1043d2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1043d5:	8b 40 04             	mov    0x4(%eax),%eax

    list_entry_t *le = list_next(&free_list);
  1043d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
  1043db:	e9 08 01 00 00       	jmp    1044e8 <default_free_pages+0x237>
        // Get the next block and fetch its property by tranforming it to a page pointer.
        p = le2page(le, page_link);
  1043e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1043e3:	83 e8 0c             	sub    $0xc,%eax
  1043e6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1043e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1043ec:	89 45 e0             	mov    %eax,-0x20(%ebp)
  1043ef:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1043f2:	8b 40 04             	mov    0x4(%eax),%eax
        le = list_next(le);
  1043f5:	89 45 f0             	mov    %eax,-0x10(%ebp)

        // Do merge.
        if (base + base->property == p) {
  1043f8:	8b 45 08             	mov    0x8(%ebp),%eax
  1043fb:	8b 50 08             	mov    0x8(%eax),%edx
  1043fe:	89 d0                	mov    %edx,%eax
  104400:	c1 e0 02             	shl    $0x2,%eax
  104403:	01 d0                	add    %edx,%eax
  104405:	c1 e0 02             	shl    $0x2,%eax
  104408:	89 c2                	mov    %eax,%edx
  10440a:	8b 45 08             	mov    0x8(%ebp),%eax
  10440d:	01 d0                	add    %edx,%eax
  10440f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104412:	75 5a                	jne    10446e <default_free_pages+0x1bd>
            // Merge with the next block.
            base->property += p->property;
  104414:	8b 45 08             	mov    0x8(%ebp),%eax
  104417:	8b 50 08             	mov    0x8(%eax),%edx
  10441a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10441d:	8b 40 08             	mov    0x8(%eax),%eax
  104420:	01 c2                	add    %eax,%edx
  104422:	8b 45 08             	mov    0x8(%ebp),%eax
  104425:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(p);
  104428:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10442b:	83 c0 04             	add    $0x4,%eax
  10442e:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  104435:	89 45 98             	mov    %eax,-0x68(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  104438:	8b 45 98             	mov    -0x68(%ebp),%eax
  10443b:	8b 55 d0             	mov    -0x30(%ebp),%edx
  10443e:	0f b3 10             	btr    %edx,(%eax)
            list_del(&(p->page_link));
  104441:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104444:	83 c0 0c             	add    $0xc,%eax
  104447:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
  10444a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10444d:	8b 40 04             	mov    0x4(%eax),%eax
  104450:	8b 55 d8             	mov    -0x28(%ebp),%edx
  104453:	8b 12                	mov    (%edx),%edx
  104455:	89 55 a0             	mov    %edx,-0x60(%ebp)
  104458:	89 45 9c             	mov    %eax,-0x64(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
  10445b:	8b 45 a0             	mov    -0x60(%ebp),%eax
  10445e:	8b 55 9c             	mov    -0x64(%ebp),%edx
  104461:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
  104464:	8b 45 9c             	mov    -0x64(%ebp),%eax
  104467:	8b 55 a0             	mov    -0x60(%ebp),%edx
  10446a:	89 10                	mov    %edx,(%eax)
  10446c:	eb 7a                	jmp    1044e8 <default_free_pages+0x237>
        }
        else if (p + p->property == base) {
  10446e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104471:	8b 50 08             	mov    0x8(%eax),%edx
  104474:	89 d0                	mov    %edx,%eax
  104476:	c1 e0 02             	shl    $0x2,%eax
  104479:	01 d0                	add    %edx,%eax
  10447b:	c1 e0 02             	shl    $0x2,%eax
  10447e:	89 c2                	mov    %eax,%edx
  104480:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104483:	01 d0                	add    %edx,%eax
  104485:	3b 45 08             	cmp    0x8(%ebp),%eax
  104488:	75 5e                	jne    1044e8 <default_free_pages+0x237>
            // Merge with the previous block.
            p->property += base->property;
  10448a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10448d:	8b 50 08             	mov    0x8(%eax),%edx
  104490:	8b 45 08             	mov    0x8(%ebp),%eax
  104493:	8b 40 08             	mov    0x8(%eax),%eax
  104496:	01 c2                	add    %eax,%edx
  104498:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10449b:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(base);
  10449e:	8b 45 08             	mov    0x8(%ebp),%eax
  1044a1:	83 c0 04             	add    $0x4,%eax
  1044a4:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
  1044ab:	89 45 8c             	mov    %eax,-0x74(%ebp)
  1044ae:	8b 45 8c             	mov    -0x74(%ebp),%eax
  1044b1:	8b 55 c8             	mov    -0x38(%ebp),%edx
  1044b4:	0f b3 10             	btr    %edx,(%eax)
            base = p;
  1044b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1044ba:	89 45 08             	mov    %eax,0x8(%ebp)
            list_del(&(p->page_link));
  1044bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1044c0:	83 c0 0c             	add    $0xc,%eax
  1044c3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
  1044c6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1044c9:	8b 40 04             	mov    0x4(%eax),%eax
  1044cc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1044cf:	8b 12                	mov    (%edx),%edx
  1044d1:	89 55 94             	mov    %edx,-0x6c(%ebp)
  1044d4:	89 45 90             	mov    %eax,-0x70(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
  1044d7:	8b 45 94             	mov    -0x6c(%ebp),%eax
  1044da:	8b 55 90             	mov    -0x70(%ebp),%edx
  1044dd:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
  1044e0:	8b 45 90             	mov    -0x70(%ebp),%eax
  1044e3:	8b 55 94             	mov    -0x6c(%ebp),%edx
  1044e6:	89 10                	mov    %edx,(%eax)
    }
    base->property = n;
    SetPageProperty(base);

    list_entry_t *le = list_next(&free_list);
    while (le != &free_list) {
  1044e8:	81 7d f0 1c af 11 00 	cmpl   $0x11af1c,-0x10(%ebp)
  1044ef:	0f 85 eb fe ff ff    	jne    1043e0 <default_free_pages+0x12f>
  1044f5:	c7 45 cc 1c af 11 00 	movl   $0x11af1c,-0x34(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  1044fc:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1044ff:	8b 40 04             	mov    0x4(%eax),%eax
    /*
     * Haobin Chen.
     * 
     * Find the right place to insert.
     */
    list_entry_t *ptr = list_next(&free_list);
  104502:	89 45 ec             	mov    %eax,-0x14(%ebp)
    while (ptr != &free_list) {
  104505:	eb 34                	jmp    10453b <default_free_pages+0x28a>
         * le2page receives two parameters to convert a struct to another. The second parameter
         * means the member to be the first parameter.
         * 
         * E.g. Current page's page_link member will be the first parameter: ptr (which is the current block to be accessed).
         */
        struct Page *cur = le2page(ptr, page_link);
  104507:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10450a:	83 e8 0c             	sub    $0xc,%eax
  10450d:	89 45 c0             	mov    %eax,-0x40(%ebp)
        if (base + base->property < cur) {
  104510:	8b 45 08             	mov    0x8(%ebp),%eax
  104513:	8b 50 08             	mov    0x8(%eax),%edx
  104516:	89 d0                	mov    %edx,%eax
  104518:	c1 e0 02             	shl    $0x2,%eax
  10451b:	01 d0                	add    %edx,%eax
  10451d:	c1 e0 02             	shl    $0x2,%eax
  104520:	89 c2                	mov    %eax,%edx
  104522:	8b 45 08             	mov    0x8(%ebp),%eax
  104525:	01 d0                	add    %edx,%eax
  104527:	3b 45 c0             	cmp    -0x40(%ebp),%eax
  10452a:	72 1a                	jb     104546 <default_free_pages+0x295>
  10452c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10452f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
  104532:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  104535:	8b 40 04             	mov    0x4(%eax),%eax
            break;
        }
        ptr = list_next(ptr);
  104538:	89 45 ec             	mov    %eax,-0x14(%ebp)
     * Haobin Chen.
     * 
     * Find the right place to insert.
     */
    list_entry_t *ptr = list_next(&free_list);
    while (ptr != &free_list) {
  10453b:	81 7d ec 1c af 11 00 	cmpl   $0x11af1c,-0x14(%ebp)
  104542:	75 c3                	jne    104507 <default_free_pages+0x256>
  104544:	eb 01                	jmp    104547 <default_free_pages+0x296>
         * 
         * E.g. Current page's page_link member will be the first parameter: ptr (which is the current block to be accessed).
         */
        struct Page *cur = le2page(ptr, page_link);
        if (base + base->property < cur) {
            break;
  104546:	90                   	nop
        }
        ptr = list_next(ptr);
    }

    list_add_before(ptr, &(base->page_link));
  104547:	8b 45 08             	mov    0x8(%ebp),%eax
  10454a:	8d 50 0c             	lea    0xc(%eax),%edx
  10454d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104550:	89 45 bc             	mov    %eax,-0x44(%ebp)
  104553:	89 55 88             	mov    %edx,-0x78(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
  104556:	8b 45 bc             	mov    -0x44(%ebp),%eax
  104559:	8b 00                	mov    (%eax),%eax
  10455b:	8b 55 88             	mov    -0x78(%ebp),%edx
  10455e:	89 55 84             	mov    %edx,-0x7c(%ebp)
  104561:	89 45 80             	mov    %eax,-0x80(%ebp)
  104564:	8b 45 bc             	mov    -0x44(%ebp),%eax
  104567:	89 85 7c ff ff ff    	mov    %eax,-0x84(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  10456d:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  104573:	8b 55 84             	mov    -0x7c(%ebp),%edx
  104576:	89 10                	mov    %edx,(%eax)
  104578:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  10457e:	8b 10                	mov    (%eax),%edx
  104580:	8b 45 80             	mov    -0x80(%ebp),%eax
  104583:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  104586:	8b 45 84             	mov    -0x7c(%ebp),%eax
  104589:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  10458f:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  104592:	8b 45 84             	mov    -0x7c(%ebp),%eax
  104595:	8b 55 80             	mov    -0x80(%ebp),%edx
  104598:	89 10                	mov    %edx,(%eax)
    nr_free += n;
  10459a:	8b 15 24 af 11 00    	mov    0x11af24,%edx
  1045a0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1045a3:	01 d0                	add    %edx,%eax
  1045a5:	a3 24 af 11 00       	mov    %eax,0x11af24

    //list_add_before(&free_list, &(base->page_link));
}
  1045aa:	90                   	nop
  1045ab:	c9                   	leave  
  1045ac:	c3                   	ret    

001045ad <default_nr_free_pages>:

static size_t
default_nr_free_pages(void) {
  1045ad:	55                   	push   %ebp
  1045ae:	89 e5                	mov    %esp,%ebp
    return nr_free;
  1045b0:	a1 24 af 11 00       	mov    0x11af24,%eax
}
  1045b5:	5d                   	pop    %ebp
  1045b6:	c3                   	ret    

001045b7 <basic_check>:

static void
basic_check(void) {
  1045b7:	55                   	push   %ebp
  1045b8:	89 e5                	mov    %esp,%ebp
  1045ba:	83 ec 48             	sub    $0x48,%esp
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
  1045bd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1045c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1045c7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1045ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1045cd:	89 45 ec             	mov    %eax,-0x14(%ebp)
    assert((p0 = alloc_page()) != NULL);
  1045d0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1045d7:	e8 76 e3 ff ff       	call   102952 <alloc_pages>
  1045dc:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1045df:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1045e3:	75 24                	jne    104609 <basic_check+0x52>
  1045e5:	c7 44 24 0c 61 6a 10 	movl   $0x106a61,0xc(%esp)
  1045ec:	00 
  1045ed:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  1045f4:	00 
  1045f5:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
  1045fc:	00 
  1045fd:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104604:	e8 e0 bd ff ff       	call   1003e9 <__panic>
    assert((p1 = alloc_page()) != NULL);
  104609:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104610:	e8 3d e3 ff ff       	call   102952 <alloc_pages>
  104615:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104618:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  10461c:	75 24                	jne    104642 <basic_check+0x8b>
  10461e:	c7 44 24 0c 7d 6a 10 	movl   $0x106a7d,0xc(%esp)
  104625:	00 
  104626:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  10462d:	00 
  10462e:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
  104635:	00 
  104636:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  10463d:	e8 a7 bd ff ff       	call   1003e9 <__panic>
    assert((p2 = alloc_page()) != NULL);
  104642:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104649:	e8 04 e3 ff ff       	call   102952 <alloc_pages>
  10464e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104651:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  104655:	75 24                	jne    10467b <basic_check+0xc4>
  104657:	c7 44 24 0c 99 6a 10 	movl   $0x106a99,0xc(%esp)
  10465e:	00 
  10465f:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104666:	00 
  104667:	c7 44 24 04 23 01 00 	movl   $0x123,0x4(%esp)
  10466e:	00 
  10466f:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104676:	e8 6e bd ff ff       	call   1003e9 <__panic>

    assert(p0 != p1 && p0 != p2 && p1 != p2);
  10467b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10467e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104681:	74 10                	je     104693 <basic_check+0xdc>
  104683:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104686:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104689:	74 08                	je     104693 <basic_check+0xdc>
  10468b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10468e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104691:	75 24                	jne    1046b7 <basic_check+0x100>
  104693:	c7 44 24 0c b8 6a 10 	movl   $0x106ab8,0xc(%esp)
  10469a:	00 
  10469b:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  1046a2:	00 
  1046a3:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
  1046aa:	00 
  1046ab:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  1046b2:	e8 32 bd ff ff       	call   1003e9 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
  1046b7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1046ba:	89 04 24             	mov    %eax,(%esp)
  1046bd:	e8 d7 f8 ff ff       	call   103f99 <page_ref>
  1046c2:	85 c0                	test   %eax,%eax
  1046c4:	75 1e                	jne    1046e4 <basic_check+0x12d>
  1046c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1046c9:	89 04 24             	mov    %eax,(%esp)
  1046cc:	e8 c8 f8 ff ff       	call   103f99 <page_ref>
  1046d1:	85 c0                	test   %eax,%eax
  1046d3:	75 0f                	jne    1046e4 <basic_check+0x12d>
  1046d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1046d8:	89 04 24             	mov    %eax,(%esp)
  1046db:	e8 b9 f8 ff ff       	call   103f99 <page_ref>
  1046e0:	85 c0                	test   %eax,%eax
  1046e2:	74 24                	je     104708 <basic_check+0x151>
  1046e4:	c7 44 24 0c dc 6a 10 	movl   $0x106adc,0xc(%esp)
  1046eb:	00 
  1046ec:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  1046f3:	00 
  1046f4:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
  1046fb:	00 
  1046fc:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104703:	e8 e1 bc ff ff       	call   1003e9 <__panic>

    assert(page2pa(p0) < npage * PGSIZE);
  104708:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10470b:	89 04 24             	mov    %eax,(%esp)
  10470e:	e8 70 f8 ff ff       	call   103f83 <page2pa>
  104713:	8b 15 80 ae 11 00    	mov    0x11ae80,%edx
  104719:	c1 e2 0c             	shl    $0xc,%edx
  10471c:	39 d0                	cmp    %edx,%eax
  10471e:	72 24                	jb     104744 <basic_check+0x18d>
  104720:	c7 44 24 0c 18 6b 10 	movl   $0x106b18,0xc(%esp)
  104727:	00 
  104728:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  10472f:	00 
  104730:	c7 44 24 04 28 01 00 	movl   $0x128,0x4(%esp)
  104737:	00 
  104738:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  10473f:	e8 a5 bc ff ff       	call   1003e9 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
  104744:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104747:	89 04 24             	mov    %eax,(%esp)
  10474a:	e8 34 f8 ff ff       	call   103f83 <page2pa>
  10474f:	8b 15 80 ae 11 00    	mov    0x11ae80,%edx
  104755:	c1 e2 0c             	shl    $0xc,%edx
  104758:	39 d0                	cmp    %edx,%eax
  10475a:	72 24                	jb     104780 <basic_check+0x1c9>
  10475c:	c7 44 24 0c 35 6b 10 	movl   $0x106b35,0xc(%esp)
  104763:	00 
  104764:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  10476b:	00 
  10476c:	c7 44 24 04 29 01 00 	movl   $0x129,0x4(%esp)
  104773:	00 
  104774:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  10477b:	e8 69 bc ff ff       	call   1003e9 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
  104780:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104783:	89 04 24             	mov    %eax,(%esp)
  104786:	e8 f8 f7 ff ff       	call   103f83 <page2pa>
  10478b:	8b 15 80 ae 11 00    	mov    0x11ae80,%edx
  104791:	c1 e2 0c             	shl    $0xc,%edx
  104794:	39 d0                	cmp    %edx,%eax
  104796:	72 24                	jb     1047bc <basic_check+0x205>
  104798:	c7 44 24 0c 52 6b 10 	movl   $0x106b52,0xc(%esp)
  10479f:	00 
  1047a0:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  1047a7:	00 
  1047a8:	c7 44 24 04 2a 01 00 	movl   $0x12a,0x4(%esp)
  1047af:	00 
  1047b0:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  1047b7:	e8 2d bc ff ff       	call   1003e9 <__panic>

    list_entry_t free_list_store = free_list;
  1047bc:	a1 1c af 11 00       	mov    0x11af1c,%eax
  1047c1:	8b 15 20 af 11 00    	mov    0x11af20,%edx
  1047c7:	89 45 d0             	mov    %eax,-0x30(%ebp)
  1047ca:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  1047cd:	c7 45 e4 1c af 11 00 	movl   $0x11af1c,-0x1c(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
  1047d4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1047d7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1047da:	89 50 04             	mov    %edx,0x4(%eax)
  1047dd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1047e0:	8b 50 04             	mov    0x4(%eax),%edx
  1047e3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1047e6:	89 10                	mov    %edx,(%eax)
  1047e8:	c7 45 d8 1c af 11 00 	movl   $0x11af1c,-0x28(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
  1047ef:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1047f2:	8b 40 04             	mov    0x4(%eax),%eax
  1047f5:	39 45 d8             	cmp    %eax,-0x28(%ebp)
  1047f8:	0f 94 c0             	sete   %al
  1047fb:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
  1047fe:	85 c0                	test   %eax,%eax
  104800:	75 24                	jne    104826 <basic_check+0x26f>
  104802:	c7 44 24 0c 6f 6b 10 	movl   $0x106b6f,0xc(%esp)
  104809:	00 
  10480a:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104811:	00 
  104812:	c7 44 24 04 2e 01 00 	movl   $0x12e,0x4(%esp)
  104819:	00 
  10481a:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104821:	e8 c3 bb ff ff       	call   1003e9 <__panic>

    unsigned int nr_free_store = nr_free;
  104826:	a1 24 af 11 00       	mov    0x11af24,%eax
  10482b:	89 45 e0             	mov    %eax,-0x20(%ebp)
    nr_free = 0;
  10482e:	c7 05 24 af 11 00 00 	movl   $0x0,0x11af24
  104835:	00 00 00 

    assert(alloc_page() == NULL);
  104838:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10483f:	e8 0e e1 ff ff       	call   102952 <alloc_pages>
  104844:	85 c0                	test   %eax,%eax
  104846:	74 24                	je     10486c <basic_check+0x2b5>
  104848:	c7 44 24 0c 86 6b 10 	movl   $0x106b86,0xc(%esp)
  10484f:	00 
  104850:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104857:	00 
  104858:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
  10485f:	00 
  104860:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104867:	e8 7d bb ff ff       	call   1003e9 <__panic>

    free_page(p0);
  10486c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104873:	00 
  104874:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104877:	89 04 24             	mov    %eax,(%esp)
  10487a:	e8 0b e1 ff ff       	call   10298a <free_pages>
    free_page(p1);
  10487f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104886:	00 
  104887:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10488a:	89 04 24             	mov    %eax,(%esp)
  10488d:	e8 f8 e0 ff ff       	call   10298a <free_pages>
    free_page(p2);
  104892:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104899:	00 
  10489a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10489d:	89 04 24             	mov    %eax,(%esp)
  1048a0:	e8 e5 e0 ff ff       	call   10298a <free_pages>
    assert(nr_free == 3);
  1048a5:	a1 24 af 11 00       	mov    0x11af24,%eax
  1048aa:	83 f8 03             	cmp    $0x3,%eax
  1048ad:	74 24                	je     1048d3 <basic_check+0x31c>
  1048af:	c7 44 24 0c 9b 6b 10 	movl   $0x106b9b,0xc(%esp)
  1048b6:	00 
  1048b7:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  1048be:	00 
  1048bf:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
  1048c6:	00 
  1048c7:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  1048ce:	e8 16 bb ff ff       	call   1003e9 <__panic>

    assert((p0 = alloc_page()) != NULL);
  1048d3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1048da:	e8 73 e0 ff ff       	call   102952 <alloc_pages>
  1048df:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1048e2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1048e6:	75 24                	jne    10490c <basic_check+0x355>
  1048e8:	c7 44 24 0c 61 6a 10 	movl   $0x106a61,0xc(%esp)
  1048ef:	00 
  1048f0:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  1048f7:	00 
  1048f8:	c7 44 24 04 3a 01 00 	movl   $0x13a,0x4(%esp)
  1048ff:	00 
  104900:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104907:	e8 dd ba ff ff       	call   1003e9 <__panic>
    assert((p1 = alloc_page()) != NULL);
  10490c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104913:	e8 3a e0 ff ff       	call   102952 <alloc_pages>
  104918:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10491b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  10491f:	75 24                	jne    104945 <basic_check+0x38e>
  104921:	c7 44 24 0c 7d 6a 10 	movl   $0x106a7d,0xc(%esp)
  104928:	00 
  104929:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104930:	00 
  104931:	c7 44 24 04 3b 01 00 	movl   $0x13b,0x4(%esp)
  104938:	00 
  104939:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104940:	e8 a4 ba ff ff       	call   1003e9 <__panic>
    assert((p2 = alloc_page()) != NULL);
  104945:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10494c:	e8 01 e0 ff ff       	call   102952 <alloc_pages>
  104951:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104954:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  104958:	75 24                	jne    10497e <basic_check+0x3c7>
  10495a:	c7 44 24 0c 99 6a 10 	movl   $0x106a99,0xc(%esp)
  104961:	00 
  104962:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104969:	00 
  10496a:	c7 44 24 04 3c 01 00 	movl   $0x13c,0x4(%esp)
  104971:	00 
  104972:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104979:	e8 6b ba ff ff       	call   1003e9 <__panic>

    assert(alloc_page() == NULL);
  10497e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104985:	e8 c8 df ff ff       	call   102952 <alloc_pages>
  10498a:	85 c0                	test   %eax,%eax
  10498c:	74 24                	je     1049b2 <basic_check+0x3fb>
  10498e:	c7 44 24 0c 86 6b 10 	movl   $0x106b86,0xc(%esp)
  104995:	00 
  104996:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  10499d:	00 
  10499e:	c7 44 24 04 3e 01 00 	movl   $0x13e,0x4(%esp)
  1049a5:	00 
  1049a6:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  1049ad:	e8 37 ba ff ff       	call   1003e9 <__panic>

    free_page(p0);
  1049b2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1049b9:	00 
  1049ba:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1049bd:	89 04 24             	mov    %eax,(%esp)
  1049c0:	e8 c5 df ff ff       	call   10298a <free_pages>
  1049c5:	c7 45 e8 1c af 11 00 	movl   $0x11af1c,-0x18(%ebp)
  1049cc:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1049cf:	8b 40 04             	mov    0x4(%eax),%eax
  1049d2:	39 45 e8             	cmp    %eax,-0x18(%ebp)
  1049d5:	0f 94 c0             	sete   %al
  1049d8:	0f b6 c0             	movzbl %al,%eax
    assert(!list_empty(&free_list));
  1049db:	85 c0                	test   %eax,%eax
  1049dd:	74 24                	je     104a03 <basic_check+0x44c>
  1049df:	c7 44 24 0c a8 6b 10 	movl   $0x106ba8,0xc(%esp)
  1049e6:	00 
  1049e7:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  1049ee:	00 
  1049ef:	c7 44 24 04 41 01 00 	movl   $0x141,0x4(%esp)
  1049f6:	00 
  1049f7:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  1049fe:	e8 e6 b9 ff ff       	call   1003e9 <__panic>

    struct Page *p;
    assert((p = alloc_page()) == p0);
  104a03:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104a0a:	e8 43 df ff ff       	call   102952 <alloc_pages>
  104a0f:	89 45 dc             	mov    %eax,-0x24(%ebp)
  104a12:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104a15:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  104a18:	74 24                	je     104a3e <basic_check+0x487>
  104a1a:	c7 44 24 0c c0 6b 10 	movl   $0x106bc0,0xc(%esp)
  104a21:	00 
  104a22:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104a29:	00 
  104a2a:	c7 44 24 04 44 01 00 	movl   $0x144,0x4(%esp)
  104a31:	00 
  104a32:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104a39:	e8 ab b9 ff ff       	call   1003e9 <__panic>
    assert(alloc_page() == NULL);
  104a3e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104a45:	e8 08 df ff ff       	call   102952 <alloc_pages>
  104a4a:	85 c0                	test   %eax,%eax
  104a4c:	74 24                	je     104a72 <basic_check+0x4bb>
  104a4e:	c7 44 24 0c 86 6b 10 	movl   $0x106b86,0xc(%esp)
  104a55:	00 
  104a56:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104a5d:	00 
  104a5e:	c7 44 24 04 45 01 00 	movl   $0x145,0x4(%esp)
  104a65:	00 
  104a66:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104a6d:	e8 77 b9 ff ff       	call   1003e9 <__panic>

    assert(nr_free == 0);
  104a72:	a1 24 af 11 00       	mov    0x11af24,%eax
  104a77:	85 c0                	test   %eax,%eax
  104a79:	74 24                	je     104a9f <basic_check+0x4e8>
  104a7b:	c7 44 24 0c d9 6b 10 	movl   $0x106bd9,0xc(%esp)
  104a82:	00 
  104a83:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104a8a:	00 
  104a8b:	c7 44 24 04 47 01 00 	movl   $0x147,0x4(%esp)
  104a92:	00 
  104a93:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104a9a:	e8 4a b9 ff ff       	call   1003e9 <__panic>
    free_list = free_list_store;
  104a9f:	8b 45 d0             	mov    -0x30(%ebp),%eax
  104aa2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  104aa5:	a3 1c af 11 00       	mov    %eax,0x11af1c
  104aaa:	89 15 20 af 11 00    	mov    %edx,0x11af20
    nr_free = nr_free_store;
  104ab0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104ab3:	a3 24 af 11 00       	mov    %eax,0x11af24

    free_page(p);
  104ab8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104abf:	00 
  104ac0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104ac3:	89 04 24             	mov    %eax,(%esp)
  104ac6:	e8 bf de ff ff       	call   10298a <free_pages>
    free_page(p1);
  104acb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104ad2:	00 
  104ad3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104ad6:	89 04 24             	mov    %eax,(%esp)
  104ad9:	e8 ac de ff ff       	call   10298a <free_pages>
    free_page(p2);
  104ade:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104ae5:	00 
  104ae6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104ae9:	89 04 24             	mov    %eax,(%esp)
  104aec:	e8 99 de ff ff       	call   10298a <free_pages>
}
  104af1:	90                   	nop
  104af2:	c9                   	leave  
  104af3:	c3                   	ret    

00104af4 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
  104af4:	55                   	push   %ebp
  104af5:	89 e5                	mov    %esp,%ebp
  104af7:	81 ec 98 00 00 00    	sub    $0x98,%esp
    int count = 0, total = 0;
  104afd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  104b04:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    list_entry_t *le = &free_list;
  104b0b:	c7 45 ec 1c af 11 00 	movl   $0x11af1c,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
  104b12:	eb 6a                	jmp    104b7e <default_check+0x8a>
        struct Page *p = le2page(le, page_link);
  104b14:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104b17:	83 e8 0c             	sub    $0xc,%eax
  104b1a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        assert(PageProperty(p));
  104b1d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104b20:	83 c0 04             	add    $0x4,%eax
  104b23:	c7 45 b0 01 00 00 00 	movl   $0x1,-0x50(%ebp)
  104b2a:	89 45 ac             	mov    %eax,-0x54(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104b2d:	8b 45 ac             	mov    -0x54(%ebp),%eax
  104b30:	8b 55 b0             	mov    -0x50(%ebp),%edx
  104b33:	0f a3 10             	bt     %edx,(%eax)
  104b36:	19 c0                	sbb    %eax,%eax
  104b38:	89 45 a8             	mov    %eax,-0x58(%ebp)
    return oldbit != 0;
  104b3b:	83 7d a8 00          	cmpl   $0x0,-0x58(%ebp)
  104b3f:	0f 95 c0             	setne  %al
  104b42:	0f b6 c0             	movzbl %al,%eax
  104b45:	85 c0                	test   %eax,%eax
  104b47:	75 24                	jne    104b6d <default_check+0x79>
  104b49:	c7 44 24 0c e6 6b 10 	movl   $0x106be6,0xc(%esp)
  104b50:	00 
  104b51:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104b58:	00 
  104b59:	c7 44 24 04 58 01 00 	movl   $0x158,0x4(%esp)
  104b60:	00 
  104b61:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104b68:	e8 7c b8 ff ff       	call   1003e9 <__panic>
        count ++, total += p->property;
  104b6d:	ff 45 f4             	incl   -0xc(%ebp)
  104b70:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104b73:	8b 50 08             	mov    0x8(%eax),%edx
  104b76:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104b79:	01 d0                	add    %edx,%eax
  104b7b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104b7e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104b81:	89 45 e0             	mov    %eax,-0x20(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  104b84:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104b87:	8b 40 04             	mov    0x4(%eax),%eax
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
  104b8a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  104b8d:	81 7d ec 1c af 11 00 	cmpl   $0x11af1c,-0x14(%ebp)
  104b94:	0f 85 7a ff ff ff    	jne    104b14 <default_check+0x20>
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());
  104b9a:	e8 1e de ff ff       	call   1029bd <nr_free_pages>
  104b9f:	89 c2                	mov    %eax,%edx
  104ba1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104ba4:	39 c2                	cmp    %eax,%edx
  104ba6:	74 24                	je     104bcc <default_check+0xd8>
  104ba8:	c7 44 24 0c f6 6b 10 	movl   $0x106bf6,0xc(%esp)
  104baf:	00 
  104bb0:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104bb7:	00 
  104bb8:	c7 44 24 04 5b 01 00 	movl   $0x15b,0x4(%esp)
  104bbf:	00 
  104bc0:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104bc7:	e8 1d b8 ff ff       	call   1003e9 <__panic>

    basic_check();
  104bcc:	e8 e6 f9 ff ff       	call   1045b7 <basic_check>

    struct Page *p0 = alloc_pages(5), *p1, *p2;
  104bd1:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
  104bd8:	e8 75 dd ff ff       	call   102952 <alloc_pages>
  104bdd:	89 45 dc             	mov    %eax,-0x24(%ebp)
    assert(p0 != NULL);
  104be0:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  104be4:	75 24                	jne    104c0a <default_check+0x116>
  104be6:	c7 44 24 0c 0f 6c 10 	movl   $0x106c0f,0xc(%esp)
  104bed:	00 
  104bee:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104bf5:	00 
  104bf6:	c7 44 24 04 60 01 00 	movl   $0x160,0x4(%esp)
  104bfd:	00 
  104bfe:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104c05:	e8 df b7 ff ff       	call   1003e9 <__panic>
    assert(!PageProperty(p0));
  104c0a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104c0d:	83 c0 04             	add    $0x4,%eax
  104c10:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
  104c17:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104c1a:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  104c1d:	8b 55 e8             	mov    -0x18(%ebp),%edx
  104c20:	0f a3 10             	bt     %edx,(%eax)
  104c23:	19 c0                	sbb    %eax,%eax
  104c25:	89 45 a0             	mov    %eax,-0x60(%ebp)
    return oldbit != 0;
  104c28:	83 7d a0 00          	cmpl   $0x0,-0x60(%ebp)
  104c2c:	0f 95 c0             	setne  %al
  104c2f:	0f b6 c0             	movzbl %al,%eax
  104c32:	85 c0                	test   %eax,%eax
  104c34:	74 24                	je     104c5a <default_check+0x166>
  104c36:	c7 44 24 0c 1a 6c 10 	movl   $0x106c1a,0xc(%esp)
  104c3d:	00 
  104c3e:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104c45:	00 
  104c46:	c7 44 24 04 61 01 00 	movl   $0x161,0x4(%esp)
  104c4d:	00 
  104c4e:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104c55:	e8 8f b7 ff ff       	call   1003e9 <__panic>

    list_entry_t free_list_store = free_list;
  104c5a:	a1 1c af 11 00       	mov    0x11af1c,%eax
  104c5f:	8b 15 20 af 11 00    	mov    0x11af20,%edx
  104c65:	89 45 80             	mov    %eax,-0x80(%ebp)
  104c68:	89 55 84             	mov    %edx,-0x7c(%ebp)
  104c6b:	c7 45 d0 1c af 11 00 	movl   $0x11af1c,-0x30(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
  104c72:	8b 45 d0             	mov    -0x30(%ebp),%eax
  104c75:	8b 55 d0             	mov    -0x30(%ebp),%edx
  104c78:	89 50 04             	mov    %edx,0x4(%eax)
  104c7b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  104c7e:	8b 50 04             	mov    0x4(%eax),%edx
  104c81:	8b 45 d0             	mov    -0x30(%ebp),%eax
  104c84:	89 10                	mov    %edx,(%eax)
  104c86:	c7 45 d8 1c af 11 00 	movl   $0x11af1c,-0x28(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
  104c8d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104c90:	8b 40 04             	mov    0x4(%eax),%eax
  104c93:	39 45 d8             	cmp    %eax,-0x28(%ebp)
  104c96:	0f 94 c0             	sete   %al
  104c99:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
  104c9c:	85 c0                	test   %eax,%eax
  104c9e:	75 24                	jne    104cc4 <default_check+0x1d0>
  104ca0:	c7 44 24 0c 6f 6b 10 	movl   $0x106b6f,0xc(%esp)
  104ca7:	00 
  104ca8:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104caf:	00 
  104cb0:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
  104cb7:	00 
  104cb8:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104cbf:	e8 25 b7 ff ff       	call   1003e9 <__panic>
    assert(alloc_page() == NULL);
  104cc4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104ccb:	e8 82 dc ff ff       	call   102952 <alloc_pages>
  104cd0:	85 c0                	test   %eax,%eax
  104cd2:	74 24                	je     104cf8 <default_check+0x204>
  104cd4:	c7 44 24 0c 86 6b 10 	movl   $0x106b86,0xc(%esp)
  104cdb:	00 
  104cdc:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104ce3:	00 
  104ce4:	c7 44 24 04 66 01 00 	movl   $0x166,0x4(%esp)
  104ceb:	00 
  104cec:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104cf3:	e8 f1 b6 ff ff       	call   1003e9 <__panic>

    unsigned int nr_free_store = nr_free;
  104cf8:	a1 24 af 11 00       	mov    0x11af24,%eax
  104cfd:	89 45 cc             	mov    %eax,-0x34(%ebp)
    nr_free = 0;
  104d00:	c7 05 24 af 11 00 00 	movl   $0x0,0x11af24
  104d07:	00 00 00 

    free_pages(p0 + 2, 3);
  104d0a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104d0d:	83 c0 28             	add    $0x28,%eax
  104d10:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
  104d17:	00 
  104d18:	89 04 24             	mov    %eax,(%esp)
  104d1b:	e8 6a dc ff ff       	call   10298a <free_pages>
    assert(alloc_pages(4) == NULL);
  104d20:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  104d27:	e8 26 dc ff ff       	call   102952 <alloc_pages>
  104d2c:	85 c0                	test   %eax,%eax
  104d2e:	74 24                	je     104d54 <default_check+0x260>
  104d30:	c7 44 24 0c 2c 6c 10 	movl   $0x106c2c,0xc(%esp)
  104d37:	00 
  104d38:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104d3f:	00 
  104d40:	c7 44 24 04 6c 01 00 	movl   $0x16c,0x4(%esp)
  104d47:	00 
  104d48:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104d4f:	e8 95 b6 ff ff       	call   1003e9 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
  104d54:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104d57:	83 c0 28             	add    $0x28,%eax
  104d5a:	83 c0 04             	add    $0x4,%eax
  104d5d:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  104d64:	89 45 9c             	mov    %eax,-0x64(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104d67:	8b 45 9c             	mov    -0x64(%ebp),%eax
  104d6a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  104d6d:	0f a3 10             	bt     %edx,(%eax)
  104d70:	19 c0                	sbb    %eax,%eax
  104d72:	89 45 98             	mov    %eax,-0x68(%ebp)
    return oldbit != 0;
  104d75:	83 7d 98 00          	cmpl   $0x0,-0x68(%ebp)
  104d79:	0f 95 c0             	setne  %al
  104d7c:	0f b6 c0             	movzbl %al,%eax
  104d7f:	85 c0                	test   %eax,%eax
  104d81:	74 0e                	je     104d91 <default_check+0x29d>
  104d83:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104d86:	83 c0 28             	add    $0x28,%eax
  104d89:	8b 40 08             	mov    0x8(%eax),%eax
  104d8c:	83 f8 03             	cmp    $0x3,%eax
  104d8f:	74 24                	je     104db5 <default_check+0x2c1>
  104d91:	c7 44 24 0c 44 6c 10 	movl   $0x106c44,0xc(%esp)
  104d98:	00 
  104d99:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104da0:	00 
  104da1:	c7 44 24 04 6d 01 00 	movl   $0x16d,0x4(%esp)
  104da8:	00 
  104da9:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104db0:	e8 34 b6 ff ff       	call   1003e9 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
  104db5:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
  104dbc:	e8 91 db ff ff       	call   102952 <alloc_pages>
  104dc1:	89 45 c4             	mov    %eax,-0x3c(%ebp)
  104dc4:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
  104dc8:	75 24                	jne    104dee <default_check+0x2fa>
  104dca:	c7 44 24 0c 70 6c 10 	movl   $0x106c70,0xc(%esp)
  104dd1:	00 
  104dd2:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104dd9:	00 
  104dda:	c7 44 24 04 6e 01 00 	movl   $0x16e,0x4(%esp)
  104de1:	00 
  104de2:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104de9:	e8 fb b5 ff ff       	call   1003e9 <__panic>
    assert(alloc_page() == NULL);
  104dee:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104df5:	e8 58 db ff ff       	call   102952 <alloc_pages>
  104dfa:	85 c0                	test   %eax,%eax
  104dfc:	74 24                	je     104e22 <default_check+0x32e>
  104dfe:	c7 44 24 0c 86 6b 10 	movl   $0x106b86,0xc(%esp)
  104e05:	00 
  104e06:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104e0d:	00 
  104e0e:	c7 44 24 04 6f 01 00 	movl   $0x16f,0x4(%esp)
  104e15:	00 
  104e16:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104e1d:	e8 c7 b5 ff ff       	call   1003e9 <__panic>
    assert(p0 + 2 == p1);
  104e22:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104e25:	83 c0 28             	add    $0x28,%eax
  104e28:	3b 45 c4             	cmp    -0x3c(%ebp),%eax
  104e2b:	74 24                	je     104e51 <default_check+0x35d>
  104e2d:	c7 44 24 0c 8e 6c 10 	movl   $0x106c8e,0xc(%esp)
  104e34:	00 
  104e35:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104e3c:	00 
  104e3d:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
  104e44:	00 
  104e45:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104e4c:	e8 98 b5 ff ff       	call   1003e9 <__panic>

    p2 = p0 + 1;
  104e51:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104e54:	83 c0 14             	add    $0x14,%eax
  104e57:	89 45 c0             	mov    %eax,-0x40(%ebp)
    free_page(p0);
  104e5a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104e61:	00 
  104e62:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104e65:	89 04 24             	mov    %eax,(%esp)
  104e68:	e8 1d db ff ff       	call   10298a <free_pages>
    free_pages(p1, 3);
  104e6d:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
  104e74:	00 
  104e75:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  104e78:	89 04 24             	mov    %eax,(%esp)
  104e7b:	e8 0a db ff ff       	call   10298a <free_pages>
    assert(PageProperty(p0) && p0->property == 1);
  104e80:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104e83:	83 c0 04             	add    $0x4,%eax
  104e86:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
  104e8d:	89 45 94             	mov    %eax,-0x6c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104e90:	8b 45 94             	mov    -0x6c(%ebp),%eax
  104e93:	8b 55 c8             	mov    -0x38(%ebp),%edx
  104e96:	0f a3 10             	bt     %edx,(%eax)
  104e99:	19 c0                	sbb    %eax,%eax
  104e9b:	89 45 90             	mov    %eax,-0x70(%ebp)
    return oldbit != 0;
  104e9e:	83 7d 90 00          	cmpl   $0x0,-0x70(%ebp)
  104ea2:	0f 95 c0             	setne  %al
  104ea5:	0f b6 c0             	movzbl %al,%eax
  104ea8:	85 c0                	test   %eax,%eax
  104eaa:	74 0b                	je     104eb7 <default_check+0x3c3>
  104eac:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104eaf:	8b 40 08             	mov    0x8(%eax),%eax
  104eb2:	83 f8 01             	cmp    $0x1,%eax
  104eb5:	74 24                	je     104edb <default_check+0x3e7>
  104eb7:	c7 44 24 0c 9c 6c 10 	movl   $0x106c9c,0xc(%esp)
  104ebe:	00 
  104ebf:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104ec6:	00 
  104ec7:	c7 44 24 04 75 01 00 	movl   $0x175,0x4(%esp)
  104ece:	00 
  104ecf:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104ed6:	e8 0e b5 ff ff       	call   1003e9 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
  104edb:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  104ede:	83 c0 04             	add    $0x4,%eax
  104ee1:	c7 45 bc 01 00 00 00 	movl   $0x1,-0x44(%ebp)
  104ee8:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104eeb:	8b 45 8c             	mov    -0x74(%ebp),%eax
  104eee:	8b 55 bc             	mov    -0x44(%ebp),%edx
  104ef1:	0f a3 10             	bt     %edx,(%eax)
  104ef4:	19 c0                	sbb    %eax,%eax
  104ef6:	89 45 88             	mov    %eax,-0x78(%ebp)
    return oldbit != 0;
  104ef9:	83 7d 88 00          	cmpl   $0x0,-0x78(%ebp)
  104efd:	0f 95 c0             	setne  %al
  104f00:	0f b6 c0             	movzbl %al,%eax
  104f03:	85 c0                	test   %eax,%eax
  104f05:	74 0b                	je     104f12 <default_check+0x41e>
  104f07:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  104f0a:	8b 40 08             	mov    0x8(%eax),%eax
  104f0d:	83 f8 03             	cmp    $0x3,%eax
  104f10:	74 24                	je     104f36 <default_check+0x442>
  104f12:	c7 44 24 0c c4 6c 10 	movl   $0x106cc4,0xc(%esp)
  104f19:	00 
  104f1a:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104f21:	00 
  104f22:	c7 44 24 04 76 01 00 	movl   $0x176,0x4(%esp)
  104f29:	00 
  104f2a:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104f31:	e8 b3 b4 ff ff       	call   1003e9 <__panic>

    assert((p0 = alloc_page()) == p2 - 1);
  104f36:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104f3d:	e8 10 da ff ff       	call   102952 <alloc_pages>
  104f42:	89 45 dc             	mov    %eax,-0x24(%ebp)
  104f45:	8b 45 c0             	mov    -0x40(%ebp),%eax
  104f48:	83 e8 14             	sub    $0x14,%eax
  104f4b:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  104f4e:	74 24                	je     104f74 <default_check+0x480>
  104f50:	c7 44 24 0c ea 6c 10 	movl   $0x106cea,0xc(%esp)
  104f57:	00 
  104f58:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104f5f:	00 
  104f60:	c7 44 24 04 78 01 00 	movl   $0x178,0x4(%esp)
  104f67:	00 
  104f68:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104f6f:	e8 75 b4 ff ff       	call   1003e9 <__panic>
    free_page(p0);
  104f74:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104f7b:	00 
  104f7c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104f7f:	89 04 24             	mov    %eax,(%esp)
  104f82:	e8 03 da ff ff       	call   10298a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
  104f87:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  104f8e:	e8 bf d9 ff ff       	call   102952 <alloc_pages>
  104f93:	89 45 dc             	mov    %eax,-0x24(%ebp)
  104f96:	8b 45 c0             	mov    -0x40(%ebp),%eax
  104f99:	83 c0 14             	add    $0x14,%eax
  104f9c:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  104f9f:	74 24                	je     104fc5 <default_check+0x4d1>
  104fa1:	c7 44 24 0c 08 6d 10 	movl   $0x106d08,0xc(%esp)
  104fa8:	00 
  104fa9:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  104fb0:	00 
  104fb1:	c7 44 24 04 7a 01 00 	movl   $0x17a,0x4(%esp)
  104fb8:	00 
  104fb9:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  104fc0:	e8 24 b4 ff ff       	call   1003e9 <__panic>

    free_pages(p0, 2);
  104fc5:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  104fcc:	00 
  104fcd:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104fd0:	89 04 24             	mov    %eax,(%esp)
  104fd3:	e8 b2 d9 ff ff       	call   10298a <free_pages>
    free_page(p2);
  104fd8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104fdf:	00 
  104fe0:	8b 45 c0             	mov    -0x40(%ebp),%eax
  104fe3:	89 04 24             	mov    %eax,(%esp)
  104fe6:	e8 9f d9 ff ff       	call   10298a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
  104feb:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
  104ff2:	e8 5b d9 ff ff       	call   102952 <alloc_pages>
  104ff7:	89 45 dc             	mov    %eax,-0x24(%ebp)
  104ffa:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  104ffe:	75 24                	jne    105024 <default_check+0x530>
  105000:	c7 44 24 0c 28 6d 10 	movl   $0x106d28,0xc(%esp)
  105007:	00 
  105008:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  10500f:	00 
  105010:	c7 44 24 04 7f 01 00 	movl   $0x17f,0x4(%esp)
  105017:	00 
  105018:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  10501f:	e8 c5 b3 ff ff       	call   1003e9 <__panic>
    assert(alloc_page() == NULL);
  105024:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10502b:	e8 22 d9 ff ff       	call   102952 <alloc_pages>
  105030:	85 c0                	test   %eax,%eax
  105032:	74 24                	je     105058 <default_check+0x564>
  105034:	c7 44 24 0c 86 6b 10 	movl   $0x106b86,0xc(%esp)
  10503b:	00 
  10503c:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  105043:	00 
  105044:	c7 44 24 04 80 01 00 	movl   $0x180,0x4(%esp)
  10504b:	00 
  10504c:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  105053:	e8 91 b3 ff ff       	call   1003e9 <__panic>

    assert(nr_free == 0);
  105058:	a1 24 af 11 00       	mov    0x11af24,%eax
  10505d:	85 c0                	test   %eax,%eax
  10505f:	74 24                	je     105085 <default_check+0x591>
  105061:	c7 44 24 0c d9 6b 10 	movl   $0x106bd9,0xc(%esp)
  105068:	00 
  105069:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  105070:	00 
  105071:	c7 44 24 04 82 01 00 	movl   $0x182,0x4(%esp)
  105078:	00 
  105079:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  105080:	e8 64 b3 ff ff       	call   1003e9 <__panic>
    nr_free = nr_free_store;
  105085:	8b 45 cc             	mov    -0x34(%ebp),%eax
  105088:	a3 24 af 11 00       	mov    %eax,0x11af24

    free_list = free_list_store;
  10508d:	8b 45 80             	mov    -0x80(%ebp),%eax
  105090:	8b 55 84             	mov    -0x7c(%ebp),%edx
  105093:	a3 1c af 11 00       	mov    %eax,0x11af1c
  105098:	89 15 20 af 11 00    	mov    %edx,0x11af20
    free_pages(p0, 5);
  10509e:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
  1050a5:	00 
  1050a6:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1050a9:	89 04 24             	mov    %eax,(%esp)
  1050ac:	e8 d9 d8 ff ff       	call   10298a <free_pages>

    le = &free_list;
  1050b1:	c7 45 ec 1c af 11 00 	movl   $0x11af1c,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
  1050b8:	eb 5a                	jmp    105114 <default_check+0x620>
        assert(le->next->prev == le && le->prev->next == le);
  1050ba:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1050bd:	8b 40 04             	mov    0x4(%eax),%eax
  1050c0:	8b 00                	mov    (%eax),%eax
  1050c2:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1050c5:	75 0d                	jne    1050d4 <default_check+0x5e0>
  1050c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1050ca:	8b 00                	mov    (%eax),%eax
  1050cc:	8b 40 04             	mov    0x4(%eax),%eax
  1050cf:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1050d2:	74 24                	je     1050f8 <default_check+0x604>
  1050d4:	c7 44 24 0c 48 6d 10 	movl   $0x106d48,0xc(%esp)
  1050db:	00 
  1050dc:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  1050e3:	00 
  1050e4:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
  1050eb:	00 
  1050ec:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  1050f3:	e8 f1 b2 ff ff       	call   1003e9 <__panic>
        struct Page *p = le2page(le, page_link);
  1050f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1050fb:	83 e8 0c             	sub    $0xc,%eax
  1050fe:	89 45 b4             	mov    %eax,-0x4c(%ebp)
        count --, total -= p->property;
  105101:	ff 4d f4             	decl   -0xc(%ebp)
  105104:	8b 55 f0             	mov    -0x10(%ebp),%edx
  105107:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  10510a:	8b 40 08             	mov    0x8(%eax),%eax
  10510d:	29 c2                	sub    %eax,%edx
  10510f:	89 d0                	mov    %edx,%eax
  105111:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105114:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105117:	89 45 b8             	mov    %eax,-0x48(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  10511a:	8b 45 b8             	mov    -0x48(%ebp),%eax
  10511d:	8b 40 04             	mov    0x4(%eax),%eax

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
  105120:	89 45 ec             	mov    %eax,-0x14(%ebp)
  105123:	81 7d ec 1c af 11 00 	cmpl   $0x11af1c,-0x14(%ebp)
  10512a:	75 8e                	jne    1050ba <default_check+0x5c6>
        assert(le->next->prev == le && le->prev->next == le);
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
  10512c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  105130:	74 24                	je     105156 <default_check+0x662>
  105132:	c7 44 24 0c 75 6d 10 	movl   $0x106d75,0xc(%esp)
  105139:	00 
  10513a:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  105141:	00 
  105142:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
  105149:	00 
  10514a:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  105151:	e8 93 b2 ff ff       	call   1003e9 <__panic>
    assert(total == 0);
  105156:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  10515a:	74 24                	je     105180 <default_check+0x68c>
  10515c:	c7 44 24 0c 80 6d 10 	movl   $0x106d80,0xc(%esp)
  105163:	00 
  105164:	c7 44 24 08 fe 69 10 	movl   $0x1069fe,0x8(%esp)
  10516b:	00 
  10516c:	c7 44 24 04 8f 01 00 	movl   $0x18f,0x4(%esp)
  105173:	00 
  105174:	c7 04 24 13 6a 10 00 	movl   $0x106a13,(%esp)
  10517b:	e8 69 b2 ff ff       	call   1003e9 <__panic>
}
  105180:	90                   	nop
  105181:	c9                   	leave  
  105182:	c3                   	ret    

00105183 <strlen>:
 * @s:      the input string
 *
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
  105183:	55                   	push   %ebp
  105184:	89 e5                	mov    %esp,%ebp
  105186:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
  105189:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (*s ++ != '\0') {
  105190:	eb 03                	jmp    105195 <strlen+0x12>
        cnt ++;
  105192:	ff 45 fc             	incl   -0x4(%ebp)
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
  105195:	8b 45 08             	mov    0x8(%ebp),%eax
  105198:	8d 50 01             	lea    0x1(%eax),%edx
  10519b:	89 55 08             	mov    %edx,0x8(%ebp)
  10519e:	0f b6 00             	movzbl (%eax),%eax
  1051a1:	84 c0                	test   %al,%al
  1051a3:	75 ed                	jne    105192 <strlen+0xf>
        cnt ++;
    }
    return cnt;
  1051a5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1051a8:	c9                   	leave  
  1051a9:	c3                   	ret    

001051aa <strnlen>:
 * The return value is strlen(s), if that is less than @len, or
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
  1051aa:	55                   	push   %ebp
  1051ab:	89 e5                	mov    %esp,%ebp
  1051ad:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
  1051b0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (cnt < len && *s ++ != '\0') {
  1051b7:	eb 03                	jmp    1051bc <strnlen+0x12>
        cnt ++;
  1051b9:	ff 45 fc             	incl   -0x4(%ebp)
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
  1051bc:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1051bf:	3b 45 0c             	cmp    0xc(%ebp),%eax
  1051c2:	73 10                	jae    1051d4 <strnlen+0x2a>
  1051c4:	8b 45 08             	mov    0x8(%ebp),%eax
  1051c7:	8d 50 01             	lea    0x1(%eax),%edx
  1051ca:	89 55 08             	mov    %edx,0x8(%ebp)
  1051cd:	0f b6 00             	movzbl (%eax),%eax
  1051d0:	84 c0                	test   %al,%al
  1051d2:	75 e5                	jne    1051b9 <strnlen+0xf>
        cnt ++;
    }
    return cnt;
  1051d4:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1051d7:	c9                   	leave  
  1051d8:	c3                   	ret    

001051d9 <strcpy>:
 * To avoid overflows, the size of array pointed by @dst should be long enough to
 * contain the same string as @src (including the terminating null character), and
 * should not overlap in memory with @src.
 * */
char *
strcpy(char *dst, const char *src) {
  1051d9:	55                   	push   %ebp
  1051da:	89 e5                	mov    %esp,%ebp
  1051dc:	57                   	push   %edi
  1051dd:	56                   	push   %esi
  1051de:	83 ec 20             	sub    $0x20,%esp
  1051e1:	8b 45 08             	mov    0x8(%ebp),%eax
  1051e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1051e7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1051ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCPY
#define __HAVE_ARCH_STRCPY
static inline char *
__strcpy(char *dst, const char *src) {
    int d0, d1, d2;
    asm volatile (
  1051ed:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1051f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1051f3:	89 d1                	mov    %edx,%ecx
  1051f5:	89 c2                	mov    %eax,%edx
  1051f7:	89 ce                	mov    %ecx,%esi
  1051f9:	89 d7                	mov    %edx,%edi
  1051fb:	ac                   	lods   %ds:(%esi),%al
  1051fc:	aa                   	stos   %al,%es:(%edi)
  1051fd:	84 c0                	test   %al,%al
  1051ff:	75 fa                	jne    1051fb <strcpy+0x22>
  105201:	89 fa                	mov    %edi,%edx
  105203:	89 f1                	mov    %esi,%ecx
  105205:	89 4d ec             	mov    %ecx,-0x14(%ebp)
  105208:	89 55 e8             	mov    %edx,-0x18(%ebp)
  10520b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        "stosb;"
        "testb %%al, %%al;"
        "jne 1b;"
        : "=&S" (d0), "=&D" (d1), "=&a" (d2)
        : "0" (src), "1" (dst) : "memory");
    return dst;
  10520e:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
  105211:	90                   	nop
    char *p = dst;
    while ((*p ++ = *src ++) != '\0')
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
  105212:	83 c4 20             	add    $0x20,%esp
  105215:	5e                   	pop    %esi
  105216:	5f                   	pop    %edi
  105217:	5d                   	pop    %ebp
  105218:	c3                   	ret    

00105219 <strncpy>:
 * @len:    maximum number of characters to be copied from @src
 *
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
  105219:	55                   	push   %ebp
  10521a:	89 e5                	mov    %esp,%ebp
  10521c:	83 ec 10             	sub    $0x10,%esp
    char *p = dst;
  10521f:	8b 45 08             	mov    0x8(%ebp),%eax
  105222:	89 45 fc             	mov    %eax,-0x4(%ebp)
    while (len > 0) {
  105225:	eb 1e                	jmp    105245 <strncpy+0x2c>
        if ((*p = *src) != '\0') {
  105227:	8b 45 0c             	mov    0xc(%ebp),%eax
  10522a:	0f b6 10             	movzbl (%eax),%edx
  10522d:	8b 45 fc             	mov    -0x4(%ebp),%eax
  105230:	88 10                	mov    %dl,(%eax)
  105232:	8b 45 fc             	mov    -0x4(%ebp),%eax
  105235:	0f b6 00             	movzbl (%eax),%eax
  105238:	84 c0                	test   %al,%al
  10523a:	74 03                	je     10523f <strncpy+0x26>
            src ++;
  10523c:	ff 45 0c             	incl   0xc(%ebp)
        }
        p ++, len --;
  10523f:	ff 45 fc             	incl   -0x4(%ebp)
  105242:	ff 4d 10             	decl   0x10(%ebp)
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
    char *p = dst;
    while (len > 0) {
  105245:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105249:	75 dc                	jne    105227 <strncpy+0xe>
        if ((*p = *src) != '\0') {
            src ++;
        }
        p ++, len --;
    }
    return dst;
  10524b:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10524e:	c9                   	leave  
  10524f:	c3                   	ret    

00105250 <strcmp>:
 * - A value greater than zero indicates that the first character that does
 *   not match has a greater value in @s1 than in @s2;
 * - And a value less than zero indicates the opposite.
 * */
int
strcmp(const char *s1, const char *s2) {
  105250:	55                   	push   %ebp
  105251:	89 e5                	mov    %esp,%ebp
  105253:	57                   	push   %edi
  105254:	56                   	push   %esi
  105255:	83 ec 20             	sub    $0x20,%esp
  105258:	8b 45 08             	mov    0x8(%ebp),%eax
  10525b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10525e:	8b 45 0c             	mov    0xc(%ebp),%eax
  105261:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCMP
#define __HAVE_ARCH_STRCMP
static inline int
__strcmp(const char *s1, const char *s2) {
    int d0, d1, ret;
    asm volatile (
  105264:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105267:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10526a:	89 d1                	mov    %edx,%ecx
  10526c:	89 c2                	mov    %eax,%edx
  10526e:	89 ce                	mov    %ecx,%esi
  105270:	89 d7                	mov    %edx,%edi
  105272:	ac                   	lods   %ds:(%esi),%al
  105273:	ae                   	scas   %es:(%edi),%al
  105274:	75 08                	jne    10527e <strcmp+0x2e>
  105276:	84 c0                	test   %al,%al
  105278:	75 f8                	jne    105272 <strcmp+0x22>
  10527a:	31 c0                	xor    %eax,%eax
  10527c:	eb 04                	jmp    105282 <strcmp+0x32>
  10527e:	19 c0                	sbb    %eax,%eax
  105280:	0c 01                	or     $0x1,%al
  105282:	89 fa                	mov    %edi,%edx
  105284:	89 f1                	mov    %esi,%ecx
  105286:	89 45 ec             	mov    %eax,-0x14(%ebp)
  105289:	89 4d e8             	mov    %ecx,-0x18(%ebp)
  10528c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
        "orb $1, %%al;"
        "3:"
        : "=a" (ret), "=&S" (d0), "=&D" (d1)
        : "1" (s1), "2" (s2)
        : "memory");
    return ret;
  10528f:	8b 45 ec             	mov    -0x14(%ebp),%eax
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
  105292:	90                   	nop
    while (*s1 != '\0' && *s1 == *s2) {
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
#endif /* __HAVE_ARCH_STRCMP */
}
  105293:	83 c4 20             	add    $0x20,%esp
  105296:	5e                   	pop    %esi
  105297:	5f                   	pop    %edi
  105298:	5d                   	pop    %ebp
  105299:	c3                   	ret    

0010529a <strncmp>:
 * they are equal to each other, it continues with the following pairs until
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
  10529a:	55                   	push   %ebp
  10529b:	89 e5                	mov    %esp,%ebp
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
  10529d:	eb 09                	jmp    1052a8 <strncmp+0xe>
        n --, s1 ++, s2 ++;
  10529f:	ff 4d 10             	decl   0x10(%ebp)
  1052a2:	ff 45 08             	incl   0x8(%ebp)
  1052a5:	ff 45 0c             	incl   0xc(%ebp)
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
  1052a8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1052ac:	74 1a                	je     1052c8 <strncmp+0x2e>
  1052ae:	8b 45 08             	mov    0x8(%ebp),%eax
  1052b1:	0f b6 00             	movzbl (%eax),%eax
  1052b4:	84 c0                	test   %al,%al
  1052b6:	74 10                	je     1052c8 <strncmp+0x2e>
  1052b8:	8b 45 08             	mov    0x8(%ebp),%eax
  1052bb:	0f b6 10             	movzbl (%eax),%edx
  1052be:	8b 45 0c             	mov    0xc(%ebp),%eax
  1052c1:	0f b6 00             	movzbl (%eax),%eax
  1052c4:	38 c2                	cmp    %al,%dl
  1052c6:	74 d7                	je     10529f <strncmp+0x5>
        n --, s1 ++, s2 ++;
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
  1052c8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1052cc:	74 18                	je     1052e6 <strncmp+0x4c>
  1052ce:	8b 45 08             	mov    0x8(%ebp),%eax
  1052d1:	0f b6 00             	movzbl (%eax),%eax
  1052d4:	0f b6 d0             	movzbl %al,%edx
  1052d7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1052da:	0f b6 00             	movzbl (%eax),%eax
  1052dd:	0f b6 c0             	movzbl %al,%eax
  1052e0:	29 c2                	sub    %eax,%edx
  1052e2:	89 d0                	mov    %edx,%eax
  1052e4:	eb 05                	jmp    1052eb <strncmp+0x51>
  1052e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1052eb:	5d                   	pop    %ebp
  1052ec:	c3                   	ret    

001052ed <strchr>:
 *
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
  1052ed:	55                   	push   %ebp
  1052ee:	89 e5                	mov    %esp,%ebp
  1052f0:	83 ec 04             	sub    $0x4,%esp
  1052f3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1052f6:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
  1052f9:	eb 13                	jmp    10530e <strchr+0x21>
        if (*s == c) {
  1052fb:	8b 45 08             	mov    0x8(%ebp),%eax
  1052fe:	0f b6 00             	movzbl (%eax),%eax
  105301:	3a 45 fc             	cmp    -0x4(%ebp),%al
  105304:	75 05                	jne    10530b <strchr+0x1e>
            return (char *)s;
  105306:	8b 45 08             	mov    0x8(%ebp),%eax
  105309:	eb 12                	jmp    10531d <strchr+0x30>
        }
        s ++;
  10530b:	ff 45 08             	incl   0x8(%ebp)
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
  10530e:	8b 45 08             	mov    0x8(%ebp),%eax
  105311:	0f b6 00             	movzbl (%eax),%eax
  105314:	84 c0                	test   %al,%al
  105316:	75 e3                	jne    1052fb <strchr+0xe>
        if (*s == c) {
            return (char *)s;
        }
        s ++;
    }
    return NULL;
  105318:	b8 00 00 00 00       	mov    $0x0,%eax
}
  10531d:	c9                   	leave  
  10531e:	c3                   	ret    

0010531f <strfind>:
 * The strfind() function is like strchr() except that if @c is
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
  10531f:	55                   	push   %ebp
  105320:	89 e5                	mov    %esp,%ebp
  105322:	83 ec 04             	sub    $0x4,%esp
  105325:	8b 45 0c             	mov    0xc(%ebp),%eax
  105328:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
  10532b:	eb 0e                	jmp    10533b <strfind+0x1c>
        if (*s == c) {
  10532d:	8b 45 08             	mov    0x8(%ebp),%eax
  105330:	0f b6 00             	movzbl (%eax),%eax
  105333:	3a 45 fc             	cmp    -0x4(%ebp),%al
  105336:	74 0f                	je     105347 <strfind+0x28>
            break;
        }
        s ++;
  105338:	ff 45 08             	incl   0x8(%ebp)
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
    while (*s != '\0') {
  10533b:	8b 45 08             	mov    0x8(%ebp),%eax
  10533e:	0f b6 00             	movzbl (%eax),%eax
  105341:	84 c0                	test   %al,%al
  105343:	75 e8                	jne    10532d <strfind+0xe>
  105345:	eb 01                	jmp    105348 <strfind+0x29>
        if (*s == c) {
            break;
  105347:	90                   	nop
        }
        s ++;
    }
    return (char *)s;
  105348:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10534b:	c9                   	leave  
  10534c:	c3                   	ret    

0010534d <strtol>:
 * an optional "0x" or "0X" prefix.
 *
 * The strtol() function returns the converted integral number as a long int value.
 * */
long
strtol(const char *s, char **endptr, int base) {
  10534d:	55                   	push   %ebp
  10534e:	89 e5                	mov    %esp,%ebp
  105350:	83 ec 10             	sub    $0x10,%esp
    int neg = 0;
  105353:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    long val = 0;
  10535a:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
  105361:	eb 03                	jmp    105366 <strtol+0x19>
        s ++;
  105363:	ff 45 08             	incl   0x8(%ebp)
strtol(const char *s, char **endptr, int base) {
    int neg = 0;
    long val = 0;

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
  105366:	8b 45 08             	mov    0x8(%ebp),%eax
  105369:	0f b6 00             	movzbl (%eax),%eax
  10536c:	3c 20                	cmp    $0x20,%al
  10536e:	74 f3                	je     105363 <strtol+0x16>
  105370:	8b 45 08             	mov    0x8(%ebp),%eax
  105373:	0f b6 00             	movzbl (%eax),%eax
  105376:	3c 09                	cmp    $0x9,%al
  105378:	74 e9                	je     105363 <strtol+0x16>
        s ++;
    }

    // plus/minus sign
    if (*s == '+') {
  10537a:	8b 45 08             	mov    0x8(%ebp),%eax
  10537d:	0f b6 00             	movzbl (%eax),%eax
  105380:	3c 2b                	cmp    $0x2b,%al
  105382:	75 05                	jne    105389 <strtol+0x3c>
        s ++;
  105384:	ff 45 08             	incl   0x8(%ebp)
  105387:	eb 14                	jmp    10539d <strtol+0x50>
    }
    else if (*s == '-') {
  105389:	8b 45 08             	mov    0x8(%ebp),%eax
  10538c:	0f b6 00             	movzbl (%eax),%eax
  10538f:	3c 2d                	cmp    $0x2d,%al
  105391:	75 0a                	jne    10539d <strtol+0x50>
        s ++, neg = 1;
  105393:	ff 45 08             	incl   0x8(%ebp)
  105396:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)
    }

    // hex or octal base prefix
    if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x')) {
  10539d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1053a1:	74 06                	je     1053a9 <strtol+0x5c>
  1053a3:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
  1053a7:	75 22                	jne    1053cb <strtol+0x7e>
  1053a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1053ac:	0f b6 00             	movzbl (%eax),%eax
  1053af:	3c 30                	cmp    $0x30,%al
  1053b1:	75 18                	jne    1053cb <strtol+0x7e>
  1053b3:	8b 45 08             	mov    0x8(%ebp),%eax
  1053b6:	40                   	inc    %eax
  1053b7:	0f b6 00             	movzbl (%eax),%eax
  1053ba:	3c 78                	cmp    $0x78,%al
  1053bc:	75 0d                	jne    1053cb <strtol+0x7e>
        s += 2, base = 16;
  1053be:	83 45 08 02          	addl   $0x2,0x8(%ebp)
  1053c2:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
  1053c9:	eb 29                	jmp    1053f4 <strtol+0xa7>
    }
    else if (base == 0 && s[0] == '0') {
  1053cb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1053cf:	75 16                	jne    1053e7 <strtol+0x9a>
  1053d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1053d4:	0f b6 00             	movzbl (%eax),%eax
  1053d7:	3c 30                	cmp    $0x30,%al
  1053d9:	75 0c                	jne    1053e7 <strtol+0x9a>
        s ++, base = 8;
  1053db:	ff 45 08             	incl   0x8(%ebp)
  1053de:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
  1053e5:	eb 0d                	jmp    1053f4 <strtol+0xa7>
    }
    else if (base == 0) {
  1053e7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1053eb:	75 07                	jne    1053f4 <strtol+0xa7>
        base = 10;
  1053ed:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

    // digits
    while (1) {
        int dig;

        if (*s >= '0' && *s <= '9') {
  1053f4:	8b 45 08             	mov    0x8(%ebp),%eax
  1053f7:	0f b6 00             	movzbl (%eax),%eax
  1053fa:	3c 2f                	cmp    $0x2f,%al
  1053fc:	7e 1b                	jle    105419 <strtol+0xcc>
  1053fe:	8b 45 08             	mov    0x8(%ebp),%eax
  105401:	0f b6 00             	movzbl (%eax),%eax
  105404:	3c 39                	cmp    $0x39,%al
  105406:	7f 11                	jg     105419 <strtol+0xcc>
            dig = *s - '0';
  105408:	8b 45 08             	mov    0x8(%ebp),%eax
  10540b:	0f b6 00             	movzbl (%eax),%eax
  10540e:	0f be c0             	movsbl %al,%eax
  105411:	83 e8 30             	sub    $0x30,%eax
  105414:	89 45 f4             	mov    %eax,-0xc(%ebp)
  105417:	eb 48                	jmp    105461 <strtol+0x114>
        }
        else if (*s >= 'a' && *s <= 'z') {
  105419:	8b 45 08             	mov    0x8(%ebp),%eax
  10541c:	0f b6 00             	movzbl (%eax),%eax
  10541f:	3c 60                	cmp    $0x60,%al
  105421:	7e 1b                	jle    10543e <strtol+0xf1>
  105423:	8b 45 08             	mov    0x8(%ebp),%eax
  105426:	0f b6 00             	movzbl (%eax),%eax
  105429:	3c 7a                	cmp    $0x7a,%al
  10542b:	7f 11                	jg     10543e <strtol+0xf1>
            dig = *s - 'a' + 10;
  10542d:	8b 45 08             	mov    0x8(%ebp),%eax
  105430:	0f b6 00             	movzbl (%eax),%eax
  105433:	0f be c0             	movsbl %al,%eax
  105436:	83 e8 57             	sub    $0x57,%eax
  105439:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10543c:	eb 23                	jmp    105461 <strtol+0x114>
        }
        else if (*s >= 'A' && *s <= 'Z') {
  10543e:	8b 45 08             	mov    0x8(%ebp),%eax
  105441:	0f b6 00             	movzbl (%eax),%eax
  105444:	3c 40                	cmp    $0x40,%al
  105446:	7e 3b                	jle    105483 <strtol+0x136>
  105448:	8b 45 08             	mov    0x8(%ebp),%eax
  10544b:	0f b6 00             	movzbl (%eax),%eax
  10544e:	3c 5a                	cmp    $0x5a,%al
  105450:	7f 31                	jg     105483 <strtol+0x136>
            dig = *s - 'A' + 10;
  105452:	8b 45 08             	mov    0x8(%ebp),%eax
  105455:	0f b6 00             	movzbl (%eax),%eax
  105458:	0f be c0             	movsbl %al,%eax
  10545b:	83 e8 37             	sub    $0x37,%eax
  10545e:	89 45 f4             	mov    %eax,-0xc(%ebp)
        }
        else {
            break;
        }
        if (dig >= base) {
  105461:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105464:	3b 45 10             	cmp    0x10(%ebp),%eax
  105467:	7d 19                	jge    105482 <strtol+0x135>
            break;
        }
        s ++, val = (val * base) + dig;
  105469:	ff 45 08             	incl   0x8(%ebp)
  10546c:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10546f:	0f af 45 10          	imul   0x10(%ebp),%eax
  105473:	89 c2                	mov    %eax,%edx
  105475:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105478:	01 d0                	add    %edx,%eax
  10547a:	89 45 f8             	mov    %eax,-0x8(%ebp)
        // we don't properly detect overflow!
    }
  10547d:	e9 72 ff ff ff       	jmp    1053f4 <strtol+0xa7>
        }
        else {
            break;
        }
        if (dig >= base) {
            break;
  105482:	90                   	nop
        }
        s ++, val = (val * base) + dig;
        // we don't properly detect overflow!
    }

    if (endptr) {
  105483:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  105487:	74 08                	je     105491 <strtol+0x144>
        *endptr = (char *) s;
  105489:	8b 45 0c             	mov    0xc(%ebp),%eax
  10548c:	8b 55 08             	mov    0x8(%ebp),%edx
  10548f:	89 10                	mov    %edx,(%eax)
    }
    return (neg ? -val : val);
  105491:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
  105495:	74 07                	je     10549e <strtol+0x151>
  105497:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10549a:	f7 d8                	neg    %eax
  10549c:	eb 03                	jmp    1054a1 <strtol+0x154>
  10549e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  1054a1:	c9                   	leave  
  1054a2:	c3                   	ret    

001054a3 <memset>:
 * @n:      number of bytes to be set to the value
 *
 * The memset() function returns @s.
 * */
void *
memset(void *s, char c, size_t n) {
  1054a3:	55                   	push   %ebp
  1054a4:	89 e5                	mov    %esp,%ebp
  1054a6:	57                   	push   %edi
  1054a7:	83 ec 24             	sub    $0x24,%esp
  1054aa:	8b 45 0c             	mov    0xc(%ebp),%eax
  1054ad:	88 45 d8             	mov    %al,-0x28(%ebp)
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
  1054b0:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  1054b4:	8b 55 08             	mov    0x8(%ebp),%edx
  1054b7:	89 55 f8             	mov    %edx,-0x8(%ebp)
  1054ba:	88 45 f7             	mov    %al,-0x9(%ebp)
  1054bd:	8b 45 10             	mov    0x10(%ebp),%eax
  1054c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_MEMSET
#define __HAVE_ARCH_MEMSET
static inline void *
__memset(void *s, char c, size_t n) {
    int d0, d1;
    asm volatile (
  1054c3:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  1054c6:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  1054ca:	8b 55 f8             	mov    -0x8(%ebp),%edx
  1054cd:	89 d7                	mov    %edx,%edi
  1054cf:	f3 aa                	rep stos %al,%es:(%edi)
  1054d1:	89 fa                	mov    %edi,%edx
  1054d3:	89 4d ec             	mov    %ecx,-0x14(%ebp)
  1054d6:	89 55 e8             	mov    %edx,-0x18(%ebp)
        "rep; stosb;"
        : "=&c" (d0), "=&D" (d1)
        : "0" (n), "a" (c), "1" (s)
        : "memory");
    return s;
  1054d9:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1054dc:	90                   	nop
    while (n -- > 0) {
        *p ++ = c;
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
  1054dd:	83 c4 24             	add    $0x24,%esp
  1054e0:	5f                   	pop    %edi
  1054e1:	5d                   	pop    %ebp
  1054e2:	c3                   	ret    

001054e3 <memmove>:
 * @n:      number of bytes to copy
 *
 * The memmove() function returns @dst.
 * */
void *
memmove(void *dst, const void *src, size_t n) {
  1054e3:	55                   	push   %ebp
  1054e4:	89 e5                	mov    %esp,%ebp
  1054e6:	57                   	push   %edi
  1054e7:	56                   	push   %esi
  1054e8:	53                   	push   %ebx
  1054e9:	83 ec 30             	sub    $0x30,%esp
  1054ec:	8b 45 08             	mov    0x8(%ebp),%eax
  1054ef:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1054f2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1054f5:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1054f8:	8b 45 10             	mov    0x10(%ebp),%eax
  1054fb:	89 45 e8             	mov    %eax,-0x18(%ebp)

#ifndef __HAVE_ARCH_MEMMOVE
#define __HAVE_ARCH_MEMMOVE
static inline void *
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
  1054fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105501:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  105504:	73 42                	jae    105548 <memmove+0x65>
  105506:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105509:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  10550c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10550f:	89 45 e0             	mov    %eax,-0x20(%ebp)
  105512:	8b 45 e8             	mov    -0x18(%ebp),%eax
  105515:	89 45 dc             	mov    %eax,-0x24(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
  105518:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10551b:	c1 e8 02             	shr    $0x2,%eax
  10551e:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
  105520:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  105523:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105526:	89 d7                	mov    %edx,%edi
  105528:	89 c6                	mov    %eax,%esi
  10552a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  10552c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  10552f:	83 e1 03             	and    $0x3,%ecx
  105532:	74 02                	je     105536 <memmove+0x53>
  105534:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  105536:	89 f0                	mov    %esi,%eax
  105538:	89 fa                	mov    %edi,%edx
  10553a:	89 4d d8             	mov    %ecx,-0x28(%ebp)
  10553d:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  105540:	89 45 d0             	mov    %eax,-0x30(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
  105543:	8b 45 e4             	mov    -0x1c(%ebp),%eax
#ifdef __HAVE_ARCH_MEMMOVE
    return __memmove(dst, src, n);
  105546:	eb 36                	jmp    10557e <memmove+0x9b>
    asm volatile (
        "std;"
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
  105548:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10554b:	8d 50 ff             	lea    -0x1(%eax),%edx
  10554e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105551:	01 c2                	add    %eax,%edx
  105553:	8b 45 e8             	mov    -0x18(%ebp),%eax
  105556:	8d 48 ff             	lea    -0x1(%eax),%ecx
  105559:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10555c:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
        return __memcpy(dst, src, n);
    }
    int d0, d1, d2;
    asm volatile (
  10555f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  105562:	89 c1                	mov    %eax,%ecx
  105564:	89 d8                	mov    %ebx,%eax
  105566:	89 d6                	mov    %edx,%esi
  105568:	89 c7                	mov    %eax,%edi
  10556a:	fd                   	std    
  10556b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  10556d:	fc                   	cld    
  10556e:	89 f8                	mov    %edi,%eax
  105570:	89 f2                	mov    %esi,%edx
  105572:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  105575:	89 55 c8             	mov    %edx,-0x38(%ebp)
  105578:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
        : "memory");
    return dst;
  10557b:	8b 45 f0             	mov    -0x10(%ebp),%eax
            *d ++ = *s ++;
        }
    }
    return dst;
#endif /* __HAVE_ARCH_MEMMOVE */
}
  10557e:	83 c4 30             	add    $0x30,%esp
  105581:	5b                   	pop    %ebx
  105582:	5e                   	pop    %esi
  105583:	5f                   	pop    %edi
  105584:	5d                   	pop    %ebp
  105585:	c3                   	ret    

00105586 <memcpy>:
 * it always copies exactly @n bytes. To avoid overflows, the size of arrays pointed
 * by both @src and @dst, should be at least @n bytes, and should not overlap
 * (for overlapping memory area, memmove is a safer approach).
 * */
void *
memcpy(void *dst, const void *src, size_t n) {
  105586:	55                   	push   %ebp
  105587:	89 e5                	mov    %esp,%ebp
  105589:	57                   	push   %edi
  10558a:	56                   	push   %esi
  10558b:	83 ec 20             	sub    $0x20,%esp
  10558e:	8b 45 08             	mov    0x8(%ebp),%eax
  105591:	89 45 f4             	mov    %eax,-0xc(%ebp)
  105594:	8b 45 0c             	mov    0xc(%ebp),%eax
  105597:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10559a:	8b 45 10             	mov    0x10(%ebp),%eax
  10559d:	89 45 ec             	mov    %eax,-0x14(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
  1055a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1055a3:	c1 e8 02             	shr    $0x2,%eax
  1055a6:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
  1055a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1055ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1055ae:	89 d7                	mov    %edx,%edi
  1055b0:	89 c6                	mov    %eax,%esi
  1055b2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  1055b4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
  1055b7:	83 e1 03             	and    $0x3,%ecx
  1055ba:	74 02                	je     1055be <memcpy+0x38>
  1055bc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  1055be:	89 f0                	mov    %esi,%eax
  1055c0:	89 fa                	mov    %edi,%edx
  1055c2:	89 4d e8             	mov    %ecx,-0x18(%ebp)
  1055c5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  1055c8:	89 45 e0             	mov    %eax,-0x20(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
  1055cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
  1055ce:	90                   	nop
    while (n -- > 0) {
        *d ++ = *s ++;
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
  1055cf:	83 c4 20             	add    $0x20,%esp
  1055d2:	5e                   	pop    %esi
  1055d3:	5f                   	pop    %edi
  1055d4:	5d                   	pop    %ebp
  1055d5:	c3                   	ret    

001055d6 <memcmp>:
 *   match in both memory blocks has a greater value in @v1 than in @v2
 *   as if evaluated as unsigned char values;
 * - And a value less than zero indicates the opposite.
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
  1055d6:	55                   	push   %ebp
  1055d7:	89 e5                	mov    %esp,%ebp
  1055d9:	83 ec 10             	sub    $0x10,%esp
    const char *s1 = (const char *)v1;
  1055dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1055df:	89 45 fc             	mov    %eax,-0x4(%ebp)
    const char *s2 = (const char *)v2;
  1055e2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1055e5:	89 45 f8             	mov    %eax,-0x8(%ebp)
    while (n -- > 0) {
  1055e8:	eb 2e                	jmp    105618 <memcmp+0x42>
        if (*s1 != *s2) {
  1055ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1055ed:	0f b6 10             	movzbl (%eax),%edx
  1055f0:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1055f3:	0f b6 00             	movzbl (%eax),%eax
  1055f6:	38 c2                	cmp    %al,%dl
  1055f8:	74 18                	je     105612 <memcmp+0x3c>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
  1055fa:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1055fd:	0f b6 00             	movzbl (%eax),%eax
  105600:	0f b6 d0             	movzbl %al,%edx
  105603:	8b 45 f8             	mov    -0x8(%ebp),%eax
  105606:	0f b6 00             	movzbl (%eax),%eax
  105609:	0f b6 c0             	movzbl %al,%eax
  10560c:	29 c2                	sub    %eax,%edx
  10560e:	89 d0                	mov    %edx,%eax
  105610:	eb 18                	jmp    10562a <memcmp+0x54>
        }
        s1 ++, s2 ++;
  105612:	ff 45 fc             	incl   -0x4(%ebp)
  105615:	ff 45 f8             	incl   -0x8(%ebp)
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
  105618:	8b 45 10             	mov    0x10(%ebp),%eax
  10561b:	8d 50 ff             	lea    -0x1(%eax),%edx
  10561e:	89 55 10             	mov    %edx,0x10(%ebp)
  105621:	85 c0                	test   %eax,%eax
  105623:	75 c5                	jne    1055ea <memcmp+0x14>
        if (*s1 != *s2) {
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
    }
    return 0;
  105625:	b8 00 00 00 00       	mov    $0x0,%eax
}
  10562a:	c9                   	leave  
  10562b:	c3                   	ret    

0010562c <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  10562c:	55                   	push   %ebp
  10562d:	89 e5                	mov    %esp,%ebp
  10562f:	83 ec 58             	sub    $0x58,%esp
  105632:	8b 45 10             	mov    0x10(%ebp),%eax
  105635:	89 45 d0             	mov    %eax,-0x30(%ebp)
  105638:	8b 45 14             	mov    0x14(%ebp),%eax
  10563b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    unsigned long long result = num;
  10563e:	8b 45 d0             	mov    -0x30(%ebp),%eax
  105641:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  105644:	89 45 e8             	mov    %eax,-0x18(%ebp)
  105647:	89 55 ec             	mov    %edx,-0x14(%ebp)
    unsigned mod = do_div(result, base);
  10564a:	8b 45 18             	mov    0x18(%ebp),%eax
  10564d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  105650:	8b 45 e8             	mov    -0x18(%ebp),%eax
  105653:	8b 55 ec             	mov    -0x14(%ebp),%edx
  105656:	89 45 e0             	mov    %eax,-0x20(%ebp)
  105659:	89 55 f0             	mov    %edx,-0x10(%ebp)
  10565c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10565f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  105662:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  105666:	74 1c                	je     105684 <printnum+0x58>
  105668:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10566b:	ba 00 00 00 00       	mov    $0x0,%edx
  105670:	f7 75 e4             	divl   -0x1c(%ebp)
  105673:	89 55 f4             	mov    %edx,-0xc(%ebp)
  105676:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105679:	ba 00 00 00 00       	mov    $0x0,%edx
  10567e:	f7 75 e4             	divl   -0x1c(%ebp)
  105681:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105684:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105687:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10568a:	f7 75 e4             	divl   -0x1c(%ebp)
  10568d:	89 45 e0             	mov    %eax,-0x20(%ebp)
  105690:	89 55 dc             	mov    %edx,-0x24(%ebp)
  105693:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105696:	8b 55 f0             	mov    -0x10(%ebp),%edx
  105699:	89 45 e8             	mov    %eax,-0x18(%ebp)
  10569c:	89 55 ec             	mov    %edx,-0x14(%ebp)
  10569f:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1056a2:	89 45 d8             	mov    %eax,-0x28(%ebp)

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
  1056a5:	8b 45 18             	mov    0x18(%ebp),%eax
  1056a8:	ba 00 00 00 00       	mov    $0x0,%edx
  1056ad:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  1056b0:	77 56                	ja     105708 <printnum+0xdc>
  1056b2:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  1056b5:	72 05                	jb     1056bc <printnum+0x90>
  1056b7:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1056ba:	77 4c                	ja     105708 <printnum+0xdc>
        printnum(putch, putdat, result, base, width - 1, padc);
  1056bc:	8b 45 1c             	mov    0x1c(%ebp),%eax
  1056bf:	8d 50 ff             	lea    -0x1(%eax),%edx
  1056c2:	8b 45 20             	mov    0x20(%ebp),%eax
  1056c5:	89 44 24 18          	mov    %eax,0x18(%esp)
  1056c9:	89 54 24 14          	mov    %edx,0x14(%esp)
  1056cd:	8b 45 18             	mov    0x18(%ebp),%eax
  1056d0:	89 44 24 10          	mov    %eax,0x10(%esp)
  1056d4:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1056d7:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1056da:	89 44 24 08          	mov    %eax,0x8(%esp)
  1056de:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1056e2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1056e5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1056e9:	8b 45 08             	mov    0x8(%ebp),%eax
  1056ec:	89 04 24             	mov    %eax,(%esp)
  1056ef:	e8 38 ff ff ff       	call   10562c <printnum>
  1056f4:	eb 1b                	jmp    105711 <printnum+0xe5>
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
            putch(padc, putdat);
  1056f6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1056f9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1056fd:	8b 45 20             	mov    0x20(%ebp),%eax
  105700:	89 04 24             	mov    %eax,(%esp)
  105703:	8b 45 08             	mov    0x8(%ebp),%eax
  105706:	ff d0                	call   *%eax
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  105708:	ff 4d 1c             	decl   0x1c(%ebp)
  10570b:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
  10570f:	7f e5                	jg     1056f6 <printnum+0xca>
            putch(padc, putdat);
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  105711:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105714:	05 3c 6e 10 00       	add    $0x106e3c,%eax
  105719:	0f b6 00             	movzbl (%eax),%eax
  10571c:	0f be c0             	movsbl %al,%eax
  10571f:	8b 55 0c             	mov    0xc(%ebp),%edx
  105722:	89 54 24 04          	mov    %edx,0x4(%esp)
  105726:	89 04 24             	mov    %eax,(%esp)
  105729:	8b 45 08             	mov    0x8(%ebp),%eax
  10572c:	ff d0                	call   *%eax
}
  10572e:	90                   	nop
  10572f:	c9                   	leave  
  105730:	c3                   	ret    

00105731 <getuint>:
 * getuint - get an unsigned int of various possible sizes from a varargs list
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static unsigned long long
getuint(va_list *ap, int lflag) {
  105731:	55                   	push   %ebp
  105732:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
  105734:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  105738:	7e 14                	jle    10574e <getuint+0x1d>
        return va_arg(*ap, unsigned long long);
  10573a:	8b 45 08             	mov    0x8(%ebp),%eax
  10573d:	8b 00                	mov    (%eax),%eax
  10573f:	8d 48 08             	lea    0x8(%eax),%ecx
  105742:	8b 55 08             	mov    0x8(%ebp),%edx
  105745:	89 0a                	mov    %ecx,(%edx)
  105747:	8b 50 04             	mov    0x4(%eax),%edx
  10574a:	8b 00                	mov    (%eax),%eax
  10574c:	eb 30                	jmp    10577e <getuint+0x4d>
    }
    else if (lflag) {
  10574e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  105752:	74 16                	je     10576a <getuint+0x39>
        return va_arg(*ap, unsigned long);
  105754:	8b 45 08             	mov    0x8(%ebp),%eax
  105757:	8b 00                	mov    (%eax),%eax
  105759:	8d 48 04             	lea    0x4(%eax),%ecx
  10575c:	8b 55 08             	mov    0x8(%ebp),%edx
  10575f:	89 0a                	mov    %ecx,(%edx)
  105761:	8b 00                	mov    (%eax),%eax
  105763:	ba 00 00 00 00       	mov    $0x0,%edx
  105768:	eb 14                	jmp    10577e <getuint+0x4d>
    }
    else {
        return va_arg(*ap, unsigned int);
  10576a:	8b 45 08             	mov    0x8(%ebp),%eax
  10576d:	8b 00                	mov    (%eax),%eax
  10576f:	8d 48 04             	lea    0x4(%eax),%ecx
  105772:	8b 55 08             	mov    0x8(%ebp),%edx
  105775:	89 0a                	mov    %ecx,(%edx)
  105777:	8b 00                	mov    (%eax),%eax
  105779:	ba 00 00 00 00       	mov    $0x0,%edx
    }
}
  10577e:	5d                   	pop    %ebp
  10577f:	c3                   	ret    

00105780 <getint>:
 * getint - same as getuint but signed, we can't use getuint because of sign extension
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static long long
getint(va_list *ap, int lflag) {
  105780:	55                   	push   %ebp
  105781:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
  105783:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  105787:	7e 14                	jle    10579d <getint+0x1d>
        return va_arg(*ap, long long);
  105789:	8b 45 08             	mov    0x8(%ebp),%eax
  10578c:	8b 00                	mov    (%eax),%eax
  10578e:	8d 48 08             	lea    0x8(%eax),%ecx
  105791:	8b 55 08             	mov    0x8(%ebp),%edx
  105794:	89 0a                	mov    %ecx,(%edx)
  105796:	8b 50 04             	mov    0x4(%eax),%edx
  105799:	8b 00                	mov    (%eax),%eax
  10579b:	eb 28                	jmp    1057c5 <getint+0x45>
    }
    else if (lflag) {
  10579d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  1057a1:	74 12                	je     1057b5 <getint+0x35>
        return va_arg(*ap, long);
  1057a3:	8b 45 08             	mov    0x8(%ebp),%eax
  1057a6:	8b 00                	mov    (%eax),%eax
  1057a8:	8d 48 04             	lea    0x4(%eax),%ecx
  1057ab:	8b 55 08             	mov    0x8(%ebp),%edx
  1057ae:	89 0a                	mov    %ecx,(%edx)
  1057b0:	8b 00                	mov    (%eax),%eax
  1057b2:	99                   	cltd   
  1057b3:	eb 10                	jmp    1057c5 <getint+0x45>
    }
    else {
        return va_arg(*ap, int);
  1057b5:	8b 45 08             	mov    0x8(%ebp),%eax
  1057b8:	8b 00                	mov    (%eax),%eax
  1057ba:	8d 48 04             	lea    0x4(%eax),%ecx
  1057bd:	8b 55 08             	mov    0x8(%ebp),%edx
  1057c0:	89 0a                	mov    %ecx,(%edx)
  1057c2:	8b 00                	mov    (%eax),%eax
  1057c4:	99                   	cltd   
    }
}
  1057c5:	5d                   	pop    %ebp
  1057c6:	c3                   	ret    

001057c7 <printfmt>:
 * @putch:      specified putch function, print a single character
 * @putdat:     used by @putch function
 * @fmt:        the format string to use
 * */
void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  1057c7:	55                   	push   %ebp
  1057c8:	89 e5                	mov    %esp,%ebp
  1057ca:	83 ec 28             	sub    $0x28,%esp
    va_list ap;

    va_start(ap, fmt);
  1057cd:	8d 45 14             	lea    0x14(%ebp),%eax
  1057d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
    vprintfmt(putch, putdat, fmt, ap);
  1057d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1057d6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1057da:	8b 45 10             	mov    0x10(%ebp),%eax
  1057dd:	89 44 24 08          	mov    %eax,0x8(%esp)
  1057e1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1057e4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1057e8:	8b 45 08             	mov    0x8(%ebp),%eax
  1057eb:	89 04 24             	mov    %eax,(%esp)
  1057ee:	e8 03 00 00 00       	call   1057f6 <vprintfmt>
    va_end(ap);
}
  1057f3:	90                   	nop
  1057f4:	c9                   	leave  
  1057f5:	c3                   	ret    

001057f6 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  1057f6:	55                   	push   %ebp
  1057f7:	89 e5                	mov    %esp,%ebp
  1057f9:	56                   	push   %esi
  1057fa:	53                   	push   %ebx
  1057fb:	83 ec 40             	sub    $0x40,%esp
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  1057fe:	eb 17                	jmp    105817 <vprintfmt+0x21>
            if (ch == '\0') {
  105800:	85 db                	test   %ebx,%ebx
  105802:	0f 84 bf 03 00 00    	je     105bc7 <vprintfmt+0x3d1>
                return;
            }
            putch(ch, putdat);
  105808:	8b 45 0c             	mov    0xc(%ebp),%eax
  10580b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10580f:	89 1c 24             	mov    %ebx,(%esp)
  105812:	8b 45 08             	mov    0x8(%ebp),%eax
  105815:	ff d0                	call   *%eax
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  105817:	8b 45 10             	mov    0x10(%ebp),%eax
  10581a:	8d 50 01             	lea    0x1(%eax),%edx
  10581d:	89 55 10             	mov    %edx,0x10(%ebp)
  105820:	0f b6 00             	movzbl (%eax),%eax
  105823:	0f b6 d8             	movzbl %al,%ebx
  105826:	83 fb 25             	cmp    $0x25,%ebx
  105829:	75 d5                	jne    105800 <vprintfmt+0xa>
            }
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
  10582b:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
        width = precision = -1;
  10582f:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  105836:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105839:	89 45 e8             	mov    %eax,-0x18(%ebp)
        lflag = altflag = 0;
  10583c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  105843:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105846:	89 45 e0             	mov    %eax,-0x20(%ebp)

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
  105849:	8b 45 10             	mov    0x10(%ebp),%eax
  10584c:	8d 50 01             	lea    0x1(%eax),%edx
  10584f:	89 55 10             	mov    %edx,0x10(%ebp)
  105852:	0f b6 00             	movzbl (%eax),%eax
  105855:	0f b6 d8             	movzbl %al,%ebx
  105858:	8d 43 dd             	lea    -0x23(%ebx),%eax
  10585b:	83 f8 55             	cmp    $0x55,%eax
  10585e:	0f 87 37 03 00 00    	ja     105b9b <vprintfmt+0x3a5>
  105864:	8b 04 85 60 6e 10 00 	mov    0x106e60(,%eax,4),%eax
  10586b:	ff e0                	jmp    *%eax

        // flag to pad on the right
        case '-':
            padc = '-';
  10586d:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
            goto reswitch;
  105871:	eb d6                	jmp    105849 <vprintfmt+0x53>

        // flag to pad with 0's instead of spaces
        case '0':
            padc = '0';
  105873:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
            goto reswitch;
  105877:	eb d0                	jmp    105849 <vprintfmt+0x53>

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
  105879:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
                precision = precision * 10 + ch - '0';
  105880:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  105883:	89 d0                	mov    %edx,%eax
  105885:	c1 e0 02             	shl    $0x2,%eax
  105888:	01 d0                	add    %edx,%eax
  10588a:	01 c0                	add    %eax,%eax
  10588c:	01 d8                	add    %ebx,%eax
  10588e:	83 e8 30             	sub    $0x30,%eax
  105891:	89 45 e4             	mov    %eax,-0x1c(%ebp)
                ch = *fmt;
  105894:	8b 45 10             	mov    0x10(%ebp),%eax
  105897:	0f b6 00             	movzbl (%eax),%eax
  10589a:	0f be d8             	movsbl %al,%ebx
                if (ch < '0' || ch > '9') {
  10589d:	83 fb 2f             	cmp    $0x2f,%ebx
  1058a0:	7e 38                	jle    1058da <vprintfmt+0xe4>
  1058a2:	83 fb 39             	cmp    $0x39,%ebx
  1058a5:	7f 33                	jg     1058da <vprintfmt+0xe4>
            padc = '0';
            goto reswitch;

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
  1058a7:	ff 45 10             	incl   0x10(%ebp)
                precision = precision * 10 + ch - '0';
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
  1058aa:	eb d4                	jmp    105880 <vprintfmt+0x8a>
            goto process_precision;

        case '*':
            precision = va_arg(ap, int);
  1058ac:	8b 45 14             	mov    0x14(%ebp),%eax
  1058af:	8d 50 04             	lea    0x4(%eax),%edx
  1058b2:	89 55 14             	mov    %edx,0x14(%ebp)
  1058b5:	8b 00                	mov    (%eax),%eax
  1058b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            goto process_precision;
  1058ba:	eb 1f                	jmp    1058db <vprintfmt+0xe5>

        case '.':
            if (width < 0)
  1058bc:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  1058c0:	79 87                	jns    105849 <vprintfmt+0x53>
                width = 0;
  1058c2:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
            goto reswitch;
  1058c9:	e9 7b ff ff ff       	jmp    105849 <vprintfmt+0x53>

        case '#':
            altflag = 1;
  1058ce:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
            goto reswitch;
  1058d5:	e9 6f ff ff ff       	jmp    105849 <vprintfmt+0x53>
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
            goto process_precision;
  1058da:	90                   	nop
        case '#':
            altflag = 1;
            goto reswitch;

        process_precision:
            if (width < 0)
  1058db:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  1058df:	0f 89 64 ff ff ff    	jns    105849 <vprintfmt+0x53>
                width = precision, precision = -1;
  1058e5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1058e8:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1058eb:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
            goto reswitch;
  1058f2:	e9 52 ff ff ff       	jmp    105849 <vprintfmt+0x53>

        // long flag (doubled for long long)
        case 'l':
            lflag ++;
  1058f7:	ff 45 e0             	incl   -0x20(%ebp)
            goto reswitch;
  1058fa:	e9 4a ff ff ff       	jmp    105849 <vprintfmt+0x53>

        // character
        case 'c':
            putch(va_arg(ap, int), putdat);
  1058ff:	8b 45 14             	mov    0x14(%ebp),%eax
  105902:	8d 50 04             	lea    0x4(%eax),%edx
  105905:	89 55 14             	mov    %edx,0x14(%ebp)
  105908:	8b 00                	mov    (%eax),%eax
  10590a:	8b 55 0c             	mov    0xc(%ebp),%edx
  10590d:	89 54 24 04          	mov    %edx,0x4(%esp)
  105911:	89 04 24             	mov    %eax,(%esp)
  105914:	8b 45 08             	mov    0x8(%ebp),%eax
  105917:	ff d0                	call   *%eax
            break;
  105919:	e9 a4 02 00 00       	jmp    105bc2 <vprintfmt+0x3cc>

        // error message
        case 'e':
            err = va_arg(ap, int);
  10591e:	8b 45 14             	mov    0x14(%ebp),%eax
  105921:	8d 50 04             	lea    0x4(%eax),%edx
  105924:	89 55 14             	mov    %edx,0x14(%ebp)
  105927:	8b 18                	mov    (%eax),%ebx
            if (err < 0) {
  105929:	85 db                	test   %ebx,%ebx
  10592b:	79 02                	jns    10592f <vprintfmt+0x139>
                err = -err;
  10592d:	f7 db                	neg    %ebx
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  10592f:	83 fb 06             	cmp    $0x6,%ebx
  105932:	7f 0b                	jg     10593f <vprintfmt+0x149>
  105934:	8b 34 9d 20 6e 10 00 	mov    0x106e20(,%ebx,4),%esi
  10593b:	85 f6                	test   %esi,%esi
  10593d:	75 23                	jne    105962 <vprintfmt+0x16c>
                printfmt(putch, putdat, "error %d", err);
  10593f:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  105943:	c7 44 24 08 4d 6e 10 	movl   $0x106e4d,0x8(%esp)
  10594a:	00 
  10594b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10594e:	89 44 24 04          	mov    %eax,0x4(%esp)
  105952:	8b 45 08             	mov    0x8(%ebp),%eax
  105955:	89 04 24             	mov    %eax,(%esp)
  105958:	e8 6a fe ff ff       	call   1057c7 <printfmt>
            }
            else {
                printfmt(putch, putdat, "%s", p);
            }
            break;
  10595d:	e9 60 02 00 00       	jmp    105bc2 <vprintfmt+0x3cc>
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
                printfmt(putch, putdat, "error %d", err);
            }
            else {
                printfmt(putch, putdat, "%s", p);
  105962:	89 74 24 0c          	mov    %esi,0xc(%esp)
  105966:	c7 44 24 08 56 6e 10 	movl   $0x106e56,0x8(%esp)
  10596d:	00 
  10596e:	8b 45 0c             	mov    0xc(%ebp),%eax
  105971:	89 44 24 04          	mov    %eax,0x4(%esp)
  105975:	8b 45 08             	mov    0x8(%ebp),%eax
  105978:	89 04 24             	mov    %eax,(%esp)
  10597b:	e8 47 fe ff ff       	call   1057c7 <printfmt>
            }
            break;
  105980:	e9 3d 02 00 00       	jmp    105bc2 <vprintfmt+0x3cc>

        // string
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
  105985:	8b 45 14             	mov    0x14(%ebp),%eax
  105988:	8d 50 04             	lea    0x4(%eax),%edx
  10598b:	89 55 14             	mov    %edx,0x14(%ebp)
  10598e:	8b 30                	mov    (%eax),%esi
  105990:	85 f6                	test   %esi,%esi
  105992:	75 05                	jne    105999 <vprintfmt+0x1a3>
                p = "(null)";
  105994:	be 59 6e 10 00       	mov    $0x106e59,%esi
            }
            if (width > 0 && padc != '-') {
  105999:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  10599d:	7e 76                	jle    105a15 <vprintfmt+0x21f>
  10599f:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
  1059a3:	74 70                	je     105a15 <vprintfmt+0x21f>
                for (width -= strnlen(p, precision); width > 0; width --) {
  1059a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1059a8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1059ac:	89 34 24             	mov    %esi,(%esp)
  1059af:	e8 f6 f7 ff ff       	call   1051aa <strnlen>
  1059b4:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1059b7:	29 c2                	sub    %eax,%edx
  1059b9:	89 d0                	mov    %edx,%eax
  1059bb:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1059be:	eb 16                	jmp    1059d6 <vprintfmt+0x1e0>
                    putch(padc, putdat);
  1059c0:	0f be 45 db          	movsbl -0x25(%ebp),%eax
  1059c4:	8b 55 0c             	mov    0xc(%ebp),%edx
  1059c7:	89 54 24 04          	mov    %edx,0x4(%esp)
  1059cb:	89 04 24             	mov    %eax,(%esp)
  1059ce:	8b 45 08             	mov    0x8(%ebp),%eax
  1059d1:	ff d0                	call   *%eax
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
                p = "(null)";
            }
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
  1059d3:	ff 4d e8             	decl   -0x18(%ebp)
  1059d6:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  1059da:	7f e4                	jg     1059c0 <vprintfmt+0x1ca>
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  1059dc:	eb 37                	jmp    105a15 <vprintfmt+0x21f>
                if (altflag && (ch < ' ' || ch > '~')) {
  1059de:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  1059e2:	74 1f                	je     105a03 <vprintfmt+0x20d>
  1059e4:	83 fb 1f             	cmp    $0x1f,%ebx
  1059e7:	7e 05                	jle    1059ee <vprintfmt+0x1f8>
  1059e9:	83 fb 7e             	cmp    $0x7e,%ebx
  1059ec:	7e 15                	jle    105a03 <vprintfmt+0x20d>
                    putch('?', putdat);
  1059ee:	8b 45 0c             	mov    0xc(%ebp),%eax
  1059f1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1059f5:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  1059fc:	8b 45 08             	mov    0x8(%ebp),%eax
  1059ff:	ff d0                	call   *%eax
  105a01:	eb 0f                	jmp    105a12 <vprintfmt+0x21c>
                }
                else {
                    putch(ch, putdat);
  105a03:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a06:	89 44 24 04          	mov    %eax,0x4(%esp)
  105a0a:	89 1c 24             	mov    %ebx,(%esp)
  105a0d:	8b 45 08             	mov    0x8(%ebp),%eax
  105a10:	ff d0                	call   *%eax
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  105a12:	ff 4d e8             	decl   -0x18(%ebp)
  105a15:	89 f0                	mov    %esi,%eax
  105a17:	8d 70 01             	lea    0x1(%eax),%esi
  105a1a:	0f b6 00             	movzbl (%eax),%eax
  105a1d:	0f be d8             	movsbl %al,%ebx
  105a20:	85 db                	test   %ebx,%ebx
  105a22:	74 27                	je     105a4b <vprintfmt+0x255>
  105a24:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  105a28:	78 b4                	js     1059de <vprintfmt+0x1e8>
  105a2a:	ff 4d e4             	decl   -0x1c(%ebp)
  105a2d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  105a31:	79 ab                	jns    1059de <vprintfmt+0x1e8>
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
  105a33:	eb 16                	jmp    105a4b <vprintfmt+0x255>
                putch(' ', putdat);
  105a35:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a38:	89 44 24 04          	mov    %eax,0x4(%esp)
  105a3c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  105a43:	8b 45 08             	mov    0x8(%ebp),%eax
  105a46:	ff d0                	call   *%eax
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
  105a48:	ff 4d e8             	decl   -0x18(%ebp)
  105a4b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  105a4f:	7f e4                	jg     105a35 <vprintfmt+0x23f>
                putch(' ', putdat);
            }
            break;
  105a51:	e9 6c 01 00 00       	jmp    105bc2 <vprintfmt+0x3cc>

        // (signed) decimal
        case 'd':
            num = getint(&ap, lflag);
  105a56:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105a59:	89 44 24 04          	mov    %eax,0x4(%esp)
  105a5d:	8d 45 14             	lea    0x14(%ebp),%eax
  105a60:	89 04 24             	mov    %eax,(%esp)
  105a63:	e8 18 fd ff ff       	call   105780 <getint>
  105a68:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105a6b:	89 55 f4             	mov    %edx,-0xc(%ebp)
            if ((long long)num < 0) {
  105a6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105a71:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105a74:	85 d2                	test   %edx,%edx
  105a76:	79 26                	jns    105a9e <vprintfmt+0x2a8>
                putch('-', putdat);
  105a78:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a7b:	89 44 24 04          	mov    %eax,0x4(%esp)
  105a7f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  105a86:	8b 45 08             	mov    0x8(%ebp),%eax
  105a89:	ff d0                	call   *%eax
                num = -(long long)num;
  105a8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105a8e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105a91:	f7 d8                	neg    %eax
  105a93:	83 d2 00             	adc    $0x0,%edx
  105a96:	f7 da                	neg    %edx
  105a98:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105a9b:	89 55 f4             	mov    %edx,-0xc(%ebp)
            }
            base = 10;
  105a9e:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
  105aa5:	e9 a8 00 00 00       	jmp    105b52 <vprintfmt+0x35c>

        // unsigned decimal
        case 'u':
            num = getuint(&ap, lflag);
  105aaa:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105aad:	89 44 24 04          	mov    %eax,0x4(%esp)
  105ab1:	8d 45 14             	lea    0x14(%ebp),%eax
  105ab4:	89 04 24             	mov    %eax,(%esp)
  105ab7:	e8 75 fc ff ff       	call   105731 <getuint>
  105abc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105abf:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 10;
  105ac2:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
  105ac9:	e9 84 00 00 00       	jmp    105b52 <vprintfmt+0x35c>

        // (unsigned) octal
        case 'o':
            num = getuint(&ap, lflag);
  105ace:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105ad1:	89 44 24 04          	mov    %eax,0x4(%esp)
  105ad5:	8d 45 14             	lea    0x14(%ebp),%eax
  105ad8:	89 04 24             	mov    %eax,(%esp)
  105adb:	e8 51 fc ff ff       	call   105731 <getuint>
  105ae0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105ae3:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 8;
  105ae6:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
            goto number;
  105aed:	eb 63                	jmp    105b52 <vprintfmt+0x35c>

        // pointer
        case 'p':
            putch('0', putdat);
  105aef:	8b 45 0c             	mov    0xc(%ebp),%eax
  105af2:	89 44 24 04          	mov    %eax,0x4(%esp)
  105af6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  105afd:	8b 45 08             	mov    0x8(%ebp),%eax
  105b00:	ff d0                	call   *%eax
            putch('x', putdat);
  105b02:	8b 45 0c             	mov    0xc(%ebp),%eax
  105b05:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b09:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  105b10:	8b 45 08             	mov    0x8(%ebp),%eax
  105b13:	ff d0                	call   *%eax
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  105b15:	8b 45 14             	mov    0x14(%ebp),%eax
  105b18:	8d 50 04             	lea    0x4(%eax),%edx
  105b1b:	89 55 14             	mov    %edx,0x14(%ebp)
  105b1e:	8b 00                	mov    (%eax),%eax
  105b20:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105b23:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
            base = 16;
  105b2a:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
            goto number;
  105b31:	eb 1f                	jmp    105b52 <vprintfmt+0x35c>

        // (unsigned) hexadecimal
        case 'x':
            num = getuint(&ap, lflag);
  105b33:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105b36:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b3a:	8d 45 14             	lea    0x14(%ebp),%eax
  105b3d:	89 04 24             	mov    %eax,(%esp)
  105b40:	e8 ec fb ff ff       	call   105731 <getuint>
  105b45:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105b48:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 16;
  105b4b:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
        number:
            printnum(putch, putdat, num, base, width, padc);
  105b52:	0f be 55 db          	movsbl -0x25(%ebp),%edx
  105b56:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105b59:	89 54 24 18          	mov    %edx,0x18(%esp)
  105b5d:	8b 55 e8             	mov    -0x18(%ebp),%edx
  105b60:	89 54 24 14          	mov    %edx,0x14(%esp)
  105b64:	89 44 24 10          	mov    %eax,0x10(%esp)
  105b68:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105b6b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105b6e:	89 44 24 08          	mov    %eax,0x8(%esp)
  105b72:	89 54 24 0c          	mov    %edx,0xc(%esp)
  105b76:	8b 45 0c             	mov    0xc(%ebp),%eax
  105b79:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b7d:	8b 45 08             	mov    0x8(%ebp),%eax
  105b80:	89 04 24             	mov    %eax,(%esp)
  105b83:	e8 a4 fa ff ff       	call   10562c <printnum>
            break;
  105b88:	eb 38                	jmp    105bc2 <vprintfmt+0x3cc>

        // escaped '%' character
        case '%':
            putch(ch, putdat);
  105b8a:	8b 45 0c             	mov    0xc(%ebp),%eax
  105b8d:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b91:	89 1c 24             	mov    %ebx,(%esp)
  105b94:	8b 45 08             	mov    0x8(%ebp),%eax
  105b97:	ff d0                	call   *%eax
            break;
  105b99:	eb 27                	jmp    105bc2 <vprintfmt+0x3cc>

        // unrecognized escape sequence - just print it literally
        default:
            putch('%', putdat);
  105b9b:	8b 45 0c             	mov    0xc(%ebp),%eax
  105b9e:	89 44 24 04          	mov    %eax,0x4(%esp)
  105ba2:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  105ba9:	8b 45 08             	mov    0x8(%ebp),%eax
  105bac:	ff d0                	call   *%eax
            for (fmt --; fmt[-1] != '%'; fmt --)
  105bae:	ff 4d 10             	decl   0x10(%ebp)
  105bb1:	eb 03                	jmp    105bb6 <vprintfmt+0x3c0>
  105bb3:	ff 4d 10             	decl   0x10(%ebp)
  105bb6:	8b 45 10             	mov    0x10(%ebp),%eax
  105bb9:	48                   	dec    %eax
  105bba:	0f b6 00             	movzbl (%eax),%eax
  105bbd:	3c 25                	cmp    $0x25,%al
  105bbf:	75 f2                	jne    105bb3 <vprintfmt+0x3bd>
                /* do nothing */;
            break;
  105bc1:	90                   	nop
        }
    }
  105bc2:	e9 37 fc ff ff       	jmp    1057fe <vprintfmt+0x8>
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
            if (ch == '\0') {
                return;
  105bc7:	90                   	nop
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  105bc8:	83 c4 40             	add    $0x40,%esp
  105bcb:	5b                   	pop    %ebx
  105bcc:	5e                   	pop    %esi
  105bcd:	5d                   	pop    %ebp
  105bce:	c3                   	ret    

00105bcf <sprintputch>:
 * sprintputch - 'print' a single character in a buffer
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
  105bcf:	55                   	push   %ebp
  105bd0:	89 e5                	mov    %esp,%ebp
    b->cnt ++;
  105bd2:	8b 45 0c             	mov    0xc(%ebp),%eax
  105bd5:	8b 40 08             	mov    0x8(%eax),%eax
  105bd8:	8d 50 01             	lea    0x1(%eax),%edx
  105bdb:	8b 45 0c             	mov    0xc(%ebp),%eax
  105bde:	89 50 08             	mov    %edx,0x8(%eax)
    if (b->buf < b->ebuf) {
  105be1:	8b 45 0c             	mov    0xc(%ebp),%eax
  105be4:	8b 10                	mov    (%eax),%edx
  105be6:	8b 45 0c             	mov    0xc(%ebp),%eax
  105be9:	8b 40 04             	mov    0x4(%eax),%eax
  105bec:	39 c2                	cmp    %eax,%edx
  105bee:	73 12                	jae    105c02 <sprintputch+0x33>
        *b->buf ++ = ch;
  105bf0:	8b 45 0c             	mov    0xc(%ebp),%eax
  105bf3:	8b 00                	mov    (%eax),%eax
  105bf5:	8d 48 01             	lea    0x1(%eax),%ecx
  105bf8:	8b 55 0c             	mov    0xc(%ebp),%edx
  105bfb:	89 0a                	mov    %ecx,(%edx)
  105bfd:	8b 55 08             	mov    0x8(%ebp),%edx
  105c00:	88 10                	mov    %dl,(%eax)
    }
}
  105c02:	90                   	nop
  105c03:	5d                   	pop    %ebp
  105c04:	c3                   	ret    

00105c05 <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
  105c05:	55                   	push   %ebp
  105c06:	89 e5                	mov    %esp,%ebp
  105c08:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
  105c0b:	8d 45 14             	lea    0x14(%ebp),%eax
  105c0e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vsnprintf(str, size, fmt, ap);
  105c11:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105c14:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105c18:	8b 45 10             	mov    0x10(%ebp),%eax
  105c1b:	89 44 24 08          	mov    %eax,0x8(%esp)
  105c1f:	8b 45 0c             	mov    0xc(%ebp),%eax
  105c22:	89 44 24 04          	mov    %eax,0x4(%esp)
  105c26:	8b 45 08             	mov    0x8(%ebp),%eax
  105c29:	89 04 24             	mov    %eax,(%esp)
  105c2c:	e8 08 00 00 00       	call   105c39 <vsnprintf>
  105c31:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
  105c34:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  105c37:	c9                   	leave  
  105c38:	c3                   	ret    

00105c39 <vsnprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
  105c39:	55                   	push   %ebp
  105c3a:	89 e5                	mov    %esp,%ebp
  105c3c:	83 ec 28             	sub    $0x28,%esp
    struct sprintbuf b = {str, str + size - 1, 0};
  105c3f:	8b 45 08             	mov    0x8(%ebp),%eax
  105c42:	89 45 ec             	mov    %eax,-0x14(%ebp)
  105c45:	8b 45 0c             	mov    0xc(%ebp),%eax
  105c48:	8d 50 ff             	lea    -0x1(%eax),%edx
  105c4b:	8b 45 08             	mov    0x8(%ebp),%eax
  105c4e:	01 d0                	add    %edx,%eax
  105c50:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105c53:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if (str == NULL || b.buf > b.ebuf) {
  105c5a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  105c5e:	74 0a                	je     105c6a <vsnprintf+0x31>
  105c60:	8b 55 ec             	mov    -0x14(%ebp),%edx
  105c63:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105c66:	39 c2                	cmp    %eax,%edx
  105c68:	76 07                	jbe    105c71 <vsnprintf+0x38>
        return -E_INVAL;
  105c6a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  105c6f:	eb 2a                	jmp    105c9b <vsnprintf+0x62>
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
  105c71:	8b 45 14             	mov    0x14(%ebp),%eax
  105c74:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105c78:	8b 45 10             	mov    0x10(%ebp),%eax
  105c7b:	89 44 24 08          	mov    %eax,0x8(%esp)
  105c7f:	8d 45 ec             	lea    -0x14(%ebp),%eax
  105c82:	89 44 24 04          	mov    %eax,0x4(%esp)
  105c86:	c7 04 24 cf 5b 10 00 	movl   $0x105bcf,(%esp)
  105c8d:	e8 64 fb ff ff       	call   1057f6 <vprintfmt>
    // null terminate the buffer
    *b.buf = '\0';
  105c92:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105c95:	c6 00 00             	movb   $0x0,(%eax)
    return b.cnt;
  105c98:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  105c9b:	c9                   	leave  
  105c9c:	c3                   	ret    
