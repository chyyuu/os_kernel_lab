.main
mov  $9,%dx
.top
sub  $1,%dx
test $0,%dx     
jgte .top         
halt
