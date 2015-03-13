.text
.globl start                                                /* 程序从start处开始运行 */
.code16
start:
 jmpl $0x0, $code 
msg:
 .string "Hello world!"
code:
	mov     %cs,%ax   
	mov     %ax,%ds 
	mov     %ax,%es    
	mov     %ax,%ss  
	mov     $0x400,%sp  
	call       dispstr                                    /* call dispstr函数显示字符串 */
			
loop0:                                                          /* 无限循环 */
	jmp loop0
	
dispstr:
	mov $msg      ,%ax
	mov %ax        ,%bp                             /* es:bp = 串地址 */
	mov $12         ,%cx                              /* cs = 串长度 */
	mov $0x1301 ,%ax                              /* ah=0x13：显示字符串 ,al=0x1：显示输出方式 */
	mov $0x000c ,%bx                              /* bh=0 ：第0页,  bl=0xc ：高亮 黑底红字 */
	mov $0           ,%dl                               /* 在0行0列显示*/
	int $0x10                                              /* 调用BIOS提供的int服务0x10的0x13功能：显示字符串 */ 
	ret
		
.org    0x1fe, 0x90                                       /* 0x1fe=510，表示从ret后的位置开始，直到510处结束的代码/数据空间，填写0x90 */
.word 0xaa55                                              /* 合法的主引导扇区标识 */
