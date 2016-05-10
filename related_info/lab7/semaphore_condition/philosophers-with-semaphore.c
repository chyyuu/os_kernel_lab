/*  Philosophers.c - Demonstrate the semaphore solution to the dining
    philosophers problem. The Room semaphore is neede to prevent all
    philosophers from entering the room and grabbing their left most fork
    at the same time, which would lead to deadlock. The Room sempahore
    can be enabled by specifying a command line argument.  */

#include <stdio.h>
#include <pthread.h>
#include <semaphore.h>
typedef	enum { False=0, True=1 } bool ;

#define N 5 /* Number of times each philosopher tries to eat */
#define P 3 /* Number of philosophers */

sem_t Room;
sem_t Fork[P];
bool Switch ;

void *tphilosopher(void *ptr) {
    int i, k = *((int *) ptr);
    for(i = 1; i <= N; i++) {
        printf("%*cThink %d %d\n", k*4, ' ', k, i);
        if(Switch) {
            sem_wait(&Room) ;
        }
        sem_wait(&Fork[k]) ;
        sem_wait(&Fork[(k+1) % P]) ;
        printf("%*cEat %d %d\n", k*4, ' ', k, i);
        sem_post(&Fork[k]) ;
        sem_post(&Fork[(k+1) % P]) ;
        if(Switch) {
            sem_post(&Room) ;
        }
    }
    pthread_exit(0);
}

int main(int argc, char * argv[]) {
    int i, targ[P];
    pthread_t thread[P];
    sem_init(&Room, 0, P-1);    
    Switch = (argc > 1); /* Room semaphore on/off */
    printf("Switch=%s\n",(Switch?"true":"false"));
    for(i=0;i<P;i++) {
        sem_init(&Fork[i], 0, 1);    
    }
    for(i=0;i<P;i++) {
        targ[i] = i;
        pthread_create(&thread[i], NULL, &tphilosopher,(void *) &targ[i]);
    }
    for(i=0;i<P;i++) {
        pthread_join(thread[i], NULL);
    }
    for(i=0;i<P;i++) {
        sem_destroy(&Fork[i]);
    }
    sem_destroy(&Room);
    return 0;
}

/*  Please note that the checks on the return value of the system calls
    have been omitted to avoid cluttering the code. However, system calls
    can and will fail, in which case the results are unpredictable. */
