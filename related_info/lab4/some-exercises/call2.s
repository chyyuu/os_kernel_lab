
call2:     file format elf32-i386


Disassembly of section .init:

08048294 <_init>:
 8048294:	53                   	push   %ebx
 8048295:	83 ec 08             	sub    $0x8,%esp
 8048298:	e8 83 00 00 00       	call   8048320 <__x86.get_pc_thunk.bx>
 804829d:	81 c3 63 1d 00 00    	add    $0x1d63,%ebx
 80482a3:	8b 83 fc ff ff ff    	mov    -0x4(%ebx),%eax
 80482a9:	85 c0                	test   %eax,%eax
 80482ab:	74 05                	je     80482b2 <_init+0x1e>
 80482ad:	e8 1e 00 00 00       	call   80482d0 <__gmon_start__@plt>
 80482b2:	83 c4 08             	add    $0x8,%esp
 80482b5:	5b                   	pop    %ebx
 80482b6:	c3                   	ret    

Disassembly of section .plt:

080482c0 <__gmon_start__@plt-0x10>:
 80482c0:	ff 35 04 a0 04 08    	pushl  0x804a004
 80482c6:	ff 25 08 a0 04 08    	jmp    *0x804a008
 80482cc:	00 00                	add    %al,(%eax)
	...

080482d0 <__gmon_start__@plt>:
 80482d0:	ff 25 0c a0 04 08    	jmp    *0x804a00c
 80482d6:	68 00 00 00 00       	push   $0x0
 80482db:	e9 e0 ff ff ff       	jmp    80482c0 <_init+0x2c>

080482e0 <__libc_start_main@plt>:
 80482e0:	ff 25 10 a0 04 08    	jmp    *0x804a010
 80482e6:	68 08 00 00 00       	push   $0x8
 80482eb:	e9 d0 ff ff ff       	jmp    80482c0 <_init+0x2c>

Disassembly of section .text:

080482f0 <main>:

int main()
{
  func2( 1111, 2222);
  return 0;
}
 80482f0:	31 c0                	xor    %eax,%eax
 80482f2:	c3                   	ret    

080482f3 <_start>:
 80482f3:	31 ed                	xor    %ebp,%ebp
 80482f5:	5e                   	pop    %esi
 80482f6:	89 e1                	mov    %esp,%ecx
 80482f8:	83 e4 f0             	and    $0xfffffff0,%esp
 80482fb:	50                   	push   %eax
 80482fc:	54                   	push   %esp
 80482fd:	52                   	push   %edx
 80482fe:	68 60 84 04 08       	push   $0x8048460
 8048303:	68 00 84 04 08       	push   $0x8048400
 8048308:	51                   	push   %ecx
 8048309:	56                   	push   %esi
 804830a:	68 f0 82 04 08       	push   $0x80482f0
 804830f:	e8 cc ff ff ff       	call   80482e0 <__libc_start_main@plt>
 8048314:	f4                   	hlt    
 8048315:	66 90                	xchg   %ax,%ax
 8048317:	66 90                	xchg   %ax,%ax
 8048319:	66 90                	xchg   %ax,%ax
 804831b:	66 90                	xchg   %ax,%ax
 804831d:	66 90                	xchg   %ax,%ax
 804831f:	90                   	nop

08048320 <__x86.get_pc_thunk.bx>:
 8048320:	8b 1c 24             	mov    (%esp),%ebx
 8048323:	c3                   	ret    
 8048324:	66 90                	xchg   %ax,%ax
 8048326:	66 90                	xchg   %ax,%ax
 8048328:	66 90                	xchg   %ax,%ax
 804832a:	66 90                	xchg   %ax,%ax
 804832c:	66 90                	xchg   %ax,%ax
 804832e:	66 90                	xchg   %ax,%ax

08048330 <deregister_tm_clones>:
 8048330:	b8 1f a0 04 08       	mov    $0x804a01f,%eax
 8048335:	2d 1c a0 04 08       	sub    $0x804a01c,%eax
 804833a:	83 f8 06             	cmp    $0x6,%eax
 804833d:	76 1a                	jbe    8048359 <deregister_tm_clones+0x29>
 804833f:	b8 00 00 00 00       	mov    $0x0,%eax
 8048344:	85 c0                	test   %eax,%eax
 8048346:	74 11                	je     8048359 <deregister_tm_clones+0x29>
 8048348:	55                   	push   %ebp
 8048349:	89 e5                	mov    %esp,%ebp
 804834b:	83 ec 14             	sub    $0x14,%esp
 804834e:	68 1c a0 04 08       	push   $0x804a01c
 8048353:	ff d0                	call   *%eax
 8048355:	83 c4 10             	add    $0x10,%esp
 8048358:	c9                   	leave  
 8048359:	f3 c3                	repz ret 
 804835b:	90                   	nop
 804835c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

08048360 <register_tm_clones>:
 8048360:	b8 1c a0 04 08       	mov    $0x804a01c,%eax
 8048365:	2d 1c a0 04 08       	sub    $0x804a01c,%eax
 804836a:	c1 f8 02             	sar    $0x2,%eax
 804836d:	89 c2                	mov    %eax,%edx
 804836f:	c1 ea 1f             	shr    $0x1f,%edx
 8048372:	01 d0                	add    %edx,%eax
 8048374:	d1 f8                	sar    %eax
 8048376:	74 1b                	je     8048393 <register_tm_clones+0x33>
 8048378:	ba 00 00 00 00       	mov    $0x0,%edx
 804837d:	85 d2                	test   %edx,%edx
 804837f:	74 12                	je     8048393 <register_tm_clones+0x33>
 8048381:	55                   	push   %ebp
 8048382:	89 e5                	mov    %esp,%ebp
 8048384:	83 ec 10             	sub    $0x10,%esp
 8048387:	50                   	push   %eax
 8048388:	68 1c a0 04 08       	push   $0x804a01c
 804838d:	ff d2                	call   *%edx
 804838f:	83 c4 10             	add    $0x10,%esp
 8048392:	c9                   	leave  
 8048393:	f3 c3                	repz ret 
 8048395:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
 8048399:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

