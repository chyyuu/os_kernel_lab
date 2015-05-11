/* 
 * From
 * [url]http://www.crasseux.com/books/ctutorial/Programming-with-pipes.html[/url]
 * but changed to use fgets() instead of the GNU extension getdelim()
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main()
{
    FILE *ps_pipe;
    FILE *grep_pipe;
    int bytes_read;
    char buffer[100];           /* could be anything you want */
    /* Open our two pipes 
          ls -a | grep pipe*
   */
   
    ps_pipe = popen("/bin/ls -a", "r");
    grep_pipe = popen("/bin/grep 'pipe*'", "w");
    /* Check that pipes are non-null, therefore open */
    if ((!ps_pipe) || (!grep_pipe)) {
        fprintf(stderr, "One or both pipes failed.\n");
        return EXIT_FAILURE;
    }
    bytes_read = 0;
    while (fgets(buffer, sizeof(buffer), ps_pipe)) {
        fprintf(grep_pipe, "%s", buffer);
        bytes_read += strlen(buffer);
    }
    printf("Total bytes read = %d\n", bytes_read);
    /* Close ps_pipe, checking for errors */
    if (pclose(ps_pipe) != 0) {
        fprintf(stderr, "Could not run 'ls', or other error.\n");
    }
    /* Close grep_pipe, cehcking for errors */
    if (pclose(grep_pipe) != 0) {
        fprintf(stderr, "Could not run 'grep', or other error.\n");
    }
    /* Exit! */
    return 0;
}
 
