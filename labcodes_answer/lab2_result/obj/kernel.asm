
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

static void lab1_switch_test(void);

int
kern_init(void) {
c0100036:	55                   	push   %ebp
c0100037:	89 e5                	mov    %esp,%ebp
c0100039:	83 ec 18             	sub    $0x18,%esp
    extern char edata[], end[];
    memset(edata, 0, end - edata);
c010003c:	ba 28 af 11 c0       	mov    $0xc011af28,%edx
c0100041:	b8 00 a0 11 c0       	mov    $0xc011a000,%eax
c0100046:	29 c2                	sub    %eax,%edx
c0100048:	89 d0                	mov    %edx,%eax
c010004a:	83 ec 04             	sub    $0x4,%esp
c010004d:	50                   	push   %eax
c010004e:	6a 00                	push   $0x0
c0100050:	68 00 a0 11 c0       	push   $0xc011a000
c0100055:	e8 99 52 00 00       	call   c01052f3 <memset>
c010005a:	83 c4 10             	add    $0x10,%esp

    cons_init();                // init the console
c010005d:	e8 70 15 00 00       	call   c01015d2 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
c0100062:	c7 45 f4 a0 5a 10 c0 	movl   $0xc0105aa0,-0xc(%ebp)
    cprintf("%s\n\n", message);
c0100069:	83 ec 08             	sub    $0x8,%esp
c010006c:	ff 75 f4             	pushl  -0xc(%ebp)
c010006f:	68 bc 5a 10 c0       	push   $0xc0105abc
c0100074:	e8 fa 01 00 00       	call   c0100273 <cprintf>
c0100079:	83 c4 10             	add    $0x10,%esp

    print_kerninfo();
c010007c:	e8 91 08 00 00       	call   c0100912 <print_kerninfo>

    grade_backtrace();
c0100081:	e8 74 00 00 00       	call   c01000fa <grade_backtrace>

    pmm_init();                 // init physical memory management
c0100086:	e8 7a 30 00 00       	call   c0103105 <pmm_init>

    pic_init();                 // init interrupt controller
c010008b:	e8 b4 16 00 00       	call   c0101744 <pic_init>
    idt_init();                 // init interrupt descriptor table
c0100090:	e8 36 18 00 00       	call   c01018cb <idt_init>

    clock_init();               // init clock interrupt
c0100095:	e8 df 0c 00 00       	call   c0100d79 <clock_init>
    intr_enable();              // enable irq interrupt
c010009a:	e8 e2 17 00 00       	call   c0101881 <intr_enable>
    //LAB1: CAHLLENGE 1 If you try to do it, uncomment lab1_switch_test()
    // user/kernel mode switch test
    //lab1_switch_test();

    /* do nothing */
    while (1);
c010009f:	eb fe                	jmp    c010009f <kern_init+0x69>

c01000a1 <grade_backtrace2>:
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
c01000a1:	55                   	push   %ebp
c01000a2:	89 e5                	mov    %esp,%ebp
c01000a4:	83 ec 08             	sub    $0x8,%esp
    mon_backtrace(0, NULL, NULL);
c01000a7:	83 ec 04             	sub    $0x4,%esp
c01000aa:	6a 00                	push   $0x0
c01000ac:	6a 00                	push   $0x0
c01000ae:	6a 00                	push   $0x0
c01000b0:	e8 b2 0c 00 00       	call   c0100d67 <mon_backtrace>
c01000b5:	83 c4 10             	add    $0x10,%esp
}
c01000b8:	90                   	nop
c01000b9:	c9                   	leave  
c01000ba:	c3                   	ret    

c01000bb <grade_backtrace1>:

void __attribute__((noinline))
grade_backtrace1(int arg0, int arg1) {
c01000bb:	55                   	push   %ebp
c01000bc:	89 e5                	mov    %esp,%ebp
c01000be:	53                   	push   %ebx
c01000bf:	83 ec 04             	sub    $0x4,%esp
    grade_backtrace2(arg0, (int)&arg0, arg1, (int)&arg1);
c01000c2:	8d 4d 0c             	lea    0xc(%ebp),%ecx
c01000c5:	8b 55 0c             	mov    0xc(%ebp),%edx
c01000c8:	8d 5d 08             	lea    0x8(%ebp),%ebx
c01000cb:	8b 45 08             	mov    0x8(%ebp),%eax
c01000ce:	51                   	push   %ecx
c01000cf:	52                   	push   %edx
c01000d0:	53                   	push   %ebx
c01000d1:	50                   	push   %eax
c01000d2:	e8 ca ff ff ff       	call   c01000a1 <grade_backtrace2>
c01000d7:	83 c4 10             	add    $0x10,%esp
}
c01000da:	90                   	nop
c01000db:	8b 5d fc             	mov    -0x4(%ebp),%ebx
c01000de:	c9                   	leave  
c01000df:	c3                   	ret    

c01000e0 <grade_backtrace0>:

void __attribute__((noinline))
grade_backtrace0(int arg0, int arg1, int arg2) {
c01000e0:	55                   	push   %ebp
c01000e1:	89 e5                	mov    %esp,%ebp
c01000e3:	83 ec 08             	sub    $0x8,%esp
    grade_backtrace1(arg0, arg2);
c01000e6:	83 ec 08             	sub    $0x8,%esp
c01000e9:	ff 75 10             	pushl  0x10(%ebp)
c01000ec:	ff 75 08             	pushl  0x8(%ebp)
c01000ef:	e8 c7 ff ff ff       	call   c01000bb <grade_backtrace1>
c01000f4:	83 c4 10             	add    $0x10,%esp
}
c01000f7:	90                   	nop
c01000f8:	c9                   	leave  
c01000f9:	c3                   	ret    

c01000fa <grade_backtrace>:

void
grade_backtrace(void) {
c01000fa:	55                   	push   %ebp
c01000fb:	89 e5                	mov    %esp,%ebp
c01000fd:	83 ec 08             	sub    $0x8,%esp
    grade_backtrace0(0, (int)kern_init, 0xffff0000);
c0100100:	b8 36 00 10 c0       	mov    $0xc0100036,%eax
c0100105:	83 ec 04             	sub    $0x4,%esp
c0100108:	68 00 00 ff ff       	push   $0xffff0000
c010010d:	50                   	push   %eax
c010010e:	6a 00                	push   $0x0
c0100110:	e8 cb ff ff ff       	call   c01000e0 <grade_backtrace0>
c0100115:	83 c4 10             	add    $0x10,%esp
}
c0100118:	90                   	nop
c0100119:	c9                   	leave  
c010011a:	c3                   	ret    

c010011b <lab1_print_cur_status>:

static void
lab1_print_cur_status(void) {
c010011b:	55                   	push   %ebp
c010011c:	89 e5                	mov    %esp,%ebp
c010011e:	83 ec 18             	sub    $0x18,%esp
    static int round = 0;
    uint16_t reg1, reg2, reg3, reg4;
    asm volatile (
c0100121:	8c 4d f6             	mov    %cs,-0xa(%ebp)
c0100124:	8c 5d f4             	mov    %ds,-0xc(%ebp)
c0100127:	8c 45 f2             	mov    %es,-0xe(%ebp)
c010012a:	8c 55 f0             	mov    %ss,-0x10(%ebp)
            "mov %%cs, %0;"
            "mov %%ds, %1;"
            "mov %%es, %2;"
            "mov %%ss, %3;"
            : "=m"(reg1), "=m"(reg2), "=m"(reg3), "=m"(reg4));
    cprintf("%d: @ring %d\n", round, reg1 & 3);
c010012d:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100131:	0f b7 c0             	movzwl %ax,%eax
c0100134:	83 e0 03             	and    $0x3,%eax
c0100137:	89 c2                	mov    %eax,%edx
c0100139:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c010013e:	83 ec 04             	sub    $0x4,%esp
c0100141:	52                   	push   %edx
c0100142:	50                   	push   %eax
c0100143:	68 c1 5a 10 c0       	push   $0xc0105ac1
c0100148:	e8 26 01 00 00       	call   c0100273 <cprintf>
c010014d:	83 c4 10             	add    $0x10,%esp
    cprintf("%d:  cs = %x\n", round, reg1);
c0100150:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100154:	0f b7 d0             	movzwl %ax,%edx
c0100157:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c010015c:	83 ec 04             	sub    $0x4,%esp
c010015f:	52                   	push   %edx
c0100160:	50                   	push   %eax
c0100161:	68 cf 5a 10 c0       	push   $0xc0105acf
c0100166:	e8 08 01 00 00       	call   c0100273 <cprintf>
c010016b:	83 c4 10             	add    $0x10,%esp
    cprintf("%d:  ds = %x\n", round, reg2);
c010016e:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
c0100172:	0f b7 d0             	movzwl %ax,%edx
c0100175:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c010017a:	83 ec 04             	sub    $0x4,%esp
c010017d:	52                   	push   %edx
c010017e:	50                   	push   %eax
c010017f:	68 dd 5a 10 c0       	push   $0xc0105add
c0100184:	e8 ea 00 00 00       	call   c0100273 <cprintf>
c0100189:	83 c4 10             	add    $0x10,%esp
    cprintf("%d:  es = %x\n", round, reg3);
c010018c:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c0100190:	0f b7 d0             	movzwl %ax,%edx
c0100193:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c0100198:	83 ec 04             	sub    $0x4,%esp
c010019b:	52                   	push   %edx
c010019c:	50                   	push   %eax
c010019d:	68 eb 5a 10 c0       	push   $0xc0105aeb
c01001a2:	e8 cc 00 00 00       	call   c0100273 <cprintf>
c01001a7:	83 c4 10             	add    $0x10,%esp
    cprintf("%d:  ss = %x\n", round, reg4);
c01001aa:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
c01001ae:	0f b7 d0             	movzwl %ax,%edx
c01001b1:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c01001b6:	83 ec 04             	sub    $0x4,%esp
c01001b9:	52                   	push   %edx
c01001ba:	50                   	push   %eax
c01001bb:	68 f9 5a 10 c0       	push   $0xc0105af9
c01001c0:	e8 ae 00 00 00       	call   c0100273 <cprintf>
c01001c5:	83 c4 10             	add    $0x10,%esp
    round ++;
c01001c8:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c01001cd:	83 c0 01             	add    $0x1,%eax
c01001d0:	a3 00 a0 11 c0       	mov    %eax,0xc011a000
}
c01001d5:	90                   	nop
c01001d6:	c9                   	leave  
c01001d7:	c3                   	ret    

c01001d8 <lab1_switch_to_user>:

static void
lab1_switch_to_user(void) {
c01001d8:	55                   	push   %ebp
c01001d9:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 : TODO
}
c01001db:	90                   	nop
c01001dc:	5d                   	pop    %ebp
c01001dd:	c3                   	ret    

c01001de <lab1_switch_to_kernel>:

static void
lab1_switch_to_kernel(void) {
c01001de:	55                   	push   %ebp
c01001df:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 :  TODO
}
c01001e1:	90                   	nop
c01001e2:	5d                   	pop    %ebp
c01001e3:	c3                   	ret    

c01001e4 <lab1_switch_test>:

static void
lab1_switch_test(void) {
c01001e4:	55                   	push   %ebp
c01001e5:	89 e5                	mov    %esp,%ebp
c01001e7:	83 ec 08             	sub    $0x8,%esp
    lab1_print_cur_status();
c01001ea:	e8 2c ff ff ff       	call   c010011b <lab1_print_cur_status>
    cprintf("+++ switch to  user  mode +++\n");
c01001ef:	83 ec 0c             	sub    $0xc,%esp
c01001f2:	68 08 5b 10 c0       	push   $0xc0105b08
c01001f7:	e8 77 00 00 00       	call   c0100273 <cprintf>
c01001fc:	83 c4 10             	add    $0x10,%esp
    lab1_switch_to_user();
c01001ff:	e8 d4 ff ff ff       	call   c01001d8 <lab1_switch_to_user>
    lab1_print_cur_status();
c0100204:	e8 12 ff ff ff       	call   c010011b <lab1_print_cur_status>
    cprintf("+++ switch to kernel mode +++\n");
c0100209:	83 ec 0c             	sub    $0xc,%esp
c010020c:	68 28 5b 10 c0       	push   $0xc0105b28
c0100211:	e8 5d 00 00 00       	call   c0100273 <cprintf>
c0100216:	83 c4 10             	add    $0x10,%esp
    lab1_switch_to_kernel();
c0100219:	e8 c0 ff ff ff       	call   c01001de <lab1_switch_to_kernel>
    lab1_print_cur_status();
c010021e:	e8 f8 fe ff ff       	call   c010011b <lab1_print_cur_status>
}
c0100223:	90                   	nop
c0100224:	c9                   	leave  
c0100225:	c3                   	ret    

c0100226 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
c0100226:	55                   	push   %ebp
c0100227:	89 e5                	mov    %esp,%ebp
c0100229:	83 ec 08             	sub    $0x8,%esp
    cons_putc(c);
c010022c:	83 ec 0c             	sub    $0xc,%esp
c010022f:	ff 75 08             	pushl  0x8(%ebp)
c0100232:	e8 cc 13 00 00       	call   c0101603 <cons_putc>
c0100237:	83 c4 10             	add    $0x10,%esp
    (*cnt) ++;
c010023a:	8b 45 0c             	mov    0xc(%ebp),%eax
c010023d:	8b 00                	mov    (%eax),%eax
c010023f:	8d 50 01             	lea    0x1(%eax),%edx
c0100242:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100245:	89 10                	mov    %edx,(%eax)
}
c0100247:	90                   	nop
c0100248:	c9                   	leave  
c0100249:	c3                   	ret    

c010024a <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
c010024a:	55                   	push   %ebp
c010024b:	89 e5                	mov    %esp,%ebp
c010024d:	83 ec 18             	sub    $0x18,%esp
    int cnt = 0;
c0100250:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
c0100257:	ff 75 0c             	pushl  0xc(%ebp)
c010025a:	ff 75 08             	pushl  0x8(%ebp)
c010025d:	8d 45 f4             	lea    -0xc(%ebp),%eax
c0100260:	50                   	push   %eax
c0100261:	68 26 02 10 c0       	push   $0xc0100226
c0100266:	e8 be 53 00 00       	call   c0105629 <vprintfmt>
c010026b:	83 c4 10             	add    $0x10,%esp
    return cnt;
c010026e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0100271:	c9                   	leave  
c0100272:	c3                   	ret    

c0100273 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
c0100273:	55                   	push   %ebp
c0100274:	89 e5                	mov    %esp,%ebp
c0100276:	83 ec 18             	sub    $0x18,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
c0100279:	8d 45 0c             	lea    0xc(%ebp),%eax
c010027c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vcprintf(fmt, ap);
c010027f:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100282:	83 ec 08             	sub    $0x8,%esp
c0100285:	50                   	push   %eax
c0100286:	ff 75 08             	pushl  0x8(%ebp)
c0100289:	e8 bc ff ff ff       	call   c010024a <vcprintf>
c010028e:	83 c4 10             	add    $0x10,%esp
c0100291:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
c0100294:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0100297:	c9                   	leave  
c0100298:	c3                   	ret    

c0100299 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
c0100299:	55                   	push   %ebp
c010029a:	89 e5                	mov    %esp,%ebp
c010029c:	83 ec 08             	sub    $0x8,%esp
    cons_putc(c);
c010029f:	83 ec 0c             	sub    $0xc,%esp
c01002a2:	ff 75 08             	pushl  0x8(%ebp)
c01002a5:	e8 59 13 00 00       	call   c0101603 <cons_putc>
c01002aa:	83 c4 10             	add    $0x10,%esp
}
c01002ad:	90                   	nop
c01002ae:	c9                   	leave  
c01002af:	c3                   	ret    

c01002b0 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
c01002b0:	55                   	push   %ebp
c01002b1:	89 e5                	mov    %esp,%ebp
c01002b3:	83 ec 18             	sub    $0x18,%esp
    int cnt = 0;
c01002b6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    char c;
    while ((c = *str ++) != '\0') {
c01002bd:	eb 14                	jmp    c01002d3 <cputs+0x23>
        cputch(c, &cnt);
c01002bf:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c01002c3:	83 ec 08             	sub    $0x8,%esp
c01002c6:	8d 55 f0             	lea    -0x10(%ebp),%edx
c01002c9:	52                   	push   %edx
c01002ca:	50                   	push   %eax
c01002cb:	e8 56 ff ff ff       	call   c0100226 <cputch>
c01002d0:	83 c4 10             	add    $0x10,%esp
 * */
int
cputs(const char *str) {
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
c01002d3:	8b 45 08             	mov    0x8(%ebp),%eax
c01002d6:	8d 50 01             	lea    0x1(%eax),%edx
c01002d9:	89 55 08             	mov    %edx,0x8(%ebp)
c01002dc:	0f b6 00             	movzbl (%eax),%eax
c01002df:	88 45 f7             	mov    %al,-0x9(%ebp)
c01002e2:	80 7d f7 00          	cmpb   $0x0,-0x9(%ebp)
c01002e6:	75 d7                	jne    c01002bf <cputs+0xf>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
c01002e8:	83 ec 08             	sub    $0x8,%esp
c01002eb:	8d 45 f0             	lea    -0x10(%ebp),%eax
c01002ee:	50                   	push   %eax
c01002ef:	6a 0a                	push   $0xa
c01002f1:	e8 30 ff ff ff       	call   c0100226 <cputch>
c01002f6:	83 c4 10             	add    $0x10,%esp
    return cnt;
c01002f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
c01002fc:	c9                   	leave  
c01002fd:	c3                   	ret    

c01002fe <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
c01002fe:	55                   	push   %ebp
c01002ff:	89 e5                	mov    %esp,%ebp
c0100301:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = cons_getc()) == 0)
c0100304:	e8 43 13 00 00       	call   c010164c <cons_getc>
c0100309:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010030c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0100310:	74 f2                	je     c0100304 <getchar+0x6>
        /* do nothing */;
    return c;
c0100312:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0100315:	c9                   	leave  
c0100316:	c3                   	ret    

c0100317 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
c0100317:	55                   	push   %ebp
c0100318:	89 e5                	mov    %esp,%ebp
c010031a:	83 ec 18             	sub    $0x18,%esp
    if (prompt != NULL) {
c010031d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0100321:	74 13                	je     c0100336 <readline+0x1f>
        cprintf("%s", prompt);
c0100323:	83 ec 08             	sub    $0x8,%esp
c0100326:	ff 75 08             	pushl  0x8(%ebp)
c0100329:	68 47 5b 10 c0       	push   $0xc0105b47
c010032e:	e8 40 ff ff ff       	call   c0100273 <cprintf>
c0100333:	83 c4 10             	add    $0x10,%esp
    }
    int i = 0, c;
c0100336:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        c = getchar();
c010033d:	e8 bc ff ff ff       	call   c01002fe <getchar>
c0100342:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (c < 0) {
c0100345:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0100349:	79 0a                	jns    c0100355 <readline+0x3e>
            return NULL;
c010034b:	b8 00 00 00 00       	mov    $0x0,%eax
c0100350:	e9 82 00 00 00       	jmp    c01003d7 <readline+0xc0>
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
c0100355:	83 7d f0 1f          	cmpl   $0x1f,-0x10(%ebp)
c0100359:	7e 2b                	jle    c0100386 <readline+0x6f>
c010035b:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
c0100362:	7f 22                	jg     c0100386 <readline+0x6f>
            cputchar(c);
c0100364:	83 ec 0c             	sub    $0xc,%esp
c0100367:	ff 75 f0             	pushl  -0x10(%ebp)
c010036a:	e8 2a ff ff ff       	call   c0100299 <cputchar>
c010036f:	83 c4 10             	add    $0x10,%esp
            buf[i ++] = c;
c0100372:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100375:	8d 50 01             	lea    0x1(%eax),%edx
c0100378:	89 55 f4             	mov    %edx,-0xc(%ebp)
c010037b:	8b 55 f0             	mov    -0x10(%ebp),%edx
c010037e:	88 90 20 a0 11 c0    	mov    %dl,-0x3fee5fe0(%eax)
c0100384:	eb 4c                	jmp    c01003d2 <readline+0xbb>
        }
        else if (c == '\b' && i > 0) {
c0100386:	83 7d f0 08          	cmpl   $0x8,-0x10(%ebp)
c010038a:	75 1a                	jne    c01003a6 <readline+0x8f>
c010038c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0100390:	7e 14                	jle    c01003a6 <readline+0x8f>
            cputchar(c);
c0100392:	83 ec 0c             	sub    $0xc,%esp
c0100395:	ff 75 f0             	pushl  -0x10(%ebp)
c0100398:	e8 fc fe ff ff       	call   c0100299 <cputchar>
c010039d:	83 c4 10             	add    $0x10,%esp
            i --;
c01003a0:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
c01003a4:	eb 2c                	jmp    c01003d2 <readline+0xbb>
        }
        else if (c == '\n' || c == '\r') {
c01003a6:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
c01003aa:	74 06                	je     c01003b2 <readline+0x9b>
c01003ac:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
c01003b0:	75 8b                	jne    c010033d <readline+0x26>
            cputchar(c);
c01003b2:	83 ec 0c             	sub    $0xc,%esp
c01003b5:	ff 75 f0             	pushl  -0x10(%ebp)
c01003b8:	e8 dc fe ff ff       	call   c0100299 <cputchar>
c01003bd:	83 c4 10             	add    $0x10,%esp
            buf[i] = '\0';
c01003c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01003c3:	05 20 a0 11 c0       	add    $0xc011a020,%eax
c01003c8:	c6 00 00             	movb   $0x0,(%eax)
            return buf;
c01003cb:	b8 20 a0 11 c0       	mov    $0xc011a020,%eax
c01003d0:	eb 05                	jmp    c01003d7 <readline+0xc0>
        }
    }
c01003d2:	e9 66 ff ff ff       	jmp    c010033d <readline+0x26>
}
c01003d7:	c9                   	leave  
c01003d8:	c3                   	ret    

c01003d9 <__panic>:
/* *
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
c01003d9:	55                   	push   %ebp
c01003da:	89 e5                	mov    %esp,%ebp
c01003dc:	83 ec 18             	sub    $0x18,%esp
    if (is_panic) {
c01003df:	a1 20 a4 11 c0       	mov    0xc011a420,%eax
c01003e4:	85 c0                	test   %eax,%eax
c01003e6:	75 5f                	jne    c0100447 <__panic+0x6e>
        goto panic_dead;
    }
    is_panic = 1;
c01003e8:	c7 05 20 a4 11 c0 01 	movl   $0x1,0xc011a420
c01003ef:	00 00 00 

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
c01003f2:	8d 45 14             	lea    0x14(%ebp),%eax
c01003f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
c01003f8:	83 ec 04             	sub    $0x4,%esp
c01003fb:	ff 75 0c             	pushl  0xc(%ebp)
c01003fe:	ff 75 08             	pushl  0x8(%ebp)
c0100401:	68 4a 5b 10 c0       	push   $0xc0105b4a
c0100406:	e8 68 fe ff ff       	call   c0100273 <cprintf>
c010040b:	83 c4 10             	add    $0x10,%esp
    vcprintf(fmt, ap);
c010040e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100411:	83 ec 08             	sub    $0x8,%esp
c0100414:	50                   	push   %eax
c0100415:	ff 75 10             	pushl  0x10(%ebp)
c0100418:	e8 2d fe ff ff       	call   c010024a <vcprintf>
c010041d:	83 c4 10             	add    $0x10,%esp
    cprintf("\n");
c0100420:	83 ec 0c             	sub    $0xc,%esp
c0100423:	68 66 5b 10 c0       	push   $0xc0105b66
c0100428:	e8 46 fe ff ff       	call   c0100273 <cprintf>
c010042d:	83 c4 10             	add    $0x10,%esp
    
    cprintf("stack trackback:\n");
c0100430:	83 ec 0c             	sub    $0xc,%esp
c0100433:	68 68 5b 10 c0       	push   $0xc0105b68
c0100438:	e8 36 fe ff ff       	call   c0100273 <cprintf>
c010043d:	83 c4 10             	add    $0x10,%esp
    print_stackframe();
c0100440:	e8 17 06 00 00       	call   c0100a5c <print_stackframe>
c0100445:	eb 01                	jmp    c0100448 <__panic+0x6f>
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
        goto panic_dead;
c0100447:	90                   	nop
    print_stackframe();
    
    va_end(ap);

panic_dead:
    intr_disable();
c0100448:	e8 3b 14 00 00       	call   c0101888 <intr_disable>
    while (1) {
        kmonitor(NULL);
c010044d:	83 ec 0c             	sub    $0xc,%esp
c0100450:	6a 00                	push   $0x0
c0100452:	e8 36 08 00 00       	call   c0100c8d <kmonitor>
c0100457:	83 c4 10             	add    $0x10,%esp
    }
c010045a:	eb f1                	jmp    c010044d <__panic+0x74>

c010045c <__warn>:
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
c010045c:	55                   	push   %ebp
c010045d:	89 e5                	mov    %esp,%ebp
c010045f:	83 ec 18             	sub    $0x18,%esp
    va_list ap;
    va_start(ap, fmt);
c0100462:	8d 45 14             	lea    0x14(%ebp),%eax
c0100465:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
c0100468:	83 ec 04             	sub    $0x4,%esp
c010046b:	ff 75 0c             	pushl  0xc(%ebp)
c010046e:	ff 75 08             	pushl  0x8(%ebp)
c0100471:	68 7a 5b 10 c0       	push   $0xc0105b7a
c0100476:	e8 f8 fd ff ff       	call   c0100273 <cprintf>
c010047b:	83 c4 10             	add    $0x10,%esp
    vcprintf(fmt, ap);
c010047e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100481:	83 ec 08             	sub    $0x8,%esp
c0100484:	50                   	push   %eax
c0100485:	ff 75 10             	pushl  0x10(%ebp)
c0100488:	e8 bd fd ff ff       	call   c010024a <vcprintf>
c010048d:	83 c4 10             	add    $0x10,%esp
    cprintf("\n");
c0100490:	83 ec 0c             	sub    $0xc,%esp
c0100493:	68 66 5b 10 c0       	push   $0xc0105b66
c0100498:	e8 d6 fd ff ff       	call   c0100273 <cprintf>
c010049d:	83 c4 10             	add    $0x10,%esp
    va_end(ap);
}
c01004a0:	90                   	nop
c01004a1:	c9                   	leave  
c01004a2:	c3                   	ret    

c01004a3 <is_kernel_panic>:

bool
is_kernel_panic(void) {
c01004a3:	55                   	push   %ebp
c01004a4:	89 e5                	mov    %esp,%ebp
    return is_panic;
c01004a6:	a1 20 a4 11 c0       	mov    0xc011a420,%eax
}
c01004ab:	5d                   	pop    %ebp
c01004ac:	c3                   	ret    

c01004ad <stab_binsearch>:
 *      stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
 * will exit setting left = 118, right = 554.
 * */
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
c01004ad:	55                   	push   %ebp
c01004ae:	89 e5                	mov    %esp,%ebp
c01004b0:	83 ec 20             	sub    $0x20,%esp
    int l = *region_left, r = *region_right, any_matches = 0;
c01004b3:	8b 45 0c             	mov    0xc(%ebp),%eax
c01004b6:	8b 00                	mov    (%eax),%eax
c01004b8:	89 45 fc             	mov    %eax,-0x4(%ebp)
c01004bb:	8b 45 10             	mov    0x10(%ebp),%eax
c01004be:	8b 00                	mov    (%eax),%eax
c01004c0:	89 45 f8             	mov    %eax,-0x8(%ebp)
c01004c3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

    while (l <= r) {
c01004ca:	e9 d2 00 00 00       	jmp    c01005a1 <stab_binsearch+0xf4>
        int true_m = (l + r) / 2, m = true_m;
c01004cf:	8b 55 fc             	mov    -0x4(%ebp),%edx
c01004d2:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01004d5:	01 d0                	add    %edx,%eax
c01004d7:	89 c2                	mov    %eax,%edx
c01004d9:	c1 ea 1f             	shr    $0x1f,%edx
c01004dc:	01 d0                	add    %edx,%eax
c01004de:	d1 f8                	sar    %eax
c01004e0:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01004e3:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01004e6:	89 45 f0             	mov    %eax,-0x10(%ebp)

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
c01004e9:	eb 04                	jmp    c01004ef <stab_binsearch+0x42>
            m --;
c01004eb:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)

    while (l <= r) {
        int true_m = (l + r) / 2, m = true_m;

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
c01004ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01004f2:	3b 45 fc             	cmp    -0x4(%ebp),%eax
c01004f5:	7c 1f                	jl     c0100516 <stab_binsearch+0x69>
c01004f7:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01004fa:	89 d0                	mov    %edx,%eax
c01004fc:	01 c0                	add    %eax,%eax
c01004fe:	01 d0                	add    %edx,%eax
c0100500:	c1 e0 02             	shl    $0x2,%eax
c0100503:	89 c2                	mov    %eax,%edx
c0100505:	8b 45 08             	mov    0x8(%ebp),%eax
c0100508:	01 d0                	add    %edx,%eax
c010050a:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c010050e:	0f b6 c0             	movzbl %al,%eax
c0100511:	3b 45 14             	cmp    0x14(%ebp),%eax
c0100514:	75 d5                	jne    c01004eb <stab_binsearch+0x3e>
            m --;
        }
        if (m < l) {    // no match in [l, m]
c0100516:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100519:	3b 45 fc             	cmp    -0x4(%ebp),%eax
c010051c:	7d 0b                	jge    c0100529 <stab_binsearch+0x7c>
            l = true_m + 1;
c010051e:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100521:	83 c0 01             	add    $0x1,%eax
c0100524:	89 45 fc             	mov    %eax,-0x4(%ebp)
            continue;
c0100527:	eb 78                	jmp    c01005a1 <stab_binsearch+0xf4>
        }

        // actual binary search
        any_matches = 1;
c0100529:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
        if (stabs[m].n_value < addr) {
c0100530:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100533:	89 d0                	mov    %edx,%eax
c0100535:	01 c0                	add    %eax,%eax
c0100537:	01 d0                	add    %edx,%eax
c0100539:	c1 e0 02             	shl    $0x2,%eax
c010053c:	89 c2                	mov    %eax,%edx
c010053e:	8b 45 08             	mov    0x8(%ebp),%eax
c0100541:	01 d0                	add    %edx,%eax
c0100543:	8b 40 08             	mov    0x8(%eax),%eax
c0100546:	3b 45 18             	cmp    0x18(%ebp),%eax
c0100549:	73 13                	jae    c010055e <stab_binsearch+0xb1>
            *region_left = m;
c010054b:	8b 45 0c             	mov    0xc(%ebp),%eax
c010054e:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100551:	89 10                	mov    %edx,(%eax)
            l = true_m + 1;
c0100553:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100556:	83 c0 01             	add    $0x1,%eax
c0100559:	89 45 fc             	mov    %eax,-0x4(%ebp)
c010055c:	eb 43                	jmp    c01005a1 <stab_binsearch+0xf4>
        } else if (stabs[m].n_value > addr) {
c010055e:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100561:	89 d0                	mov    %edx,%eax
c0100563:	01 c0                	add    %eax,%eax
c0100565:	01 d0                	add    %edx,%eax
c0100567:	c1 e0 02             	shl    $0x2,%eax
c010056a:	89 c2                	mov    %eax,%edx
c010056c:	8b 45 08             	mov    0x8(%ebp),%eax
c010056f:	01 d0                	add    %edx,%eax
c0100571:	8b 40 08             	mov    0x8(%eax),%eax
c0100574:	3b 45 18             	cmp    0x18(%ebp),%eax
c0100577:	76 16                	jbe    c010058f <stab_binsearch+0xe2>
            *region_right = m - 1;
c0100579:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010057c:	8d 50 ff             	lea    -0x1(%eax),%edx
c010057f:	8b 45 10             	mov    0x10(%ebp),%eax
c0100582:	89 10                	mov    %edx,(%eax)
            r = m - 1;
c0100584:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100587:	83 e8 01             	sub    $0x1,%eax
c010058a:	89 45 f8             	mov    %eax,-0x8(%ebp)
c010058d:	eb 12                	jmp    c01005a1 <stab_binsearch+0xf4>
        } else {
            // exact match for 'addr', but continue loop to find
            // *region_right
            *region_left = m;
c010058f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100592:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100595:	89 10                	mov    %edx,(%eax)
            l = m;
c0100597:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010059a:	89 45 fc             	mov    %eax,-0x4(%ebp)
            addr ++;
c010059d:	83 45 18 01          	addl   $0x1,0x18(%ebp)
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
    int l = *region_left, r = *region_right, any_matches = 0;

    while (l <= r) {
c01005a1:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01005a4:	3b 45 f8             	cmp    -0x8(%ebp),%eax
c01005a7:	0f 8e 22 ff ff ff    	jle    c01004cf <stab_binsearch+0x22>
            l = m;
            addr ++;
        }
    }

    if (!any_matches) {
c01005ad:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01005b1:	75 0f                	jne    c01005c2 <stab_binsearch+0x115>
        *region_right = *region_left - 1;
c01005b3:	8b 45 0c             	mov    0xc(%ebp),%eax
c01005b6:	8b 00                	mov    (%eax),%eax
c01005b8:	8d 50 ff             	lea    -0x1(%eax),%edx
c01005bb:	8b 45 10             	mov    0x10(%ebp),%eax
c01005be:	89 10                	mov    %edx,(%eax)
        l = *region_right;
        for (; l > *region_left && stabs[l].n_type != type; l --)
            /* do nothing */;
        *region_left = l;
    }
}
c01005c0:	eb 3f                	jmp    c0100601 <stab_binsearch+0x154>
    if (!any_matches) {
        *region_right = *region_left - 1;
    }
    else {
        // find rightmost region containing 'addr'
        l = *region_right;
c01005c2:	8b 45 10             	mov    0x10(%ebp),%eax
c01005c5:	8b 00                	mov    (%eax),%eax
c01005c7:	89 45 fc             	mov    %eax,-0x4(%ebp)
        for (; l > *region_left && stabs[l].n_type != type; l --)
c01005ca:	eb 04                	jmp    c01005d0 <stab_binsearch+0x123>
c01005cc:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
c01005d0:	8b 45 0c             	mov    0xc(%ebp),%eax
c01005d3:	8b 00                	mov    (%eax),%eax
c01005d5:	3b 45 fc             	cmp    -0x4(%ebp),%eax
c01005d8:	7d 1f                	jge    c01005f9 <stab_binsearch+0x14c>
c01005da:	8b 55 fc             	mov    -0x4(%ebp),%edx
c01005dd:	89 d0                	mov    %edx,%eax
c01005df:	01 c0                	add    %eax,%eax
c01005e1:	01 d0                	add    %edx,%eax
c01005e3:	c1 e0 02             	shl    $0x2,%eax
c01005e6:	89 c2                	mov    %eax,%edx
c01005e8:	8b 45 08             	mov    0x8(%ebp),%eax
c01005eb:	01 d0                	add    %edx,%eax
c01005ed:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c01005f1:	0f b6 c0             	movzbl %al,%eax
c01005f4:	3b 45 14             	cmp    0x14(%ebp),%eax
c01005f7:	75 d3                	jne    c01005cc <stab_binsearch+0x11f>
            /* do nothing */;
        *region_left = l;
c01005f9:	8b 45 0c             	mov    0xc(%ebp),%eax
c01005fc:	8b 55 fc             	mov    -0x4(%ebp),%edx
c01005ff:	89 10                	mov    %edx,(%eax)
    }
}
c0100601:	90                   	nop
c0100602:	c9                   	leave  
c0100603:	c3                   	ret    

c0100604 <debuginfo_eip>:
 * the specified instruction address, @addr.  Returns 0 if information
 * was found, and negative if not.  But even if it returns negative it
 * has stored some information into '*info'.
 * */
int
debuginfo_eip(uintptr_t addr, struct eipdebuginfo *info) {
c0100604:	55                   	push   %ebp
c0100605:	89 e5                	mov    %esp,%ebp
c0100607:	83 ec 38             	sub    $0x38,%esp
    const struct stab *stabs, *stab_end;
    const char *stabstr, *stabstr_end;

    info->eip_file = "<unknown>";
c010060a:	8b 45 0c             	mov    0xc(%ebp),%eax
c010060d:	c7 00 98 5b 10 c0    	movl   $0xc0105b98,(%eax)
    info->eip_line = 0;
c0100613:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100616:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
    info->eip_fn_name = "<unknown>";
c010061d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100620:	c7 40 08 98 5b 10 c0 	movl   $0xc0105b98,0x8(%eax)
    info->eip_fn_namelen = 9;
c0100627:	8b 45 0c             	mov    0xc(%ebp),%eax
c010062a:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
    info->eip_fn_addr = addr;
c0100631:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100634:	8b 55 08             	mov    0x8(%ebp),%edx
c0100637:	89 50 10             	mov    %edx,0x10(%eax)
    info->eip_fn_narg = 0;
c010063a:	8b 45 0c             	mov    0xc(%ebp),%eax
c010063d:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

    stabs = __STAB_BEGIN__;
c0100644:	c7 45 f4 e0 6d 10 c0 	movl   $0xc0106de0,-0xc(%ebp)
    stab_end = __STAB_END__;
c010064b:	c7 45 f0 04 1c 11 c0 	movl   $0xc0111c04,-0x10(%ebp)
    stabstr = __STABSTR_BEGIN__;
c0100652:	c7 45 ec 05 1c 11 c0 	movl   $0xc0111c05,-0x14(%ebp)
    stabstr_end = __STABSTR_END__;
c0100659:	c7 45 e8 76 46 11 c0 	movl   $0xc0114676,-0x18(%ebp)

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0) {
c0100660:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0100663:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0100666:	76 0d                	jbe    c0100675 <debuginfo_eip+0x71>
c0100668:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010066b:	83 e8 01             	sub    $0x1,%eax
c010066e:	0f b6 00             	movzbl (%eax),%eax
c0100671:	84 c0                	test   %al,%al
c0100673:	74 0a                	je     c010067f <debuginfo_eip+0x7b>
        return -1;
c0100675:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c010067a:	e9 91 02 00 00       	jmp    c0100910 <debuginfo_eip+0x30c>
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
c0100699:	83 e8 01             	sub    $0x1,%eax
c010069c:	89 45 e0             	mov    %eax,-0x20(%ebp)
    stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
c010069f:	ff 75 08             	pushl  0x8(%ebp)
c01006a2:	6a 64                	push   $0x64
c01006a4:	8d 45 e0             	lea    -0x20(%ebp),%eax
c01006a7:	50                   	push   %eax
c01006a8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
c01006ab:	50                   	push   %eax
c01006ac:	ff 75 f4             	pushl  -0xc(%ebp)
c01006af:	e8 f9 fd ff ff       	call   c01004ad <stab_binsearch>
c01006b4:	83 c4 14             	add    $0x14,%esp
    if (lfile == 0)
c01006b7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01006ba:	85 c0                	test   %eax,%eax
c01006bc:	75 0a                	jne    c01006c8 <debuginfo_eip+0xc4>
        return -1;
c01006be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c01006c3:	e9 48 02 00 00       	jmp    c0100910 <debuginfo_eip+0x30c>

    // Search within that file's stabs for the function definition
    // (N_FUN).
    int lfun = lfile, rfun = rfile;
c01006c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01006cb:	89 45 dc             	mov    %eax,-0x24(%ebp)
c01006ce:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01006d1:	89 45 d8             	mov    %eax,-0x28(%ebp)
    int lline, rline;
    stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
c01006d4:	ff 75 08             	pushl  0x8(%ebp)
c01006d7:	6a 24                	push   $0x24
c01006d9:	8d 45 d8             	lea    -0x28(%ebp),%eax
c01006dc:	50                   	push   %eax
c01006dd:	8d 45 dc             	lea    -0x24(%ebp),%eax
c01006e0:	50                   	push   %eax
c01006e1:	ff 75 f4             	pushl  -0xc(%ebp)
c01006e4:	e8 c4 fd ff ff       	call   c01004ad <stab_binsearch>
c01006e9:	83 c4 14             	add    $0x14,%esp

    if (lfun <= rfun) {
c01006ec:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01006ef:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01006f2:	39 c2                	cmp    %eax,%edx
c01006f4:	7f 7c                	jg     c0100772 <debuginfo_eip+0x16e>
        // stabs[lfun] points to the function name
        // in the string table, but check bounds just in case.
        if (stabs[lfun].n_strx < stabstr_end - stabstr) {
c01006f6:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01006f9:	89 c2                	mov    %eax,%edx
c01006fb:	89 d0                	mov    %edx,%eax
c01006fd:	01 c0                	add    %eax,%eax
c01006ff:	01 d0                	add    %edx,%eax
c0100701:	c1 e0 02             	shl    $0x2,%eax
c0100704:	89 c2                	mov    %eax,%edx
c0100706:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100709:	01 d0                	add    %edx,%eax
c010070b:	8b 00                	mov    (%eax),%eax
c010070d:	8b 4d e8             	mov    -0x18(%ebp),%ecx
c0100710:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0100713:	29 d1                	sub    %edx,%ecx
c0100715:	89 ca                	mov    %ecx,%edx
c0100717:	39 d0                	cmp    %edx,%eax
c0100719:	73 22                	jae    c010073d <debuginfo_eip+0x139>
            info->eip_fn_name = stabstr + stabs[lfun].n_strx;
c010071b:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010071e:	89 c2                	mov    %eax,%edx
c0100720:	89 d0                	mov    %edx,%eax
c0100722:	01 c0                	add    %eax,%eax
c0100724:	01 d0                	add    %edx,%eax
c0100726:	c1 e0 02             	shl    $0x2,%eax
c0100729:	89 c2                	mov    %eax,%edx
c010072b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010072e:	01 d0                	add    %edx,%eax
c0100730:	8b 10                	mov    (%eax),%edx
c0100732:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100735:	01 c2                	add    %eax,%edx
c0100737:	8b 45 0c             	mov    0xc(%ebp),%eax
c010073a:	89 50 08             	mov    %edx,0x8(%eax)
        }
        info->eip_fn_addr = stabs[lfun].n_value;
c010073d:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100740:	89 c2                	mov    %eax,%edx
c0100742:	89 d0                	mov    %edx,%eax
c0100744:	01 c0                	add    %eax,%eax
c0100746:	01 d0                	add    %edx,%eax
c0100748:	c1 e0 02             	shl    $0x2,%eax
c010074b:	89 c2                	mov    %eax,%edx
c010074d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100750:	01 d0                	add    %edx,%eax
c0100752:	8b 50 08             	mov    0x8(%eax),%edx
c0100755:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100758:	89 50 10             	mov    %edx,0x10(%eax)
        addr -= info->eip_fn_addr;
c010075b:	8b 45 0c             	mov    0xc(%ebp),%eax
c010075e:	8b 40 10             	mov    0x10(%eax),%eax
c0100761:	29 45 08             	sub    %eax,0x8(%ebp)
        // Search within the function definition for the line number.
        lline = lfun;
c0100764:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100767:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfun;
c010076a:	8b 45 d8             	mov    -0x28(%ebp),%eax
c010076d:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0100770:	eb 15                	jmp    c0100787 <debuginfo_eip+0x183>
    } else {
        // Couldn't find function stab!  Maybe we're in an assembly
        // file.  Search the whole file for the line number.
        info->eip_fn_addr = addr;
c0100772:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100775:	8b 55 08             	mov    0x8(%ebp),%edx
c0100778:	89 50 10             	mov    %edx,0x10(%eax)
        lline = lfile;
c010077b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010077e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfile;
c0100781:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0100784:	89 45 d0             	mov    %eax,-0x30(%ebp)
    }
    info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
c0100787:	8b 45 0c             	mov    0xc(%ebp),%eax
c010078a:	8b 40 08             	mov    0x8(%eax),%eax
c010078d:	83 ec 08             	sub    $0x8,%esp
c0100790:	6a 3a                	push   $0x3a
c0100792:	50                   	push   %eax
c0100793:	e8 cf 49 00 00       	call   c0105167 <strfind>
c0100798:	83 c4 10             	add    $0x10,%esp
c010079b:	89 c2                	mov    %eax,%edx
c010079d:	8b 45 0c             	mov    0xc(%ebp),%eax
c01007a0:	8b 40 08             	mov    0x8(%eax),%eax
c01007a3:	29 c2                	sub    %eax,%edx
c01007a5:	8b 45 0c             	mov    0xc(%ebp),%eax
c01007a8:	89 50 0c             	mov    %edx,0xc(%eax)

    // Search within [lline, rline] for the line number stab.
    // If found, set info->eip_line to the right line number.
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
c01007ab:	83 ec 0c             	sub    $0xc,%esp
c01007ae:	ff 75 08             	pushl  0x8(%ebp)
c01007b1:	6a 44                	push   $0x44
c01007b3:	8d 45 d0             	lea    -0x30(%ebp),%eax
c01007b6:	50                   	push   %eax
c01007b7:	8d 45 d4             	lea    -0x2c(%ebp),%eax
c01007ba:	50                   	push   %eax
c01007bb:	ff 75 f4             	pushl  -0xc(%ebp)
c01007be:	e8 ea fc ff ff       	call   c01004ad <stab_binsearch>
c01007c3:	83 c4 20             	add    $0x20,%esp
    if (lline <= rline) {
c01007c6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01007c9:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01007cc:	39 c2                	cmp    %eax,%edx
c01007ce:	7f 24                	jg     c01007f4 <debuginfo_eip+0x1f0>
        info->eip_line = stabs[rline].n_desc;
c01007d0:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01007d3:	89 c2                	mov    %eax,%edx
c01007d5:	89 d0                	mov    %edx,%eax
c01007d7:	01 c0                	add    %eax,%eax
c01007d9:	01 d0                	add    %edx,%eax
c01007db:	c1 e0 02             	shl    $0x2,%eax
c01007de:	89 c2                	mov    %eax,%edx
c01007e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01007e3:	01 d0                	add    %edx,%eax
c01007e5:	0f b7 40 06          	movzwl 0x6(%eax),%eax
c01007e9:	0f b7 d0             	movzwl %ax,%edx
c01007ec:	8b 45 0c             	mov    0xc(%ebp),%eax
c01007ef:	89 50 04             	mov    %edx,0x4(%eax)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
c01007f2:	eb 13                	jmp    c0100807 <debuginfo_eip+0x203>
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
    if (lline <= rline) {
        info->eip_line = stabs[rline].n_desc;
    } else {
        return -1;
c01007f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c01007f9:	e9 12 01 00 00       	jmp    c0100910 <debuginfo_eip+0x30c>
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
           && stabs[lline].n_type != N_SOL
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
        lline --;
c01007fe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100801:	83 e8 01             	sub    $0x1,%eax
c0100804:	89 45 d4             	mov    %eax,-0x2c(%ebp)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
c0100807:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c010080a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010080d:	39 c2                	cmp    %eax,%edx
c010080f:	7c 56                	jl     c0100867 <debuginfo_eip+0x263>
           && stabs[lline].n_type != N_SOL
c0100811:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100814:	89 c2                	mov    %eax,%edx
c0100816:	89 d0                	mov    %edx,%eax
c0100818:	01 c0                	add    %eax,%eax
c010081a:	01 d0                	add    %edx,%eax
c010081c:	c1 e0 02             	shl    $0x2,%eax
c010081f:	89 c2                	mov    %eax,%edx
c0100821:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100824:	01 d0                	add    %edx,%eax
c0100826:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c010082a:	3c 84                	cmp    $0x84,%al
c010082c:	74 39                	je     c0100867 <debuginfo_eip+0x263>
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
c010082e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100831:	89 c2                	mov    %eax,%edx
c0100833:	89 d0                	mov    %edx,%eax
c0100835:	01 c0                	add    %eax,%eax
c0100837:	01 d0                	add    %edx,%eax
c0100839:	c1 e0 02             	shl    $0x2,%eax
c010083c:	89 c2                	mov    %eax,%edx
c010083e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100841:	01 d0                	add    %edx,%eax
c0100843:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c0100847:	3c 64                	cmp    $0x64,%al
c0100849:	75 b3                	jne    c01007fe <debuginfo_eip+0x1fa>
c010084b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010084e:	89 c2                	mov    %eax,%edx
c0100850:	89 d0                	mov    %edx,%eax
c0100852:	01 c0                	add    %eax,%eax
c0100854:	01 d0                	add    %edx,%eax
c0100856:	c1 e0 02             	shl    $0x2,%eax
c0100859:	89 c2                	mov    %eax,%edx
c010085b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010085e:	01 d0                	add    %edx,%eax
c0100860:	8b 40 08             	mov    0x8(%eax),%eax
c0100863:	85 c0                	test   %eax,%eax
c0100865:	74 97                	je     c01007fe <debuginfo_eip+0x1fa>
        lline --;
    }
    if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr) {
c0100867:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c010086a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010086d:	39 c2                	cmp    %eax,%edx
c010086f:	7c 46                	jl     c01008b7 <debuginfo_eip+0x2b3>
c0100871:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100874:	89 c2                	mov    %eax,%edx
c0100876:	89 d0                	mov    %edx,%eax
c0100878:	01 c0                	add    %eax,%eax
c010087a:	01 d0                	add    %edx,%eax
c010087c:	c1 e0 02             	shl    $0x2,%eax
c010087f:	89 c2                	mov    %eax,%edx
c0100881:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100884:	01 d0                	add    %edx,%eax
c0100886:	8b 00                	mov    (%eax),%eax
c0100888:	8b 4d e8             	mov    -0x18(%ebp),%ecx
c010088b:	8b 55 ec             	mov    -0x14(%ebp),%edx
c010088e:	29 d1                	sub    %edx,%ecx
c0100890:	89 ca                	mov    %ecx,%edx
c0100892:	39 d0                	cmp    %edx,%eax
c0100894:	73 21                	jae    c01008b7 <debuginfo_eip+0x2b3>
        info->eip_file = stabstr + stabs[lline].n_strx;
c0100896:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100899:	89 c2                	mov    %eax,%edx
c010089b:	89 d0                	mov    %edx,%eax
c010089d:	01 c0                	add    %eax,%eax
c010089f:	01 d0                	add    %edx,%eax
c01008a1:	c1 e0 02             	shl    $0x2,%eax
c01008a4:	89 c2                	mov    %eax,%edx
c01008a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01008a9:	01 d0                	add    %edx,%eax
c01008ab:	8b 10                	mov    (%eax),%edx
c01008ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01008b0:	01 c2                	add    %eax,%edx
c01008b2:	8b 45 0c             	mov    0xc(%ebp),%eax
c01008b5:	89 10                	mov    %edx,(%eax)
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
c01008b7:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01008ba:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01008bd:	39 c2                	cmp    %eax,%edx
c01008bf:	7d 4a                	jge    c010090b <debuginfo_eip+0x307>
        for (lline = lfun + 1;
c01008c1:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01008c4:	83 c0 01             	add    $0x1,%eax
c01008c7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
c01008ca:	eb 18                	jmp    c01008e4 <debuginfo_eip+0x2e0>
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
            info->eip_fn_narg ++;
c01008cc:	8b 45 0c             	mov    0xc(%ebp),%eax
c01008cf:	8b 40 14             	mov    0x14(%eax),%eax
c01008d2:	8d 50 01             	lea    0x1(%eax),%edx
c01008d5:	8b 45 0c             	mov    0xc(%ebp),%eax
c01008d8:	89 50 14             	mov    %edx,0x14(%eax)
    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
c01008db:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01008de:	83 c0 01             	add    $0x1,%eax
c01008e1:	89 45 d4             	mov    %eax,-0x2c(%ebp)

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM;
c01008e4:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01008e7:	8b 45 d8             	mov    -0x28(%ebp),%eax
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
c01008ea:	39 c2                	cmp    %eax,%edx
c01008ec:	7d 1d                	jge    c010090b <debuginfo_eip+0x307>
             lline < rfun && stabs[lline].n_type == N_PSYM;
c01008ee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01008f1:	89 c2                	mov    %eax,%edx
c01008f3:	89 d0                	mov    %edx,%eax
c01008f5:	01 c0                	add    %eax,%eax
c01008f7:	01 d0                	add    %edx,%eax
c01008f9:	c1 e0 02             	shl    $0x2,%eax
c01008fc:	89 c2                	mov    %eax,%edx
c01008fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100901:	01 d0                	add    %edx,%eax
c0100903:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c0100907:	3c a0                	cmp    $0xa0,%al
c0100909:	74 c1                	je     c01008cc <debuginfo_eip+0x2c8>
             lline ++) {
            info->eip_fn_narg ++;
        }
    }
    return 0;
c010090b:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100910:	c9                   	leave  
c0100911:	c3                   	ret    

c0100912 <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void
print_kerninfo(void) {
c0100912:	55                   	push   %ebp
c0100913:	89 e5                	mov    %esp,%ebp
c0100915:	83 ec 08             	sub    $0x8,%esp
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
c0100918:	83 ec 0c             	sub    $0xc,%esp
c010091b:	68 a2 5b 10 c0       	push   $0xc0105ba2
c0100920:	e8 4e f9 ff ff       	call   c0100273 <cprintf>
c0100925:	83 c4 10             	add    $0x10,%esp
    cprintf("  entry  0x%08x (phys)\n", kern_init);
c0100928:	83 ec 08             	sub    $0x8,%esp
c010092b:	68 36 00 10 c0       	push   $0xc0100036
c0100930:	68 bb 5b 10 c0       	push   $0xc0105bbb
c0100935:	e8 39 f9 ff ff       	call   c0100273 <cprintf>
c010093a:	83 c4 10             	add    $0x10,%esp
    cprintf("  etext  0x%08x (phys)\n", etext);
c010093d:	83 ec 08             	sub    $0x8,%esp
c0100940:	68 8a 5a 10 c0       	push   $0xc0105a8a
c0100945:	68 d3 5b 10 c0       	push   $0xc0105bd3
c010094a:	e8 24 f9 ff ff       	call   c0100273 <cprintf>
c010094f:	83 c4 10             	add    $0x10,%esp
    cprintf("  edata  0x%08x (phys)\n", edata);
c0100952:	83 ec 08             	sub    $0x8,%esp
c0100955:	68 00 a0 11 c0       	push   $0xc011a000
c010095a:	68 eb 5b 10 c0       	push   $0xc0105beb
c010095f:	e8 0f f9 ff ff       	call   c0100273 <cprintf>
c0100964:	83 c4 10             	add    $0x10,%esp
    cprintf("  end    0x%08x (phys)\n", end);
c0100967:	83 ec 08             	sub    $0x8,%esp
c010096a:	68 28 af 11 c0       	push   $0xc011af28
c010096f:	68 03 5c 10 c0       	push   $0xc0105c03
c0100974:	e8 fa f8 ff ff       	call   c0100273 <cprintf>
c0100979:	83 c4 10             	add    $0x10,%esp
    cprintf("Kernel executable memory footprint: %dKB\n", (end - kern_init + 1023)/1024);
c010097c:	b8 28 af 11 c0       	mov    $0xc011af28,%eax
c0100981:	05 ff 03 00 00       	add    $0x3ff,%eax
c0100986:	ba 36 00 10 c0       	mov    $0xc0100036,%edx
c010098b:	29 d0                	sub    %edx,%eax
c010098d:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
c0100993:	85 c0                	test   %eax,%eax
c0100995:	0f 48 c2             	cmovs  %edx,%eax
c0100998:	c1 f8 0a             	sar    $0xa,%eax
c010099b:	83 ec 08             	sub    $0x8,%esp
c010099e:	50                   	push   %eax
c010099f:	68 1c 5c 10 c0       	push   $0xc0105c1c
c01009a4:	e8 ca f8 ff ff       	call   c0100273 <cprintf>
c01009a9:	83 c4 10             	add    $0x10,%esp
}
c01009ac:	90                   	nop
c01009ad:	c9                   	leave  
c01009ae:	c3                   	ret    

c01009af <print_debuginfo>:
/* *
 * print_debuginfo - read and print the stat information for the address @eip,
 * and info.eip_fn_addr should be the first address of the related function.
 * */
void
print_debuginfo(uintptr_t eip) {
c01009af:	55                   	push   %ebp
c01009b0:	89 e5                	mov    %esp,%ebp
c01009b2:	81 ec 28 01 00 00    	sub    $0x128,%esp
    struct eipdebuginfo info;
    if (debuginfo_eip(eip, &info) != 0) {
c01009b8:	83 ec 08             	sub    $0x8,%esp
c01009bb:	8d 45 dc             	lea    -0x24(%ebp),%eax
c01009be:	50                   	push   %eax
c01009bf:	ff 75 08             	pushl  0x8(%ebp)
c01009c2:	e8 3d fc ff ff       	call   c0100604 <debuginfo_eip>
c01009c7:	83 c4 10             	add    $0x10,%esp
c01009ca:	85 c0                	test   %eax,%eax
c01009cc:	74 15                	je     c01009e3 <print_debuginfo+0x34>
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
c01009ce:	83 ec 08             	sub    $0x8,%esp
c01009d1:	ff 75 08             	pushl  0x8(%ebp)
c01009d4:	68 46 5c 10 c0       	push   $0xc0105c46
c01009d9:	e8 95 f8 ff ff       	call   c0100273 <cprintf>
c01009de:	83 c4 10             	add    $0x10,%esp
        }
        fnname[j] = '\0';
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
                fnname, eip - info.eip_fn_addr);
    }
}
c01009e1:	eb 65                	jmp    c0100a48 <print_debuginfo+0x99>
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
c01009e3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c01009ea:	eb 1c                	jmp    c0100a08 <print_debuginfo+0x59>
            fnname[j] = info.eip_fn_name[j];
c01009ec:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01009ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01009f2:	01 d0                	add    %edx,%eax
c01009f4:	0f b6 00             	movzbl (%eax),%eax
c01009f7:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
c01009fd:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100a00:	01 ca                	add    %ecx,%edx
c0100a02:	88 02                	mov    %al,(%edx)
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
c0100a04:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0100a08:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0100a0b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0100a0e:	7f dc                	jg     c01009ec <print_debuginfo+0x3d>
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
c0100a10:	8d 95 dc fe ff ff    	lea    -0x124(%ebp),%edx
c0100a16:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a19:	01 d0                	add    %edx,%eax
c0100a1b:	c6 00 00             	movb   $0x0,(%eax)
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
                fnname, eip - info.eip_fn_addr);
c0100a1e:	8b 45 ec             	mov    -0x14(%ebp),%eax
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
c0100a21:	8b 55 08             	mov    0x8(%ebp),%edx
c0100a24:	89 d1                	mov    %edx,%ecx
c0100a26:	29 c1                	sub    %eax,%ecx
c0100a28:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0100a2b:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100a2e:	83 ec 0c             	sub    $0xc,%esp
c0100a31:	51                   	push   %ecx
c0100a32:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
c0100a38:	51                   	push   %ecx
c0100a39:	52                   	push   %edx
c0100a3a:	50                   	push   %eax
c0100a3b:	68 62 5c 10 c0       	push   $0xc0105c62
c0100a40:	e8 2e f8 ff ff       	call   c0100273 <cprintf>
c0100a45:	83 c4 20             	add    $0x20,%esp
                fnname, eip - info.eip_fn_addr);
    }
}
c0100a48:	90                   	nop
c0100a49:	c9                   	leave  
c0100a4a:	c3                   	ret    

c0100a4b <read_eip>:

static __noinline uint32_t
read_eip(void) {
c0100a4b:	55                   	push   %ebp
c0100a4c:	89 e5                	mov    %esp,%ebp
c0100a4e:	83 ec 10             	sub    $0x10,%esp
    uint32_t eip;
    asm volatile("movl 4(%%ebp), %0" : "=r" (eip));
c0100a51:	8b 45 04             	mov    0x4(%ebp),%eax
c0100a54:	89 45 fc             	mov    %eax,-0x4(%ebp)
    return eip;
c0100a57:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0100a5a:	c9                   	leave  
c0100a5b:	c3                   	ret    

c0100a5c <print_stackframe>:
 *
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the boundary.
 * */
void
print_stackframe(void) {
c0100a5c:	55                   	push   %ebp
c0100a5d:	89 e5                	mov    %esp,%ebp
c0100a5f:	83 ec 28             	sub    $0x28,%esp
}

static inline uint32_t
read_ebp(void) {
    uint32_t ebp;
    asm volatile ("movl %%ebp, %0" : "=r" (ebp));
c0100a62:	89 e8                	mov    %ebp,%eax
c0100a64:	89 45 e0             	mov    %eax,-0x20(%ebp)
    return ebp;
c0100a67:	8b 45 e0             	mov    -0x20(%ebp),%eax
      *    (3.4) call print_debuginfo(eip-1) to print the C calling function name and line number, etc.
      *    (3.5) popup a calling stackframe
      *           NOTICE: the calling funciton's return addr eip  = ss:[ebp+4]
      *                   the calling funciton's ebp = ss:[ebp]
      */
    uint32_t ebp = read_ebp(), eip = read_eip();
c0100a6a:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0100a6d:	e8 d9 ff ff ff       	call   c0100a4b <read_eip>
c0100a72:	89 45 f0             	mov    %eax,-0x10(%ebp)

    int i, j;
    for (i = 0; ebp != 0 && i < STACKFRAME_DEPTH; i ++) {
c0100a75:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
c0100a7c:	e9 8d 00 00 00       	jmp    c0100b0e <print_stackframe+0xb2>
        cprintf("ebp:0x%08x eip:0x%08x args:", ebp, eip);
c0100a81:	83 ec 04             	sub    $0x4,%esp
c0100a84:	ff 75 f0             	pushl  -0x10(%ebp)
c0100a87:	ff 75 f4             	pushl  -0xc(%ebp)
c0100a8a:	68 74 5c 10 c0       	push   $0xc0105c74
c0100a8f:	e8 df f7 ff ff       	call   c0100273 <cprintf>
c0100a94:	83 c4 10             	add    $0x10,%esp
        uint32_t *args = (uint32_t *)ebp + 2;
c0100a97:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a9a:	83 c0 08             	add    $0x8,%eax
c0100a9d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        for (j = 0; j < 4; j ++) {
c0100aa0:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
c0100aa7:	eb 26                	jmp    c0100acf <print_stackframe+0x73>
            cprintf("0x%08x ", args[j]);
c0100aa9:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0100aac:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0100ab3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100ab6:	01 d0                	add    %edx,%eax
c0100ab8:	8b 00                	mov    (%eax),%eax
c0100aba:	83 ec 08             	sub    $0x8,%esp
c0100abd:	50                   	push   %eax
c0100abe:	68 90 5c 10 c0       	push   $0xc0105c90
c0100ac3:	e8 ab f7 ff ff       	call   c0100273 <cprintf>
c0100ac8:	83 c4 10             	add    $0x10,%esp

    int i, j;
    for (i = 0; ebp != 0 && i < STACKFRAME_DEPTH; i ++) {
        cprintf("ebp:0x%08x eip:0x%08x args:", ebp, eip);
        uint32_t *args = (uint32_t *)ebp + 2;
        for (j = 0; j < 4; j ++) {
c0100acb:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
c0100acf:	83 7d e8 03          	cmpl   $0x3,-0x18(%ebp)
c0100ad3:	7e d4                	jle    c0100aa9 <print_stackframe+0x4d>
            cprintf("0x%08x ", args[j]);
        }
        cprintf("\n");
c0100ad5:	83 ec 0c             	sub    $0xc,%esp
c0100ad8:	68 98 5c 10 c0       	push   $0xc0105c98
c0100add:	e8 91 f7 ff ff       	call   c0100273 <cprintf>
c0100ae2:	83 c4 10             	add    $0x10,%esp
        print_debuginfo(eip - 1);
c0100ae5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100ae8:	83 e8 01             	sub    $0x1,%eax
c0100aeb:	83 ec 0c             	sub    $0xc,%esp
c0100aee:	50                   	push   %eax
c0100aef:	e8 bb fe ff ff       	call   c01009af <print_debuginfo>
c0100af4:	83 c4 10             	add    $0x10,%esp
        eip = ((uint32_t *)ebp)[1];
c0100af7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100afa:	83 c0 04             	add    $0x4,%eax
c0100afd:	8b 00                	mov    (%eax),%eax
c0100aff:	89 45 f0             	mov    %eax,-0x10(%ebp)
        ebp = ((uint32_t *)ebp)[0];
c0100b02:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100b05:	8b 00                	mov    (%eax),%eax
c0100b07:	89 45 f4             	mov    %eax,-0xc(%ebp)
      *                   the calling funciton's ebp = ss:[ebp]
      */
    uint32_t ebp = read_ebp(), eip = read_eip();

    int i, j;
    for (i = 0; ebp != 0 && i < STACKFRAME_DEPTH; i ++) {
c0100b0a:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
c0100b0e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0100b12:	74 0a                	je     c0100b1e <print_stackframe+0xc2>
c0100b14:	83 7d ec 13          	cmpl   $0x13,-0x14(%ebp)
c0100b18:	0f 8e 63 ff ff ff    	jle    c0100a81 <print_stackframe+0x25>
        cprintf("\n");
        print_debuginfo(eip - 1);
        eip = ((uint32_t *)ebp)[1];
        ebp = ((uint32_t *)ebp)[0];
    }
}
c0100b1e:	90                   	nop
c0100b1f:	c9                   	leave  
c0100b20:	c3                   	ret    

c0100b21 <parse>:
#define MAXARGS         16
#define WHITESPACE      " \t\n\r"

/* parse - parse the command buffer into whitespace-separated arguments */
static int
parse(char *buf, char **argv) {
c0100b21:	55                   	push   %ebp
c0100b22:	89 e5                	mov    %esp,%ebp
c0100b24:	83 ec 18             	sub    $0x18,%esp
    int argc = 0;
c0100b27:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
c0100b2e:	eb 0c                	jmp    c0100b3c <parse+0x1b>
            *buf ++ = '\0';
c0100b30:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b33:	8d 50 01             	lea    0x1(%eax),%edx
c0100b36:	89 55 08             	mov    %edx,0x8(%ebp)
c0100b39:	c6 00 00             	movb   $0x0,(%eax)
static int
parse(char *buf, char **argv) {
    int argc = 0;
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
c0100b3c:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b3f:	0f b6 00             	movzbl (%eax),%eax
c0100b42:	84 c0                	test   %al,%al
c0100b44:	74 1e                	je     c0100b64 <parse+0x43>
c0100b46:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b49:	0f b6 00             	movzbl (%eax),%eax
c0100b4c:	0f be c0             	movsbl %al,%eax
c0100b4f:	83 ec 08             	sub    $0x8,%esp
c0100b52:	50                   	push   %eax
c0100b53:	68 1c 5d 10 c0       	push   $0xc0105d1c
c0100b58:	e8 d7 45 00 00       	call   c0105134 <strchr>
c0100b5d:	83 c4 10             	add    $0x10,%esp
c0100b60:	85 c0                	test   %eax,%eax
c0100b62:	75 cc                	jne    c0100b30 <parse+0xf>
            *buf ++ = '\0';
        }
        if (*buf == '\0') {
c0100b64:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b67:	0f b6 00             	movzbl (%eax),%eax
c0100b6a:	84 c0                	test   %al,%al
c0100b6c:	74 69                	je     c0100bd7 <parse+0xb6>
            break;
        }

        // save and scan past next arg
        if (argc == MAXARGS - 1) {
c0100b6e:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
c0100b72:	75 12                	jne    c0100b86 <parse+0x65>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
c0100b74:	83 ec 08             	sub    $0x8,%esp
c0100b77:	6a 10                	push   $0x10
c0100b79:	68 21 5d 10 c0       	push   $0xc0105d21
c0100b7e:	e8 f0 f6 ff ff       	call   c0100273 <cprintf>
c0100b83:	83 c4 10             	add    $0x10,%esp
        }
        argv[argc ++] = buf;
c0100b86:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100b89:	8d 50 01             	lea    0x1(%eax),%edx
c0100b8c:	89 55 f4             	mov    %edx,-0xc(%ebp)
c0100b8f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0100b96:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100b99:	01 c2                	add    %eax,%edx
c0100b9b:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b9e:	89 02                	mov    %eax,(%edx)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
c0100ba0:	eb 04                	jmp    c0100ba6 <parse+0x85>
            buf ++;
c0100ba2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
        // save and scan past next arg
        if (argc == MAXARGS - 1) {
            cprintf("Too many arguments (max %d).\n", MAXARGS);
        }
        argv[argc ++] = buf;
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
c0100ba6:	8b 45 08             	mov    0x8(%ebp),%eax
c0100ba9:	0f b6 00             	movzbl (%eax),%eax
c0100bac:	84 c0                	test   %al,%al
c0100bae:	0f 84 7a ff ff ff    	je     c0100b2e <parse+0xd>
c0100bb4:	8b 45 08             	mov    0x8(%ebp),%eax
c0100bb7:	0f b6 00             	movzbl (%eax),%eax
c0100bba:	0f be c0             	movsbl %al,%eax
c0100bbd:	83 ec 08             	sub    $0x8,%esp
c0100bc0:	50                   	push   %eax
c0100bc1:	68 1c 5d 10 c0       	push   $0xc0105d1c
c0100bc6:	e8 69 45 00 00       	call   c0105134 <strchr>
c0100bcb:	83 c4 10             	add    $0x10,%esp
c0100bce:	85 c0                	test   %eax,%eax
c0100bd0:	74 d0                	je     c0100ba2 <parse+0x81>
            buf ++;
        }
    }
c0100bd2:	e9 57 ff ff ff       	jmp    c0100b2e <parse+0xd>
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
            *buf ++ = '\0';
        }
        if (*buf == '\0') {
            break;
c0100bd7:	90                   	nop
        argv[argc ++] = buf;
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
            buf ++;
        }
    }
    return argc;
c0100bd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0100bdb:	c9                   	leave  
c0100bdc:	c3                   	ret    

c0100bdd <runcmd>:
/* *
 * runcmd - parse the input string, split it into separated arguments
 * and then lookup and invoke some related commands/
 * */
static int
runcmd(char *buf, struct trapframe *tf) {
c0100bdd:	55                   	push   %ebp
c0100bde:	89 e5                	mov    %esp,%ebp
c0100be0:	83 ec 58             	sub    $0x58,%esp
    char *argv[MAXARGS];
    int argc = parse(buf, argv);
c0100be3:	83 ec 08             	sub    $0x8,%esp
c0100be6:	8d 45 b0             	lea    -0x50(%ebp),%eax
c0100be9:	50                   	push   %eax
c0100bea:	ff 75 08             	pushl  0x8(%ebp)
c0100bed:	e8 2f ff ff ff       	call   c0100b21 <parse>
c0100bf2:	83 c4 10             	add    $0x10,%esp
c0100bf5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if (argc == 0) {
c0100bf8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0100bfc:	75 0a                	jne    c0100c08 <runcmd+0x2b>
        return 0;
c0100bfe:	b8 00 00 00 00       	mov    $0x0,%eax
c0100c03:	e9 83 00 00 00       	jmp    c0100c8b <runcmd+0xae>
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100c08:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0100c0f:	eb 59                	jmp    c0100c6a <runcmd+0x8d>
        if (strcmp(commands[i].name, argv[0]) == 0) {
c0100c11:	8b 4d b0             	mov    -0x50(%ebp),%ecx
c0100c14:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100c17:	89 d0                	mov    %edx,%eax
c0100c19:	01 c0                	add    %eax,%eax
c0100c1b:	01 d0                	add    %edx,%eax
c0100c1d:	c1 e0 02             	shl    $0x2,%eax
c0100c20:	05 00 70 11 c0       	add    $0xc0117000,%eax
c0100c25:	8b 00                	mov    (%eax),%eax
c0100c27:	83 ec 08             	sub    $0x8,%esp
c0100c2a:	51                   	push   %ecx
c0100c2b:	50                   	push   %eax
c0100c2c:	e8 63 44 00 00       	call   c0105094 <strcmp>
c0100c31:	83 c4 10             	add    $0x10,%esp
c0100c34:	85 c0                	test   %eax,%eax
c0100c36:	75 2e                	jne    c0100c66 <runcmd+0x89>
            return commands[i].func(argc - 1, argv + 1, tf);
c0100c38:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100c3b:	89 d0                	mov    %edx,%eax
c0100c3d:	01 c0                	add    %eax,%eax
c0100c3f:	01 d0                	add    %edx,%eax
c0100c41:	c1 e0 02             	shl    $0x2,%eax
c0100c44:	05 08 70 11 c0       	add    $0xc0117008,%eax
c0100c49:	8b 10                	mov    (%eax),%edx
c0100c4b:	8d 45 b0             	lea    -0x50(%ebp),%eax
c0100c4e:	83 c0 04             	add    $0x4,%eax
c0100c51:	8b 4d f0             	mov    -0x10(%ebp),%ecx
c0100c54:	83 e9 01             	sub    $0x1,%ecx
c0100c57:	83 ec 04             	sub    $0x4,%esp
c0100c5a:	ff 75 0c             	pushl  0xc(%ebp)
c0100c5d:	50                   	push   %eax
c0100c5e:	51                   	push   %ecx
c0100c5f:	ff d2                	call   *%edx
c0100c61:	83 c4 10             	add    $0x10,%esp
c0100c64:	eb 25                	jmp    c0100c8b <runcmd+0xae>
    int argc = parse(buf, argv);
    if (argc == 0) {
        return 0;
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100c66:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0100c6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100c6d:	83 f8 02             	cmp    $0x2,%eax
c0100c70:	76 9f                	jbe    c0100c11 <runcmd+0x34>
        if (strcmp(commands[i].name, argv[0]) == 0) {
            return commands[i].func(argc - 1, argv + 1, tf);
        }
    }
    cprintf("Unknown command '%s'\n", argv[0]);
c0100c72:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0100c75:	83 ec 08             	sub    $0x8,%esp
c0100c78:	50                   	push   %eax
c0100c79:	68 3f 5d 10 c0       	push   $0xc0105d3f
c0100c7e:	e8 f0 f5 ff ff       	call   c0100273 <cprintf>
c0100c83:	83 c4 10             	add    $0x10,%esp
    return 0;
c0100c86:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100c8b:	c9                   	leave  
c0100c8c:	c3                   	ret    

c0100c8d <kmonitor>:

/***** Implementations of basic kernel monitor commands *****/

void
kmonitor(struct trapframe *tf) {
c0100c8d:	55                   	push   %ebp
c0100c8e:	89 e5                	mov    %esp,%ebp
c0100c90:	83 ec 18             	sub    $0x18,%esp
    cprintf("Welcome to the kernel debug monitor!!\n");
c0100c93:	83 ec 0c             	sub    $0xc,%esp
c0100c96:	68 58 5d 10 c0       	push   $0xc0105d58
c0100c9b:	e8 d3 f5 ff ff       	call   c0100273 <cprintf>
c0100ca0:	83 c4 10             	add    $0x10,%esp
    cprintf("Type 'help' for a list of commands.\n");
c0100ca3:	83 ec 0c             	sub    $0xc,%esp
c0100ca6:	68 80 5d 10 c0       	push   $0xc0105d80
c0100cab:	e8 c3 f5 ff ff       	call   c0100273 <cprintf>
c0100cb0:	83 c4 10             	add    $0x10,%esp

    if (tf != NULL) {
c0100cb3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0100cb7:	74 0e                	je     c0100cc7 <kmonitor+0x3a>
        print_trapframe(tf);
c0100cb9:	83 ec 0c             	sub    $0xc,%esp
c0100cbc:	ff 75 08             	pushl  0x8(%ebp)
c0100cbf:	e8 41 0d 00 00       	call   c0101a05 <print_trapframe>
c0100cc4:	83 c4 10             	add    $0x10,%esp
    }

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
c0100cc7:	83 ec 0c             	sub    $0xc,%esp
c0100cca:	68 a5 5d 10 c0       	push   $0xc0105da5
c0100ccf:	e8 43 f6 ff ff       	call   c0100317 <readline>
c0100cd4:	83 c4 10             	add    $0x10,%esp
c0100cd7:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0100cda:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0100cde:	74 e7                	je     c0100cc7 <kmonitor+0x3a>
            if (runcmd(buf, tf) < 0) {
c0100ce0:	83 ec 08             	sub    $0x8,%esp
c0100ce3:	ff 75 08             	pushl  0x8(%ebp)
c0100ce6:	ff 75 f4             	pushl  -0xc(%ebp)
c0100ce9:	e8 ef fe ff ff       	call   c0100bdd <runcmd>
c0100cee:	83 c4 10             	add    $0x10,%esp
c0100cf1:	85 c0                	test   %eax,%eax
c0100cf3:	78 02                	js     c0100cf7 <kmonitor+0x6a>
                break;
            }
        }
    }
c0100cf5:	eb d0                	jmp    c0100cc7 <kmonitor+0x3a>

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
            if (runcmd(buf, tf) < 0) {
                break;
c0100cf7:	90                   	nop
            }
        }
    }
}
c0100cf8:	90                   	nop
c0100cf9:	c9                   	leave  
c0100cfa:	c3                   	ret    

c0100cfb <mon_help>:

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
c0100cfb:	55                   	push   %ebp
c0100cfc:	89 e5                	mov    %esp,%ebp
c0100cfe:	83 ec 18             	sub    $0x18,%esp
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100d01:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0100d08:	eb 3c                	jmp    c0100d46 <mon_help+0x4b>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
c0100d0a:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100d0d:	89 d0                	mov    %edx,%eax
c0100d0f:	01 c0                	add    %eax,%eax
c0100d11:	01 d0                	add    %edx,%eax
c0100d13:	c1 e0 02             	shl    $0x2,%eax
c0100d16:	05 04 70 11 c0       	add    $0xc0117004,%eax
c0100d1b:	8b 08                	mov    (%eax),%ecx
c0100d1d:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100d20:	89 d0                	mov    %edx,%eax
c0100d22:	01 c0                	add    %eax,%eax
c0100d24:	01 d0                	add    %edx,%eax
c0100d26:	c1 e0 02             	shl    $0x2,%eax
c0100d29:	05 00 70 11 c0       	add    $0xc0117000,%eax
c0100d2e:	8b 00                	mov    (%eax),%eax
c0100d30:	83 ec 04             	sub    $0x4,%esp
c0100d33:	51                   	push   %ecx
c0100d34:	50                   	push   %eax
c0100d35:	68 a9 5d 10 c0       	push   $0xc0105da9
c0100d3a:	e8 34 f5 ff ff       	call   c0100273 <cprintf>
c0100d3f:	83 c4 10             	add    $0x10,%esp

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100d42:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0100d46:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100d49:	83 f8 02             	cmp    $0x2,%eax
c0100d4c:	76 bc                	jbe    c0100d0a <mon_help+0xf>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
    }
    return 0;
c0100d4e:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100d53:	c9                   	leave  
c0100d54:	c3                   	ret    

c0100d55 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
c0100d55:	55                   	push   %ebp
c0100d56:	89 e5                	mov    %esp,%ebp
c0100d58:	83 ec 08             	sub    $0x8,%esp
    print_kerninfo();
c0100d5b:	e8 b2 fb ff ff       	call   c0100912 <print_kerninfo>
    return 0;
c0100d60:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100d65:	c9                   	leave  
c0100d66:	c3                   	ret    

c0100d67 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
c0100d67:	55                   	push   %ebp
c0100d68:	89 e5                	mov    %esp,%ebp
c0100d6a:	83 ec 08             	sub    $0x8,%esp
    print_stackframe();
c0100d6d:	e8 ea fc ff ff       	call   c0100a5c <print_stackframe>
    return 0;
c0100d72:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100d77:	c9                   	leave  
c0100d78:	c3                   	ret    

c0100d79 <clock_init>:
/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void
clock_init(void) {
c0100d79:	55                   	push   %ebp
c0100d7a:	89 e5                	mov    %esp,%ebp
c0100d7c:	83 ec 18             	sub    $0x18,%esp
c0100d7f:	66 c7 45 f6 43 00    	movw   $0x43,-0xa(%ebp)
c0100d85:	c6 45 ef 34          	movb   $0x34,-0x11(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100d89:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
c0100d8d:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100d91:	ee                   	out    %al,(%dx)
c0100d92:	66 c7 45 f4 40 00    	movw   $0x40,-0xc(%ebp)
c0100d98:	c6 45 f0 9c          	movb   $0x9c,-0x10(%ebp)
c0100d9c:	0f b6 45 f0          	movzbl -0x10(%ebp),%eax
c0100da0:	0f b7 55 f4          	movzwl -0xc(%ebp),%edx
c0100da4:	ee                   	out    %al,(%dx)
c0100da5:	66 c7 45 f2 40 00    	movw   $0x40,-0xe(%ebp)
c0100dab:	c6 45 f1 2e          	movb   $0x2e,-0xf(%ebp)
c0100daf:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c0100db3:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0100db7:	ee                   	out    %al,(%dx)
    outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
    outb(IO_TIMER1, TIMER_DIV(100) % 256);
    outb(IO_TIMER1, TIMER_DIV(100) / 256);

    // initialize time counter 'ticks' to zero
    ticks = 0;
c0100db8:	c7 05 0c af 11 c0 00 	movl   $0x0,0xc011af0c
c0100dbf:	00 00 00 

    cprintf("++ setup timer interrupts\n");
c0100dc2:	83 ec 0c             	sub    $0xc,%esp
c0100dc5:	68 b2 5d 10 c0       	push   $0xc0105db2
c0100dca:	e8 a4 f4 ff ff       	call   c0100273 <cprintf>
c0100dcf:	83 c4 10             	add    $0x10,%esp
    pic_enable(IRQ_TIMER);
c0100dd2:	83 ec 0c             	sub    $0xc,%esp
c0100dd5:	6a 00                	push   $0x0
c0100dd7:	e8 3b 09 00 00       	call   c0101717 <pic_enable>
c0100ddc:	83 c4 10             	add    $0x10,%esp
}
c0100ddf:	90                   	nop
c0100de0:	c9                   	leave  
c0100de1:	c3                   	ret    

c0100de2 <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
c0100de2:	55                   	push   %ebp
c0100de3:	89 e5                	mov    %esp,%ebp
c0100de5:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c0100de8:	9c                   	pushf  
c0100de9:	58                   	pop    %eax
c0100dea:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c0100ded:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
c0100df0:	25 00 02 00 00       	and    $0x200,%eax
c0100df5:	85 c0                	test   %eax,%eax
c0100df7:	74 0c                	je     c0100e05 <__intr_save+0x23>
        intr_disable();
c0100df9:	e8 8a 0a 00 00       	call   c0101888 <intr_disable>
        return 1;
c0100dfe:	b8 01 00 00 00       	mov    $0x1,%eax
c0100e03:	eb 05                	jmp    c0100e0a <__intr_save+0x28>
    }
    return 0;
c0100e05:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100e0a:	c9                   	leave  
c0100e0b:	c3                   	ret    

c0100e0c <__intr_restore>:

static inline void
__intr_restore(bool flag) {
c0100e0c:	55                   	push   %ebp
c0100e0d:	89 e5                	mov    %esp,%ebp
c0100e0f:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c0100e12:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0100e16:	74 05                	je     c0100e1d <__intr_restore+0x11>
        intr_enable();
c0100e18:	e8 64 0a 00 00       	call   c0101881 <intr_enable>
    }
}
c0100e1d:	90                   	nop
c0100e1e:	c9                   	leave  
c0100e1f:	c3                   	ret    

c0100e20 <delay>:
#include <memlayout.h>
#include <sync.h>

/* stupid I/O delay routine necessitated by historical PC design flaws */
static void
delay(void) {
c0100e20:	55                   	push   %ebp
c0100e21:	89 e5                	mov    %esp,%ebp
c0100e23:	83 ec 10             	sub    $0x10,%esp
c0100e26:	66 c7 45 fe 84 00    	movw   $0x84,-0x2(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100e2c:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
c0100e30:	89 c2                	mov    %eax,%edx
c0100e32:	ec                   	in     (%dx),%al
c0100e33:	88 45 f4             	mov    %al,-0xc(%ebp)
c0100e36:	66 c7 45 fc 84 00    	movw   $0x84,-0x4(%ebp)
c0100e3c:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
c0100e40:	89 c2                	mov    %eax,%edx
c0100e42:	ec                   	in     (%dx),%al
c0100e43:	88 45 f5             	mov    %al,-0xb(%ebp)
c0100e46:	66 c7 45 fa 84 00    	movw   $0x84,-0x6(%ebp)
c0100e4c:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c0100e50:	89 c2                	mov    %eax,%edx
c0100e52:	ec                   	in     (%dx),%al
c0100e53:	88 45 f6             	mov    %al,-0xa(%ebp)
c0100e56:	66 c7 45 f8 84 00    	movw   $0x84,-0x8(%ebp)
c0100e5c:	0f b7 45 f8          	movzwl -0x8(%ebp),%eax
c0100e60:	89 c2                	mov    %eax,%edx
c0100e62:	ec                   	in     (%dx),%al
c0100e63:	88 45 f7             	mov    %al,-0x9(%ebp)
    inb(0x84);
    inb(0x84);
    inb(0x84);
    inb(0x84);
}
c0100e66:	90                   	nop
c0100e67:	c9                   	leave  
c0100e68:	c3                   	ret    

c0100e69 <cga_init>:
static uint16_t addr_6845;

/* TEXT-mode CGA/VGA display output */

static void
cga_init(void) {
c0100e69:	55                   	push   %ebp
c0100e6a:	89 e5                	mov    %esp,%ebp
c0100e6c:	83 ec 20             	sub    $0x20,%esp
    volatile uint16_t *cp = (uint16_t *)(CGA_BUF + KERNBASE);
c0100e6f:	c7 45 fc 00 80 0b c0 	movl   $0xc00b8000,-0x4(%ebp)
    uint16_t was = *cp;
c0100e76:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100e79:	0f b7 00             	movzwl (%eax),%eax
c0100e7c:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
    *cp = (uint16_t) 0xA55A;
c0100e80:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100e83:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
    if (*cp != 0xA55A) {
c0100e88:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100e8b:	0f b7 00             	movzwl (%eax),%eax
c0100e8e:	66 3d 5a a5          	cmp    $0xa55a,%ax
c0100e92:	74 12                	je     c0100ea6 <cga_init+0x3d>
        cp = (uint16_t*)(MONO_BUF + KERNBASE);
c0100e94:	c7 45 fc 00 00 0b c0 	movl   $0xc00b0000,-0x4(%ebp)
        addr_6845 = MONO_BASE;
c0100e9b:	66 c7 05 46 a4 11 c0 	movw   $0x3b4,0xc011a446
c0100ea2:	b4 03 
c0100ea4:	eb 13                	jmp    c0100eb9 <cga_init+0x50>
    } else {
        *cp = was;
c0100ea6:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100ea9:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c0100ead:	66 89 10             	mov    %dx,(%eax)
        addr_6845 = CGA_BASE;
c0100eb0:	66 c7 05 46 a4 11 c0 	movw   $0x3d4,0xc011a446
c0100eb7:	d4 03 
    }

    // Extract cursor location
    uint32_t pos;
    outb(addr_6845, 14);
c0100eb9:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c0100ec0:	0f b7 c0             	movzwl %ax,%eax
c0100ec3:	66 89 45 f8          	mov    %ax,-0x8(%ebp)
c0100ec7:	c6 45 ea 0e          	movb   $0xe,-0x16(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100ecb:	0f b6 45 ea          	movzbl -0x16(%ebp),%eax
c0100ecf:	0f b7 55 f8          	movzwl -0x8(%ebp),%edx
c0100ed3:	ee                   	out    %al,(%dx)
    pos = inb(addr_6845 + 1) << 8;
c0100ed4:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c0100edb:	83 c0 01             	add    $0x1,%eax
c0100ede:	0f b7 c0             	movzwl %ax,%eax
c0100ee1:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100ee5:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c0100ee9:	89 c2                	mov    %eax,%edx
c0100eeb:	ec                   	in     (%dx),%al
c0100eec:	88 45 eb             	mov    %al,-0x15(%ebp)
    return data;
c0100eef:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
c0100ef3:	0f b6 c0             	movzbl %al,%eax
c0100ef6:	c1 e0 08             	shl    $0x8,%eax
c0100ef9:	89 45 f4             	mov    %eax,-0xc(%ebp)
    outb(addr_6845, 15);
c0100efc:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c0100f03:	0f b7 c0             	movzwl %ax,%eax
c0100f06:	66 89 45 f0          	mov    %ax,-0x10(%ebp)
c0100f0a:	c6 45 ec 0f          	movb   $0xf,-0x14(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100f0e:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
c0100f12:	0f b7 55 f0          	movzwl -0x10(%ebp),%edx
c0100f16:	ee                   	out    %al,(%dx)
    pos |= inb(addr_6845 + 1);
c0100f17:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c0100f1e:	83 c0 01             	add    $0x1,%eax
c0100f21:	0f b7 c0             	movzwl %ax,%eax
c0100f24:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100f28:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
c0100f2c:	89 c2                	mov    %eax,%edx
c0100f2e:	ec                   	in     (%dx),%al
c0100f2f:	88 45 ed             	mov    %al,-0x13(%ebp)
    return data;
c0100f32:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c0100f36:	0f b6 c0             	movzbl %al,%eax
c0100f39:	09 45 f4             	or     %eax,-0xc(%ebp)

    crt_buf = (uint16_t*) cp;
c0100f3c:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100f3f:	a3 40 a4 11 c0       	mov    %eax,0xc011a440
    crt_pos = pos;
c0100f44:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100f47:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
}
c0100f4d:	90                   	nop
c0100f4e:	c9                   	leave  
c0100f4f:	c3                   	ret    

c0100f50 <serial_init>:

static bool serial_exists = 0;

static void
serial_init(void) {
c0100f50:	55                   	push   %ebp
c0100f51:	89 e5                	mov    %esp,%ebp
c0100f53:	83 ec 28             	sub    $0x28,%esp
c0100f56:	66 c7 45 f6 fa 03    	movw   $0x3fa,-0xa(%ebp)
c0100f5c:	c6 45 da 00          	movb   $0x0,-0x26(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100f60:	0f b6 45 da          	movzbl -0x26(%ebp),%eax
c0100f64:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100f68:	ee                   	out    %al,(%dx)
c0100f69:	66 c7 45 f4 fb 03    	movw   $0x3fb,-0xc(%ebp)
c0100f6f:	c6 45 db 80          	movb   $0x80,-0x25(%ebp)
c0100f73:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
c0100f77:	0f b7 55 f4          	movzwl -0xc(%ebp),%edx
c0100f7b:	ee                   	out    %al,(%dx)
c0100f7c:	66 c7 45 f2 f8 03    	movw   $0x3f8,-0xe(%ebp)
c0100f82:	c6 45 dc 0c          	movb   $0xc,-0x24(%ebp)
c0100f86:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
c0100f8a:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0100f8e:	ee                   	out    %al,(%dx)
c0100f8f:	66 c7 45 f0 f9 03    	movw   $0x3f9,-0x10(%ebp)
c0100f95:	c6 45 dd 00          	movb   $0x0,-0x23(%ebp)
c0100f99:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
c0100f9d:	0f b7 55 f0          	movzwl -0x10(%ebp),%edx
c0100fa1:	ee                   	out    %al,(%dx)
c0100fa2:	66 c7 45 ee fb 03    	movw   $0x3fb,-0x12(%ebp)
c0100fa8:	c6 45 de 03          	movb   $0x3,-0x22(%ebp)
c0100fac:	0f b6 45 de          	movzbl -0x22(%ebp),%eax
c0100fb0:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c0100fb4:	ee                   	out    %al,(%dx)
c0100fb5:	66 c7 45 ec fc 03    	movw   $0x3fc,-0x14(%ebp)
c0100fbb:	c6 45 df 00          	movb   $0x0,-0x21(%ebp)
c0100fbf:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
c0100fc3:	0f b7 55 ec          	movzwl -0x14(%ebp),%edx
c0100fc7:	ee                   	out    %al,(%dx)
c0100fc8:	66 c7 45 ea f9 03    	movw   $0x3f9,-0x16(%ebp)
c0100fce:	c6 45 e0 01          	movb   $0x1,-0x20(%ebp)
c0100fd2:	0f b6 45 e0          	movzbl -0x20(%ebp),%eax
c0100fd6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c0100fda:	ee                   	out    %al,(%dx)
c0100fdb:	66 c7 45 e8 fd 03    	movw   $0x3fd,-0x18(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100fe1:	0f b7 45 e8          	movzwl -0x18(%ebp),%eax
c0100fe5:	89 c2                	mov    %eax,%edx
c0100fe7:	ec                   	in     (%dx),%al
c0100fe8:	88 45 e1             	mov    %al,-0x1f(%ebp)
    return data;
c0100feb:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
    // Enable rcv interrupts
    outb(COM1 + COM_IER, COM_IER_RDI);

    // Clear any preexisting overrun indications and interrupts
    // Serial port doesn't exist if COM_LSR returns 0xFF
    serial_exists = (inb(COM1 + COM_LSR) != 0xFF);
c0100fef:	3c ff                	cmp    $0xff,%al
c0100ff1:	0f 95 c0             	setne  %al
c0100ff4:	0f b6 c0             	movzbl %al,%eax
c0100ff7:	a3 48 a4 11 c0       	mov    %eax,0xc011a448
c0100ffc:	66 c7 45 e6 fa 03    	movw   $0x3fa,-0x1a(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0101002:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax
c0101006:	89 c2                	mov    %eax,%edx
c0101008:	ec                   	in     (%dx),%al
c0101009:	88 45 e2             	mov    %al,-0x1e(%ebp)
c010100c:	66 c7 45 e4 f8 03    	movw   $0x3f8,-0x1c(%ebp)
c0101012:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
c0101016:	89 c2                	mov    %eax,%edx
c0101018:	ec                   	in     (%dx),%al
c0101019:	88 45 e3             	mov    %al,-0x1d(%ebp)
    (void) inb(COM1+COM_IIR);
    (void) inb(COM1+COM_RX);

    if (serial_exists) {
c010101c:	a1 48 a4 11 c0       	mov    0xc011a448,%eax
c0101021:	85 c0                	test   %eax,%eax
c0101023:	74 0d                	je     c0101032 <serial_init+0xe2>
        pic_enable(IRQ_COM1);
c0101025:	83 ec 0c             	sub    $0xc,%esp
c0101028:	6a 04                	push   $0x4
c010102a:	e8 e8 06 00 00       	call   c0101717 <pic_enable>
c010102f:	83 c4 10             	add    $0x10,%esp
    }
}
c0101032:	90                   	nop
c0101033:	c9                   	leave  
c0101034:	c3                   	ret    

c0101035 <lpt_putc_sub>:

static void
lpt_putc_sub(int c) {
c0101035:	55                   	push   %ebp
c0101036:	89 e5                	mov    %esp,%ebp
c0101038:	83 ec 10             	sub    $0x10,%esp
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
c010103b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c0101042:	eb 09                	jmp    c010104d <lpt_putc_sub+0x18>
        delay();
c0101044:	e8 d7 fd ff ff       	call   c0100e20 <delay>
}

static void
lpt_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
c0101049:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c010104d:	66 c7 45 f4 79 03    	movw   $0x379,-0xc(%ebp)
c0101053:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
c0101057:	89 c2                	mov    %eax,%edx
c0101059:	ec                   	in     (%dx),%al
c010105a:	88 45 f3             	mov    %al,-0xd(%ebp)
    return data;
c010105d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101061:	84 c0                	test   %al,%al
c0101063:	78 09                	js     c010106e <lpt_putc_sub+0x39>
c0101065:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
c010106c:	7e d6                	jle    c0101044 <lpt_putc_sub+0xf>
        delay();
    }
    outb(LPTPORT + 0, c);
c010106e:	8b 45 08             	mov    0x8(%ebp),%eax
c0101071:	0f b6 c0             	movzbl %al,%eax
c0101074:	66 c7 45 f8 78 03    	movw   $0x378,-0x8(%ebp)
c010107a:	88 45 f0             	mov    %al,-0x10(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c010107d:	0f b6 45 f0          	movzbl -0x10(%ebp),%eax
c0101081:	0f b7 55 f8          	movzwl -0x8(%ebp),%edx
c0101085:	ee                   	out    %al,(%dx)
c0101086:	66 c7 45 f6 7a 03    	movw   $0x37a,-0xa(%ebp)
c010108c:	c6 45 f1 0d          	movb   $0xd,-0xf(%ebp)
c0101090:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c0101094:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0101098:	ee                   	out    %al,(%dx)
c0101099:	66 c7 45 fa 7a 03    	movw   $0x37a,-0x6(%ebp)
c010109f:	c6 45 f2 08          	movb   $0x8,-0xe(%ebp)
c01010a3:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
c01010a7:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c01010ab:	ee                   	out    %al,(%dx)
    outb(LPTPORT + 2, 0x08 | 0x04 | 0x01);
    outb(LPTPORT + 2, 0x08);
}
c01010ac:	90                   	nop
c01010ad:	c9                   	leave  
c01010ae:	c3                   	ret    

c01010af <lpt_putc>:

/* lpt_putc - copy console output to parallel port */
static void
lpt_putc(int c) {
c01010af:	55                   	push   %ebp
c01010b0:	89 e5                	mov    %esp,%ebp
    if (c != '\b') {
c01010b2:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
c01010b6:	74 0d                	je     c01010c5 <lpt_putc+0x16>
        lpt_putc_sub(c);
c01010b8:	ff 75 08             	pushl  0x8(%ebp)
c01010bb:	e8 75 ff ff ff       	call   c0101035 <lpt_putc_sub>
c01010c0:	83 c4 04             	add    $0x4,%esp
    else {
        lpt_putc_sub('\b');
        lpt_putc_sub(' ');
        lpt_putc_sub('\b');
    }
}
c01010c3:	eb 1e                	jmp    c01010e3 <lpt_putc+0x34>
lpt_putc(int c) {
    if (c != '\b') {
        lpt_putc_sub(c);
    }
    else {
        lpt_putc_sub('\b');
c01010c5:	6a 08                	push   $0x8
c01010c7:	e8 69 ff ff ff       	call   c0101035 <lpt_putc_sub>
c01010cc:	83 c4 04             	add    $0x4,%esp
        lpt_putc_sub(' ');
c01010cf:	6a 20                	push   $0x20
c01010d1:	e8 5f ff ff ff       	call   c0101035 <lpt_putc_sub>
c01010d6:	83 c4 04             	add    $0x4,%esp
        lpt_putc_sub('\b');
c01010d9:	6a 08                	push   $0x8
c01010db:	e8 55 ff ff ff       	call   c0101035 <lpt_putc_sub>
c01010e0:	83 c4 04             	add    $0x4,%esp
    }
}
c01010e3:	90                   	nop
c01010e4:	c9                   	leave  
c01010e5:	c3                   	ret    

c01010e6 <cga_putc>:

/* cga_putc - print character to console */
static void
cga_putc(int c) {
c01010e6:	55                   	push   %ebp
c01010e7:	89 e5                	mov    %esp,%ebp
c01010e9:	53                   	push   %ebx
c01010ea:	83 ec 14             	sub    $0x14,%esp
    // set black on white
    if (!(c & ~0xFF)) {
c01010ed:	8b 45 08             	mov    0x8(%ebp),%eax
c01010f0:	b0 00                	mov    $0x0,%al
c01010f2:	85 c0                	test   %eax,%eax
c01010f4:	75 07                	jne    c01010fd <cga_putc+0x17>
        c |= 0x0700;
c01010f6:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)
    }

    switch (c & 0xff) {
c01010fd:	8b 45 08             	mov    0x8(%ebp),%eax
c0101100:	0f b6 c0             	movzbl %al,%eax
c0101103:	83 f8 0a             	cmp    $0xa,%eax
c0101106:	74 4e                	je     c0101156 <cga_putc+0x70>
c0101108:	83 f8 0d             	cmp    $0xd,%eax
c010110b:	74 59                	je     c0101166 <cga_putc+0x80>
c010110d:	83 f8 08             	cmp    $0x8,%eax
c0101110:	0f 85 8a 00 00 00    	jne    c01011a0 <cga_putc+0xba>
    case '\b':
        if (crt_pos > 0) {
c0101116:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c010111d:	66 85 c0             	test   %ax,%ax
c0101120:	0f 84 a0 00 00 00    	je     c01011c6 <cga_putc+0xe0>
            crt_pos --;
c0101126:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c010112d:	83 e8 01             	sub    $0x1,%eax
c0101130:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
c0101136:	a1 40 a4 11 c0       	mov    0xc011a440,%eax
c010113b:	0f b7 15 44 a4 11 c0 	movzwl 0xc011a444,%edx
c0101142:	0f b7 d2             	movzwl %dx,%edx
c0101145:	01 d2                	add    %edx,%edx
c0101147:	01 d0                	add    %edx,%eax
c0101149:	8b 55 08             	mov    0x8(%ebp),%edx
c010114c:	b2 00                	mov    $0x0,%dl
c010114e:	83 ca 20             	or     $0x20,%edx
c0101151:	66 89 10             	mov    %dx,(%eax)
        }
        break;
c0101154:	eb 70                	jmp    c01011c6 <cga_putc+0xe0>
    case '\n':
        crt_pos += CRT_COLS;
c0101156:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c010115d:	83 c0 50             	add    $0x50,%eax
c0101160:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
    case '\r':
        crt_pos -= (crt_pos % CRT_COLS);
c0101166:	0f b7 1d 44 a4 11 c0 	movzwl 0xc011a444,%ebx
c010116d:	0f b7 0d 44 a4 11 c0 	movzwl 0xc011a444,%ecx
c0101174:	0f b7 c1             	movzwl %cx,%eax
c0101177:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
c010117d:	c1 e8 10             	shr    $0x10,%eax
c0101180:	89 c2                	mov    %eax,%edx
c0101182:	66 c1 ea 06          	shr    $0x6,%dx
c0101186:	89 d0                	mov    %edx,%eax
c0101188:	c1 e0 02             	shl    $0x2,%eax
c010118b:	01 d0                	add    %edx,%eax
c010118d:	c1 e0 04             	shl    $0x4,%eax
c0101190:	29 c1                	sub    %eax,%ecx
c0101192:	89 ca                	mov    %ecx,%edx
c0101194:	89 d8                	mov    %ebx,%eax
c0101196:	29 d0                	sub    %edx,%eax
c0101198:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
        break;
c010119e:	eb 27                	jmp    c01011c7 <cga_putc+0xe1>
    default:
        crt_buf[crt_pos ++] = c;     // write the character
c01011a0:	8b 0d 40 a4 11 c0    	mov    0xc011a440,%ecx
c01011a6:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c01011ad:	8d 50 01             	lea    0x1(%eax),%edx
c01011b0:	66 89 15 44 a4 11 c0 	mov    %dx,0xc011a444
c01011b7:	0f b7 c0             	movzwl %ax,%eax
c01011ba:	01 c0                	add    %eax,%eax
c01011bc:	01 c8                	add    %ecx,%eax
c01011be:	8b 55 08             	mov    0x8(%ebp),%edx
c01011c1:	66 89 10             	mov    %dx,(%eax)
        break;
c01011c4:	eb 01                	jmp    c01011c7 <cga_putc+0xe1>
    case '\b':
        if (crt_pos > 0) {
            crt_pos --;
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
        }
        break;
c01011c6:	90                   	nop
        crt_buf[crt_pos ++] = c;     // write the character
        break;
    }

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
c01011c7:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c01011ce:	66 3d cf 07          	cmp    $0x7cf,%ax
c01011d2:	76 59                	jbe    c010122d <cga_putc+0x147>
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
c01011d4:	a1 40 a4 11 c0       	mov    0xc011a440,%eax
c01011d9:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
c01011df:	a1 40 a4 11 c0       	mov    0xc011a440,%eax
c01011e4:	83 ec 04             	sub    $0x4,%esp
c01011e7:	68 00 0f 00 00       	push   $0xf00
c01011ec:	52                   	push   %edx
c01011ed:	50                   	push   %eax
c01011ee:	e8 40 41 00 00       	call   c0105333 <memmove>
c01011f3:	83 c4 10             	add    $0x10,%esp
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
c01011f6:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
c01011fd:	eb 15                	jmp    c0101214 <cga_putc+0x12e>
            crt_buf[i] = 0x0700 | ' ';
c01011ff:	a1 40 a4 11 c0       	mov    0xc011a440,%eax
c0101204:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0101207:	01 d2                	add    %edx,%edx
c0101209:	01 d0                	add    %edx,%eax
c010120b:	66 c7 00 20 07       	movw   $0x720,(%eax)

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
c0101210:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0101214:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
c010121b:	7e e2                	jle    c01011ff <cga_putc+0x119>
            crt_buf[i] = 0x0700 | ' ';
        }
        crt_pos -= CRT_COLS;
c010121d:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c0101224:	83 e8 50             	sub    $0x50,%eax
c0101227:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
    }

    // move that little blinky thing
    outb(addr_6845, 14);
c010122d:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c0101234:	0f b7 c0             	movzwl %ax,%eax
c0101237:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
c010123b:	c6 45 e8 0e          	movb   $0xe,-0x18(%ebp)
c010123f:	0f b6 45 e8          	movzbl -0x18(%ebp),%eax
c0101243:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0101247:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos >> 8);
c0101248:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c010124f:	66 c1 e8 08          	shr    $0x8,%ax
c0101253:	0f b6 c0             	movzbl %al,%eax
c0101256:	0f b7 15 46 a4 11 c0 	movzwl 0xc011a446,%edx
c010125d:	83 c2 01             	add    $0x1,%edx
c0101260:	0f b7 d2             	movzwl %dx,%edx
c0101263:	66 89 55 f0          	mov    %dx,-0x10(%ebp)
c0101267:	88 45 e9             	mov    %al,-0x17(%ebp)
c010126a:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c010126e:	0f b7 55 f0          	movzwl -0x10(%ebp),%edx
c0101272:	ee                   	out    %al,(%dx)
    outb(addr_6845, 15);
c0101273:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c010127a:	0f b7 c0             	movzwl %ax,%eax
c010127d:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
c0101281:	c6 45 ea 0f          	movb   $0xf,-0x16(%ebp)
c0101285:	0f b6 45 ea          	movzbl -0x16(%ebp),%eax
c0101289:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c010128d:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos);
c010128e:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c0101295:	0f b6 c0             	movzbl %al,%eax
c0101298:	0f b7 15 46 a4 11 c0 	movzwl 0xc011a446,%edx
c010129f:	83 c2 01             	add    $0x1,%edx
c01012a2:	0f b7 d2             	movzwl %dx,%edx
c01012a5:	66 89 55 ec          	mov    %dx,-0x14(%ebp)
c01012a9:	88 45 eb             	mov    %al,-0x15(%ebp)
c01012ac:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
c01012b0:	0f b7 55 ec          	movzwl -0x14(%ebp),%edx
c01012b4:	ee                   	out    %al,(%dx)
}
c01012b5:	90                   	nop
c01012b6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
c01012b9:	c9                   	leave  
c01012ba:	c3                   	ret    

c01012bb <serial_putc_sub>:

static void
serial_putc_sub(int c) {
c01012bb:	55                   	push   %ebp
c01012bc:	89 e5                	mov    %esp,%ebp
c01012be:	83 ec 10             	sub    $0x10,%esp
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
c01012c1:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c01012c8:	eb 09                	jmp    c01012d3 <serial_putc_sub+0x18>
        delay();
c01012ca:	e8 51 fb ff ff       	call   c0100e20 <delay>
}

static void
serial_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
c01012cf:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c01012d3:	66 c7 45 f8 fd 03    	movw   $0x3fd,-0x8(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c01012d9:	0f b7 45 f8          	movzwl -0x8(%ebp),%eax
c01012dd:	89 c2                	mov    %eax,%edx
c01012df:	ec                   	in     (%dx),%al
c01012e0:	88 45 f7             	mov    %al,-0x9(%ebp)
    return data;
c01012e3:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
c01012e7:	0f b6 c0             	movzbl %al,%eax
c01012ea:	83 e0 20             	and    $0x20,%eax
c01012ed:	85 c0                	test   %eax,%eax
c01012ef:	75 09                	jne    c01012fa <serial_putc_sub+0x3f>
c01012f1:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
c01012f8:	7e d0                	jle    c01012ca <serial_putc_sub+0xf>
        delay();
    }
    outb(COM1 + COM_TX, c);
c01012fa:	8b 45 08             	mov    0x8(%ebp),%eax
c01012fd:	0f b6 c0             	movzbl %al,%eax
c0101300:	66 c7 45 fa f8 03    	movw   $0x3f8,-0x6(%ebp)
c0101306:	88 45 f6             	mov    %al,-0xa(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0101309:	0f b6 45 f6          	movzbl -0xa(%ebp),%eax
c010130d:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c0101311:	ee                   	out    %al,(%dx)
}
c0101312:	90                   	nop
c0101313:	c9                   	leave  
c0101314:	c3                   	ret    

c0101315 <serial_putc>:

/* serial_putc - print character to serial port */
static void
serial_putc(int c) {
c0101315:	55                   	push   %ebp
c0101316:	89 e5                	mov    %esp,%ebp
    if (c != '\b') {
c0101318:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
c010131c:	74 0d                	je     c010132b <serial_putc+0x16>
        serial_putc_sub(c);
c010131e:	ff 75 08             	pushl  0x8(%ebp)
c0101321:	e8 95 ff ff ff       	call   c01012bb <serial_putc_sub>
c0101326:	83 c4 04             	add    $0x4,%esp
    else {
        serial_putc_sub('\b');
        serial_putc_sub(' ');
        serial_putc_sub('\b');
    }
}
c0101329:	eb 1e                	jmp    c0101349 <serial_putc+0x34>
serial_putc(int c) {
    if (c != '\b') {
        serial_putc_sub(c);
    }
    else {
        serial_putc_sub('\b');
c010132b:	6a 08                	push   $0x8
c010132d:	e8 89 ff ff ff       	call   c01012bb <serial_putc_sub>
c0101332:	83 c4 04             	add    $0x4,%esp
        serial_putc_sub(' ');
c0101335:	6a 20                	push   $0x20
c0101337:	e8 7f ff ff ff       	call   c01012bb <serial_putc_sub>
c010133c:	83 c4 04             	add    $0x4,%esp
        serial_putc_sub('\b');
c010133f:	6a 08                	push   $0x8
c0101341:	e8 75 ff ff ff       	call   c01012bb <serial_putc_sub>
c0101346:	83 c4 04             	add    $0x4,%esp
    }
}
c0101349:	90                   	nop
c010134a:	c9                   	leave  
c010134b:	c3                   	ret    

c010134c <cons_intr>:
/* *
 * cons_intr - called by device interrupt routines to feed input
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
c010134c:	55                   	push   %ebp
c010134d:	89 e5                	mov    %esp,%ebp
c010134f:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = (*proc)()) != -1) {
c0101352:	eb 33                	jmp    c0101387 <cons_intr+0x3b>
        if (c != 0) {
c0101354:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0101358:	74 2d                	je     c0101387 <cons_intr+0x3b>
            cons.buf[cons.wpos ++] = c;
c010135a:	a1 64 a6 11 c0       	mov    0xc011a664,%eax
c010135f:	8d 50 01             	lea    0x1(%eax),%edx
c0101362:	89 15 64 a6 11 c0    	mov    %edx,0xc011a664
c0101368:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010136b:	88 90 60 a4 11 c0    	mov    %dl,-0x3fee5ba0(%eax)
            if (cons.wpos == CONSBUFSIZE) {
c0101371:	a1 64 a6 11 c0       	mov    0xc011a664,%eax
c0101376:	3d 00 02 00 00       	cmp    $0x200,%eax
c010137b:	75 0a                	jne    c0101387 <cons_intr+0x3b>
                cons.wpos = 0;
c010137d:	c7 05 64 a6 11 c0 00 	movl   $0x0,0xc011a664
c0101384:	00 00 00 
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
    int c;
    while ((c = (*proc)()) != -1) {
c0101387:	8b 45 08             	mov    0x8(%ebp),%eax
c010138a:	ff d0                	call   *%eax
c010138c:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010138f:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
c0101393:	75 bf                	jne    c0101354 <cons_intr+0x8>
            if (cons.wpos == CONSBUFSIZE) {
                cons.wpos = 0;
            }
        }
    }
}
c0101395:	90                   	nop
c0101396:	c9                   	leave  
c0101397:	c3                   	ret    

c0101398 <serial_proc_data>:

/* serial_proc_data - get data from serial port */
static int
serial_proc_data(void) {
c0101398:	55                   	push   %ebp
c0101399:	89 e5                	mov    %esp,%ebp
c010139b:	83 ec 10             	sub    $0x10,%esp
c010139e:	66 c7 45 f8 fd 03    	movw   $0x3fd,-0x8(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c01013a4:	0f b7 45 f8          	movzwl -0x8(%ebp),%eax
c01013a8:	89 c2                	mov    %eax,%edx
c01013aa:	ec                   	in     (%dx),%al
c01013ab:	88 45 f7             	mov    %al,-0x9(%ebp)
    return data;
c01013ae:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
    if (!(inb(COM1 + COM_LSR) & COM_LSR_DATA)) {
c01013b2:	0f b6 c0             	movzbl %al,%eax
c01013b5:	83 e0 01             	and    $0x1,%eax
c01013b8:	85 c0                	test   %eax,%eax
c01013ba:	75 07                	jne    c01013c3 <serial_proc_data+0x2b>
        return -1;
c01013bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c01013c1:	eb 2a                	jmp    c01013ed <serial_proc_data+0x55>
c01013c3:	66 c7 45 fa f8 03    	movw   $0x3f8,-0x6(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c01013c9:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c01013cd:	89 c2                	mov    %eax,%edx
c01013cf:	ec                   	in     (%dx),%al
c01013d0:	88 45 f6             	mov    %al,-0xa(%ebp)
    return data;
c01013d3:	0f b6 45 f6          	movzbl -0xa(%ebp),%eax
    }
    int c = inb(COM1 + COM_RX);
c01013d7:	0f b6 c0             	movzbl %al,%eax
c01013da:	89 45 fc             	mov    %eax,-0x4(%ebp)
    if (c == 127) {
c01013dd:	83 7d fc 7f          	cmpl   $0x7f,-0x4(%ebp)
c01013e1:	75 07                	jne    c01013ea <serial_proc_data+0x52>
        c = '\b';
c01013e3:	c7 45 fc 08 00 00 00 	movl   $0x8,-0x4(%ebp)
    }
    return c;
c01013ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c01013ed:	c9                   	leave  
c01013ee:	c3                   	ret    

c01013ef <serial_intr>:

/* serial_intr - try to feed input characters from serial port */
void
serial_intr(void) {
c01013ef:	55                   	push   %ebp
c01013f0:	89 e5                	mov    %esp,%ebp
c01013f2:	83 ec 08             	sub    $0x8,%esp
    if (serial_exists) {
c01013f5:	a1 48 a4 11 c0       	mov    0xc011a448,%eax
c01013fa:	85 c0                	test   %eax,%eax
c01013fc:	74 10                	je     c010140e <serial_intr+0x1f>
        cons_intr(serial_proc_data);
c01013fe:	83 ec 0c             	sub    $0xc,%esp
c0101401:	68 98 13 10 c0       	push   $0xc0101398
c0101406:	e8 41 ff ff ff       	call   c010134c <cons_intr>
c010140b:	83 c4 10             	add    $0x10,%esp
    }
}
c010140e:	90                   	nop
c010140f:	c9                   	leave  
c0101410:	c3                   	ret    

c0101411 <kbd_proc_data>:
 *
 * The kbd_proc_data() function gets data from the keyboard.
 * If we finish a character, return it, else 0. And return -1 if no data.
 * */
static int
kbd_proc_data(void) {
c0101411:	55                   	push   %ebp
c0101412:	89 e5                	mov    %esp,%ebp
c0101414:	83 ec 18             	sub    $0x18,%esp
c0101417:	66 c7 45 ec 64 00    	movw   $0x64,-0x14(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c010141d:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
c0101421:	89 c2                	mov    %eax,%edx
c0101423:	ec                   	in     (%dx),%al
c0101424:	88 45 eb             	mov    %al,-0x15(%ebp)
    return data;
c0101427:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
    int c;
    uint8_t data;
    static uint32_t shift;

    if ((inb(KBSTATP) & KBS_DIB) == 0) {
c010142b:	0f b6 c0             	movzbl %al,%eax
c010142e:	83 e0 01             	and    $0x1,%eax
c0101431:	85 c0                	test   %eax,%eax
c0101433:	75 0a                	jne    c010143f <kbd_proc_data+0x2e>
        return -1;
c0101435:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c010143a:	e9 5d 01 00 00       	jmp    c010159c <kbd_proc_data+0x18b>
c010143f:	66 c7 45 f0 60 00    	movw   $0x60,-0x10(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0101445:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
c0101449:	89 c2                	mov    %eax,%edx
c010144b:	ec                   	in     (%dx),%al
c010144c:	88 45 ea             	mov    %al,-0x16(%ebp)
    return data;
c010144f:	0f b6 45 ea          	movzbl -0x16(%ebp),%eax
    }

    data = inb(KBDATAP);
c0101453:	88 45 f3             	mov    %al,-0xd(%ebp)

    if (data == 0xE0) {
c0101456:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
c010145a:	75 17                	jne    c0101473 <kbd_proc_data+0x62>
        // E0 escape character
        shift |= E0ESC;
c010145c:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c0101461:	83 c8 40             	or     $0x40,%eax
c0101464:	a3 68 a6 11 c0       	mov    %eax,0xc011a668
        return 0;
c0101469:	b8 00 00 00 00       	mov    $0x0,%eax
c010146e:	e9 29 01 00 00       	jmp    c010159c <kbd_proc_data+0x18b>
    } else if (data & 0x80) {
c0101473:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101477:	84 c0                	test   %al,%al
c0101479:	79 47                	jns    c01014c2 <kbd_proc_data+0xb1>
        // Key released
        data = (shift & E0ESC ? data : data & 0x7F);
c010147b:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c0101480:	83 e0 40             	and    $0x40,%eax
c0101483:	85 c0                	test   %eax,%eax
c0101485:	75 09                	jne    c0101490 <kbd_proc_data+0x7f>
c0101487:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c010148b:	83 e0 7f             	and    $0x7f,%eax
c010148e:	eb 04                	jmp    c0101494 <kbd_proc_data+0x83>
c0101490:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101494:	88 45 f3             	mov    %al,-0xd(%ebp)
        shift &= ~(shiftcode[data] | E0ESC);
c0101497:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c010149b:	0f b6 80 40 70 11 c0 	movzbl -0x3fee8fc0(%eax),%eax
c01014a2:	83 c8 40             	or     $0x40,%eax
c01014a5:	0f b6 c0             	movzbl %al,%eax
c01014a8:	f7 d0                	not    %eax
c01014aa:	89 c2                	mov    %eax,%edx
c01014ac:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c01014b1:	21 d0                	and    %edx,%eax
c01014b3:	a3 68 a6 11 c0       	mov    %eax,0xc011a668
        return 0;
c01014b8:	b8 00 00 00 00       	mov    $0x0,%eax
c01014bd:	e9 da 00 00 00       	jmp    c010159c <kbd_proc_data+0x18b>
    } else if (shift & E0ESC) {
c01014c2:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c01014c7:	83 e0 40             	and    $0x40,%eax
c01014ca:	85 c0                	test   %eax,%eax
c01014cc:	74 11                	je     c01014df <kbd_proc_data+0xce>
        // Last character was an E0 escape; or with 0x80
        data |= 0x80;
c01014ce:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
        shift &= ~E0ESC;
c01014d2:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c01014d7:	83 e0 bf             	and    $0xffffffbf,%eax
c01014da:	a3 68 a6 11 c0       	mov    %eax,0xc011a668
    }

    shift |= shiftcode[data];
c01014df:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c01014e3:	0f b6 80 40 70 11 c0 	movzbl -0x3fee8fc0(%eax),%eax
c01014ea:	0f b6 d0             	movzbl %al,%edx
c01014ed:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c01014f2:	09 d0                	or     %edx,%eax
c01014f4:	a3 68 a6 11 c0       	mov    %eax,0xc011a668
    shift ^= togglecode[data];
c01014f9:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c01014fd:	0f b6 80 40 71 11 c0 	movzbl -0x3fee8ec0(%eax),%eax
c0101504:	0f b6 d0             	movzbl %al,%edx
c0101507:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c010150c:	31 d0                	xor    %edx,%eax
c010150e:	a3 68 a6 11 c0       	mov    %eax,0xc011a668

    c = charcode[shift & (CTL | SHIFT)][data];
c0101513:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c0101518:	83 e0 03             	and    $0x3,%eax
c010151b:	8b 14 85 40 75 11 c0 	mov    -0x3fee8ac0(,%eax,4),%edx
c0101522:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101526:	01 d0                	add    %edx,%eax
c0101528:	0f b6 00             	movzbl (%eax),%eax
c010152b:	0f b6 c0             	movzbl %al,%eax
c010152e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (shift & CAPSLOCK) {
c0101531:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c0101536:	83 e0 08             	and    $0x8,%eax
c0101539:	85 c0                	test   %eax,%eax
c010153b:	74 22                	je     c010155f <kbd_proc_data+0x14e>
        if ('a' <= c && c <= 'z')
c010153d:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
c0101541:	7e 0c                	jle    c010154f <kbd_proc_data+0x13e>
c0101543:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
c0101547:	7f 06                	jg     c010154f <kbd_proc_data+0x13e>
            c += 'A' - 'a';
c0101549:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
c010154d:	eb 10                	jmp    c010155f <kbd_proc_data+0x14e>
        else if ('A' <= c && c <= 'Z')
c010154f:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
c0101553:	7e 0a                	jle    c010155f <kbd_proc_data+0x14e>
c0101555:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
c0101559:	7f 04                	jg     c010155f <kbd_proc_data+0x14e>
            c += 'a' - 'A';
c010155b:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
    }

    // Process special keys
    // Ctrl-Alt-Del: reboot
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
c010155f:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c0101564:	f7 d0                	not    %eax
c0101566:	83 e0 06             	and    $0x6,%eax
c0101569:	85 c0                	test   %eax,%eax
c010156b:	75 2c                	jne    c0101599 <kbd_proc_data+0x188>
c010156d:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
c0101574:	75 23                	jne    c0101599 <kbd_proc_data+0x188>
        cprintf("Rebooting!\n");
c0101576:	83 ec 0c             	sub    $0xc,%esp
c0101579:	68 cd 5d 10 c0       	push   $0xc0105dcd
c010157e:	e8 f0 ec ff ff       	call   c0100273 <cprintf>
c0101583:	83 c4 10             	add    $0x10,%esp
c0101586:	66 c7 45 ee 92 00    	movw   $0x92,-0x12(%ebp)
c010158c:	c6 45 e9 03          	movb   $0x3,-0x17(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0101590:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c0101594:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c0101598:	ee                   	out    %al,(%dx)
        outb(0x92, 0x3); // courtesy of Chris Frost
    }
    return c;
c0101599:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c010159c:	c9                   	leave  
c010159d:	c3                   	ret    

c010159e <kbd_intr>:

/* kbd_intr - try to feed input characters from keyboard */
static void
kbd_intr(void) {
c010159e:	55                   	push   %ebp
c010159f:	89 e5                	mov    %esp,%ebp
c01015a1:	83 ec 08             	sub    $0x8,%esp
    cons_intr(kbd_proc_data);
c01015a4:	83 ec 0c             	sub    $0xc,%esp
c01015a7:	68 11 14 10 c0       	push   $0xc0101411
c01015ac:	e8 9b fd ff ff       	call   c010134c <cons_intr>
c01015b1:	83 c4 10             	add    $0x10,%esp
}
c01015b4:	90                   	nop
c01015b5:	c9                   	leave  
c01015b6:	c3                   	ret    

c01015b7 <kbd_init>:

static void
kbd_init(void) {
c01015b7:	55                   	push   %ebp
c01015b8:	89 e5                	mov    %esp,%ebp
c01015ba:	83 ec 08             	sub    $0x8,%esp
    // drain the kbd buffer
    kbd_intr();
c01015bd:	e8 dc ff ff ff       	call   c010159e <kbd_intr>
    pic_enable(IRQ_KBD);
c01015c2:	83 ec 0c             	sub    $0xc,%esp
c01015c5:	6a 01                	push   $0x1
c01015c7:	e8 4b 01 00 00       	call   c0101717 <pic_enable>
c01015cc:	83 c4 10             	add    $0x10,%esp
}
c01015cf:	90                   	nop
c01015d0:	c9                   	leave  
c01015d1:	c3                   	ret    

c01015d2 <cons_init>:

/* cons_init - initializes the console devices */
void
cons_init(void) {
c01015d2:	55                   	push   %ebp
c01015d3:	89 e5                	mov    %esp,%ebp
c01015d5:	83 ec 08             	sub    $0x8,%esp
    cga_init();
c01015d8:	e8 8c f8 ff ff       	call   c0100e69 <cga_init>
    serial_init();
c01015dd:	e8 6e f9 ff ff       	call   c0100f50 <serial_init>
    kbd_init();
c01015e2:	e8 d0 ff ff ff       	call   c01015b7 <kbd_init>
    if (!serial_exists) {
c01015e7:	a1 48 a4 11 c0       	mov    0xc011a448,%eax
c01015ec:	85 c0                	test   %eax,%eax
c01015ee:	75 10                	jne    c0101600 <cons_init+0x2e>
        cprintf("serial port does not exist!!\n");
c01015f0:	83 ec 0c             	sub    $0xc,%esp
c01015f3:	68 d9 5d 10 c0       	push   $0xc0105dd9
c01015f8:	e8 76 ec ff ff       	call   c0100273 <cprintf>
c01015fd:	83 c4 10             	add    $0x10,%esp
    }
}
c0101600:	90                   	nop
c0101601:	c9                   	leave  
c0101602:	c3                   	ret    

c0101603 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void
cons_putc(int c) {
c0101603:	55                   	push   %ebp
c0101604:	89 e5                	mov    %esp,%ebp
c0101606:	83 ec 18             	sub    $0x18,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
c0101609:	e8 d4 f7 ff ff       	call   c0100de2 <__intr_save>
c010160e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        lpt_putc(c);
c0101611:	83 ec 0c             	sub    $0xc,%esp
c0101614:	ff 75 08             	pushl  0x8(%ebp)
c0101617:	e8 93 fa ff ff       	call   c01010af <lpt_putc>
c010161c:	83 c4 10             	add    $0x10,%esp
        cga_putc(c);
c010161f:	83 ec 0c             	sub    $0xc,%esp
c0101622:	ff 75 08             	pushl  0x8(%ebp)
c0101625:	e8 bc fa ff ff       	call   c01010e6 <cga_putc>
c010162a:	83 c4 10             	add    $0x10,%esp
        serial_putc(c);
c010162d:	83 ec 0c             	sub    $0xc,%esp
c0101630:	ff 75 08             	pushl  0x8(%ebp)
c0101633:	e8 dd fc ff ff       	call   c0101315 <serial_putc>
c0101638:	83 c4 10             	add    $0x10,%esp
    }
    local_intr_restore(intr_flag);
c010163b:	83 ec 0c             	sub    $0xc,%esp
c010163e:	ff 75 f4             	pushl  -0xc(%ebp)
c0101641:	e8 c6 f7 ff ff       	call   c0100e0c <__intr_restore>
c0101646:	83 c4 10             	add    $0x10,%esp
}
c0101649:	90                   	nop
c010164a:	c9                   	leave  
c010164b:	c3                   	ret    

c010164c <cons_getc>:
/* *
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int
cons_getc(void) {
c010164c:	55                   	push   %ebp
c010164d:	89 e5                	mov    %esp,%ebp
c010164f:	83 ec 18             	sub    $0x18,%esp
    int c = 0;
c0101652:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
c0101659:	e8 84 f7 ff ff       	call   c0100de2 <__intr_save>
c010165e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        // poll for any pending input characters,
        // so that this function works even when interrupts are disabled
        // (e.g., when called from the kernel monitor).
        serial_intr();
c0101661:	e8 89 fd ff ff       	call   c01013ef <serial_intr>
        kbd_intr();
c0101666:	e8 33 ff ff ff       	call   c010159e <kbd_intr>

        // grab the next character from the input buffer.
        if (cons.rpos != cons.wpos) {
c010166b:	8b 15 60 a6 11 c0    	mov    0xc011a660,%edx
c0101671:	a1 64 a6 11 c0       	mov    0xc011a664,%eax
c0101676:	39 c2                	cmp    %eax,%edx
c0101678:	74 31                	je     c01016ab <cons_getc+0x5f>
            c = cons.buf[cons.rpos ++];
c010167a:	a1 60 a6 11 c0       	mov    0xc011a660,%eax
c010167f:	8d 50 01             	lea    0x1(%eax),%edx
c0101682:	89 15 60 a6 11 c0    	mov    %edx,0xc011a660
c0101688:	0f b6 80 60 a4 11 c0 	movzbl -0x3fee5ba0(%eax),%eax
c010168f:	0f b6 c0             	movzbl %al,%eax
c0101692:	89 45 f4             	mov    %eax,-0xc(%ebp)
            if (cons.rpos == CONSBUFSIZE) {
c0101695:	a1 60 a6 11 c0       	mov    0xc011a660,%eax
c010169a:	3d 00 02 00 00       	cmp    $0x200,%eax
c010169f:	75 0a                	jne    c01016ab <cons_getc+0x5f>
                cons.rpos = 0;
c01016a1:	c7 05 60 a6 11 c0 00 	movl   $0x0,0xc011a660
c01016a8:	00 00 00 
            }
        }
    }
    local_intr_restore(intr_flag);
c01016ab:	83 ec 0c             	sub    $0xc,%esp
c01016ae:	ff 75 f0             	pushl  -0x10(%ebp)
c01016b1:	e8 56 f7 ff ff       	call   c0100e0c <__intr_restore>
c01016b6:	83 c4 10             	add    $0x10,%esp
    return c;
c01016b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01016bc:	c9                   	leave  
c01016bd:	c3                   	ret    

c01016be <pic_setmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static uint16_t irq_mask = 0xFFFF & ~(1 << IRQ_SLAVE);
static bool did_init = 0;

static void
pic_setmask(uint16_t mask) {
c01016be:	55                   	push   %ebp
c01016bf:	89 e5                	mov    %esp,%ebp
c01016c1:	83 ec 14             	sub    $0x14,%esp
c01016c4:	8b 45 08             	mov    0x8(%ebp),%eax
c01016c7:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
    irq_mask = mask;
c01016cb:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
c01016cf:	66 a3 50 75 11 c0    	mov    %ax,0xc0117550
    if (did_init) {
c01016d5:	a1 6c a6 11 c0       	mov    0xc011a66c,%eax
c01016da:	85 c0                	test   %eax,%eax
c01016dc:	74 36                	je     c0101714 <pic_setmask+0x56>
        outb(IO_PIC1 + 1, mask);
c01016de:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
c01016e2:	0f b6 c0             	movzbl %al,%eax
c01016e5:	66 c7 45 fe 21 00    	movw   $0x21,-0x2(%ebp)
c01016eb:	88 45 fa             	mov    %al,-0x6(%ebp)
c01016ee:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
c01016f2:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
c01016f6:	ee                   	out    %al,(%dx)
        outb(IO_PIC2 + 1, mask >> 8);
c01016f7:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
c01016fb:	66 c1 e8 08          	shr    $0x8,%ax
c01016ff:	0f b6 c0             	movzbl %al,%eax
c0101702:	66 c7 45 fc a1 00    	movw   $0xa1,-0x4(%ebp)
c0101708:	88 45 fb             	mov    %al,-0x5(%ebp)
c010170b:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
c010170f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
c0101713:	ee                   	out    %al,(%dx)
    }
}
c0101714:	90                   	nop
c0101715:	c9                   	leave  
c0101716:	c3                   	ret    

c0101717 <pic_enable>:

void
pic_enable(unsigned int irq) {
c0101717:	55                   	push   %ebp
c0101718:	89 e5                	mov    %esp,%ebp
    pic_setmask(irq_mask & ~(1 << irq));
c010171a:	8b 45 08             	mov    0x8(%ebp),%eax
c010171d:	ba 01 00 00 00       	mov    $0x1,%edx
c0101722:	89 c1                	mov    %eax,%ecx
c0101724:	d3 e2                	shl    %cl,%edx
c0101726:	89 d0                	mov    %edx,%eax
c0101728:	f7 d0                	not    %eax
c010172a:	89 c2                	mov    %eax,%edx
c010172c:	0f b7 05 50 75 11 c0 	movzwl 0xc0117550,%eax
c0101733:	21 d0                	and    %edx,%eax
c0101735:	0f b7 c0             	movzwl %ax,%eax
c0101738:	50                   	push   %eax
c0101739:	e8 80 ff ff ff       	call   c01016be <pic_setmask>
c010173e:	83 c4 04             	add    $0x4,%esp
}
c0101741:	90                   	nop
c0101742:	c9                   	leave  
c0101743:	c3                   	ret    

c0101744 <pic_init>:

/* pic_init - initialize the 8259A interrupt controllers */
void
pic_init(void) {
c0101744:	55                   	push   %ebp
c0101745:	89 e5                	mov    %esp,%ebp
c0101747:	83 ec 30             	sub    $0x30,%esp
    did_init = 1;
c010174a:	c7 05 6c a6 11 c0 01 	movl   $0x1,0xc011a66c
c0101751:	00 00 00 
c0101754:	66 c7 45 fe 21 00    	movw   $0x21,-0x2(%ebp)
c010175a:	c6 45 d6 ff          	movb   $0xff,-0x2a(%ebp)
c010175e:	0f b6 45 d6          	movzbl -0x2a(%ebp),%eax
c0101762:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
c0101766:	ee                   	out    %al,(%dx)
c0101767:	66 c7 45 fc a1 00    	movw   $0xa1,-0x4(%ebp)
c010176d:	c6 45 d7 ff          	movb   $0xff,-0x29(%ebp)
c0101771:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
c0101775:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
c0101779:	ee                   	out    %al,(%dx)
c010177a:	66 c7 45 fa 20 00    	movw   $0x20,-0x6(%ebp)
c0101780:	c6 45 d8 11          	movb   $0x11,-0x28(%ebp)
c0101784:	0f b6 45 d8          	movzbl -0x28(%ebp),%eax
c0101788:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c010178c:	ee                   	out    %al,(%dx)
c010178d:	66 c7 45 f8 21 00    	movw   $0x21,-0x8(%ebp)
c0101793:	c6 45 d9 20          	movb   $0x20,-0x27(%ebp)
c0101797:	0f b6 45 d9          	movzbl -0x27(%ebp),%eax
c010179b:	0f b7 55 f8          	movzwl -0x8(%ebp),%edx
c010179f:	ee                   	out    %al,(%dx)
c01017a0:	66 c7 45 f6 21 00    	movw   $0x21,-0xa(%ebp)
c01017a6:	c6 45 da 04          	movb   $0x4,-0x26(%ebp)
c01017aa:	0f b6 45 da          	movzbl -0x26(%ebp),%eax
c01017ae:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c01017b2:	ee                   	out    %al,(%dx)
c01017b3:	66 c7 45 f4 21 00    	movw   $0x21,-0xc(%ebp)
c01017b9:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
c01017bd:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
c01017c1:	0f b7 55 f4          	movzwl -0xc(%ebp),%edx
c01017c5:	ee                   	out    %al,(%dx)
c01017c6:	66 c7 45 f2 a0 00    	movw   $0xa0,-0xe(%ebp)
c01017cc:	c6 45 dc 11          	movb   $0x11,-0x24(%ebp)
c01017d0:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
c01017d4:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c01017d8:	ee                   	out    %al,(%dx)
c01017d9:	66 c7 45 f0 a1 00    	movw   $0xa1,-0x10(%ebp)
c01017df:	c6 45 dd 28          	movb   $0x28,-0x23(%ebp)
c01017e3:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
c01017e7:	0f b7 55 f0          	movzwl -0x10(%ebp),%edx
c01017eb:	ee                   	out    %al,(%dx)
c01017ec:	66 c7 45 ee a1 00    	movw   $0xa1,-0x12(%ebp)
c01017f2:	c6 45 de 02          	movb   $0x2,-0x22(%ebp)
c01017f6:	0f b6 45 de          	movzbl -0x22(%ebp),%eax
c01017fa:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c01017fe:	ee                   	out    %al,(%dx)
c01017ff:	66 c7 45 ec a1 00    	movw   $0xa1,-0x14(%ebp)
c0101805:	c6 45 df 03          	movb   $0x3,-0x21(%ebp)
c0101809:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
c010180d:	0f b7 55 ec          	movzwl -0x14(%ebp),%edx
c0101811:	ee                   	out    %al,(%dx)
c0101812:	66 c7 45 ea 20 00    	movw   $0x20,-0x16(%ebp)
c0101818:	c6 45 e0 68          	movb   $0x68,-0x20(%ebp)
c010181c:	0f b6 45 e0          	movzbl -0x20(%ebp),%eax
c0101820:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c0101824:	ee                   	out    %al,(%dx)
c0101825:	66 c7 45 e8 20 00    	movw   $0x20,-0x18(%ebp)
c010182b:	c6 45 e1 0a          	movb   $0xa,-0x1f(%ebp)
c010182f:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
c0101833:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
c0101837:	ee                   	out    %al,(%dx)
c0101838:	66 c7 45 e6 a0 00    	movw   $0xa0,-0x1a(%ebp)
c010183e:	c6 45 e2 68          	movb   $0x68,-0x1e(%ebp)
c0101842:	0f b6 45 e2          	movzbl -0x1e(%ebp),%eax
c0101846:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
c010184a:	ee                   	out    %al,(%dx)
c010184b:	66 c7 45 e4 a0 00    	movw   $0xa0,-0x1c(%ebp)
c0101851:	c6 45 e3 0a          	movb   $0xa,-0x1d(%ebp)
c0101855:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
c0101859:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
c010185d:	ee                   	out    %al,(%dx)
    outb(IO_PIC1, 0x0a);    // read IRR by default

    outb(IO_PIC2, 0x68);    // OCW3
    outb(IO_PIC2, 0x0a);    // OCW3

    if (irq_mask != 0xFFFF) {
c010185e:	0f b7 05 50 75 11 c0 	movzwl 0xc0117550,%eax
c0101865:	66 83 f8 ff          	cmp    $0xffff,%ax
c0101869:	74 13                	je     c010187e <pic_init+0x13a>
        pic_setmask(irq_mask);
c010186b:	0f b7 05 50 75 11 c0 	movzwl 0xc0117550,%eax
c0101872:	0f b7 c0             	movzwl %ax,%eax
c0101875:	50                   	push   %eax
c0101876:	e8 43 fe ff ff       	call   c01016be <pic_setmask>
c010187b:	83 c4 04             	add    $0x4,%esp
    }
}
c010187e:	90                   	nop
c010187f:	c9                   	leave  
c0101880:	c3                   	ret    

c0101881 <intr_enable>:
#include <x86.h>
#include <intr.h>

/* intr_enable - enable irq interrupt */
void
intr_enable(void) {
c0101881:	55                   	push   %ebp
c0101882:	89 e5                	mov    %esp,%ebp
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
}

static inline void
sti(void) {
    asm volatile ("sti");
c0101884:	fb                   	sti    
    sti();
}
c0101885:	90                   	nop
c0101886:	5d                   	pop    %ebp
c0101887:	c3                   	ret    

c0101888 <intr_disable>:

/* intr_disable - disable irq interrupt */
void
intr_disable(void) {
c0101888:	55                   	push   %ebp
c0101889:	89 e5                	mov    %esp,%ebp
}

static inline void
cli(void) {
    asm volatile ("cli" ::: "memory");
c010188b:	fa                   	cli    
    cli();
}
c010188c:	90                   	nop
c010188d:	5d                   	pop    %ebp
c010188e:	c3                   	ret    

c010188f <print_ticks>:
#include <console.h>
#include <kdebug.h>

#define TICK_NUM 100

static void print_ticks() {
c010188f:	55                   	push   %ebp
c0101890:	89 e5                	mov    %esp,%ebp
c0101892:	83 ec 08             	sub    $0x8,%esp
    cprintf("%d ticks\n",TICK_NUM);
c0101895:	83 ec 08             	sub    $0x8,%esp
c0101898:	6a 64                	push   $0x64
c010189a:	68 00 5e 10 c0       	push   $0xc0105e00
c010189f:	e8 cf e9 ff ff       	call   c0100273 <cprintf>
c01018a4:	83 c4 10             	add    $0x10,%esp
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
c01018a7:	83 ec 0c             	sub    $0xc,%esp
c01018aa:	68 0a 5e 10 c0       	push   $0xc0105e0a
c01018af:	e8 bf e9 ff ff       	call   c0100273 <cprintf>
c01018b4:	83 c4 10             	add    $0x10,%esp
    panic("EOT: kernel seems ok.");
c01018b7:	83 ec 04             	sub    $0x4,%esp
c01018ba:	68 18 5e 10 c0       	push   $0xc0105e18
c01018bf:	6a 12                	push   $0x12
c01018c1:	68 2e 5e 10 c0       	push   $0xc0105e2e
c01018c6:	e8 0e eb ff ff       	call   c01003d9 <__panic>

c01018cb <idt_init>:
    sizeof(idt) - 1, (uintptr_t)idt
};

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S */
void
idt_init(void) {
c01018cb:	55                   	push   %ebp
c01018cc:	89 e5                	mov    %esp,%ebp
c01018ce:	83 ec 10             	sub    $0x10,%esp
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
    extern uintptr_t __vectors[];
    int i;
    for (i = 0; i < sizeof(idt) / sizeof(struct gatedesc); i ++) {
c01018d1:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c01018d8:	e9 c3 00 00 00       	jmp    c01019a0 <idt_init+0xd5>
        SETGATE(idt[i], 0, GD_KTEXT, __vectors[i], DPL_KERNEL);
c01018dd:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018e0:	8b 04 85 e0 75 11 c0 	mov    -0x3fee8a20(,%eax,4),%eax
c01018e7:	89 c2                	mov    %eax,%edx
c01018e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018ec:	66 89 14 c5 80 a6 11 	mov    %dx,-0x3fee5980(,%eax,8)
c01018f3:	c0 
c01018f4:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018f7:	66 c7 04 c5 82 a6 11 	movw   $0x8,-0x3fee597e(,%eax,8)
c01018fe:	c0 08 00 
c0101901:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101904:	0f b6 14 c5 84 a6 11 	movzbl -0x3fee597c(,%eax,8),%edx
c010190b:	c0 
c010190c:	83 e2 e0             	and    $0xffffffe0,%edx
c010190f:	88 14 c5 84 a6 11 c0 	mov    %dl,-0x3fee597c(,%eax,8)
c0101916:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101919:	0f b6 14 c5 84 a6 11 	movzbl -0x3fee597c(,%eax,8),%edx
c0101920:	c0 
c0101921:	83 e2 1f             	and    $0x1f,%edx
c0101924:	88 14 c5 84 a6 11 c0 	mov    %dl,-0x3fee597c(,%eax,8)
c010192b:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010192e:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c0101935:	c0 
c0101936:	83 e2 f0             	and    $0xfffffff0,%edx
c0101939:	83 ca 0e             	or     $0xe,%edx
c010193c:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c0101943:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101946:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c010194d:	c0 
c010194e:	83 e2 ef             	and    $0xffffffef,%edx
c0101951:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c0101958:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010195b:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c0101962:	c0 
c0101963:	83 e2 9f             	and    $0xffffff9f,%edx
c0101966:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c010196d:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101970:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c0101977:	c0 
c0101978:	83 ca 80             	or     $0xffffff80,%edx
c010197b:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c0101982:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101985:	8b 04 85 e0 75 11 c0 	mov    -0x3fee8a20(,%eax,4),%eax
c010198c:	c1 e8 10             	shr    $0x10,%eax
c010198f:	89 c2                	mov    %eax,%edx
c0101991:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101994:	66 89 14 c5 86 a6 11 	mov    %dx,-0x3fee597a(,%eax,8)
c010199b:	c0 
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
    extern uintptr_t __vectors[];
    int i;
    for (i = 0; i < sizeof(idt) / sizeof(struct gatedesc); i ++) {
c010199c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c01019a0:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01019a3:	3d ff 00 00 00       	cmp    $0xff,%eax
c01019a8:	0f 86 2f ff ff ff    	jbe    c01018dd <idt_init+0x12>
c01019ae:	c7 45 f8 60 75 11 c0 	movl   $0xc0117560,-0x8(%ebp)
    }
}

static inline void
lidt(struct pseudodesc *pd) {
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
c01019b5:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01019b8:	0f 01 18             	lidtl  (%eax)
        SETGATE(idt[i], 0, GD_KTEXT, __vectors[i], DPL_KERNEL);
    }
    lidt(&idt_pd);
}
c01019bb:	90                   	nop
c01019bc:	c9                   	leave  
c01019bd:	c3                   	ret    

c01019be <trapname>:

static const char *
trapname(int trapno) {
c01019be:	55                   	push   %ebp
c01019bf:	89 e5                	mov    %esp,%ebp
        "Alignment Check",
        "Machine-Check",
        "SIMD Floating-Point Exception"
    };

    if (trapno < sizeof(excnames)/sizeof(const char * const)) {
c01019c1:	8b 45 08             	mov    0x8(%ebp),%eax
c01019c4:	83 f8 13             	cmp    $0x13,%eax
c01019c7:	77 0c                	ja     c01019d5 <trapname+0x17>
        return excnames[trapno];
c01019c9:	8b 45 08             	mov    0x8(%ebp),%eax
c01019cc:	8b 04 85 80 61 10 c0 	mov    -0x3fef9e80(,%eax,4),%eax
c01019d3:	eb 18                	jmp    c01019ed <trapname+0x2f>
    }
    if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16) {
c01019d5:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
c01019d9:	7e 0d                	jle    c01019e8 <trapname+0x2a>
c01019db:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
c01019df:	7f 07                	jg     c01019e8 <trapname+0x2a>
        return "Hardware Interrupt";
c01019e1:	b8 3f 5e 10 c0       	mov    $0xc0105e3f,%eax
c01019e6:	eb 05                	jmp    c01019ed <trapname+0x2f>
    }
    return "(unknown trap)";
c01019e8:	b8 52 5e 10 c0       	mov    $0xc0105e52,%eax
}
c01019ed:	5d                   	pop    %ebp
c01019ee:	c3                   	ret    

c01019ef <trap_in_kernel>:

/* trap_in_kernel - test if trap happened in kernel */
bool
trap_in_kernel(struct trapframe *tf) {
c01019ef:	55                   	push   %ebp
c01019f0:	89 e5                	mov    %esp,%ebp
    return (tf->tf_cs == (uint16_t)KERNEL_CS);
c01019f2:	8b 45 08             	mov    0x8(%ebp),%eax
c01019f5:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c01019f9:	66 83 f8 08          	cmp    $0x8,%ax
c01019fd:	0f 94 c0             	sete   %al
c0101a00:	0f b6 c0             	movzbl %al,%eax
}
c0101a03:	5d                   	pop    %ebp
c0101a04:	c3                   	ret    

c0101a05 <print_trapframe>:
    "TF", "IF", "DF", "OF", NULL, NULL, "NT", NULL,
    "RF", "VM", "AC", "VIF", "VIP", "ID", NULL, NULL,
};

void
print_trapframe(struct trapframe *tf) {
c0101a05:	55                   	push   %ebp
c0101a06:	89 e5                	mov    %esp,%ebp
c0101a08:	83 ec 18             	sub    $0x18,%esp
    cprintf("trapframe at %p\n", tf);
c0101a0b:	83 ec 08             	sub    $0x8,%esp
c0101a0e:	ff 75 08             	pushl  0x8(%ebp)
c0101a11:	68 93 5e 10 c0       	push   $0xc0105e93
c0101a16:	e8 58 e8 ff ff       	call   c0100273 <cprintf>
c0101a1b:	83 c4 10             	add    $0x10,%esp
    print_regs(&tf->tf_regs);
c0101a1e:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a21:	83 ec 0c             	sub    $0xc,%esp
c0101a24:	50                   	push   %eax
c0101a25:	e8 b8 01 00 00       	call   c0101be2 <print_regs>
c0101a2a:	83 c4 10             	add    $0x10,%esp
    cprintf("  ds   0x----%04x\n", tf->tf_ds);
c0101a2d:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a30:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
c0101a34:	0f b7 c0             	movzwl %ax,%eax
c0101a37:	83 ec 08             	sub    $0x8,%esp
c0101a3a:	50                   	push   %eax
c0101a3b:	68 a4 5e 10 c0       	push   $0xc0105ea4
c0101a40:	e8 2e e8 ff ff       	call   c0100273 <cprintf>
c0101a45:	83 c4 10             	add    $0x10,%esp
    cprintf("  es   0x----%04x\n", tf->tf_es);
c0101a48:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a4b:	0f b7 40 28          	movzwl 0x28(%eax),%eax
c0101a4f:	0f b7 c0             	movzwl %ax,%eax
c0101a52:	83 ec 08             	sub    $0x8,%esp
c0101a55:	50                   	push   %eax
c0101a56:	68 b7 5e 10 c0       	push   $0xc0105eb7
c0101a5b:	e8 13 e8 ff ff       	call   c0100273 <cprintf>
c0101a60:	83 c4 10             	add    $0x10,%esp
    cprintf("  fs   0x----%04x\n", tf->tf_fs);
c0101a63:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a66:	0f b7 40 24          	movzwl 0x24(%eax),%eax
c0101a6a:	0f b7 c0             	movzwl %ax,%eax
c0101a6d:	83 ec 08             	sub    $0x8,%esp
c0101a70:	50                   	push   %eax
c0101a71:	68 ca 5e 10 c0       	push   $0xc0105eca
c0101a76:	e8 f8 e7 ff ff       	call   c0100273 <cprintf>
c0101a7b:	83 c4 10             	add    $0x10,%esp
    cprintf("  gs   0x----%04x\n", tf->tf_gs);
c0101a7e:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a81:	0f b7 40 20          	movzwl 0x20(%eax),%eax
c0101a85:	0f b7 c0             	movzwl %ax,%eax
c0101a88:	83 ec 08             	sub    $0x8,%esp
c0101a8b:	50                   	push   %eax
c0101a8c:	68 dd 5e 10 c0       	push   $0xc0105edd
c0101a91:	e8 dd e7 ff ff       	call   c0100273 <cprintf>
c0101a96:	83 c4 10             	add    $0x10,%esp
    cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
c0101a99:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a9c:	8b 40 30             	mov    0x30(%eax),%eax
c0101a9f:	83 ec 0c             	sub    $0xc,%esp
c0101aa2:	50                   	push   %eax
c0101aa3:	e8 16 ff ff ff       	call   c01019be <trapname>
c0101aa8:	83 c4 10             	add    $0x10,%esp
c0101aab:	89 c2                	mov    %eax,%edx
c0101aad:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ab0:	8b 40 30             	mov    0x30(%eax),%eax
c0101ab3:	83 ec 04             	sub    $0x4,%esp
c0101ab6:	52                   	push   %edx
c0101ab7:	50                   	push   %eax
c0101ab8:	68 f0 5e 10 c0       	push   $0xc0105ef0
c0101abd:	e8 b1 e7 ff ff       	call   c0100273 <cprintf>
c0101ac2:	83 c4 10             	add    $0x10,%esp
    cprintf("  err  0x%08x\n", tf->tf_err);
c0101ac5:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ac8:	8b 40 34             	mov    0x34(%eax),%eax
c0101acb:	83 ec 08             	sub    $0x8,%esp
c0101ace:	50                   	push   %eax
c0101acf:	68 02 5f 10 c0       	push   $0xc0105f02
c0101ad4:	e8 9a e7 ff ff       	call   c0100273 <cprintf>
c0101ad9:	83 c4 10             	add    $0x10,%esp
    cprintf("  eip  0x%08x\n", tf->tf_eip);
c0101adc:	8b 45 08             	mov    0x8(%ebp),%eax
c0101adf:	8b 40 38             	mov    0x38(%eax),%eax
c0101ae2:	83 ec 08             	sub    $0x8,%esp
c0101ae5:	50                   	push   %eax
c0101ae6:	68 11 5f 10 c0       	push   $0xc0105f11
c0101aeb:	e8 83 e7 ff ff       	call   c0100273 <cprintf>
c0101af0:	83 c4 10             	add    $0x10,%esp
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
c0101af3:	8b 45 08             	mov    0x8(%ebp),%eax
c0101af6:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101afa:	0f b7 c0             	movzwl %ax,%eax
c0101afd:	83 ec 08             	sub    $0x8,%esp
c0101b00:	50                   	push   %eax
c0101b01:	68 20 5f 10 c0       	push   $0xc0105f20
c0101b06:	e8 68 e7 ff ff       	call   c0100273 <cprintf>
c0101b0b:	83 c4 10             	add    $0x10,%esp
    cprintf("  flag 0x%08x ", tf->tf_eflags);
c0101b0e:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b11:	8b 40 40             	mov    0x40(%eax),%eax
c0101b14:	83 ec 08             	sub    $0x8,%esp
c0101b17:	50                   	push   %eax
c0101b18:	68 33 5f 10 c0       	push   $0xc0105f33
c0101b1d:	e8 51 e7 ff ff       	call   c0100273 <cprintf>
c0101b22:	83 c4 10             	add    $0x10,%esp

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
c0101b25:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0101b2c:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
c0101b33:	eb 3f                	jmp    c0101b74 <print_trapframe+0x16f>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
c0101b35:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b38:	8b 50 40             	mov    0x40(%eax),%edx
c0101b3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0101b3e:	21 d0                	and    %edx,%eax
c0101b40:	85 c0                	test   %eax,%eax
c0101b42:	74 29                	je     c0101b6d <print_trapframe+0x168>
c0101b44:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101b47:	8b 04 85 80 75 11 c0 	mov    -0x3fee8a80(,%eax,4),%eax
c0101b4e:	85 c0                	test   %eax,%eax
c0101b50:	74 1b                	je     c0101b6d <print_trapframe+0x168>
            cprintf("%s,", IA32flags[i]);
c0101b52:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101b55:	8b 04 85 80 75 11 c0 	mov    -0x3fee8a80(,%eax,4),%eax
c0101b5c:	83 ec 08             	sub    $0x8,%esp
c0101b5f:	50                   	push   %eax
c0101b60:	68 42 5f 10 c0       	push   $0xc0105f42
c0101b65:	e8 09 e7 ff ff       	call   c0100273 <cprintf>
c0101b6a:	83 c4 10             	add    $0x10,%esp
    cprintf("  eip  0x%08x\n", tf->tf_eip);
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
    cprintf("  flag 0x%08x ", tf->tf_eflags);

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
c0101b6d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0101b71:	d1 65 f0             	shll   -0x10(%ebp)
c0101b74:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101b77:	83 f8 17             	cmp    $0x17,%eax
c0101b7a:	76 b9                	jbe    c0101b35 <print_trapframe+0x130>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
            cprintf("%s,", IA32flags[i]);
        }
    }
    cprintf("IOPL=%d\n", (tf->tf_eflags & FL_IOPL_MASK) >> 12);
c0101b7c:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b7f:	8b 40 40             	mov    0x40(%eax),%eax
c0101b82:	25 00 30 00 00       	and    $0x3000,%eax
c0101b87:	c1 e8 0c             	shr    $0xc,%eax
c0101b8a:	83 ec 08             	sub    $0x8,%esp
c0101b8d:	50                   	push   %eax
c0101b8e:	68 46 5f 10 c0       	push   $0xc0105f46
c0101b93:	e8 db e6 ff ff       	call   c0100273 <cprintf>
c0101b98:	83 c4 10             	add    $0x10,%esp

    if (!trap_in_kernel(tf)) {
c0101b9b:	83 ec 0c             	sub    $0xc,%esp
c0101b9e:	ff 75 08             	pushl  0x8(%ebp)
c0101ba1:	e8 49 fe ff ff       	call   c01019ef <trap_in_kernel>
c0101ba6:	83 c4 10             	add    $0x10,%esp
c0101ba9:	85 c0                	test   %eax,%eax
c0101bab:	75 32                	jne    c0101bdf <print_trapframe+0x1da>
        cprintf("  esp  0x%08x\n", tf->tf_esp);
c0101bad:	8b 45 08             	mov    0x8(%ebp),%eax
c0101bb0:	8b 40 44             	mov    0x44(%eax),%eax
c0101bb3:	83 ec 08             	sub    $0x8,%esp
c0101bb6:	50                   	push   %eax
c0101bb7:	68 4f 5f 10 c0       	push   $0xc0105f4f
c0101bbc:	e8 b2 e6 ff ff       	call   c0100273 <cprintf>
c0101bc1:	83 c4 10             	add    $0x10,%esp
        cprintf("  ss   0x----%04x\n", tf->tf_ss);
c0101bc4:	8b 45 08             	mov    0x8(%ebp),%eax
c0101bc7:	0f b7 40 48          	movzwl 0x48(%eax),%eax
c0101bcb:	0f b7 c0             	movzwl %ax,%eax
c0101bce:	83 ec 08             	sub    $0x8,%esp
c0101bd1:	50                   	push   %eax
c0101bd2:	68 5e 5f 10 c0       	push   $0xc0105f5e
c0101bd7:	e8 97 e6 ff ff       	call   c0100273 <cprintf>
c0101bdc:	83 c4 10             	add    $0x10,%esp
    }
}
c0101bdf:	90                   	nop
c0101be0:	c9                   	leave  
c0101be1:	c3                   	ret    

c0101be2 <print_regs>:

void
print_regs(struct pushregs *regs) {
c0101be2:	55                   	push   %ebp
c0101be3:	89 e5                	mov    %esp,%ebp
c0101be5:	83 ec 08             	sub    $0x8,%esp
    cprintf("  edi  0x%08x\n", regs->reg_edi);
c0101be8:	8b 45 08             	mov    0x8(%ebp),%eax
c0101beb:	8b 00                	mov    (%eax),%eax
c0101bed:	83 ec 08             	sub    $0x8,%esp
c0101bf0:	50                   	push   %eax
c0101bf1:	68 71 5f 10 c0       	push   $0xc0105f71
c0101bf6:	e8 78 e6 ff ff       	call   c0100273 <cprintf>
c0101bfb:	83 c4 10             	add    $0x10,%esp
    cprintf("  esi  0x%08x\n", regs->reg_esi);
c0101bfe:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c01:	8b 40 04             	mov    0x4(%eax),%eax
c0101c04:	83 ec 08             	sub    $0x8,%esp
c0101c07:	50                   	push   %eax
c0101c08:	68 80 5f 10 c0       	push   $0xc0105f80
c0101c0d:	e8 61 e6 ff ff       	call   c0100273 <cprintf>
c0101c12:	83 c4 10             	add    $0x10,%esp
    cprintf("  ebp  0x%08x\n", regs->reg_ebp);
c0101c15:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c18:	8b 40 08             	mov    0x8(%eax),%eax
c0101c1b:	83 ec 08             	sub    $0x8,%esp
c0101c1e:	50                   	push   %eax
c0101c1f:	68 8f 5f 10 c0       	push   $0xc0105f8f
c0101c24:	e8 4a e6 ff ff       	call   c0100273 <cprintf>
c0101c29:	83 c4 10             	add    $0x10,%esp
    cprintf("  oesp 0x%08x\n", regs->reg_oesp);
c0101c2c:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c2f:	8b 40 0c             	mov    0xc(%eax),%eax
c0101c32:	83 ec 08             	sub    $0x8,%esp
c0101c35:	50                   	push   %eax
c0101c36:	68 9e 5f 10 c0       	push   $0xc0105f9e
c0101c3b:	e8 33 e6 ff ff       	call   c0100273 <cprintf>
c0101c40:	83 c4 10             	add    $0x10,%esp
    cprintf("  ebx  0x%08x\n", regs->reg_ebx);
c0101c43:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c46:	8b 40 10             	mov    0x10(%eax),%eax
c0101c49:	83 ec 08             	sub    $0x8,%esp
c0101c4c:	50                   	push   %eax
c0101c4d:	68 ad 5f 10 c0       	push   $0xc0105fad
c0101c52:	e8 1c e6 ff ff       	call   c0100273 <cprintf>
c0101c57:	83 c4 10             	add    $0x10,%esp
    cprintf("  edx  0x%08x\n", regs->reg_edx);
c0101c5a:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c5d:	8b 40 14             	mov    0x14(%eax),%eax
c0101c60:	83 ec 08             	sub    $0x8,%esp
c0101c63:	50                   	push   %eax
c0101c64:	68 bc 5f 10 c0       	push   $0xc0105fbc
c0101c69:	e8 05 e6 ff ff       	call   c0100273 <cprintf>
c0101c6e:	83 c4 10             	add    $0x10,%esp
    cprintf("  ecx  0x%08x\n", regs->reg_ecx);
c0101c71:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c74:	8b 40 18             	mov    0x18(%eax),%eax
c0101c77:	83 ec 08             	sub    $0x8,%esp
c0101c7a:	50                   	push   %eax
c0101c7b:	68 cb 5f 10 c0       	push   $0xc0105fcb
c0101c80:	e8 ee e5 ff ff       	call   c0100273 <cprintf>
c0101c85:	83 c4 10             	add    $0x10,%esp
    cprintf("  eax  0x%08x\n", regs->reg_eax);
c0101c88:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c8b:	8b 40 1c             	mov    0x1c(%eax),%eax
c0101c8e:	83 ec 08             	sub    $0x8,%esp
c0101c91:	50                   	push   %eax
c0101c92:	68 da 5f 10 c0       	push   $0xc0105fda
c0101c97:	e8 d7 e5 ff ff       	call   c0100273 <cprintf>
c0101c9c:	83 c4 10             	add    $0x10,%esp
}
c0101c9f:	90                   	nop
c0101ca0:	c9                   	leave  
c0101ca1:	c3                   	ret    

c0101ca2 <trap_dispatch>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static void
trap_dispatch(struct trapframe *tf) {
c0101ca2:	55                   	push   %ebp
c0101ca3:	89 e5                	mov    %esp,%ebp
c0101ca5:	83 ec 18             	sub    $0x18,%esp
    char c;

    switch (tf->tf_trapno) {
c0101ca8:	8b 45 08             	mov    0x8(%ebp),%eax
c0101cab:	8b 40 30             	mov    0x30(%eax),%eax
c0101cae:	83 f8 2f             	cmp    $0x2f,%eax
c0101cb1:	77 1d                	ja     c0101cd0 <trap_dispatch+0x2e>
c0101cb3:	83 f8 2e             	cmp    $0x2e,%eax
c0101cb6:	0f 83 f4 00 00 00    	jae    c0101db0 <trap_dispatch+0x10e>
c0101cbc:	83 f8 21             	cmp    $0x21,%eax
c0101cbf:	74 7e                	je     c0101d3f <trap_dispatch+0x9d>
c0101cc1:	83 f8 24             	cmp    $0x24,%eax
c0101cc4:	74 55                	je     c0101d1b <trap_dispatch+0x79>
c0101cc6:	83 f8 20             	cmp    $0x20,%eax
c0101cc9:	74 16                	je     c0101ce1 <trap_dispatch+0x3f>
c0101ccb:	e9 aa 00 00 00       	jmp    c0101d7a <trap_dispatch+0xd8>
c0101cd0:	83 e8 78             	sub    $0x78,%eax
c0101cd3:	83 f8 01             	cmp    $0x1,%eax
c0101cd6:	0f 87 9e 00 00 00    	ja     c0101d7a <trap_dispatch+0xd8>
c0101cdc:	e9 82 00 00 00       	jmp    c0101d63 <trap_dispatch+0xc1>
        /* handle the timer interrupt */
        /* (1) After a timer interrupt, you should record this event using a global variable (increase it), such as ticks in kern/driver/clock.c
         * (2) Every TICK_NUM cycle, you can print some info using a funciton, such as print_ticks().
         * (3) Too Simple? Yes, I think so!
         */
        ticks ++;
c0101ce1:	a1 0c af 11 c0       	mov    0xc011af0c,%eax
c0101ce6:	83 c0 01             	add    $0x1,%eax
c0101ce9:	a3 0c af 11 c0       	mov    %eax,0xc011af0c
        if (ticks % TICK_NUM == 0) {
c0101cee:	8b 0d 0c af 11 c0    	mov    0xc011af0c,%ecx
c0101cf4:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
c0101cf9:	89 c8                	mov    %ecx,%eax
c0101cfb:	f7 e2                	mul    %edx
c0101cfd:	89 d0                	mov    %edx,%eax
c0101cff:	c1 e8 05             	shr    $0x5,%eax
c0101d02:	6b c0 64             	imul   $0x64,%eax,%eax
c0101d05:	29 c1                	sub    %eax,%ecx
c0101d07:	89 c8                	mov    %ecx,%eax
c0101d09:	85 c0                	test   %eax,%eax
c0101d0b:	0f 85 a2 00 00 00    	jne    c0101db3 <trap_dispatch+0x111>
            print_ticks();
c0101d11:	e8 79 fb ff ff       	call   c010188f <print_ticks>
        }
        break;
c0101d16:	e9 98 00 00 00       	jmp    c0101db3 <trap_dispatch+0x111>
    case IRQ_OFFSET + IRQ_COM1:
        c = cons_getc();
c0101d1b:	e8 2c f9 ff ff       	call   c010164c <cons_getc>
c0101d20:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("serial [%03d] %c\n", c, c);
c0101d23:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
c0101d27:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c0101d2b:	83 ec 04             	sub    $0x4,%esp
c0101d2e:	52                   	push   %edx
c0101d2f:	50                   	push   %eax
c0101d30:	68 e9 5f 10 c0       	push   $0xc0105fe9
c0101d35:	e8 39 e5 ff ff       	call   c0100273 <cprintf>
c0101d3a:	83 c4 10             	add    $0x10,%esp
        break;
c0101d3d:	eb 75                	jmp    c0101db4 <trap_dispatch+0x112>
    case IRQ_OFFSET + IRQ_KBD:
        c = cons_getc();
c0101d3f:	e8 08 f9 ff ff       	call   c010164c <cons_getc>
c0101d44:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("kbd [%03d] %c\n", c, c);
c0101d47:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
c0101d4b:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c0101d4f:	83 ec 04             	sub    $0x4,%esp
c0101d52:	52                   	push   %edx
c0101d53:	50                   	push   %eax
c0101d54:	68 fb 5f 10 c0       	push   $0xc0105ffb
c0101d59:	e8 15 e5 ff ff       	call   c0100273 <cprintf>
c0101d5e:	83 c4 10             	add    $0x10,%esp
        break;
c0101d61:	eb 51                	jmp    c0101db4 <trap_dispatch+0x112>
    //LAB1 CHALLENGE 1 : YOUR CODE you should modify below codes.
    case T_SWITCH_TOU:
    case T_SWITCH_TOK:
        panic("T_SWITCH_** ??\n");
c0101d63:	83 ec 04             	sub    $0x4,%esp
c0101d66:	68 0a 60 10 c0       	push   $0xc010600a
c0101d6b:	68 ac 00 00 00       	push   $0xac
c0101d70:	68 2e 5e 10 c0       	push   $0xc0105e2e
c0101d75:	e8 5f e6 ff ff       	call   c01003d9 <__panic>
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
    default:
        // in kernel, it must be a mistake
        if ((tf->tf_cs & 3) == 0) {
c0101d7a:	8b 45 08             	mov    0x8(%ebp),%eax
c0101d7d:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101d81:	0f b7 c0             	movzwl %ax,%eax
c0101d84:	83 e0 03             	and    $0x3,%eax
c0101d87:	85 c0                	test   %eax,%eax
c0101d89:	75 29                	jne    c0101db4 <trap_dispatch+0x112>
            print_trapframe(tf);
c0101d8b:	83 ec 0c             	sub    $0xc,%esp
c0101d8e:	ff 75 08             	pushl  0x8(%ebp)
c0101d91:	e8 6f fc ff ff       	call   c0101a05 <print_trapframe>
c0101d96:	83 c4 10             	add    $0x10,%esp
            panic("unexpected trap in kernel.\n");
c0101d99:	83 ec 04             	sub    $0x4,%esp
c0101d9c:	68 1a 60 10 c0       	push   $0xc010601a
c0101da1:	68 b6 00 00 00       	push   $0xb6
c0101da6:	68 2e 5e 10 c0       	push   $0xc0105e2e
c0101dab:	e8 29 e6 ff ff       	call   c01003d9 <__panic>
        panic("T_SWITCH_** ??\n");
        break;
    case IRQ_OFFSET + IRQ_IDE1:
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
c0101db0:	90                   	nop
c0101db1:	eb 01                	jmp    c0101db4 <trap_dispatch+0x112>
         */
        ticks ++;
        if (ticks % TICK_NUM == 0) {
            print_ticks();
        }
        break;
c0101db3:	90                   	nop
        if ((tf->tf_cs & 3) == 0) {
            print_trapframe(tf);
            panic("unexpected trap in kernel.\n");
        }
    }
}
c0101db4:	90                   	nop
c0101db5:	c9                   	leave  
c0101db6:	c3                   	ret    

c0101db7 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
c0101db7:	55                   	push   %ebp
c0101db8:	89 e5                	mov    %esp,%ebp
c0101dba:	83 ec 08             	sub    $0x8,%esp
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
c0101dbd:	83 ec 0c             	sub    $0xc,%esp
c0101dc0:	ff 75 08             	pushl  0x8(%ebp)
c0101dc3:	e8 da fe ff ff       	call   c0101ca2 <trap_dispatch>
c0101dc8:	83 c4 10             	add    $0x10,%esp
}
c0101dcb:	90                   	nop
c0101dcc:	c9                   	leave  
c0101dcd:	c3                   	ret    

c0101dce <vector0>:
# handler
.text
.globl __alltraps
.globl vector0
vector0:
  pushl $0
c0101dce:	6a 00                	push   $0x0
  pushl $0
c0101dd0:	6a 00                	push   $0x0
  jmp __alltraps
c0101dd2:	e9 67 0a 00 00       	jmp    c010283e <__alltraps>

c0101dd7 <vector1>:
.globl vector1
vector1:
  pushl $0
c0101dd7:	6a 00                	push   $0x0
  pushl $1
c0101dd9:	6a 01                	push   $0x1
  jmp __alltraps
c0101ddb:	e9 5e 0a 00 00       	jmp    c010283e <__alltraps>

c0101de0 <vector2>:
.globl vector2
vector2:
  pushl $0
c0101de0:	6a 00                	push   $0x0
  pushl $2
c0101de2:	6a 02                	push   $0x2
  jmp __alltraps
c0101de4:	e9 55 0a 00 00       	jmp    c010283e <__alltraps>

c0101de9 <vector3>:
.globl vector3
vector3:
  pushl $0
c0101de9:	6a 00                	push   $0x0
  pushl $3
c0101deb:	6a 03                	push   $0x3
  jmp __alltraps
c0101ded:	e9 4c 0a 00 00       	jmp    c010283e <__alltraps>

c0101df2 <vector4>:
.globl vector4
vector4:
  pushl $0
c0101df2:	6a 00                	push   $0x0
  pushl $4
c0101df4:	6a 04                	push   $0x4
  jmp __alltraps
c0101df6:	e9 43 0a 00 00       	jmp    c010283e <__alltraps>

c0101dfb <vector5>:
.globl vector5
vector5:
  pushl $0
c0101dfb:	6a 00                	push   $0x0
  pushl $5
c0101dfd:	6a 05                	push   $0x5
  jmp __alltraps
c0101dff:	e9 3a 0a 00 00       	jmp    c010283e <__alltraps>

c0101e04 <vector6>:
.globl vector6
vector6:
  pushl $0
c0101e04:	6a 00                	push   $0x0
  pushl $6
c0101e06:	6a 06                	push   $0x6
  jmp __alltraps
c0101e08:	e9 31 0a 00 00       	jmp    c010283e <__alltraps>

c0101e0d <vector7>:
.globl vector7
vector7:
  pushl $0
c0101e0d:	6a 00                	push   $0x0
  pushl $7
c0101e0f:	6a 07                	push   $0x7
  jmp __alltraps
c0101e11:	e9 28 0a 00 00       	jmp    c010283e <__alltraps>

c0101e16 <vector8>:
.globl vector8
vector8:
  pushl $8
c0101e16:	6a 08                	push   $0x8
  jmp __alltraps
c0101e18:	e9 21 0a 00 00       	jmp    c010283e <__alltraps>

c0101e1d <vector9>:
.globl vector9
vector9:
  pushl $9
c0101e1d:	6a 09                	push   $0x9
  jmp __alltraps
c0101e1f:	e9 1a 0a 00 00       	jmp    c010283e <__alltraps>

c0101e24 <vector10>:
.globl vector10
vector10:
  pushl $10
c0101e24:	6a 0a                	push   $0xa
  jmp __alltraps
c0101e26:	e9 13 0a 00 00       	jmp    c010283e <__alltraps>

c0101e2b <vector11>:
.globl vector11
vector11:
  pushl $11
c0101e2b:	6a 0b                	push   $0xb
  jmp __alltraps
c0101e2d:	e9 0c 0a 00 00       	jmp    c010283e <__alltraps>

c0101e32 <vector12>:
.globl vector12
vector12:
  pushl $12
c0101e32:	6a 0c                	push   $0xc
  jmp __alltraps
c0101e34:	e9 05 0a 00 00       	jmp    c010283e <__alltraps>

c0101e39 <vector13>:
.globl vector13
vector13:
  pushl $13
c0101e39:	6a 0d                	push   $0xd
  jmp __alltraps
c0101e3b:	e9 fe 09 00 00       	jmp    c010283e <__alltraps>

c0101e40 <vector14>:
.globl vector14
vector14:
  pushl $14
c0101e40:	6a 0e                	push   $0xe
  jmp __alltraps
c0101e42:	e9 f7 09 00 00       	jmp    c010283e <__alltraps>

c0101e47 <vector15>:
.globl vector15
vector15:
  pushl $0
c0101e47:	6a 00                	push   $0x0
  pushl $15
c0101e49:	6a 0f                	push   $0xf
  jmp __alltraps
c0101e4b:	e9 ee 09 00 00       	jmp    c010283e <__alltraps>

c0101e50 <vector16>:
.globl vector16
vector16:
  pushl $0
c0101e50:	6a 00                	push   $0x0
  pushl $16
c0101e52:	6a 10                	push   $0x10
  jmp __alltraps
c0101e54:	e9 e5 09 00 00       	jmp    c010283e <__alltraps>

c0101e59 <vector17>:
.globl vector17
vector17:
  pushl $17
c0101e59:	6a 11                	push   $0x11
  jmp __alltraps
c0101e5b:	e9 de 09 00 00       	jmp    c010283e <__alltraps>

c0101e60 <vector18>:
.globl vector18
vector18:
  pushl $0
c0101e60:	6a 00                	push   $0x0
  pushl $18
c0101e62:	6a 12                	push   $0x12
  jmp __alltraps
c0101e64:	e9 d5 09 00 00       	jmp    c010283e <__alltraps>

c0101e69 <vector19>:
.globl vector19
vector19:
  pushl $0
c0101e69:	6a 00                	push   $0x0
  pushl $19
c0101e6b:	6a 13                	push   $0x13
  jmp __alltraps
c0101e6d:	e9 cc 09 00 00       	jmp    c010283e <__alltraps>

c0101e72 <vector20>:
.globl vector20
vector20:
  pushl $0
c0101e72:	6a 00                	push   $0x0
  pushl $20
c0101e74:	6a 14                	push   $0x14
  jmp __alltraps
c0101e76:	e9 c3 09 00 00       	jmp    c010283e <__alltraps>

c0101e7b <vector21>:
.globl vector21
vector21:
  pushl $0
c0101e7b:	6a 00                	push   $0x0
  pushl $21
c0101e7d:	6a 15                	push   $0x15
  jmp __alltraps
c0101e7f:	e9 ba 09 00 00       	jmp    c010283e <__alltraps>

c0101e84 <vector22>:
.globl vector22
vector22:
  pushl $0
c0101e84:	6a 00                	push   $0x0
  pushl $22
c0101e86:	6a 16                	push   $0x16
  jmp __alltraps
c0101e88:	e9 b1 09 00 00       	jmp    c010283e <__alltraps>

c0101e8d <vector23>:
.globl vector23
vector23:
  pushl $0
c0101e8d:	6a 00                	push   $0x0
  pushl $23
c0101e8f:	6a 17                	push   $0x17
  jmp __alltraps
c0101e91:	e9 a8 09 00 00       	jmp    c010283e <__alltraps>

c0101e96 <vector24>:
.globl vector24
vector24:
  pushl $0
c0101e96:	6a 00                	push   $0x0
  pushl $24
c0101e98:	6a 18                	push   $0x18
  jmp __alltraps
c0101e9a:	e9 9f 09 00 00       	jmp    c010283e <__alltraps>

c0101e9f <vector25>:
.globl vector25
vector25:
  pushl $0
c0101e9f:	6a 00                	push   $0x0
  pushl $25
c0101ea1:	6a 19                	push   $0x19
  jmp __alltraps
c0101ea3:	e9 96 09 00 00       	jmp    c010283e <__alltraps>

c0101ea8 <vector26>:
.globl vector26
vector26:
  pushl $0
c0101ea8:	6a 00                	push   $0x0
  pushl $26
c0101eaa:	6a 1a                	push   $0x1a
  jmp __alltraps
c0101eac:	e9 8d 09 00 00       	jmp    c010283e <__alltraps>

c0101eb1 <vector27>:
.globl vector27
vector27:
  pushl $0
c0101eb1:	6a 00                	push   $0x0
  pushl $27
c0101eb3:	6a 1b                	push   $0x1b
  jmp __alltraps
c0101eb5:	e9 84 09 00 00       	jmp    c010283e <__alltraps>

c0101eba <vector28>:
.globl vector28
vector28:
  pushl $0
c0101eba:	6a 00                	push   $0x0
  pushl $28
c0101ebc:	6a 1c                	push   $0x1c
  jmp __alltraps
c0101ebe:	e9 7b 09 00 00       	jmp    c010283e <__alltraps>

c0101ec3 <vector29>:
.globl vector29
vector29:
  pushl $0
c0101ec3:	6a 00                	push   $0x0
  pushl $29
c0101ec5:	6a 1d                	push   $0x1d
  jmp __alltraps
c0101ec7:	e9 72 09 00 00       	jmp    c010283e <__alltraps>

c0101ecc <vector30>:
.globl vector30
vector30:
  pushl $0
c0101ecc:	6a 00                	push   $0x0
  pushl $30
c0101ece:	6a 1e                	push   $0x1e
  jmp __alltraps
c0101ed0:	e9 69 09 00 00       	jmp    c010283e <__alltraps>

c0101ed5 <vector31>:
.globl vector31
vector31:
  pushl $0
c0101ed5:	6a 00                	push   $0x0
  pushl $31
c0101ed7:	6a 1f                	push   $0x1f
  jmp __alltraps
c0101ed9:	e9 60 09 00 00       	jmp    c010283e <__alltraps>

c0101ede <vector32>:
.globl vector32
vector32:
  pushl $0
c0101ede:	6a 00                	push   $0x0
  pushl $32
c0101ee0:	6a 20                	push   $0x20
  jmp __alltraps
c0101ee2:	e9 57 09 00 00       	jmp    c010283e <__alltraps>

c0101ee7 <vector33>:
.globl vector33
vector33:
  pushl $0
c0101ee7:	6a 00                	push   $0x0
  pushl $33
c0101ee9:	6a 21                	push   $0x21
  jmp __alltraps
c0101eeb:	e9 4e 09 00 00       	jmp    c010283e <__alltraps>

c0101ef0 <vector34>:
.globl vector34
vector34:
  pushl $0
c0101ef0:	6a 00                	push   $0x0
  pushl $34
c0101ef2:	6a 22                	push   $0x22
  jmp __alltraps
c0101ef4:	e9 45 09 00 00       	jmp    c010283e <__alltraps>

c0101ef9 <vector35>:
.globl vector35
vector35:
  pushl $0
c0101ef9:	6a 00                	push   $0x0
  pushl $35
c0101efb:	6a 23                	push   $0x23
  jmp __alltraps
c0101efd:	e9 3c 09 00 00       	jmp    c010283e <__alltraps>

c0101f02 <vector36>:
.globl vector36
vector36:
  pushl $0
c0101f02:	6a 00                	push   $0x0
  pushl $36
c0101f04:	6a 24                	push   $0x24
  jmp __alltraps
c0101f06:	e9 33 09 00 00       	jmp    c010283e <__alltraps>

c0101f0b <vector37>:
.globl vector37
vector37:
  pushl $0
c0101f0b:	6a 00                	push   $0x0
  pushl $37
c0101f0d:	6a 25                	push   $0x25
  jmp __alltraps
c0101f0f:	e9 2a 09 00 00       	jmp    c010283e <__alltraps>

c0101f14 <vector38>:
.globl vector38
vector38:
  pushl $0
c0101f14:	6a 00                	push   $0x0
  pushl $38
c0101f16:	6a 26                	push   $0x26
  jmp __alltraps
c0101f18:	e9 21 09 00 00       	jmp    c010283e <__alltraps>

c0101f1d <vector39>:
.globl vector39
vector39:
  pushl $0
c0101f1d:	6a 00                	push   $0x0
  pushl $39
c0101f1f:	6a 27                	push   $0x27
  jmp __alltraps
c0101f21:	e9 18 09 00 00       	jmp    c010283e <__alltraps>

c0101f26 <vector40>:
.globl vector40
vector40:
  pushl $0
c0101f26:	6a 00                	push   $0x0
  pushl $40
c0101f28:	6a 28                	push   $0x28
  jmp __alltraps
c0101f2a:	e9 0f 09 00 00       	jmp    c010283e <__alltraps>

c0101f2f <vector41>:
.globl vector41
vector41:
  pushl $0
c0101f2f:	6a 00                	push   $0x0
  pushl $41
c0101f31:	6a 29                	push   $0x29
  jmp __alltraps
c0101f33:	e9 06 09 00 00       	jmp    c010283e <__alltraps>

c0101f38 <vector42>:
.globl vector42
vector42:
  pushl $0
c0101f38:	6a 00                	push   $0x0
  pushl $42
c0101f3a:	6a 2a                	push   $0x2a
  jmp __alltraps
c0101f3c:	e9 fd 08 00 00       	jmp    c010283e <__alltraps>

c0101f41 <vector43>:
.globl vector43
vector43:
  pushl $0
c0101f41:	6a 00                	push   $0x0
  pushl $43
c0101f43:	6a 2b                	push   $0x2b
  jmp __alltraps
c0101f45:	e9 f4 08 00 00       	jmp    c010283e <__alltraps>

c0101f4a <vector44>:
.globl vector44
vector44:
  pushl $0
c0101f4a:	6a 00                	push   $0x0
  pushl $44
c0101f4c:	6a 2c                	push   $0x2c
  jmp __alltraps
c0101f4e:	e9 eb 08 00 00       	jmp    c010283e <__alltraps>

c0101f53 <vector45>:
.globl vector45
vector45:
  pushl $0
c0101f53:	6a 00                	push   $0x0
  pushl $45
c0101f55:	6a 2d                	push   $0x2d
  jmp __alltraps
c0101f57:	e9 e2 08 00 00       	jmp    c010283e <__alltraps>

c0101f5c <vector46>:
.globl vector46
vector46:
  pushl $0
c0101f5c:	6a 00                	push   $0x0
  pushl $46
c0101f5e:	6a 2e                	push   $0x2e
  jmp __alltraps
c0101f60:	e9 d9 08 00 00       	jmp    c010283e <__alltraps>

c0101f65 <vector47>:
.globl vector47
vector47:
  pushl $0
c0101f65:	6a 00                	push   $0x0
  pushl $47
c0101f67:	6a 2f                	push   $0x2f
  jmp __alltraps
c0101f69:	e9 d0 08 00 00       	jmp    c010283e <__alltraps>

c0101f6e <vector48>:
.globl vector48
vector48:
  pushl $0
c0101f6e:	6a 00                	push   $0x0
  pushl $48
c0101f70:	6a 30                	push   $0x30
  jmp __alltraps
c0101f72:	e9 c7 08 00 00       	jmp    c010283e <__alltraps>

c0101f77 <vector49>:
.globl vector49
vector49:
  pushl $0
c0101f77:	6a 00                	push   $0x0
  pushl $49
c0101f79:	6a 31                	push   $0x31
  jmp __alltraps
c0101f7b:	e9 be 08 00 00       	jmp    c010283e <__alltraps>

c0101f80 <vector50>:
.globl vector50
vector50:
  pushl $0
c0101f80:	6a 00                	push   $0x0
  pushl $50
c0101f82:	6a 32                	push   $0x32
  jmp __alltraps
c0101f84:	e9 b5 08 00 00       	jmp    c010283e <__alltraps>

c0101f89 <vector51>:
.globl vector51
vector51:
  pushl $0
c0101f89:	6a 00                	push   $0x0
  pushl $51
c0101f8b:	6a 33                	push   $0x33
  jmp __alltraps
c0101f8d:	e9 ac 08 00 00       	jmp    c010283e <__alltraps>

c0101f92 <vector52>:
.globl vector52
vector52:
  pushl $0
c0101f92:	6a 00                	push   $0x0
  pushl $52
c0101f94:	6a 34                	push   $0x34
  jmp __alltraps
c0101f96:	e9 a3 08 00 00       	jmp    c010283e <__alltraps>

c0101f9b <vector53>:
.globl vector53
vector53:
  pushl $0
c0101f9b:	6a 00                	push   $0x0
  pushl $53
c0101f9d:	6a 35                	push   $0x35
  jmp __alltraps
c0101f9f:	e9 9a 08 00 00       	jmp    c010283e <__alltraps>

c0101fa4 <vector54>:
.globl vector54
vector54:
  pushl $0
c0101fa4:	6a 00                	push   $0x0
  pushl $54
c0101fa6:	6a 36                	push   $0x36
  jmp __alltraps
c0101fa8:	e9 91 08 00 00       	jmp    c010283e <__alltraps>

c0101fad <vector55>:
.globl vector55
vector55:
  pushl $0
c0101fad:	6a 00                	push   $0x0
  pushl $55
c0101faf:	6a 37                	push   $0x37
  jmp __alltraps
c0101fb1:	e9 88 08 00 00       	jmp    c010283e <__alltraps>

c0101fb6 <vector56>:
.globl vector56
vector56:
  pushl $0
c0101fb6:	6a 00                	push   $0x0
  pushl $56
c0101fb8:	6a 38                	push   $0x38
  jmp __alltraps
c0101fba:	e9 7f 08 00 00       	jmp    c010283e <__alltraps>

c0101fbf <vector57>:
.globl vector57
vector57:
  pushl $0
c0101fbf:	6a 00                	push   $0x0
  pushl $57
c0101fc1:	6a 39                	push   $0x39
  jmp __alltraps
c0101fc3:	e9 76 08 00 00       	jmp    c010283e <__alltraps>

c0101fc8 <vector58>:
.globl vector58
vector58:
  pushl $0
c0101fc8:	6a 00                	push   $0x0
  pushl $58
c0101fca:	6a 3a                	push   $0x3a
  jmp __alltraps
c0101fcc:	e9 6d 08 00 00       	jmp    c010283e <__alltraps>

c0101fd1 <vector59>:
.globl vector59
vector59:
  pushl $0
c0101fd1:	6a 00                	push   $0x0
  pushl $59
c0101fd3:	6a 3b                	push   $0x3b
  jmp __alltraps
c0101fd5:	e9 64 08 00 00       	jmp    c010283e <__alltraps>

c0101fda <vector60>:
.globl vector60
vector60:
  pushl $0
c0101fda:	6a 00                	push   $0x0
  pushl $60
c0101fdc:	6a 3c                	push   $0x3c
  jmp __alltraps
c0101fde:	e9 5b 08 00 00       	jmp    c010283e <__alltraps>

c0101fe3 <vector61>:
.globl vector61
vector61:
  pushl $0
c0101fe3:	6a 00                	push   $0x0
  pushl $61
c0101fe5:	6a 3d                	push   $0x3d
  jmp __alltraps
c0101fe7:	e9 52 08 00 00       	jmp    c010283e <__alltraps>

c0101fec <vector62>:
.globl vector62
vector62:
  pushl $0
c0101fec:	6a 00                	push   $0x0
  pushl $62
c0101fee:	6a 3e                	push   $0x3e
  jmp __alltraps
c0101ff0:	e9 49 08 00 00       	jmp    c010283e <__alltraps>

c0101ff5 <vector63>:
.globl vector63
vector63:
  pushl $0
c0101ff5:	6a 00                	push   $0x0
  pushl $63
c0101ff7:	6a 3f                	push   $0x3f
  jmp __alltraps
c0101ff9:	e9 40 08 00 00       	jmp    c010283e <__alltraps>

c0101ffe <vector64>:
.globl vector64
vector64:
  pushl $0
c0101ffe:	6a 00                	push   $0x0
  pushl $64
c0102000:	6a 40                	push   $0x40
  jmp __alltraps
c0102002:	e9 37 08 00 00       	jmp    c010283e <__alltraps>

c0102007 <vector65>:
.globl vector65
vector65:
  pushl $0
c0102007:	6a 00                	push   $0x0
  pushl $65
c0102009:	6a 41                	push   $0x41
  jmp __alltraps
c010200b:	e9 2e 08 00 00       	jmp    c010283e <__alltraps>

c0102010 <vector66>:
.globl vector66
vector66:
  pushl $0
c0102010:	6a 00                	push   $0x0
  pushl $66
c0102012:	6a 42                	push   $0x42
  jmp __alltraps
c0102014:	e9 25 08 00 00       	jmp    c010283e <__alltraps>

c0102019 <vector67>:
.globl vector67
vector67:
  pushl $0
c0102019:	6a 00                	push   $0x0
  pushl $67
c010201b:	6a 43                	push   $0x43
  jmp __alltraps
c010201d:	e9 1c 08 00 00       	jmp    c010283e <__alltraps>

c0102022 <vector68>:
.globl vector68
vector68:
  pushl $0
c0102022:	6a 00                	push   $0x0
  pushl $68
c0102024:	6a 44                	push   $0x44
  jmp __alltraps
c0102026:	e9 13 08 00 00       	jmp    c010283e <__alltraps>

c010202b <vector69>:
.globl vector69
vector69:
  pushl $0
c010202b:	6a 00                	push   $0x0
  pushl $69
c010202d:	6a 45                	push   $0x45
  jmp __alltraps
c010202f:	e9 0a 08 00 00       	jmp    c010283e <__alltraps>

c0102034 <vector70>:
.globl vector70
vector70:
  pushl $0
c0102034:	6a 00                	push   $0x0
  pushl $70
c0102036:	6a 46                	push   $0x46
  jmp __alltraps
c0102038:	e9 01 08 00 00       	jmp    c010283e <__alltraps>

c010203d <vector71>:
.globl vector71
vector71:
  pushl $0
c010203d:	6a 00                	push   $0x0
  pushl $71
c010203f:	6a 47                	push   $0x47
  jmp __alltraps
c0102041:	e9 f8 07 00 00       	jmp    c010283e <__alltraps>

c0102046 <vector72>:
.globl vector72
vector72:
  pushl $0
c0102046:	6a 00                	push   $0x0
  pushl $72
c0102048:	6a 48                	push   $0x48
  jmp __alltraps
c010204a:	e9 ef 07 00 00       	jmp    c010283e <__alltraps>

c010204f <vector73>:
.globl vector73
vector73:
  pushl $0
c010204f:	6a 00                	push   $0x0
  pushl $73
c0102051:	6a 49                	push   $0x49
  jmp __alltraps
c0102053:	e9 e6 07 00 00       	jmp    c010283e <__alltraps>

c0102058 <vector74>:
.globl vector74
vector74:
  pushl $0
c0102058:	6a 00                	push   $0x0
  pushl $74
c010205a:	6a 4a                	push   $0x4a
  jmp __alltraps
c010205c:	e9 dd 07 00 00       	jmp    c010283e <__alltraps>

c0102061 <vector75>:
.globl vector75
vector75:
  pushl $0
c0102061:	6a 00                	push   $0x0
  pushl $75
c0102063:	6a 4b                	push   $0x4b
  jmp __alltraps
c0102065:	e9 d4 07 00 00       	jmp    c010283e <__alltraps>

c010206a <vector76>:
.globl vector76
vector76:
  pushl $0
c010206a:	6a 00                	push   $0x0
  pushl $76
c010206c:	6a 4c                	push   $0x4c
  jmp __alltraps
c010206e:	e9 cb 07 00 00       	jmp    c010283e <__alltraps>

c0102073 <vector77>:
.globl vector77
vector77:
  pushl $0
c0102073:	6a 00                	push   $0x0
  pushl $77
c0102075:	6a 4d                	push   $0x4d
  jmp __alltraps
c0102077:	e9 c2 07 00 00       	jmp    c010283e <__alltraps>

c010207c <vector78>:
.globl vector78
vector78:
  pushl $0
c010207c:	6a 00                	push   $0x0
  pushl $78
c010207e:	6a 4e                	push   $0x4e
  jmp __alltraps
c0102080:	e9 b9 07 00 00       	jmp    c010283e <__alltraps>

c0102085 <vector79>:
.globl vector79
vector79:
  pushl $0
c0102085:	6a 00                	push   $0x0
  pushl $79
c0102087:	6a 4f                	push   $0x4f
  jmp __alltraps
c0102089:	e9 b0 07 00 00       	jmp    c010283e <__alltraps>

c010208e <vector80>:
.globl vector80
vector80:
  pushl $0
c010208e:	6a 00                	push   $0x0
  pushl $80
c0102090:	6a 50                	push   $0x50
  jmp __alltraps
c0102092:	e9 a7 07 00 00       	jmp    c010283e <__alltraps>

c0102097 <vector81>:
.globl vector81
vector81:
  pushl $0
c0102097:	6a 00                	push   $0x0
  pushl $81
c0102099:	6a 51                	push   $0x51
  jmp __alltraps
c010209b:	e9 9e 07 00 00       	jmp    c010283e <__alltraps>

c01020a0 <vector82>:
.globl vector82
vector82:
  pushl $0
c01020a0:	6a 00                	push   $0x0
  pushl $82
c01020a2:	6a 52                	push   $0x52
  jmp __alltraps
c01020a4:	e9 95 07 00 00       	jmp    c010283e <__alltraps>

c01020a9 <vector83>:
.globl vector83
vector83:
  pushl $0
c01020a9:	6a 00                	push   $0x0
  pushl $83
c01020ab:	6a 53                	push   $0x53
  jmp __alltraps
c01020ad:	e9 8c 07 00 00       	jmp    c010283e <__alltraps>

c01020b2 <vector84>:
.globl vector84
vector84:
  pushl $0
c01020b2:	6a 00                	push   $0x0
  pushl $84
c01020b4:	6a 54                	push   $0x54
  jmp __alltraps
c01020b6:	e9 83 07 00 00       	jmp    c010283e <__alltraps>

c01020bb <vector85>:
.globl vector85
vector85:
  pushl $0
c01020bb:	6a 00                	push   $0x0
  pushl $85
c01020bd:	6a 55                	push   $0x55
  jmp __alltraps
c01020bf:	e9 7a 07 00 00       	jmp    c010283e <__alltraps>

c01020c4 <vector86>:
.globl vector86
vector86:
  pushl $0
c01020c4:	6a 00                	push   $0x0
  pushl $86
c01020c6:	6a 56                	push   $0x56
  jmp __alltraps
c01020c8:	e9 71 07 00 00       	jmp    c010283e <__alltraps>

c01020cd <vector87>:
.globl vector87
vector87:
  pushl $0
c01020cd:	6a 00                	push   $0x0
  pushl $87
c01020cf:	6a 57                	push   $0x57
  jmp __alltraps
c01020d1:	e9 68 07 00 00       	jmp    c010283e <__alltraps>

c01020d6 <vector88>:
.globl vector88
vector88:
  pushl $0
c01020d6:	6a 00                	push   $0x0
  pushl $88
c01020d8:	6a 58                	push   $0x58
  jmp __alltraps
c01020da:	e9 5f 07 00 00       	jmp    c010283e <__alltraps>

c01020df <vector89>:
.globl vector89
vector89:
  pushl $0
c01020df:	6a 00                	push   $0x0
  pushl $89
c01020e1:	6a 59                	push   $0x59
  jmp __alltraps
c01020e3:	e9 56 07 00 00       	jmp    c010283e <__alltraps>

c01020e8 <vector90>:
.globl vector90
vector90:
  pushl $0
c01020e8:	6a 00                	push   $0x0
  pushl $90
c01020ea:	6a 5a                	push   $0x5a
  jmp __alltraps
c01020ec:	e9 4d 07 00 00       	jmp    c010283e <__alltraps>

c01020f1 <vector91>:
.globl vector91
vector91:
  pushl $0
c01020f1:	6a 00                	push   $0x0
  pushl $91
c01020f3:	6a 5b                	push   $0x5b
  jmp __alltraps
c01020f5:	e9 44 07 00 00       	jmp    c010283e <__alltraps>

c01020fa <vector92>:
.globl vector92
vector92:
  pushl $0
c01020fa:	6a 00                	push   $0x0
  pushl $92
c01020fc:	6a 5c                	push   $0x5c
  jmp __alltraps
c01020fe:	e9 3b 07 00 00       	jmp    c010283e <__alltraps>

c0102103 <vector93>:
.globl vector93
vector93:
  pushl $0
c0102103:	6a 00                	push   $0x0
  pushl $93
c0102105:	6a 5d                	push   $0x5d
  jmp __alltraps
c0102107:	e9 32 07 00 00       	jmp    c010283e <__alltraps>

c010210c <vector94>:
.globl vector94
vector94:
  pushl $0
c010210c:	6a 00                	push   $0x0
  pushl $94
c010210e:	6a 5e                	push   $0x5e
  jmp __alltraps
c0102110:	e9 29 07 00 00       	jmp    c010283e <__alltraps>

c0102115 <vector95>:
.globl vector95
vector95:
  pushl $0
c0102115:	6a 00                	push   $0x0
  pushl $95
c0102117:	6a 5f                	push   $0x5f
  jmp __alltraps
c0102119:	e9 20 07 00 00       	jmp    c010283e <__alltraps>

c010211e <vector96>:
.globl vector96
vector96:
  pushl $0
c010211e:	6a 00                	push   $0x0
  pushl $96
c0102120:	6a 60                	push   $0x60
  jmp __alltraps
c0102122:	e9 17 07 00 00       	jmp    c010283e <__alltraps>

c0102127 <vector97>:
.globl vector97
vector97:
  pushl $0
c0102127:	6a 00                	push   $0x0
  pushl $97
c0102129:	6a 61                	push   $0x61
  jmp __alltraps
c010212b:	e9 0e 07 00 00       	jmp    c010283e <__alltraps>

c0102130 <vector98>:
.globl vector98
vector98:
  pushl $0
c0102130:	6a 00                	push   $0x0
  pushl $98
c0102132:	6a 62                	push   $0x62
  jmp __alltraps
c0102134:	e9 05 07 00 00       	jmp    c010283e <__alltraps>

c0102139 <vector99>:
.globl vector99
vector99:
  pushl $0
c0102139:	6a 00                	push   $0x0
  pushl $99
c010213b:	6a 63                	push   $0x63
  jmp __alltraps
c010213d:	e9 fc 06 00 00       	jmp    c010283e <__alltraps>

c0102142 <vector100>:
.globl vector100
vector100:
  pushl $0
c0102142:	6a 00                	push   $0x0
  pushl $100
c0102144:	6a 64                	push   $0x64
  jmp __alltraps
c0102146:	e9 f3 06 00 00       	jmp    c010283e <__alltraps>

c010214b <vector101>:
.globl vector101
vector101:
  pushl $0
c010214b:	6a 00                	push   $0x0
  pushl $101
c010214d:	6a 65                	push   $0x65
  jmp __alltraps
c010214f:	e9 ea 06 00 00       	jmp    c010283e <__alltraps>

c0102154 <vector102>:
.globl vector102
vector102:
  pushl $0
c0102154:	6a 00                	push   $0x0
  pushl $102
c0102156:	6a 66                	push   $0x66
  jmp __alltraps
c0102158:	e9 e1 06 00 00       	jmp    c010283e <__alltraps>

c010215d <vector103>:
.globl vector103
vector103:
  pushl $0
c010215d:	6a 00                	push   $0x0
  pushl $103
c010215f:	6a 67                	push   $0x67
  jmp __alltraps
c0102161:	e9 d8 06 00 00       	jmp    c010283e <__alltraps>

c0102166 <vector104>:
.globl vector104
vector104:
  pushl $0
c0102166:	6a 00                	push   $0x0
  pushl $104
c0102168:	6a 68                	push   $0x68
  jmp __alltraps
c010216a:	e9 cf 06 00 00       	jmp    c010283e <__alltraps>

c010216f <vector105>:
.globl vector105
vector105:
  pushl $0
c010216f:	6a 00                	push   $0x0
  pushl $105
c0102171:	6a 69                	push   $0x69
  jmp __alltraps
c0102173:	e9 c6 06 00 00       	jmp    c010283e <__alltraps>

c0102178 <vector106>:
.globl vector106
vector106:
  pushl $0
c0102178:	6a 00                	push   $0x0
  pushl $106
c010217a:	6a 6a                	push   $0x6a
  jmp __alltraps
c010217c:	e9 bd 06 00 00       	jmp    c010283e <__alltraps>

c0102181 <vector107>:
.globl vector107
vector107:
  pushl $0
c0102181:	6a 00                	push   $0x0
  pushl $107
c0102183:	6a 6b                	push   $0x6b
  jmp __alltraps
c0102185:	e9 b4 06 00 00       	jmp    c010283e <__alltraps>

c010218a <vector108>:
.globl vector108
vector108:
  pushl $0
c010218a:	6a 00                	push   $0x0
  pushl $108
c010218c:	6a 6c                	push   $0x6c
  jmp __alltraps
c010218e:	e9 ab 06 00 00       	jmp    c010283e <__alltraps>

c0102193 <vector109>:
.globl vector109
vector109:
  pushl $0
c0102193:	6a 00                	push   $0x0
  pushl $109
c0102195:	6a 6d                	push   $0x6d
  jmp __alltraps
c0102197:	e9 a2 06 00 00       	jmp    c010283e <__alltraps>

c010219c <vector110>:
.globl vector110
vector110:
  pushl $0
c010219c:	6a 00                	push   $0x0
  pushl $110
c010219e:	6a 6e                	push   $0x6e
  jmp __alltraps
c01021a0:	e9 99 06 00 00       	jmp    c010283e <__alltraps>

c01021a5 <vector111>:
.globl vector111
vector111:
  pushl $0
c01021a5:	6a 00                	push   $0x0
  pushl $111
c01021a7:	6a 6f                	push   $0x6f
  jmp __alltraps
c01021a9:	e9 90 06 00 00       	jmp    c010283e <__alltraps>

c01021ae <vector112>:
.globl vector112
vector112:
  pushl $0
c01021ae:	6a 00                	push   $0x0
  pushl $112
c01021b0:	6a 70                	push   $0x70
  jmp __alltraps
c01021b2:	e9 87 06 00 00       	jmp    c010283e <__alltraps>

c01021b7 <vector113>:
.globl vector113
vector113:
  pushl $0
c01021b7:	6a 00                	push   $0x0
  pushl $113
c01021b9:	6a 71                	push   $0x71
  jmp __alltraps
c01021bb:	e9 7e 06 00 00       	jmp    c010283e <__alltraps>

c01021c0 <vector114>:
.globl vector114
vector114:
  pushl $0
c01021c0:	6a 00                	push   $0x0
  pushl $114
c01021c2:	6a 72                	push   $0x72
  jmp __alltraps
c01021c4:	e9 75 06 00 00       	jmp    c010283e <__alltraps>

c01021c9 <vector115>:
.globl vector115
vector115:
  pushl $0
c01021c9:	6a 00                	push   $0x0
  pushl $115
c01021cb:	6a 73                	push   $0x73
  jmp __alltraps
c01021cd:	e9 6c 06 00 00       	jmp    c010283e <__alltraps>

c01021d2 <vector116>:
.globl vector116
vector116:
  pushl $0
c01021d2:	6a 00                	push   $0x0
  pushl $116
c01021d4:	6a 74                	push   $0x74
  jmp __alltraps
c01021d6:	e9 63 06 00 00       	jmp    c010283e <__alltraps>

c01021db <vector117>:
.globl vector117
vector117:
  pushl $0
c01021db:	6a 00                	push   $0x0
  pushl $117
c01021dd:	6a 75                	push   $0x75
  jmp __alltraps
c01021df:	e9 5a 06 00 00       	jmp    c010283e <__alltraps>

c01021e4 <vector118>:
.globl vector118
vector118:
  pushl $0
c01021e4:	6a 00                	push   $0x0
  pushl $118
c01021e6:	6a 76                	push   $0x76
  jmp __alltraps
c01021e8:	e9 51 06 00 00       	jmp    c010283e <__alltraps>

c01021ed <vector119>:
.globl vector119
vector119:
  pushl $0
c01021ed:	6a 00                	push   $0x0
  pushl $119
c01021ef:	6a 77                	push   $0x77
  jmp __alltraps
c01021f1:	e9 48 06 00 00       	jmp    c010283e <__alltraps>

c01021f6 <vector120>:
.globl vector120
vector120:
  pushl $0
c01021f6:	6a 00                	push   $0x0
  pushl $120
c01021f8:	6a 78                	push   $0x78
  jmp __alltraps
c01021fa:	e9 3f 06 00 00       	jmp    c010283e <__alltraps>

c01021ff <vector121>:
.globl vector121
vector121:
  pushl $0
c01021ff:	6a 00                	push   $0x0
  pushl $121
c0102201:	6a 79                	push   $0x79
  jmp __alltraps
c0102203:	e9 36 06 00 00       	jmp    c010283e <__alltraps>

c0102208 <vector122>:
.globl vector122
vector122:
  pushl $0
c0102208:	6a 00                	push   $0x0
  pushl $122
c010220a:	6a 7a                	push   $0x7a
  jmp __alltraps
c010220c:	e9 2d 06 00 00       	jmp    c010283e <__alltraps>

c0102211 <vector123>:
.globl vector123
vector123:
  pushl $0
c0102211:	6a 00                	push   $0x0
  pushl $123
c0102213:	6a 7b                	push   $0x7b
  jmp __alltraps
c0102215:	e9 24 06 00 00       	jmp    c010283e <__alltraps>

c010221a <vector124>:
.globl vector124
vector124:
  pushl $0
c010221a:	6a 00                	push   $0x0
  pushl $124
c010221c:	6a 7c                	push   $0x7c
  jmp __alltraps
c010221e:	e9 1b 06 00 00       	jmp    c010283e <__alltraps>

c0102223 <vector125>:
.globl vector125
vector125:
  pushl $0
c0102223:	6a 00                	push   $0x0
  pushl $125
c0102225:	6a 7d                	push   $0x7d
  jmp __alltraps
c0102227:	e9 12 06 00 00       	jmp    c010283e <__alltraps>

c010222c <vector126>:
.globl vector126
vector126:
  pushl $0
c010222c:	6a 00                	push   $0x0
  pushl $126
c010222e:	6a 7e                	push   $0x7e
  jmp __alltraps
c0102230:	e9 09 06 00 00       	jmp    c010283e <__alltraps>

c0102235 <vector127>:
.globl vector127
vector127:
  pushl $0
c0102235:	6a 00                	push   $0x0
  pushl $127
c0102237:	6a 7f                	push   $0x7f
  jmp __alltraps
c0102239:	e9 00 06 00 00       	jmp    c010283e <__alltraps>

c010223e <vector128>:
.globl vector128
vector128:
  pushl $0
c010223e:	6a 00                	push   $0x0
  pushl $128
c0102240:	68 80 00 00 00       	push   $0x80
  jmp __alltraps
c0102245:	e9 f4 05 00 00       	jmp    c010283e <__alltraps>

c010224a <vector129>:
.globl vector129
vector129:
  pushl $0
c010224a:	6a 00                	push   $0x0
  pushl $129
c010224c:	68 81 00 00 00       	push   $0x81
  jmp __alltraps
c0102251:	e9 e8 05 00 00       	jmp    c010283e <__alltraps>

c0102256 <vector130>:
.globl vector130
vector130:
  pushl $0
c0102256:	6a 00                	push   $0x0
  pushl $130
c0102258:	68 82 00 00 00       	push   $0x82
  jmp __alltraps
c010225d:	e9 dc 05 00 00       	jmp    c010283e <__alltraps>

c0102262 <vector131>:
.globl vector131
vector131:
  pushl $0
c0102262:	6a 00                	push   $0x0
  pushl $131
c0102264:	68 83 00 00 00       	push   $0x83
  jmp __alltraps
c0102269:	e9 d0 05 00 00       	jmp    c010283e <__alltraps>

c010226e <vector132>:
.globl vector132
vector132:
  pushl $0
c010226e:	6a 00                	push   $0x0
  pushl $132
c0102270:	68 84 00 00 00       	push   $0x84
  jmp __alltraps
c0102275:	e9 c4 05 00 00       	jmp    c010283e <__alltraps>

c010227a <vector133>:
.globl vector133
vector133:
  pushl $0
c010227a:	6a 00                	push   $0x0
  pushl $133
c010227c:	68 85 00 00 00       	push   $0x85
  jmp __alltraps
c0102281:	e9 b8 05 00 00       	jmp    c010283e <__alltraps>

c0102286 <vector134>:
.globl vector134
vector134:
  pushl $0
c0102286:	6a 00                	push   $0x0
  pushl $134
c0102288:	68 86 00 00 00       	push   $0x86
  jmp __alltraps
c010228d:	e9 ac 05 00 00       	jmp    c010283e <__alltraps>

c0102292 <vector135>:
.globl vector135
vector135:
  pushl $0
c0102292:	6a 00                	push   $0x0
  pushl $135
c0102294:	68 87 00 00 00       	push   $0x87
  jmp __alltraps
c0102299:	e9 a0 05 00 00       	jmp    c010283e <__alltraps>

c010229e <vector136>:
.globl vector136
vector136:
  pushl $0
c010229e:	6a 00                	push   $0x0
  pushl $136
c01022a0:	68 88 00 00 00       	push   $0x88
  jmp __alltraps
c01022a5:	e9 94 05 00 00       	jmp    c010283e <__alltraps>

c01022aa <vector137>:
.globl vector137
vector137:
  pushl $0
c01022aa:	6a 00                	push   $0x0
  pushl $137
c01022ac:	68 89 00 00 00       	push   $0x89
  jmp __alltraps
c01022b1:	e9 88 05 00 00       	jmp    c010283e <__alltraps>

c01022b6 <vector138>:
.globl vector138
vector138:
  pushl $0
c01022b6:	6a 00                	push   $0x0
  pushl $138
c01022b8:	68 8a 00 00 00       	push   $0x8a
  jmp __alltraps
c01022bd:	e9 7c 05 00 00       	jmp    c010283e <__alltraps>

c01022c2 <vector139>:
.globl vector139
vector139:
  pushl $0
c01022c2:	6a 00                	push   $0x0
  pushl $139
c01022c4:	68 8b 00 00 00       	push   $0x8b
  jmp __alltraps
c01022c9:	e9 70 05 00 00       	jmp    c010283e <__alltraps>

c01022ce <vector140>:
.globl vector140
vector140:
  pushl $0
c01022ce:	6a 00                	push   $0x0
  pushl $140
c01022d0:	68 8c 00 00 00       	push   $0x8c
  jmp __alltraps
c01022d5:	e9 64 05 00 00       	jmp    c010283e <__alltraps>

c01022da <vector141>:
.globl vector141
vector141:
  pushl $0
c01022da:	6a 00                	push   $0x0
  pushl $141
c01022dc:	68 8d 00 00 00       	push   $0x8d
  jmp __alltraps
c01022e1:	e9 58 05 00 00       	jmp    c010283e <__alltraps>

c01022e6 <vector142>:
.globl vector142
vector142:
  pushl $0
c01022e6:	6a 00                	push   $0x0
  pushl $142
c01022e8:	68 8e 00 00 00       	push   $0x8e
  jmp __alltraps
c01022ed:	e9 4c 05 00 00       	jmp    c010283e <__alltraps>

c01022f2 <vector143>:
.globl vector143
vector143:
  pushl $0
c01022f2:	6a 00                	push   $0x0
  pushl $143
c01022f4:	68 8f 00 00 00       	push   $0x8f
  jmp __alltraps
c01022f9:	e9 40 05 00 00       	jmp    c010283e <__alltraps>

c01022fe <vector144>:
.globl vector144
vector144:
  pushl $0
c01022fe:	6a 00                	push   $0x0
  pushl $144
c0102300:	68 90 00 00 00       	push   $0x90
  jmp __alltraps
c0102305:	e9 34 05 00 00       	jmp    c010283e <__alltraps>

c010230a <vector145>:
.globl vector145
vector145:
  pushl $0
c010230a:	6a 00                	push   $0x0
  pushl $145
c010230c:	68 91 00 00 00       	push   $0x91
  jmp __alltraps
c0102311:	e9 28 05 00 00       	jmp    c010283e <__alltraps>

c0102316 <vector146>:
.globl vector146
vector146:
  pushl $0
c0102316:	6a 00                	push   $0x0
  pushl $146
c0102318:	68 92 00 00 00       	push   $0x92
  jmp __alltraps
c010231d:	e9 1c 05 00 00       	jmp    c010283e <__alltraps>

c0102322 <vector147>:
.globl vector147
vector147:
  pushl $0
c0102322:	6a 00                	push   $0x0
  pushl $147
c0102324:	68 93 00 00 00       	push   $0x93
  jmp __alltraps
c0102329:	e9 10 05 00 00       	jmp    c010283e <__alltraps>

c010232e <vector148>:
.globl vector148
vector148:
  pushl $0
c010232e:	6a 00                	push   $0x0
  pushl $148
c0102330:	68 94 00 00 00       	push   $0x94
  jmp __alltraps
c0102335:	e9 04 05 00 00       	jmp    c010283e <__alltraps>

c010233a <vector149>:
.globl vector149
vector149:
  pushl $0
c010233a:	6a 00                	push   $0x0
  pushl $149
c010233c:	68 95 00 00 00       	push   $0x95
  jmp __alltraps
c0102341:	e9 f8 04 00 00       	jmp    c010283e <__alltraps>

c0102346 <vector150>:
.globl vector150
vector150:
  pushl $0
c0102346:	6a 00                	push   $0x0
  pushl $150
c0102348:	68 96 00 00 00       	push   $0x96
  jmp __alltraps
c010234d:	e9 ec 04 00 00       	jmp    c010283e <__alltraps>

c0102352 <vector151>:
.globl vector151
vector151:
  pushl $0
c0102352:	6a 00                	push   $0x0
  pushl $151
c0102354:	68 97 00 00 00       	push   $0x97
  jmp __alltraps
c0102359:	e9 e0 04 00 00       	jmp    c010283e <__alltraps>

c010235e <vector152>:
.globl vector152
vector152:
  pushl $0
c010235e:	6a 00                	push   $0x0
  pushl $152
c0102360:	68 98 00 00 00       	push   $0x98
  jmp __alltraps
c0102365:	e9 d4 04 00 00       	jmp    c010283e <__alltraps>

c010236a <vector153>:
.globl vector153
vector153:
  pushl $0
c010236a:	6a 00                	push   $0x0
  pushl $153
c010236c:	68 99 00 00 00       	push   $0x99
  jmp __alltraps
c0102371:	e9 c8 04 00 00       	jmp    c010283e <__alltraps>

c0102376 <vector154>:
.globl vector154
vector154:
  pushl $0
c0102376:	6a 00                	push   $0x0
  pushl $154
c0102378:	68 9a 00 00 00       	push   $0x9a
  jmp __alltraps
c010237d:	e9 bc 04 00 00       	jmp    c010283e <__alltraps>

c0102382 <vector155>:
.globl vector155
vector155:
  pushl $0
c0102382:	6a 00                	push   $0x0
  pushl $155
c0102384:	68 9b 00 00 00       	push   $0x9b
  jmp __alltraps
c0102389:	e9 b0 04 00 00       	jmp    c010283e <__alltraps>

c010238e <vector156>:
.globl vector156
vector156:
  pushl $0
c010238e:	6a 00                	push   $0x0
  pushl $156
c0102390:	68 9c 00 00 00       	push   $0x9c
  jmp __alltraps
c0102395:	e9 a4 04 00 00       	jmp    c010283e <__alltraps>

c010239a <vector157>:
.globl vector157
vector157:
  pushl $0
c010239a:	6a 00                	push   $0x0
  pushl $157
c010239c:	68 9d 00 00 00       	push   $0x9d
  jmp __alltraps
c01023a1:	e9 98 04 00 00       	jmp    c010283e <__alltraps>

c01023a6 <vector158>:
.globl vector158
vector158:
  pushl $0
c01023a6:	6a 00                	push   $0x0
  pushl $158
c01023a8:	68 9e 00 00 00       	push   $0x9e
  jmp __alltraps
c01023ad:	e9 8c 04 00 00       	jmp    c010283e <__alltraps>

c01023b2 <vector159>:
.globl vector159
vector159:
  pushl $0
c01023b2:	6a 00                	push   $0x0
  pushl $159
c01023b4:	68 9f 00 00 00       	push   $0x9f
  jmp __alltraps
c01023b9:	e9 80 04 00 00       	jmp    c010283e <__alltraps>

c01023be <vector160>:
.globl vector160
vector160:
  pushl $0
c01023be:	6a 00                	push   $0x0
  pushl $160
c01023c0:	68 a0 00 00 00       	push   $0xa0
  jmp __alltraps
c01023c5:	e9 74 04 00 00       	jmp    c010283e <__alltraps>

c01023ca <vector161>:
.globl vector161
vector161:
  pushl $0
c01023ca:	6a 00                	push   $0x0
  pushl $161
c01023cc:	68 a1 00 00 00       	push   $0xa1
  jmp __alltraps
c01023d1:	e9 68 04 00 00       	jmp    c010283e <__alltraps>

c01023d6 <vector162>:
.globl vector162
vector162:
  pushl $0
c01023d6:	6a 00                	push   $0x0
  pushl $162
c01023d8:	68 a2 00 00 00       	push   $0xa2
  jmp __alltraps
c01023dd:	e9 5c 04 00 00       	jmp    c010283e <__alltraps>

c01023e2 <vector163>:
.globl vector163
vector163:
  pushl $0
c01023e2:	6a 00                	push   $0x0
  pushl $163
c01023e4:	68 a3 00 00 00       	push   $0xa3
  jmp __alltraps
c01023e9:	e9 50 04 00 00       	jmp    c010283e <__alltraps>

c01023ee <vector164>:
.globl vector164
vector164:
  pushl $0
c01023ee:	6a 00                	push   $0x0
  pushl $164
c01023f0:	68 a4 00 00 00       	push   $0xa4
  jmp __alltraps
c01023f5:	e9 44 04 00 00       	jmp    c010283e <__alltraps>

c01023fa <vector165>:
.globl vector165
vector165:
  pushl $0
c01023fa:	6a 00                	push   $0x0
  pushl $165
c01023fc:	68 a5 00 00 00       	push   $0xa5
  jmp __alltraps
c0102401:	e9 38 04 00 00       	jmp    c010283e <__alltraps>

c0102406 <vector166>:
.globl vector166
vector166:
  pushl $0
c0102406:	6a 00                	push   $0x0
  pushl $166
c0102408:	68 a6 00 00 00       	push   $0xa6
  jmp __alltraps
c010240d:	e9 2c 04 00 00       	jmp    c010283e <__alltraps>

c0102412 <vector167>:
.globl vector167
vector167:
  pushl $0
c0102412:	6a 00                	push   $0x0
  pushl $167
c0102414:	68 a7 00 00 00       	push   $0xa7
  jmp __alltraps
c0102419:	e9 20 04 00 00       	jmp    c010283e <__alltraps>

c010241e <vector168>:
.globl vector168
vector168:
  pushl $0
c010241e:	6a 00                	push   $0x0
  pushl $168
c0102420:	68 a8 00 00 00       	push   $0xa8
  jmp __alltraps
c0102425:	e9 14 04 00 00       	jmp    c010283e <__alltraps>

c010242a <vector169>:
.globl vector169
vector169:
  pushl $0
c010242a:	6a 00                	push   $0x0
  pushl $169
c010242c:	68 a9 00 00 00       	push   $0xa9
  jmp __alltraps
c0102431:	e9 08 04 00 00       	jmp    c010283e <__alltraps>

c0102436 <vector170>:
.globl vector170
vector170:
  pushl $0
c0102436:	6a 00                	push   $0x0
  pushl $170
c0102438:	68 aa 00 00 00       	push   $0xaa
  jmp __alltraps
c010243d:	e9 fc 03 00 00       	jmp    c010283e <__alltraps>

c0102442 <vector171>:
.globl vector171
vector171:
  pushl $0
c0102442:	6a 00                	push   $0x0
  pushl $171
c0102444:	68 ab 00 00 00       	push   $0xab
  jmp __alltraps
c0102449:	e9 f0 03 00 00       	jmp    c010283e <__alltraps>

c010244e <vector172>:
.globl vector172
vector172:
  pushl $0
c010244e:	6a 00                	push   $0x0
  pushl $172
c0102450:	68 ac 00 00 00       	push   $0xac
  jmp __alltraps
c0102455:	e9 e4 03 00 00       	jmp    c010283e <__alltraps>

c010245a <vector173>:
.globl vector173
vector173:
  pushl $0
c010245a:	6a 00                	push   $0x0
  pushl $173
c010245c:	68 ad 00 00 00       	push   $0xad
  jmp __alltraps
c0102461:	e9 d8 03 00 00       	jmp    c010283e <__alltraps>

c0102466 <vector174>:
.globl vector174
vector174:
  pushl $0
c0102466:	6a 00                	push   $0x0
  pushl $174
c0102468:	68 ae 00 00 00       	push   $0xae
  jmp __alltraps
c010246d:	e9 cc 03 00 00       	jmp    c010283e <__alltraps>

c0102472 <vector175>:
.globl vector175
vector175:
  pushl $0
c0102472:	6a 00                	push   $0x0
  pushl $175
c0102474:	68 af 00 00 00       	push   $0xaf
  jmp __alltraps
c0102479:	e9 c0 03 00 00       	jmp    c010283e <__alltraps>

c010247e <vector176>:
.globl vector176
vector176:
  pushl $0
c010247e:	6a 00                	push   $0x0
  pushl $176
c0102480:	68 b0 00 00 00       	push   $0xb0
  jmp __alltraps
c0102485:	e9 b4 03 00 00       	jmp    c010283e <__alltraps>

c010248a <vector177>:
.globl vector177
vector177:
  pushl $0
c010248a:	6a 00                	push   $0x0
  pushl $177
c010248c:	68 b1 00 00 00       	push   $0xb1
  jmp __alltraps
c0102491:	e9 a8 03 00 00       	jmp    c010283e <__alltraps>

c0102496 <vector178>:
.globl vector178
vector178:
  pushl $0
c0102496:	6a 00                	push   $0x0
  pushl $178
c0102498:	68 b2 00 00 00       	push   $0xb2
  jmp __alltraps
c010249d:	e9 9c 03 00 00       	jmp    c010283e <__alltraps>

c01024a2 <vector179>:
.globl vector179
vector179:
  pushl $0
c01024a2:	6a 00                	push   $0x0
  pushl $179
c01024a4:	68 b3 00 00 00       	push   $0xb3
  jmp __alltraps
c01024a9:	e9 90 03 00 00       	jmp    c010283e <__alltraps>

c01024ae <vector180>:
.globl vector180
vector180:
  pushl $0
c01024ae:	6a 00                	push   $0x0
  pushl $180
c01024b0:	68 b4 00 00 00       	push   $0xb4
  jmp __alltraps
c01024b5:	e9 84 03 00 00       	jmp    c010283e <__alltraps>

c01024ba <vector181>:
.globl vector181
vector181:
  pushl $0
c01024ba:	6a 00                	push   $0x0
  pushl $181
c01024bc:	68 b5 00 00 00       	push   $0xb5
  jmp __alltraps
c01024c1:	e9 78 03 00 00       	jmp    c010283e <__alltraps>

c01024c6 <vector182>:
.globl vector182
vector182:
  pushl $0
c01024c6:	6a 00                	push   $0x0
  pushl $182
c01024c8:	68 b6 00 00 00       	push   $0xb6
  jmp __alltraps
c01024cd:	e9 6c 03 00 00       	jmp    c010283e <__alltraps>

c01024d2 <vector183>:
.globl vector183
vector183:
  pushl $0
c01024d2:	6a 00                	push   $0x0
  pushl $183
c01024d4:	68 b7 00 00 00       	push   $0xb7
  jmp __alltraps
c01024d9:	e9 60 03 00 00       	jmp    c010283e <__alltraps>

c01024de <vector184>:
.globl vector184
vector184:
  pushl $0
c01024de:	6a 00                	push   $0x0
  pushl $184
c01024e0:	68 b8 00 00 00       	push   $0xb8
  jmp __alltraps
c01024e5:	e9 54 03 00 00       	jmp    c010283e <__alltraps>

c01024ea <vector185>:
.globl vector185
vector185:
  pushl $0
c01024ea:	6a 00                	push   $0x0
  pushl $185
c01024ec:	68 b9 00 00 00       	push   $0xb9
  jmp __alltraps
c01024f1:	e9 48 03 00 00       	jmp    c010283e <__alltraps>

c01024f6 <vector186>:
.globl vector186
vector186:
  pushl $0
c01024f6:	6a 00                	push   $0x0
  pushl $186
c01024f8:	68 ba 00 00 00       	push   $0xba
  jmp __alltraps
c01024fd:	e9 3c 03 00 00       	jmp    c010283e <__alltraps>

c0102502 <vector187>:
.globl vector187
vector187:
  pushl $0
c0102502:	6a 00                	push   $0x0
  pushl $187
c0102504:	68 bb 00 00 00       	push   $0xbb
  jmp __alltraps
c0102509:	e9 30 03 00 00       	jmp    c010283e <__alltraps>

c010250e <vector188>:
.globl vector188
vector188:
  pushl $0
c010250e:	6a 00                	push   $0x0
  pushl $188
c0102510:	68 bc 00 00 00       	push   $0xbc
  jmp __alltraps
c0102515:	e9 24 03 00 00       	jmp    c010283e <__alltraps>

c010251a <vector189>:
.globl vector189
vector189:
  pushl $0
c010251a:	6a 00                	push   $0x0
  pushl $189
c010251c:	68 bd 00 00 00       	push   $0xbd
  jmp __alltraps
c0102521:	e9 18 03 00 00       	jmp    c010283e <__alltraps>

c0102526 <vector190>:
.globl vector190
vector190:
  pushl $0
c0102526:	6a 00                	push   $0x0
  pushl $190
c0102528:	68 be 00 00 00       	push   $0xbe
  jmp __alltraps
c010252d:	e9 0c 03 00 00       	jmp    c010283e <__alltraps>

c0102532 <vector191>:
.globl vector191
vector191:
  pushl $0
c0102532:	6a 00                	push   $0x0
  pushl $191
c0102534:	68 bf 00 00 00       	push   $0xbf
  jmp __alltraps
c0102539:	e9 00 03 00 00       	jmp    c010283e <__alltraps>

c010253e <vector192>:
.globl vector192
vector192:
  pushl $0
c010253e:	6a 00                	push   $0x0
  pushl $192
c0102540:	68 c0 00 00 00       	push   $0xc0
  jmp __alltraps
c0102545:	e9 f4 02 00 00       	jmp    c010283e <__alltraps>

c010254a <vector193>:
.globl vector193
vector193:
  pushl $0
c010254a:	6a 00                	push   $0x0
  pushl $193
c010254c:	68 c1 00 00 00       	push   $0xc1
  jmp __alltraps
c0102551:	e9 e8 02 00 00       	jmp    c010283e <__alltraps>

c0102556 <vector194>:
.globl vector194
vector194:
  pushl $0
c0102556:	6a 00                	push   $0x0
  pushl $194
c0102558:	68 c2 00 00 00       	push   $0xc2
  jmp __alltraps
c010255d:	e9 dc 02 00 00       	jmp    c010283e <__alltraps>

c0102562 <vector195>:
.globl vector195
vector195:
  pushl $0
c0102562:	6a 00                	push   $0x0
  pushl $195
c0102564:	68 c3 00 00 00       	push   $0xc3
  jmp __alltraps
c0102569:	e9 d0 02 00 00       	jmp    c010283e <__alltraps>

c010256e <vector196>:
.globl vector196
vector196:
  pushl $0
c010256e:	6a 00                	push   $0x0
  pushl $196
c0102570:	68 c4 00 00 00       	push   $0xc4
  jmp __alltraps
c0102575:	e9 c4 02 00 00       	jmp    c010283e <__alltraps>

c010257a <vector197>:
.globl vector197
vector197:
  pushl $0
c010257a:	6a 00                	push   $0x0
  pushl $197
c010257c:	68 c5 00 00 00       	push   $0xc5
  jmp __alltraps
c0102581:	e9 b8 02 00 00       	jmp    c010283e <__alltraps>

c0102586 <vector198>:
.globl vector198
vector198:
  pushl $0
c0102586:	6a 00                	push   $0x0
  pushl $198
c0102588:	68 c6 00 00 00       	push   $0xc6
  jmp __alltraps
c010258d:	e9 ac 02 00 00       	jmp    c010283e <__alltraps>

c0102592 <vector199>:
.globl vector199
vector199:
  pushl $0
c0102592:	6a 00                	push   $0x0
  pushl $199
c0102594:	68 c7 00 00 00       	push   $0xc7
  jmp __alltraps
c0102599:	e9 a0 02 00 00       	jmp    c010283e <__alltraps>

c010259e <vector200>:
.globl vector200
vector200:
  pushl $0
c010259e:	6a 00                	push   $0x0
  pushl $200
c01025a0:	68 c8 00 00 00       	push   $0xc8
  jmp __alltraps
c01025a5:	e9 94 02 00 00       	jmp    c010283e <__alltraps>

c01025aa <vector201>:
.globl vector201
vector201:
  pushl $0
c01025aa:	6a 00                	push   $0x0
  pushl $201
c01025ac:	68 c9 00 00 00       	push   $0xc9
  jmp __alltraps
c01025b1:	e9 88 02 00 00       	jmp    c010283e <__alltraps>

c01025b6 <vector202>:
.globl vector202
vector202:
  pushl $0
c01025b6:	6a 00                	push   $0x0
  pushl $202
c01025b8:	68 ca 00 00 00       	push   $0xca
  jmp __alltraps
c01025bd:	e9 7c 02 00 00       	jmp    c010283e <__alltraps>

c01025c2 <vector203>:
.globl vector203
vector203:
  pushl $0
c01025c2:	6a 00                	push   $0x0
  pushl $203
c01025c4:	68 cb 00 00 00       	push   $0xcb
  jmp __alltraps
c01025c9:	e9 70 02 00 00       	jmp    c010283e <__alltraps>

c01025ce <vector204>:
.globl vector204
vector204:
  pushl $0
c01025ce:	6a 00                	push   $0x0
  pushl $204
c01025d0:	68 cc 00 00 00       	push   $0xcc
  jmp __alltraps
c01025d5:	e9 64 02 00 00       	jmp    c010283e <__alltraps>

c01025da <vector205>:
.globl vector205
vector205:
  pushl $0
c01025da:	6a 00                	push   $0x0
  pushl $205
c01025dc:	68 cd 00 00 00       	push   $0xcd
  jmp __alltraps
c01025e1:	e9 58 02 00 00       	jmp    c010283e <__alltraps>

c01025e6 <vector206>:
.globl vector206
vector206:
  pushl $0
c01025e6:	6a 00                	push   $0x0
  pushl $206
c01025e8:	68 ce 00 00 00       	push   $0xce
  jmp __alltraps
c01025ed:	e9 4c 02 00 00       	jmp    c010283e <__alltraps>

c01025f2 <vector207>:
.globl vector207
vector207:
  pushl $0
c01025f2:	6a 00                	push   $0x0
  pushl $207
c01025f4:	68 cf 00 00 00       	push   $0xcf
  jmp __alltraps
c01025f9:	e9 40 02 00 00       	jmp    c010283e <__alltraps>

c01025fe <vector208>:
.globl vector208
vector208:
  pushl $0
c01025fe:	6a 00                	push   $0x0
  pushl $208
c0102600:	68 d0 00 00 00       	push   $0xd0
  jmp __alltraps
c0102605:	e9 34 02 00 00       	jmp    c010283e <__alltraps>

c010260a <vector209>:
.globl vector209
vector209:
  pushl $0
c010260a:	6a 00                	push   $0x0
  pushl $209
c010260c:	68 d1 00 00 00       	push   $0xd1
  jmp __alltraps
c0102611:	e9 28 02 00 00       	jmp    c010283e <__alltraps>

c0102616 <vector210>:
.globl vector210
vector210:
  pushl $0
c0102616:	6a 00                	push   $0x0
  pushl $210
c0102618:	68 d2 00 00 00       	push   $0xd2
  jmp __alltraps
c010261d:	e9 1c 02 00 00       	jmp    c010283e <__alltraps>

c0102622 <vector211>:
.globl vector211
vector211:
  pushl $0
c0102622:	6a 00                	push   $0x0
  pushl $211
c0102624:	68 d3 00 00 00       	push   $0xd3
  jmp __alltraps
c0102629:	e9 10 02 00 00       	jmp    c010283e <__alltraps>

c010262e <vector212>:
.globl vector212
vector212:
  pushl $0
c010262e:	6a 00                	push   $0x0
  pushl $212
c0102630:	68 d4 00 00 00       	push   $0xd4
  jmp __alltraps
c0102635:	e9 04 02 00 00       	jmp    c010283e <__alltraps>

c010263a <vector213>:
.globl vector213
vector213:
  pushl $0
c010263a:	6a 00                	push   $0x0
  pushl $213
c010263c:	68 d5 00 00 00       	push   $0xd5
  jmp __alltraps
c0102641:	e9 f8 01 00 00       	jmp    c010283e <__alltraps>

c0102646 <vector214>:
.globl vector214
vector214:
  pushl $0
c0102646:	6a 00                	push   $0x0
  pushl $214
c0102648:	68 d6 00 00 00       	push   $0xd6
  jmp __alltraps
c010264d:	e9 ec 01 00 00       	jmp    c010283e <__alltraps>

c0102652 <vector215>:
.globl vector215
vector215:
  pushl $0
c0102652:	6a 00                	push   $0x0
  pushl $215
c0102654:	68 d7 00 00 00       	push   $0xd7
  jmp __alltraps
c0102659:	e9 e0 01 00 00       	jmp    c010283e <__alltraps>

c010265e <vector216>:
.globl vector216
vector216:
  pushl $0
c010265e:	6a 00                	push   $0x0
  pushl $216
c0102660:	68 d8 00 00 00       	push   $0xd8
  jmp __alltraps
c0102665:	e9 d4 01 00 00       	jmp    c010283e <__alltraps>

c010266a <vector217>:
.globl vector217
vector217:
  pushl $0
c010266a:	6a 00                	push   $0x0
  pushl $217
c010266c:	68 d9 00 00 00       	push   $0xd9
  jmp __alltraps
c0102671:	e9 c8 01 00 00       	jmp    c010283e <__alltraps>

c0102676 <vector218>:
.globl vector218
vector218:
  pushl $0
c0102676:	6a 00                	push   $0x0
  pushl $218
c0102678:	68 da 00 00 00       	push   $0xda
  jmp __alltraps
c010267d:	e9 bc 01 00 00       	jmp    c010283e <__alltraps>

c0102682 <vector219>:
.globl vector219
vector219:
  pushl $0
c0102682:	6a 00                	push   $0x0
  pushl $219
c0102684:	68 db 00 00 00       	push   $0xdb
  jmp __alltraps
c0102689:	e9 b0 01 00 00       	jmp    c010283e <__alltraps>

c010268e <vector220>:
.globl vector220
vector220:
  pushl $0
c010268e:	6a 00                	push   $0x0
  pushl $220
c0102690:	68 dc 00 00 00       	push   $0xdc
  jmp __alltraps
c0102695:	e9 a4 01 00 00       	jmp    c010283e <__alltraps>

c010269a <vector221>:
.globl vector221
vector221:
  pushl $0
c010269a:	6a 00                	push   $0x0
  pushl $221
c010269c:	68 dd 00 00 00       	push   $0xdd
  jmp __alltraps
c01026a1:	e9 98 01 00 00       	jmp    c010283e <__alltraps>

c01026a6 <vector222>:
.globl vector222
vector222:
  pushl $0
c01026a6:	6a 00                	push   $0x0
  pushl $222
c01026a8:	68 de 00 00 00       	push   $0xde
  jmp __alltraps
c01026ad:	e9 8c 01 00 00       	jmp    c010283e <__alltraps>

c01026b2 <vector223>:
.globl vector223
vector223:
  pushl $0
c01026b2:	6a 00                	push   $0x0
  pushl $223
c01026b4:	68 df 00 00 00       	push   $0xdf
  jmp __alltraps
c01026b9:	e9 80 01 00 00       	jmp    c010283e <__alltraps>

c01026be <vector224>:
.globl vector224
vector224:
  pushl $0
c01026be:	6a 00                	push   $0x0
  pushl $224
c01026c0:	68 e0 00 00 00       	push   $0xe0
  jmp __alltraps
c01026c5:	e9 74 01 00 00       	jmp    c010283e <__alltraps>

c01026ca <vector225>:
.globl vector225
vector225:
  pushl $0
c01026ca:	6a 00                	push   $0x0
  pushl $225
c01026cc:	68 e1 00 00 00       	push   $0xe1
  jmp __alltraps
c01026d1:	e9 68 01 00 00       	jmp    c010283e <__alltraps>

c01026d6 <vector226>:
.globl vector226
vector226:
  pushl $0
c01026d6:	6a 00                	push   $0x0
  pushl $226
c01026d8:	68 e2 00 00 00       	push   $0xe2
  jmp __alltraps
c01026dd:	e9 5c 01 00 00       	jmp    c010283e <__alltraps>

c01026e2 <vector227>:
.globl vector227
vector227:
  pushl $0
c01026e2:	6a 00                	push   $0x0
  pushl $227
c01026e4:	68 e3 00 00 00       	push   $0xe3
  jmp __alltraps
c01026e9:	e9 50 01 00 00       	jmp    c010283e <__alltraps>

c01026ee <vector228>:
.globl vector228
vector228:
  pushl $0
c01026ee:	6a 00                	push   $0x0
  pushl $228
c01026f0:	68 e4 00 00 00       	push   $0xe4
  jmp __alltraps
c01026f5:	e9 44 01 00 00       	jmp    c010283e <__alltraps>

c01026fa <vector229>:
.globl vector229
vector229:
  pushl $0
c01026fa:	6a 00                	push   $0x0
  pushl $229
c01026fc:	68 e5 00 00 00       	push   $0xe5
  jmp __alltraps
c0102701:	e9 38 01 00 00       	jmp    c010283e <__alltraps>

c0102706 <vector230>:
.globl vector230
vector230:
  pushl $0
c0102706:	6a 00                	push   $0x0
  pushl $230
c0102708:	68 e6 00 00 00       	push   $0xe6
  jmp __alltraps
c010270d:	e9 2c 01 00 00       	jmp    c010283e <__alltraps>

c0102712 <vector231>:
.globl vector231
vector231:
  pushl $0
c0102712:	6a 00                	push   $0x0
  pushl $231
c0102714:	68 e7 00 00 00       	push   $0xe7
  jmp __alltraps
c0102719:	e9 20 01 00 00       	jmp    c010283e <__alltraps>

c010271e <vector232>:
.globl vector232
vector232:
  pushl $0
c010271e:	6a 00                	push   $0x0
  pushl $232
c0102720:	68 e8 00 00 00       	push   $0xe8
  jmp __alltraps
c0102725:	e9 14 01 00 00       	jmp    c010283e <__alltraps>

c010272a <vector233>:
.globl vector233
vector233:
  pushl $0
c010272a:	6a 00                	push   $0x0
  pushl $233
c010272c:	68 e9 00 00 00       	push   $0xe9
  jmp __alltraps
c0102731:	e9 08 01 00 00       	jmp    c010283e <__alltraps>

c0102736 <vector234>:
.globl vector234
vector234:
  pushl $0
c0102736:	6a 00                	push   $0x0
  pushl $234
c0102738:	68 ea 00 00 00       	push   $0xea
  jmp __alltraps
c010273d:	e9 fc 00 00 00       	jmp    c010283e <__alltraps>

c0102742 <vector235>:
.globl vector235
vector235:
  pushl $0
c0102742:	6a 00                	push   $0x0
  pushl $235
c0102744:	68 eb 00 00 00       	push   $0xeb
  jmp __alltraps
c0102749:	e9 f0 00 00 00       	jmp    c010283e <__alltraps>

c010274e <vector236>:
.globl vector236
vector236:
  pushl $0
c010274e:	6a 00                	push   $0x0
  pushl $236
c0102750:	68 ec 00 00 00       	push   $0xec
  jmp __alltraps
c0102755:	e9 e4 00 00 00       	jmp    c010283e <__alltraps>

c010275a <vector237>:
.globl vector237
vector237:
  pushl $0
c010275a:	6a 00                	push   $0x0
  pushl $237
c010275c:	68 ed 00 00 00       	push   $0xed
  jmp __alltraps
c0102761:	e9 d8 00 00 00       	jmp    c010283e <__alltraps>

c0102766 <vector238>:
.globl vector238
vector238:
  pushl $0
c0102766:	6a 00                	push   $0x0
  pushl $238
c0102768:	68 ee 00 00 00       	push   $0xee
  jmp __alltraps
c010276d:	e9 cc 00 00 00       	jmp    c010283e <__alltraps>

c0102772 <vector239>:
.globl vector239
vector239:
  pushl $0
c0102772:	6a 00                	push   $0x0
  pushl $239
c0102774:	68 ef 00 00 00       	push   $0xef
  jmp __alltraps
c0102779:	e9 c0 00 00 00       	jmp    c010283e <__alltraps>

c010277e <vector240>:
.globl vector240
vector240:
  pushl $0
c010277e:	6a 00                	push   $0x0
  pushl $240
c0102780:	68 f0 00 00 00       	push   $0xf0
  jmp __alltraps
c0102785:	e9 b4 00 00 00       	jmp    c010283e <__alltraps>

c010278a <vector241>:
.globl vector241
vector241:
  pushl $0
c010278a:	6a 00                	push   $0x0
  pushl $241
c010278c:	68 f1 00 00 00       	push   $0xf1
  jmp __alltraps
c0102791:	e9 a8 00 00 00       	jmp    c010283e <__alltraps>

c0102796 <vector242>:
.globl vector242
vector242:
  pushl $0
c0102796:	6a 00                	push   $0x0
  pushl $242
c0102798:	68 f2 00 00 00       	push   $0xf2
  jmp __alltraps
c010279d:	e9 9c 00 00 00       	jmp    c010283e <__alltraps>

c01027a2 <vector243>:
.globl vector243
vector243:
  pushl $0
c01027a2:	6a 00                	push   $0x0
  pushl $243
c01027a4:	68 f3 00 00 00       	push   $0xf3
  jmp __alltraps
c01027a9:	e9 90 00 00 00       	jmp    c010283e <__alltraps>

c01027ae <vector244>:
.globl vector244
vector244:
  pushl $0
c01027ae:	6a 00                	push   $0x0
  pushl $244
c01027b0:	68 f4 00 00 00       	push   $0xf4
  jmp __alltraps
c01027b5:	e9 84 00 00 00       	jmp    c010283e <__alltraps>

c01027ba <vector245>:
.globl vector245
vector245:
  pushl $0
c01027ba:	6a 00                	push   $0x0
  pushl $245
c01027bc:	68 f5 00 00 00       	push   $0xf5
  jmp __alltraps
c01027c1:	e9 78 00 00 00       	jmp    c010283e <__alltraps>

c01027c6 <vector246>:
.globl vector246
vector246:
  pushl $0
c01027c6:	6a 00                	push   $0x0
  pushl $246
c01027c8:	68 f6 00 00 00       	push   $0xf6
  jmp __alltraps
c01027cd:	e9 6c 00 00 00       	jmp    c010283e <__alltraps>

c01027d2 <vector247>:
.globl vector247
vector247:
  pushl $0
c01027d2:	6a 00                	push   $0x0
  pushl $247
c01027d4:	68 f7 00 00 00       	push   $0xf7
  jmp __alltraps
c01027d9:	e9 60 00 00 00       	jmp    c010283e <__alltraps>

c01027de <vector248>:
.globl vector248
vector248:
  pushl $0
c01027de:	6a 00                	push   $0x0
  pushl $248
c01027e0:	68 f8 00 00 00       	push   $0xf8
  jmp __alltraps
c01027e5:	e9 54 00 00 00       	jmp    c010283e <__alltraps>

c01027ea <vector249>:
.globl vector249
vector249:
  pushl $0
c01027ea:	6a 00                	push   $0x0
  pushl $249
c01027ec:	68 f9 00 00 00       	push   $0xf9
  jmp __alltraps
c01027f1:	e9 48 00 00 00       	jmp    c010283e <__alltraps>

c01027f6 <vector250>:
.globl vector250
vector250:
  pushl $0
c01027f6:	6a 00                	push   $0x0
  pushl $250
c01027f8:	68 fa 00 00 00       	push   $0xfa
  jmp __alltraps
c01027fd:	e9 3c 00 00 00       	jmp    c010283e <__alltraps>

c0102802 <vector251>:
.globl vector251
vector251:
  pushl $0
c0102802:	6a 00                	push   $0x0
  pushl $251
c0102804:	68 fb 00 00 00       	push   $0xfb
  jmp __alltraps
c0102809:	e9 30 00 00 00       	jmp    c010283e <__alltraps>

c010280e <vector252>:
.globl vector252
vector252:
  pushl $0
c010280e:	6a 00                	push   $0x0
  pushl $252
c0102810:	68 fc 00 00 00       	push   $0xfc
  jmp __alltraps
c0102815:	e9 24 00 00 00       	jmp    c010283e <__alltraps>

c010281a <vector253>:
.globl vector253
vector253:
  pushl $0
c010281a:	6a 00                	push   $0x0
  pushl $253
c010281c:	68 fd 00 00 00       	push   $0xfd
  jmp __alltraps
c0102821:	e9 18 00 00 00       	jmp    c010283e <__alltraps>

c0102826 <vector254>:
.globl vector254
vector254:
  pushl $0
c0102826:	6a 00                	push   $0x0
  pushl $254
c0102828:	68 fe 00 00 00       	push   $0xfe
  jmp __alltraps
c010282d:	e9 0c 00 00 00       	jmp    c010283e <__alltraps>

c0102832 <vector255>:
.globl vector255
vector255:
  pushl $0
c0102832:	6a 00                	push   $0x0
  pushl $255
c0102834:	68 ff 00 00 00       	push   $0xff
  jmp __alltraps
c0102839:	e9 00 00 00 00       	jmp    c010283e <__alltraps>

c010283e <__alltraps>:
.text
.globl __alltraps
__alltraps:
    # push registers to build a trap frame
    # therefore make the stack look like a struct trapframe
    pushl %ds
c010283e:	1e                   	push   %ds
    pushl %es
c010283f:	06                   	push   %es
    pushl %fs
c0102840:	0f a0                	push   %fs
    pushl %gs
c0102842:	0f a8                	push   %gs
    pushal
c0102844:	60                   	pusha  

    # load GD_KDATA into %ds and %es to set up data segments for kernel
    movl $GD_KDATA, %eax
c0102845:	b8 10 00 00 00       	mov    $0x10,%eax
    movw %ax, %ds
c010284a:	8e d8                	mov    %eax,%ds
    movw %ax, %es
c010284c:	8e c0                	mov    %eax,%es

    # push %esp to pass a pointer to the trapframe as an argument to trap()
    pushl %esp
c010284e:	54                   	push   %esp

    # call trap(tf), where tf=%esp
    call trap
c010284f:	e8 63 f5 ff ff       	call   c0101db7 <trap>

    # pop the pushed stack pointer
    popl %esp
c0102854:	5c                   	pop    %esp

c0102855 <__trapret>:

    # return falls through to trapret...
.globl __trapret
__trapret:
    # restore registers from stack
    popal
c0102855:	61                   	popa   

    # restore %ds, %es, %fs and %gs
    popl %gs
c0102856:	0f a9                	pop    %gs
    popl %fs
c0102858:	0f a1                	pop    %fs
    popl %es
c010285a:	07                   	pop    %es
    popl %ds
c010285b:	1f                   	pop    %ds

    # get rid of the trap number and error code
    addl $0x8, %esp
c010285c:	83 c4 08             	add    $0x8,%esp
    iret
c010285f:	cf                   	iret   

c0102860 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
c0102860:	55                   	push   %ebp
c0102861:	89 e5                	mov    %esp,%ebp
    return page - pages;
c0102863:	8b 45 08             	mov    0x8(%ebp),%eax
c0102866:	8b 15 18 af 11 c0    	mov    0xc011af18,%edx
c010286c:	29 d0                	sub    %edx,%eax
c010286e:	c1 f8 02             	sar    $0x2,%eax
c0102871:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
c0102877:	5d                   	pop    %ebp
c0102878:	c3                   	ret    

c0102879 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
c0102879:	55                   	push   %ebp
c010287a:	89 e5                	mov    %esp,%ebp
    return page2ppn(page) << PGSHIFT;
c010287c:	ff 75 08             	pushl  0x8(%ebp)
c010287f:	e8 dc ff ff ff       	call   c0102860 <page2ppn>
c0102884:	83 c4 04             	add    $0x4,%esp
c0102887:	c1 e0 0c             	shl    $0xc,%eax
}
c010288a:	c9                   	leave  
c010288b:	c3                   	ret    

c010288c <pa2page>:

static inline struct Page *
pa2page(uintptr_t pa) {
c010288c:	55                   	push   %ebp
c010288d:	89 e5                	mov    %esp,%ebp
c010288f:	83 ec 08             	sub    $0x8,%esp
    if (PPN(pa) >= npage) {
c0102892:	8b 45 08             	mov    0x8(%ebp),%eax
c0102895:	c1 e8 0c             	shr    $0xc,%eax
c0102898:	89 c2                	mov    %eax,%edx
c010289a:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c010289f:	39 c2                	cmp    %eax,%edx
c01028a1:	72 14                	jb     c01028b7 <pa2page+0x2b>
        panic("pa2page called with invalid pa");
c01028a3:	83 ec 04             	sub    $0x4,%esp
c01028a6:	68 d0 61 10 c0       	push   $0xc01061d0
c01028ab:	6a 5a                	push   $0x5a
c01028ad:	68 ef 61 10 c0       	push   $0xc01061ef
c01028b2:	e8 22 db ff ff       	call   c01003d9 <__panic>
    }
    return &pages[PPN(pa)];
c01028b7:	8b 0d 18 af 11 c0    	mov    0xc011af18,%ecx
c01028bd:	8b 45 08             	mov    0x8(%ebp),%eax
c01028c0:	c1 e8 0c             	shr    $0xc,%eax
c01028c3:	89 c2                	mov    %eax,%edx
c01028c5:	89 d0                	mov    %edx,%eax
c01028c7:	c1 e0 02             	shl    $0x2,%eax
c01028ca:	01 d0                	add    %edx,%eax
c01028cc:	c1 e0 02             	shl    $0x2,%eax
c01028cf:	01 c8                	add    %ecx,%eax
}
c01028d1:	c9                   	leave  
c01028d2:	c3                   	ret    

c01028d3 <page2kva>:

static inline void *
page2kva(struct Page *page) {
c01028d3:	55                   	push   %ebp
c01028d4:	89 e5                	mov    %esp,%ebp
c01028d6:	83 ec 18             	sub    $0x18,%esp
    return KADDR(page2pa(page));
c01028d9:	ff 75 08             	pushl  0x8(%ebp)
c01028dc:	e8 98 ff ff ff       	call   c0102879 <page2pa>
c01028e1:	83 c4 04             	add    $0x4,%esp
c01028e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01028e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01028ea:	c1 e8 0c             	shr    $0xc,%eax
c01028ed:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01028f0:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01028f5:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c01028f8:	72 14                	jb     c010290e <page2kva+0x3b>
c01028fa:	ff 75 f4             	pushl  -0xc(%ebp)
c01028fd:	68 00 62 10 c0       	push   $0xc0106200
c0102902:	6a 61                	push   $0x61
c0102904:	68 ef 61 10 c0       	push   $0xc01061ef
c0102909:	e8 cb da ff ff       	call   c01003d9 <__panic>
c010290e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102911:	2d 00 00 00 40       	sub    $0x40000000,%eax
}
c0102916:	c9                   	leave  
c0102917:	c3                   	ret    

c0102918 <pte2page>:
kva2page(void *kva) {
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte) {
c0102918:	55                   	push   %ebp
c0102919:	89 e5                	mov    %esp,%ebp
c010291b:	83 ec 08             	sub    $0x8,%esp
    if (!(pte & PTE_P)) {
c010291e:	8b 45 08             	mov    0x8(%ebp),%eax
c0102921:	83 e0 01             	and    $0x1,%eax
c0102924:	85 c0                	test   %eax,%eax
c0102926:	75 14                	jne    c010293c <pte2page+0x24>
        panic("pte2page called with invalid pte");
c0102928:	83 ec 04             	sub    $0x4,%esp
c010292b:	68 24 62 10 c0       	push   $0xc0106224
c0102930:	6a 6c                	push   $0x6c
c0102932:	68 ef 61 10 c0       	push   $0xc01061ef
c0102937:	e8 9d da ff ff       	call   c01003d9 <__panic>
    }
    return pa2page(PTE_ADDR(pte));
c010293c:	8b 45 08             	mov    0x8(%ebp),%eax
c010293f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0102944:	83 ec 0c             	sub    $0xc,%esp
c0102947:	50                   	push   %eax
c0102948:	e8 3f ff ff ff       	call   c010288c <pa2page>
c010294d:	83 c4 10             	add    $0x10,%esp
}
c0102950:	c9                   	leave  
c0102951:	c3                   	ret    

c0102952 <pde2page>:

static inline struct Page *
pde2page(pde_t pde) {
c0102952:	55                   	push   %ebp
c0102953:	89 e5                	mov    %esp,%ebp
c0102955:	83 ec 08             	sub    $0x8,%esp
    return pa2page(PDE_ADDR(pde));
c0102958:	8b 45 08             	mov    0x8(%ebp),%eax
c010295b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0102960:	83 ec 0c             	sub    $0xc,%esp
c0102963:	50                   	push   %eax
c0102964:	e8 23 ff ff ff       	call   c010288c <pa2page>
c0102969:	83 c4 10             	add    $0x10,%esp
}
c010296c:	c9                   	leave  
c010296d:	c3                   	ret    

c010296e <page_ref>:

static inline int
page_ref(struct Page *page) {
c010296e:	55                   	push   %ebp
c010296f:	89 e5                	mov    %esp,%ebp
    return page->ref;
c0102971:	8b 45 08             	mov    0x8(%ebp),%eax
c0102974:	8b 00                	mov    (%eax),%eax
}
c0102976:	5d                   	pop    %ebp
c0102977:	c3                   	ret    

c0102978 <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
c0102978:	55                   	push   %ebp
c0102979:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c010297b:	8b 45 08             	mov    0x8(%ebp),%eax
c010297e:	8b 55 0c             	mov    0xc(%ebp),%edx
c0102981:	89 10                	mov    %edx,(%eax)
}
c0102983:	90                   	nop
c0102984:	5d                   	pop    %ebp
c0102985:	c3                   	ret    

c0102986 <page_ref_inc>:

static inline int
page_ref_inc(struct Page *page) {
c0102986:	55                   	push   %ebp
c0102987:	89 e5                	mov    %esp,%ebp
    page->ref += 1;
c0102989:	8b 45 08             	mov    0x8(%ebp),%eax
c010298c:	8b 00                	mov    (%eax),%eax
c010298e:	8d 50 01             	lea    0x1(%eax),%edx
c0102991:	8b 45 08             	mov    0x8(%ebp),%eax
c0102994:	89 10                	mov    %edx,(%eax)
    return page->ref;
c0102996:	8b 45 08             	mov    0x8(%ebp),%eax
c0102999:	8b 00                	mov    (%eax),%eax
}
c010299b:	5d                   	pop    %ebp
c010299c:	c3                   	ret    

c010299d <page_ref_dec>:

static inline int
page_ref_dec(struct Page *page) {
c010299d:	55                   	push   %ebp
c010299e:	89 e5                	mov    %esp,%ebp
    page->ref -= 1;
c01029a0:	8b 45 08             	mov    0x8(%ebp),%eax
c01029a3:	8b 00                	mov    (%eax),%eax
c01029a5:	8d 50 ff             	lea    -0x1(%eax),%edx
c01029a8:	8b 45 08             	mov    0x8(%ebp),%eax
c01029ab:	89 10                	mov    %edx,(%eax)
    return page->ref;
c01029ad:	8b 45 08             	mov    0x8(%ebp),%eax
c01029b0:	8b 00                	mov    (%eax),%eax
}
c01029b2:	5d                   	pop    %ebp
c01029b3:	c3                   	ret    

c01029b4 <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
c01029b4:	55                   	push   %ebp
c01029b5:	89 e5                	mov    %esp,%ebp
c01029b7:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c01029ba:	9c                   	pushf  
c01029bb:	58                   	pop    %eax
c01029bc:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c01029bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
c01029c2:	25 00 02 00 00       	and    $0x200,%eax
c01029c7:	85 c0                	test   %eax,%eax
c01029c9:	74 0c                	je     c01029d7 <__intr_save+0x23>
        intr_disable();
c01029cb:	e8 b8 ee ff ff       	call   c0101888 <intr_disable>
        return 1;
c01029d0:	b8 01 00 00 00       	mov    $0x1,%eax
c01029d5:	eb 05                	jmp    c01029dc <__intr_save+0x28>
    }
    return 0;
c01029d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01029dc:	c9                   	leave  
c01029dd:	c3                   	ret    

c01029de <__intr_restore>:

static inline void
__intr_restore(bool flag) {
c01029de:	55                   	push   %ebp
c01029df:	89 e5                	mov    %esp,%ebp
c01029e1:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c01029e4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c01029e8:	74 05                	je     c01029ef <__intr_restore+0x11>
        intr_enable();
c01029ea:	e8 92 ee ff ff       	call   c0101881 <intr_enable>
    }
}
c01029ef:	90                   	nop
c01029f0:	c9                   	leave  
c01029f1:	c3                   	ret    

c01029f2 <lgdt>:
/* *
 * lgdt - load the global descriptor table register and reset the
 * data/code segement registers for kernel.
 * */
static inline void
lgdt(struct pseudodesc *pd) {
c01029f2:	55                   	push   %ebp
c01029f3:	89 e5                	mov    %esp,%ebp
    asm volatile ("lgdt (%0)" :: "r" (pd));
c01029f5:	8b 45 08             	mov    0x8(%ebp),%eax
c01029f8:	0f 01 10             	lgdtl  (%eax)
    asm volatile ("movw %%ax, %%gs" :: "a" (USER_DS));
c01029fb:	b8 23 00 00 00       	mov    $0x23,%eax
c0102a00:	8e e8                	mov    %eax,%gs
    asm volatile ("movw %%ax, %%fs" :: "a" (USER_DS));
c0102a02:	b8 23 00 00 00       	mov    $0x23,%eax
c0102a07:	8e e0                	mov    %eax,%fs
    asm volatile ("movw %%ax, %%es" :: "a" (KERNEL_DS));
c0102a09:	b8 10 00 00 00       	mov    $0x10,%eax
c0102a0e:	8e c0                	mov    %eax,%es
    asm volatile ("movw %%ax, %%ds" :: "a" (KERNEL_DS));
c0102a10:	b8 10 00 00 00       	mov    $0x10,%eax
c0102a15:	8e d8                	mov    %eax,%ds
    asm volatile ("movw %%ax, %%ss" :: "a" (KERNEL_DS));
c0102a17:	b8 10 00 00 00       	mov    $0x10,%eax
c0102a1c:	8e d0                	mov    %eax,%ss
    // reload cs
    asm volatile ("ljmp %0, $1f\n 1:\n" :: "i" (KERNEL_CS));
c0102a1e:	ea 25 2a 10 c0 08 00 	ljmp   $0x8,$0xc0102a25
}
c0102a25:	90                   	nop
c0102a26:	5d                   	pop    %ebp
c0102a27:	c3                   	ret    

c0102a28 <load_esp0>:
 * load_esp0 - change the ESP0 in default task state segment,
 * so that we can use different kernel stack when we trap frame
 * user to kernel.
 * */
void
load_esp0(uintptr_t esp0) {
c0102a28:	55                   	push   %ebp
c0102a29:	89 e5                	mov    %esp,%ebp
    ts.ts_esp0 = esp0;
c0102a2b:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a2e:	a3 a4 ae 11 c0       	mov    %eax,0xc011aea4
}
c0102a33:	90                   	nop
c0102a34:	5d                   	pop    %ebp
c0102a35:	c3                   	ret    

c0102a36 <gdt_init>:

/* gdt_init - initialize the default GDT and TSS */
static void
gdt_init(void) {
c0102a36:	55                   	push   %ebp
c0102a37:	89 e5                	mov    %esp,%ebp
c0102a39:	83 ec 10             	sub    $0x10,%esp
    // set boot kernel stack and default SS0
    load_esp0((uintptr_t)bootstacktop);
c0102a3c:	b8 00 70 11 c0       	mov    $0xc0117000,%eax
c0102a41:	50                   	push   %eax
c0102a42:	e8 e1 ff ff ff       	call   c0102a28 <load_esp0>
c0102a47:	83 c4 04             	add    $0x4,%esp
    ts.ts_ss0 = KERNEL_DS;
c0102a4a:	66 c7 05 a8 ae 11 c0 	movw   $0x10,0xc011aea8
c0102a51:	10 00 

    // initialize the TSS filed of the gdt
    gdt[SEG_TSS] = SEGTSS(STS_T32A, (uintptr_t)&ts, sizeof(ts), DPL_KERNEL);
c0102a53:	66 c7 05 28 7a 11 c0 	movw   $0x68,0xc0117a28
c0102a5a:	68 00 
c0102a5c:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c0102a61:	66 a3 2a 7a 11 c0    	mov    %ax,0xc0117a2a
c0102a67:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c0102a6c:	c1 e8 10             	shr    $0x10,%eax
c0102a6f:	a2 2c 7a 11 c0       	mov    %al,0xc0117a2c
c0102a74:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c0102a7b:	83 e0 f0             	and    $0xfffffff0,%eax
c0102a7e:	83 c8 09             	or     $0x9,%eax
c0102a81:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102a86:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c0102a8d:	83 e0 ef             	and    $0xffffffef,%eax
c0102a90:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102a95:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c0102a9c:	83 e0 9f             	and    $0xffffff9f,%eax
c0102a9f:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102aa4:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c0102aab:	83 c8 80             	or     $0xffffff80,%eax
c0102aae:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102ab3:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102aba:	83 e0 f0             	and    $0xfffffff0,%eax
c0102abd:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102ac2:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102ac9:	83 e0 ef             	and    $0xffffffef,%eax
c0102acc:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102ad1:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102ad8:	83 e0 df             	and    $0xffffffdf,%eax
c0102adb:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102ae0:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102ae7:	83 c8 40             	or     $0x40,%eax
c0102aea:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102aef:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102af6:	83 e0 7f             	and    $0x7f,%eax
c0102af9:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102afe:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c0102b03:	c1 e8 18             	shr    $0x18,%eax
c0102b06:	a2 2f 7a 11 c0       	mov    %al,0xc0117a2f

    // reload all segment registers
    lgdt(&gdt_pd);
c0102b0b:	68 30 7a 11 c0       	push   $0xc0117a30
c0102b10:	e8 dd fe ff ff       	call   c01029f2 <lgdt>
c0102b15:	83 c4 04             	add    $0x4,%esp
c0102b18:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
    asm volatile ("cli" ::: "memory");
}

static inline void
ltr(uint16_t sel) {
    asm volatile ("ltr %0" :: "r" (sel) : "memory");
c0102b1e:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
c0102b22:	0f 00 d8             	ltr    %ax

    // load the TSS
    ltr(GD_TSS);
}
c0102b25:	90                   	nop
c0102b26:	c9                   	leave  
c0102b27:	c3                   	ret    

c0102b28 <init_pmm_manager>:

//init_pmm_manager - initialize a pmm_manager instance
static void
init_pmm_manager(void) {
c0102b28:	55                   	push   %ebp
c0102b29:	89 e5                	mov    %esp,%ebp
c0102b2b:	83 ec 08             	sub    $0x8,%esp
    pmm_manager = &default_pmm_manager;
c0102b2e:	c7 05 10 af 11 c0 c8 	movl   $0xc0106bc8,0xc011af10
c0102b35:	6b 10 c0 
    cprintf("memory management: %s\n", pmm_manager->name);
c0102b38:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102b3d:	8b 00                	mov    (%eax),%eax
c0102b3f:	83 ec 08             	sub    $0x8,%esp
c0102b42:	50                   	push   %eax
c0102b43:	68 50 62 10 c0       	push   $0xc0106250
c0102b48:	e8 26 d7 ff ff       	call   c0100273 <cprintf>
c0102b4d:	83 c4 10             	add    $0x10,%esp
    pmm_manager->init();
c0102b50:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102b55:	8b 40 04             	mov    0x4(%eax),%eax
c0102b58:	ff d0                	call   *%eax
}
c0102b5a:	90                   	nop
c0102b5b:	c9                   	leave  
c0102b5c:	c3                   	ret    

c0102b5d <init_memmap>:

//init_memmap - call pmm->init_memmap to build Page struct for free memory  
static void
init_memmap(struct Page *base, size_t n) {
c0102b5d:	55                   	push   %ebp
c0102b5e:	89 e5                	mov    %esp,%ebp
c0102b60:	83 ec 08             	sub    $0x8,%esp
    pmm_manager->init_memmap(base, n);
c0102b63:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102b68:	8b 40 08             	mov    0x8(%eax),%eax
c0102b6b:	83 ec 08             	sub    $0x8,%esp
c0102b6e:	ff 75 0c             	pushl  0xc(%ebp)
c0102b71:	ff 75 08             	pushl  0x8(%ebp)
c0102b74:	ff d0                	call   *%eax
c0102b76:	83 c4 10             	add    $0x10,%esp
}
c0102b79:	90                   	nop
c0102b7a:	c9                   	leave  
c0102b7b:	c3                   	ret    

c0102b7c <alloc_pages>:

//alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory 
struct Page *
alloc_pages(size_t n) {
c0102b7c:	55                   	push   %ebp
c0102b7d:	89 e5                	mov    %esp,%ebp
c0102b7f:	83 ec 18             	sub    $0x18,%esp
    struct Page *page=NULL;
c0102b82:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
c0102b89:	e8 26 fe ff ff       	call   c01029b4 <__intr_save>
c0102b8e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        page = pmm_manager->alloc_pages(n);
c0102b91:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102b96:	8b 40 0c             	mov    0xc(%eax),%eax
c0102b99:	83 ec 0c             	sub    $0xc,%esp
c0102b9c:	ff 75 08             	pushl  0x8(%ebp)
c0102b9f:	ff d0                	call   *%eax
c0102ba1:	83 c4 10             	add    $0x10,%esp
c0102ba4:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }
    local_intr_restore(intr_flag);
c0102ba7:	83 ec 0c             	sub    $0xc,%esp
c0102baa:	ff 75 f0             	pushl  -0x10(%ebp)
c0102bad:	e8 2c fe ff ff       	call   c01029de <__intr_restore>
c0102bb2:	83 c4 10             	add    $0x10,%esp
    return page;
c0102bb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0102bb8:	c9                   	leave  
c0102bb9:	c3                   	ret    

c0102bba <free_pages>:

//free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory 
void
free_pages(struct Page *base, size_t n) {
c0102bba:	55                   	push   %ebp
c0102bbb:	89 e5                	mov    %esp,%ebp
c0102bbd:	83 ec 18             	sub    $0x18,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
c0102bc0:	e8 ef fd ff ff       	call   c01029b4 <__intr_save>
c0102bc5:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        pmm_manager->free_pages(base, n);
c0102bc8:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102bcd:	8b 40 10             	mov    0x10(%eax),%eax
c0102bd0:	83 ec 08             	sub    $0x8,%esp
c0102bd3:	ff 75 0c             	pushl  0xc(%ebp)
c0102bd6:	ff 75 08             	pushl  0x8(%ebp)
c0102bd9:	ff d0                	call   *%eax
c0102bdb:	83 c4 10             	add    $0x10,%esp
    }
    local_intr_restore(intr_flag);
c0102bde:	83 ec 0c             	sub    $0xc,%esp
c0102be1:	ff 75 f4             	pushl  -0xc(%ebp)
c0102be4:	e8 f5 fd ff ff       	call   c01029de <__intr_restore>
c0102be9:	83 c4 10             	add    $0x10,%esp
}
c0102bec:	90                   	nop
c0102bed:	c9                   	leave  
c0102bee:	c3                   	ret    

c0102bef <nr_free_pages>:

//nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE) 
//of current free memory
size_t
nr_free_pages(void) {
c0102bef:	55                   	push   %ebp
c0102bf0:	89 e5                	mov    %esp,%ebp
c0102bf2:	83 ec 18             	sub    $0x18,%esp
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
c0102bf5:	e8 ba fd ff ff       	call   c01029b4 <__intr_save>
c0102bfa:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        ret = pmm_manager->nr_free_pages();
c0102bfd:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102c02:	8b 40 14             	mov    0x14(%eax),%eax
c0102c05:	ff d0                	call   *%eax
c0102c07:	89 45 f0             	mov    %eax,-0x10(%ebp)
    }
    local_intr_restore(intr_flag);
c0102c0a:	83 ec 0c             	sub    $0xc,%esp
c0102c0d:	ff 75 f4             	pushl  -0xc(%ebp)
c0102c10:	e8 c9 fd ff ff       	call   c01029de <__intr_restore>
c0102c15:	83 c4 10             	add    $0x10,%esp
    return ret;
c0102c18:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
c0102c1b:	c9                   	leave  
c0102c1c:	c3                   	ret    

c0102c1d <page_init>:

/* pmm_init - initialize the physical memory management */
static void
page_init(void) {
c0102c1d:	55                   	push   %ebp
c0102c1e:	89 e5                	mov    %esp,%ebp
c0102c20:	57                   	push   %edi
c0102c21:	56                   	push   %esi
c0102c22:	53                   	push   %ebx
c0102c23:	83 ec 7c             	sub    $0x7c,%esp
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
c0102c26:	c7 45 c4 00 80 00 c0 	movl   $0xc0008000,-0x3c(%ebp)
    uint64_t maxpa = 0;
c0102c2d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
c0102c34:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

    cprintf("e820map:\n");
c0102c3b:	83 ec 0c             	sub    $0xc,%esp
c0102c3e:	68 67 62 10 c0       	push   $0xc0106267
c0102c43:	e8 2b d6 ff ff       	call   c0100273 <cprintf>
c0102c48:	83 c4 10             	add    $0x10,%esp
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
c0102c4b:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102c52:	e9 fc 00 00 00       	jmp    c0102d53 <page_init+0x136>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
c0102c57:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102c5a:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102c5d:	89 d0                	mov    %edx,%eax
c0102c5f:	c1 e0 02             	shl    $0x2,%eax
c0102c62:	01 d0                	add    %edx,%eax
c0102c64:	c1 e0 02             	shl    $0x2,%eax
c0102c67:	01 c8                	add    %ecx,%eax
c0102c69:	8b 50 08             	mov    0x8(%eax),%edx
c0102c6c:	8b 40 04             	mov    0x4(%eax),%eax
c0102c6f:	89 45 b8             	mov    %eax,-0x48(%ebp)
c0102c72:	89 55 bc             	mov    %edx,-0x44(%ebp)
c0102c75:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102c78:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102c7b:	89 d0                	mov    %edx,%eax
c0102c7d:	c1 e0 02             	shl    $0x2,%eax
c0102c80:	01 d0                	add    %edx,%eax
c0102c82:	c1 e0 02             	shl    $0x2,%eax
c0102c85:	01 c8                	add    %ecx,%eax
c0102c87:	8b 48 0c             	mov    0xc(%eax),%ecx
c0102c8a:	8b 58 10             	mov    0x10(%eax),%ebx
c0102c8d:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0102c90:	8b 55 bc             	mov    -0x44(%ebp),%edx
c0102c93:	01 c8                	add    %ecx,%eax
c0102c95:	11 da                	adc    %ebx,%edx
c0102c97:	89 45 b0             	mov    %eax,-0x50(%ebp)
c0102c9a:	89 55 b4             	mov    %edx,-0x4c(%ebp)
        cprintf("  memory: %08llx, [%08llx, %08llx], type = %d.\n",
c0102c9d:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102ca0:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102ca3:	89 d0                	mov    %edx,%eax
c0102ca5:	c1 e0 02             	shl    $0x2,%eax
c0102ca8:	01 d0                	add    %edx,%eax
c0102caa:	c1 e0 02             	shl    $0x2,%eax
c0102cad:	01 c8                	add    %ecx,%eax
c0102caf:	83 c0 14             	add    $0x14,%eax
c0102cb2:	8b 00                	mov    (%eax),%eax
c0102cb4:	89 45 84             	mov    %eax,-0x7c(%ebp)
c0102cb7:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0102cba:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0102cbd:	83 c0 ff             	add    $0xffffffff,%eax
c0102cc0:	83 d2 ff             	adc    $0xffffffff,%edx
c0102cc3:	89 c1                	mov    %eax,%ecx
c0102cc5:	89 d3                	mov    %edx,%ebx
c0102cc7:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c0102cca:	89 55 80             	mov    %edx,-0x80(%ebp)
c0102ccd:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102cd0:	89 d0                	mov    %edx,%eax
c0102cd2:	c1 e0 02             	shl    $0x2,%eax
c0102cd5:	01 d0                	add    %edx,%eax
c0102cd7:	c1 e0 02             	shl    $0x2,%eax
c0102cda:	03 45 80             	add    -0x80(%ebp),%eax
c0102cdd:	8b 50 10             	mov    0x10(%eax),%edx
c0102ce0:	8b 40 0c             	mov    0xc(%eax),%eax
c0102ce3:	ff 75 84             	pushl  -0x7c(%ebp)
c0102ce6:	53                   	push   %ebx
c0102ce7:	51                   	push   %ecx
c0102ce8:	ff 75 bc             	pushl  -0x44(%ebp)
c0102ceb:	ff 75 b8             	pushl  -0x48(%ebp)
c0102cee:	52                   	push   %edx
c0102cef:	50                   	push   %eax
c0102cf0:	68 74 62 10 c0       	push   $0xc0106274
c0102cf5:	e8 79 d5 ff ff       	call   c0100273 <cprintf>
c0102cfa:	83 c4 20             	add    $0x20,%esp
                memmap->map[i].size, begin, end - 1, memmap->map[i].type);
        if (memmap->map[i].type == E820_ARM) {
c0102cfd:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102d00:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102d03:	89 d0                	mov    %edx,%eax
c0102d05:	c1 e0 02             	shl    $0x2,%eax
c0102d08:	01 d0                	add    %edx,%eax
c0102d0a:	c1 e0 02             	shl    $0x2,%eax
c0102d0d:	01 c8                	add    %ecx,%eax
c0102d0f:	83 c0 14             	add    $0x14,%eax
c0102d12:	8b 00                	mov    (%eax),%eax
c0102d14:	83 f8 01             	cmp    $0x1,%eax
c0102d17:	75 36                	jne    c0102d4f <page_init+0x132>
            if (maxpa < end && begin < KMEMSIZE) {
c0102d19:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0102d1c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0102d1f:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
c0102d22:	77 2b                	ja     c0102d4f <page_init+0x132>
c0102d24:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
c0102d27:	72 05                	jb     c0102d2e <page_init+0x111>
c0102d29:	3b 45 b0             	cmp    -0x50(%ebp),%eax
c0102d2c:	73 21                	jae    c0102d4f <page_init+0x132>
c0102d2e:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
c0102d32:	77 1b                	ja     c0102d4f <page_init+0x132>
c0102d34:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
c0102d38:	72 09                	jb     c0102d43 <page_init+0x126>
c0102d3a:	81 7d b8 ff ff ff 37 	cmpl   $0x37ffffff,-0x48(%ebp)
c0102d41:	77 0c                	ja     c0102d4f <page_init+0x132>
                maxpa = end;
c0102d43:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0102d46:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0102d49:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0102d4c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
    uint64_t maxpa = 0;

    cprintf("e820map:\n");
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
c0102d4f:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
c0102d53:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0102d56:	8b 00                	mov    (%eax),%eax
c0102d58:	3b 45 dc             	cmp    -0x24(%ebp),%eax
c0102d5b:	0f 8f f6 fe ff ff    	jg     c0102c57 <page_init+0x3a>
            if (maxpa < end && begin < KMEMSIZE) {
                maxpa = end;
            }
        }
    }
    if (maxpa > KMEMSIZE) {
c0102d61:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0102d65:	72 1d                	jb     c0102d84 <page_init+0x167>
c0102d67:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0102d6b:	77 09                	ja     c0102d76 <page_init+0x159>
c0102d6d:	81 7d e0 00 00 00 38 	cmpl   $0x38000000,-0x20(%ebp)
c0102d74:	76 0e                	jbe    c0102d84 <page_init+0x167>
        maxpa = KMEMSIZE;
c0102d76:	c7 45 e0 00 00 00 38 	movl   $0x38000000,-0x20(%ebp)
c0102d7d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    }

    extern char end[];

    npage = maxpa / PGSIZE;
c0102d84:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0102d87:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0102d8a:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c0102d8e:	c1 ea 0c             	shr    $0xc,%edx
c0102d91:	a3 80 ae 11 c0       	mov    %eax,0xc011ae80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
c0102d96:	c7 45 ac 00 10 00 00 	movl   $0x1000,-0x54(%ebp)
c0102d9d:	b8 28 af 11 c0       	mov    $0xc011af28,%eax
c0102da2:	8d 50 ff             	lea    -0x1(%eax),%edx
c0102da5:	8b 45 ac             	mov    -0x54(%ebp),%eax
c0102da8:	01 d0                	add    %edx,%eax
c0102daa:	89 45 a8             	mov    %eax,-0x58(%ebp)
c0102dad:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0102db0:	ba 00 00 00 00       	mov    $0x0,%edx
c0102db5:	f7 75 ac             	divl   -0x54(%ebp)
c0102db8:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0102dbb:	29 d0                	sub    %edx,%eax
c0102dbd:	a3 18 af 11 c0       	mov    %eax,0xc011af18

    for (i = 0; i < npage; i ++) {
c0102dc2:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102dc9:	eb 2f                	jmp    c0102dfa <page_init+0x1dd>
        SetPageReserved(pages + i);
c0102dcb:	8b 0d 18 af 11 c0    	mov    0xc011af18,%ecx
c0102dd1:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102dd4:	89 d0                	mov    %edx,%eax
c0102dd6:	c1 e0 02             	shl    $0x2,%eax
c0102dd9:	01 d0                	add    %edx,%eax
c0102ddb:	c1 e0 02             	shl    $0x2,%eax
c0102dde:	01 c8                	add    %ecx,%eax
c0102de0:	83 c0 04             	add    $0x4,%eax
c0102de3:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
c0102dea:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0102ded:	8b 45 8c             	mov    -0x74(%ebp),%eax
c0102df0:	8b 55 90             	mov    -0x70(%ebp),%edx
c0102df3:	0f ab 10             	bts    %edx,(%eax)
    extern char end[];

    npage = maxpa / PGSIZE;
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    for (i = 0; i < npage; i ++) {
c0102df6:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
c0102dfa:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102dfd:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0102e02:	39 c2                	cmp    %eax,%edx
c0102e04:	72 c5                	jb     c0102dcb <page_init+0x1ae>
        SetPageReserved(pages + i);
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);
c0102e06:	8b 15 80 ae 11 c0    	mov    0xc011ae80,%edx
c0102e0c:	89 d0                	mov    %edx,%eax
c0102e0e:	c1 e0 02             	shl    $0x2,%eax
c0102e11:	01 d0                	add    %edx,%eax
c0102e13:	c1 e0 02             	shl    $0x2,%eax
c0102e16:	89 c2                	mov    %eax,%edx
c0102e18:	a1 18 af 11 c0       	mov    0xc011af18,%eax
c0102e1d:	01 d0                	add    %edx,%eax
c0102e1f:	89 45 a4             	mov    %eax,-0x5c(%ebp)
c0102e22:	81 7d a4 ff ff ff bf 	cmpl   $0xbfffffff,-0x5c(%ebp)
c0102e29:	77 17                	ja     c0102e42 <page_init+0x225>
c0102e2b:	ff 75 a4             	pushl  -0x5c(%ebp)
c0102e2e:	68 a4 62 10 c0       	push   $0xc01062a4
c0102e33:	68 dc 00 00 00       	push   $0xdc
c0102e38:	68 c8 62 10 c0       	push   $0xc01062c8
c0102e3d:	e8 97 d5 ff ff       	call   c01003d9 <__panic>
c0102e42:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0102e45:	05 00 00 00 40       	add    $0x40000000,%eax
c0102e4a:	89 45 a0             	mov    %eax,-0x60(%ebp)

    for (i = 0; i < memmap->nr_map; i ++) {
c0102e4d:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102e54:	e9 69 01 00 00       	jmp    c0102fc2 <page_init+0x3a5>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
c0102e59:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102e5c:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102e5f:	89 d0                	mov    %edx,%eax
c0102e61:	c1 e0 02             	shl    $0x2,%eax
c0102e64:	01 d0                	add    %edx,%eax
c0102e66:	c1 e0 02             	shl    $0x2,%eax
c0102e69:	01 c8                	add    %ecx,%eax
c0102e6b:	8b 50 08             	mov    0x8(%eax),%edx
c0102e6e:	8b 40 04             	mov    0x4(%eax),%eax
c0102e71:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0102e74:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0102e77:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102e7a:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102e7d:	89 d0                	mov    %edx,%eax
c0102e7f:	c1 e0 02             	shl    $0x2,%eax
c0102e82:	01 d0                	add    %edx,%eax
c0102e84:	c1 e0 02             	shl    $0x2,%eax
c0102e87:	01 c8                	add    %ecx,%eax
c0102e89:	8b 48 0c             	mov    0xc(%eax),%ecx
c0102e8c:	8b 58 10             	mov    0x10(%eax),%ebx
c0102e8f:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102e92:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0102e95:	01 c8                	add    %ecx,%eax
c0102e97:	11 da                	adc    %ebx,%edx
c0102e99:	89 45 c8             	mov    %eax,-0x38(%ebp)
c0102e9c:	89 55 cc             	mov    %edx,-0x34(%ebp)
        if (memmap->map[i].type == E820_ARM) {
c0102e9f:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102ea2:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102ea5:	89 d0                	mov    %edx,%eax
c0102ea7:	c1 e0 02             	shl    $0x2,%eax
c0102eaa:	01 d0                	add    %edx,%eax
c0102eac:	c1 e0 02             	shl    $0x2,%eax
c0102eaf:	01 c8                	add    %ecx,%eax
c0102eb1:	83 c0 14             	add    $0x14,%eax
c0102eb4:	8b 00                	mov    (%eax),%eax
c0102eb6:	83 f8 01             	cmp    $0x1,%eax
c0102eb9:	0f 85 ff 00 00 00    	jne    c0102fbe <page_init+0x3a1>
            if (begin < freemem) {
c0102ebf:	8b 45 a0             	mov    -0x60(%ebp),%eax
c0102ec2:	ba 00 00 00 00       	mov    $0x0,%edx
c0102ec7:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0102eca:	72 17                	jb     c0102ee3 <page_init+0x2c6>
c0102ecc:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0102ecf:	77 05                	ja     c0102ed6 <page_init+0x2b9>
c0102ed1:	3b 45 d0             	cmp    -0x30(%ebp),%eax
c0102ed4:	76 0d                	jbe    c0102ee3 <page_init+0x2c6>
                begin = freemem;
c0102ed6:	8b 45 a0             	mov    -0x60(%ebp),%eax
c0102ed9:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0102edc:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
            }
            if (end > KMEMSIZE) {
c0102ee3:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c0102ee7:	72 1d                	jb     c0102f06 <page_init+0x2e9>
c0102ee9:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c0102eed:	77 09                	ja     c0102ef8 <page_init+0x2db>
c0102eef:	81 7d c8 00 00 00 38 	cmpl   $0x38000000,-0x38(%ebp)
c0102ef6:	76 0e                	jbe    c0102f06 <page_init+0x2e9>
                end = KMEMSIZE;
c0102ef8:	c7 45 c8 00 00 00 38 	movl   $0x38000000,-0x38(%ebp)
c0102eff:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
            }
            if (begin < end) {
c0102f06:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102f09:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0102f0c:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0102f0f:	0f 87 a9 00 00 00    	ja     c0102fbe <page_init+0x3a1>
c0102f15:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0102f18:	72 09                	jb     c0102f23 <page_init+0x306>
c0102f1a:	3b 45 c8             	cmp    -0x38(%ebp),%eax
c0102f1d:	0f 83 9b 00 00 00    	jae    c0102fbe <page_init+0x3a1>
                begin = ROUNDUP(begin, PGSIZE);
c0102f23:	c7 45 9c 00 10 00 00 	movl   $0x1000,-0x64(%ebp)
c0102f2a:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0102f2d:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0102f30:	01 d0                	add    %edx,%eax
c0102f32:	83 e8 01             	sub    $0x1,%eax
c0102f35:	89 45 98             	mov    %eax,-0x68(%ebp)
c0102f38:	8b 45 98             	mov    -0x68(%ebp),%eax
c0102f3b:	ba 00 00 00 00       	mov    $0x0,%edx
c0102f40:	f7 75 9c             	divl   -0x64(%ebp)
c0102f43:	8b 45 98             	mov    -0x68(%ebp),%eax
c0102f46:	29 d0                	sub    %edx,%eax
c0102f48:	ba 00 00 00 00       	mov    $0x0,%edx
c0102f4d:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0102f50:	89 55 d4             	mov    %edx,-0x2c(%ebp)
                end = ROUNDDOWN(end, PGSIZE);
c0102f53:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0102f56:	89 45 94             	mov    %eax,-0x6c(%ebp)
c0102f59:	8b 45 94             	mov    -0x6c(%ebp),%eax
c0102f5c:	ba 00 00 00 00       	mov    $0x0,%edx
c0102f61:	89 c3                	mov    %eax,%ebx
c0102f63:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
c0102f69:	89 de                	mov    %ebx,%esi
c0102f6b:	89 d0                	mov    %edx,%eax
c0102f6d:	83 e0 00             	and    $0x0,%eax
c0102f70:	89 c7                	mov    %eax,%edi
c0102f72:	89 75 c8             	mov    %esi,-0x38(%ebp)
c0102f75:	89 7d cc             	mov    %edi,-0x34(%ebp)
                if (begin < end) {
c0102f78:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102f7b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0102f7e:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0102f81:	77 3b                	ja     c0102fbe <page_init+0x3a1>
c0102f83:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0102f86:	72 05                	jb     c0102f8d <page_init+0x370>
c0102f88:	3b 45 c8             	cmp    -0x38(%ebp),%eax
c0102f8b:	73 31                	jae    c0102fbe <page_init+0x3a1>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
c0102f8d:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0102f90:	8b 55 cc             	mov    -0x34(%ebp),%edx
c0102f93:	2b 45 d0             	sub    -0x30(%ebp),%eax
c0102f96:	1b 55 d4             	sbb    -0x2c(%ebp),%edx
c0102f99:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c0102f9d:	c1 ea 0c             	shr    $0xc,%edx
c0102fa0:	89 c3                	mov    %eax,%ebx
c0102fa2:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102fa5:	83 ec 0c             	sub    $0xc,%esp
c0102fa8:	50                   	push   %eax
c0102fa9:	e8 de f8 ff ff       	call   c010288c <pa2page>
c0102fae:	83 c4 10             	add    $0x10,%esp
c0102fb1:	83 ec 08             	sub    $0x8,%esp
c0102fb4:	53                   	push   %ebx
c0102fb5:	50                   	push   %eax
c0102fb6:	e8 a2 fb ff ff       	call   c0102b5d <init_memmap>
c0102fbb:	83 c4 10             	add    $0x10,%esp
        SetPageReserved(pages + i);
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);

    for (i = 0; i < memmap->nr_map; i ++) {
c0102fbe:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
c0102fc2:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0102fc5:	8b 00                	mov    (%eax),%eax
c0102fc7:	3b 45 dc             	cmp    -0x24(%ebp),%eax
c0102fca:	0f 8f 89 fe ff ff    	jg     c0102e59 <page_init+0x23c>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
                }
            }
        }
    }
}
c0102fd0:	90                   	nop
c0102fd1:	8d 65 f4             	lea    -0xc(%ebp),%esp
c0102fd4:	5b                   	pop    %ebx
c0102fd5:	5e                   	pop    %esi
c0102fd6:	5f                   	pop    %edi
c0102fd7:	5d                   	pop    %ebp
c0102fd8:	c3                   	ret    

c0102fd9 <boot_map_segment>:
//  la:   linear address of this memory need to map (after x86 segment map)
//  size: memory size
//  pa:   physical address of this memory
//  perm: permission of this memory  
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
c0102fd9:	55                   	push   %ebp
c0102fda:	89 e5                	mov    %esp,%ebp
c0102fdc:	83 ec 28             	sub    $0x28,%esp
    assert(PGOFF(la) == PGOFF(pa));
c0102fdf:	8b 45 0c             	mov    0xc(%ebp),%eax
c0102fe2:	33 45 14             	xor    0x14(%ebp),%eax
c0102fe5:	25 ff 0f 00 00       	and    $0xfff,%eax
c0102fea:	85 c0                	test   %eax,%eax
c0102fec:	74 19                	je     c0103007 <boot_map_segment+0x2e>
c0102fee:	68 d6 62 10 c0       	push   $0xc01062d6
c0102ff3:	68 ed 62 10 c0       	push   $0xc01062ed
c0102ff8:	68 fa 00 00 00       	push   $0xfa
c0102ffd:	68 c8 62 10 c0       	push   $0xc01062c8
c0103002:	e8 d2 d3 ff ff       	call   c01003d9 <__panic>
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
c0103007:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
c010300e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103011:	25 ff 0f 00 00       	and    $0xfff,%eax
c0103016:	89 c2                	mov    %eax,%edx
c0103018:	8b 45 10             	mov    0x10(%ebp),%eax
c010301b:	01 c2                	add    %eax,%edx
c010301d:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103020:	01 d0                	add    %edx,%eax
c0103022:	83 e8 01             	sub    $0x1,%eax
c0103025:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0103028:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010302b:	ba 00 00 00 00       	mov    $0x0,%edx
c0103030:	f7 75 f0             	divl   -0x10(%ebp)
c0103033:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103036:	29 d0                	sub    %edx,%eax
c0103038:	c1 e8 0c             	shr    $0xc,%eax
c010303b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    la = ROUNDDOWN(la, PGSIZE);
c010303e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103041:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0103044:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103047:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c010304c:	89 45 0c             	mov    %eax,0xc(%ebp)
    pa = ROUNDDOWN(pa, PGSIZE);
c010304f:	8b 45 14             	mov    0x14(%ebp),%eax
c0103052:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103055:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103058:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c010305d:	89 45 14             	mov    %eax,0x14(%ebp)
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
c0103060:	eb 57                	jmp    c01030b9 <boot_map_segment+0xe0>
        pte_t *ptep = get_pte(pgdir, la, 1);
c0103062:	83 ec 04             	sub    $0x4,%esp
c0103065:	6a 01                	push   $0x1
c0103067:	ff 75 0c             	pushl  0xc(%ebp)
c010306a:	ff 75 08             	pushl  0x8(%ebp)
c010306d:	e8 53 01 00 00       	call   c01031c5 <get_pte>
c0103072:	83 c4 10             	add    $0x10,%esp
c0103075:	89 45 e0             	mov    %eax,-0x20(%ebp)
        assert(ptep != NULL);
c0103078:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c010307c:	75 19                	jne    c0103097 <boot_map_segment+0xbe>
c010307e:	68 02 63 10 c0       	push   $0xc0106302
c0103083:	68 ed 62 10 c0       	push   $0xc01062ed
c0103088:	68 00 01 00 00       	push   $0x100
c010308d:	68 c8 62 10 c0       	push   $0xc01062c8
c0103092:	e8 42 d3 ff ff       	call   c01003d9 <__panic>
        *ptep = pa | PTE_P | perm;
c0103097:	8b 45 14             	mov    0x14(%ebp),%eax
c010309a:	0b 45 18             	or     0x18(%ebp),%eax
c010309d:	83 c8 01             	or     $0x1,%eax
c01030a0:	89 c2                	mov    %eax,%edx
c01030a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01030a5:	89 10                	mov    %edx,(%eax)
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
    assert(PGOFF(la) == PGOFF(pa));
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
c01030a7:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
c01030ab:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
c01030b2:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
c01030b9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01030bd:	75 a3                	jne    c0103062 <boot_map_segment+0x89>
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pa | PTE_P | perm;
    }
}
c01030bf:	90                   	nop
c01030c0:	c9                   	leave  
c01030c1:	c3                   	ret    

c01030c2 <boot_alloc_page>:

//boot_alloc_page - allocate one page using pmm->alloc_pages(1) 
// return value: the kernel virtual address of this allocated page
//note: this function is used to get the memory for PDT(Page Directory Table)&PT(Page Table)
static void *
boot_alloc_page(void) {
c01030c2:	55                   	push   %ebp
c01030c3:	89 e5                	mov    %esp,%ebp
c01030c5:	83 ec 18             	sub    $0x18,%esp
    struct Page *p = alloc_page();
c01030c8:	83 ec 0c             	sub    $0xc,%esp
c01030cb:	6a 01                	push   $0x1
c01030cd:	e8 aa fa ff ff       	call   c0102b7c <alloc_pages>
c01030d2:	83 c4 10             	add    $0x10,%esp
c01030d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (p == NULL) {
c01030d8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01030dc:	75 17                	jne    c01030f5 <boot_alloc_page+0x33>
        panic("boot_alloc_page failed.\n");
c01030de:	83 ec 04             	sub    $0x4,%esp
c01030e1:	68 0f 63 10 c0       	push   $0xc010630f
c01030e6:	68 0c 01 00 00       	push   $0x10c
c01030eb:	68 c8 62 10 c0       	push   $0xc01062c8
c01030f0:	e8 e4 d2 ff ff       	call   c01003d9 <__panic>
    }
    return page2kva(p);
c01030f5:	83 ec 0c             	sub    $0xc,%esp
c01030f8:	ff 75 f4             	pushl  -0xc(%ebp)
c01030fb:	e8 d3 f7 ff ff       	call   c01028d3 <page2kva>
c0103100:	83 c4 10             	add    $0x10,%esp
}
c0103103:	c9                   	leave  
c0103104:	c3                   	ret    

c0103105 <pmm_init>:

//pmm_init - setup a pmm to manage physical memory, build PDT&PT to setup paging mechanism 
//         - check the correctness of pmm & paging mechanism, print PDT&PT
void
pmm_init(void) {
c0103105:	55                   	push   %ebp
c0103106:	89 e5                	mov    %esp,%ebp
c0103108:	83 ec 18             	sub    $0x18,%esp
    // We've already enabled paging
    boot_cr3 = PADDR(boot_pgdir);
c010310b:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103110:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0103113:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
c010311a:	77 17                	ja     c0103133 <pmm_init+0x2e>
c010311c:	ff 75 f4             	pushl  -0xc(%ebp)
c010311f:	68 a4 62 10 c0       	push   $0xc01062a4
c0103124:	68 16 01 00 00       	push   $0x116
c0103129:	68 c8 62 10 c0       	push   $0xc01062c8
c010312e:	e8 a6 d2 ff ff       	call   c01003d9 <__panic>
c0103133:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103136:	05 00 00 00 40       	add    $0x40000000,%eax
c010313b:	a3 14 af 11 c0       	mov    %eax,0xc011af14
    //We need to alloc/free the physical memory (granularity is 4KB or other size). 
    //So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    //First we should init a physical memory manager(pmm) based on the framework.
    //Then pmm can alloc/free the physical memory. 
    //Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();
c0103140:	e8 e3 f9 ff ff       	call   c0102b28 <init_pmm_manager>

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();
c0103145:	e8 d3 fa ff ff       	call   c0102c1d <page_init>

    //use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();
c010314a:	e8 90 03 00 00       	call   c01034df <check_alloc_page>

    check_pgdir();
c010314f:	e8 ae 03 00 00       	call   c0103502 <check_pgdir>

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // recursively insert boot_pgdir in itself
    // to form a virtual page table at virtual address VPT
    boot_pgdir[PDX(VPT)] = PADDR(boot_pgdir) | PTE_P | PTE_W;
c0103154:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103159:	8d 90 ac 0f 00 00    	lea    0xfac(%eax),%edx
c010315f:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103164:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103167:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
c010316e:	77 17                	ja     c0103187 <pmm_init+0x82>
c0103170:	ff 75 f0             	pushl  -0x10(%ebp)
c0103173:	68 a4 62 10 c0       	push   $0xc01062a4
c0103178:	68 2c 01 00 00       	push   $0x12c
c010317d:	68 c8 62 10 c0       	push   $0xc01062c8
c0103182:	e8 52 d2 ff ff       	call   c01003d9 <__panic>
c0103187:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010318a:	05 00 00 00 40       	add    $0x40000000,%eax
c010318f:	83 c8 03             	or     $0x3,%eax
c0103192:	89 02                	mov    %eax,(%edx)

    // map all physical memory to linear memory with base linear addr KERNBASE
    // linear_addr KERNBASE ~ KERNBASE + KMEMSIZE = phy_addr 0 ~ KMEMSIZE
    boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, 0, PTE_W);
c0103194:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103199:	83 ec 0c             	sub    $0xc,%esp
c010319c:	6a 02                	push   $0x2
c010319e:	6a 00                	push   $0x0
c01031a0:	68 00 00 00 38       	push   $0x38000000
c01031a5:	68 00 00 00 c0       	push   $0xc0000000
c01031aa:	50                   	push   %eax
c01031ab:	e8 29 fe ff ff       	call   c0102fd9 <boot_map_segment>
c01031b0:	83 c4 20             	add    $0x20,%esp

    // Since we are using bootloader's GDT,
    // we should reload gdt (second time, the last time) to get user segments and the TSS
    // map virtual_addr 0 ~ 4G = linear_addr 0 ~ 4G
    // then set kernel stack (ss:esp) in TSS, setup TSS in gdt, load TSS
    gdt_init();
c01031b3:	e8 7e f8 ff ff       	call   c0102a36 <gdt_init>

    //now the basic virtual memory map(see memalyout.h) is established.
    //check the correctness of the basic virtual memory map.
    check_boot_pgdir();
c01031b8:	e8 ab 08 00 00       	call   c0103a68 <check_boot_pgdir>

    print_pgdir();
c01031bd:	e8 a1 0c 00 00       	call   c0103e63 <print_pgdir>

}
c01031c2:	90                   	nop
c01031c3:	c9                   	leave  
c01031c4:	c3                   	ret    

c01031c5 <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *
get_pte(pde_t *pgdir, uintptr_t la, bool create) {
c01031c5:	55                   	push   %ebp
c01031c6:	89 e5                	mov    %esp,%ebp
c01031c8:	83 ec 28             	sub    $0x28,%esp
                          // (6) clear page content using memset
                          // (7) set page directory entry's permission
    }
    return NULL;          // (8) return page table entry
#endif
    pde_t *pdep = &pgdir[PDX(la)];
c01031cb:	8b 45 0c             	mov    0xc(%ebp),%eax
c01031ce:	c1 e8 16             	shr    $0x16,%eax
c01031d1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c01031d8:	8b 45 08             	mov    0x8(%ebp),%eax
c01031db:	01 d0                	add    %edx,%eax
c01031dd:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (!(*pdep & PTE_P)) {
c01031e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01031e3:	8b 00                	mov    (%eax),%eax
c01031e5:	83 e0 01             	and    $0x1,%eax
c01031e8:	85 c0                	test   %eax,%eax
c01031ea:	0f 85 9f 00 00 00    	jne    c010328f <get_pte+0xca>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
c01031f0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01031f4:	74 16                	je     c010320c <get_pte+0x47>
c01031f6:	83 ec 0c             	sub    $0xc,%esp
c01031f9:	6a 01                	push   $0x1
c01031fb:	e8 7c f9 ff ff       	call   c0102b7c <alloc_pages>
c0103200:	83 c4 10             	add    $0x10,%esp
c0103203:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103206:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010320a:	75 0a                	jne    c0103216 <get_pte+0x51>
            return NULL;
c010320c:	b8 00 00 00 00       	mov    $0x0,%eax
c0103211:	e9 ca 00 00 00       	jmp    c01032e0 <get_pte+0x11b>
        }
        set_page_ref(page, 1);
c0103216:	83 ec 08             	sub    $0x8,%esp
c0103219:	6a 01                	push   $0x1
c010321b:	ff 75 f0             	pushl  -0x10(%ebp)
c010321e:	e8 55 f7 ff ff       	call   c0102978 <set_page_ref>
c0103223:	83 c4 10             	add    $0x10,%esp
        uintptr_t pa = page2pa(page);
c0103226:	83 ec 0c             	sub    $0xc,%esp
c0103229:	ff 75 f0             	pushl  -0x10(%ebp)
c010322c:	e8 48 f6 ff ff       	call   c0102879 <page2pa>
c0103231:	83 c4 10             	add    $0x10,%esp
c0103234:	89 45 ec             	mov    %eax,-0x14(%ebp)
        memset(KADDR(pa), 0, PGSIZE);
c0103237:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010323a:	89 45 e8             	mov    %eax,-0x18(%ebp)
c010323d:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103240:	c1 e8 0c             	shr    $0xc,%eax
c0103243:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103246:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c010324b:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
c010324e:	72 17                	jb     c0103267 <get_pte+0xa2>
c0103250:	ff 75 e8             	pushl  -0x18(%ebp)
c0103253:	68 00 62 10 c0       	push   $0xc0106200
c0103258:	68 72 01 00 00       	push   $0x172
c010325d:	68 c8 62 10 c0       	push   $0xc01062c8
c0103262:	e8 72 d1 ff ff       	call   c01003d9 <__panic>
c0103267:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010326a:	2d 00 00 00 40       	sub    $0x40000000,%eax
c010326f:	83 ec 04             	sub    $0x4,%esp
c0103272:	68 00 10 00 00       	push   $0x1000
c0103277:	6a 00                	push   $0x0
c0103279:	50                   	push   %eax
c010327a:	e8 74 20 00 00       	call   c01052f3 <memset>
c010327f:	83 c4 10             	add    $0x10,%esp
        *pdep = pa | PTE_U | PTE_W | PTE_P;
c0103282:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103285:	83 c8 07             	or     $0x7,%eax
c0103288:	89 c2                	mov    %eax,%edx
c010328a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010328d:	89 10                	mov    %edx,(%eax)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep)))[PTX(la)];
c010328f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103292:	8b 00                	mov    (%eax),%eax
c0103294:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103299:	89 45 e0             	mov    %eax,-0x20(%ebp)
c010329c:	8b 45 e0             	mov    -0x20(%ebp),%eax
c010329f:	c1 e8 0c             	shr    $0xc,%eax
c01032a2:	89 45 dc             	mov    %eax,-0x24(%ebp)
c01032a5:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01032aa:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c01032ad:	72 17                	jb     c01032c6 <get_pte+0x101>
c01032af:	ff 75 e0             	pushl  -0x20(%ebp)
c01032b2:	68 00 62 10 c0       	push   $0xc0106200
c01032b7:	68 75 01 00 00       	push   $0x175
c01032bc:	68 c8 62 10 c0       	push   $0xc01062c8
c01032c1:	e8 13 d1 ff ff       	call   c01003d9 <__panic>
c01032c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01032c9:	2d 00 00 00 40       	sub    $0x40000000,%eax
c01032ce:	89 c2                	mov    %eax,%edx
c01032d0:	8b 45 0c             	mov    0xc(%ebp),%eax
c01032d3:	c1 e8 0c             	shr    $0xc,%eax
c01032d6:	25 ff 03 00 00       	and    $0x3ff,%eax
c01032db:	c1 e0 02             	shl    $0x2,%eax
c01032de:	01 d0                	add    %edx,%eax
}
c01032e0:	c9                   	leave  
c01032e1:	c3                   	ret    

c01032e2 <get_page>:

//get_page - get related Page struct for linear address la using PDT pgdir
struct Page *
get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
c01032e2:	55                   	push   %ebp
c01032e3:	89 e5                	mov    %esp,%ebp
c01032e5:	83 ec 18             	sub    $0x18,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
c01032e8:	83 ec 04             	sub    $0x4,%esp
c01032eb:	6a 00                	push   $0x0
c01032ed:	ff 75 0c             	pushl  0xc(%ebp)
c01032f0:	ff 75 08             	pushl  0x8(%ebp)
c01032f3:	e8 cd fe ff ff       	call   c01031c5 <get_pte>
c01032f8:	83 c4 10             	add    $0x10,%esp
c01032fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep_store != NULL) {
c01032fe:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0103302:	74 08                	je     c010330c <get_page+0x2a>
        *ptep_store = ptep;
c0103304:	8b 45 10             	mov    0x10(%ebp),%eax
c0103307:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010330a:	89 10                	mov    %edx,(%eax)
    }
    if (ptep != NULL && *ptep & PTE_P) {
c010330c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103310:	74 1f                	je     c0103331 <get_page+0x4f>
c0103312:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103315:	8b 00                	mov    (%eax),%eax
c0103317:	83 e0 01             	and    $0x1,%eax
c010331a:	85 c0                	test   %eax,%eax
c010331c:	74 13                	je     c0103331 <get_page+0x4f>
        return pte2page(*ptep);
c010331e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103321:	8b 00                	mov    (%eax),%eax
c0103323:	83 ec 0c             	sub    $0xc,%esp
c0103326:	50                   	push   %eax
c0103327:	e8 ec f5 ff ff       	call   c0102918 <pte2page>
c010332c:	83 c4 10             	add    $0x10,%esp
c010332f:	eb 05                	jmp    c0103336 <get_page+0x54>
    }
    return NULL;
c0103331:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0103336:	c9                   	leave  
c0103337:	c3                   	ret    

c0103338 <page_remove_pte>:

//page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
//note: PT is changed, so the TLB need to be invalidate 
static inline void
page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
c0103338:	55                   	push   %ebp
c0103339:	89 e5                	mov    %esp,%ebp
c010333b:	83 ec 18             	sub    $0x18,%esp
                                  //(4) and free this page when page reference reachs 0
                                  //(5) clear second page table entry
                                  //(6) flush tlb
    }
#endif
    if (*ptep & PTE_P) {
c010333e:	8b 45 10             	mov    0x10(%ebp),%eax
c0103341:	8b 00                	mov    (%eax),%eax
c0103343:	83 e0 01             	and    $0x1,%eax
c0103346:	85 c0                	test   %eax,%eax
c0103348:	74 50                	je     c010339a <page_remove_pte+0x62>
        struct Page *page = pte2page(*ptep);
c010334a:	8b 45 10             	mov    0x10(%ebp),%eax
c010334d:	8b 00                	mov    (%eax),%eax
c010334f:	83 ec 0c             	sub    $0xc,%esp
c0103352:	50                   	push   %eax
c0103353:	e8 c0 f5 ff ff       	call   c0102918 <pte2page>
c0103358:	83 c4 10             	add    $0x10,%esp
c010335b:	89 45 f4             	mov    %eax,-0xc(%ebp)
        if (page_ref_dec(page) == 0) {
c010335e:	83 ec 0c             	sub    $0xc,%esp
c0103361:	ff 75 f4             	pushl  -0xc(%ebp)
c0103364:	e8 34 f6 ff ff       	call   c010299d <page_ref_dec>
c0103369:	83 c4 10             	add    $0x10,%esp
c010336c:	85 c0                	test   %eax,%eax
c010336e:	75 10                	jne    c0103380 <page_remove_pte+0x48>
            free_page(page);
c0103370:	83 ec 08             	sub    $0x8,%esp
c0103373:	6a 01                	push   $0x1
c0103375:	ff 75 f4             	pushl  -0xc(%ebp)
c0103378:	e8 3d f8 ff ff       	call   c0102bba <free_pages>
c010337d:	83 c4 10             	add    $0x10,%esp
        }
        *ptep = 0;
c0103380:	8b 45 10             	mov    0x10(%ebp),%eax
c0103383:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        tlb_invalidate(pgdir, la);
c0103389:	83 ec 08             	sub    $0x8,%esp
c010338c:	ff 75 0c             	pushl  0xc(%ebp)
c010338f:	ff 75 08             	pushl  0x8(%ebp)
c0103392:	e8 f8 00 00 00       	call   c010348f <tlb_invalidate>
c0103397:	83 c4 10             	add    $0x10,%esp
    }
}
c010339a:	90                   	nop
c010339b:	c9                   	leave  
c010339c:	c3                   	ret    

c010339d <page_remove>:

//page_remove - free an Page which is related linear address la and has an validated pte
void
page_remove(pde_t *pgdir, uintptr_t la) {
c010339d:	55                   	push   %ebp
c010339e:	89 e5                	mov    %esp,%ebp
c01033a0:	83 ec 18             	sub    $0x18,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
c01033a3:	83 ec 04             	sub    $0x4,%esp
c01033a6:	6a 00                	push   $0x0
c01033a8:	ff 75 0c             	pushl  0xc(%ebp)
c01033ab:	ff 75 08             	pushl  0x8(%ebp)
c01033ae:	e8 12 fe ff ff       	call   c01031c5 <get_pte>
c01033b3:	83 c4 10             	add    $0x10,%esp
c01033b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep != NULL) {
c01033b9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01033bd:	74 14                	je     c01033d3 <page_remove+0x36>
        page_remove_pte(pgdir, la, ptep);
c01033bf:	83 ec 04             	sub    $0x4,%esp
c01033c2:	ff 75 f4             	pushl  -0xc(%ebp)
c01033c5:	ff 75 0c             	pushl  0xc(%ebp)
c01033c8:	ff 75 08             	pushl  0x8(%ebp)
c01033cb:	e8 68 ff ff ff       	call   c0103338 <page_remove_pte>
c01033d0:	83 c4 10             	add    $0x10,%esp
    }
}
c01033d3:	90                   	nop
c01033d4:	c9                   	leave  
c01033d5:	c3                   	ret    

c01033d6 <page_insert>:
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
//note: PT is changed, so the TLB need to be invalidate 
int
page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
c01033d6:	55                   	push   %ebp
c01033d7:	89 e5                	mov    %esp,%ebp
c01033d9:	83 ec 18             	sub    $0x18,%esp
    pte_t *ptep = get_pte(pgdir, la, 1);
c01033dc:	83 ec 04             	sub    $0x4,%esp
c01033df:	6a 01                	push   $0x1
c01033e1:	ff 75 10             	pushl  0x10(%ebp)
c01033e4:	ff 75 08             	pushl  0x8(%ebp)
c01033e7:	e8 d9 fd ff ff       	call   c01031c5 <get_pte>
c01033ec:	83 c4 10             	add    $0x10,%esp
c01033ef:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep == NULL) {
c01033f2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01033f6:	75 0a                	jne    c0103402 <page_insert+0x2c>
        return -E_NO_MEM;
c01033f8:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
c01033fd:	e9 8b 00 00 00       	jmp    c010348d <page_insert+0xb7>
    }
    page_ref_inc(page);
c0103402:	83 ec 0c             	sub    $0xc,%esp
c0103405:	ff 75 0c             	pushl  0xc(%ebp)
c0103408:	e8 79 f5 ff ff       	call   c0102986 <page_ref_inc>
c010340d:	83 c4 10             	add    $0x10,%esp
    if (*ptep & PTE_P) {
c0103410:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103413:	8b 00                	mov    (%eax),%eax
c0103415:	83 e0 01             	and    $0x1,%eax
c0103418:	85 c0                	test   %eax,%eax
c010341a:	74 40                	je     c010345c <page_insert+0x86>
        struct Page *p = pte2page(*ptep);
c010341c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010341f:	8b 00                	mov    (%eax),%eax
c0103421:	83 ec 0c             	sub    $0xc,%esp
c0103424:	50                   	push   %eax
c0103425:	e8 ee f4 ff ff       	call   c0102918 <pte2page>
c010342a:	83 c4 10             	add    $0x10,%esp
c010342d:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (p == page) {
c0103430:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103433:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103436:	75 10                	jne    c0103448 <page_insert+0x72>
            page_ref_dec(page);
c0103438:	83 ec 0c             	sub    $0xc,%esp
c010343b:	ff 75 0c             	pushl  0xc(%ebp)
c010343e:	e8 5a f5 ff ff       	call   c010299d <page_ref_dec>
c0103443:	83 c4 10             	add    $0x10,%esp
c0103446:	eb 14                	jmp    c010345c <page_insert+0x86>
        }
        else {
            page_remove_pte(pgdir, la, ptep);
c0103448:	83 ec 04             	sub    $0x4,%esp
c010344b:	ff 75 f4             	pushl  -0xc(%ebp)
c010344e:	ff 75 10             	pushl  0x10(%ebp)
c0103451:	ff 75 08             	pushl  0x8(%ebp)
c0103454:	e8 df fe ff ff       	call   c0103338 <page_remove_pte>
c0103459:	83 c4 10             	add    $0x10,%esp
        }
    }
    *ptep = page2pa(page) | PTE_P | perm;
c010345c:	83 ec 0c             	sub    $0xc,%esp
c010345f:	ff 75 0c             	pushl  0xc(%ebp)
c0103462:	e8 12 f4 ff ff       	call   c0102879 <page2pa>
c0103467:	83 c4 10             	add    $0x10,%esp
c010346a:	0b 45 14             	or     0x14(%ebp),%eax
c010346d:	83 c8 01             	or     $0x1,%eax
c0103470:	89 c2                	mov    %eax,%edx
c0103472:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103475:	89 10                	mov    %edx,(%eax)
    tlb_invalidate(pgdir, la);
c0103477:	83 ec 08             	sub    $0x8,%esp
c010347a:	ff 75 10             	pushl  0x10(%ebp)
c010347d:	ff 75 08             	pushl  0x8(%ebp)
c0103480:	e8 0a 00 00 00       	call   c010348f <tlb_invalidate>
c0103485:	83 c4 10             	add    $0x10,%esp
    return 0;
c0103488:	b8 00 00 00 00       	mov    $0x0,%eax
}
c010348d:	c9                   	leave  
c010348e:	c3                   	ret    

c010348f <tlb_invalidate>:

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void
tlb_invalidate(pde_t *pgdir, uintptr_t la) {
c010348f:	55                   	push   %ebp
c0103490:	89 e5                	mov    %esp,%ebp
c0103492:	83 ec 18             	sub    $0x18,%esp
}

static inline uintptr_t
rcr3(void) {
    uintptr_t cr3;
    asm volatile ("mov %%cr3, %0" : "=r" (cr3) :: "memory");
c0103495:	0f 20 d8             	mov    %cr3,%eax
c0103498:	89 45 ec             	mov    %eax,-0x14(%ebp)
    return cr3;
c010349b:	8b 55 ec             	mov    -0x14(%ebp),%edx
    if (rcr3() == PADDR(pgdir)) {
c010349e:	8b 45 08             	mov    0x8(%ebp),%eax
c01034a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01034a4:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
c01034ab:	77 17                	ja     c01034c4 <tlb_invalidate+0x35>
c01034ad:	ff 75 f0             	pushl  -0x10(%ebp)
c01034b0:	68 a4 62 10 c0       	push   $0xc01062a4
c01034b5:	68 d7 01 00 00       	push   $0x1d7
c01034ba:	68 c8 62 10 c0       	push   $0xc01062c8
c01034bf:	e8 15 cf ff ff       	call   c01003d9 <__panic>
c01034c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01034c7:	05 00 00 00 40       	add    $0x40000000,%eax
c01034cc:	39 c2                	cmp    %eax,%edx
c01034ce:	75 0c                	jne    c01034dc <tlb_invalidate+0x4d>
        invlpg((void *)la);
c01034d0:	8b 45 0c             	mov    0xc(%ebp),%eax
c01034d3:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static inline void
invlpg(void *addr) {
    asm volatile ("invlpg (%0)" :: "r" (addr) : "memory");
c01034d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01034d9:	0f 01 38             	invlpg (%eax)
    }
}
c01034dc:	90                   	nop
c01034dd:	c9                   	leave  
c01034de:	c3                   	ret    

c01034df <check_alloc_page>:

static void
check_alloc_page(void) {
c01034df:	55                   	push   %ebp
c01034e0:	89 e5                	mov    %esp,%ebp
c01034e2:	83 ec 08             	sub    $0x8,%esp
    pmm_manager->check();
c01034e5:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c01034ea:	8b 40 18             	mov    0x18(%eax),%eax
c01034ed:	ff d0                	call   *%eax
    cprintf("check_alloc_page() succeeded!\n");
c01034ef:	83 ec 0c             	sub    $0xc,%esp
c01034f2:	68 28 63 10 c0       	push   $0xc0106328
c01034f7:	e8 77 cd ff ff       	call   c0100273 <cprintf>
c01034fc:	83 c4 10             	add    $0x10,%esp
}
c01034ff:	90                   	nop
c0103500:	c9                   	leave  
c0103501:	c3                   	ret    

c0103502 <check_pgdir>:

static void
check_pgdir(void) {
c0103502:	55                   	push   %ebp
c0103503:	89 e5                	mov    %esp,%ebp
c0103505:	83 ec 28             	sub    $0x28,%esp
    assert(npage <= KMEMSIZE / PGSIZE);
c0103508:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c010350d:	3d 00 80 03 00       	cmp    $0x38000,%eax
c0103512:	76 19                	jbe    c010352d <check_pgdir+0x2b>
c0103514:	68 47 63 10 c0       	push   $0xc0106347
c0103519:	68 ed 62 10 c0       	push   $0xc01062ed
c010351e:	68 e4 01 00 00       	push   $0x1e4
c0103523:	68 c8 62 10 c0       	push   $0xc01062c8
c0103528:	e8 ac ce ff ff       	call   c01003d9 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
c010352d:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103532:	85 c0                	test   %eax,%eax
c0103534:	74 0e                	je     c0103544 <check_pgdir+0x42>
c0103536:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010353b:	25 ff 0f 00 00       	and    $0xfff,%eax
c0103540:	85 c0                	test   %eax,%eax
c0103542:	74 19                	je     c010355d <check_pgdir+0x5b>
c0103544:	68 64 63 10 c0       	push   $0xc0106364
c0103549:	68 ed 62 10 c0       	push   $0xc01062ed
c010354e:	68 e5 01 00 00       	push   $0x1e5
c0103553:	68 c8 62 10 c0       	push   $0xc01062c8
c0103558:	e8 7c ce ff ff       	call   c01003d9 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
c010355d:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103562:	83 ec 04             	sub    $0x4,%esp
c0103565:	6a 00                	push   $0x0
c0103567:	6a 00                	push   $0x0
c0103569:	50                   	push   %eax
c010356a:	e8 73 fd ff ff       	call   c01032e2 <get_page>
c010356f:	83 c4 10             	add    $0x10,%esp
c0103572:	85 c0                	test   %eax,%eax
c0103574:	74 19                	je     c010358f <check_pgdir+0x8d>
c0103576:	68 9c 63 10 c0       	push   $0xc010639c
c010357b:	68 ed 62 10 c0       	push   $0xc01062ed
c0103580:	68 e6 01 00 00       	push   $0x1e6
c0103585:	68 c8 62 10 c0       	push   $0xc01062c8
c010358a:	e8 4a ce ff ff       	call   c01003d9 <__panic>

    struct Page *p1, *p2;
    p1 = alloc_page();
c010358f:	83 ec 0c             	sub    $0xc,%esp
c0103592:	6a 01                	push   $0x1
c0103594:	e8 e3 f5 ff ff       	call   c0102b7c <alloc_pages>
c0103599:	83 c4 10             	add    $0x10,%esp
c010359c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
c010359f:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01035a4:	6a 00                	push   $0x0
c01035a6:	6a 00                	push   $0x0
c01035a8:	ff 75 f4             	pushl  -0xc(%ebp)
c01035ab:	50                   	push   %eax
c01035ac:	e8 25 fe ff ff       	call   c01033d6 <page_insert>
c01035b1:	83 c4 10             	add    $0x10,%esp
c01035b4:	85 c0                	test   %eax,%eax
c01035b6:	74 19                	je     c01035d1 <check_pgdir+0xcf>
c01035b8:	68 c4 63 10 c0       	push   $0xc01063c4
c01035bd:	68 ed 62 10 c0       	push   $0xc01062ed
c01035c2:	68 ea 01 00 00       	push   $0x1ea
c01035c7:	68 c8 62 10 c0       	push   $0xc01062c8
c01035cc:	e8 08 ce ff ff       	call   c01003d9 <__panic>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
c01035d1:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01035d6:	83 ec 04             	sub    $0x4,%esp
c01035d9:	6a 00                	push   $0x0
c01035db:	6a 00                	push   $0x0
c01035dd:	50                   	push   %eax
c01035de:	e8 e2 fb ff ff       	call   c01031c5 <get_pte>
c01035e3:	83 c4 10             	add    $0x10,%esp
c01035e6:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01035e9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01035ed:	75 19                	jne    c0103608 <check_pgdir+0x106>
c01035ef:	68 f0 63 10 c0       	push   $0xc01063f0
c01035f4:	68 ed 62 10 c0       	push   $0xc01062ed
c01035f9:	68 ed 01 00 00       	push   $0x1ed
c01035fe:	68 c8 62 10 c0       	push   $0xc01062c8
c0103603:	e8 d1 cd ff ff       	call   c01003d9 <__panic>
    assert(pte2page(*ptep) == p1);
c0103608:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010360b:	8b 00                	mov    (%eax),%eax
c010360d:	83 ec 0c             	sub    $0xc,%esp
c0103610:	50                   	push   %eax
c0103611:	e8 02 f3 ff ff       	call   c0102918 <pte2page>
c0103616:	83 c4 10             	add    $0x10,%esp
c0103619:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010361c:	74 19                	je     c0103637 <check_pgdir+0x135>
c010361e:	68 1d 64 10 c0       	push   $0xc010641d
c0103623:	68 ed 62 10 c0       	push   $0xc01062ed
c0103628:	68 ee 01 00 00       	push   $0x1ee
c010362d:	68 c8 62 10 c0       	push   $0xc01062c8
c0103632:	e8 a2 cd ff ff       	call   c01003d9 <__panic>
    assert(page_ref(p1) == 1);
c0103637:	83 ec 0c             	sub    $0xc,%esp
c010363a:	ff 75 f4             	pushl  -0xc(%ebp)
c010363d:	e8 2c f3 ff ff       	call   c010296e <page_ref>
c0103642:	83 c4 10             	add    $0x10,%esp
c0103645:	83 f8 01             	cmp    $0x1,%eax
c0103648:	74 19                	je     c0103663 <check_pgdir+0x161>
c010364a:	68 33 64 10 c0       	push   $0xc0106433
c010364f:	68 ed 62 10 c0       	push   $0xc01062ed
c0103654:	68 ef 01 00 00       	push   $0x1ef
c0103659:	68 c8 62 10 c0       	push   $0xc01062c8
c010365e:	e8 76 cd ff ff       	call   c01003d9 <__panic>

    ptep = &((pte_t *)KADDR(PDE_ADDR(boot_pgdir[0])))[1];
c0103663:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103668:	8b 00                	mov    (%eax),%eax
c010366a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c010366f:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0103672:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103675:	c1 e8 0c             	shr    $0xc,%eax
c0103678:	89 45 e8             	mov    %eax,-0x18(%ebp)
c010367b:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103680:	39 45 e8             	cmp    %eax,-0x18(%ebp)
c0103683:	72 17                	jb     c010369c <check_pgdir+0x19a>
c0103685:	ff 75 ec             	pushl  -0x14(%ebp)
c0103688:	68 00 62 10 c0       	push   $0xc0106200
c010368d:	68 f1 01 00 00       	push   $0x1f1
c0103692:	68 c8 62 10 c0       	push   $0xc01062c8
c0103697:	e8 3d cd ff ff       	call   c01003d9 <__panic>
c010369c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010369f:	2d 00 00 00 40       	sub    $0x40000000,%eax
c01036a4:	83 c0 04             	add    $0x4,%eax
c01036a7:	89 45 f0             	mov    %eax,-0x10(%ebp)
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
c01036aa:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01036af:	83 ec 04             	sub    $0x4,%esp
c01036b2:	6a 00                	push   $0x0
c01036b4:	68 00 10 00 00       	push   $0x1000
c01036b9:	50                   	push   %eax
c01036ba:	e8 06 fb ff ff       	call   c01031c5 <get_pte>
c01036bf:	83 c4 10             	add    $0x10,%esp
c01036c2:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c01036c5:	74 19                	je     c01036e0 <check_pgdir+0x1de>
c01036c7:	68 48 64 10 c0       	push   $0xc0106448
c01036cc:	68 ed 62 10 c0       	push   $0xc01062ed
c01036d1:	68 f2 01 00 00       	push   $0x1f2
c01036d6:	68 c8 62 10 c0       	push   $0xc01062c8
c01036db:	e8 f9 cc ff ff       	call   c01003d9 <__panic>

    p2 = alloc_page();
c01036e0:	83 ec 0c             	sub    $0xc,%esp
c01036e3:	6a 01                	push   $0x1
c01036e5:	e8 92 f4 ff ff       	call   c0102b7c <alloc_pages>
c01036ea:	83 c4 10             	add    $0x10,%esp
c01036ed:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
c01036f0:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01036f5:	6a 06                	push   $0x6
c01036f7:	68 00 10 00 00       	push   $0x1000
c01036fc:	ff 75 e4             	pushl  -0x1c(%ebp)
c01036ff:	50                   	push   %eax
c0103700:	e8 d1 fc ff ff       	call   c01033d6 <page_insert>
c0103705:	83 c4 10             	add    $0x10,%esp
c0103708:	85 c0                	test   %eax,%eax
c010370a:	74 19                	je     c0103725 <check_pgdir+0x223>
c010370c:	68 70 64 10 c0       	push   $0xc0106470
c0103711:	68 ed 62 10 c0       	push   $0xc01062ed
c0103716:	68 f5 01 00 00       	push   $0x1f5
c010371b:	68 c8 62 10 c0       	push   $0xc01062c8
c0103720:	e8 b4 cc ff ff       	call   c01003d9 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
c0103725:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010372a:	83 ec 04             	sub    $0x4,%esp
c010372d:	6a 00                	push   $0x0
c010372f:	68 00 10 00 00       	push   $0x1000
c0103734:	50                   	push   %eax
c0103735:	e8 8b fa ff ff       	call   c01031c5 <get_pte>
c010373a:	83 c4 10             	add    $0x10,%esp
c010373d:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103740:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0103744:	75 19                	jne    c010375f <check_pgdir+0x25d>
c0103746:	68 a8 64 10 c0       	push   $0xc01064a8
c010374b:	68 ed 62 10 c0       	push   $0xc01062ed
c0103750:	68 f6 01 00 00       	push   $0x1f6
c0103755:	68 c8 62 10 c0       	push   $0xc01062c8
c010375a:	e8 7a cc ff ff       	call   c01003d9 <__panic>
    assert(*ptep & PTE_U);
c010375f:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103762:	8b 00                	mov    (%eax),%eax
c0103764:	83 e0 04             	and    $0x4,%eax
c0103767:	85 c0                	test   %eax,%eax
c0103769:	75 19                	jne    c0103784 <check_pgdir+0x282>
c010376b:	68 d8 64 10 c0       	push   $0xc01064d8
c0103770:	68 ed 62 10 c0       	push   $0xc01062ed
c0103775:	68 f7 01 00 00       	push   $0x1f7
c010377a:	68 c8 62 10 c0       	push   $0xc01062c8
c010377f:	e8 55 cc ff ff       	call   c01003d9 <__panic>
    assert(*ptep & PTE_W);
c0103784:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103787:	8b 00                	mov    (%eax),%eax
c0103789:	83 e0 02             	and    $0x2,%eax
c010378c:	85 c0                	test   %eax,%eax
c010378e:	75 19                	jne    c01037a9 <check_pgdir+0x2a7>
c0103790:	68 e6 64 10 c0       	push   $0xc01064e6
c0103795:	68 ed 62 10 c0       	push   $0xc01062ed
c010379a:	68 f8 01 00 00       	push   $0x1f8
c010379f:	68 c8 62 10 c0       	push   $0xc01062c8
c01037a4:	e8 30 cc ff ff       	call   c01003d9 <__panic>
    assert(boot_pgdir[0] & PTE_U);
c01037a9:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01037ae:	8b 00                	mov    (%eax),%eax
c01037b0:	83 e0 04             	and    $0x4,%eax
c01037b3:	85 c0                	test   %eax,%eax
c01037b5:	75 19                	jne    c01037d0 <check_pgdir+0x2ce>
c01037b7:	68 f4 64 10 c0       	push   $0xc01064f4
c01037bc:	68 ed 62 10 c0       	push   $0xc01062ed
c01037c1:	68 f9 01 00 00       	push   $0x1f9
c01037c6:	68 c8 62 10 c0       	push   $0xc01062c8
c01037cb:	e8 09 cc ff ff       	call   c01003d9 <__panic>
    assert(page_ref(p2) == 1);
c01037d0:	83 ec 0c             	sub    $0xc,%esp
c01037d3:	ff 75 e4             	pushl  -0x1c(%ebp)
c01037d6:	e8 93 f1 ff ff       	call   c010296e <page_ref>
c01037db:	83 c4 10             	add    $0x10,%esp
c01037de:	83 f8 01             	cmp    $0x1,%eax
c01037e1:	74 19                	je     c01037fc <check_pgdir+0x2fa>
c01037e3:	68 0a 65 10 c0       	push   $0xc010650a
c01037e8:	68 ed 62 10 c0       	push   $0xc01062ed
c01037ed:	68 fa 01 00 00       	push   $0x1fa
c01037f2:	68 c8 62 10 c0       	push   $0xc01062c8
c01037f7:	e8 dd cb ff ff       	call   c01003d9 <__panic>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
c01037fc:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103801:	6a 00                	push   $0x0
c0103803:	68 00 10 00 00       	push   $0x1000
c0103808:	ff 75 f4             	pushl  -0xc(%ebp)
c010380b:	50                   	push   %eax
c010380c:	e8 c5 fb ff ff       	call   c01033d6 <page_insert>
c0103811:	83 c4 10             	add    $0x10,%esp
c0103814:	85 c0                	test   %eax,%eax
c0103816:	74 19                	je     c0103831 <check_pgdir+0x32f>
c0103818:	68 1c 65 10 c0       	push   $0xc010651c
c010381d:	68 ed 62 10 c0       	push   $0xc01062ed
c0103822:	68 fc 01 00 00       	push   $0x1fc
c0103827:	68 c8 62 10 c0       	push   $0xc01062c8
c010382c:	e8 a8 cb ff ff       	call   c01003d9 <__panic>
    assert(page_ref(p1) == 2);
c0103831:	83 ec 0c             	sub    $0xc,%esp
c0103834:	ff 75 f4             	pushl  -0xc(%ebp)
c0103837:	e8 32 f1 ff ff       	call   c010296e <page_ref>
c010383c:	83 c4 10             	add    $0x10,%esp
c010383f:	83 f8 02             	cmp    $0x2,%eax
c0103842:	74 19                	je     c010385d <check_pgdir+0x35b>
c0103844:	68 48 65 10 c0       	push   $0xc0106548
c0103849:	68 ed 62 10 c0       	push   $0xc01062ed
c010384e:	68 fd 01 00 00       	push   $0x1fd
c0103853:	68 c8 62 10 c0       	push   $0xc01062c8
c0103858:	e8 7c cb ff ff       	call   c01003d9 <__panic>
    assert(page_ref(p2) == 0);
c010385d:	83 ec 0c             	sub    $0xc,%esp
c0103860:	ff 75 e4             	pushl  -0x1c(%ebp)
c0103863:	e8 06 f1 ff ff       	call   c010296e <page_ref>
c0103868:	83 c4 10             	add    $0x10,%esp
c010386b:	85 c0                	test   %eax,%eax
c010386d:	74 19                	je     c0103888 <check_pgdir+0x386>
c010386f:	68 5a 65 10 c0       	push   $0xc010655a
c0103874:	68 ed 62 10 c0       	push   $0xc01062ed
c0103879:	68 fe 01 00 00       	push   $0x1fe
c010387e:	68 c8 62 10 c0       	push   $0xc01062c8
c0103883:	e8 51 cb ff ff       	call   c01003d9 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
c0103888:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010388d:	83 ec 04             	sub    $0x4,%esp
c0103890:	6a 00                	push   $0x0
c0103892:	68 00 10 00 00       	push   $0x1000
c0103897:	50                   	push   %eax
c0103898:	e8 28 f9 ff ff       	call   c01031c5 <get_pte>
c010389d:	83 c4 10             	add    $0x10,%esp
c01038a0:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01038a3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01038a7:	75 19                	jne    c01038c2 <check_pgdir+0x3c0>
c01038a9:	68 a8 64 10 c0       	push   $0xc01064a8
c01038ae:	68 ed 62 10 c0       	push   $0xc01062ed
c01038b3:	68 ff 01 00 00       	push   $0x1ff
c01038b8:	68 c8 62 10 c0       	push   $0xc01062c8
c01038bd:	e8 17 cb ff ff       	call   c01003d9 <__panic>
    assert(pte2page(*ptep) == p1);
c01038c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01038c5:	8b 00                	mov    (%eax),%eax
c01038c7:	83 ec 0c             	sub    $0xc,%esp
c01038ca:	50                   	push   %eax
c01038cb:	e8 48 f0 ff ff       	call   c0102918 <pte2page>
c01038d0:	83 c4 10             	add    $0x10,%esp
c01038d3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01038d6:	74 19                	je     c01038f1 <check_pgdir+0x3ef>
c01038d8:	68 1d 64 10 c0       	push   $0xc010641d
c01038dd:	68 ed 62 10 c0       	push   $0xc01062ed
c01038e2:	68 00 02 00 00       	push   $0x200
c01038e7:	68 c8 62 10 c0       	push   $0xc01062c8
c01038ec:	e8 e8 ca ff ff       	call   c01003d9 <__panic>
    assert((*ptep & PTE_U) == 0);
c01038f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01038f4:	8b 00                	mov    (%eax),%eax
c01038f6:	83 e0 04             	and    $0x4,%eax
c01038f9:	85 c0                	test   %eax,%eax
c01038fb:	74 19                	je     c0103916 <check_pgdir+0x414>
c01038fd:	68 6c 65 10 c0       	push   $0xc010656c
c0103902:	68 ed 62 10 c0       	push   $0xc01062ed
c0103907:	68 01 02 00 00       	push   $0x201
c010390c:	68 c8 62 10 c0       	push   $0xc01062c8
c0103911:	e8 c3 ca ff ff       	call   c01003d9 <__panic>

    page_remove(boot_pgdir, 0x0);
c0103916:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010391b:	83 ec 08             	sub    $0x8,%esp
c010391e:	6a 00                	push   $0x0
c0103920:	50                   	push   %eax
c0103921:	e8 77 fa ff ff       	call   c010339d <page_remove>
c0103926:	83 c4 10             	add    $0x10,%esp
    assert(page_ref(p1) == 1);
c0103929:	83 ec 0c             	sub    $0xc,%esp
c010392c:	ff 75 f4             	pushl  -0xc(%ebp)
c010392f:	e8 3a f0 ff ff       	call   c010296e <page_ref>
c0103934:	83 c4 10             	add    $0x10,%esp
c0103937:	83 f8 01             	cmp    $0x1,%eax
c010393a:	74 19                	je     c0103955 <check_pgdir+0x453>
c010393c:	68 33 64 10 c0       	push   $0xc0106433
c0103941:	68 ed 62 10 c0       	push   $0xc01062ed
c0103946:	68 04 02 00 00       	push   $0x204
c010394b:	68 c8 62 10 c0       	push   $0xc01062c8
c0103950:	e8 84 ca ff ff       	call   c01003d9 <__panic>
    assert(page_ref(p2) == 0);
c0103955:	83 ec 0c             	sub    $0xc,%esp
c0103958:	ff 75 e4             	pushl  -0x1c(%ebp)
c010395b:	e8 0e f0 ff ff       	call   c010296e <page_ref>
c0103960:	83 c4 10             	add    $0x10,%esp
c0103963:	85 c0                	test   %eax,%eax
c0103965:	74 19                	je     c0103980 <check_pgdir+0x47e>
c0103967:	68 5a 65 10 c0       	push   $0xc010655a
c010396c:	68 ed 62 10 c0       	push   $0xc01062ed
c0103971:	68 05 02 00 00       	push   $0x205
c0103976:	68 c8 62 10 c0       	push   $0xc01062c8
c010397b:	e8 59 ca ff ff       	call   c01003d9 <__panic>

    page_remove(boot_pgdir, PGSIZE);
c0103980:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103985:	83 ec 08             	sub    $0x8,%esp
c0103988:	68 00 10 00 00       	push   $0x1000
c010398d:	50                   	push   %eax
c010398e:	e8 0a fa ff ff       	call   c010339d <page_remove>
c0103993:	83 c4 10             	add    $0x10,%esp
    assert(page_ref(p1) == 0);
c0103996:	83 ec 0c             	sub    $0xc,%esp
c0103999:	ff 75 f4             	pushl  -0xc(%ebp)
c010399c:	e8 cd ef ff ff       	call   c010296e <page_ref>
c01039a1:	83 c4 10             	add    $0x10,%esp
c01039a4:	85 c0                	test   %eax,%eax
c01039a6:	74 19                	je     c01039c1 <check_pgdir+0x4bf>
c01039a8:	68 81 65 10 c0       	push   $0xc0106581
c01039ad:	68 ed 62 10 c0       	push   $0xc01062ed
c01039b2:	68 08 02 00 00       	push   $0x208
c01039b7:	68 c8 62 10 c0       	push   $0xc01062c8
c01039bc:	e8 18 ca ff ff       	call   c01003d9 <__panic>
    assert(page_ref(p2) == 0);
c01039c1:	83 ec 0c             	sub    $0xc,%esp
c01039c4:	ff 75 e4             	pushl  -0x1c(%ebp)
c01039c7:	e8 a2 ef ff ff       	call   c010296e <page_ref>
c01039cc:	83 c4 10             	add    $0x10,%esp
c01039cf:	85 c0                	test   %eax,%eax
c01039d1:	74 19                	je     c01039ec <check_pgdir+0x4ea>
c01039d3:	68 5a 65 10 c0       	push   $0xc010655a
c01039d8:	68 ed 62 10 c0       	push   $0xc01062ed
c01039dd:	68 09 02 00 00       	push   $0x209
c01039e2:	68 c8 62 10 c0       	push   $0xc01062c8
c01039e7:	e8 ed c9 ff ff       	call   c01003d9 <__panic>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
c01039ec:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01039f1:	8b 00                	mov    (%eax),%eax
c01039f3:	83 ec 0c             	sub    $0xc,%esp
c01039f6:	50                   	push   %eax
c01039f7:	e8 56 ef ff ff       	call   c0102952 <pde2page>
c01039fc:	83 c4 10             	add    $0x10,%esp
c01039ff:	83 ec 0c             	sub    $0xc,%esp
c0103a02:	50                   	push   %eax
c0103a03:	e8 66 ef ff ff       	call   c010296e <page_ref>
c0103a08:	83 c4 10             	add    $0x10,%esp
c0103a0b:	83 f8 01             	cmp    $0x1,%eax
c0103a0e:	74 19                	je     c0103a29 <check_pgdir+0x527>
c0103a10:	68 94 65 10 c0       	push   $0xc0106594
c0103a15:	68 ed 62 10 c0       	push   $0xc01062ed
c0103a1a:	68 0b 02 00 00       	push   $0x20b
c0103a1f:	68 c8 62 10 c0       	push   $0xc01062c8
c0103a24:	e8 b0 c9 ff ff       	call   c01003d9 <__panic>
    free_page(pde2page(boot_pgdir[0]));
c0103a29:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103a2e:	8b 00                	mov    (%eax),%eax
c0103a30:	83 ec 0c             	sub    $0xc,%esp
c0103a33:	50                   	push   %eax
c0103a34:	e8 19 ef ff ff       	call   c0102952 <pde2page>
c0103a39:	83 c4 10             	add    $0x10,%esp
c0103a3c:	83 ec 08             	sub    $0x8,%esp
c0103a3f:	6a 01                	push   $0x1
c0103a41:	50                   	push   %eax
c0103a42:	e8 73 f1 ff ff       	call   c0102bba <free_pages>
c0103a47:	83 c4 10             	add    $0x10,%esp
    boot_pgdir[0] = 0;
c0103a4a:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103a4f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_pgdir() succeeded!\n");
c0103a55:	83 ec 0c             	sub    $0xc,%esp
c0103a58:	68 bb 65 10 c0       	push   $0xc01065bb
c0103a5d:	e8 11 c8 ff ff       	call   c0100273 <cprintf>
c0103a62:	83 c4 10             	add    $0x10,%esp
}
c0103a65:	90                   	nop
c0103a66:	c9                   	leave  
c0103a67:	c3                   	ret    

c0103a68 <check_boot_pgdir>:

static void
check_boot_pgdir(void) {
c0103a68:	55                   	push   %ebp
c0103a69:	89 e5                	mov    %esp,%ebp
c0103a6b:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
c0103a6e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0103a75:	e9 a3 00 00 00       	jmp    c0103b1d <check_boot_pgdir+0xb5>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
c0103a7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103a7d:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103a80:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103a83:	c1 e8 0c             	shr    $0xc,%eax
c0103a86:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0103a89:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103a8e:	39 45 ec             	cmp    %eax,-0x14(%ebp)
c0103a91:	72 17                	jb     c0103aaa <check_boot_pgdir+0x42>
c0103a93:	ff 75 f0             	pushl  -0x10(%ebp)
c0103a96:	68 00 62 10 c0       	push   $0xc0106200
c0103a9b:	68 17 02 00 00       	push   $0x217
c0103aa0:	68 c8 62 10 c0       	push   $0xc01062c8
c0103aa5:	e8 2f c9 ff ff       	call   c01003d9 <__panic>
c0103aaa:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103aad:	2d 00 00 00 40       	sub    $0x40000000,%eax
c0103ab2:	89 c2                	mov    %eax,%edx
c0103ab4:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103ab9:	83 ec 04             	sub    $0x4,%esp
c0103abc:	6a 00                	push   $0x0
c0103abe:	52                   	push   %edx
c0103abf:	50                   	push   %eax
c0103ac0:	e8 00 f7 ff ff       	call   c01031c5 <get_pte>
c0103ac5:	83 c4 10             	add    $0x10,%esp
c0103ac8:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0103acb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0103acf:	75 19                	jne    c0103aea <check_boot_pgdir+0x82>
c0103ad1:	68 d8 65 10 c0       	push   $0xc01065d8
c0103ad6:	68 ed 62 10 c0       	push   $0xc01062ed
c0103adb:	68 17 02 00 00       	push   $0x217
c0103ae0:	68 c8 62 10 c0       	push   $0xc01062c8
c0103ae5:	e8 ef c8 ff ff       	call   c01003d9 <__panic>
        assert(PTE_ADDR(*ptep) == i);
c0103aea:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103aed:	8b 00                	mov    (%eax),%eax
c0103aef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103af4:	89 c2                	mov    %eax,%edx
c0103af6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103af9:	39 c2                	cmp    %eax,%edx
c0103afb:	74 19                	je     c0103b16 <check_boot_pgdir+0xae>
c0103afd:	68 15 66 10 c0       	push   $0xc0106615
c0103b02:	68 ed 62 10 c0       	push   $0xc01062ed
c0103b07:	68 18 02 00 00       	push   $0x218
c0103b0c:	68 c8 62 10 c0       	push   $0xc01062c8
c0103b11:	e8 c3 c8 ff ff       	call   c01003d9 <__panic>

static void
check_boot_pgdir(void) {
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
c0103b16:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
c0103b1d:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0103b20:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103b25:	39 c2                	cmp    %eax,%edx
c0103b27:	0f 82 4d ff ff ff    	jb     c0103a7a <check_boot_pgdir+0x12>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }

    assert(PDE_ADDR(boot_pgdir[PDX(VPT)]) == PADDR(boot_pgdir));
c0103b2d:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103b32:	05 ac 0f 00 00       	add    $0xfac,%eax
c0103b37:	8b 00                	mov    (%eax),%eax
c0103b39:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103b3e:	89 c2                	mov    %eax,%edx
c0103b40:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103b45:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103b48:	81 7d e4 ff ff ff bf 	cmpl   $0xbfffffff,-0x1c(%ebp)
c0103b4f:	77 17                	ja     c0103b68 <check_boot_pgdir+0x100>
c0103b51:	ff 75 e4             	pushl  -0x1c(%ebp)
c0103b54:	68 a4 62 10 c0       	push   $0xc01062a4
c0103b59:	68 1b 02 00 00       	push   $0x21b
c0103b5e:	68 c8 62 10 c0       	push   $0xc01062c8
c0103b63:	e8 71 c8 ff ff       	call   c01003d9 <__panic>
c0103b68:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103b6b:	05 00 00 00 40       	add    $0x40000000,%eax
c0103b70:	39 c2                	cmp    %eax,%edx
c0103b72:	74 19                	je     c0103b8d <check_boot_pgdir+0x125>
c0103b74:	68 2c 66 10 c0       	push   $0xc010662c
c0103b79:	68 ed 62 10 c0       	push   $0xc01062ed
c0103b7e:	68 1b 02 00 00       	push   $0x21b
c0103b83:	68 c8 62 10 c0       	push   $0xc01062c8
c0103b88:	e8 4c c8 ff ff       	call   c01003d9 <__panic>

    assert(boot_pgdir[0] == 0);
c0103b8d:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103b92:	8b 00                	mov    (%eax),%eax
c0103b94:	85 c0                	test   %eax,%eax
c0103b96:	74 19                	je     c0103bb1 <check_boot_pgdir+0x149>
c0103b98:	68 60 66 10 c0       	push   $0xc0106660
c0103b9d:	68 ed 62 10 c0       	push   $0xc01062ed
c0103ba2:	68 1d 02 00 00       	push   $0x21d
c0103ba7:	68 c8 62 10 c0       	push   $0xc01062c8
c0103bac:	e8 28 c8 ff ff       	call   c01003d9 <__panic>

    struct Page *p;
    p = alloc_page();
c0103bb1:	83 ec 0c             	sub    $0xc,%esp
c0103bb4:	6a 01                	push   $0x1
c0103bb6:	e8 c1 ef ff ff       	call   c0102b7c <alloc_pages>
c0103bbb:	83 c4 10             	add    $0x10,%esp
c0103bbe:	89 45 e0             	mov    %eax,-0x20(%ebp)
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W) == 0);
c0103bc1:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103bc6:	6a 02                	push   $0x2
c0103bc8:	68 00 01 00 00       	push   $0x100
c0103bcd:	ff 75 e0             	pushl  -0x20(%ebp)
c0103bd0:	50                   	push   %eax
c0103bd1:	e8 00 f8 ff ff       	call   c01033d6 <page_insert>
c0103bd6:	83 c4 10             	add    $0x10,%esp
c0103bd9:	85 c0                	test   %eax,%eax
c0103bdb:	74 19                	je     c0103bf6 <check_boot_pgdir+0x18e>
c0103bdd:	68 74 66 10 c0       	push   $0xc0106674
c0103be2:	68 ed 62 10 c0       	push   $0xc01062ed
c0103be7:	68 21 02 00 00       	push   $0x221
c0103bec:	68 c8 62 10 c0       	push   $0xc01062c8
c0103bf1:	e8 e3 c7 ff ff       	call   c01003d9 <__panic>
    assert(page_ref(p) == 1);
c0103bf6:	83 ec 0c             	sub    $0xc,%esp
c0103bf9:	ff 75 e0             	pushl  -0x20(%ebp)
c0103bfc:	e8 6d ed ff ff       	call   c010296e <page_ref>
c0103c01:	83 c4 10             	add    $0x10,%esp
c0103c04:	83 f8 01             	cmp    $0x1,%eax
c0103c07:	74 19                	je     c0103c22 <check_boot_pgdir+0x1ba>
c0103c09:	68 a2 66 10 c0       	push   $0xc01066a2
c0103c0e:	68 ed 62 10 c0       	push   $0xc01062ed
c0103c13:	68 22 02 00 00       	push   $0x222
c0103c18:	68 c8 62 10 c0       	push   $0xc01062c8
c0103c1d:	e8 b7 c7 ff ff       	call   c01003d9 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W) == 0);
c0103c22:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103c27:	6a 02                	push   $0x2
c0103c29:	68 00 11 00 00       	push   $0x1100
c0103c2e:	ff 75 e0             	pushl  -0x20(%ebp)
c0103c31:	50                   	push   %eax
c0103c32:	e8 9f f7 ff ff       	call   c01033d6 <page_insert>
c0103c37:	83 c4 10             	add    $0x10,%esp
c0103c3a:	85 c0                	test   %eax,%eax
c0103c3c:	74 19                	je     c0103c57 <check_boot_pgdir+0x1ef>
c0103c3e:	68 b4 66 10 c0       	push   $0xc01066b4
c0103c43:	68 ed 62 10 c0       	push   $0xc01062ed
c0103c48:	68 23 02 00 00       	push   $0x223
c0103c4d:	68 c8 62 10 c0       	push   $0xc01062c8
c0103c52:	e8 82 c7 ff ff       	call   c01003d9 <__panic>
    assert(page_ref(p) == 2);
c0103c57:	83 ec 0c             	sub    $0xc,%esp
c0103c5a:	ff 75 e0             	pushl  -0x20(%ebp)
c0103c5d:	e8 0c ed ff ff       	call   c010296e <page_ref>
c0103c62:	83 c4 10             	add    $0x10,%esp
c0103c65:	83 f8 02             	cmp    $0x2,%eax
c0103c68:	74 19                	je     c0103c83 <check_boot_pgdir+0x21b>
c0103c6a:	68 eb 66 10 c0       	push   $0xc01066eb
c0103c6f:	68 ed 62 10 c0       	push   $0xc01062ed
c0103c74:	68 24 02 00 00       	push   $0x224
c0103c79:	68 c8 62 10 c0       	push   $0xc01062c8
c0103c7e:	e8 56 c7 ff ff       	call   c01003d9 <__panic>

    const char *str = "ucore: Hello world!!";
c0103c83:	c7 45 dc fc 66 10 c0 	movl   $0xc01066fc,-0x24(%ebp)
    strcpy((void *)0x100, str);
c0103c8a:	83 ec 08             	sub    $0x8,%esp
c0103c8d:	ff 75 dc             	pushl  -0x24(%ebp)
c0103c90:	68 00 01 00 00       	push   $0x100
c0103c95:	e8 80 13 00 00       	call   c010501a <strcpy>
c0103c9a:	83 c4 10             	add    $0x10,%esp
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
c0103c9d:	83 ec 08             	sub    $0x8,%esp
c0103ca0:	68 00 11 00 00       	push   $0x1100
c0103ca5:	68 00 01 00 00       	push   $0x100
c0103caa:	e8 e5 13 00 00       	call   c0105094 <strcmp>
c0103caf:	83 c4 10             	add    $0x10,%esp
c0103cb2:	85 c0                	test   %eax,%eax
c0103cb4:	74 19                	je     c0103ccf <check_boot_pgdir+0x267>
c0103cb6:	68 14 67 10 c0       	push   $0xc0106714
c0103cbb:	68 ed 62 10 c0       	push   $0xc01062ed
c0103cc0:	68 28 02 00 00       	push   $0x228
c0103cc5:	68 c8 62 10 c0       	push   $0xc01062c8
c0103cca:	e8 0a c7 ff ff       	call   c01003d9 <__panic>

    *(char *)(page2kva(p) + 0x100) = '\0';
c0103ccf:	83 ec 0c             	sub    $0xc,%esp
c0103cd2:	ff 75 e0             	pushl  -0x20(%ebp)
c0103cd5:	e8 f9 eb ff ff       	call   c01028d3 <page2kva>
c0103cda:	83 c4 10             	add    $0x10,%esp
c0103cdd:	05 00 01 00 00       	add    $0x100,%eax
c0103ce2:	c6 00 00             	movb   $0x0,(%eax)
    assert(strlen((const char *)0x100) == 0);
c0103ce5:	83 ec 0c             	sub    $0xc,%esp
c0103ce8:	68 00 01 00 00       	push   $0x100
c0103ced:	e8 d0 12 00 00       	call   c0104fc2 <strlen>
c0103cf2:	83 c4 10             	add    $0x10,%esp
c0103cf5:	85 c0                	test   %eax,%eax
c0103cf7:	74 19                	je     c0103d12 <check_boot_pgdir+0x2aa>
c0103cf9:	68 4c 67 10 c0       	push   $0xc010674c
c0103cfe:	68 ed 62 10 c0       	push   $0xc01062ed
c0103d03:	68 2b 02 00 00       	push   $0x22b
c0103d08:	68 c8 62 10 c0       	push   $0xc01062c8
c0103d0d:	e8 c7 c6 ff ff       	call   c01003d9 <__panic>

    free_page(p);
c0103d12:	83 ec 08             	sub    $0x8,%esp
c0103d15:	6a 01                	push   $0x1
c0103d17:	ff 75 e0             	pushl  -0x20(%ebp)
c0103d1a:	e8 9b ee ff ff       	call   c0102bba <free_pages>
c0103d1f:	83 c4 10             	add    $0x10,%esp
    free_page(pde2page(boot_pgdir[0]));
c0103d22:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103d27:	8b 00                	mov    (%eax),%eax
c0103d29:	83 ec 0c             	sub    $0xc,%esp
c0103d2c:	50                   	push   %eax
c0103d2d:	e8 20 ec ff ff       	call   c0102952 <pde2page>
c0103d32:	83 c4 10             	add    $0x10,%esp
c0103d35:	83 ec 08             	sub    $0x8,%esp
c0103d38:	6a 01                	push   $0x1
c0103d3a:	50                   	push   %eax
c0103d3b:	e8 7a ee ff ff       	call   c0102bba <free_pages>
c0103d40:	83 c4 10             	add    $0x10,%esp
    boot_pgdir[0] = 0;
c0103d43:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103d48:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_boot_pgdir() succeeded!\n");
c0103d4e:	83 ec 0c             	sub    $0xc,%esp
c0103d51:	68 70 67 10 c0       	push   $0xc0106770
c0103d56:	e8 18 c5 ff ff       	call   c0100273 <cprintf>
c0103d5b:	83 c4 10             	add    $0x10,%esp
}
c0103d5e:	90                   	nop
c0103d5f:	c9                   	leave  
c0103d60:	c3                   	ret    

c0103d61 <perm2str>:

//perm2str - use string 'u,r,w,-' to present the permission
static const char *
perm2str(int perm) {
c0103d61:	55                   	push   %ebp
c0103d62:	89 e5                	mov    %esp,%ebp
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
c0103d64:	8b 45 08             	mov    0x8(%ebp),%eax
c0103d67:	83 e0 04             	and    $0x4,%eax
c0103d6a:	85 c0                	test   %eax,%eax
c0103d6c:	74 07                	je     c0103d75 <perm2str+0x14>
c0103d6e:	b8 75 00 00 00       	mov    $0x75,%eax
c0103d73:	eb 05                	jmp    c0103d7a <perm2str+0x19>
c0103d75:	b8 2d 00 00 00       	mov    $0x2d,%eax
c0103d7a:	a2 08 af 11 c0       	mov    %al,0xc011af08
    str[1] = 'r';
c0103d7f:	c6 05 09 af 11 c0 72 	movb   $0x72,0xc011af09
    str[2] = (perm & PTE_W) ? 'w' : '-';
c0103d86:	8b 45 08             	mov    0x8(%ebp),%eax
c0103d89:	83 e0 02             	and    $0x2,%eax
c0103d8c:	85 c0                	test   %eax,%eax
c0103d8e:	74 07                	je     c0103d97 <perm2str+0x36>
c0103d90:	b8 77 00 00 00       	mov    $0x77,%eax
c0103d95:	eb 05                	jmp    c0103d9c <perm2str+0x3b>
c0103d97:	b8 2d 00 00 00       	mov    $0x2d,%eax
c0103d9c:	a2 0a af 11 c0       	mov    %al,0xc011af0a
    str[3] = '\0';
c0103da1:	c6 05 0b af 11 c0 00 	movb   $0x0,0xc011af0b
    return str;
c0103da8:	b8 08 af 11 c0       	mov    $0xc011af08,%eax
}
c0103dad:	5d                   	pop    %ebp
c0103dae:	c3                   	ret    

c0103daf <get_pgtable_items>:
//  table:       the beginning addr of table
//  left_store:  the pointer of the high side of table's next range
//  right_store: the pointer of the low side of table's next range
// return value: 0 - not a invalid item range, perm - a valid item range with perm permission 
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
c0103daf:	55                   	push   %ebp
c0103db0:	89 e5                	mov    %esp,%ebp
c0103db2:	83 ec 10             	sub    $0x10,%esp
    if (start >= right) {
c0103db5:	8b 45 10             	mov    0x10(%ebp),%eax
c0103db8:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103dbb:	72 0e                	jb     c0103dcb <get_pgtable_items+0x1c>
        return 0;
c0103dbd:	b8 00 00 00 00       	mov    $0x0,%eax
c0103dc2:	e9 9a 00 00 00       	jmp    c0103e61 <get_pgtable_items+0xb2>
    }
    while (start < right && !(table[start] & PTE_P)) {
        start ++;
c0103dc7:	83 45 10 01          	addl   $0x1,0x10(%ebp)
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
    if (start >= right) {
        return 0;
    }
    while (start < right && !(table[start] & PTE_P)) {
c0103dcb:	8b 45 10             	mov    0x10(%ebp),%eax
c0103dce:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103dd1:	73 18                	jae    c0103deb <get_pgtable_items+0x3c>
c0103dd3:	8b 45 10             	mov    0x10(%ebp),%eax
c0103dd6:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103ddd:	8b 45 14             	mov    0x14(%ebp),%eax
c0103de0:	01 d0                	add    %edx,%eax
c0103de2:	8b 00                	mov    (%eax),%eax
c0103de4:	83 e0 01             	and    $0x1,%eax
c0103de7:	85 c0                	test   %eax,%eax
c0103de9:	74 dc                	je     c0103dc7 <get_pgtable_items+0x18>
        start ++;
    }
    if (start < right) {
c0103deb:	8b 45 10             	mov    0x10(%ebp),%eax
c0103dee:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103df1:	73 69                	jae    c0103e5c <get_pgtable_items+0xad>
        if (left_store != NULL) {
c0103df3:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
c0103df7:	74 08                	je     c0103e01 <get_pgtable_items+0x52>
            *left_store = start;
c0103df9:	8b 45 18             	mov    0x18(%ebp),%eax
c0103dfc:	8b 55 10             	mov    0x10(%ebp),%edx
c0103dff:	89 10                	mov    %edx,(%eax)
        }
        int perm = (table[start ++] & PTE_USER);
c0103e01:	8b 45 10             	mov    0x10(%ebp),%eax
c0103e04:	8d 50 01             	lea    0x1(%eax),%edx
c0103e07:	89 55 10             	mov    %edx,0x10(%ebp)
c0103e0a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103e11:	8b 45 14             	mov    0x14(%ebp),%eax
c0103e14:	01 d0                	add    %edx,%eax
c0103e16:	8b 00                	mov    (%eax),%eax
c0103e18:	83 e0 07             	and    $0x7,%eax
c0103e1b:	89 45 fc             	mov    %eax,-0x4(%ebp)
        while (start < right && (table[start] & PTE_USER) == perm) {
c0103e1e:	eb 04                	jmp    c0103e24 <get_pgtable_items+0x75>
            start ++;
c0103e20:	83 45 10 01          	addl   $0x1,0x10(%ebp)
    if (start < right) {
        if (left_store != NULL) {
            *left_store = start;
        }
        int perm = (table[start ++] & PTE_USER);
        while (start < right && (table[start] & PTE_USER) == perm) {
c0103e24:	8b 45 10             	mov    0x10(%ebp),%eax
c0103e27:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103e2a:	73 1d                	jae    c0103e49 <get_pgtable_items+0x9a>
c0103e2c:	8b 45 10             	mov    0x10(%ebp),%eax
c0103e2f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103e36:	8b 45 14             	mov    0x14(%ebp),%eax
c0103e39:	01 d0                	add    %edx,%eax
c0103e3b:	8b 00                	mov    (%eax),%eax
c0103e3d:	83 e0 07             	and    $0x7,%eax
c0103e40:	89 c2                	mov    %eax,%edx
c0103e42:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103e45:	39 c2                	cmp    %eax,%edx
c0103e47:	74 d7                	je     c0103e20 <get_pgtable_items+0x71>
            start ++;
        }
        if (right_store != NULL) {
c0103e49:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
c0103e4d:	74 08                	je     c0103e57 <get_pgtable_items+0xa8>
            *right_store = start;
c0103e4f:	8b 45 1c             	mov    0x1c(%ebp),%eax
c0103e52:	8b 55 10             	mov    0x10(%ebp),%edx
c0103e55:	89 10                	mov    %edx,(%eax)
        }
        return perm;
c0103e57:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103e5a:	eb 05                	jmp    c0103e61 <get_pgtable_items+0xb2>
    }
    return 0;
c0103e5c:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0103e61:	c9                   	leave  
c0103e62:	c3                   	ret    

c0103e63 <print_pgdir>:

//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
c0103e63:	55                   	push   %ebp
c0103e64:	89 e5                	mov    %esp,%ebp
c0103e66:	57                   	push   %edi
c0103e67:	56                   	push   %esi
c0103e68:	53                   	push   %ebx
c0103e69:	83 ec 2c             	sub    $0x2c,%esp
    cprintf("-------------------- BEGIN --------------------\n");
c0103e6c:	83 ec 0c             	sub    $0xc,%esp
c0103e6f:	68 90 67 10 c0       	push   $0xc0106790
c0103e74:	e8 fa c3 ff ff       	call   c0100273 <cprintf>
c0103e79:	83 c4 10             	add    $0x10,%esp
    size_t left, right = 0, perm;
c0103e7c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
c0103e83:	e9 e5 00 00 00       	jmp    c0103f6d <print_pgdir+0x10a>
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
c0103e88:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103e8b:	83 ec 0c             	sub    $0xc,%esp
c0103e8e:	50                   	push   %eax
c0103e8f:	e8 cd fe ff ff       	call   c0103d61 <perm2str>
c0103e94:	83 c4 10             	add    $0x10,%esp
c0103e97:	89 c7                	mov    %eax,%edi
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
c0103e99:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0103e9c:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103e9f:	29 c2                	sub    %eax,%edx
c0103ea1:	89 d0                	mov    %edx,%eax
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
c0103ea3:	c1 e0 16             	shl    $0x16,%eax
c0103ea6:	89 c3                	mov    %eax,%ebx
c0103ea8:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0103eab:	c1 e0 16             	shl    $0x16,%eax
c0103eae:	89 c1                	mov    %eax,%ecx
c0103eb0:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103eb3:	c1 e0 16             	shl    $0x16,%eax
c0103eb6:	89 c2                	mov    %eax,%edx
c0103eb8:	8b 75 dc             	mov    -0x24(%ebp),%esi
c0103ebb:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103ebe:	29 c6                	sub    %eax,%esi
c0103ec0:	89 f0                	mov    %esi,%eax
c0103ec2:	83 ec 08             	sub    $0x8,%esp
c0103ec5:	57                   	push   %edi
c0103ec6:	53                   	push   %ebx
c0103ec7:	51                   	push   %ecx
c0103ec8:	52                   	push   %edx
c0103ec9:	50                   	push   %eax
c0103eca:	68 c1 67 10 c0       	push   $0xc01067c1
c0103ecf:	e8 9f c3 ff ff       	call   c0100273 <cprintf>
c0103ed4:	83 c4 20             	add    $0x20,%esp
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
c0103ed7:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103eda:	c1 e0 0a             	shl    $0xa,%eax
c0103edd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
c0103ee0:	eb 4f                	jmp    c0103f31 <print_pgdir+0xce>
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
c0103ee2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103ee5:	83 ec 0c             	sub    $0xc,%esp
c0103ee8:	50                   	push   %eax
c0103ee9:	e8 73 fe ff ff       	call   c0103d61 <perm2str>
c0103eee:	83 c4 10             	add    $0x10,%esp
c0103ef1:	89 c7                	mov    %eax,%edi
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
c0103ef3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0103ef6:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0103ef9:	29 c2                	sub    %eax,%edx
c0103efb:	89 d0                	mov    %edx,%eax
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
c0103efd:	c1 e0 0c             	shl    $0xc,%eax
c0103f00:	89 c3                	mov    %eax,%ebx
c0103f02:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0103f05:	c1 e0 0c             	shl    $0xc,%eax
c0103f08:	89 c1                	mov    %eax,%ecx
c0103f0a:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0103f0d:	c1 e0 0c             	shl    $0xc,%eax
c0103f10:	89 c2                	mov    %eax,%edx
c0103f12:	8b 75 d4             	mov    -0x2c(%ebp),%esi
c0103f15:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0103f18:	29 c6                	sub    %eax,%esi
c0103f1a:	89 f0                	mov    %esi,%eax
c0103f1c:	83 ec 08             	sub    $0x8,%esp
c0103f1f:	57                   	push   %edi
c0103f20:	53                   	push   %ebx
c0103f21:	51                   	push   %ecx
c0103f22:	52                   	push   %edx
c0103f23:	50                   	push   %eax
c0103f24:	68 e0 67 10 c0       	push   $0xc01067e0
c0103f29:	e8 45 c3 ff ff       	call   c0100273 <cprintf>
c0103f2e:	83 c4 20             	add    $0x20,%esp
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
c0103f31:	be 00 00 c0 fa       	mov    $0xfac00000,%esi
c0103f36:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0103f39:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0103f3c:	89 d3                	mov    %edx,%ebx
c0103f3e:	c1 e3 0a             	shl    $0xa,%ebx
c0103f41:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0103f44:	89 d1                	mov    %edx,%ecx
c0103f46:	c1 e1 0a             	shl    $0xa,%ecx
c0103f49:	83 ec 08             	sub    $0x8,%esp
c0103f4c:	8d 55 d4             	lea    -0x2c(%ebp),%edx
c0103f4f:	52                   	push   %edx
c0103f50:	8d 55 d8             	lea    -0x28(%ebp),%edx
c0103f53:	52                   	push   %edx
c0103f54:	56                   	push   %esi
c0103f55:	50                   	push   %eax
c0103f56:	53                   	push   %ebx
c0103f57:	51                   	push   %ecx
c0103f58:	e8 52 fe ff ff       	call   c0103daf <get_pgtable_items>
c0103f5d:	83 c4 20             	add    $0x20,%esp
c0103f60:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103f63:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0103f67:	0f 85 75 ff ff ff    	jne    c0103ee2 <print_pgdir+0x7f>
//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
c0103f6d:	b9 00 b0 fe fa       	mov    $0xfafeb000,%ecx
c0103f72:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0103f75:	83 ec 08             	sub    $0x8,%esp
c0103f78:	8d 55 dc             	lea    -0x24(%ebp),%edx
c0103f7b:	52                   	push   %edx
c0103f7c:	8d 55 e0             	lea    -0x20(%ebp),%edx
c0103f7f:	52                   	push   %edx
c0103f80:	51                   	push   %ecx
c0103f81:	50                   	push   %eax
c0103f82:	68 00 04 00 00       	push   $0x400
c0103f87:	6a 00                	push   $0x0
c0103f89:	e8 21 fe ff ff       	call   c0103daf <get_pgtable_items>
c0103f8e:	83 c4 20             	add    $0x20,%esp
c0103f91:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103f94:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0103f98:	0f 85 ea fe ff ff    	jne    c0103e88 <print_pgdir+0x25>
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
        }
    }
    cprintf("--------------------- END ---------------------\n");
c0103f9e:	83 ec 0c             	sub    $0xc,%esp
c0103fa1:	68 04 68 10 c0       	push   $0xc0106804
c0103fa6:	e8 c8 c2 ff ff       	call   c0100273 <cprintf>
c0103fab:	83 c4 10             	add    $0x10,%esp
}
c0103fae:	90                   	nop
c0103faf:	8d 65 f4             	lea    -0xc(%ebp),%esp
c0103fb2:	5b                   	pop    %ebx
c0103fb3:	5e                   	pop    %esi
c0103fb4:	5f                   	pop    %edi
c0103fb5:	5d                   	pop    %ebp
c0103fb6:	c3                   	ret    

c0103fb7 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
c0103fb7:	55                   	push   %ebp
c0103fb8:	89 e5                	mov    %esp,%ebp
    return page - pages;
c0103fba:	8b 45 08             	mov    0x8(%ebp),%eax
c0103fbd:	8b 15 18 af 11 c0    	mov    0xc011af18,%edx
c0103fc3:	29 d0                	sub    %edx,%eax
c0103fc5:	c1 f8 02             	sar    $0x2,%eax
c0103fc8:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
c0103fce:	5d                   	pop    %ebp
c0103fcf:	c3                   	ret    

c0103fd0 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
c0103fd0:	55                   	push   %ebp
c0103fd1:	89 e5                	mov    %esp,%ebp
    return page2ppn(page) << PGSHIFT;
c0103fd3:	ff 75 08             	pushl  0x8(%ebp)
c0103fd6:	e8 dc ff ff ff       	call   c0103fb7 <page2ppn>
c0103fdb:	83 c4 04             	add    $0x4,%esp
c0103fde:	c1 e0 0c             	shl    $0xc,%eax
}
c0103fe1:	c9                   	leave  
c0103fe2:	c3                   	ret    

c0103fe3 <page_ref>:
pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
}

static inline int
page_ref(struct Page *page) {
c0103fe3:	55                   	push   %ebp
c0103fe4:	89 e5                	mov    %esp,%ebp
    return page->ref;
c0103fe6:	8b 45 08             	mov    0x8(%ebp),%eax
c0103fe9:	8b 00                	mov    (%eax),%eax
}
c0103feb:	5d                   	pop    %ebp
c0103fec:	c3                   	ret    

c0103fed <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
c0103fed:	55                   	push   %ebp
c0103fee:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c0103ff0:	8b 45 08             	mov    0x8(%ebp),%eax
c0103ff3:	8b 55 0c             	mov    0xc(%ebp),%edx
c0103ff6:	89 10                	mov    %edx,(%eax)
}
c0103ff8:	90                   	nop
c0103ff9:	5d                   	pop    %ebp
c0103ffa:	c3                   	ret    

c0103ffb <default_init>:

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
c0103ffb:	55                   	push   %ebp
c0103ffc:	89 e5                	mov    %esp,%ebp
c0103ffe:	83 ec 10             	sub    $0x10,%esp
c0104001:	c7 45 fc 1c af 11 c0 	movl   $0xc011af1c,-0x4(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c0104008:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010400b:	8b 55 fc             	mov    -0x4(%ebp),%edx
c010400e:	89 50 04             	mov    %edx,0x4(%eax)
c0104011:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0104014:	8b 50 04             	mov    0x4(%eax),%edx
c0104017:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010401a:	89 10                	mov    %edx,(%eax)
    list_init(&free_list);
    nr_free = 0;
c010401c:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c0104023:	00 00 00 
}
c0104026:	90                   	nop
c0104027:	c9                   	leave  
c0104028:	c3                   	ret    

c0104029 <default_init_memmap>:

static void
default_init_memmap(struct Page *base, size_t n) {
c0104029:	55                   	push   %ebp
c010402a:	89 e5                	mov    %esp,%ebp
c010402c:	83 ec 38             	sub    $0x38,%esp
    assert(n > 0);
c010402f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0104033:	75 16                	jne    c010404b <default_init_memmap+0x22>
c0104035:	68 38 68 10 c0       	push   $0xc0106838
c010403a:	68 3e 68 10 c0       	push   $0xc010683e
c010403f:	6a 6d                	push   $0x6d
c0104041:	68 53 68 10 c0       	push   $0xc0106853
c0104046:	e8 8e c3 ff ff       	call   c01003d9 <__panic>
    struct Page *p = base;
c010404b:	8b 45 08             	mov    0x8(%ebp),%eax
c010404e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
c0104051:	eb 6c                	jmp    c01040bf <default_init_memmap+0x96>
        assert(PageReserved(p));
c0104053:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104056:	83 c0 04             	add    $0x4,%eax
c0104059:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
c0104060:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104063:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104066:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0104069:	0f a3 10             	bt     %edx,(%eax)
c010406c:	19 c0                	sbb    %eax,%eax
c010406e:	89 45 e0             	mov    %eax,-0x20(%ebp)
    return oldbit != 0;
c0104071:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c0104075:	0f 95 c0             	setne  %al
c0104078:	0f b6 c0             	movzbl %al,%eax
c010407b:	85 c0                	test   %eax,%eax
c010407d:	75 16                	jne    c0104095 <default_init_memmap+0x6c>
c010407f:	68 69 68 10 c0       	push   $0xc0106869
c0104084:	68 3e 68 10 c0       	push   $0xc010683e
c0104089:	6a 70                	push   $0x70
c010408b:	68 53 68 10 c0       	push   $0xc0106853
c0104090:	e8 44 c3 ff ff       	call   c01003d9 <__panic>
        p->flags = p->property = 0;
c0104095:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104098:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
c010409f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01040a2:	8b 50 08             	mov    0x8(%eax),%edx
c01040a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01040a8:	89 50 04             	mov    %edx,0x4(%eax)
        set_page_ref(p, 0);
c01040ab:	83 ec 08             	sub    $0x8,%esp
c01040ae:	6a 00                	push   $0x0
c01040b0:	ff 75 f4             	pushl  -0xc(%ebp)
c01040b3:	e8 35 ff ff ff       	call   c0103fed <set_page_ref>
c01040b8:	83 c4 10             	add    $0x10,%esp

static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
c01040bb:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
c01040bf:	8b 55 0c             	mov    0xc(%ebp),%edx
c01040c2:	89 d0                	mov    %edx,%eax
c01040c4:	c1 e0 02             	shl    $0x2,%eax
c01040c7:	01 d0                	add    %edx,%eax
c01040c9:	c1 e0 02             	shl    $0x2,%eax
c01040cc:	89 c2                	mov    %eax,%edx
c01040ce:	8b 45 08             	mov    0x8(%ebp),%eax
c01040d1:	01 d0                	add    %edx,%eax
c01040d3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01040d6:	0f 85 77 ff ff ff    	jne    c0104053 <default_init_memmap+0x2a>
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
c01040dc:	8b 45 08             	mov    0x8(%ebp),%eax
c01040df:	8b 55 0c             	mov    0xc(%ebp),%edx
c01040e2:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
c01040e5:	8b 45 08             	mov    0x8(%ebp),%eax
c01040e8:	83 c0 04             	add    $0x4,%eax
c01040eb:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
c01040f2:	89 45 cc             	mov    %eax,-0x34(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c01040f5:	8b 45 cc             	mov    -0x34(%ebp),%eax
c01040f8:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01040fb:	0f ab 10             	bts    %edx,(%eax)
    nr_free += n;
c01040fe:	8b 15 24 af 11 c0    	mov    0xc011af24,%edx
c0104104:	8b 45 0c             	mov    0xc(%ebp),%eax
c0104107:	01 d0                	add    %edx,%eax
c0104109:	a3 24 af 11 c0       	mov    %eax,0xc011af24
    list_add_before(&free_list, &(base->page_link));
c010410e:	8b 45 08             	mov    0x8(%ebp),%eax
c0104111:	83 c0 0c             	add    $0xc,%eax
c0104114:	c7 45 f0 1c af 11 c0 	movl   $0xc011af1c,-0x10(%ebp)
c010411b:	89 45 dc             	mov    %eax,-0x24(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
c010411e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104121:	8b 00                	mov    (%eax),%eax
c0104123:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0104126:	89 55 d8             	mov    %edx,-0x28(%ebp)
c0104129:	89 45 d4             	mov    %eax,-0x2c(%ebp)
c010412c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010412f:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c0104132:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104135:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0104138:	89 10                	mov    %edx,(%eax)
c010413a:	8b 45 d0             	mov    -0x30(%ebp),%eax
c010413d:	8b 10                	mov    (%eax),%edx
c010413f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0104142:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c0104145:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104148:	8b 55 d0             	mov    -0x30(%ebp),%edx
c010414b:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c010414e:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104151:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104154:	89 10                	mov    %edx,(%eax)
}
c0104156:	90                   	nop
c0104157:	c9                   	leave  
c0104158:	c3                   	ret    

c0104159 <default_alloc_pages>:

static struct Page *
default_alloc_pages(size_t n) {
c0104159:	55                   	push   %ebp
c010415a:	89 e5                	mov    %esp,%ebp
c010415c:	83 ec 58             	sub    $0x58,%esp
    assert(n > 0);
c010415f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0104163:	75 16                	jne    c010417b <default_alloc_pages+0x22>
c0104165:	68 38 68 10 c0       	push   $0xc0106838
c010416a:	68 3e 68 10 c0       	push   $0xc010683e
c010416f:	6a 7c                	push   $0x7c
c0104171:	68 53 68 10 c0       	push   $0xc0106853
c0104176:	e8 5e c2 ff ff       	call   c01003d9 <__panic>
    if (n > nr_free) {
c010417b:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104180:	3b 45 08             	cmp    0x8(%ebp),%eax
c0104183:	73 0a                	jae    c010418f <default_alloc_pages+0x36>
        return NULL;
c0104185:	b8 00 00 00 00       	mov    $0x0,%eax
c010418a:	e9 3d 01 00 00       	jmp    c01042cc <default_alloc_pages+0x173>
    }
    struct Page *page = NULL;
c010418f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    list_entry_t *le = &free_list;
c0104196:	c7 45 f0 1c af 11 c0 	movl   $0xc011af1c,-0x10(%ebp)
    // TODO: optimize (next-fit)
    while ((le = list_next(le)) != &free_list) {
c010419d:	eb 1c                	jmp    c01041bb <default_alloc_pages+0x62>
        struct Page *p = le2page(le, page_link);
c010419f:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01041a2:	83 e8 0c             	sub    $0xc,%eax
c01041a5:	89 45 e8             	mov    %eax,-0x18(%ebp)
        if (p->property >= n) {
c01041a8:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01041ab:	8b 40 08             	mov    0x8(%eax),%eax
c01041ae:	3b 45 08             	cmp    0x8(%ebp),%eax
c01041b1:	72 08                	jb     c01041bb <default_alloc_pages+0x62>
            page = p;
c01041b3:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01041b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
            break;
c01041b9:	eb 18                	jmp    c01041d3 <default_alloc_pages+0x7a>
c01041bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01041be:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c01041c1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01041c4:	8b 40 04             	mov    0x4(%eax),%eax
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    // TODO: optimize (next-fit)
    while ((le = list_next(le)) != &free_list) {
c01041c7:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01041ca:	81 7d f0 1c af 11 c0 	cmpl   $0xc011af1c,-0x10(%ebp)
c01041d1:	75 cc                	jne    c010419f <default_alloc_pages+0x46>
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
c01041d3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01041d7:	0f 84 ec 00 00 00    	je     c01042c9 <default_alloc_pages+0x170>
        if (page->property > n) {
c01041dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01041e0:	8b 40 08             	mov    0x8(%eax),%eax
c01041e3:	3b 45 08             	cmp    0x8(%ebp),%eax
c01041e6:	0f 86 8c 00 00 00    	jbe    c0104278 <default_alloc_pages+0x11f>
            struct Page *p = page + n;
c01041ec:	8b 55 08             	mov    0x8(%ebp),%edx
c01041ef:	89 d0                	mov    %edx,%eax
c01041f1:	c1 e0 02             	shl    $0x2,%eax
c01041f4:	01 d0                	add    %edx,%eax
c01041f6:	c1 e0 02             	shl    $0x2,%eax
c01041f9:	89 c2                	mov    %eax,%edx
c01041fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01041fe:	01 d0                	add    %edx,%eax
c0104200:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            p->property = page->property - n;
c0104203:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104206:	8b 40 08             	mov    0x8(%eax),%eax
c0104209:	2b 45 08             	sub    0x8(%ebp),%eax
c010420c:	89 c2                	mov    %eax,%edx
c010420e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104211:	89 50 08             	mov    %edx,0x8(%eax)
            SetPageProperty(p);
c0104214:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104217:	83 c0 04             	add    $0x4,%eax
c010421a:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
c0104221:	89 45 c0             	mov    %eax,-0x40(%ebp)
c0104224:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0104227:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010422a:	0f ab 10             	bts    %edx,(%eax)
            list_add_after(&(page->page_link), &(p->page_link));
c010422d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104230:	83 c0 0c             	add    $0xc,%eax
c0104233:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0104236:	83 c2 0c             	add    $0xc,%edx
c0104239:	89 55 ec             	mov    %edx,-0x14(%ebp)
c010423c:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
c010423f:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104242:	8b 40 04             	mov    0x4(%eax),%eax
c0104245:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0104248:	89 55 cc             	mov    %edx,-0x34(%ebp)
c010424b:	8b 55 ec             	mov    -0x14(%ebp),%edx
c010424e:	89 55 c8             	mov    %edx,-0x38(%ebp)
c0104251:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c0104254:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104257:	8b 55 cc             	mov    -0x34(%ebp),%edx
c010425a:	89 10                	mov    %edx,(%eax)
c010425c:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c010425f:	8b 10                	mov    (%eax),%edx
c0104261:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0104264:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c0104267:	8b 45 cc             	mov    -0x34(%ebp),%eax
c010426a:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c010426d:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0104270:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0104273:	8b 55 c8             	mov    -0x38(%ebp),%edx
c0104276:	89 10                	mov    %edx,(%eax)
        }
        list_del(&(page->page_link));
c0104278:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010427b:	83 c0 0c             	add    $0xc,%eax
c010427e:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c0104281:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104284:	8b 40 04             	mov    0x4(%eax),%eax
c0104287:	8b 55 d8             	mov    -0x28(%ebp),%edx
c010428a:	8b 12                	mov    (%edx),%edx
c010428c:	89 55 b8             	mov    %edx,-0x48(%ebp)
c010428f:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c0104292:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0104295:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0104298:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c010429b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c010429e:	8b 55 b8             	mov    -0x48(%ebp),%edx
c01042a1:	89 10                	mov    %edx,(%eax)
        nr_free -= n;
c01042a3:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c01042a8:	2b 45 08             	sub    0x8(%ebp),%eax
c01042ab:	a3 24 af 11 c0       	mov    %eax,0xc011af24
        ClearPageProperty(page);
c01042b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01042b3:	83 c0 04             	add    $0x4,%eax
c01042b6:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
c01042bd:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c01042c0:	8b 45 bc             	mov    -0x44(%ebp),%eax
c01042c3:	8b 55 e0             	mov    -0x20(%ebp),%edx
c01042c6:	0f b3 10             	btr    %edx,(%eax)
    }
    return page;
c01042c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01042cc:	c9                   	leave  
c01042cd:	c3                   	ret    

c01042ce <default_free_pages>:

static void
default_free_pages(struct Page *base, size_t n) {
c01042ce:	55                   	push   %ebp
c01042cf:	89 e5                	mov    %esp,%ebp
c01042d1:	81 ec 88 00 00 00    	sub    $0x88,%esp
    assert(n > 0);
c01042d7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c01042db:	75 19                	jne    c01042f6 <default_free_pages+0x28>
c01042dd:	68 38 68 10 c0       	push   $0xc0106838
c01042e2:	68 3e 68 10 c0       	push   $0xc010683e
c01042e7:	68 9a 00 00 00       	push   $0x9a
c01042ec:	68 53 68 10 c0       	push   $0xc0106853
c01042f1:	e8 e3 c0 ff ff       	call   c01003d9 <__panic>
    struct Page *p = base;
c01042f6:	8b 45 08             	mov    0x8(%ebp),%eax
c01042f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
c01042fc:	e9 8f 00 00 00       	jmp    c0104390 <default_free_pages+0xc2>
        assert(!PageReserved(p) && !PageProperty(p));
c0104301:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104304:	83 c0 04             	add    $0x4,%eax
c0104307:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
c010430e:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104311:	8b 45 bc             	mov    -0x44(%ebp),%eax
c0104314:	8b 55 c0             	mov    -0x40(%ebp),%edx
c0104317:	0f a3 10             	bt     %edx,(%eax)
c010431a:	19 c0                	sbb    %eax,%eax
c010431c:	89 45 b8             	mov    %eax,-0x48(%ebp)
    return oldbit != 0;
c010431f:	83 7d b8 00          	cmpl   $0x0,-0x48(%ebp)
c0104323:	0f 95 c0             	setne  %al
c0104326:	0f b6 c0             	movzbl %al,%eax
c0104329:	85 c0                	test   %eax,%eax
c010432b:	75 2c                	jne    c0104359 <default_free_pages+0x8b>
c010432d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104330:	83 c0 04             	add    $0x4,%eax
c0104333:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
c010433a:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c010433d:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c0104340:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0104343:	0f a3 10             	bt     %edx,(%eax)
c0104346:	19 c0                	sbb    %eax,%eax
c0104348:	89 45 b0             	mov    %eax,-0x50(%ebp)
    return oldbit != 0;
c010434b:	83 7d b0 00          	cmpl   $0x0,-0x50(%ebp)
c010434f:	0f 95 c0             	setne  %al
c0104352:	0f b6 c0             	movzbl %al,%eax
c0104355:	85 c0                	test   %eax,%eax
c0104357:	74 19                	je     c0104372 <default_free_pages+0xa4>
c0104359:	68 7c 68 10 c0       	push   $0xc010687c
c010435e:	68 3e 68 10 c0       	push   $0xc010683e
c0104363:	68 9d 00 00 00       	push   $0x9d
c0104368:	68 53 68 10 c0       	push   $0xc0106853
c010436d:	e8 67 c0 ff ff       	call   c01003d9 <__panic>
        p->flags = 0;
c0104372:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104375:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
        set_page_ref(p, 0);
c010437c:	83 ec 08             	sub    $0x8,%esp
c010437f:	6a 00                	push   $0x0
c0104381:	ff 75 f4             	pushl  -0xc(%ebp)
c0104384:	e8 64 fc ff ff       	call   c0103fed <set_page_ref>
c0104389:	83 c4 10             	add    $0x10,%esp

static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
c010438c:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
c0104390:	8b 55 0c             	mov    0xc(%ebp),%edx
c0104393:	89 d0                	mov    %edx,%eax
c0104395:	c1 e0 02             	shl    $0x2,%eax
c0104398:	01 d0                	add    %edx,%eax
c010439a:	c1 e0 02             	shl    $0x2,%eax
c010439d:	89 c2                	mov    %eax,%edx
c010439f:	8b 45 08             	mov    0x8(%ebp),%eax
c01043a2:	01 d0                	add    %edx,%eax
c01043a4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01043a7:	0f 85 54 ff ff ff    	jne    c0104301 <default_free_pages+0x33>
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
c01043ad:	8b 45 08             	mov    0x8(%ebp),%eax
c01043b0:	8b 55 0c             	mov    0xc(%ebp),%edx
c01043b3:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
c01043b6:	8b 45 08             	mov    0x8(%ebp),%eax
c01043b9:	83 c0 04             	add    $0x4,%eax
c01043bc:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
c01043c3:	89 45 ac             	mov    %eax,-0x54(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c01043c6:	8b 45 ac             	mov    -0x54(%ebp),%eax
c01043c9:	8b 55 e0             	mov    -0x20(%ebp),%edx
c01043cc:	0f ab 10             	bts    %edx,(%eax)
c01043cf:	c7 45 e8 1c af 11 c0 	movl   $0xc011af1c,-0x18(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c01043d6:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01043d9:	8b 40 04             	mov    0x4(%eax),%eax
    list_entry_t *le = list_next(&free_list);
c01043dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
c01043df:	e9 08 01 00 00       	jmp    c01044ec <default_free_pages+0x21e>
        p = le2page(le, page_link);
c01043e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01043e7:	83 e8 0c             	sub    $0xc,%eax
c01043ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01043ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01043f0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01043f3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01043f6:	8b 40 04             	mov    0x4(%eax),%eax
        le = list_next(le);
c01043f9:	89 45 f0             	mov    %eax,-0x10(%ebp)
        // TODO: optimize
        if (base + base->property == p) {
c01043fc:	8b 45 08             	mov    0x8(%ebp),%eax
c01043ff:	8b 50 08             	mov    0x8(%eax),%edx
c0104402:	89 d0                	mov    %edx,%eax
c0104404:	c1 e0 02             	shl    $0x2,%eax
c0104407:	01 d0                	add    %edx,%eax
c0104409:	c1 e0 02             	shl    $0x2,%eax
c010440c:	89 c2                	mov    %eax,%edx
c010440e:	8b 45 08             	mov    0x8(%ebp),%eax
c0104411:	01 d0                	add    %edx,%eax
c0104413:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104416:	75 5a                	jne    c0104472 <default_free_pages+0x1a4>
            base->property += p->property;
c0104418:	8b 45 08             	mov    0x8(%ebp),%eax
c010441b:	8b 50 08             	mov    0x8(%eax),%edx
c010441e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104421:	8b 40 08             	mov    0x8(%eax),%eax
c0104424:	01 c2                	add    %eax,%edx
c0104426:	8b 45 08             	mov    0x8(%ebp),%eax
c0104429:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(p);
c010442c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010442f:	83 c0 04             	add    $0x4,%eax
c0104432:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
c0104439:	89 45 a0             	mov    %eax,-0x60(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c010443c:	8b 45 a0             	mov    -0x60(%ebp),%eax
c010443f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104442:	0f b3 10             	btr    %edx,(%eax)
            list_del(&(p->page_link));
c0104445:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104448:	83 c0 0c             	add    $0xc,%eax
c010444b:	89 45 dc             	mov    %eax,-0x24(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c010444e:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104451:	8b 40 04             	mov    0x4(%eax),%eax
c0104454:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0104457:	8b 12                	mov    (%edx),%edx
c0104459:	89 55 a8             	mov    %edx,-0x58(%ebp)
c010445c:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c010445f:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0104462:	8b 55 a4             	mov    -0x5c(%ebp),%edx
c0104465:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c0104468:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c010446b:	8b 55 a8             	mov    -0x58(%ebp),%edx
c010446e:	89 10                	mov    %edx,(%eax)
c0104470:	eb 7a                	jmp    c01044ec <default_free_pages+0x21e>
        }
        else if (p + p->property == base) {
c0104472:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104475:	8b 50 08             	mov    0x8(%eax),%edx
c0104478:	89 d0                	mov    %edx,%eax
c010447a:	c1 e0 02             	shl    $0x2,%eax
c010447d:	01 d0                	add    %edx,%eax
c010447f:	c1 e0 02             	shl    $0x2,%eax
c0104482:	89 c2                	mov    %eax,%edx
c0104484:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104487:	01 d0                	add    %edx,%eax
c0104489:	3b 45 08             	cmp    0x8(%ebp),%eax
c010448c:	75 5e                	jne    c01044ec <default_free_pages+0x21e>
            p->property += base->property;
c010448e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104491:	8b 50 08             	mov    0x8(%eax),%edx
c0104494:	8b 45 08             	mov    0x8(%ebp),%eax
c0104497:	8b 40 08             	mov    0x8(%eax),%eax
c010449a:	01 c2                	add    %eax,%edx
c010449c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010449f:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(base);
c01044a2:	8b 45 08             	mov    0x8(%ebp),%eax
c01044a5:	83 c0 04             	add    $0x4,%eax
c01044a8:	c7 45 cc 01 00 00 00 	movl   $0x1,-0x34(%ebp)
c01044af:	89 45 94             	mov    %eax,-0x6c(%ebp)
c01044b2:	8b 45 94             	mov    -0x6c(%ebp),%eax
c01044b5:	8b 55 cc             	mov    -0x34(%ebp),%edx
c01044b8:	0f b3 10             	btr    %edx,(%eax)
            base = p;
c01044bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01044be:	89 45 08             	mov    %eax,0x8(%ebp)
            list_del(&(p->page_link));
c01044c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01044c4:	83 c0 0c             	add    $0xc,%eax
c01044c7:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c01044ca:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01044cd:	8b 40 04             	mov    0x4(%eax),%eax
c01044d0:	8b 55 d8             	mov    -0x28(%ebp),%edx
c01044d3:	8b 12                	mov    (%edx),%edx
c01044d5:	89 55 9c             	mov    %edx,-0x64(%ebp)
c01044d8:	89 45 98             	mov    %eax,-0x68(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c01044db:	8b 45 9c             	mov    -0x64(%ebp),%eax
c01044de:	8b 55 98             	mov    -0x68(%ebp),%edx
c01044e1:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c01044e4:	8b 45 98             	mov    -0x68(%ebp),%eax
c01044e7:	8b 55 9c             	mov    -0x64(%ebp),%edx
c01044ea:	89 10                	mov    %edx,(%eax)
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    list_entry_t *le = list_next(&free_list);
    while (le != &free_list) {
c01044ec:	81 7d f0 1c af 11 c0 	cmpl   $0xc011af1c,-0x10(%ebp)
c01044f3:	0f 85 eb fe ff ff    	jne    c01043e4 <default_free_pages+0x116>
            ClearPageProperty(base);
            base = p;
            list_del(&(p->page_link));
        }
    }
    nr_free += n;
c01044f9:	8b 15 24 af 11 c0    	mov    0xc011af24,%edx
c01044ff:	8b 45 0c             	mov    0xc(%ebp),%eax
c0104502:	01 d0                	add    %edx,%eax
c0104504:	a3 24 af 11 c0       	mov    %eax,0xc011af24
c0104509:	c7 45 d0 1c af 11 c0 	movl   $0xc011af1c,-0x30(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0104510:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104513:	8b 40 04             	mov    0x4(%eax),%eax
    le = list_next(&free_list);
c0104516:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
c0104519:	eb 69                	jmp    c0104584 <default_free_pages+0x2b6>
        p = le2page(le, page_link);
c010451b:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010451e:	83 e8 0c             	sub    $0xc,%eax
c0104521:	89 45 f4             	mov    %eax,-0xc(%ebp)
        if (base + base->property <= p) {
c0104524:	8b 45 08             	mov    0x8(%ebp),%eax
c0104527:	8b 50 08             	mov    0x8(%eax),%edx
c010452a:	89 d0                	mov    %edx,%eax
c010452c:	c1 e0 02             	shl    $0x2,%eax
c010452f:	01 d0                	add    %edx,%eax
c0104531:	c1 e0 02             	shl    $0x2,%eax
c0104534:	89 c2                	mov    %eax,%edx
c0104536:	8b 45 08             	mov    0x8(%ebp),%eax
c0104539:	01 d0                	add    %edx,%eax
c010453b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010453e:	77 35                	ja     c0104575 <default_free_pages+0x2a7>
            assert(base + base->property != p);
c0104540:	8b 45 08             	mov    0x8(%ebp),%eax
c0104543:	8b 50 08             	mov    0x8(%eax),%edx
c0104546:	89 d0                	mov    %edx,%eax
c0104548:	c1 e0 02             	shl    $0x2,%eax
c010454b:	01 d0                	add    %edx,%eax
c010454d:	c1 e0 02             	shl    $0x2,%eax
c0104550:	89 c2                	mov    %eax,%edx
c0104552:	8b 45 08             	mov    0x8(%ebp),%eax
c0104555:	01 d0                	add    %edx,%eax
c0104557:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010455a:	75 33                	jne    c010458f <default_free_pages+0x2c1>
c010455c:	68 a1 68 10 c0       	push   $0xc01068a1
c0104561:	68 3e 68 10 c0       	push   $0xc010683e
c0104566:	68 b9 00 00 00       	push   $0xb9
c010456b:	68 53 68 10 c0       	push   $0xc0106853
c0104570:	e8 64 be ff ff       	call   c01003d9 <__panic>
c0104575:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104578:	89 45 c8             	mov    %eax,-0x38(%ebp)
c010457b:	8b 45 c8             	mov    -0x38(%ebp),%eax
c010457e:	8b 40 04             	mov    0x4(%eax),%eax
            break;
        }
        le = list_next(le);
c0104581:	89 45 f0             	mov    %eax,-0x10(%ebp)
            list_del(&(p->page_link));
        }
    }
    nr_free += n;
    le = list_next(&free_list);
    while (le != &free_list) {
c0104584:	81 7d f0 1c af 11 c0 	cmpl   $0xc011af1c,-0x10(%ebp)
c010458b:	75 8e                	jne    c010451b <default_free_pages+0x24d>
c010458d:	eb 01                	jmp    c0104590 <default_free_pages+0x2c2>
        p = le2page(le, page_link);
        if (base + base->property <= p) {
            assert(base + base->property != p);
            break;
c010458f:	90                   	nop
        }
        le = list_next(le);
    }
    list_add_before(le, &(base->page_link));
c0104590:	8b 45 08             	mov    0x8(%ebp),%eax
c0104593:	8d 50 0c             	lea    0xc(%eax),%edx
c0104596:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104599:	89 45 c4             	mov    %eax,-0x3c(%ebp)
c010459c:	89 55 90             	mov    %edx,-0x70(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
c010459f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c01045a2:	8b 00                	mov    (%eax),%eax
c01045a4:	8b 55 90             	mov    -0x70(%ebp),%edx
c01045a7:	89 55 8c             	mov    %edx,-0x74(%ebp)
c01045aa:	89 45 88             	mov    %eax,-0x78(%ebp)
c01045ad:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c01045b0:	89 45 84             	mov    %eax,-0x7c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c01045b3:	8b 45 84             	mov    -0x7c(%ebp),%eax
c01045b6:	8b 55 8c             	mov    -0x74(%ebp),%edx
c01045b9:	89 10                	mov    %edx,(%eax)
c01045bb:	8b 45 84             	mov    -0x7c(%ebp),%eax
c01045be:	8b 10                	mov    (%eax),%edx
c01045c0:	8b 45 88             	mov    -0x78(%ebp),%eax
c01045c3:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c01045c6:	8b 45 8c             	mov    -0x74(%ebp),%eax
c01045c9:	8b 55 84             	mov    -0x7c(%ebp),%edx
c01045cc:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c01045cf:	8b 45 8c             	mov    -0x74(%ebp),%eax
c01045d2:	8b 55 88             	mov    -0x78(%ebp),%edx
c01045d5:	89 10                	mov    %edx,(%eax)
}
c01045d7:	90                   	nop
c01045d8:	c9                   	leave  
c01045d9:	c3                   	ret    

c01045da <default_nr_free_pages>:

static size_t
default_nr_free_pages(void) {
c01045da:	55                   	push   %ebp
c01045db:	89 e5                	mov    %esp,%ebp
    return nr_free;
c01045dd:	a1 24 af 11 c0       	mov    0xc011af24,%eax
}
c01045e2:	5d                   	pop    %ebp
c01045e3:	c3                   	ret    

c01045e4 <basic_check>:

static void
basic_check(void) {
c01045e4:	55                   	push   %ebp
c01045e5:	89 e5                	mov    %esp,%ebp
c01045e7:	83 ec 38             	sub    $0x38,%esp
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
c01045ea:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c01045f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01045f4:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01045f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01045fa:	89 45 ec             	mov    %eax,-0x14(%ebp)
    assert((p0 = alloc_page()) != NULL);
c01045fd:	83 ec 0c             	sub    $0xc,%esp
c0104600:	6a 01                	push   $0x1
c0104602:	e8 75 e5 ff ff       	call   c0102b7c <alloc_pages>
c0104607:	83 c4 10             	add    $0x10,%esp
c010460a:	89 45 ec             	mov    %eax,-0x14(%ebp)
c010460d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c0104611:	75 19                	jne    c010462c <basic_check+0x48>
c0104613:	68 bc 68 10 c0       	push   $0xc01068bc
c0104618:	68 3e 68 10 c0       	push   $0xc010683e
c010461d:	68 ca 00 00 00       	push   $0xca
c0104622:	68 53 68 10 c0       	push   $0xc0106853
c0104627:	e8 ad bd ff ff       	call   c01003d9 <__panic>
    assert((p1 = alloc_page()) != NULL);
c010462c:	83 ec 0c             	sub    $0xc,%esp
c010462f:	6a 01                	push   $0x1
c0104631:	e8 46 e5 ff ff       	call   c0102b7c <alloc_pages>
c0104636:	83 c4 10             	add    $0x10,%esp
c0104639:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010463c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0104640:	75 19                	jne    c010465b <basic_check+0x77>
c0104642:	68 d8 68 10 c0       	push   $0xc01068d8
c0104647:	68 3e 68 10 c0       	push   $0xc010683e
c010464c:	68 cb 00 00 00       	push   $0xcb
c0104651:	68 53 68 10 c0       	push   $0xc0106853
c0104656:	e8 7e bd ff ff       	call   c01003d9 <__panic>
    assert((p2 = alloc_page()) != NULL);
c010465b:	83 ec 0c             	sub    $0xc,%esp
c010465e:	6a 01                	push   $0x1
c0104660:	e8 17 e5 ff ff       	call   c0102b7c <alloc_pages>
c0104665:	83 c4 10             	add    $0x10,%esp
c0104668:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010466b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c010466f:	75 19                	jne    c010468a <basic_check+0xa6>
c0104671:	68 f4 68 10 c0       	push   $0xc01068f4
c0104676:	68 3e 68 10 c0       	push   $0xc010683e
c010467b:	68 cc 00 00 00       	push   $0xcc
c0104680:	68 53 68 10 c0       	push   $0xc0106853
c0104685:	e8 4f bd ff ff       	call   c01003d9 <__panic>

    assert(p0 != p1 && p0 != p2 && p1 != p2);
c010468a:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010468d:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c0104690:	74 10                	je     c01046a2 <basic_check+0xbe>
c0104692:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104695:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104698:	74 08                	je     c01046a2 <basic_check+0xbe>
c010469a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010469d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01046a0:	75 19                	jne    c01046bb <basic_check+0xd7>
c01046a2:	68 10 69 10 c0       	push   $0xc0106910
c01046a7:	68 3e 68 10 c0       	push   $0xc010683e
c01046ac:	68 ce 00 00 00       	push   $0xce
c01046b1:	68 53 68 10 c0       	push   $0xc0106853
c01046b6:	e8 1e bd ff ff       	call   c01003d9 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
c01046bb:	83 ec 0c             	sub    $0xc,%esp
c01046be:	ff 75 ec             	pushl  -0x14(%ebp)
c01046c1:	e8 1d f9 ff ff       	call   c0103fe3 <page_ref>
c01046c6:	83 c4 10             	add    $0x10,%esp
c01046c9:	85 c0                	test   %eax,%eax
c01046cb:	75 24                	jne    c01046f1 <basic_check+0x10d>
c01046cd:	83 ec 0c             	sub    $0xc,%esp
c01046d0:	ff 75 f0             	pushl  -0x10(%ebp)
c01046d3:	e8 0b f9 ff ff       	call   c0103fe3 <page_ref>
c01046d8:	83 c4 10             	add    $0x10,%esp
c01046db:	85 c0                	test   %eax,%eax
c01046dd:	75 12                	jne    c01046f1 <basic_check+0x10d>
c01046df:	83 ec 0c             	sub    $0xc,%esp
c01046e2:	ff 75 f4             	pushl  -0xc(%ebp)
c01046e5:	e8 f9 f8 ff ff       	call   c0103fe3 <page_ref>
c01046ea:	83 c4 10             	add    $0x10,%esp
c01046ed:	85 c0                	test   %eax,%eax
c01046ef:	74 19                	je     c010470a <basic_check+0x126>
c01046f1:	68 34 69 10 c0       	push   $0xc0106934
c01046f6:	68 3e 68 10 c0       	push   $0xc010683e
c01046fb:	68 cf 00 00 00       	push   $0xcf
c0104700:	68 53 68 10 c0       	push   $0xc0106853
c0104705:	e8 cf bc ff ff       	call   c01003d9 <__panic>

    assert(page2pa(p0) < npage * PGSIZE);
c010470a:	83 ec 0c             	sub    $0xc,%esp
c010470d:	ff 75 ec             	pushl  -0x14(%ebp)
c0104710:	e8 bb f8 ff ff       	call   c0103fd0 <page2pa>
c0104715:	83 c4 10             	add    $0x10,%esp
c0104718:	89 c2                	mov    %eax,%edx
c010471a:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c010471f:	c1 e0 0c             	shl    $0xc,%eax
c0104722:	39 c2                	cmp    %eax,%edx
c0104724:	72 19                	jb     c010473f <basic_check+0x15b>
c0104726:	68 70 69 10 c0       	push   $0xc0106970
c010472b:	68 3e 68 10 c0       	push   $0xc010683e
c0104730:	68 d1 00 00 00       	push   $0xd1
c0104735:	68 53 68 10 c0       	push   $0xc0106853
c010473a:	e8 9a bc ff ff       	call   c01003d9 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
c010473f:	83 ec 0c             	sub    $0xc,%esp
c0104742:	ff 75 f0             	pushl  -0x10(%ebp)
c0104745:	e8 86 f8 ff ff       	call   c0103fd0 <page2pa>
c010474a:	83 c4 10             	add    $0x10,%esp
c010474d:	89 c2                	mov    %eax,%edx
c010474f:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0104754:	c1 e0 0c             	shl    $0xc,%eax
c0104757:	39 c2                	cmp    %eax,%edx
c0104759:	72 19                	jb     c0104774 <basic_check+0x190>
c010475b:	68 8d 69 10 c0       	push   $0xc010698d
c0104760:	68 3e 68 10 c0       	push   $0xc010683e
c0104765:	68 d2 00 00 00       	push   $0xd2
c010476a:	68 53 68 10 c0       	push   $0xc0106853
c010476f:	e8 65 bc ff ff       	call   c01003d9 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
c0104774:	83 ec 0c             	sub    $0xc,%esp
c0104777:	ff 75 f4             	pushl  -0xc(%ebp)
c010477a:	e8 51 f8 ff ff       	call   c0103fd0 <page2pa>
c010477f:	83 c4 10             	add    $0x10,%esp
c0104782:	89 c2                	mov    %eax,%edx
c0104784:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0104789:	c1 e0 0c             	shl    $0xc,%eax
c010478c:	39 c2                	cmp    %eax,%edx
c010478e:	72 19                	jb     c01047a9 <basic_check+0x1c5>
c0104790:	68 aa 69 10 c0       	push   $0xc01069aa
c0104795:	68 3e 68 10 c0       	push   $0xc010683e
c010479a:	68 d3 00 00 00       	push   $0xd3
c010479f:	68 53 68 10 c0       	push   $0xc0106853
c01047a4:	e8 30 bc ff ff       	call   c01003d9 <__panic>

    list_entry_t free_list_store = free_list;
c01047a9:	a1 1c af 11 c0       	mov    0xc011af1c,%eax
c01047ae:	8b 15 20 af 11 c0    	mov    0xc011af20,%edx
c01047b4:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01047b7:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c01047ba:	c7 45 e4 1c af 11 c0 	movl   $0xc011af1c,-0x1c(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c01047c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01047c4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01047c7:	89 50 04             	mov    %edx,0x4(%eax)
c01047ca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01047cd:	8b 50 04             	mov    0x4(%eax),%edx
c01047d0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01047d3:	89 10                	mov    %edx,(%eax)
c01047d5:	c7 45 d8 1c af 11 c0 	movl   $0xc011af1c,-0x28(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
c01047dc:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01047df:	8b 40 04             	mov    0x4(%eax),%eax
c01047e2:	39 45 d8             	cmp    %eax,-0x28(%ebp)
c01047e5:	0f 94 c0             	sete   %al
c01047e8:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
c01047eb:	85 c0                	test   %eax,%eax
c01047ed:	75 19                	jne    c0104808 <basic_check+0x224>
c01047ef:	68 c7 69 10 c0       	push   $0xc01069c7
c01047f4:	68 3e 68 10 c0       	push   $0xc010683e
c01047f9:	68 d7 00 00 00       	push   $0xd7
c01047fe:	68 53 68 10 c0       	push   $0xc0106853
c0104803:	e8 d1 bb ff ff       	call   c01003d9 <__panic>

    unsigned int nr_free_store = nr_free;
c0104808:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c010480d:	89 45 e0             	mov    %eax,-0x20(%ebp)
    nr_free = 0;
c0104810:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c0104817:	00 00 00 

    assert(alloc_page() == NULL);
c010481a:	83 ec 0c             	sub    $0xc,%esp
c010481d:	6a 01                	push   $0x1
c010481f:	e8 58 e3 ff ff       	call   c0102b7c <alloc_pages>
c0104824:	83 c4 10             	add    $0x10,%esp
c0104827:	85 c0                	test   %eax,%eax
c0104829:	74 19                	je     c0104844 <basic_check+0x260>
c010482b:	68 de 69 10 c0       	push   $0xc01069de
c0104830:	68 3e 68 10 c0       	push   $0xc010683e
c0104835:	68 dc 00 00 00       	push   $0xdc
c010483a:	68 53 68 10 c0       	push   $0xc0106853
c010483f:	e8 95 bb ff ff       	call   c01003d9 <__panic>

    free_page(p0);
c0104844:	83 ec 08             	sub    $0x8,%esp
c0104847:	6a 01                	push   $0x1
c0104849:	ff 75 ec             	pushl  -0x14(%ebp)
c010484c:	e8 69 e3 ff ff       	call   c0102bba <free_pages>
c0104851:	83 c4 10             	add    $0x10,%esp
    free_page(p1);
c0104854:	83 ec 08             	sub    $0x8,%esp
c0104857:	6a 01                	push   $0x1
c0104859:	ff 75 f0             	pushl  -0x10(%ebp)
c010485c:	e8 59 e3 ff ff       	call   c0102bba <free_pages>
c0104861:	83 c4 10             	add    $0x10,%esp
    free_page(p2);
c0104864:	83 ec 08             	sub    $0x8,%esp
c0104867:	6a 01                	push   $0x1
c0104869:	ff 75 f4             	pushl  -0xc(%ebp)
c010486c:	e8 49 e3 ff ff       	call   c0102bba <free_pages>
c0104871:	83 c4 10             	add    $0x10,%esp
    assert(nr_free == 3);
c0104874:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104879:	83 f8 03             	cmp    $0x3,%eax
c010487c:	74 19                	je     c0104897 <basic_check+0x2b3>
c010487e:	68 f3 69 10 c0       	push   $0xc01069f3
c0104883:	68 3e 68 10 c0       	push   $0xc010683e
c0104888:	68 e1 00 00 00       	push   $0xe1
c010488d:	68 53 68 10 c0       	push   $0xc0106853
c0104892:	e8 42 bb ff ff       	call   c01003d9 <__panic>

    assert((p0 = alloc_page()) != NULL);
c0104897:	83 ec 0c             	sub    $0xc,%esp
c010489a:	6a 01                	push   $0x1
c010489c:	e8 db e2 ff ff       	call   c0102b7c <alloc_pages>
c01048a1:	83 c4 10             	add    $0x10,%esp
c01048a4:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01048a7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c01048ab:	75 19                	jne    c01048c6 <basic_check+0x2e2>
c01048ad:	68 bc 68 10 c0       	push   $0xc01068bc
c01048b2:	68 3e 68 10 c0       	push   $0xc010683e
c01048b7:	68 e3 00 00 00       	push   $0xe3
c01048bc:	68 53 68 10 c0       	push   $0xc0106853
c01048c1:	e8 13 bb ff ff       	call   c01003d9 <__panic>
    assert((p1 = alloc_page()) != NULL);
c01048c6:	83 ec 0c             	sub    $0xc,%esp
c01048c9:	6a 01                	push   $0x1
c01048cb:	e8 ac e2 ff ff       	call   c0102b7c <alloc_pages>
c01048d0:	83 c4 10             	add    $0x10,%esp
c01048d3:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01048d6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01048da:	75 19                	jne    c01048f5 <basic_check+0x311>
c01048dc:	68 d8 68 10 c0       	push   $0xc01068d8
c01048e1:	68 3e 68 10 c0       	push   $0xc010683e
c01048e6:	68 e4 00 00 00       	push   $0xe4
c01048eb:	68 53 68 10 c0       	push   $0xc0106853
c01048f0:	e8 e4 ba ff ff       	call   c01003d9 <__panic>
    assert((p2 = alloc_page()) != NULL);
c01048f5:	83 ec 0c             	sub    $0xc,%esp
c01048f8:	6a 01                	push   $0x1
c01048fa:	e8 7d e2 ff ff       	call   c0102b7c <alloc_pages>
c01048ff:	83 c4 10             	add    $0x10,%esp
c0104902:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0104905:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0104909:	75 19                	jne    c0104924 <basic_check+0x340>
c010490b:	68 f4 68 10 c0       	push   $0xc01068f4
c0104910:	68 3e 68 10 c0       	push   $0xc010683e
c0104915:	68 e5 00 00 00       	push   $0xe5
c010491a:	68 53 68 10 c0       	push   $0xc0106853
c010491f:	e8 b5 ba ff ff       	call   c01003d9 <__panic>

    assert(alloc_page() == NULL);
c0104924:	83 ec 0c             	sub    $0xc,%esp
c0104927:	6a 01                	push   $0x1
c0104929:	e8 4e e2 ff ff       	call   c0102b7c <alloc_pages>
c010492e:	83 c4 10             	add    $0x10,%esp
c0104931:	85 c0                	test   %eax,%eax
c0104933:	74 19                	je     c010494e <basic_check+0x36a>
c0104935:	68 de 69 10 c0       	push   $0xc01069de
c010493a:	68 3e 68 10 c0       	push   $0xc010683e
c010493f:	68 e7 00 00 00       	push   $0xe7
c0104944:	68 53 68 10 c0       	push   $0xc0106853
c0104949:	e8 8b ba ff ff       	call   c01003d9 <__panic>

    free_page(p0);
c010494e:	83 ec 08             	sub    $0x8,%esp
c0104951:	6a 01                	push   $0x1
c0104953:	ff 75 ec             	pushl  -0x14(%ebp)
c0104956:	e8 5f e2 ff ff       	call   c0102bba <free_pages>
c010495b:	83 c4 10             	add    $0x10,%esp
c010495e:	c7 45 e8 1c af 11 c0 	movl   $0xc011af1c,-0x18(%ebp)
c0104965:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0104968:	8b 40 04             	mov    0x4(%eax),%eax
c010496b:	39 45 e8             	cmp    %eax,-0x18(%ebp)
c010496e:	0f 94 c0             	sete   %al
c0104971:	0f b6 c0             	movzbl %al,%eax
    assert(!list_empty(&free_list));
c0104974:	85 c0                	test   %eax,%eax
c0104976:	74 19                	je     c0104991 <basic_check+0x3ad>
c0104978:	68 00 6a 10 c0       	push   $0xc0106a00
c010497d:	68 3e 68 10 c0       	push   $0xc010683e
c0104982:	68 ea 00 00 00       	push   $0xea
c0104987:	68 53 68 10 c0       	push   $0xc0106853
c010498c:	e8 48 ba ff ff       	call   c01003d9 <__panic>

    struct Page *p;
    assert((p = alloc_page()) == p0);
c0104991:	83 ec 0c             	sub    $0xc,%esp
c0104994:	6a 01                	push   $0x1
c0104996:	e8 e1 e1 ff ff       	call   c0102b7c <alloc_pages>
c010499b:	83 c4 10             	add    $0x10,%esp
c010499e:	89 45 dc             	mov    %eax,-0x24(%ebp)
c01049a1:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01049a4:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c01049a7:	74 19                	je     c01049c2 <basic_check+0x3de>
c01049a9:	68 18 6a 10 c0       	push   $0xc0106a18
c01049ae:	68 3e 68 10 c0       	push   $0xc010683e
c01049b3:	68 ed 00 00 00       	push   $0xed
c01049b8:	68 53 68 10 c0       	push   $0xc0106853
c01049bd:	e8 17 ba ff ff       	call   c01003d9 <__panic>
    assert(alloc_page() == NULL);
c01049c2:	83 ec 0c             	sub    $0xc,%esp
c01049c5:	6a 01                	push   $0x1
c01049c7:	e8 b0 e1 ff ff       	call   c0102b7c <alloc_pages>
c01049cc:	83 c4 10             	add    $0x10,%esp
c01049cf:	85 c0                	test   %eax,%eax
c01049d1:	74 19                	je     c01049ec <basic_check+0x408>
c01049d3:	68 de 69 10 c0       	push   $0xc01069de
c01049d8:	68 3e 68 10 c0       	push   $0xc010683e
c01049dd:	68 ee 00 00 00       	push   $0xee
c01049e2:	68 53 68 10 c0       	push   $0xc0106853
c01049e7:	e8 ed b9 ff ff       	call   c01003d9 <__panic>

    assert(nr_free == 0);
c01049ec:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c01049f1:	85 c0                	test   %eax,%eax
c01049f3:	74 19                	je     c0104a0e <basic_check+0x42a>
c01049f5:	68 31 6a 10 c0       	push   $0xc0106a31
c01049fa:	68 3e 68 10 c0       	push   $0xc010683e
c01049ff:	68 f0 00 00 00       	push   $0xf0
c0104a04:	68 53 68 10 c0       	push   $0xc0106853
c0104a09:	e8 cb b9 ff ff       	call   c01003d9 <__panic>
    free_list = free_list_store;
c0104a0e:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104a11:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104a14:	a3 1c af 11 c0       	mov    %eax,0xc011af1c
c0104a19:	89 15 20 af 11 c0    	mov    %edx,0xc011af20
    nr_free = nr_free_store;
c0104a1f:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0104a22:	a3 24 af 11 c0       	mov    %eax,0xc011af24

    free_page(p);
c0104a27:	83 ec 08             	sub    $0x8,%esp
c0104a2a:	6a 01                	push   $0x1
c0104a2c:	ff 75 dc             	pushl  -0x24(%ebp)
c0104a2f:	e8 86 e1 ff ff       	call   c0102bba <free_pages>
c0104a34:	83 c4 10             	add    $0x10,%esp
    free_page(p1);
c0104a37:	83 ec 08             	sub    $0x8,%esp
c0104a3a:	6a 01                	push   $0x1
c0104a3c:	ff 75 f0             	pushl  -0x10(%ebp)
c0104a3f:	e8 76 e1 ff ff       	call   c0102bba <free_pages>
c0104a44:	83 c4 10             	add    $0x10,%esp
    free_page(p2);
c0104a47:	83 ec 08             	sub    $0x8,%esp
c0104a4a:	6a 01                	push   $0x1
c0104a4c:	ff 75 f4             	pushl  -0xc(%ebp)
c0104a4f:	e8 66 e1 ff ff       	call   c0102bba <free_pages>
c0104a54:	83 c4 10             	add    $0x10,%esp
}
c0104a57:	90                   	nop
c0104a58:	c9                   	leave  
c0104a59:	c3                   	ret    

c0104a5a <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
c0104a5a:	55                   	push   %ebp
c0104a5b:	89 e5                	mov    %esp,%ebp
c0104a5d:	81 ec 88 00 00 00    	sub    $0x88,%esp
    int count = 0, total = 0;
c0104a63:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0104a6a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    list_entry_t *le = &free_list;
c0104a71:	c7 45 ec 1c af 11 c0 	movl   $0xc011af1c,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
c0104a78:	eb 60                	jmp    c0104ada <default_check+0x80>
        struct Page *p = le2page(le, page_link);
c0104a7a:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104a7d:	83 e8 0c             	sub    $0xc,%eax
c0104a80:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        assert(PageProperty(p));
c0104a83:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104a86:	83 c0 04             	add    $0x4,%eax
c0104a89:	c7 45 b0 01 00 00 00 	movl   $0x1,-0x50(%ebp)
c0104a90:	89 45 ac             	mov    %eax,-0x54(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104a93:	8b 45 ac             	mov    -0x54(%ebp),%eax
c0104a96:	8b 55 b0             	mov    -0x50(%ebp),%edx
c0104a99:	0f a3 10             	bt     %edx,(%eax)
c0104a9c:	19 c0                	sbb    %eax,%eax
c0104a9e:	89 45 a8             	mov    %eax,-0x58(%ebp)
    return oldbit != 0;
c0104aa1:	83 7d a8 00          	cmpl   $0x0,-0x58(%ebp)
c0104aa5:	0f 95 c0             	setne  %al
c0104aa8:	0f b6 c0             	movzbl %al,%eax
c0104aab:	85 c0                	test   %eax,%eax
c0104aad:	75 19                	jne    c0104ac8 <default_check+0x6e>
c0104aaf:	68 3e 6a 10 c0       	push   $0xc0106a3e
c0104ab4:	68 3e 68 10 c0       	push   $0xc010683e
c0104ab9:	68 01 01 00 00       	push   $0x101
c0104abe:	68 53 68 10 c0       	push   $0xc0106853
c0104ac3:	e8 11 b9 ff ff       	call   c01003d9 <__panic>
        count ++, total += p->property;
c0104ac8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0104acc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104acf:	8b 50 08             	mov    0x8(%eax),%edx
c0104ad2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104ad5:	01 d0                	add    %edx,%eax
c0104ad7:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104ada:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104add:	89 45 e0             	mov    %eax,-0x20(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0104ae0:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0104ae3:	8b 40 04             	mov    0x4(%eax),%eax
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c0104ae6:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0104ae9:	81 7d ec 1c af 11 c0 	cmpl   $0xc011af1c,-0x14(%ebp)
c0104af0:	75 88                	jne    c0104a7a <default_check+0x20>
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());
c0104af2:	e8 f8 e0 ff ff       	call   c0102bef <nr_free_pages>
c0104af7:	89 c2                	mov    %eax,%edx
c0104af9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104afc:	39 c2                	cmp    %eax,%edx
c0104afe:	74 19                	je     c0104b19 <default_check+0xbf>
c0104b00:	68 4e 6a 10 c0       	push   $0xc0106a4e
c0104b05:	68 3e 68 10 c0       	push   $0xc010683e
c0104b0a:	68 04 01 00 00       	push   $0x104
c0104b0f:	68 53 68 10 c0       	push   $0xc0106853
c0104b14:	e8 c0 b8 ff ff       	call   c01003d9 <__panic>

    basic_check();
c0104b19:	e8 c6 fa ff ff       	call   c01045e4 <basic_check>

    struct Page *p0 = alloc_pages(5), *p1, *p2;
c0104b1e:	83 ec 0c             	sub    $0xc,%esp
c0104b21:	6a 05                	push   $0x5
c0104b23:	e8 54 e0 ff ff       	call   c0102b7c <alloc_pages>
c0104b28:	83 c4 10             	add    $0x10,%esp
c0104b2b:	89 45 dc             	mov    %eax,-0x24(%ebp)
    assert(p0 != NULL);
c0104b2e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0104b32:	75 19                	jne    c0104b4d <default_check+0xf3>
c0104b34:	68 67 6a 10 c0       	push   $0xc0106a67
c0104b39:	68 3e 68 10 c0       	push   $0xc010683e
c0104b3e:	68 09 01 00 00       	push   $0x109
c0104b43:	68 53 68 10 c0       	push   $0xc0106853
c0104b48:	e8 8c b8 ff ff       	call   c01003d9 <__panic>
    assert(!PageProperty(p0));
c0104b4d:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104b50:	83 c0 04             	add    $0x4,%eax
c0104b53:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
c0104b5a:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104b5d:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0104b60:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0104b63:	0f a3 10             	bt     %edx,(%eax)
c0104b66:	19 c0                	sbb    %eax,%eax
c0104b68:	89 45 a0             	mov    %eax,-0x60(%ebp)
    return oldbit != 0;
c0104b6b:	83 7d a0 00          	cmpl   $0x0,-0x60(%ebp)
c0104b6f:	0f 95 c0             	setne  %al
c0104b72:	0f b6 c0             	movzbl %al,%eax
c0104b75:	85 c0                	test   %eax,%eax
c0104b77:	74 19                	je     c0104b92 <default_check+0x138>
c0104b79:	68 72 6a 10 c0       	push   $0xc0106a72
c0104b7e:	68 3e 68 10 c0       	push   $0xc010683e
c0104b83:	68 0a 01 00 00       	push   $0x10a
c0104b88:	68 53 68 10 c0       	push   $0xc0106853
c0104b8d:	e8 47 b8 ff ff       	call   c01003d9 <__panic>

    list_entry_t free_list_store = free_list;
c0104b92:	a1 1c af 11 c0       	mov    0xc011af1c,%eax
c0104b97:	8b 15 20 af 11 c0    	mov    0xc011af20,%edx
c0104b9d:	89 45 80             	mov    %eax,-0x80(%ebp)
c0104ba0:	89 55 84             	mov    %edx,-0x7c(%ebp)
c0104ba3:	c7 45 d0 1c af 11 c0 	movl   $0xc011af1c,-0x30(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c0104baa:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104bad:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0104bb0:	89 50 04             	mov    %edx,0x4(%eax)
c0104bb3:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104bb6:	8b 50 04             	mov    0x4(%eax),%edx
c0104bb9:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104bbc:	89 10                	mov    %edx,(%eax)
c0104bbe:	c7 45 d8 1c af 11 c0 	movl   $0xc011af1c,-0x28(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
c0104bc5:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104bc8:	8b 40 04             	mov    0x4(%eax),%eax
c0104bcb:	39 45 d8             	cmp    %eax,-0x28(%ebp)
c0104bce:	0f 94 c0             	sete   %al
c0104bd1:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
c0104bd4:	85 c0                	test   %eax,%eax
c0104bd6:	75 19                	jne    c0104bf1 <default_check+0x197>
c0104bd8:	68 c7 69 10 c0       	push   $0xc01069c7
c0104bdd:	68 3e 68 10 c0       	push   $0xc010683e
c0104be2:	68 0e 01 00 00       	push   $0x10e
c0104be7:	68 53 68 10 c0       	push   $0xc0106853
c0104bec:	e8 e8 b7 ff ff       	call   c01003d9 <__panic>
    assert(alloc_page() == NULL);
c0104bf1:	83 ec 0c             	sub    $0xc,%esp
c0104bf4:	6a 01                	push   $0x1
c0104bf6:	e8 81 df ff ff       	call   c0102b7c <alloc_pages>
c0104bfb:	83 c4 10             	add    $0x10,%esp
c0104bfe:	85 c0                	test   %eax,%eax
c0104c00:	74 19                	je     c0104c1b <default_check+0x1c1>
c0104c02:	68 de 69 10 c0       	push   $0xc01069de
c0104c07:	68 3e 68 10 c0       	push   $0xc010683e
c0104c0c:	68 0f 01 00 00       	push   $0x10f
c0104c11:	68 53 68 10 c0       	push   $0xc0106853
c0104c16:	e8 be b7 ff ff       	call   c01003d9 <__panic>

    unsigned int nr_free_store = nr_free;
c0104c1b:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104c20:	89 45 cc             	mov    %eax,-0x34(%ebp)
    nr_free = 0;
c0104c23:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c0104c2a:	00 00 00 

    free_pages(p0 + 2, 3);
c0104c2d:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104c30:	83 c0 28             	add    $0x28,%eax
c0104c33:	83 ec 08             	sub    $0x8,%esp
c0104c36:	6a 03                	push   $0x3
c0104c38:	50                   	push   %eax
c0104c39:	e8 7c df ff ff       	call   c0102bba <free_pages>
c0104c3e:	83 c4 10             	add    $0x10,%esp
    assert(alloc_pages(4) == NULL);
c0104c41:	83 ec 0c             	sub    $0xc,%esp
c0104c44:	6a 04                	push   $0x4
c0104c46:	e8 31 df ff ff       	call   c0102b7c <alloc_pages>
c0104c4b:	83 c4 10             	add    $0x10,%esp
c0104c4e:	85 c0                	test   %eax,%eax
c0104c50:	74 19                	je     c0104c6b <default_check+0x211>
c0104c52:	68 84 6a 10 c0       	push   $0xc0106a84
c0104c57:	68 3e 68 10 c0       	push   $0xc010683e
c0104c5c:	68 15 01 00 00       	push   $0x115
c0104c61:	68 53 68 10 c0       	push   $0xc0106853
c0104c66:	e8 6e b7 ff ff       	call   c01003d9 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
c0104c6b:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104c6e:	83 c0 28             	add    $0x28,%eax
c0104c71:	83 c0 04             	add    $0x4,%eax
c0104c74:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
c0104c7b:	89 45 9c             	mov    %eax,-0x64(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104c7e:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0104c81:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104c84:	0f a3 10             	bt     %edx,(%eax)
c0104c87:	19 c0                	sbb    %eax,%eax
c0104c89:	89 45 98             	mov    %eax,-0x68(%ebp)
    return oldbit != 0;
c0104c8c:	83 7d 98 00          	cmpl   $0x0,-0x68(%ebp)
c0104c90:	0f 95 c0             	setne  %al
c0104c93:	0f b6 c0             	movzbl %al,%eax
c0104c96:	85 c0                	test   %eax,%eax
c0104c98:	74 0e                	je     c0104ca8 <default_check+0x24e>
c0104c9a:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104c9d:	83 c0 28             	add    $0x28,%eax
c0104ca0:	8b 40 08             	mov    0x8(%eax),%eax
c0104ca3:	83 f8 03             	cmp    $0x3,%eax
c0104ca6:	74 19                	je     c0104cc1 <default_check+0x267>
c0104ca8:	68 9c 6a 10 c0       	push   $0xc0106a9c
c0104cad:	68 3e 68 10 c0       	push   $0xc010683e
c0104cb2:	68 16 01 00 00       	push   $0x116
c0104cb7:	68 53 68 10 c0       	push   $0xc0106853
c0104cbc:	e8 18 b7 ff ff       	call   c01003d9 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
c0104cc1:	83 ec 0c             	sub    $0xc,%esp
c0104cc4:	6a 03                	push   $0x3
c0104cc6:	e8 b1 de ff ff       	call   c0102b7c <alloc_pages>
c0104ccb:	83 c4 10             	add    $0x10,%esp
c0104cce:	89 45 c4             	mov    %eax,-0x3c(%ebp)
c0104cd1:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
c0104cd5:	75 19                	jne    c0104cf0 <default_check+0x296>
c0104cd7:	68 c8 6a 10 c0       	push   $0xc0106ac8
c0104cdc:	68 3e 68 10 c0       	push   $0xc010683e
c0104ce1:	68 17 01 00 00       	push   $0x117
c0104ce6:	68 53 68 10 c0       	push   $0xc0106853
c0104ceb:	e8 e9 b6 ff ff       	call   c01003d9 <__panic>
    assert(alloc_page() == NULL);
c0104cf0:	83 ec 0c             	sub    $0xc,%esp
c0104cf3:	6a 01                	push   $0x1
c0104cf5:	e8 82 de ff ff       	call   c0102b7c <alloc_pages>
c0104cfa:	83 c4 10             	add    $0x10,%esp
c0104cfd:	85 c0                	test   %eax,%eax
c0104cff:	74 19                	je     c0104d1a <default_check+0x2c0>
c0104d01:	68 de 69 10 c0       	push   $0xc01069de
c0104d06:	68 3e 68 10 c0       	push   $0xc010683e
c0104d0b:	68 18 01 00 00       	push   $0x118
c0104d10:	68 53 68 10 c0       	push   $0xc0106853
c0104d15:	e8 bf b6 ff ff       	call   c01003d9 <__panic>
    assert(p0 + 2 == p1);
c0104d1a:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104d1d:	83 c0 28             	add    $0x28,%eax
c0104d20:	3b 45 c4             	cmp    -0x3c(%ebp),%eax
c0104d23:	74 19                	je     c0104d3e <default_check+0x2e4>
c0104d25:	68 e6 6a 10 c0       	push   $0xc0106ae6
c0104d2a:	68 3e 68 10 c0       	push   $0xc010683e
c0104d2f:	68 19 01 00 00       	push   $0x119
c0104d34:	68 53 68 10 c0       	push   $0xc0106853
c0104d39:	e8 9b b6 ff ff       	call   c01003d9 <__panic>

    p2 = p0 + 1;
c0104d3e:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104d41:	83 c0 14             	add    $0x14,%eax
c0104d44:	89 45 c0             	mov    %eax,-0x40(%ebp)
    free_page(p0);
c0104d47:	83 ec 08             	sub    $0x8,%esp
c0104d4a:	6a 01                	push   $0x1
c0104d4c:	ff 75 dc             	pushl  -0x24(%ebp)
c0104d4f:	e8 66 de ff ff       	call   c0102bba <free_pages>
c0104d54:	83 c4 10             	add    $0x10,%esp
    free_pages(p1, 3);
c0104d57:	83 ec 08             	sub    $0x8,%esp
c0104d5a:	6a 03                	push   $0x3
c0104d5c:	ff 75 c4             	pushl  -0x3c(%ebp)
c0104d5f:	e8 56 de ff ff       	call   c0102bba <free_pages>
c0104d64:	83 c4 10             	add    $0x10,%esp
    assert(PageProperty(p0) && p0->property == 1);
c0104d67:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104d6a:	83 c0 04             	add    $0x4,%eax
c0104d6d:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
c0104d74:	89 45 94             	mov    %eax,-0x6c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104d77:	8b 45 94             	mov    -0x6c(%ebp),%eax
c0104d7a:	8b 55 c8             	mov    -0x38(%ebp),%edx
c0104d7d:	0f a3 10             	bt     %edx,(%eax)
c0104d80:	19 c0                	sbb    %eax,%eax
c0104d82:	89 45 90             	mov    %eax,-0x70(%ebp)
    return oldbit != 0;
c0104d85:	83 7d 90 00          	cmpl   $0x0,-0x70(%ebp)
c0104d89:	0f 95 c0             	setne  %al
c0104d8c:	0f b6 c0             	movzbl %al,%eax
c0104d8f:	85 c0                	test   %eax,%eax
c0104d91:	74 0b                	je     c0104d9e <default_check+0x344>
c0104d93:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104d96:	8b 40 08             	mov    0x8(%eax),%eax
c0104d99:	83 f8 01             	cmp    $0x1,%eax
c0104d9c:	74 19                	je     c0104db7 <default_check+0x35d>
c0104d9e:	68 f4 6a 10 c0       	push   $0xc0106af4
c0104da3:	68 3e 68 10 c0       	push   $0xc010683e
c0104da8:	68 1e 01 00 00       	push   $0x11e
c0104dad:	68 53 68 10 c0       	push   $0xc0106853
c0104db2:	e8 22 b6 ff ff       	call   c01003d9 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
c0104db7:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104dba:	83 c0 04             	add    $0x4,%eax
c0104dbd:	c7 45 bc 01 00 00 00 	movl   $0x1,-0x44(%ebp)
c0104dc4:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104dc7:	8b 45 8c             	mov    -0x74(%ebp),%eax
c0104dca:	8b 55 bc             	mov    -0x44(%ebp),%edx
c0104dcd:	0f a3 10             	bt     %edx,(%eax)
c0104dd0:	19 c0                	sbb    %eax,%eax
c0104dd2:	89 45 88             	mov    %eax,-0x78(%ebp)
    return oldbit != 0;
c0104dd5:	83 7d 88 00          	cmpl   $0x0,-0x78(%ebp)
c0104dd9:	0f 95 c0             	setne  %al
c0104ddc:	0f b6 c0             	movzbl %al,%eax
c0104ddf:	85 c0                	test   %eax,%eax
c0104de1:	74 0b                	je     c0104dee <default_check+0x394>
c0104de3:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104de6:	8b 40 08             	mov    0x8(%eax),%eax
c0104de9:	83 f8 03             	cmp    $0x3,%eax
c0104dec:	74 19                	je     c0104e07 <default_check+0x3ad>
c0104dee:	68 1c 6b 10 c0       	push   $0xc0106b1c
c0104df3:	68 3e 68 10 c0       	push   $0xc010683e
c0104df8:	68 1f 01 00 00       	push   $0x11f
c0104dfd:	68 53 68 10 c0       	push   $0xc0106853
c0104e02:	e8 d2 b5 ff ff       	call   c01003d9 <__panic>

    assert((p0 = alloc_page()) == p2 - 1);
c0104e07:	83 ec 0c             	sub    $0xc,%esp
c0104e0a:	6a 01                	push   $0x1
c0104e0c:	e8 6b dd ff ff       	call   c0102b7c <alloc_pages>
c0104e11:	83 c4 10             	add    $0x10,%esp
c0104e14:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104e17:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0104e1a:	83 e8 14             	sub    $0x14,%eax
c0104e1d:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c0104e20:	74 19                	je     c0104e3b <default_check+0x3e1>
c0104e22:	68 42 6b 10 c0       	push   $0xc0106b42
c0104e27:	68 3e 68 10 c0       	push   $0xc010683e
c0104e2c:	68 21 01 00 00       	push   $0x121
c0104e31:	68 53 68 10 c0       	push   $0xc0106853
c0104e36:	e8 9e b5 ff ff       	call   c01003d9 <__panic>
    free_page(p0);
c0104e3b:	83 ec 08             	sub    $0x8,%esp
c0104e3e:	6a 01                	push   $0x1
c0104e40:	ff 75 dc             	pushl  -0x24(%ebp)
c0104e43:	e8 72 dd ff ff       	call   c0102bba <free_pages>
c0104e48:	83 c4 10             	add    $0x10,%esp
    assert((p0 = alloc_pages(2)) == p2 + 1);
c0104e4b:	83 ec 0c             	sub    $0xc,%esp
c0104e4e:	6a 02                	push   $0x2
c0104e50:	e8 27 dd ff ff       	call   c0102b7c <alloc_pages>
c0104e55:	83 c4 10             	add    $0x10,%esp
c0104e58:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104e5b:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0104e5e:	83 c0 14             	add    $0x14,%eax
c0104e61:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c0104e64:	74 19                	je     c0104e7f <default_check+0x425>
c0104e66:	68 60 6b 10 c0       	push   $0xc0106b60
c0104e6b:	68 3e 68 10 c0       	push   $0xc010683e
c0104e70:	68 23 01 00 00       	push   $0x123
c0104e75:	68 53 68 10 c0       	push   $0xc0106853
c0104e7a:	e8 5a b5 ff ff       	call   c01003d9 <__panic>

    free_pages(p0, 2);
c0104e7f:	83 ec 08             	sub    $0x8,%esp
c0104e82:	6a 02                	push   $0x2
c0104e84:	ff 75 dc             	pushl  -0x24(%ebp)
c0104e87:	e8 2e dd ff ff       	call   c0102bba <free_pages>
c0104e8c:	83 c4 10             	add    $0x10,%esp
    free_page(p2);
c0104e8f:	83 ec 08             	sub    $0x8,%esp
c0104e92:	6a 01                	push   $0x1
c0104e94:	ff 75 c0             	pushl  -0x40(%ebp)
c0104e97:	e8 1e dd ff ff       	call   c0102bba <free_pages>
c0104e9c:	83 c4 10             	add    $0x10,%esp

    assert((p0 = alloc_pages(5)) != NULL);
c0104e9f:	83 ec 0c             	sub    $0xc,%esp
c0104ea2:	6a 05                	push   $0x5
c0104ea4:	e8 d3 dc ff ff       	call   c0102b7c <alloc_pages>
c0104ea9:	83 c4 10             	add    $0x10,%esp
c0104eac:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104eaf:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0104eb3:	75 19                	jne    c0104ece <default_check+0x474>
c0104eb5:	68 80 6b 10 c0       	push   $0xc0106b80
c0104eba:	68 3e 68 10 c0       	push   $0xc010683e
c0104ebf:	68 28 01 00 00       	push   $0x128
c0104ec4:	68 53 68 10 c0       	push   $0xc0106853
c0104ec9:	e8 0b b5 ff ff       	call   c01003d9 <__panic>
    assert(alloc_page() == NULL);
c0104ece:	83 ec 0c             	sub    $0xc,%esp
c0104ed1:	6a 01                	push   $0x1
c0104ed3:	e8 a4 dc ff ff       	call   c0102b7c <alloc_pages>
c0104ed8:	83 c4 10             	add    $0x10,%esp
c0104edb:	85 c0                	test   %eax,%eax
c0104edd:	74 19                	je     c0104ef8 <default_check+0x49e>
c0104edf:	68 de 69 10 c0       	push   $0xc01069de
c0104ee4:	68 3e 68 10 c0       	push   $0xc010683e
c0104ee9:	68 29 01 00 00       	push   $0x129
c0104eee:	68 53 68 10 c0       	push   $0xc0106853
c0104ef3:	e8 e1 b4 ff ff       	call   c01003d9 <__panic>

    assert(nr_free == 0);
c0104ef8:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104efd:	85 c0                	test   %eax,%eax
c0104eff:	74 19                	je     c0104f1a <default_check+0x4c0>
c0104f01:	68 31 6a 10 c0       	push   $0xc0106a31
c0104f06:	68 3e 68 10 c0       	push   $0xc010683e
c0104f0b:	68 2b 01 00 00       	push   $0x12b
c0104f10:	68 53 68 10 c0       	push   $0xc0106853
c0104f15:	e8 bf b4 ff ff       	call   c01003d9 <__panic>
    nr_free = nr_free_store;
c0104f1a:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0104f1d:	a3 24 af 11 c0       	mov    %eax,0xc011af24

    free_list = free_list_store;
c0104f22:	8b 45 80             	mov    -0x80(%ebp),%eax
c0104f25:	8b 55 84             	mov    -0x7c(%ebp),%edx
c0104f28:	a3 1c af 11 c0       	mov    %eax,0xc011af1c
c0104f2d:	89 15 20 af 11 c0    	mov    %edx,0xc011af20
    free_pages(p0, 5);
c0104f33:	83 ec 08             	sub    $0x8,%esp
c0104f36:	6a 05                	push   $0x5
c0104f38:	ff 75 dc             	pushl  -0x24(%ebp)
c0104f3b:	e8 7a dc ff ff       	call   c0102bba <free_pages>
c0104f40:	83 c4 10             	add    $0x10,%esp

    le = &free_list;
c0104f43:	c7 45 ec 1c af 11 c0 	movl   $0xc011af1c,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
c0104f4a:	eb 1d                	jmp    c0104f69 <default_check+0x50f>
        struct Page *p = le2page(le, page_link);
c0104f4c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104f4f:	83 e8 0c             	sub    $0xc,%eax
c0104f52:	89 45 b4             	mov    %eax,-0x4c(%ebp)
        count --, total -= p->property;
c0104f55:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
c0104f59:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0104f5c:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c0104f5f:	8b 40 08             	mov    0x8(%eax),%eax
c0104f62:	29 c2                	sub    %eax,%edx
c0104f64:	89 d0                	mov    %edx,%eax
c0104f66:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104f69:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104f6c:	89 45 b8             	mov    %eax,-0x48(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0104f6f:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0104f72:	8b 40 04             	mov    0x4(%eax),%eax

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c0104f75:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0104f78:	81 7d ec 1c af 11 c0 	cmpl   $0xc011af1c,-0x14(%ebp)
c0104f7f:	75 cb                	jne    c0104f4c <default_check+0x4f2>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
c0104f81:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0104f85:	74 19                	je     c0104fa0 <default_check+0x546>
c0104f87:	68 9e 6b 10 c0       	push   $0xc0106b9e
c0104f8c:	68 3e 68 10 c0       	push   $0xc010683e
c0104f91:	68 36 01 00 00       	push   $0x136
c0104f96:	68 53 68 10 c0       	push   $0xc0106853
c0104f9b:	e8 39 b4 ff ff       	call   c01003d9 <__panic>
    assert(total == 0);
c0104fa0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0104fa4:	74 19                	je     c0104fbf <default_check+0x565>
c0104fa6:	68 a9 6b 10 c0       	push   $0xc0106ba9
c0104fab:	68 3e 68 10 c0       	push   $0xc010683e
c0104fb0:	68 37 01 00 00       	push   $0x137
c0104fb5:	68 53 68 10 c0       	push   $0xc0106853
c0104fba:	e8 1a b4 ff ff       	call   c01003d9 <__panic>
}
c0104fbf:	90                   	nop
c0104fc0:	c9                   	leave  
c0104fc1:	c3                   	ret    

c0104fc2 <strlen>:
 * @s:      the input string
 *
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
c0104fc2:	55                   	push   %ebp
c0104fc3:	89 e5                	mov    %esp,%ebp
c0104fc5:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
c0104fc8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (*s ++ != '\0') {
c0104fcf:	eb 04                	jmp    c0104fd5 <strlen+0x13>
        cnt ++;
c0104fd1:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
c0104fd5:	8b 45 08             	mov    0x8(%ebp),%eax
c0104fd8:	8d 50 01             	lea    0x1(%eax),%edx
c0104fdb:	89 55 08             	mov    %edx,0x8(%ebp)
c0104fde:	0f b6 00             	movzbl (%eax),%eax
c0104fe1:	84 c0                	test   %al,%al
c0104fe3:	75 ec                	jne    c0104fd1 <strlen+0xf>
        cnt ++;
    }
    return cnt;
c0104fe5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0104fe8:	c9                   	leave  
c0104fe9:	c3                   	ret    

c0104fea <strnlen>:
 * The return value is strlen(s), if that is less than @len, or
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
c0104fea:	55                   	push   %ebp
c0104feb:	89 e5                	mov    %esp,%ebp
c0104fed:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
c0104ff0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (cnt < len && *s ++ != '\0') {
c0104ff7:	eb 04                	jmp    c0104ffd <strnlen+0x13>
        cnt ++;
c0104ff9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
c0104ffd:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0105000:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0105003:	73 10                	jae    c0105015 <strnlen+0x2b>
c0105005:	8b 45 08             	mov    0x8(%ebp),%eax
c0105008:	8d 50 01             	lea    0x1(%eax),%edx
c010500b:	89 55 08             	mov    %edx,0x8(%ebp)
c010500e:	0f b6 00             	movzbl (%eax),%eax
c0105011:	84 c0                	test   %al,%al
c0105013:	75 e4                	jne    c0104ff9 <strnlen+0xf>
        cnt ++;
    }
    return cnt;
c0105015:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0105018:	c9                   	leave  
c0105019:	c3                   	ret    

c010501a <strcpy>:
 * To avoid overflows, the size of array pointed by @dst should be long enough to
 * contain the same string as @src (including the terminating null character), and
 * should not overlap in memory with @src.
 * */
char *
strcpy(char *dst, const char *src) {
c010501a:	55                   	push   %ebp
c010501b:	89 e5                	mov    %esp,%ebp
c010501d:	57                   	push   %edi
c010501e:	56                   	push   %esi
c010501f:	83 ec 20             	sub    $0x20,%esp
c0105022:	8b 45 08             	mov    0x8(%ebp),%eax
c0105025:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105028:	8b 45 0c             	mov    0xc(%ebp),%eax
c010502b:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCPY
#define __HAVE_ARCH_STRCPY
static inline char *
__strcpy(char *dst, const char *src) {
    int d0, d1, d2;
    asm volatile (
c010502e:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0105031:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105034:	89 d1                	mov    %edx,%ecx
c0105036:	89 c2                	mov    %eax,%edx
c0105038:	89 ce                	mov    %ecx,%esi
c010503a:	89 d7                	mov    %edx,%edi
c010503c:	ac                   	lods   %ds:(%esi),%al
c010503d:	aa                   	stos   %al,%es:(%edi)
c010503e:	84 c0                	test   %al,%al
c0105040:	75 fa                	jne    c010503c <strcpy+0x22>
c0105042:	89 fa                	mov    %edi,%edx
c0105044:	89 f1                	mov    %esi,%ecx
c0105046:	89 4d ec             	mov    %ecx,-0x14(%ebp)
c0105049:	89 55 e8             	mov    %edx,-0x18(%ebp)
c010504c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        "stosb;"
        "testb %%al, %%al;"
        "jne 1b;"
        : "=&S" (d0), "=&D" (d1), "=&a" (d2)
        : "0" (src), "1" (dst) : "memory");
    return dst;
c010504f:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
c0105052:	90                   	nop
    char *p = dst;
    while ((*p ++ = *src ++) != '\0')
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
c0105053:	83 c4 20             	add    $0x20,%esp
c0105056:	5e                   	pop    %esi
c0105057:	5f                   	pop    %edi
c0105058:	5d                   	pop    %ebp
c0105059:	c3                   	ret    

c010505a <strncpy>:
 * @len:    maximum number of characters to be copied from @src
 *
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
c010505a:	55                   	push   %ebp
c010505b:	89 e5                	mov    %esp,%ebp
c010505d:	83 ec 10             	sub    $0x10,%esp
    char *p = dst;
c0105060:	8b 45 08             	mov    0x8(%ebp),%eax
c0105063:	89 45 fc             	mov    %eax,-0x4(%ebp)
    while (len > 0) {
c0105066:	eb 21                	jmp    c0105089 <strncpy+0x2f>
        if ((*p = *src) != '\0') {
c0105068:	8b 45 0c             	mov    0xc(%ebp),%eax
c010506b:	0f b6 10             	movzbl (%eax),%edx
c010506e:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0105071:	88 10                	mov    %dl,(%eax)
c0105073:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0105076:	0f b6 00             	movzbl (%eax),%eax
c0105079:	84 c0                	test   %al,%al
c010507b:	74 04                	je     c0105081 <strncpy+0x27>
            src ++;
c010507d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
        }
        p ++, len --;
c0105081:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c0105085:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
    char *p = dst;
    while (len > 0) {
c0105089:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c010508d:	75 d9                	jne    c0105068 <strncpy+0xe>
        if ((*p = *src) != '\0') {
            src ++;
        }
        p ++, len --;
    }
    return dst;
c010508f:	8b 45 08             	mov    0x8(%ebp),%eax
}
c0105092:	c9                   	leave  
c0105093:	c3                   	ret    

c0105094 <strcmp>:
 * - A value greater than zero indicates that the first character that does
 *   not match has a greater value in @s1 than in @s2;
 * - And a value less than zero indicates the opposite.
 * */
int
strcmp(const char *s1, const char *s2) {
c0105094:	55                   	push   %ebp
c0105095:	89 e5                	mov    %esp,%ebp
c0105097:	57                   	push   %edi
c0105098:	56                   	push   %esi
c0105099:	83 ec 20             	sub    $0x20,%esp
c010509c:	8b 45 08             	mov    0x8(%ebp),%eax
c010509f:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01050a2:	8b 45 0c             	mov    0xc(%ebp),%eax
c01050a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCMP
#define __HAVE_ARCH_STRCMP
static inline int
__strcmp(const char *s1, const char *s2) {
    int d0, d1, ret;
    asm volatile (
c01050a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01050ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01050ae:	89 d1                	mov    %edx,%ecx
c01050b0:	89 c2                	mov    %eax,%edx
c01050b2:	89 ce                	mov    %ecx,%esi
c01050b4:	89 d7                	mov    %edx,%edi
c01050b6:	ac                   	lods   %ds:(%esi),%al
c01050b7:	ae                   	scas   %es:(%edi),%al
c01050b8:	75 08                	jne    c01050c2 <strcmp+0x2e>
c01050ba:	84 c0                	test   %al,%al
c01050bc:	75 f8                	jne    c01050b6 <strcmp+0x22>
c01050be:	31 c0                	xor    %eax,%eax
c01050c0:	eb 04                	jmp    c01050c6 <strcmp+0x32>
c01050c2:	19 c0                	sbb    %eax,%eax
c01050c4:	0c 01                	or     $0x1,%al
c01050c6:	89 fa                	mov    %edi,%edx
c01050c8:	89 f1                	mov    %esi,%ecx
c01050ca:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01050cd:	89 4d e8             	mov    %ecx,-0x18(%ebp)
c01050d0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
        "orb $1, %%al;"
        "3:"
        : "=a" (ret), "=&S" (d0), "=&D" (d1)
        : "1" (s1), "2" (s2)
        : "memory");
    return ret;
c01050d3:	8b 45 ec             	mov    -0x14(%ebp),%eax
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
c01050d6:	90                   	nop
    while (*s1 != '\0' && *s1 == *s2) {
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
#endif /* __HAVE_ARCH_STRCMP */
}
c01050d7:	83 c4 20             	add    $0x20,%esp
c01050da:	5e                   	pop    %esi
c01050db:	5f                   	pop    %edi
c01050dc:	5d                   	pop    %ebp
c01050dd:	c3                   	ret    

c01050de <strncmp>:
 * they are equal to each other, it continues with the following pairs until
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
c01050de:	55                   	push   %ebp
c01050df:	89 e5                	mov    %esp,%ebp
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
c01050e1:	eb 0c                	jmp    c01050ef <strncmp+0x11>
        n --, s1 ++, s2 ++;
c01050e3:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
c01050e7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c01050eb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
c01050ef:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01050f3:	74 1a                	je     c010510f <strncmp+0x31>
c01050f5:	8b 45 08             	mov    0x8(%ebp),%eax
c01050f8:	0f b6 00             	movzbl (%eax),%eax
c01050fb:	84 c0                	test   %al,%al
c01050fd:	74 10                	je     c010510f <strncmp+0x31>
c01050ff:	8b 45 08             	mov    0x8(%ebp),%eax
c0105102:	0f b6 10             	movzbl (%eax),%edx
c0105105:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105108:	0f b6 00             	movzbl (%eax),%eax
c010510b:	38 c2                	cmp    %al,%dl
c010510d:	74 d4                	je     c01050e3 <strncmp+0x5>
        n --, s1 ++, s2 ++;
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
c010510f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0105113:	74 18                	je     c010512d <strncmp+0x4f>
c0105115:	8b 45 08             	mov    0x8(%ebp),%eax
c0105118:	0f b6 00             	movzbl (%eax),%eax
c010511b:	0f b6 d0             	movzbl %al,%edx
c010511e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105121:	0f b6 00             	movzbl (%eax),%eax
c0105124:	0f b6 c0             	movzbl %al,%eax
c0105127:	29 c2                	sub    %eax,%edx
c0105129:	89 d0                	mov    %edx,%eax
c010512b:	eb 05                	jmp    c0105132 <strncmp+0x54>
c010512d:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0105132:	5d                   	pop    %ebp
c0105133:	c3                   	ret    

c0105134 <strchr>:
 *
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
c0105134:	55                   	push   %ebp
c0105135:	89 e5                	mov    %esp,%ebp
c0105137:	83 ec 04             	sub    $0x4,%esp
c010513a:	8b 45 0c             	mov    0xc(%ebp),%eax
c010513d:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
c0105140:	eb 14                	jmp    c0105156 <strchr+0x22>
        if (*s == c) {
c0105142:	8b 45 08             	mov    0x8(%ebp),%eax
c0105145:	0f b6 00             	movzbl (%eax),%eax
c0105148:	3a 45 fc             	cmp    -0x4(%ebp),%al
c010514b:	75 05                	jne    c0105152 <strchr+0x1e>
            return (char *)s;
c010514d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105150:	eb 13                	jmp    c0105165 <strchr+0x31>
        }
        s ++;
c0105152:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
c0105156:	8b 45 08             	mov    0x8(%ebp),%eax
c0105159:	0f b6 00             	movzbl (%eax),%eax
c010515c:	84 c0                	test   %al,%al
c010515e:	75 e2                	jne    c0105142 <strchr+0xe>
        if (*s == c) {
            return (char *)s;
        }
        s ++;
    }
    return NULL;
c0105160:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0105165:	c9                   	leave  
c0105166:	c3                   	ret    

c0105167 <strfind>:
 * The strfind() function is like strchr() except that if @c is
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
c0105167:	55                   	push   %ebp
c0105168:	89 e5                	mov    %esp,%ebp
c010516a:	83 ec 04             	sub    $0x4,%esp
c010516d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105170:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
c0105173:	eb 0f                	jmp    c0105184 <strfind+0x1d>
        if (*s == c) {
c0105175:	8b 45 08             	mov    0x8(%ebp),%eax
c0105178:	0f b6 00             	movzbl (%eax),%eax
c010517b:	3a 45 fc             	cmp    -0x4(%ebp),%al
c010517e:	74 10                	je     c0105190 <strfind+0x29>
            break;
        }
        s ++;
c0105180:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
    while (*s != '\0') {
c0105184:	8b 45 08             	mov    0x8(%ebp),%eax
c0105187:	0f b6 00             	movzbl (%eax),%eax
c010518a:	84 c0                	test   %al,%al
c010518c:	75 e7                	jne    c0105175 <strfind+0xe>
c010518e:	eb 01                	jmp    c0105191 <strfind+0x2a>
        if (*s == c) {
            break;
c0105190:	90                   	nop
        }
        s ++;
    }
    return (char *)s;
c0105191:	8b 45 08             	mov    0x8(%ebp),%eax
}
c0105194:	c9                   	leave  
c0105195:	c3                   	ret    

c0105196 <strtol>:
 * an optional "0x" or "0X" prefix.
 *
 * The strtol() function returns the converted integral number as a long int value.
 * */
long
strtol(const char *s, char **endptr, int base) {
c0105196:	55                   	push   %ebp
c0105197:	89 e5                	mov    %esp,%ebp
c0105199:	83 ec 10             	sub    $0x10,%esp
    int neg = 0;
c010519c:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    long val = 0;
c01051a3:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
c01051aa:	eb 04                	jmp    c01051b0 <strtol+0x1a>
        s ++;
c01051ac:	83 45 08 01          	addl   $0x1,0x8(%ebp)
strtol(const char *s, char **endptr, int base) {
    int neg = 0;
    long val = 0;

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
c01051b0:	8b 45 08             	mov    0x8(%ebp),%eax
c01051b3:	0f b6 00             	movzbl (%eax),%eax
c01051b6:	3c 20                	cmp    $0x20,%al
c01051b8:	74 f2                	je     c01051ac <strtol+0x16>
c01051ba:	8b 45 08             	mov    0x8(%ebp),%eax
c01051bd:	0f b6 00             	movzbl (%eax),%eax
c01051c0:	3c 09                	cmp    $0x9,%al
c01051c2:	74 e8                	je     c01051ac <strtol+0x16>
        s ++;
    }

    // plus/minus sign
    if (*s == '+') {
c01051c4:	8b 45 08             	mov    0x8(%ebp),%eax
c01051c7:	0f b6 00             	movzbl (%eax),%eax
c01051ca:	3c 2b                	cmp    $0x2b,%al
c01051cc:	75 06                	jne    c01051d4 <strtol+0x3e>
        s ++;
c01051ce:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c01051d2:	eb 15                	jmp    c01051e9 <strtol+0x53>
    }
    else if (*s == '-') {
c01051d4:	8b 45 08             	mov    0x8(%ebp),%eax
c01051d7:	0f b6 00             	movzbl (%eax),%eax
c01051da:	3c 2d                	cmp    $0x2d,%al
c01051dc:	75 0b                	jne    c01051e9 <strtol+0x53>
        s ++, neg = 1;
c01051de:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c01051e2:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)
    }

    // hex or octal base prefix
    if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x')) {
c01051e9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01051ed:	74 06                	je     c01051f5 <strtol+0x5f>
c01051ef:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
c01051f3:	75 24                	jne    c0105219 <strtol+0x83>
c01051f5:	8b 45 08             	mov    0x8(%ebp),%eax
c01051f8:	0f b6 00             	movzbl (%eax),%eax
c01051fb:	3c 30                	cmp    $0x30,%al
c01051fd:	75 1a                	jne    c0105219 <strtol+0x83>
c01051ff:	8b 45 08             	mov    0x8(%ebp),%eax
c0105202:	83 c0 01             	add    $0x1,%eax
c0105205:	0f b6 00             	movzbl (%eax),%eax
c0105208:	3c 78                	cmp    $0x78,%al
c010520a:	75 0d                	jne    c0105219 <strtol+0x83>
        s += 2, base = 16;
c010520c:	83 45 08 02          	addl   $0x2,0x8(%ebp)
c0105210:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
c0105217:	eb 2a                	jmp    c0105243 <strtol+0xad>
    }
    else if (base == 0 && s[0] == '0') {
c0105219:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c010521d:	75 17                	jne    c0105236 <strtol+0xa0>
c010521f:	8b 45 08             	mov    0x8(%ebp),%eax
c0105222:	0f b6 00             	movzbl (%eax),%eax
c0105225:	3c 30                	cmp    $0x30,%al
c0105227:	75 0d                	jne    c0105236 <strtol+0xa0>
        s ++, base = 8;
c0105229:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c010522d:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
c0105234:	eb 0d                	jmp    c0105243 <strtol+0xad>
    }
    else if (base == 0) {
c0105236:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c010523a:	75 07                	jne    c0105243 <strtol+0xad>
        base = 10;
c010523c:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

    // digits
    while (1) {
        int dig;

        if (*s >= '0' && *s <= '9') {
c0105243:	8b 45 08             	mov    0x8(%ebp),%eax
c0105246:	0f b6 00             	movzbl (%eax),%eax
c0105249:	3c 2f                	cmp    $0x2f,%al
c010524b:	7e 1b                	jle    c0105268 <strtol+0xd2>
c010524d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105250:	0f b6 00             	movzbl (%eax),%eax
c0105253:	3c 39                	cmp    $0x39,%al
c0105255:	7f 11                	jg     c0105268 <strtol+0xd2>
            dig = *s - '0';
c0105257:	8b 45 08             	mov    0x8(%ebp),%eax
c010525a:	0f b6 00             	movzbl (%eax),%eax
c010525d:	0f be c0             	movsbl %al,%eax
c0105260:	83 e8 30             	sub    $0x30,%eax
c0105263:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105266:	eb 48                	jmp    c01052b0 <strtol+0x11a>
        }
        else if (*s >= 'a' && *s <= 'z') {
c0105268:	8b 45 08             	mov    0x8(%ebp),%eax
c010526b:	0f b6 00             	movzbl (%eax),%eax
c010526e:	3c 60                	cmp    $0x60,%al
c0105270:	7e 1b                	jle    c010528d <strtol+0xf7>
c0105272:	8b 45 08             	mov    0x8(%ebp),%eax
c0105275:	0f b6 00             	movzbl (%eax),%eax
c0105278:	3c 7a                	cmp    $0x7a,%al
c010527a:	7f 11                	jg     c010528d <strtol+0xf7>
            dig = *s - 'a' + 10;
c010527c:	8b 45 08             	mov    0x8(%ebp),%eax
c010527f:	0f b6 00             	movzbl (%eax),%eax
c0105282:	0f be c0             	movsbl %al,%eax
c0105285:	83 e8 57             	sub    $0x57,%eax
c0105288:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010528b:	eb 23                	jmp    c01052b0 <strtol+0x11a>
        }
        else if (*s >= 'A' && *s <= 'Z') {
c010528d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105290:	0f b6 00             	movzbl (%eax),%eax
c0105293:	3c 40                	cmp    $0x40,%al
c0105295:	7e 3c                	jle    c01052d3 <strtol+0x13d>
c0105297:	8b 45 08             	mov    0x8(%ebp),%eax
c010529a:	0f b6 00             	movzbl (%eax),%eax
c010529d:	3c 5a                	cmp    $0x5a,%al
c010529f:	7f 32                	jg     c01052d3 <strtol+0x13d>
            dig = *s - 'A' + 10;
c01052a1:	8b 45 08             	mov    0x8(%ebp),%eax
c01052a4:	0f b6 00             	movzbl (%eax),%eax
c01052a7:	0f be c0             	movsbl %al,%eax
c01052aa:	83 e8 37             	sub    $0x37,%eax
c01052ad:	89 45 f4             	mov    %eax,-0xc(%ebp)
        }
        else {
            break;
        }
        if (dig >= base) {
c01052b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01052b3:	3b 45 10             	cmp    0x10(%ebp),%eax
c01052b6:	7d 1a                	jge    c01052d2 <strtol+0x13c>
            break;
        }
        s ++, val = (val * base) + dig;
c01052b8:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c01052bc:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01052bf:	0f af 45 10          	imul   0x10(%ebp),%eax
c01052c3:	89 c2                	mov    %eax,%edx
c01052c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01052c8:	01 d0                	add    %edx,%eax
c01052ca:	89 45 f8             	mov    %eax,-0x8(%ebp)
        // we don't properly detect overflow!
    }
c01052cd:	e9 71 ff ff ff       	jmp    c0105243 <strtol+0xad>
        }
        else {
            break;
        }
        if (dig >= base) {
            break;
c01052d2:	90                   	nop
        }
        s ++, val = (val * base) + dig;
        // we don't properly detect overflow!
    }

    if (endptr) {
c01052d3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c01052d7:	74 08                	je     c01052e1 <strtol+0x14b>
        *endptr = (char *) s;
c01052d9:	8b 45 0c             	mov    0xc(%ebp),%eax
c01052dc:	8b 55 08             	mov    0x8(%ebp),%edx
c01052df:	89 10                	mov    %edx,(%eax)
    }
    return (neg ? -val : val);
c01052e1:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
c01052e5:	74 07                	je     c01052ee <strtol+0x158>
c01052e7:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01052ea:	f7 d8                	neg    %eax
c01052ec:	eb 03                	jmp    c01052f1 <strtol+0x15b>
c01052ee:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
c01052f1:	c9                   	leave  
c01052f2:	c3                   	ret    

c01052f3 <memset>:
 * @n:      number of bytes to be set to the value
 *
 * The memset() function returns @s.
 * */
void *
memset(void *s, char c, size_t n) {
c01052f3:	55                   	push   %ebp
c01052f4:	89 e5                	mov    %esp,%ebp
c01052f6:	57                   	push   %edi
c01052f7:	83 ec 24             	sub    $0x24,%esp
c01052fa:	8b 45 0c             	mov    0xc(%ebp),%eax
c01052fd:	88 45 d8             	mov    %al,-0x28(%ebp)
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
c0105300:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
c0105304:	8b 55 08             	mov    0x8(%ebp),%edx
c0105307:	89 55 f8             	mov    %edx,-0x8(%ebp)
c010530a:	88 45 f7             	mov    %al,-0x9(%ebp)
c010530d:	8b 45 10             	mov    0x10(%ebp),%eax
c0105310:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_MEMSET
#define __HAVE_ARCH_MEMSET
static inline void *
__memset(void *s, char c, size_t n) {
    int d0, d1;
    asm volatile (
c0105313:	8b 4d f0             	mov    -0x10(%ebp),%ecx
c0105316:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
c010531a:	8b 55 f8             	mov    -0x8(%ebp),%edx
c010531d:	89 d7                	mov    %edx,%edi
c010531f:	f3 aa                	rep stos %al,%es:(%edi)
c0105321:	89 fa                	mov    %edi,%edx
c0105323:	89 4d ec             	mov    %ecx,-0x14(%ebp)
c0105326:	89 55 e8             	mov    %edx,-0x18(%ebp)
        "rep; stosb;"
        : "=&c" (d0), "=&D" (d1)
        : "0" (n), "a" (c), "1" (s)
        : "memory");
    return s;
c0105329:	8b 45 f8             	mov    -0x8(%ebp),%eax
c010532c:	90                   	nop
    while (n -- > 0) {
        *p ++ = c;
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
c010532d:	83 c4 24             	add    $0x24,%esp
c0105330:	5f                   	pop    %edi
c0105331:	5d                   	pop    %ebp
c0105332:	c3                   	ret    

c0105333 <memmove>:
 * @n:      number of bytes to copy
 *
 * The memmove() function returns @dst.
 * */
void *
memmove(void *dst, const void *src, size_t n) {
c0105333:	55                   	push   %ebp
c0105334:	89 e5                	mov    %esp,%ebp
c0105336:	57                   	push   %edi
c0105337:	56                   	push   %esi
c0105338:	53                   	push   %ebx
c0105339:	83 ec 30             	sub    $0x30,%esp
c010533c:	8b 45 08             	mov    0x8(%ebp),%eax
c010533f:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105342:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105345:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105348:	8b 45 10             	mov    0x10(%ebp),%eax
c010534b:	89 45 e8             	mov    %eax,-0x18(%ebp)

#ifndef __HAVE_ARCH_MEMMOVE
#define __HAVE_ARCH_MEMMOVE
static inline void *
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
c010534e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105351:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0105354:	73 42                	jae    c0105398 <memmove+0x65>
c0105356:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105359:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c010535c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010535f:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0105362:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105365:	89 45 dc             	mov    %eax,-0x24(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c0105368:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010536b:	c1 e8 02             	shr    $0x2,%eax
c010536e:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
c0105370:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0105373:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105376:	89 d7                	mov    %edx,%edi
c0105378:	89 c6                	mov    %eax,%esi
c010537a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c010537c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
c010537f:	83 e1 03             	and    $0x3,%ecx
c0105382:	74 02                	je     c0105386 <memmove+0x53>
c0105384:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c0105386:	89 f0                	mov    %esi,%eax
c0105388:	89 fa                	mov    %edi,%edx
c010538a:	89 4d d8             	mov    %ecx,-0x28(%ebp)
c010538d:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0105390:	89 45 d0             	mov    %eax,-0x30(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
c0105393:	8b 45 e4             	mov    -0x1c(%ebp),%eax
#ifdef __HAVE_ARCH_MEMMOVE
    return __memmove(dst, src, n);
c0105396:	eb 36                	jmp    c01053ce <memmove+0x9b>
    asm volatile (
        "std;"
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
c0105398:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010539b:	8d 50 ff             	lea    -0x1(%eax),%edx
c010539e:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01053a1:	01 c2                	add    %eax,%edx
c01053a3:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01053a6:	8d 48 ff             	lea    -0x1(%eax),%ecx
c01053a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01053ac:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
        return __memcpy(dst, src, n);
    }
    int d0, d1, d2;
    asm volatile (
c01053af:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01053b2:	89 c1                	mov    %eax,%ecx
c01053b4:	89 d8                	mov    %ebx,%eax
c01053b6:	89 d6                	mov    %edx,%esi
c01053b8:	89 c7                	mov    %eax,%edi
c01053ba:	fd                   	std    
c01053bb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c01053bd:	fc                   	cld    
c01053be:	89 f8                	mov    %edi,%eax
c01053c0:	89 f2                	mov    %esi,%edx
c01053c2:	89 4d cc             	mov    %ecx,-0x34(%ebp)
c01053c5:	89 55 c8             	mov    %edx,-0x38(%ebp)
c01053c8:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
        : "memory");
    return dst;
c01053cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
            *d ++ = *s ++;
        }
    }
    return dst;
#endif /* __HAVE_ARCH_MEMMOVE */
}
c01053ce:	83 c4 30             	add    $0x30,%esp
c01053d1:	5b                   	pop    %ebx
c01053d2:	5e                   	pop    %esi
c01053d3:	5f                   	pop    %edi
c01053d4:	5d                   	pop    %ebp
c01053d5:	c3                   	ret    

c01053d6 <memcpy>:
 * it always copies exactly @n bytes. To avoid overflows, the size of arrays pointed
 * by both @src and @dst, should be at least @n bytes, and should not overlap
 * (for overlapping memory area, memmove is a safer approach).
 * */
void *
memcpy(void *dst, const void *src, size_t n) {
c01053d6:	55                   	push   %ebp
c01053d7:	89 e5                	mov    %esp,%ebp
c01053d9:	57                   	push   %edi
c01053da:	56                   	push   %esi
c01053db:	83 ec 20             	sub    $0x20,%esp
c01053de:	8b 45 08             	mov    0x8(%ebp),%eax
c01053e1:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01053e4:	8b 45 0c             	mov    0xc(%ebp),%eax
c01053e7:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01053ea:	8b 45 10             	mov    0x10(%ebp),%eax
c01053ed:	89 45 ec             	mov    %eax,-0x14(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c01053f0:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01053f3:	c1 e8 02             	shr    $0x2,%eax
c01053f6:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
c01053f8:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01053fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01053fe:	89 d7                	mov    %edx,%edi
c0105400:	89 c6                	mov    %eax,%esi
c0105402:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c0105404:	8b 4d ec             	mov    -0x14(%ebp),%ecx
c0105407:	83 e1 03             	and    $0x3,%ecx
c010540a:	74 02                	je     c010540e <memcpy+0x38>
c010540c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c010540e:	89 f0                	mov    %esi,%eax
c0105410:	89 fa                	mov    %edi,%edx
c0105412:	89 4d e8             	mov    %ecx,-0x18(%ebp)
c0105415:	89 55 e4             	mov    %edx,-0x1c(%ebp)
c0105418:	89 45 e0             	mov    %eax,-0x20(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
c010541b:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
c010541e:	90                   	nop
    while (n -- > 0) {
        *d ++ = *s ++;
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
c010541f:	83 c4 20             	add    $0x20,%esp
c0105422:	5e                   	pop    %esi
c0105423:	5f                   	pop    %edi
c0105424:	5d                   	pop    %ebp
c0105425:	c3                   	ret    

c0105426 <memcmp>:
 *   match in both memory blocks has a greater value in @v1 than in @v2
 *   as if evaluated as unsigned char values;
 * - And a value less than zero indicates the opposite.
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
c0105426:	55                   	push   %ebp
c0105427:	89 e5                	mov    %esp,%ebp
c0105429:	83 ec 10             	sub    $0x10,%esp
    const char *s1 = (const char *)v1;
c010542c:	8b 45 08             	mov    0x8(%ebp),%eax
c010542f:	89 45 fc             	mov    %eax,-0x4(%ebp)
    const char *s2 = (const char *)v2;
c0105432:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105435:	89 45 f8             	mov    %eax,-0x8(%ebp)
    while (n -- > 0) {
c0105438:	eb 30                	jmp    c010546a <memcmp+0x44>
        if (*s1 != *s2) {
c010543a:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010543d:	0f b6 10             	movzbl (%eax),%edx
c0105440:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0105443:	0f b6 00             	movzbl (%eax),%eax
c0105446:	38 c2                	cmp    %al,%dl
c0105448:	74 18                	je     c0105462 <memcmp+0x3c>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
c010544a:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010544d:	0f b6 00             	movzbl (%eax),%eax
c0105450:	0f b6 d0             	movzbl %al,%edx
c0105453:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0105456:	0f b6 00             	movzbl (%eax),%eax
c0105459:	0f b6 c0             	movzbl %al,%eax
c010545c:	29 c2                	sub    %eax,%edx
c010545e:	89 d0                	mov    %edx,%eax
c0105460:	eb 1a                	jmp    c010547c <memcmp+0x56>
        }
        s1 ++, s2 ++;
c0105462:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c0105466:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
c010546a:	8b 45 10             	mov    0x10(%ebp),%eax
c010546d:	8d 50 ff             	lea    -0x1(%eax),%edx
c0105470:	89 55 10             	mov    %edx,0x10(%ebp)
c0105473:	85 c0                	test   %eax,%eax
c0105475:	75 c3                	jne    c010543a <memcmp+0x14>
        if (*s1 != *s2) {
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
    }
    return 0;
c0105477:	b8 00 00 00 00       	mov    $0x0,%eax
}
c010547c:	c9                   	leave  
c010547d:	c3                   	ret    

c010547e <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
c010547e:	55                   	push   %ebp
c010547f:	89 e5                	mov    %esp,%ebp
c0105481:	83 ec 38             	sub    $0x38,%esp
c0105484:	8b 45 10             	mov    0x10(%ebp),%eax
c0105487:	89 45 d0             	mov    %eax,-0x30(%ebp)
c010548a:	8b 45 14             	mov    0x14(%ebp),%eax
c010548d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    unsigned long long result = num;
c0105490:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0105493:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0105496:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0105499:	89 55 ec             	mov    %edx,-0x14(%ebp)
    unsigned mod = do_div(result, base);
c010549c:	8b 45 18             	mov    0x18(%ebp),%eax
c010549f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01054a2:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01054a5:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01054a8:	89 45 e0             	mov    %eax,-0x20(%ebp)
c01054ab:	89 55 f0             	mov    %edx,-0x10(%ebp)
c01054ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01054b1:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01054b4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01054b8:	74 1c                	je     c01054d6 <printnum+0x58>
c01054ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01054bd:	ba 00 00 00 00       	mov    $0x0,%edx
c01054c2:	f7 75 e4             	divl   -0x1c(%ebp)
c01054c5:	89 55 f4             	mov    %edx,-0xc(%ebp)
c01054c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01054cb:	ba 00 00 00 00       	mov    $0x0,%edx
c01054d0:	f7 75 e4             	divl   -0x1c(%ebp)
c01054d3:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01054d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01054d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01054dc:	f7 75 e4             	divl   -0x1c(%ebp)
c01054df:	89 45 e0             	mov    %eax,-0x20(%ebp)
c01054e2:	89 55 dc             	mov    %edx,-0x24(%ebp)
c01054e5:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01054e8:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01054eb:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01054ee:	89 55 ec             	mov    %edx,-0x14(%ebp)
c01054f1:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01054f4:	89 45 d8             	mov    %eax,-0x28(%ebp)

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
c01054f7:	8b 45 18             	mov    0x18(%ebp),%eax
c01054fa:	ba 00 00 00 00       	mov    $0x0,%edx
c01054ff:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0105502:	77 41                	ja     c0105545 <printnum+0xc7>
c0105504:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0105507:	72 05                	jb     c010550e <printnum+0x90>
c0105509:	3b 45 d0             	cmp    -0x30(%ebp),%eax
c010550c:	77 37                	ja     c0105545 <printnum+0xc7>
        printnum(putch, putdat, result, base, width - 1, padc);
c010550e:	8b 45 1c             	mov    0x1c(%ebp),%eax
c0105511:	83 e8 01             	sub    $0x1,%eax
c0105514:	83 ec 04             	sub    $0x4,%esp
c0105517:	ff 75 20             	pushl  0x20(%ebp)
c010551a:	50                   	push   %eax
c010551b:	ff 75 18             	pushl  0x18(%ebp)
c010551e:	ff 75 ec             	pushl  -0x14(%ebp)
c0105521:	ff 75 e8             	pushl  -0x18(%ebp)
c0105524:	ff 75 0c             	pushl  0xc(%ebp)
c0105527:	ff 75 08             	pushl  0x8(%ebp)
c010552a:	e8 4f ff ff ff       	call   c010547e <printnum>
c010552f:	83 c4 20             	add    $0x20,%esp
c0105532:	eb 1b                	jmp    c010554f <printnum+0xd1>
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
            putch(padc, putdat);
c0105534:	83 ec 08             	sub    $0x8,%esp
c0105537:	ff 75 0c             	pushl  0xc(%ebp)
c010553a:	ff 75 20             	pushl  0x20(%ebp)
c010553d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105540:	ff d0                	call   *%eax
c0105542:	83 c4 10             	add    $0x10,%esp
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
c0105545:	83 6d 1c 01          	subl   $0x1,0x1c(%ebp)
c0105549:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
c010554d:	7f e5                	jg     c0105534 <printnum+0xb6>
            putch(padc, putdat);
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
c010554f:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0105552:	05 64 6c 10 c0       	add    $0xc0106c64,%eax
c0105557:	0f b6 00             	movzbl (%eax),%eax
c010555a:	0f be c0             	movsbl %al,%eax
c010555d:	83 ec 08             	sub    $0x8,%esp
c0105560:	ff 75 0c             	pushl  0xc(%ebp)
c0105563:	50                   	push   %eax
c0105564:	8b 45 08             	mov    0x8(%ebp),%eax
c0105567:	ff d0                	call   *%eax
c0105569:	83 c4 10             	add    $0x10,%esp
}
c010556c:	90                   	nop
c010556d:	c9                   	leave  
c010556e:	c3                   	ret    

c010556f <getuint>:
 * getuint - get an unsigned int of various possible sizes from a varargs list
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static unsigned long long
getuint(va_list *ap, int lflag) {
c010556f:	55                   	push   %ebp
c0105570:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
c0105572:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
c0105576:	7e 14                	jle    c010558c <getuint+0x1d>
        return va_arg(*ap, unsigned long long);
c0105578:	8b 45 08             	mov    0x8(%ebp),%eax
c010557b:	8b 00                	mov    (%eax),%eax
c010557d:	8d 48 08             	lea    0x8(%eax),%ecx
c0105580:	8b 55 08             	mov    0x8(%ebp),%edx
c0105583:	89 0a                	mov    %ecx,(%edx)
c0105585:	8b 50 04             	mov    0x4(%eax),%edx
c0105588:	8b 00                	mov    (%eax),%eax
c010558a:	eb 30                	jmp    c01055bc <getuint+0x4d>
    }
    else if (lflag) {
c010558c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0105590:	74 16                	je     c01055a8 <getuint+0x39>
        return va_arg(*ap, unsigned long);
c0105592:	8b 45 08             	mov    0x8(%ebp),%eax
c0105595:	8b 00                	mov    (%eax),%eax
c0105597:	8d 48 04             	lea    0x4(%eax),%ecx
c010559a:	8b 55 08             	mov    0x8(%ebp),%edx
c010559d:	89 0a                	mov    %ecx,(%edx)
c010559f:	8b 00                	mov    (%eax),%eax
c01055a1:	ba 00 00 00 00       	mov    $0x0,%edx
c01055a6:	eb 14                	jmp    c01055bc <getuint+0x4d>
    }
    else {
        return va_arg(*ap, unsigned int);
c01055a8:	8b 45 08             	mov    0x8(%ebp),%eax
c01055ab:	8b 00                	mov    (%eax),%eax
c01055ad:	8d 48 04             	lea    0x4(%eax),%ecx
c01055b0:	8b 55 08             	mov    0x8(%ebp),%edx
c01055b3:	89 0a                	mov    %ecx,(%edx)
c01055b5:	8b 00                	mov    (%eax),%eax
c01055b7:	ba 00 00 00 00       	mov    $0x0,%edx
    }
}
c01055bc:	5d                   	pop    %ebp
c01055bd:	c3                   	ret    

c01055be <getint>:
 * getint - same as getuint but signed, we can't use getuint because of sign extension
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static long long
getint(va_list *ap, int lflag) {
c01055be:	55                   	push   %ebp
c01055bf:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
c01055c1:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
c01055c5:	7e 14                	jle    c01055db <getint+0x1d>
        return va_arg(*ap, long long);
c01055c7:	8b 45 08             	mov    0x8(%ebp),%eax
c01055ca:	8b 00                	mov    (%eax),%eax
c01055cc:	8d 48 08             	lea    0x8(%eax),%ecx
c01055cf:	8b 55 08             	mov    0x8(%ebp),%edx
c01055d2:	89 0a                	mov    %ecx,(%edx)
c01055d4:	8b 50 04             	mov    0x4(%eax),%edx
c01055d7:	8b 00                	mov    (%eax),%eax
c01055d9:	eb 28                	jmp    c0105603 <getint+0x45>
    }
    else if (lflag) {
c01055db:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c01055df:	74 12                	je     c01055f3 <getint+0x35>
        return va_arg(*ap, long);
c01055e1:	8b 45 08             	mov    0x8(%ebp),%eax
c01055e4:	8b 00                	mov    (%eax),%eax
c01055e6:	8d 48 04             	lea    0x4(%eax),%ecx
c01055e9:	8b 55 08             	mov    0x8(%ebp),%edx
c01055ec:	89 0a                	mov    %ecx,(%edx)
c01055ee:	8b 00                	mov    (%eax),%eax
c01055f0:	99                   	cltd   
c01055f1:	eb 10                	jmp    c0105603 <getint+0x45>
    }
    else {
        return va_arg(*ap, int);
c01055f3:	8b 45 08             	mov    0x8(%ebp),%eax
c01055f6:	8b 00                	mov    (%eax),%eax
c01055f8:	8d 48 04             	lea    0x4(%eax),%ecx
c01055fb:	8b 55 08             	mov    0x8(%ebp),%edx
c01055fe:	89 0a                	mov    %ecx,(%edx)
c0105600:	8b 00                	mov    (%eax),%eax
c0105602:	99                   	cltd   
    }
}
c0105603:	5d                   	pop    %ebp
c0105604:	c3                   	ret    

c0105605 <printfmt>:
 * @putch:      specified putch function, print a single character
 * @putdat:     used by @putch function
 * @fmt:        the format string to use
 * */
void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
c0105605:	55                   	push   %ebp
c0105606:	89 e5                	mov    %esp,%ebp
c0105608:	83 ec 18             	sub    $0x18,%esp
    va_list ap;

    va_start(ap, fmt);
c010560b:	8d 45 14             	lea    0x14(%ebp),%eax
c010560e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    vprintfmt(putch, putdat, fmt, ap);
c0105611:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105614:	50                   	push   %eax
c0105615:	ff 75 10             	pushl  0x10(%ebp)
c0105618:	ff 75 0c             	pushl  0xc(%ebp)
c010561b:	ff 75 08             	pushl  0x8(%ebp)
c010561e:	e8 06 00 00 00       	call   c0105629 <vprintfmt>
c0105623:	83 c4 10             	add    $0x10,%esp
    va_end(ap);
}
c0105626:	90                   	nop
c0105627:	c9                   	leave  
c0105628:	c3                   	ret    

c0105629 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
c0105629:	55                   	push   %ebp
c010562a:	89 e5                	mov    %esp,%ebp
c010562c:	56                   	push   %esi
c010562d:	53                   	push   %ebx
c010562e:	83 ec 20             	sub    $0x20,%esp
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c0105631:	eb 17                	jmp    c010564a <vprintfmt+0x21>
            if (ch == '\0') {
c0105633:	85 db                	test   %ebx,%ebx
c0105635:	0f 84 8e 03 00 00    	je     c01059c9 <vprintfmt+0x3a0>
                return;
            }
            putch(ch, putdat);
c010563b:	83 ec 08             	sub    $0x8,%esp
c010563e:	ff 75 0c             	pushl  0xc(%ebp)
c0105641:	53                   	push   %ebx
c0105642:	8b 45 08             	mov    0x8(%ebp),%eax
c0105645:	ff d0                	call   *%eax
c0105647:	83 c4 10             	add    $0x10,%esp
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c010564a:	8b 45 10             	mov    0x10(%ebp),%eax
c010564d:	8d 50 01             	lea    0x1(%eax),%edx
c0105650:	89 55 10             	mov    %edx,0x10(%ebp)
c0105653:	0f b6 00             	movzbl (%eax),%eax
c0105656:	0f b6 d8             	movzbl %al,%ebx
c0105659:	83 fb 25             	cmp    $0x25,%ebx
c010565c:	75 d5                	jne    c0105633 <vprintfmt+0xa>
            }
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
c010565e:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
        width = precision = -1;
c0105662:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
c0105669:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010566c:	89 45 e8             	mov    %eax,-0x18(%ebp)
        lflag = altflag = 0;
c010566f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0105676:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105679:	89 45 e0             	mov    %eax,-0x20(%ebp)

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
c010567c:	8b 45 10             	mov    0x10(%ebp),%eax
c010567f:	8d 50 01             	lea    0x1(%eax),%edx
c0105682:	89 55 10             	mov    %edx,0x10(%ebp)
c0105685:	0f b6 00             	movzbl (%eax),%eax
c0105688:	0f b6 d8             	movzbl %al,%ebx
c010568b:	8d 43 dd             	lea    -0x23(%ebx),%eax
c010568e:	83 f8 55             	cmp    $0x55,%eax
c0105691:	0f 87 05 03 00 00    	ja     c010599c <vprintfmt+0x373>
c0105697:	8b 04 85 88 6c 10 c0 	mov    -0x3fef9378(,%eax,4),%eax
c010569e:	ff e0                	jmp    *%eax

        // flag to pad on the right
        case '-':
            padc = '-';
c01056a0:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
            goto reswitch;
c01056a4:	eb d6                	jmp    c010567c <vprintfmt+0x53>

        // flag to pad with 0's instead of spaces
        case '0':
            padc = '0';
c01056a6:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
            goto reswitch;
c01056aa:	eb d0                	jmp    c010567c <vprintfmt+0x53>

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
c01056ac:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
                precision = precision * 10 + ch - '0';
c01056b3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01056b6:	89 d0                	mov    %edx,%eax
c01056b8:	c1 e0 02             	shl    $0x2,%eax
c01056bb:	01 d0                	add    %edx,%eax
c01056bd:	01 c0                	add    %eax,%eax
c01056bf:	01 d8                	add    %ebx,%eax
c01056c1:	83 e8 30             	sub    $0x30,%eax
c01056c4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
                ch = *fmt;
c01056c7:	8b 45 10             	mov    0x10(%ebp),%eax
c01056ca:	0f b6 00             	movzbl (%eax),%eax
c01056cd:	0f be d8             	movsbl %al,%ebx
                if (ch < '0' || ch > '9') {
c01056d0:	83 fb 2f             	cmp    $0x2f,%ebx
c01056d3:	7e 39                	jle    c010570e <vprintfmt+0xe5>
c01056d5:	83 fb 39             	cmp    $0x39,%ebx
c01056d8:	7f 34                	jg     c010570e <vprintfmt+0xe5>
            padc = '0';
            goto reswitch;

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
c01056da:	83 45 10 01          	addl   $0x1,0x10(%ebp)
                precision = precision * 10 + ch - '0';
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
c01056de:	eb d3                	jmp    c01056b3 <vprintfmt+0x8a>
            goto process_precision;

        case '*':
            precision = va_arg(ap, int);
c01056e0:	8b 45 14             	mov    0x14(%ebp),%eax
c01056e3:	8d 50 04             	lea    0x4(%eax),%edx
c01056e6:	89 55 14             	mov    %edx,0x14(%ebp)
c01056e9:	8b 00                	mov    (%eax),%eax
c01056eb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            goto process_precision;
c01056ee:	eb 1f                	jmp    c010570f <vprintfmt+0xe6>

        case '.':
            if (width < 0)
c01056f0:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c01056f4:	79 86                	jns    c010567c <vprintfmt+0x53>
                width = 0;
c01056f6:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
            goto reswitch;
c01056fd:	e9 7a ff ff ff       	jmp    c010567c <vprintfmt+0x53>

        case '#':
            altflag = 1;
c0105702:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
            goto reswitch;
c0105709:	e9 6e ff ff ff       	jmp    c010567c <vprintfmt+0x53>
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
            goto process_precision;
c010570e:	90                   	nop
        case '#':
            altflag = 1;
            goto reswitch;

        process_precision:
            if (width < 0)
c010570f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0105713:	0f 89 63 ff ff ff    	jns    c010567c <vprintfmt+0x53>
                width = precision, precision = -1;
c0105719:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010571c:	89 45 e8             	mov    %eax,-0x18(%ebp)
c010571f:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
            goto reswitch;
c0105726:	e9 51 ff ff ff       	jmp    c010567c <vprintfmt+0x53>

        // long flag (doubled for long long)
        case 'l':
            lflag ++;
c010572b:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
            goto reswitch;
c010572f:	e9 48 ff ff ff       	jmp    c010567c <vprintfmt+0x53>

        // character
        case 'c':
            putch(va_arg(ap, int), putdat);
c0105734:	8b 45 14             	mov    0x14(%ebp),%eax
c0105737:	8d 50 04             	lea    0x4(%eax),%edx
c010573a:	89 55 14             	mov    %edx,0x14(%ebp)
c010573d:	8b 00                	mov    (%eax),%eax
c010573f:	83 ec 08             	sub    $0x8,%esp
c0105742:	ff 75 0c             	pushl  0xc(%ebp)
c0105745:	50                   	push   %eax
c0105746:	8b 45 08             	mov    0x8(%ebp),%eax
c0105749:	ff d0                	call   *%eax
c010574b:	83 c4 10             	add    $0x10,%esp
            break;
c010574e:	e9 71 02 00 00       	jmp    c01059c4 <vprintfmt+0x39b>

        // error message
        case 'e':
            err = va_arg(ap, int);
c0105753:	8b 45 14             	mov    0x14(%ebp),%eax
c0105756:	8d 50 04             	lea    0x4(%eax),%edx
c0105759:	89 55 14             	mov    %edx,0x14(%ebp)
c010575c:	8b 18                	mov    (%eax),%ebx
            if (err < 0) {
c010575e:	85 db                	test   %ebx,%ebx
c0105760:	79 02                	jns    c0105764 <vprintfmt+0x13b>
                err = -err;
c0105762:	f7 db                	neg    %ebx
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
c0105764:	83 fb 06             	cmp    $0x6,%ebx
c0105767:	7f 0b                	jg     c0105774 <vprintfmt+0x14b>
c0105769:	8b 34 9d 48 6c 10 c0 	mov    -0x3fef93b8(,%ebx,4),%esi
c0105770:	85 f6                	test   %esi,%esi
c0105772:	75 19                	jne    c010578d <vprintfmt+0x164>
                printfmt(putch, putdat, "error %d", err);
c0105774:	53                   	push   %ebx
c0105775:	68 75 6c 10 c0       	push   $0xc0106c75
c010577a:	ff 75 0c             	pushl  0xc(%ebp)
c010577d:	ff 75 08             	pushl  0x8(%ebp)
c0105780:	e8 80 fe ff ff       	call   c0105605 <printfmt>
c0105785:	83 c4 10             	add    $0x10,%esp
            }
            else {
                printfmt(putch, putdat, "%s", p);
            }
            break;
c0105788:	e9 37 02 00 00       	jmp    c01059c4 <vprintfmt+0x39b>
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
                printfmt(putch, putdat, "error %d", err);
            }
            else {
                printfmt(putch, putdat, "%s", p);
c010578d:	56                   	push   %esi
c010578e:	68 7e 6c 10 c0       	push   $0xc0106c7e
c0105793:	ff 75 0c             	pushl  0xc(%ebp)
c0105796:	ff 75 08             	pushl  0x8(%ebp)
c0105799:	e8 67 fe ff ff       	call   c0105605 <printfmt>
c010579e:	83 c4 10             	add    $0x10,%esp
            }
            break;
c01057a1:	e9 1e 02 00 00       	jmp    c01059c4 <vprintfmt+0x39b>

        // string
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
c01057a6:	8b 45 14             	mov    0x14(%ebp),%eax
c01057a9:	8d 50 04             	lea    0x4(%eax),%edx
c01057ac:	89 55 14             	mov    %edx,0x14(%ebp)
c01057af:	8b 30                	mov    (%eax),%esi
c01057b1:	85 f6                	test   %esi,%esi
c01057b3:	75 05                	jne    c01057ba <vprintfmt+0x191>
                p = "(null)";
c01057b5:	be 81 6c 10 c0       	mov    $0xc0106c81,%esi
            }
            if (width > 0 && padc != '-') {
c01057ba:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c01057be:	7e 76                	jle    c0105836 <vprintfmt+0x20d>
c01057c0:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
c01057c4:	74 70                	je     c0105836 <vprintfmt+0x20d>
                for (width -= strnlen(p, precision); width > 0; width --) {
c01057c6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01057c9:	83 ec 08             	sub    $0x8,%esp
c01057cc:	50                   	push   %eax
c01057cd:	56                   	push   %esi
c01057ce:	e8 17 f8 ff ff       	call   c0104fea <strnlen>
c01057d3:	83 c4 10             	add    $0x10,%esp
c01057d6:	89 c2                	mov    %eax,%edx
c01057d8:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01057db:	29 d0                	sub    %edx,%eax
c01057dd:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01057e0:	eb 17                	jmp    c01057f9 <vprintfmt+0x1d0>
                    putch(padc, putdat);
c01057e2:	0f be 45 db          	movsbl -0x25(%ebp),%eax
c01057e6:	83 ec 08             	sub    $0x8,%esp
c01057e9:	ff 75 0c             	pushl  0xc(%ebp)
c01057ec:	50                   	push   %eax
c01057ed:	8b 45 08             	mov    0x8(%ebp),%eax
c01057f0:	ff d0                	call   *%eax
c01057f2:	83 c4 10             	add    $0x10,%esp
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
                p = "(null)";
            }
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
c01057f5:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
c01057f9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c01057fd:	7f e3                	jg     c01057e2 <vprintfmt+0x1b9>
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
c01057ff:	eb 35                	jmp    c0105836 <vprintfmt+0x20d>
                if (altflag && (ch < ' ' || ch > '~')) {
c0105801:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0105805:	74 1c                	je     c0105823 <vprintfmt+0x1fa>
c0105807:	83 fb 1f             	cmp    $0x1f,%ebx
c010580a:	7e 05                	jle    c0105811 <vprintfmt+0x1e8>
c010580c:	83 fb 7e             	cmp    $0x7e,%ebx
c010580f:	7e 12                	jle    c0105823 <vprintfmt+0x1fa>
                    putch('?', putdat);
c0105811:	83 ec 08             	sub    $0x8,%esp
c0105814:	ff 75 0c             	pushl  0xc(%ebp)
c0105817:	6a 3f                	push   $0x3f
c0105819:	8b 45 08             	mov    0x8(%ebp),%eax
c010581c:	ff d0                	call   *%eax
c010581e:	83 c4 10             	add    $0x10,%esp
c0105821:	eb 0f                	jmp    c0105832 <vprintfmt+0x209>
                }
                else {
                    putch(ch, putdat);
c0105823:	83 ec 08             	sub    $0x8,%esp
c0105826:	ff 75 0c             	pushl  0xc(%ebp)
c0105829:	53                   	push   %ebx
c010582a:	8b 45 08             	mov    0x8(%ebp),%eax
c010582d:	ff d0                	call   *%eax
c010582f:	83 c4 10             	add    $0x10,%esp
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
c0105832:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
c0105836:	89 f0                	mov    %esi,%eax
c0105838:	8d 70 01             	lea    0x1(%eax),%esi
c010583b:	0f b6 00             	movzbl (%eax),%eax
c010583e:	0f be d8             	movsbl %al,%ebx
c0105841:	85 db                	test   %ebx,%ebx
c0105843:	74 26                	je     c010586b <vprintfmt+0x242>
c0105845:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0105849:	78 b6                	js     c0105801 <vprintfmt+0x1d8>
c010584b:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
c010584f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0105853:	79 ac                	jns    c0105801 <vprintfmt+0x1d8>
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
c0105855:	eb 14                	jmp    c010586b <vprintfmt+0x242>
                putch(' ', putdat);
c0105857:	83 ec 08             	sub    $0x8,%esp
c010585a:	ff 75 0c             	pushl  0xc(%ebp)
c010585d:	6a 20                	push   $0x20
c010585f:	8b 45 08             	mov    0x8(%ebp),%eax
c0105862:	ff d0                	call   *%eax
c0105864:	83 c4 10             	add    $0x10,%esp
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
c0105867:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
c010586b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c010586f:	7f e6                	jg     c0105857 <vprintfmt+0x22e>
                putch(' ', putdat);
            }
            break;
c0105871:	e9 4e 01 00 00       	jmp    c01059c4 <vprintfmt+0x39b>

        // (signed) decimal
        case 'd':
            num = getint(&ap, lflag);
c0105876:	83 ec 08             	sub    $0x8,%esp
c0105879:	ff 75 e0             	pushl  -0x20(%ebp)
c010587c:	8d 45 14             	lea    0x14(%ebp),%eax
c010587f:	50                   	push   %eax
c0105880:	e8 39 fd ff ff       	call   c01055be <getint>
c0105885:	83 c4 10             	add    $0x10,%esp
c0105888:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010588b:	89 55 f4             	mov    %edx,-0xc(%ebp)
            if ((long long)num < 0) {
c010588e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105891:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105894:	85 d2                	test   %edx,%edx
c0105896:	79 23                	jns    c01058bb <vprintfmt+0x292>
                putch('-', putdat);
c0105898:	83 ec 08             	sub    $0x8,%esp
c010589b:	ff 75 0c             	pushl  0xc(%ebp)
c010589e:	6a 2d                	push   $0x2d
c01058a0:	8b 45 08             	mov    0x8(%ebp),%eax
c01058a3:	ff d0                	call   *%eax
c01058a5:	83 c4 10             	add    $0x10,%esp
                num = -(long long)num;
c01058a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01058ab:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01058ae:	f7 d8                	neg    %eax
c01058b0:	83 d2 00             	adc    $0x0,%edx
c01058b3:	f7 da                	neg    %edx
c01058b5:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01058b8:	89 55 f4             	mov    %edx,-0xc(%ebp)
            }
            base = 10;
c01058bb:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
c01058c2:	e9 9f 00 00 00       	jmp    c0105966 <vprintfmt+0x33d>

        // unsigned decimal
        case 'u':
            num = getuint(&ap, lflag);
c01058c7:	83 ec 08             	sub    $0x8,%esp
c01058ca:	ff 75 e0             	pushl  -0x20(%ebp)
c01058cd:	8d 45 14             	lea    0x14(%ebp),%eax
c01058d0:	50                   	push   %eax
c01058d1:	e8 99 fc ff ff       	call   c010556f <getuint>
c01058d6:	83 c4 10             	add    $0x10,%esp
c01058d9:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01058dc:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 10;
c01058df:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
c01058e6:	eb 7e                	jmp    c0105966 <vprintfmt+0x33d>

        // (unsigned) octal
        case 'o':
            num = getuint(&ap, lflag);
c01058e8:	83 ec 08             	sub    $0x8,%esp
c01058eb:	ff 75 e0             	pushl  -0x20(%ebp)
c01058ee:	8d 45 14             	lea    0x14(%ebp),%eax
c01058f1:	50                   	push   %eax
c01058f2:	e8 78 fc ff ff       	call   c010556f <getuint>
c01058f7:	83 c4 10             	add    $0x10,%esp
c01058fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01058fd:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 8;
c0105900:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
            goto number;
c0105907:	eb 5d                	jmp    c0105966 <vprintfmt+0x33d>

        // pointer
        case 'p':
            putch('0', putdat);
c0105909:	83 ec 08             	sub    $0x8,%esp
c010590c:	ff 75 0c             	pushl  0xc(%ebp)
c010590f:	6a 30                	push   $0x30
c0105911:	8b 45 08             	mov    0x8(%ebp),%eax
c0105914:	ff d0                	call   *%eax
c0105916:	83 c4 10             	add    $0x10,%esp
            putch('x', putdat);
c0105919:	83 ec 08             	sub    $0x8,%esp
c010591c:	ff 75 0c             	pushl  0xc(%ebp)
c010591f:	6a 78                	push   $0x78
c0105921:	8b 45 08             	mov    0x8(%ebp),%eax
c0105924:	ff d0                	call   *%eax
c0105926:	83 c4 10             	add    $0x10,%esp
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
c0105929:	8b 45 14             	mov    0x14(%ebp),%eax
c010592c:	8d 50 04             	lea    0x4(%eax),%edx
c010592f:	89 55 14             	mov    %edx,0x14(%ebp)
c0105932:	8b 00                	mov    (%eax),%eax
c0105934:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105937:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
            base = 16;
c010593e:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
            goto number;
c0105945:	eb 1f                	jmp    c0105966 <vprintfmt+0x33d>

        // (unsigned) hexadecimal
        case 'x':
            num = getuint(&ap, lflag);
c0105947:	83 ec 08             	sub    $0x8,%esp
c010594a:	ff 75 e0             	pushl  -0x20(%ebp)
c010594d:	8d 45 14             	lea    0x14(%ebp),%eax
c0105950:	50                   	push   %eax
c0105951:	e8 19 fc ff ff       	call   c010556f <getuint>
c0105956:	83 c4 10             	add    $0x10,%esp
c0105959:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010595c:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 16;
c010595f:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
        number:
            printnum(putch, putdat, num, base, width, padc);
c0105966:	0f be 55 db          	movsbl -0x25(%ebp),%edx
c010596a:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010596d:	83 ec 04             	sub    $0x4,%esp
c0105970:	52                   	push   %edx
c0105971:	ff 75 e8             	pushl  -0x18(%ebp)
c0105974:	50                   	push   %eax
c0105975:	ff 75 f4             	pushl  -0xc(%ebp)
c0105978:	ff 75 f0             	pushl  -0x10(%ebp)
c010597b:	ff 75 0c             	pushl  0xc(%ebp)
c010597e:	ff 75 08             	pushl  0x8(%ebp)
c0105981:	e8 f8 fa ff ff       	call   c010547e <printnum>
c0105986:	83 c4 20             	add    $0x20,%esp
            break;
c0105989:	eb 39                	jmp    c01059c4 <vprintfmt+0x39b>

        // escaped '%' character
        case '%':
            putch(ch, putdat);
c010598b:	83 ec 08             	sub    $0x8,%esp
c010598e:	ff 75 0c             	pushl  0xc(%ebp)
c0105991:	53                   	push   %ebx
c0105992:	8b 45 08             	mov    0x8(%ebp),%eax
c0105995:	ff d0                	call   *%eax
c0105997:	83 c4 10             	add    $0x10,%esp
            break;
c010599a:	eb 28                	jmp    c01059c4 <vprintfmt+0x39b>

        // unrecognized escape sequence - just print it literally
        default:
            putch('%', putdat);
c010599c:	83 ec 08             	sub    $0x8,%esp
c010599f:	ff 75 0c             	pushl  0xc(%ebp)
c01059a2:	6a 25                	push   $0x25
c01059a4:	8b 45 08             	mov    0x8(%ebp),%eax
c01059a7:	ff d0                	call   *%eax
c01059a9:	83 c4 10             	add    $0x10,%esp
            for (fmt --; fmt[-1] != '%'; fmt --)
c01059ac:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
c01059b0:	eb 04                	jmp    c01059b6 <vprintfmt+0x38d>
c01059b2:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
c01059b6:	8b 45 10             	mov    0x10(%ebp),%eax
c01059b9:	83 e8 01             	sub    $0x1,%eax
c01059bc:	0f b6 00             	movzbl (%eax),%eax
c01059bf:	3c 25                	cmp    $0x25,%al
c01059c1:	75 ef                	jne    c01059b2 <vprintfmt+0x389>
                /* do nothing */;
            break;
c01059c3:	90                   	nop
        }
    }
c01059c4:	e9 68 fc ff ff       	jmp    c0105631 <vprintfmt+0x8>
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
            if (ch == '\0') {
                return;
c01059c9:	90                   	nop
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
c01059ca:	8d 65 f8             	lea    -0x8(%ebp),%esp
c01059cd:	5b                   	pop    %ebx
c01059ce:	5e                   	pop    %esi
c01059cf:	5d                   	pop    %ebp
c01059d0:	c3                   	ret    

c01059d1 <sprintputch>:
 * sprintputch - 'print' a single character in a buffer
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
c01059d1:	55                   	push   %ebp
c01059d2:	89 e5                	mov    %esp,%ebp
    b->cnt ++;
c01059d4:	8b 45 0c             	mov    0xc(%ebp),%eax
c01059d7:	8b 40 08             	mov    0x8(%eax),%eax
c01059da:	8d 50 01             	lea    0x1(%eax),%edx
c01059dd:	8b 45 0c             	mov    0xc(%ebp),%eax
c01059e0:	89 50 08             	mov    %edx,0x8(%eax)
    if (b->buf < b->ebuf) {
c01059e3:	8b 45 0c             	mov    0xc(%ebp),%eax
c01059e6:	8b 10                	mov    (%eax),%edx
c01059e8:	8b 45 0c             	mov    0xc(%ebp),%eax
c01059eb:	8b 40 04             	mov    0x4(%eax),%eax
c01059ee:	39 c2                	cmp    %eax,%edx
c01059f0:	73 12                	jae    c0105a04 <sprintputch+0x33>
        *b->buf ++ = ch;
c01059f2:	8b 45 0c             	mov    0xc(%ebp),%eax
c01059f5:	8b 00                	mov    (%eax),%eax
c01059f7:	8d 48 01             	lea    0x1(%eax),%ecx
c01059fa:	8b 55 0c             	mov    0xc(%ebp),%edx
c01059fd:	89 0a                	mov    %ecx,(%edx)
c01059ff:	8b 55 08             	mov    0x8(%ebp),%edx
c0105a02:	88 10                	mov    %dl,(%eax)
    }
}
c0105a04:	90                   	nop
c0105a05:	5d                   	pop    %ebp
c0105a06:	c3                   	ret    

c0105a07 <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
c0105a07:	55                   	push   %ebp
c0105a08:	89 e5                	mov    %esp,%ebp
c0105a0a:	83 ec 18             	sub    $0x18,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
c0105a0d:	8d 45 14             	lea    0x14(%ebp),%eax
c0105a10:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vsnprintf(str, size, fmt, ap);
c0105a13:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105a16:	50                   	push   %eax
c0105a17:	ff 75 10             	pushl  0x10(%ebp)
c0105a1a:	ff 75 0c             	pushl  0xc(%ebp)
c0105a1d:	ff 75 08             	pushl  0x8(%ebp)
c0105a20:	e8 0b 00 00 00       	call   c0105a30 <vsnprintf>
c0105a25:	83 c4 10             	add    $0x10,%esp
c0105a28:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
c0105a2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0105a2e:	c9                   	leave  
c0105a2f:	c3                   	ret    

c0105a30 <vsnprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
c0105a30:	55                   	push   %ebp
c0105a31:	89 e5                	mov    %esp,%ebp
c0105a33:	83 ec 18             	sub    $0x18,%esp
    struct sprintbuf b = {str, str + size - 1, 0};
c0105a36:	8b 45 08             	mov    0x8(%ebp),%eax
c0105a39:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105a3c:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105a3f:	8d 50 ff             	lea    -0x1(%eax),%edx
c0105a42:	8b 45 08             	mov    0x8(%ebp),%eax
c0105a45:	01 d0                	add    %edx,%eax
c0105a47:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105a4a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if (str == NULL || b.buf > b.ebuf) {
c0105a51:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0105a55:	74 0a                	je     c0105a61 <vsnprintf+0x31>
c0105a57:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0105a5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105a5d:	39 c2                	cmp    %eax,%edx
c0105a5f:	76 07                	jbe    c0105a68 <vsnprintf+0x38>
        return -E_INVAL;
c0105a61:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
c0105a66:	eb 20                	jmp    c0105a88 <vsnprintf+0x58>
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
c0105a68:	ff 75 14             	pushl  0x14(%ebp)
c0105a6b:	ff 75 10             	pushl  0x10(%ebp)
c0105a6e:	8d 45 ec             	lea    -0x14(%ebp),%eax
c0105a71:	50                   	push   %eax
c0105a72:	68 d1 59 10 c0       	push   $0xc01059d1
c0105a77:	e8 ad fb ff ff       	call   c0105629 <vprintfmt>
c0105a7c:	83 c4 10             	add    $0x10,%esp
    // null terminate the buffer
    *b.buf = '\0';
c0105a7f:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105a82:	c6 00 00             	movb   $0x0,(%eax)
    return b.cnt;
c0105a85:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0105a88:	c9                   	leave  
c0105a89:	c3                   	ret    
