#ifndef __UTIL_H
#define __UTIL_H
#include <stddef.h>

extern void setStats(int enable);

static int verify(int n, const volatile int* test, const int* ref) {
    int i;
    for (i = 0; i < n; i++)
        if (test[i] != ref[i]) return i + 1;
    return 0;
}

#endif
