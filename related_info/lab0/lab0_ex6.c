#include <stdio.h>
#include <unistd.h>
void main(void){
  int child_status, exec_status;
  int pid = fork(); //create a child
  if (pid==0) {     // child continues here
    printf("Child: EXEC lec7_1\n");
    exec_status=execve("lec7_1",NULL,NULL);
    printf("Child: Why would I execute?\n");
  } else {           // parent continues here
    printf("Parent: Whose your daddy?\n");
    child_status=wait(pid);
    printf("Parent: the child %d exit with %d\n",pid, child_status);
  }
}
