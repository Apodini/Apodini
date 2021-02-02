#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <stdio.h>
#include <string.h>
#include <limits.h>


const char *const ApodiniProcessIsChildInvocationWrapperCLIArgument = "__ApodiniDeployCLI.ProcessIsChildProcessInvocationWrapper";


// A constructor function which will get called when the shared library is loaded (ie before execution enters `main`, see below).
// This is part of the child process management API (see Task.swift), and used to move child processes into the parent's
// process group. We want all processes to be in the same group so that signals like SIGINT are sent to all processes.
__attribute__((constructor))
static void LKHandleTaskChildProcessLaunchIfNecessary(int argc, const char * argv[], const char *const envp[]) {
#if 0 && DEBUG
    // print cwd
    char cwd[PATH_MAX];
    if (getcwd(cwd, sizeof(cwd)) != NULL) {
        printf("LAUNCH>CWD: %s\n", cwd);
    }
    // print invocation info
    for (size_t idx = 0; idx < argc; idx++) {
        printf("argv[%zu]: %s\n", idx, argv[idx]);
    }
    printf("ENV:\n");
    for (__auto_type *env = envp; *env != 0; env++) {
        printf("%s\n", *env);
    }
#endif
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
    if (childArgv == NULL) {
        perror("Unable to allocate memory for child argv");
        exit(EXIT_FAILURE);
    }
    for (size_t idx = 0; idx < childArgc; idx++) {
        // making a copy of the child's argv.
        // not that it would be necessary, given we're about to nuke the current process.
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


// Place a pointer to our constructor function into the __DATA segment's __mod_init_func section.
// This will cause it to get called with the same arguments as `main` (ie argv, argv, envp).
// Note: If this fails to compile or does not work (eg because the linker doesn't recognise the section name), try `section(".init_array")` instead.
__attribute__((used, section("__DATA,__mod_init_func")))
static void* ctorFnPtr = &LKHandleTaskChildProcessLaunchIfNecessary;
