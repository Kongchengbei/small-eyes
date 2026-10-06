#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

// Fail one selected commit rename, then allow rollback renames to succeed.
int rename(const char *from, const char *to)
{
    static int failed;
    const char *target = getenv("SOC_CONFIG_TEST_FAIL_RENAME_TARGET");
    if (!failed && target && !strcmp(target, to)) {
        failed = 1;
        errno = EIO;
        return -1;
    }
    int (*real_rename)(const char *, const char *) = dlsym(RTLD_NEXT, "rename");
    return real_rename(from, to);
}
