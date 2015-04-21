.main
test $1, %ax     # ax should be 1 (signaller) or 0 (waiter)
je .signaller

.waiter	
mov  2000, %cx
test $1, %cx
jne .waiter
halt

.signaller
mov  $1, 2000
halt
