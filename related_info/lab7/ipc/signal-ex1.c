#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

// Define the function to be called when ctrl-c (SIGINT) signal is sent to process
void
signal_callback_handler(int signum)
{
   printf("Caught signal %d\n",signum);
   // Cleanup and close up stuff here

   // Terminate program
   exit(signum);
}

int main()
{
   // Register signal and signal handler
   signal(SIGINT, signal_callback_handler);

   while(1)
   {
      printf("Program processing stuff here.\n");
      sleep(1);
   }
   return EXIT_SUCCESS;
}
