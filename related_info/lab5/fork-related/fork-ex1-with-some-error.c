#include <signal.h>
#include <unistd.h>

int main(void) {
        pid_t child = fork();
        if (child) {  // in parent
                sleep(5);
                kill(child, SIGKILL);
        } else {  // in child
                for (;;);  // loop until killed
        }

        return 0;
}
