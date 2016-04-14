This program compiles with no errors or warnings, not even with -Wall -Wextra -Werror. I recommend you don’t run it though, and here’s why. From the POSIX specification for fork(2):

Upon successful completion, fork() shall return 0 to the child process and shall return the process ID of the child process to the parent process. Both processes shall continue to execute from the fork() function. Otherwise, -1 shall be returned to the parent process, no child process shall be created, and errno shall be set to indicate the error.
And from the specification for kill(2):

If pid is -1, sig shall be sent to all processes (excluding an unspecified set of system processes) for which the process has permission to send that signal.
Putting the two together, that program could really ruin our day. If the fork() call fails for some reason2, we store -1 in child. Later, we call kill(-1, SIGKILL), which tries to kill all our processes, and most likely hose our login. Not even screen or tmux will save us!3

It’s a pretty scary failure mode, and neither the library nor the language do anything at all to prevent us from having a terrible day.


