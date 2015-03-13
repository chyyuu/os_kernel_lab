#define Descriptor(base,lim,type)\
.word lim&0xffff;\
.word base&0xffff;\
.byte (base>>16)&0xff;\
.word ((lim>>8)&0xf00)|(type&0x0f0ff);\
.byte ((base>>24)&0xff)

DA_C = 0x98
DA_32 = 0x4000
DA_DRW = 0x92

.text
.globl start
.code16
start:
 jmpl $0x0, $code 
		
GDT_START:	
Descriptor_DUMMY:Descriptor(0x0,0x0,0x0)                        /* 第0项里面全是0，不会用到 */
Descript_CODE32 :Descriptor(0x0,0xffffffff,DA_C+DA_32)    /* 32位代码段的段基址，段界限，访问类型 */
Descriptor_VIDEO:Descriptor(0xb8000,0x0ffff,DA_DRW)     /* 显存的段基址，段界限，访问类型 */
GDT_END:

GdtPtr:
	.word (GDT_END-GDT_START)-1	# so does gdt 
	.long GDT_START 	# This will be rewrite by code.
msg:
 .string "Hello world!"
code:
	mov     %cs,%ax   
	mov     %ax,%ds 
	mov     %ax,%es    
	mov     %ax,%ss  
	mov  $0x8000,%sp  
	/*显示HelloWorld字符串*/
	mov $msg   ,%ax
	mov %ax    ,%bp
	mov $12    ,%cx
	mov $0x1301,%ax
	mov $0x000c,%bx
	mov $0     ,%dl
	
	int $0x10
	
/*加载gdtr即将全局描述符表gdt的首地址和gdt的界限赋给gdtr寄存器*/       
	lgdt GdtPtr

/*关中断*/
	cli

/*打开地址线A20*/
	inb $0x92,%al
	or  $0x02,%al
	outb %al,$0x92

/*设置cr0寄存器,切换到保护模式*/
	movl %cr0,%eax
	or   $1,%eax
	movl %eax,%cr0


/*真正进入保护模式,执行此命令后CS=0x8,IP=LABEL_SEG_CODE32的偏移地址*/
	ljmp $0x8,$(LABEL_SEG_CODE32)
/*此时CS:IP=全局描述符表中第1(0x8>>3)项描述符给出的段基址+LABEL_SEG_CODE32的偏移地址*/


LABEL_SEG_CODE32:
.align  32
.code32
	movw $0x10,%ax
	movw %ax,%gs
	movl $((80*11+79)*2),%edi/*第11行，79列*/
	movb $0x0c,%ah/*高四位表示黑底,低四位表示红字*/
	movb $'P',%al/*显示的字符*/
	movw %ax,%gs:(%edi)
	
loop2:
	jmp loop2

.org 0x1fe, 0x90 
.word 0xaa55 
