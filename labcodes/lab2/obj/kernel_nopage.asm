
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
  10005d:	e8 1f 56 00 00       	call   105681 <memset>

    cons_init();                // init the console
  100062:	e8 be 14 00 00       	call   101525 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
  100067:	c7 45 f4 80 5e 10 00 	movl   $0x105e80,-0xc(%ebp)
    cprintf("%s\n\n", message);
  10006e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100071:	89 44 24 04          	mov    %eax,0x4(%esp)
  100075:	c7 04 24 9c 5e 10 00 	movl   $0x105e9c,(%esp)
  10007c:	e8 11 02 00 00       	call   100292 <cprintf>

    print_kerninfo();
  100081:	e8 b2 08 00 00       	call   100938 <print_kerninfo>

    grade_backtrace();
  100086:	e8 89 00 00 00       	call   100114 <grade_backtrace>

    pmm_init();                 // init physical memory management
  10008b:	e8 c1 2f 00 00       	call   103051 <pmm_init>

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
  100162:	c7 04 24 a1 5e 10 00 	movl   $0x105ea1,(%esp)
  100169:	e8 24 01 00 00       	call   100292 <cprintf>
    cprintf("%d:  cs = %x\n", round, reg1);
  10016e:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  100172:	89 c2                	mov    %eax,%edx
  100174:	a1 00 a0 11 00       	mov    0x11a000,%eax
  100179:	89 54 24 08          	mov    %edx,0x8(%esp)
  10017d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100181:	c7 04 24 af 5e 10 00 	movl   $0x105eaf,(%esp)
  100188:	e8 05 01 00 00       	call   100292 <cprintf>
    cprintf("%d:  ds = %x\n", round, reg2);
  10018d:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
  100191:	89 c2                	mov    %eax,%edx
  100193:	a1 00 a0 11 00       	mov    0x11a000,%eax
  100198:	89 54 24 08          	mov    %edx,0x8(%esp)
  10019c:	89 44 24 04          	mov    %eax,0x4(%esp)
  1001a0:	c7 04 24 bd 5e 10 00 	movl   $0x105ebd,(%esp)
  1001a7:	e8 e6 00 00 00       	call   100292 <cprintf>
    cprintf("%d:  es = %x\n", round, reg3);
  1001ac:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
  1001b0:	89 c2                	mov    %eax,%edx
  1001b2:	a1 00 a0 11 00       	mov    0x11a000,%eax
  1001b7:	89 54 24 08          	mov    %edx,0x8(%esp)
  1001bb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1001bf:	c7 04 24 cb 5e 10 00 	movl   $0x105ecb,(%esp)
  1001c6:	e8 c7 00 00 00       	call   100292 <cprintf>
    cprintf("%d:  ss = %x\n", round, reg4);
  1001cb:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
  1001cf:	89 c2                	mov    %eax,%edx
  1001d1:	a1 00 a0 11 00       	mov    0x11a000,%eax
  1001d6:	89 54 24 08          	mov    %edx,0x8(%esp)
  1001da:	89 44 24 04          	mov    %eax,0x4(%esp)
  1001de:	c7 04 24 d9 5e 10 00 	movl   $0x105ed9,(%esp)
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
  10020f:	c7 04 24 e8 5e 10 00 	movl   $0x105ee8,(%esp)
  100216:	e8 77 00 00 00       	call   100292 <cprintf>
    lab1_switch_to_user();
  10021b:	e8 d8 ff ff ff       	call   1001f8 <lab1_switch_to_user>
    lab1_print_cur_status();
  100220:	e8 15 ff ff ff       	call   10013a <lab1_print_cur_status>
    cprintf("+++ switch to kernel mode +++\n");
  100225:	c7 04 24 08 5f 10 00 	movl   $0x105f08,(%esp)
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
  100288:	e8 47 57 00 00       	call   1059d4 <vprintfmt>
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
  100347:	c7 04 24 27 5f 10 00 	movl   $0x105f27,(%esp)
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
  100416:	c7 04 24 2a 5f 10 00 	movl   $0x105f2a,(%esp)
  10041d:	e8 70 fe ff ff       	call   100292 <cprintf>
    vcprintf(fmt, ap);
  100422:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100425:	89 44 24 04          	mov    %eax,0x4(%esp)
  100429:	8b 45 10             	mov    0x10(%ebp),%eax
  10042c:	89 04 24             	mov    %eax,(%esp)
  10042f:	e8 2b fe ff ff       	call   10025f <vcprintf>
    cprintf("\n");
  100434:	c7 04 24 46 5f 10 00 	movl   $0x105f46,(%esp)
  10043b:	e8 52 fe ff ff       	call   100292 <cprintf>
    
    cprintf("stack trackback:\n");
  100440:	c7 04 24 48 5f 10 00 	movl   $0x105f48,(%esp)
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
  100481:	c7 04 24 5a 5f 10 00 	movl   $0x105f5a,(%esp)
  100488:	e8 05 fe ff ff       	call   100292 <cprintf>
    vcprintf(fmt, ap);
  10048d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100490:	89 44 24 04          	mov    %eax,0x4(%esp)
  100494:	8b 45 10             	mov    0x10(%ebp),%eax
  100497:	89 04 24             	mov    %eax,(%esp)
  10049a:	e8 c0 fd ff ff       	call   10025f <vcprintf>
    cprintf("\n");
  10049f:	c7 04 24 46 5f 10 00 	movl   $0x105f46,(%esp)
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
  10060f:	c7 00 78 5f 10 00    	movl   $0x105f78,(%eax)
    info->eip_line = 0;
  100615:	8b 45 0c             	mov    0xc(%ebp),%eax
  100618:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
    info->eip_fn_name = "<unknown>";
  10061f:	8b 45 0c             	mov    0xc(%ebp),%eax
  100622:	c7 40 08 78 5f 10 00 	movl   $0x105f78,0x8(%eax)
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
  100646:	c7 45 f4 98 71 10 00 	movl   $0x107198,-0xc(%ebp)
    stab_end = __STAB_END__;
  10064d:	c7 45 f0 38 1f 11 00 	movl   $0x111f38,-0x10(%ebp)
    stabstr = __STABSTR_BEGIN__;
  100654:	c7 45 ec 39 1f 11 00 	movl   $0x111f39,-0x14(%ebp)
    stabstr_end = __STABSTR_END__;
  10065b:	c7 45 e8 e4 49 11 00 	movl   $0x1149e4,-0x18(%ebp)

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
  1007b6:	e8 42 4d 00 00       	call   1054fd <strfind>
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
  10093e:	c7 04 24 82 5f 10 00 	movl   $0x105f82,(%esp)
  100945:	e8 48 f9 ff ff       	call   100292 <cprintf>
    cprintf("  entry  0x%08x (phys)\n", kern_init);
  10094a:	c7 44 24 04 36 00 10 	movl   $0x100036,0x4(%esp)
  100951:	00 
  100952:	c7 04 24 9b 5f 10 00 	movl   $0x105f9b,(%esp)
  100959:	e8 34 f9 ff ff       	call   100292 <cprintf>
    cprintf("  etext  0x%08x (phys)\n", etext);
  10095e:	c7 44 24 04 7b 5e 10 	movl   $0x105e7b,0x4(%esp)
  100965:	00 
  100966:	c7 04 24 b3 5f 10 00 	movl   $0x105fb3,(%esp)
  10096d:	e8 20 f9 ff ff       	call   100292 <cprintf>
    cprintf("  edata  0x%08x (phys)\n", edata);
  100972:	c7 44 24 04 36 7a 11 	movl   $0x117a36,0x4(%esp)
  100979:	00 
  10097a:	c7 04 24 cb 5f 10 00 	movl   $0x105fcb,(%esp)
  100981:	e8 0c f9 ff ff       	call   100292 <cprintf>
    cprintf("  end    0x%08x (phys)\n", end);
  100986:	c7 44 24 04 28 af 11 	movl   $0x11af28,0x4(%esp)
  10098d:	00 
  10098e:	c7 04 24 e3 5f 10 00 	movl   $0x105fe3,(%esp)
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
  1009c0:	c7 04 24 fc 5f 10 00 	movl   $0x105ffc,(%esp)
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
  1009f5:	c7 04 24 26 60 10 00 	movl   $0x106026,(%esp)
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
  100a63:	c7 04 24 42 60 10 00 	movl   $0x106042,(%esp)
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
  100abb:	c7 04 24 d4 60 10 00 	movl   $0x1060d4,(%esp)
  100ac2:	e8 04 4a 00 00       	call   1054cb <strchr>
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
  100ae3:	c7 04 24 d9 60 10 00 	movl   $0x1060d9,(%esp)
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
  100b29:	c7 04 24 d4 60 10 00 	movl   $0x1060d4,(%esp)
  100b30:	e8 96 49 00 00       	call   1054cb <strchr>
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
  100b96:	e8 93 48 00 00       	call   10542e <strcmp>
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
  100be2:	c7 04 24 f7 60 10 00 	movl   $0x1060f7,(%esp)
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
  100bff:	c7 04 24 10 61 10 00 	movl   $0x106110,(%esp)
  100c06:	e8 87 f6 ff ff       	call   100292 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
  100c0b:	c7 04 24 38 61 10 00 	movl   $0x106138,(%esp)
  100c12:	e8 7b f6 ff ff       	call   100292 <cprintf>

    if (tf != NULL) {
  100c17:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  100c1b:	74 0b                	je     100c28 <kmonitor+0x2f>
        print_trapframe(tf);
  100c1d:	8b 45 08             	mov    0x8(%ebp),%eax
  100c20:	89 04 24             	mov    %eax,(%esp)
  100c23:	e8 f9 0c 00 00       	call   101921 <print_trapframe>
    }

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
  100c28:	c7 04 24 5d 61 10 00 	movl   $0x10615d,(%esp)
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
  100c96:	c7 04 24 61 61 10 00 	movl   $0x106161,(%esp)
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
  100d20:	c7 04 24 6a 61 10 00 	movl   $0x10616a,(%esp)
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
  101156:	e8 66 45 00 00       	call   1056c1 <memmove>
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
  1014d2:	c7 04 24 85 61 10 00 	movl   $0x106185,(%esp)
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
  101543:	c7 04 24 91 61 10 00 	movl   $0x106191,(%esp)
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
  1017d8:	c7 04 24 c0 61 10 00 	movl   $0x1061c0,(%esp)
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
  1017ea:	83 ec 10             	sub    $0x10,%esp
      * (3) After setup the contents of IDT, you will let CPU know where is the IDT by using 'lidt' instruction.
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
    extern uintptr_t __vectors[];
    for (int i = 0; i < sizeof(idt) / sizeof(struct gatedesc); i++) {
  1017ed:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1017f4:	e9 c4 00 00 00       	jmp    1018bd <idt_init+0xd6>
	SETGATE(idt[i], 0, GD_KTEXT, __vectors[i], DPL_KERNEL);
  1017f9:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1017fc:	8b 04 85 e0 75 11 00 	mov    0x1175e0(,%eax,4),%eax
  101803:	0f b7 d0             	movzwl %ax,%edx
  101806:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101809:	66 89 14 c5 80 a6 11 	mov    %dx,0x11a680(,%eax,8)
  101810:	00 
  101811:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101814:	66 c7 04 c5 82 a6 11 	movw   $0x8,0x11a682(,%eax,8)
  10181b:	00 08 00 
  10181e:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101821:	0f b6 14 c5 84 a6 11 	movzbl 0x11a684(,%eax,8),%edx
  101828:	00 
  101829:	80 e2 e0             	and    $0xe0,%dl
  10182c:	88 14 c5 84 a6 11 00 	mov    %dl,0x11a684(,%eax,8)
  101833:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101836:	0f b6 14 c5 84 a6 11 	movzbl 0x11a684(,%eax,8),%edx
  10183d:	00 
  10183e:	80 e2 1f             	and    $0x1f,%dl
  101841:	88 14 c5 84 a6 11 00 	mov    %dl,0x11a684(,%eax,8)
  101848:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10184b:	0f b6 14 c5 85 a6 11 	movzbl 0x11a685(,%eax,8),%edx
  101852:	00 
  101853:	80 e2 f0             	and    $0xf0,%dl
  101856:	80 ca 0e             	or     $0xe,%dl
  101859:	88 14 c5 85 a6 11 00 	mov    %dl,0x11a685(,%eax,8)
  101860:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101863:	0f b6 14 c5 85 a6 11 	movzbl 0x11a685(,%eax,8),%edx
  10186a:	00 
  10186b:	80 e2 ef             	and    $0xef,%dl
  10186e:	88 14 c5 85 a6 11 00 	mov    %dl,0x11a685(,%eax,8)
  101875:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101878:	0f b6 14 c5 85 a6 11 	movzbl 0x11a685(,%eax,8),%edx
  10187f:	00 
  101880:	80 e2 9f             	and    $0x9f,%dl
  101883:	88 14 c5 85 a6 11 00 	mov    %dl,0x11a685(,%eax,8)
  10188a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10188d:	0f b6 14 c5 85 a6 11 	movzbl 0x11a685(,%eax,8),%edx
  101894:	00 
  101895:	80 ca 80             	or     $0x80,%dl
  101898:	88 14 c5 85 a6 11 00 	mov    %dl,0x11a685(,%eax,8)
  10189f:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1018a2:	8b 04 85 e0 75 11 00 	mov    0x1175e0(,%eax,4),%eax
  1018a9:	c1 e8 10             	shr    $0x10,%eax
  1018ac:	0f b7 d0             	movzwl %ax,%edx
  1018af:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1018b2:	66 89 14 c5 86 a6 11 	mov    %dx,0x11a686(,%eax,8)
  1018b9:	00 
      * (3) After setup the contents of IDT, you will let CPU know where is the IDT by using 'lidt' instruction.
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
    extern uintptr_t __vectors[];
    for (int i = 0; i < sizeof(idt) / sizeof(struct gatedesc); i++) {
  1018ba:	ff 45 fc             	incl   -0x4(%ebp)
  1018bd:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1018c0:	3d ff 00 00 00       	cmp    $0xff,%eax
  1018c5:	0f 86 2e ff ff ff    	jbe    1017f9 <idt_init+0x12>
  1018cb:	c7 45 f8 60 75 11 00 	movl   $0x117560,-0x8(%ebp)
    }
}

static inline void
lidt(struct pseudodesc *pd) {
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
  1018d2:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1018d5:	0f 01 18             	lidtl  (%eax)
	SETGATE(idt[i], 0, GD_KTEXT, __vectors[i], DPL_KERNEL);
    }
    lidt(&idt_pd);
}
  1018d8:	90                   	nop
  1018d9:	c9                   	leave  
  1018da:	c3                   	ret    

001018db <trapname>:

static const char *
trapname(int trapno) {
  1018db:	55                   	push   %ebp
  1018dc:	89 e5                	mov    %esp,%ebp
        "Alignment Check",
        "Machine-Check",
        "SIMD Floating-Point Exception"
    };

    if (trapno < sizeof(excnames)/sizeof(const char * const)) {
  1018de:	8b 45 08             	mov    0x8(%ebp),%eax
  1018e1:	83 f8 13             	cmp    $0x13,%eax
  1018e4:	77 0c                	ja     1018f2 <trapname+0x17>
        return excnames[trapno];
  1018e6:	8b 45 08             	mov    0x8(%ebp),%eax
  1018e9:	8b 04 85 20 65 10 00 	mov    0x106520(,%eax,4),%eax
  1018f0:	eb 18                	jmp    10190a <trapname+0x2f>
    }
    if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16) {
  1018f2:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  1018f6:	7e 0d                	jle    101905 <trapname+0x2a>
  1018f8:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  1018fc:	7f 07                	jg     101905 <trapname+0x2a>
        return "Hardware Interrupt";
  1018fe:	b8 ca 61 10 00       	mov    $0x1061ca,%eax
  101903:	eb 05                	jmp    10190a <trapname+0x2f>
    }
    return "(unknown trap)";
  101905:	b8 dd 61 10 00       	mov    $0x1061dd,%eax
}
  10190a:	5d                   	pop    %ebp
  10190b:	c3                   	ret    

0010190c <trap_in_kernel>:

/* trap_in_kernel - test if trap happened in kernel */
bool
trap_in_kernel(struct trapframe *tf) {
  10190c:	55                   	push   %ebp
  10190d:	89 e5                	mov    %esp,%ebp
    return (tf->tf_cs == (uint16_t)KERNEL_CS);
  10190f:	8b 45 08             	mov    0x8(%ebp),%eax
  101912:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101916:	83 f8 08             	cmp    $0x8,%eax
  101919:	0f 94 c0             	sete   %al
  10191c:	0f b6 c0             	movzbl %al,%eax
}
  10191f:	5d                   	pop    %ebp
  101920:	c3                   	ret    

00101921 <print_trapframe>:
    "TF", "IF", "DF", "OF", NULL, NULL, "NT", NULL,
    "RF", "VM", "AC", "VIF", "VIP", "ID", NULL, NULL,
};

void
print_trapframe(struct trapframe *tf) {
  101921:	55                   	push   %ebp
  101922:	89 e5                	mov    %esp,%ebp
  101924:	83 ec 28             	sub    $0x28,%esp
    cprintf("trapframe at %p\n", tf);
  101927:	8b 45 08             	mov    0x8(%ebp),%eax
  10192a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10192e:	c7 04 24 1e 62 10 00 	movl   $0x10621e,(%esp)
  101935:	e8 58 e9 ff ff       	call   100292 <cprintf>
    print_regs(&tf->tf_regs);
  10193a:	8b 45 08             	mov    0x8(%ebp),%eax
  10193d:	89 04 24             	mov    %eax,(%esp)
  101940:	e8 91 01 00 00       	call   101ad6 <print_regs>
    cprintf("  ds   0x----%04x\n", tf->tf_ds);
  101945:	8b 45 08             	mov    0x8(%ebp),%eax
  101948:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10194c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101950:	c7 04 24 2f 62 10 00 	movl   $0x10622f,(%esp)
  101957:	e8 36 e9 ff ff       	call   100292 <cprintf>
    cprintf("  es   0x----%04x\n", tf->tf_es);
  10195c:	8b 45 08             	mov    0x8(%ebp),%eax
  10195f:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101963:	89 44 24 04          	mov    %eax,0x4(%esp)
  101967:	c7 04 24 42 62 10 00 	movl   $0x106242,(%esp)
  10196e:	e8 1f e9 ff ff       	call   100292 <cprintf>
    cprintf("  fs   0x----%04x\n", tf->tf_fs);
  101973:	8b 45 08             	mov    0x8(%ebp),%eax
  101976:	0f b7 40 24          	movzwl 0x24(%eax),%eax
  10197a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10197e:	c7 04 24 55 62 10 00 	movl   $0x106255,(%esp)
  101985:	e8 08 e9 ff ff       	call   100292 <cprintf>
    cprintf("  gs   0x----%04x\n", tf->tf_gs);
  10198a:	8b 45 08             	mov    0x8(%ebp),%eax
  10198d:	0f b7 40 20          	movzwl 0x20(%eax),%eax
  101991:	89 44 24 04          	mov    %eax,0x4(%esp)
  101995:	c7 04 24 68 62 10 00 	movl   $0x106268,(%esp)
  10199c:	e8 f1 e8 ff ff       	call   100292 <cprintf>
    cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
  1019a1:	8b 45 08             	mov    0x8(%ebp),%eax
  1019a4:	8b 40 30             	mov    0x30(%eax),%eax
  1019a7:	89 04 24             	mov    %eax,(%esp)
  1019aa:	e8 2c ff ff ff       	call   1018db <trapname>
  1019af:	89 c2                	mov    %eax,%edx
  1019b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1019b4:	8b 40 30             	mov    0x30(%eax),%eax
  1019b7:	89 54 24 08          	mov    %edx,0x8(%esp)
  1019bb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1019bf:	c7 04 24 7b 62 10 00 	movl   $0x10627b,(%esp)
  1019c6:	e8 c7 e8 ff ff       	call   100292 <cprintf>
    cprintf("  err  0x%08x\n", tf->tf_err);
  1019cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1019ce:	8b 40 34             	mov    0x34(%eax),%eax
  1019d1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1019d5:	c7 04 24 8d 62 10 00 	movl   $0x10628d,(%esp)
  1019dc:	e8 b1 e8 ff ff       	call   100292 <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
  1019e1:	8b 45 08             	mov    0x8(%ebp),%eax
  1019e4:	8b 40 38             	mov    0x38(%eax),%eax
  1019e7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1019eb:	c7 04 24 9c 62 10 00 	movl   $0x10629c,(%esp)
  1019f2:	e8 9b e8 ff ff       	call   100292 <cprintf>
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
  1019f7:	8b 45 08             	mov    0x8(%ebp),%eax
  1019fa:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1019fe:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a02:	c7 04 24 ab 62 10 00 	movl   $0x1062ab,(%esp)
  101a09:	e8 84 e8 ff ff       	call   100292 <cprintf>
    cprintf("  flag 0x%08x ", tf->tf_eflags);
  101a0e:	8b 45 08             	mov    0x8(%ebp),%eax
  101a11:	8b 40 40             	mov    0x40(%eax),%eax
  101a14:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a18:	c7 04 24 be 62 10 00 	movl   $0x1062be,(%esp)
  101a1f:	e8 6e e8 ff ff       	call   100292 <cprintf>

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
  101a24:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  101a2b:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
  101a32:	eb 3d                	jmp    101a71 <print_trapframe+0x150>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
  101a34:	8b 45 08             	mov    0x8(%ebp),%eax
  101a37:	8b 50 40             	mov    0x40(%eax),%edx
  101a3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101a3d:	21 d0                	and    %edx,%eax
  101a3f:	85 c0                	test   %eax,%eax
  101a41:	74 28                	je     101a6b <print_trapframe+0x14a>
  101a43:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101a46:	8b 04 85 80 75 11 00 	mov    0x117580(,%eax,4),%eax
  101a4d:	85 c0                	test   %eax,%eax
  101a4f:	74 1a                	je     101a6b <print_trapframe+0x14a>
            cprintf("%s,", IA32flags[i]);
  101a51:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101a54:	8b 04 85 80 75 11 00 	mov    0x117580(,%eax,4),%eax
  101a5b:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a5f:	c7 04 24 cd 62 10 00 	movl   $0x1062cd,(%esp)
  101a66:	e8 27 e8 ff ff       	call   100292 <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
    cprintf("  flag 0x%08x ", tf->tf_eflags);

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
  101a6b:	ff 45 f4             	incl   -0xc(%ebp)
  101a6e:	d1 65 f0             	shll   -0x10(%ebp)
  101a71:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101a74:	83 f8 17             	cmp    $0x17,%eax
  101a77:	76 bb                	jbe    101a34 <print_trapframe+0x113>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
            cprintf("%s,", IA32flags[i]);
        }
    }
    cprintf("IOPL=%d\n", (tf->tf_eflags & FL_IOPL_MASK) >> 12);
  101a79:	8b 45 08             	mov    0x8(%ebp),%eax
  101a7c:	8b 40 40             	mov    0x40(%eax),%eax
  101a7f:	25 00 30 00 00       	and    $0x3000,%eax
  101a84:	c1 e8 0c             	shr    $0xc,%eax
  101a87:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a8b:	c7 04 24 d1 62 10 00 	movl   $0x1062d1,(%esp)
  101a92:	e8 fb e7 ff ff       	call   100292 <cprintf>

    if (!trap_in_kernel(tf)) {
  101a97:	8b 45 08             	mov    0x8(%ebp),%eax
  101a9a:	89 04 24             	mov    %eax,(%esp)
  101a9d:	e8 6a fe ff ff       	call   10190c <trap_in_kernel>
  101aa2:	85 c0                	test   %eax,%eax
  101aa4:	75 2d                	jne    101ad3 <print_trapframe+0x1b2>
        cprintf("  esp  0x%08x\n", tf->tf_esp);
  101aa6:	8b 45 08             	mov    0x8(%ebp),%eax
  101aa9:	8b 40 44             	mov    0x44(%eax),%eax
  101aac:	89 44 24 04          	mov    %eax,0x4(%esp)
  101ab0:	c7 04 24 da 62 10 00 	movl   $0x1062da,(%esp)
  101ab7:	e8 d6 e7 ff ff       	call   100292 <cprintf>
        cprintf("  ss   0x----%04x\n", tf->tf_ss);
  101abc:	8b 45 08             	mov    0x8(%ebp),%eax
  101abf:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101ac3:	89 44 24 04          	mov    %eax,0x4(%esp)
  101ac7:	c7 04 24 e9 62 10 00 	movl   $0x1062e9,(%esp)
  101ace:	e8 bf e7 ff ff       	call   100292 <cprintf>
    }
}
  101ad3:	90                   	nop
  101ad4:	c9                   	leave  
  101ad5:	c3                   	ret    

00101ad6 <print_regs>:

void
print_regs(struct pushregs *regs) {
  101ad6:	55                   	push   %ebp
  101ad7:	89 e5                	mov    %esp,%ebp
  101ad9:	83 ec 18             	sub    $0x18,%esp
    cprintf("  edi  0x%08x\n", regs->reg_edi);
  101adc:	8b 45 08             	mov    0x8(%ebp),%eax
  101adf:	8b 00                	mov    (%eax),%eax
  101ae1:	89 44 24 04          	mov    %eax,0x4(%esp)
  101ae5:	c7 04 24 fc 62 10 00 	movl   $0x1062fc,(%esp)
  101aec:	e8 a1 e7 ff ff       	call   100292 <cprintf>
    cprintf("  esi  0x%08x\n", regs->reg_esi);
  101af1:	8b 45 08             	mov    0x8(%ebp),%eax
  101af4:	8b 40 04             	mov    0x4(%eax),%eax
  101af7:	89 44 24 04          	mov    %eax,0x4(%esp)
  101afb:	c7 04 24 0b 63 10 00 	movl   $0x10630b,(%esp)
  101b02:	e8 8b e7 ff ff       	call   100292 <cprintf>
    cprintf("  ebp  0x%08x\n", regs->reg_ebp);
  101b07:	8b 45 08             	mov    0x8(%ebp),%eax
  101b0a:	8b 40 08             	mov    0x8(%eax),%eax
  101b0d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b11:	c7 04 24 1a 63 10 00 	movl   $0x10631a,(%esp)
  101b18:	e8 75 e7 ff ff       	call   100292 <cprintf>
    cprintf("  oesp 0x%08x\n", regs->reg_oesp);
  101b1d:	8b 45 08             	mov    0x8(%ebp),%eax
  101b20:	8b 40 0c             	mov    0xc(%eax),%eax
  101b23:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b27:	c7 04 24 29 63 10 00 	movl   $0x106329,(%esp)
  101b2e:	e8 5f e7 ff ff       	call   100292 <cprintf>
    cprintf("  ebx  0x%08x\n", regs->reg_ebx);
  101b33:	8b 45 08             	mov    0x8(%ebp),%eax
  101b36:	8b 40 10             	mov    0x10(%eax),%eax
  101b39:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b3d:	c7 04 24 38 63 10 00 	movl   $0x106338,(%esp)
  101b44:	e8 49 e7 ff ff       	call   100292 <cprintf>
    cprintf("  edx  0x%08x\n", regs->reg_edx);
  101b49:	8b 45 08             	mov    0x8(%ebp),%eax
  101b4c:	8b 40 14             	mov    0x14(%eax),%eax
  101b4f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b53:	c7 04 24 47 63 10 00 	movl   $0x106347,(%esp)
  101b5a:	e8 33 e7 ff ff       	call   100292 <cprintf>
    cprintf("  ecx  0x%08x\n", regs->reg_ecx);
  101b5f:	8b 45 08             	mov    0x8(%ebp),%eax
  101b62:	8b 40 18             	mov    0x18(%eax),%eax
  101b65:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b69:	c7 04 24 56 63 10 00 	movl   $0x106356,(%esp)
  101b70:	e8 1d e7 ff ff       	call   100292 <cprintf>
    cprintf("  eax  0x%08x\n", regs->reg_eax);
  101b75:	8b 45 08             	mov    0x8(%ebp),%eax
  101b78:	8b 40 1c             	mov    0x1c(%eax),%eax
  101b7b:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b7f:	c7 04 24 65 63 10 00 	movl   $0x106365,(%esp)
  101b86:	e8 07 e7 ff ff       	call   100292 <cprintf>
}
  101b8b:	90                   	nop
  101b8c:	c9                   	leave  
  101b8d:	c3                   	ret    

00101b8e <trap_dispatch>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static void
trap_dispatch(struct trapframe *tf) {
  101b8e:	55                   	push   %ebp
  101b8f:	89 e5                	mov    %esp,%ebp
  101b91:	83 ec 28             	sub    $0x28,%esp
    char c;

    switch (tf->tf_trapno) {
  101b94:	8b 45 08             	mov    0x8(%ebp),%eax
  101b97:	8b 40 30             	mov    0x30(%eax),%eax
  101b9a:	83 f8 2f             	cmp    $0x2f,%eax
  101b9d:	77 21                	ja     101bc0 <trap_dispatch+0x32>
  101b9f:	83 f8 2e             	cmp    $0x2e,%eax
  101ba2:	0f 83 09 01 00 00    	jae    101cb1 <trap_dispatch+0x123>
  101ba8:	83 f8 21             	cmp    $0x21,%eax
  101bab:	0f 84 89 00 00 00    	je     101c3a <trap_dispatch+0xac>
  101bb1:	83 f8 24             	cmp    $0x24,%eax
  101bb4:	74 5e                	je     101c14 <trap_dispatch+0x86>
  101bb6:	83 f8 20             	cmp    $0x20,%eax
  101bb9:	74 16                	je     101bd1 <trap_dispatch+0x43>
  101bbb:	e9 bc 00 00 00       	jmp    101c7c <trap_dispatch+0xee>
  101bc0:	83 e8 78             	sub    $0x78,%eax
  101bc3:	83 f8 01             	cmp    $0x1,%eax
  101bc6:	0f 87 b0 00 00 00    	ja     101c7c <trap_dispatch+0xee>
  101bcc:	e9 8f 00 00 00       	jmp    101c60 <trap_dispatch+0xd2>
        /* handle the timer interrupt */
        /* (1) After a timer interrupt, you should record this event using a global variable (increase it), such as ticks in kern/driver/clock.c
         * (2) Every TICK_NUM cycle, you can print some info using a funciton, such as print_ticks().
         * (3) Too Simple? Yes, I think so!
         */
	if (++ticks % TICK_NUM == 0) {
  101bd1:	a1 0c af 11 00       	mov    0x11af0c,%eax
  101bd6:	8d 48 01             	lea    0x1(%eax),%ecx
  101bd9:	89 0d 0c af 11 00    	mov    %ecx,0x11af0c
  101bdf:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
  101be4:	89 c8                	mov    %ecx,%eax
  101be6:	f7 e2                	mul    %edx
  101be8:	c1 ea 05             	shr    $0x5,%edx
  101beb:	89 d0                	mov    %edx,%eax
  101bed:	c1 e0 02             	shl    $0x2,%eax
  101bf0:	01 d0                	add    %edx,%eax
  101bf2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  101bf9:	01 d0                	add    %edx,%eax
  101bfb:	c1 e0 02             	shl    $0x2,%eax
  101bfe:	29 c1                	sub    %eax,%ecx
  101c00:	89 ca                	mov    %ecx,%edx
  101c02:	85 d2                	test   %edx,%edx
  101c04:	0f 85 aa 00 00 00    	jne    101cb4 <trap_dispatch+0x126>
	    print_ticks();
  101c0a:	e8 bb fb ff ff       	call   1017ca <print_ticks>
	}
        break;
  101c0f:	e9 a0 00 00 00       	jmp    101cb4 <trap_dispatch+0x126>
    case IRQ_OFFSET + IRQ_COM1:
        c = cons_getc();
  101c14:	e8 76 f9 ff ff       	call   10158f <cons_getc>
  101c19:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("serial [%03d] %c\n", c, c);
  101c1c:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
  101c20:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  101c24:	89 54 24 08          	mov    %edx,0x8(%esp)
  101c28:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c2c:	c7 04 24 74 63 10 00 	movl   $0x106374,(%esp)
  101c33:	e8 5a e6 ff ff       	call   100292 <cprintf>
        break;
  101c38:	eb 7b                	jmp    101cb5 <trap_dispatch+0x127>
    case IRQ_OFFSET + IRQ_KBD:
        c = cons_getc();
  101c3a:	e8 50 f9 ff ff       	call   10158f <cons_getc>
  101c3f:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("kbd [%03d] %c\n", c, c);
  101c42:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
  101c46:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  101c4a:	89 54 24 08          	mov    %edx,0x8(%esp)
  101c4e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c52:	c7 04 24 86 63 10 00 	movl   $0x106386,(%esp)
  101c59:	e8 34 e6 ff ff       	call   100292 <cprintf>
        break;
  101c5e:	eb 55                	jmp    101cb5 <trap_dispatch+0x127>
    //LAB1 CHALLENGE 1 : YOUR CODE you should modify below codes.
    case T_SWITCH_TOU:
    case T_SWITCH_TOK:
        panic("T_SWITCH_** ??\n");
  101c60:	c7 44 24 08 95 63 10 	movl   $0x106395,0x8(%esp)
  101c67:	00 
  101c68:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  101c6f:	00 
  101c70:	c7 04 24 a5 63 10 00 	movl   $0x1063a5,(%esp)
  101c77:	e8 6d e7 ff ff       	call   1003e9 <__panic>
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
    default:
        // in kernel, it must be a mistake
        if ((tf->tf_cs & 3) == 0) {
  101c7c:	8b 45 08             	mov    0x8(%ebp),%eax
  101c7f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101c83:	83 e0 03             	and    $0x3,%eax
  101c86:	85 c0                	test   %eax,%eax
  101c88:	75 2b                	jne    101cb5 <trap_dispatch+0x127>
            print_trapframe(tf);
  101c8a:	8b 45 08             	mov    0x8(%ebp),%eax
  101c8d:	89 04 24             	mov    %eax,(%esp)
  101c90:	e8 8c fc ff ff       	call   101921 <print_trapframe>
            panic("unexpected trap in kernel.\n");
  101c95:	c7 44 24 08 b6 63 10 	movl   $0x1063b6,0x8(%esp)
  101c9c:	00 
  101c9d:	c7 44 24 04 b4 00 00 	movl   $0xb4,0x4(%esp)
  101ca4:	00 
  101ca5:	c7 04 24 a5 63 10 00 	movl   $0x1063a5,(%esp)
  101cac:	e8 38 e7 ff ff       	call   1003e9 <__panic>
        panic("T_SWITCH_** ??\n");
        break;
    case IRQ_OFFSET + IRQ_IDE1:
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
  101cb1:	90                   	nop
  101cb2:	eb 01                	jmp    101cb5 <trap_dispatch+0x127>
         * (3) Too Simple? Yes, I think so!
         */
	if (++ticks % TICK_NUM == 0) {
	    print_ticks();
	}
        break;
  101cb4:	90                   	nop
        if ((tf->tf_cs & 3) == 0) {
            print_trapframe(tf);
            panic("unexpected trap in kernel.\n");
        }
    }
}
  101cb5:	90                   	nop
  101cb6:	c9                   	leave  
  101cb7:	c3                   	ret    

00101cb8 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
  101cb8:	55                   	push   %ebp
  101cb9:	89 e5                	mov    %esp,%ebp
  101cbb:	83 ec 18             	sub    $0x18,%esp
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
  101cbe:	8b 45 08             	mov    0x8(%ebp),%eax
  101cc1:	89 04 24             	mov    %eax,(%esp)
  101cc4:	e8 c5 fe ff ff       	call   101b8e <trap_dispatch>
}
  101cc9:	90                   	nop
  101cca:	c9                   	leave  
  101ccb:	c3                   	ret    

00101ccc <vector0>:
# handler
.text
.globl __alltraps
.globl vector0
vector0:
  pushl $0
  101ccc:	6a 00                	push   $0x0
  pushl $0
  101cce:	6a 00                	push   $0x0
  jmp __alltraps
  101cd0:	e9 69 0a 00 00       	jmp    10273e <__alltraps>

00101cd5 <vector1>:
.globl vector1
vector1:
  pushl $0
  101cd5:	6a 00                	push   $0x0
  pushl $1
  101cd7:	6a 01                	push   $0x1
  jmp __alltraps
  101cd9:	e9 60 0a 00 00       	jmp    10273e <__alltraps>

00101cde <vector2>:
.globl vector2
vector2:
  pushl $0
  101cde:	6a 00                	push   $0x0
  pushl $2
  101ce0:	6a 02                	push   $0x2
  jmp __alltraps
  101ce2:	e9 57 0a 00 00       	jmp    10273e <__alltraps>

00101ce7 <vector3>:
.globl vector3
vector3:
  pushl $0
  101ce7:	6a 00                	push   $0x0
  pushl $3
  101ce9:	6a 03                	push   $0x3
  jmp __alltraps
  101ceb:	e9 4e 0a 00 00       	jmp    10273e <__alltraps>

00101cf0 <vector4>:
.globl vector4
vector4:
  pushl $0
  101cf0:	6a 00                	push   $0x0
  pushl $4
  101cf2:	6a 04                	push   $0x4
  jmp __alltraps
  101cf4:	e9 45 0a 00 00       	jmp    10273e <__alltraps>

00101cf9 <vector5>:
.globl vector5
vector5:
  pushl $0
  101cf9:	6a 00                	push   $0x0
  pushl $5
  101cfb:	6a 05                	push   $0x5
  jmp __alltraps
  101cfd:	e9 3c 0a 00 00       	jmp    10273e <__alltraps>

00101d02 <vector6>:
.globl vector6
vector6:
  pushl $0
  101d02:	6a 00                	push   $0x0
  pushl $6
  101d04:	6a 06                	push   $0x6
  jmp __alltraps
  101d06:	e9 33 0a 00 00       	jmp    10273e <__alltraps>

00101d0b <vector7>:
.globl vector7
vector7:
  pushl $0
  101d0b:	6a 00                	push   $0x0
  pushl $7
  101d0d:	6a 07                	push   $0x7
  jmp __alltraps
  101d0f:	e9 2a 0a 00 00       	jmp    10273e <__alltraps>

00101d14 <vector8>:
.globl vector8
vector8:
  pushl $8
  101d14:	6a 08                	push   $0x8
  jmp __alltraps
  101d16:	e9 23 0a 00 00       	jmp    10273e <__alltraps>

00101d1b <vector9>:
.globl vector9
vector9:
  pushl $0
  101d1b:	6a 00                	push   $0x0
  pushl $9
  101d1d:	6a 09                	push   $0x9
  jmp __alltraps
  101d1f:	e9 1a 0a 00 00       	jmp    10273e <__alltraps>

00101d24 <vector10>:
.globl vector10
vector10:
  pushl $10
  101d24:	6a 0a                	push   $0xa
  jmp __alltraps
  101d26:	e9 13 0a 00 00       	jmp    10273e <__alltraps>

00101d2b <vector11>:
.globl vector11
vector11:
  pushl $11
  101d2b:	6a 0b                	push   $0xb
  jmp __alltraps
  101d2d:	e9 0c 0a 00 00       	jmp    10273e <__alltraps>

00101d32 <vector12>:
.globl vector12
vector12:
  pushl $12
  101d32:	6a 0c                	push   $0xc
  jmp __alltraps
  101d34:	e9 05 0a 00 00       	jmp    10273e <__alltraps>

00101d39 <vector13>:
.globl vector13
vector13:
  pushl $13
  101d39:	6a 0d                	push   $0xd
  jmp __alltraps
  101d3b:	e9 fe 09 00 00       	jmp    10273e <__alltraps>

00101d40 <vector14>:
.globl vector14
vector14:
  pushl $14
  101d40:	6a 0e                	push   $0xe
  jmp __alltraps
  101d42:	e9 f7 09 00 00       	jmp    10273e <__alltraps>

00101d47 <vector15>:
.globl vector15
vector15:
  pushl $0
  101d47:	6a 00                	push   $0x0
  pushl $15
  101d49:	6a 0f                	push   $0xf
  jmp __alltraps
  101d4b:	e9 ee 09 00 00       	jmp    10273e <__alltraps>

00101d50 <vector16>:
.globl vector16
vector16:
  pushl $0
  101d50:	6a 00                	push   $0x0
  pushl $16
  101d52:	6a 10                	push   $0x10
  jmp __alltraps
  101d54:	e9 e5 09 00 00       	jmp    10273e <__alltraps>

00101d59 <vector17>:
.globl vector17
vector17:
  pushl $17
  101d59:	6a 11                	push   $0x11
  jmp __alltraps
  101d5b:	e9 de 09 00 00       	jmp    10273e <__alltraps>

00101d60 <vector18>:
.globl vector18
vector18:
  pushl $0
  101d60:	6a 00                	push   $0x0
  pushl $18
  101d62:	6a 12                	push   $0x12
  jmp __alltraps
  101d64:	e9 d5 09 00 00       	jmp    10273e <__alltraps>

00101d69 <vector19>:
.globl vector19
vector19:
  pushl $0
  101d69:	6a 00                	push   $0x0
  pushl $19
  101d6b:	6a 13                	push   $0x13
  jmp __alltraps
  101d6d:	e9 cc 09 00 00       	jmp    10273e <__alltraps>

00101d72 <vector20>:
.globl vector20
vector20:
  pushl $0
  101d72:	6a 00                	push   $0x0
  pushl $20
  101d74:	6a 14                	push   $0x14
  jmp __alltraps
  101d76:	e9 c3 09 00 00       	jmp    10273e <__alltraps>

00101d7b <vector21>:
.globl vector21
vector21:
  pushl $0
  101d7b:	6a 00                	push   $0x0
  pushl $21
  101d7d:	6a 15                	push   $0x15
  jmp __alltraps
  101d7f:	e9 ba 09 00 00       	jmp    10273e <__alltraps>

00101d84 <vector22>:
.globl vector22
vector22:
  pushl $0
  101d84:	6a 00                	push   $0x0
  pushl $22
  101d86:	6a 16                	push   $0x16
  jmp __alltraps
  101d88:	e9 b1 09 00 00       	jmp    10273e <__alltraps>

00101d8d <vector23>:
.globl vector23
vector23:
  pushl $0
  101d8d:	6a 00                	push   $0x0
  pushl $23
  101d8f:	6a 17                	push   $0x17
  jmp __alltraps
  101d91:	e9 a8 09 00 00       	jmp    10273e <__alltraps>

00101d96 <vector24>:
.globl vector24
vector24:
  pushl $0
  101d96:	6a 00                	push   $0x0
  pushl $24
  101d98:	6a 18                	push   $0x18
  jmp __alltraps
  101d9a:	e9 9f 09 00 00       	jmp    10273e <__alltraps>

00101d9f <vector25>:
.globl vector25
vector25:
  pushl $0
  101d9f:	6a 00                	push   $0x0
  pushl $25
  101da1:	6a 19                	push   $0x19
  jmp __alltraps
  101da3:	e9 96 09 00 00       	jmp    10273e <__alltraps>

00101da8 <vector26>:
.globl vector26
vector26:
  pushl $0
  101da8:	6a 00                	push   $0x0
  pushl $26
  101daa:	6a 1a                	push   $0x1a
  jmp __alltraps
  101dac:	e9 8d 09 00 00       	jmp    10273e <__alltraps>

00101db1 <vector27>:
.globl vector27
vector27:
  pushl $0
  101db1:	6a 00                	push   $0x0
  pushl $27
  101db3:	6a 1b                	push   $0x1b
  jmp __alltraps
  101db5:	e9 84 09 00 00       	jmp    10273e <__alltraps>

00101dba <vector28>:
.globl vector28
vector28:
  pushl $0
  101dba:	6a 00                	push   $0x0
  pushl $28
  101dbc:	6a 1c                	push   $0x1c
  jmp __alltraps
  101dbe:	e9 7b 09 00 00       	jmp    10273e <__alltraps>

00101dc3 <vector29>:
.globl vector29
vector29:
  pushl $0
  101dc3:	6a 00                	push   $0x0
  pushl $29
  101dc5:	6a 1d                	push   $0x1d
  jmp __alltraps
  101dc7:	e9 72 09 00 00       	jmp    10273e <__alltraps>

00101dcc <vector30>:
.globl vector30
vector30:
  pushl $0
  101dcc:	6a 00                	push   $0x0
  pushl $30
  101dce:	6a 1e                	push   $0x1e
  jmp __alltraps
  101dd0:	e9 69 09 00 00       	jmp    10273e <__alltraps>

00101dd5 <vector31>:
.globl vector31
vector31:
  pushl $0
  101dd5:	6a 00                	push   $0x0
  pushl $31
  101dd7:	6a 1f                	push   $0x1f
  jmp __alltraps
  101dd9:	e9 60 09 00 00       	jmp    10273e <__alltraps>

00101dde <vector32>:
.globl vector32
vector32:
  pushl $0
  101dde:	6a 00                	push   $0x0
  pushl $32
  101de0:	6a 20                	push   $0x20
  jmp __alltraps
  101de2:	e9 57 09 00 00       	jmp    10273e <__alltraps>

00101de7 <vector33>:
.globl vector33
vector33:
  pushl $0
  101de7:	6a 00                	push   $0x0
  pushl $33
  101de9:	6a 21                	push   $0x21
  jmp __alltraps
  101deb:	e9 4e 09 00 00       	jmp    10273e <__alltraps>

00101df0 <vector34>:
.globl vector34
vector34:
  pushl $0
  101df0:	6a 00                	push   $0x0
  pushl $34
  101df2:	6a 22                	push   $0x22
  jmp __alltraps
  101df4:	e9 45 09 00 00       	jmp    10273e <__alltraps>

00101df9 <vector35>:
.globl vector35
vector35:
  pushl $0
  101df9:	6a 00                	push   $0x0
  pushl $35
  101dfb:	6a 23                	push   $0x23
  jmp __alltraps
  101dfd:	e9 3c 09 00 00       	jmp    10273e <__alltraps>

00101e02 <vector36>:
.globl vector36
vector36:
  pushl $0
  101e02:	6a 00                	push   $0x0
  pushl $36
  101e04:	6a 24                	push   $0x24
  jmp __alltraps
  101e06:	e9 33 09 00 00       	jmp    10273e <__alltraps>

00101e0b <vector37>:
.globl vector37
vector37:
  pushl $0
  101e0b:	6a 00                	push   $0x0
  pushl $37
  101e0d:	6a 25                	push   $0x25
  jmp __alltraps
  101e0f:	e9 2a 09 00 00       	jmp    10273e <__alltraps>

00101e14 <vector38>:
.globl vector38
vector38:
  pushl $0
  101e14:	6a 00                	push   $0x0
  pushl $38
  101e16:	6a 26                	push   $0x26
  jmp __alltraps
  101e18:	e9 21 09 00 00       	jmp    10273e <__alltraps>

00101e1d <vector39>:
.globl vector39
vector39:
  pushl $0
  101e1d:	6a 00                	push   $0x0
  pushl $39
  101e1f:	6a 27                	push   $0x27
  jmp __alltraps
  101e21:	e9 18 09 00 00       	jmp    10273e <__alltraps>

00101e26 <vector40>:
.globl vector40
vector40:
  pushl $0
  101e26:	6a 00                	push   $0x0
  pushl $40
  101e28:	6a 28                	push   $0x28
  jmp __alltraps
  101e2a:	e9 0f 09 00 00       	jmp    10273e <__alltraps>

00101e2f <vector41>:
.globl vector41
vector41:
  pushl $0
  101e2f:	6a 00                	push   $0x0
  pushl $41
  101e31:	6a 29                	push   $0x29
  jmp __alltraps
  101e33:	e9 06 09 00 00       	jmp    10273e <__alltraps>

00101e38 <vector42>:
.globl vector42
vector42:
  pushl $0
  101e38:	6a 00                	push   $0x0
  pushl $42
  101e3a:	6a 2a                	push   $0x2a
  jmp __alltraps
  101e3c:	e9 fd 08 00 00       	jmp    10273e <__alltraps>

00101e41 <vector43>:
.globl vector43
vector43:
  pushl $0
  101e41:	6a 00                	push   $0x0
  pushl $43
  101e43:	6a 2b                	push   $0x2b
  jmp __alltraps
  101e45:	e9 f4 08 00 00       	jmp    10273e <__alltraps>

00101e4a <vector44>:
.globl vector44
vector44:
  pushl $0
  101e4a:	6a 00                	push   $0x0
  pushl $44
  101e4c:	6a 2c                	push   $0x2c
  jmp __alltraps
  101e4e:	e9 eb 08 00 00       	jmp    10273e <__alltraps>

00101e53 <vector45>:
.globl vector45
vector45:
  pushl $0
  101e53:	6a 00                	push   $0x0
  pushl $45
  101e55:	6a 2d                	push   $0x2d
  jmp __alltraps
  101e57:	e9 e2 08 00 00       	jmp    10273e <__alltraps>

00101e5c <vector46>:
.globl vector46
vector46:
  pushl $0
  101e5c:	6a 00                	push   $0x0
  pushl $46
  101e5e:	6a 2e                	push   $0x2e
  jmp __alltraps
  101e60:	e9 d9 08 00 00       	jmp    10273e <__alltraps>

00101e65 <vector47>:
.globl vector47
vector47:
  pushl $0
  101e65:	6a 00                	push   $0x0
  pushl $47
  101e67:	6a 2f                	push   $0x2f
  jmp __alltraps
  101e69:	e9 d0 08 00 00       	jmp    10273e <__alltraps>

00101e6e <vector48>:
.globl vector48
vector48:
  pushl $0
  101e6e:	6a 00                	push   $0x0
  pushl $48
  101e70:	6a 30                	push   $0x30
  jmp __alltraps
  101e72:	e9 c7 08 00 00       	jmp    10273e <__alltraps>

00101e77 <vector49>:
.globl vector49
vector49:
  pushl $0
  101e77:	6a 00                	push   $0x0
  pushl $49
  101e79:	6a 31                	push   $0x31
  jmp __alltraps
  101e7b:	e9 be 08 00 00       	jmp    10273e <__alltraps>

00101e80 <vector50>:
.globl vector50
vector50:
  pushl $0
  101e80:	6a 00                	push   $0x0
  pushl $50
  101e82:	6a 32                	push   $0x32
  jmp __alltraps
  101e84:	e9 b5 08 00 00       	jmp    10273e <__alltraps>

00101e89 <vector51>:
.globl vector51
vector51:
  pushl $0
  101e89:	6a 00                	push   $0x0
  pushl $51
  101e8b:	6a 33                	push   $0x33
  jmp __alltraps
  101e8d:	e9 ac 08 00 00       	jmp    10273e <__alltraps>

00101e92 <vector52>:
.globl vector52
vector52:
  pushl $0
  101e92:	6a 00                	push   $0x0
  pushl $52
  101e94:	6a 34                	push   $0x34
  jmp __alltraps
  101e96:	e9 a3 08 00 00       	jmp    10273e <__alltraps>

00101e9b <vector53>:
.globl vector53
vector53:
  pushl $0
  101e9b:	6a 00                	push   $0x0
  pushl $53
  101e9d:	6a 35                	push   $0x35
  jmp __alltraps
  101e9f:	e9 9a 08 00 00       	jmp    10273e <__alltraps>

00101ea4 <vector54>:
.globl vector54
vector54:
  pushl $0
  101ea4:	6a 00                	push   $0x0
  pushl $54
  101ea6:	6a 36                	push   $0x36
  jmp __alltraps
  101ea8:	e9 91 08 00 00       	jmp    10273e <__alltraps>

00101ead <vector55>:
.globl vector55
vector55:
  pushl $0
  101ead:	6a 00                	push   $0x0
  pushl $55
  101eaf:	6a 37                	push   $0x37
  jmp __alltraps
  101eb1:	e9 88 08 00 00       	jmp    10273e <__alltraps>

00101eb6 <vector56>:
.globl vector56
vector56:
  pushl $0
  101eb6:	6a 00                	push   $0x0
  pushl $56
  101eb8:	6a 38                	push   $0x38
  jmp __alltraps
  101eba:	e9 7f 08 00 00       	jmp    10273e <__alltraps>

00101ebf <vector57>:
.globl vector57
vector57:
  pushl $0
  101ebf:	6a 00                	push   $0x0
  pushl $57
  101ec1:	6a 39                	push   $0x39
  jmp __alltraps
  101ec3:	e9 76 08 00 00       	jmp    10273e <__alltraps>

00101ec8 <vector58>:
.globl vector58
vector58:
  pushl $0
  101ec8:	6a 00                	push   $0x0
  pushl $58
  101eca:	6a 3a                	push   $0x3a
  jmp __alltraps
  101ecc:	e9 6d 08 00 00       	jmp    10273e <__alltraps>

00101ed1 <vector59>:
.globl vector59
vector59:
  pushl $0
  101ed1:	6a 00                	push   $0x0
  pushl $59
  101ed3:	6a 3b                	push   $0x3b
  jmp __alltraps
  101ed5:	e9 64 08 00 00       	jmp    10273e <__alltraps>

00101eda <vector60>:
.globl vector60
vector60:
  pushl $0
  101eda:	6a 00                	push   $0x0
  pushl $60
  101edc:	6a 3c                	push   $0x3c
  jmp __alltraps
  101ede:	e9 5b 08 00 00       	jmp    10273e <__alltraps>

00101ee3 <vector61>:
.globl vector61
vector61:
  pushl $0
  101ee3:	6a 00                	push   $0x0
  pushl $61
  101ee5:	6a 3d                	push   $0x3d
  jmp __alltraps
  101ee7:	e9 52 08 00 00       	jmp    10273e <__alltraps>

00101eec <vector62>:
.globl vector62
vector62:
  pushl $0
  101eec:	6a 00                	push   $0x0
  pushl $62
  101eee:	6a 3e                	push   $0x3e
  jmp __alltraps
  101ef0:	e9 49 08 00 00       	jmp    10273e <__alltraps>

00101ef5 <vector63>:
.globl vector63
vector63:
  pushl $0
  101ef5:	6a 00                	push   $0x0
  pushl $63
  101ef7:	6a 3f                	push   $0x3f
  jmp __alltraps
  101ef9:	e9 40 08 00 00       	jmp    10273e <__alltraps>

00101efe <vector64>:
.globl vector64
vector64:
  pushl $0
  101efe:	6a 00                	push   $0x0
  pushl $64
  101f00:	6a 40                	push   $0x40
  jmp __alltraps
  101f02:	e9 37 08 00 00       	jmp    10273e <__alltraps>

00101f07 <vector65>:
.globl vector65
vector65:
  pushl $0
  101f07:	6a 00                	push   $0x0
  pushl $65
  101f09:	6a 41                	push   $0x41
  jmp __alltraps
  101f0b:	e9 2e 08 00 00       	jmp    10273e <__alltraps>

00101f10 <vector66>:
.globl vector66
vector66:
  pushl $0
  101f10:	6a 00                	push   $0x0
  pushl $66
  101f12:	6a 42                	push   $0x42
  jmp __alltraps
  101f14:	e9 25 08 00 00       	jmp    10273e <__alltraps>

00101f19 <vector67>:
.globl vector67
vector67:
  pushl $0
  101f19:	6a 00                	push   $0x0
  pushl $67
  101f1b:	6a 43                	push   $0x43
  jmp __alltraps
  101f1d:	e9 1c 08 00 00       	jmp    10273e <__alltraps>

00101f22 <vector68>:
.globl vector68
vector68:
  pushl $0
  101f22:	6a 00                	push   $0x0
  pushl $68
  101f24:	6a 44                	push   $0x44
  jmp __alltraps
  101f26:	e9 13 08 00 00       	jmp    10273e <__alltraps>

00101f2b <vector69>:
.globl vector69
vector69:
  pushl $0
  101f2b:	6a 00                	push   $0x0
  pushl $69
  101f2d:	6a 45                	push   $0x45
  jmp __alltraps
  101f2f:	e9 0a 08 00 00       	jmp    10273e <__alltraps>

00101f34 <vector70>:
.globl vector70
vector70:
  pushl $0
  101f34:	6a 00                	push   $0x0
  pushl $70
  101f36:	6a 46                	push   $0x46
  jmp __alltraps
  101f38:	e9 01 08 00 00       	jmp    10273e <__alltraps>

00101f3d <vector71>:
.globl vector71
vector71:
  pushl $0
  101f3d:	6a 00                	push   $0x0
  pushl $71
  101f3f:	6a 47                	push   $0x47
  jmp __alltraps
  101f41:	e9 f8 07 00 00       	jmp    10273e <__alltraps>

00101f46 <vector72>:
.globl vector72
vector72:
  pushl $0
  101f46:	6a 00                	push   $0x0
  pushl $72
  101f48:	6a 48                	push   $0x48
  jmp __alltraps
  101f4a:	e9 ef 07 00 00       	jmp    10273e <__alltraps>

00101f4f <vector73>:
.globl vector73
vector73:
  pushl $0
  101f4f:	6a 00                	push   $0x0
  pushl $73
  101f51:	6a 49                	push   $0x49
  jmp __alltraps
  101f53:	e9 e6 07 00 00       	jmp    10273e <__alltraps>

00101f58 <vector74>:
.globl vector74
vector74:
  pushl $0
  101f58:	6a 00                	push   $0x0
  pushl $74
  101f5a:	6a 4a                	push   $0x4a
  jmp __alltraps
  101f5c:	e9 dd 07 00 00       	jmp    10273e <__alltraps>

00101f61 <vector75>:
.globl vector75
vector75:
  pushl $0
  101f61:	6a 00                	push   $0x0
  pushl $75
  101f63:	6a 4b                	push   $0x4b
  jmp __alltraps
  101f65:	e9 d4 07 00 00       	jmp    10273e <__alltraps>

00101f6a <vector76>:
.globl vector76
vector76:
  pushl $0
  101f6a:	6a 00                	push   $0x0
  pushl $76
  101f6c:	6a 4c                	push   $0x4c
  jmp __alltraps
  101f6e:	e9 cb 07 00 00       	jmp    10273e <__alltraps>

00101f73 <vector77>:
.globl vector77
vector77:
  pushl $0
  101f73:	6a 00                	push   $0x0
  pushl $77
  101f75:	6a 4d                	push   $0x4d
  jmp __alltraps
  101f77:	e9 c2 07 00 00       	jmp    10273e <__alltraps>

00101f7c <vector78>:
.globl vector78
vector78:
  pushl $0
  101f7c:	6a 00                	push   $0x0
  pushl $78
  101f7e:	6a 4e                	push   $0x4e
  jmp __alltraps
  101f80:	e9 b9 07 00 00       	jmp    10273e <__alltraps>

00101f85 <vector79>:
.globl vector79
vector79:
  pushl $0
  101f85:	6a 00                	push   $0x0
  pushl $79
  101f87:	6a 4f                	push   $0x4f
  jmp __alltraps
  101f89:	e9 b0 07 00 00       	jmp    10273e <__alltraps>

00101f8e <vector80>:
.globl vector80
vector80:
  pushl $0
  101f8e:	6a 00                	push   $0x0
  pushl $80
  101f90:	6a 50                	push   $0x50
  jmp __alltraps
  101f92:	e9 a7 07 00 00       	jmp    10273e <__alltraps>

00101f97 <vector81>:
.globl vector81
vector81:
  pushl $0
  101f97:	6a 00                	push   $0x0
  pushl $81
  101f99:	6a 51                	push   $0x51
  jmp __alltraps
  101f9b:	e9 9e 07 00 00       	jmp    10273e <__alltraps>

00101fa0 <vector82>:
.globl vector82
vector82:
  pushl $0
  101fa0:	6a 00                	push   $0x0
  pushl $82
  101fa2:	6a 52                	push   $0x52
  jmp __alltraps
  101fa4:	e9 95 07 00 00       	jmp    10273e <__alltraps>

00101fa9 <vector83>:
.globl vector83
vector83:
  pushl $0
  101fa9:	6a 00                	push   $0x0
  pushl $83
  101fab:	6a 53                	push   $0x53
  jmp __alltraps
  101fad:	e9 8c 07 00 00       	jmp    10273e <__alltraps>

00101fb2 <vector84>:
.globl vector84
vector84:
  pushl $0
  101fb2:	6a 00                	push   $0x0
  pushl $84
  101fb4:	6a 54                	push   $0x54
  jmp __alltraps
  101fb6:	e9 83 07 00 00       	jmp    10273e <__alltraps>

00101fbb <vector85>:
.globl vector85
vector85:
  pushl $0
  101fbb:	6a 00                	push   $0x0
  pushl $85
  101fbd:	6a 55                	push   $0x55
  jmp __alltraps
  101fbf:	e9 7a 07 00 00       	jmp    10273e <__alltraps>

00101fc4 <vector86>:
.globl vector86
vector86:
  pushl $0
  101fc4:	6a 00                	push   $0x0
  pushl $86
  101fc6:	6a 56                	push   $0x56
  jmp __alltraps
  101fc8:	e9 71 07 00 00       	jmp    10273e <__alltraps>

00101fcd <vector87>:
.globl vector87
vector87:
  pushl $0
  101fcd:	6a 00                	push   $0x0
  pushl $87
  101fcf:	6a 57                	push   $0x57
  jmp __alltraps
  101fd1:	e9 68 07 00 00       	jmp    10273e <__alltraps>

00101fd6 <vector88>:
.globl vector88
vector88:
  pushl $0
  101fd6:	6a 00                	push   $0x0
  pushl $88
  101fd8:	6a 58                	push   $0x58
  jmp __alltraps
  101fda:	e9 5f 07 00 00       	jmp    10273e <__alltraps>

00101fdf <vector89>:
.globl vector89
vector89:
  pushl $0
  101fdf:	6a 00                	push   $0x0
  pushl $89
  101fe1:	6a 59                	push   $0x59
  jmp __alltraps
  101fe3:	e9 56 07 00 00       	jmp    10273e <__alltraps>

00101fe8 <vector90>:
.globl vector90
vector90:
  pushl $0
  101fe8:	6a 00                	push   $0x0
  pushl $90
  101fea:	6a 5a                	push   $0x5a
  jmp __alltraps
  101fec:	e9 4d 07 00 00       	jmp    10273e <__alltraps>

00101ff1 <vector91>:
.globl vector91
vector91:
  pushl $0
  101ff1:	6a 00                	push   $0x0
  pushl $91
  101ff3:	6a 5b                	push   $0x5b
  jmp __alltraps
  101ff5:	e9 44 07 00 00       	jmp    10273e <__alltraps>

00101ffa <vector92>:
.globl vector92
vector92:
  pushl $0
  101ffa:	6a 00                	push   $0x0
  pushl $92
  101ffc:	6a 5c                	push   $0x5c
  jmp __alltraps
  101ffe:	e9 3b 07 00 00       	jmp    10273e <__alltraps>

00102003 <vector93>:
.globl vector93
vector93:
  pushl $0
  102003:	6a 00                	push   $0x0
  pushl $93
  102005:	6a 5d                	push   $0x5d
  jmp __alltraps
  102007:	e9 32 07 00 00       	jmp    10273e <__alltraps>

0010200c <vector94>:
.globl vector94
vector94:
  pushl $0
  10200c:	6a 00                	push   $0x0
  pushl $94
  10200e:	6a 5e                	push   $0x5e
  jmp __alltraps
  102010:	e9 29 07 00 00       	jmp    10273e <__alltraps>

00102015 <vector95>:
.globl vector95
vector95:
  pushl $0
  102015:	6a 00                	push   $0x0
  pushl $95
  102017:	6a 5f                	push   $0x5f
  jmp __alltraps
  102019:	e9 20 07 00 00       	jmp    10273e <__alltraps>

0010201e <vector96>:
.globl vector96
vector96:
  pushl $0
  10201e:	6a 00                	push   $0x0
  pushl $96
  102020:	6a 60                	push   $0x60
  jmp __alltraps
  102022:	e9 17 07 00 00       	jmp    10273e <__alltraps>

00102027 <vector97>:
.globl vector97
vector97:
  pushl $0
  102027:	6a 00                	push   $0x0
  pushl $97
  102029:	6a 61                	push   $0x61
  jmp __alltraps
  10202b:	e9 0e 07 00 00       	jmp    10273e <__alltraps>

00102030 <vector98>:
.globl vector98
vector98:
  pushl $0
  102030:	6a 00                	push   $0x0
  pushl $98
  102032:	6a 62                	push   $0x62
  jmp __alltraps
  102034:	e9 05 07 00 00       	jmp    10273e <__alltraps>

00102039 <vector99>:
.globl vector99
vector99:
  pushl $0
  102039:	6a 00                	push   $0x0
  pushl $99
  10203b:	6a 63                	push   $0x63
  jmp __alltraps
  10203d:	e9 fc 06 00 00       	jmp    10273e <__alltraps>

00102042 <vector100>:
.globl vector100
vector100:
  pushl $0
  102042:	6a 00                	push   $0x0
  pushl $100
  102044:	6a 64                	push   $0x64
  jmp __alltraps
  102046:	e9 f3 06 00 00       	jmp    10273e <__alltraps>

0010204b <vector101>:
.globl vector101
vector101:
  pushl $0
  10204b:	6a 00                	push   $0x0
  pushl $101
  10204d:	6a 65                	push   $0x65
  jmp __alltraps
  10204f:	e9 ea 06 00 00       	jmp    10273e <__alltraps>

00102054 <vector102>:
.globl vector102
vector102:
  pushl $0
  102054:	6a 00                	push   $0x0
  pushl $102
  102056:	6a 66                	push   $0x66
  jmp __alltraps
  102058:	e9 e1 06 00 00       	jmp    10273e <__alltraps>

0010205d <vector103>:
.globl vector103
vector103:
  pushl $0
  10205d:	6a 00                	push   $0x0
  pushl $103
  10205f:	6a 67                	push   $0x67
  jmp __alltraps
  102061:	e9 d8 06 00 00       	jmp    10273e <__alltraps>

00102066 <vector104>:
.globl vector104
vector104:
  pushl $0
  102066:	6a 00                	push   $0x0
  pushl $104
  102068:	6a 68                	push   $0x68
  jmp __alltraps
  10206a:	e9 cf 06 00 00       	jmp    10273e <__alltraps>

0010206f <vector105>:
.globl vector105
vector105:
  pushl $0
  10206f:	6a 00                	push   $0x0
  pushl $105
  102071:	6a 69                	push   $0x69
  jmp __alltraps
  102073:	e9 c6 06 00 00       	jmp    10273e <__alltraps>

00102078 <vector106>:
.globl vector106
vector106:
  pushl $0
  102078:	6a 00                	push   $0x0
  pushl $106
  10207a:	6a 6a                	push   $0x6a
  jmp __alltraps
  10207c:	e9 bd 06 00 00       	jmp    10273e <__alltraps>

00102081 <vector107>:
.globl vector107
vector107:
  pushl $0
  102081:	6a 00                	push   $0x0
  pushl $107
  102083:	6a 6b                	push   $0x6b
  jmp __alltraps
  102085:	e9 b4 06 00 00       	jmp    10273e <__alltraps>

0010208a <vector108>:
.globl vector108
vector108:
  pushl $0
  10208a:	6a 00                	push   $0x0
  pushl $108
  10208c:	6a 6c                	push   $0x6c
  jmp __alltraps
  10208e:	e9 ab 06 00 00       	jmp    10273e <__alltraps>

00102093 <vector109>:
.globl vector109
vector109:
  pushl $0
  102093:	6a 00                	push   $0x0
  pushl $109
  102095:	6a 6d                	push   $0x6d
  jmp __alltraps
  102097:	e9 a2 06 00 00       	jmp    10273e <__alltraps>

0010209c <vector110>:
.globl vector110
vector110:
  pushl $0
  10209c:	6a 00                	push   $0x0
  pushl $110
  10209e:	6a 6e                	push   $0x6e
  jmp __alltraps
  1020a0:	e9 99 06 00 00       	jmp    10273e <__alltraps>

001020a5 <vector111>:
.globl vector111
vector111:
  pushl $0
  1020a5:	6a 00                	push   $0x0
  pushl $111
  1020a7:	6a 6f                	push   $0x6f
  jmp __alltraps
  1020a9:	e9 90 06 00 00       	jmp    10273e <__alltraps>

001020ae <vector112>:
.globl vector112
vector112:
  pushl $0
  1020ae:	6a 00                	push   $0x0
  pushl $112
  1020b0:	6a 70                	push   $0x70
  jmp __alltraps
  1020b2:	e9 87 06 00 00       	jmp    10273e <__alltraps>

001020b7 <vector113>:
.globl vector113
vector113:
  pushl $0
  1020b7:	6a 00                	push   $0x0
  pushl $113
  1020b9:	6a 71                	push   $0x71
  jmp __alltraps
  1020bb:	e9 7e 06 00 00       	jmp    10273e <__alltraps>

001020c0 <vector114>:
.globl vector114
vector114:
  pushl $0
  1020c0:	6a 00                	push   $0x0
  pushl $114
  1020c2:	6a 72                	push   $0x72
  jmp __alltraps
  1020c4:	e9 75 06 00 00       	jmp    10273e <__alltraps>

001020c9 <vector115>:
.globl vector115
vector115:
  pushl $0
  1020c9:	6a 00                	push   $0x0
  pushl $115
  1020cb:	6a 73                	push   $0x73
  jmp __alltraps
  1020cd:	e9 6c 06 00 00       	jmp    10273e <__alltraps>

001020d2 <vector116>:
.globl vector116
vector116:
  pushl $0
  1020d2:	6a 00                	push   $0x0
  pushl $116
  1020d4:	6a 74                	push   $0x74
  jmp __alltraps
  1020d6:	e9 63 06 00 00       	jmp    10273e <__alltraps>

001020db <vector117>:
.globl vector117
vector117:
  pushl $0
  1020db:	6a 00                	push   $0x0
  pushl $117
  1020dd:	6a 75                	push   $0x75
  jmp __alltraps
  1020df:	e9 5a 06 00 00       	jmp    10273e <__alltraps>

001020e4 <vector118>:
.globl vector118
vector118:
  pushl $0
  1020e4:	6a 00                	push   $0x0
  pushl $118
  1020e6:	6a 76                	push   $0x76
  jmp __alltraps
  1020e8:	e9 51 06 00 00       	jmp    10273e <__alltraps>

001020ed <vector119>:
.globl vector119
vector119:
  pushl $0
  1020ed:	6a 00                	push   $0x0
  pushl $119
  1020ef:	6a 77                	push   $0x77
  jmp __alltraps
  1020f1:	e9 48 06 00 00       	jmp    10273e <__alltraps>

001020f6 <vector120>:
.globl vector120
vector120:
  pushl $0
  1020f6:	6a 00                	push   $0x0
  pushl $120
  1020f8:	6a 78                	push   $0x78
  jmp __alltraps
  1020fa:	e9 3f 06 00 00       	jmp    10273e <__alltraps>

001020ff <vector121>:
.globl vector121
vector121:
  pushl $0
  1020ff:	6a 00                	push   $0x0
  pushl $121
  102101:	6a 79                	push   $0x79
  jmp __alltraps
  102103:	e9 36 06 00 00       	jmp    10273e <__alltraps>

00102108 <vector122>:
.globl vector122
vector122:
  pushl $0
  102108:	6a 00                	push   $0x0
  pushl $122
  10210a:	6a 7a                	push   $0x7a
  jmp __alltraps
  10210c:	e9 2d 06 00 00       	jmp    10273e <__alltraps>

00102111 <vector123>:
.globl vector123
vector123:
  pushl $0
  102111:	6a 00                	push   $0x0
  pushl $123
  102113:	6a 7b                	push   $0x7b
  jmp __alltraps
  102115:	e9 24 06 00 00       	jmp    10273e <__alltraps>

0010211a <vector124>:
.globl vector124
vector124:
  pushl $0
  10211a:	6a 00                	push   $0x0
  pushl $124
  10211c:	6a 7c                	push   $0x7c
  jmp __alltraps
  10211e:	e9 1b 06 00 00       	jmp    10273e <__alltraps>

00102123 <vector125>:
.globl vector125
vector125:
  pushl $0
  102123:	6a 00                	push   $0x0
  pushl $125
  102125:	6a 7d                	push   $0x7d
  jmp __alltraps
  102127:	e9 12 06 00 00       	jmp    10273e <__alltraps>

0010212c <vector126>:
.globl vector126
vector126:
  pushl $0
  10212c:	6a 00                	push   $0x0
  pushl $126
  10212e:	6a 7e                	push   $0x7e
  jmp __alltraps
  102130:	e9 09 06 00 00       	jmp    10273e <__alltraps>

00102135 <vector127>:
.globl vector127
vector127:
  pushl $0
  102135:	6a 00                	push   $0x0
  pushl $127
  102137:	6a 7f                	push   $0x7f
  jmp __alltraps
  102139:	e9 00 06 00 00       	jmp    10273e <__alltraps>

0010213e <vector128>:
.globl vector128
vector128:
  pushl $0
  10213e:	6a 00                	push   $0x0
  pushl $128
  102140:	68 80 00 00 00       	push   $0x80
  jmp __alltraps
  102145:	e9 f4 05 00 00       	jmp    10273e <__alltraps>

0010214a <vector129>:
.globl vector129
vector129:
  pushl $0
  10214a:	6a 00                	push   $0x0
  pushl $129
  10214c:	68 81 00 00 00       	push   $0x81
  jmp __alltraps
  102151:	e9 e8 05 00 00       	jmp    10273e <__alltraps>

00102156 <vector130>:
.globl vector130
vector130:
  pushl $0
  102156:	6a 00                	push   $0x0
  pushl $130
  102158:	68 82 00 00 00       	push   $0x82
  jmp __alltraps
  10215d:	e9 dc 05 00 00       	jmp    10273e <__alltraps>

00102162 <vector131>:
.globl vector131
vector131:
  pushl $0
  102162:	6a 00                	push   $0x0
  pushl $131
  102164:	68 83 00 00 00       	push   $0x83
  jmp __alltraps
  102169:	e9 d0 05 00 00       	jmp    10273e <__alltraps>

0010216e <vector132>:
.globl vector132
vector132:
  pushl $0
  10216e:	6a 00                	push   $0x0
  pushl $132
  102170:	68 84 00 00 00       	push   $0x84
  jmp __alltraps
  102175:	e9 c4 05 00 00       	jmp    10273e <__alltraps>

0010217a <vector133>:
.globl vector133
vector133:
  pushl $0
  10217a:	6a 00                	push   $0x0
  pushl $133
  10217c:	68 85 00 00 00       	push   $0x85
  jmp __alltraps
  102181:	e9 b8 05 00 00       	jmp    10273e <__alltraps>

00102186 <vector134>:
.globl vector134
vector134:
  pushl $0
  102186:	6a 00                	push   $0x0
  pushl $134
  102188:	68 86 00 00 00       	push   $0x86
  jmp __alltraps
  10218d:	e9 ac 05 00 00       	jmp    10273e <__alltraps>

00102192 <vector135>:
.globl vector135
vector135:
  pushl $0
  102192:	6a 00                	push   $0x0
  pushl $135
  102194:	68 87 00 00 00       	push   $0x87
  jmp __alltraps
  102199:	e9 a0 05 00 00       	jmp    10273e <__alltraps>

0010219e <vector136>:
.globl vector136
vector136:
  pushl $0
  10219e:	6a 00                	push   $0x0
  pushl $136
  1021a0:	68 88 00 00 00       	push   $0x88
  jmp __alltraps
  1021a5:	e9 94 05 00 00       	jmp    10273e <__alltraps>

001021aa <vector137>:
.globl vector137
vector137:
  pushl $0
  1021aa:	6a 00                	push   $0x0
  pushl $137
  1021ac:	68 89 00 00 00       	push   $0x89
  jmp __alltraps
  1021b1:	e9 88 05 00 00       	jmp    10273e <__alltraps>

001021b6 <vector138>:
.globl vector138
vector138:
  pushl $0
  1021b6:	6a 00                	push   $0x0
  pushl $138
  1021b8:	68 8a 00 00 00       	push   $0x8a
  jmp __alltraps
  1021bd:	e9 7c 05 00 00       	jmp    10273e <__alltraps>

001021c2 <vector139>:
.globl vector139
vector139:
  pushl $0
  1021c2:	6a 00                	push   $0x0
  pushl $139
  1021c4:	68 8b 00 00 00       	push   $0x8b
  jmp __alltraps
  1021c9:	e9 70 05 00 00       	jmp    10273e <__alltraps>

001021ce <vector140>:
.globl vector140
vector140:
  pushl $0
  1021ce:	6a 00                	push   $0x0
  pushl $140
  1021d0:	68 8c 00 00 00       	push   $0x8c
  jmp __alltraps
  1021d5:	e9 64 05 00 00       	jmp    10273e <__alltraps>

001021da <vector141>:
.globl vector141
vector141:
  pushl $0
  1021da:	6a 00                	push   $0x0
  pushl $141
  1021dc:	68 8d 00 00 00       	push   $0x8d
  jmp __alltraps
  1021e1:	e9 58 05 00 00       	jmp    10273e <__alltraps>

001021e6 <vector142>:
.globl vector142
vector142:
  pushl $0
  1021e6:	6a 00                	push   $0x0
  pushl $142
  1021e8:	68 8e 00 00 00       	push   $0x8e
  jmp __alltraps
  1021ed:	e9 4c 05 00 00       	jmp    10273e <__alltraps>

001021f2 <vector143>:
.globl vector143
vector143:
  pushl $0
  1021f2:	6a 00                	push   $0x0
  pushl $143
  1021f4:	68 8f 00 00 00       	push   $0x8f
  jmp __alltraps
  1021f9:	e9 40 05 00 00       	jmp    10273e <__alltraps>

001021fe <vector144>:
.globl vector144
vector144:
  pushl $0
  1021fe:	6a 00                	push   $0x0
  pushl $144
  102200:	68 90 00 00 00       	push   $0x90
  jmp __alltraps
  102205:	e9 34 05 00 00       	jmp    10273e <__alltraps>

0010220a <vector145>:
.globl vector145
vector145:
  pushl $0
  10220a:	6a 00                	push   $0x0
  pushl $145
  10220c:	68 91 00 00 00       	push   $0x91
  jmp __alltraps
  102211:	e9 28 05 00 00       	jmp    10273e <__alltraps>

00102216 <vector146>:
.globl vector146
vector146:
  pushl $0
  102216:	6a 00                	push   $0x0
  pushl $146
  102218:	68 92 00 00 00       	push   $0x92
  jmp __alltraps
  10221d:	e9 1c 05 00 00       	jmp    10273e <__alltraps>

00102222 <vector147>:
.globl vector147
vector147:
  pushl $0
  102222:	6a 00                	push   $0x0
  pushl $147
  102224:	68 93 00 00 00       	push   $0x93
  jmp __alltraps
  102229:	e9 10 05 00 00       	jmp    10273e <__alltraps>

0010222e <vector148>:
.globl vector148
vector148:
  pushl $0
  10222e:	6a 00                	push   $0x0
  pushl $148
  102230:	68 94 00 00 00       	push   $0x94
  jmp __alltraps
  102235:	e9 04 05 00 00       	jmp    10273e <__alltraps>

0010223a <vector149>:
.globl vector149
vector149:
  pushl $0
  10223a:	6a 00                	push   $0x0
  pushl $149
  10223c:	68 95 00 00 00       	push   $0x95
  jmp __alltraps
  102241:	e9 f8 04 00 00       	jmp    10273e <__alltraps>

00102246 <vector150>:
.globl vector150
vector150:
  pushl $0
  102246:	6a 00                	push   $0x0
  pushl $150
  102248:	68 96 00 00 00       	push   $0x96
  jmp __alltraps
  10224d:	e9 ec 04 00 00       	jmp    10273e <__alltraps>

00102252 <vector151>:
.globl vector151
vector151:
  pushl $0
  102252:	6a 00                	push   $0x0
  pushl $151
  102254:	68 97 00 00 00       	push   $0x97
  jmp __alltraps
  102259:	e9 e0 04 00 00       	jmp    10273e <__alltraps>

0010225e <vector152>:
.globl vector152
vector152:
  pushl $0
  10225e:	6a 00                	push   $0x0
  pushl $152
  102260:	68 98 00 00 00       	push   $0x98
  jmp __alltraps
  102265:	e9 d4 04 00 00       	jmp    10273e <__alltraps>

0010226a <vector153>:
.globl vector153
vector153:
  pushl $0
  10226a:	6a 00                	push   $0x0
  pushl $153
  10226c:	68 99 00 00 00       	push   $0x99
  jmp __alltraps
  102271:	e9 c8 04 00 00       	jmp    10273e <__alltraps>

00102276 <vector154>:
.globl vector154
vector154:
  pushl $0
  102276:	6a 00                	push   $0x0
  pushl $154
  102278:	68 9a 00 00 00       	push   $0x9a
  jmp __alltraps
  10227d:	e9 bc 04 00 00       	jmp    10273e <__alltraps>

00102282 <vector155>:
.globl vector155
vector155:
  pushl $0
  102282:	6a 00                	push   $0x0
  pushl $155
  102284:	68 9b 00 00 00       	push   $0x9b
  jmp __alltraps
  102289:	e9 b0 04 00 00       	jmp    10273e <__alltraps>

0010228e <vector156>:
.globl vector156
vector156:
  pushl $0
  10228e:	6a 00                	push   $0x0
  pushl $156
  102290:	68 9c 00 00 00       	push   $0x9c
  jmp __alltraps
  102295:	e9 a4 04 00 00       	jmp    10273e <__alltraps>

0010229a <vector157>:
.globl vector157
vector157:
  pushl $0
  10229a:	6a 00                	push   $0x0
  pushl $157
  10229c:	68 9d 00 00 00       	push   $0x9d
  jmp __alltraps
  1022a1:	e9 98 04 00 00       	jmp    10273e <__alltraps>

001022a6 <vector158>:
.globl vector158
vector158:
  pushl $0
  1022a6:	6a 00                	push   $0x0
  pushl $158
  1022a8:	68 9e 00 00 00       	push   $0x9e
  jmp __alltraps
  1022ad:	e9 8c 04 00 00       	jmp    10273e <__alltraps>

001022b2 <vector159>:
.globl vector159
vector159:
  pushl $0
  1022b2:	6a 00                	push   $0x0
  pushl $159
  1022b4:	68 9f 00 00 00       	push   $0x9f
  jmp __alltraps
  1022b9:	e9 80 04 00 00       	jmp    10273e <__alltraps>

001022be <vector160>:
.globl vector160
vector160:
  pushl $0
  1022be:	6a 00                	push   $0x0
  pushl $160
  1022c0:	68 a0 00 00 00       	push   $0xa0
  jmp __alltraps
  1022c5:	e9 74 04 00 00       	jmp    10273e <__alltraps>

001022ca <vector161>:
.globl vector161
vector161:
  pushl $0
  1022ca:	6a 00                	push   $0x0
  pushl $161
  1022cc:	68 a1 00 00 00       	push   $0xa1
  jmp __alltraps
  1022d1:	e9 68 04 00 00       	jmp    10273e <__alltraps>

001022d6 <vector162>:
.globl vector162
vector162:
  pushl $0
  1022d6:	6a 00                	push   $0x0
  pushl $162
  1022d8:	68 a2 00 00 00       	push   $0xa2
  jmp __alltraps
  1022dd:	e9 5c 04 00 00       	jmp    10273e <__alltraps>

001022e2 <vector163>:
.globl vector163
vector163:
  pushl $0
  1022e2:	6a 00                	push   $0x0
  pushl $163
  1022e4:	68 a3 00 00 00       	push   $0xa3
  jmp __alltraps
  1022e9:	e9 50 04 00 00       	jmp    10273e <__alltraps>

001022ee <vector164>:
.globl vector164
vector164:
  pushl $0
  1022ee:	6a 00                	push   $0x0
  pushl $164
  1022f0:	68 a4 00 00 00       	push   $0xa4
  jmp __alltraps
  1022f5:	e9 44 04 00 00       	jmp    10273e <__alltraps>

001022fa <vector165>:
.globl vector165
vector165:
  pushl $0
  1022fa:	6a 00                	push   $0x0
  pushl $165
  1022fc:	68 a5 00 00 00       	push   $0xa5
  jmp __alltraps
  102301:	e9 38 04 00 00       	jmp    10273e <__alltraps>

00102306 <vector166>:
.globl vector166
vector166:
  pushl $0
  102306:	6a 00                	push   $0x0
  pushl $166
  102308:	68 a6 00 00 00       	push   $0xa6
  jmp __alltraps
  10230d:	e9 2c 04 00 00       	jmp    10273e <__alltraps>

00102312 <vector167>:
.globl vector167
vector167:
  pushl $0
  102312:	6a 00                	push   $0x0
  pushl $167
  102314:	68 a7 00 00 00       	push   $0xa7
  jmp __alltraps
  102319:	e9 20 04 00 00       	jmp    10273e <__alltraps>

0010231e <vector168>:
.globl vector168
vector168:
  pushl $0
  10231e:	6a 00                	push   $0x0
  pushl $168
  102320:	68 a8 00 00 00       	push   $0xa8
  jmp __alltraps
  102325:	e9 14 04 00 00       	jmp    10273e <__alltraps>

0010232a <vector169>:
.globl vector169
vector169:
  pushl $0
  10232a:	6a 00                	push   $0x0
  pushl $169
  10232c:	68 a9 00 00 00       	push   $0xa9
  jmp __alltraps
  102331:	e9 08 04 00 00       	jmp    10273e <__alltraps>

00102336 <vector170>:
.globl vector170
vector170:
  pushl $0
  102336:	6a 00                	push   $0x0
  pushl $170
  102338:	68 aa 00 00 00       	push   $0xaa
  jmp __alltraps
  10233d:	e9 fc 03 00 00       	jmp    10273e <__alltraps>

00102342 <vector171>:
.globl vector171
vector171:
  pushl $0
  102342:	6a 00                	push   $0x0
  pushl $171
  102344:	68 ab 00 00 00       	push   $0xab
  jmp __alltraps
  102349:	e9 f0 03 00 00       	jmp    10273e <__alltraps>

0010234e <vector172>:
.globl vector172
vector172:
  pushl $0
  10234e:	6a 00                	push   $0x0
  pushl $172
  102350:	68 ac 00 00 00       	push   $0xac
  jmp __alltraps
  102355:	e9 e4 03 00 00       	jmp    10273e <__alltraps>

0010235a <vector173>:
.globl vector173
vector173:
  pushl $0
  10235a:	6a 00                	push   $0x0
  pushl $173
  10235c:	68 ad 00 00 00       	push   $0xad
  jmp __alltraps
  102361:	e9 d8 03 00 00       	jmp    10273e <__alltraps>

00102366 <vector174>:
.globl vector174
vector174:
  pushl $0
  102366:	6a 00                	push   $0x0
  pushl $174
  102368:	68 ae 00 00 00       	push   $0xae
  jmp __alltraps
  10236d:	e9 cc 03 00 00       	jmp    10273e <__alltraps>

00102372 <vector175>:
.globl vector175
vector175:
  pushl $0
  102372:	6a 00                	push   $0x0
  pushl $175
  102374:	68 af 00 00 00       	push   $0xaf
  jmp __alltraps
  102379:	e9 c0 03 00 00       	jmp    10273e <__alltraps>

0010237e <vector176>:
.globl vector176
vector176:
  pushl $0
  10237e:	6a 00                	push   $0x0
  pushl $176
  102380:	68 b0 00 00 00       	push   $0xb0
  jmp __alltraps
  102385:	e9 b4 03 00 00       	jmp    10273e <__alltraps>

0010238a <vector177>:
.globl vector177
vector177:
  pushl $0
  10238a:	6a 00                	push   $0x0
  pushl $177
  10238c:	68 b1 00 00 00       	push   $0xb1
  jmp __alltraps
  102391:	e9 a8 03 00 00       	jmp    10273e <__alltraps>

00102396 <vector178>:
.globl vector178
vector178:
  pushl $0
  102396:	6a 00                	push   $0x0
  pushl $178
  102398:	68 b2 00 00 00       	push   $0xb2
  jmp __alltraps
  10239d:	e9 9c 03 00 00       	jmp    10273e <__alltraps>

001023a2 <vector179>:
.globl vector179
vector179:
  pushl $0
  1023a2:	6a 00                	push   $0x0
  pushl $179
  1023a4:	68 b3 00 00 00       	push   $0xb3
  jmp __alltraps
  1023a9:	e9 90 03 00 00       	jmp    10273e <__alltraps>

001023ae <vector180>:
.globl vector180
vector180:
  pushl $0
  1023ae:	6a 00                	push   $0x0
  pushl $180
  1023b0:	68 b4 00 00 00       	push   $0xb4
  jmp __alltraps
  1023b5:	e9 84 03 00 00       	jmp    10273e <__alltraps>

001023ba <vector181>:
.globl vector181
vector181:
  pushl $0
  1023ba:	6a 00                	push   $0x0
  pushl $181
  1023bc:	68 b5 00 00 00       	push   $0xb5
  jmp __alltraps
  1023c1:	e9 78 03 00 00       	jmp    10273e <__alltraps>

001023c6 <vector182>:
.globl vector182
vector182:
  pushl $0
  1023c6:	6a 00                	push   $0x0
  pushl $182
  1023c8:	68 b6 00 00 00       	push   $0xb6
  jmp __alltraps
  1023cd:	e9 6c 03 00 00       	jmp    10273e <__alltraps>

001023d2 <vector183>:
.globl vector183
vector183:
  pushl $0
  1023d2:	6a 00                	push   $0x0
  pushl $183
  1023d4:	68 b7 00 00 00       	push   $0xb7
  jmp __alltraps
  1023d9:	e9 60 03 00 00       	jmp    10273e <__alltraps>

001023de <vector184>:
.globl vector184
vector184:
  pushl $0
  1023de:	6a 00                	push   $0x0
  pushl $184
  1023e0:	68 b8 00 00 00       	push   $0xb8
  jmp __alltraps
  1023e5:	e9 54 03 00 00       	jmp    10273e <__alltraps>

001023ea <vector185>:
.globl vector185
vector185:
  pushl $0
  1023ea:	6a 00                	push   $0x0
  pushl $185
  1023ec:	68 b9 00 00 00       	push   $0xb9
  jmp __alltraps
  1023f1:	e9 48 03 00 00       	jmp    10273e <__alltraps>

001023f6 <vector186>:
.globl vector186
vector186:
  pushl $0
  1023f6:	6a 00                	push   $0x0
  pushl $186
  1023f8:	68 ba 00 00 00       	push   $0xba
  jmp __alltraps
  1023fd:	e9 3c 03 00 00       	jmp    10273e <__alltraps>

00102402 <vector187>:
.globl vector187
vector187:
  pushl $0
  102402:	6a 00                	push   $0x0
  pushl $187
  102404:	68 bb 00 00 00       	push   $0xbb
  jmp __alltraps
  102409:	e9 30 03 00 00       	jmp    10273e <__alltraps>

0010240e <vector188>:
.globl vector188
vector188:
  pushl $0
  10240e:	6a 00                	push   $0x0
  pushl $188
  102410:	68 bc 00 00 00       	push   $0xbc
  jmp __alltraps
  102415:	e9 24 03 00 00       	jmp    10273e <__alltraps>

0010241a <vector189>:
.globl vector189
vector189:
  pushl $0
  10241a:	6a 00                	push   $0x0
  pushl $189
  10241c:	68 bd 00 00 00       	push   $0xbd
  jmp __alltraps
  102421:	e9 18 03 00 00       	jmp    10273e <__alltraps>

00102426 <vector190>:
.globl vector190
vector190:
  pushl $0
  102426:	6a 00                	push   $0x0
  pushl $190
  102428:	68 be 00 00 00       	push   $0xbe
  jmp __alltraps
  10242d:	e9 0c 03 00 00       	jmp    10273e <__alltraps>

00102432 <vector191>:
.globl vector191
vector191:
  pushl $0
  102432:	6a 00                	push   $0x0
  pushl $191
  102434:	68 bf 00 00 00       	push   $0xbf
  jmp __alltraps
  102439:	e9 00 03 00 00       	jmp    10273e <__alltraps>

0010243e <vector192>:
.globl vector192
vector192:
  pushl $0
  10243e:	6a 00                	push   $0x0
  pushl $192
  102440:	68 c0 00 00 00       	push   $0xc0
  jmp __alltraps
  102445:	e9 f4 02 00 00       	jmp    10273e <__alltraps>

0010244a <vector193>:
.globl vector193
vector193:
  pushl $0
  10244a:	6a 00                	push   $0x0
  pushl $193
  10244c:	68 c1 00 00 00       	push   $0xc1
  jmp __alltraps
  102451:	e9 e8 02 00 00       	jmp    10273e <__alltraps>

00102456 <vector194>:
.globl vector194
vector194:
  pushl $0
  102456:	6a 00                	push   $0x0
  pushl $194
  102458:	68 c2 00 00 00       	push   $0xc2
  jmp __alltraps
  10245d:	e9 dc 02 00 00       	jmp    10273e <__alltraps>

00102462 <vector195>:
.globl vector195
vector195:
  pushl $0
  102462:	6a 00                	push   $0x0
  pushl $195
  102464:	68 c3 00 00 00       	push   $0xc3
  jmp __alltraps
  102469:	e9 d0 02 00 00       	jmp    10273e <__alltraps>

0010246e <vector196>:
.globl vector196
vector196:
  pushl $0
  10246e:	6a 00                	push   $0x0
  pushl $196
  102470:	68 c4 00 00 00       	push   $0xc4
  jmp __alltraps
  102475:	e9 c4 02 00 00       	jmp    10273e <__alltraps>

0010247a <vector197>:
.globl vector197
vector197:
  pushl $0
  10247a:	6a 00                	push   $0x0
  pushl $197
  10247c:	68 c5 00 00 00       	push   $0xc5
  jmp __alltraps
  102481:	e9 b8 02 00 00       	jmp    10273e <__alltraps>

00102486 <vector198>:
.globl vector198
vector198:
  pushl $0
  102486:	6a 00                	push   $0x0
  pushl $198
  102488:	68 c6 00 00 00       	push   $0xc6
  jmp __alltraps
  10248d:	e9 ac 02 00 00       	jmp    10273e <__alltraps>

00102492 <vector199>:
.globl vector199
vector199:
  pushl $0
  102492:	6a 00                	push   $0x0
  pushl $199
  102494:	68 c7 00 00 00       	push   $0xc7
  jmp __alltraps
  102499:	e9 a0 02 00 00       	jmp    10273e <__alltraps>

0010249e <vector200>:
.globl vector200
vector200:
  pushl $0
  10249e:	6a 00                	push   $0x0
  pushl $200
  1024a0:	68 c8 00 00 00       	push   $0xc8
  jmp __alltraps
  1024a5:	e9 94 02 00 00       	jmp    10273e <__alltraps>

001024aa <vector201>:
.globl vector201
vector201:
  pushl $0
  1024aa:	6a 00                	push   $0x0
  pushl $201
  1024ac:	68 c9 00 00 00       	push   $0xc9
  jmp __alltraps
  1024b1:	e9 88 02 00 00       	jmp    10273e <__alltraps>

001024b6 <vector202>:
.globl vector202
vector202:
  pushl $0
  1024b6:	6a 00                	push   $0x0
  pushl $202
  1024b8:	68 ca 00 00 00       	push   $0xca
  jmp __alltraps
  1024bd:	e9 7c 02 00 00       	jmp    10273e <__alltraps>

001024c2 <vector203>:
.globl vector203
vector203:
  pushl $0
  1024c2:	6a 00                	push   $0x0
  pushl $203
  1024c4:	68 cb 00 00 00       	push   $0xcb
  jmp __alltraps
  1024c9:	e9 70 02 00 00       	jmp    10273e <__alltraps>

001024ce <vector204>:
.globl vector204
vector204:
  pushl $0
  1024ce:	6a 00                	push   $0x0
  pushl $204
  1024d0:	68 cc 00 00 00       	push   $0xcc
  jmp __alltraps
  1024d5:	e9 64 02 00 00       	jmp    10273e <__alltraps>

001024da <vector205>:
.globl vector205
vector205:
  pushl $0
  1024da:	6a 00                	push   $0x0
  pushl $205
  1024dc:	68 cd 00 00 00       	push   $0xcd
  jmp __alltraps
  1024e1:	e9 58 02 00 00       	jmp    10273e <__alltraps>

001024e6 <vector206>:
.globl vector206
vector206:
  pushl $0
  1024e6:	6a 00                	push   $0x0
  pushl $206
  1024e8:	68 ce 00 00 00       	push   $0xce
  jmp __alltraps
  1024ed:	e9 4c 02 00 00       	jmp    10273e <__alltraps>

001024f2 <vector207>:
.globl vector207
vector207:
  pushl $0
  1024f2:	6a 00                	push   $0x0
  pushl $207
  1024f4:	68 cf 00 00 00       	push   $0xcf
  jmp __alltraps
  1024f9:	e9 40 02 00 00       	jmp    10273e <__alltraps>

001024fe <vector208>:
.globl vector208
vector208:
  pushl $0
  1024fe:	6a 00                	push   $0x0
  pushl $208
  102500:	68 d0 00 00 00       	push   $0xd0
  jmp __alltraps
  102505:	e9 34 02 00 00       	jmp    10273e <__alltraps>

0010250a <vector209>:
.globl vector209
vector209:
  pushl $0
  10250a:	6a 00                	push   $0x0
  pushl $209
  10250c:	68 d1 00 00 00       	push   $0xd1
  jmp __alltraps
  102511:	e9 28 02 00 00       	jmp    10273e <__alltraps>

00102516 <vector210>:
.globl vector210
vector210:
  pushl $0
  102516:	6a 00                	push   $0x0
  pushl $210
  102518:	68 d2 00 00 00       	push   $0xd2
  jmp __alltraps
  10251d:	e9 1c 02 00 00       	jmp    10273e <__alltraps>

00102522 <vector211>:
.globl vector211
vector211:
  pushl $0
  102522:	6a 00                	push   $0x0
  pushl $211
  102524:	68 d3 00 00 00       	push   $0xd3
  jmp __alltraps
  102529:	e9 10 02 00 00       	jmp    10273e <__alltraps>

0010252e <vector212>:
.globl vector212
vector212:
  pushl $0
  10252e:	6a 00                	push   $0x0
  pushl $212
  102530:	68 d4 00 00 00       	push   $0xd4
  jmp __alltraps
  102535:	e9 04 02 00 00       	jmp    10273e <__alltraps>

0010253a <vector213>:
.globl vector213
vector213:
  pushl $0
  10253a:	6a 00                	push   $0x0
  pushl $213
  10253c:	68 d5 00 00 00       	push   $0xd5
  jmp __alltraps
  102541:	e9 f8 01 00 00       	jmp    10273e <__alltraps>

00102546 <vector214>:
.globl vector214
vector214:
  pushl $0
  102546:	6a 00                	push   $0x0
  pushl $214
  102548:	68 d6 00 00 00       	push   $0xd6
  jmp __alltraps
  10254d:	e9 ec 01 00 00       	jmp    10273e <__alltraps>

00102552 <vector215>:
.globl vector215
vector215:
  pushl $0
  102552:	6a 00                	push   $0x0
  pushl $215
  102554:	68 d7 00 00 00       	push   $0xd7
  jmp __alltraps
  102559:	e9 e0 01 00 00       	jmp    10273e <__alltraps>

0010255e <vector216>:
.globl vector216
vector216:
  pushl $0
  10255e:	6a 00                	push   $0x0
  pushl $216
  102560:	68 d8 00 00 00       	push   $0xd8
  jmp __alltraps
  102565:	e9 d4 01 00 00       	jmp    10273e <__alltraps>

0010256a <vector217>:
.globl vector217
vector217:
  pushl $0
  10256a:	6a 00                	push   $0x0
  pushl $217
  10256c:	68 d9 00 00 00       	push   $0xd9
  jmp __alltraps
  102571:	e9 c8 01 00 00       	jmp    10273e <__alltraps>

00102576 <vector218>:
.globl vector218
vector218:
  pushl $0
  102576:	6a 00                	push   $0x0
  pushl $218
  102578:	68 da 00 00 00       	push   $0xda
  jmp __alltraps
  10257d:	e9 bc 01 00 00       	jmp    10273e <__alltraps>

00102582 <vector219>:
.globl vector219
vector219:
  pushl $0
  102582:	6a 00                	push   $0x0
  pushl $219
  102584:	68 db 00 00 00       	push   $0xdb
  jmp __alltraps
  102589:	e9 b0 01 00 00       	jmp    10273e <__alltraps>

0010258e <vector220>:
.globl vector220
vector220:
  pushl $0
  10258e:	6a 00                	push   $0x0
  pushl $220
  102590:	68 dc 00 00 00       	push   $0xdc
  jmp __alltraps
  102595:	e9 a4 01 00 00       	jmp    10273e <__alltraps>

0010259a <vector221>:
.globl vector221
vector221:
  pushl $0
  10259a:	6a 00                	push   $0x0
  pushl $221
  10259c:	68 dd 00 00 00       	push   $0xdd
  jmp __alltraps
  1025a1:	e9 98 01 00 00       	jmp    10273e <__alltraps>

001025a6 <vector222>:
.globl vector222
vector222:
  pushl $0
  1025a6:	6a 00                	push   $0x0
  pushl $222
  1025a8:	68 de 00 00 00       	push   $0xde
  jmp __alltraps
  1025ad:	e9 8c 01 00 00       	jmp    10273e <__alltraps>

001025b2 <vector223>:
.globl vector223
vector223:
  pushl $0
  1025b2:	6a 00                	push   $0x0
  pushl $223
  1025b4:	68 df 00 00 00       	push   $0xdf
  jmp __alltraps
  1025b9:	e9 80 01 00 00       	jmp    10273e <__alltraps>

001025be <vector224>:
.globl vector224
vector224:
  pushl $0
  1025be:	6a 00                	push   $0x0
  pushl $224
  1025c0:	68 e0 00 00 00       	push   $0xe0
  jmp __alltraps
  1025c5:	e9 74 01 00 00       	jmp    10273e <__alltraps>

001025ca <vector225>:
.globl vector225
vector225:
  pushl $0
  1025ca:	6a 00                	push   $0x0
  pushl $225
  1025cc:	68 e1 00 00 00       	push   $0xe1
  jmp __alltraps
  1025d1:	e9 68 01 00 00       	jmp    10273e <__alltraps>

001025d6 <vector226>:
.globl vector226
vector226:
  pushl $0
  1025d6:	6a 00                	push   $0x0
  pushl $226
  1025d8:	68 e2 00 00 00       	push   $0xe2
  jmp __alltraps
  1025dd:	e9 5c 01 00 00       	jmp    10273e <__alltraps>

001025e2 <vector227>:
.globl vector227
vector227:
  pushl $0
  1025e2:	6a 00                	push   $0x0
  pushl $227
  1025e4:	68 e3 00 00 00       	push   $0xe3
  jmp __alltraps
  1025e9:	e9 50 01 00 00       	jmp    10273e <__alltraps>

001025ee <vector228>:
.globl vector228
vector228:
  pushl $0
  1025ee:	6a 00                	push   $0x0
  pushl $228
  1025f0:	68 e4 00 00 00       	push   $0xe4
  jmp __alltraps
  1025f5:	e9 44 01 00 00       	jmp    10273e <__alltraps>

001025fa <vector229>:
.globl vector229
vector229:
  pushl $0
  1025fa:	6a 00                	push   $0x0
  pushl $229
  1025fc:	68 e5 00 00 00       	push   $0xe5
  jmp __alltraps
  102601:	e9 38 01 00 00       	jmp    10273e <__alltraps>

00102606 <vector230>:
.globl vector230
vector230:
  pushl $0
  102606:	6a 00                	push   $0x0
  pushl $230
  102608:	68 e6 00 00 00       	push   $0xe6
  jmp __alltraps
  10260d:	e9 2c 01 00 00       	jmp    10273e <__alltraps>

00102612 <vector231>:
.globl vector231
vector231:
  pushl $0
  102612:	6a 00                	push   $0x0
  pushl $231
  102614:	68 e7 00 00 00       	push   $0xe7
  jmp __alltraps
  102619:	e9 20 01 00 00       	jmp    10273e <__alltraps>

0010261e <vector232>:
.globl vector232
vector232:
  pushl $0
  10261e:	6a 00                	push   $0x0
  pushl $232
  102620:	68 e8 00 00 00       	push   $0xe8
  jmp __alltraps
  102625:	e9 14 01 00 00       	jmp    10273e <__alltraps>

0010262a <vector233>:
.globl vector233
vector233:
  pushl $0
  10262a:	6a 00                	push   $0x0
  pushl $233
  10262c:	68 e9 00 00 00       	push   $0xe9
  jmp __alltraps
  102631:	e9 08 01 00 00       	jmp    10273e <__alltraps>

00102636 <vector234>:
.globl vector234
vector234:
  pushl $0
  102636:	6a 00                	push   $0x0
  pushl $234
  102638:	68 ea 00 00 00       	push   $0xea
  jmp __alltraps
  10263d:	e9 fc 00 00 00       	jmp    10273e <__alltraps>

00102642 <vector235>:
.globl vector235
vector235:
  pushl $0
  102642:	6a 00                	push   $0x0
  pushl $235
  102644:	68 eb 00 00 00       	push   $0xeb
  jmp __alltraps
  102649:	e9 f0 00 00 00       	jmp    10273e <__alltraps>

0010264e <vector236>:
.globl vector236
vector236:
  pushl $0
  10264e:	6a 00                	push   $0x0
  pushl $236
  102650:	68 ec 00 00 00       	push   $0xec
  jmp __alltraps
  102655:	e9 e4 00 00 00       	jmp    10273e <__alltraps>

0010265a <vector237>:
.globl vector237
vector237:
  pushl $0
  10265a:	6a 00                	push   $0x0
  pushl $237
  10265c:	68 ed 00 00 00       	push   $0xed
  jmp __alltraps
  102661:	e9 d8 00 00 00       	jmp    10273e <__alltraps>

00102666 <vector238>:
.globl vector238
vector238:
  pushl $0
  102666:	6a 00                	push   $0x0
  pushl $238
  102668:	68 ee 00 00 00       	push   $0xee
  jmp __alltraps
  10266d:	e9 cc 00 00 00       	jmp    10273e <__alltraps>

00102672 <vector239>:
.globl vector239
vector239:
  pushl $0
  102672:	6a 00                	push   $0x0
  pushl $239
  102674:	68 ef 00 00 00       	push   $0xef
  jmp __alltraps
  102679:	e9 c0 00 00 00       	jmp    10273e <__alltraps>

0010267e <vector240>:
.globl vector240
vector240:
  pushl $0
  10267e:	6a 00                	push   $0x0
  pushl $240
  102680:	68 f0 00 00 00       	push   $0xf0
  jmp __alltraps
  102685:	e9 b4 00 00 00       	jmp    10273e <__alltraps>

0010268a <vector241>:
.globl vector241
vector241:
  pushl $0
  10268a:	6a 00                	push   $0x0
  pushl $241
  10268c:	68 f1 00 00 00       	push   $0xf1
  jmp __alltraps
  102691:	e9 a8 00 00 00       	jmp    10273e <__alltraps>

00102696 <vector242>:
.globl vector242
vector242:
  pushl $0
  102696:	6a 00                	push   $0x0
  pushl $242
  102698:	68 f2 00 00 00       	push   $0xf2
  jmp __alltraps
  10269d:	e9 9c 00 00 00       	jmp    10273e <__alltraps>

001026a2 <vector243>:
.globl vector243
vector243:
  pushl $0
  1026a2:	6a 00                	push   $0x0
  pushl $243
  1026a4:	68 f3 00 00 00       	push   $0xf3
  jmp __alltraps
  1026a9:	e9 90 00 00 00       	jmp    10273e <__alltraps>

001026ae <vector244>:
.globl vector244
vector244:
  pushl $0
  1026ae:	6a 00                	push   $0x0
  pushl $244
  1026b0:	68 f4 00 00 00       	push   $0xf4
  jmp __alltraps
  1026b5:	e9 84 00 00 00       	jmp    10273e <__alltraps>

001026ba <vector245>:
.globl vector245
vector245:
  pushl $0
  1026ba:	6a 00                	push   $0x0
  pushl $245
  1026bc:	68 f5 00 00 00       	push   $0xf5
  jmp __alltraps
  1026c1:	e9 78 00 00 00       	jmp    10273e <__alltraps>

001026c6 <vector246>:
.globl vector246
vector246:
  pushl $0
  1026c6:	6a 00                	push   $0x0
  pushl $246
  1026c8:	68 f6 00 00 00       	push   $0xf6
  jmp __alltraps
  1026cd:	e9 6c 00 00 00       	jmp    10273e <__alltraps>

001026d2 <vector247>:
.globl vector247
vector247:
  pushl $0
  1026d2:	6a 00                	push   $0x0
  pushl $247
  1026d4:	68 f7 00 00 00       	push   $0xf7
  jmp __alltraps
  1026d9:	e9 60 00 00 00       	jmp    10273e <__alltraps>

001026de <vector248>:
.globl vector248
vector248:
  pushl $0
  1026de:	6a 00                	push   $0x0
  pushl $248
  1026e0:	68 f8 00 00 00       	push   $0xf8
  jmp __alltraps
  1026e5:	e9 54 00 00 00       	jmp    10273e <__alltraps>

001026ea <vector249>:
.globl vector249
vector249:
  pushl $0
  1026ea:	6a 00                	push   $0x0
  pushl $249
  1026ec:	68 f9 00 00 00       	push   $0xf9
  jmp __alltraps
  1026f1:	e9 48 00 00 00       	jmp    10273e <__alltraps>

001026f6 <vector250>:
.globl vector250
vector250:
  pushl $0
  1026f6:	6a 00                	push   $0x0
  pushl $250
  1026f8:	68 fa 00 00 00       	push   $0xfa
  jmp __alltraps
  1026fd:	e9 3c 00 00 00       	jmp    10273e <__alltraps>

00102702 <vector251>:
.globl vector251
vector251:
  pushl $0
  102702:	6a 00                	push   $0x0
  pushl $251
  102704:	68 fb 00 00 00       	push   $0xfb
  jmp __alltraps
  102709:	e9 30 00 00 00       	jmp    10273e <__alltraps>

0010270e <vector252>:
.globl vector252
vector252:
  pushl $0
  10270e:	6a 00                	push   $0x0
  pushl $252
  102710:	68 fc 00 00 00       	push   $0xfc
  jmp __alltraps
  102715:	e9 24 00 00 00       	jmp    10273e <__alltraps>

0010271a <vector253>:
.globl vector253
vector253:
  pushl $0
  10271a:	6a 00                	push   $0x0
  pushl $253
  10271c:	68 fd 00 00 00       	push   $0xfd
  jmp __alltraps
  102721:	e9 18 00 00 00       	jmp    10273e <__alltraps>

00102726 <vector254>:
.globl vector254
vector254:
  pushl $0
  102726:	6a 00                	push   $0x0
  pushl $254
  102728:	68 fe 00 00 00       	push   $0xfe
  jmp __alltraps
  10272d:	e9 0c 00 00 00       	jmp    10273e <__alltraps>

00102732 <vector255>:
.globl vector255
vector255:
  pushl $0
  102732:	6a 00                	push   $0x0
  pushl $255
  102734:	68 ff 00 00 00       	push   $0xff
  jmp __alltraps
  102739:	e9 00 00 00 00       	jmp    10273e <__alltraps>

0010273e <__alltraps>:
.text
.globl __alltraps
__alltraps:
    # push registers to build a trap frame
    # therefore make the stack look like a struct trapframe
    pushl %ds
  10273e:	1e                   	push   %ds
    pushl %es
  10273f:	06                   	push   %es
    pushl %fs
  102740:	0f a0                	push   %fs
    pushl %gs
  102742:	0f a8                	push   %gs
    pushal
  102744:	60                   	pusha  

    # load GD_KDATA into %ds and %es to set up data segments for kernel
    movl $GD_KDATA, %eax
  102745:	b8 10 00 00 00       	mov    $0x10,%eax
    movw %ax, %ds
  10274a:	8e d8                	mov    %eax,%ds
    movw %ax, %es
  10274c:	8e c0                	mov    %eax,%es

    # push %esp to pass a pointer to the trapframe as an argument to trap()
    pushl %esp
  10274e:	54                   	push   %esp

    # call trap(tf), where tf=%esp
    call trap
  10274f:	e8 64 f5 ff ff       	call   101cb8 <trap>

    # pop the pushed stack pointer
    popl %esp
  102754:	5c                   	pop    %esp

00102755 <__trapret>:

    # return falls through to trapret...
.globl __trapret
__trapret:
    # restore registers from stack
    popal
  102755:	61                   	popa   

    # restore %ds, %es, %fs and %gs
    popl %gs
  102756:	0f a9                	pop    %gs
    popl %fs
  102758:	0f a1                	pop    %fs
    popl %es
  10275a:	07                   	pop    %es
    popl %ds
  10275b:	1f                   	pop    %ds

    # get rid of the trap number and error code
    addl $0x8, %esp
  10275c:	83 c4 08             	add    $0x8,%esp
    iret
  10275f:	cf                   	iret   

00102760 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
  102760:	55                   	push   %ebp
  102761:	89 e5                	mov    %esp,%ebp
    return page - pages;
  102763:	8b 45 08             	mov    0x8(%ebp),%eax
  102766:	8b 15 18 af 11 00    	mov    0x11af18,%edx
  10276c:	29 d0                	sub    %edx,%eax
  10276e:	c1 f8 02             	sar    $0x2,%eax
  102771:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
  102777:	5d                   	pop    %ebp
  102778:	c3                   	ret    

00102779 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
  102779:	55                   	push   %ebp
  10277a:	89 e5                	mov    %esp,%ebp
  10277c:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
  10277f:	8b 45 08             	mov    0x8(%ebp),%eax
  102782:	89 04 24             	mov    %eax,(%esp)
  102785:	e8 d6 ff ff ff       	call   102760 <page2ppn>
  10278a:	c1 e0 0c             	shl    $0xc,%eax
}
  10278d:	c9                   	leave  
  10278e:	c3                   	ret    

0010278f <pa2page>:

static inline struct Page *
pa2page(uintptr_t pa) {
  10278f:	55                   	push   %ebp
  102790:	89 e5                	mov    %esp,%ebp
  102792:	83 ec 18             	sub    $0x18,%esp
    if (PPN(pa) >= npage) {
  102795:	8b 45 08             	mov    0x8(%ebp),%eax
  102798:	c1 e8 0c             	shr    $0xc,%eax
  10279b:	89 c2                	mov    %eax,%edx
  10279d:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  1027a2:	39 c2                	cmp    %eax,%edx
  1027a4:	72 1c                	jb     1027c2 <pa2page+0x33>
        panic("pa2page called with invalid pa");
  1027a6:	c7 44 24 08 70 65 10 	movl   $0x106570,0x8(%esp)
  1027ad:	00 
  1027ae:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  1027b5:	00 
  1027b6:	c7 04 24 8f 65 10 00 	movl   $0x10658f,(%esp)
  1027bd:	e8 27 dc ff ff       	call   1003e9 <__panic>
    }
    return &pages[PPN(pa)];
  1027c2:	8b 0d 18 af 11 00    	mov    0x11af18,%ecx
  1027c8:	8b 45 08             	mov    0x8(%ebp),%eax
  1027cb:	c1 e8 0c             	shr    $0xc,%eax
  1027ce:	89 c2                	mov    %eax,%edx
  1027d0:	89 d0                	mov    %edx,%eax
  1027d2:	c1 e0 02             	shl    $0x2,%eax
  1027d5:	01 d0                	add    %edx,%eax
  1027d7:	c1 e0 02             	shl    $0x2,%eax
  1027da:	01 c8                	add    %ecx,%eax
}
  1027dc:	c9                   	leave  
  1027dd:	c3                   	ret    

001027de <page2kva>:

static inline void *
page2kva(struct Page *page) {
  1027de:	55                   	push   %ebp
  1027df:	89 e5                	mov    %esp,%ebp
  1027e1:	83 ec 28             	sub    $0x28,%esp
    return KADDR(page2pa(page));
  1027e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1027e7:	89 04 24             	mov    %eax,(%esp)
  1027ea:	e8 8a ff ff ff       	call   102779 <page2pa>
  1027ef:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1027f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1027f5:	c1 e8 0c             	shr    $0xc,%eax
  1027f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1027fb:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  102800:	39 45 f0             	cmp    %eax,-0x10(%ebp)
  102803:	72 23                	jb     102828 <page2kva+0x4a>
  102805:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102808:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10280c:	c7 44 24 08 a0 65 10 	movl   $0x1065a0,0x8(%esp)
  102813:	00 
  102814:	c7 44 24 04 61 00 00 	movl   $0x61,0x4(%esp)
  10281b:	00 
  10281c:	c7 04 24 8f 65 10 00 	movl   $0x10658f,(%esp)
  102823:	e8 c1 db ff ff       	call   1003e9 <__panic>
  102828:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10282b:	2d 00 00 00 40       	sub    $0x40000000,%eax
}
  102830:	c9                   	leave  
  102831:	c3                   	ret    

00102832 <pte2page>:
kva2page(void *kva) {
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte) {
  102832:	55                   	push   %ebp
  102833:	89 e5                	mov    %esp,%ebp
  102835:	83 ec 18             	sub    $0x18,%esp
    if (!(pte & PTE_P)) {
  102838:	8b 45 08             	mov    0x8(%ebp),%eax
  10283b:	83 e0 01             	and    $0x1,%eax
  10283e:	85 c0                	test   %eax,%eax
  102840:	75 1c                	jne    10285e <pte2page+0x2c>
        panic("pte2page called with invalid pte");
  102842:	c7 44 24 08 c4 65 10 	movl   $0x1065c4,0x8(%esp)
  102849:	00 
  10284a:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
  102851:	00 
  102852:	c7 04 24 8f 65 10 00 	movl   $0x10658f,(%esp)
  102859:	e8 8b db ff ff       	call   1003e9 <__panic>
    }
    return pa2page(PTE_ADDR(pte));
  10285e:	8b 45 08             	mov    0x8(%ebp),%eax
  102861:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102866:	89 04 24             	mov    %eax,(%esp)
  102869:	e8 21 ff ff ff       	call   10278f <pa2page>
}
  10286e:	c9                   	leave  
  10286f:	c3                   	ret    

00102870 <pde2page>:

static inline struct Page *
pde2page(pde_t pde) {
  102870:	55                   	push   %ebp
  102871:	89 e5                	mov    %esp,%ebp
  102873:	83 ec 18             	sub    $0x18,%esp
    return pa2page(PDE_ADDR(pde));
  102876:	8b 45 08             	mov    0x8(%ebp),%eax
  102879:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10287e:	89 04 24             	mov    %eax,(%esp)
  102881:	e8 09 ff ff ff       	call   10278f <pa2page>
}
  102886:	c9                   	leave  
  102887:	c3                   	ret    

00102888 <page_ref>:

static inline int
page_ref(struct Page *page) {
  102888:	55                   	push   %ebp
  102889:	89 e5                	mov    %esp,%ebp
    return page->ref;
  10288b:	8b 45 08             	mov    0x8(%ebp),%eax
  10288e:	8b 00                	mov    (%eax),%eax
}
  102890:	5d                   	pop    %ebp
  102891:	c3                   	ret    

00102892 <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
  102892:	55                   	push   %ebp
  102893:	89 e5                	mov    %esp,%ebp
    page->ref = val;
  102895:	8b 45 08             	mov    0x8(%ebp),%eax
  102898:	8b 55 0c             	mov    0xc(%ebp),%edx
  10289b:	89 10                	mov    %edx,(%eax)
}
  10289d:	90                   	nop
  10289e:	5d                   	pop    %ebp
  10289f:	c3                   	ret    

001028a0 <page_ref_inc>:

static inline int
page_ref_inc(struct Page *page) {
  1028a0:	55                   	push   %ebp
  1028a1:	89 e5                	mov    %esp,%ebp
    page->ref += 1;
  1028a3:	8b 45 08             	mov    0x8(%ebp),%eax
  1028a6:	8b 00                	mov    (%eax),%eax
  1028a8:	8d 50 01             	lea    0x1(%eax),%edx
  1028ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1028ae:	89 10                	mov    %edx,(%eax)
    return page->ref;
  1028b0:	8b 45 08             	mov    0x8(%ebp),%eax
  1028b3:	8b 00                	mov    (%eax),%eax
}
  1028b5:	5d                   	pop    %ebp
  1028b6:	c3                   	ret    

001028b7 <page_ref_dec>:

static inline int
page_ref_dec(struct Page *page) {
  1028b7:	55                   	push   %ebp
  1028b8:	89 e5                	mov    %esp,%ebp
    page->ref -= 1;
  1028ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1028bd:	8b 00                	mov    (%eax),%eax
  1028bf:	8d 50 ff             	lea    -0x1(%eax),%edx
  1028c2:	8b 45 08             	mov    0x8(%ebp),%eax
  1028c5:	89 10                	mov    %edx,(%eax)
    return page->ref;
  1028c7:	8b 45 08             	mov    0x8(%ebp),%eax
  1028ca:	8b 00                	mov    (%eax),%eax
}
  1028cc:	5d                   	pop    %ebp
  1028cd:	c3                   	ret    

001028ce <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
  1028ce:	55                   	push   %ebp
  1028cf:	89 e5                	mov    %esp,%ebp
  1028d1:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
  1028d4:	9c                   	pushf  
  1028d5:	58                   	pop    %eax
  1028d6:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
  1028d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
  1028dc:	25 00 02 00 00       	and    $0x200,%eax
  1028e1:	85 c0                	test   %eax,%eax
  1028e3:	74 0c                	je     1028f1 <__intr_save+0x23>
        intr_disable();
  1028e5:	e8 d9 ee ff ff       	call   1017c3 <intr_disable>
        return 1;
  1028ea:	b8 01 00 00 00       	mov    $0x1,%eax
  1028ef:	eb 05                	jmp    1028f6 <__intr_save+0x28>
    }
    return 0;
  1028f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1028f6:	c9                   	leave  
  1028f7:	c3                   	ret    

001028f8 <__intr_restore>:

static inline void
__intr_restore(bool flag) {
  1028f8:	55                   	push   %ebp
  1028f9:	89 e5                	mov    %esp,%ebp
  1028fb:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
  1028fe:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102902:	74 05                	je     102909 <__intr_restore+0x11>
        intr_enable();
  102904:	e8 b3 ee ff ff       	call   1017bc <intr_enable>
    }
}
  102909:	90                   	nop
  10290a:	c9                   	leave  
  10290b:	c3                   	ret    

0010290c <lgdt>:
/* *
 * lgdt - load the global descriptor table register and reset the
 * data/code segement registers for kernel.
 * */
static inline void
lgdt(struct pseudodesc *pd) {
  10290c:	55                   	push   %ebp
  10290d:	89 e5                	mov    %esp,%ebp
    asm volatile ("lgdt (%0)" :: "r" (pd));
  10290f:	8b 45 08             	mov    0x8(%ebp),%eax
  102912:	0f 01 10             	lgdtl  (%eax)
    asm volatile ("movw %%ax, %%gs" :: "a" (USER_DS));
  102915:	b8 23 00 00 00       	mov    $0x23,%eax
  10291a:	8e e8                	mov    %eax,%gs
    asm volatile ("movw %%ax, %%fs" :: "a" (USER_DS));
  10291c:	b8 23 00 00 00       	mov    $0x23,%eax
  102921:	8e e0                	mov    %eax,%fs
    asm volatile ("movw %%ax, %%es" :: "a" (KERNEL_DS));
  102923:	b8 10 00 00 00       	mov    $0x10,%eax
  102928:	8e c0                	mov    %eax,%es
    asm volatile ("movw %%ax, %%ds" :: "a" (KERNEL_DS));
  10292a:	b8 10 00 00 00       	mov    $0x10,%eax
  10292f:	8e d8                	mov    %eax,%ds
    asm volatile ("movw %%ax, %%ss" :: "a" (KERNEL_DS));
  102931:	b8 10 00 00 00       	mov    $0x10,%eax
  102936:	8e d0                	mov    %eax,%ss
    // reload cs
    asm volatile ("ljmp %0, $1f\n 1:\n" :: "i" (KERNEL_CS));
  102938:	ea 3f 29 10 00 08 00 	ljmp   $0x8,$0x10293f
}
  10293f:	90                   	nop
  102940:	5d                   	pop    %ebp
  102941:	c3                   	ret    

00102942 <load_esp0>:
 * load_esp0 - change the ESP0 in default task state segment,
 * so that we can use different kernel stack when we trap frame
 * user to kernel.
 * */
void
load_esp0(uintptr_t esp0) {
  102942:	55                   	push   %ebp
  102943:	89 e5                	mov    %esp,%ebp
    ts.ts_esp0 = esp0;
  102945:	8b 45 08             	mov    0x8(%ebp),%eax
  102948:	a3 a4 ae 11 00       	mov    %eax,0x11aea4
}
  10294d:	90                   	nop
  10294e:	5d                   	pop    %ebp
  10294f:	c3                   	ret    

00102950 <gdt_init>:

/* gdt_init - initialize the default GDT and TSS */
static void
gdt_init(void) {
  102950:	55                   	push   %ebp
  102951:	89 e5                	mov    %esp,%ebp
  102953:	83 ec 14             	sub    $0x14,%esp
    // set boot kernel stack and default SS0
    load_esp0((uintptr_t)bootstacktop);
  102956:	b8 00 70 11 00       	mov    $0x117000,%eax
  10295b:	89 04 24             	mov    %eax,(%esp)
  10295e:	e8 df ff ff ff       	call   102942 <load_esp0>
    ts.ts_ss0 = KERNEL_DS;
  102963:	66 c7 05 a8 ae 11 00 	movw   $0x10,0x11aea8
  10296a:	10 00 

    // initialize the TSS filed of the gdt
    gdt[SEG_TSS] = SEGTSS(STS_T32A, (uintptr_t)&ts, sizeof(ts), DPL_KERNEL);
  10296c:	66 c7 05 28 7a 11 00 	movw   $0x68,0x117a28
  102973:	68 00 
  102975:	b8 a0 ae 11 00       	mov    $0x11aea0,%eax
  10297a:	0f b7 c0             	movzwl %ax,%eax
  10297d:	66 a3 2a 7a 11 00    	mov    %ax,0x117a2a
  102983:	b8 a0 ae 11 00       	mov    $0x11aea0,%eax
  102988:	c1 e8 10             	shr    $0x10,%eax
  10298b:	a2 2c 7a 11 00       	mov    %al,0x117a2c
  102990:	0f b6 05 2d 7a 11 00 	movzbl 0x117a2d,%eax
  102997:	24 f0                	and    $0xf0,%al
  102999:	0c 09                	or     $0x9,%al
  10299b:	a2 2d 7a 11 00       	mov    %al,0x117a2d
  1029a0:	0f b6 05 2d 7a 11 00 	movzbl 0x117a2d,%eax
  1029a7:	24 ef                	and    $0xef,%al
  1029a9:	a2 2d 7a 11 00       	mov    %al,0x117a2d
  1029ae:	0f b6 05 2d 7a 11 00 	movzbl 0x117a2d,%eax
  1029b5:	24 9f                	and    $0x9f,%al
  1029b7:	a2 2d 7a 11 00       	mov    %al,0x117a2d
  1029bc:	0f b6 05 2d 7a 11 00 	movzbl 0x117a2d,%eax
  1029c3:	0c 80                	or     $0x80,%al
  1029c5:	a2 2d 7a 11 00       	mov    %al,0x117a2d
  1029ca:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  1029d1:	24 f0                	and    $0xf0,%al
  1029d3:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  1029d8:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  1029df:	24 ef                	and    $0xef,%al
  1029e1:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  1029e6:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  1029ed:	24 df                	and    $0xdf,%al
  1029ef:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  1029f4:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  1029fb:	0c 40                	or     $0x40,%al
  1029fd:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  102a02:	0f b6 05 2e 7a 11 00 	movzbl 0x117a2e,%eax
  102a09:	24 7f                	and    $0x7f,%al
  102a0b:	a2 2e 7a 11 00       	mov    %al,0x117a2e
  102a10:	b8 a0 ae 11 00       	mov    $0x11aea0,%eax
  102a15:	c1 e8 18             	shr    $0x18,%eax
  102a18:	a2 2f 7a 11 00       	mov    %al,0x117a2f

    // reload all segment registers
    lgdt(&gdt_pd);
  102a1d:	c7 04 24 30 7a 11 00 	movl   $0x117a30,(%esp)
  102a24:	e8 e3 fe ff ff       	call   10290c <lgdt>
  102a29:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
    asm volatile ("cli" ::: "memory");
}

static inline void
ltr(uint16_t sel) {
    asm volatile ("ltr %0" :: "r" (sel) : "memory");
  102a2f:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
  102a33:	0f 00 d8             	ltr    %ax

    // load the TSS
    ltr(GD_TSS);
}
  102a36:	90                   	nop
  102a37:	c9                   	leave  
  102a38:	c3                   	ret    

00102a39 <init_pmm_manager>:

//init_pmm_manager - initialize a pmm_manager instance
static void
init_pmm_manager(void) {
  102a39:	55                   	push   %ebp
  102a3a:	89 e5                	mov    %esp,%ebp
  102a3c:	83 ec 18             	sub    $0x18,%esp
    pmm_manager = &default_pmm_manager;
  102a3f:	c7 05 10 af 11 00 80 	movl   $0x106f80,0x11af10
  102a46:	6f 10 00 
    cprintf("memory management: %s\n", pmm_manager->name);
  102a49:	a1 10 af 11 00       	mov    0x11af10,%eax
  102a4e:	8b 00                	mov    (%eax),%eax
  102a50:	89 44 24 04          	mov    %eax,0x4(%esp)
  102a54:	c7 04 24 f0 65 10 00 	movl   $0x1065f0,(%esp)
  102a5b:	e8 32 d8 ff ff       	call   100292 <cprintf>
    pmm_manager->init();
  102a60:	a1 10 af 11 00       	mov    0x11af10,%eax
  102a65:	8b 40 04             	mov    0x4(%eax),%eax
  102a68:	ff d0                	call   *%eax
}
  102a6a:	90                   	nop
  102a6b:	c9                   	leave  
  102a6c:	c3                   	ret    

00102a6d <init_memmap>:

//init_memmap - call pmm->init_memmap to build Page struct for free memory  
static void
init_memmap(struct Page *base, size_t n) {
  102a6d:	55                   	push   %ebp
  102a6e:	89 e5                	mov    %esp,%ebp
  102a70:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->init_memmap(base, n);
  102a73:	a1 10 af 11 00       	mov    0x11af10,%eax
  102a78:	8b 40 08             	mov    0x8(%eax),%eax
  102a7b:	8b 55 0c             	mov    0xc(%ebp),%edx
  102a7e:	89 54 24 04          	mov    %edx,0x4(%esp)
  102a82:	8b 55 08             	mov    0x8(%ebp),%edx
  102a85:	89 14 24             	mov    %edx,(%esp)
  102a88:	ff d0                	call   *%eax
}
  102a8a:	90                   	nop
  102a8b:	c9                   	leave  
  102a8c:	c3                   	ret    

00102a8d <alloc_pages>:

//alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory 
struct Page *
alloc_pages(size_t n) {
  102a8d:	55                   	push   %ebp
  102a8e:	89 e5                	mov    %esp,%ebp
  102a90:	83 ec 28             	sub    $0x28,%esp
    struct Page *page=NULL;
  102a93:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
  102a9a:	e8 2f fe ff ff       	call   1028ce <__intr_save>
  102a9f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        page = pmm_manager->alloc_pages(n);
  102aa2:	a1 10 af 11 00       	mov    0x11af10,%eax
  102aa7:	8b 40 0c             	mov    0xc(%eax),%eax
  102aaa:	8b 55 08             	mov    0x8(%ebp),%edx
  102aad:	89 14 24             	mov    %edx,(%esp)
  102ab0:	ff d0                	call   *%eax
  102ab2:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }
    local_intr_restore(intr_flag);
  102ab5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ab8:	89 04 24             	mov    %eax,(%esp)
  102abb:	e8 38 fe ff ff       	call   1028f8 <__intr_restore>
    return page;
  102ac0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  102ac3:	c9                   	leave  
  102ac4:	c3                   	ret    

00102ac5 <free_pages>:

//free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory 
void
free_pages(struct Page *base, size_t n) {
  102ac5:	55                   	push   %ebp
  102ac6:	89 e5                	mov    %esp,%ebp
  102ac8:	83 ec 28             	sub    $0x28,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
  102acb:	e8 fe fd ff ff       	call   1028ce <__intr_save>
  102ad0:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        pmm_manager->free_pages(base, n);
  102ad3:	a1 10 af 11 00       	mov    0x11af10,%eax
  102ad8:	8b 40 10             	mov    0x10(%eax),%eax
  102adb:	8b 55 0c             	mov    0xc(%ebp),%edx
  102ade:	89 54 24 04          	mov    %edx,0x4(%esp)
  102ae2:	8b 55 08             	mov    0x8(%ebp),%edx
  102ae5:	89 14 24             	mov    %edx,(%esp)
  102ae8:	ff d0                	call   *%eax
    }
    local_intr_restore(intr_flag);
  102aea:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102aed:	89 04 24             	mov    %eax,(%esp)
  102af0:	e8 03 fe ff ff       	call   1028f8 <__intr_restore>
}
  102af5:	90                   	nop
  102af6:	c9                   	leave  
  102af7:	c3                   	ret    

00102af8 <nr_free_pages>:

//nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE) 
//of current free memory
size_t
nr_free_pages(void) {
  102af8:	55                   	push   %ebp
  102af9:	89 e5                	mov    %esp,%ebp
  102afb:	83 ec 28             	sub    $0x28,%esp
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
  102afe:	e8 cb fd ff ff       	call   1028ce <__intr_save>
  102b03:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        ret = pmm_manager->nr_free_pages();
  102b06:	a1 10 af 11 00       	mov    0x11af10,%eax
  102b0b:	8b 40 14             	mov    0x14(%eax),%eax
  102b0e:	ff d0                	call   *%eax
  102b10:	89 45 f0             	mov    %eax,-0x10(%ebp)
    }
    local_intr_restore(intr_flag);
  102b13:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102b16:	89 04 24             	mov    %eax,(%esp)
  102b19:	e8 da fd ff ff       	call   1028f8 <__intr_restore>
    return ret;
  102b1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102b21:	c9                   	leave  
  102b22:	c3                   	ret    

00102b23 <page_init>:

/* pmm_init - initialize the physical memory management */
static void
page_init(void) {
  102b23:	55                   	push   %ebp
  102b24:	89 e5                	mov    %esp,%ebp
  102b26:	57                   	push   %edi
  102b27:	56                   	push   %esi
  102b28:	53                   	push   %ebx
  102b29:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
  102b2f:	c7 45 c4 00 80 00 c0 	movl   $0xc0008000,-0x3c(%ebp)
    uint64_t maxpa = 0;
  102b36:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  102b3d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

    cprintf("e820map:\n");
  102b44:	c7 04 24 07 66 10 00 	movl   $0x106607,(%esp)
  102b4b:	e8 42 d7 ff ff       	call   100292 <cprintf>
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
  102b50:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  102b57:	e9 22 01 00 00       	jmp    102c7e <page_init+0x15b>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
  102b5c:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102b5f:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102b62:	89 d0                	mov    %edx,%eax
  102b64:	c1 e0 02             	shl    $0x2,%eax
  102b67:	01 d0                	add    %edx,%eax
  102b69:	c1 e0 02             	shl    $0x2,%eax
  102b6c:	01 c8                	add    %ecx,%eax
  102b6e:	8b 50 08             	mov    0x8(%eax),%edx
  102b71:	8b 40 04             	mov    0x4(%eax),%eax
  102b74:	89 45 b8             	mov    %eax,-0x48(%ebp)
  102b77:	89 55 bc             	mov    %edx,-0x44(%ebp)
  102b7a:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102b7d:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102b80:	89 d0                	mov    %edx,%eax
  102b82:	c1 e0 02             	shl    $0x2,%eax
  102b85:	01 d0                	add    %edx,%eax
  102b87:	c1 e0 02             	shl    $0x2,%eax
  102b8a:	01 c8                	add    %ecx,%eax
  102b8c:	8b 48 0c             	mov    0xc(%eax),%ecx
  102b8f:	8b 58 10             	mov    0x10(%eax),%ebx
  102b92:	8b 45 b8             	mov    -0x48(%ebp),%eax
  102b95:	8b 55 bc             	mov    -0x44(%ebp),%edx
  102b98:	01 c8                	add    %ecx,%eax
  102b9a:	11 da                	adc    %ebx,%edx
  102b9c:	89 45 b0             	mov    %eax,-0x50(%ebp)
  102b9f:	89 55 b4             	mov    %edx,-0x4c(%ebp)
        cprintf("  memory: %08llx, [%08llx, %08llx], type = %d.\n",
  102ba2:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102ba5:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102ba8:	89 d0                	mov    %edx,%eax
  102baa:	c1 e0 02             	shl    $0x2,%eax
  102bad:	01 d0                	add    %edx,%eax
  102baf:	c1 e0 02             	shl    $0x2,%eax
  102bb2:	01 c8                	add    %ecx,%eax
  102bb4:	83 c0 14             	add    $0x14,%eax
  102bb7:	8b 00                	mov    (%eax),%eax
  102bb9:	89 45 84             	mov    %eax,-0x7c(%ebp)
  102bbc:	8b 45 b0             	mov    -0x50(%ebp),%eax
  102bbf:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  102bc2:	83 c0 ff             	add    $0xffffffff,%eax
  102bc5:	83 d2 ff             	adc    $0xffffffff,%edx
  102bc8:	89 85 78 ff ff ff    	mov    %eax,-0x88(%ebp)
  102bce:	89 95 7c ff ff ff    	mov    %edx,-0x84(%ebp)
  102bd4:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102bd7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102bda:	89 d0                	mov    %edx,%eax
  102bdc:	c1 e0 02             	shl    $0x2,%eax
  102bdf:	01 d0                	add    %edx,%eax
  102be1:	c1 e0 02             	shl    $0x2,%eax
  102be4:	01 c8                	add    %ecx,%eax
  102be6:	8b 48 0c             	mov    0xc(%eax),%ecx
  102be9:	8b 58 10             	mov    0x10(%eax),%ebx
  102bec:	8b 55 84             	mov    -0x7c(%ebp),%edx
  102bef:	89 54 24 1c          	mov    %edx,0x1c(%esp)
  102bf3:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  102bf9:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  102bff:	89 44 24 14          	mov    %eax,0x14(%esp)
  102c03:	89 54 24 18          	mov    %edx,0x18(%esp)
  102c07:	8b 45 b8             	mov    -0x48(%ebp),%eax
  102c0a:	8b 55 bc             	mov    -0x44(%ebp),%edx
  102c0d:	89 44 24 0c          	mov    %eax,0xc(%esp)
  102c11:	89 54 24 10          	mov    %edx,0x10(%esp)
  102c15:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  102c19:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  102c1d:	c7 04 24 14 66 10 00 	movl   $0x106614,(%esp)
  102c24:	e8 69 d6 ff ff       	call   100292 <cprintf>
                memmap->map[i].size, begin, end - 1, memmap->map[i].type);
        if (memmap->map[i].type == E820_ARM) {
  102c29:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102c2c:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102c2f:	89 d0                	mov    %edx,%eax
  102c31:	c1 e0 02             	shl    $0x2,%eax
  102c34:	01 d0                	add    %edx,%eax
  102c36:	c1 e0 02             	shl    $0x2,%eax
  102c39:	01 c8                	add    %ecx,%eax
  102c3b:	83 c0 14             	add    $0x14,%eax
  102c3e:	8b 00                	mov    (%eax),%eax
  102c40:	83 f8 01             	cmp    $0x1,%eax
  102c43:	75 36                	jne    102c7b <page_init+0x158>
            if (maxpa < end && begin < KMEMSIZE) {
  102c45:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102c48:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  102c4b:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
  102c4e:	77 2b                	ja     102c7b <page_init+0x158>
  102c50:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
  102c53:	72 05                	jb     102c5a <page_init+0x137>
  102c55:	3b 45 b0             	cmp    -0x50(%ebp),%eax
  102c58:	73 21                	jae    102c7b <page_init+0x158>
  102c5a:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
  102c5e:	77 1b                	ja     102c7b <page_init+0x158>
  102c60:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
  102c64:	72 09                	jb     102c6f <page_init+0x14c>
  102c66:	81 7d b8 ff ff ff 37 	cmpl   $0x37ffffff,-0x48(%ebp)
  102c6d:	77 0c                	ja     102c7b <page_init+0x158>
                maxpa = end;
  102c6f:	8b 45 b0             	mov    -0x50(%ebp),%eax
  102c72:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  102c75:	89 45 e0             	mov    %eax,-0x20(%ebp)
  102c78:	89 55 e4             	mov    %edx,-0x1c(%ebp)
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
    uint64_t maxpa = 0;

    cprintf("e820map:\n");
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
  102c7b:	ff 45 dc             	incl   -0x24(%ebp)
  102c7e:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  102c81:	8b 00                	mov    (%eax),%eax
  102c83:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  102c86:	0f 8f d0 fe ff ff    	jg     102b5c <page_init+0x39>
            if (maxpa < end && begin < KMEMSIZE) {
                maxpa = end;
            }
        }
    }
    if (maxpa > KMEMSIZE) {
  102c8c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  102c90:	72 1d                	jb     102caf <page_init+0x18c>
  102c92:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  102c96:	77 09                	ja     102ca1 <page_init+0x17e>
  102c98:	81 7d e0 00 00 00 38 	cmpl   $0x38000000,-0x20(%ebp)
  102c9f:	76 0e                	jbe    102caf <page_init+0x18c>
        maxpa = KMEMSIZE;
  102ca1:	c7 45 e0 00 00 00 38 	movl   $0x38000000,-0x20(%ebp)
  102ca8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    }

    extern char end[];

    npage = maxpa / PGSIZE;
  102caf:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102cb2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  102cb5:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
  102cb9:	c1 ea 0c             	shr    $0xc,%edx
  102cbc:	a3 80 ae 11 00       	mov    %eax,0x11ae80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
  102cc1:	c7 45 ac 00 10 00 00 	movl   $0x1000,-0x54(%ebp)
  102cc8:	b8 28 af 11 00       	mov    $0x11af28,%eax
  102ccd:	8d 50 ff             	lea    -0x1(%eax),%edx
  102cd0:	8b 45 ac             	mov    -0x54(%ebp),%eax
  102cd3:	01 d0                	add    %edx,%eax
  102cd5:	89 45 a8             	mov    %eax,-0x58(%ebp)
  102cd8:	8b 45 a8             	mov    -0x58(%ebp),%eax
  102cdb:	ba 00 00 00 00       	mov    $0x0,%edx
  102ce0:	f7 75 ac             	divl   -0x54(%ebp)
  102ce3:	8b 45 a8             	mov    -0x58(%ebp),%eax
  102ce6:	29 d0                	sub    %edx,%eax
  102ce8:	a3 18 af 11 00       	mov    %eax,0x11af18

    for (i = 0; i < npage; i ++) {
  102ced:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  102cf4:	eb 2e                	jmp    102d24 <page_init+0x201>
        SetPageReserved(pages + i);
  102cf6:	8b 0d 18 af 11 00    	mov    0x11af18,%ecx
  102cfc:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102cff:	89 d0                	mov    %edx,%eax
  102d01:	c1 e0 02             	shl    $0x2,%eax
  102d04:	01 d0                	add    %edx,%eax
  102d06:	c1 e0 02             	shl    $0x2,%eax
  102d09:	01 c8                	add    %ecx,%eax
  102d0b:	83 c0 04             	add    $0x4,%eax
  102d0e:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  102d15:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  102d18:	8b 45 8c             	mov    -0x74(%ebp),%eax
  102d1b:	8b 55 90             	mov    -0x70(%ebp),%edx
  102d1e:	0f ab 10             	bts    %edx,(%eax)
    extern char end[];

    npage = maxpa / PGSIZE;
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    for (i = 0; i < npage; i ++) {
  102d21:	ff 45 dc             	incl   -0x24(%ebp)
  102d24:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102d27:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  102d2c:	39 c2                	cmp    %eax,%edx
  102d2e:	72 c6                	jb     102cf6 <page_init+0x1d3>
        SetPageReserved(pages + i);
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);
  102d30:	8b 15 80 ae 11 00    	mov    0x11ae80,%edx
  102d36:	89 d0                	mov    %edx,%eax
  102d38:	c1 e0 02             	shl    $0x2,%eax
  102d3b:	01 d0                	add    %edx,%eax
  102d3d:	c1 e0 02             	shl    $0x2,%eax
  102d40:	89 c2                	mov    %eax,%edx
  102d42:	a1 18 af 11 00       	mov    0x11af18,%eax
  102d47:	01 d0                	add    %edx,%eax
  102d49:	89 45 a4             	mov    %eax,-0x5c(%ebp)
  102d4c:	81 7d a4 ff ff ff bf 	cmpl   $0xbfffffff,-0x5c(%ebp)
  102d53:	77 23                	ja     102d78 <page_init+0x255>
  102d55:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  102d58:	89 44 24 0c          	mov    %eax,0xc(%esp)
  102d5c:	c7 44 24 08 44 66 10 	movl   $0x106644,0x8(%esp)
  102d63:	00 
  102d64:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  102d6b:	00 
  102d6c:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  102d73:	e8 71 d6 ff ff       	call   1003e9 <__panic>
  102d78:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  102d7b:	05 00 00 00 40       	add    $0x40000000,%eax
  102d80:	89 45 a0             	mov    %eax,-0x60(%ebp)

    for (i = 0; i < memmap->nr_map; i ++) {
  102d83:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  102d8a:	e9 61 01 00 00       	jmp    102ef0 <page_init+0x3cd>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
  102d8f:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102d92:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102d95:	89 d0                	mov    %edx,%eax
  102d97:	c1 e0 02             	shl    $0x2,%eax
  102d9a:	01 d0                	add    %edx,%eax
  102d9c:	c1 e0 02             	shl    $0x2,%eax
  102d9f:	01 c8                	add    %ecx,%eax
  102da1:	8b 50 08             	mov    0x8(%eax),%edx
  102da4:	8b 40 04             	mov    0x4(%eax),%eax
  102da7:	89 45 d0             	mov    %eax,-0x30(%ebp)
  102daa:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  102dad:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102db0:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102db3:	89 d0                	mov    %edx,%eax
  102db5:	c1 e0 02             	shl    $0x2,%eax
  102db8:	01 d0                	add    %edx,%eax
  102dba:	c1 e0 02             	shl    $0x2,%eax
  102dbd:	01 c8                	add    %ecx,%eax
  102dbf:	8b 48 0c             	mov    0xc(%eax),%ecx
  102dc2:	8b 58 10             	mov    0x10(%eax),%ebx
  102dc5:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102dc8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  102dcb:	01 c8                	add    %ecx,%eax
  102dcd:	11 da                	adc    %ebx,%edx
  102dcf:	89 45 c8             	mov    %eax,-0x38(%ebp)
  102dd2:	89 55 cc             	mov    %edx,-0x34(%ebp)
        if (memmap->map[i].type == E820_ARM) {
  102dd5:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  102dd8:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102ddb:	89 d0                	mov    %edx,%eax
  102ddd:	c1 e0 02             	shl    $0x2,%eax
  102de0:	01 d0                	add    %edx,%eax
  102de2:	c1 e0 02             	shl    $0x2,%eax
  102de5:	01 c8                	add    %ecx,%eax
  102de7:	83 c0 14             	add    $0x14,%eax
  102dea:	8b 00                	mov    (%eax),%eax
  102dec:	83 f8 01             	cmp    $0x1,%eax
  102def:	0f 85 f8 00 00 00    	jne    102eed <page_init+0x3ca>
            if (begin < freemem) {
  102df5:	8b 45 a0             	mov    -0x60(%ebp),%eax
  102df8:	ba 00 00 00 00       	mov    $0x0,%edx
  102dfd:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  102e00:	72 17                	jb     102e19 <page_init+0x2f6>
  102e02:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  102e05:	77 05                	ja     102e0c <page_init+0x2e9>
  102e07:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102e0a:	76 0d                	jbe    102e19 <page_init+0x2f6>
                begin = freemem;
  102e0c:	8b 45 a0             	mov    -0x60(%ebp),%eax
  102e0f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  102e12:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
            }
            if (end > KMEMSIZE) {
  102e19:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  102e1d:	72 1d                	jb     102e3c <page_init+0x319>
  102e1f:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
  102e23:	77 09                	ja     102e2e <page_init+0x30b>
  102e25:	81 7d c8 00 00 00 38 	cmpl   $0x38000000,-0x38(%ebp)
  102e2c:	76 0e                	jbe    102e3c <page_init+0x319>
                end = KMEMSIZE;
  102e2e:	c7 45 c8 00 00 00 38 	movl   $0x38000000,-0x38(%ebp)
  102e35:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
            }
            if (begin < end) {
  102e3c:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102e3f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  102e42:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  102e45:	0f 87 a2 00 00 00    	ja     102eed <page_init+0x3ca>
  102e4b:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  102e4e:	72 09                	jb     102e59 <page_init+0x336>
  102e50:	3b 45 c8             	cmp    -0x38(%ebp),%eax
  102e53:	0f 83 94 00 00 00    	jae    102eed <page_init+0x3ca>
                begin = ROUNDUP(begin, PGSIZE);
  102e59:	c7 45 9c 00 10 00 00 	movl   $0x1000,-0x64(%ebp)
  102e60:	8b 55 d0             	mov    -0x30(%ebp),%edx
  102e63:	8b 45 9c             	mov    -0x64(%ebp),%eax
  102e66:	01 d0                	add    %edx,%eax
  102e68:	48                   	dec    %eax
  102e69:	89 45 98             	mov    %eax,-0x68(%ebp)
  102e6c:	8b 45 98             	mov    -0x68(%ebp),%eax
  102e6f:	ba 00 00 00 00       	mov    $0x0,%edx
  102e74:	f7 75 9c             	divl   -0x64(%ebp)
  102e77:	8b 45 98             	mov    -0x68(%ebp),%eax
  102e7a:	29 d0                	sub    %edx,%eax
  102e7c:	ba 00 00 00 00       	mov    $0x0,%edx
  102e81:	89 45 d0             	mov    %eax,-0x30(%ebp)
  102e84:	89 55 d4             	mov    %edx,-0x2c(%ebp)
                end = ROUNDDOWN(end, PGSIZE);
  102e87:	8b 45 c8             	mov    -0x38(%ebp),%eax
  102e8a:	89 45 94             	mov    %eax,-0x6c(%ebp)
  102e8d:	8b 45 94             	mov    -0x6c(%ebp),%eax
  102e90:	ba 00 00 00 00       	mov    $0x0,%edx
  102e95:	89 c3                	mov    %eax,%ebx
  102e97:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  102e9d:	89 de                	mov    %ebx,%esi
  102e9f:	89 d0                	mov    %edx,%eax
  102ea1:	83 e0 00             	and    $0x0,%eax
  102ea4:	89 c7                	mov    %eax,%edi
  102ea6:	89 75 c8             	mov    %esi,-0x38(%ebp)
  102ea9:	89 7d cc             	mov    %edi,-0x34(%ebp)
                if (begin < end) {
  102eac:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102eaf:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  102eb2:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  102eb5:	77 36                	ja     102eed <page_init+0x3ca>
  102eb7:	3b 55 cc             	cmp    -0x34(%ebp),%edx
  102eba:	72 05                	jb     102ec1 <page_init+0x39e>
  102ebc:	3b 45 c8             	cmp    -0x38(%ebp),%eax
  102ebf:	73 2c                	jae    102eed <page_init+0x3ca>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
  102ec1:	8b 45 c8             	mov    -0x38(%ebp),%eax
  102ec4:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102ec7:	2b 45 d0             	sub    -0x30(%ebp),%eax
  102eca:	1b 55 d4             	sbb    -0x2c(%ebp),%edx
  102ecd:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
  102ed1:	c1 ea 0c             	shr    $0xc,%edx
  102ed4:	89 c3                	mov    %eax,%ebx
  102ed6:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102ed9:	89 04 24             	mov    %eax,(%esp)
  102edc:	e8 ae f8 ff ff       	call   10278f <pa2page>
  102ee1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  102ee5:	89 04 24             	mov    %eax,(%esp)
  102ee8:	e8 80 fb ff ff       	call   102a6d <init_memmap>
        SetPageReserved(pages + i);
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);

    for (i = 0; i < memmap->nr_map; i ++) {
  102eed:	ff 45 dc             	incl   -0x24(%ebp)
  102ef0:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  102ef3:	8b 00                	mov    (%eax),%eax
  102ef5:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  102ef8:	0f 8f 91 fe ff ff    	jg     102d8f <page_init+0x26c>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
                }
            }
        }
    }
}
  102efe:	90                   	nop
  102eff:	81 c4 9c 00 00 00    	add    $0x9c,%esp
  102f05:	5b                   	pop    %ebx
  102f06:	5e                   	pop    %esi
  102f07:	5f                   	pop    %edi
  102f08:	5d                   	pop    %ebp
  102f09:	c3                   	ret    

00102f0a <boot_map_segment>:
//  la:   linear address of this memory need to map (after x86 segment map)
//  size: memory size
//  pa:   physical address of this memory
//  perm: permission of this memory  
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
  102f0a:	55                   	push   %ebp
  102f0b:	89 e5                	mov    %esp,%ebp
  102f0d:	83 ec 38             	sub    $0x38,%esp
    assert(PGOFF(la) == PGOFF(pa));
  102f10:	8b 45 0c             	mov    0xc(%ebp),%eax
  102f13:	33 45 14             	xor    0x14(%ebp),%eax
  102f16:	25 ff 0f 00 00       	and    $0xfff,%eax
  102f1b:	85 c0                	test   %eax,%eax
  102f1d:	74 24                	je     102f43 <boot_map_segment+0x39>
  102f1f:	c7 44 24 0c 76 66 10 	movl   $0x106676,0xc(%esp)
  102f26:	00 
  102f27:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  102f2e:	00 
  102f2f:	c7 44 24 04 06 01 00 	movl   $0x106,0x4(%esp)
  102f36:	00 
  102f37:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  102f3e:	e8 a6 d4 ff ff       	call   1003e9 <__panic>
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
  102f43:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
  102f4a:	8b 45 0c             	mov    0xc(%ebp),%eax
  102f4d:	25 ff 0f 00 00       	and    $0xfff,%eax
  102f52:	89 c2                	mov    %eax,%edx
  102f54:	8b 45 10             	mov    0x10(%ebp),%eax
  102f57:	01 c2                	add    %eax,%edx
  102f59:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102f5c:	01 d0                	add    %edx,%eax
  102f5e:	48                   	dec    %eax
  102f5f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  102f62:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102f65:	ba 00 00 00 00       	mov    $0x0,%edx
  102f6a:	f7 75 f0             	divl   -0x10(%ebp)
  102f6d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102f70:	29 d0                	sub    %edx,%eax
  102f72:	c1 e8 0c             	shr    $0xc,%eax
  102f75:	89 45 f4             	mov    %eax,-0xc(%ebp)
    la = ROUNDDOWN(la, PGSIZE);
  102f78:	8b 45 0c             	mov    0xc(%ebp),%eax
  102f7b:	89 45 e8             	mov    %eax,-0x18(%ebp)
  102f7e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102f81:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102f86:	89 45 0c             	mov    %eax,0xc(%ebp)
    pa = ROUNDDOWN(pa, PGSIZE);
  102f89:	8b 45 14             	mov    0x14(%ebp),%eax
  102f8c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  102f8f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102f92:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102f97:	89 45 14             	mov    %eax,0x14(%ebp)
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
  102f9a:	eb 68                	jmp    103004 <boot_map_segment+0xfa>
        pte_t *ptep = get_pte(pgdir, la, 1);
  102f9c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  102fa3:	00 
  102fa4:	8b 45 0c             	mov    0xc(%ebp),%eax
  102fa7:	89 44 24 04          	mov    %eax,0x4(%esp)
  102fab:	8b 45 08             	mov    0x8(%ebp),%eax
  102fae:	89 04 24             	mov    %eax,(%esp)
  102fb1:	e8 81 01 00 00       	call   103137 <get_pte>
  102fb6:	89 45 e0             	mov    %eax,-0x20(%ebp)
        assert(ptep != NULL);
  102fb9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  102fbd:	75 24                	jne    102fe3 <boot_map_segment+0xd9>
  102fbf:	c7 44 24 0c a2 66 10 	movl   $0x1066a2,0xc(%esp)
  102fc6:	00 
  102fc7:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  102fce:	00 
  102fcf:	c7 44 24 04 0c 01 00 	movl   $0x10c,0x4(%esp)
  102fd6:	00 
  102fd7:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  102fde:	e8 06 d4 ff ff       	call   1003e9 <__panic>
        *ptep = pa | PTE_P | perm;
  102fe3:	8b 45 14             	mov    0x14(%ebp),%eax
  102fe6:	0b 45 18             	or     0x18(%ebp),%eax
  102fe9:	83 c8 01             	or     $0x1,%eax
  102fec:	89 c2                	mov    %eax,%edx
  102fee:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102ff1:	89 10                	mov    %edx,(%eax)
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
    assert(PGOFF(la) == PGOFF(pa));
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
  102ff3:	ff 4d f4             	decl   -0xc(%ebp)
  102ff6:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
  102ffd:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  103004:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103008:	75 92                	jne    102f9c <boot_map_segment+0x92>
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pa | PTE_P | perm;
    }
}
  10300a:	90                   	nop
  10300b:	c9                   	leave  
  10300c:	c3                   	ret    

0010300d <boot_alloc_page>:

//boot_alloc_page - allocate one page using pmm->alloc_pages(1) 
// return value: the kernel virtual address of this allocated page
//note: this function is used to get the memory for PDT(Page Directory Table)&PT(Page Table)
static void *
boot_alloc_page(void) {
  10300d:	55                   	push   %ebp
  10300e:	89 e5                	mov    %esp,%ebp
  103010:	83 ec 28             	sub    $0x28,%esp
    struct Page *p = alloc_page();
  103013:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10301a:	e8 6e fa ff ff       	call   102a8d <alloc_pages>
  10301f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (p == NULL) {
  103022:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103026:	75 1c                	jne    103044 <boot_alloc_page+0x37>
        panic("boot_alloc_page failed.\n");
  103028:	c7 44 24 08 af 66 10 	movl   $0x1066af,0x8(%esp)
  10302f:	00 
  103030:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
  103037:	00 
  103038:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  10303f:	e8 a5 d3 ff ff       	call   1003e9 <__panic>
    }
    return page2kva(p);
  103044:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103047:	89 04 24             	mov    %eax,(%esp)
  10304a:	e8 8f f7 ff ff       	call   1027de <page2kva>
}
  10304f:	c9                   	leave  
  103050:	c3                   	ret    

00103051 <pmm_init>:

//pmm_init - setup a pmm to manage physical memory, build PDT&PT to setup paging mechanism 
//         - check the correctness of pmm & paging mechanism, print PDT&PT
void
pmm_init(void) {
  103051:	55                   	push   %ebp
  103052:	89 e5                	mov    %esp,%ebp
  103054:	83 ec 38             	sub    $0x38,%esp
    // We've already enabled paging
    boot_cr3 = PADDR(boot_pgdir);
  103057:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  10305c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10305f:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
  103066:	77 23                	ja     10308b <pmm_init+0x3a>
  103068:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10306b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10306f:	c7 44 24 08 44 66 10 	movl   $0x106644,0x8(%esp)
  103076:	00 
  103077:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
  10307e:	00 
  10307f:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103086:	e8 5e d3 ff ff       	call   1003e9 <__panic>
  10308b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10308e:	05 00 00 00 40       	add    $0x40000000,%eax
  103093:	a3 14 af 11 00       	mov    %eax,0x11af14
    //We need to alloc/free the physical memory (granularity is 4KB or other size). 
    //So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    //First we should init a physical memory manager(pmm) based on the framework.
    //Then pmm can alloc/free the physical memory. 
    //Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();
  103098:	e8 9c f9 ff ff       	call   102a39 <init_pmm_manager>

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();
  10309d:	e8 81 fa ff ff       	call   102b23 <page_init>

    //use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();
  1030a2:	e8 f9 03 00 00       	call   1034a0 <check_alloc_page>

    check_pgdir();
  1030a7:	e8 13 04 00 00       	call   1034bf <check_pgdir>

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // recursively insert boot_pgdir in itself
    // to form a virtual page table at virtual address VPT
    boot_pgdir[PDX(VPT)] = PADDR(boot_pgdir) | PTE_P | PTE_W;
  1030ac:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1030b1:	8d 90 ac 0f 00 00    	lea    0xfac(%eax),%edx
  1030b7:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1030bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1030bf:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
  1030c6:	77 23                	ja     1030eb <pmm_init+0x9a>
  1030c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1030cf:	c7 44 24 08 44 66 10 	movl   $0x106644,0x8(%esp)
  1030d6:	00 
  1030d7:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
  1030de:	00 
  1030df:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  1030e6:	e8 fe d2 ff ff       	call   1003e9 <__panic>
  1030eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030ee:	05 00 00 00 40       	add    $0x40000000,%eax
  1030f3:	83 c8 03             	or     $0x3,%eax
  1030f6:	89 02                	mov    %eax,(%edx)

    // map all physical memory to linear memory with base linear addr KERNBASE
    // linear_addr KERNBASE ~ KERNBASE + KMEMSIZE = phy_addr 0 ~ KMEMSIZE
    boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, 0, PTE_W);
  1030f8:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1030fd:	c7 44 24 10 02 00 00 	movl   $0x2,0x10(%esp)
  103104:	00 
  103105:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10310c:	00 
  10310d:	c7 44 24 08 00 00 00 	movl   $0x38000000,0x8(%esp)
  103114:	38 
  103115:	c7 44 24 04 00 00 00 	movl   $0xc0000000,0x4(%esp)
  10311c:	c0 
  10311d:	89 04 24             	mov    %eax,(%esp)
  103120:	e8 e5 fd ff ff       	call   102f0a <boot_map_segment>

    // Since we are using bootloader's GDT,
    // we should reload gdt (second time, the last time) to get user segments and the TSS
    // map virtual_addr 0 ~ 4G = linear_addr 0 ~ 4G
    // then set kernel stack (ss:esp) in TSS, setup TSS in gdt, load TSS
    gdt_init();
  103125:	e8 26 f8 ff ff       	call   102950 <gdt_init>

    //now the basic virtual memory map(see memalyout.h) is established.
    //check the correctness of the basic virtual memory map.
    check_boot_pgdir();
  10312a:	e8 2c 0a 00 00       	call   103b5b <check_boot_pgdir>

    print_pgdir();
  10312f:	e8 a5 0e 00 00       	call   103fd9 <print_pgdir>

}
  103134:	90                   	nop
  103135:	c9                   	leave  
  103136:	c3                   	ret    

00103137 <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *
get_pte(pde_t *pgdir, uintptr_t la, bool create) {
  103137:	55                   	push   %ebp
  103138:	89 e5                	mov    %esp,%ebp
  10313a:	83 ec 48             	sub    $0x48,%esp
    }
    return NULL;          // (8) return page table entry
#endif
    // Get the page directory entry by adding offset(the index) and the base address of page direcotry table.

    pde_t *entry = &pgdir[PDX(la)];
  10313d:	8b 45 0c             	mov    0xc(%ebp),%eax
  103140:	c1 e8 16             	shr    $0x16,%eax
  103143:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  10314a:	8b 45 08             	mov    0x8(%ebp),%eax
  10314d:	01 d0                	add    %edx,%eax
  10314f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    
    if (!(*entry & PTE_P)) {
  103152:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103155:	8b 00                	mov    (%eax),%eax
  103157:	83 e0 01             	and    $0x1,%eax
  10315a:	85 c0                	test   %eax,%eax
  10315c:	0f 85 b6 00 00 00    	jne    103218 <get_pte+0xe1>
        // Not present in the table? We need to allocate the page table.
        struct Page *page = create ? alloc_page() : NULL;
  103162:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  103166:	74 0e                	je     103176 <get_pte+0x3f>
  103168:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10316f:	e8 19 f9 ff ff       	call   102a8d <alloc_pages>
  103174:	eb 05                	jmp    10317b <get_pte+0x44>
  103176:	b8 00 00 00 00       	mov    $0x0,%eax
  10317b:	89 45 f0             	mov    %eax,-0x10(%ebp)

	if (!page) {
  10317e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  103182:	75 0a                	jne    10318e <get_pte+0x57>
	    return NULL;
  103184:	b8 00 00 00 00       	mov    $0x0,%eax
  103189:	e9 fb 00 00 00       	jmp    103289 <get_pte+0x152>
        }

        // Initialize the page.
        set_page_ref(page, 1);
  10318e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103195:	00 
  103196:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103199:	89 04 24             	mov    %eax,(%esp)
  10319c:	e8 f1 f6 ff ff       	call   102892 <set_page_ref>
        // Get the physical address for next step.
        // ? uintptr_t seems to be unsigned int...
        uintptr_t page_addr = page2pa(page);
  1031a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1031a4:	89 04 24             	mov    %eax,(%esp)
  1031a7:	e8 cd f5 ff ff       	call   102779 <page2pa>
  1031ac:	89 45 ec             	mov    %eax,-0x14(%ebp)
        // Set the page to be empty in the kernel.
        memset(KADDR(page_addr), 0, (PGSIZE));
  1031af:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1031b2:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1031b5:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1031b8:	c1 e8 0c             	shr    $0xc,%eax
  1031bb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1031be:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  1031c3:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
  1031c6:	72 23                	jb     1031eb <get_pte+0xb4>
  1031c8:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1031cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1031cf:	c7 44 24 08 a0 65 10 	movl   $0x1065a0,0x8(%esp)
  1031d6:	00 
  1031d7:	c7 44 24 04 88 01 00 	movl   $0x188,0x4(%esp)
  1031de:	00 
  1031df:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  1031e6:	e8 fe d1 ff ff       	call   1003e9 <__panic>
  1031eb:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1031ee:	2d 00 00 00 40       	sub    $0x40000000,%eax
  1031f3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1031fa:	00 
  1031fb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103202:	00 
  103203:	89 04 24             	mov    %eax,(%esp)
  103206:	e8 76 24 00 00       	call   105681 <memset>
        *entry = page_addr |
                 PTE_P     |
                 PTE_W     |
  10320b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10320e:	83 c8 07             	or     $0x7,%eax
  103211:	89 c2                	mov    %eax,%edx
        // Get the physical address for next step.
        // ? uintptr_t seems to be unsigned int...
        uintptr_t page_addr = page2pa(page);
        // Set the page to be empty in the kernel.
        memset(KADDR(page_addr), 0, (PGSIZE));
        *entry = page_addr |
  103213:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103216:	89 10                	mov    %edx,(%eax)
                 PTE_P     |
                 PTE_W     |
                 PTE_U     ;
    }

    uintptr_t page_table_index = PTX(la);
  103218:	8b 45 0c             	mov    0xc(%ebp),%eax
  10321b:	c1 e8 0c             	shr    $0xc,%eax
  10321e:	25 ff 03 00 00       	and    $0x3ff,%eax
  103223:	89 45 e0             	mov    %eax,-0x20(%ebp)
    // Page directory table's entry is just a pointer to the page table itself.
    pte_t *page_table_addr = (pte_t *)KADDR(PDE_ADDR(*entry)); // Provided by the kernel.
  103226:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103229:	8b 00                	mov    (%eax),%eax
  10322b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103230:	89 45 dc             	mov    %eax,-0x24(%ebp)
  103233:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103236:	c1 e8 0c             	shr    $0xc,%eax
  103239:	89 45 d8             	mov    %eax,-0x28(%ebp)
  10323c:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  103241:	39 45 d8             	cmp    %eax,-0x28(%ebp)
  103244:	72 23                	jb     103269 <get_pte+0x132>
  103246:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103249:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10324d:	c7 44 24 08 a0 65 10 	movl   $0x1065a0,0x8(%esp)
  103254:	00 
  103255:	c7 44 24 04 91 01 00 	movl   $0x191,0x4(%esp)
  10325c:	00 
  10325d:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103264:	e8 80 d1 ff ff       	call   1003e9 <__panic>
  103269:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10326c:	2d 00 00 00 40       	sub    $0x40000000,%eax
  103271:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    pte_t *pte = &(*(page_table_addr + page_table_index));
  103274:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103277:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  10327e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  103281:	01 d0                	add    %edx,%eax
  103283:	89 45 d0             	mov    %eax,-0x30(%ebp)

    return pte;
  103286:	8b 45 d0             	mov    -0x30(%ebp),%eax
}
  103289:	c9                   	leave  
  10328a:	c3                   	ret    

0010328b <get_page>:

//get_page - get related Page struct for linear address la using PDT pgdir
struct Page *
get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
  10328b:	55                   	push   %ebp
  10328c:	89 e5                	mov    %esp,%ebp
  10328e:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
  103291:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103298:	00 
  103299:	8b 45 0c             	mov    0xc(%ebp),%eax
  10329c:	89 44 24 04          	mov    %eax,0x4(%esp)
  1032a0:	8b 45 08             	mov    0x8(%ebp),%eax
  1032a3:	89 04 24             	mov    %eax,(%esp)
  1032a6:	e8 8c fe ff ff       	call   103137 <get_pte>
  1032ab:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep_store != NULL) {
  1032ae:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1032b2:	74 08                	je     1032bc <get_page+0x31>
        *ptep_store = ptep;
  1032b4:	8b 45 10             	mov    0x10(%ebp),%eax
  1032b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1032ba:	89 10                	mov    %edx,(%eax)
    }
    if (ptep != NULL && *ptep & PTE_P) {
  1032bc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1032c0:	74 1b                	je     1032dd <get_page+0x52>
  1032c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1032c5:	8b 00                	mov    (%eax),%eax
  1032c7:	83 e0 01             	and    $0x1,%eax
  1032ca:	85 c0                	test   %eax,%eax
  1032cc:	74 0f                	je     1032dd <get_page+0x52>
        return pte2page(*ptep);
  1032ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1032d1:	8b 00                	mov    (%eax),%eax
  1032d3:	89 04 24             	mov    %eax,(%esp)
  1032d6:	e8 57 f5 ff ff       	call   102832 <pte2page>
  1032db:	eb 05                	jmp    1032e2 <get_page+0x57>
    }
    return NULL;
  1032dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1032e2:	c9                   	leave  
  1032e3:	c3                   	ret    

001032e4 <page_remove_pte>:

//page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
//note: PT is changed, so the TLB need to be invalidate 
static inline void
page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
  1032e4:	55                   	push   %ebp
  1032e5:	89 e5                	mov    %esp,%ebp
  1032e7:	83 ec 28             	sub    $0x28,%esp
                                  //(4) and free this page when page reference reachs 0
                                  //(5) clear second page table entry
                                  //(6) flush tlb
    }
#endif
    if (*ptep & PTE_P) {
  1032ea:	8b 45 10             	mov    0x10(%ebp),%eax
  1032ed:	8b 00                	mov    (%eax),%eax
  1032ef:	83 e0 01             	and    $0x1,%eax
  1032f2:	85 c0                	test   %eax,%eax
  1032f4:	74 4d                	je     103343 <page_remove_pte+0x5f>
        struct Page *page = pte2page(*ptep);
  1032f6:	8b 45 10             	mov    0x10(%ebp),%eax
  1032f9:	8b 00                	mov    (%eax),%eax
  1032fb:	89 04 24             	mov    %eax,(%esp)
  1032fe:	e8 2f f5 ff ff       	call   102832 <pte2page>
  103303:	89 45 f4             	mov    %eax,-0xc(%ebp)
        if (page_ref_dec(page) == 0) {
  103306:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103309:	89 04 24             	mov    %eax,(%esp)
  10330c:	e8 a6 f5 ff ff       	call   1028b7 <page_ref_dec>
  103311:	85 c0                	test   %eax,%eax
  103313:	75 13                	jne    103328 <page_remove_pte+0x44>
            free_page(page);
  103315:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10331c:	00 
  10331d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103320:	89 04 24             	mov    %eax,(%esp)
  103323:	e8 9d f7 ff ff       	call   102ac5 <free_pages>
        }
        *ptep = 0;
  103328:	8b 45 10             	mov    0x10(%ebp),%eax
  10332b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        tlb_invalidate(pgdir, la);
  103331:	8b 45 0c             	mov    0xc(%ebp),%eax
  103334:	89 44 24 04          	mov    %eax,0x4(%esp)
  103338:	8b 45 08             	mov    0x8(%ebp),%eax
  10333b:	89 04 24             	mov    %eax,(%esp)
  10333e:	e8 01 01 00 00       	call   103444 <tlb_invalidate>
    }
}
  103343:	90                   	nop
  103344:	c9                   	leave  
  103345:	c3                   	ret    

00103346 <page_remove>:

//page_remove - free an Page which is related linear address la and has an validated pte
void
page_remove(pde_t *pgdir, uintptr_t la) {
  103346:	55                   	push   %ebp
  103347:	89 e5                	mov    %esp,%ebp
  103349:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
  10334c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103353:	00 
  103354:	8b 45 0c             	mov    0xc(%ebp),%eax
  103357:	89 44 24 04          	mov    %eax,0x4(%esp)
  10335b:	8b 45 08             	mov    0x8(%ebp),%eax
  10335e:	89 04 24             	mov    %eax,(%esp)
  103361:	e8 d1 fd ff ff       	call   103137 <get_pte>
  103366:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep != NULL) {
  103369:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10336d:	74 19                	je     103388 <page_remove+0x42>
        page_remove_pte(pgdir, la, ptep);
  10336f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103372:	89 44 24 08          	mov    %eax,0x8(%esp)
  103376:	8b 45 0c             	mov    0xc(%ebp),%eax
  103379:	89 44 24 04          	mov    %eax,0x4(%esp)
  10337d:	8b 45 08             	mov    0x8(%ebp),%eax
  103380:	89 04 24             	mov    %eax,(%esp)
  103383:	e8 5c ff ff ff       	call   1032e4 <page_remove_pte>
    }
}
  103388:	90                   	nop
  103389:	c9                   	leave  
  10338a:	c3                   	ret    

0010338b <page_insert>:
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
//note: PT is changed, so the TLB need to be invalidate 
int
page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
  10338b:	55                   	push   %ebp
  10338c:	89 e5                	mov    %esp,%ebp
  10338e:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 1);
  103391:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  103398:	00 
  103399:	8b 45 10             	mov    0x10(%ebp),%eax
  10339c:	89 44 24 04          	mov    %eax,0x4(%esp)
  1033a0:	8b 45 08             	mov    0x8(%ebp),%eax
  1033a3:	89 04 24             	mov    %eax,(%esp)
  1033a6:	e8 8c fd ff ff       	call   103137 <get_pte>
  1033ab:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep == NULL) {
  1033ae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1033b2:	75 0a                	jne    1033be <page_insert+0x33>
        return -E_NO_MEM;
  1033b4:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
  1033b9:	e9 84 00 00 00       	jmp    103442 <page_insert+0xb7>
    }
    page_ref_inc(page);
  1033be:	8b 45 0c             	mov    0xc(%ebp),%eax
  1033c1:	89 04 24             	mov    %eax,(%esp)
  1033c4:	e8 d7 f4 ff ff       	call   1028a0 <page_ref_inc>
    if (*ptep & PTE_P) {
  1033c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1033cc:	8b 00                	mov    (%eax),%eax
  1033ce:	83 e0 01             	and    $0x1,%eax
  1033d1:	85 c0                	test   %eax,%eax
  1033d3:	74 3e                	je     103413 <page_insert+0x88>
        struct Page *p = pte2page(*ptep);
  1033d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1033d8:	8b 00                	mov    (%eax),%eax
  1033da:	89 04 24             	mov    %eax,(%esp)
  1033dd:	e8 50 f4 ff ff       	call   102832 <pte2page>
  1033e2:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (p == page) {
  1033e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1033e8:	3b 45 0c             	cmp    0xc(%ebp),%eax
  1033eb:	75 0d                	jne    1033fa <page_insert+0x6f>
            page_ref_dec(page);
  1033ed:	8b 45 0c             	mov    0xc(%ebp),%eax
  1033f0:	89 04 24             	mov    %eax,(%esp)
  1033f3:	e8 bf f4 ff ff       	call   1028b7 <page_ref_dec>
  1033f8:	eb 19                	jmp    103413 <page_insert+0x88>
        }
        else {
            page_remove_pte(pgdir, la, ptep);
  1033fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1033fd:	89 44 24 08          	mov    %eax,0x8(%esp)
  103401:	8b 45 10             	mov    0x10(%ebp),%eax
  103404:	89 44 24 04          	mov    %eax,0x4(%esp)
  103408:	8b 45 08             	mov    0x8(%ebp),%eax
  10340b:	89 04 24             	mov    %eax,(%esp)
  10340e:	e8 d1 fe ff ff       	call   1032e4 <page_remove_pte>
        }
    }
    *ptep = page2pa(page) | PTE_P | perm;
  103413:	8b 45 0c             	mov    0xc(%ebp),%eax
  103416:	89 04 24             	mov    %eax,(%esp)
  103419:	e8 5b f3 ff ff       	call   102779 <page2pa>
  10341e:	0b 45 14             	or     0x14(%ebp),%eax
  103421:	83 c8 01             	or     $0x1,%eax
  103424:	89 c2                	mov    %eax,%edx
  103426:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103429:	89 10                	mov    %edx,(%eax)
    tlb_invalidate(pgdir, la);
  10342b:	8b 45 10             	mov    0x10(%ebp),%eax
  10342e:	89 44 24 04          	mov    %eax,0x4(%esp)
  103432:	8b 45 08             	mov    0x8(%ebp),%eax
  103435:	89 04 24             	mov    %eax,(%esp)
  103438:	e8 07 00 00 00       	call   103444 <tlb_invalidate>
    return 0;
  10343d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  103442:	c9                   	leave  
  103443:	c3                   	ret    

00103444 <tlb_invalidate>:

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void
tlb_invalidate(pde_t *pgdir, uintptr_t la) {
  103444:	55                   	push   %ebp
  103445:	89 e5                	mov    %esp,%ebp
  103447:	83 ec 28             	sub    $0x28,%esp
}

static inline uintptr_t
rcr3(void) {
    uintptr_t cr3;
    asm volatile ("mov %%cr3, %0" : "=r" (cr3) :: "memory");
  10344a:	0f 20 d8             	mov    %cr3,%eax
  10344d:	89 45 ec             	mov    %eax,-0x14(%ebp)
    return cr3;
  103450:	8b 55 ec             	mov    -0x14(%ebp),%edx
    if (rcr3() == PADDR(pgdir)) {
  103453:	8b 45 08             	mov    0x8(%ebp),%eax
  103456:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103459:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
  103460:	77 23                	ja     103485 <tlb_invalidate+0x41>
  103462:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103465:	89 44 24 0c          	mov    %eax,0xc(%esp)
  103469:	c7 44 24 08 44 66 10 	movl   $0x106644,0x8(%esp)
  103470:	00 
  103471:	c7 44 24 04 f6 01 00 	movl   $0x1f6,0x4(%esp)
  103478:	00 
  103479:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103480:	e8 64 cf ff ff       	call   1003e9 <__panic>
  103485:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103488:	05 00 00 00 40       	add    $0x40000000,%eax
  10348d:	39 c2                	cmp    %eax,%edx
  10348f:	75 0c                	jne    10349d <tlb_invalidate+0x59>
        invlpg((void *)la);
  103491:	8b 45 0c             	mov    0xc(%ebp),%eax
  103494:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static inline void
invlpg(void *addr) {
    asm volatile ("invlpg (%0)" :: "r" (addr) : "memory");
  103497:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10349a:	0f 01 38             	invlpg (%eax)
    }
}
  10349d:	90                   	nop
  10349e:	c9                   	leave  
  10349f:	c3                   	ret    

001034a0 <check_alloc_page>:

static void
check_alloc_page(void) {
  1034a0:	55                   	push   %ebp
  1034a1:	89 e5                	mov    %esp,%ebp
  1034a3:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->check();
  1034a6:	a1 10 af 11 00       	mov    0x11af10,%eax
  1034ab:	8b 40 18             	mov    0x18(%eax),%eax
  1034ae:	ff d0                	call   *%eax
    cprintf("check_alloc_page() succeeded!\n");
  1034b0:	c7 04 24 c8 66 10 00 	movl   $0x1066c8,(%esp)
  1034b7:	e8 d6 cd ff ff       	call   100292 <cprintf>
}
  1034bc:	90                   	nop
  1034bd:	c9                   	leave  
  1034be:	c3                   	ret    

001034bf <check_pgdir>:

static void
check_pgdir(void) {
  1034bf:	55                   	push   %ebp
  1034c0:	89 e5                	mov    %esp,%ebp
  1034c2:	83 ec 38             	sub    $0x38,%esp
    assert(npage <= KMEMSIZE / PGSIZE);
  1034c5:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  1034ca:	3d 00 80 03 00       	cmp    $0x38000,%eax
  1034cf:	76 24                	jbe    1034f5 <check_pgdir+0x36>
  1034d1:	c7 44 24 0c e7 66 10 	movl   $0x1066e7,0xc(%esp)
  1034d8:	00 
  1034d9:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  1034e0:	00 
  1034e1:	c7 44 24 04 03 02 00 	movl   $0x203,0x4(%esp)
  1034e8:	00 
  1034e9:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  1034f0:	e8 f4 ce ff ff       	call   1003e9 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
  1034f5:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1034fa:	85 c0                	test   %eax,%eax
  1034fc:	74 0e                	je     10350c <check_pgdir+0x4d>
  1034fe:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103503:	25 ff 0f 00 00       	and    $0xfff,%eax
  103508:	85 c0                	test   %eax,%eax
  10350a:	74 24                	je     103530 <check_pgdir+0x71>
  10350c:	c7 44 24 0c 04 67 10 	movl   $0x106704,0xc(%esp)
  103513:	00 
  103514:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  10351b:	00 
  10351c:	c7 44 24 04 04 02 00 	movl   $0x204,0x4(%esp)
  103523:	00 
  103524:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  10352b:	e8 b9 ce ff ff       	call   1003e9 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
  103530:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103535:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  10353c:	00 
  10353d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103544:	00 
  103545:	89 04 24             	mov    %eax,(%esp)
  103548:	e8 3e fd ff ff       	call   10328b <get_page>
  10354d:	85 c0                	test   %eax,%eax
  10354f:	74 24                	je     103575 <check_pgdir+0xb6>
  103551:	c7 44 24 0c 3c 67 10 	movl   $0x10673c,0xc(%esp)
  103558:	00 
  103559:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103560:	00 
  103561:	c7 44 24 04 05 02 00 	movl   $0x205,0x4(%esp)
  103568:	00 
  103569:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103570:	e8 74 ce ff ff       	call   1003e9 <__panic>

    struct Page *p1, *p2;
    p1 = alloc_page();
  103575:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10357c:	e8 0c f5 ff ff       	call   102a8d <alloc_pages>
  103581:	89 45 f4             	mov    %eax,-0xc(%ebp)
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
  103584:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103589:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  103590:	00 
  103591:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103598:	00 
  103599:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10359c:	89 54 24 04          	mov    %edx,0x4(%esp)
  1035a0:	89 04 24             	mov    %eax,(%esp)
  1035a3:	e8 e3 fd ff ff       	call   10338b <page_insert>
  1035a8:	85 c0                	test   %eax,%eax
  1035aa:	74 24                	je     1035d0 <check_pgdir+0x111>
  1035ac:	c7 44 24 0c 64 67 10 	movl   $0x106764,0xc(%esp)
  1035b3:	00 
  1035b4:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  1035bb:	00 
  1035bc:	c7 44 24 04 09 02 00 	movl   $0x209,0x4(%esp)
  1035c3:	00 
  1035c4:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  1035cb:	e8 19 ce ff ff       	call   1003e9 <__panic>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
  1035d0:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1035d5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1035dc:	00 
  1035dd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1035e4:	00 
  1035e5:	89 04 24             	mov    %eax,(%esp)
  1035e8:	e8 4a fb ff ff       	call   103137 <get_pte>
  1035ed:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1035f0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1035f4:	75 24                	jne    10361a <check_pgdir+0x15b>
  1035f6:	c7 44 24 0c 90 67 10 	movl   $0x106790,0xc(%esp)
  1035fd:	00 
  1035fe:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103605:	00 
  103606:	c7 44 24 04 0c 02 00 	movl   $0x20c,0x4(%esp)
  10360d:	00 
  10360e:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103615:	e8 cf cd ff ff       	call   1003e9 <__panic>
    assert(pte2page(*ptep) == p1);
  10361a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10361d:	8b 00                	mov    (%eax),%eax
  10361f:	89 04 24             	mov    %eax,(%esp)
  103622:	e8 0b f2 ff ff       	call   102832 <pte2page>
  103627:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  10362a:	74 24                	je     103650 <check_pgdir+0x191>
  10362c:	c7 44 24 0c bd 67 10 	movl   $0x1067bd,0xc(%esp)
  103633:	00 
  103634:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  10363b:	00 
  10363c:	c7 44 24 04 0d 02 00 	movl   $0x20d,0x4(%esp)
  103643:	00 
  103644:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  10364b:	e8 99 cd ff ff       	call   1003e9 <__panic>
    assert(page_ref(p1) == 1);
  103650:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103653:	89 04 24             	mov    %eax,(%esp)
  103656:	e8 2d f2 ff ff       	call   102888 <page_ref>
  10365b:	83 f8 01             	cmp    $0x1,%eax
  10365e:	74 24                	je     103684 <check_pgdir+0x1c5>
  103660:	c7 44 24 0c d3 67 10 	movl   $0x1067d3,0xc(%esp)
  103667:	00 
  103668:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  10366f:	00 
  103670:	c7 44 24 04 0e 02 00 	movl   $0x20e,0x4(%esp)
  103677:	00 
  103678:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  10367f:	e8 65 cd ff ff       	call   1003e9 <__panic>

    ptep = &((pte_t *)KADDR(PDE_ADDR(boot_pgdir[0])))[1];
  103684:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103689:	8b 00                	mov    (%eax),%eax
  10368b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103690:	89 45 ec             	mov    %eax,-0x14(%ebp)
  103693:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103696:	c1 e8 0c             	shr    $0xc,%eax
  103699:	89 45 e8             	mov    %eax,-0x18(%ebp)
  10369c:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  1036a1:	39 45 e8             	cmp    %eax,-0x18(%ebp)
  1036a4:	72 23                	jb     1036c9 <check_pgdir+0x20a>
  1036a6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1036a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1036ad:	c7 44 24 08 a0 65 10 	movl   $0x1065a0,0x8(%esp)
  1036b4:	00 
  1036b5:	c7 44 24 04 10 02 00 	movl   $0x210,0x4(%esp)
  1036bc:	00 
  1036bd:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  1036c4:	e8 20 cd ff ff       	call   1003e9 <__panic>
  1036c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1036cc:	2d 00 00 00 40       	sub    $0x40000000,%eax
  1036d1:	83 c0 04             	add    $0x4,%eax
  1036d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
  1036d7:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1036dc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1036e3:	00 
  1036e4:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  1036eb:	00 
  1036ec:	89 04 24             	mov    %eax,(%esp)
  1036ef:	e8 43 fa ff ff       	call   103137 <get_pte>
  1036f4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1036f7:	74 24                	je     10371d <check_pgdir+0x25e>
  1036f9:	c7 44 24 0c e8 67 10 	movl   $0x1067e8,0xc(%esp)
  103700:	00 
  103701:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103708:	00 
  103709:	c7 44 24 04 11 02 00 	movl   $0x211,0x4(%esp)
  103710:	00 
  103711:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103718:	e8 cc cc ff ff       	call   1003e9 <__panic>

    p2 = alloc_page();
  10371d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  103724:	e8 64 f3 ff ff       	call   102a8d <alloc_pages>
  103729:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
  10372c:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103731:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  103738:	00 
  103739:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  103740:	00 
  103741:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103744:	89 54 24 04          	mov    %edx,0x4(%esp)
  103748:	89 04 24             	mov    %eax,(%esp)
  10374b:	e8 3b fc ff ff       	call   10338b <page_insert>
  103750:	85 c0                	test   %eax,%eax
  103752:	74 24                	je     103778 <check_pgdir+0x2b9>
  103754:	c7 44 24 0c 10 68 10 	movl   $0x106810,0xc(%esp)
  10375b:	00 
  10375c:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103763:	00 
  103764:	c7 44 24 04 14 02 00 	movl   $0x214,0x4(%esp)
  10376b:	00 
  10376c:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103773:	e8 71 cc ff ff       	call   1003e9 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
  103778:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  10377d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103784:	00 
  103785:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  10378c:	00 
  10378d:	89 04 24             	mov    %eax,(%esp)
  103790:	e8 a2 f9 ff ff       	call   103137 <get_pte>
  103795:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103798:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  10379c:	75 24                	jne    1037c2 <check_pgdir+0x303>
  10379e:	c7 44 24 0c 48 68 10 	movl   $0x106848,0xc(%esp)
  1037a5:	00 
  1037a6:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  1037ad:	00 
  1037ae:	c7 44 24 04 15 02 00 	movl   $0x215,0x4(%esp)
  1037b5:	00 
  1037b6:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  1037bd:	e8 27 cc ff ff       	call   1003e9 <__panic>
    assert(*ptep & PTE_U);
  1037c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1037c5:	8b 00                	mov    (%eax),%eax
  1037c7:	83 e0 04             	and    $0x4,%eax
  1037ca:	85 c0                	test   %eax,%eax
  1037cc:	75 24                	jne    1037f2 <check_pgdir+0x333>
  1037ce:	c7 44 24 0c 78 68 10 	movl   $0x106878,0xc(%esp)
  1037d5:	00 
  1037d6:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  1037dd:	00 
  1037de:	c7 44 24 04 16 02 00 	movl   $0x216,0x4(%esp)
  1037e5:	00 
  1037e6:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  1037ed:	e8 f7 cb ff ff       	call   1003e9 <__panic>
    assert(*ptep & PTE_W);
  1037f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1037f5:	8b 00                	mov    (%eax),%eax
  1037f7:	83 e0 02             	and    $0x2,%eax
  1037fa:	85 c0                	test   %eax,%eax
  1037fc:	75 24                	jne    103822 <check_pgdir+0x363>
  1037fe:	c7 44 24 0c 86 68 10 	movl   $0x106886,0xc(%esp)
  103805:	00 
  103806:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  10380d:	00 
  10380e:	c7 44 24 04 17 02 00 	movl   $0x217,0x4(%esp)
  103815:	00 
  103816:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  10381d:	e8 c7 cb ff ff       	call   1003e9 <__panic>
    assert(boot_pgdir[0] & PTE_U);
  103822:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103827:	8b 00                	mov    (%eax),%eax
  103829:	83 e0 04             	and    $0x4,%eax
  10382c:	85 c0                	test   %eax,%eax
  10382e:	75 24                	jne    103854 <check_pgdir+0x395>
  103830:	c7 44 24 0c 94 68 10 	movl   $0x106894,0xc(%esp)
  103837:	00 
  103838:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  10383f:	00 
  103840:	c7 44 24 04 18 02 00 	movl   $0x218,0x4(%esp)
  103847:	00 
  103848:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  10384f:	e8 95 cb ff ff       	call   1003e9 <__panic>
    assert(page_ref(p2) == 1);
  103854:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103857:	89 04 24             	mov    %eax,(%esp)
  10385a:	e8 29 f0 ff ff       	call   102888 <page_ref>
  10385f:	83 f8 01             	cmp    $0x1,%eax
  103862:	74 24                	je     103888 <check_pgdir+0x3c9>
  103864:	c7 44 24 0c aa 68 10 	movl   $0x1068aa,0xc(%esp)
  10386b:	00 
  10386c:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103873:	00 
  103874:	c7 44 24 04 19 02 00 	movl   $0x219,0x4(%esp)
  10387b:	00 
  10387c:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103883:	e8 61 cb ff ff       	call   1003e9 <__panic>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
  103888:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  10388d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  103894:	00 
  103895:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10389c:	00 
  10389d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1038a0:	89 54 24 04          	mov    %edx,0x4(%esp)
  1038a4:	89 04 24             	mov    %eax,(%esp)
  1038a7:	e8 df fa ff ff       	call   10338b <page_insert>
  1038ac:	85 c0                	test   %eax,%eax
  1038ae:	74 24                	je     1038d4 <check_pgdir+0x415>
  1038b0:	c7 44 24 0c bc 68 10 	movl   $0x1068bc,0xc(%esp)
  1038b7:	00 
  1038b8:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  1038bf:	00 
  1038c0:	c7 44 24 04 1b 02 00 	movl   $0x21b,0x4(%esp)
  1038c7:	00 
  1038c8:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  1038cf:	e8 15 cb ff ff       	call   1003e9 <__panic>
    assert(page_ref(p1) == 2);
  1038d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1038d7:	89 04 24             	mov    %eax,(%esp)
  1038da:	e8 a9 ef ff ff       	call   102888 <page_ref>
  1038df:	83 f8 02             	cmp    $0x2,%eax
  1038e2:	74 24                	je     103908 <check_pgdir+0x449>
  1038e4:	c7 44 24 0c e8 68 10 	movl   $0x1068e8,0xc(%esp)
  1038eb:	00 
  1038ec:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  1038f3:	00 
  1038f4:	c7 44 24 04 1c 02 00 	movl   $0x21c,0x4(%esp)
  1038fb:	00 
  1038fc:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103903:	e8 e1 ca ff ff       	call   1003e9 <__panic>
    assert(page_ref(p2) == 0);
  103908:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10390b:	89 04 24             	mov    %eax,(%esp)
  10390e:	e8 75 ef ff ff       	call   102888 <page_ref>
  103913:	85 c0                	test   %eax,%eax
  103915:	74 24                	je     10393b <check_pgdir+0x47c>
  103917:	c7 44 24 0c fa 68 10 	movl   $0x1068fa,0xc(%esp)
  10391e:	00 
  10391f:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103926:	00 
  103927:	c7 44 24 04 1d 02 00 	movl   $0x21d,0x4(%esp)
  10392e:	00 
  10392f:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103936:	e8 ae ca ff ff       	call   1003e9 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
  10393b:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103940:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103947:	00 
  103948:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  10394f:	00 
  103950:	89 04 24             	mov    %eax,(%esp)
  103953:	e8 df f7 ff ff       	call   103137 <get_pte>
  103958:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10395b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  10395f:	75 24                	jne    103985 <check_pgdir+0x4c6>
  103961:	c7 44 24 0c 48 68 10 	movl   $0x106848,0xc(%esp)
  103968:	00 
  103969:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103970:	00 
  103971:	c7 44 24 04 1e 02 00 	movl   $0x21e,0x4(%esp)
  103978:	00 
  103979:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103980:	e8 64 ca ff ff       	call   1003e9 <__panic>
    assert(pte2page(*ptep) == p1);
  103985:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103988:	8b 00                	mov    (%eax),%eax
  10398a:	89 04 24             	mov    %eax,(%esp)
  10398d:	e8 a0 ee ff ff       	call   102832 <pte2page>
  103992:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  103995:	74 24                	je     1039bb <check_pgdir+0x4fc>
  103997:	c7 44 24 0c bd 67 10 	movl   $0x1067bd,0xc(%esp)
  10399e:	00 
  10399f:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  1039a6:	00 
  1039a7:	c7 44 24 04 1f 02 00 	movl   $0x21f,0x4(%esp)
  1039ae:	00 
  1039af:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  1039b6:	e8 2e ca ff ff       	call   1003e9 <__panic>
    assert((*ptep & PTE_U) == 0);
  1039bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1039be:	8b 00                	mov    (%eax),%eax
  1039c0:	83 e0 04             	and    $0x4,%eax
  1039c3:	85 c0                	test   %eax,%eax
  1039c5:	74 24                	je     1039eb <check_pgdir+0x52c>
  1039c7:	c7 44 24 0c 0c 69 10 	movl   $0x10690c,0xc(%esp)
  1039ce:	00 
  1039cf:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  1039d6:	00 
  1039d7:	c7 44 24 04 20 02 00 	movl   $0x220,0x4(%esp)
  1039de:	00 
  1039df:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  1039e6:	e8 fe c9 ff ff       	call   1003e9 <__panic>

    page_remove(boot_pgdir, 0x0);
  1039eb:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  1039f0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1039f7:	00 
  1039f8:	89 04 24             	mov    %eax,(%esp)
  1039fb:	e8 46 f9 ff ff       	call   103346 <page_remove>
    assert(page_ref(p1) == 1);
  103a00:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a03:	89 04 24             	mov    %eax,(%esp)
  103a06:	e8 7d ee ff ff       	call   102888 <page_ref>
  103a0b:	83 f8 01             	cmp    $0x1,%eax
  103a0e:	74 24                	je     103a34 <check_pgdir+0x575>
  103a10:	c7 44 24 0c d3 67 10 	movl   $0x1067d3,0xc(%esp)
  103a17:	00 
  103a18:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103a1f:	00 
  103a20:	c7 44 24 04 23 02 00 	movl   $0x223,0x4(%esp)
  103a27:	00 
  103a28:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103a2f:	e8 b5 c9 ff ff       	call   1003e9 <__panic>
    assert(page_ref(p2) == 0);
  103a34:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103a37:	89 04 24             	mov    %eax,(%esp)
  103a3a:	e8 49 ee ff ff       	call   102888 <page_ref>
  103a3f:	85 c0                	test   %eax,%eax
  103a41:	74 24                	je     103a67 <check_pgdir+0x5a8>
  103a43:	c7 44 24 0c fa 68 10 	movl   $0x1068fa,0xc(%esp)
  103a4a:	00 
  103a4b:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103a52:	00 
  103a53:	c7 44 24 04 24 02 00 	movl   $0x224,0x4(%esp)
  103a5a:	00 
  103a5b:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103a62:	e8 82 c9 ff ff       	call   1003e9 <__panic>

    page_remove(boot_pgdir, PGSIZE);
  103a67:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103a6c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
  103a73:	00 
  103a74:	89 04 24             	mov    %eax,(%esp)
  103a77:	e8 ca f8 ff ff       	call   103346 <page_remove>
    assert(page_ref(p1) == 0);
  103a7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a7f:	89 04 24             	mov    %eax,(%esp)
  103a82:	e8 01 ee ff ff       	call   102888 <page_ref>
  103a87:	85 c0                	test   %eax,%eax
  103a89:	74 24                	je     103aaf <check_pgdir+0x5f0>
  103a8b:	c7 44 24 0c 21 69 10 	movl   $0x106921,0xc(%esp)
  103a92:	00 
  103a93:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103a9a:	00 
  103a9b:	c7 44 24 04 27 02 00 	movl   $0x227,0x4(%esp)
  103aa2:	00 
  103aa3:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103aaa:	e8 3a c9 ff ff       	call   1003e9 <__panic>
    assert(page_ref(p2) == 0);
  103aaf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103ab2:	89 04 24             	mov    %eax,(%esp)
  103ab5:	e8 ce ed ff ff       	call   102888 <page_ref>
  103aba:	85 c0                	test   %eax,%eax
  103abc:	74 24                	je     103ae2 <check_pgdir+0x623>
  103abe:	c7 44 24 0c fa 68 10 	movl   $0x1068fa,0xc(%esp)
  103ac5:	00 
  103ac6:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103acd:	00 
  103ace:	c7 44 24 04 28 02 00 	movl   $0x228,0x4(%esp)
  103ad5:	00 
  103ad6:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103add:	e8 07 c9 ff ff       	call   1003e9 <__panic>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
  103ae2:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103ae7:	8b 00                	mov    (%eax),%eax
  103ae9:	89 04 24             	mov    %eax,(%esp)
  103aec:	e8 7f ed ff ff       	call   102870 <pde2page>
  103af1:	89 04 24             	mov    %eax,(%esp)
  103af4:	e8 8f ed ff ff       	call   102888 <page_ref>
  103af9:	83 f8 01             	cmp    $0x1,%eax
  103afc:	74 24                	je     103b22 <check_pgdir+0x663>
  103afe:	c7 44 24 0c 34 69 10 	movl   $0x106934,0xc(%esp)
  103b05:	00 
  103b06:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103b0d:	00 
  103b0e:	c7 44 24 04 2a 02 00 	movl   $0x22a,0x4(%esp)
  103b15:	00 
  103b16:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103b1d:	e8 c7 c8 ff ff       	call   1003e9 <__panic>
    free_page(pde2page(boot_pgdir[0]));
  103b22:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103b27:	8b 00                	mov    (%eax),%eax
  103b29:	89 04 24             	mov    %eax,(%esp)
  103b2c:	e8 3f ed ff ff       	call   102870 <pde2page>
  103b31:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103b38:	00 
  103b39:	89 04 24             	mov    %eax,(%esp)
  103b3c:	e8 84 ef ff ff       	call   102ac5 <free_pages>
    boot_pgdir[0] = 0;
  103b41:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103b46:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_pgdir() succeeded!\n");
  103b4c:	c7 04 24 5b 69 10 00 	movl   $0x10695b,(%esp)
  103b53:	e8 3a c7 ff ff       	call   100292 <cprintf>
}
  103b58:	90                   	nop
  103b59:	c9                   	leave  
  103b5a:	c3                   	ret    

00103b5b <check_boot_pgdir>:

static void
check_boot_pgdir(void) {
  103b5b:	55                   	push   %ebp
  103b5c:	89 e5                	mov    %esp,%ebp
  103b5e:	83 ec 38             	sub    $0x38,%esp
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
  103b61:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  103b68:	e9 ca 00 00 00       	jmp    103c37 <check_boot_pgdir+0xdc>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
  103b6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b70:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103b73:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103b76:	c1 e8 0c             	shr    $0xc,%eax
  103b79:	89 45 ec             	mov    %eax,-0x14(%ebp)
  103b7c:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  103b81:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  103b84:	72 23                	jb     103ba9 <check_boot_pgdir+0x4e>
  103b86:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103b89:	89 44 24 0c          	mov    %eax,0xc(%esp)
  103b8d:	c7 44 24 08 a0 65 10 	movl   $0x1065a0,0x8(%esp)
  103b94:	00 
  103b95:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
  103b9c:	00 
  103b9d:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103ba4:	e8 40 c8 ff ff       	call   1003e9 <__panic>
  103ba9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103bac:	2d 00 00 00 40       	sub    $0x40000000,%eax
  103bb1:	89 c2                	mov    %eax,%edx
  103bb3:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103bb8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103bbf:	00 
  103bc0:	89 54 24 04          	mov    %edx,0x4(%esp)
  103bc4:	89 04 24             	mov    %eax,(%esp)
  103bc7:	e8 6b f5 ff ff       	call   103137 <get_pte>
  103bcc:	89 45 e8             	mov    %eax,-0x18(%ebp)
  103bcf:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  103bd3:	75 24                	jne    103bf9 <check_boot_pgdir+0x9e>
  103bd5:	c7 44 24 0c 78 69 10 	movl   $0x106978,0xc(%esp)
  103bdc:	00 
  103bdd:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103be4:	00 
  103be5:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
  103bec:	00 
  103bed:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103bf4:	e8 f0 c7 ff ff       	call   1003e9 <__panic>
        assert(PTE_ADDR(*ptep) == i);
  103bf9:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103bfc:	8b 00                	mov    (%eax),%eax
  103bfe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103c03:	89 c2                	mov    %eax,%edx
  103c05:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c08:	39 c2                	cmp    %eax,%edx
  103c0a:	74 24                	je     103c30 <check_boot_pgdir+0xd5>
  103c0c:	c7 44 24 0c b5 69 10 	movl   $0x1069b5,0xc(%esp)
  103c13:	00 
  103c14:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103c1b:	00 
  103c1c:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
  103c23:	00 
  103c24:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103c2b:	e8 b9 c7 ff ff       	call   1003e9 <__panic>

static void
check_boot_pgdir(void) {
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
  103c30:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
  103c37:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103c3a:	a1 80 ae 11 00       	mov    0x11ae80,%eax
  103c3f:	39 c2                	cmp    %eax,%edx
  103c41:	0f 82 26 ff ff ff    	jb     103b6d <check_boot_pgdir+0x12>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }

    assert(PDE_ADDR(boot_pgdir[PDX(VPT)]) == PADDR(boot_pgdir));
  103c47:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103c4c:	05 ac 0f 00 00       	add    $0xfac,%eax
  103c51:	8b 00                	mov    (%eax),%eax
  103c53:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103c58:	89 c2                	mov    %eax,%edx
  103c5a:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103c5f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  103c62:	81 7d e4 ff ff ff bf 	cmpl   $0xbfffffff,-0x1c(%ebp)
  103c69:	77 23                	ja     103c8e <check_boot_pgdir+0x133>
  103c6b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103c6e:	89 44 24 0c          	mov    %eax,0xc(%esp)
  103c72:	c7 44 24 08 44 66 10 	movl   $0x106644,0x8(%esp)
  103c79:	00 
  103c7a:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
  103c81:	00 
  103c82:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103c89:	e8 5b c7 ff ff       	call   1003e9 <__panic>
  103c8e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103c91:	05 00 00 00 40       	add    $0x40000000,%eax
  103c96:	39 c2                	cmp    %eax,%edx
  103c98:	74 24                	je     103cbe <check_boot_pgdir+0x163>
  103c9a:	c7 44 24 0c cc 69 10 	movl   $0x1069cc,0xc(%esp)
  103ca1:	00 
  103ca2:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103ca9:	00 
  103caa:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
  103cb1:	00 
  103cb2:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103cb9:	e8 2b c7 ff ff       	call   1003e9 <__panic>

    assert(boot_pgdir[0] == 0);
  103cbe:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103cc3:	8b 00                	mov    (%eax),%eax
  103cc5:	85 c0                	test   %eax,%eax
  103cc7:	74 24                	je     103ced <check_boot_pgdir+0x192>
  103cc9:	c7 44 24 0c 00 6a 10 	movl   $0x106a00,0xc(%esp)
  103cd0:	00 
  103cd1:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103cd8:	00 
  103cd9:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
  103ce0:	00 
  103ce1:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103ce8:	e8 fc c6 ff ff       	call   1003e9 <__panic>

    struct Page *p;
    p = alloc_page();
  103ced:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  103cf4:	e8 94 ed ff ff       	call   102a8d <alloc_pages>
  103cf9:	89 45 e0             	mov    %eax,-0x20(%ebp)
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W) == 0);
  103cfc:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103d01:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
  103d08:	00 
  103d09:	c7 44 24 08 00 01 00 	movl   $0x100,0x8(%esp)
  103d10:	00 
  103d11:	8b 55 e0             	mov    -0x20(%ebp),%edx
  103d14:	89 54 24 04          	mov    %edx,0x4(%esp)
  103d18:	89 04 24             	mov    %eax,(%esp)
  103d1b:	e8 6b f6 ff ff       	call   10338b <page_insert>
  103d20:	85 c0                	test   %eax,%eax
  103d22:	74 24                	je     103d48 <check_boot_pgdir+0x1ed>
  103d24:	c7 44 24 0c 14 6a 10 	movl   $0x106a14,0xc(%esp)
  103d2b:	00 
  103d2c:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103d33:	00 
  103d34:	c7 44 24 04 40 02 00 	movl   $0x240,0x4(%esp)
  103d3b:	00 
  103d3c:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103d43:	e8 a1 c6 ff ff       	call   1003e9 <__panic>
    assert(page_ref(p) == 1);
  103d48:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103d4b:	89 04 24             	mov    %eax,(%esp)
  103d4e:	e8 35 eb ff ff       	call   102888 <page_ref>
  103d53:	83 f8 01             	cmp    $0x1,%eax
  103d56:	74 24                	je     103d7c <check_boot_pgdir+0x221>
  103d58:	c7 44 24 0c 42 6a 10 	movl   $0x106a42,0xc(%esp)
  103d5f:	00 
  103d60:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103d67:	00 
  103d68:	c7 44 24 04 41 02 00 	movl   $0x241,0x4(%esp)
  103d6f:	00 
  103d70:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103d77:	e8 6d c6 ff ff       	call   1003e9 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W) == 0);
  103d7c:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103d81:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
  103d88:	00 
  103d89:	c7 44 24 08 00 11 00 	movl   $0x1100,0x8(%esp)
  103d90:	00 
  103d91:	8b 55 e0             	mov    -0x20(%ebp),%edx
  103d94:	89 54 24 04          	mov    %edx,0x4(%esp)
  103d98:	89 04 24             	mov    %eax,(%esp)
  103d9b:	e8 eb f5 ff ff       	call   10338b <page_insert>
  103da0:	85 c0                	test   %eax,%eax
  103da2:	74 24                	je     103dc8 <check_boot_pgdir+0x26d>
  103da4:	c7 44 24 0c 54 6a 10 	movl   $0x106a54,0xc(%esp)
  103dab:	00 
  103dac:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103db3:	00 
  103db4:	c7 44 24 04 42 02 00 	movl   $0x242,0x4(%esp)
  103dbb:	00 
  103dbc:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103dc3:	e8 21 c6 ff ff       	call   1003e9 <__panic>
    assert(page_ref(p) == 2);
  103dc8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103dcb:	89 04 24             	mov    %eax,(%esp)
  103dce:	e8 b5 ea ff ff       	call   102888 <page_ref>
  103dd3:	83 f8 02             	cmp    $0x2,%eax
  103dd6:	74 24                	je     103dfc <check_boot_pgdir+0x2a1>
  103dd8:	c7 44 24 0c 8b 6a 10 	movl   $0x106a8b,0xc(%esp)
  103ddf:	00 
  103de0:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103de7:	00 
  103de8:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
  103def:	00 
  103df0:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103df7:	e8 ed c5 ff ff       	call   1003e9 <__panic>

    const char *str = "ucore: Hello world!!";
  103dfc:	c7 45 dc 9c 6a 10 00 	movl   $0x106a9c,-0x24(%ebp)
    strcpy((void *)0x100, str);
  103e03:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103e06:	89 44 24 04          	mov    %eax,0x4(%esp)
  103e0a:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
  103e11:	e8 a1 15 00 00       	call   1053b7 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
  103e16:	c7 44 24 04 00 11 00 	movl   $0x1100,0x4(%esp)
  103e1d:	00 
  103e1e:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
  103e25:	e8 04 16 00 00       	call   10542e <strcmp>
  103e2a:	85 c0                	test   %eax,%eax
  103e2c:	74 24                	je     103e52 <check_boot_pgdir+0x2f7>
  103e2e:	c7 44 24 0c b4 6a 10 	movl   $0x106ab4,0xc(%esp)
  103e35:	00 
  103e36:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103e3d:	00 
  103e3e:	c7 44 24 04 47 02 00 	movl   $0x247,0x4(%esp)
  103e45:	00 
  103e46:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103e4d:	e8 97 c5 ff ff       	call   1003e9 <__panic>

    *(char *)(page2kva(p) + 0x100) = '\0';
  103e52:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103e55:	89 04 24             	mov    %eax,(%esp)
  103e58:	e8 81 e9 ff ff       	call   1027de <page2kva>
  103e5d:	05 00 01 00 00       	add    $0x100,%eax
  103e62:	c6 00 00             	movb   $0x0,(%eax)
    assert(strlen((const char *)0x100) == 0);
  103e65:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
  103e6c:	e8 f0 14 00 00       	call   105361 <strlen>
  103e71:	85 c0                	test   %eax,%eax
  103e73:	74 24                	je     103e99 <check_boot_pgdir+0x33e>
  103e75:	c7 44 24 0c ec 6a 10 	movl   $0x106aec,0xc(%esp)
  103e7c:	00 
  103e7d:	c7 44 24 08 8d 66 10 	movl   $0x10668d,0x8(%esp)
  103e84:	00 
  103e85:	c7 44 24 04 4a 02 00 	movl   $0x24a,0x4(%esp)
  103e8c:	00 
  103e8d:	c7 04 24 68 66 10 00 	movl   $0x106668,(%esp)
  103e94:	e8 50 c5 ff ff       	call   1003e9 <__panic>

    free_page(p);
  103e99:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103ea0:	00 
  103ea1:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103ea4:	89 04 24             	mov    %eax,(%esp)
  103ea7:	e8 19 ec ff ff       	call   102ac5 <free_pages>
    free_page(pde2page(boot_pgdir[0]));
  103eac:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103eb1:	8b 00                	mov    (%eax),%eax
  103eb3:	89 04 24             	mov    %eax,(%esp)
  103eb6:	e8 b5 e9 ff ff       	call   102870 <pde2page>
  103ebb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103ec2:	00 
  103ec3:	89 04 24             	mov    %eax,(%esp)
  103ec6:	e8 fa eb ff ff       	call   102ac5 <free_pages>
    boot_pgdir[0] = 0;
  103ecb:	a1 e0 79 11 00       	mov    0x1179e0,%eax
  103ed0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_boot_pgdir() succeeded!\n");
  103ed6:	c7 04 24 10 6b 10 00 	movl   $0x106b10,(%esp)
  103edd:	e8 b0 c3 ff ff       	call   100292 <cprintf>
}
  103ee2:	90                   	nop
  103ee3:	c9                   	leave  
  103ee4:	c3                   	ret    

00103ee5 <perm2str>:

//perm2str - use string 'u,r,w,-' to present the permission
static const char *
perm2str(int perm) {
  103ee5:	55                   	push   %ebp
  103ee6:	89 e5                	mov    %esp,%ebp
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
  103ee8:	8b 45 08             	mov    0x8(%ebp),%eax
  103eeb:	83 e0 04             	and    $0x4,%eax
  103eee:	85 c0                	test   %eax,%eax
  103ef0:	74 04                	je     103ef6 <perm2str+0x11>
  103ef2:	b0 75                	mov    $0x75,%al
  103ef4:	eb 02                	jmp    103ef8 <perm2str+0x13>
  103ef6:	b0 2d                	mov    $0x2d,%al
  103ef8:	a2 08 af 11 00       	mov    %al,0x11af08
    str[1] = 'r';
  103efd:	c6 05 09 af 11 00 72 	movb   $0x72,0x11af09
    str[2] = (perm & PTE_W) ? 'w' : '-';
  103f04:	8b 45 08             	mov    0x8(%ebp),%eax
  103f07:	83 e0 02             	and    $0x2,%eax
  103f0a:	85 c0                	test   %eax,%eax
  103f0c:	74 04                	je     103f12 <perm2str+0x2d>
  103f0e:	b0 77                	mov    $0x77,%al
  103f10:	eb 02                	jmp    103f14 <perm2str+0x2f>
  103f12:	b0 2d                	mov    $0x2d,%al
  103f14:	a2 0a af 11 00       	mov    %al,0x11af0a
    str[3] = '\0';
  103f19:	c6 05 0b af 11 00 00 	movb   $0x0,0x11af0b
    return str;
  103f20:	b8 08 af 11 00       	mov    $0x11af08,%eax
}
  103f25:	5d                   	pop    %ebp
  103f26:	c3                   	ret    

00103f27 <get_pgtable_items>:
//  table:       the beginning addr of table
//  left_store:  the pointer of the high side of table's next range
//  right_store: the pointer of the low side of table's next range
// return value: 0 - not a invalid item range, perm - a valid item range with perm permission 
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
  103f27:	55                   	push   %ebp
  103f28:	89 e5                	mov    %esp,%ebp
  103f2a:	83 ec 10             	sub    $0x10,%esp
    if (start >= right) {
  103f2d:	8b 45 10             	mov    0x10(%ebp),%eax
  103f30:	3b 45 0c             	cmp    0xc(%ebp),%eax
  103f33:	72 0d                	jb     103f42 <get_pgtable_items+0x1b>
        return 0;
  103f35:	b8 00 00 00 00       	mov    $0x0,%eax
  103f3a:	e9 98 00 00 00       	jmp    103fd7 <get_pgtable_items+0xb0>
    }
    while (start < right && !(table[start] & PTE_P)) {
        start ++;
  103f3f:	ff 45 10             	incl   0x10(%ebp)
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
    if (start >= right) {
        return 0;
    }
    while (start < right && !(table[start] & PTE_P)) {
  103f42:	8b 45 10             	mov    0x10(%ebp),%eax
  103f45:	3b 45 0c             	cmp    0xc(%ebp),%eax
  103f48:	73 18                	jae    103f62 <get_pgtable_items+0x3b>
  103f4a:	8b 45 10             	mov    0x10(%ebp),%eax
  103f4d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  103f54:	8b 45 14             	mov    0x14(%ebp),%eax
  103f57:	01 d0                	add    %edx,%eax
  103f59:	8b 00                	mov    (%eax),%eax
  103f5b:	83 e0 01             	and    $0x1,%eax
  103f5e:	85 c0                	test   %eax,%eax
  103f60:	74 dd                	je     103f3f <get_pgtable_items+0x18>
        start ++;
    }
    if (start < right) {
  103f62:	8b 45 10             	mov    0x10(%ebp),%eax
  103f65:	3b 45 0c             	cmp    0xc(%ebp),%eax
  103f68:	73 68                	jae    103fd2 <get_pgtable_items+0xab>
        if (left_store != NULL) {
  103f6a:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
  103f6e:	74 08                	je     103f78 <get_pgtable_items+0x51>
            *left_store = start;
  103f70:	8b 45 18             	mov    0x18(%ebp),%eax
  103f73:	8b 55 10             	mov    0x10(%ebp),%edx
  103f76:	89 10                	mov    %edx,(%eax)
        }
        int perm = (table[start ++] & PTE_USER);
  103f78:	8b 45 10             	mov    0x10(%ebp),%eax
  103f7b:	8d 50 01             	lea    0x1(%eax),%edx
  103f7e:	89 55 10             	mov    %edx,0x10(%ebp)
  103f81:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  103f88:	8b 45 14             	mov    0x14(%ebp),%eax
  103f8b:	01 d0                	add    %edx,%eax
  103f8d:	8b 00                	mov    (%eax),%eax
  103f8f:	83 e0 07             	and    $0x7,%eax
  103f92:	89 45 fc             	mov    %eax,-0x4(%ebp)
        while (start < right && (table[start] & PTE_USER) == perm) {
  103f95:	eb 03                	jmp    103f9a <get_pgtable_items+0x73>
            start ++;
  103f97:	ff 45 10             	incl   0x10(%ebp)
    if (start < right) {
        if (left_store != NULL) {
            *left_store = start;
        }
        int perm = (table[start ++] & PTE_USER);
        while (start < right && (table[start] & PTE_USER) == perm) {
  103f9a:	8b 45 10             	mov    0x10(%ebp),%eax
  103f9d:	3b 45 0c             	cmp    0xc(%ebp),%eax
  103fa0:	73 1d                	jae    103fbf <get_pgtable_items+0x98>
  103fa2:	8b 45 10             	mov    0x10(%ebp),%eax
  103fa5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  103fac:	8b 45 14             	mov    0x14(%ebp),%eax
  103faf:	01 d0                	add    %edx,%eax
  103fb1:	8b 00                	mov    (%eax),%eax
  103fb3:	83 e0 07             	and    $0x7,%eax
  103fb6:	89 c2                	mov    %eax,%edx
  103fb8:	8b 45 fc             	mov    -0x4(%ebp),%eax
  103fbb:	39 c2                	cmp    %eax,%edx
  103fbd:	74 d8                	je     103f97 <get_pgtable_items+0x70>
            start ++;
        }
        if (right_store != NULL) {
  103fbf:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
  103fc3:	74 08                	je     103fcd <get_pgtable_items+0xa6>
            *right_store = start;
  103fc5:	8b 45 1c             	mov    0x1c(%ebp),%eax
  103fc8:	8b 55 10             	mov    0x10(%ebp),%edx
  103fcb:	89 10                	mov    %edx,(%eax)
        }
        return perm;
  103fcd:	8b 45 fc             	mov    -0x4(%ebp),%eax
  103fd0:	eb 05                	jmp    103fd7 <get_pgtable_items+0xb0>
    }
    return 0;
  103fd2:	b8 00 00 00 00       	mov    $0x0,%eax
}
  103fd7:	c9                   	leave  
  103fd8:	c3                   	ret    

00103fd9 <print_pgdir>:

//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
  103fd9:	55                   	push   %ebp
  103fda:	89 e5                	mov    %esp,%ebp
  103fdc:	57                   	push   %edi
  103fdd:	56                   	push   %esi
  103fde:	53                   	push   %ebx
  103fdf:	83 ec 4c             	sub    $0x4c,%esp
    cprintf("-------------------- BEGIN --------------------\n");
  103fe2:	c7 04 24 30 6b 10 00 	movl   $0x106b30,(%esp)
  103fe9:	e8 a4 c2 ff ff       	call   100292 <cprintf>
    size_t left, right = 0, perm;
  103fee:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
  103ff5:	e9 fa 00 00 00       	jmp    1040f4 <print_pgdir+0x11b>
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
  103ffa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103ffd:	89 04 24             	mov    %eax,(%esp)
  104000:	e8 e0 fe ff ff       	call   103ee5 <perm2str>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
  104005:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  104008:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10400b:	29 d1                	sub    %edx,%ecx
  10400d:	89 ca                	mov    %ecx,%edx
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
  10400f:	89 d6                	mov    %edx,%esi
  104011:	c1 e6 16             	shl    $0x16,%esi
  104014:	8b 55 dc             	mov    -0x24(%ebp),%edx
  104017:	89 d3                	mov    %edx,%ebx
  104019:	c1 e3 16             	shl    $0x16,%ebx
  10401c:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10401f:	89 d1                	mov    %edx,%ecx
  104021:	c1 e1 16             	shl    $0x16,%ecx
  104024:	8b 7d dc             	mov    -0x24(%ebp),%edi
  104027:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10402a:	29 d7                	sub    %edx,%edi
  10402c:	89 fa                	mov    %edi,%edx
  10402e:	89 44 24 14          	mov    %eax,0x14(%esp)
  104032:	89 74 24 10          	mov    %esi,0x10(%esp)
  104036:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  10403a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  10403e:	89 54 24 04          	mov    %edx,0x4(%esp)
  104042:	c7 04 24 61 6b 10 00 	movl   $0x106b61,(%esp)
  104049:	e8 44 c2 ff ff       	call   100292 <cprintf>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
  10404e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104051:	c1 e0 0a             	shl    $0xa,%eax
  104054:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
  104057:	eb 54                	jmp    1040ad <print_pgdir+0xd4>
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
  104059:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10405c:	89 04 24             	mov    %eax,(%esp)
  10405f:	e8 81 fe ff ff       	call   103ee5 <perm2str>
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
  104064:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  104067:	8b 55 d8             	mov    -0x28(%ebp),%edx
  10406a:	29 d1                	sub    %edx,%ecx
  10406c:	89 ca                	mov    %ecx,%edx
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
  10406e:	89 d6                	mov    %edx,%esi
  104070:	c1 e6 0c             	shl    $0xc,%esi
  104073:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  104076:	89 d3                	mov    %edx,%ebx
  104078:	c1 e3 0c             	shl    $0xc,%ebx
  10407b:	8b 55 d8             	mov    -0x28(%ebp),%edx
  10407e:	89 d1                	mov    %edx,%ecx
  104080:	c1 e1 0c             	shl    $0xc,%ecx
  104083:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  104086:	8b 55 d8             	mov    -0x28(%ebp),%edx
  104089:	29 d7                	sub    %edx,%edi
  10408b:	89 fa                	mov    %edi,%edx
  10408d:	89 44 24 14          	mov    %eax,0x14(%esp)
  104091:	89 74 24 10          	mov    %esi,0x10(%esp)
  104095:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  104099:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  10409d:	89 54 24 04          	mov    %edx,0x4(%esp)
  1040a1:	c7 04 24 80 6b 10 00 	movl   $0x106b80,(%esp)
  1040a8:	e8 e5 c1 ff ff       	call   100292 <cprintf>
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
  1040ad:	be 00 00 c0 fa       	mov    $0xfac00000,%esi
  1040b2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1040b5:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1040b8:	89 d3                	mov    %edx,%ebx
  1040ba:	c1 e3 0a             	shl    $0xa,%ebx
  1040bd:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1040c0:	89 d1                	mov    %edx,%ecx
  1040c2:	c1 e1 0a             	shl    $0xa,%ecx
  1040c5:	8d 55 d4             	lea    -0x2c(%ebp),%edx
  1040c8:	89 54 24 14          	mov    %edx,0x14(%esp)
  1040cc:	8d 55 d8             	lea    -0x28(%ebp),%edx
  1040cf:	89 54 24 10          	mov    %edx,0x10(%esp)
  1040d3:	89 74 24 0c          	mov    %esi,0xc(%esp)
  1040d7:	89 44 24 08          	mov    %eax,0x8(%esp)
  1040db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  1040df:	89 0c 24             	mov    %ecx,(%esp)
  1040e2:	e8 40 fe ff ff       	call   103f27 <get_pgtable_items>
  1040e7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1040ea:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  1040ee:	0f 85 65 ff ff ff    	jne    104059 <print_pgdir+0x80>
//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
  1040f4:	b9 00 b0 fe fa       	mov    $0xfafeb000,%ecx
  1040f9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1040fc:	8d 55 dc             	lea    -0x24(%ebp),%edx
  1040ff:	89 54 24 14          	mov    %edx,0x14(%esp)
  104103:	8d 55 e0             	lea    -0x20(%ebp),%edx
  104106:	89 54 24 10          	mov    %edx,0x10(%esp)
  10410a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  10410e:	89 44 24 08          	mov    %eax,0x8(%esp)
  104112:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  104119:	00 
  10411a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104121:	e8 01 fe ff ff       	call   103f27 <get_pgtable_items>
  104126:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  104129:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  10412d:	0f 85 c7 fe ff ff    	jne    103ffa <print_pgdir+0x21>
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
        }
    }
    cprintf("--------------------- END ---------------------\n");
  104133:	c7 04 24 a4 6b 10 00 	movl   $0x106ba4,(%esp)
  10413a:	e8 53 c1 ff ff       	call   100292 <cprintf>
}
  10413f:	90                   	nop
  104140:	83 c4 4c             	add    $0x4c,%esp
  104143:	5b                   	pop    %ebx
  104144:	5e                   	pop    %esi
  104145:	5f                   	pop    %edi
  104146:	5d                   	pop    %ebp
  104147:	c3                   	ret    

00104148 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
  104148:	55                   	push   %ebp
  104149:	89 e5                	mov    %esp,%ebp
    return page - pages;
  10414b:	8b 45 08             	mov    0x8(%ebp),%eax
  10414e:	8b 15 18 af 11 00    	mov    0x11af18,%edx
  104154:	29 d0                	sub    %edx,%eax
  104156:	c1 f8 02             	sar    $0x2,%eax
  104159:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
  10415f:	5d                   	pop    %ebp
  104160:	c3                   	ret    

00104161 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
  104161:	55                   	push   %ebp
  104162:	89 e5                	mov    %esp,%ebp
  104164:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
  104167:	8b 45 08             	mov    0x8(%ebp),%eax
  10416a:	89 04 24             	mov    %eax,(%esp)
  10416d:	e8 d6 ff ff ff       	call   104148 <page2ppn>
  104172:	c1 e0 0c             	shl    $0xc,%eax
}
  104175:	c9                   	leave  
  104176:	c3                   	ret    

00104177 <page_ref>:
pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
}

static inline int
page_ref(struct Page *page) {
  104177:	55                   	push   %ebp
  104178:	89 e5                	mov    %esp,%ebp
    return page->ref;
  10417a:	8b 45 08             	mov    0x8(%ebp),%eax
  10417d:	8b 00                	mov    (%eax),%eax
}
  10417f:	5d                   	pop    %ebp
  104180:	c3                   	ret    

00104181 <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
  104181:	55                   	push   %ebp
  104182:	89 e5                	mov    %esp,%ebp
    page->ref = val;
  104184:	8b 45 08             	mov    0x8(%ebp),%eax
  104187:	8b 55 0c             	mov    0xc(%ebp),%edx
  10418a:	89 10                	mov    %edx,(%eax)
}
  10418c:	90                   	nop
  10418d:	5d                   	pop    %ebp
  10418e:	c3                   	ret    

0010418f <default_init>:

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
  10418f:	55                   	push   %ebp
  104190:	89 e5                	mov    %esp,%ebp
  104192:	83 ec 10             	sub    $0x10,%esp
  104195:	c7 45 fc 1c af 11 00 	movl   $0x11af1c,-0x4(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
  10419c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10419f:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1041a2:	89 50 04             	mov    %edx,0x4(%eax)
  1041a5:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1041a8:	8b 50 04             	mov    0x4(%eax),%edx
  1041ab:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1041ae:	89 10                	mov    %edx,(%eax)
     * Because at first there is no free block to add, so we just let the prev and next pointers to point to itself.
     * This is done through:
     *      free_list->next = free_list->prev = free_list;
     */
    list_init(&free_list);
    nr_free = 0;
  1041b0:	c7 05 24 af 11 00 00 	movl   $0x0,0x11af24
  1041b7:	00 00 00 
}
  1041ba:	90                   	nop
  1041bb:	c9                   	leave  
  1041bc:	c3                   	ret    

001041bd <default_init_memmap>:
 * Page has been referenced, etc.
 * 
 * This function is used to initilize each page within a free memory block and then link it to the free list.
 */
static void
default_init_memmap(struct Page *base, size_t n) {
  1041bd:	55                   	push   %ebp
  1041be:	89 e5                	mov    %esp,%ebp
  1041c0:	83 ec 48             	sub    $0x48,%esp
assert(n > 0);
  1041c3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  1041c7:	75 24                	jne    1041ed <default_init_memmap+0x30>
  1041c9:	c7 44 24 0c d8 6b 10 	movl   $0x106bd8,0xc(%esp)
  1041d0:	00 
  1041d1:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  1041d8:	00 
  1041d9:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  1041e0:	00 
  1041e1:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  1041e8:	e8 fc c1 ff ff       	call   1003e9 <__panic>
    struct Page *p = base;
  1041ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1041f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
  1041f3:	eb 7d                	jmp    104272 <default_init_memmap+0xb5>
        assert(PageReserved(p));
  1041f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1041f8:	83 c0 04             	add    $0x4,%eax
  1041fb:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  104202:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104205:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104208:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10420b:	0f a3 10             	bt     %edx,(%eax)
  10420e:	19 c0                	sbb    %eax,%eax
  104210:	89 45 e0             	mov    %eax,-0x20(%ebp)
    return oldbit != 0;
  104213:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  104217:	0f 95 c0             	setne  %al
  10421a:	0f b6 c0             	movzbl %al,%eax
  10421d:	85 c0                	test   %eax,%eax
  10421f:	75 24                	jne    104245 <default_init_memmap+0x88>
  104221:	c7 44 24 0c 09 6c 10 	movl   $0x106c09,0xc(%esp)
  104228:	00 
  104229:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104230:	00 
  104231:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  104238:	00 
  104239:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104240:	e8 a4 c1 ff ff       	call   1003e9 <__panic>
        p->flags = p->property = 0;
  104245:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104248:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  10424f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104252:	8b 50 08             	mov    0x8(%eax),%edx
  104255:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104258:	89 50 04             	mov    %edx,0x4(%eax)
        set_page_ref(p, 0);
  10425b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104262:	00 
  104263:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104266:	89 04 24             	mov    %eax,(%esp)
  104269:	e8 13 ff ff ff       	call   104181 <set_page_ref>
 */
static void
default_init_memmap(struct Page *base, size_t n) {
assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
  10426e:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
  104272:	8b 55 0c             	mov    0xc(%ebp),%edx
  104275:	89 d0                	mov    %edx,%eax
  104277:	c1 e0 02             	shl    $0x2,%eax
  10427a:	01 d0                	add    %edx,%eax
  10427c:	c1 e0 02             	shl    $0x2,%eax
  10427f:	89 c2                	mov    %eax,%edx
  104281:	8b 45 08             	mov    0x8(%ebp),%eax
  104284:	01 d0                	add    %edx,%eax
  104286:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104289:	0f 85 66 ff ff ff    	jne    1041f5 <default_init_memmap+0x38>
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
  10428f:	8b 45 08             	mov    0x8(%ebp),%eax
  104292:	8b 55 0c             	mov    0xc(%ebp),%edx
  104295:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
  104298:	8b 45 08             	mov    0x8(%ebp),%eax
  10429b:	83 c0 04             	add    $0x4,%eax
  10429e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
  1042a5:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  1042a8:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1042ab:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1042ae:	0f ab 10             	bts    %edx,(%eax)
    nr_free += n;
  1042b1:	8b 15 24 af 11 00    	mov    0x11af24,%edx
  1042b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1042ba:	01 d0                	add    %edx,%eax
  1042bc:	a3 24 af 11 00       	mov    %eax,0x11af24
    list_add_before(&free_list, &(base->page_link));
  1042c1:	8b 45 08             	mov    0x8(%ebp),%eax
  1042c4:	83 c0 0c             	add    $0xc,%eax
  1042c7:	c7 45 f0 1c af 11 00 	movl   $0x11af1c,-0x10(%ebp)
  1042ce:	89 45 dc             	mov    %eax,-0x24(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
  1042d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042d4:	8b 00                	mov    (%eax),%eax
  1042d6:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1042d9:	89 55 d8             	mov    %edx,-0x28(%ebp)
  1042dc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  1042df:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042e2:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  1042e5:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1042e8:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1042eb:	89 10                	mov    %edx,(%eax)
  1042ed:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1042f0:	8b 10                	mov    (%eax),%edx
  1042f2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1042f5:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  1042f8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1042fb:	8b 55 d0             	mov    -0x30(%ebp),%edx
  1042fe:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  104301:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104304:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  104307:	89 10                	mov    %edx,(%eax)
}
  104309:	90                   	nop
  10430a:	c9                   	leave  
  10430b:	c3                   	ret    

0010430c <default_alloc_pages>:
static struct Page *
default_alloc_pages(size_t n) {
  10430c:	55                   	push   %ebp
  10430d:	89 e5                	mov    %esp,%ebp
  10430f:	83 ec 68             	sub    $0x68,%esp

    assert(n > 0);
  104312:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  104316:	75 24                	jne    10433c <default_alloc_pages+0x30>
  104318:	c7 44 24 0c d8 6b 10 	movl   $0x106bd8,0xc(%esp)
  10431f:	00 
  104320:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104327:	00 
  104328:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  10432f:	00 
  104330:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104337:	e8 ad c0 ff ff       	call   1003e9 <__panic>
    /*
     * The required size n cannot be allocated, because there is no more free memory block.
     */
    if (n > nr_free) {
  10433c:	a1 24 af 11 00       	mov    0x11af24,%eax
  104341:	3b 45 08             	cmp    0x8(%ebp),%eax
  104344:	73 0a                	jae    104350 <default_alloc_pages+0x44>
        return NULL;
  104346:	b8 00 00 00 00       	mov    $0x0,%eax
  10434b:	e9 3d 01 00 00       	jmp    10448d <default_alloc_pages+0x181>
    }
    struct Page *page = NULL; // <- This is the base page of the block, i.e., the identifier of the block.
  104350:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    list_entry_t *le = &free_list;
  104357:	c7 45 f0 1c af 11 00 	movl   $0x11af1c,-0x10(%ebp)
    /* 
     * Haobin Chen.
     * Traverse the free list.
     * If the next memory block to find is the head of the free list, then it means we cannot find any available block.
     */
    while ((le = list_next(le)) != &free_list) {
  10435e:	eb 1c                	jmp    10437c <default_alloc_pages+0x70>
        struct Page *p = le2page(le, page_link);
  104360:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104363:	83 e8 0c             	sub    $0xc,%eax
  104366:	89 45 e8             	mov    %eax,-0x18(%ebp)
        if (p->property >= n) {
  104369:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10436c:	8b 40 08             	mov    0x8(%eax),%eax
  10436f:	3b 45 08             	cmp    0x8(%ebp),%eax
  104372:	72 08                	jb     10437c <default_alloc_pages+0x70>
            page = p;
  104374:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104377:	89 45 f4             	mov    %eax,-0xc(%ebp)
            break;
  10437a:	eb 18                	jmp    104394 <default_alloc_pages+0x88>
  10437c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10437f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  104382:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  104385:	8b 40 04             	mov    0x4(%eax),%eax
    /* 
     * Haobin Chen.
     * Traverse the free list.
     * If the next memory block to find is the head of the free list, then it means we cannot find any available block.
     */
    while ((le = list_next(le)) != &free_list) {
  104388:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10438b:	81 7d f0 1c af 11 00 	cmpl   $0x11af1c,-0x10(%ebp)
  104392:	75 cc                	jne    104360 <default_alloc_pages+0x54>
            page = p;
            break;
        }
    }

    if (page != NULL) {
  104394:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  104398:	0f 84 ec 00 00 00    	je     10448a <default_alloc_pages+0x17e>
        // Adjust the allocation step by split block into two.
        // list_del(&(page->page_link));
        if (page->property > n) {
  10439e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1043a1:	8b 40 08             	mov    0x8(%eax),%eax
  1043a4:	3b 45 08             	cmp    0x8(%ebp),%eax
  1043a7:	0f 86 8c 00 00 00    	jbe    104439 <default_alloc_pages+0x12d>
            struct Page *p = page + n;
  1043ad:	8b 55 08             	mov    0x8(%ebp),%edx
  1043b0:	89 d0                	mov    %edx,%eax
  1043b2:	c1 e0 02             	shl    $0x2,%eax
  1043b5:	01 d0                	add    %edx,%eax
  1043b7:	c1 e0 02             	shl    $0x2,%eax
  1043ba:	89 c2                	mov    %eax,%edx
  1043bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1043bf:	01 d0                	add    %edx,%eax
  1043c1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            p->property = page->property - n;
  1043c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1043c7:	8b 40 08             	mov    0x8(%eax),%eax
  1043ca:	2b 45 08             	sub    0x8(%ebp),%eax
  1043cd:	89 c2                	mov    %eax,%edx
  1043cf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1043d2:	89 50 08             	mov    %edx,0x8(%eax)
            // Apply the property.
            SetPageProperty(p);
  1043d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1043d8:	83 c0 04             	add    $0x4,%eax
  1043db:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
  1043e2:	89 45 c0             	mov    %eax,-0x40(%ebp)
  1043e5:	8b 45 c0             	mov    -0x40(%ebp),%eax
  1043e8:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1043eb:	0f ab 10             	bts    %edx,(%eax)
            // Split the memory block and append the remainder right behind the current block.
            list_add_after(&(page->page_link), &(p->page_link));
  1043ee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1043f1:	83 c0 0c             	add    $0xc,%eax
  1043f4:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1043f7:	83 c2 0c             	add    $0xc,%edx
  1043fa:	89 55 ec             	mov    %edx,-0x14(%ebp)
  1043fd:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
  104400:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104403:	8b 40 04             	mov    0x4(%eax),%eax
  104406:	8b 55 d0             	mov    -0x30(%ebp),%edx
  104409:	89 55 cc             	mov    %edx,-0x34(%ebp)
  10440c:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10440f:	89 55 c8             	mov    %edx,-0x38(%ebp)
  104412:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  104415:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  104418:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10441b:	89 10                	mov    %edx,(%eax)
  10441d:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  104420:	8b 10                	mov    (%eax),%edx
  104422:	8b 45 c8             	mov    -0x38(%ebp),%eax
  104425:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  104428:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10442b:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  10442e:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  104431:	8b 45 cc             	mov    -0x34(%ebp),%eax
  104434:	8b 55 c8             	mov    -0x38(%ebp),%edx
  104437:	89 10                	mov    %edx,(%eax)
        }

        list_del(&(page->page_link));
  104439:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10443c:	83 c0 0c             	add    $0xc,%eax
  10443f:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
  104442:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104445:	8b 40 04             	mov    0x4(%eax),%eax
  104448:	8b 55 d8             	mov    -0x28(%ebp),%edx
  10444b:	8b 12                	mov    (%edx),%edx
  10444d:	89 55 b8             	mov    %edx,-0x48(%ebp)
  104450:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
  104453:	8b 45 b8             	mov    -0x48(%ebp),%eax
  104456:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  104459:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
  10445c:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  10445f:	8b 55 b8             	mov    -0x48(%ebp),%edx
  104462:	89 10                	mov    %edx,(%eax)
        nr_free -= n;
  104464:	a1 24 af 11 00       	mov    0x11af24,%eax
  104469:	2b 45 08             	sub    0x8(%ebp),%eax
  10446c:	a3 24 af 11 00       	mov    %eax,0x11af24
        ClearPageProperty(page);
  104471:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104474:	83 c0 04             	add    $0x4,%eax
  104477:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
  10447e:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  104481:	8b 45 bc             	mov    -0x44(%ebp),%eax
  104484:	8b 55 e0             	mov    -0x20(%ebp),%edx
  104487:	0f b3 10             	btr    %edx,(%eax)
    }
    return page;
  10448a:	8b 45 f4             	mov    -0xc(%ebp),%eax

}
  10448d:	c9                   	leave  
  10448e:	c3                   	ret    

0010448f <default_free_pages>:

static void
default_free_pages(struct Page *base, size_t n) {
  10448f:	55                   	push   %ebp
  104490:	89 e5                	mov    %esp,%ebp
  104492:	81 ec 98 00 00 00    	sub    $0x98,%esp
    assert(n > 0);
  104498:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  10449c:	75 24                	jne    1044c2 <default_free_pages+0x33>
  10449e:	c7 44 24 0c d8 6b 10 	movl   $0x106bd8,0xc(%esp)
  1044a5:	00 
  1044a6:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  1044ad:	00 
  1044ae:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
  1044b5:	00 
  1044b6:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  1044bd:	e8 27 bf ff ff       	call   1003e9 <__panic>
    struct Page *p = base;
  1044c2:	8b 45 08             	mov    0x8(%ebp),%eax
  1044c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
  1044c8:	e9 9d 00 00 00       	jmp    10456a <default_free_pages+0xdb>
        // Reset the pages within the block.
        assert(!PageReserved(p) && !PageProperty(p));
  1044cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1044d0:	83 c0 04             	add    $0x4,%eax
  1044d3:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
  1044da:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  1044dd:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  1044e0:	8b 55 b8             	mov    -0x48(%ebp),%edx
  1044e3:	0f a3 10             	bt     %edx,(%eax)
  1044e6:	19 c0                	sbb    %eax,%eax
  1044e8:	89 45 b0             	mov    %eax,-0x50(%ebp)
    return oldbit != 0;
  1044eb:	83 7d b0 00          	cmpl   $0x0,-0x50(%ebp)
  1044ef:	0f 95 c0             	setne  %al
  1044f2:	0f b6 c0             	movzbl %al,%eax
  1044f5:	85 c0                	test   %eax,%eax
  1044f7:	75 2c                	jne    104525 <default_free_pages+0x96>
  1044f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1044fc:	83 c0 04             	add    $0x4,%eax
  1044ff:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
  104506:	89 45 ac             	mov    %eax,-0x54(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104509:	8b 45 ac             	mov    -0x54(%ebp),%eax
  10450c:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10450f:	0f a3 10             	bt     %edx,(%eax)
  104512:	19 c0                	sbb    %eax,%eax
  104514:	89 45 a8             	mov    %eax,-0x58(%ebp)
    return oldbit != 0;
  104517:	83 7d a8 00          	cmpl   $0x0,-0x58(%ebp)
  10451b:	0f 95 c0             	setne  %al
  10451e:	0f b6 c0             	movzbl %al,%eax
  104521:	85 c0                	test   %eax,%eax
  104523:	74 24                	je     104549 <default_free_pages+0xba>
  104525:	c7 44 24 0c 1c 6c 10 	movl   $0x106c1c,0xc(%esp)
  10452c:	00 
  10452d:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104534:	00 
  104535:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
  10453c:	00 
  10453d:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104544:	e8 a0 be ff ff       	call   1003e9 <__panic>
        p->flags = 0;
  104549:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10454c:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
        set_page_ref(p, 0);
  104553:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10455a:	00 
  10455b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10455e:	89 04 24             	mov    %eax,(%esp)
  104561:	e8 1b fc ff ff       	call   104181 <set_page_ref>

static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
  104566:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
  10456a:	8b 55 0c             	mov    0xc(%ebp),%edx
  10456d:	89 d0                	mov    %edx,%eax
  10456f:	c1 e0 02             	shl    $0x2,%eax
  104572:	01 d0                	add    %edx,%eax
  104574:	c1 e0 02             	shl    $0x2,%eax
  104577:	89 c2                	mov    %eax,%edx
  104579:	8b 45 08             	mov    0x8(%ebp),%eax
  10457c:	01 d0                	add    %edx,%eax
  10457e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104581:	0f 85 46 ff ff ff    	jne    1044cd <default_free_pages+0x3e>
        // Reset the pages within the block.
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
  104587:	8b 45 08             	mov    0x8(%ebp),%eax
  10458a:	8b 55 0c             	mov    0xc(%ebp),%edx
  10458d:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
  104590:	8b 45 08             	mov    0x8(%ebp),%eax
  104593:	83 c0 04             	add    $0x4,%eax
  104596:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
  10459d:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  1045a0:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  1045a3:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1045a6:	0f ab 10             	bts    %edx,(%eax)
  1045a9:	c7 45 e4 1c af 11 00 	movl   $0x11af1c,-0x1c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  1045b0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1045b3:	8b 40 04             	mov    0x4(%eax),%eax

    list_entry_t *le = list_next(&free_list);
  1045b6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
  1045b9:	e9 08 01 00 00       	jmp    1046c6 <default_free_pages+0x237>
        // Get the next block and fetch its property by tranforming it to a page pointer.
        p = le2page(le, page_link);
  1045be:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1045c1:	83 e8 0c             	sub    $0xc,%eax
  1045c4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1045c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1045ca:	89 45 e0             	mov    %eax,-0x20(%ebp)
  1045cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1045d0:	8b 40 04             	mov    0x4(%eax),%eax
        le = list_next(le);
  1045d3:	89 45 f0             	mov    %eax,-0x10(%ebp)

        // Do merge.
        if (base + base->property == p) {
  1045d6:	8b 45 08             	mov    0x8(%ebp),%eax
  1045d9:	8b 50 08             	mov    0x8(%eax),%edx
  1045dc:	89 d0                	mov    %edx,%eax
  1045de:	c1 e0 02             	shl    $0x2,%eax
  1045e1:	01 d0                	add    %edx,%eax
  1045e3:	c1 e0 02             	shl    $0x2,%eax
  1045e6:	89 c2                	mov    %eax,%edx
  1045e8:	8b 45 08             	mov    0x8(%ebp),%eax
  1045eb:	01 d0                	add    %edx,%eax
  1045ed:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  1045f0:	75 5a                	jne    10464c <default_free_pages+0x1bd>
            // Merge with the next block.
            base->property += p->property;
  1045f2:	8b 45 08             	mov    0x8(%ebp),%eax
  1045f5:	8b 50 08             	mov    0x8(%eax),%edx
  1045f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1045fb:	8b 40 08             	mov    0x8(%eax),%eax
  1045fe:	01 c2                	add    %eax,%edx
  104600:	8b 45 08             	mov    0x8(%ebp),%eax
  104603:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(p);
  104606:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104609:	83 c0 04             	add    $0x4,%eax
  10460c:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  104613:	89 45 98             	mov    %eax,-0x68(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
  104616:	8b 45 98             	mov    -0x68(%ebp),%eax
  104619:	8b 55 d0             	mov    -0x30(%ebp),%edx
  10461c:	0f b3 10             	btr    %edx,(%eax)
            list_del(&(p->page_link));
  10461f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104622:	83 c0 0c             	add    $0xc,%eax
  104625:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
  104628:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10462b:	8b 40 04             	mov    0x4(%eax),%eax
  10462e:	8b 55 d8             	mov    -0x28(%ebp),%edx
  104631:	8b 12                	mov    (%edx),%edx
  104633:	89 55 a0             	mov    %edx,-0x60(%ebp)
  104636:	89 45 9c             	mov    %eax,-0x64(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
  104639:	8b 45 a0             	mov    -0x60(%ebp),%eax
  10463c:	8b 55 9c             	mov    -0x64(%ebp),%edx
  10463f:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
  104642:	8b 45 9c             	mov    -0x64(%ebp),%eax
  104645:	8b 55 a0             	mov    -0x60(%ebp),%edx
  104648:	89 10                	mov    %edx,(%eax)
  10464a:	eb 7a                	jmp    1046c6 <default_free_pages+0x237>
        }
        else if (p + p->property == base) {
  10464c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10464f:	8b 50 08             	mov    0x8(%eax),%edx
  104652:	89 d0                	mov    %edx,%eax
  104654:	c1 e0 02             	shl    $0x2,%eax
  104657:	01 d0                	add    %edx,%eax
  104659:	c1 e0 02             	shl    $0x2,%eax
  10465c:	89 c2                	mov    %eax,%edx
  10465e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104661:	01 d0                	add    %edx,%eax
  104663:	3b 45 08             	cmp    0x8(%ebp),%eax
  104666:	75 5e                	jne    1046c6 <default_free_pages+0x237>
            // Merge with the previous block.
            p->property += base->property;
  104668:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10466b:	8b 50 08             	mov    0x8(%eax),%edx
  10466e:	8b 45 08             	mov    0x8(%ebp),%eax
  104671:	8b 40 08             	mov    0x8(%eax),%eax
  104674:	01 c2                	add    %eax,%edx
  104676:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104679:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(base);
  10467c:	8b 45 08             	mov    0x8(%ebp),%eax
  10467f:	83 c0 04             	add    $0x4,%eax
  104682:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
  104689:	89 45 8c             	mov    %eax,-0x74(%ebp)
  10468c:	8b 45 8c             	mov    -0x74(%ebp),%eax
  10468f:	8b 55 c8             	mov    -0x38(%ebp),%edx
  104692:	0f b3 10             	btr    %edx,(%eax)
            base = p;
  104695:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104698:	89 45 08             	mov    %eax,0x8(%ebp)
            list_del(&(p->page_link));
  10469b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10469e:	83 c0 0c             	add    $0xc,%eax
  1046a1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
  1046a4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1046a7:	8b 40 04             	mov    0x4(%eax),%eax
  1046aa:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1046ad:	8b 12                	mov    (%edx),%edx
  1046af:	89 55 94             	mov    %edx,-0x6c(%ebp)
  1046b2:	89 45 90             	mov    %eax,-0x70(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
  1046b5:	8b 45 94             	mov    -0x6c(%ebp),%eax
  1046b8:	8b 55 90             	mov    -0x70(%ebp),%edx
  1046bb:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
  1046be:	8b 45 90             	mov    -0x70(%ebp),%eax
  1046c1:	8b 55 94             	mov    -0x6c(%ebp),%edx
  1046c4:	89 10                	mov    %edx,(%eax)
    }
    base->property = n;
    SetPageProperty(base);

    list_entry_t *le = list_next(&free_list);
    while (le != &free_list) {
  1046c6:	81 7d f0 1c af 11 00 	cmpl   $0x11af1c,-0x10(%ebp)
  1046cd:	0f 85 eb fe ff ff    	jne    1045be <default_free_pages+0x12f>
  1046d3:	c7 45 cc 1c af 11 00 	movl   $0x11af1c,-0x34(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  1046da:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1046dd:	8b 40 04             	mov    0x4(%eax),%eax
    /*
     * Haobin Chen.
     * 
     * Find the right place to insert.
     */
    list_entry_t *ptr = list_next(&free_list);
  1046e0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    while (ptr != &free_list) {
  1046e3:	eb 34                	jmp    104719 <default_free_pages+0x28a>
         * le2page receives two parameters to convert a struct to another. The second parameter
         * means the member to be the first parameter.
         * 
         * E.g. Current page's page_link member will be the first parameter: ptr (which is the current block to be accessed).
         */
        struct Page *cur = le2page(ptr, page_link);
  1046e5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1046e8:	83 e8 0c             	sub    $0xc,%eax
  1046eb:	89 45 c0             	mov    %eax,-0x40(%ebp)
        if (base + base->property < cur) {
  1046ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1046f1:	8b 50 08             	mov    0x8(%eax),%edx
  1046f4:	89 d0                	mov    %edx,%eax
  1046f6:	c1 e0 02             	shl    $0x2,%eax
  1046f9:	01 d0                	add    %edx,%eax
  1046fb:	c1 e0 02             	shl    $0x2,%eax
  1046fe:	89 c2                	mov    %eax,%edx
  104700:	8b 45 08             	mov    0x8(%ebp),%eax
  104703:	01 d0                	add    %edx,%eax
  104705:	3b 45 c0             	cmp    -0x40(%ebp),%eax
  104708:	72 1a                	jb     104724 <default_free_pages+0x295>
  10470a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10470d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
  104710:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  104713:	8b 40 04             	mov    0x4(%eax),%eax
            break;
        }
        ptr = list_next(ptr);
  104716:	89 45 ec             	mov    %eax,-0x14(%ebp)
     * Haobin Chen.
     * 
     * Find the right place to insert.
     */
    list_entry_t *ptr = list_next(&free_list);
    while (ptr != &free_list) {
  104719:	81 7d ec 1c af 11 00 	cmpl   $0x11af1c,-0x14(%ebp)
  104720:	75 c3                	jne    1046e5 <default_free_pages+0x256>
  104722:	eb 01                	jmp    104725 <default_free_pages+0x296>
         * 
         * E.g. Current page's page_link member will be the first parameter: ptr (which is the current block to be accessed).
         */
        struct Page *cur = le2page(ptr, page_link);
        if (base + base->property < cur) {
            break;
  104724:	90                   	nop
        }
        ptr = list_next(ptr);
    }

    list_add_before(ptr, &(base->page_link));
  104725:	8b 45 08             	mov    0x8(%ebp),%eax
  104728:	8d 50 0c             	lea    0xc(%eax),%edx
  10472b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10472e:	89 45 bc             	mov    %eax,-0x44(%ebp)
  104731:	89 55 88             	mov    %edx,-0x78(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
  104734:	8b 45 bc             	mov    -0x44(%ebp),%eax
  104737:	8b 00                	mov    (%eax),%eax
  104739:	8b 55 88             	mov    -0x78(%ebp),%edx
  10473c:	89 55 84             	mov    %edx,-0x7c(%ebp)
  10473f:	89 45 80             	mov    %eax,-0x80(%ebp)
  104742:	8b 45 bc             	mov    -0x44(%ebp),%eax
  104745:	89 85 7c ff ff ff    	mov    %eax,-0x84(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
  10474b:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  104751:	8b 55 84             	mov    -0x7c(%ebp),%edx
  104754:	89 10                	mov    %edx,(%eax)
  104756:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  10475c:	8b 10                	mov    (%eax),%edx
  10475e:	8b 45 80             	mov    -0x80(%ebp),%eax
  104761:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
  104764:	8b 45 84             	mov    -0x7c(%ebp),%eax
  104767:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  10476d:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
  104770:	8b 45 84             	mov    -0x7c(%ebp),%eax
  104773:	8b 55 80             	mov    -0x80(%ebp),%edx
  104776:	89 10                	mov    %edx,(%eax)
    nr_free += n;
  104778:	8b 15 24 af 11 00    	mov    0x11af24,%edx
  10477e:	8b 45 0c             	mov    0xc(%ebp),%eax
  104781:	01 d0                	add    %edx,%eax
  104783:	a3 24 af 11 00       	mov    %eax,0x11af24
}
  104788:	90                   	nop
  104789:	c9                   	leave  
  10478a:	c3                   	ret    

0010478b <default_nr_free_pages>:

static size_t
default_nr_free_pages(void) {
  10478b:	55                   	push   %ebp
  10478c:	89 e5                	mov    %esp,%ebp
    return nr_free;
  10478e:	a1 24 af 11 00       	mov    0x11af24,%eax
}
  104793:	5d                   	pop    %ebp
  104794:	c3                   	ret    

00104795 <basic_check>:

static void
basic_check(void) {
  104795:	55                   	push   %ebp
  104796:	89 e5                	mov    %esp,%ebp
  104798:	83 ec 48             	sub    $0x48,%esp
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
  10479b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1047a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1047a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1047a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1047ab:	89 45 ec             	mov    %eax,-0x14(%ebp)
    assert((p0 = alloc_page()) != NULL);
  1047ae:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1047b5:	e8 d3 e2 ff ff       	call   102a8d <alloc_pages>
  1047ba:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1047bd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1047c1:	75 24                	jne    1047e7 <basic_check+0x52>
  1047c3:	c7 44 24 0c 41 6c 10 	movl   $0x106c41,0xc(%esp)
  1047ca:	00 
  1047cb:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  1047d2:	00 
  1047d3:	c7 44 24 04 1c 01 00 	movl   $0x11c,0x4(%esp)
  1047da:	00 
  1047db:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  1047e2:	e8 02 bc ff ff       	call   1003e9 <__panic>
    assert((p1 = alloc_page()) != NULL);
  1047e7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1047ee:	e8 9a e2 ff ff       	call   102a8d <alloc_pages>
  1047f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1047f6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1047fa:	75 24                	jne    104820 <basic_check+0x8b>
  1047fc:	c7 44 24 0c 5d 6c 10 	movl   $0x106c5d,0xc(%esp)
  104803:	00 
  104804:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  10480b:	00 
  10480c:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
  104813:	00 
  104814:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  10481b:	e8 c9 bb ff ff       	call   1003e9 <__panic>
    assert((p2 = alloc_page()) != NULL);
  104820:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104827:	e8 61 e2 ff ff       	call   102a8d <alloc_pages>
  10482c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10482f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  104833:	75 24                	jne    104859 <basic_check+0xc4>
  104835:	c7 44 24 0c 79 6c 10 	movl   $0x106c79,0xc(%esp)
  10483c:	00 
  10483d:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104844:	00 
  104845:	c7 44 24 04 1e 01 00 	movl   $0x11e,0x4(%esp)
  10484c:	00 
  10484d:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104854:	e8 90 bb ff ff       	call   1003e9 <__panic>

    assert(p0 != p1 && p0 != p2 && p1 != p2);
  104859:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10485c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10485f:	74 10                	je     104871 <basic_check+0xdc>
  104861:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104864:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104867:	74 08                	je     104871 <basic_check+0xdc>
  104869:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10486c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  10486f:	75 24                	jne    104895 <basic_check+0x100>
  104871:	c7 44 24 0c 98 6c 10 	movl   $0x106c98,0xc(%esp)
  104878:	00 
  104879:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104880:	00 
  104881:	c7 44 24 04 20 01 00 	movl   $0x120,0x4(%esp)
  104888:	00 
  104889:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104890:	e8 54 bb ff ff       	call   1003e9 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
  104895:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104898:	89 04 24             	mov    %eax,(%esp)
  10489b:	e8 d7 f8 ff ff       	call   104177 <page_ref>
  1048a0:	85 c0                	test   %eax,%eax
  1048a2:	75 1e                	jne    1048c2 <basic_check+0x12d>
  1048a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1048a7:	89 04 24             	mov    %eax,(%esp)
  1048aa:	e8 c8 f8 ff ff       	call   104177 <page_ref>
  1048af:	85 c0                	test   %eax,%eax
  1048b1:	75 0f                	jne    1048c2 <basic_check+0x12d>
  1048b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1048b6:	89 04 24             	mov    %eax,(%esp)
  1048b9:	e8 b9 f8 ff ff       	call   104177 <page_ref>
  1048be:	85 c0                	test   %eax,%eax
  1048c0:	74 24                	je     1048e6 <basic_check+0x151>
  1048c2:	c7 44 24 0c bc 6c 10 	movl   $0x106cbc,0xc(%esp)
  1048c9:	00 
  1048ca:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  1048d1:	00 
  1048d2:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
  1048d9:	00 
  1048da:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  1048e1:	e8 03 bb ff ff       	call   1003e9 <__panic>

    assert(page2pa(p0) < npage * PGSIZE);
  1048e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1048e9:	89 04 24             	mov    %eax,(%esp)
  1048ec:	e8 70 f8 ff ff       	call   104161 <page2pa>
  1048f1:	8b 15 80 ae 11 00    	mov    0x11ae80,%edx
  1048f7:	c1 e2 0c             	shl    $0xc,%edx
  1048fa:	39 d0                	cmp    %edx,%eax
  1048fc:	72 24                	jb     104922 <basic_check+0x18d>
  1048fe:	c7 44 24 0c f8 6c 10 	movl   $0x106cf8,0xc(%esp)
  104905:	00 
  104906:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  10490d:	00 
  10490e:	c7 44 24 04 23 01 00 	movl   $0x123,0x4(%esp)
  104915:	00 
  104916:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  10491d:	e8 c7 ba ff ff       	call   1003e9 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
  104922:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104925:	89 04 24             	mov    %eax,(%esp)
  104928:	e8 34 f8 ff ff       	call   104161 <page2pa>
  10492d:	8b 15 80 ae 11 00    	mov    0x11ae80,%edx
  104933:	c1 e2 0c             	shl    $0xc,%edx
  104936:	39 d0                	cmp    %edx,%eax
  104938:	72 24                	jb     10495e <basic_check+0x1c9>
  10493a:	c7 44 24 0c 15 6d 10 	movl   $0x106d15,0xc(%esp)
  104941:	00 
  104942:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104949:	00 
  10494a:	c7 44 24 04 24 01 00 	movl   $0x124,0x4(%esp)
  104951:	00 
  104952:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104959:	e8 8b ba ff ff       	call   1003e9 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
  10495e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104961:	89 04 24             	mov    %eax,(%esp)
  104964:	e8 f8 f7 ff ff       	call   104161 <page2pa>
  104969:	8b 15 80 ae 11 00    	mov    0x11ae80,%edx
  10496f:	c1 e2 0c             	shl    $0xc,%edx
  104972:	39 d0                	cmp    %edx,%eax
  104974:	72 24                	jb     10499a <basic_check+0x205>
  104976:	c7 44 24 0c 32 6d 10 	movl   $0x106d32,0xc(%esp)
  10497d:	00 
  10497e:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104985:	00 
  104986:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
  10498d:	00 
  10498e:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104995:	e8 4f ba ff ff       	call   1003e9 <__panic>

    list_entry_t free_list_store = free_list;
  10499a:	a1 1c af 11 00       	mov    0x11af1c,%eax
  10499f:	8b 15 20 af 11 00    	mov    0x11af20,%edx
  1049a5:	89 45 d0             	mov    %eax,-0x30(%ebp)
  1049a8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  1049ab:	c7 45 e4 1c af 11 00 	movl   $0x11af1c,-0x1c(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
  1049b2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1049b5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1049b8:	89 50 04             	mov    %edx,0x4(%eax)
  1049bb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1049be:	8b 50 04             	mov    0x4(%eax),%edx
  1049c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1049c4:	89 10                	mov    %edx,(%eax)
  1049c6:	c7 45 d8 1c af 11 00 	movl   $0x11af1c,-0x28(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
  1049cd:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1049d0:	8b 40 04             	mov    0x4(%eax),%eax
  1049d3:	39 45 d8             	cmp    %eax,-0x28(%ebp)
  1049d6:	0f 94 c0             	sete   %al
  1049d9:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
  1049dc:	85 c0                	test   %eax,%eax
  1049de:	75 24                	jne    104a04 <basic_check+0x26f>
  1049e0:	c7 44 24 0c 4f 6d 10 	movl   $0x106d4f,0xc(%esp)
  1049e7:	00 
  1049e8:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  1049ef:	00 
  1049f0:	c7 44 24 04 29 01 00 	movl   $0x129,0x4(%esp)
  1049f7:	00 
  1049f8:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  1049ff:	e8 e5 b9 ff ff       	call   1003e9 <__panic>

    unsigned int nr_free_store = nr_free;
  104a04:	a1 24 af 11 00       	mov    0x11af24,%eax
  104a09:	89 45 e0             	mov    %eax,-0x20(%ebp)
    nr_free = 0;
  104a0c:	c7 05 24 af 11 00 00 	movl   $0x0,0x11af24
  104a13:	00 00 00 

    assert(alloc_page() == NULL);
  104a16:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104a1d:	e8 6b e0 ff ff       	call   102a8d <alloc_pages>
  104a22:	85 c0                	test   %eax,%eax
  104a24:	74 24                	je     104a4a <basic_check+0x2b5>
  104a26:	c7 44 24 0c 66 6d 10 	movl   $0x106d66,0xc(%esp)
  104a2d:	00 
  104a2e:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104a35:	00 
  104a36:	c7 44 24 04 2e 01 00 	movl   $0x12e,0x4(%esp)
  104a3d:	00 
  104a3e:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104a45:	e8 9f b9 ff ff       	call   1003e9 <__panic>

    free_page(p0);
  104a4a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104a51:	00 
  104a52:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104a55:	89 04 24             	mov    %eax,(%esp)
  104a58:	e8 68 e0 ff ff       	call   102ac5 <free_pages>
    free_page(p1);
  104a5d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104a64:	00 
  104a65:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104a68:	89 04 24             	mov    %eax,(%esp)
  104a6b:	e8 55 e0 ff ff       	call   102ac5 <free_pages>
    free_page(p2);
  104a70:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104a77:	00 
  104a78:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104a7b:	89 04 24             	mov    %eax,(%esp)
  104a7e:	e8 42 e0 ff ff       	call   102ac5 <free_pages>
    assert(nr_free == 3);
  104a83:	a1 24 af 11 00       	mov    0x11af24,%eax
  104a88:	83 f8 03             	cmp    $0x3,%eax
  104a8b:	74 24                	je     104ab1 <basic_check+0x31c>
  104a8d:	c7 44 24 0c 7b 6d 10 	movl   $0x106d7b,0xc(%esp)
  104a94:	00 
  104a95:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104a9c:	00 
  104a9d:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
  104aa4:	00 
  104aa5:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104aac:	e8 38 b9 ff ff       	call   1003e9 <__panic>

    assert((p0 = alloc_page()) != NULL);
  104ab1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104ab8:	e8 d0 df ff ff       	call   102a8d <alloc_pages>
  104abd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  104ac0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  104ac4:	75 24                	jne    104aea <basic_check+0x355>
  104ac6:	c7 44 24 0c 41 6c 10 	movl   $0x106c41,0xc(%esp)
  104acd:	00 
  104ace:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104ad5:	00 
  104ad6:	c7 44 24 04 35 01 00 	movl   $0x135,0x4(%esp)
  104add:	00 
  104ade:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104ae5:	e8 ff b8 ff ff       	call   1003e9 <__panic>
    assert((p1 = alloc_page()) != NULL);
  104aea:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104af1:	e8 97 df ff ff       	call   102a8d <alloc_pages>
  104af6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104af9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104afd:	75 24                	jne    104b23 <basic_check+0x38e>
  104aff:	c7 44 24 0c 5d 6c 10 	movl   $0x106c5d,0xc(%esp)
  104b06:	00 
  104b07:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104b0e:	00 
  104b0f:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
  104b16:	00 
  104b17:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104b1e:	e8 c6 b8 ff ff       	call   1003e9 <__panic>
    assert((p2 = alloc_page()) != NULL);
  104b23:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104b2a:	e8 5e df ff ff       	call   102a8d <alloc_pages>
  104b2f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104b32:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  104b36:	75 24                	jne    104b5c <basic_check+0x3c7>
  104b38:	c7 44 24 0c 79 6c 10 	movl   $0x106c79,0xc(%esp)
  104b3f:	00 
  104b40:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104b47:	00 
  104b48:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
  104b4f:	00 
  104b50:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104b57:	e8 8d b8 ff ff       	call   1003e9 <__panic>

    assert(alloc_page() == NULL);
  104b5c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104b63:	e8 25 df ff ff       	call   102a8d <alloc_pages>
  104b68:	85 c0                	test   %eax,%eax
  104b6a:	74 24                	je     104b90 <basic_check+0x3fb>
  104b6c:	c7 44 24 0c 66 6d 10 	movl   $0x106d66,0xc(%esp)
  104b73:	00 
  104b74:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104b7b:	00 
  104b7c:	c7 44 24 04 39 01 00 	movl   $0x139,0x4(%esp)
  104b83:	00 
  104b84:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104b8b:	e8 59 b8 ff ff       	call   1003e9 <__panic>

    free_page(p0);
  104b90:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104b97:	00 
  104b98:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104b9b:	89 04 24             	mov    %eax,(%esp)
  104b9e:	e8 22 df ff ff       	call   102ac5 <free_pages>
  104ba3:	c7 45 e8 1c af 11 00 	movl   $0x11af1c,-0x18(%ebp)
  104baa:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104bad:	8b 40 04             	mov    0x4(%eax),%eax
  104bb0:	39 45 e8             	cmp    %eax,-0x18(%ebp)
  104bb3:	0f 94 c0             	sete   %al
  104bb6:	0f b6 c0             	movzbl %al,%eax
    assert(!list_empty(&free_list));
  104bb9:	85 c0                	test   %eax,%eax
  104bbb:	74 24                	je     104be1 <basic_check+0x44c>
  104bbd:	c7 44 24 0c 88 6d 10 	movl   $0x106d88,0xc(%esp)
  104bc4:	00 
  104bc5:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104bcc:	00 
  104bcd:	c7 44 24 04 3c 01 00 	movl   $0x13c,0x4(%esp)
  104bd4:	00 
  104bd5:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104bdc:	e8 08 b8 ff ff       	call   1003e9 <__panic>

    struct Page *p;
    assert((p = alloc_page()) == p0);
  104be1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104be8:	e8 a0 de ff ff       	call   102a8d <alloc_pages>
  104bed:	89 45 dc             	mov    %eax,-0x24(%ebp)
  104bf0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104bf3:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  104bf6:	74 24                	je     104c1c <basic_check+0x487>
  104bf8:	c7 44 24 0c a0 6d 10 	movl   $0x106da0,0xc(%esp)
  104bff:	00 
  104c00:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104c07:	00 
  104c08:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
  104c0f:	00 
  104c10:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104c17:	e8 cd b7 ff ff       	call   1003e9 <__panic>
    assert(alloc_page() == NULL);
  104c1c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104c23:	e8 65 de ff ff       	call   102a8d <alloc_pages>
  104c28:	85 c0                	test   %eax,%eax
  104c2a:	74 24                	je     104c50 <basic_check+0x4bb>
  104c2c:	c7 44 24 0c 66 6d 10 	movl   $0x106d66,0xc(%esp)
  104c33:	00 
  104c34:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104c3b:	00 
  104c3c:	c7 44 24 04 40 01 00 	movl   $0x140,0x4(%esp)
  104c43:	00 
  104c44:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104c4b:	e8 99 b7 ff ff       	call   1003e9 <__panic>

    assert(nr_free == 0);
  104c50:	a1 24 af 11 00       	mov    0x11af24,%eax
  104c55:	85 c0                	test   %eax,%eax
  104c57:	74 24                	je     104c7d <basic_check+0x4e8>
  104c59:	c7 44 24 0c b9 6d 10 	movl   $0x106db9,0xc(%esp)
  104c60:	00 
  104c61:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104c68:	00 
  104c69:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
  104c70:	00 
  104c71:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104c78:	e8 6c b7 ff ff       	call   1003e9 <__panic>
    free_list = free_list_store;
  104c7d:	8b 45 d0             	mov    -0x30(%ebp),%eax
  104c80:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  104c83:	a3 1c af 11 00       	mov    %eax,0x11af1c
  104c88:	89 15 20 af 11 00    	mov    %edx,0x11af20
    nr_free = nr_free_store;
  104c8e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104c91:	a3 24 af 11 00       	mov    %eax,0x11af24

    free_page(p);
  104c96:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104c9d:	00 
  104c9e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104ca1:	89 04 24             	mov    %eax,(%esp)
  104ca4:	e8 1c de ff ff       	call   102ac5 <free_pages>
    free_page(p1);
  104ca9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104cb0:	00 
  104cb1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104cb4:	89 04 24             	mov    %eax,(%esp)
  104cb7:	e8 09 de ff ff       	call   102ac5 <free_pages>
    free_page(p2);
  104cbc:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104cc3:	00 
  104cc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104cc7:	89 04 24             	mov    %eax,(%esp)
  104cca:	e8 f6 dd ff ff       	call   102ac5 <free_pages>
}
  104ccf:	90                   	nop
  104cd0:	c9                   	leave  
  104cd1:	c3                   	ret    

00104cd2 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
  104cd2:	55                   	push   %ebp
  104cd3:	89 e5                	mov    %esp,%ebp
  104cd5:	81 ec 98 00 00 00    	sub    $0x98,%esp
    int count = 0, total = 0;
  104cdb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  104ce2:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    list_entry_t *le = &free_list;
  104ce9:	c7 45 ec 1c af 11 00 	movl   $0x11af1c,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
  104cf0:	eb 6a                	jmp    104d5c <default_check+0x8a>
        struct Page *p = le2page(le, page_link);
  104cf2:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104cf5:	83 e8 0c             	sub    $0xc,%eax
  104cf8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        assert(PageProperty(p));
  104cfb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104cfe:	83 c0 04             	add    $0x4,%eax
  104d01:	c7 45 b0 01 00 00 00 	movl   $0x1,-0x50(%ebp)
  104d08:	89 45 ac             	mov    %eax,-0x54(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104d0b:	8b 45 ac             	mov    -0x54(%ebp),%eax
  104d0e:	8b 55 b0             	mov    -0x50(%ebp),%edx
  104d11:	0f a3 10             	bt     %edx,(%eax)
  104d14:	19 c0                	sbb    %eax,%eax
  104d16:	89 45 a8             	mov    %eax,-0x58(%ebp)
    return oldbit != 0;
  104d19:	83 7d a8 00          	cmpl   $0x0,-0x58(%ebp)
  104d1d:	0f 95 c0             	setne  %al
  104d20:	0f b6 c0             	movzbl %al,%eax
  104d23:	85 c0                	test   %eax,%eax
  104d25:	75 24                	jne    104d4b <default_check+0x79>
  104d27:	c7 44 24 0c c6 6d 10 	movl   $0x106dc6,0xc(%esp)
  104d2e:	00 
  104d2f:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104d36:	00 
  104d37:	c7 44 24 04 53 01 00 	movl   $0x153,0x4(%esp)
  104d3e:	00 
  104d3f:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104d46:	e8 9e b6 ff ff       	call   1003e9 <__panic>
        count ++, total += p->property;
  104d4b:	ff 45 f4             	incl   -0xc(%ebp)
  104d4e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104d51:	8b 50 08             	mov    0x8(%eax),%edx
  104d54:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104d57:	01 d0                	add    %edx,%eax
  104d59:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104d5c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104d5f:	89 45 e0             	mov    %eax,-0x20(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  104d62:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104d65:	8b 40 04             	mov    0x4(%eax),%eax
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
  104d68:	89 45 ec             	mov    %eax,-0x14(%ebp)
  104d6b:	81 7d ec 1c af 11 00 	cmpl   $0x11af1c,-0x14(%ebp)
  104d72:	0f 85 7a ff ff ff    	jne    104cf2 <default_check+0x20>
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());
  104d78:	e8 7b dd ff ff       	call   102af8 <nr_free_pages>
  104d7d:	89 c2                	mov    %eax,%edx
  104d7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104d82:	39 c2                	cmp    %eax,%edx
  104d84:	74 24                	je     104daa <default_check+0xd8>
  104d86:	c7 44 24 0c d6 6d 10 	movl   $0x106dd6,0xc(%esp)
  104d8d:	00 
  104d8e:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104d95:	00 
  104d96:	c7 44 24 04 56 01 00 	movl   $0x156,0x4(%esp)
  104d9d:	00 
  104d9e:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104da5:	e8 3f b6 ff ff       	call   1003e9 <__panic>

    basic_check();
  104daa:	e8 e6 f9 ff ff       	call   104795 <basic_check>

    struct Page *p0 = alloc_pages(5), *p1, *p2;
  104daf:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
  104db6:	e8 d2 dc ff ff       	call   102a8d <alloc_pages>
  104dbb:	89 45 dc             	mov    %eax,-0x24(%ebp)
    assert(p0 != NULL);
  104dbe:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  104dc2:	75 24                	jne    104de8 <default_check+0x116>
  104dc4:	c7 44 24 0c ef 6d 10 	movl   $0x106def,0xc(%esp)
  104dcb:	00 
  104dcc:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104dd3:	00 
  104dd4:	c7 44 24 04 5b 01 00 	movl   $0x15b,0x4(%esp)
  104ddb:	00 
  104ddc:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104de3:	e8 01 b6 ff ff       	call   1003e9 <__panic>
    assert(!PageProperty(p0));
  104de8:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104deb:	83 c0 04             	add    $0x4,%eax
  104dee:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
  104df5:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104df8:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  104dfb:	8b 55 e8             	mov    -0x18(%ebp),%edx
  104dfe:	0f a3 10             	bt     %edx,(%eax)
  104e01:	19 c0                	sbb    %eax,%eax
  104e03:	89 45 a0             	mov    %eax,-0x60(%ebp)
    return oldbit != 0;
  104e06:	83 7d a0 00          	cmpl   $0x0,-0x60(%ebp)
  104e0a:	0f 95 c0             	setne  %al
  104e0d:	0f b6 c0             	movzbl %al,%eax
  104e10:	85 c0                	test   %eax,%eax
  104e12:	74 24                	je     104e38 <default_check+0x166>
  104e14:	c7 44 24 0c fa 6d 10 	movl   $0x106dfa,0xc(%esp)
  104e1b:	00 
  104e1c:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104e23:	00 
  104e24:	c7 44 24 04 5c 01 00 	movl   $0x15c,0x4(%esp)
  104e2b:	00 
  104e2c:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104e33:	e8 b1 b5 ff ff       	call   1003e9 <__panic>

    list_entry_t free_list_store = free_list;
  104e38:	a1 1c af 11 00       	mov    0x11af1c,%eax
  104e3d:	8b 15 20 af 11 00    	mov    0x11af20,%edx
  104e43:	89 45 80             	mov    %eax,-0x80(%ebp)
  104e46:	89 55 84             	mov    %edx,-0x7c(%ebp)
  104e49:	c7 45 d0 1c af 11 00 	movl   $0x11af1c,-0x30(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
  104e50:	8b 45 d0             	mov    -0x30(%ebp),%eax
  104e53:	8b 55 d0             	mov    -0x30(%ebp),%edx
  104e56:	89 50 04             	mov    %edx,0x4(%eax)
  104e59:	8b 45 d0             	mov    -0x30(%ebp),%eax
  104e5c:	8b 50 04             	mov    0x4(%eax),%edx
  104e5f:	8b 45 d0             	mov    -0x30(%ebp),%eax
  104e62:	89 10                	mov    %edx,(%eax)
  104e64:	c7 45 d8 1c af 11 00 	movl   $0x11af1c,-0x28(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
  104e6b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104e6e:	8b 40 04             	mov    0x4(%eax),%eax
  104e71:	39 45 d8             	cmp    %eax,-0x28(%ebp)
  104e74:	0f 94 c0             	sete   %al
  104e77:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
  104e7a:	85 c0                	test   %eax,%eax
  104e7c:	75 24                	jne    104ea2 <default_check+0x1d0>
  104e7e:	c7 44 24 0c 4f 6d 10 	movl   $0x106d4f,0xc(%esp)
  104e85:	00 
  104e86:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104e8d:	00 
  104e8e:	c7 44 24 04 60 01 00 	movl   $0x160,0x4(%esp)
  104e95:	00 
  104e96:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104e9d:	e8 47 b5 ff ff       	call   1003e9 <__panic>
    assert(alloc_page() == NULL);
  104ea2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104ea9:	e8 df db ff ff       	call   102a8d <alloc_pages>
  104eae:	85 c0                	test   %eax,%eax
  104eb0:	74 24                	je     104ed6 <default_check+0x204>
  104eb2:	c7 44 24 0c 66 6d 10 	movl   $0x106d66,0xc(%esp)
  104eb9:	00 
  104eba:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104ec1:	00 
  104ec2:	c7 44 24 04 61 01 00 	movl   $0x161,0x4(%esp)
  104ec9:	00 
  104eca:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104ed1:	e8 13 b5 ff ff       	call   1003e9 <__panic>

    unsigned int nr_free_store = nr_free;
  104ed6:	a1 24 af 11 00       	mov    0x11af24,%eax
  104edb:	89 45 cc             	mov    %eax,-0x34(%ebp)
    nr_free = 0;
  104ede:	c7 05 24 af 11 00 00 	movl   $0x0,0x11af24
  104ee5:	00 00 00 

    free_pages(p0 + 2, 3);
  104ee8:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104eeb:	83 c0 28             	add    $0x28,%eax
  104eee:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
  104ef5:	00 
  104ef6:	89 04 24             	mov    %eax,(%esp)
  104ef9:	e8 c7 db ff ff       	call   102ac5 <free_pages>
    assert(alloc_pages(4) == NULL);
  104efe:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  104f05:	e8 83 db ff ff       	call   102a8d <alloc_pages>
  104f0a:	85 c0                	test   %eax,%eax
  104f0c:	74 24                	je     104f32 <default_check+0x260>
  104f0e:	c7 44 24 0c 0c 6e 10 	movl   $0x106e0c,0xc(%esp)
  104f15:	00 
  104f16:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104f1d:	00 
  104f1e:	c7 44 24 04 67 01 00 	movl   $0x167,0x4(%esp)
  104f25:	00 
  104f26:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104f2d:	e8 b7 b4 ff ff       	call   1003e9 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
  104f32:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104f35:	83 c0 28             	add    $0x28,%eax
  104f38:	83 c0 04             	add    $0x4,%eax
  104f3b:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  104f42:	89 45 9c             	mov    %eax,-0x64(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  104f45:	8b 45 9c             	mov    -0x64(%ebp),%eax
  104f48:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  104f4b:	0f a3 10             	bt     %edx,(%eax)
  104f4e:	19 c0                	sbb    %eax,%eax
  104f50:	89 45 98             	mov    %eax,-0x68(%ebp)
    return oldbit != 0;
  104f53:	83 7d 98 00          	cmpl   $0x0,-0x68(%ebp)
  104f57:	0f 95 c0             	setne  %al
  104f5a:	0f b6 c0             	movzbl %al,%eax
  104f5d:	85 c0                	test   %eax,%eax
  104f5f:	74 0e                	je     104f6f <default_check+0x29d>
  104f61:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104f64:	83 c0 28             	add    $0x28,%eax
  104f67:	8b 40 08             	mov    0x8(%eax),%eax
  104f6a:	83 f8 03             	cmp    $0x3,%eax
  104f6d:	74 24                	je     104f93 <default_check+0x2c1>
  104f6f:	c7 44 24 0c 24 6e 10 	movl   $0x106e24,0xc(%esp)
  104f76:	00 
  104f77:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104f7e:	00 
  104f7f:	c7 44 24 04 68 01 00 	movl   $0x168,0x4(%esp)
  104f86:	00 
  104f87:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104f8e:	e8 56 b4 ff ff       	call   1003e9 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
  104f93:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
  104f9a:	e8 ee da ff ff       	call   102a8d <alloc_pages>
  104f9f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
  104fa2:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
  104fa6:	75 24                	jne    104fcc <default_check+0x2fa>
  104fa8:	c7 44 24 0c 50 6e 10 	movl   $0x106e50,0xc(%esp)
  104faf:	00 
  104fb0:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104fb7:	00 
  104fb8:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
  104fbf:	00 
  104fc0:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104fc7:	e8 1d b4 ff ff       	call   1003e9 <__panic>
    assert(alloc_page() == NULL);
  104fcc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104fd3:	e8 b5 da ff ff       	call   102a8d <alloc_pages>
  104fd8:	85 c0                	test   %eax,%eax
  104fda:	74 24                	je     105000 <default_check+0x32e>
  104fdc:	c7 44 24 0c 66 6d 10 	movl   $0x106d66,0xc(%esp)
  104fe3:	00 
  104fe4:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  104feb:	00 
  104fec:	c7 44 24 04 6a 01 00 	movl   $0x16a,0x4(%esp)
  104ff3:	00 
  104ff4:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  104ffb:	e8 e9 b3 ff ff       	call   1003e9 <__panic>
    assert(p0 + 2 == p1);
  105000:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105003:	83 c0 28             	add    $0x28,%eax
  105006:	3b 45 c4             	cmp    -0x3c(%ebp),%eax
  105009:	74 24                	je     10502f <default_check+0x35d>
  10500b:	c7 44 24 0c 6e 6e 10 	movl   $0x106e6e,0xc(%esp)
  105012:	00 
  105013:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  10501a:	00 
  10501b:	c7 44 24 04 6b 01 00 	movl   $0x16b,0x4(%esp)
  105022:	00 
  105023:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  10502a:	e8 ba b3 ff ff       	call   1003e9 <__panic>

    p2 = p0 + 1;
  10502f:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105032:	83 c0 14             	add    $0x14,%eax
  105035:	89 45 c0             	mov    %eax,-0x40(%ebp)
    free_page(p0);
  105038:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10503f:	00 
  105040:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105043:	89 04 24             	mov    %eax,(%esp)
  105046:	e8 7a da ff ff       	call   102ac5 <free_pages>
    free_pages(p1, 3);
  10504b:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
  105052:	00 
  105053:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  105056:	89 04 24             	mov    %eax,(%esp)
  105059:	e8 67 da ff ff       	call   102ac5 <free_pages>
    assert(PageProperty(p0) && p0->property == 1);
  10505e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105061:	83 c0 04             	add    $0x4,%eax
  105064:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
  10506b:	89 45 94             	mov    %eax,-0x6c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  10506e:	8b 45 94             	mov    -0x6c(%ebp),%eax
  105071:	8b 55 c8             	mov    -0x38(%ebp),%edx
  105074:	0f a3 10             	bt     %edx,(%eax)
  105077:	19 c0                	sbb    %eax,%eax
  105079:	89 45 90             	mov    %eax,-0x70(%ebp)
    return oldbit != 0;
  10507c:	83 7d 90 00          	cmpl   $0x0,-0x70(%ebp)
  105080:	0f 95 c0             	setne  %al
  105083:	0f b6 c0             	movzbl %al,%eax
  105086:	85 c0                	test   %eax,%eax
  105088:	74 0b                	je     105095 <default_check+0x3c3>
  10508a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10508d:	8b 40 08             	mov    0x8(%eax),%eax
  105090:	83 f8 01             	cmp    $0x1,%eax
  105093:	74 24                	je     1050b9 <default_check+0x3e7>
  105095:	c7 44 24 0c 7c 6e 10 	movl   $0x106e7c,0xc(%esp)
  10509c:	00 
  10509d:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  1050a4:	00 
  1050a5:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
  1050ac:	00 
  1050ad:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  1050b4:	e8 30 b3 ff ff       	call   1003e9 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
  1050b9:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  1050bc:	83 c0 04             	add    $0x4,%eax
  1050bf:	c7 45 bc 01 00 00 00 	movl   $0x1,-0x44(%ebp)
  1050c6:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
  1050c9:	8b 45 8c             	mov    -0x74(%ebp),%eax
  1050cc:	8b 55 bc             	mov    -0x44(%ebp),%edx
  1050cf:	0f a3 10             	bt     %edx,(%eax)
  1050d2:	19 c0                	sbb    %eax,%eax
  1050d4:	89 45 88             	mov    %eax,-0x78(%ebp)
    return oldbit != 0;
  1050d7:	83 7d 88 00          	cmpl   $0x0,-0x78(%ebp)
  1050db:	0f 95 c0             	setne  %al
  1050de:	0f b6 c0             	movzbl %al,%eax
  1050e1:	85 c0                	test   %eax,%eax
  1050e3:	74 0b                	je     1050f0 <default_check+0x41e>
  1050e5:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  1050e8:	8b 40 08             	mov    0x8(%eax),%eax
  1050eb:	83 f8 03             	cmp    $0x3,%eax
  1050ee:	74 24                	je     105114 <default_check+0x442>
  1050f0:	c7 44 24 0c a4 6e 10 	movl   $0x106ea4,0xc(%esp)
  1050f7:	00 
  1050f8:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  1050ff:	00 
  105100:	c7 44 24 04 71 01 00 	movl   $0x171,0x4(%esp)
  105107:	00 
  105108:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  10510f:	e8 d5 b2 ff ff       	call   1003e9 <__panic>

    assert((p0 = alloc_page()) == p2 - 1);
  105114:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10511b:	e8 6d d9 ff ff       	call   102a8d <alloc_pages>
  105120:	89 45 dc             	mov    %eax,-0x24(%ebp)
  105123:	8b 45 c0             	mov    -0x40(%ebp),%eax
  105126:	83 e8 14             	sub    $0x14,%eax
  105129:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  10512c:	74 24                	je     105152 <default_check+0x480>
  10512e:	c7 44 24 0c ca 6e 10 	movl   $0x106eca,0xc(%esp)
  105135:	00 
  105136:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  10513d:	00 
  10513e:	c7 44 24 04 73 01 00 	movl   $0x173,0x4(%esp)
  105145:	00 
  105146:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  10514d:	e8 97 b2 ff ff       	call   1003e9 <__panic>
    free_page(p0);
  105152:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105159:	00 
  10515a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10515d:	89 04 24             	mov    %eax,(%esp)
  105160:	e8 60 d9 ff ff       	call   102ac5 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
  105165:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  10516c:	e8 1c d9 ff ff       	call   102a8d <alloc_pages>
  105171:	89 45 dc             	mov    %eax,-0x24(%ebp)
  105174:	8b 45 c0             	mov    -0x40(%ebp),%eax
  105177:	83 c0 14             	add    $0x14,%eax
  10517a:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  10517d:	74 24                	je     1051a3 <default_check+0x4d1>
  10517f:	c7 44 24 0c e8 6e 10 	movl   $0x106ee8,0xc(%esp)
  105186:	00 
  105187:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  10518e:	00 
  10518f:	c7 44 24 04 75 01 00 	movl   $0x175,0x4(%esp)
  105196:	00 
  105197:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  10519e:	e8 46 b2 ff ff       	call   1003e9 <__panic>

    free_pages(p0, 2);
  1051a3:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  1051aa:	00 
  1051ab:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1051ae:	89 04 24             	mov    %eax,(%esp)
  1051b1:	e8 0f d9 ff ff       	call   102ac5 <free_pages>
    free_page(p2);
  1051b6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1051bd:	00 
  1051be:	8b 45 c0             	mov    -0x40(%ebp),%eax
  1051c1:	89 04 24             	mov    %eax,(%esp)
  1051c4:	e8 fc d8 ff ff       	call   102ac5 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
  1051c9:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
  1051d0:	e8 b8 d8 ff ff       	call   102a8d <alloc_pages>
  1051d5:	89 45 dc             	mov    %eax,-0x24(%ebp)
  1051d8:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  1051dc:	75 24                	jne    105202 <default_check+0x530>
  1051de:	c7 44 24 0c 08 6f 10 	movl   $0x106f08,0xc(%esp)
  1051e5:	00 
  1051e6:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  1051ed:	00 
  1051ee:	c7 44 24 04 7a 01 00 	movl   $0x17a,0x4(%esp)
  1051f5:	00 
  1051f6:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  1051fd:	e8 e7 b1 ff ff       	call   1003e9 <__panic>
    assert(alloc_page() == NULL);
  105202:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  105209:	e8 7f d8 ff ff       	call   102a8d <alloc_pages>
  10520e:	85 c0                	test   %eax,%eax
  105210:	74 24                	je     105236 <default_check+0x564>
  105212:	c7 44 24 0c 66 6d 10 	movl   $0x106d66,0xc(%esp)
  105219:	00 
  10521a:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  105221:	00 
  105222:	c7 44 24 04 7b 01 00 	movl   $0x17b,0x4(%esp)
  105229:	00 
  10522a:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  105231:	e8 b3 b1 ff ff       	call   1003e9 <__panic>

    assert(nr_free == 0);
  105236:	a1 24 af 11 00       	mov    0x11af24,%eax
  10523b:	85 c0                	test   %eax,%eax
  10523d:	74 24                	je     105263 <default_check+0x591>
  10523f:	c7 44 24 0c b9 6d 10 	movl   $0x106db9,0xc(%esp)
  105246:	00 
  105247:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  10524e:	00 
  10524f:	c7 44 24 04 7d 01 00 	movl   $0x17d,0x4(%esp)
  105256:	00 
  105257:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  10525e:	e8 86 b1 ff ff       	call   1003e9 <__panic>
    nr_free = nr_free_store;
  105263:	8b 45 cc             	mov    -0x34(%ebp),%eax
  105266:	a3 24 af 11 00       	mov    %eax,0x11af24

    free_list = free_list_store;
  10526b:	8b 45 80             	mov    -0x80(%ebp),%eax
  10526e:	8b 55 84             	mov    -0x7c(%ebp),%edx
  105271:	a3 1c af 11 00       	mov    %eax,0x11af1c
  105276:	89 15 20 af 11 00    	mov    %edx,0x11af20
    free_pages(p0, 5);
  10527c:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
  105283:	00 
  105284:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105287:	89 04 24             	mov    %eax,(%esp)
  10528a:	e8 36 d8 ff ff       	call   102ac5 <free_pages>

    le = &free_list;
  10528f:	c7 45 ec 1c af 11 00 	movl   $0x11af1c,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
  105296:	eb 5a                	jmp    1052f2 <default_check+0x620>
        assert(le->next->prev == le && le->prev->next == le);
  105298:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10529b:	8b 40 04             	mov    0x4(%eax),%eax
  10529e:	8b 00                	mov    (%eax),%eax
  1052a0:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1052a3:	75 0d                	jne    1052b2 <default_check+0x5e0>
  1052a5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1052a8:	8b 00                	mov    (%eax),%eax
  1052aa:	8b 40 04             	mov    0x4(%eax),%eax
  1052ad:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1052b0:	74 24                	je     1052d6 <default_check+0x604>
  1052b2:	c7 44 24 0c 28 6f 10 	movl   $0x106f28,0xc(%esp)
  1052b9:	00 
  1052ba:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  1052c1:	00 
  1052c2:	c7 44 24 04 85 01 00 	movl   $0x185,0x4(%esp)
  1052c9:	00 
  1052ca:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  1052d1:	e8 13 b1 ff ff       	call   1003e9 <__panic>
        struct Page *p = le2page(le, page_link);
  1052d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1052d9:	83 e8 0c             	sub    $0xc,%eax
  1052dc:	89 45 b4             	mov    %eax,-0x4c(%ebp)
        count --, total -= p->property;
  1052df:	ff 4d f4             	decl   -0xc(%ebp)
  1052e2:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1052e5:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  1052e8:	8b 40 08             	mov    0x8(%eax),%eax
  1052eb:	29 c2                	sub    %eax,%edx
  1052ed:	89 d0                	mov    %edx,%eax
  1052ef:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1052f2:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1052f5:	89 45 b8             	mov    %eax,-0x48(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
  1052f8:	8b 45 b8             	mov    -0x48(%ebp),%eax
  1052fb:	8b 40 04             	mov    0x4(%eax),%eax

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
  1052fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
  105301:	81 7d ec 1c af 11 00 	cmpl   $0x11af1c,-0x14(%ebp)
  105308:	75 8e                	jne    105298 <default_check+0x5c6>
        assert(le->next->prev == le && le->prev->next == le);
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
  10530a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10530e:	74 24                	je     105334 <default_check+0x662>
  105310:	c7 44 24 0c 55 6f 10 	movl   $0x106f55,0xc(%esp)
  105317:	00 
  105318:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  10531f:	00 
  105320:	c7 44 24 04 89 01 00 	movl   $0x189,0x4(%esp)
  105327:	00 
  105328:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  10532f:	e8 b5 b0 ff ff       	call   1003e9 <__panic>
    assert(total == 0);
  105334:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  105338:	74 24                	je     10535e <default_check+0x68c>
  10533a:	c7 44 24 0c 60 6f 10 	movl   $0x106f60,0xc(%esp)
  105341:	00 
  105342:	c7 44 24 08 de 6b 10 	movl   $0x106bde,0x8(%esp)
  105349:	00 
  10534a:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
  105351:	00 
  105352:	c7 04 24 f3 6b 10 00 	movl   $0x106bf3,(%esp)
  105359:	e8 8b b0 ff ff       	call   1003e9 <__panic>
}
  10535e:	90                   	nop
  10535f:	c9                   	leave  
  105360:	c3                   	ret    

00105361 <strlen>:
 * @s:      the input string
 *
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
  105361:	55                   	push   %ebp
  105362:	89 e5                	mov    %esp,%ebp
  105364:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
  105367:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (*s ++ != '\0') {
  10536e:	eb 03                	jmp    105373 <strlen+0x12>
        cnt ++;
  105370:	ff 45 fc             	incl   -0x4(%ebp)
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
  105373:	8b 45 08             	mov    0x8(%ebp),%eax
  105376:	8d 50 01             	lea    0x1(%eax),%edx
  105379:	89 55 08             	mov    %edx,0x8(%ebp)
  10537c:	0f b6 00             	movzbl (%eax),%eax
  10537f:	84 c0                	test   %al,%al
  105381:	75 ed                	jne    105370 <strlen+0xf>
        cnt ++;
    }
    return cnt;
  105383:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  105386:	c9                   	leave  
  105387:	c3                   	ret    

00105388 <strnlen>:
 * The return value is strlen(s), if that is less than @len, or
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
  105388:	55                   	push   %ebp
  105389:	89 e5                	mov    %esp,%ebp
  10538b:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
  10538e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (cnt < len && *s ++ != '\0') {
  105395:	eb 03                	jmp    10539a <strnlen+0x12>
        cnt ++;
  105397:	ff 45 fc             	incl   -0x4(%ebp)
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
  10539a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10539d:	3b 45 0c             	cmp    0xc(%ebp),%eax
  1053a0:	73 10                	jae    1053b2 <strnlen+0x2a>
  1053a2:	8b 45 08             	mov    0x8(%ebp),%eax
  1053a5:	8d 50 01             	lea    0x1(%eax),%edx
  1053a8:	89 55 08             	mov    %edx,0x8(%ebp)
  1053ab:	0f b6 00             	movzbl (%eax),%eax
  1053ae:	84 c0                	test   %al,%al
  1053b0:	75 e5                	jne    105397 <strnlen+0xf>
        cnt ++;
    }
    return cnt;
  1053b2:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1053b5:	c9                   	leave  
  1053b6:	c3                   	ret    

001053b7 <strcpy>:
 * To avoid overflows, the size of array pointed by @dst should be long enough to
 * contain the same string as @src (including the terminating null character), and
 * should not overlap in memory with @src.
 * */
char *
strcpy(char *dst, const char *src) {
  1053b7:	55                   	push   %ebp
  1053b8:	89 e5                	mov    %esp,%ebp
  1053ba:	57                   	push   %edi
  1053bb:	56                   	push   %esi
  1053bc:	83 ec 20             	sub    $0x20,%esp
  1053bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1053c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1053c5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1053c8:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCPY
#define __HAVE_ARCH_STRCPY
static inline char *
__strcpy(char *dst, const char *src) {
    int d0, d1, d2;
    asm volatile (
  1053cb:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1053ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1053d1:	89 d1                	mov    %edx,%ecx
  1053d3:	89 c2                	mov    %eax,%edx
  1053d5:	89 ce                	mov    %ecx,%esi
  1053d7:	89 d7                	mov    %edx,%edi
  1053d9:	ac                   	lods   %ds:(%esi),%al
  1053da:	aa                   	stos   %al,%es:(%edi)
  1053db:	84 c0                	test   %al,%al
  1053dd:	75 fa                	jne    1053d9 <strcpy+0x22>
  1053df:	89 fa                	mov    %edi,%edx
  1053e1:	89 f1                	mov    %esi,%ecx
  1053e3:	89 4d ec             	mov    %ecx,-0x14(%ebp)
  1053e6:	89 55 e8             	mov    %edx,-0x18(%ebp)
  1053e9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        "stosb;"
        "testb %%al, %%al;"
        "jne 1b;"
        : "=&S" (d0), "=&D" (d1), "=&a" (d2)
        : "0" (src), "1" (dst) : "memory");
    return dst;
  1053ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
  1053ef:	90                   	nop
    char *p = dst;
    while ((*p ++ = *src ++) != '\0')
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
  1053f0:	83 c4 20             	add    $0x20,%esp
  1053f3:	5e                   	pop    %esi
  1053f4:	5f                   	pop    %edi
  1053f5:	5d                   	pop    %ebp
  1053f6:	c3                   	ret    

001053f7 <strncpy>:
 * @len:    maximum number of characters to be copied from @src
 *
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
  1053f7:	55                   	push   %ebp
  1053f8:	89 e5                	mov    %esp,%ebp
  1053fa:	83 ec 10             	sub    $0x10,%esp
    char *p = dst;
  1053fd:	8b 45 08             	mov    0x8(%ebp),%eax
  105400:	89 45 fc             	mov    %eax,-0x4(%ebp)
    while (len > 0) {
  105403:	eb 1e                	jmp    105423 <strncpy+0x2c>
        if ((*p = *src) != '\0') {
  105405:	8b 45 0c             	mov    0xc(%ebp),%eax
  105408:	0f b6 10             	movzbl (%eax),%edx
  10540b:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10540e:	88 10                	mov    %dl,(%eax)
  105410:	8b 45 fc             	mov    -0x4(%ebp),%eax
  105413:	0f b6 00             	movzbl (%eax),%eax
  105416:	84 c0                	test   %al,%al
  105418:	74 03                	je     10541d <strncpy+0x26>
            src ++;
  10541a:	ff 45 0c             	incl   0xc(%ebp)
        }
        p ++, len --;
  10541d:	ff 45 fc             	incl   -0x4(%ebp)
  105420:	ff 4d 10             	decl   0x10(%ebp)
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
    char *p = dst;
    while (len > 0) {
  105423:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105427:	75 dc                	jne    105405 <strncpy+0xe>
        if ((*p = *src) != '\0') {
            src ++;
        }
        p ++, len --;
    }
    return dst;
  105429:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10542c:	c9                   	leave  
  10542d:	c3                   	ret    

0010542e <strcmp>:
 * - A value greater than zero indicates that the first character that does
 *   not match has a greater value in @s1 than in @s2;
 * - And a value less than zero indicates the opposite.
 * */
int
strcmp(const char *s1, const char *s2) {
  10542e:	55                   	push   %ebp
  10542f:	89 e5                	mov    %esp,%ebp
  105431:	57                   	push   %edi
  105432:	56                   	push   %esi
  105433:	83 ec 20             	sub    $0x20,%esp
  105436:	8b 45 08             	mov    0x8(%ebp),%eax
  105439:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10543c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10543f:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCMP
#define __HAVE_ARCH_STRCMP
static inline int
__strcmp(const char *s1, const char *s2) {
    int d0, d1, ret;
    asm volatile (
  105442:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105445:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105448:	89 d1                	mov    %edx,%ecx
  10544a:	89 c2                	mov    %eax,%edx
  10544c:	89 ce                	mov    %ecx,%esi
  10544e:	89 d7                	mov    %edx,%edi
  105450:	ac                   	lods   %ds:(%esi),%al
  105451:	ae                   	scas   %es:(%edi),%al
  105452:	75 08                	jne    10545c <strcmp+0x2e>
  105454:	84 c0                	test   %al,%al
  105456:	75 f8                	jne    105450 <strcmp+0x22>
  105458:	31 c0                	xor    %eax,%eax
  10545a:	eb 04                	jmp    105460 <strcmp+0x32>
  10545c:	19 c0                	sbb    %eax,%eax
  10545e:	0c 01                	or     $0x1,%al
  105460:	89 fa                	mov    %edi,%edx
  105462:	89 f1                	mov    %esi,%ecx
  105464:	89 45 ec             	mov    %eax,-0x14(%ebp)
  105467:	89 4d e8             	mov    %ecx,-0x18(%ebp)
  10546a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
        "orb $1, %%al;"
        "3:"
        : "=a" (ret), "=&S" (d0), "=&D" (d1)
        : "1" (s1), "2" (s2)
        : "memory");
    return ret;
  10546d:	8b 45 ec             	mov    -0x14(%ebp),%eax
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
  105470:	90                   	nop
    while (*s1 != '\0' && *s1 == *s2) {
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
#endif /* __HAVE_ARCH_STRCMP */
}
  105471:	83 c4 20             	add    $0x20,%esp
  105474:	5e                   	pop    %esi
  105475:	5f                   	pop    %edi
  105476:	5d                   	pop    %ebp
  105477:	c3                   	ret    

00105478 <strncmp>:
 * they are equal to each other, it continues with the following pairs until
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
  105478:	55                   	push   %ebp
  105479:	89 e5                	mov    %esp,%ebp
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
  10547b:	eb 09                	jmp    105486 <strncmp+0xe>
        n --, s1 ++, s2 ++;
  10547d:	ff 4d 10             	decl   0x10(%ebp)
  105480:	ff 45 08             	incl   0x8(%ebp)
  105483:	ff 45 0c             	incl   0xc(%ebp)
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
  105486:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10548a:	74 1a                	je     1054a6 <strncmp+0x2e>
  10548c:	8b 45 08             	mov    0x8(%ebp),%eax
  10548f:	0f b6 00             	movzbl (%eax),%eax
  105492:	84 c0                	test   %al,%al
  105494:	74 10                	je     1054a6 <strncmp+0x2e>
  105496:	8b 45 08             	mov    0x8(%ebp),%eax
  105499:	0f b6 10             	movzbl (%eax),%edx
  10549c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10549f:	0f b6 00             	movzbl (%eax),%eax
  1054a2:	38 c2                	cmp    %al,%dl
  1054a4:	74 d7                	je     10547d <strncmp+0x5>
        n --, s1 ++, s2 ++;
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
  1054a6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1054aa:	74 18                	je     1054c4 <strncmp+0x4c>
  1054ac:	8b 45 08             	mov    0x8(%ebp),%eax
  1054af:	0f b6 00             	movzbl (%eax),%eax
  1054b2:	0f b6 d0             	movzbl %al,%edx
  1054b5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1054b8:	0f b6 00             	movzbl (%eax),%eax
  1054bb:	0f b6 c0             	movzbl %al,%eax
  1054be:	29 c2                	sub    %eax,%edx
  1054c0:	89 d0                	mov    %edx,%eax
  1054c2:	eb 05                	jmp    1054c9 <strncmp+0x51>
  1054c4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1054c9:	5d                   	pop    %ebp
  1054ca:	c3                   	ret    

001054cb <strchr>:
 *
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
  1054cb:	55                   	push   %ebp
  1054cc:	89 e5                	mov    %esp,%ebp
  1054ce:	83 ec 04             	sub    $0x4,%esp
  1054d1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1054d4:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
  1054d7:	eb 13                	jmp    1054ec <strchr+0x21>
        if (*s == c) {
  1054d9:	8b 45 08             	mov    0x8(%ebp),%eax
  1054dc:	0f b6 00             	movzbl (%eax),%eax
  1054df:	3a 45 fc             	cmp    -0x4(%ebp),%al
  1054e2:	75 05                	jne    1054e9 <strchr+0x1e>
            return (char *)s;
  1054e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1054e7:	eb 12                	jmp    1054fb <strchr+0x30>
        }
        s ++;
  1054e9:	ff 45 08             	incl   0x8(%ebp)
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
  1054ec:	8b 45 08             	mov    0x8(%ebp),%eax
  1054ef:	0f b6 00             	movzbl (%eax),%eax
  1054f2:	84 c0                	test   %al,%al
  1054f4:	75 e3                	jne    1054d9 <strchr+0xe>
        if (*s == c) {
            return (char *)s;
        }
        s ++;
    }
    return NULL;
  1054f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1054fb:	c9                   	leave  
  1054fc:	c3                   	ret    

001054fd <strfind>:
 * The strfind() function is like strchr() except that if @c is
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
  1054fd:	55                   	push   %ebp
  1054fe:	89 e5                	mov    %esp,%ebp
  105500:	83 ec 04             	sub    $0x4,%esp
  105503:	8b 45 0c             	mov    0xc(%ebp),%eax
  105506:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
  105509:	eb 0e                	jmp    105519 <strfind+0x1c>
        if (*s == c) {
  10550b:	8b 45 08             	mov    0x8(%ebp),%eax
  10550e:	0f b6 00             	movzbl (%eax),%eax
  105511:	3a 45 fc             	cmp    -0x4(%ebp),%al
  105514:	74 0f                	je     105525 <strfind+0x28>
            break;
        }
        s ++;
  105516:	ff 45 08             	incl   0x8(%ebp)
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
    while (*s != '\0') {
  105519:	8b 45 08             	mov    0x8(%ebp),%eax
  10551c:	0f b6 00             	movzbl (%eax),%eax
  10551f:	84 c0                	test   %al,%al
  105521:	75 e8                	jne    10550b <strfind+0xe>
  105523:	eb 01                	jmp    105526 <strfind+0x29>
        if (*s == c) {
            break;
  105525:	90                   	nop
        }
        s ++;
    }
    return (char *)s;
  105526:	8b 45 08             	mov    0x8(%ebp),%eax
}
  105529:	c9                   	leave  
  10552a:	c3                   	ret    

0010552b <strtol>:
 * an optional "0x" or "0X" prefix.
 *
 * The strtol() function returns the converted integral number as a long int value.
 * */
long
strtol(const char *s, char **endptr, int base) {
  10552b:	55                   	push   %ebp
  10552c:	89 e5                	mov    %esp,%ebp
  10552e:	83 ec 10             	sub    $0x10,%esp
    int neg = 0;
  105531:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    long val = 0;
  105538:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
  10553f:	eb 03                	jmp    105544 <strtol+0x19>
        s ++;
  105541:	ff 45 08             	incl   0x8(%ebp)
strtol(const char *s, char **endptr, int base) {
    int neg = 0;
    long val = 0;

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
  105544:	8b 45 08             	mov    0x8(%ebp),%eax
  105547:	0f b6 00             	movzbl (%eax),%eax
  10554a:	3c 20                	cmp    $0x20,%al
  10554c:	74 f3                	je     105541 <strtol+0x16>
  10554e:	8b 45 08             	mov    0x8(%ebp),%eax
  105551:	0f b6 00             	movzbl (%eax),%eax
  105554:	3c 09                	cmp    $0x9,%al
  105556:	74 e9                	je     105541 <strtol+0x16>
        s ++;
    }

    // plus/minus sign
    if (*s == '+') {
  105558:	8b 45 08             	mov    0x8(%ebp),%eax
  10555b:	0f b6 00             	movzbl (%eax),%eax
  10555e:	3c 2b                	cmp    $0x2b,%al
  105560:	75 05                	jne    105567 <strtol+0x3c>
        s ++;
  105562:	ff 45 08             	incl   0x8(%ebp)
  105565:	eb 14                	jmp    10557b <strtol+0x50>
    }
    else if (*s == '-') {
  105567:	8b 45 08             	mov    0x8(%ebp),%eax
  10556a:	0f b6 00             	movzbl (%eax),%eax
  10556d:	3c 2d                	cmp    $0x2d,%al
  10556f:	75 0a                	jne    10557b <strtol+0x50>
        s ++, neg = 1;
  105571:	ff 45 08             	incl   0x8(%ebp)
  105574:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)
    }

    // hex or octal base prefix
    if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x')) {
  10557b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10557f:	74 06                	je     105587 <strtol+0x5c>
  105581:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
  105585:	75 22                	jne    1055a9 <strtol+0x7e>
  105587:	8b 45 08             	mov    0x8(%ebp),%eax
  10558a:	0f b6 00             	movzbl (%eax),%eax
  10558d:	3c 30                	cmp    $0x30,%al
  10558f:	75 18                	jne    1055a9 <strtol+0x7e>
  105591:	8b 45 08             	mov    0x8(%ebp),%eax
  105594:	40                   	inc    %eax
  105595:	0f b6 00             	movzbl (%eax),%eax
  105598:	3c 78                	cmp    $0x78,%al
  10559a:	75 0d                	jne    1055a9 <strtol+0x7e>
        s += 2, base = 16;
  10559c:	83 45 08 02          	addl   $0x2,0x8(%ebp)
  1055a0:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
  1055a7:	eb 29                	jmp    1055d2 <strtol+0xa7>
    }
    else if (base == 0 && s[0] == '0') {
  1055a9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1055ad:	75 16                	jne    1055c5 <strtol+0x9a>
  1055af:	8b 45 08             	mov    0x8(%ebp),%eax
  1055b2:	0f b6 00             	movzbl (%eax),%eax
  1055b5:	3c 30                	cmp    $0x30,%al
  1055b7:	75 0c                	jne    1055c5 <strtol+0x9a>
        s ++, base = 8;
  1055b9:	ff 45 08             	incl   0x8(%ebp)
  1055bc:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
  1055c3:	eb 0d                	jmp    1055d2 <strtol+0xa7>
    }
    else if (base == 0) {
  1055c5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1055c9:	75 07                	jne    1055d2 <strtol+0xa7>
        base = 10;
  1055cb:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

    // digits
    while (1) {
        int dig;

        if (*s >= '0' && *s <= '9') {
  1055d2:	8b 45 08             	mov    0x8(%ebp),%eax
  1055d5:	0f b6 00             	movzbl (%eax),%eax
  1055d8:	3c 2f                	cmp    $0x2f,%al
  1055da:	7e 1b                	jle    1055f7 <strtol+0xcc>
  1055dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1055df:	0f b6 00             	movzbl (%eax),%eax
  1055e2:	3c 39                	cmp    $0x39,%al
  1055e4:	7f 11                	jg     1055f7 <strtol+0xcc>
            dig = *s - '0';
  1055e6:	8b 45 08             	mov    0x8(%ebp),%eax
  1055e9:	0f b6 00             	movzbl (%eax),%eax
  1055ec:	0f be c0             	movsbl %al,%eax
  1055ef:	83 e8 30             	sub    $0x30,%eax
  1055f2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1055f5:	eb 48                	jmp    10563f <strtol+0x114>
        }
        else if (*s >= 'a' && *s <= 'z') {
  1055f7:	8b 45 08             	mov    0x8(%ebp),%eax
  1055fa:	0f b6 00             	movzbl (%eax),%eax
  1055fd:	3c 60                	cmp    $0x60,%al
  1055ff:	7e 1b                	jle    10561c <strtol+0xf1>
  105601:	8b 45 08             	mov    0x8(%ebp),%eax
  105604:	0f b6 00             	movzbl (%eax),%eax
  105607:	3c 7a                	cmp    $0x7a,%al
  105609:	7f 11                	jg     10561c <strtol+0xf1>
            dig = *s - 'a' + 10;
  10560b:	8b 45 08             	mov    0x8(%ebp),%eax
  10560e:	0f b6 00             	movzbl (%eax),%eax
  105611:	0f be c0             	movsbl %al,%eax
  105614:	83 e8 57             	sub    $0x57,%eax
  105617:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10561a:	eb 23                	jmp    10563f <strtol+0x114>
        }
        else if (*s >= 'A' && *s <= 'Z') {
  10561c:	8b 45 08             	mov    0x8(%ebp),%eax
  10561f:	0f b6 00             	movzbl (%eax),%eax
  105622:	3c 40                	cmp    $0x40,%al
  105624:	7e 3b                	jle    105661 <strtol+0x136>
  105626:	8b 45 08             	mov    0x8(%ebp),%eax
  105629:	0f b6 00             	movzbl (%eax),%eax
  10562c:	3c 5a                	cmp    $0x5a,%al
  10562e:	7f 31                	jg     105661 <strtol+0x136>
            dig = *s - 'A' + 10;
  105630:	8b 45 08             	mov    0x8(%ebp),%eax
  105633:	0f b6 00             	movzbl (%eax),%eax
  105636:	0f be c0             	movsbl %al,%eax
  105639:	83 e8 37             	sub    $0x37,%eax
  10563c:	89 45 f4             	mov    %eax,-0xc(%ebp)
        }
        else {
            break;
        }
        if (dig >= base) {
  10563f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105642:	3b 45 10             	cmp    0x10(%ebp),%eax
  105645:	7d 19                	jge    105660 <strtol+0x135>
            break;
        }
        s ++, val = (val * base) + dig;
  105647:	ff 45 08             	incl   0x8(%ebp)
  10564a:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10564d:	0f af 45 10          	imul   0x10(%ebp),%eax
  105651:	89 c2                	mov    %eax,%edx
  105653:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105656:	01 d0                	add    %edx,%eax
  105658:	89 45 f8             	mov    %eax,-0x8(%ebp)
        // we don't properly detect overflow!
    }
  10565b:	e9 72 ff ff ff       	jmp    1055d2 <strtol+0xa7>
        }
        else {
            break;
        }
        if (dig >= base) {
            break;
  105660:	90                   	nop
        }
        s ++, val = (val * base) + dig;
        // we don't properly detect overflow!
    }

    if (endptr) {
  105661:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  105665:	74 08                	je     10566f <strtol+0x144>
        *endptr = (char *) s;
  105667:	8b 45 0c             	mov    0xc(%ebp),%eax
  10566a:	8b 55 08             	mov    0x8(%ebp),%edx
  10566d:	89 10                	mov    %edx,(%eax)
    }
    return (neg ? -val : val);
  10566f:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
  105673:	74 07                	je     10567c <strtol+0x151>
  105675:	8b 45 f8             	mov    -0x8(%ebp),%eax
  105678:	f7 d8                	neg    %eax
  10567a:	eb 03                	jmp    10567f <strtol+0x154>
  10567c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  10567f:	c9                   	leave  
  105680:	c3                   	ret    

00105681 <memset>:
 * @n:      number of bytes to be set to the value
 *
 * The memset() function returns @s.
 * */
void *
memset(void *s, char c, size_t n) {
  105681:	55                   	push   %ebp
  105682:	89 e5                	mov    %esp,%ebp
  105684:	57                   	push   %edi
  105685:	83 ec 24             	sub    $0x24,%esp
  105688:	8b 45 0c             	mov    0xc(%ebp),%eax
  10568b:	88 45 d8             	mov    %al,-0x28(%ebp)
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
  10568e:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  105692:	8b 55 08             	mov    0x8(%ebp),%edx
  105695:	89 55 f8             	mov    %edx,-0x8(%ebp)
  105698:	88 45 f7             	mov    %al,-0x9(%ebp)
  10569b:	8b 45 10             	mov    0x10(%ebp),%eax
  10569e:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_MEMSET
#define __HAVE_ARCH_MEMSET
static inline void *
__memset(void *s, char c, size_t n) {
    int d0, d1;
    asm volatile (
  1056a1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  1056a4:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  1056a8:	8b 55 f8             	mov    -0x8(%ebp),%edx
  1056ab:	89 d7                	mov    %edx,%edi
  1056ad:	f3 aa                	rep stos %al,%es:(%edi)
  1056af:	89 fa                	mov    %edi,%edx
  1056b1:	89 4d ec             	mov    %ecx,-0x14(%ebp)
  1056b4:	89 55 e8             	mov    %edx,-0x18(%ebp)
        "rep; stosb;"
        : "=&c" (d0), "=&D" (d1)
        : "0" (n), "a" (c), "1" (s)
        : "memory");
    return s;
  1056b7:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1056ba:	90                   	nop
    while (n -- > 0) {
        *p ++ = c;
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
  1056bb:	83 c4 24             	add    $0x24,%esp
  1056be:	5f                   	pop    %edi
  1056bf:	5d                   	pop    %ebp
  1056c0:	c3                   	ret    

001056c1 <memmove>:
 * @n:      number of bytes to copy
 *
 * The memmove() function returns @dst.
 * */
void *
memmove(void *dst, const void *src, size_t n) {
  1056c1:	55                   	push   %ebp
  1056c2:	89 e5                	mov    %esp,%ebp
  1056c4:	57                   	push   %edi
  1056c5:	56                   	push   %esi
  1056c6:	53                   	push   %ebx
  1056c7:	83 ec 30             	sub    $0x30,%esp
  1056ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1056cd:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1056d0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1056d3:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1056d6:	8b 45 10             	mov    0x10(%ebp),%eax
  1056d9:	89 45 e8             	mov    %eax,-0x18(%ebp)

#ifndef __HAVE_ARCH_MEMMOVE
#define __HAVE_ARCH_MEMMOVE
static inline void *
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
  1056dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1056df:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1056e2:	73 42                	jae    105726 <memmove+0x65>
  1056e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1056e7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1056ea:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1056ed:	89 45 e0             	mov    %eax,-0x20(%ebp)
  1056f0:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1056f3:	89 45 dc             	mov    %eax,-0x24(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
  1056f6:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1056f9:	c1 e8 02             	shr    $0x2,%eax
  1056fc:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
  1056fe:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  105701:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105704:	89 d7                	mov    %edx,%edi
  105706:	89 c6                	mov    %eax,%esi
  105708:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  10570a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  10570d:	83 e1 03             	and    $0x3,%ecx
  105710:	74 02                	je     105714 <memmove+0x53>
  105712:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  105714:	89 f0                	mov    %esi,%eax
  105716:	89 fa                	mov    %edi,%edx
  105718:	89 4d d8             	mov    %ecx,-0x28(%ebp)
  10571b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  10571e:	89 45 d0             	mov    %eax,-0x30(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
  105721:	8b 45 e4             	mov    -0x1c(%ebp),%eax
#ifdef __HAVE_ARCH_MEMMOVE
    return __memmove(dst, src, n);
  105724:	eb 36                	jmp    10575c <memmove+0x9b>
    asm volatile (
        "std;"
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
  105726:	8b 45 e8             	mov    -0x18(%ebp),%eax
  105729:	8d 50 ff             	lea    -0x1(%eax),%edx
  10572c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10572f:	01 c2                	add    %eax,%edx
  105731:	8b 45 e8             	mov    -0x18(%ebp),%eax
  105734:	8d 48 ff             	lea    -0x1(%eax),%ecx
  105737:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10573a:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
        return __memcpy(dst, src, n);
    }
    int d0, d1, d2;
    asm volatile (
  10573d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  105740:	89 c1                	mov    %eax,%ecx
  105742:	89 d8                	mov    %ebx,%eax
  105744:	89 d6                	mov    %edx,%esi
  105746:	89 c7                	mov    %eax,%edi
  105748:	fd                   	std    
  105749:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  10574b:	fc                   	cld    
  10574c:	89 f8                	mov    %edi,%eax
  10574e:	89 f2                	mov    %esi,%edx
  105750:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  105753:	89 55 c8             	mov    %edx,-0x38(%ebp)
  105756:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
        : "memory");
    return dst;
  105759:	8b 45 f0             	mov    -0x10(%ebp),%eax
            *d ++ = *s ++;
        }
    }
    return dst;
#endif /* __HAVE_ARCH_MEMMOVE */
}
  10575c:	83 c4 30             	add    $0x30,%esp
  10575f:	5b                   	pop    %ebx
  105760:	5e                   	pop    %esi
  105761:	5f                   	pop    %edi
  105762:	5d                   	pop    %ebp
  105763:	c3                   	ret    

00105764 <memcpy>:
 * it always copies exactly @n bytes. To avoid overflows, the size of arrays pointed
 * by both @src and @dst, should be at least @n bytes, and should not overlap
 * (for overlapping memory area, memmove is a safer approach).
 * */
void *
memcpy(void *dst, const void *src, size_t n) {
  105764:	55                   	push   %ebp
  105765:	89 e5                	mov    %esp,%ebp
  105767:	57                   	push   %edi
  105768:	56                   	push   %esi
  105769:	83 ec 20             	sub    $0x20,%esp
  10576c:	8b 45 08             	mov    0x8(%ebp),%eax
  10576f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  105772:	8b 45 0c             	mov    0xc(%ebp),%eax
  105775:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105778:	8b 45 10             	mov    0x10(%ebp),%eax
  10577b:	89 45 ec             	mov    %eax,-0x14(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
  10577e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105781:	c1 e8 02             	shr    $0x2,%eax
  105784:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
  105786:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105789:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10578c:	89 d7                	mov    %edx,%edi
  10578e:	89 c6                	mov    %eax,%esi
  105790:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  105792:	8b 4d ec             	mov    -0x14(%ebp),%ecx
  105795:	83 e1 03             	and    $0x3,%ecx
  105798:	74 02                	je     10579c <memcpy+0x38>
  10579a:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  10579c:	89 f0                	mov    %esi,%eax
  10579e:	89 fa                	mov    %edi,%edx
  1057a0:	89 4d e8             	mov    %ecx,-0x18(%ebp)
  1057a3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  1057a6:	89 45 e0             	mov    %eax,-0x20(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
  1057a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
  1057ac:	90                   	nop
    while (n -- > 0) {
        *d ++ = *s ++;
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
  1057ad:	83 c4 20             	add    $0x20,%esp
  1057b0:	5e                   	pop    %esi
  1057b1:	5f                   	pop    %edi
  1057b2:	5d                   	pop    %ebp
  1057b3:	c3                   	ret    

001057b4 <memcmp>:
 *   match in both memory blocks has a greater value in @v1 than in @v2
 *   as if evaluated as unsigned char values;
 * - And a value less than zero indicates the opposite.
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
  1057b4:	55                   	push   %ebp
  1057b5:	89 e5                	mov    %esp,%ebp
  1057b7:	83 ec 10             	sub    $0x10,%esp
    const char *s1 = (const char *)v1;
  1057ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1057bd:	89 45 fc             	mov    %eax,-0x4(%ebp)
    const char *s2 = (const char *)v2;
  1057c0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1057c3:	89 45 f8             	mov    %eax,-0x8(%ebp)
    while (n -- > 0) {
  1057c6:	eb 2e                	jmp    1057f6 <memcmp+0x42>
        if (*s1 != *s2) {
  1057c8:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1057cb:	0f b6 10             	movzbl (%eax),%edx
  1057ce:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1057d1:	0f b6 00             	movzbl (%eax),%eax
  1057d4:	38 c2                	cmp    %al,%dl
  1057d6:	74 18                	je     1057f0 <memcmp+0x3c>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
  1057d8:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1057db:	0f b6 00             	movzbl (%eax),%eax
  1057de:	0f b6 d0             	movzbl %al,%edx
  1057e1:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1057e4:	0f b6 00             	movzbl (%eax),%eax
  1057e7:	0f b6 c0             	movzbl %al,%eax
  1057ea:	29 c2                	sub    %eax,%edx
  1057ec:	89 d0                	mov    %edx,%eax
  1057ee:	eb 18                	jmp    105808 <memcmp+0x54>
        }
        s1 ++, s2 ++;
  1057f0:	ff 45 fc             	incl   -0x4(%ebp)
  1057f3:	ff 45 f8             	incl   -0x8(%ebp)
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
  1057f6:	8b 45 10             	mov    0x10(%ebp),%eax
  1057f9:	8d 50 ff             	lea    -0x1(%eax),%edx
  1057fc:	89 55 10             	mov    %edx,0x10(%ebp)
  1057ff:	85 c0                	test   %eax,%eax
  105801:	75 c5                	jne    1057c8 <memcmp+0x14>
        if (*s1 != *s2) {
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
    }
    return 0;
  105803:	b8 00 00 00 00       	mov    $0x0,%eax
}
  105808:	c9                   	leave  
  105809:	c3                   	ret    

0010580a <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
  10580a:	55                   	push   %ebp
  10580b:	89 e5                	mov    %esp,%ebp
  10580d:	83 ec 58             	sub    $0x58,%esp
  105810:	8b 45 10             	mov    0x10(%ebp),%eax
  105813:	89 45 d0             	mov    %eax,-0x30(%ebp)
  105816:	8b 45 14             	mov    0x14(%ebp),%eax
  105819:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    unsigned long long result = num;
  10581c:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10581f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  105822:	89 45 e8             	mov    %eax,-0x18(%ebp)
  105825:	89 55 ec             	mov    %edx,-0x14(%ebp)
    unsigned mod = do_div(result, base);
  105828:	8b 45 18             	mov    0x18(%ebp),%eax
  10582b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  10582e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  105831:	8b 55 ec             	mov    -0x14(%ebp),%edx
  105834:	89 45 e0             	mov    %eax,-0x20(%ebp)
  105837:	89 55 f0             	mov    %edx,-0x10(%ebp)
  10583a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10583d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  105840:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  105844:	74 1c                	je     105862 <printnum+0x58>
  105846:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105849:	ba 00 00 00 00       	mov    $0x0,%edx
  10584e:	f7 75 e4             	divl   -0x1c(%ebp)
  105851:	89 55 f4             	mov    %edx,-0xc(%ebp)
  105854:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105857:	ba 00 00 00 00       	mov    $0x0,%edx
  10585c:	f7 75 e4             	divl   -0x1c(%ebp)
  10585f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105862:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105865:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105868:	f7 75 e4             	divl   -0x1c(%ebp)
  10586b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  10586e:	89 55 dc             	mov    %edx,-0x24(%ebp)
  105871:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105874:	8b 55 f0             	mov    -0x10(%ebp),%edx
  105877:	89 45 e8             	mov    %eax,-0x18(%ebp)
  10587a:	89 55 ec             	mov    %edx,-0x14(%ebp)
  10587d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105880:	89 45 d8             	mov    %eax,-0x28(%ebp)

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
  105883:	8b 45 18             	mov    0x18(%ebp),%eax
  105886:	ba 00 00 00 00       	mov    $0x0,%edx
  10588b:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  10588e:	77 56                	ja     1058e6 <printnum+0xdc>
  105890:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
  105893:	72 05                	jb     10589a <printnum+0x90>
  105895:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  105898:	77 4c                	ja     1058e6 <printnum+0xdc>
        printnum(putch, putdat, result, base, width - 1, padc);
  10589a:	8b 45 1c             	mov    0x1c(%ebp),%eax
  10589d:	8d 50 ff             	lea    -0x1(%eax),%edx
  1058a0:	8b 45 20             	mov    0x20(%ebp),%eax
  1058a3:	89 44 24 18          	mov    %eax,0x18(%esp)
  1058a7:	89 54 24 14          	mov    %edx,0x14(%esp)
  1058ab:	8b 45 18             	mov    0x18(%ebp),%eax
  1058ae:	89 44 24 10          	mov    %eax,0x10(%esp)
  1058b2:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1058b5:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1058b8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1058bc:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1058c0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1058c3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1058c7:	8b 45 08             	mov    0x8(%ebp),%eax
  1058ca:	89 04 24             	mov    %eax,(%esp)
  1058cd:	e8 38 ff ff ff       	call   10580a <printnum>
  1058d2:	eb 1b                	jmp    1058ef <printnum+0xe5>
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
            putch(padc, putdat);
  1058d4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1058d7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1058db:	8b 45 20             	mov    0x20(%ebp),%eax
  1058de:	89 04 24             	mov    %eax,(%esp)
  1058e1:	8b 45 08             	mov    0x8(%ebp),%eax
  1058e4:	ff d0                	call   *%eax
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  1058e6:	ff 4d 1c             	decl   0x1c(%ebp)
  1058e9:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
  1058ed:	7f e5                	jg     1058d4 <printnum+0xca>
            putch(padc, putdat);
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  1058ef:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1058f2:	05 1c 70 10 00       	add    $0x10701c,%eax
  1058f7:	0f b6 00             	movzbl (%eax),%eax
  1058fa:	0f be c0             	movsbl %al,%eax
  1058fd:	8b 55 0c             	mov    0xc(%ebp),%edx
  105900:	89 54 24 04          	mov    %edx,0x4(%esp)
  105904:	89 04 24             	mov    %eax,(%esp)
  105907:	8b 45 08             	mov    0x8(%ebp),%eax
  10590a:	ff d0                	call   *%eax
}
  10590c:	90                   	nop
  10590d:	c9                   	leave  
  10590e:	c3                   	ret    

0010590f <getuint>:
 * getuint - get an unsigned int of various possible sizes from a varargs list
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static unsigned long long
getuint(va_list *ap, int lflag) {
  10590f:	55                   	push   %ebp
  105910:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
  105912:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  105916:	7e 14                	jle    10592c <getuint+0x1d>
        return va_arg(*ap, unsigned long long);
  105918:	8b 45 08             	mov    0x8(%ebp),%eax
  10591b:	8b 00                	mov    (%eax),%eax
  10591d:	8d 48 08             	lea    0x8(%eax),%ecx
  105920:	8b 55 08             	mov    0x8(%ebp),%edx
  105923:	89 0a                	mov    %ecx,(%edx)
  105925:	8b 50 04             	mov    0x4(%eax),%edx
  105928:	8b 00                	mov    (%eax),%eax
  10592a:	eb 30                	jmp    10595c <getuint+0x4d>
    }
    else if (lflag) {
  10592c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  105930:	74 16                	je     105948 <getuint+0x39>
        return va_arg(*ap, unsigned long);
  105932:	8b 45 08             	mov    0x8(%ebp),%eax
  105935:	8b 00                	mov    (%eax),%eax
  105937:	8d 48 04             	lea    0x4(%eax),%ecx
  10593a:	8b 55 08             	mov    0x8(%ebp),%edx
  10593d:	89 0a                	mov    %ecx,(%edx)
  10593f:	8b 00                	mov    (%eax),%eax
  105941:	ba 00 00 00 00       	mov    $0x0,%edx
  105946:	eb 14                	jmp    10595c <getuint+0x4d>
    }
    else {
        return va_arg(*ap, unsigned int);
  105948:	8b 45 08             	mov    0x8(%ebp),%eax
  10594b:	8b 00                	mov    (%eax),%eax
  10594d:	8d 48 04             	lea    0x4(%eax),%ecx
  105950:	8b 55 08             	mov    0x8(%ebp),%edx
  105953:	89 0a                	mov    %ecx,(%edx)
  105955:	8b 00                	mov    (%eax),%eax
  105957:	ba 00 00 00 00       	mov    $0x0,%edx
    }
}
  10595c:	5d                   	pop    %ebp
  10595d:	c3                   	ret    

0010595e <getint>:
 * getint - same as getuint but signed, we can't use getuint because of sign extension
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static long long
getint(va_list *ap, int lflag) {
  10595e:	55                   	push   %ebp
  10595f:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
  105961:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  105965:	7e 14                	jle    10597b <getint+0x1d>
        return va_arg(*ap, long long);
  105967:	8b 45 08             	mov    0x8(%ebp),%eax
  10596a:	8b 00                	mov    (%eax),%eax
  10596c:	8d 48 08             	lea    0x8(%eax),%ecx
  10596f:	8b 55 08             	mov    0x8(%ebp),%edx
  105972:	89 0a                	mov    %ecx,(%edx)
  105974:	8b 50 04             	mov    0x4(%eax),%edx
  105977:	8b 00                	mov    (%eax),%eax
  105979:	eb 28                	jmp    1059a3 <getint+0x45>
    }
    else if (lflag) {
  10597b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  10597f:	74 12                	je     105993 <getint+0x35>
        return va_arg(*ap, long);
  105981:	8b 45 08             	mov    0x8(%ebp),%eax
  105984:	8b 00                	mov    (%eax),%eax
  105986:	8d 48 04             	lea    0x4(%eax),%ecx
  105989:	8b 55 08             	mov    0x8(%ebp),%edx
  10598c:	89 0a                	mov    %ecx,(%edx)
  10598e:	8b 00                	mov    (%eax),%eax
  105990:	99                   	cltd   
  105991:	eb 10                	jmp    1059a3 <getint+0x45>
    }
    else {
        return va_arg(*ap, int);
  105993:	8b 45 08             	mov    0x8(%ebp),%eax
  105996:	8b 00                	mov    (%eax),%eax
  105998:	8d 48 04             	lea    0x4(%eax),%ecx
  10599b:	8b 55 08             	mov    0x8(%ebp),%edx
  10599e:	89 0a                	mov    %ecx,(%edx)
  1059a0:	8b 00                	mov    (%eax),%eax
  1059a2:	99                   	cltd   
    }
}
  1059a3:	5d                   	pop    %ebp
  1059a4:	c3                   	ret    

001059a5 <printfmt>:
 * @putch:      specified putch function, print a single character
 * @putdat:     used by @putch function
 * @fmt:        the format string to use
 * */
void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  1059a5:	55                   	push   %ebp
  1059a6:	89 e5                	mov    %esp,%ebp
  1059a8:	83 ec 28             	sub    $0x28,%esp
    va_list ap;

    va_start(ap, fmt);
  1059ab:	8d 45 14             	lea    0x14(%ebp),%eax
  1059ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
    vprintfmt(putch, putdat, fmt, ap);
  1059b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1059b4:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1059b8:	8b 45 10             	mov    0x10(%ebp),%eax
  1059bb:	89 44 24 08          	mov    %eax,0x8(%esp)
  1059bf:	8b 45 0c             	mov    0xc(%ebp),%eax
  1059c2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1059c6:	8b 45 08             	mov    0x8(%ebp),%eax
  1059c9:	89 04 24             	mov    %eax,(%esp)
  1059cc:	e8 03 00 00 00       	call   1059d4 <vprintfmt>
    va_end(ap);
}
  1059d1:	90                   	nop
  1059d2:	c9                   	leave  
  1059d3:	c3                   	ret    

001059d4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  1059d4:	55                   	push   %ebp
  1059d5:	89 e5                	mov    %esp,%ebp
  1059d7:	56                   	push   %esi
  1059d8:	53                   	push   %ebx
  1059d9:	83 ec 40             	sub    $0x40,%esp
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  1059dc:	eb 17                	jmp    1059f5 <vprintfmt+0x21>
            if (ch == '\0') {
  1059de:	85 db                	test   %ebx,%ebx
  1059e0:	0f 84 bf 03 00 00    	je     105da5 <vprintfmt+0x3d1>
                return;
            }
            putch(ch, putdat);
  1059e6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1059e9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1059ed:	89 1c 24             	mov    %ebx,(%esp)
  1059f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1059f3:	ff d0                	call   *%eax
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  1059f5:	8b 45 10             	mov    0x10(%ebp),%eax
  1059f8:	8d 50 01             	lea    0x1(%eax),%edx
  1059fb:	89 55 10             	mov    %edx,0x10(%ebp)
  1059fe:	0f b6 00             	movzbl (%eax),%eax
  105a01:	0f b6 d8             	movzbl %al,%ebx
  105a04:	83 fb 25             	cmp    $0x25,%ebx
  105a07:	75 d5                	jne    1059de <vprintfmt+0xa>
            }
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
  105a09:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
        width = precision = -1;
  105a0d:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  105a14:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105a17:	89 45 e8             	mov    %eax,-0x18(%ebp)
        lflag = altflag = 0;
  105a1a:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  105a21:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105a24:	89 45 e0             	mov    %eax,-0x20(%ebp)

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
  105a27:	8b 45 10             	mov    0x10(%ebp),%eax
  105a2a:	8d 50 01             	lea    0x1(%eax),%edx
  105a2d:	89 55 10             	mov    %edx,0x10(%ebp)
  105a30:	0f b6 00             	movzbl (%eax),%eax
  105a33:	0f b6 d8             	movzbl %al,%ebx
  105a36:	8d 43 dd             	lea    -0x23(%ebx),%eax
  105a39:	83 f8 55             	cmp    $0x55,%eax
  105a3c:	0f 87 37 03 00 00    	ja     105d79 <vprintfmt+0x3a5>
  105a42:	8b 04 85 40 70 10 00 	mov    0x107040(,%eax,4),%eax
  105a49:	ff e0                	jmp    *%eax

        // flag to pad on the right
        case '-':
            padc = '-';
  105a4b:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
            goto reswitch;
  105a4f:	eb d6                	jmp    105a27 <vprintfmt+0x53>

        // flag to pad with 0's instead of spaces
        case '0':
            padc = '0';
  105a51:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
            goto reswitch;
  105a55:	eb d0                	jmp    105a27 <vprintfmt+0x53>

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
  105a57:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
                precision = precision * 10 + ch - '0';
  105a5e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  105a61:	89 d0                	mov    %edx,%eax
  105a63:	c1 e0 02             	shl    $0x2,%eax
  105a66:	01 d0                	add    %edx,%eax
  105a68:	01 c0                	add    %eax,%eax
  105a6a:	01 d8                	add    %ebx,%eax
  105a6c:	83 e8 30             	sub    $0x30,%eax
  105a6f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
                ch = *fmt;
  105a72:	8b 45 10             	mov    0x10(%ebp),%eax
  105a75:	0f b6 00             	movzbl (%eax),%eax
  105a78:	0f be d8             	movsbl %al,%ebx
                if (ch < '0' || ch > '9') {
  105a7b:	83 fb 2f             	cmp    $0x2f,%ebx
  105a7e:	7e 38                	jle    105ab8 <vprintfmt+0xe4>
  105a80:	83 fb 39             	cmp    $0x39,%ebx
  105a83:	7f 33                	jg     105ab8 <vprintfmt+0xe4>
            padc = '0';
            goto reswitch;

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
  105a85:	ff 45 10             	incl   0x10(%ebp)
                precision = precision * 10 + ch - '0';
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
  105a88:	eb d4                	jmp    105a5e <vprintfmt+0x8a>
            goto process_precision;

        case '*':
            precision = va_arg(ap, int);
  105a8a:	8b 45 14             	mov    0x14(%ebp),%eax
  105a8d:	8d 50 04             	lea    0x4(%eax),%edx
  105a90:	89 55 14             	mov    %edx,0x14(%ebp)
  105a93:	8b 00                	mov    (%eax),%eax
  105a95:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            goto process_precision;
  105a98:	eb 1f                	jmp    105ab9 <vprintfmt+0xe5>

        case '.':
            if (width < 0)
  105a9a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  105a9e:	79 87                	jns    105a27 <vprintfmt+0x53>
                width = 0;
  105aa0:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
            goto reswitch;
  105aa7:	e9 7b ff ff ff       	jmp    105a27 <vprintfmt+0x53>

        case '#':
            altflag = 1;
  105aac:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
            goto reswitch;
  105ab3:	e9 6f ff ff ff       	jmp    105a27 <vprintfmt+0x53>
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
            goto process_precision;
  105ab8:	90                   	nop
        case '#':
            altflag = 1;
            goto reswitch;

        process_precision:
            if (width < 0)
  105ab9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  105abd:	0f 89 64 ff ff ff    	jns    105a27 <vprintfmt+0x53>
                width = precision, precision = -1;
  105ac3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105ac6:	89 45 e8             	mov    %eax,-0x18(%ebp)
  105ac9:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
            goto reswitch;
  105ad0:	e9 52 ff ff ff       	jmp    105a27 <vprintfmt+0x53>

        // long flag (doubled for long long)
        case 'l':
            lflag ++;
  105ad5:	ff 45 e0             	incl   -0x20(%ebp)
            goto reswitch;
  105ad8:	e9 4a ff ff ff       	jmp    105a27 <vprintfmt+0x53>

        // character
        case 'c':
            putch(va_arg(ap, int), putdat);
  105add:	8b 45 14             	mov    0x14(%ebp),%eax
  105ae0:	8d 50 04             	lea    0x4(%eax),%edx
  105ae3:	89 55 14             	mov    %edx,0x14(%ebp)
  105ae6:	8b 00                	mov    (%eax),%eax
  105ae8:	8b 55 0c             	mov    0xc(%ebp),%edx
  105aeb:	89 54 24 04          	mov    %edx,0x4(%esp)
  105aef:	89 04 24             	mov    %eax,(%esp)
  105af2:	8b 45 08             	mov    0x8(%ebp),%eax
  105af5:	ff d0                	call   *%eax
            break;
  105af7:	e9 a4 02 00 00       	jmp    105da0 <vprintfmt+0x3cc>

        // error message
        case 'e':
            err = va_arg(ap, int);
  105afc:	8b 45 14             	mov    0x14(%ebp),%eax
  105aff:	8d 50 04             	lea    0x4(%eax),%edx
  105b02:	89 55 14             	mov    %edx,0x14(%ebp)
  105b05:	8b 18                	mov    (%eax),%ebx
            if (err < 0) {
  105b07:	85 db                	test   %ebx,%ebx
  105b09:	79 02                	jns    105b0d <vprintfmt+0x139>
                err = -err;
  105b0b:	f7 db                	neg    %ebx
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  105b0d:	83 fb 06             	cmp    $0x6,%ebx
  105b10:	7f 0b                	jg     105b1d <vprintfmt+0x149>
  105b12:	8b 34 9d 00 70 10 00 	mov    0x107000(,%ebx,4),%esi
  105b19:	85 f6                	test   %esi,%esi
  105b1b:	75 23                	jne    105b40 <vprintfmt+0x16c>
                printfmt(putch, putdat, "error %d", err);
  105b1d:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  105b21:	c7 44 24 08 2d 70 10 	movl   $0x10702d,0x8(%esp)
  105b28:	00 
  105b29:	8b 45 0c             	mov    0xc(%ebp),%eax
  105b2c:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b30:	8b 45 08             	mov    0x8(%ebp),%eax
  105b33:	89 04 24             	mov    %eax,(%esp)
  105b36:	e8 6a fe ff ff       	call   1059a5 <printfmt>
            }
            else {
                printfmt(putch, putdat, "%s", p);
            }
            break;
  105b3b:	e9 60 02 00 00       	jmp    105da0 <vprintfmt+0x3cc>
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
                printfmt(putch, putdat, "error %d", err);
            }
            else {
                printfmt(putch, putdat, "%s", p);
  105b40:	89 74 24 0c          	mov    %esi,0xc(%esp)
  105b44:	c7 44 24 08 36 70 10 	movl   $0x107036,0x8(%esp)
  105b4b:	00 
  105b4c:	8b 45 0c             	mov    0xc(%ebp),%eax
  105b4f:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b53:	8b 45 08             	mov    0x8(%ebp),%eax
  105b56:	89 04 24             	mov    %eax,(%esp)
  105b59:	e8 47 fe ff ff       	call   1059a5 <printfmt>
            }
            break;
  105b5e:	e9 3d 02 00 00       	jmp    105da0 <vprintfmt+0x3cc>

        // string
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
  105b63:	8b 45 14             	mov    0x14(%ebp),%eax
  105b66:	8d 50 04             	lea    0x4(%eax),%edx
  105b69:	89 55 14             	mov    %edx,0x14(%ebp)
  105b6c:	8b 30                	mov    (%eax),%esi
  105b6e:	85 f6                	test   %esi,%esi
  105b70:	75 05                	jne    105b77 <vprintfmt+0x1a3>
                p = "(null)";
  105b72:	be 39 70 10 00       	mov    $0x107039,%esi
            }
            if (width > 0 && padc != '-') {
  105b77:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  105b7b:	7e 76                	jle    105bf3 <vprintfmt+0x21f>
  105b7d:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
  105b81:	74 70                	je     105bf3 <vprintfmt+0x21f>
                for (width -= strnlen(p, precision); width > 0; width --) {
  105b83:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105b86:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b8a:	89 34 24             	mov    %esi,(%esp)
  105b8d:	e8 f6 f7 ff ff       	call   105388 <strnlen>
  105b92:	8b 55 e8             	mov    -0x18(%ebp),%edx
  105b95:	29 c2                	sub    %eax,%edx
  105b97:	89 d0                	mov    %edx,%eax
  105b99:	89 45 e8             	mov    %eax,-0x18(%ebp)
  105b9c:	eb 16                	jmp    105bb4 <vprintfmt+0x1e0>
                    putch(padc, putdat);
  105b9e:	0f be 45 db          	movsbl -0x25(%ebp),%eax
  105ba2:	8b 55 0c             	mov    0xc(%ebp),%edx
  105ba5:	89 54 24 04          	mov    %edx,0x4(%esp)
  105ba9:	89 04 24             	mov    %eax,(%esp)
  105bac:	8b 45 08             	mov    0x8(%ebp),%eax
  105baf:	ff d0                	call   *%eax
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
                p = "(null)";
            }
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
  105bb1:	ff 4d e8             	decl   -0x18(%ebp)
  105bb4:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  105bb8:	7f e4                	jg     105b9e <vprintfmt+0x1ca>
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  105bba:	eb 37                	jmp    105bf3 <vprintfmt+0x21f>
                if (altflag && (ch < ' ' || ch > '~')) {
  105bbc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  105bc0:	74 1f                	je     105be1 <vprintfmt+0x20d>
  105bc2:	83 fb 1f             	cmp    $0x1f,%ebx
  105bc5:	7e 05                	jle    105bcc <vprintfmt+0x1f8>
  105bc7:	83 fb 7e             	cmp    $0x7e,%ebx
  105bca:	7e 15                	jle    105be1 <vprintfmt+0x20d>
                    putch('?', putdat);
  105bcc:	8b 45 0c             	mov    0xc(%ebp),%eax
  105bcf:	89 44 24 04          	mov    %eax,0x4(%esp)
  105bd3:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  105bda:	8b 45 08             	mov    0x8(%ebp),%eax
  105bdd:	ff d0                	call   *%eax
  105bdf:	eb 0f                	jmp    105bf0 <vprintfmt+0x21c>
                }
                else {
                    putch(ch, putdat);
  105be1:	8b 45 0c             	mov    0xc(%ebp),%eax
  105be4:	89 44 24 04          	mov    %eax,0x4(%esp)
  105be8:	89 1c 24             	mov    %ebx,(%esp)
  105beb:	8b 45 08             	mov    0x8(%ebp),%eax
  105bee:	ff d0                	call   *%eax
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  105bf0:	ff 4d e8             	decl   -0x18(%ebp)
  105bf3:	89 f0                	mov    %esi,%eax
  105bf5:	8d 70 01             	lea    0x1(%eax),%esi
  105bf8:	0f b6 00             	movzbl (%eax),%eax
  105bfb:	0f be d8             	movsbl %al,%ebx
  105bfe:	85 db                	test   %ebx,%ebx
  105c00:	74 27                	je     105c29 <vprintfmt+0x255>
  105c02:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  105c06:	78 b4                	js     105bbc <vprintfmt+0x1e8>
  105c08:	ff 4d e4             	decl   -0x1c(%ebp)
  105c0b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  105c0f:	79 ab                	jns    105bbc <vprintfmt+0x1e8>
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
  105c11:	eb 16                	jmp    105c29 <vprintfmt+0x255>
                putch(' ', putdat);
  105c13:	8b 45 0c             	mov    0xc(%ebp),%eax
  105c16:	89 44 24 04          	mov    %eax,0x4(%esp)
  105c1a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  105c21:	8b 45 08             	mov    0x8(%ebp),%eax
  105c24:	ff d0                	call   *%eax
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
  105c26:	ff 4d e8             	decl   -0x18(%ebp)
  105c29:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  105c2d:	7f e4                	jg     105c13 <vprintfmt+0x23f>
                putch(' ', putdat);
            }
            break;
  105c2f:	e9 6c 01 00 00       	jmp    105da0 <vprintfmt+0x3cc>

        // (signed) decimal
        case 'd':
            num = getint(&ap, lflag);
  105c34:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105c37:	89 44 24 04          	mov    %eax,0x4(%esp)
  105c3b:	8d 45 14             	lea    0x14(%ebp),%eax
  105c3e:	89 04 24             	mov    %eax,(%esp)
  105c41:	e8 18 fd ff ff       	call   10595e <getint>
  105c46:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105c49:	89 55 f4             	mov    %edx,-0xc(%ebp)
            if ((long long)num < 0) {
  105c4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105c4f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105c52:	85 d2                	test   %edx,%edx
  105c54:	79 26                	jns    105c7c <vprintfmt+0x2a8>
                putch('-', putdat);
  105c56:	8b 45 0c             	mov    0xc(%ebp),%eax
  105c59:	89 44 24 04          	mov    %eax,0x4(%esp)
  105c5d:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  105c64:	8b 45 08             	mov    0x8(%ebp),%eax
  105c67:	ff d0                	call   *%eax
                num = -(long long)num;
  105c69:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105c6c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105c6f:	f7 d8                	neg    %eax
  105c71:	83 d2 00             	adc    $0x0,%edx
  105c74:	f7 da                	neg    %edx
  105c76:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105c79:	89 55 f4             	mov    %edx,-0xc(%ebp)
            }
            base = 10;
  105c7c:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
  105c83:	e9 a8 00 00 00       	jmp    105d30 <vprintfmt+0x35c>

        // unsigned decimal
        case 'u':
            num = getuint(&ap, lflag);
  105c88:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105c8b:	89 44 24 04          	mov    %eax,0x4(%esp)
  105c8f:	8d 45 14             	lea    0x14(%ebp),%eax
  105c92:	89 04 24             	mov    %eax,(%esp)
  105c95:	e8 75 fc ff ff       	call   10590f <getuint>
  105c9a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105c9d:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 10;
  105ca0:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
  105ca7:	e9 84 00 00 00       	jmp    105d30 <vprintfmt+0x35c>

        // (unsigned) octal
        case 'o':
            num = getuint(&ap, lflag);
  105cac:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105caf:	89 44 24 04          	mov    %eax,0x4(%esp)
  105cb3:	8d 45 14             	lea    0x14(%ebp),%eax
  105cb6:	89 04 24             	mov    %eax,(%esp)
  105cb9:	e8 51 fc ff ff       	call   10590f <getuint>
  105cbe:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105cc1:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 8;
  105cc4:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
            goto number;
  105ccb:	eb 63                	jmp    105d30 <vprintfmt+0x35c>

        // pointer
        case 'p':
            putch('0', putdat);
  105ccd:	8b 45 0c             	mov    0xc(%ebp),%eax
  105cd0:	89 44 24 04          	mov    %eax,0x4(%esp)
  105cd4:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  105cdb:	8b 45 08             	mov    0x8(%ebp),%eax
  105cde:	ff d0                	call   *%eax
            putch('x', putdat);
  105ce0:	8b 45 0c             	mov    0xc(%ebp),%eax
  105ce3:	89 44 24 04          	mov    %eax,0x4(%esp)
  105ce7:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  105cee:	8b 45 08             	mov    0x8(%ebp),%eax
  105cf1:	ff d0                	call   *%eax
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  105cf3:	8b 45 14             	mov    0x14(%ebp),%eax
  105cf6:	8d 50 04             	lea    0x4(%eax),%edx
  105cf9:	89 55 14             	mov    %edx,0x14(%ebp)
  105cfc:	8b 00                	mov    (%eax),%eax
  105cfe:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105d01:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
            base = 16;
  105d08:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
            goto number;
  105d0f:	eb 1f                	jmp    105d30 <vprintfmt+0x35c>

        // (unsigned) hexadecimal
        case 'x':
            num = getuint(&ap, lflag);
  105d11:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105d14:	89 44 24 04          	mov    %eax,0x4(%esp)
  105d18:	8d 45 14             	lea    0x14(%ebp),%eax
  105d1b:	89 04 24             	mov    %eax,(%esp)
  105d1e:	e8 ec fb ff ff       	call   10590f <getuint>
  105d23:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105d26:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 16;
  105d29:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
        number:
            printnum(putch, putdat, num, base, width, padc);
  105d30:	0f be 55 db          	movsbl -0x25(%ebp),%edx
  105d34:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105d37:	89 54 24 18          	mov    %edx,0x18(%esp)
  105d3b:	8b 55 e8             	mov    -0x18(%ebp),%edx
  105d3e:	89 54 24 14          	mov    %edx,0x14(%esp)
  105d42:	89 44 24 10          	mov    %eax,0x10(%esp)
  105d46:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105d49:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105d4c:	89 44 24 08          	mov    %eax,0x8(%esp)
  105d50:	89 54 24 0c          	mov    %edx,0xc(%esp)
  105d54:	8b 45 0c             	mov    0xc(%ebp),%eax
  105d57:	89 44 24 04          	mov    %eax,0x4(%esp)
  105d5b:	8b 45 08             	mov    0x8(%ebp),%eax
  105d5e:	89 04 24             	mov    %eax,(%esp)
  105d61:	e8 a4 fa ff ff       	call   10580a <printnum>
            break;
  105d66:	eb 38                	jmp    105da0 <vprintfmt+0x3cc>

        // escaped '%' character
        case '%':
            putch(ch, putdat);
  105d68:	8b 45 0c             	mov    0xc(%ebp),%eax
  105d6b:	89 44 24 04          	mov    %eax,0x4(%esp)
  105d6f:	89 1c 24             	mov    %ebx,(%esp)
  105d72:	8b 45 08             	mov    0x8(%ebp),%eax
  105d75:	ff d0                	call   *%eax
            break;
  105d77:	eb 27                	jmp    105da0 <vprintfmt+0x3cc>

        // unrecognized escape sequence - just print it literally
        default:
            putch('%', putdat);
  105d79:	8b 45 0c             	mov    0xc(%ebp),%eax
  105d7c:	89 44 24 04          	mov    %eax,0x4(%esp)
  105d80:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  105d87:	8b 45 08             	mov    0x8(%ebp),%eax
  105d8a:	ff d0                	call   *%eax
            for (fmt --; fmt[-1] != '%'; fmt --)
  105d8c:	ff 4d 10             	decl   0x10(%ebp)
  105d8f:	eb 03                	jmp    105d94 <vprintfmt+0x3c0>
  105d91:	ff 4d 10             	decl   0x10(%ebp)
  105d94:	8b 45 10             	mov    0x10(%ebp),%eax
  105d97:	48                   	dec    %eax
  105d98:	0f b6 00             	movzbl (%eax),%eax
  105d9b:	3c 25                	cmp    $0x25,%al
  105d9d:	75 f2                	jne    105d91 <vprintfmt+0x3bd>
                /* do nothing */;
            break;
  105d9f:	90                   	nop
        }
    }
  105da0:	e9 37 fc ff ff       	jmp    1059dc <vprintfmt+0x8>
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
            if (ch == '\0') {
                return;
  105da5:	90                   	nop
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  105da6:	83 c4 40             	add    $0x40,%esp
  105da9:	5b                   	pop    %ebx
  105daa:	5e                   	pop    %esi
  105dab:	5d                   	pop    %ebp
  105dac:	c3                   	ret    

00105dad <sprintputch>:
 * sprintputch - 'print' a single character in a buffer
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
  105dad:	55                   	push   %ebp
  105dae:	89 e5                	mov    %esp,%ebp
    b->cnt ++;
  105db0:	8b 45 0c             	mov    0xc(%ebp),%eax
  105db3:	8b 40 08             	mov    0x8(%eax),%eax
  105db6:	8d 50 01             	lea    0x1(%eax),%edx
  105db9:	8b 45 0c             	mov    0xc(%ebp),%eax
  105dbc:	89 50 08             	mov    %edx,0x8(%eax)
    if (b->buf < b->ebuf) {
  105dbf:	8b 45 0c             	mov    0xc(%ebp),%eax
  105dc2:	8b 10                	mov    (%eax),%edx
  105dc4:	8b 45 0c             	mov    0xc(%ebp),%eax
  105dc7:	8b 40 04             	mov    0x4(%eax),%eax
  105dca:	39 c2                	cmp    %eax,%edx
  105dcc:	73 12                	jae    105de0 <sprintputch+0x33>
        *b->buf ++ = ch;
  105dce:	8b 45 0c             	mov    0xc(%ebp),%eax
  105dd1:	8b 00                	mov    (%eax),%eax
  105dd3:	8d 48 01             	lea    0x1(%eax),%ecx
  105dd6:	8b 55 0c             	mov    0xc(%ebp),%edx
  105dd9:	89 0a                	mov    %ecx,(%edx)
  105ddb:	8b 55 08             	mov    0x8(%ebp),%edx
  105dde:	88 10                	mov    %dl,(%eax)
    }
}
  105de0:	90                   	nop
  105de1:	5d                   	pop    %ebp
  105de2:	c3                   	ret    

00105de3 <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
  105de3:	55                   	push   %ebp
  105de4:	89 e5                	mov    %esp,%ebp
  105de6:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
  105de9:	8d 45 14             	lea    0x14(%ebp),%eax
  105dec:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vsnprintf(str, size, fmt, ap);
  105def:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105df2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105df6:	8b 45 10             	mov    0x10(%ebp),%eax
  105df9:	89 44 24 08          	mov    %eax,0x8(%esp)
  105dfd:	8b 45 0c             	mov    0xc(%ebp),%eax
  105e00:	89 44 24 04          	mov    %eax,0x4(%esp)
  105e04:	8b 45 08             	mov    0x8(%ebp),%eax
  105e07:	89 04 24             	mov    %eax,(%esp)
  105e0a:	e8 08 00 00 00       	call   105e17 <vsnprintf>
  105e0f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
  105e12:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  105e15:	c9                   	leave  
  105e16:	c3                   	ret    

00105e17 <vsnprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
  105e17:	55                   	push   %ebp
  105e18:	89 e5                	mov    %esp,%ebp
  105e1a:	83 ec 28             	sub    $0x28,%esp
    struct sprintbuf b = {str, str + size - 1, 0};
  105e1d:	8b 45 08             	mov    0x8(%ebp),%eax
  105e20:	89 45 ec             	mov    %eax,-0x14(%ebp)
  105e23:	8b 45 0c             	mov    0xc(%ebp),%eax
  105e26:	8d 50 ff             	lea    -0x1(%eax),%edx
  105e29:	8b 45 08             	mov    0x8(%ebp),%eax
  105e2c:	01 d0                	add    %edx,%eax
  105e2e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  105e31:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if (str == NULL || b.buf > b.ebuf) {
  105e38:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  105e3c:	74 0a                	je     105e48 <vsnprintf+0x31>
  105e3e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  105e41:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105e44:	39 c2                	cmp    %eax,%edx
  105e46:	76 07                	jbe    105e4f <vsnprintf+0x38>
        return -E_INVAL;
  105e48:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  105e4d:	eb 2a                	jmp    105e79 <vsnprintf+0x62>
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
  105e4f:	8b 45 14             	mov    0x14(%ebp),%eax
  105e52:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105e56:	8b 45 10             	mov    0x10(%ebp),%eax
  105e59:	89 44 24 08          	mov    %eax,0x8(%esp)
  105e5d:	8d 45 ec             	lea    -0x14(%ebp),%eax
  105e60:	89 44 24 04          	mov    %eax,0x4(%esp)
  105e64:	c7 04 24 ad 5d 10 00 	movl   $0x105dad,(%esp)
  105e6b:	e8 64 fb ff ff       	call   1059d4 <vprintfmt>
    // null terminate the buffer
    *b.buf = '\0';
  105e70:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105e73:	c6 00 00             	movb   $0x0,(%eax)
    return b.cnt;
  105e76:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  105e79:	c9                   	leave  
  105e7a:	c3                   	ret    
