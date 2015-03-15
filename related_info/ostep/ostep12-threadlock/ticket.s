.var ticket
.var turn
.var count

.main
.top	

.acquire
mov $1, %ax
fetchadd %ax, ticket  # grab a ticket (keep it in dx)
.tryagain
mov turn, %cx         # check if it's your turn 
test %cx, %ax
jne .tryagain

# critical section
mov  count, %ax       # get the value at the address
add  $1, %ax          # increment it
mov  %ax, count       # store it back

# release lock
mov $1, %ax
fetchadd %ax, turn

# see if we're still looping
sub  $1, %bx
test $0, %bx
jgt .top	

halt
