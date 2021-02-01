#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

//#include "include/task_static_init.h"

const char *const ApodiniProcessIsChildInvocationWrapperCLIArgument = "__ApodiniDeployCLI.ProcessIsChildProcessInvocationWrapper";


__attribute__((constructor))
static void LKHandleTaskChildProcessLaunchIfNecessary(int argc, const char * argv[], const char *const envp[]) {
    if (!(argc >= 2 && strcmp(argv[1], ApodiniProcessIsChildInvocationWrapperCLIArgument) == 0)) {
        // Nothing to do if the program isn't being launched with the special parameter
        return;
    }
    
    if (-1 == setpgid(getpid(), getpgid(getppid()))) {
        perror("Error moving process into parent group");
        exit(EXIT_FAILURE);
    }
    
    
    int childArgc = argc - 2; // first two are our binary and the special parameter
    char **childArgv = calloc(childArgc + 1, sizeof(char *)); // +1 bc the array is null-terminated
    for (size_t idx = 0; idx < childArgc; idx++) {
        childArgv[idx] = strdup(argv[idx + 2]);
    }
    
#if DEBUG
    printf("[%s] Replacing current process (%i) w/ child process. argv:", __PRETTY_FUNCTION__, getpid());
    for (size_t idx = 0; idx < childArgc; idx++) {
        printf(" %s", childArgv[idx]);
    }
    printf("\n");
#endif
    execve(childArgv[0], childArgv, (char *const *) envp);
    perror("execve failed");
    exit(EXIT_FAILURE);
}

//__attribute__((used, section(".init_array")))
__attribute__((used, section("__DATA,__mod_init_func")))
static void *ctr = &LKHandleTaskChildProcessLaunchIfNecessary;
