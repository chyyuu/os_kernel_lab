
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
c010005d:	e8 1f 56 00 00       	call   c0105681 <memset>

    cons_init();                // init the console
c0100062:	e8 be 14 00 00       	call   c0101525 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
c0100067:	c7 45 f4 80 5e 10 c0 	movl   $0xc0105e80,-0xc(%ebp)
    cprintf("%s\n\n", message);
c010006e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100071:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100075:	c7 04 24 9c 5e 10 c0 	movl   $0xc0105e9c,(%esp)
c010007c:	e8 11 02 00 00       	call   c0100292 <cprintf>

    print_kerninfo();
c0100081:	e8 b2 08 00 00       	call   c0100938 <print_kerninfo>

    grade_backtrace();
c0100086:	e8 89 00 00 00       	call   c0100114 <grade_backtrace>

    pmm_init();                 // init physical memory management
c010008b:	e8 c1 2f 00 00       	call   c0103051 <pmm_init>

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
c0100162:	c7 04 24 a1 5e 10 c0 	movl   $0xc0105ea1,(%esp)
c0100169:	e8 24 01 00 00       	call   c0100292 <cprintf>
    cprintf("%d:  cs = %x\n", round, reg1);
c010016e:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100172:	89 c2                	mov    %eax,%edx
c0100174:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c0100179:	89 54 24 08          	mov    %edx,0x8(%esp)
c010017d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100181:	c7 04 24 af 5e 10 c0 	movl   $0xc0105eaf,(%esp)
c0100188:	e8 05 01 00 00       	call   c0100292 <cprintf>
    cprintf("%d:  ds = %x\n", round, reg2);
c010018d:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
c0100191:	89 c2                	mov    %eax,%edx
c0100193:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c0100198:	89 54 24 08          	mov    %edx,0x8(%esp)
c010019c:	89 44 24 04          	mov    %eax,0x4(%esp)
c01001a0:	c7 04 24 bd 5e 10 c0 	movl   $0xc0105ebd,(%esp)
c01001a7:	e8 e6 00 00 00       	call   c0100292 <cprintf>
    cprintf("%d:  es = %x\n", round, reg3);
c01001ac:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c01001b0:	89 c2                	mov    %eax,%edx
c01001b2:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c01001b7:	89 54 24 08          	mov    %edx,0x8(%esp)
c01001bb:	89 44 24 04          	mov    %eax,0x4(%esp)
c01001bf:	c7 04 24 cb 5e 10 c0 	movl   $0xc0105ecb,(%esp)
c01001c6:	e8 c7 00 00 00       	call   c0100292 <cprintf>
    cprintf("%d:  ss = %x\n", round, reg4);
c01001cb:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
c01001cf:	89 c2                	mov    %eax,%edx
c01001d1:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c01001d6:	89 54 24 08          	mov    %edx,0x8(%esp)
c01001da:	89 44 24 04          	mov    %eax,0x4(%esp)
c01001de:	c7 04 24 d9 5e 10 c0 	movl   $0xc0105ed9,(%esp)
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
c010020f:	c7 04 24 e8 5e 10 c0 	movl   $0xc0105ee8,(%esp)
c0100216:	e8 77 00 00 00       	call   c0100292 <cprintf>
    lab1_switch_to_user();
c010021b:	e8 d8 ff ff ff       	call   c01001f8 <lab1_switch_to_user>
    lab1_print_cur_status();
c0100220:	e8 15 ff ff ff       	call   c010013a <lab1_print_cur_status>
    cprintf("+++ switch to kernel mode +++\n");
c0100225:	c7 04 24 08 5f 10 c0 	movl   $0xc0105f08,(%esp)
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
c0100288:	e8 47 57 00 00       	call   c01059d4 <vprintfmt>
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
c0100347:	c7 04 24 27 5f 10 c0 	movl   $0xc0105f27,(%esp)
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
c0100416:	c7 04 24 2a 5f 10 c0 	movl   $0xc0105f2a,(%esp)
c010041d:	e8 70 fe ff ff       	call   c0100292 <cprintf>
    vcprintf(fmt, ap);
c0100422:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100425:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100429:	8b 45 10             	mov    0x10(%ebp),%eax
c010042c:	89 04 24             	mov    %eax,(%esp)
c010042f:	e8 2b fe ff ff       	call   c010025f <vcprintf>
    cprintf("\n");
c0100434:	c7 04 24 46 5f 10 c0 	movl   $0xc0105f46,(%esp)
c010043b:	e8 52 fe ff ff       	call   c0100292 <cprintf>
    
    cprintf("stack trackback:\n");
c0100440:	c7 04 24 48 5f 10 c0 	movl   $0xc0105f48,(%esp)
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
c0100481:	c7 04 24 5a 5f 10 c0 	movl   $0xc0105f5a,(%esp)
c0100488:	e8 05 fe ff ff       	call   c0100292 <cprintf>
    vcprintf(fmt, ap);
c010048d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100490:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100494:	8b 45 10             	mov    0x10(%ebp),%eax
c0100497:	89 04 24             	mov    %eax,(%esp)
c010049a:	e8 c0 fd ff ff       	call   c010025f <vcprintf>
    cprintf("\n");
c010049f:	c7 04 24 46 5f 10 c0 	movl   $0xc0105f46,(%esp)
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
c010060f:	c7 00 78 5f 10 c0    	movl   $0xc0105f78,(%eax)
    info->eip_line = 0;
c0100615:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100618:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
    info->eip_fn_name = "<unknown>";
c010061f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100622:	c7 40 08 78 5f 10 c0 	movl   $0xc0105f78,0x8(%eax)
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
c0100646:	c7 45 f4 98 71 10 c0 	movl   $0xc0107198,-0xc(%ebp)
    stab_end = __STAB_END__;
c010064d:	c7 45 f0 38 1f 11 c0 	movl   $0xc0111f38,-0x10(%ebp)
    stabstr = __STABSTR_BEGIN__;
c0100654:	c7 45 ec 39 1f 11 c0 	movl   $0xc0111f39,-0x14(%ebp)
    stabstr_end = __STABSTR_END__;
c010065b:	c7 45 e8 e4 49 11 c0 	movl   $0xc01149e4,-0x18(%ebp)

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
c01007b6:	e8 42 4d 00 00       	call   c01054fd <strfind>
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
c010093e:	c7 04 24 82 5f 10 c0 	movl   $0xc0105f82,(%esp)
c0100945:	e8 48 f9 ff ff       	call   c0100292 <cprintf>
    cprintf("  entry  0x%08x (phys)\n", kern_init);
c010094a:	c7 44 24 04 36 00 10 	movl   $0xc0100036,0x4(%esp)
c0100951:	c0 
c0100952:	c7 04 24 9b 5f 10 c0 	movl   $0xc0105f9b,(%esp)
c0100959:	e8 34 f9 ff ff       	call   c0100292 <cprintf>
    cprintf("  etext  0x%08x (phys)\n", etext);
c010095e:	c7 44 24 04 7b 5e 10 	movl   $0xc0105e7b,0x4(%esp)
c0100965:	c0 
c0100966:	c7 04 24 b3 5f 10 c0 	movl   $0xc0105fb3,(%esp)
c010096d:	e8 20 f9 ff ff       	call   c0100292 <cprintf>
    cprintf("  edata  0x%08x (phys)\n", edata);
c0100972:	c7 44 24 04 00 a0 11 	movl   $0xc011a000,0x4(%esp)
c0100979:	c0 
c010097a:	c7 04 24 cb 5f 10 c0 	movl   $0xc0105fcb,(%esp)
c0100981:	e8 0c f9 ff ff       	call   c0100292 <cprintf>
    cprintf("  end    0x%08x (phys)\n", end);
c0100986:	c7 44 24 04 28 af 11 	movl   $0xc011af28,0x4(%esp)
c010098d:	c0 
c010098e:	c7 04 24 e3 5f 10 c0 	movl   $0xc0105fe3,(%esp)
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
c01009c0:	c7 04 24 fc 5f 10 c0 	movl   $0xc0105ffc,(%esp)
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
c01009f5:	c7 04 24 26 60 10 c0 	movl   $0xc0106026,(%esp)
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
c0100a63:	c7 04 24 42 60 10 c0 	movl   $0xc0106042,(%esp)
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
c0100abb:	c7 04 24 d4 60 10 c0 	movl   $0xc01060d4,(%esp)
c0100ac2:	e8 04 4a 00 00       	call   c01054cb <strchr>
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
c0100ae3:	c7 04 24 d9 60 10 c0 	movl   $0xc01060d9,(%esp)
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
c0100b29:	c7 04 24 d4 60 10 c0 	movl   $0xc01060d4,(%esp)
c0100b30:	e8 96 49 00 00       	call   c01054cb <strchr>
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
c0100b96:	e8 93 48 00 00       	call   c010542e <strcmp>
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
c0100be2:	c7 04 24 f7 60 10 c0 	movl   $0xc01060f7,(%esp)
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
c0100bff:	c7 04 24 10 61 10 c0 	movl   $0xc0106110,(%esp)
c0100c06:	e8 87 f6 ff ff       	call   c0100292 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
c0100c0b:	c7 04 24 38 61 10 c0 	movl   $0xc0106138,(%esp)
c0100c12:	e8 7b f6 ff ff       	call   c0100292 <cprintf>

    if (tf != NULL) {
c0100c17:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0100c1b:	74 0b                	je     c0100c28 <kmonitor+0x2f>
        print_trapframe(tf);
c0100c1d:	8b 45 08             	mov    0x8(%ebp),%eax
c0100c20:	89 04 24             	mov    %eax,(%esp)
c0100c23:	e8 f9 0c 00 00       	call   c0101921 <print_trapframe>
    }

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
c0100c28:	c7 04 24 5d 61 10 c0 	movl   $0xc010615d,(%esp)
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
c0100c96:	c7 04 24 61 61 10 c0 	movl   $0xc0106161,(%esp)
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
c0100d20:	c7 04 24 6a 61 10 c0 	movl   $0xc010616a,(%esp)
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
c0101156:	e8 66 45 00 00       	call   c01056c1 <memmove>
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
c01014d2:	c7 04 24 85 61 10 c0 	movl   $0xc0106185,(%esp)
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
c0101543:	c7 04 24 91 61 10 c0 	movl   $0xc0106191,(%esp)
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
c01017d8:	c7 04 24 c0 61 10 c0 	movl   $0xc01061c0,(%esp)
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
c01017ea:	83 ec 10             	sub    $0x10,%esp
      * (3) After setup the contents of IDT, you will let CPU know where is the IDT by using 'lidt' instruction.
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
    extern uintptr_t __vectors[];
    for (int i = 0; i < sizeof(idt) / sizeof(struct gatedesc); i++) {
c01017ed:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c01017f4:	e9 c4 00 00 00       	jmp    c01018bd <idt_init+0xd6>
	SETGATE(idt[i], 0, GD_KTEXT, __vectors[i], DPL_KERNEL);
c01017f9:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01017fc:	8b 04 85 e0 75 11 c0 	mov    -0x3fee8a20(,%eax,4),%eax
c0101803:	0f b7 d0             	movzwl %ax,%edx
c0101806:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101809:	66 89 14 c5 80 a6 11 	mov    %dx,-0x3fee5980(,%eax,8)
c0101810:	c0 
c0101811:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101814:	66 c7 04 c5 82 a6 11 	movw   $0x8,-0x3fee597e(,%eax,8)
c010181b:	c0 08 00 
c010181e:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101821:	0f b6 14 c5 84 a6 11 	movzbl -0x3fee597c(,%eax,8),%edx
c0101828:	c0 
c0101829:	80 e2 e0             	and    $0xe0,%dl
c010182c:	88 14 c5 84 a6 11 c0 	mov    %dl,-0x3fee597c(,%eax,8)
c0101833:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101836:	0f b6 14 c5 84 a6 11 	movzbl -0x3fee597c(,%eax,8),%edx
c010183d:	c0 
c010183e:	80 e2 1f             	and    $0x1f,%dl
c0101841:	88 14 c5 84 a6 11 c0 	mov    %dl,-0x3fee597c(,%eax,8)
c0101848:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010184b:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c0101852:	c0 
c0101853:	80 e2 f0             	and    $0xf0,%dl
c0101856:	80 ca 0e             	or     $0xe,%dl
c0101859:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c0101860:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101863:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c010186a:	c0 
c010186b:	80 e2 ef             	and    $0xef,%dl
c010186e:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c0101875:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101878:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c010187f:	c0 
c0101880:	80 e2 9f             	and    $0x9f,%dl
c0101883:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c010188a:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010188d:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c0101894:	c0 
c0101895:	80 ca 80             	or     $0x80,%dl
c0101898:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c010189f:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018a2:	8b 04 85 e0 75 11 c0 	mov    -0x3fee8a20(,%eax,4),%eax
c01018a9:	c1 e8 10             	shr    $0x10,%eax
c01018ac:	0f b7 d0             	movzwl %ax,%edx
c01018af:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018b2:	66 89 14 c5 86 a6 11 	mov    %dx,-0x3fee597a(,%eax,8)
c01018b9:	c0 
      * (3) After setup the contents of IDT, you will let CPU know where is the IDT by using 'lidt' instruction.
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
    extern uintptr_t __vectors[];
    for (int i = 0; i < sizeof(idt) / sizeof(struct gatedesc); i++) {
c01018ba:	ff 45 fc             	incl   -0x4(%ebp)
c01018bd:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018c0:	3d ff 00 00 00       	cmp    $0xff,%eax
c01018c5:	0f 86 2e ff ff ff    	jbe    c01017f9 <idt_init+0x12>
c01018cb:	c7 45 f8 60 75 11 c0 	movl   $0xc0117560,-0x8(%ebp)
    }
}

static inline void
lidt(struct pseudodesc *pd) {
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
c01018d2:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01018d5:	0f 01 18             	lidtl  (%eax)
	SETGATE(idt[i], 0, GD_KTEXT, __vectors[i], DPL_KERNEL);
    }
    lidt(&idt_pd);
}
c01018d8:	90                   	nop
c01018d9:	c9                   	leave  
c01018da:	c3                   	ret    

c01018db <trapname>:

static const char *
trapname(int trapno) {
c01018db:	55                   	push   %ebp
c01018dc:	89 e5                	mov    %esp,%ebp
        "Alignment Check",
        "Machine-Check",
        "SIMD Floating-Point Exception"
    };

    if (trapno < sizeof(excnames)/sizeof(const char * const)) {
c01018de:	8b 45 08             	mov    0x8(%ebp),%eax
c01018e1:	83 f8 13             	cmp    $0x13,%eax
c01018e4:	77 0c                	ja     c01018f2 <trapname+0x17>
        return excnames[trapno];
c01018e6:	8b 45 08             	mov    0x8(%ebp),%eax
c01018e9:	8b 04 85 20 65 10 c0 	mov    -0x3fef9ae0(,%eax,4),%eax
c01018f0:	eb 18                	jmp    c010190a <trapname+0x2f>
    }
    if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16) {
c01018f2:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
c01018f6:	7e 0d                	jle    c0101905 <trapname+0x2a>
c01018f8:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
c01018fc:	7f 07                	jg     c0101905 <trapname+0x2a>
        return "Hardware Interrupt";
c01018fe:	b8 ca 61 10 c0       	mov    $0xc01061ca,%eax
c0101903:	eb 05                	jmp    c010190a <trapname+0x2f>
    }
    return "(unknown trap)";
c0101905:	b8 dd 61 10 c0       	mov    $0xc01061dd,%eax
}
c010190a:	5d                   	pop    %ebp
c010190b:	c3                   	ret    

c010190c <trap_in_kernel>:

/* trap_in_kernel - test if trap happened in kernel */
bool
trap_in_kernel(struct trapframe *tf) {
c010190c:	55                   	push   %ebp
c010190d:	89 e5                	mov    %esp,%ebp
    return (tf->tf_cs == (uint16_t)KERNEL_CS);
c010190f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101912:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101916:	83 f8 08             	cmp    $0x8,%eax
c0101919:	0f 94 c0             	sete   %al
c010191c:	0f b6 c0             	movzbl %al,%eax
}
c010191f:	5d                   	pop    %ebp
c0101920:	c3                   	ret    

c0101921 <print_trapframe>:
    "TF", "IF", "DF", "OF", NULL, NULL, "NT", NULL,
    "RF", "VM", "AC", "VIF", "VIP", "ID", NULL, NULL,
};

void
print_trapframe(struct trapframe *tf) {
c0101921:	55                   	push   %ebp
c0101922:	89 e5                	mov    %esp,%ebp
c0101924:	83 ec 28             	sub    $0x28,%esp
    cprintf("trapframe at %p\n", tf);
c0101927:	8b 45 08             	mov    0x8(%ebp),%eax
c010192a:	89 44 24 04          	mov    %eax,0x4(%esp)
c010192e:	c7 04 24 1e 62 10 c0 	movl   $0xc010621e,(%esp)
c0101935:	e8 58 e9 ff ff       	call   c0100292 <cprintf>
    print_regs(&tf->tf_regs);
c010193a:	8b 45 08             	mov    0x8(%ebp),%eax
c010193d:	89 04 24             	mov    %eax,(%esp)
c0101940:	e8 91 01 00 00       	call   c0101ad6 <print_regs>
    cprintf("  ds   0x----%04x\n", tf->tf_ds);
c0101945:	8b 45 08             	mov    0x8(%ebp),%eax
c0101948:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
c010194c:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101950:	c7 04 24 2f 62 10 c0 	movl   $0xc010622f,(%esp)
c0101957:	e8 36 e9 ff ff       	call   c0100292 <cprintf>
    cprintf("  es   0x----%04x\n", tf->tf_es);
c010195c:	8b 45 08             	mov    0x8(%ebp),%eax
c010195f:	0f b7 40 28          	movzwl 0x28(%eax),%eax
c0101963:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101967:	c7 04 24 42 62 10 c0 	movl   $0xc0106242,(%esp)
c010196e:	e8 1f e9 ff ff       	call   c0100292 <cprintf>
    cprintf("  fs   0x----%04x\n", tf->tf_fs);
c0101973:	8b 45 08             	mov    0x8(%ebp),%eax
c0101976:	0f b7 40 24          	movzwl 0x24(%eax),%eax
c010197a:	89 44 24 04          	mov    %eax,0x4(%esp)
c010197e:	c7 04 24 55 62 10 c0 	movl   $0xc0106255,(%esp)
c0101985:	e8 08 e9 ff ff       	call   c0100292 <cprintf>
    cprintf("  gs   0x----%04x\n", tf->tf_gs);
c010198a:	8b 45 08             	mov    0x8(%ebp),%eax
c010198d:	0f b7 40 20          	movzwl 0x20(%eax),%eax
c0101991:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101995:	c7 04 24 68 62 10 c0 	movl   $0xc0106268,(%esp)
c010199c:	e8 f1 e8 ff ff       	call   c0100292 <cprintf>
    cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
c01019a1:	8b 45 08             	mov    0x8(%ebp),%eax
c01019a4:	8b 40 30             	mov    0x30(%eax),%eax
c01019a7:	89 04 24             	mov    %eax,(%esp)
c01019aa:	e8 2c ff ff ff       	call   c01018db <trapname>
c01019af:	89 c2                	mov    %eax,%edx
c01019b1:	8b 45 08             	mov    0x8(%ebp),%eax
c01019b4:	8b 40 30             	mov    0x30(%eax),%eax
c01019b7:	89 54 24 08          	mov    %edx,0x8(%esp)
c01019bb:	89 44 24 04          	mov    %eax,0x4(%esp)
c01019bf:	c7 04 24 7b 62 10 c0 	movl   $0xc010627b,(%esp)
c01019c6:	e8 c7 e8 ff ff       	call   c0100292 <cprintf>
    cprintf("  err  0x%08x\n", tf->tf_err);
c01019cb:	8b 45 08             	mov    0x8(%ebp),%eax
c01019ce:	8b 40 34             	mov    0x34(%eax),%eax
c01019d1:	89 44 24 04          	mov    %eax,0x4(%esp)
c01019d5:	c7 04 24 8d 62 10 c0 	movl   $0xc010628d,(%esp)
c01019dc:	e8 b1 e8 ff ff       	call   c0100292 <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
c01019e1:	8b 45 08             	mov    0x8(%ebp),%eax
c01019e4:	8b 40 38             	mov    0x38(%eax),%eax
c01019e7:	89 44 24 04          	mov    %eax,0x4(%esp)
c01019eb:	c7 04 24 9c 62 10 c0 	movl   $0xc010629c,(%esp)
c01019f2:	e8 9b e8 ff ff       	call   c0100292 <cprintf>
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
c01019f7:	8b 45 08             	mov    0x8(%ebp),%eax
c01019fa:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c01019fe:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101a02:	c7 04 24 ab 62 10 c0 	movl   $0xc01062ab,(%esp)
c0101a09:	e8 84 e8 ff ff       	call   c0100292 <cprintf>
    cprintf("  flag 0x%08x ", tf->tf_eflags);
c0101a0e:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a11:	8b 40 40             	mov    0x40(%eax),%eax
c0101a14:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101a18:	c7 04 24 be 62 10 c0 	movl   $0xc01062be,(%esp)
c0101a1f:	e8 6e e8 ff ff       	call   c0100292 <cprintf>

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
c0101a24:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0101a2b:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
c0101a32:	eb 3d                	jmp    c0101a71 <print_trapframe+0x150>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
c0101a34:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a37:	8b 50 40             	mov    0x40(%eax),%edx
c0101a3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0101a3d:	21 d0                	and    %edx,%eax
c0101a3f:	85 c0                	test   %eax,%eax
c0101a41:	74 28                	je     c0101a6b <print_trapframe+0x14a>
c0101a43:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101a46:	8b 04 85 80 75 11 c0 	mov    -0x3fee8a80(,%eax,4),%eax
c0101a4d:	85 c0                	test   %eax,%eax
c0101a4f:	74 1a                	je     c0101a6b <print_trapframe+0x14a>
            cprintf("%s,", IA32flags[i]);
c0101a51:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101a54:	8b 04 85 80 75 11 c0 	mov    -0x3fee8a80(,%eax,4),%eax
c0101a5b:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101a5f:	c7 04 24 cd 62 10 c0 	movl   $0xc01062cd,(%esp)
c0101a66:	e8 27 e8 ff ff       	call   c0100292 <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
    cprintf("  flag 0x%08x ", tf->tf_eflags);

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
c0101a6b:	ff 45 f4             	incl   -0xc(%ebp)
c0101a6e:	d1 65 f0             	shll   -0x10(%ebp)
c0101a71:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101a74:	83 f8 17             	cmp    $0x17,%eax
c0101a77:	76 bb                	jbe    c0101a34 <print_trapframe+0x113>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
            cprintf("%s,", IA32flags[i]);
        }
    }
    cprintf("IOPL=%d\n", (tf->tf_eflags & FL_IOPL_MASK) >> 12);
c0101a79:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a7c:	8b 40 40             	mov    0x40(%eax),%eax
c0101a7f:	25 00 30 00 00       	and    $0x3000,%eax
c0101a84:	c1 e8 0c             	shr    $0xc,%eax
c0101a87:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101a8b:	c7 04 24 d1 62 10 c0 	movl   $0xc01062d1,(%esp)
c0101a92:	e8 fb e7 ff ff       	call   c0100292 <cprintf>

    if (!trap_in_kernel(tf)) {
c0101a97:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a9a:	89 04 24             	mov    %eax,(%esp)
c0101a9d:	e8 6a fe ff ff       	call   c010190c <trap_in_kernel>
c0101aa2:	85 c0                	test   %eax,%eax
c0101aa4:	75 2d                	jne    c0101ad3 <print_trapframe+0x1b2>
        cprintf("  esp  0x%08x\n", tf->tf_esp);
c0101aa6:	8b 45 08             	mov    0x8(%ebp),%eax
c0101aa9:	8b 40 44             	mov    0x44(%eax),%eax
c0101aac:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101ab0:	c7 04 24 da 62 10 c0 	movl   $0xc01062da,(%esp)
c0101ab7:	e8 d6 e7 ff ff       	call   c0100292 <cprintf>
        cprintf("  ss   0x----%04x\n", tf->tf_ss);
c0101abc:	8b 45 08             	mov    0x8(%ebp),%eax
c0101abf:	0f b7 40 48          	movzwl 0x48(%eax),%eax
c0101ac3:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101ac7:	c7 04 24 e9 62 10 c0 	movl   $0xc01062e9,(%esp)
c0101ace:	e8 bf e7 ff ff       	call   c0100292 <cprintf>
    }
}
c0101ad3:	90                   	nop
c0101ad4:	c9                   	leave  
c0101ad5:	c3                   	ret    

c0101ad6 <print_regs>:

void
print_regs(struct pushregs *regs) {
c0101ad6:	55                   	push   %ebp
c0101ad7:	89 e5                	mov    %esp,%ebp
c0101ad9:	83 ec 18             	sub    $0x18,%esp
    cprintf("  edi  0x%08x\n", regs->reg_edi);
c0101adc:	8b 45 08             	mov    0x8(%ebp),%eax
c0101adf:	8b 00                	mov    (%eax),%eax
c0101ae1:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101ae5:	c7 04 24 fc 62 10 c0 	movl   $0xc01062fc,(%esp)
c0101aec:	e8 a1 e7 ff ff       	call   c0100292 <cprintf>
    cprintf("  esi  0x%08x\n", regs->reg_esi);
c0101af1:	8b 45 08             	mov    0x8(%ebp),%eax
c0101af4:	8b 40 04             	mov    0x4(%eax),%eax
c0101af7:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101afb:	c7 04 24 0b 63 10 c0 	movl   $0xc010630b,(%esp)
c0101b02:	e8 8b e7 ff ff       	call   c0100292 <cprintf>
    cprintf("  ebp  0x%08x\n", regs->reg_ebp);
c0101b07:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b0a:	8b 40 08             	mov    0x8(%eax),%eax
c0101b0d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101b11:	c7 04 24 1a 63 10 c0 	movl   $0xc010631a,(%esp)
c0101b18:	e8 75 e7 ff ff       	call   c0100292 <cprintf>
    cprintf("  oesp 0x%08x\n", regs->reg_oesp);
c0101b1d:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b20:	8b 40 0c             	mov    0xc(%eax),%eax
c0101b23:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101b27:	c7 04 24 29 63 10 c0 	movl   $0xc0106329,(%esp)
c0101b2e:	e8 5f e7 ff ff       	call   c0100292 <cprintf>
    cprintf("  ebx  0x%08x\n", regs->reg_ebx);
c0101b33:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b36:	8b 40 10             	mov    0x10(%eax),%eax
c0101b39:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101b3d:	c7 04 24 38 63 10 c0 	movl   $0xc0106338,(%esp)
c0101b44:	e8 49 e7 ff ff       	call   c0100292 <cprintf>
    cprintf("  edx  0x%08x\n", regs->reg_edx);
c0101b49:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b4c:	8b 40 14             	mov    0x14(%eax),%eax
c0101b4f:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101b53:	c7 04 24 47 63 10 c0 	movl   $0xc0106347,(%esp)
c0101b5a:	e8 33 e7 ff ff       	call   c0100292 <cprintf>
    cprintf("  ecx  0x%08x\n", regs->reg_ecx);
c0101b5f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b62:	8b 40 18             	mov    0x18(%eax),%eax
c0101b65:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101b69:	c7 04 24 56 63 10 c0 	movl   $0xc0106356,(%esp)
c0101b70:	e8 1d e7 ff ff       	call   c0100292 <cprintf>
    cprintf("  eax  0x%08x\n", regs->reg_eax);
c0101b75:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b78:	8b 40 1c             	mov    0x1c(%eax),%eax
c0101b7b:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101b7f:	c7 04 24 65 63 10 c0 	movl   $0xc0106365,(%esp)
c0101b86:	e8 07 e7 ff ff       	call   c0100292 <cprintf>
}
c0101b8b:	90                   	nop
c0101b8c:	c9                   	leave  
c0101b8d:	c3                   	ret    

c0101b8e <trap_dispatch>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static void
trap_dispatch(struct trapframe *tf) {
c0101b8e:	55                   	push   %ebp
c0101b8f:	89 e5                	mov    %esp,%ebp
c0101b91:	83 ec 28             	sub    $0x28,%esp
    char c;

    switch (tf->tf_trapno) {
c0101b94:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b97:	8b 40 30             	mov    0x30(%eax),%eax
c0101b9a:	83 f8 2f             	cmp    $0x2f,%eax
c0101b9d:	77 21                	ja     c0101bc0 <trap_dispatch+0x32>
c0101b9f:	83 f8 2e             	cmp    $0x2e,%eax
c0101ba2:	0f 83 09 01 00 00    	jae    c0101cb1 <trap_dispatch+0x123>
c0101ba8:	83 f8 21             	cmp    $0x21,%eax
c0101bab:	0f 84 89 00 00 00    	je     c0101c3a <trap_dispatch+0xac>
c0101bb1:	83 f8 24             	cmp    $0x24,%eax
c0101bb4:	74 5e                	je     c0101c14 <trap_dispatch+0x86>
c0101bb6:	83 f8 20             	cmp    $0x20,%eax
c0101bb9:	74 16                	je     c0101bd1 <trap_dispatch+0x43>
c0101bbb:	e9 bc 00 00 00       	jmp    c0101c7c <trap_dispatch+0xee>
c0101bc0:	83 e8 78             	sub    $0x78,%eax
c0101bc3:	83 f8 01             	cmp    $0x1,%eax
c0101bc6:	0f 87 b0 00 00 00    	ja     c0101c7c <trap_dispatch+0xee>
c0101bcc:	e9 8f 00 00 00       	jmp    c0101c60 <trap_dispatch+0xd2>
        /* handle the timer interrupt */
        /* (1) After a timer interrupt, you should record this event using a global variable (increase it), such as ticks in kern/driver/clock.c
         * (2) Every TICK_NUM cycle, you can print some info using a funciton, such as print_ticks().
         * (3) Too Simple? Yes, I think so!
         */
	if (++ticks % TICK_NUM == 0) {
c0101bd1:	a1 0c af 11 c0       	mov    0xc011af0c,%eax
c0101bd6:	8d 48 01             	lea    0x1(%eax),%ecx
c0101bd9:	89 0d 0c af 11 c0    	mov    %ecx,0xc011af0c
c0101bdf:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
c0101be4:	89 c8                	mov    %ecx,%eax
c0101be6:	f7 e2                	mul    %edx
c0101be8:	c1 ea 05             	shr    $0x5,%edx
c0101beb:	89 d0                	mov    %edx,%eax
c0101bed:	c1 e0 02             	shl    $0x2,%eax
c0101bf0:	01 d0                	add    %edx,%eax
c0101bf2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0101bf9:	01 d0                	add    %edx,%eax
c0101bfb:	c1 e0 02             	shl    $0x2,%eax
c0101bfe:	29 c1                	sub    %eax,%ecx
c0101c00:	89 ca                	mov    %ecx,%edx
c0101c02:	85 d2                	test   %edx,%edx
c0101c04:	0f 85 aa 00 00 00    	jne    c0101cb4 <trap_dispatch+0x126>
	    print_ticks();
c0101c0a:	e8 bb fb ff ff       	call   c01017ca <print_ticks>
	}
        break;
c0101c0f:	e9 a0 00 00 00       	jmp    c0101cb4 <trap_dispatch+0x126>
    case IRQ_OFFSET + IRQ_COM1:
        c = cons_getc();
c0101c14:	e8 76 f9 ff ff       	call   c010158f <cons_getc>
c0101c19:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("serial [%03d] %c\n", c, c);
c0101c1c:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
c0101c20:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c0101c24:	89 54 24 08          	mov    %edx,0x8(%esp)
c0101c28:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101c2c:	c7 04 24 74 63 10 c0 	movl   $0xc0106374,(%esp)
c0101c33:	e8 5a e6 ff ff       	call   c0100292 <cprintf>
        break;
c0101c38:	eb 7b                	jmp    c0101cb5 <trap_dispatch+0x127>
    case IRQ_OFFSET + IRQ_KBD:
        c = cons_getc();
c0101c3a:	e8 50 f9 ff ff       	call   c010158f <cons_getc>
c0101c3f:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("kbd [%03d] %c\n", c, c);
c0101c42:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
c0101c46:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c0101c4a:	89 54 24 08          	mov    %edx,0x8(%esp)
c0101c4e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101c52:	c7 04 24 86 63 10 c0 	movl   $0xc0106386,(%esp)
c0101c59:	e8 34 e6 ff ff       	call   c0100292 <cprintf>
        break;
c0101c5e:	eb 55                	jmp    c0101cb5 <trap_dispatch+0x127>
    //LAB1 CHALLENGE 1 : YOUR CODE you should modify below codes.
    case T_SWITCH_TOU:
    case T_SWITCH_TOK:
        panic("T_SWITCH_** ??\n");
c0101c60:	c7 44 24 08 95 63 10 	movl   $0xc0106395,0x8(%esp)
c0101c67:	c0 
c0101c68:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
c0101c6f:	00 
c0101c70:	c7 04 24 a5 63 10 c0 	movl   $0xc01063a5,(%esp)
c0101c77:	e8 6d e7 ff ff       	call   c01003e9 <__panic>
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
    default:
        // in kernel, it must be a mistake
        if ((tf->tf_cs & 3) == 0) {
c0101c7c:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c7f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101c83:	83 e0 03             	and    $0x3,%eax
c0101c86:	85 c0                	test   %eax,%eax
c0101c88:	75 2b                	jne    c0101cb5 <trap_dispatch+0x127>
            print_trapframe(tf);
c0101c8a:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c8d:	89 04 24             	mov    %eax,(%esp)
c0101c90:	e8 8c fc ff ff       	call   c0101921 <print_trapframe>
            panic("unexpected trap in kernel.\n");
c0101c95:	c7 44 24 08 b6 63 10 	movl   $0xc01063b6,0x8(%esp)
c0101c9c:	c0 
c0101c9d:	c7 44 24 04 b4 00 00 	movl   $0xb4,0x4(%esp)
c0101ca4:	00 
c0101ca5:	c7 04 24 a5 63 10 c0 	movl   $0xc01063a5,(%esp)
c0101cac:	e8 38 e7 ff ff       	call   c01003e9 <__panic>
        panic("T_SWITCH_** ??\n");
        break;
    case IRQ_OFFSET + IRQ_IDE1:
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
c0101cb1:	90                   	nop
c0101cb2:	eb 01                	jmp    c0101cb5 <trap_dispatch+0x127>
         * (3) Too Simple? Yes, I think so!
         */
	if (++ticks % TICK_NUM == 0) {
	    print_ticks();
	}
        break;
c0101cb4:	90                   	nop
        if ((tf->tf_cs & 3) == 0) {
            print_trapframe(tf);
            panic("unexpected trap in kernel.\n");
        }
    }
}
c0101cb5:	90                   	nop
c0101cb6:	c9                   	leave  
c0101cb7:	c3                   	ret    

c0101cb8 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
c0101cb8:	55                   	push   %ebp
c0101cb9:	89 e5                	mov    %esp,%ebp
c0101cbb:	83 ec 18             	sub    $0x18,%esp
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
c0101cbe:	8b 45 08             	mov    0x8(%ebp),%eax
c0101cc1:	89 04 24             	mov    %eax,(%esp)
c0101cc4:	e8 c5 fe ff ff       	call   c0101b8e <trap_dispatch>
}
c0101cc9:	90                   	nop
c0101cca:	c9                   	leave  
c0101ccb:	c3                   	ret    

c0101ccc <vector0>:
# handler
.text
.globl __alltraps
.globl vector0
vector0:
  pushl $0
c0101ccc:	6a 00                	push   $0x0
  pushl $0
c0101cce:	6a 00                	push   $0x0
  jmp __alltraps
c0101cd0:	e9 69 0a 00 00       	jmp    c010273e <__alltraps>

c0101cd5 <vector1>:
.globl vector1
vector1:
  pushl $0
c0101cd5:	6a 00                	push   $0x0
  pushl $1
c0101cd7:	6a 01                	push   $0x1
  jmp __alltraps
c0101cd9:	e9 60 0a 00 00       	jmp    c010273e <__alltraps>

c0101cde <vector2>:
.globl vector2
vector2:
  pushl $0
c0101cde:	6a 00                	push   $0x0
  pushl $2
c0101ce0:	6a 02                	push   $0x2
  jmp __alltraps
c0101ce2:	e9 57 0a 00 00       	jmp    c010273e <__alltraps>

c0101ce7 <vector3>:
.globl vector3
vector3:
  pushl $0
c0101ce7:	6a 00                	push   $0x0
  pushl $3
c0101ce9:	6a 03                	push   $0x3
  jmp __alltraps
c0101ceb:	e9 4e 0a 00 00       	jmp    c010273e <__alltraps>

c0101cf0 <vector4>:
.globl vector4
vector4:
  pushl $0
c0101cf0:	6a 00                	push   $0x0
  pushl $4
c0101cf2:	6a 04                	push   $0x4
  jmp __alltraps
c0101cf4:	e9 45 0a 00 00       	jmp    c010273e <__alltraps>

c0101cf9 <vector5>:
.globl vector5
vector5:
  pushl $0
c0101cf9:	6a 00                	push   $0x0
  pushl $5
c0101cfb:	6a 05                	push   $0x5
  jmp __alltraps
c0101cfd:	e9 3c 0a 00 00       	jmp    c010273e <__alltraps>

c0101d02 <vector6>:
.globl vector6
vector6:
  pushl $0
c0101d02:	6a 00                	push   $0x0
  pushl $6
c0101d04:	6a 06                	push   $0x6
  jmp __alltraps
c0101d06:	e9 33 0a 00 00       	jmp    c010273e <__alltraps>

c0101d0b <vector7>:
.globl vector7
vector7:
  pushl $0
c0101d0b:	6a 00                	push   $0x0
  pushl $7
c0101d0d:	6a 07                	push   $0x7
  jmp __alltraps
c0101d0f:	e9 2a 0a 00 00       	jmp    c010273e <__alltraps>

c0101d14 <vector8>:
.globl vector8
vector8:
  pushl $8
c0101d14:	6a 08                	push   $0x8
  jmp __alltraps
c0101d16:	e9 23 0a 00 00       	jmp    c010273e <__alltraps>

c0101d1b <vector9>:
.globl vector9
vector9:
  pushl $0
c0101d1b:	6a 00                	push   $0x0
  pushl $9
c0101d1d:	6a 09                	push   $0x9
  jmp __alltraps
c0101d1f:	e9 1a 0a 00 00       	jmp    c010273e <__alltraps>

c0101d24 <vector10>:
.globl vector10
vector10:
  pushl $10
c0101d24:	6a 0a                	push   $0xa
  jmp __alltraps
c0101d26:	e9 13 0a 00 00       	jmp    c010273e <__alltraps>

c0101d2b <vector11>:
.globl vector11
vector11:
  pushl $11
c0101d2b:	6a 0b                	push   $0xb
  jmp __alltraps
c0101d2d:	e9 0c 0a 00 00       	jmp    c010273e <__alltraps>

c0101d32 <vector12>:
.globl vector12
vector12:
  pushl $12
c0101d32:	6a 0c                	push   $0xc
  jmp __alltraps
c0101d34:	e9 05 0a 00 00       	jmp    c010273e <__alltraps>

c0101d39 <vector13>:
.globl vector13
vector13:
  pushl $13
c0101d39:	6a 0d                	push   $0xd
  jmp __alltraps
c0101d3b:	e9 fe 09 00 00       	jmp    c010273e <__alltraps>

c0101d40 <vector14>:
.globl vector14
vector14:
  pushl $14
c0101d40:	6a 0e                	push   $0xe
  jmp __alltraps
c0101d42:	e9 f7 09 00 00       	jmp    c010273e <__alltraps>

c0101d47 <vector15>:
.globl vector15
vector15:
  pushl $0
c0101d47:	6a 00                	push   $0x0
  pushl $15
c0101d49:	6a 0f                	push   $0xf
  jmp __alltraps
c0101d4b:	e9 ee 09 00 00       	jmp    c010273e <__alltraps>

c0101d50 <vector16>:
.globl vector16
vector16:
  pushl $0
c0101d50:	6a 00                	push   $0x0
  pushl $16
c0101d52:	6a 10                	push   $0x10
  jmp __alltraps
c0101d54:	e9 e5 09 00 00       	jmp    c010273e <__alltraps>

c0101d59 <vector17>:
.globl vector17
vector17:
  pushl $17
c0101d59:	6a 11                	push   $0x11
  jmp __alltraps
c0101d5b:	e9 de 09 00 00       	jmp    c010273e <__alltraps>

c0101d60 <vector18>:
.globl vector18
vector18:
  pushl $0
c0101d60:	6a 00                	push   $0x0
  pushl $18
c0101d62:	6a 12                	push   $0x12
  jmp __alltraps
c0101d64:	e9 d5 09 00 00       	jmp    c010273e <__alltraps>

c0101d69 <vector19>:
.globl vector19
vector19:
  pushl $0
c0101d69:	6a 00                	push   $0x0
  pushl $19
c0101d6b:	6a 13                	push   $0x13
  jmp __alltraps
c0101d6d:	e9 cc 09 00 00       	jmp    c010273e <__alltraps>

c0101d72 <vector20>:
.globl vector20
vector20:
  pushl $0
c0101d72:	6a 00                	push   $0x0
  pushl $20
c0101d74:	6a 14                	push   $0x14
  jmp __alltraps
c0101d76:	e9 c3 09 00 00       	jmp    c010273e <__alltraps>

c0101d7b <vector21>:
.globl vector21
vector21:
  pushl $0
c0101d7b:	6a 00                	push   $0x0
  pushl $21
c0101d7d:	6a 15                	push   $0x15
  jmp __alltraps
c0101d7f:	e9 ba 09 00 00       	jmp    c010273e <__alltraps>

c0101d84 <vector22>:
.globl vector22
vector22:
  pushl $0
c0101d84:	6a 00                	push   $0x0
  pushl $22
c0101d86:	6a 16                	push   $0x16
  jmp __alltraps
c0101d88:	e9 b1 09 00 00       	jmp    c010273e <__alltraps>

c0101d8d <vector23>:
.globl vector23
vector23:
  pushl $0
c0101d8d:	6a 00                	push   $0x0
  pushl $23
c0101d8f:	6a 17                	push   $0x17
  jmp __alltraps
c0101d91:	e9 a8 09 00 00       	jmp    c010273e <__alltraps>

c0101d96 <vector24>:
.globl vector24
vector24:
  pushl $0
c0101d96:	6a 00                	push   $0x0
  pushl $24
c0101d98:	6a 18                	push   $0x18
  jmp __alltraps
c0101d9a:	e9 9f 09 00 00       	jmp    c010273e <__alltraps>

c0101d9f <vector25>:
.globl vector25
vector25:
  pushl $0
c0101d9f:	6a 00                	push   $0x0
  pushl $25
c0101da1:	6a 19                	push   $0x19
  jmp __alltraps
c0101da3:	e9 96 09 00 00       	jmp    c010273e <__alltraps>

c0101da8 <vector26>:
.globl vector26
vector26:
  pushl $0
c0101da8:	6a 00                	push   $0x0
  pushl $26
c0101daa:	6a 1a                	push   $0x1a
  jmp __alltraps
c0101dac:	e9 8d 09 00 00       	jmp    c010273e <__alltraps>

c0101db1 <vector27>:
.globl vector27
vector27:
  pushl $0
c0101db1:	6a 00                	push   $0x0
  pushl $27
c0101db3:	6a 1b                	push   $0x1b
  jmp __alltraps
c0101db5:	e9 84 09 00 00       	jmp    c010273e <__alltraps>

c0101dba <vector28>:
.globl vector28
vector28:
  pushl $0
c0101dba:	6a 00                	push   $0x0
  pushl $28
c0101dbc:	6a 1c                	push   $0x1c
  jmp __alltraps
c0101dbe:	e9 7b 09 00 00       	jmp    c010273e <__alltraps>

c0101dc3 <vector29>:
.globl vector29
vector29:
  pushl $0
c0101dc3:	6a 00                	push   $0x0
  pushl $29
c0101dc5:	6a 1d                	push   $0x1d
  jmp __alltraps
c0101dc7:	e9 72 09 00 00       	jmp    c010273e <__alltraps>

c0101dcc <vector30>:
.globl vector30
vector30:
  pushl $0
c0101dcc:	6a 00                	push   $0x0
  pushl $30
c0101dce:	6a 1e                	push   $0x1e
  jmp __alltraps
c0101dd0:	e9 69 09 00 00       	jmp    c010273e <__alltraps>

c0101dd5 <vector31>:
.globl vector31
vector31:
  pushl $0
c0101dd5:	6a 00                	push   $0x0
  pushl $31
c0101dd7:	6a 1f                	push   $0x1f
  jmp __alltraps
c0101dd9:	e9 60 09 00 00       	jmp    c010273e <__alltraps>

c0101dde <vector32>:
.globl vector32
vector32:
  pushl $0
c0101dde:	6a 00                	push   $0x0
  pushl $32
c0101de0:	6a 20                	push   $0x20
  jmp __alltraps
c0101de2:	e9 57 09 00 00       	jmp    c010273e <__alltraps>

c0101de7 <vector33>:
.globl vector33
vector33:
  pushl $0
c0101de7:	6a 00                	push   $0x0
  pushl $33
c0101de9:	6a 21                	push   $0x21
  jmp __alltraps
c0101deb:	e9 4e 09 00 00       	jmp    c010273e <__alltraps>

c0101df0 <vector34>:
.globl vector34
vector34:
  pushl $0
c0101df0:	6a 00                	push   $0x0
  pushl $34
c0101df2:	6a 22                	push   $0x22
  jmp __alltraps
c0101df4:	e9 45 09 00 00       	jmp    c010273e <__alltraps>

c0101df9 <vector35>:
.globl vector35
vector35:
  pushl $0
c0101df9:	6a 00                	push   $0x0
  pushl $35
c0101dfb:	6a 23                	push   $0x23
  jmp __alltraps
c0101dfd:	e9 3c 09 00 00       	jmp    c010273e <__alltraps>

c0101e02 <vector36>:
.globl vector36
vector36:
  pushl $0
c0101e02:	6a 00                	push   $0x0
  pushl $36
c0101e04:	6a 24                	push   $0x24
  jmp __alltraps
c0101e06:	e9 33 09 00 00       	jmp    c010273e <__alltraps>

c0101e0b <vector37>:
.globl vector37
vector37:
  pushl $0
c0101e0b:	6a 00                	push   $0x0
  pushl $37
c0101e0d:	6a 25                	push   $0x25
  jmp __alltraps
c0101e0f:	e9 2a 09 00 00       	jmp    c010273e <__alltraps>

c0101e14 <vector38>:
.globl vector38
vector38:
  pushl $0
c0101e14:	6a 00                	push   $0x0
  pushl $38
c0101e16:	6a 26                	push   $0x26
  jmp __alltraps
c0101e18:	e9 21 09 00 00       	jmp    c010273e <__alltraps>

c0101e1d <vector39>:
.globl vector39
vector39:
  pushl $0
c0101e1d:	6a 00                	push   $0x0
  pushl $39
c0101e1f:	6a 27                	push   $0x27
  jmp __alltraps
c0101e21:	e9 18 09 00 00       	jmp    c010273e <__alltraps>

c0101e26 <vector40>:
.globl vector40
vector40:
  pushl $0
c0101e26:	6a 00                	push   $0x0
  pushl $40
c0101e28:	6a 28                	push   $0x28
  jmp __alltraps
c0101e2a:	e9 0f 09 00 00       	jmp    c010273e <__alltraps>

c0101e2f <vector41>:
.globl vector41
vector41:
  pushl $0
c0101e2f:	6a 00                	push   $0x0
  pushl $41
c0101e31:	6a 29                	push   $0x29
  jmp __alltraps
c0101e33:	e9 06 09 00 00       	jmp    c010273e <__alltraps>

c0101e38 <vector42>:
.globl vector42
vector42:
  pushl $0
c0101e38:	6a 00                	push   $0x0
  pushl $42
c0101e3a:	6a 2a                	push   $0x2a
  jmp __alltraps
c0101e3c:	e9 fd 08 00 00       	jmp    c010273e <__alltraps>

c0101e41 <vector43>:
.globl vector43
vector43:
  pushl $0
c0101e41:	6a 00                	push   $0x0
  pushl $43
c0101e43:	6a 2b                	push   $0x2b
  jmp __alltraps
c0101e45:	e9 f4 08 00 00       	jmp    c010273e <__alltraps>

c0101e4a <vector44>:
.globl vector44
vector44:
  pushl $0
c0101e4a:	6a 00                	push   $0x0
  pushl $44
c0101e4c:	6a 2c                	push   $0x2c
  jmp __alltraps
c0101e4e:	e9 eb 08 00 00       	jmp    c010273e <__alltraps>

c0101e53 <vector45>:
.globl vector45
vector45:
  pushl $0
c0101e53:	6a 00                	push   $0x0
  pushl $45
c0101e55:	6a 2d                	push   $0x2d
  jmp __alltraps
c0101e57:	e9 e2 08 00 00       	jmp    c010273e <__alltraps>

c0101e5c <vector46>:
.globl vector46
vector46:
  pushl $0
c0101e5c:	6a 00                	push   $0x0
  pushl $46
c0101e5e:	6a 2e                	push   $0x2e
  jmp __alltraps
c0101e60:	e9 d9 08 00 00       	jmp    c010273e <__alltraps>

c0101e65 <vector47>:
.globl vector47
vector47:
  pushl $0
c0101e65:	6a 00                	push   $0x0
  pushl $47
c0101e67:	6a 2f                	push   $0x2f
  jmp __alltraps
c0101e69:	e9 d0 08 00 00       	jmp    c010273e <__alltraps>

c0101e6e <vector48>:
.globl vector48
vector48:
  pushl $0
c0101e6e:	6a 00                	push   $0x0
  pushl $48
c0101e70:	6a 30                	push   $0x30
  jmp __alltraps
c0101e72:	e9 c7 08 00 00       	jmp    c010273e <__alltraps>

c0101e77 <vector49>:
.globl vector49
vector49:
  pushl $0
c0101e77:	6a 00                	push   $0x0
  pushl $49
c0101e79:	6a 31                	push   $0x31
  jmp __alltraps
c0101e7b:	e9 be 08 00 00       	jmp    c010273e <__alltraps>

c0101e80 <vector50>:
.globl vector50
vector50:
  pushl $0
c0101e80:	6a 00                	push   $0x0
  pushl $50
c0101e82:	6a 32                	push   $0x32
  jmp __alltraps
c0101e84:	e9 b5 08 00 00       	jmp    c010273e <__alltraps>

c0101e89 <vector51>:
.globl vector51
vector51:
  pushl $0
c0101e89:	6a 00                	push   $0x0
  pushl $51
c0101e8b:	6a 33                	push   $0x33
  jmp __alltraps
c0101e8d:	e9 ac 08 00 00       	jmp    c010273e <__alltraps>

c0101e92 <vector52>:
.globl vector52
vector52:
  pushl $0
c0101e92:	6a 00                	push   $0x0
  pushl $52
c0101e94:	6a 34                	push   $0x34
  jmp __alltraps
c0101e96:	e9 a3 08 00 00       	jmp    c010273e <__alltraps>

c0101e9b <vector53>:
.globl vector53
vector53:
  pushl $0
c0101e9b:	6a 00                	push   $0x0
  pushl $53
c0101e9d:	6a 35                	push   $0x35
  jmp __alltraps
c0101e9f:	e9 9a 08 00 00       	jmp    c010273e <__alltraps>

c0101ea4 <vector54>:
.globl vector54
vector54:
  pushl $0
c0101ea4:	6a 00                	push   $0x0
  pushl $54
c0101ea6:	6a 36                	push   $0x36
  jmp __alltraps
c0101ea8:	e9 91 08 00 00       	jmp    c010273e <__alltraps>

c0101ead <vector55>:
.globl vector55
vector55:
  pushl $0
c0101ead:	6a 00                	push   $0x0
  pushl $55
c0101eaf:	6a 37                	push   $0x37
  jmp __alltraps
c0101eb1:	e9 88 08 00 00       	jmp    c010273e <__alltraps>

c0101eb6 <vector56>:
.globl vector56
vector56:
  pushl $0
c0101eb6:	6a 00                	push   $0x0
  pushl $56
c0101eb8:	6a 38                	push   $0x38
  jmp __alltraps
c0101eba:	e9 7f 08 00 00       	jmp    c010273e <__alltraps>

c0101ebf <vector57>:
.globl vector57
vector57:
  pushl $0
c0101ebf:	6a 00                	push   $0x0
  pushl $57
c0101ec1:	6a 39                	push   $0x39
  jmp __alltraps
c0101ec3:	e9 76 08 00 00       	jmp    c010273e <__alltraps>

c0101ec8 <vector58>:
.globl vector58
vector58:
  pushl $0
c0101ec8:	6a 00                	push   $0x0
  pushl $58
c0101eca:	6a 3a                	push   $0x3a
  jmp __alltraps
c0101ecc:	e9 6d 08 00 00       	jmp    c010273e <__alltraps>

c0101ed1 <vector59>:
.globl vector59
vector59:
  pushl $0
c0101ed1:	6a 00                	push   $0x0
  pushl $59
c0101ed3:	6a 3b                	push   $0x3b
  jmp __alltraps
c0101ed5:	e9 64 08 00 00       	jmp    c010273e <__alltraps>

c0101eda <vector60>:
.globl vector60
vector60:
  pushl $0
c0101eda:	6a 00                	push   $0x0
  pushl $60
c0101edc:	6a 3c                	push   $0x3c
  jmp __alltraps
c0101ede:	e9 5b 08 00 00       	jmp    c010273e <__alltraps>

c0101ee3 <vector61>:
.globl vector61
vector61:
  pushl $0
c0101ee3:	6a 00                	push   $0x0
  pushl $61
c0101ee5:	6a 3d                	push   $0x3d
  jmp __alltraps
c0101ee7:	e9 52 08 00 00       	jmp    c010273e <__alltraps>

c0101eec <vector62>:
.globl vector62
vector62:
  pushl $0
c0101eec:	6a 00                	push   $0x0
  pushl $62
c0101eee:	6a 3e                	push   $0x3e
  jmp __alltraps
c0101ef0:	e9 49 08 00 00       	jmp    c010273e <__alltraps>

c0101ef5 <vector63>:
.globl vector63
vector63:
  pushl $0
c0101ef5:	6a 00                	push   $0x0
  pushl $63
c0101ef7:	6a 3f                	push   $0x3f
  jmp __alltraps
c0101ef9:	e9 40 08 00 00       	jmp    c010273e <__alltraps>

c0101efe <vector64>:
.globl vector64
vector64:
  pushl $0
c0101efe:	6a 00                	push   $0x0
  pushl $64
c0101f00:	6a 40                	push   $0x40
  jmp __alltraps
c0101f02:	e9 37 08 00 00       	jmp    c010273e <__alltraps>

c0101f07 <vector65>:
.globl vector65
vector65:
  pushl $0
c0101f07:	6a 00                	push   $0x0
  pushl $65
c0101f09:	6a 41                	push   $0x41
  jmp __alltraps
c0101f0b:	e9 2e 08 00 00       	jmp    c010273e <__alltraps>

c0101f10 <vector66>:
.globl vector66
vector66:
  pushl $0
c0101f10:	6a 00                	push   $0x0
  pushl $66
c0101f12:	6a 42                	push   $0x42
  jmp __alltraps
c0101f14:	e9 25 08 00 00       	jmp    c010273e <__alltraps>

c0101f19 <vector67>:
.globl vector67
vector67:
  pushl $0
c0101f19:	6a 00                	push   $0x0
  pushl $67
c0101f1b:	6a 43                	push   $0x43
  jmp __alltraps
c0101f1d:	e9 1c 08 00 00       	jmp    c010273e <__alltraps>

c0101f22 <vector68>:
.globl vector68
vector68:
  pushl $0
c0101f22:	6a 00                	push   $0x0
  pushl $68
c0101f24:	6a 44                	push   $0x44
  jmp __alltraps
c0101f26:	e9 13 08 00 00       	jmp    c010273e <__alltraps>

c0101f2b <vector69>:
.globl vector69
vector69:
  pushl $0
c0101f2b:	6a 00                	push   $0x0
  pushl $69
c0101f2d:	6a 45                	push   $0x45
  jmp __alltraps
c0101f2f:	e9 0a 08 00 00       	jmp    c010273e <__alltraps>

c0101f34 <vector70>:
.globl vector70
vector70:
  pushl $0
c0101f34:	6a 00                	push   $0x0
  pushl $70
c0101f36:	6a 46                	push   $0x46
  jmp __alltraps
c0101f38:	e9 01 08 00 00       	jmp    c010273e <__alltraps>

c0101f3d <vector71>:
.globl vector71
vector71:
  pushl $0
c0101f3d:	6a 00                	push   $0x0
  pushl $71
c0101f3f:	6a 47                	push   $0x47
  jmp __alltraps
c0101f41:	e9 f8 07 00 00       	jmp    c010273e <__alltraps>

c0101f46 <vector72>:
.globl vector72
vector72:
  pushl $0
c0101f46:	6a 00                	push   $0x0
  pushl $72
c0101f48:	6a 48                	push   $0x48
  jmp __alltraps
c0101f4a:	e9 ef 07 00 00       	jmp    c010273e <__alltraps>

c0101f4f <vector73>:
.globl vector73
vector73:
  pushl $0
c0101f4f:	6a 00                	push   $0x0
  pushl $73
c0101f51:	6a 49                	push   $0x49
  jmp __alltraps
c0101f53:	e9 e6 07 00 00       	jmp    c010273e <__alltraps>

c0101f58 <vector74>:
.globl vector74
vector74:
  pushl $0
c0101f58:	6a 00                	push   $0x0
  pushl $74
c0101f5a:	6a 4a                	push   $0x4a
  jmp __alltraps
c0101f5c:	e9 dd 07 00 00       	jmp    c010273e <__alltraps>

c0101f61 <vector75>:
.globl vector75
vector75:
  pushl $0
c0101f61:	6a 00                	push   $0x0
  pushl $75
c0101f63:	6a 4b                	push   $0x4b
  jmp __alltraps
c0101f65:	e9 d4 07 00 00       	jmp    c010273e <__alltraps>

c0101f6a <vector76>:
.globl vector76
vector76:
  pushl $0
c0101f6a:	6a 00                	push   $0x0
  pushl $76
c0101f6c:	6a 4c                	push   $0x4c
  jmp __alltraps
c0101f6e:	e9 cb 07 00 00       	jmp    c010273e <__alltraps>

c0101f73 <vector77>:
.globl vector77
vector77:
  pushl $0
c0101f73:	6a 00                	push   $0x0
  pushl $77
c0101f75:	6a 4d                	push   $0x4d
  jmp __alltraps
c0101f77:	e9 c2 07 00 00       	jmp    c010273e <__alltraps>

c0101f7c <vector78>:
.globl vector78
vector78:
  pushl $0
c0101f7c:	6a 00                	push   $0x0
  pushl $78
c0101f7e:	6a 4e                	push   $0x4e
  jmp __alltraps
c0101f80:	e9 b9 07 00 00       	jmp    c010273e <__alltraps>

c0101f85 <vector79>:
.globl vector79
vector79:
  pushl $0
c0101f85:	6a 00                	push   $0x0
  pushl $79
c0101f87:	6a 4f                	push   $0x4f
  jmp __alltraps
c0101f89:	e9 b0 07 00 00       	jmp    c010273e <__alltraps>

c0101f8e <vector80>:
.globl vector80
vector80:
  pushl $0
c0101f8e:	6a 00                	push   $0x0
  pushl $80
c0101f90:	6a 50                	push   $0x50
  jmp __alltraps
c0101f92:	e9 a7 07 00 00       	jmp    c010273e <__alltraps>

c0101f97 <vector81>:
.globl vector81
vector81:
  pushl $0
c0101f97:	6a 00                	push   $0x0
  pushl $81
c0101f99:	6a 51                	push   $0x51
  jmp __alltraps
c0101f9b:	e9 9e 07 00 00       	jmp    c010273e <__alltraps>

c0101fa0 <vector82>:
.globl vector82
vector82:
  pushl $0
c0101fa0:	6a 00                	push   $0x0
  pushl $82
c0101fa2:	6a 52                	push   $0x52
  jmp __alltraps
c0101fa4:	e9 95 07 00 00       	jmp    c010273e <__alltraps>

c0101fa9 <vector83>:
.globl vector83
vector83:
  pushl $0
c0101fa9:	6a 00                	push   $0x0
  pushl $83
c0101fab:	6a 53                	push   $0x53
  jmp __alltraps
c0101fad:	e9 8c 07 00 00       	jmp    c010273e <__alltraps>

c0101fb2 <vector84>:
.globl vector84
vector84:
  pushl $0
c0101fb2:	6a 00                	push   $0x0
  pushl $84
c0101fb4:	6a 54                	push   $0x54
  jmp __alltraps
c0101fb6:	e9 83 07 00 00       	jmp    c010273e <__alltraps>

c0101fbb <vector85>:
.globl vector85
vector85:
  pushl $0
c0101fbb:	6a 00                	push   $0x0
  pushl $85
c0101fbd:	6a 55                	push   $0x55
  jmp __alltraps
c0101fbf:	e9 7a 07 00 00       	jmp    c010273e <__alltraps>

c0101fc4 <vector86>:
.globl vector86
vector86:
  pushl $0
c0101fc4:	6a 00                	push   $0x0
  pushl $86
c0101fc6:	6a 56                	push   $0x56
  jmp __alltraps
c0101fc8:	e9 71 07 00 00       	jmp    c010273e <__alltraps>

c0101fcd <vector87>:
.globl vector87
vector87:
  pushl $0
c0101fcd:	6a 00                	push   $0x0
  pushl $87
c0101fcf:	6a 57                	push   $0x57
  jmp __alltraps
c0101fd1:	e9 68 07 00 00       	jmp    c010273e <__alltraps>

c0101fd6 <vector88>:
.globl vector88
vector88:
  pushl $0
c0101fd6:	6a 00                	push   $0x0
  pushl $88
c0101fd8:	6a 58                	push   $0x58
  jmp __alltraps
c0101fda:	e9 5f 07 00 00       	jmp    c010273e <__alltraps>

c0101fdf <vector89>:
.globl vector89
vector89:
  pushl $0
c0101fdf:	6a 00                	push   $0x0
  pushl $89
c0101fe1:	6a 59                	push   $0x59
  jmp __alltraps
c0101fe3:	e9 56 07 00 00       	jmp    c010273e <__alltraps>

c0101fe8 <vector90>:
.globl vector90
vector90:
  pushl $0
c0101fe8:	6a 00                	push   $0x0
  pushl $90
c0101fea:	6a 5a                	push   $0x5a
  jmp __alltraps
c0101fec:	e9 4d 07 00 00       	jmp    c010273e <__alltraps>

c0101ff1 <vector91>:
.globl vector91
vector91:
  pushl $0
c0101ff1:	6a 00                	push   $0x0
  pushl $91
c0101ff3:	6a 5b                	push   $0x5b
  jmp __alltraps
c0101ff5:	e9 44 07 00 00       	jmp    c010273e <__alltraps>

c0101ffa <vector92>:
.globl vector92
vector92:
  pushl $0
c0101ffa:	6a 00                	push   $0x0
  pushl $92
c0101ffc:	6a 5c                	push   $0x5c
  jmp __alltraps
c0101ffe:	e9 3b 07 00 00       	jmp    c010273e <__alltraps>

c0102003 <vector93>:
.globl vector93
vector93:
  pushl $0
c0102003:	6a 00                	push   $0x0
  pushl $93
c0102005:	6a 5d                	push   $0x5d
  jmp __alltraps
c0102007:	e9 32 07 00 00       	jmp    c010273e <__alltraps>

c010200c <vector94>:
.globl vector94
vector94:
  pushl $0
c010200c:	6a 00                	push   $0x0
  pushl $94
c010200e:	6a 5e                	push   $0x5e
  jmp __alltraps
c0102010:	e9 29 07 00 00       	jmp    c010273e <__alltraps>

c0102015 <vector95>:
.globl vector95
vector95:
  pushl $0
c0102015:	6a 00                	push   $0x0
  pushl $95
c0102017:	6a 5f                	push   $0x5f
  jmp __alltraps
c0102019:	e9 20 07 00 00       	jmp    c010273e <__alltraps>

c010201e <vector96>:
.globl vector96
vector96:
  pushl $0
c010201e:	6a 00                	push   $0x0
  pushl $96
c0102020:	6a 60                	push   $0x60
  jmp __alltraps
c0102022:	e9 17 07 00 00       	jmp    c010273e <__alltraps>

c0102027 <vector97>:
.globl vector97
vector97:
  pushl $0
c0102027:	6a 00                	push   $0x0
  pushl $97
c0102029:	6a 61                	push   $0x61
  jmp __alltraps
c010202b:	e9 0e 07 00 00       	jmp    c010273e <__alltraps>

c0102030 <vector98>:
.globl vector98
vector98:
  pushl $0
c0102030:	6a 00                	push   $0x0
  pushl $98
c0102032:	6a 62                	push   $0x62
  jmp __alltraps
c0102034:	e9 05 07 00 00       	jmp    c010273e <__alltraps>

c0102039 <vector99>:
.globl vector99
vector99:
  pushl $0
c0102039:	6a 00                	push   $0x0
  pushl $99
c010203b:	6a 63                	push   $0x63
  jmp __alltraps
c010203d:	e9 fc 06 00 00       	jmp    c010273e <__alltraps>

c0102042 <vector100>:
.globl vector100
vector100:
  pushl $0
c0102042:	6a 00                	push   $0x0
  pushl $100
c0102044:	6a 64                	push   $0x64
  jmp __alltraps
c0102046:	e9 f3 06 00 00       	jmp    c010273e <__alltraps>

c010204b <vector101>:
.globl vector101
vector101:
  pushl $0
c010204b:	6a 00                	push   $0x0
  pushl $101
c010204d:	6a 65                	push   $0x65
  jmp __alltraps
c010204f:	e9 ea 06 00 00       	jmp    c010273e <__alltraps>

c0102054 <vector102>:
.globl vector102
vector102:
  pushl $0
c0102054:	6a 00                	push   $0x0
  pushl $102
c0102056:	6a 66                	push   $0x66
  jmp __alltraps
c0102058:	e9 e1 06 00 00       	jmp    c010273e <__alltraps>

c010205d <vector103>:
.globl vector103
vector103:
  pushl $0
c010205d:	6a 00                	push   $0x0
  pushl $103
c010205f:	6a 67                	push   $0x67
  jmp __alltraps
c0102061:	e9 d8 06 00 00       	jmp    c010273e <__alltraps>

c0102066 <vector104>:
.globl vector104
vector104:
  pushl $0
c0102066:	6a 00                	push   $0x0
  pushl $104
c0102068:	6a 68                	push   $0x68
  jmp __alltraps
c010206a:	e9 cf 06 00 00       	jmp    c010273e <__alltraps>

c010206f <vector105>:
.globl vector105
vector105:
  pushl $0
c010206f:	6a 00                	push   $0x0
  pushl $105
c0102071:	6a 69                	push   $0x69
  jmp __alltraps
c0102073:	e9 c6 06 00 00       	jmp    c010273e <__alltraps>

c0102078 <vector106>:
.globl vector106
vector106:
  pushl $0
c0102078:	6a 00                	push   $0x0
  pushl $106
c010207a:	6a 6a                	push   $0x6a
  jmp __alltraps
c010207c:	e9 bd 06 00 00       	jmp    c010273e <__alltraps>

c0102081 <vector107>:
.globl vector107
vector107:
  pushl $0
c0102081:	6a 00                	push   $0x0
  pushl $107
c0102083:	6a 6b                	push   $0x6b
  jmp __alltraps
c0102085:	e9 b4 06 00 00       	jmp    c010273e <__alltraps>

c010208a <vector108>:
.globl vector108
vector108:
  pushl $0
c010208a:	6a 00                	push   $0x0
  pushl $108
c010208c:	6a 6c                	push   $0x6c
  jmp __alltraps
c010208e:	e9 ab 06 00 00       	jmp    c010273e <__alltraps>

c0102093 <vector109>:
.globl vector109
vector109:
  pushl $0
c0102093:	6a 00                	push   $0x0
  pushl $109
c0102095:	6a 6d                	push   $0x6d
  jmp __alltraps
c0102097:	e9 a2 06 00 00       	jmp    c010273e <__alltraps>

c010209c <vector110>:
.globl vector110
vector110:
  pushl $0
c010209c:	6a 00                	push   $0x0
  pushl $110
c010209e:	6a 6e                	push   $0x6e
  jmp __alltraps
c01020a0:	e9 99 06 00 00       	jmp    c010273e <__alltraps>

c01020a5 <vector111>:
.globl vector111
vector111:
  pushl $0
c01020a5:	6a 00                	push   $0x0
  pushl $111
c01020a7:	6a 6f                	push   $0x6f
  jmp __alltraps
c01020a9:	e9 90 06 00 00       	jmp    c010273e <__alltraps>

c01020ae <vector112>:
.globl vector112
vector112:
  pushl $0
c01020ae:	6a 00                	push   $0x0
  pushl $112
c01020b0:	6a 70                	push   $0x70
  jmp __alltraps
c01020b2:	e9 87 06 00 00       	jmp    c010273e <__alltraps>

c01020b7 <vector113>:
.globl vector113
vector113:
  pushl $0
c01020b7:	6a 00                	push   $0x0
  pushl $113
c01020b9:	6a 71                	push   $0x71
  jmp __alltraps
c01020bb:	e9 7e 06 00 00       	jmp    c010273e <__alltraps>

c01020c0 <vector114>:
.globl vector114
vector114:
  pushl $0
c01020c0:	6a 00                	push   $0x0
  pushl $114
c01020c2:	6a 72                	push   $0x72
  jmp __alltraps
c01020c4:	e9 75 06 00 00       	jmp    c010273e <__alltraps>

c01020c9 <vector115>:
.globl vector115
vector115:
  pushl $0
c01020c9:	6a 00                	push   $0x0
  pushl $115
c01020cb:	6a 73                	push   $0x73
  jmp __alltraps
c01020cd:	e9 6c 06 00 00       	jmp    c010273e <__alltraps>

c01020d2 <vector116>:
.globl vector116
vector116:
  pushl $0
c01020d2:	6a 00                	push   $0x0
  pushl $116
c01020d4:	6a 74                	push   $0x74
  jmp __alltraps
c01020d6:	e9 63 06 00 00       	jmp    c010273e <__alltraps>

c01020db <vector117>:
.globl vector117
vector117:
  pushl $0
c01020db:	6a 00                	push   $0x0
  pushl $117
c01020dd:	6a 75                	push   $0x75
  jmp __alltraps
c01020df:	e9 5a 06 00 00       	jmp    c010273e <__alltraps>

c01020e4 <vector118>:
.globl vector118
vector118:
  pushl $0
c01020e4:	6a 00                	push   $0x0
  pushl $118
c01020e6:	6a 76                	push   $0x76
  jmp __alltraps
c01020e8:	e9 51 06 00 00       	jmp    c010273e <__alltraps>

c01020ed <vector119>:
.globl vector119
vector119:
  pushl $0
c01020ed:	6a 00                	push   $0x0
  pushl $119
c01020ef:	6a 77                	push   $0x77
  jmp __alltraps
c01020f1:	e9 48 06 00 00       	jmp    c010273e <__alltraps>

c01020f6 <vector120>:
.globl vector120
vector120:
  pushl $0
c01020f6:	6a 00                	push   $0x0
  pushl $120
c01020f8:	6a 78                	push   $0x78
  jmp __alltraps
c01020fa:	e9 3f 06 00 00       	jmp    c010273e <__alltraps>

c01020ff <vector121>:
.globl vector121
vector121:
  pushl $0
c01020ff:	6a 00                	push   $0x0
  pushl $121
c0102101:	6a 79                	push   $0x79
  jmp __alltraps
c0102103:	e9 36 06 00 00       	jmp    c010273e <__alltraps>

c0102108 <vector122>:
.globl vector122
vector122:
  pushl $0
c0102108:	6a 00                	push   $0x0
  pushl $122
c010210a:	6a 7a                	push   $0x7a
  jmp __alltraps
c010210c:	e9 2d 06 00 00       	jmp    c010273e <__alltraps>

c0102111 <vector123>:
.globl vector123
vector123:
  pushl $0
c0102111:	6a 00                	push   $0x0
  pushl $123
c0102113:	6a 7b                	push   $0x7b
  jmp __alltraps
c0102115:	e9 24 06 00 00       	jmp    c010273e <__alltraps>

c010211a <vector124>:
.globl vector124
vector124:
  pushl $0
c010211a:	6a 00                	push   $0x0
  pushl $124
c010211c:	6a 7c                	push   $0x7c
  jmp __alltraps
c010211e:	e9 1b 06 00 00       	jmp    c010273e <__alltraps>

c0102123 <vector125>:
.globl vector125
vector125:
  pushl $0
c0102123:	6a 00                	push   $0x0
  pushl $125
c0102125:	6a 7d                	push   $0x7d
  jmp __alltraps
c0102127:	e9 12 06 00 00       	jmp    c010273e <__alltraps>

c010212c <vector126>:
.globl vector126
vector126:
  pushl $0
c010212c:	6a 00                	push   $0x0
  pushl $126
c010212e:	6a 7e                	push   $0x7e
  jmp __alltraps
c0102130:	e9 09 06 00 00       	jmp    c010273e <__alltraps>

c0102135 <vector127>:
.globl vector127
vector127:
  pushl $0
c0102135:	6a 00                	push   $0x0
  pushl $127
c0102137:	6a 7f                	push   $0x7f
  jmp __alltraps
c0102139:	e9 00 06 00 00       	jmp    c010273e <__alltraps>

c010213e <vector128>:
.globl vector128
vector128:
  pushl $0
c010213e:	6a 00                	push   $0x0
  pushl $128
c0102140:	68 80 00 00 00       	push   $0x80
  jmp __alltraps
c0102145:	e9 f4 05 00 00       	jmp    c010273e <__alltraps>

c010214a <vector129>:
.globl vector129
vector129:
  pushl $0
c010214a:	6a 00                	push   $0x0
  pushl $129
c010214c:	68 81 00 00 00       	push   $0x81
  jmp __alltraps
c0102151:	e9 e8 05 00 00       	jmp    c010273e <__alltraps>

c0102156 <vector130>:
.globl vector130
vector130:
  pushl $0
c0102156:	6a 00                	push   $0x0
  pushl $130
c0102158:	68 82 00 00 00       	push   $0x82
  jmp __alltraps
c010215d:	e9 dc 05 00 00       	jmp    c010273e <__alltraps>

c0102162 <vector131>:
.globl vector131
vector131:
  pushl $0
c0102162:	6a 00                	push   $0x0
  pushl $131
c0102164:	68 83 00 00 00       	push   $0x83
  jmp __alltraps
c0102169:	e9 d0 05 00 00       	jmp    c010273e <__alltraps>

c010216e <vector132>:
.globl vector132
vector132:
  pushl $0
c010216e:	6a 00                	push   $0x0
  pushl $132
c0102170:	68 84 00 00 00       	push   $0x84
  jmp __alltraps
c0102175:	e9 c4 05 00 00       	jmp    c010273e <__alltraps>

c010217a <vector133>:
.globl vector133
vector133:
  pushl $0
c010217a:	6a 00                	push   $0x0
  pushl $133
c010217c:	68 85 00 00 00       	push   $0x85
  jmp __alltraps
c0102181:	e9 b8 05 00 00       	jmp    c010273e <__alltraps>

c0102186 <vector134>:
.globl vector134
vector134:
  pushl $0
c0102186:	6a 00                	push   $0x0
  pushl $134
c0102188:	68 86 00 00 00       	push   $0x86
  jmp __alltraps
c010218d:	e9 ac 05 00 00       	jmp    c010273e <__alltraps>

c0102192 <vector135>:
.globl vector135
vector135:
  pushl $0
c0102192:	6a 00                	push   $0x0
  pushl $135
c0102194:	68 87 00 00 00       	push   $0x87
  jmp __alltraps
c0102199:	e9 a0 05 00 00       	jmp    c010273e <__alltraps>

c010219e <vector136>:
.globl vector136
vector136:
  pushl $0
c010219e:	6a 00                	push   $0x0
  pushl $136
c01021a0:	68 88 00 00 00       	push   $0x88
  jmp __alltraps
c01021a5:	e9 94 05 00 00       	jmp    c010273e <__alltraps>

c01021aa <vector137>:
.globl vector137
vector137:
  pushl $0
c01021aa:	6a 00                	push   $0x0
  pushl $137
c01021ac:	68 89 00 00 00       	push   $0x89
  jmp __alltraps
c01021b1:	e9 88 05 00 00       	jmp    c010273e <__alltraps>

c01021b6 <vector138>:
.globl vector138
vector138:
  pushl $0
c01021b6:	6a 00                	push   $0x0
  pushl $138
c01021b8:	68 8a 00 00 00       	push   $0x8a
  jmp __alltraps
c01021bd:	e9 7c 05 00 00       	jmp    c010273e <__alltraps>

c01021c2 <vector139>:
.globl vector139
vector139:
  pushl $0
c01021c2:	6a 00                	push   $0x0
  pushl $139
c01021c4:	68 8b 00 00 00       	push   $0x8b
  jmp __alltraps
c01021c9:	e9 70 05 00 00       	jmp    c010273e <__alltraps>

c01021ce <vector140>:
.globl vector140
vector140:
  pushl $0
c01021ce:	6a 00                	push   $0x0
  pushl $140
c01021d0:	68 8c 00 00 00       	push   $0x8c
  jmp __alltraps
c01021d5:	e9 64 05 00 00       	jmp    c010273e <__alltraps>

c01021da <vector141>:
.globl vector141
vector141:
  pushl $0
c01021da:	6a 00                	push   $0x0
  pushl $141
c01021dc:	68 8d 00 00 00       	push   $0x8d
  jmp __alltraps
c01021e1:	e9 58 05 00 00       	jmp    c010273e <__alltraps>

c01021e6 <vector142>:
.globl vector142
vector142:
  pushl $0
c01021e6:	6a 00                	push   $0x0
  pushl $142
c01021e8:	68 8e 00 00 00       	push   $0x8e
  jmp __alltraps
c01021ed:	e9 4c 05 00 00       	jmp    c010273e <__alltraps>

c01021f2 <vector143>:
.globl vector143
vector143:
  pushl $0
c01021f2:	6a 00                	push   $0x0
  pushl $143
c01021f4:	68 8f 00 00 00       	push   $0x8f
  jmp __alltraps
c01021f9:	e9 40 05 00 00       	jmp    c010273e <__alltraps>

c01021fe <vector144>:
.globl vector144
vector144:
  pushl $0
c01021fe:	6a 00                	push   $0x0
  pushl $144
c0102200:	68 90 00 00 00       	push   $0x90
  jmp __alltraps
c0102205:	e9 34 05 00 00       	jmp    c010273e <__alltraps>

c010220a <vector145>:
.globl vector145
vector145:
  pushl $0
c010220a:	6a 00                	push   $0x0
  pushl $145
c010220c:	68 91 00 00 00       	push   $0x91
  jmp __alltraps
c0102211:	e9 28 05 00 00       	jmp    c010273e <__alltraps>

c0102216 <vector146>:
.globl vector146
vector146:
  pushl $0
c0102216:	6a 00                	push   $0x0
  pushl $146
c0102218:	68 92 00 00 00       	push   $0x92
  jmp __alltraps
c010221d:	e9 1c 05 00 00       	jmp    c010273e <__alltraps>

c0102222 <vector147>:
.globl vector147
vector147:
  pushl $0
c0102222:	6a 00                	push   $0x0
  pushl $147
c0102224:	68 93 00 00 00       	push   $0x93
  jmp __alltraps
c0102229:	e9 10 05 00 00       	jmp    c010273e <__alltraps>

c010222e <vector148>:
.globl vector148
vector148:
  pushl $0
c010222e:	6a 00                	push   $0x0
  pushl $148
c0102230:	68 94 00 00 00       	push   $0x94
  jmp __alltraps
c0102235:	e9 04 05 00 00       	jmp    c010273e <__alltraps>

c010223a <vector149>:
.globl vector149
vector149:
  pushl $0
c010223a:	6a 00                	push   $0x0
  pushl $149
c010223c:	68 95 00 00 00       	push   $0x95
  jmp __alltraps
c0102241:	e9 f8 04 00 00       	jmp    c010273e <__alltraps>

c0102246 <vector150>:
.globl vector150
vector150:
  pushl $0
c0102246:	6a 00                	push   $0x0
  pushl $150
c0102248:	68 96 00 00 00       	push   $0x96
  jmp __alltraps
c010224d:	e9 ec 04 00 00       	jmp    c010273e <__alltraps>

c0102252 <vector151>:
.globl vector151
vector151:
  pushl $0
c0102252:	6a 00                	push   $0x0
  pushl $151
c0102254:	68 97 00 00 00       	push   $0x97
  jmp __alltraps
c0102259:	e9 e0 04 00 00       	jmp    c010273e <__alltraps>

c010225e <vector152>:
.globl vector152
vector152:
  pushl $0
c010225e:	6a 00                	push   $0x0
  pushl $152
c0102260:	68 98 00 00 00       	push   $0x98
  jmp __alltraps
c0102265:	e9 d4 04 00 00       	jmp    c010273e <__alltraps>

c010226a <vector153>:
.globl vector153
vector153:
  pushl $0
c010226a:	6a 00                	push   $0x0
  pushl $153
c010226c:	68 99 00 00 00       	push   $0x99
  jmp __alltraps
c0102271:	e9 c8 04 00 00       	jmp    c010273e <__alltraps>

c0102276 <vector154>:
.globl vector154
vector154:
  pushl $0
c0102276:	6a 00                	push   $0x0
  pushl $154
c0102278:	68 9a 00 00 00       	push   $0x9a
  jmp __alltraps
c010227d:	e9 bc 04 00 00       	jmp    c010273e <__alltraps>

c0102282 <vector155>:
.globl vector155
vector155:
  pushl $0
c0102282:	6a 00                	push   $0x0
  pushl $155
c0102284:	68 9b 00 00 00       	push   $0x9b
  jmp __alltraps
c0102289:	e9 b0 04 00 00       	jmp    c010273e <__alltraps>

c010228e <vector156>:
.globl vector156
vector156:
  pushl $0
c010228e:	6a 00                	push   $0x0
  pushl $156
c0102290:	68 9c 00 00 00       	push   $0x9c
  jmp __alltraps
c0102295:	e9 a4 04 00 00       	jmp    c010273e <__alltraps>

c010229a <vector157>:
.globl vector157
vector157:
  pushl $0
c010229a:	6a 00                	push   $0x0
  pushl $157
c010229c:	68 9d 00 00 00       	push   $0x9d
  jmp __alltraps
c01022a1:	e9 98 04 00 00       	jmp    c010273e <__alltraps>

c01022a6 <vector158>:
.globl vector158
vector158:
  pushl $0
c01022a6:	6a 00                	push   $0x0
  pushl $158
c01022a8:	68 9e 00 00 00       	push   $0x9e
  jmp __alltraps
c01022ad:	e9 8c 04 00 00       	jmp    c010273e <__alltraps>

c01022b2 <vector159>:
.globl vector159
vector159:
  pushl $0
c01022b2:	6a 00                	push   $0x0
  pushl $159
c01022b4:	68 9f 00 00 00       	push   $0x9f
  jmp __alltraps
c01022b9:	e9 80 04 00 00       	jmp    c010273e <__alltraps>

c01022be <vector160>:
.globl vector160
vector160:
  pushl $0
c01022be:	6a 00                	push   $0x0
  pushl $160
c01022c0:	68 a0 00 00 00       	push   $0xa0
  jmp __alltraps
c01022c5:	e9 74 04 00 00       	jmp    c010273e <__alltraps>

c01022ca <vector161>:
.globl vector161
vector161:
  pushl $0
c01022ca:	6a 00                	push   $0x0
  pushl $161
c01022cc:	68 a1 00 00 00       	push   $0xa1
  jmp __alltraps
c01022d1:	e9 68 04 00 00       	jmp    c010273e <__alltraps>

c01022d6 <vector162>:
.globl vector162
vector162:
  pushl $0
c01022d6:	6a 00                	push   $0x0
  pushl $162
c01022d8:	68 a2 00 00 00       	push   $0xa2
  jmp __alltraps
c01022dd:	e9 5c 04 00 00       	jmp    c010273e <__alltraps>

c01022e2 <vector163>:
.globl vector163
vector163:
  pushl $0
c01022e2:	6a 00                	push   $0x0
  pushl $163
c01022e4:	68 a3 00 00 00       	push   $0xa3
  jmp __alltraps
c01022e9:	e9 50 04 00 00       	jmp    c010273e <__alltraps>

c01022ee <vector164>:
.globl vector164
vector164:
  pushl $0
c01022ee:	6a 00                	push   $0x0
  pushl $164
c01022f0:	68 a4 00 00 00       	push   $0xa4
  jmp __alltraps
c01022f5:	e9 44 04 00 00       	jmp    c010273e <__alltraps>

c01022fa <vector165>:
.globl vector165
vector165:
  pushl $0
c01022fa:	6a 00                	push   $0x0
  pushl $165
c01022fc:	68 a5 00 00 00       	push   $0xa5
  jmp __alltraps
c0102301:	e9 38 04 00 00       	jmp    c010273e <__alltraps>

c0102306 <vector166>:
.globl vector166
vector166:
  pushl $0
c0102306:	6a 00                	push   $0x0
  pushl $166
c0102308:	68 a6 00 00 00       	push   $0xa6
  jmp __alltraps
c010230d:	e9 2c 04 00 00       	jmp    c010273e <__alltraps>

c0102312 <vector167>:
.globl vector167
vector167:
  pushl $0
c0102312:	6a 00                	push   $0x0
  pushl $167
c0102314:	68 a7 00 00 00       	push   $0xa7
  jmp __alltraps
c0102319:	e9 20 04 00 00       	jmp    c010273e <__alltraps>

c010231e <vector168>:
.globl vector168
vector168:
  pushl $0
c010231e:	6a 00                	push   $0x0
  pushl $168
c0102320:	68 a8 00 00 00       	push   $0xa8
  jmp __alltraps
c0102325:	e9 14 04 00 00       	jmp    c010273e <__alltraps>

c010232a <vector169>:
.globl vector169
vector169:
  pushl $0
c010232a:	6a 00                	push   $0x0
  pushl $169
c010232c:	68 a9 00 00 00       	push   $0xa9
  jmp __alltraps
c0102331:	e9 08 04 00 00       	jmp    c010273e <__alltraps>

c0102336 <vector170>:
.globl vector170
vector170:
  pushl $0
c0102336:	6a 00                	push   $0x0
  pushl $170
c0102338:	68 aa 00 00 00       	push   $0xaa
  jmp __alltraps
c010233d:	e9 fc 03 00 00       	jmp    c010273e <__alltraps>

c0102342 <vector171>:
.globl vector171
vector171:
  pushl $0
c0102342:	6a 00                	push   $0x0
  pushl $171
c0102344:	68 ab 00 00 00       	push   $0xab
  jmp __alltraps
c0102349:	e9 f0 03 00 00       	jmp    c010273e <__alltraps>

c010234e <vector172>:
.globl vector172
vector172:
  pushl $0
c010234e:	6a 00                	push   $0x0
  pushl $172
c0102350:	68 ac 00 00 00       	push   $0xac
  jmp __alltraps
c0102355:	e9 e4 03 00 00       	jmp    c010273e <__alltraps>

c010235a <vector173>:
.globl vector173
vector173:
  pushl $0
c010235a:	6a 00                	push   $0x0
  pushl $173
c010235c:	68 ad 00 00 00       	push   $0xad
  jmp __alltraps
c0102361:	e9 d8 03 00 00       	jmp    c010273e <__alltraps>

c0102366 <vector174>:
.globl vector174
vector174:
  pushl $0
c0102366:	6a 00                	push   $0x0
  pushl $174
c0102368:	68 ae 00 00 00       	push   $0xae
  jmp __alltraps
c010236d:	e9 cc 03 00 00       	jmp    c010273e <__alltraps>

c0102372 <vector175>:
.globl vector175
vector175:
  pushl $0
c0102372:	6a 00                	push   $0x0
  pushl $175
c0102374:	68 af 00 00 00       	push   $0xaf
  jmp __alltraps
c0102379:	e9 c0 03 00 00       	jmp    c010273e <__alltraps>

c010237e <vector176>:
.globl vector176
vector176:
  pushl $0
c010237e:	6a 00                	push   $0x0
  pushl $176
c0102380:	68 b0 00 00 00       	push   $0xb0
  jmp __alltraps
c0102385:	e9 b4 03 00 00       	jmp    c010273e <__alltraps>

c010238a <vector177>:
.globl vector177
vector177:
  pushl $0
c010238a:	6a 00                	push   $0x0
  pushl $177
c010238c:	68 b1 00 00 00       	push   $0xb1
  jmp __alltraps
c0102391:	e9 a8 03 00 00       	jmp    c010273e <__alltraps>

c0102396 <vector178>:
.globl vector178
vector178:
  pushl $0
c0102396:	6a 00                	push   $0x0
  pushl $178
c0102398:	68 b2 00 00 00       	push   $0xb2
  jmp __alltraps
c010239d:	e9 9c 03 00 00       	jmp    c010273e <__alltraps>

c01023a2 <vector179>:
.globl vector179
vector179:
  pushl $0
c01023a2:	6a 00                	push   $0x0
  pushl $179
c01023a4:	68 b3 00 00 00       	push   $0xb3
  jmp __alltraps
c01023a9:	e9 90 03 00 00       	jmp    c010273e <__alltraps>

c01023ae <vector180>:
.globl vector180
vector180:
  pushl $0
c01023ae:	6a 00                	push   $0x0
  pushl $180
c01023b0:	68 b4 00 00 00       	push   $0xb4
  jmp __alltraps
c01023b5:	e9 84 03 00 00       	jmp    c010273e <__alltraps>

c01023ba <vector181>:
.globl vector181
vector181:
  pushl $0
c01023ba:	6a 00                	push   $0x0
  pushl $181
c01023bc:	68 b5 00 00 00       	push   $0xb5
  jmp __alltraps
c01023c1:	e9 78 03 00 00       	jmp    c010273e <__alltraps>

c01023c6 <vector182>:
.globl vector182
vector182:
  pushl $0
c01023c6:	6a 00                	push   $0x0
  pushl $182
c01023c8:	68 b6 00 00 00       	push   $0xb6
  jmp __alltraps
c01023cd:	e9 6c 03 00 00       	jmp    c010273e <__alltraps>

c01023d2 <vector183>:
.globl vector183
vector183:
  pushl $0
c01023d2:	6a 00                	push   $0x0
  pushl $183
c01023d4:	68 b7 00 00 00       	push   $0xb7
  jmp __alltraps
c01023d9:	e9 60 03 00 00       	jmp    c010273e <__alltraps>

c01023de <vector184>:
.globl vector184
vector184:
  pushl $0
c01023de:	6a 00                	push   $0x0
  pushl $184
c01023e0:	68 b8 00 00 00       	push   $0xb8
  jmp __alltraps
c01023e5:	e9 54 03 00 00       	jmp    c010273e <__alltraps>

c01023ea <vector185>:
.globl vector185
vector185:
  pushl $0
c01023ea:	6a 00                	push   $0x0
  pushl $185
c01023ec:	68 b9 00 00 00       	push   $0xb9
  jmp __alltraps
c01023f1:	e9 48 03 00 00       	jmp    c010273e <__alltraps>

c01023f6 <vector186>:
.globl vector186
vector186:
  pushl $0
c01023f6:	6a 00                	push   $0x0
  pushl $186
c01023f8:	68 ba 00 00 00       	push   $0xba
  jmp __alltraps
c01023fd:	e9 3c 03 00 00       	jmp    c010273e <__alltraps>

c0102402 <vector187>:
.globl vector187
vector187:
  pushl $0
c0102402:	6a 00                	push   $0x0
  pushl $187
c0102404:	68 bb 00 00 00       	push   $0xbb
  jmp __alltraps
c0102409:	e9 30 03 00 00       	jmp    c010273e <__alltraps>

c010240e <vector188>:
.globl vector188
vector188:
  pushl $0
c010240e:	6a 00                	push   $0x0
  pushl $188
c0102410:	68 bc 00 00 00       	push   $0xbc
  jmp __alltraps
c0102415:	e9 24 03 00 00       	jmp    c010273e <__alltraps>

c010241a <vector189>:
.globl vector189
vector189:
  pushl $0
c010241a:	6a 00                	push   $0x0
  pushl $189
c010241c:	68 bd 00 00 00       	push   $0xbd
  jmp __alltraps
c0102421:	e9 18 03 00 00       	jmp    c010273e <__alltraps>

c0102426 <vector190>:
.globl vector190
vector190:
  pushl $0
c0102426:	6a 00                	push   $0x0
  pushl $190
c0102428:	68 be 00 00 00       	push   $0xbe
  jmp __alltraps
c010242d:	e9 0c 03 00 00       	jmp    c010273e <__alltraps>

c0102432 <vector191>:
.globl vector191
vector191:
  pushl $0
c0102432:	6a 00                	push   $0x0
  pushl $191
c0102434:	68 bf 00 00 00       	push   $0xbf
  jmp __alltraps
c0102439:	e9 00 03 00 00       	jmp    c010273e <__alltraps>

c010243e <vector192>:
.globl vector192
vector192:
  pushl $0
c010243e:	6a 00                	push   $0x0
  pushl $192
c0102440:	68 c0 00 00 00       	push   $0xc0
  jmp __alltraps
c0102445:	e9 f4 02 00 00       	jmp    c010273e <__alltraps>

c010244a <vector193>:
.globl vector193
vector193:
  pushl $0
c010244a:	6a 00                	push   $0x0
  pushl $193
c010244c:	68 c1 00 00 00       	push   $0xc1
  jmp __alltraps
c0102451:	e9 e8 02 00 00       	jmp    c010273e <__alltraps>

c0102456 <vector194>:
.globl vector194
vector194:
  pushl $0
c0102456:	6a 00                	push   $0x0
  pushl $194
c0102458:	68 c2 00 00 00       	push   $0xc2
  jmp __alltraps
c010245d:	e9 dc 02 00 00       	jmp    c010273e <__alltraps>

c0102462 <vector195>:
.globl vector195
vector195:
  pushl $0
c0102462:	6a 00                	push   $0x0
  pushl $195
c0102464:	68 c3 00 00 00       	push   $0xc3
  jmp __alltraps
c0102469:	e9 d0 02 00 00       	jmp    c010273e <__alltraps>

c010246e <vector196>:
.globl vector196
vector196:
  pushl $0
c010246e:	6a 00                	push   $0x0
  pushl $196
c0102470:	68 c4 00 00 00       	push   $0xc4
  jmp __alltraps
c0102475:	e9 c4 02 00 00       	jmp    c010273e <__alltraps>

c010247a <vector197>:
.globl vector197
vector197:
  pushl $0
c010247a:	6a 00                	push   $0x0
  pushl $197
c010247c:	68 c5 00 00 00       	push   $0xc5
  jmp __alltraps
c0102481:	e9 b8 02 00 00       	jmp    c010273e <__alltraps>

c0102486 <vector198>:
.globl vector198
vector198:
  pushl $0
c0102486:	6a 00                	push   $0x0
  pushl $198
c0102488:	68 c6 00 00 00       	push   $0xc6
  jmp __alltraps
c010248d:	e9 ac 02 00 00       	jmp    c010273e <__alltraps>

c0102492 <vector199>:
.globl vector199
vector199:
  pushl $0
c0102492:	6a 00                	push   $0x0
  pushl $199
c0102494:	68 c7 00 00 00       	push   $0xc7
  jmp __alltraps
c0102499:	e9 a0 02 00 00       	jmp    c010273e <__alltraps>

c010249e <vector200>:
.globl vector200
vector200:
  pushl $0
c010249e:	6a 00                	push   $0x0
  pushl $200
c01024a0:	68 c8 00 00 00       	push   $0xc8
  jmp __alltraps
c01024a5:	e9 94 02 00 00       	jmp    c010273e <__alltraps>

c01024aa <vector201>:
.globl vector201
vector201:
  pushl $0
c01024aa:	6a 00                	push   $0x0
  pushl $201
c01024ac:	68 c9 00 00 00       	push   $0xc9
  jmp __alltraps
c01024b1:	e9 88 02 00 00       	jmp    c010273e <__alltraps>

c01024b6 <vector202>:
.globl vector202
vector202:
  pushl $0
c01024b6:	6a 00                	push   $0x0
  pushl $202
c01024b8:	68 ca 00 00 00       	push   $0xca
  jmp __alltraps
c01024bd:	e9 7c 02 00 00       	jmp    c010273e <__alltraps>

c01024c2 <vector203>:
.globl vector203
vector203:
  pushl $0
c01024c2:	6a 00                	push   $0x0
  pushl $203
c01024c4:	68 cb 00 00 00       	push   $0xcb
  jmp __alltraps
c01024c9:	e9 70 02 00 00       	jmp    c010273e <__alltraps>

c01024ce <vector204>:
.globl vector204
vector204:
  pushl $0
c01024ce:	6a 00                	push   $0x0
  pushl $204
c01024d0:	68 cc 00 00 00       	push   $0xcc
  jmp __alltraps
c01024d5:	e9 64 02 00 00       	jmp    c010273e <__alltraps>

c01024da <vector205>:
.globl vector205
vector205:
  pushl $0
c01024da:	6a 00                	push   $0x0
  pushl $205
c01024dc:	68 cd 00 00 00       	push   $0xcd
  jmp __alltraps
c01024e1:	e9 58 02 00 00       	jmp    c010273e <__alltraps>

c01024e6 <vector206>:
.globl vector206
vector206:
  pushl $0
c01024e6:	6a 00                	push   $0x0
  pushl $206
c01024e8:	68 ce 00 00 00       	push   $0xce
  jmp __alltraps
c01024ed:	e9 4c 02 00 00       	jmp    c010273e <__alltraps>

c01024f2 <vector207>:
.globl vector207
vector207:
  pushl $0
c01024f2:	6a 00                	push   $0x0
  pushl $207
c01024f4:	68 cf 00 00 00       	push   $0xcf
  jmp __alltraps
c01024f9:	e9 40 02 00 00       	jmp    c010273e <__alltraps>

c01024fe <vector208>:
.globl vector208
vector208:
  pushl $0
c01024fe:	6a 00                	push   $0x0
  pushl $208
c0102500:	68 d0 00 00 00       	push   $0xd0
  jmp __alltraps
c0102505:	e9 34 02 00 00       	jmp    c010273e <__alltraps>

c010250a <vector209>:
.globl vector209
vector209:
  pushl $0
c010250a:	6a 00                	push   $0x0
  pushl $209
c010250c:	68 d1 00 00 00       	push   $0xd1
  jmp __alltraps
c0102511:	e9 28 02 00 00       	jmp    c010273e <__alltraps>

c0102516 <vector210>:
.globl vector210
vector210:
  pushl $0
c0102516:	6a 00                	push   $0x0
  pushl $210
c0102518:	68 d2 00 00 00       	push   $0xd2
  jmp __alltraps
c010251d:	e9 1c 02 00 00       	jmp    c010273e <__alltraps>

c0102522 <vector211>:
.globl vector211
vector211:
  pushl $0
c0102522:	6a 00                	push   $0x0
  pushl $211
c0102524:	68 d3 00 00 00       	push   $0xd3
  jmp __alltraps
c0102529:	e9 10 02 00 00       	jmp    c010273e <__alltraps>

c010252e <vector212>:
.globl vector212
vector212:
  pushl $0
c010252e:	6a 00                	push   $0x0
  pushl $212
c0102530:	68 d4 00 00 00       	push   $0xd4
  jmp __alltraps
c0102535:	e9 04 02 00 00       	jmp    c010273e <__alltraps>

c010253a <vector213>:
.globl vector213
vector213:
  pushl $0
c010253a:	6a 00                	push   $0x0
  pushl $213
c010253c:	68 d5 00 00 00       	push   $0xd5
  jmp __alltraps
c0102541:	e9 f8 01 00 00       	jmp    c010273e <__alltraps>

c0102546 <vector214>:
.globl vector214
vector214:
  pushl $0
c0102546:	6a 00                	push   $0x0
  pushl $214
c0102548:	68 d6 00 00 00       	push   $0xd6
  jmp __alltraps
c010254d:	e9 ec 01 00 00       	jmp    c010273e <__alltraps>

c0102552 <vector215>:
.globl vector215
vector215:
  pushl $0
c0102552:	6a 00                	push   $0x0
  pushl $215
c0102554:	68 d7 00 00 00       	push   $0xd7
  jmp __alltraps
c0102559:	e9 e0 01 00 00       	jmp    c010273e <__alltraps>

c010255e <vector216>:
.globl vector216
vector216:
  pushl $0
c010255e:	6a 00                	push   $0x0
  pushl $216
c0102560:	68 d8 00 00 00       	push   $0xd8
  jmp __alltraps
c0102565:	e9 d4 01 00 00       	jmp    c010273e <__alltraps>

c010256a <vector217>:
.globl vector217
vector217:
  pushl $0
c010256a:	6a 00                	push   $0x0
  pushl $217
c010256c:	68 d9 00 00 00       	push   $0xd9
  jmp __alltraps
c0102571:	e9 c8 01 00 00       	jmp    c010273e <__alltraps>

c0102576 <vector218>:
.globl vector218
vector218:
  pushl $0
c0102576:	6a 00                	push   $0x0
  pushl $218
c0102578:	68 da 00 00 00       	push   $0xda
  jmp __alltraps
c010257d:	e9 bc 01 00 00       	jmp    c010273e <__alltraps>

c0102582 <vector219>:
.globl vector219
vector219:
  pushl $0
c0102582:	6a 00                	push   $0x0
  pushl $219
c0102584:	68 db 00 00 00       	push   $0xdb
  jmp __alltraps
c0102589:	e9 b0 01 00 00       	jmp    c010273e <__alltraps>

c010258e <vector220>:
.globl vector220
vector220:
  pushl $0
c010258e:	6a 00                	push   $0x0
  pushl $220
c0102590:	68 dc 00 00 00       	push   $0xdc
  jmp __alltraps
c0102595:	e9 a4 01 00 00       	jmp    c010273e <__alltraps>

c010259a <vector221>:
.globl vector221
vector221:
  pushl $0
c010259a:	6a 00                	push   $0x0
  pushl $221
c010259c:	68 dd 00 00 00       	push   $0xdd
  jmp __alltraps
c01025a1:	e9 98 01 00 00       	jmp    c010273e <__alltraps>

c01025a6 <vector222>:
.globl vector222
vector222:
  pushl $0
c01025a6:	6a 00                	push   $0x0
  pushl $222
c01025a8:	68 de 00 00 00       	push   $0xde
  jmp __alltraps
c01025ad:	e9 8c 01 00 00       	jmp    c010273e <__alltraps>

c01025b2 <vector223>:
.globl vector223
vector223:
  pushl $0
c01025b2:	6a 00                	push   $0x0
  pushl $223
c01025b4:	68 df 00 00 00       	push   $0xdf
  jmp __alltraps
c01025b9:	e9 80 01 00 00       	jmp    c010273e <__alltraps>

c01025be <vector224>:
.globl vector224
vector224:
  pushl $0
c01025be:	6a 00                	push   $0x0
  pushl $224
c01025c0:	68 e0 00 00 00       	push   $0xe0
  jmp __alltraps
c01025c5:	e9 74 01 00 00       	jmp    c010273e <__alltraps>

c01025ca <vector225>:
.globl vector225
vector225:
  pushl $0
c01025ca:	6a 00                	push   $0x0
  pushl $225
c01025cc:	68 e1 00 00 00       	push   $0xe1
  jmp __alltraps
c01025d1:	e9 68 01 00 00       	jmp    c010273e <__alltraps>

c01025d6 <vector226>:
.globl vector226
vector226:
  pushl $0
c01025d6:	6a 00                	push   $0x0
  pushl $226
c01025d8:	68 e2 00 00 00       	push   $0xe2
  jmp __alltraps
c01025dd:	e9 5c 01 00 00       	jmp    c010273e <__alltraps>

c01025e2 <vector227>:
.globl vector227
vector227:
  pushl $0
c01025e2:	6a 00                	push   $0x0
  pushl $227
c01025e4:	68 e3 00 00 00       	push   $0xe3
  jmp __alltraps
c01025e9:	e9 50 01 00 00       	jmp    c010273e <__alltraps>

c01025ee <vector228>:
.globl vector228
vector228:
  pushl $0
c01025ee:	6a 00                	push   $0x0
  pushl $228
c01025f0:	68 e4 00 00 00       	push   $0xe4
  jmp __alltraps
c01025f5:	e9 44 01 00 00       	jmp    c010273e <__alltraps>

c01025fa <vector229>:
.globl vector229
vector229:
  pushl $0
c01025fa:	6a 00                	push   $0x0
  pushl $229
c01025fc:	68 e5 00 00 00       	push   $0xe5
  jmp __alltraps
c0102601:	e9 38 01 00 00       	jmp    c010273e <__alltraps>

c0102606 <vector230>:
.globl vector230
vector230:
  pushl $0
c0102606:	6a 00                	push   $0x0
  pushl $230
c0102608:	68 e6 00 00 00       	push   $0xe6
  jmp __alltraps
c010260d:	e9 2c 01 00 00       	jmp    c010273e <__alltraps>

c0102612 <vector231>:
.globl vector231
vector231:
  pushl $0
c0102612:	6a 00                	push   $0x0
  pushl $231
c0102614:	68 e7 00 00 00       	push   $0xe7
  jmp __alltraps
c0102619:	e9 20 01 00 00       	jmp    c010273e <__alltraps>

c010261e <vector232>:
.globl vector232
vector232:
  pushl $0
c010261e:	6a 00                	push   $0x0
  pushl $232
c0102620:	68 e8 00 00 00       	push   $0xe8
  jmp __alltraps
c0102625:	e9 14 01 00 00       	jmp    c010273e <__alltraps>

c010262a <vector233>:
.globl vector233
vector233:
  pushl $0
c010262a:	6a 00                	push   $0x0
  pushl $233
c010262c:	68 e9 00 00 00       	push   $0xe9
  jmp __alltraps
c0102631:	e9 08 01 00 00       	jmp    c010273e <__alltraps>

c0102636 <vector234>:
.globl vector234
vector234:
  pushl $0
c0102636:	6a 00                	push   $0x0
  pushl $234
c0102638:	68 ea 00 00 00       	push   $0xea
  jmp __alltraps
c010263d:	e9 fc 00 00 00       	jmp    c010273e <__alltraps>

c0102642 <vector235>:
.globl vector235
vector235:
  pushl $0
c0102642:	6a 00                	push   $0x0
  pushl $235
c0102644:	68 eb 00 00 00       	push   $0xeb
  jmp __alltraps
c0102649:	e9 f0 00 00 00       	jmp    c010273e <__alltraps>

c010264e <vector236>:
.globl vector236
vector236:
  pushl $0
c010264e:	6a 00                	push   $0x0
  pushl $236
c0102650:	68 ec 00 00 00       	push   $0xec
  jmp __alltraps
c0102655:	e9 e4 00 00 00       	jmp    c010273e <__alltraps>

c010265a <vector237>:
.globl vector237
vector237:
  pushl $0
c010265a:	6a 00                	push   $0x0
  pushl $237
c010265c:	68 ed 00 00 00       	push   $0xed
  jmp __alltraps
c0102661:	e9 d8 00 00 00       	jmp    c010273e <__alltraps>

c0102666 <vector238>:
.globl vector238
vector238:
  pushl $0
c0102666:	6a 00                	push   $0x0
  pushl $238
c0102668:	68 ee 00 00 00       	push   $0xee
  jmp __alltraps
c010266d:	e9 cc 00 00 00       	jmp    c010273e <__alltraps>

c0102672 <vector239>:
.globl vector239
vector239:
  pushl $0
c0102672:	6a 00                	push   $0x0
  pushl $239
c0102674:	68 ef 00 00 00       	push   $0xef
  jmp __alltraps
c0102679:	e9 c0 00 00 00       	jmp    c010273e <__alltraps>

c010267e <vector240>:
.globl vector240
vector240:
  pushl $0
c010267e:	6a 00                	push   $0x0
  pushl $240
c0102680:	68 f0 00 00 00       	push   $0xf0
  jmp __alltraps
c0102685:	e9 b4 00 00 00       	jmp    c010273e <__alltraps>

c010268a <vector241>:
.globl vector241
vector241:
  pushl $0
c010268a:	6a 00                	push   $0x0
  pushl $241
c010268c:	68 f1 00 00 00       	push   $0xf1
  jmp __alltraps
c0102691:	e9 a8 00 00 00       	jmp    c010273e <__alltraps>

c0102696 <vector242>:
.globl vector242
vector242:
  pushl $0
c0102696:	6a 00                	push   $0x0
  pushl $242
c0102698:	68 f2 00 00 00       	push   $0xf2
  jmp __alltraps
c010269d:	e9 9c 00 00 00       	jmp    c010273e <__alltraps>

c01026a2 <vector243>:
.globl vector243
vector243:
  pushl $0
c01026a2:	6a 00                	push   $0x0
  pushl $243
c01026a4:	68 f3 00 00 00       	push   $0xf3
  jmp __alltraps
c01026a9:	e9 90 00 00 00       	jmp    c010273e <__alltraps>

c01026ae <vector244>:
.globl vector244
vector244:
  pushl $0
c01026ae:	6a 00                	push   $0x0
  pushl $244
c01026b0:	68 f4 00 00 00       	push   $0xf4
  jmp __alltraps
c01026b5:	e9 84 00 00 00       	jmp    c010273e <__alltraps>

c01026ba <vector245>:
.globl vector245
vector245:
  pushl $0
c01026ba:	6a 00                	push   $0x0
  pushl $245
c01026bc:	68 f5 00 00 00       	push   $0xf5
  jmp __alltraps
c01026c1:	e9 78 00 00 00       	jmp    c010273e <__alltraps>

c01026c6 <vector246>:
.globl vector246
vector246:
  pushl $0
c01026c6:	6a 00                	push   $0x0
  pushl $246
c01026c8:	68 f6 00 00 00       	push   $0xf6
  jmp __alltraps
c01026cd:	e9 6c 00 00 00       	jmp    c010273e <__alltraps>

c01026d2 <vector247>:
.globl vector247
vector247:
  pushl $0
c01026d2:	6a 00                	push   $0x0
  pushl $247
c01026d4:	68 f7 00 00 00       	push   $0xf7
  jmp __alltraps
c01026d9:	e9 60 00 00 00       	jmp    c010273e <__alltraps>

c01026de <vector248>:
.globl vector248
vector248:
  pushl $0
c01026de:	6a 00                	push   $0x0
  pushl $248
c01026e0:	68 f8 00 00 00       	push   $0xf8
  jmp __alltraps
c01026e5:	e9 54 00 00 00       	jmp    c010273e <__alltraps>

c01026ea <vector249>:
.globl vector249
vector249:
  pushl $0
c01026ea:	6a 00                	push   $0x0
  pushl $249
c01026ec:	68 f9 00 00 00       	push   $0xf9
  jmp __alltraps
c01026f1:	e9 48 00 00 00       	jmp    c010273e <__alltraps>

c01026f6 <vector250>:
.globl vector250
vector250:
  pushl $0
c01026f6:	6a 00                	push   $0x0
  pushl $250
c01026f8:	68 fa 00 00 00       	push   $0xfa
  jmp __alltraps
c01026fd:	e9 3c 00 00 00       	jmp    c010273e <__alltraps>

c0102702 <vector251>:
.globl vector251
vector251:
  pushl $0
c0102702:	6a 00                	push   $0x0
  pushl $251
c0102704:	68 fb 00 00 00       	push   $0xfb
  jmp __alltraps
c0102709:	e9 30 00 00 00       	jmp    c010273e <__alltraps>

c010270e <vector252>:
.globl vector252
vector252:
  pushl $0
c010270e:	6a 00                	push   $0x0
  pushl $252
c0102710:	68 fc 00 00 00       	push   $0xfc
  jmp __alltraps
c0102715:	e9 24 00 00 00       	jmp    c010273e <__alltraps>

c010271a <vector253>:
.globl vector253
vector253:
  pushl $0
c010271a:	6a 00                	push   $0x0
  pushl $253
c010271c:	68 fd 00 00 00       	push   $0xfd
  jmp __alltraps
c0102721:	e9 18 00 00 00       	jmp    c010273e <__alltraps>

c0102726 <vector254>:
.globl vector254
vector254:
  pushl $0
c0102726:	6a 00                	push   $0x0
  pushl $254
c0102728:	68 fe 00 00 00       	push   $0xfe
  jmp __alltraps
c010272d:	e9 0c 00 00 00       	jmp    c010273e <__alltraps>

c0102732 <vector255>:
.globl vector255
vector255:
  pushl $0
c0102732:	6a 00                	push   $0x0
  pushl $255
c0102734:	68 ff 00 00 00       	push   $0xff
  jmp __alltraps
c0102739:	e9 00 00 00 00       	jmp    c010273e <__alltraps>

c010273e <__alltraps>:
.text
.globl __alltraps
__alltraps:
    # push registers to build a trap frame
    # therefore make the stack look like a struct trapframe
    pushl %ds
c010273e:	1e                   	push   %ds
    pushl %es
c010273f:	06                   	push   %es
    pushl %fs
c0102740:	0f a0                	push   %fs
    pushl %gs
c0102742:	0f a8                	push   %gs
    pushal
c0102744:	60                   	pusha  

    # load GD_KDATA into %ds and %es to set up data segments for kernel
    movl $GD_KDATA, %eax
c0102745:	b8 10 00 00 00       	mov    $0x10,%eax
    movw %ax, %ds
c010274a:	8e d8                	mov    %eax,%ds
    movw %ax, %es
c010274c:	8e c0                	mov    %eax,%es

    # push %esp to pass a pointer to the trapframe as an argument to trap()
    pushl %esp
c010274e:	54                   	push   %esp

    # call trap(tf), where tf=%esp
    call trap
c010274f:	e8 64 f5 ff ff       	call   c0101cb8 <trap>

    # pop the pushed stack pointer
    popl %esp
c0102754:	5c                   	pop    %esp

c0102755 <__trapret>:

    # return falls through to trapret...
.globl __trapret
__trapret:
    # restore registers from stack
    popal
c0102755:	61                   	popa   

    # restore %ds, %es, %fs and %gs
    popl %gs
c0102756:	0f a9                	pop    %gs
    popl %fs
c0102758:	0f a1                	pop    %fs
    popl %es
c010275a:	07                   	pop    %es
    popl %ds
c010275b:	1f                   	pop    %ds

    # get rid of the trap number and error code
    addl $0x8, %esp
c010275c:	83 c4 08             	add    $0x8,%esp
    iret
c010275f:	cf                   	iret   

c0102760 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
c0102760:	55                   	push   %ebp
c0102761:	89 e5                	mov    %esp,%ebp
    return page - pages;
c0102763:	8b 45 08             	mov    0x8(%ebp),%eax
c0102766:	8b 15 18 af 11 c0    	mov    0xc011af18,%edx
c010276c:	29 d0                	sub    %edx,%eax
c010276e:	c1 f8 02             	sar    $0x2,%eax
c0102771:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
c0102777:	5d                   	pop    %ebp
c0102778:	c3                   	ret    

c0102779 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
c0102779:	55                   	push   %ebp
c010277a:	89 e5                	mov    %esp,%ebp
c010277c:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
c010277f:	8b 45 08             	mov    0x8(%ebp),%eax
c0102782:	89 04 24             	mov    %eax,(%esp)
c0102785:	e8 d6 ff ff ff       	call   c0102760 <page2ppn>
c010278a:	c1 e0 0c             	shl    $0xc,%eax
}
c010278d:	c9                   	leave  
c010278e:	c3                   	ret    

c010278f <pa2page>:

static inline struct Page *
pa2page(uintptr_t pa) {
c010278f:	55                   	push   %ebp
c0102790:	89 e5                	mov    %esp,%ebp
c0102792:	83 ec 18             	sub    $0x18,%esp
    if (PPN(pa) >= npage) {
c0102795:	8b 45 08             	mov    0x8(%ebp),%eax
c0102798:	c1 e8 0c             	shr    $0xc,%eax
c010279b:	89 c2                	mov    %eax,%edx
c010279d:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01027a2:	39 c2                	cmp    %eax,%edx
c01027a4:	72 1c                	jb     c01027c2 <pa2page+0x33>
        panic("pa2page called with invalid pa");
c01027a6:	c7 44 24 08 70 65 10 	movl   $0xc0106570,0x8(%esp)
c01027ad:	c0 
c01027ae:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
c01027b5:	00 
c01027b6:	c7 04 24 8f 65 10 c0 	movl   $0xc010658f,(%esp)
c01027bd:	e8 27 dc ff ff       	call   c01003e9 <__panic>
    }
    return &pages[PPN(pa)];
c01027c2:	8b 0d 18 af 11 c0    	mov    0xc011af18,%ecx
c01027c8:	8b 45 08             	mov    0x8(%ebp),%eax
c01027cb:	c1 e8 0c             	shr    $0xc,%eax
c01027ce:	89 c2                	mov    %eax,%edx
c01027d0:	89 d0                	mov    %edx,%eax
c01027d2:	c1 e0 02             	shl    $0x2,%eax
c01027d5:	01 d0                	add    %edx,%eax
c01027d7:	c1 e0 02             	shl    $0x2,%eax
c01027da:	01 c8                	add    %ecx,%eax
}
c01027dc:	c9                   	leave  
c01027dd:	c3                   	ret    

c01027de <page2kva>:

static inline void *
page2kva(struct Page *page) {
c01027de:	55                   	push   %ebp
c01027df:	89 e5                	mov    %esp,%ebp
c01027e1:	83 ec 28             	sub    $0x28,%esp
    return KADDR(page2pa(page));
c01027e4:	8b 45 08             	mov    0x8(%ebp),%eax
c01027e7:	89 04 24             	mov    %eax,(%esp)
c01027ea:	e8 8a ff ff ff       	call   c0102779 <page2pa>
c01027ef:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01027f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01027f5:	c1 e8 0c             	shr    $0xc,%eax
c01027f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01027fb:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0102800:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c0102803:	72 23                	jb     c0102828 <page2kva+0x4a>
c0102805:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102808:	89 44 24 0c          	mov    %eax,0xc(%esp)
c010280c:	c7 44 24 08 a0 65 10 	movl   $0xc01065a0,0x8(%esp)
c0102813:	c0 
c0102814:	c7 44 24 04 61 00 00 	movl   $0x61,0x4(%esp)
c010281b:	00 
c010281c:	c7 04 24 8f 65 10 c0 	movl   $0xc010658f,(%esp)
c0102823:	e8 c1 db ff ff       	call   c01003e9 <__panic>
c0102828:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010282b:	2d 00 00 00 40       	sub    $0x40000000,%eax
}
c0102830:	c9                   	leave  
c0102831:	c3                   	ret    

c0102832 <pte2page>:
kva2page(void *kva) {
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte) {
c0102832:	55                   	push   %ebp
c0102833:	89 e5                	mov    %esp,%ebp
c0102835:	83 ec 18             	sub    $0x18,%esp
    if (!(pte & PTE_P)) {
c0102838:	8b 45 08             	mov    0x8(%ebp),%eax
c010283b:	83 e0 01             	and    $0x1,%eax
c010283e:	85 c0                	test   %eax,%eax
c0102840:	75 1c                	jne    c010285e <pte2page+0x2c>
        panic("pte2page called with invalid pte");
c0102842:	c7 44 24 08 c4 65 10 	movl   $0xc01065c4,0x8(%esp)
c0102849:	c0 
c010284a:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
c0102851:	00 
c0102852:	c7 04 24 8f 65 10 c0 	movl   $0xc010658f,(%esp)
c0102859:	e8 8b db ff ff       	call   c01003e9 <__panic>
    }
    return pa2page(PTE_ADDR(pte));
c010285e:	8b 45 08             	mov    0x8(%ebp),%eax
c0102861:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0102866:	89 04 24             	mov    %eax,(%esp)
c0102869:	e8 21 ff ff ff       	call   c010278f <pa2page>
}
c010286e:	c9                   	leave  
c010286f:	c3                   	ret    

c0102870 <pde2page>:

static inline struct Page *
pde2page(pde_t pde) {
c0102870:	55                   	push   %ebp
c0102871:	89 e5                	mov    %esp,%ebp
c0102873:	83 ec 18             	sub    $0x18,%esp
    return pa2page(PDE_ADDR(pde));
c0102876:	8b 45 08             	mov    0x8(%ebp),%eax
c0102879:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c010287e:	89 04 24             	mov    %eax,(%esp)
c0102881:	e8 09 ff ff ff       	call   c010278f <pa2page>
}
c0102886:	c9                   	leave  
c0102887:	c3                   	ret    

c0102888 <page_ref>:

static inline int
page_ref(struct Page *page) {
c0102888:	55                   	push   %ebp
c0102889:	89 e5                	mov    %esp,%ebp
    return page->ref;
c010288b:	8b 45 08             	mov    0x8(%ebp),%eax
c010288e:	8b 00                	mov    (%eax),%eax
}
c0102890:	5d                   	pop    %ebp
c0102891:	c3                   	ret    

c0102892 <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
c0102892:	55                   	push   %ebp
c0102893:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c0102895:	8b 45 08             	mov    0x8(%ebp),%eax
c0102898:	8b 55 0c             	mov    0xc(%ebp),%edx
c010289b:	89 10                	mov    %edx,(%eax)
}
c010289d:	90                   	nop
c010289e:	5d                   	pop    %ebp
c010289f:	c3                   	ret    

c01028a0 <page_ref_inc>:

static inline int
page_ref_inc(struct Page *page) {
c01028a0:	55                   	push   %ebp
c01028a1:	89 e5                	mov    %esp,%ebp
    page->ref += 1;
c01028a3:	8b 45 08             	mov    0x8(%ebp),%eax
c01028a6:	8b 00                	mov    (%eax),%eax
c01028a8:	8d 50 01             	lea    0x1(%eax),%edx
c01028ab:	8b 45 08             	mov    0x8(%ebp),%eax
c01028ae:	89 10                	mov    %edx,(%eax)
    return page->ref;
c01028b0:	8b 45 08             	mov    0x8(%ebp),%eax
c01028b3:	8b 00                	mov    (%eax),%eax
}
c01028b5:	5d                   	pop    %ebp
c01028b6:	c3                   	ret    

c01028b7 <page_ref_dec>:

static inline int
page_ref_dec(struct Page *page) {
c01028b7:	55                   	push   %ebp
c01028b8:	89 e5                	mov    %esp,%ebp
    page->ref -= 1;
c01028ba:	8b 45 08             	mov    0x8(%ebp),%eax
c01028bd:	8b 00                	mov    (%eax),%eax
c01028bf:	8d 50 ff             	lea    -0x1(%eax),%edx
c01028c2:	8b 45 08             	mov    0x8(%ebp),%eax
c01028c5:	89 10                	mov    %edx,(%eax)
    return page->ref;
c01028c7:	8b 45 08             	mov    0x8(%ebp),%eax
c01028ca:	8b 00                	mov    (%eax),%eax
}
c01028cc:	5d                   	pop    %ebp
c01028cd:	c3                   	ret    

c01028ce <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
c01028ce:	55                   	push   %ebp
c01028cf:	89 e5                	mov    %esp,%ebp
c01028d1:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c01028d4:	9c                   	pushf  
c01028d5:	58                   	pop    %eax
c01028d6:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c01028d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
c01028dc:	25 00 02 00 00       	and    $0x200,%eax
c01028e1:	85 c0                	test   %eax,%eax
c01028e3:	74 0c                	je     c01028f1 <__intr_save+0x23>
        intr_disable();
c01028e5:	e8 d9 ee ff ff       	call   c01017c3 <intr_disable>
        return 1;
c01028ea:	b8 01 00 00 00       	mov    $0x1,%eax
c01028ef:	eb 05                	jmp    c01028f6 <__intr_save+0x28>
    }
    return 0;
c01028f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01028f6:	c9                   	leave  
c01028f7:	c3                   	ret    

c01028f8 <__intr_restore>:

static inline void
__intr_restore(bool flag) {
c01028f8:	55                   	push   %ebp
c01028f9:	89 e5                	mov    %esp,%ebp
c01028fb:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c01028fe:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0102902:	74 05                	je     c0102909 <__intr_restore+0x11>
        intr_enable();
c0102904:	e8 b3 ee ff ff       	call   c01017bc <intr_enable>
    }
}
c0102909:	90                   	nop
c010290a:	c9                   	leave  
c010290b:	c3                   	ret    

c010290c <lgdt>:
/* *
 * lgdt - load the global descriptor table register and reset the
 * data/code segement registers for kernel.
 * */
static inline void
lgdt(struct pseudodesc *pd) {
c010290c:	55                   	push   %ebp
c010290d:	89 e5                	mov    %esp,%ebp
    asm volatile ("lgdt (%0)" :: "r" (pd));
c010290f:	8b 45 08             	mov    0x8(%ebp),%eax
c0102912:	0f 01 10             	lgdtl  (%eax)
    asm volatile ("movw %%ax, %%gs" :: "a" (USER_DS));
c0102915:	b8 23 00 00 00       	mov    $0x23,%eax
c010291a:	8e e8                	mov    %eax,%gs
    asm volatile ("movw %%ax, %%fs" :: "a" (USER_DS));
c010291c:	b8 23 00 00 00       	mov    $0x23,%eax
c0102921:	8e e0                	mov    %eax,%fs
    asm volatile ("movw %%ax, %%es" :: "a" (KERNEL_DS));
c0102923:	b8 10 00 00 00       	mov    $0x10,%eax
c0102928:	8e c0                	mov    %eax,%es
    asm volatile ("movw %%ax, %%ds" :: "a" (KERNEL_DS));
c010292a:	b8 10 00 00 00       	mov    $0x10,%eax
c010292f:	8e d8                	mov    %eax,%ds
    asm volatile ("movw %%ax, %%ss" :: "a" (KERNEL_DS));
c0102931:	b8 10 00 00 00       	mov    $0x10,%eax
c0102936:	8e d0                	mov    %eax,%ss
    // reload cs
    asm volatile ("ljmp %0, $1f\n 1:\n" :: "i" (KERNEL_CS));
c0102938:	ea 3f 29 10 c0 08 00 	ljmp   $0x8,$0xc010293f
}
c010293f:	90                   	nop
c0102940:	5d                   	pop    %ebp
c0102941:	c3                   	ret    

c0102942 <load_esp0>:
 * load_esp0 - change the ESP0 in default task state segment,
 * so that we can use different kernel stack when we trap frame
 * user to kernel.
 * */
void
load_esp0(uintptr_t esp0) {
c0102942:	55                   	push   %ebp
c0102943:	89 e5                	mov    %esp,%ebp
    ts.ts_esp0 = esp0;
c0102945:	8b 45 08             	mov    0x8(%ebp),%eax
c0102948:	a3 a4 ae 11 c0       	mov    %eax,0xc011aea4
}
c010294d:	90                   	nop
c010294e:	5d                   	pop    %ebp
c010294f:	c3                   	ret    

c0102950 <gdt_init>:

/* gdt_init - initialize the default GDT and TSS */
static void
gdt_init(void) {
c0102950:	55                   	push   %ebp
c0102951:	89 e5                	mov    %esp,%ebp
c0102953:	83 ec 14             	sub    $0x14,%esp
    // set boot kernel stack and default SS0
    load_esp0((uintptr_t)bootstacktop);
c0102956:	b8 00 70 11 c0       	mov    $0xc0117000,%eax
c010295b:	89 04 24             	mov    %eax,(%esp)
c010295e:	e8 df ff ff ff       	call   c0102942 <load_esp0>
    ts.ts_ss0 = KERNEL_DS;
c0102963:	66 c7 05 a8 ae 11 c0 	movw   $0x10,0xc011aea8
c010296a:	10 00 

    // initialize the TSS filed of the gdt
    gdt[SEG_TSS] = SEGTSS(STS_T32A, (uintptr_t)&ts, sizeof(ts), DPL_KERNEL);
c010296c:	66 c7 05 28 7a 11 c0 	movw   $0x68,0xc0117a28
c0102973:	68 00 
c0102975:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c010297a:	0f b7 c0             	movzwl %ax,%eax
c010297d:	66 a3 2a 7a 11 c0    	mov    %ax,0xc0117a2a
c0102983:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c0102988:	c1 e8 10             	shr    $0x10,%eax
c010298b:	a2 2c 7a 11 c0       	mov    %al,0xc0117a2c
c0102990:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c0102997:	24 f0                	and    $0xf0,%al
c0102999:	0c 09                	or     $0x9,%al
c010299b:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c01029a0:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c01029a7:	24 ef                	and    $0xef,%al
c01029a9:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c01029ae:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c01029b5:	24 9f                	and    $0x9f,%al
c01029b7:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c01029bc:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c01029c3:	0c 80                	or     $0x80,%al
c01029c5:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c01029ca:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c01029d1:	24 f0                	and    $0xf0,%al
c01029d3:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c01029d8:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c01029df:	24 ef                	and    $0xef,%al
c01029e1:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c01029e6:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c01029ed:	24 df                	and    $0xdf,%al
c01029ef:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c01029f4:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c01029fb:	0c 40                	or     $0x40,%al
c01029fd:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102a02:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102a09:	24 7f                	and    $0x7f,%al
c0102a0b:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102a10:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c0102a15:	c1 e8 18             	shr    $0x18,%eax
c0102a18:	a2 2f 7a 11 c0       	mov    %al,0xc0117a2f

    // reload all segment registers
    lgdt(&gdt_pd);
c0102a1d:	c7 04 24 30 7a 11 c0 	movl   $0xc0117a30,(%esp)
c0102a24:	e8 e3 fe ff ff       	call   c010290c <lgdt>
c0102a29:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
    asm volatile ("cli" ::: "memory");
}

static inline void
ltr(uint16_t sel) {
    asm volatile ("ltr %0" :: "r" (sel) : "memory");
c0102a2f:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
c0102a33:	0f 00 d8             	ltr    %ax

    // load the TSS
    ltr(GD_TSS);
}
c0102a36:	90                   	nop
c0102a37:	c9                   	leave  
c0102a38:	c3                   	ret    

c0102a39 <init_pmm_manager>:

//init_pmm_manager - initialize a pmm_manager instance
static void
init_pmm_manager(void) {
c0102a39:	55                   	push   %ebp
c0102a3a:	89 e5                	mov    %esp,%ebp
c0102a3c:	83 ec 18             	sub    $0x18,%esp
    pmm_manager = &default_pmm_manager;
c0102a3f:	c7 05 10 af 11 c0 80 	movl   $0xc0106f80,0xc011af10
c0102a46:	6f 10 c0 
    cprintf("memory management: %s\n", pmm_manager->name);
c0102a49:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102a4e:	8b 00                	mov    (%eax),%eax
c0102a50:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102a54:	c7 04 24 f0 65 10 c0 	movl   $0xc01065f0,(%esp)
c0102a5b:	e8 32 d8 ff ff       	call   c0100292 <cprintf>
    pmm_manager->init();
c0102a60:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102a65:	8b 40 04             	mov    0x4(%eax),%eax
c0102a68:	ff d0                	call   *%eax
}
c0102a6a:	90                   	nop
c0102a6b:	c9                   	leave  
c0102a6c:	c3                   	ret    

c0102a6d <init_memmap>:

//init_memmap - call pmm->init_memmap to build Page struct for free memory  
static void
init_memmap(struct Page *base, size_t n) {
c0102a6d:	55                   	push   %ebp
c0102a6e:	89 e5                	mov    %esp,%ebp
c0102a70:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->init_memmap(base, n);
c0102a73:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102a78:	8b 40 08             	mov    0x8(%eax),%eax
c0102a7b:	8b 55 0c             	mov    0xc(%ebp),%edx
c0102a7e:	89 54 24 04          	mov    %edx,0x4(%esp)
c0102a82:	8b 55 08             	mov    0x8(%ebp),%edx
c0102a85:	89 14 24             	mov    %edx,(%esp)
c0102a88:	ff d0                	call   *%eax
}
c0102a8a:	90                   	nop
c0102a8b:	c9                   	leave  
c0102a8c:	c3                   	ret    

c0102a8d <alloc_pages>:

//alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory 
struct Page *
alloc_pages(size_t n) {
c0102a8d:	55                   	push   %ebp
c0102a8e:	89 e5                	mov    %esp,%ebp
c0102a90:	83 ec 28             	sub    $0x28,%esp
    struct Page *page=NULL;
c0102a93:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
c0102a9a:	e8 2f fe ff ff       	call   c01028ce <__intr_save>
c0102a9f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        page = pmm_manager->alloc_pages(n);
c0102aa2:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102aa7:	8b 40 0c             	mov    0xc(%eax),%eax
c0102aaa:	8b 55 08             	mov    0x8(%ebp),%edx
c0102aad:	89 14 24             	mov    %edx,(%esp)
c0102ab0:	ff d0                	call   *%eax
c0102ab2:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }
    local_intr_restore(intr_flag);
c0102ab5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0102ab8:	89 04 24             	mov    %eax,(%esp)
c0102abb:	e8 38 fe ff ff       	call   c01028f8 <__intr_restore>
    return page;
c0102ac0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0102ac3:	c9                   	leave  
c0102ac4:	c3                   	ret    

c0102ac5 <free_pages>:

//free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory 
void
free_pages(struct Page *base, size_t n) {
c0102ac5:	55                   	push   %ebp
c0102ac6:	89 e5                	mov    %esp,%ebp
c0102ac8:	83 ec 28             	sub    $0x28,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
c0102acb:	e8 fe fd ff ff       	call   c01028ce <__intr_save>
c0102ad0:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        pmm_manager->free_pages(base, n);
c0102ad3:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102ad8:	8b 40 10             	mov    0x10(%eax),%eax
c0102adb:	8b 55 0c             	mov    0xc(%ebp),%edx
c0102ade:	89 54 24 04          	mov    %edx,0x4(%esp)
c0102ae2:	8b 55 08             	mov    0x8(%ebp),%edx
c0102ae5:	89 14 24             	mov    %edx,(%esp)
c0102ae8:	ff d0                	call   *%eax
    }
    local_intr_restore(intr_flag);
c0102aea:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102aed:	89 04 24             	mov    %eax,(%esp)
c0102af0:	e8 03 fe ff ff       	call   c01028f8 <__intr_restore>
}
c0102af5:	90                   	nop
c0102af6:	c9                   	leave  
c0102af7:	c3                   	ret    

c0102af8 <nr_free_pages>:

//nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE) 
//of current free memory
size_t
nr_free_pages(void) {
c0102af8:	55                   	push   %ebp
c0102af9:	89 e5                	mov    %esp,%ebp
c0102afb:	83 ec 28             	sub    $0x28,%esp
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
c0102afe:	e8 cb fd ff ff       	call   c01028ce <__intr_save>
c0102b03:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        ret = pmm_manager->nr_free_pages();
c0102b06:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102b0b:	8b 40 14             	mov    0x14(%eax),%eax
c0102b0e:	ff d0                	call   *%eax
c0102b10:	89 45 f0             	mov    %eax,-0x10(%ebp)
    }
    local_intr_restore(intr_flag);
c0102b13:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102b16:	89 04 24             	mov    %eax,(%esp)
c0102b19:	e8 da fd ff ff       	call   c01028f8 <__intr_restore>
    return ret;
c0102b1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
c0102b21:	c9                   	leave  
c0102b22:	c3                   	ret    

c0102b23 <page_init>:

/* pmm_init - initialize the physical memory management */
static void
page_init(void) {
c0102b23:	55                   	push   %ebp
c0102b24:	89 e5                	mov    %esp,%ebp
c0102b26:	57                   	push   %edi
c0102b27:	56                   	push   %esi
c0102b28:	53                   	push   %ebx
c0102b29:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
c0102b2f:	c7 45 c4 00 80 00 c0 	movl   $0xc0008000,-0x3c(%ebp)
    uint64_t maxpa = 0;
c0102b36:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
c0102b3d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

    cprintf("e820map:\n");
c0102b44:	c7 04 24 07 66 10 c0 	movl   $0xc0106607,(%esp)
c0102b4b:	e8 42 d7 ff ff       	call   c0100292 <cprintf>
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
c0102b50:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102b57:	e9 22 01 00 00       	jmp    c0102c7e <page_init+0x15b>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
c0102b5c:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102b5f:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102b62:	89 d0                	mov    %edx,%eax
c0102b64:	c1 e0 02             	shl    $0x2,%eax
c0102b67:	01 d0                	add    %edx,%eax
c0102b69:	c1 e0 02             	shl    $0x2,%eax
c0102b6c:	01 c8                	add    %ecx,%eax
c0102b6e:	8b 50 08             	mov    0x8(%eax),%edx
c0102b71:	8b 40 04             	mov    0x4(%eax),%eax
c0102b74:	89 45 b8             	mov    %eax,-0x48(%ebp)
c0102b77:	89 55 bc             	mov    %edx,-0x44(%ebp)
c0102b7a:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102b7d:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102b80:	89 d0                	mov    %edx,%eax
c0102b82:	c1 e0 02             	shl    $0x2,%eax
c0102b85:	01 d0                	add    %edx,%eax
c0102b87:	c1 e0 02             	shl    $0x2,%eax
c0102b8a:	01 c8                	add    %ecx,%eax
c0102b8c:	8b 48 0c             	mov    0xc(%eax),%ecx
c0102b8f:	8b 58 10             	mov    0x10(%eax),%ebx
c0102b92:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0102b95:	8b 55 bc             	mov    -0x44(%ebp),%edx
c0102b98:	01 c8                	add    %ecx,%eax
c0102b9a:	11 da                	adc    %ebx,%edx
c0102b9c:	89 45 b0             	mov    %eax,-0x50(%ebp)
c0102b9f:	89 55 b4             	mov    %edx,-0x4c(%ebp)
        cprintf("  memory: %08llx, [%08llx, %08llx], type = %d.\n",
c0102ba2:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102ba5:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102ba8:	89 d0                	mov    %edx,%eax
c0102baa:	c1 e0 02             	shl    $0x2,%eax
c0102bad:	01 d0                	add    %edx,%eax
c0102baf:	c1 e0 02             	shl    $0x2,%eax
c0102bb2:	01 c8                	add    %ecx,%eax
c0102bb4:	83 c0 14             	add    $0x14,%eax
c0102bb7:	8b 00                	mov    (%eax),%eax
c0102bb9:	89 45 84             	mov    %eax,-0x7c(%ebp)
c0102bbc:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0102bbf:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0102bc2:	83 c0 ff             	add    $0xffffffff,%eax
c0102bc5:	83 d2 ff             	adc    $0xffffffff,%edx
c0102bc8:	89 85 78 ff ff ff    	mov    %eax,-0x88(%ebp)
c0102bce:	89 95 7c ff ff ff    	mov    %edx,-0x84(%ebp)
c0102bd4:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102bd7:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102bda:	89 d0                	mov    %edx,%eax
c0102bdc:	c1 e0 02             	shl    $0x2,%eax
c0102bdf:	01 d0                	add    %edx,%eax
c0102be1:	c1 e0 02             	shl    $0x2,%eax
c0102be4:	01 c8                	add    %ecx,%eax
c0102be6:	8b 48 0c             	mov    0xc(%eax),%ecx
c0102be9:	8b 58 10             	mov    0x10(%eax),%ebx
c0102bec:	8b 55 84             	mov    -0x7c(%ebp),%edx
c0102bef:	89 54 24 1c          	mov    %edx,0x1c(%esp)
c0102bf3:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
c0102bf9:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
c0102bff:	89 44 24 14          	mov    %eax,0x14(%esp)
c0102c03:	89 54 24 18          	mov    %edx,0x18(%esp)
c0102c07:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0102c0a:	8b 55 bc             	mov    -0x44(%ebp),%edx
c0102c0d:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0102c11:	89 54 24 10          	mov    %edx,0x10(%esp)
c0102c15:	89 4c 24 04          	mov    %ecx,0x4(%esp)
c0102c19:	89 5c 24 08          	mov    %ebx,0x8(%esp)
c0102c1d:	c7 04 24 14 66 10 c0 	movl   $0xc0106614,(%esp)
c0102c24:	e8 69 d6 ff ff       	call   c0100292 <cprintf>
                memmap->map[i].size, begin, end - 1, memmap->map[i].type);
        if (memmap->map[i].type == E820_ARM) {
c0102c29:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102c2c:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102c2f:	89 d0                	mov    %edx,%eax
c0102c31:	c1 e0 02             	shl    $0x2,%eax
c0102c34:	01 d0                	add    %edx,%eax
c0102c36:	c1 e0 02             	shl    $0x2,%eax
c0102c39:	01 c8                	add    %ecx,%eax
c0102c3b:	83 c0 14             	add    $0x14,%eax
c0102c3e:	8b 00                	mov    (%eax),%eax
c0102c40:	83 f8 01             	cmp    $0x1,%eax
c0102c43:	75 36                	jne    c0102c7b <page_init+0x158>
            if (maxpa < end && begin < KMEMSIZE) {
c0102c45:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0102c48:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0102c4b:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
c0102c4e:	77 2b                	ja     c0102c7b <page_init+0x158>
c0102c50:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
c0102c53:	72 05                	jb     c0102c5a <page_init+0x137>
c0102c55:	3b 45 b0             	cmp    -0x50(%ebp),%eax
c0102c58:	73 21                	jae    c0102c7b <page_init+0x158>
c0102c5a:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
c0102c5e:	77 1b                	ja     c0102c7b <page_init+0x158>
c0102c60:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
c0102c64:	72 09                	jb     c0102c6f <page_init+0x14c>
c0102c66:	81 7d b8 ff ff ff 37 	cmpl   $0x37ffffff,-0x48(%ebp)
c0102c6d:	77 0c                	ja     c0102c7b <page_init+0x158>
                maxpa = end;
c0102c6f:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0102c72:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0102c75:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0102c78:	89 55 e4             	mov    %edx,-0x1c(%ebp)
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
    uint64_t maxpa = 0;

    cprintf("e820map:\n");
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
c0102c7b:	ff 45 dc             	incl   -0x24(%ebp)
c0102c7e:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0102c81:	8b 00                	mov    (%eax),%eax
c0102c83:	3b 45 dc             	cmp    -0x24(%ebp),%eax
c0102c86:	0f 8f d0 fe ff ff    	jg     c0102b5c <page_init+0x39>
            if (maxpa < end && begin < KMEMSIZE) {
                maxpa = end;
            }
        }
    }
    if (maxpa > KMEMSIZE) {
c0102c8c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0102c90:	72 1d                	jb     c0102caf <page_init+0x18c>
c0102c92:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0102c96:	77 09                	ja     c0102ca1 <page_init+0x17e>
c0102c98:	81 7d e0 00 00 00 38 	cmpl   $0x38000000,-0x20(%ebp)
c0102c9f:	76 0e                	jbe    c0102caf <page_init+0x18c>
        maxpa = KMEMSIZE;
c0102ca1:	c7 45 e0 00 00 00 38 	movl   $0x38000000,-0x20(%ebp)
c0102ca8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    }

    extern char end[];

    npage = maxpa / PGSIZE;
c0102caf:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0102cb2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0102cb5:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c0102cb9:	c1 ea 0c             	shr    $0xc,%edx
c0102cbc:	a3 80 ae 11 c0       	mov    %eax,0xc011ae80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
c0102cc1:	c7 45 ac 00 10 00 00 	movl   $0x1000,-0x54(%ebp)
c0102cc8:	b8 28 af 11 c0       	mov    $0xc011af28,%eax
c0102ccd:	8d 50 ff             	lea    -0x1(%eax),%edx
c0102cd0:	8b 45 ac             	mov    -0x54(%ebp),%eax
c0102cd3:	01 d0                	add    %edx,%eax
c0102cd5:	89 45 a8             	mov    %eax,-0x58(%ebp)
c0102cd8:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0102cdb:	ba 00 00 00 00       	mov    $0x0,%edx
c0102ce0:	f7 75 ac             	divl   -0x54(%ebp)
c0102ce3:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0102ce6:	29 d0                	sub    %edx,%eax
c0102ce8:	a3 18 af 11 c0       	mov    %eax,0xc011af18

    for (i = 0; i < npage; i ++) {
c0102ced:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102cf4:	eb 2e                	jmp    c0102d24 <page_init+0x201>
        SetPageReserved(pages + i);
c0102cf6:	8b 0d 18 af 11 c0    	mov    0xc011af18,%ecx
c0102cfc:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102cff:	89 d0                	mov    %edx,%eax
c0102d01:	c1 e0 02             	shl    $0x2,%eax
c0102d04:	01 d0                	add    %edx,%eax
c0102d06:	c1 e0 02             	shl    $0x2,%eax
c0102d09:	01 c8                	add    %ecx,%eax
c0102d0b:	83 c0 04             	add    $0x4,%eax
c0102d0e:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
c0102d15:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0102d18:	8b 45 8c             	mov    -0x74(%ebp),%eax
c0102d1b:	8b 55 90             	mov    -0x70(%ebp),%edx
c0102d1e:	0f ab 10             	bts    %edx,(%eax)
    extern char end[];

    npage = maxpa / PGSIZE;
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    for (i = 0; i < npage; i ++) {
c0102d21:	ff 45 dc             	incl   -0x24(%ebp)
c0102d24:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102d27:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0102d2c:	39 c2                	cmp    %eax,%edx
c0102d2e:	72 c6                	jb     c0102cf6 <page_init+0x1d3>
        SetPageReserved(pages + i);
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);
c0102d30:	8b 15 80 ae 11 c0    	mov    0xc011ae80,%edx
c0102d36:	89 d0                	mov    %edx,%eax
c0102d38:	c1 e0 02             	shl    $0x2,%eax
c0102d3b:	01 d0                	add    %edx,%eax
c0102d3d:	c1 e0 02             	shl    $0x2,%eax
c0102d40:	89 c2                	mov    %eax,%edx
c0102d42:	a1 18 af 11 c0       	mov    0xc011af18,%eax
c0102d47:	01 d0                	add    %edx,%eax
c0102d49:	89 45 a4             	mov    %eax,-0x5c(%ebp)
c0102d4c:	81 7d a4 ff ff ff bf 	cmpl   $0xbfffffff,-0x5c(%ebp)
c0102d53:	77 23                	ja     c0102d78 <page_init+0x255>
c0102d55:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0102d58:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0102d5c:	c7 44 24 08 44 66 10 	movl   $0xc0106644,0x8(%esp)
c0102d63:	c0 
c0102d64:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
c0102d6b:	00 
c0102d6c:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0102d73:	e8 71 d6 ff ff       	call   c01003e9 <__panic>
c0102d78:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0102d7b:	05 00 00 00 40       	add    $0x40000000,%eax
c0102d80:	89 45 a0             	mov    %eax,-0x60(%ebp)

    for (i = 0; i < memmap->nr_map; i ++) {
c0102d83:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102d8a:	e9 61 01 00 00       	jmp    c0102ef0 <page_init+0x3cd>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
c0102d8f:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102d92:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102d95:	89 d0                	mov    %edx,%eax
c0102d97:	c1 e0 02             	shl    $0x2,%eax
c0102d9a:	01 d0                	add    %edx,%eax
c0102d9c:	c1 e0 02             	shl    $0x2,%eax
c0102d9f:	01 c8                	add    %ecx,%eax
c0102da1:	8b 50 08             	mov    0x8(%eax),%edx
c0102da4:	8b 40 04             	mov    0x4(%eax),%eax
c0102da7:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0102daa:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0102dad:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102db0:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102db3:	89 d0                	mov    %edx,%eax
c0102db5:	c1 e0 02             	shl    $0x2,%eax
c0102db8:	01 d0                	add    %edx,%eax
c0102dba:	c1 e0 02             	shl    $0x2,%eax
c0102dbd:	01 c8                	add    %ecx,%eax
c0102dbf:	8b 48 0c             	mov    0xc(%eax),%ecx
c0102dc2:	8b 58 10             	mov    0x10(%eax),%ebx
c0102dc5:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102dc8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0102dcb:	01 c8                	add    %ecx,%eax
c0102dcd:	11 da                	adc    %ebx,%edx
c0102dcf:	89 45 c8             	mov    %eax,-0x38(%ebp)
c0102dd2:	89 55 cc             	mov    %edx,-0x34(%ebp)
        if (memmap->map[i].type == E820_ARM) {
c0102dd5:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102dd8:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102ddb:	89 d0                	mov    %edx,%eax
c0102ddd:	c1 e0 02             	shl    $0x2,%eax
c0102de0:	01 d0                	add    %edx,%eax
c0102de2:	c1 e0 02             	shl    $0x2,%eax
c0102de5:	01 c8                	add    %ecx,%eax
c0102de7:	83 c0 14             	add    $0x14,%eax
c0102dea:	8b 00                	mov    (%eax),%eax
c0102dec:	83 f8 01             	cmp    $0x1,%eax
c0102def:	0f 85 f8 00 00 00    	jne    c0102eed <page_init+0x3ca>
            if (begin < freemem) {
c0102df5:	8b 45 a0             	mov    -0x60(%ebp),%eax
c0102df8:	ba 00 00 00 00       	mov    $0x0,%edx
c0102dfd:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0102e00:	72 17                	jb     c0102e19 <page_init+0x2f6>
c0102e02:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0102e05:	77 05                	ja     c0102e0c <page_init+0x2e9>
c0102e07:	3b 45 d0             	cmp    -0x30(%ebp),%eax
c0102e0a:	76 0d                	jbe    c0102e19 <page_init+0x2f6>
                begin = freemem;
c0102e0c:	8b 45 a0             	mov    -0x60(%ebp),%eax
c0102e0f:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0102e12:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
            }
            if (end > KMEMSIZE) {
c0102e19:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c0102e1d:	72 1d                	jb     c0102e3c <page_init+0x319>
c0102e1f:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c0102e23:	77 09                	ja     c0102e2e <page_init+0x30b>
c0102e25:	81 7d c8 00 00 00 38 	cmpl   $0x38000000,-0x38(%ebp)
c0102e2c:	76 0e                	jbe    c0102e3c <page_init+0x319>
                end = KMEMSIZE;
c0102e2e:	c7 45 c8 00 00 00 38 	movl   $0x38000000,-0x38(%ebp)
c0102e35:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
            }
            if (begin < end) {
c0102e3c:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102e3f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0102e42:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0102e45:	0f 87 a2 00 00 00    	ja     c0102eed <page_init+0x3ca>
c0102e4b:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0102e4e:	72 09                	jb     c0102e59 <page_init+0x336>
c0102e50:	3b 45 c8             	cmp    -0x38(%ebp),%eax
c0102e53:	0f 83 94 00 00 00    	jae    c0102eed <page_init+0x3ca>
                begin = ROUNDUP(begin, PGSIZE);
c0102e59:	c7 45 9c 00 10 00 00 	movl   $0x1000,-0x64(%ebp)
c0102e60:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0102e63:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0102e66:	01 d0                	add    %edx,%eax
c0102e68:	48                   	dec    %eax
c0102e69:	89 45 98             	mov    %eax,-0x68(%ebp)
c0102e6c:	8b 45 98             	mov    -0x68(%ebp),%eax
c0102e6f:	ba 00 00 00 00       	mov    $0x0,%edx
c0102e74:	f7 75 9c             	divl   -0x64(%ebp)
c0102e77:	8b 45 98             	mov    -0x68(%ebp),%eax
c0102e7a:	29 d0                	sub    %edx,%eax
c0102e7c:	ba 00 00 00 00       	mov    $0x0,%edx
c0102e81:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0102e84:	89 55 d4             	mov    %edx,-0x2c(%ebp)
                end = ROUNDDOWN(end, PGSIZE);
c0102e87:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0102e8a:	89 45 94             	mov    %eax,-0x6c(%ebp)
c0102e8d:	8b 45 94             	mov    -0x6c(%ebp),%eax
c0102e90:	ba 00 00 00 00       	mov    $0x0,%edx
c0102e95:	89 c3                	mov    %eax,%ebx
c0102e97:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
c0102e9d:	89 de                	mov    %ebx,%esi
c0102e9f:	89 d0                	mov    %edx,%eax
c0102ea1:	83 e0 00             	and    $0x0,%eax
c0102ea4:	89 c7                	mov    %eax,%edi
c0102ea6:	89 75 c8             	mov    %esi,-0x38(%ebp)
c0102ea9:	89 7d cc             	mov    %edi,-0x34(%ebp)
                if (begin < end) {
c0102eac:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102eaf:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0102eb2:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0102eb5:	77 36                	ja     c0102eed <page_init+0x3ca>
c0102eb7:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0102eba:	72 05                	jb     c0102ec1 <page_init+0x39e>
c0102ebc:	3b 45 c8             	cmp    -0x38(%ebp),%eax
c0102ebf:	73 2c                	jae    c0102eed <page_init+0x3ca>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
c0102ec1:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0102ec4:	8b 55 cc             	mov    -0x34(%ebp),%edx
c0102ec7:	2b 45 d0             	sub    -0x30(%ebp),%eax
c0102eca:	1b 55 d4             	sbb    -0x2c(%ebp),%edx
c0102ecd:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c0102ed1:	c1 ea 0c             	shr    $0xc,%edx
c0102ed4:	89 c3                	mov    %eax,%ebx
c0102ed6:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102ed9:	89 04 24             	mov    %eax,(%esp)
c0102edc:	e8 ae f8 ff ff       	call   c010278f <pa2page>
c0102ee1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
c0102ee5:	89 04 24             	mov    %eax,(%esp)
c0102ee8:	e8 80 fb ff ff       	call   c0102a6d <init_memmap>
        SetPageReserved(pages + i);
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);

    for (i = 0; i < memmap->nr_map; i ++) {
c0102eed:	ff 45 dc             	incl   -0x24(%ebp)
c0102ef0:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0102ef3:	8b 00                	mov    (%eax),%eax
c0102ef5:	3b 45 dc             	cmp    -0x24(%ebp),%eax
c0102ef8:	0f 8f 91 fe ff ff    	jg     c0102d8f <page_init+0x26c>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
                }
            }
        }
    }
}
c0102efe:	90                   	nop
c0102eff:	81 c4 9c 00 00 00    	add    $0x9c,%esp
c0102f05:	5b                   	pop    %ebx
c0102f06:	5e                   	pop    %esi
c0102f07:	5f                   	pop    %edi
c0102f08:	5d                   	pop    %ebp
c0102f09:	c3                   	ret    

c0102f0a <boot_map_segment>:
//  la:   linear address of this memory need to map (after x86 segment map)
//  size: memory size
//  pa:   physical address of this memory
//  perm: permission of this memory  
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
c0102f0a:	55                   	push   %ebp
c0102f0b:	89 e5                	mov    %esp,%ebp
c0102f0d:	83 ec 38             	sub    $0x38,%esp
    assert(PGOFF(la) == PGOFF(pa));
c0102f10:	8b 45 0c             	mov    0xc(%ebp),%eax
c0102f13:	33 45 14             	xor    0x14(%ebp),%eax
c0102f16:	25 ff 0f 00 00       	and    $0xfff,%eax
c0102f1b:	85 c0                	test   %eax,%eax
c0102f1d:	74 24                	je     c0102f43 <boot_map_segment+0x39>
c0102f1f:	c7 44 24 0c 76 66 10 	movl   $0xc0106676,0xc(%esp)
c0102f26:	c0 
c0102f27:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0102f2e:	c0 
c0102f2f:	c7 44 24 04 06 01 00 	movl   $0x106,0x4(%esp)
c0102f36:	00 
c0102f37:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0102f3e:	e8 a6 d4 ff ff       	call   c01003e9 <__panic>
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
c0102f43:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
c0102f4a:	8b 45 0c             	mov    0xc(%ebp),%eax
c0102f4d:	25 ff 0f 00 00       	and    $0xfff,%eax
c0102f52:	89 c2                	mov    %eax,%edx
c0102f54:	8b 45 10             	mov    0x10(%ebp),%eax
c0102f57:	01 c2                	add    %eax,%edx
c0102f59:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0102f5c:	01 d0                	add    %edx,%eax
c0102f5e:	48                   	dec    %eax
c0102f5f:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0102f62:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0102f65:	ba 00 00 00 00       	mov    $0x0,%edx
c0102f6a:	f7 75 f0             	divl   -0x10(%ebp)
c0102f6d:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0102f70:	29 d0                	sub    %edx,%eax
c0102f72:	c1 e8 0c             	shr    $0xc,%eax
c0102f75:	89 45 f4             	mov    %eax,-0xc(%ebp)
    la = ROUNDDOWN(la, PGSIZE);
c0102f78:	8b 45 0c             	mov    0xc(%ebp),%eax
c0102f7b:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0102f7e:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0102f81:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0102f86:	89 45 0c             	mov    %eax,0xc(%ebp)
    pa = ROUNDDOWN(pa, PGSIZE);
c0102f89:	8b 45 14             	mov    0x14(%ebp),%eax
c0102f8c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0102f8f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0102f92:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0102f97:	89 45 14             	mov    %eax,0x14(%ebp)
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
c0102f9a:	eb 68                	jmp    c0103004 <boot_map_segment+0xfa>
        pte_t *ptep = get_pte(pgdir, la, 1);
c0102f9c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
c0102fa3:	00 
c0102fa4:	8b 45 0c             	mov    0xc(%ebp),%eax
c0102fa7:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102fab:	8b 45 08             	mov    0x8(%ebp),%eax
c0102fae:	89 04 24             	mov    %eax,(%esp)
c0102fb1:	e8 81 01 00 00       	call   c0103137 <get_pte>
c0102fb6:	89 45 e0             	mov    %eax,-0x20(%ebp)
        assert(ptep != NULL);
c0102fb9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c0102fbd:	75 24                	jne    c0102fe3 <boot_map_segment+0xd9>
c0102fbf:	c7 44 24 0c a2 66 10 	movl   $0xc01066a2,0xc(%esp)
c0102fc6:	c0 
c0102fc7:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0102fce:	c0 
c0102fcf:	c7 44 24 04 0c 01 00 	movl   $0x10c,0x4(%esp)
c0102fd6:	00 
c0102fd7:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0102fde:	e8 06 d4 ff ff       	call   c01003e9 <__panic>
        *ptep = pa | PTE_P | perm;
c0102fe3:	8b 45 14             	mov    0x14(%ebp),%eax
c0102fe6:	0b 45 18             	or     0x18(%ebp),%eax
c0102fe9:	83 c8 01             	or     $0x1,%eax
c0102fec:	89 c2                	mov    %eax,%edx
c0102fee:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0102ff1:	89 10                	mov    %edx,(%eax)
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
    assert(PGOFF(la) == PGOFF(pa));
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
c0102ff3:	ff 4d f4             	decl   -0xc(%ebp)
c0102ff6:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
c0102ffd:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
c0103004:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103008:	75 92                	jne    c0102f9c <boot_map_segment+0x92>
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pa | PTE_P | perm;
    }
}
c010300a:	90                   	nop
c010300b:	c9                   	leave  
c010300c:	c3                   	ret    

c010300d <boot_alloc_page>:

//boot_alloc_page - allocate one page using pmm->alloc_pages(1) 
// return value: the kernel virtual address of this allocated page
//note: this function is used to get the memory for PDT(Page Directory Table)&PT(Page Table)
static void *
boot_alloc_page(void) {
c010300d:	55                   	push   %ebp
c010300e:	89 e5                	mov    %esp,%ebp
c0103010:	83 ec 28             	sub    $0x28,%esp
    struct Page *p = alloc_page();
c0103013:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010301a:	e8 6e fa ff ff       	call   c0102a8d <alloc_pages>
c010301f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (p == NULL) {
c0103022:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103026:	75 1c                	jne    c0103044 <boot_alloc_page+0x37>
        panic("boot_alloc_page failed.\n");
c0103028:	c7 44 24 08 af 66 10 	movl   $0xc01066af,0x8(%esp)
c010302f:	c0 
c0103030:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
c0103037:	00 
c0103038:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c010303f:	e8 a5 d3 ff ff       	call   c01003e9 <__panic>
    }
    return page2kva(p);
c0103044:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103047:	89 04 24             	mov    %eax,(%esp)
c010304a:	e8 8f f7 ff ff       	call   c01027de <page2kva>
}
c010304f:	c9                   	leave  
c0103050:	c3                   	ret    

c0103051 <pmm_init>:

//pmm_init - setup a pmm to manage physical memory, build PDT&PT to setup paging mechanism 
//         - check the correctness of pmm & paging mechanism, print PDT&PT
void
pmm_init(void) {
c0103051:	55                   	push   %ebp
c0103052:	89 e5                	mov    %esp,%ebp
c0103054:	83 ec 38             	sub    $0x38,%esp
    // We've already enabled paging
    boot_cr3 = PADDR(boot_pgdir);
c0103057:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010305c:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010305f:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
c0103066:	77 23                	ja     c010308b <pmm_init+0x3a>
c0103068:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010306b:	89 44 24 0c          	mov    %eax,0xc(%esp)
c010306f:	c7 44 24 08 44 66 10 	movl   $0xc0106644,0x8(%esp)
c0103076:	c0 
c0103077:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
c010307e:	00 
c010307f:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103086:	e8 5e d3 ff ff       	call   c01003e9 <__panic>
c010308b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010308e:	05 00 00 00 40       	add    $0x40000000,%eax
c0103093:	a3 14 af 11 c0       	mov    %eax,0xc011af14
    //We need to alloc/free the physical memory (granularity is 4KB or other size). 
    //So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    //First we should init a physical memory manager(pmm) based on the framework.
    //Then pmm can alloc/free the physical memory. 
    //Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();
c0103098:	e8 9c f9 ff ff       	call   c0102a39 <init_pmm_manager>

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();
c010309d:	e8 81 fa ff ff       	call   c0102b23 <page_init>

    //use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();
c01030a2:	e8 f9 03 00 00       	call   c01034a0 <check_alloc_page>

    check_pgdir();
c01030a7:	e8 13 04 00 00       	call   c01034bf <check_pgdir>

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // recursively insert boot_pgdir in itself
    // to form a virtual page table at virtual address VPT
    boot_pgdir[PDX(VPT)] = PADDR(boot_pgdir) | PTE_P | PTE_W;
c01030ac:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01030b1:	8d 90 ac 0f 00 00    	lea    0xfac(%eax),%edx
c01030b7:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01030bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01030bf:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
c01030c6:	77 23                	ja     c01030eb <pmm_init+0x9a>
c01030c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01030cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01030cf:	c7 44 24 08 44 66 10 	movl   $0xc0106644,0x8(%esp)
c01030d6:	c0 
c01030d7:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
c01030de:	00 
c01030df:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c01030e6:	e8 fe d2 ff ff       	call   c01003e9 <__panic>
c01030eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01030ee:	05 00 00 00 40       	add    $0x40000000,%eax
c01030f3:	83 c8 03             	or     $0x3,%eax
c01030f6:	89 02                	mov    %eax,(%edx)

    // map all physical memory to linear memory with base linear addr KERNBASE
    // linear_addr KERNBASE ~ KERNBASE + KMEMSIZE = phy_addr 0 ~ KMEMSIZE
    boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, 0, PTE_W);
c01030f8:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01030fd:	c7 44 24 10 02 00 00 	movl   $0x2,0x10(%esp)
c0103104:	00 
c0103105:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
c010310c:	00 
c010310d:	c7 44 24 08 00 00 00 	movl   $0x38000000,0x8(%esp)
c0103114:	38 
c0103115:	c7 44 24 04 00 00 00 	movl   $0xc0000000,0x4(%esp)
c010311c:	c0 
c010311d:	89 04 24             	mov    %eax,(%esp)
c0103120:	e8 e5 fd ff ff       	call   c0102f0a <boot_map_segment>

    // Since we are using bootloader's GDT,
    // we should reload gdt (second time, the last time) to get user segments and the TSS
    // map virtual_addr 0 ~ 4G = linear_addr 0 ~ 4G
    // then set kernel stack (ss:esp) in TSS, setup TSS in gdt, load TSS
    gdt_init();
c0103125:	e8 26 f8 ff ff       	call   c0102950 <gdt_init>

    //now the basic virtual memory map(see memalyout.h) is established.
    //check the correctness of the basic virtual memory map.
    check_boot_pgdir();
c010312a:	e8 2c 0a 00 00       	call   c0103b5b <check_boot_pgdir>

    print_pgdir();
c010312f:	e8 a5 0e 00 00       	call   c0103fd9 <print_pgdir>

}
c0103134:	90                   	nop
c0103135:	c9                   	leave  
c0103136:	c3                   	ret    

c0103137 <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *
get_pte(pde_t *pgdir, uintptr_t la, bool create) {
c0103137:	55                   	push   %ebp
c0103138:	89 e5                	mov    %esp,%ebp
c010313a:	83 ec 48             	sub    $0x48,%esp
    }
    return NULL;          // (8) return page table entry
#endif
    // Get the page directory entry by adding offset(the index) and the base address of page direcotry table.

    pde_t *entry = &pgdir[PDX(la)];
c010313d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103140:	c1 e8 16             	shr    $0x16,%eax
c0103143:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c010314a:	8b 45 08             	mov    0x8(%ebp),%eax
c010314d:	01 d0                	add    %edx,%eax
c010314f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    
    if (!(*entry & PTE_P)) {
c0103152:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103155:	8b 00                	mov    (%eax),%eax
c0103157:	83 e0 01             	and    $0x1,%eax
c010315a:	85 c0                	test   %eax,%eax
c010315c:	0f 85 b6 00 00 00    	jne    c0103218 <get_pte+0xe1>
        // Not present in the table? We need to allocate the page table.
        struct Page *page = create ? alloc_page() : NULL;
c0103162:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0103166:	74 0e                	je     c0103176 <get_pte+0x3f>
c0103168:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010316f:	e8 19 f9 ff ff       	call   c0102a8d <alloc_pages>
c0103174:	eb 05                	jmp    c010317b <get_pte+0x44>
c0103176:	b8 00 00 00 00       	mov    $0x0,%eax
c010317b:	89 45 f0             	mov    %eax,-0x10(%ebp)

	if (!page) {
c010317e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0103182:	75 0a                	jne    c010318e <get_pte+0x57>
	    return NULL;
c0103184:	b8 00 00 00 00       	mov    $0x0,%eax
c0103189:	e9 fb 00 00 00       	jmp    c0103289 <get_pte+0x152>
        }

        // Initialize the page.
        set_page_ref(page, 1);
c010318e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0103195:	00 
c0103196:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103199:	89 04 24             	mov    %eax,(%esp)
c010319c:	e8 f1 f6 ff ff       	call   c0102892 <set_page_ref>
        // Get the physical address for next step.
        // ? uintptr_t seems to be unsigned int...
        uintptr_t page_addr = page2pa(page);
c01031a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01031a4:	89 04 24             	mov    %eax,(%esp)
c01031a7:	e8 cd f5 ff ff       	call   c0102779 <page2pa>
c01031ac:	89 45 ec             	mov    %eax,-0x14(%ebp)
        // Set the page to be empty in the kernel.
        memset(KADDR(page_addr), 0, (PGSIZE));
c01031af:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01031b2:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01031b5:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01031b8:	c1 e8 0c             	shr    $0xc,%eax
c01031bb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01031be:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01031c3:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
c01031c6:	72 23                	jb     c01031eb <get_pte+0xb4>
c01031c8:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01031cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01031cf:	c7 44 24 08 a0 65 10 	movl   $0xc01065a0,0x8(%esp)
c01031d6:	c0 
c01031d7:	c7 44 24 04 88 01 00 	movl   $0x188,0x4(%esp)
c01031de:	00 
c01031df:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c01031e6:	e8 fe d1 ff ff       	call   c01003e9 <__panic>
c01031eb:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01031ee:	2d 00 00 00 40       	sub    $0x40000000,%eax
c01031f3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
c01031fa:	00 
c01031fb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0103202:	00 
c0103203:	89 04 24             	mov    %eax,(%esp)
c0103206:	e8 76 24 00 00       	call   c0105681 <memset>
        *entry = page_addr |
                 PTE_P     |
                 PTE_W     |
c010320b:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010320e:	83 c8 07             	or     $0x7,%eax
c0103211:	89 c2                	mov    %eax,%edx
        // Get the physical address for next step.
        // ? uintptr_t seems to be unsigned int...
        uintptr_t page_addr = page2pa(page);
        // Set the page to be empty in the kernel.
        memset(KADDR(page_addr), 0, (PGSIZE));
        *entry = page_addr |
c0103213:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103216:	89 10                	mov    %edx,(%eax)
                 PTE_P     |
                 PTE_W     |
                 PTE_U     ;
    }

    uintptr_t page_table_index = PTX(la);
c0103218:	8b 45 0c             	mov    0xc(%ebp),%eax
c010321b:	c1 e8 0c             	shr    $0xc,%eax
c010321e:	25 ff 03 00 00       	and    $0x3ff,%eax
c0103223:	89 45 e0             	mov    %eax,-0x20(%ebp)
    // Page directory table's entry is just a pointer to the page table itself.
    pte_t *page_table_addr = (pte_t *)KADDR(PDE_ADDR(*entry)); // Provided by the kernel.
c0103226:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103229:	8b 00                	mov    (%eax),%eax
c010322b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103230:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0103233:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0103236:	c1 e8 0c             	shr    $0xc,%eax
c0103239:	89 45 d8             	mov    %eax,-0x28(%ebp)
c010323c:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103241:	39 45 d8             	cmp    %eax,-0x28(%ebp)
c0103244:	72 23                	jb     c0103269 <get_pte+0x132>
c0103246:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0103249:	89 44 24 0c          	mov    %eax,0xc(%esp)
c010324d:	c7 44 24 08 a0 65 10 	movl   $0xc01065a0,0x8(%esp)
c0103254:	c0 
c0103255:	c7 44 24 04 91 01 00 	movl   $0x191,0x4(%esp)
c010325c:	00 
c010325d:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103264:	e8 80 d1 ff ff       	call   c01003e9 <__panic>
c0103269:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010326c:	2d 00 00 00 40       	sub    $0x40000000,%eax
c0103271:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    pte_t *pte = &(*(page_table_addr + page_table_index));
c0103274:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103277:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c010327e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0103281:	01 d0                	add    %edx,%eax
c0103283:	89 45 d0             	mov    %eax,-0x30(%ebp)

    return pte;
c0103286:	8b 45 d0             	mov    -0x30(%ebp),%eax
}
c0103289:	c9                   	leave  
c010328a:	c3                   	ret    

c010328b <get_page>:

//get_page - get related Page struct for linear address la using PDT pgdir
struct Page *
get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
c010328b:	55                   	push   %ebp
c010328c:	89 e5                	mov    %esp,%ebp
c010328e:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
c0103291:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0103298:	00 
c0103299:	8b 45 0c             	mov    0xc(%ebp),%eax
c010329c:	89 44 24 04          	mov    %eax,0x4(%esp)
c01032a0:	8b 45 08             	mov    0x8(%ebp),%eax
c01032a3:	89 04 24             	mov    %eax,(%esp)
c01032a6:	e8 8c fe ff ff       	call   c0103137 <get_pte>
c01032ab:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep_store != NULL) {
c01032ae:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01032b2:	74 08                	je     c01032bc <get_page+0x31>
        *ptep_store = ptep;
c01032b4:	8b 45 10             	mov    0x10(%ebp),%eax
c01032b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01032ba:	89 10                	mov    %edx,(%eax)
    }
    if (ptep != NULL && *ptep & PTE_P) {
c01032bc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01032c0:	74 1b                	je     c01032dd <get_page+0x52>
c01032c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01032c5:	8b 00                	mov    (%eax),%eax
c01032c7:	83 e0 01             	and    $0x1,%eax
c01032ca:	85 c0                	test   %eax,%eax
c01032cc:	74 0f                	je     c01032dd <get_page+0x52>
        return pte2page(*ptep);
c01032ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01032d1:	8b 00                	mov    (%eax),%eax
c01032d3:	89 04 24             	mov    %eax,(%esp)
c01032d6:	e8 57 f5 ff ff       	call   c0102832 <pte2page>
c01032db:	eb 05                	jmp    c01032e2 <get_page+0x57>
    }
    return NULL;
c01032dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01032e2:	c9                   	leave  
c01032e3:	c3                   	ret    

c01032e4 <page_remove_pte>:

//page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
//note: PT is changed, so the TLB need to be invalidate 
static inline void
page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
c01032e4:	55                   	push   %ebp
c01032e5:	89 e5                	mov    %esp,%ebp
c01032e7:	83 ec 28             	sub    $0x28,%esp
                                  //(4) and free this page when page reference reachs 0
                                  //(5) clear second page table entry
                                  //(6) flush tlb
    }
#endif
    if (*ptep & PTE_P) {
c01032ea:	8b 45 10             	mov    0x10(%ebp),%eax
c01032ed:	8b 00                	mov    (%eax),%eax
c01032ef:	83 e0 01             	and    $0x1,%eax
c01032f2:	85 c0                	test   %eax,%eax
c01032f4:	74 4d                	je     c0103343 <page_remove_pte+0x5f>
        struct Page *page = pte2page(*ptep);
c01032f6:	8b 45 10             	mov    0x10(%ebp),%eax
c01032f9:	8b 00                	mov    (%eax),%eax
c01032fb:	89 04 24             	mov    %eax,(%esp)
c01032fe:	e8 2f f5 ff ff       	call   c0102832 <pte2page>
c0103303:	89 45 f4             	mov    %eax,-0xc(%ebp)
        if (page_ref_dec(page) == 0) {
c0103306:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103309:	89 04 24             	mov    %eax,(%esp)
c010330c:	e8 a6 f5 ff ff       	call   c01028b7 <page_ref_dec>
c0103311:	85 c0                	test   %eax,%eax
c0103313:	75 13                	jne    c0103328 <page_remove_pte+0x44>
            free_page(page);
c0103315:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c010331c:	00 
c010331d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103320:	89 04 24             	mov    %eax,(%esp)
c0103323:	e8 9d f7 ff ff       	call   c0102ac5 <free_pages>
        }
        *ptep = 0;
c0103328:	8b 45 10             	mov    0x10(%ebp),%eax
c010332b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        tlb_invalidate(pgdir, la);
c0103331:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103334:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103338:	8b 45 08             	mov    0x8(%ebp),%eax
c010333b:	89 04 24             	mov    %eax,(%esp)
c010333e:	e8 01 01 00 00       	call   c0103444 <tlb_invalidate>
    }
}
c0103343:	90                   	nop
c0103344:	c9                   	leave  
c0103345:	c3                   	ret    

c0103346 <page_remove>:

//page_remove - free an Page which is related linear address la and has an validated pte
void
page_remove(pde_t *pgdir, uintptr_t la) {
c0103346:	55                   	push   %ebp
c0103347:	89 e5                	mov    %esp,%ebp
c0103349:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
c010334c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0103353:	00 
c0103354:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103357:	89 44 24 04          	mov    %eax,0x4(%esp)
c010335b:	8b 45 08             	mov    0x8(%ebp),%eax
c010335e:	89 04 24             	mov    %eax,(%esp)
c0103361:	e8 d1 fd ff ff       	call   c0103137 <get_pte>
c0103366:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep != NULL) {
c0103369:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c010336d:	74 19                	je     c0103388 <page_remove+0x42>
        page_remove_pte(pgdir, la, ptep);
c010336f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103372:	89 44 24 08          	mov    %eax,0x8(%esp)
c0103376:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103379:	89 44 24 04          	mov    %eax,0x4(%esp)
c010337d:	8b 45 08             	mov    0x8(%ebp),%eax
c0103380:	89 04 24             	mov    %eax,(%esp)
c0103383:	e8 5c ff ff ff       	call   c01032e4 <page_remove_pte>
    }
}
c0103388:	90                   	nop
c0103389:	c9                   	leave  
c010338a:	c3                   	ret    

c010338b <page_insert>:
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
//note: PT is changed, so the TLB need to be invalidate 
int
page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
c010338b:	55                   	push   %ebp
c010338c:	89 e5                	mov    %esp,%ebp
c010338e:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 1);
c0103391:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
c0103398:	00 
c0103399:	8b 45 10             	mov    0x10(%ebp),%eax
c010339c:	89 44 24 04          	mov    %eax,0x4(%esp)
c01033a0:	8b 45 08             	mov    0x8(%ebp),%eax
c01033a3:	89 04 24             	mov    %eax,(%esp)
c01033a6:	e8 8c fd ff ff       	call   c0103137 <get_pte>
c01033ab:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep == NULL) {
c01033ae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01033b2:	75 0a                	jne    c01033be <page_insert+0x33>
        return -E_NO_MEM;
c01033b4:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
c01033b9:	e9 84 00 00 00       	jmp    c0103442 <page_insert+0xb7>
    }
    page_ref_inc(page);
c01033be:	8b 45 0c             	mov    0xc(%ebp),%eax
c01033c1:	89 04 24             	mov    %eax,(%esp)
c01033c4:	e8 d7 f4 ff ff       	call   c01028a0 <page_ref_inc>
    if (*ptep & PTE_P) {
c01033c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01033cc:	8b 00                	mov    (%eax),%eax
c01033ce:	83 e0 01             	and    $0x1,%eax
c01033d1:	85 c0                	test   %eax,%eax
c01033d3:	74 3e                	je     c0103413 <page_insert+0x88>
        struct Page *p = pte2page(*ptep);
c01033d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01033d8:	8b 00                	mov    (%eax),%eax
c01033da:	89 04 24             	mov    %eax,(%esp)
c01033dd:	e8 50 f4 ff ff       	call   c0102832 <pte2page>
c01033e2:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (p == page) {
c01033e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01033e8:	3b 45 0c             	cmp    0xc(%ebp),%eax
c01033eb:	75 0d                	jne    c01033fa <page_insert+0x6f>
            page_ref_dec(page);
c01033ed:	8b 45 0c             	mov    0xc(%ebp),%eax
c01033f0:	89 04 24             	mov    %eax,(%esp)
c01033f3:	e8 bf f4 ff ff       	call   c01028b7 <page_ref_dec>
c01033f8:	eb 19                	jmp    c0103413 <page_insert+0x88>
        }
        else {
            page_remove_pte(pgdir, la, ptep);
c01033fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01033fd:	89 44 24 08          	mov    %eax,0x8(%esp)
c0103401:	8b 45 10             	mov    0x10(%ebp),%eax
c0103404:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103408:	8b 45 08             	mov    0x8(%ebp),%eax
c010340b:	89 04 24             	mov    %eax,(%esp)
c010340e:	e8 d1 fe ff ff       	call   c01032e4 <page_remove_pte>
        }
    }
    *ptep = page2pa(page) | PTE_P | perm;
c0103413:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103416:	89 04 24             	mov    %eax,(%esp)
c0103419:	e8 5b f3 ff ff       	call   c0102779 <page2pa>
c010341e:	0b 45 14             	or     0x14(%ebp),%eax
c0103421:	83 c8 01             	or     $0x1,%eax
c0103424:	89 c2                	mov    %eax,%edx
c0103426:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103429:	89 10                	mov    %edx,(%eax)
    tlb_invalidate(pgdir, la);
c010342b:	8b 45 10             	mov    0x10(%ebp),%eax
c010342e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103432:	8b 45 08             	mov    0x8(%ebp),%eax
c0103435:	89 04 24             	mov    %eax,(%esp)
c0103438:	e8 07 00 00 00       	call   c0103444 <tlb_invalidate>
    return 0;
c010343d:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0103442:	c9                   	leave  
c0103443:	c3                   	ret    

c0103444 <tlb_invalidate>:

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void
tlb_invalidate(pde_t *pgdir, uintptr_t la) {
c0103444:	55                   	push   %ebp
c0103445:	89 e5                	mov    %esp,%ebp
c0103447:	83 ec 28             	sub    $0x28,%esp
}

static inline uintptr_t
rcr3(void) {
    uintptr_t cr3;
    asm volatile ("mov %%cr3, %0" : "=r" (cr3) :: "memory");
c010344a:	0f 20 d8             	mov    %cr3,%eax
c010344d:	89 45 ec             	mov    %eax,-0x14(%ebp)
    return cr3;
c0103450:	8b 55 ec             	mov    -0x14(%ebp),%edx
    if (rcr3() == PADDR(pgdir)) {
c0103453:	8b 45 08             	mov    0x8(%ebp),%eax
c0103456:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103459:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
c0103460:	77 23                	ja     c0103485 <tlb_invalidate+0x41>
c0103462:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103465:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0103469:	c7 44 24 08 44 66 10 	movl   $0xc0106644,0x8(%esp)
c0103470:	c0 
c0103471:	c7 44 24 04 f6 01 00 	movl   $0x1f6,0x4(%esp)
c0103478:	00 
c0103479:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103480:	e8 64 cf ff ff       	call   c01003e9 <__panic>
c0103485:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103488:	05 00 00 00 40       	add    $0x40000000,%eax
c010348d:	39 c2                	cmp    %eax,%edx
c010348f:	75 0c                	jne    c010349d <tlb_invalidate+0x59>
        invlpg((void *)la);
c0103491:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103494:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static inline void
invlpg(void *addr) {
    asm volatile ("invlpg (%0)" :: "r" (addr) : "memory");
c0103497:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010349a:	0f 01 38             	invlpg (%eax)
    }
}
c010349d:	90                   	nop
c010349e:	c9                   	leave  
c010349f:	c3                   	ret    

c01034a0 <check_alloc_page>:

static void
check_alloc_page(void) {
c01034a0:	55                   	push   %ebp
c01034a1:	89 e5                	mov    %esp,%ebp
c01034a3:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->check();
c01034a6:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c01034ab:	8b 40 18             	mov    0x18(%eax),%eax
c01034ae:	ff d0                	call   *%eax
    cprintf("check_alloc_page() succeeded!\n");
c01034b0:	c7 04 24 c8 66 10 c0 	movl   $0xc01066c8,(%esp)
c01034b7:	e8 d6 cd ff ff       	call   c0100292 <cprintf>
}
c01034bc:	90                   	nop
c01034bd:	c9                   	leave  
c01034be:	c3                   	ret    

c01034bf <check_pgdir>:

static void
check_pgdir(void) {
c01034bf:	55                   	push   %ebp
c01034c0:	89 e5                	mov    %esp,%ebp
c01034c2:	83 ec 38             	sub    $0x38,%esp
    assert(npage <= KMEMSIZE / PGSIZE);
c01034c5:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01034ca:	3d 00 80 03 00       	cmp    $0x38000,%eax
c01034cf:	76 24                	jbe    c01034f5 <check_pgdir+0x36>
c01034d1:	c7 44 24 0c e7 66 10 	movl   $0xc01066e7,0xc(%esp)
c01034d8:	c0 
c01034d9:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c01034e0:	c0 
c01034e1:	c7 44 24 04 03 02 00 	movl   $0x203,0x4(%esp)
c01034e8:	00 
c01034e9:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c01034f0:	e8 f4 ce ff ff       	call   c01003e9 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
c01034f5:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01034fa:	85 c0                	test   %eax,%eax
c01034fc:	74 0e                	je     c010350c <check_pgdir+0x4d>
c01034fe:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103503:	25 ff 0f 00 00       	and    $0xfff,%eax
c0103508:	85 c0                	test   %eax,%eax
c010350a:	74 24                	je     c0103530 <check_pgdir+0x71>
c010350c:	c7 44 24 0c 04 67 10 	movl   $0xc0106704,0xc(%esp)
c0103513:	c0 
c0103514:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c010351b:	c0 
c010351c:	c7 44 24 04 04 02 00 	movl   $0x204,0x4(%esp)
c0103523:	00 
c0103524:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c010352b:	e8 b9 ce ff ff       	call   c01003e9 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
c0103530:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103535:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c010353c:	00 
c010353d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0103544:	00 
c0103545:	89 04 24             	mov    %eax,(%esp)
c0103548:	e8 3e fd ff ff       	call   c010328b <get_page>
c010354d:	85 c0                	test   %eax,%eax
c010354f:	74 24                	je     c0103575 <check_pgdir+0xb6>
c0103551:	c7 44 24 0c 3c 67 10 	movl   $0xc010673c,0xc(%esp)
c0103558:	c0 
c0103559:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103560:	c0 
c0103561:	c7 44 24 04 05 02 00 	movl   $0x205,0x4(%esp)
c0103568:	00 
c0103569:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103570:	e8 74 ce ff ff       	call   c01003e9 <__panic>

    struct Page *p1, *p2;
    p1 = alloc_page();
c0103575:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010357c:	e8 0c f5 ff ff       	call   c0102a8d <alloc_pages>
c0103581:	89 45 f4             	mov    %eax,-0xc(%ebp)
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
c0103584:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103589:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
c0103590:	00 
c0103591:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0103598:	00 
c0103599:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010359c:	89 54 24 04          	mov    %edx,0x4(%esp)
c01035a0:	89 04 24             	mov    %eax,(%esp)
c01035a3:	e8 e3 fd ff ff       	call   c010338b <page_insert>
c01035a8:	85 c0                	test   %eax,%eax
c01035aa:	74 24                	je     c01035d0 <check_pgdir+0x111>
c01035ac:	c7 44 24 0c 64 67 10 	movl   $0xc0106764,0xc(%esp)
c01035b3:	c0 
c01035b4:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c01035bb:	c0 
c01035bc:	c7 44 24 04 09 02 00 	movl   $0x209,0x4(%esp)
c01035c3:	00 
c01035c4:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c01035cb:	e8 19 ce ff ff       	call   c01003e9 <__panic>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
c01035d0:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01035d5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01035dc:	00 
c01035dd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c01035e4:	00 
c01035e5:	89 04 24             	mov    %eax,(%esp)
c01035e8:	e8 4a fb ff ff       	call   c0103137 <get_pte>
c01035ed:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01035f0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01035f4:	75 24                	jne    c010361a <check_pgdir+0x15b>
c01035f6:	c7 44 24 0c 90 67 10 	movl   $0xc0106790,0xc(%esp)
c01035fd:	c0 
c01035fe:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103605:	c0 
c0103606:	c7 44 24 04 0c 02 00 	movl   $0x20c,0x4(%esp)
c010360d:	00 
c010360e:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103615:	e8 cf cd ff ff       	call   c01003e9 <__panic>
    assert(pte2page(*ptep) == p1);
c010361a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010361d:	8b 00                	mov    (%eax),%eax
c010361f:	89 04 24             	mov    %eax,(%esp)
c0103622:	e8 0b f2 ff ff       	call   c0102832 <pte2page>
c0103627:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010362a:	74 24                	je     c0103650 <check_pgdir+0x191>
c010362c:	c7 44 24 0c bd 67 10 	movl   $0xc01067bd,0xc(%esp)
c0103633:	c0 
c0103634:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c010363b:	c0 
c010363c:	c7 44 24 04 0d 02 00 	movl   $0x20d,0x4(%esp)
c0103643:	00 
c0103644:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c010364b:	e8 99 cd ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p1) == 1);
c0103650:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103653:	89 04 24             	mov    %eax,(%esp)
c0103656:	e8 2d f2 ff ff       	call   c0102888 <page_ref>
c010365b:	83 f8 01             	cmp    $0x1,%eax
c010365e:	74 24                	je     c0103684 <check_pgdir+0x1c5>
c0103660:	c7 44 24 0c d3 67 10 	movl   $0xc01067d3,0xc(%esp)
c0103667:	c0 
c0103668:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c010366f:	c0 
c0103670:	c7 44 24 04 0e 02 00 	movl   $0x20e,0x4(%esp)
c0103677:	00 
c0103678:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c010367f:	e8 65 cd ff ff       	call   c01003e9 <__panic>

    ptep = &((pte_t *)KADDR(PDE_ADDR(boot_pgdir[0])))[1];
c0103684:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103689:	8b 00                	mov    (%eax),%eax
c010368b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103690:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0103693:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103696:	c1 e8 0c             	shr    $0xc,%eax
c0103699:	89 45 e8             	mov    %eax,-0x18(%ebp)
c010369c:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01036a1:	39 45 e8             	cmp    %eax,-0x18(%ebp)
c01036a4:	72 23                	jb     c01036c9 <check_pgdir+0x20a>
c01036a6:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01036a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01036ad:	c7 44 24 08 a0 65 10 	movl   $0xc01065a0,0x8(%esp)
c01036b4:	c0 
c01036b5:	c7 44 24 04 10 02 00 	movl   $0x210,0x4(%esp)
c01036bc:	00 
c01036bd:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c01036c4:	e8 20 cd ff ff       	call   c01003e9 <__panic>
c01036c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01036cc:	2d 00 00 00 40       	sub    $0x40000000,%eax
c01036d1:	83 c0 04             	add    $0x4,%eax
c01036d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
c01036d7:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01036dc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01036e3:	00 
c01036e4:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c01036eb:	00 
c01036ec:	89 04 24             	mov    %eax,(%esp)
c01036ef:	e8 43 fa ff ff       	call   c0103137 <get_pte>
c01036f4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c01036f7:	74 24                	je     c010371d <check_pgdir+0x25e>
c01036f9:	c7 44 24 0c e8 67 10 	movl   $0xc01067e8,0xc(%esp)
c0103700:	c0 
c0103701:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103708:	c0 
c0103709:	c7 44 24 04 11 02 00 	movl   $0x211,0x4(%esp)
c0103710:	00 
c0103711:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103718:	e8 cc cc ff ff       	call   c01003e9 <__panic>

    p2 = alloc_page();
c010371d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0103724:	e8 64 f3 ff ff       	call   c0102a8d <alloc_pages>
c0103729:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
c010372c:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103731:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
c0103738:	00 
c0103739:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
c0103740:	00 
c0103741:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0103744:	89 54 24 04          	mov    %edx,0x4(%esp)
c0103748:	89 04 24             	mov    %eax,(%esp)
c010374b:	e8 3b fc ff ff       	call   c010338b <page_insert>
c0103750:	85 c0                	test   %eax,%eax
c0103752:	74 24                	je     c0103778 <check_pgdir+0x2b9>
c0103754:	c7 44 24 0c 10 68 10 	movl   $0xc0106810,0xc(%esp)
c010375b:	c0 
c010375c:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103763:	c0 
c0103764:	c7 44 24 04 14 02 00 	movl   $0x214,0x4(%esp)
c010376b:	00 
c010376c:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103773:	e8 71 cc ff ff       	call   c01003e9 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
c0103778:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010377d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0103784:	00 
c0103785:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c010378c:	00 
c010378d:	89 04 24             	mov    %eax,(%esp)
c0103790:	e8 a2 f9 ff ff       	call   c0103137 <get_pte>
c0103795:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103798:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010379c:	75 24                	jne    c01037c2 <check_pgdir+0x303>
c010379e:	c7 44 24 0c 48 68 10 	movl   $0xc0106848,0xc(%esp)
c01037a5:	c0 
c01037a6:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c01037ad:	c0 
c01037ae:	c7 44 24 04 15 02 00 	movl   $0x215,0x4(%esp)
c01037b5:	00 
c01037b6:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c01037bd:	e8 27 cc ff ff       	call   c01003e9 <__panic>
    assert(*ptep & PTE_U);
c01037c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01037c5:	8b 00                	mov    (%eax),%eax
c01037c7:	83 e0 04             	and    $0x4,%eax
c01037ca:	85 c0                	test   %eax,%eax
c01037cc:	75 24                	jne    c01037f2 <check_pgdir+0x333>
c01037ce:	c7 44 24 0c 78 68 10 	movl   $0xc0106878,0xc(%esp)
c01037d5:	c0 
c01037d6:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c01037dd:	c0 
c01037de:	c7 44 24 04 16 02 00 	movl   $0x216,0x4(%esp)
c01037e5:	00 
c01037e6:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c01037ed:	e8 f7 cb ff ff       	call   c01003e9 <__panic>
    assert(*ptep & PTE_W);
c01037f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01037f5:	8b 00                	mov    (%eax),%eax
c01037f7:	83 e0 02             	and    $0x2,%eax
c01037fa:	85 c0                	test   %eax,%eax
c01037fc:	75 24                	jne    c0103822 <check_pgdir+0x363>
c01037fe:	c7 44 24 0c 86 68 10 	movl   $0xc0106886,0xc(%esp)
c0103805:	c0 
c0103806:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c010380d:	c0 
c010380e:	c7 44 24 04 17 02 00 	movl   $0x217,0x4(%esp)
c0103815:	00 
c0103816:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c010381d:	e8 c7 cb ff ff       	call   c01003e9 <__panic>
    assert(boot_pgdir[0] & PTE_U);
c0103822:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103827:	8b 00                	mov    (%eax),%eax
c0103829:	83 e0 04             	and    $0x4,%eax
c010382c:	85 c0                	test   %eax,%eax
c010382e:	75 24                	jne    c0103854 <check_pgdir+0x395>
c0103830:	c7 44 24 0c 94 68 10 	movl   $0xc0106894,0xc(%esp)
c0103837:	c0 
c0103838:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c010383f:	c0 
c0103840:	c7 44 24 04 18 02 00 	movl   $0x218,0x4(%esp)
c0103847:	00 
c0103848:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c010384f:	e8 95 cb ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p2) == 1);
c0103854:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103857:	89 04 24             	mov    %eax,(%esp)
c010385a:	e8 29 f0 ff ff       	call   c0102888 <page_ref>
c010385f:	83 f8 01             	cmp    $0x1,%eax
c0103862:	74 24                	je     c0103888 <check_pgdir+0x3c9>
c0103864:	c7 44 24 0c aa 68 10 	movl   $0xc01068aa,0xc(%esp)
c010386b:	c0 
c010386c:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103873:	c0 
c0103874:	c7 44 24 04 19 02 00 	movl   $0x219,0x4(%esp)
c010387b:	00 
c010387c:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103883:	e8 61 cb ff ff       	call   c01003e9 <__panic>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
c0103888:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010388d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
c0103894:	00 
c0103895:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
c010389c:	00 
c010389d:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01038a0:	89 54 24 04          	mov    %edx,0x4(%esp)
c01038a4:	89 04 24             	mov    %eax,(%esp)
c01038a7:	e8 df fa ff ff       	call   c010338b <page_insert>
c01038ac:	85 c0                	test   %eax,%eax
c01038ae:	74 24                	je     c01038d4 <check_pgdir+0x415>
c01038b0:	c7 44 24 0c bc 68 10 	movl   $0xc01068bc,0xc(%esp)
c01038b7:	c0 
c01038b8:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c01038bf:	c0 
c01038c0:	c7 44 24 04 1b 02 00 	movl   $0x21b,0x4(%esp)
c01038c7:	00 
c01038c8:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c01038cf:	e8 15 cb ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p1) == 2);
c01038d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01038d7:	89 04 24             	mov    %eax,(%esp)
c01038da:	e8 a9 ef ff ff       	call   c0102888 <page_ref>
c01038df:	83 f8 02             	cmp    $0x2,%eax
c01038e2:	74 24                	je     c0103908 <check_pgdir+0x449>
c01038e4:	c7 44 24 0c e8 68 10 	movl   $0xc01068e8,0xc(%esp)
c01038eb:	c0 
c01038ec:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c01038f3:	c0 
c01038f4:	c7 44 24 04 1c 02 00 	movl   $0x21c,0x4(%esp)
c01038fb:	00 
c01038fc:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103903:	e8 e1 ca ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p2) == 0);
c0103908:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010390b:	89 04 24             	mov    %eax,(%esp)
c010390e:	e8 75 ef ff ff       	call   c0102888 <page_ref>
c0103913:	85 c0                	test   %eax,%eax
c0103915:	74 24                	je     c010393b <check_pgdir+0x47c>
c0103917:	c7 44 24 0c fa 68 10 	movl   $0xc01068fa,0xc(%esp)
c010391e:	c0 
c010391f:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103926:	c0 
c0103927:	c7 44 24 04 1d 02 00 	movl   $0x21d,0x4(%esp)
c010392e:	00 
c010392f:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103936:	e8 ae ca ff ff       	call   c01003e9 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
c010393b:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103940:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0103947:	00 
c0103948:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c010394f:	00 
c0103950:	89 04 24             	mov    %eax,(%esp)
c0103953:	e8 df f7 ff ff       	call   c0103137 <get_pte>
c0103958:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010395b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010395f:	75 24                	jne    c0103985 <check_pgdir+0x4c6>
c0103961:	c7 44 24 0c 48 68 10 	movl   $0xc0106848,0xc(%esp)
c0103968:	c0 
c0103969:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103970:	c0 
c0103971:	c7 44 24 04 1e 02 00 	movl   $0x21e,0x4(%esp)
c0103978:	00 
c0103979:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103980:	e8 64 ca ff ff       	call   c01003e9 <__panic>
    assert(pte2page(*ptep) == p1);
c0103985:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103988:	8b 00                	mov    (%eax),%eax
c010398a:	89 04 24             	mov    %eax,(%esp)
c010398d:	e8 a0 ee ff ff       	call   c0102832 <pte2page>
c0103992:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0103995:	74 24                	je     c01039bb <check_pgdir+0x4fc>
c0103997:	c7 44 24 0c bd 67 10 	movl   $0xc01067bd,0xc(%esp)
c010399e:	c0 
c010399f:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c01039a6:	c0 
c01039a7:	c7 44 24 04 1f 02 00 	movl   $0x21f,0x4(%esp)
c01039ae:	00 
c01039af:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c01039b6:	e8 2e ca ff ff       	call   c01003e9 <__panic>
    assert((*ptep & PTE_U) == 0);
c01039bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01039be:	8b 00                	mov    (%eax),%eax
c01039c0:	83 e0 04             	and    $0x4,%eax
c01039c3:	85 c0                	test   %eax,%eax
c01039c5:	74 24                	je     c01039eb <check_pgdir+0x52c>
c01039c7:	c7 44 24 0c 0c 69 10 	movl   $0xc010690c,0xc(%esp)
c01039ce:	c0 
c01039cf:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c01039d6:	c0 
c01039d7:	c7 44 24 04 20 02 00 	movl   $0x220,0x4(%esp)
c01039de:	00 
c01039df:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c01039e6:	e8 fe c9 ff ff       	call   c01003e9 <__panic>

    page_remove(boot_pgdir, 0x0);
c01039eb:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01039f0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c01039f7:	00 
c01039f8:	89 04 24             	mov    %eax,(%esp)
c01039fb:	e8 46 f9 ff ff       	call   c0103346 <page_remove>
    assert(page_ref(p1) == 1);
c0103a00:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103a03:	89 04 24             	mov    %eax,(%esp)
c0103a06:	e8 7d ee ff ff       	call   c0102888 <page_ref>
c0103a0b:	83 f8 01             	cmp    $0x1,%eax
c0103a0e:	74 24                	je     c0103a34 <check_pgdir+0x575>
c0103a10:	c7 44 24 0c d3 67 10 	movl   $0xc01067d3,0xc(%esp)
c0103a17:	c0 
c0103a18:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103a1f:	c0 
c0103a20:	c7 44 24 04 23 02 00 	movl   $0x223,0x4(%esp)
c0103a27:	00 
c0103a28:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103a2f:	e8 b5 c9 ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p2) == 0);
c0103a34:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103a37:	89 04 24             	mov    %eax,(%esp)
c0103a3a:	e8 49 ee ff ff       	call   c0102888 <page_ref>
c0103a3f:	85 c0                	test   %eax,%eax
c0103a41:	74 24                	je     c0103a67 <check_pgdir+0x5a8>
c0103a43:	c7 44 24 0c fa 68 10 	movl   $0xc01068fa,0xc(%esp)
c0103a4a:	c0 
c0103a4b:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103a52:	c0 
c0103a53:	c7 44 24 04 24 02 00 	movl   $0x224,0x4(%esp)
c0103a5a:	00 
c0103a5b:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103a62:	e8 82 c9 ff ff       	call   c01003e9 <__panic>

    page_remove(boot_pgdir, PGSIZE);
c0103a67:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103a6c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c0103a73:	00 
c0103a74:	89 04 24             	mov    %eax,(%esp)
c0103a77:	e8 ca f8 ff ff       	call   c0103346 <page_remove>
    assert(page_ref(p1) == 0);
c0103a7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103a7f:	89 04 24             	mov    %eax,(%esp)
c0103a82:	e8 01 ee ff ff       	call   c0102888 <page_ref>
c0103a87:	85 c0                	test   %eax,%eax
c0103a89:	74 24                	je     c0103aaf <check_pgdir+0x5f0>
c0103a8b:	c7 44 24 0c 21 69 10 	movl   $0xc0106921,0xc(%esp)
c0103a92:	c0 
c0103a93:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103a9a:	c0 
c0103a9b:	c7 44 24 04 27 02 00 	movl   $0x227,0x4(%esp)
c0103aa2:	00 
c0103aa3:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103aaa:	e8 3a c9 ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p2) == 0);
c0103aaf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103ab2:	89 04 24             	mov    %eax,(%esp)
c0103ab5:	e8 ce ed ff ff       	call   c0102888 <page_ref>
c0103aba:	85 c0                	test   %eax,%eax
c0103abc:	74 24                	je     c0103ae2 <check_pgdir+0x623>
c0103abe:	c7 44 24 0c fa 68 10 	movl   $0xc01068fa,0xc(%esp)
c0103ac5:	c0 
c0103ac6:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103acd:	c0 
c0103ace:	c7 44 24 04 28 02 00 	movl   $0x228,0x4(%esp)
c0103ad5:	00 
c0103ad6:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103add:	e8 07 c9 ff ff       	call   c01003e9 <__panic>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
c0103ae2:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103ae7:	8b 00                	mov    (%eax),%eax
c0103ae9:	89 04 24             	mov    %eax,(%esp)
c0103aec:	e8 7f ed ff ff       	call   c0102870 <pde2page>
c0103af1:	89 04 24             	mov    %eax,(%esp)
c0103af4:	e8 8f ed ff ff       	call   c0102888 <page_ref>
c0103af9:	83 f8 01             	cmp    $0x1,%eax
c0103afc:	74 24                	je     c0103b22 <check_pgdir+0x663>
c0103afe:	c7 44 24 0c 34 69 10 	movl   $0xc0106934,0xc(%esp)
c0103b05:	c0 
c0103b06:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103b0d:	c0 
c0103b0e:	c7 44 24 04 2a 02 00 	movl   $0x22a,0x4(%esp)
c0103b15:	00 
c0103b16:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103b1d:	e8 c7 c8 ff ff       	call   c01003e9 <__panic>
    free_page(pde2page(boot_pgdir[0]));
c0103b22:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103b27:	8b 00                	mov    (%eax),%eax
c0103b29:	89 04 24             	mov    %eax,(%esp)
c0103b2c:	e8 3f ed ff ff       	call   c0102870 <pde2page>
c0103b31:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0103b38:	00 
c0103b39:	89 04 24             	mov    %eax,(%esp)
c0103b3c:	e8 84 ef ff ff       	call   c0102ac5 <free_pages>
    boot_pgdir[0] = 0;
c0103b41:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103b46:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_pgdir() succeeded!\n");
c0103b4c:	c7 04 24 5b 69 10 c0 	movl   $0xc010695b,(%esp)
c0103b53:	e8 3a c7 ff ff       	call   c0100292 <cprintf>
}
c0103b58:	90                   	nop
c0103b59:	c9                   	leave  
c0103b5a:	c3                   	ret    

c0103b5b <check_boot_pgdir>:

static void
check_boot_pgdir(void) {
c0103b5b:	55                   	push   %ebp
c0103b5c:	89 e5                	mov    %esp,%ebp
c0103b5e:	83 ec 38             	sub    $0x38,%esp
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
c0103b61:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0103b68:	e9 ca 00 00 00       	jmp    c0103c37 <check_boot_pgdir+0xdc>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
c0103b6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103b70:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103b73:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103b76:	c1 e8 0c             	shr    $0xc,%eax
c0103b79:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0103b7c:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103b81:	39 45 ec             	cmp    %eax,-0x14(%ebp)
c0103b84:	72 23                	jb     c0103ba9 <check_boot_pgdir+0x4e>
c0103b86:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103b89:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0103b8d:	c7 44 24 08 a0 65 10 	movl   $0xc01065a0,0x8(%esp)
c0103b94:	c0 
c0103b95:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
c0103b9c:	00 
c0103b9d:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103ba4:	e8 40 c8 ff ff       	call   c01003e9 <__panic>
c0103ba9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103bac:	2d 00 00 00 40       	sub    $0x40000000,%eax
c0103bb1:	89 c2                	mov    %eax,%edx
c0103bb3:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103bb8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0103bbf:	00 
c0103bc0:	89 54 24 04          	mov    %edx,0x4(%esp)
c0103bc4:	89 04 24             	mov    %eax,(%esp)
c0103bc7:	e8 6b f5 ff ff       	call   c0103137 <get_pte>
c0103bcc:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0103bcf:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0103bd3:	75 24                	jne    c0103bf9 <check_boot_pgdir+0x9e>
c0103bd5:	c7 44 24 0c 78 69 10 	movl   $0xc0106978,0xc(%esp)
c0103bdc:	c0 
c0103bdd:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103be4:	c0 
c0103be5:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
c0103bec:	00 
c0103bed:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103bf4:	e8 f0 c7 ff ff       	call   c01003e9 <__panic>
        assert(PTE_ADDR(*ptep) == i);
c0103bf9:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103bfc:	8b 00                	mov    (%eax),%eax
c0103bfe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103c03:	89 c2                	mov    %eax,%edx
c0103c05:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103c08:	39 c2                	cmp    %eax,%edx
c0103c0a:	74 24                	je     c0103c30 <check_boot_pgdir+0xd5>
c0103c0c:	c7 44 24 0c b5 69 10 	movl   $0xc01069b5,0xc(%esp)
c0103c13:	c0 
c0103c14:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103c1b:	c0 
c0103c1c:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
c0103c23:	00 
c0103c24:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103c2b:	e8 b9 c7 ff ff       	call   c01003e9 <__panic>

static void
check_boot_pgdir(void) {
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
c0103c30:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
c0103c37:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0103c3a:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103c3f:	39 c2                	cmp    %eax,%edx
c0103c41:	0f 82 26 ff ff ff    	jb     c0103b6d <check_boot_pgdir+0x12>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }

    assert(PDE_ADDR(boot_pgdir[PDX(VPT)]) == PADDR(boot_pgdir));
c0103c47:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103c4c:	05 ac 0f 00 00       	add    $0xfac,%eax
c0103c51:	8b 00                	mov    (%eax),%eax
c0103c53:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103c58:	89 c2                	mov    %eax,%edx
c0103c5a:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103c5f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103c62:	81 7d e4 ff ff ff bf 	cmpl   $0xbfffffff,-0x1c(%ebp)
c0103c69:	77 23                	ja     c0103c8e <check_boot_pgdir+0x133>
c0103c6b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103c6e:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0103c72:	c7 44 24 08 44 66 10 	movl   $0xc0106644,0x8(%esp)
c0103c79:	c0 
c0103c7a:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
c0103c81:	00 
c0103c82:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103c89:	e8 5b c7 ff ff       	call   c01003e9 <__panic>
c0103c8e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103c91:	05 00 00 00 40       	add    $0x40000000,%eax
c0103c96:	39 c2                	cmp    %eax,%edx
c0103c98:	74 24                	je     c0103cbe <check_boot_pgdir+0x163>
c0103c9a:	c7 44 24 0c cc 69 10 	movl   $0xc01069cc,0xc(%esp)
c0103ca1:	c0 
c0103ca2:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103ca9:	c0 
c0103caa:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
c0103cb1:	00 
c0103cb2:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103cb9:	e8 2b c7 ff ff       	call   c01003e9 <__panic>

    assert(boot_pgdir[0] == 0);
c0103cbe:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103cc3:	8b 00                	mov    (%eax),%eax
c0103cc5:	85 c0                	test   %eax,%eax
c0103cc7:	74 24                	je     c0103ced <check_boot_pgdir+0x192>
c0103cc9:	c7 44 24 0c 00 6a 10 	movl   $0xc0106a00,0xc(%esp)
c0103cd0:	c0 
c0103cd1:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103cd8:	c0 
c0103cd9:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
c0103ce0:	00 
c0103ce1:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103ce8:	e8 fc c6 ff ff       	call   c01003e9 <__panic>

    struct Page *p;
    p = alloc_page();
c0103ced:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0103cf4:	e8 94 ed ff ff       	call   c0102a8d <alloc_pages>
c0103cf9:	89 45 e0             	mov    %eax,-0x20(%ebp)
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W) == 0);
c0103cfc:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103d01:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
c0103d08:	00 
c0103d09:	c7 44 24 08 00 01 00 	movl   $0x100,0x8(%esp)
c0103d10:	00 
c0103d11:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0103d14:	89 54 24 04          	mov    %edx,0x4(%esp)
c0103d18:	89 04 24             	mov    %eax,(%esp)
c0103d1b:	e8 6b f6 ff ff       	call   c010338b <page_insert>
c0103d20:	85 c0                	test   %eax,%eax
c0103d22:	74 24                	je     c0103d48 <check_boot_pgdir+0x1ed>
c0103d24:	c7 44 24 0c 14 6a 10 	movl   $0xc0106a14,0xc(%esp)
c0103d2b:	c0 
c0103d2c:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103d33:	c0 
c0103d34:	c7 44 24 04 40 02 00 	movl   $0x240,0x4(%esp)
c0103d3b:	00 
c0103d3c:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103d43:	e8 a1 c6 ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p) == 1);
c0103d48:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103d4b:	89 04 24             	mov    %eax,(%esp)
c0103d4e:	e8 35 eb ff ff       	call   c0102888 <page_ref>
c0103d53:	83 f8 01             	cmp    $0x1,%eax
c0103d56:	74 24                	je     c0103d7c <check_boot_pgdir+0x221>
c0103d58:	c7 44 24 0c 42 6a 10 	movl   $0xc0106a42,0xc(%esp)
c0103d5f:	c0 
c0103d60:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103d67:	c0 
c0103d68:	c7 44 24 04 41 02 00 	movl   $0x241,0x4(%esp)
c0103d6f:	00 
c0103d70:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103d77:	e8 6d c6 ff ff       	call   c01003e9 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W) == 0);
c0103d7c:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103d81:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
c0103d88:	00 
c0103d89:	c7 44 24 08 00 11 00 	movl   $0x1100,0x8(%esp)
c0103d90:	00 
c0103d91:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0103d94:	89 54 24 04          	mov    %edx,0x4(%esp)
c0103d98:	89 04 24             	mov    %eax,(%esp)
c0103d9b:	e8 eb f5 ff ff       	call   c010338b <page_insert>
c0103da0:	85 c0                	test   %eax,%eax
c0103da2:	74 24                	je     c0103dc8 <check_boot_pgdir+0x26d>
c0103da4:	c7 44 24 0c 54 6a 10 	movl   $0xc0106a54,0xc(%esp)
c0103dab:	c0 
c0103dac:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103db3:	c0 
c0103db4:	c7 44 24 04 42 02 00 	movl   $0x242,0x4(%esp)
c0103dbb:	00 
c0103dbc:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103dc3:	e8 21 c6 ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p) == 2);
c0103dc8:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103dcb:	89 04 24             	mov    %eax,(%esp)
c0103dce:	e8 b5 ea ff ff       	call   c0102888 <page_ref>
c0103dd3:	83 f8 02             	cmp    $0x2,%eax
c0103dd6:	74 24                	je     c0103dfc <check_boot_pgdir+0x2a1>
c0103dd8:	c7 44 24 0c 8b 6a 10 	movl   $0xc0106a8b,0xc(%esp)
c0103ddf:	c0 
c0103de0:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103de7:	c0 
c0103de8:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
c0103def:	00 
c0103df0:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103df7:	e8 ed c5 ff ff       	call   c01003e9 <__panic>

    const char *str = "ucore: Hello world!!";
c0103dfc:	c7 45 dc 9c 6a 10 c0 	movl   $0xc0106a9c,-0x24(%ebp)
    strcpy((void *)0x100, str);
c0103e03:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0103e06:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103e0a:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
c0103e11:	e8 a1 15 00 00       	call   c01053b7 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
c0103e16:	c7 44 24 04 00 11 00 	movl   $0x1100,0x4(%esp)
c0103e1d:	00 
c0103e1e:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
c0103e25:	e8 04 16 00 00       	call   c010542e <strcmp>
c0103e2a:	85 c0                	test   %eax,%eax
c0103e2c:	74 24                	je     c0103e52 <check_boot_pgdir+0x2f7>
c0103e2e:	c7 44 24 0c b4 6a 10 	movl   $0xc0106ab4,0xc(%esp)
c0103e35:	c0 
c0103e36:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103e3d:	c0 
c0103e3e:	c7 44 24 04 47 02 00 	movl   $0x247,0x4(%esp)
c0103e45:	00 
c0103e46:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103e4d:	e8 97 c5 ff ff       	call   c01003e9 <__panic>

    *(char *)(page2kva(p) + 0x100) = '\0';
c0103e52:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103e55:	89 04 24             	mov    %eax,(%esp)
c0103e58:	e8 81 e9 ff ff       	call   c01027de <page2kva>
c0103e5d:	05 00 01 00 00       	add    $0x100,%eax
c0103e62:	c6 00 00             	movb   $0x0,(%eax)
    assert(strlen((const char *)0x100) == 0);
c0103e65:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
c0103e6c:	e8 f0 14 00 00       	call   c0105361 <strlen>
c0103e71:	85 c0                	test   %eax,%eax
c0103e73:	74 24                	je     c0103e99 <check_boot_pgdir+0x33e>
c0103e75:	c7 44 24 0c ec 6a 10 	movl   $0xc0106aec,0xc(%esp)
c0103e7c:	c0 
c0103e7d:	c7 44 24 08 8d 66 10 	movl   $0xc010668d,0x8(%esp)
c0103e84:	c0 
c0103e85:	c7 44 24 04 4a 02 00 	movl   $0x24a,0x4(%esp)
c0103e8c:	00 
c0103e8d:	c7 04 24 68 66 10 c0 	movl   $0xc0106668,(%esp)
c0103e94:	e8 50 c5 ff ff       	call   c01003e9 <__panic>

    free_page(p);
c0103e99:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0103ea0:	00 
c0103ea1:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103ea4:	89 04 24             	mov    %eax,(%esp)
c0103ea7:	e8 19 ec ff ff       	call   c0102ac5 <free_pages>
    free_page(pde2page(boot_pgdir[0]));
c0103eac:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103eb1:	8b 00                	mov    (%eax),%eax
c0103eb3:	89 04 24             	mov    %eax,(%esp)
c0103eb6:	e8 b5 e9 ff ff       	call   c0102870 <pde2page>
c0103ebb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0103ec2:	00 
c0103ec3:	89 04 24             	mov    %eax,(%esp)
c0103ec6:	e8 fa eb ff ff       	call   c0102ac5 <free_pages>
    boot_pgdir[0] = 0;
c0103ecb:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103ed0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_boot_pgdir() succeeded!\n");
c0103ed6:	c7 04 24 10 6b 10 c0 	movl   $0xc0106b10,(%esp)
c0103edd:	e8 b0 c3 ff ff       	call   c0100292 <cprintf>
}
c0103ee2:	90                   	nop
c0103ee3:	c9                   	leave  
c0103ee4:	c3                   	ret    

c0103ee5 <perm2str>:

//perm2str - use string 'u,r,w,-' to present the permission
static const char *
perm2str(int perm) {
c0103ee5:	55                   	push   %ebp
c0103ee6:	89 e5                	mov    %esp,%ebp
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
c0103ee8:	8b 45 08             	mov    0x8(%ebp),%eax
c0103eeb:	83 e0 04             	and    $0x4,%eax
c0103eee:	85 c0                	test   %eax,%eax
c0103ef0:	74 04                	je     c0103ef6 <perm2str+0x11>
c0103ef2:	b0 75                	mov    $0x75,%al
c0103ef4:	eb 02                	jmp    c0103ef8 <perm2str+0x13>
c0103ef6:	b0 2d                	mov    $0x2d,%al
c0103ef8:	a2 08 af 11 c0       	mov    %al,0xc011af08
    str[1] = 'r';
c0103efd:	c6 05 09 af 11 c0 72 	movb   $0x72,0xc011af09
    str[2] = (perm & PTE_W) ? 'w' : '-';
c0103f04:	8b 45 08             	mov    0x8(%ebp),%eax
c0103f07:	83 e0 02             	and    $0x2,%eax
c0103f0a:	85 c0                	test   %eax,%eax
c0103f0c:	74 04                	je     c0103f12 <perm2str+0x2d>
c0103f0e:	b0 77                	mov    $0x77,%al
c0103f10:	eb 02                	jmp    c0103f14 <perm2str+0x2f>
c0103f12:	b0 2d                	mov    $0x2d,%al
c0103f14:	a2 0a af 11 c0       	mov    %al,0xc011af0a
    str[3] = '\0';
c0103f19:	c6 05 0b af 11 c0 00 	movb   $0x0,0xc011af0b
    return str;
c0103f20:	b8 08 af 11 c0       	mov    $0xc011af08,%eax
}
c0103f25:	5d                   	pop    %ebp
c0103f26:	c3                   	ret    

c0103f27 <get_pgtable_items>:
//  table:       the beginning addr of table
//  left_store:  the pointer of the high side of table's next range
//  right_store: the pointer of the low side of table's next range
// return value: 0 - not a invalid item range, perm - a valid item range with perm permission 
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
c0103f27:	55                   	push   %ebp
c0103f28:	89 e5                	mov    %esp,%ebp
c0103f2a:	83 ec 10             	sub    $0x10,%esp
    if (start >= right) {
c0103f2d:	8b 45 10             	mov    0x10(%ebp),%eax
c0103f30:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103f33:	72 0d                	jb     c0103f42 <get_pgtable_items+0x1b>
        return 0;
c0103f35:	b8 00 00 00 00       	mov    $0x0,%eax
c0103f3a:	e9 98 00 00 00       	jmp    c0103fd7 <get_pgtable_items+0xb0>
    }
    while (start < right && !(table[start] & PTE_P)) {
        start ++;
c0103f3f:	ff 45 10             	incl   0x10(%ebp)
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
    if (start >= right) {
        return 0;
    }
    while (start < right && !(table[start] & PTE_P)) {
c0103f42:	8b 45 10             	mov    0x10(%ebp),%eax
c0103f45:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103f48:	73 18                	jae    c0103f62 <get_pgtable_items+0x3b>
c0103f4a:	8b 45 10             	mov    0x10(%ebp),%eax
c0103f4d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103f54:	8b 45 14             	mov    0x14(%ebp),%eax
c0103f57:	01 d0                	add    %edx,%eax
c0103f59:	8b 00                	mov    (%eax),%eax
c0103f5b:	83 e0 01             	and    $0x1,%eax
c0103f5e:	85 c0                	test   %eax,%eax
c0103f60:	74 dd                	je     c0103f3f <get_pgtable_items+0x18>
        start ++;
    }
    if (start < right) {
c0103f62:	8b 45 10             	mov    0x10(%ebp),%eax
c0103f65:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103f68:	73 68                	jae    c0103fd2 <get_pgtable_items+0xab>
        if (left_store != NULL) {
c0103f6a:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
c0103f6e:	74 08                	je     c0103f78 <get_pgtable_items+0x51>
            *left_store = start;
c0103f70:	8b 45 18             	mov    0x18(%ebp),%eax
c0103f73:	8b 55 10             	mov    0x10(%ebp),%edx
c0103f76:	89 10                	mov    %edx,(%eax)
        }
        int perm = (table[start ++] & PTE_USER);
c0103f78:	8b 45 10             	mov    0x10(%ebp),%eax
c0103f7b:	8d 50 01             	lea    0x1(%eax),%edx
c0103f7e:	89 55 10             	mov    %edx,0x10(%ebp)
c0103f81:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103f88:	8b 45 14             	mov    0x14(%ebp),%eax
c0103f8b:	01 d0                	add    %edx,%eax
c0103f8d:	8b 00                	mov    (%eax),%eax
c0103f8f:	83 e0 07             	and    $0x7,%eax
c0103f92:	89 45 fc             	mov    %eax,-0x4(%ebp)
        while (start < right && (table[start] & PTE_USER) == perm) {
c0103f95:	eb 03                	jmp    c0103f9a <get_pgtable_items+0x73>
            start ++;
c0103f97:	ff 45 10             	incl   0x10(%ebp)
    if (start < right) {
        if (left_store != NULL) {
            *left_store = start;
        }
        int perm = (table[start ++] & PTE_USER);
        while (start < right && (table[start] & PTE_USER) == perm) {
c0103f9a:	8b 45 10             	mov    0x10(%ebp),%eax
c0103f9d:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103fa0:	73 1d                	jae    c0103fbf <get_pgtable_items+0x98>
c0103fa2:	8b 45 10             	mov    0x10(%ebp),%eax
c0103fa5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103fac:	8b 45 14             	mov    0x14(%ebp),%eax
c0103faf:	01 d0                	add    %edx,%eax
c0103fb1:	8b 00                	mov    (%eax),%eax
c0103fb3:	83 e0 07             	and    $0x7,%eax
c0103fb6:	89 c2                	mov    %eax,%edx
c0103fb8:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103fbb:	39 c2                	cmp    %eax,%edx
c0103fbd:	74 d8                	je     c0103f97 <get_pgtable_items+0x70>
            start ++;
        }
        if (right_store != NULL) {
c0103fbf:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
c0103fc3:	74 08                	je     c0103fcd <get_pgtable_items+0xa6>
            *right_store = start;
c0103fc5:	8b 45 1c             	mov    0x1c(%ebp),%eax
c0103fc8:	8b 55 10             	mov    0x10(%ebp),%edx
c0103fcb:	89 10                	mov    %edx,(%eax)
        }
        return perm;
c0103fcd:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103fd0:	eb 05                	jmp    c0103fd7 <get_pgtable_items+0xb0>
    }
    return 0;
c0103fd2:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0103fd7:	c9                   	leave  
c0103fd8:	c3                   	ret    

c0103fd9 <print_pgdir>:

//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
c0103fd9:	55                   	push   %ebp
c0103fda:	89 e5                	mov    %esp,%ebp
c0103fdc:	57                   	push   %edi
c0103fdd:	56                   	push   %esi
c0103fde:	53                   	push   %ebx
c0103fdf:	83 ec 4c             	sub    $0x4c,%esp
    cprintf("-------------------- BEGIN --------------------\n");
c0103fe2:	c7 04 24 30 6b 10 c0 	movl   $0xc0106b30,(%esp)
c0103fe9:	e8 a4 c2 ff ff       	call   c0100292 <cprintf>
    size_t left, right = 0, perm;
c0103fee:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
c0103ff5:	e9 fa 00 00 00       	jmp    c01040f4 <print_pgdir+0x11b>
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
c0103ffa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103ffd:	89 04 24             	mov    %eax,(%esp)
c0104000:	e8 e0 fe ff ff       	call   c0103ee5 <perm2str>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
c0104005:	8b 4d dc             	mov    -0x24(%ebp),%ecx
c0104008:	8b 55 e0             	mov    -0x20(%ebp),%edx
c010400b:	29 d1                	sub    %edx,%ecx
c010400d:	89 ca                	mov    %ecx,%edx
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
c010400f:	89 d6                	mov    %edx,%esi
c0104011:	c1 e6 16             	shl    $0x16,%esi
c0104014:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0104017:	89 d3                	mov    %edx,%ebx
c0104019:	c1 e3 16             	shl    $0x16,%ebx
c010401c:	8b 55 e0             	mov    -0x20(%ebp),%edx
c010401f:	89 d1                	mov    %edx,%ecx
c0104021:	c1 e1 16             	shl    $0x16,%ecx
c0104024:	8b 7d dc             	mov    -0x24(%ebp),%edi
c0104027:	8b 55 e0             	mov    -0x20(%ebp),%edx
c010402a:	29 d7                	sub    %edx,%edi
c010402c:	89 fa                	mov    %edi,%edx
c010402e:	89 44 24 14          	mov    %eax,0x14(%esp)
c0104032:	89 74 24 10          	mov    %esi,0x10(%esp)
c0104036:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
c010403a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c010403e:	89 54 24 04          	mov    %edx,0x4(%esp)
c0104042:	c7 04 24 61 6b 10 c0 	movl   $0xc0106b61,(%esp)
c0104049:	e8 44 c2 ff ff       	call   c0100292 <cprintf>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
c010404e:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0104051:	c1 e0 0a             	shl    $0xa,%eax
c0104054:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
c0104057:	eb 54                	jmp    c01040ad <print_pgdir+0xd4>
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
c0104059:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010405c:	89 04 24             	mov    %eax,(%esp)
c010405f:	e8 81 fe ff ff       	call   c0103ee5 <perm2str>
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
c0104064:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
c0104067:	8b 55 d8             	mov    -0x28(%ebp),%edx
c010406a:	29 d1                	sub    %edx,%ecx
c010406c:	89 ca                	mov    %ecx,%edx
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
c010406e:	89 d6                	mov    %edx,%esi
c0104070:	c1 e6 0c             	shl    $0xc,%esi
c0104073:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104076:	89 d3                	mov    %edx,%ebx
c0104078:	c1 e3 0c             	shl    $0xc,%ebx
c010407b:	8b 55 d8             	mov    -0x28(%ebp),%edx
c010407e:	89 d1                	mov    %edx,%ecx
c0104080:	c1 e1 0c             	shl    $0xc,%ecx
c0104083:	8b 7d d4             	mov    -0x2c(%ebp),%edi
c0104086:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0104089:	29 d7                	sub    %edx,%edi
c010408b:	89 fa                	mov    %edi,%edx
c010408d:	89 44 24 14          	mov    %eax,0x14(%esp)
c0104091:	89 74 24 10          	mov    %esi,0x10(%esp)
c0104095:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
c0104099:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c010409d:	89 54 24 04          	mov    %edx,0x4(%esp)
c01040a1:	c7 04 24 80 6b 10 c0 	movl   $0xc0106b80,(%esp)
c01040a8:	e8 e5 c1 ff ff       	call   c0100292 <cprintf>
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
c01040ad:	be 00 00 c0 fa       	mov    $0xfac00000,%esi
c01040b2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01040b5:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01040b8:	89 d3                	mov    %edx,%ebx
c01040ba:	c1 e3 0a             	shl    $0xa,%ebx
c01040bd:	8b 55 e0             	mov    -0x20(%ebp),%edx
c01040c0:	89 d1                	mov    %edx,%ecx
c01040c2:	c1 e1 0a             	shl    $0xa,%ecx
c01040c5:	8d 55 d4             	lea    -0x2c(%ebp),%edx
c01040c8:	89 54 24 14          	mov    %edx,0x14(%esp)
c01040cc:	8d 55 d8             	lea    -0x28(%ebp),%edx
c01040cf:	89 54 24 10          	mov    %edx,0x10(%esp)
c01040d3:	89 74 24 0c          	mov    %esi,0xc(%esp)
c01040d7:	89 44 24 08          	mov    %eax,0x8(%esp)
c01040db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
c01040df:	89 0c 24             	mov    %ecx,(%esp)
c01040e2:	e8 40 fe ff ff       	call   c0103f27 <get_pgtable_items>
c01040e7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01040ea:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c01040ee:	0f 85 65 ff ff ff    	jne    c0104059 <print_pgdir+0x80>
//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
c01040f4:	b9 00 b0 fe fa       	mov    $0xfafeb000,%ecx
c01040f9:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01040fc:	8d 55 dc             	lea    -0x24(%ebp),%edx
c01040ff:	89 54 24 14          	mov    %edx,0x14(%esp)
c0104103:	8d 55 e0             	lea    -0x20(%ebp),%edx
c0104106:	89 54 24 10          	mov    %edx,0x10(%esp)
c010410a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
c010410e:	89 44 24 08          	mov    %eax,0x8(%esp)
c0104112:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
c0104119:	00 
c010411a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c0104121:	e8 01 fe ff ff       	call   c0103f27 <get_pgtable_items>
c0104126:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0104129:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c010412d:	0f 85 c7 fe ff ff    	jne    c0103ffa <print_pgdir+0x21>
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
        }
    }
    cprintf("--------------------- END ---------------------\n");
c0104133:	c7 04 24 a4 6b 10 c0 	movl   $0xc0106ba4,(%esp)
c010413a:	e8 53 c1 ff ff       	call   c0100292 <cprintf>
}
c010413f:	90                   	nop
c0104140:	83 c4 4c             	add    $0x4c,%esp
c0104143:	5b                   	pop    %ebx
c0104144:	5e                   	pop    %esi
c0104145:	5f                   	pop    %edi
c0104146:	5d                   	pop    %ebp
c0104147:	c3                   	ret    

c0104148 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
c0104148:	55                   	push   %ebp
c0104149:	89 e5                	mov    %esp,%ebp
    return page - pages;
c010414b:	8b 45 08             	mov    0x8(%ebp),%eax
c010414e:	8b 15 18 af 11 c0    	mov    0xc011af18,%edx
c0104154:	29 d0                	sub    %edx,%eax
c0104156:	c1 f8 02             	sar    $0x2,%eax
c0104159:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
c010415f:	5d                   	pop    %ebp
c0104160:	c3                   	ret    

c0104161 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
c0104161:	55                   	push   %ebp
c0104162:	89 e5                	mov    %esp,%ebp
c0104164:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;
c0104167:	8b 45 08             	mov    0x8(%ebp),%eax
c010416a:	89 04 24             	mov    %eax,(%esp)
c010416d:	e8 d6 ff ff ff       	call   c0104148 <page2ppn>
c0104172:	c1 e0 0c             	shl    $0xc,%eax
}
c0104175:	c9                   	leave  
c0104176:	c3                   	ret    

c0104177 <page_ref>:
pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
}

static inline int
page_ref(struct Page *page) {
c0104177:	55                   	push   %ebp
c0104178:	89 e5                	mov    %esp,%ebp
    return page->ref;
c010417a:	8b 45 08             	mov    0x8(%ebp),%eax
c010417d:	8b 00                	mov    (%eax),%eax
}
c010417f:	5d                   	pop    %ebp
c0104180:	c3                   	ret    

c0104181 <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
c0104181:	55                   	push   %ebp
c0104182:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c0104184:	8b 45 08             	mov    0x8(%ebp),%eax
c0104187:	8b 55 0c             	mov    0xc(%ebp),%edx
c010418a:	89 10                	mov    %edx,(%eax)
}
c010418c:	90                   	nop
c010418d:	5d                   	pop    %ebp
c010418e:	c3                   	ret    

c010418f <default_init>:

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
c010418f:	55                   	push   %ebp
c0104190:	89 e5                	mov    %esp,%ebp
c0104192:	83 ec 10             	sub    $0x10,%esp
c0104195:	c7 45 fc 1c af 11 c0 	movl   $0xc011af1c,-0x4(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c010419c:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010419f:	8b 55 fc             	mov    -0x4(%ebp),%edx
c01041a2:	89 50 04             	mov    %edx,0x4(%eax)
c01041a5:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01041a8:	8b 50 04             	mov    0x4(%eax),%edx
c01041ab:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01041ae:	89 10                	mov    %edx,(%eax)
     * Because at first there is no free block to add, so we just let the prev and next pointers to point to itself.
     * This is done through:
     *      free_list->next = free_list->prev = free_list;
     */
    list_init(&free_list);
    nr_free = 0;
c01041b0:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c01041b7:	00 00 00 
}
c01041ba:	90                   	nop
c01041bb:	c9                   	leave  
c01041bc:	c3                   	ret    

c01041bd <default_init_memmap>:
 * Page has been referenced, etc.
 * 
 * This function is used to initilize each page within a free memory block and then link it to the free list.
 */
static void
default_init_memmap(struct Page *base, size_t n) {
c01041bd:	55                   	push   %ebp
c01041be:	89 e5                	mov    %esp,%ebp
c01041c0:	83 ec 48             	sub    $0x48,%esp
assert(n > 0);
c01041c3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c01041c7:	75 24                	jne    c01041ed <default_init_memmap+0x30>
c01041c9:	c7 44 24 0c d8 6b 10 	movl   $0xc0106bd8,0xc(%esp)
c01041d0:	c0 
c01041d1:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c01041d8:	c0 
c01041d9:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
c01041e0:	00 
c01041e1:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c01041e8:	e8 fc c1 ff ff       	call   c01003e9 <__panic>
    struct Page *p = base;
c01041ed:	8b 45 08             	mov    0x8(%ebp),%eax
c01041f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
c01041f3:	eb 7d                	jmp    c0104272 <default_init_memmap+0xb5>
        assert(PageReserved(p));
c01041f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01041f8:	83 c0 04             	add    $0x4,%eax
c01041fb:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
c0104202:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104205:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104208:	8b 55 e8             	mov    -0x18(%ebp),%edx
c010420b:	0f a3 10             	bt     %edx,(%eax)
c010420e:	19 c0                	sbb    %eax,%eax
c0104210:	89 45 e0             	mov    %eax,-0x20(%ebp)
    return oldbit != 0;
c0104213:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c0104217:	0f 95 c0             	setne  %al
c010421a:	0f b6 c0             	movzbl %al,%eax
c010421d:	85 c0                	test   %eax,%eax
c010421f:	75 24                	jne    c0104245 <default_init_memmap+0x88>
c0104221:	c7 44 24 0c 09 6c 10 	movl   $0xc0106c09,0xc(%esp)
c0104228:	c0 
c0104229:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104230:	c0 
c0104231:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
c0104238:	00 
c0104239:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104240:	e8 a4 c1 ff ff       	call   c01003e9 <__panic>
        p->flags = p->property = 0;
c0104245:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104248:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
c010424f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104252:	8b 50 08             	mov    0x8(%eax),%edx
c0104255:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104258:	89 50 04             	mov    %edx,0x4(%eax)
        set_page_ref(p, 0);
c010425b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0104262:	00 
c0104263:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104266:	89 04 24             	mov    %eax,(%esp)
c0104269:	e8 13 ff ff ff       	call   c0104181 <set_page_ref>
 */
static void
default_init_memmap(struct Page *base, size_t n) {
assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
c010426e:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
c0104272:	8b 55 0c             	mov    0xc(%ebp),%edx
c0104275:	89 d0                	mov    %edx,%eax
c0104277:	c1 e0 02             	shl    $0x2,%eax
c010427a:	01 d0                	add    %edx,%eax
c010427c:	c1 e0 02             	shl    $0x2,%eax
c010427f:	89 c2                	mov    %eax,%edx
c0104281:	8b 45 08             	mov    0x8(%ebp),%eax
c0104284:	01 d0                	add    %edx,%eax
c0104286:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104289:	0f 85 66 ff ff ff    	jne    c01041f5 <default_init_memmap+0x38>
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
c010428f:	8b 45 08             	mov    0x8(%ebp),%eax
c0104292:	8b 55 0c             	mov    0xc(%ebp),%edx
c0104295:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
c0104298:	8b 45 08             	mov    0x8(%ebp),%eax
c010429b:	83 c0 04             	add    $0x4,%eax
c010429e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
c01042a5:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c01042a8:	8b 45 cc             	mov    -0x34(%ebp),%eax
c01042ab:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01042ae:	0f ab 10             	bts    %edx,(%eax)
    nr_free += n;
c01042b1:	8b 15 24 af 11 c0    	mov    0xc011af24,%edx
c01042b7:	8b 45 0c             	mov    0xc(%ebp),%eax
c01042ba:	01 d0                	add    %edx,%eax
c01042bc:	a3 24 af 11 c0       	mov    %eax,0xc011af24
    list_add_before(&free_list, &(base->page_link));
c01042c1:	8b 45 08             	mov    0x8(%ebp),%eax
c01042c4:	83 c0 0c             	add    $0xc,%eax
c01042c7:	c7 45 f0 1c af 11 c0 	movl   $0xc011af1c,-0x10(%ebp)
c01042ce:	89 45 dc             	mov    %eax,-0x24(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
c01042d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01042d4:	8b 00                	mov    (%eax),%eax
c01042d6:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01042d9:	89 55 d8             	mov    %edx,-0x28(%ebp)
c01042dc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
c01042df:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01042e2:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c01042e5:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01042e8:	8b 55 d8             	mov    -0x28(%ebp),%edx
c01042eb:	89 10                	mov    %edx,(%eax)
c01042ed:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01042f0:	8b 10                	mov    (%eax),%edx
c01042f2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01042f5:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c01042f8:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01042fb:	8b 55 d0             	mov    -0x30(%ebp),%edx
c01042fe:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0104301:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104304:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104307:	89 10                	mov    %edx,(%eax)
}
c0104309:	90                   	nop
c010430a:	c9                   	leave  
c010430b:	c3                   	ret    

c010430c <default_alloc_pages>:
static struct Page *
default_alloc_pages(size_t n) {
c010430c:	55                   	push   %ebp
c010430d:	89 e5                	mov    %esp,%ebp
c010430f:	83 ec 68             	sub    $0x68,%esp

    assert(n > 0);
c0104312:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0104316:	75 24                	jne    c010433c <default_alloc_pages+0x30>
c0104318:	c7 44 24 0c d8 6b 10 	movl   $0xc0106bd8,0xc(%esp)
c010431f:	c0 
c0104320:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104327:	c0 
c0104328:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
c010432f:	00 
c0104330:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104337:	e8 ad c0 ff ff       	call   c01003e9 <__panic>
    /*
     * The required size n cannot be allocated, because there is no more free memory block.
     */
    if (n > nr_free) {
c010433c:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104341:	3b 45 08             	cmp    0x8(%ebp),%eax
c0104344:	73 0a                	jae    c0104350 <default_alloc_pages+0x44>
        return NULL;
c0104346:	b8 00 00 00 00       	mov    $0x0,%eax
c010434b:	e9 3d 01 00 00       	jmp    c010448d <default_alloc_pages+0x181>
    }
    struct Page *page = NULL; // <- This is the base page of the block, i.e., the identifier of the block.
c0104350:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    list_entry_t *le = &free_list;
c0104357:	c7 45 f0 1c af 11 c0 	movl   $0xc011af1c,-0x10(%ebp)
    /* 
     * Haobin Chen.
     * Traverse the free list.
     * If the next memory block to find is the head of the free list, then it means we cannot find any available block.
     */
    while ((le = list_next(le)) != &free_list) {
c010435e:	eb 1c                	jmp    c010437c <default_alloc_pages+0x70>
        struct Page *p = le2page(le, page_link);
c0104360:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104363:	83 e8 0c             	sub    $0xc,%eax
c0104366:	89 45 e8             	mov    %eax,-0x18(%ebp)
        if (p->property >= n) {
c0104369:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010436c:	8b 40 08             	mov    0x8(%eax),%eax
c010436f:	3b 45 08             	cmp    0x8(%ebp),%eax
c0104372:	72 08                	jb     c010437c <default_alloc_pages+0x70>
            page = p;
c0104374:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0104377:	89 45 f4             	mov    %eax,-0xc(%ebp)
            break;
c010437a:	eb 18                	jmp    c0104394 <default_alloc_pages+0x88>
c010437c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010437f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0104382:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0104385:	8b 40 04             	mov    0x4(%eax),%eax
    /* 
     * Haobin Chen.
     * Traverse the free list.
     * If the next memory block to find is the head of the free list, then it means we cannot find any available block.
     */
    while ((le = list_next(le)) != &free_list) {
c0104388:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010438b:	81 7d f0 1c af 11 c0 	cmpl   $0xc011af1c,-0x10(%ebp)
c0104392:	75 cc                	jne    c0104360 <default_alloc_pages+0x54>
            page = p;
            break;
        }
    }

    if (page != NULL) {
c0104394:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0104398:	0f 84 ec 00 00 00    	je     c010448a <default_alloc_pages+0x17e>
        // Adjust the allocation step by split block into two.
        // list_del(&(page->page_link));
        if (page->property > n) {
c010439e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01043a1:	8b 40 08             	mov    0x8(%eax),%eax
c01043a4:	3b 45 08             	cmp    0x8(%ebp),%eax
c01043a7:	0f 86 8c 00 00 00    	jbe    c0104439 <default_alloc_pages+0x12d>
            struct Page *p = page + n;
c01043ad:	8b 55 08             	mov    0x8(%ebp),%edx
c01043b0:	89 d0                	mov    %edx,%eax
c01043b2:	c1 e0 02             	shl    $0x2,%eax
c01043b5:	01 d0                	add    %edx,%eax
c01043b7:	c1 e0 02             	shl    $0x2,%eax
c01043ba:	89 c2                	mov    %eax,%edx
c01043bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01043bf:	01 d0                	add    %edx,%eax
c01043c1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            p->property = page->property - n;
c01043c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01043c7:	8b 40 08             	mov    0x8(%eax),%eax
c01043ca:	2b 45 08             	sub    0x8(%ebp),%eax
c01043cd:	89 c2                	mov    %eax,%edx
c01043cf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01043d2:	89 50 08             	mov    %edx,0x8(%eax)
            // Apply the property.
            SetPageProperty(p);
c01043d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01043d8:	83 c0 04             	add    $0x4,%eax
c01043db:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
c01043e2:	89 45 c0             	mov    %eax,-0x40(%ebp)
c01043e5:	8b 45 c0             	mov    -0x40(%ebp),%eax
c01043e8:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01043eb:	0f ab 10             	bts    %edx,(%eax)
            // Split the memory block and append the remainder right behind the current block.
            list_add_after(&(page->page_link), &(p->page_link));
c01043ee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01043f1:	83 c0 0c             	add    $0xc,%eax
c01043f4:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01043f7:	83 c2 0c             	add    $0xc,%edx
c01043fa:	89 55 ec             	mov    %edx,-0x14(%ebp)
c01043fd:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
c0104400:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104403:	8b 40 04             	mov    0x4(%eax),%eax
c0104406:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0104409:	89 55 cc             	mov    %edx,-0x34(%ebp)
c010440c:	8b 55 ec             	mov    -0x14(%ebp),%edx
c010440f:	89 55 c8             	mov    %edx,-0x38(%ebp)
c0104412:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c0104415:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104418:	8b 55 cc             	mov    -0x34(%ebp),%edx
c010441b:	89 10                	mov    %edx,(%eax)
c010441d:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104420:	8b 10                	mov    (%eax),%edx
c0104422:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0104425:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c0104428:	8b 45 cc             	mov    -0x34(%ebp),%eax
c010442b:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c010442e:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0104431:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0104434:	8b 55 c8             	mov    -0x38(%ebp),%edx
c0104437:	89 10                	mov    %edx,(%eax)
        }

        list_del(&(page->page_link));
c0104439:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010443c:	83 c0 0c             	add    $0xc,%eax
c010443f:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c0104442:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104445:	8b 40 04             	mov    0x4(%eax),%eax
c0104448:	8b 55 d8             	mov    -0x28(%ebp),%edx
c010444b:	8b 12                	mov    (%edx),%edx
c010444d:	89 55 b8             	mov    %edx,-0x48(%ebp)
c0104450:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c0104453:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0104456:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0104459:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c010445c:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c010445f:	8b 55 b8             	mov    -0x48(%ebp),%edx
c0104462:	89 10                	mov    %edx,(%eax)
        nr_free -= n;
c0104464:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104469:	2b 45 08             	sub    0x8(%ebp),%eax
c010446c:	a3 24 af 11 c0       	mov    %eax,0xc011af24
        ClearPageProperty(page);
c0104471:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104474:	83 c0 04             	add    $0x4,%eax
c0104477:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
c010447e:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0104481:	8b 45 bc             	mov    -0x44(%ebp),%eax
c0104484:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0104487:	0f b3 10             	btr    %edx,(%eax)
    }
    return page;
c010448a:	8b 45 f4             	mov    -0xc(%ebp),%eax

}
c010448d:	c9                   	leave  
c010448e:	c3                   	ret    

c010448f <default_free_pages>:

static void
default_free_pages(struct Page *base, size_t n) {
c010448f:	55                   	push   %ebp
c0104490:	89 e5                	mov    %esp,%ebp
c0104492:	81 ec 98 00 00 00    	sub    $0x98,%esp
    assert(n > 0);
c0104498:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c010449c:	75 24                	jne    c01044c2 <default_free_pages+0x33>
c010449e:	c7 44 24 0c d8 6b 10 	movl   $0xc0106bd8,0xc(%esp)
c01044a5:	c0 
c01044a6:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c01044ad:	c0 
c01044ae:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
c01044b5:	00 
c01044b6:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c01044bd:	e8 27 bf ff ff       	call   c01003e9 <__panic>
    struct Page *p = base;
c01044c2:	8b 45 08             	mov    0x8(%ebp),%eax
c01044c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
c01044c8:	e9 9d 00 00 00       	jmp    c010456a <default_free_pages+0xdb>
        // Reset the pages within the block.
        assert(!PageReserved(p) && !PageProperty(p));
c01044cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01044d0:	83 c0 04             	add    $0x4,%eax
c01044d3:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
c01044da:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c01044dd:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c01044e0:	8b 55 b8             	mov    -0x48(%ebp),%edx
c01044e3:	0f a3 10             	bt     %edx,(%eax)
c01044e6:	19 c0                	sbb    %eax,%eax
c01044e8:	89 45 b0             	mov    %eax,-0x50(%ebp)
    return oldbit != 0;
c01044eb:	83 7d b0 00          	cmpl   $0x0,-0x50(%ebp)
c01044ef:	0f 95 c0             	setne  %al
c01044f2:	0f b6 c0             	movzbl %al,%eax
c01044f5:	85 c0                	test   %eax,%eax
c01044f7:	75 2c                	jne    c0104525 <default_free_pages+0x96>
c01044f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01044fc:	83 c0 04             	add    $0x4,%eax
c01044ff:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
c0104506:	89 45 ac             	mov    %eax,-0x54(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104509:	8b 45 ac             	mov    -0x54(%ebp),%eax
c010450c:	8b 55 e8             	mov    -0x18(%ebp),%edx
c010450f:	0f a3 10             	bt     %edx,(%eax)
c0104512:	19 c0                	sbb    %eax,%eax
c0104514:	89 45 a8             	mov    %eax,-0x58(%ebp)
    return oldbit != 0;
c0104517:	83 7d a8 00          	cmpl   $0x0,-0x58(%ebp)
c010451b:	0f 95 c0             	setne  %al
c010451e:	0f b6 c0             	movzbl %al,%eax
c0104521:	85 c0                	test   %eax,%eax
c0104523:	74 24                	je     c0104549 <default_free_pages+0xba>
c0104525:	c7 44 24 0c 1c 6c 10 	movl   $0xc0106c1c,0xc(%esp)
c010452c:	c0 
c010452d:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104534:	c0 
c0104535:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
c010453c:	00 
c010453d:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104544:	e8 a0 be ff ff       	call   c01003e9 <__panic>
        p->flags = 0;
c0104549:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010454c:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
        set_page_ref(p, 0);
c0104553:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c010455a:	00 
c010455b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010455e:	89 04 24             	mov    %eax,(%esp)
c0104561:	e8 1b fc ff ff       	call   c0104181 <set_page_ref>

static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
c0104566:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
c010456a:	8b 55 0c             	mov    0xc(%ebp),%edx
c010456d:	89 d0                	mov    %edx,%eax
c010456f:	c1 e0 02             	shl    $0x2,%eax
c0104572:	01 d0                	add    %edx,%eax
c0104574:	c1 e0 02             	shl    $0x2,%eax
c0104577:	89 c2                	mov    %eax,%edx
c0104579:	8b 45 08             	mov    0x8(%ebp),%eax
c010457c:	01 d0                	add    %edx,%eax
c010457e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104581:	0f 85 46 ff ff ff    	jne    c01044cd <default_free_pages+0x3e>
        // Reset the pages within the block.
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
c0104587:	8b 45 08             	mov    0x8(%ebp),%eax
c010458a:	8b 55 0c             	mov    0xc(%ebp),%edx
c010458d:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
c0104590:	8b 45 08             	mov    0x8(%ebp),%eax
c0104593:	83 c0 04             	add    $0x4,%eax
c0104596:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
c010459d:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c01045a0:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c01045a3:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01045a6:	0f ab 10             	bts    %edx,(%eax)
c01045a9:	c7 45 e4 1c af 11 c0 	movl   $0xc011af1c,-0x1c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c01045b0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01045b3:	8b 40 04             	mov    0x4(%eax),%eax

    list_entry_t *le = list_next(&free_list);
c01045b6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
c01045b9:	e9 08 01 00 00       	jmp    c01046c6 <default_free_pages+0x237>
        // Get the next block and fetch its property by tranforming it to a page pointer.
        p = le2page(le, page_link);
c01045be:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01045c1:	83 e8 0c             	sub    $0xc,%eax
c01045c4:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01045c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01045ca:	89 45 e0             	mov    %eax,-0x20(%ebp)
c01045cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01045d0:	8b 40 04             	mov    0x4(%eax),%eax
        le = list_next(le);
c01045d3:	89 45 f0             	mov    %eax,-0x10(%ebp)

        // Do merge.
        if (base + base->property == p) {
c01045d6:	8b 45 08             	mov    0x8(%ebp),%eax
c01045d9:	8b 50 08             	mov    0x8(%eax),%edx
c01045dc:	89 d0                	mov    %edx,%eax
c01045de:	c1 e0 02             	shl    $0x2,%eax
c01045e1:	01 d0                	add    %edx,%eax
c01045e3:	c1 e0 02             	shl    $0x2,%eax
c01045e6:	89 c2                	mov    %eax,%edx
c01045e8:	8b 45 08             	mov    0x8(%ebp),%eax
c01045eb:	01 d0                	add    %edx,%eax
c01045ed:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01045f0:	75 5a                	jne    c010464c <default_free_pages+0x1bd>
            // Merge with the next block.
            base->property += p->property;
c01045f2:	8b 45 08             	mov    0x8(%ebp),%eax
c01045f5:	8b 50 08             	mov    0x8(%eax),%edx
c01045f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01045fb:	8b 40 08             	mov    0x8(%eax),%eax
c01045fe:	01 c2                	add    %eax,%edx
c0104600:	8b 45 08             	mov    0x8(%ebp),%eax
c0104603:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(p);
c0104606:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104609:	83 c0 04             	add    $0x4,%eax
c010460c:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
c0104613:	89 45 98             	mov    %eax,-0x68(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0104616:	8b 45 98             	mov    -0x68(%ebp),%eax
c0104619:	8b 55 d0             	mov    -0x30(%ebp),%edx
c010461c:	0f b3 10             	btr    %edx,(%eax)
            list_del(&(p->page_link));
c010461f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104622:	83 c0 0c             	add    $0xc,%eax
c0104625:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c0104628:	8b 45 d8             	mov    -0x28(%ebp),%eax
c010462b:	8b 40 04             	mov    0x4(%eax),%eax
c010462e:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0104631:	8b 12                	mov    (%edx),%edx
c0104633:	89 55 a0             	mov    %edx,-0x60(%ebp)
c0104636:	89 45 9c             	mov    %eax,-0x64(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c0104639:	8b 45 a0             	mov    -0x60(%ebp),%eax
c010463c:	8b 55 9c             	mov    -0x64(%ebp),%edx
c010463f:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c0104642:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0104645:	8b 55 a0             	mov    -0x60(%ebp),%edx
c0104648:	89 10                	mov    %edx,(%eax)
c010464a:	eb 7a                	jmp    c01046c6 <default_free_pages+0x237>
        }
        else if (p + p->property == base) {
c010464c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010464f:	8b 50 08             	mov    0x8(%eax),%edx
c0104652:	89 d0                	mov    %edx,%eax
c0104654:	c1 e0 02             	shl    $0x2,%eax
c0104657:	01 d0                	add    %edx,%eax
c0104659:	c1 e0 02             	shl    $0x2,%eax
c010465c:	89 c2                	mov    %eax,%edx
c010465e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104661:	01 d0                	add    %edx,%eax
c0104663:	3b 45 08             	cmp    0x8(%ebp),%eax
c0104666:	75 5e                	jne    c01046c6 <default_free_pages+0x237>
            // Merge with the previous block.
            p->property += base->property;
c0104668:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010466b:	8b 50 08             	mov    0x8(%eax),%edx
c010466e:	8b 45 08             	mov    0x8(%ebp),%eax
c0104671:	8b 40 08             	mov    0x8(%eax),%eax
c0104674:	01 c2                	add    %eax,%edx
c0104676:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104679:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(base);
c010467c:	8b 45 08             	mov    0x8(%ebp),%eax
c010467f:	83 c0 04             	add    $0x4,%eax
c0104682:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
c0104689:	89 45 8c             	mov    %eax,-0x74(%ebp)
c010468c:	8b 45 8c             	mov    -0x74(%ebp),%eax
c010468f:	8b 55 c8             	mov    -0x38(%ebp),%edx
c0104692:	0f b3 10             	btr    %edx,(%eax)
            base = p;
c0104695:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104698:	89 45 08             	mov    %eax,0x8(%ebp)
            list_del(&(p->page_link));
c010469b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010469e:	83 c0 0c             	add    $0xc,%eax
c01046a1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c01046a4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01046a7:	8b 40 04             	mov    0x4(%eax),%eax
c01046aa:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01046ad:	8b 12                	mov    (%edx),%edx
c01046af:	89 55 94             	mov    %edx,-0x6c(%ebp)
c01046b2:	89 45 90             	mov    %eax,-0x70(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c01046b5:	8b 45 94             	mov    -0x6c(%ebp),%eax
c01046b8:	8b 55 90             	mov    -0x70(%ebp),%edx
c01046bb:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c01046be:	8b 45 90             	mov    -0x70(%ebp),%eax
c01046c1:	8b 55 94             	mov    -0x6c(%ebp),%edx
c01046c4:	89 10                	mov    %edx,(%eax)
    }
    base->property = n;
    SetPageProperty(base);

    list_entry_t *le = list_next(&free_list);
    while (le != &free_list) {
c01046c6:	81 7d f0 1c af 11 c0 	cmpl   $0xc011af1c,-0x10(%ebp)
c01046cd:	0f 85 eb fe ff ff    	jne    c01045be <default_free_pages+0x12f>
c01046d3:	c7 45 cc 1c af 11 c0 	movl   $0xc011af1c,-0x34(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c01046da:	8b 45 cc             	mov    -0x34(%ebp),%eax
c01046dd:	8b 40 04             	mov    0x4(%eax),%eax
    /*
     * Haobin Chen.
     * 
     * Find the right place to insert.
     */
    list_entry_t *ptr = list_next(&free_list);
c01046e0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    while (ptr != &free_list) {
c01046e3:	eb 34                	jmp    c0104719 <default_free_pages+0x28a>
         * le2page receives two parameters to convert a struct to another. The second parameter
         * means the member to be the first parameter.
         * 
         * E.g. Current page's page_link member will be the first parameter: ptr (which is the current block to be accessed).
         */
        struct Page *cur = le2page(ptr, page_link);
c01046e5:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01046e8:	83 e8 0c             	sub    $0xc,%eax
c01046eb:	89 45 c0             	mov    %eax,-0x40(%ebp)
        if (base + base->property < cur) {
c01046ee:	8b 45 08             	mov    0x8(%ebp),%eax
c01046f1:	8b 50 08             	mov    0x8(%eax),%edx
c01046f4:	89 d0                	mov    %edx,%eax
c01046f6:	c1 e0 02             	shl    $0x2,%eax
c01046f9:	01 d0                	add    %edx,%eax
c01046fb:	c1 e0 02             	shl    $0x2,%eax
c01046fe:	89 c2                	mov    %eax,%edx
c0104700:	8b 45 08             	mov    0x8(%ebp),%eax
c0104703:	01 d0                	add    %edx,%eax
c0104705:	3b 45 c0             	cmp    -0x40(%ebp),%eax
c0104708:	72 1a                	jb     c0104724 <default_free_pages+0x295>
c010470a:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010470d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
c0104710:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104713:	8b 40 04             	mov    0x4(%eax),%eax
            break;
        }
        ptr = list_next(ptr);
c0104716:	89 45 ec             	mov    %eax,-0x14(%ebp)
     * Haobin Chen.
     * 
     * Find the right place to insert.
     */
    list_entry_t *ptr = list_next(&free_list);
    while (ptr != &free_list) {
c0104719:	81 7d ec 1c af 11 c0 	cmpl   $0xc011af1c,-0x14(%ebp)
c0104720:	75 c3                	jne    c01046e5 <default_free_pages+0x256>
c0104722:	eb 01                	jmp    c0104725 <default_free_pages+0x296>
         * 
         * E.g. Current page's page_link member will be the first parameter: ptr (which is the current block to be accessed).
         */
        struct Page *cur = le2page(ptr, page_link);
        if (base + base->property < cur) {
            break;
c0104724:	90                   	nop
        }
        ptr = list_next(ptr);
    }

    list_add_before(ptr, &(base->page_link));
c0104725:	8b 45 08             	mov    0x8(%ebp),%eax
c0104728:	8d 50 0c             	lea    0xc(%eax),%edx
c010472b:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010472e:	89 45 bc             	mov    %eax,-0x44(%ebp)
c0104731:	89 55 88             	mov    %edx,-0x78(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
c0104734:	8b 45 bc             	mov    -0x44(%ebp),%eax
c0104737:	8b 00                	mov    (%eax),%eax
c0104739:	8b 55 88             	mov    -0x78(%ebp),%edx
c010473c:	89 55 84             	mov    %edx,-0x7c(%ebp)
c010473f:	89 45 80             	mov    %eax,-0x80(%ebp)
c0104742:	8b 45 bc             	mov    -0x44(%ebp),%eax
c0104745:	89 85 7c ff ff ff    	mov    %eax,-0x84(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c010474b:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
c0104751:	8b 55 84             	mov    -0x7c(%ebp),%edx
c0104754:	89 10                	mov    %edx,(%eax)
c0104756:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
c010475c:	8b 10                	mov    (%eax),%edx
c010475e:	8b 45 80             	mov    -0x80(%ebp),%eax
c0104761:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c0104764:	8b 45 84             	mov    -0x7c(%ebp),%eax
c0104767:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
c010476d:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0104770:	8b 45 84             	mov    -0x7c(%ebp),%eax
c0104773:	8b 55 80             	mov    -0x80(%ebp),%edx
c0104776:	89 10                	mov    %edx,(%eax)
    nr_free += n;
c0104778:	8b 15 24 af 11 c0    	mov    0xc011af24,%edx
c010477e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0104781:	01 d0                	add    %edx,%eax
c0104783:	a3 24 af 11 c0       	mov    %eax,0xc011af24
}
c0104788:	90                   	nop
c0104789:	c9                   	leave  
c010478a:	c3                   	ret    

c010478b <default_nr_free_pages>:

static size_t
default_nr_free_pages(void) {
c010478b:	55                   	push   %ebp
c010478c:	89 e5                	mov    %esp,%ebp
    return nr_free;
c010478e:	a1 24 af 11 c0       	mov    0xc011af24,%eax
}
c0104793:	5d                   	pop    %ebp
c0104794:	c3                   	ret    

c0104795 <basic_check>:

static void
basic_check(void) {
c0104795:	55                   	push   %ebp
c0104796:	89 e5                	mov    %esp,%ebp
c0104798:	83 ec 48             	sub    $0x48,%esp
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
c010479b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c01047a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01047a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01047a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01047ab:	89 45 ec             	mov    %eax,-0x14(%ebp)
    assert((p0 = alloc_page()) != NULL);
c01047ae:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01047b5:	e8 d3 e2 ff ff       	call   c0102a8d <alloc_pages>
c01047ba:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01047bd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c01047c1:	75 24                	jne    c01047e7 <basic_check+0x52>
c01047c3:	c7 44 24 0c 41 6c 10 	movl   $0xc0106c41,0xc(%esp)
c01047ca:	c0 
c01047cb:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c01047d2:	c0 
c01047d3:	c7 44 24 04 1c 01 00 	movl   $0x11c,0x4(%esp)
c01047da:	00 
c01047db:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c01047e2:	e8 02 bc ff ff       	call   c01003e9 <__panic>
    assert((p1 = alloc_page()) != NULL);
c01047e7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01047ee:	e8 9a e2 ff ff       	call   c0102a8d <alloc_pages>
c01047f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01047f6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01047fa:	75 24                	jne    c0104820 <basic_check+0x8b>
c01047fc:	c7 44 24 0c 5d 6c 10 	movl   $0xc0106c5d,0xc(%esp)
c0104803:	c0 
c0104804:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c010480b:	c0 
c010480c:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
c0104813:	00 
c0104814:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c010481b:	e8 c9 bb ff ff       	call   c01003e9 <__panic>
    assert((p2 = alloc_page()) != NULL);
c0104820:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104827:	e8 61 e2 ff ff       	call   c0102a8d <alloc_pages>
c010482c:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010482f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0104833:	75 24                	jne    c0104859 <basic_check+0xc4>
c0104835:	c7 44 24 0c 79 6c 10 	movl   $0xc0106c79,0xc(%esp)
c010483c:	c0 
c010483d:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104844:	c0 
c0104845:	c7 44 24 04 1e 01 00 	movl   $0x11e,0x4(%esp)
c010484c:	00 
c010484d:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104854:	e8 90 bb ff ff       	call   c01003e9 <__panic>

    assert(p0 != p1 && p0 != p2 && p1 != p2);
c0104859:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010485c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c010485f:	74 10                	je     c0104871 <basic_check+0xdc>
c0104861:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104864:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104867:	74 08                	je     c0104871 <basic_check+0xdc>
c0104869:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010486c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010486f:	75 24                	jne    c0104895 <basic_check+0x100>
c0104871:	c7 44 24 0c 98 6c 10 	movl   $0xc0106c98,0xc(%esp)
c0104878:	c0 
c0104879:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104880:	c0 
c0104881:	c7 44 24 04 20 01 00 	movl   $0x120,0x4(%esp)
c0104888:	00 
c0104889:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104890:	e8 54 bb ff ff       	call   c01003e9 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
c0104895:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104898:	89 04 24             	mov    %eax,(%esp)
c010489b:	e8 d7 f8 ff ff       	call   c0104177 <page_ref>
c01048a0:	85 c0                	test   %eax,%eax
c01048a2:	75 1e                	jne    c01048c2 <basic_check+0x12d>
c01048a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01048a7:	89 04 24             	mov    %eax,(%esp)
c01048aa:	e8 c8 f8 ff ff       	call   c0104177 <page_ref>
c01048af:	85 c0                	test   %eax,%eax
c01048b1:	75 0f                	jne    c01048c2 <basic_check+0x12d>
c01048b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01048b6:	89 04 24             	mov    %eax,(%esp)
c01048b9:	e8 b9 f8 ff ff       	call   c0104177 <page_ref>
c01048be:	85 c0                	test   %eax,%eax
c01048c0:	74 24                	je     c01048e6 <basic_check+0x151>
c01048c2:	c7 44 24 0c bc 6c 10 	movl   $0xc0106cbc,0xc(%esp)
c01048c9:	c0 
c01048ca:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c01048d1:	c0 
c01048d2:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
c01048d9:	00 
c01048da:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c01048e1:	e8 03 bb ff ff       	call   c01003e9 <__panic>

    assert(page2pa(p0) < npage * PGSIZE);
c01048e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01048e9:	89 04 24             	mov    %eax,(%esp)
c01048ec:	e8 70 f8 ff ff       	call   c0104161 <page2pa>
c01048f1:	8b 15 80 ae 11 c0    	mov    0xc011ae80,%edx
c01048f7:	c1 e2 0c             	shl    $0xc,%edx
c01048fa:	39 d0                	cmp    %edx,%eax
c01048fc:	72 24                	jb     c0104922 <basic_check+0x18d>
c01048fe:	c7 44 24 0c f8 6c 10 	movl   $0xc0106cf8,0xc(%esp)
c0104905:	c0 
c0104906:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c010490d:	c0 
c010490e:	c7 44 24 04 23 01 00 	movl   $0x123,0x4(%esp)
c0104915:	00 
c0104916:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c010491d:	e8 c7 ba ff ff       	call   c01003e9 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
c0104922:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104925:	89 04 24             	mov    %eax,(%esp)
c0104928:	e8 34 f8 ff ff       	call   c0104161 <page2pa>
c010492d:	8b 15 80 ae 11 c0    	mov    0xc011ae80,%edx
c0104933:	c1 e2 0c             	shl    $0xc,%edx
c0104936:	39 d0                	cmp    %edx,%eax
c0104938:	72 24                	jb     c010495e <basic_check+0x1c9>
c010493a:	c7 44 24 0c 15 6d 10 	movl   $0xc0106d15,0xc(%esp)
c0104941:	c0 
c0104942:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104949:	c0 
c010494a:	c7 44 24 04 24 01 00 	movl   $0x124,0x4(%esp)
c0104951:	00 
c0104952:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104959:	e8 8b ba ff ff       	call   c01003e9 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
c010495e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104961:	89 04 24             	mov    %eax,(%esp)
c0104964:	e8 f8 f7 ff ff       	call   c0104161 <page2pa>
c0104969:	8b 15 80 ae 11 c0    	mov    0xc011ae80,%edx
c010496f:	c1 e2 0c             	shl    $0xc,%edx
c0104972:	39 d0                	cmp    %edx,%eax
c0104974:	72 24                	jb     c010499a <basic_check+0x205>
c0104976:	c7 44 24 0c 32 6d 10 	movl   $0xc0106d32,0xc(%esp)
c010497d:	c0 
c010497e:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104985:	c0 
c0104986:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
c010498d:	00 
c010498e:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104995:	e8 4f ba ff ff       	call   c01003e9 <__panic>

    list_entry_t free_list_store = free_list;
c010499a:	a1 1c af 11 c0       	mov    0xc011af1c,%eax
c010499f:	8b 15 20 af 11 c0    	mov    0xc011af20,%edx
c01049a5:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01049a8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c01049ab:	c7 45 e4 1c af 11 c0 	movl   $0xc011af1c,-0x1c(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c01049b2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01049b5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01049b8:	89 50 04             	mov    %edx,0x4(%eax)
c01049bb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01049be:	8b 50 04             	mov    0x4(%eax),%edx
c01049c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01049c4:	89 10                	mov    %edx,(%eax)
c01049c6:	c7 45 d8 1c af 11 c0 	movl   $0xc011af1c,-0x28(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
c01049cd:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01049d0:	8b 40 04             	mov    0x4(%eax),%eax
c01049d3:	39 45 d8             	cmp    %eax,-0x28(%ebp)
c01049d6:	0f 94 c0             	sete   %al
c01049d9:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
c01049dc:	85 c0                	test   %eax,%eax
c01049de:	75 24                	jne    c0104a04 <basic_check+0x26f>
c01049e0:	c7 44 24 0c 4f 6d 10 	movl   $0xc0106d4f,0xc(%esp)
c01049e7:	c0 
c01049e8:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c01049ef:	c0 
c01049f0:	c7 44 24 04 29 01 00 	movl   $0x129,0x4(%esp)
c01049f7:	00 
c01049f8:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c01049ff:	e8 e5 b9 ff ff       	call   c01003e9 <__panic>

    unsigned int nr_free_store = nr_free;
c0104a04:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104a09:	89 45 e0             	mov    %eax,-0x20(%ebp)
    nr_free = 0;
c0104a0c:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c0104a13:	00 00 00 

    assert(alloc_page() == NULL);
c0104a16:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104a1d:	e8 6b e0 ff ff       	call   c0102a8d <alloc_pages>
c0104a22:	85 c0                	test   %eax,%eax
c0104a24:	74 24                	je     c0104a4a <basic_check+0x2b5>
c0104a26:	c7 44 24 0c 66 6d 10 	movl   $0xc0106d66,0xc(%esp)
c0104a2d:	c0 
c0104a2e:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104a35:	c0 
c0104a36:	c7 44 24 04 2e 01 00 	movl   $0x12e,0x4(%esp)
c0104a3d:	00 
c0104a3e:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104a45:	e8 9f b9 ff ff       	call   c01003e9 <__panic>

    free_page(p0);
c0104a4a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104a51:	00 
c0104a52:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104a55:	89 04 24             	mov    %eax,(%esp)
c0104a58:	e8 68 e0 ff ff       	call   c0102ac5 <free_pages>
    free_page(p1);
c0104a5d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104a64:	00 
c0104a65:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104a68:	89 04 24             	mov    %eax,(%esp)
c0104a6b:	e8 55 e0 ff ff       	call   c0102ac5 <free_pages>
    free_page(p2);
c0104a70:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104a77:	00 
c0104a78:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104a7b:	89 04 24             	mov    %eax,(%esp)
c0104a7e:	e8 42 e0 ff ff       	call   c0102ac5 <free_pages>
    assert(nr_free == 3);
c0104a83:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104a88:	83 f8 03             	cmp    $0x3,%eax
c0104a8b:	74 24                	je     c0104ab1 <basic_check+0x31c>
c0104a8d:	c7 44 24 0c 7b 6d 10 	movl   $0xc0106d7b,0xc(%esp)
c0104a94:	c0 
c0104a95:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104a9c:	c0 
c0104a9d:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
c0104aa4:	00 
c0104aa5:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104aac:	e8 38 b9 ff ff       	call   c01003e9 <__panic>

    assert((p0 = alloc_page()) != NULL);
c0104ab1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104ab8:	e8 d0 df ff ff       	call   c0102a8d <alloc_pages>
c0104abd:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0104ac0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c0104ac4:	75 24                	jne    c0104aea <basic_check+0x355>
c0104ac6:	c7 44 24 0c 41 6c 10 	movl   $0xc0106c41,0xc(%esp)
c0104acd:	c0 
c0104ace:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104ad5:	c0 
c0104ad6:	c7 44 24 04 35 01 00 	movl   $0x135,0x4(%esp)
c0104add:	00 
c0104ade:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104ae5:	e8 ff b8 ff ff       	call   c01003e9 <__panic>
    assert((p1 = alloc_page()) != NULL);
c0104aea:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104af1:	e8 97 df ff ff       	call   c0102a8d <alloc_pages>
c0104af6:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104af9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0104afd:	75 24                	jne    c0104b23 <basic_check+0x38e>
c0104aff:	c7 44 24 0c 5d 6c 10 	movl   $0xc0106c5d,0xc(%esp)
c0104b06:	c0 
c0104b07:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104b0e:	c0 
c0104b0f:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
c0104b16:	00 
c0104b17:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104b1e:	e8 c6 b8 ff ff       	call   c01003e9 <__panic>
    assert((p2 = alloc_page()) != NULL);
c0104b23:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104b2a:	e8 5e df ff ff       	call   c0102a8d <alloc_pages>
c0104b2f:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0104b32:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0104b36:	75 24                	jne    c0104b5c <basic_check+0x3c7>
c0104b38:	c7 44 24 0c 79 6c 10 	movl   $0xc0106c79,0xc(%esp)
c0104b3f:	c0 
c0104b40:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104b47:	c0 
c0104b48:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
c0104b4f:	00 
c0104b50:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104b57:	e8 8d b8 ff ff       	call   c01003e9 <__panic>

    assert(alloc_page() == NULL);
c0104b5c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104b63:	e8 25 df ff ff       	call   c0102a8d <alloc_pages>
c0104b68:	85 c0                	test   %eax,%eax
c0104b6a:	74 24                	je     c0104b90 <basic_check+0x3fb>
c0104b6c:	c7 44 24 0c 66 6d 10 	movl   $0xc0106d66,0xc(%esp)
c0104b73:	c0 
c0104b74:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104b7b:	c0 
c0104b7c:	c7 44 24 04 39 01 00 	movl   $0x139,0x4(%esp)
c0104b83:	00 
c0104b84:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104b8b:	e8 59 b8 ff ff       	call   c01003e9 <__panic>

    free_page(p0);
c0104b90:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104b97:	00 
c0104b98:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104b9b:	89 04 24             	mov    %eax,(%esp)
c0104b9e:	e8 22 df ff ff       	call   c0102ac5 <free_pages>
c0104ba3:	c7 45 e8 1c af 11 c0 	movl   $0xc011af1c,-0x18(%ebp)
c0104baa:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0104bad:	8b 40 04             	mov    0x4(%eax),%eax
c0104bb0:	39 45 e8             	cmp    %eax,-0x18(%ebp)
c0104bb3:	0f 94 c0             	sete   %al
c0104bb6:	0f b6 c0             	movzbl %al,%eax
    assert(!list_empty(&free_list));
c0104bb9:	85 c0                	test   %eax,%eax
c0104bbb:	74 24                	je     c0104be1 <basic_check+0x44c>
c0104bbd:	c7 44 24 0c 88 6d 10 	movl   $0xc0106d88,0xc(%esp)
c0104bc4:	c0 
c0104bc5:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104bcc:	c0 
c0104bcd:	c7 44 24 04 3c 01 00 	movl   $0x13c,0x4(%esp)
c0104bd4:	00 
c0104bd5:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104bdc:	e8 08 b8 ff ff       	call   c01003e9 <__panic>

    struct Page *p;
    assert((p = alloc_page()) == p0);
c0104be1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104be8:	e8 a0 de ff ff       	call   c0102a8d <alloc_pages>
c0104bed:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104bf0:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104bf3:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0104bf6:	74 24                	je     c0104c1c <basic_check+0x487>
c0104bf8:	c7 44 24 0c a0 6d 10 	movl   $0xc0106da0,0xc(%esp)
c0104bff:	c0 
c0104c00:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104c07:	c0 
c0104c08:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
c0104c0f:	00 
c0104c10:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104c17:	e8 cd b7 ff ff       	call   c01003e9 <__panic>
    assert(alloc_page() == NULL);
c0104c1c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104c23:	e8 65 de ff ff       	call   c0102a8d <alloc_pages>
c0104c28:	85 c0                	test   %eax,%eax
c0104c2a:	74 24                	je     c0104c50 <basic_check+0x4bb>
c0104c2c:	c7 44 24 0c 66 6d 10 	movl   $0xc0106d66,0xc(%esp)
c0104c33:	c0 
c0104c34:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104c3b:	c0 
c0104c3c:	c7 44 24 04 40 01 00 	movl   $0x140,0x4(%esp)
c0104c43:	00 
c0104c44:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104c4b:	e8 99 b7 ff ff       	call   c01003e9 <__panic>

    assert(nr_free == 0);
c0104c50:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104c55:	85 c0                	test   %eax,%eax
c0104c57:	74 24                	je     c0104c7d <basic_check+0x4e8>
c0104c59:	c7 44 24 0c b9 6d 10 	movl   $0xc0106db9,0xc(%esp)
c0104c60:	c0 
c0104c61:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104c68:	c0 
c0104c69:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
c0104c70:	00 
c0104c71:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104c78:	e8 6c b7 ff ff       	call   c01003e9 <__panic>
    free_list = free_list_store;
c0104c7d:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104c80:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104c83:	a3 1c af 11 c0       	mov    %eax,0xc011af1c
c0104c88:	89 15 20 af 11 c0    	mov    %edx,0xc011af20
    nr_free = nr_free_store;
c0104c8e:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0104c91:	a3 24 af 11 c0       	mov    %eax,0xc011af24

    free_page(p);
c0104c96:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104c9d:	00 
c0104c9e:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104ca1:	89 04 24             	mov    %eax,(%esp)
c0104ca4:	e8 1c de ff ff       	call   c0102ac5 <free_pages>
    free_page(p1);
c0104ca9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104cb0:	00 
c0104cb1:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104cb4:	89 04 24             	mov    %eax,(%esp)
c0104cb7:	e8 09 de ff ff       	call   c0102ac5 <free_pages>
    free_page(p2);
c0104cbc:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104cc3:	00 
c0104cc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104cc7:	89 04 24             	mov    %eax,(%esp)
c0104cca:	e8 f6 dd ff ff       	call   c0102ac5 <free_pages>
}
c0104ccf:	90                   	nop
c0104cd0:	c9                   	leave  
c0104cd1:	c3                   	ret    

c0104cd2 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
c0104cd2:	55                   	push   %ebp
c0104cd3:	89 e5                	mov    %esp,%ebp
c0104cd5:	81 ec 98 00 00 00    	sub    $0x98,%esp
    int count = 0, total = 0;
c0104cdb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0104ce2:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    list_entry_t *le = &free_list;
c0104ce9:	c7 45 ec 1c af 11 c0 	movl   $0xc011af1c,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
c0104cf0:	eb 6a                	jmp    c0104d5c <default_check+0x8a>
        struct Page *p = le2page(le, page_link);
c0104cf2:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104cf5:	83 e8 0c             	sub    $0xc,%eax
c0104cf8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        assert(PageProperty(p));
c0104cfb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104cfe:	83 c0 04             	add    $0x4,%eax
c0104d01:	c7 45 b0 01 00 00 00 	movl   $0x1,-0x50(%ebp)
c0104d08:	89 45 ac             	mov    %eax,-0x54(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104d0b:	8b 45 ac             	mov    -0x54(%ebp),%eax
c0104d0e:	8b 55 b0             	mov    -0x50(%ebp),%edx
c0104d11:	0f a3 10             	bt     %edx,(%eax)
c0104d14:	19 c0                	sbb    %eax,%eax
c0104d16:	89 45 a8             	mov    %eax,-0x58(%ebp)
    return oldbit != 0;
c0104d19:	83 7d a8 00          	cmpl   $0x0,-0x58(%ebp)
c0104d1d:	0f 95 c0             	setne  %al
c0104d20:	0f b6 c0             	movzbl %al,%eax
c0104d23:	85 c0                	test   %eax,%eax
c0104d25:	75 24                	jne    c0104d4b <default_check+0x79>
c0104d27:	c7 44 24 0c c6 6d 10 	movl   $0xc0106dc6,0xc(%esp)
c0104d2e:	c0 
c0104d2f:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104d36:	c0 
c0104d37:	c7 44 24 04 53 01 00 	movl   $0x153,0x4(%esp)
c0104d3e:	00 
c0104d3f:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104d46:	e8 9e b6 ff ff       	call   c01003e9 <__panic>
        count ++, total += p->property;
c0104d4b:	ff 45 f4             	incl   -0xc(%ebp)
c0104d4e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104d51:	8b 50 08             	mov    0x8(%eax),%edx
c0104d54:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104d57:	01 d0                	add    %edx,%eax
c0104d59:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104d5c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104d5f:	89 45 e0             	mov    %eax,-0x20(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0104d62:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0104d65:	8b 40 04             	mov    0x4(%eax),%eax
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c0104d68:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0104d6b:	81 7d ec 1c af 11 c0 	cmpl   $0xc011af1c,-0x14(%ebp)
c0104d72:	0f 85 7a ff ff ff    	jne    c0104cf2 <default_check+0x20>
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());
c0104d78:	e8 7b dd ff ff       	call   c0102af8 <nr_free_pages>
c0104d7d:	89 c2                	mov    %eax,%edx
c0104d7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104d82:	39 c2                	cmp    %eax,%edx
c0104d84:	74 24                	je     c0104daa <default_check+0xd8>
c0104d86:	c7 44 24 0c d6 6d 10 	movl   $0xc0106dd6,0xc(%esp)
c0104d8d:	c0 
c0104d8e:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104d95:	c0 
c0104d96:	c7 44 24 04 56 01 00 	movl   $0x156,0x4(%esp)
c0104d9d:	00 
c0104d9e:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104da5:	e8 3f b6 ff ff       	call   c01003e9 <__panic>

    basic_check();
c0104daa:	e8 e6 f9 ff ff       	call   c0104795 <basic_check>

    struct Page *p0 = alloc_pages(5), *p1, *p2;
c0104daf:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
c0104db6:	e8 d2 dc ff ff       	call   c0102a8d <alloc_pages>
c0104dbb:	89 45 dc             	mov    %eax,-0x24(%ebp)
    assert(p0 != NULL);
c0104dbe:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0104dc2:	75 24                	jne    c0104de8 <default_check+0x116>
c0104dc4:	c7 44 24 0c ef 6d 10 	movl   $0xc0106def,0xc(%esp)
c0104dcb:	c0 
c0104dcc:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104dd3:	c0 
c0104dd4:	c7 44 24 04 5b 01 00 	movl   $0x15b,0x4(%esp)
c0104ddb:	00 
c0104ddc:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104de3:	e8 01 b6 ff ff       	call   c01003e9 <__panic>
    assert(!PageProperty(p0));
c0104de8:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104deb:	83 c0 04             	add    $0x4,%eax
c0104dee:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
c0104df5:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104df8:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0104dfb:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0104dfe:	0f a3 10             	bt     %edx,(%eax)
c0104e01:	19 c0                	sbb    %eax,%eax
c0104e03:	89 45 a0             	mov    %eax,-0x60(%ebp)
    return oldbit != 0;
c0104e06:	83 7d a0 00          	cmpl   $0x0,-0x60(%ebp)
c0104e0a:	0f 95 c0             	setne  %al
c0104e0d:	0f b6 c0             	movzbl %al,%eax
c0104e10:	85 c0                	test   %eax,%eax
c0104e12:	74 24                	je     c0104e38 <default_check+0x166>
c0104e14:	c7 44 24 0c fa 6d 10 	movl   $0xc0106dfa,0xc(%esp)
c0104e1b:	c0 
c0104e1c:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104e23:	c0 
c0104e24:	c7 44 24 04 5c 01 00 	movl   $0x15c,0x4(%esp)
c0104e2b:	00 
c0104e2c:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104e33:	e8 b1 b5 ff ff       	call   c01003e9 <__panic>

    list_entry_t free_list_store = free_list;
c0104e38:	a1 1c af 11 c0       	mov    0xc011af1c,%eax
c0104e3d:	8b 15 20 af 11 c0    	mov    0xc011af20,%edx
c0104e43:	89 45 80             	mov    %eax,-0x80(%ebp)
c0104e46:	89 55 84             	mov    %edx,-0x7c(%ebp)
c0104e49:	c7 45 d0 1c af 11 c0 	movl   $0xc011af1c,-0x30(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c0104e50:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104e53:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0104e56:	89 50 04             	mov    %edx,0x4(%eax)
c0104e59:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104e5c:	8b 50 04             	mov    0x4(%eax),%edx
c0104e5f:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104e62:	89 10                	mov    %edx,(%eax)
c0104e64:	c7 45 d8 1c af 11 c0 	movl   $0xc011af1c,-0x28(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
c0104e6b:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104e6e:	8b 40 04             	mov    0x4(%eax),%eax
c0104e71:	39 45 d8             	cmp    %eax,-0x28(%ebp)
c0104e74:	0f 94 c0             	sete   %al
c0104e77:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
c0104e7a:	85 c0                	test   %eax,%eax
c0104e7c:	75 24                	jne    c0104ea2 <default_check+0x1d0>
c0104e7e:	c7 44 24 0c 4f 6d 10 	movl   $0xc0106d4f,0xc(%esp)
c0104e85:	c0 
c0104e86:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104e8d:	c0 
c0104e8e:	c7 44 24 04 60 01 00 	movl   $0x160,0x4(%esp)
c0104e95:	00 
c0104e96:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104e9d:	e8 47 b5 ff ff       	call   c01003e9 <__panic>
    assert(alloc_page() == NULL);
c0104ea2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104ea9:	e8 df db ff ff       	call   c0102a8d <alloc_pages>
c0104eae:	85 c0                	test   %eax,%eax
c0104eb0:	74 24                	je     c0104ed6 <default_check+0x204>
c0104eb2:	c7 44 24 0c 66 6d 10 	movl   $0xc0106d66,0xc(%esp)
c0104eb9:	c0 
c0104eba:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104ec1:	c0 
c0104ec2:	c7 44 24 04 61 01 00 	movl   $0x161,0x4(%esp)
c0104ec9:	00 
c0104eca:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104ed1:	e8 13 b5 ff ff       	call   c01003e9 <__panic>

    unsigned int nr_free_store = nr_free;
c0104ed6:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104edb:	89 45 cc             	mov    %eax,-0x34(%ebp)
    nr_free = 0;
c0104ede:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c0104ee5:	00 00 00 

    free_pages(p0 + 2, 3);
c0104ee8:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104eeb:	83 c0 28             	add    $0x28,%eax
c0104eee:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
c0104ef5:	00 
c0104ef6:	89 04 24             	mov    %eax,(%esp)
c0104ef9:	e8 c7 db ff ff       	call   c0102ac5 <free_pages>
    assert(alloc_pages(4) == NULL);
c0104efe:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
c0104f05:	e8 83 db ff ff       	call   c0102a8d <alloc_pages>
c0104f0a:	85 c0                	test   %eax,%eax
c0104f0c:	74 24                	je     c0104f32 <default_check+0x260>
c0104f0e:	c7 44 24 0c 0c 6e 10 	movl   $0xc0106e0c,0xc(%esp)
c0104f15:	c0 
c0104f16:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104f1d:	c0 
c0104f1e:	c7 44 24 04 67 01 00 	movl   $0x167,0x4(%esp)
c0104f25:	00 
c0104f26:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104f2d:	e8 b7 b4 ff ff       	call   c01003e9 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
c0104f32:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104f35:	83 c0 28             	add    $0x28,%eax
c0104f38:	83 c0 04             	add    $0x4,%eax
c0104f3b:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
c0104f42:	89 45 9c             	mov    %eax,-0x64(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104f45:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0104f48:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104f4b:	0f a3 10             	bt     %edx,(%eax)
c0104f4e:	19 c0                	sbb    %eax,%eax
c0104f50:	89 45 98             	mov    %eax,-0x68(%ebp)
    return oldbit != 0;
c0104f53:	83 7d 98 00          	cmpl   $0x0,-0x68(%ebp)
c0104f57:	0f 95 c0             	setne  %al
c0104f5a:	0f b6 c0             	movzbl %al,%eax
c0104f5d:	85 c0                	test   %eax,%eax
c0104f5f:	74 0e                	je     c0104f6f <default_check+0x29d>
c0104f61:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104f64:	83 c0 28             	add    $0x28,%eax
c0104f67:	8b 40 08             	mov    0x8(%eax),%eax
c0104f6a:	83 f8 03             	cmp    $0x3,%eax
c0104f6d:	74 24                	je     c0104f93 <default_check+0x2c1>
c0104f6f:	c7 44 24 0c 24 6e 10 	movl   $0xc0106e24,0xc(%esp)
c0104f76:	c0 
c0104f77:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104f7e:	c0 
c0104f7f:	c7 44 24 04 68 01 00 	movl   $0x168,0x4(%esp)
c0104f86:	00 
c0104f87:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104f8e:	e8 56 b4 ff ff       	call   c01003e9 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
c0104f93:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
c0104f9a:	e8 ee da ff ff       	call   c0102a8d <alloc_pages>
c0104f9f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
c0104fa2:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
c0104fa6:	75 24                	jne    c0104fcc <default_check+0x2fa>
c0104fa8:	c7 44 24 0c 50 6e 10 	movl   $0xc0106e50,0xc(%esp)
c0104faf:	c0 
c0104fb0:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104fb7:	c0 
c0104fb8:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
c0104fbf:	00 
c0104fc0:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104fc7:	e8 1d b4 ff ff       	call   c01003e9 <__panic>
    assert(alloc_page() == NULL);
c0104fcc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104fd3:	e8 b5 da ff ff       	call   c0102a8d <alloc_pages>
c0104fd8:	85 c0                	test   %eax,%eax
c0104fda:	74 24                	je     c0105000 <default_check+0x32e>
c0104fdc:	c7 44 24 0c 66 6d 10 	movl   $0xc0106d66,0xc(%esp)
c0104fe3:	c0 
c0104fe4:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0104feb:	c0 
c0104fec:	c7 44 24 04 6a 01 00 	movl   $0x16a,0x4(%esp)
c0104ff3:	00 
c0104ff4:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0104ffb:	e8 e9 b3 ff ff       	call   c01003e9 <__panic>
    assert(p0 + 2 == p1);
c0105000:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105003:	83 c0 28             	add    $0x28,%eax
c0105006:	3b 45 c4             	cmp    -0x3c(%ebp),%eax
c0105009:	74 24                	je     c010502f <default_check+0x35d>
c010500b:	c7 44 24 0c 6e 6e 10 	movl   $0xc0106e6e,0xc(%esp)
c0105012:	c0 
c0105013:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c010501a:	c0 
c010501b:	c7 44 24 04 6b 01 00 	movl   $0x16b,0x4(%esp)
c0105022:	00 
c0105023:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c010502a:	e8 ba b3 ff ff       	call   c01003e9 <__panic>

    p2 = p0 + 1;
c010502f:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105032:	83 c0 14             	add    $0x14,%eax
c0105035:	89 45 c0             	mov    %eax,-0x40(%ebp)
    free_page(p0);
c0105038:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c010503f:	00 
c0105040:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105043:	89 04 24             	mov    %eax,(%esp)
c0105046:	e8 7a da ff ff       	call   c0102ac5 <free_pages>
    free_pages(p1, 3);
c010504b:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
c0105052:	00 
c0105053:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0105056:	89 04 24             	mov    %eax,(%esp)
c0105059:	e8 67 da ff ff       	call   c0102ac5 <free_pages>
    assert(PageProperty(p0) && p0->property == 1);
c010505e:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105061:	83 c0 04             	add    $0x4,%eax
c0105064:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
c010506b:	89 45 94             	mov    %eax,-0x6c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c010506e:	8b 45 94             	mov    -0x6c(%ebp),%eax
c0105071:	8b 55 c8             	mov    -0x38(%ebp),%edx
c0105074:	0f a3 10             	bt     %edx,(%eax)
c0105077:	19 c0                	sbb    %eax,%eax
c0105079:	89 45 90             	mov    %eax,-0x70(%ebp)
    return oldbit != 0;
c010507c:	83 7d 90 00          	cmpl   $0x0,-0x70(%ebp)
c0105080:	0f 95 c0             	setne  %al
c0105083:	0f b6 c0             	movzbl %al,%eax
c0105086:	85 c0                	test   %eax,%eax
c0105088:	74 0b                	je     c0105095 <default_check+0x3c3>
c010508a:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010508d:	8b 40 08             	mov    0x8(%eax),%eax
c0105090:	83 f8 01             	cmp    $0x1,%eax
c0105093:	74 24                	je     c01050b9 <default_check+0x3e7>
c0105095:	c7 44 24 0c 7c 6e 10 	movl   $0xc0106e7c,0xc(%esp)
c010509c:	c0 
c010509d:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c01050a4:	c0 
c01050a5:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
c01050ac:	00 
c01050ad:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c01050b4:	e8 30 b3 ff ff       	call   c01003e9 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
c01050b9:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c01050bc:	83 c0 04             	add    $0x4,%eax
c01050bf:	c7 45 bc 01 00 00 00 	movl   $0x1,-0x44(%ebp)
c01050c6:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c01050c9:	8b 45 8c             	mov    -0x74(%ebp),%eax
c01050cc:	8b 55 bc             	mov    -0x44(%ebp),%edx
c01050cf:	0f a3 10             	bt     %edx,(%eax)
c01050d2:	19 c0                	sbb    %eax,%eax
c01050d4:	89 45 88             	mov    %eax,-0x78(%ebp)
    return oldbit != 0;
c01050d7:	83 7d 88 00          	cmpl   $0x0,-0x78(%ebp)
c01050db:	0f 95 c0             	setne  %al
c01050de:	0f b6 c0             	movzbl %al,%eax
c01050e1:	85 c0                	test   %eax,%eax
c01050e3:	74 0b                	je     c01050f0 <default_check+0x41e>
c01050e5:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c01050e8:	8b 40 08             	mov    0x8(%eax),%eax
c01050eb:	83 f8 03             	cmp    $0x3,%eax
c01050ee:	74 24                	je     c0105114 <default_check+0x442>
c01050f0:	c7 44 24 0c a4 6e 10 	movl   $0xc0106ea4,0xc(%esp)
c01050f7:	c0 
c01050f8:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c01050ff:	c0 
c0105100:	c7 44 24 04 71 01 00 	movl   $0x171,0x4(%esp)
c0105107:	00 
c0105108:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c010510f:	e8 d5 b2 ff ff       	call   c01003e9 <__panic>

    assert((p0 = alloc_page()) == p2 - 1);
c0105114:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010511b:	e8 6d d9 ff ff       	call   c0102a8d <alloc_pages>
c0105120:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0105123:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0105126:	83 e8 14             	sub    $0x14,%eax
c0105129:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c010512c:	74 24                	je     c0105152 <default_check+0x480>
c010512e:	c7 44 24 0c ca 6e 10 	movl   $0xc0106eca,0xc(%esp)
c0105135:	c0 
c0105136:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c010513d:	c0 
c010513e:	c7 44 24 04 73 01 00 	movl   $0x173,0x4(%esp)
c0105145:	00 
c0105146:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c010514d:	e8 97 b2 ff ff       	call   c01003e9 <__panic>
    free_page(p0);
c0105152:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0105159:	00 
c010515a:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010515d:	89 04 24             	mov    %eax,(%esp)
c0105160:	e8 60 d9 ff ff       	call   c0102ac5 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
c0105165:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
c010516c:	e8 1c d9 ff ff       	call   c0102a8d <alloc_pages>
c0105171:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0105174:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0105177:	83 c0 14             	add    $0x14,%eax
c010517a:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c010517d:	74 24                	je     c01051a3 <default_check+0x4d1>
c010517f:	c7 44 24 0c e8 6e 10 	movl   $0xc0106ee8,0xc(%esp)
c0105186:	c0 
c0105187:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c010518e:	c0 
c010518f:	c7 44 24 04 75 01 00 	movl   $0x175,0x4(%esp)
c0105196:	00 
c0105197:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c010519e:	e8 46 b2 ff ff       	call   c01003e9 <__panic>

    free_pages(p0, 2);
c01051a3:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
c01051aa:	00 
c01051ab:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01051ae:	89 04 24             	mov    %eax,(%esp)
c01051b1:	e8 0f d9 ff ff       	call   c0102ac5 <free_pages>
    free_page(p2);
c01051b6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c01051bd:	00 
c01051be:	8b 45 c0             	mov    -0x40(%ebp),%eax
c01051c1:	89 04 24             	mov    %eax,(%esp)
c01051c4:	e8 fc d8 ff ff       	call   c0102ac5 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
c01051c9:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
c01051d0:	e8 b8 d8 ff ff       	call   c0102a8d <alloc_pages>
c01051d5:	89 45 dc             	mov    %eax,-0x24(%ebp)
c01051d8:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c01051dc:	75 24                	jne    c0105202 <default_check+0x530>
c01051de:	c7 44 24 0c 08 6f 10 	movl   $0xc0106f08,0xc(%esp)
c01051e5:	c0 
c01051e6:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c01051ed:	c0 
c01051ee:	c7 44 24 04 7a 01 00 	movl   $0x17a,0x4(%esp)
c01051f5:	00 
c01051f6:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c01051fd:	e8 e7 b1 ff ff       	call   c01003e9 <__panic>
    assert(alloc_page() == NULL);
c0105202:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0105209:	e8 7f d8 ff ff       	call   c0102a8d <alloc_pages>
c010520e:	85 c0                	test   %eax,%eax
c0105210:	74 24                	je     c0105236 <default_check+0x564>
c0105212:	c7 44 24 0c 66 6d 10 	movl   $0xc0106d66,0xc(%esp)
c0105219:	c0 
c010521a:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0105221:	c0 
c0105222:	c7 44 24 04 7b 01 00 	movl   $0x17b,0x4(%esp)
c0105229:	00 
c010522a:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0105231:	e8 b3 b1 ff ff       	call   c01003e9 <__panic>

    assert(nr_free == 0);
c0105236:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c010523b:	85 c0                	test   %eax,%eax
c010523d:	74 24                	je     c0105263 <default_check+0x591>
c010523f:	c7 44 24 0c b9 6d 10 	movl   $0xc0106db9,0xc(%esp)
c0105246:	c0 
c0105247:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c010524e:	c0 
c010524f:	c7 44 24 04 7d 01 00 	movl   $0x17d,0x4(%esp)
c0105256:	00 
c0105257:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c010525e:	e8 86 b1 ff ff       	call   c01003e9 <__panic>
    nr_free = nr_free_store;
c0105263:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0105266:	a3 24 af 11 c0       	mov    %eax,0xc011af24

    free_list = free_list_store;
c010526b:	8b 45 80             	mov    -0x80(%ebp),%eax
c010526e:	8b 55 84             	mov    -0x7c(%ebp),%edx
c0105271:	a3 1c af 11 c0       	mov    %eax,0xc011af1c
c0105276:	89 15 20 af 11 c0    	mov    %edx,0xc011af20
    free_pages(p0, 5);
c010527c:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
c0105283:	00 
c0105284:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105287:	89 04 24             	mov    %eax,(%esp)
c010528a:	e8 36 d8 ff ff       	call   c0102ac5 <free_pages>

    le = &free_list;
c010528f:	c7 45 ec 1c af 11 c0 	movl   $0xc011af1c,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
c0105296:	eb 5a                	jmp    c01052f2 <default_check+0x620>
        assert(le->next->prev == le && le->prev->next == le);
c0105298:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010529b:	8b 40 04             	mov    0x4(%eax),%eax
c010529e:	8b 00                	mov    (%eax),%eax
c01052a0:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c01052a3:	75 0d                	jne    c01052b2 <default_check+0x5e0>
c01052a5:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01052a8:	8b 00                	mov    (%eax),%eax
c01052aa:	8b 40 04             	mov    0x4(%eax),%eax
c01052ad:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c01052b0:	74 24                	je     c01052d6 <default_check+0x604>
c01052b2:	c7 44 24 0c 28 6f 10 	movl   $0xc0106f28,0xc(%esp)
c01052b9:	c0 
c01052ba:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c01052c1:	c0 
c01052c2:	c7 44 24 04 85 01 00 	movl   $0x185,0x4(%esp)
c01052c9:	00 
c01052ca:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c01052d1:	e8 13 b1 ff ff       	call   c01003e9 <__panic>
        struct Page *p = le2page(le, page_link);
c01052d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01052d9:	83 e8 0c             	sub    $0xc,%eax
c01052dc:	89 45 b4             	mov    %eax,-0x4c(%ebp)
        count --, total -= p->property;
c01052df:	ff 4d f4             	decl   -0xc(%ebp)
c01052e2:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01052e5:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c01052e8:	8b 40 08             	mov    0x8(%eax),%eax
c01052eb:	29 c2                	sub    %eax,%edx
c01052ed:	89 d0                	mov    %edx,%eax
c01052ef:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01052f2:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01052f5:	89 45 b8             	mov    %eax,-0x48(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c01052f8:	8b 45 b8             	mov    -0x48(%ebp),%eax
c01052fb:	8b 40 04             	mov    0x4(%eax),%eax

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c01052fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105301:	81 7d ec 1c af 11 c0 	cmpl   $0xc011af1c,-0x14(%ebp)
c0105308:	75 8e                	jne    c0105298 <default_check+0x5c6>
        assert(le->next->prev == le && le->prev->next == le);
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
c010530a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c010530e:	74 24                	je     c0105334 <default_check+0x662>
c0105310:	c7 44 24 0c 55 6f 10 	movl   $0xc0106f55,0xc(%esp)
c0105317:	c0 
c0105318:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c010531f:	c0 
c0105320:	c7 44 24 04 89 01 00 	movl   $0x189,0x4(%esp)
c0105327:	00 
c0105328:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c010532f:	e8 b5 b0 ff ff       	call   c01003e9 <__panic>
    assert(total == 0);
c0105334:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0105338:	74 24                	je     c010535e <default_check+0x68c>
c010533a:	c7 44 24 0c 60 6f 10 	movl   $0xc0106f60,0xc(%esp)
c0105341:	c0 
c0105342:	c7 44 24 08 de 6b 10 	movl   $0xc0106bde,0x8(%esp)
c0105349:	c0 
c010534a:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
c0105351:	00 
c0105352:	c7 04 24 f3 6b 10 c0 	movl   $0xc0106bf3,(%esp)
c0105359:	e8 8b b0 ff ff       	call   c01003e9 <__panic>
}
c010535e:	90                   	nop
c010535f:	c9                   	leave  
c0105360:	c3                   	ret    

c0105361 <strlen>:
 * @s:      the input string
 *
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
c0105361:	55                   	push   %ebp
c0105362:	89 e5                	mov    %esp,%ebp
c0105364:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
c0105367:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (*s ++ != '\0') {
c010536e:	eb 03                	jmp    c0105373 <strlen+0x12>
        cnt ++;
c0105370:	ff 45 fc             	incl   -0x4(%ebp)
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
c0105373:	8b 45 08             	mov    0x8(%ebp),%eax
c0105376:	8d 50 01             	lea    0x1(%eax),%edx
c0105379:	89 55 08             	mov    %edx,0x8(%ebp)
c010537c:	0f b6 00             	movzbl (%eax),%eax
c010537f:	84 c0                	test   %al,%al
c0105381:	75 ed                	jne    c0105370 <strlen+0xf>
        cnt ++;
    }
    return cnt;
c0105383:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0105386:	c9                   	leave  
c0105387:	c3                   	ret    

c0105388 <strnlen>:
 * The return value is strlen(s), if that is less than @len, or
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
c0105388:	55                   	push   %ebp
c0105389:	89 e5                	mov    %esp,%ebp
c010538b:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
c010538e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (cnt < len && *s ++ != '\0') {
c0105395:	eb 03                	jmp    c010539a <strnlen+0x12>
        cnt ++;
c0105397:	ff 45 fc             	incl   -0x4(%ebp)
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
c010539a:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010539d:	3b 45 0c             	cmp    0xc(%ebp),%eax
c01053a0:	73 10                	jae    c01053b2 <strnlen+0x2a>
c01053a2:	8b 45 08             	mov    0x8(%ebp),%eax
c01053a5:	8d 50 01             	lea    0x1(%eax),%edx
c01053a8:	89 55 08             	mov    %edx,0x8(%ebp)
c01053ab:	0f b6 00             	movzbl (%eax),%eax
c01053ae:	84 c0                	test   %al,%al
c01053b0:	75 e5                	jne    c0105397 <strnlen+0xf>
        cnt ++;
    }
    return cnt;
c01053b2:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c01053b5:	c9                   	leave  
c01053b6:	c3                   	ret    

c01053b7 <strcpy>:
 * To avoid overflows, the size of array pointed by @dst should be long enough to
 * contain the same string as @src (including the terminating null character), and
 * should not overlap in memory with @src.
 * */
char *
strcpy(char *dst, const char *src) {
c01053b7:	55                   	push   %ebp
c01053b8:	89 e5                	mov    %esp,%ebp
c01053ba:	57                   	push   %edi
c01053bb:	56                   	push   %esi
c01053bc:	83 ec 20             	sub    $0x20,%esp
c01053bf:	8b 45 08             	mov    0x8(%ebp),%eax
c01053c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01053c5:	8b 45 0c             	mov    0xc(%ebp),%eax
c01053c8:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCPY
#define __HAVE_ARCH_STRCPY
static inline char *
__strcpy(char *dst, const char *src) {
    int d0, d1, d2;
    asm volatile (
c01053cb:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01053ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01053d1:	89 d1                	mov    %edx,%ecx
c01053d3:	89 c2                	mov    %eax,%edx
c01053d5:	89 ce                	mov    %ecx,%esi
c01053d7:	89 d7                	mov    %edx,%edi
c01053d9:	ac                   	lods   %ds:(%esi),%al
c01053da:	aa                   	stos   %al,%es:(%edi)
c01053db:	84 c0                	test   %al,%al
c01053dd:	75 fa                	jne    c01053d9 <strcpy+0x22>
c01053df:	89 fa                	mov    %edi,%edx
c01053e1:	89 f1                	mov    %esi,%ecx
c01053e3:	89 4d ec             	mov    %ecx,-0x14(%ebp)
c01053e6:	89 55 e8             	mov    %edx,-0x18(%ebp)
c01053e9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        "stosb;"
        "testb %%al, %%al;"
        "jne 1b;"
        : "=&S" (d0), "=&D" (d1), "=&a" (d2)
        : "0" (src), "1" (dst) : "memory");
    return dst;
c01053ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
c01053ef:	90                   	nop
    char *p = dst;
    while ((*p ++ = *src ++) != '\0')
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
c01053f0:	83 c4 20             	add    $0x20,%esp
c01053f3:	5e                   	pop    %esi
c01053f4:	5f                   	pop    %edi
c01053f5:	5d                   	pop    %ebp
c01053f6:	c3                   	ret    

c01053f7 <strncpy>:
 * @len:    maximum number of characters to be copied from @src
 *
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
c01053f7:	55                   	push   %ebp
c01053f8:	89 e5                	mov    %esp,%ebp
c01053fa:	83 ec 10             	sub    $0x10,%esp
    char *p = dst;
c01053fd:	8b 45 08             	mov    0x8(%ebp),%eax
c0105400:	89 45 fc             	mov    %eax,-0x4(%ebp)
    while (len > 0) {
c0105403:	eb 1e                	jmp    c0105423 <strncpy+0x2c>
        if ((*p = *src) != '\0') {
c0105405:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105408:	0f b6 10             	movzbl (%eax),%edx
c010540b:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010540e:	88 10                	mov    %dl,(%eax)
c0105410:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0105413:	0f b6 00             	movzbl (%eax),%eax
c0105416:	84 c0                	test   %al,%al
c0105418:	74 03                	je     c010541d <strncpy+0x26>
            src ++;
c010541a:	ff 45 0c             	incl   0xc(%ebp)
        }
        p ++, len --;
c010541d:	ff 45 fc             	incl   -0x4(%ebp)
c0105420:	ff 4d 10             	decl   0x10(%ebp)
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
    char *p = dst;
    while (len > 0) {
c0105423:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0105427:	75 dc                	jne    c0105405 <strncpy+0xe>
        if ((*p = *src) != '\0') {
            src ++;
        }
        p ++, len --;
    }
    return dst;
c0105429:	8b 45 08             	mov    0x8(%ebp),%eax
}
c010542c:	c9                   	leave  
c010542d:	c3                   	ret    

c010542e <strcmp>:
 * - A value greater than zero indicates that the first character that does
 *   not match has a greater value in @s1 than in @s2;
 * - And a value less than zero indicates the opposite.
 * */
int
strcmp(const char *s1, const char *s2) {
c010542e:	55                   	push   %ebp
c010542f:	89 e5                	mov    %esp,%ebp
c0105431:	57                   	push   %edi
c0105432:	56                   	push   %esi
c0105433:	83 ec 20             	sub    $0x20,%esp
c0105436:	8b 45 08             	mov    0x8(%ebp),%eax
c0105439:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010543c:	8b 45 0c             	mov    0xc(%ebp),%eax
c010543f:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCMP
#define __HAVE_ARCH_STRCMP
static inline int
__strcmp(const char *s1, const char *s2) {
    int d0, d1, ret;
    asm volatile (
c0105442:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105445:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105448:	89 d1                	mov    %edx,%ecx
c010544a:	89 c2                	mov    %eax,%edx
c010544c:	89 ce                	mov    %ecx,%esi
c010544e:	89 d7                	mov    %edx,%edi
c0105450:	ac                   	lods   %ds:(%esi),%al
c0105451:	ae                   	scas   %es:(%edi),%al
c0105452:	75 08                	jne    c010545c <strcmp+0x2e>
c0105454:	84 c0                	test   %al,%al
c0105456:	75 f8                	jne    c0105450 <strcmp+0x22>
c0105458:	31 c0                	xor    %eax,%eax
c010545a:	eb 04                	jmp    c0105460 <strcmp+0x32>
c010545c:	19 c0                	sbb    %eax,%eax
c010545e:	0c 01                	or     $0x1,%al
c0105460:	89 fa                	mov    %edi,%edx
c0105462:	89 f1                	mov    %esi,%ecx
c0105464:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105467:	89 4d e8             	mov    %ecx,-0x18(%ebp)
c010546a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
        "orb $1, %%al;"
        "3:"
        : "=a" (ret), "=&S" (d0), "=&D" (d1)
        : "1" (s1), "2" (s2)
        : "memory");
    return ret;
c010546d:	8b 45 ec             	mov    -0x14(%ebp),%eax
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
c0105470:	90                   	nop
    while (*s1 != '\0' && *s1 == *s2) {
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
#endif /* __HAVE_ARCH_STRCMP */
}
c0105471:	83 c4 20             	add    $0x20,%esp
c0105474:	5e                   	pop    %esi
c0105475:	5f                   	pop    %edi
c0105476:	5d                   	pop    %ebp
c0105477:	c3                   	ret    

c0105478 <strncmp>:
 * they are equal to each other, it continues with the following pairs until
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
c0105478:	55                   	push   %ebp
c0105479:	89 e5                	mov    %esp,%ebp
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
c010547b:	eb 09                	jmp    c0105486 <strncmp+0xe>
        n --, s1 ++, s2 ++;
c010547d:	ff 4d 10             	decl   0x10(%ebp)
c0105480:	ff 45 08             	incl   0x8(%ebp)
c0105483:	ff 45 0c             	incl   0xc(%ebp)
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
c0105486:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c010548a:	74 1a                	je     c01054a6 <strncmp+0x2e>
c010548c:	8b 45 08             	mov    0x8(%ebp),%eax
c010548f:	0f b6 00             	movzbl (%eax),%eax
c0105492:	84 c0                	test   %al,%al
c0105494:	74 10                	je     c01054a6 <strncmp+0x2e>
c0105496:	8b 45 08             	mov    0x8(%ebp),%eax
c0105499:	0f b6 10             	movzbl (%eax),%edx
c010549c:	8b 45 0c             	mov    0xc(%ebp),%eax
c010549f:	0f b6 00             	movzbl (%eax),%eax
c01054a2:	38 c2                	cmp    %al,%dl
c01054a4:	74 d7                	je     c010547d <strncmp+0x5>
        n --, s1 ++, s2 ++;
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
c01054a6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01054aa:	74 18                	je     c01054c4 <strncmp+0x4c>
c01054ac:	8b 45 08             	mov    0x8(%ebp),%eax
c01054af:	0f b6 00             	movzbl (%eax),%eax
c01054b2:	0f b6 d0             	movzbl %al,%edx
c01054b5:	8b 45 0c             	mov    0xc(%ebp),%eax
c01054b8:	0f b6 00             	movzbl (%eax),%eax
c01054bb:	0f b6 c0             	movzbl %al,%eax
c01054be:	29 c2                	sub    %eax,%edx
c01054c0:	89 d0                	mov    %edx,%eax
c01054c2:	eb 05                	jmp    c01054c9 <strncmp+0x51>
c01054c4:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01054c9:	5d                   	pop    %ebp
c01054ca:	c3                   	ret    

c01054cb <strchr>:
 *
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
c01054cb:	55                   	push   %ebp
c01054cc:	89 e5                	mov    %esp,%ebp
c01054ce:	83 ec 04             	sub    $0x4,%esp
c01054d1:	8b 45 0c             	mov    0xc(%ebp),%eax
c01054d4:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
c01054d7:	eb 13                	jmp    c01054ec <strchr+0x21>
        if (*s == c) {
c01054d9:	8b 45 08             	mov    0x8(%ebp),%eax
c01054dc:	0f b6 00             	movzbl (%eax),%eax
c01054df:	3a 45 fc             	cmp    -0x4(%ebp),%al
c01054e2:	75 05                	jne    c01054e9 <strchr+0x1e>
            return (char *)s;
c01054e4:	8b 45 08             	mov    0x8(%ebp),%eax
c01054e7:	eb 12                	jmp    c01054fb <strchr+0x30>
        }
        s ++;
c01054e9:	ff 45 08             	incl   0x8(%ebp)
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
c01054ec:	8b 45 08             	mov    0x8(%ebp),%eax
c01054ef:	0f b6 00             	movzbl (%eax),%eax
c01054f2:	84 c0                	test   %al,%al
c01054f4:	75 e3                	jne    c01054d9 <strchr+0xe>
        if (*s == c) {
            return (char *)s;
        }
        s ++;
    }
    return NULL;
c01054f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01054fb:	c9                   	leave  
c01054fc:	c3                   	ret    

c01054fd <strfind>:
 * The strfind() function is like strchr() except that if @c is
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
c01054fd:	55                   	push   %ebp
c01054fe:	89 e5                	mov    %esp,%ebp
c0105500:	83 ec 04             	sub    $0x4,%esp
c0105503:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105506:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
c0105509:	eb 0e                	jmp    c0105519 <strfind+0x1c>
        if (*s == c) {
c010550b:	8b 45 08             	mov    0x8(%ebp),%eax
c010550e:	0f b6 00             	movzbl (%eax),%eax
c0105511:	3a 45 fc             	cmp    -0x4(%ebp),%al
c0105514:	74 0f                	je     c0105525 <strfind+0x28>
            break;
        }
        s ++;
c0105516:	ff 45 08             	incl   0x8(%ebp)
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
    while (*s != '\0') {
c0105519:	8b 45 08             	mov    0x8(%ebp),%eax
c010551c:	0f b6 00             	movzbl (%eax),%eax
c010551f:	84 c0                	test   %al,%al
c0105521:	75 e8                	jne    c010550b <strfind+0xe>
c0105523:	eb 01                	jmp    c0105526 <strfind+0x29>
        if (*s == c) {
            break;
c0105525:	90                   	nop
        }
        s ++;
    }
    return (char *)s;
c0105526:	8b 45 08             	mov    0x8(%ebp),%eax
}
c0105529:	c9                   	leave  
c010552a:	c3                   	ret    

c010552b <strtol>:
 * an optional "0x" or "0X" prefix.
 *
 * The strtol() function returns the converted integral number as a long int value.
 * */
long
strtol(const char *s, char **endptr, int base) {
c010552b:	55                   	push   %ebp
c010552c:	89 e5                	mov    %esp,%ebp
c010552e:	83 ec 10             	sub    $0x10,%esp
    int neg = 0;
c0105531:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    long val = 0;
c0105538:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
c010553f:	eb 03                	jmp    c0105544 <strtol+0x19>
        s ++;
c0105541:	ff 45 08             	incl   0x8(%ebp)
strtol(const char *s, char **endptr, int base) {
    int neg = 0;
    long val = 0;

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
c0105544:	8b 45 08             	mov    0x8(%ebp),%eax
c0105547:	0f b6 00             	movzbl (%eax),%eax
c010554a:	3c 20                	cmp    $0x20,%al
c010554c:	74 f3                	je     c0105541 <strtol+0x16>
c010554e:	8b 45 08             	mov    0x8(%ebp),%eax
c0105551:	0f b6 00             	movzbl (%eax),%eax
c0105554:	3c 09                	cmp    $0x9,%al
c0105556:	74 e9                	je     c0105541 <strtol+0x16>
        s ++;
    }

    // plus/minus sign
    if (*s == '+') {
c0105558:	8b 45 08             	mov    0x8(%ebp),%eax
c010555b:	0f b6 00             	movzbl (%eax),%eax
c010555e:	3c 2b                	cmp    $0x2b,%al
c0105560:	75 05                	jne    c0105567 <strtol+0x3c>
        s ++;
c0105562:	ff 45 08             	incl   0x8(%ebp)
c0105565:	eb 14                	jmp    c010557b <strtol+0x50>
    }
    else if (*s == '-') {
c0105567:	8b 45 08             	mov    0x8(%ebp),%eax
c010556a:	0f b6 00             	movzbl (%eax),%eax
c010556d:	3c 2d                	cmp    $0x2d,%al
c010556f:	75 0a                	jne    c010557b <strtol+0x50>
        s ++, neg = 1;
c0105571:	ff 45 08             	incl   0x8(%ebp)
c0105574:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)
    }

    // hex or octal base prefix
    if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x')) {
c010557b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c010557f:	74 06                	je     c0105587 <strtol+0x5c>
c0105581:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
c0105585:	75 22                	jne    c01055a9 <strtol+0x7e>
c0105587:	8b 45 08             	mov    0x8(%ebp),%eax
c010558a:	0f b6 00             	movzbl (%eax),%eax
c010558d:	3c 30                	cmp    $0x30,%al
c010558f:	75 18                	jne    c01055a9 <strtol+0x7e>
c0105591:	8b 45 08             	mov    0x8(%ebp),%eax
c0105594:	40                   	inc    %eax
c0105595:	0f b6 00             	movzbl (%eax),%eax
c0105598:	3c 78                	cmp    $0x78,%al
c010559a:	75 0d                	jne    c01055a9 <strtol+0x7e>
        s += 2, base = 16;
c010559c:	83 45 08 02          	addl   $0x2,0x8(%ebp)
c01055a0:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
c01055a7:	eb 29                	jmp    c01055d2 <strtol+0xa7>
    }
    else if (base == 0 && s[0] == '0') {
c01055a9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01055ad:	75 16                	jne    c01055c5 <strtol+0x9a>
c01055af:	8b 45 08             	mov    0x8(%ebp),%eax
c01055b2:	0f b6 00             	movzbl (%eax),%eax
c01055b5:	3c 30                	cmp    $0x30,%al
c01055b7:	75 0c                	jne    c01055c5 <strtol+0x9a>
        s ++, base = 8;
c01055b9:	ff 45 08             	incl   0x8(%ebp)
c01055bc:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
c01055c3:	eb 0d                	jmp    c01055d2 <strtol+0xa7>
    }
    else if (base == 0) {
c01055c5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01055c9:	75 07                	jne    c01055d2 <strtol+0xa7>
        base = 10;
c01055cb:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

    // digits
    while (1) {
        int dig;

        if (*s >= '0' && *s <= '9') {
c01055d2:	8b 45 08             	mov    0x8(%ebp),%eax
c01055d5:	0f b6 00             	movzbl (%eax),%eax
c01055d8:	3c 2f                	cmp    $0x2f,%al
c01055da:	7e 1b                	jle    c01055f7 <strtol+0xcc>
c01055dc:	8b 45 08             	mov    0x8(%ebp),%eax
c01055df:	0f b6 00             	movzbl (%eax),%eax
c01055e2:	3c 39                	cmp    $0x39,%al
c01055e4:	7f 11                	jg     c01055f7 <strtol+0xcc>
            dig = *s - '0';
c01055e6:	8b 45 08             	mov    0x8(%ebp),%eax
c01055e9:	0f b6 00             	movzbl (%eax),%eax
c01055ec:	0f be c0             	movsbl %al,%eax
c01055ef:	83 e8 30             	sub    $0x30,%eax
c01055f2:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01055f5:	eb 48                	jmp    c010563f <strtol+0x114>
        }
        else if (*s >= 'a' && *s <= 'z') {
c01055f7:	8b 45 08             	mov    0x8(%ebp),%eax
c01055fa:	0f b6 00             	movzbl (%eax),%eax
c01055fd:	3c 60                	cmp    $0x60,%al
c01055ff:	7e 1b                	jle    c010561c <strtol+0xf1>
c0105601:	8b 45 08             	mov    0x8(%ebp),%eax
c0105604:	0f b6 00             	movzbl (%eax),%eax
c0105607:	3c 7a                	cmp    $0x7a,%al
c0105609:	7f 11                	jg     c010561c <strtol+0xf1>
            dig = *s - 'a' + 10;
c010560b:	8b 45 08             	mov    0x8(%ebp),%eax
c010560e:	0f b6 00             	movzbl (%eax),%eax
c0105611:	0f be c0             	movsbl %al,%eax
c0105614:	83 e8 57             	sub    $0x57,%eax
c0105617:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010561a:	eb 23                	jmp    c010563f <strtol+0x114>
        }
        else if (*s >= 'A' && *s <= 'Z') {
c010561c:	8b 45 08             	mov    0x8(%ebp),%eax
c010561f:	0f b6 00             	movzbl (%eax),%eax
c0105622:	3c 40                	cmp    $0x40,%al
c0105624:	7e 3b                	jle    c0105661 <strtol+0x136>
c0105626:	8b 45 08             	mov    0x8(%ebp),%eax
c0105629:	0f b6 00             	movzbl (%eax),%eax
c010562c:	3c 5a                	cmp    $0x5a,%al
c010562e:	7f 31                	jg     c0105661 <strtol+0x136>
            dig = *s - 'A' + 10;
c0105630:	8b 45 08             	mov    0x8(%ebp),%eax
c0105633:	0f b6 00             	movzbl (%eax),%eax
c0105636:	0f be c0             	movsbl %al,%eax
c0105639:	83 e8 37             	sub    $0x37,%eax
c010563c:	89 45 f4             	mov    %eax,-0xc(%ebp)
        }
        else {
            break;
        }
        if (dig >= base) {
c010563f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105642:	3b 45 10             	cmp    0x10(%ebp),%eax
c0105645:	7d 19                	jge    c0105660 <strtol+0x135>
            break;
        }
        s ++, val = (val * base) + dig;
c0105647:	ff 45 08             	incl   0x8(%ebp)
c010564a:	8b 45 f8             	mov    -0x8(%ebp),%eax
c010564d:	0f af 45 10          	imul   0x10(%ebp),%eax
c0105651:	89 c2                	mov    %eax,%edx
c0105653:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105656:	01 d0                	add    %edx,%eax
c0105658:	89 45 f8             	mov    %eax,-0x8(%ebp)
        // we don't properly detect overflow!
    }
c010565b:	e9 72 ff ff ff       	jmp    c01055d2 <strtol+0xa7>
        }
        else {
            break;
        }
        if (dig >= base) {
            break;
c0105660:	90                   	nop
        }
        s ++, val = (val * base) + dig;
        // we don't properly detect overflow!
    }

    if (endptr) {
c0105661:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0105665:	74 08                	je     c010566f <strtol+0x144>
        *endptr = (char *) s;
c0105667:	8b 45 0c             	mov    0xc(%ebp),%eax
c010566a:	8b 55 08             	mov    0x8(%ebp),%edx
c010566d:	89 10                	mov    %edx,(%eax)
    }
    return (neg ? -val : val);
c010566f:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
c0105673:	74 07                	je     c010567c <strtol+0x151>
c0105675:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0105678:	f7 d8                	neg    %eax
c010567a:	eb 03                	jmp    c010567f <strtol+0x154>
c010567c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
c010567f:	c9                   	leave  
c0105680:	c3                   	ret    

c0105681 <memset>:
 * @n:      number of bytes to be set to the value
 *
 * The memset() function returns @s.
 * */
void *
memset(void *s, char c, size_t n) {
c0105681:	55                   	push   %ebp
c0105682:	89 e5                	mov    %esp,%ebp
c0105684:	57                   	push   %edi
c0105685:	83 ec 24             	sub    $0x24,%esp
c0105688:	8b 45 0c             	mov    0xc(%ebp),%eax
c010568b:	88 45 d8             	mov    %al,-0x28(%ebp)
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
c010568e:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
c0105692:	8b 55 08             	mov    0x8(%ebp),%edx
c0105695:	89 55 f8             	mov    %edx,-0x8(%ebp)
c0105698:	88 45 f7             	mov    %al,-0x9(%ebp)
c010569b:	8b 45 10             	mov    0x10(%ebp),%eax
c010569e:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_MEMSET
#define __HAVE_ARCH_MEMSET
static inline void *
__memset(void *s, char c, size_t n) {
    int d0, d1;
    asm volatile (
c01056a1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
c01056a4:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
c01056a8:	8b 55 f8             	mov    -0x8(%ebp),%edx
c01056ab:	89 d7                	mov    %edx,%edi
c01056ad:	f3 aa                	rep stos %al,%es:(%edi)
c01056af:	89 fa                	mov    %edi,%edx
c01056b1:	89 4d ec             	mov    %ecx,-0x14(%ebp)
c01056b4:	89 55 e8             	mov    %edx,-0x18(%ebp)
        "rep; stosb;"
        : "=&c" (d0), "=&D" (d1)
        : "0" (n), "a" (c), "1" (s)
        : "memory");
    return s;
c01056b7:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01056ba:	90                   	nop
    while (n -- > 0) {
        *p ++ = c;
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
c01056bb:	83 c4 24             	add    $0x24,%esp
c01056be:	5f                   	pop    %edi
c01056bf:	5d                   	pop    %ebp
c01056c0:	c3                   	ret    

c01056c1 <memmove>:
 * @n:      number of bytes to copy
 *
 * The memmove() function returns @dst.
 * */
void *
memmove(void *dst, const void *src, size_t n) {
c01056c1:	55                   	push   %ebp
c01056c2:	89 e5                	mov    %esp,%ebp
c01056c4:	57                   	push   %edi
c01056c5:	56                   	push   %esi
c01056c6:	53                   	push   %ebx
c01056c7:	83 ec 30             	sub    $0x30,%esp
c01056ca:	8b 45 08             	mov    0x8(%ebp),%eax
c01056cd:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01056d0:	8b 45 0c             	mov    0xc(%ebp),%eax
c01056d3:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01056d6:	8b 45 10             	mov    0x10(%ebp),%eax
c01056d9:	89 45 e8             	mov    %eax,-0x18(%ebp)

#ifndef __HAVE_ARCH_MEMMOVE
#define __HAVE_ARCH_MEMMOVE
static inline void *
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
c01056dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01056df:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c01056e2:	73 42                	jae    c0105726 <memmove+0x65>
c01056e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01056e7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01056ea:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01056ed:	89 45 e0             	mov    %eax,-0x20(%ebp)
c01056f0:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01056f3:	89 45 dc             	mov    %eax,-0x24(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c01056f6:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01056f9:	c1 e8 02             	shr    $0x2,%eax
c01056fc:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
c01056fe:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0105701:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105704:	89 d7                	mov    %edx,%edi
c0105706:	89 c6                	mov    %eax,%esi
c0105708:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c010570a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
c010570d:	83 e1 03             	and    $0x3,%ecx
c0105710:	74 02                	je     c0105714 <memmove+0x53>
c0105712:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c0105714:	89 f0                	mov    %esi,%eax
c0105716:	89 fa                	mov    %edi,%edx
c0105718:	89 4d d8             	mov    %ecx,-0x28(%ebp)
c010571b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c010571e:	89 45 d0             	mov    %eax,-0x30(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
c0105721:	8b 45 e4             	mov    -0x1c(%ebp),%eax
#ifdef __HAVE_ARCH_MEMMOVE
    return __memmove(dst, src, n);
c0105724:	eb 36                	jmp    c010575c <memmove+0x9b>
    asm volatile (
        "std;"
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
c0105726:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105729:	8d 50 ff             	lea    -0x1(%eax),%edx
c010572c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010572f:	01 c2                	add    %eax,%edx
c0105731:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105734:	8d 48 ff             	lea    -0x1(%eax),%ecx
c0105737:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010573a:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
        return __memcpy(dst, src, n);
    }
    int d0, d1, d2;
    asm volatile (
c010573d:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105740:	89 c1                	mov    %eax,%ecx
c0105742:	89 d8                	mov    %ebx,%eax
c0105744:	89 d6                	mov    %edx,%esi
c0105746:	89 c7                	mov    %eax,%edi
c0105748:	fd                   	std    
c0105749:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c010574b:	fc                   	cld    
c010574c:	89 f8                	mov    %edi,%eax
c010574e:	89 f2                	mov    %esi,%edx
c0105750:	89 4d cc             	mov    %ecx,-0x34(%ebp)
c0105753:	89 55 c8             	mov    %edx,-0x38(%ebp)
c0105756:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
        : "memory");
    return dst;
c0105759:	8b 45 f0             	mov    -0x10(%ebp),%eax
            *d ++ = *s ++;
        }
    }
    return dst;
#endif /* __HAVE_ARCH_MEMMOVE */
}
c010575c:	83 c4 30             	add    $0x30,%esp
c010575f:	5b                   	pop    %ebx
c0105760:	5e                   	pop    %esi
c0105761:	5f                   	pop    %edi
c0105762:	5d                   	pop    %ebp
c0105763:	c3                   	ret    

c0105764 <memcpy>:
 * it always copies exactly @n bytes. To avoid overflows, the size of arrays pointed
 * by both @src and @dst, should be at least @n bytes, and should not overlap
 * (for overlapping memory area, memmove is a safer approach).
 * */
void *
memcpy(void *dst, const void *src, size_t n) {
c0105764:	55                   	push   %ebp
c0105765:	89 e5                	mov    %esp,%ebp
c0105767:	57                   	push   %edi
c0105768:	56                   	push   %esi
c0105769:	83 ec 20             	sub    $0x20,%esp
c010576c:	8b 45 08             	mov    0x8(%ebp),%eax
c010576f:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105772:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105775:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105778:	8b 45 10             	mov    0x10(%ebp),%eax
c010577b:	89 45 ec             	mov    %eax,-0x14(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c010577e:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105781:	c1 e8 02             	shr    $0x2,%eax
c0105784:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
c0105786:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105789:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010578c:	89 d7                	mov    %edx,%edi
c010578e:	89 c6                	mov    %eax,%esi
c0105790:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c0105792:	8b 4d ec             	mov    -0x14(%ebp),%ecx
c0105795:	83 e1 03             	and    $0x3,%ecx
c0105798:	74 02                	je     c010579c <memcpy+0x38>
c010579a:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c010579c:	89 f0                	mov    %esi,%eax
c010579e:	89 fa                	mov    %edi,%edx
c01057a0:	89 4d e8             	mov    %ecx,-0x18(%ebp)
c01057a3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
c01057a6:	89 45 e0             	mov    %eax,-0x20(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
c01057a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
c01057ac:	90                   	nop
    while (n -- > 0) {
        *d ++ = *s ++;
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
c01057ad:	83 c4 20             	add    $0x20,%esp
c01057b0:	5e                   	pop    %esi
c01057b1:	5f                   	pop    %edi
c01057b2:	5d                   	pop    %ebp
c01057b3:	c3                   	ret    

c01057b4 <memcmp>:
 *   match in both memory blocks has a greater value in @v1 than in @v2
 *   as if evaluated as unsigned char values;
 * - And a value less than zero indicates the opposite.
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
c01057b4:	55                   	push   %ebp
c01057b5:	89 e5                	mov    %esp,%ebp
c01057b7:	83 ec 10             	sub    $0x10,%esp
    const char *s1 = (const char *)v1;
c01057ba:	8b 45 08             	mov    0x8(%ebp),%eax
c01057bd:	89 45 fc             	mov    %eax,-0x4(%ebp)
    const char *s2 = (const char *)v2;
c01057c0:	8b 45 0c             	mov    0xc(%ebp),%eax
c01057c3:	89 45 f8             	mov    %eax,-0x8(%ebp)
    while (n -- > 0) {
c01057c6:	eb 2e                	jmp    c01057f6 <memcmp+0x42>
        if (*s1 != *s2) {
c01057c8:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01057cb:	0f b6 10             	movzbl (%eax),%edx
c01057ce:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01057d1:	0f b6 00             	movzbl (%eax),%eax
c01057d4:	38 c2                	cmp    %al,%dl
c01057d6:	74 18                	je     c01057f0 <memcmp+0x3c>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
c01057d8:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01057db:	0f b6 00             	movzbl (%eax),%eax
c01057de:	0f b6 d0             	movzbl %al,%edx
c01057e1:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01057e4:	0f b6 00             	movzbl (%eax),%eax
c01057e7:	0f b6 c0             	movzbl %al,%eax
c01057ea:	29 c2                	sub    %eax,%edx
c01057ec:	89 d0                	mov    %edx,%eax
c01057ee:	eb 18                	jmp    c0105808 <memcmp+0x54>
        }
        s1 ++, s2 ++;
c01057f0:	ff 45 fc             	incl   -0x4(%ebp)
c01057f3:	ff 45 f8             	incl   -0x8(%ebp)
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
c01057f6:	8b 45 10             	mov    0x10(%ebp),%eax
c01057f9:	8d 50 ff             	lea    -0x1(%eax),%edx
c01057fc:	89 55 10             	mov    %edx,0x10(%ebp)
c01057ff:	85 c0                	test   %eax,%eax
c0105801:	75 c5                	jne    c01057c8 <memcmp+0x14>
        if (*s1 != *s2) {
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
    }
    return 0;
c0105803:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0105808:	c9                   	leave  
c0105809:	c3                   	ret    

c010580a <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
c010580a:	55                   	push   %ebp
c010580b:	89 e5                	mov    %esp,%ebp
c010580d:	83 ec 58             	sub    $0x58,%esp
c0105810:	8b 45 10             	mov    0x10(%ebp),%eax
c0105813:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0105816:	8b 45 14             	mov    0x14(%ebp),%eax
c0105819:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    unsigned long long result = num;
c010581c:	8b 45 d0             	mov    -0x30(%ebp),%eax
c010581f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0105822:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0105825:	89 55 ec             	mov    %edx,-0x14(%ebp)
    unsigned mod = do_div(result, base);
c0105828:	8b 45 18             	mov    0x18(%ebp),%eax
c010582b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c010582e:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105831:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0105834:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0105837:	89 55 f0             	mov    %edx,-0x10(%ebp)
c010583a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010583d:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105840:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0105844:	74 1c                	je     c0105862 <printnum+0x58>
c0105846:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105849:	ba 00 00 00 00       	mov    $0x0,%edx
c010584e:	f7 75 e4             	divl   -0x1c(%ebp)
c0105851:	89 55 f4             	mov    %edx,-0xc(%ebp)
c0105854:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105857:	ba 00 00 00 00       	mov    $0x0,%edx
c010585c:	f7 75 e4             	divl   -0x1c(%ebp)
c010585f:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105862:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105865:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105868:	f7 75 e4             	divl   -0x1c(%ebp)
c010586b:	89 45 e0             	mov    %eax,-0x20(%ebp)
c010586e:	89 55 dc             	mov    %edx,-0x24(%ebp)
c0105871:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105874:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0105877:	89 45 e8             	mov    %eax,-0x18(%ebp)
c010587a:	89 55 ec             	mov    %edx,-0x14(%ebp)
c010587d:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105880:	89 45 d8             	mov    %eax,-0x28(%ebp)

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
c0105883:	8b 45 18             	mov    0x18(%ebp),%eax
c0105886:	ba 00 00 00 00       	mov    $0x0,%edx
c010588b:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c010588e:	77 56                	ja     c01058e6 <printnum+0xdc>
c0105890:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0105893:	72 05                	jb     c010589a <printnum+0x90>
c0105895:	3b 45 d0             	cmp    -0x30(%ebp),%eax
c0105898:	77 4c                	ja     c01058e6 <printnum+0xdc>
        printnum(putch, putdat, result, base, width - 1, padc);
c010589a:	8b 45 1c             	mov    0x1c(%ebp),%eax
c010589d:	8d 50 ff             	lea    -0x1(%eax),%edx
c01058a0:	8b 45 20             	mov    0x20(%ebp),%eax
c01058a3:	89 44 24 18          	mov    %eax,0x18(%esp)
c01058a7:	89 54 24 14          	mov    %edx,0x14(%esp)
c01058ab:	8b 45 18             	mov    0x18(%ebp),%eax
c01058ae:	89 44 24 10          	mov    %eax,0x10(%esp)
c01058b2:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01058b5:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01058b8:	89 44 24 08          	mov    %eax,0x8(%esp)
c01058bc:	89 54 24 0c          	mov    %edx,0xc(%esp)
c01058c0:	8b 45 0c             	mov    0xc(%ebp),%eax
c01058c3:	89 44 24 04          	mov    %eax,0x4(%esp)
c01058c7:	8b 45 08             	mov    0x8(%ebp),%eax
c01058ca:	89 04 24             	mov    %eax,(%esp)
c01058cd:	e8 38 ff ff ff       	call   c010580a <printnum>
c01058d2:	eb 1b                	jmp    c01058ef <printnum+0xe5>
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
            putch(padc, putdat);
c01058d4:	8b 45 0c             	mov    0xc(%ebp),%eax
c01058d7:	89 44 24 04          	mov    %eax,0x4(%esp)
c01058db:	8b 45 20             	mov    0x20(%ebp),%eax
c01058de:	89 04 24             	mov    %eax,(%esp)
c01058e1:	8b 45 08             	mov    0x8(%ebp),%eax
c01058e4:	ff d0                	call   *%eax
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
c01058e6:	ff 4d 1c             	decl   0x1c(%ebp)
c01058e9:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
c01058ed:	7f e5                	jg     c01058d4 <printnum+0xca>
            putch(padc, putdat);
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
c01058ef:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01058f2:	05 1c 70 10 c0       	add    $0xc010701c,%eax
c01058f7:	0f b6 00             	movzbl (%eax),%eax
c01058fa:	0f be c0             	movsbl %al,%eax
c01058fd:	8b 55 0c             	mov    0xc(%ebp),%edx
c0105900:	89 54 24 04          	mov    %edx,0x4(%esp)
c0105904:	89 04 24             	mov    %eax,(%esp)
c0105907:	8b 45 08             	mov    0x8(%ebp),%eax
c010590a:	ff d0                	call   *%eax
}
c010590c:	90                   	nop
c010590d:	c9                   	leave  
c010590e:	c3                   	ret    

c010590f <getuint>:
 * getuint - get an unsigned int of various possible sizes from a varargs list
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static unsigned long long
getuint(va_list *ap, int lflag) {
c010590f:	55                   	push   %ebp
c0105910:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
c0105912:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
c0105916:	7e 14                	jle    c010592c <getuint+0x1d>
        return va_arg(*ap, unsigned long long);
c0105918:	8b 45 08             	mov    0x8(%ebp),%eax
c010591b:	8b 00                	mov    (%eax),%eax
c010591d:	8d 48 08             	lea    0x8(%eax),%ecx
c0105920:	8b 55 08             	mov    0x8(%ebp),%edx
c0105923:	89 0a                	mov    %ecx,(%edx)
c0105925:	8b 50 04             	mov    0x4(%eax),%edx
c0105928:	8b 00                	mov    (%eax),%eax
c010592a:	eb 30                	jmp    c010595c <getuint+0x4d>
    }
    else if (lflag) {
c010592c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0105930:	74 16                	je     c0105948 <getuint+0x39>
        return va_arg(*ap, unsigned long);
c0105932:	8b 45 08             	mov    0x8(%ebp),%eax
c0105935:	8b 00                	mov    (%eax),%eax
c0105937:	8d 48 04             	lea    0x4(%eax),%ecx
c010593a:	8b 55 08             	mov    0x8(%ebp),%edx
c010593d:	89 0a                	mov    %ecx,(%edx)
c010593f:	8b 00                	mov    (%eax),%eax
c0105941:	ba 00 00 00 00       	mov    $0x0,%edx
c0105946:	eb 14                	jmp    c010595c <getuint+0x4d>
    }
    else {
        return va_arg(*ap, unsigned int);
c0105948:	8b 45 08             	mov    0x8(%ebp),%eax
c010594b:	8b 00                	mov    (%eax),%eax
c010594d:	8d 48 04             	lea    0x4(%eax),%ecx
c0105950:	8b 55 08             	mov    0x8(%ebp),%edx
c0105953:	89 0a                	mov    %ecx,(%edx)
c0105955:	8b 00                	mov    (%eax),%eax
c0105957:	ba 00 00 00 00       	mov    $0x0,%edx
    }
}
c010595c:	5d                   	pop    %ebp
c010595d:	c3                   	ret    

c010595e <getint>:
 * getint - same as getuint but signed, we can't use getuint because of sign extension
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static long long
getint(va_list *ap, int lflag) {
c010595e:	55                   	push   %ebp
c010595f:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
c0105961:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
c0105965:	7e 14                	jle    c010597b <getint+0x1d>
        return va_arg(*ap, long long);
c0105967:	8b 45 08             	mov    0x8(%ebp),%eax
c010596a:	8b 00                	mov    (%eax),%eax
c010596c:	8d 48 08             	lea    0x8(%eax),%ecx
c010596f:	8b 55 08             	mov    0x8(%ebp),%edx
c0105972:	89 0a                	mov    %ecx,(%edx)
c0105974:	8b 50 04             	mov    0x4(%eax),%edx
c0105977:	8b 00                	mov    (%eax),%eax
c0105979:	eb 28                	jmp    c01059a3 <getint+0x45>
    }
    else if (lflag) {
c010597b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c010597f:	74 12                	je     c0105993 <getint+0x35>
        return va_arg(*ap, long);
c0105981:	8b 45 08             	mov    0x8(%ebp),%eax
c0105984:	8b 00                	mov    (%eax),%eax
c0105986:	8d 48 04             	lea    0x4(%eax),%ecx
c0105989:	8b 55 08             	mov    0x8(%ebp),%edx
c010598c:	89 0a                	mov    %ecx,(%edx)
c010598e:	8b 00                	mov    (%eax),%eax
c0105990:	99                   	cltd   
c0105991:	eb 10                	jmp    c01059a3 <getint+0x45>
    }
    else {
        return va_arg(*ap, int);
c0105993:	8b 45 08             	mov    0x8(%ebp),%eax
c0105996:	8b 00                	mov    (%eax),%eax
c0105998:	8d 48 04             	lea    0x4(%eax),%ecx
c010599b:	8b 55 08             	mov    0x8(%ebp),%edx
c010599e:	89 0a                	mov    %ecx,(%edx)
c01059a0:	8b 00                	mov    (%eax),%eax
c01059a2:	99                   	cltd   
    }
}
c01059a3:	5d                   	pop    %ebp
c01059a4:	c3                   	ret    

c01059a5 <printfmt>:
 * @putch:      specified putch function, print a single character
 * @putdat:     used by @putch function
 * @fmt:        the format string to use
 * */
void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
c01059a5:	55                   	push   %ebp
c01059a6:	89 e5                	mov    %esp,%ebp
c01059a8:	83 ec 28             	sub    $0x28,%esp
    va_list ap;

    va_start(ap, fmt);
c01059ab:	8d 45 14             	lea    0x14(%ebp),%eax
c01059ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
    vprintfmt(putch, putdat, fmt, ap);
c01059b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01059b4:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01059b8:	8b 45 10             	mov    0x10(%ebp),%eax
c01059bb:	89 44 24 08          	mov    %eax,0x8(%esp)
c01059bf:	8b 45 0c             	mov    0xc(%ebp),%eax
c01059c2:	89 44 24 04          	mov    %eax,0x4(%esp)
c01059c6:	8b 45 08             	mov    0x8(%ebp),%eax
c01059c9:	89 04 24             	mov    %eax,(%esp)
c01059cc:	e8 03 00 00 00       	call   c01059d4 <vprintfmt>
    va_end(ap);
}
c01059d1:	90                   	nop
c01059d2:	c9                   	leave  
c01059d3:	c3                   	ret    

c01059d4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
c01059d4:	55                   	push   %ebp
c01059d5:	89 e5                	mov    %esp,%ebp
c01059d7:	56                   	push   %esi
c01059d8:	53                   	push   %ebx
c01059d9:	83 ec 40             	sub    $0x40,%esp
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c01059dc:	eb 17                	jmp    c01059f5 <vprintfmt+0x21>
            if (ch == '\0') {
c01059de:	85 db                	test   %ebx,%ebx
c01059e0:	0f 84 bf 03 00 00    	je     c0105da5 <vprintfmt+0x3d1>
                return;
            }
            putch(ch, putdat);
c01059e6:	8b 45 0c             	mov    0xc(%ebp),%eax
c01059e9:	89 44 24 04          	mov    %eax,0x4(%esp)
c01059ed:	89 1c 24             	mov    %ebx,(%esp)
c01059f0:	8b 45 08             	mov    0x8(%ebp),%eax
c01059f3:	ff d0                	call   *%eax
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c01059f5:	8b 45 10             	mov    0x10(%ebp),%eax
c01059f8:	8d 50 01             	lea    0x1(%eax),%edx
c01059fb:	89 55 10             	mov    %edx,0x10(%ebp)
c01059fe:	0f b6 00             	movzbl (%eax),%eax
c0105a01:	0f b6 d8             	movzbl %al,%ebx
c0105a04:	83 fb 25             	cmp    $0x25,%ebx
c0105a07:	75 d5                	jne    c01059de <vprintfmt+0xa>
            }
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
c0105a09:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
        width = precision = -1;
c0105a0d:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
c0105a14:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105a17:	89 45 e8             	mov    %eax,-0x18(%ebp)
        lflag = altflag = 0;
c0105a1a:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0105a21:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105a24:	89 45 e0             	mov    %eax,-0x20(%ebp)

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
c0105a27:	8b 45 10             	mov    0x10(%ebp),%eax
c0105a2a:	8d 50 01             	lea    0x1(%eax),%edx
c0105a2d:	89 55 10             	mov    %edx,0x10(%ebp)
c0105a30:	0f b6 00             	movzbl (%eax),%eax
c0105a33:	0f b6 d8             	movzbl %al,%ebx
c0105a36:	8d 43 dd             	lea    -0x23(%ebx),%eax
c0105a39:	83 f8 55             	cmp    $0x55,%eax
c0105a3c:	0f 87 37 03 00 00    	ja     c0105d79 <vprintfmt+0x3a5>
c0105a42:	8b 04 85 40 70 10 c0 	mov    -0x3fef8fc0(,%eax,4),%eax
c0105a49:	ff e0                	jmp    *%eax

        // flag to pad on the right
        case '-':
            padc = '-';
c0105a4b:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
            goto reswitch;
c0105a4f:	eb d6                	jmp    c0105a27 <vprintfmt+0x53>

        // flag to pad with 0's instead of spaces
        case '0':
            padc = '0';
c0105a51:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
            goto reswitch;
c0105a55:	eb d0                	jmp    c0105a27 <vprintfmt+0x53>

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
c0105a57:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
                precision = precision * 10 + ch - '0';
c0105a5e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0105a61:	89 d0                	mov    %edx,%eax
c0105a63:	c1 e0 02             	shl    $0x2,%eax
c0105a66:	01 d0                	add    %edx,%eax
c0105a68:	01 c0                	add    %eax,%eax
c0105a6a:	01 d8                	add    %ebx,%eax
c0105a6c:	83 e8 30             	sub    $0x30,%eax
c0105a6f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
                ch = *fmt;
c0105a72:	8b 45 10             	mov    0x10(%ebp),%eax
c0105a75:	0f b6 00             	movzbl (%eax),%eax
c0105a78:	0f be d8             	movsbl %al,%ebx
                if (ch < '0' || ch > '9') {
c0105a7b:	83 fb 2f             	cmp    $0x2f,%ebx
c0105a7e:	7e 38                	jle    c0105ab8 <vprintfmt+0xe4>
c0105a80:	83 fb 39             	cmp    $0x39,%ebx
c0105a83:	7f 33                	jg     c0105ab8 <vprintfmt+0xe4>
            padc = '0';
            goto reswitch;

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
c0105a85:	ff 45 10             	incl   0x10(%ebp)
                precision = precision * 10 + ch - '0';
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
c0105a88:	eb d4                	jmp    c0105a5e <vprintfmt+0x8a>
            goto process_precision;

        case '*':
            precision = va_arg(ap, int);
c0105a8a:	8b 45 14             	mov    0x14(%ebp),%eax
c0105a8d:	8d 50 04             	lea    0x4(%eax),%edx
c0105a90:	89 55 14             	mov    %edx,0x14(%ebp)
c0105a93:	8b 00                	mov    (%eax),%eax
c0105a95:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            goto process_precision;
c0105a98:	eb 1f                	jmp    c0105ab9 <vprintfmt+0xe5>

        case '.':
            if (width < 0)
c0105a9a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0105a9e:	79 87                	jns    c0105a27 <vprintfmt+0x53>
                width = 0;
c0105aa0:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
            goto reswitch;
c0105aa7:	e9 7b ff ff ff       	jmp    c0105a27 <vprintfmt+0x53>

        case '#':
            altflag = 1;
c0105aac:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
            goto reswitch;
c0105ab3:	e9 6f ff ff ff       	jmp    c0105a27 <vprintfmt+0x53>
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
            goto process_precision;
c0105ab8:	90                   	nop
        case '#':
            altflag = 1;
            goto reswitch;

        process_precision:
            if (width < 0)
c0105ab9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0105abd:	0f 89 64 ff ff ff    	jns    c0105a27 <vprintfmt+0x53>
                width = precision, precision = -1;
c0105ac3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105ac6:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0105ac9:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
            goto reswitch;
c0105ad0:	e9 52 ff ff ff       	jmp    c0105a27 <vprintfmt+0x53>

        // long flag (doubled for long long)
        case 'l':
            lflag ++;
c0105ad5:	ff 45 e0             	incl   -0x20(%ebp)
            goto reswitch;
c0105ad8:	e9 4a ff ff ff       	jmp    c0105a27 <vprintfmt+0x53>

        // character
        case 'c':
            putch(va_arg(ap, int), putdat);
c0105add:	8b 45 14             	mov    0x14(%ebp),%eax
c0105ae0:	8d 50 04             	lea    0x4(%eax),%edx
c0105ae3:	89 55 14             	mov    %edx,0x14(%ebp)
c0105ae6:	8b 00                	mov    (%eax),%eax
c0105ae8:	8b 55 0c             	mov    0xc(%ebp),%edx
c0105aeb:	89 54 24 04          	mov    %edx,0x4(%esp)
c0105aef:	89 04 24             	mov    %eax,(%esp)
c0105af2:	8b 45 08             	mov    0x8(%ebp),%eax
c0105af5:	ff d0                	call   *%eax
            break;
c0105af7:	e9 a4 02 00 00       	jmp    c0105da0 <vprintfmt+0x3cc>

        // error message
        case 'e':
            err = va_arg(ap, int);
c0105afc:	8b 45 14             	mov    0x14(%ebp),%eax
c0105aff:	8d 50 04             	lea    0x4(%eax),%edx
c0105b02:	89 55 14             	mov    %edx,0x14(%ebp)
c0105b05:	8b 18                	mov    (%eax),%ebx
            if (err < 0) {
c0105b07:	85 db                	test   %ebx,%ebx
c0105b09:	79 02                	jns    c0105b0d <vprintfmt+0x139>
                err = -err;
c0105b0b:	f7 db                	neg    %ebx
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
c0105b0d:	83 fb 06             	cmp    $0x6,%ebx
c0105b10:	7f 0b                	jg     c0105b1d <vprintfmt+0x149>
c0105b12:	8b 34 9d 00 70 10 c0 	mov    -0x3fef9000(,%ebx,4),%esi
c0105b19:	85 f6                	test   %esi,%esi
c0105b1b:	75 23                	jne    c0105b40 <vprintfmt+0x16c>
                printfmt(putch, putdat, "error %d", err);
c0105b1d:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
c0105b21:	c7 44 24 08 2d 70 10 	movl   $0xc010702d,0x8(%esp)
c0105b28:	c0 
c0105b29:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105b2c:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105b30:	8b 45 08             	mov    0x8(%ebp),%eax
c0105b33:	89 04 24             	mov    %eax,(%esp)
c0105b36:	e8 6a fe ff ff       	call   c01059a5 <printfmt>
            }
            else {
                printfmt(putch, putdat, "%s", p);
            }
            break;
c0105b3b:	e9 60 02 00 00       	jmp    c0105da0 <vprintfmt+0x3cc>
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
                printfmt(putch, putdat, "error %d", err);
            }
            else {
                printfmt(putch, putdat, "%s", p);
c0105b40:	89 74 24 0c          	mov    %esi,0xc(%esp)
c0105b44:	c7 44 24 08 36 70 10 	movl   $0xc0107036,0x8(%esp)
c0105b4b:	c0 
c0105b4c:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105b4f:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105b53:	8b 45 08             	mov    0x8(%ebp),%eax
c0105b56:	89 04 24             	mov    %eax,(%esp)
c0105b59:	e8 47 fe ff ff       	call   c01059a5 <printfmt>
            }
            break;
c0105b5e:	e9 3d 02 00 00       	jmp    c0105da0 <vprintfmt+0x3cc>

        // string
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
c0105b63:	8b 45 14             	mov    0x14(%ebp),%eax
c0105b66:	8d 50 04             	lea    0x4(%eax),%edx
c0105b69:	89 55 14             	mov    %edx,0x14(%ebp)
c0105b6c:	8b 30                	mov    (%eax),%esi
c0105b6e:	85 f6                	test   %esi,%esi
c0105b70:	75 05                	jne    c0105b77 <vprintfmt+0x1a3>
                p = "(null)";
c0105b72:	be 39 70 10 c0       	mov    $0xc0107039,%esi
            }
            if (width > 0 && padc != '-') {
c0105b77:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0105b7b:	7e 76                	jle    c0105bf3 <vprintfmt+0x21f>
c0105b7d:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
c0105b81:	74 70                	je     c0105bf3 <vprintfmt+0x21f>
                for (width -= strnlen(p, precision); width > 0; width --) {
c0105b83:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105b86:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105b8a:	89 34 24             	mov    %esi,(%esp)
c0105b8d:	e8 f6 f7 ff ff       	call   c0105388 <strnlen>
c0105b92:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0105b95:	29 c2                	sub    %eax,%edx
c0105b97:	89 d0                	mov    %edx,%eax
c0105b99:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0105b9c:	eb 16                	jmp    c0105bb4 <vprintfmt+0x1e0>
                    putch(padc, putdat);
c0105b9e:	0f be 45 db          	movsbl -0x25(%ebp),%eax
c0105ba2:	8b 55 0c             	mov    0xc(%ebp),%edx
c0105ba5:	89 54 24 04          	mov    %edx,0x4(%esp)
c0105ba9:	89 04 24             	mov    %eax,(%esp)
c0105bac:	8b 45 08             	mov    0x8(%ebp),%eax
c0105baf:	ff d0                	call   *%eax
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
                p = "(null)";
            }
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
c0105bb1:	ff 4d e8             	decl   -0x18(%ebp)
c0105bb4:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0105bb8:	7f e4                	jg     c0105b9e <vprintfmt+0x1ca>
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
c0105bba:	eb 37                	jmp    c0105bf3 <vprintfmt+0x21f>
                if (altflag && (ch < ' ' || ch > '~')) {
c0105bbc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0105bc0:	74 1f                	je     c0105be1 <vprintfmt+0x20d>
c0105bc2:	83 fb 1f             	cmp    $0x1f,%ebx
c0105bc5:	7e 05                	jle    c0105bcc <vprintfmt+0x1f8>
c0105bc7:	83 fb 7e             	cmp    $0x7e,%ebx
c0105bca:	7e 15                	jle    c0105be1 <vprintfmt+0x20d>
                    putch('?', putdat);
c0105bcc:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105bcf:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105bd3:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
c0105bda:	8b 45 08             	mov    0x8(%ebp),%eax
c0105bdd:	ff d0                	call   *%eax
c0105bdf:	eb 0f                	jmp    c0105bf0 <vprintfmt+0x21c>
                }
                else {
                    putch(ch, putdat);
c0105be1:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105be4:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105be8:	89 1c 24             	mov    %ebx,(%esp)
c0105beb:	8b 45 08             	mov    0x8(%ebp),%eax
c0105bee:	ff d0                	call   *%eax
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
c0105bf0:	ff 4d e8             	decl   -0x18(%ebp)
c0105bf3:	89 f0                	mov    %esi,%eax
c0105bf5:	8d 70 01             	lea    0x1(%eax),%esi
c0105bf8:	0f b6 00             	movzbl (%eax),%eax
c0105bfb:	0f be d8             	movsbl %al,%ebx
c0105bfe:	85 db                	test   %ebx,%ebx
c0105c00:	74 27                	je     c0105c29 <vprintfmt+0x255>
c0105c02:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0105c06:	78 b4                	js     c0105bbc <vprintfmt+0x1e8>
c0105c08:	ff 4d e4             	decl   -0x1c(%ebp)
c0105c0b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0105c0f:	79 ab                	jns    c0105bbc <vprintfmt+0x1e8>
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
c0105c11:	eb 16                	jmp    c0105c29 <vprintfmt+0x255>
                putch(' ', putdat);
c0105c13:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105c16:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105c1a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
c0105c21:	8b 45 08             	mov    0x8(%ebp),%eax
c0105c24:	ff d0                	call   *%eax
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
c0105c26:	ff 4d e8             	decl   -0x18(%ebp)
c0105c29:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0105c2d:	7f e4                	jg     c0105c13 <vprintfmt+0x23f>
                putch(' ', putdat);
            }
            break;
c0105c2f:	e9 6c 01 00 00       	jmp    c0105da0 <vprintfmt+0x3cc>

        // (signed) decimal
        case 'd':
            num = getint(&ap, lflag);
c0105c34:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105c37:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105c3b:	8d 45 14             	lea    0x14(%ebp),%eax
c0105c3e:	89 04 24             	mov    %eax,(%esp)
c0105c41:	e8 18 fd ff ff       	call   c010595e <getint>
c0105c46:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105c49:	89 55 f4             	mov    %edx,-0xc(%ebp)
            if ((long long)num < 0) {
c0105c4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105c4f:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105c52:	85 d2                	test   %edx,%edx
c0105c54:	79 26                	jns    c0105c7c <vprintfmt+0x2a8>
                putch('-', putdat);
c0105c56:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105c59:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105c5d:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
c0105c64:	8b 45 08             	mov    0x8(%ebp),%eax
c0105c67:	ff d0                	call   *%eax
                num = -(long long)num;
c0105c69:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105c6c:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105c6f:	f7 d8                	neg    %eax
c0105c71:	83 d2 00             	adc    $0x0,%edx
c0105c74:	f7 da                	neg    %edx
c0105c76:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105c79:	89 55 f4             	mov    %edx,-0xc(%ebp)
            }
            base = 10;
c0105c7c:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
c0105c83:	e9 a8 00 00 00       	jmp    c0105d30 <vprintfmt+0x35c>

        // unsigned decimal
        case 'u':
            num = getuint(&ap, lflag);
c0105c88:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105c8b:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105c8f:	8d 45 14             	lea    0x14(%ebp),%eax
c0105c92:	89 04 24             	mov    %eax,(%esp)
c0105c95:	e8 75 fc ff ff       	call   c010590f <getuint>
c0105c9a:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105c9d:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 10;
c0105ca0:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
c0105ca7:	e9 84 00 00 00       	jmp    c0105d30 <vprintfmt+0x35c>

        // (unsigned) octal
        case 'o':
            num = getuint(&ap, lflag);
c0105cac:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105caf:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105cb3:	8d 45 14             	lea    0x14(%ebp),%eax
c0105cb6:	89 04 24             	mov    %eax,(%esp)
c0105cb9:	e8 51 fc ff ff       	call   c010590f <getuint>
c0105cbe:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105cc1:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 8;
c0105cc4:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
            goto number;
c0105ccb:	eb 63                	jmp    c0105d30 <vprintfmt+0x35c>

        // pointer
        case 'p':
            putch('0', putdat);
c0105ccd:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105cd0:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105cd4:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
c0105cdb:	8b 45 08             	mov    0x8(%ebp),%eax
c0105cde:	ff d0                	call   *%eax
            putch('x', putdat);
c0105ce0:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105ce3:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105ce7:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
c0105cee:	8b 45 08             	mov    0x8(%ebp),%eax
c0105cf1:	ff d0                	call   *%eax
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
c0105cf3:	8b 45 14             	mov    0x14(%ebp),%eax
c0105cf6:	8d 50 04             	lea    0x4(%eax),%edx
c0105cf9:	89 55 14             	mov    %edx,0x14(%ebp)
c0105cfc:	8b 00                	mov    (%eax),%eax
c0105cfe:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105d01:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
            base = 16;
c0105d08:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
            goto number;
c0105d0f:	eb 1f                	jmp    c0105d30 <vprintfmt+0x35c>

        // (unsigned) hexadecimal
        case 'x':
            num = getuint(&ap, lflag);
c0105d11:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105d14:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105d18:	8d 45 14             	lea    0x14(%ebp),%eax
c0105d1b:	89 04 24             	mov    %eax,(%esp)
c0105d1e:	e8 ec fb ff ff       	call   c010590f <getuint>
c0105d23:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105d26:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 16;
c0105d29:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
        number:
            printnum(putch, putdat, num, base, width, padc);
c0105d30:	0f be 55 db          	movsbl -0x25(%ebp),%edx
c0105d34:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105d37:	89 54 24 18          	mov    %edx,0x18(%esp)
c0105d3b:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0105d3e:	89 54 24 14          	mov    %edx,0x14(%esp)
c0105d42:	89 44 24 10          	mov    %eax,0x10(%esp)
c0105d46:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105d49:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105d4c:	89 44 24 08          	mov    %eax,0x8(%esp)
c0105d50:	89 54 24 0c          	mov    %edx,0xc(%esp)
c0105d54:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105d57:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105d5b:	8b 45 08             	mov    0x8(%ebp),%eax
c0105d5e:	89 04 24             	mov    %eax,(%esp)
c0105d61:	e8 a4 fa ff ff       	call   c010580a <printnum>
            break;
c0105d66:	eb 38                	jmp    c0105da0 <vprintfmt+0x3cc>

        // escaped '%' character
        case '%':
            putch(ch, putdat);
c0105d68:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105d6b:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105d6f:	89 1c 24             	mov    %ebx,(%esp)
c0105d72:	8b 45 08             	mov    0x8(%ebp),%eax
c0105d75:	ff d0                	call   *%eax
            break;
c0105d77:	eb 27                	jmp    c0105da0 <vprintfmt+0x3cc>

        // unrecognized escape sequence - just print it literally
        default:
            putch('%', putdat);
c0105d79:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105d7c:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105d80:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
c0105d87:	8b 45 08             	mov    0x8(%ebp),%eax
c0105d8a:	ff d0                	call   *%eax
            for (fmt --; fmt[-1] != '%'; fmt --)
c0105d8c:	ff 4d 10             	decl   0x10(%ebp)
c0105d8f:	eb 03                	jmp    c0105d94 <vprintfmt+0x3c0>
c0105d91:	ff 4d 10             	decl   0x10(%ebp)
c0105d94:	8b 45 10             	mov    0x10(%ebp),%eax
c0105d97:	48                   	dec    %eax
c0105d98:	0f b6 00             	movzbl (%eax),%eax
c0105d9b:	3c 25                	cmp    $0x25,%al
c0105d9d:	75 f2                	jne    c0105d91 <vprintfmt+0x3bd>
                /* do nothing */;
            break;
c0105d9f:	90                   	nop
        }
    }
c0105da0:	e9 37 fc ff ff       	jmp    c01059dc <vprintfmt+0x8>
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
            if (ch == '\0') {
                return;
c0105da5:	90                   	nop
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
c0105da6:	83 c4 40             	add    $0x40,%esp
c0105da9:	5b                   	pop    %ebx
c0105daa:	5e                   	pop    %esi
c0105dab:	5d                   	pop    %ebp
c0105dac:	c3                   	ret    

c0105dad <sprintputch>:
 * sprintputch - 'print' a single character in a buffer
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
c0105dad:	55                   	push   %ebp
c0105dae:	89 e5                	mov    %esp,%ebp
    b->cnt ++;
c0105db0:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105db3:	8b 40 08             	mov    0x8(%eax),%eax
c0105db6:	8d 50 01             	lea    0x1(%eax),%edx
c0105db9:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105dbc:	89 50 08             	mov    %edx,0x8(%eax)
    if (b->buf < b->ebuf) {
c0105dbf:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105dc2:	8b 10                	mov    (%eax),%edx
c0105dc4:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105dc7:	8b 40 04             	mov    0x4(%eax),%eax
c0105dca:	39 c2                	cmp    %eax,%edx
c0105dcc:	73 12                	jae    c0105de0 <sprintputch+0x33>
        *b->buf ++ = ch;
c0105dce:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105dd1:	8b 00                	mov    (%eax),%eax
c0105dd3:	8d 48 01             	lea    0x1(%eax),%ecx
c0105dd6:	8b 55 0c             	mov    0xc(%ebp),%edx
c0105dd9:	89 0a                	mov    %ecx,(%edx)
c0105ddb:	8b 55 08             	mov    0x8(%ebp),%edx
c0105dde:	88 10                	mov    %dl,(%eax)
    }
}
c0105de0:	90                   	nop
c0105de1:	5d                   	pop    %ebp
c0105de2:	c3                   	ret    

c0105de3 <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
c0105de3:	55                   	push   %ebp
c0105de4:	89 e5                	mov    %esp,%ebp
c0105de6:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
c0105de9:	8d 45 14             	lea    0x14(%ebp),%eax
c0105dec:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vsnprintf(str, size, fmt, ap);
c0105def:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105df2:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0105df6:	8b 45 10             	mov    0x10(%ebp),%eax
c0105df9:	89 44 24 08          	mov    %eax,0x8(%esp)
c0105dfd:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105e00:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105e04:	8b 45 08             	mov    0x8(%ebp),%eax
c0105e07:	89 04 24             	mov    %eax,(%esp)
c0105e0a:	e8 08 00 00 00       	call   c0105e17 <vsnprintf>
c0105e0f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
c0105e12:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0105e15:	c9                   	leave  
c0105e16:	c3                   	ret    

c0105e17 <vsnprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
c0105e17:	55                   	push   %ebp
c0105e18:	89 e5                	mov    %esp,%ebp
c0105e1a:	83 ec 28             	sub    $0x28,%esp
    struct sprintbuf b = {str, str + size - 1, 0};
c0105e1d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105e20:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105e23:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105e26:	8d 50 ff             	lea    -0x1(%eax),%edx
c0105e29:	8b 45 08             	mov    0x8(%ebp),%eax
c0105e2c:	01 d0                	add    %edx,%eax
c0105e2e:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105e31:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if (str == NULL || b.buf > b.ebuf) {
c0105e38:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0105e3c:	74 0a                	je     c0105e48 <vsnprintf+0x31>
c0105e3e:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0105e41:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105e44:	39 c2                	cmp    %eax,%edx
c0105e46:	76 07                	jbe    c0105e4f <vsnprintf+0x38>
        return -E_INVAL;
c0105e48:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
c0105e4d:	eb 2a                	jmp    c0105e79 <vsnprintf+0x62>
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
c0105e4f:	8b 45 14             	mov    0x14(%ebp),%eax
c0105e52:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0105e56:	8b 45 10             	mov    0x10(%ebp),%eax
c0105e59:	89 44 24 08          	mov    %eax,0x8(%esp)
c0105e5d:	8d 45 ec             	lea    -0x14(%ebp),%eax
c0105e60:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105e64:	c7 04 24 ad 5d 10 c0 	movl   $0xc0105dad,(%esp)
c0105e6b:	e8 64 fb ff ff       	call   c01059d4 <vprintfmt>
    // null terminate the buffer
    *b.buf = '\0';
c0105e70:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105e73:	c6 00 00             	movb   $0x0,(%eax)
    return b.cnt;
c0105e76:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0105e79:	c9                   	leave  
c0105e7a:	c3                   	ret    