080483a0 <__do_global_dtors_aux>:
 80483a0:	80 3d 1c a0 04 08 00 	cmpb   $0x0,0x804a01c
 80483a7:	75 13                	jne    80483bc <__do_global_dtors_aux+0x1c>
 80483a9:	55                   	push   %ebp
 80483aa:	89 e5                	mov    %esp,%ebp
 80483ac:	83 ec 08             	sub    $0x8,%esp
 80483af:	e8 7c ff ff ff       	call   8048330 <deregister_tm_clones>
 80483b4:	c6 05 1c a0 04 08 01 	movb   $0x1,0x804a01c
 80483bb:	c9                   	leave  
 80483bc:	f3 c3                	repz ret 
 80483be:	66 90                	xchg   %ax,%ax

080483c0 <frame_dummy>:
 80483c0:	b8 10 9f 04 08       	mov    $0x8049f10,%eax
 80483c5:	8b 10                	mov    (%eax),%edx
 80483c7:	85 d2                	test   %edx,%edx
 80483c9:	75 05                	jne    80483d0 <frame_dummy+0x10>
 80483cb:	eb 93                	jmp    8048360 <register_tm_clones>
 80483cd:	8d 76 00             	lea    0x0(%esi),%esi
 80483d0:	ba 00 00 00 00       	mov    $0x0,%edx
 80483d5:	85 d2                	test   %edx,%edx
 80483d7:	74 f2                	je     80483cb <frame_dummy+0xb>
 80483d9:	55                   	push   %ebp
 80483da:	89 e5                	mov    %esp,%ebp
 80483dc:	83 ec 14             	sub    $0x14,%esp
 80483df:	50                   	push   %eax
 80483e0:	ff d2                	call   *%edx
 80483e2:	83 c4 10             	add    $0x10,%esp
 80483e5:	c9                   	leave  
 80483e6:	e9 75 ff ff ff       	jmp    8048360 <register_tm_clones>
 80483eb:	66 90                	xchg   %ax,%ax
 80483ed:	66 90                	xchg   %ax,%ax
 80483ef:	90                   	nop

080483f0 <func2>:
void func2(int a, int b)
{
 80483f0:	f3 c3                	repz ret 
 80483f2:	66 90                	xchg   %ax,%ax
 80483f4:	66 90                	xchg   %ax,%ax
 80483f6:	66 90                	xchg   %ax,%ax
 80483f8:	66 90                	xchg   %ax,%ax
 80483fa:	66 90                	xchg   %ax,%ax
 80483fc:	66 90                	xchg   %ax,%ax
 80483fe:	66 90                	xchg   %ax,%ax

08048400 <__libc_csu_init>:
 8048400:	55                   	push   %ebp
 8048401:	57                   	push   %edi
 8048402:	31 ff                	xor    %edi,%edi
 8048404:	56                   	push   %esi
 8048405:	53                   	push   %ebx
 8048406:	e8 15 ff ff ff       	call   8048320 <__x86.get_pc_thunk.bx>
 804840b:	81 c3 f5 1b 00 00    	add    $0x1bf5,%ebx
 8048411:	83 ec 0c             	sub    $0xc,%esp
 8048414:	8b 6c 24 20          	mov    0x20(%esp),%ebp
 8048418:	8d b3 0c ff ff ff    	lea    -0xf4(%ebx),%esi
 804841e:	e8 71 fe ff ff       	call   8048294 <_init>
 8048423:	8d 83 08 ff ff ff    	lea    -0xf8(%ebx),%eax
 8048429:	29 c6                	sub    %eax,%esi
 804842b:	c1 fe 02             	sar    $0x2,%esi
 804842e:	85 f6                	test   %esi,%esi
 8048430:	74 23                	je     8048455 <__libc_csu_init+0x55>
 8048432:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
 8048438:	83 ec 04             	sub    $0x4,%esp
 804843b:	ff 74 24 2c          	pushl  0x2c(%esp)
 804843f:	ff 74 24 2c          	pushl  0x2c(%esp)
 8048443:	55                   	push   %ebp
 8048444:	ff 94 bb 08 ff ff ff 	call   *-0xf8(%ebx,%edi,4)
 804844b:	83 c7 01             	add    $0x1,%edi
 804844e:	83 c4 10             	add    $0x10,%esp
 8048451:	39 f7                	cmp    %esi,%edi
 8048453:	75 e3                	jne    8048438 <__libc_csu_init+0x38>
 8048455:	83 c4 0c             	add    $0xc,%esp
 8048458:	5b                   	pop    %ebx
 8048459:	5e                   	pop    %esi
 804845a:	5f                   	pop    %edi
 804845b:	5d                   	pop    %ebp
 804845c:	c3                   	ret    
 804845d:	8d 76 00             	lea    0x0(%esi),%esi

08048460 <__libc_csu_fini>:
 8048460:	f3 c3                	repz ret 

Disassembly of section .fini:

08048464 <_fini>:
 8048464:	53                   	push   %ebx
 8048465:	83 ec 08             	sub    $0x8,%esp
 8048468:	e8 b3 fe ff ff       	call   8048320 <__x86.get_pc_thunk.bx>
 804846d:	81 c3 93 1b 00 00    	add    $0x1b93,%ebx
 8048473:	83 c4 08             	add    $0x8,%esp
 8048476:	5b                   	pop    %ebx
 8048477:	c3                   	ret    
