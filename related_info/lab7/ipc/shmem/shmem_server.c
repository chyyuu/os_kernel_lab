#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
 
#define SHMSZ 1024
 
main(int argc, char **argv)
{
	char c, tmp;
	int shmid;
	key_t key;
	char *shm, *s;	
 
    /*
     * Shared memory segment at 1234
     * "1234".
     */
	key = 1234;
 
    /*
     * Create the segment and set permissions.
     */
	if ((shmid = shmget(key, SHMSZ, IPC_CREAT | 0666)) < 0) {
		perror("shmget");
		return 1;
	}
 
    /*
     * Now we attach the segment to our data space.
     */
	if ((shm = shmat(shmid, NULL, 0)) == (char *) -1) {
		perror("shmat");
		return 1;
	}
 
	/*
	 * Zero out memory segment
	 */
	memset(shm,0,SHMSZ);
	s = shm;
 
	/*
	* Read user input from client code and tell
	* the user what was written.
	*/
	while (*shm != 'q'){
		sleep(1);
		if(tmp == *shm)
			continue;
 
		fprintf(stdout, "You pressed %c\n",*shm);
		tmp = *shm;
	}
 
	if(shmdt(shm) != 0)
		fprintf(stderr, "Could not close memory segment.\n");
 
	return 0;
}
