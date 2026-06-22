// Bare-metal syscall stubs: no HTIF, no CSRs.
#include <stddef.h>

extern int main(int argc, char** argv);

void setStats(int enable) { (void)enable; }

void exit(int code) { (void)code; while (1) {} }

void _init(int cid, int nc) { (void)cid; (void)nc; exit(main(0, 0)); }

void* memcpy(void* dest, const void* src, size_t len) {
    char* d = (char*)dest;
    const char* s = (const char*)src;
    while (len--) *d++ = *s++;
    return dest;
}

void* memset(void* dest, int byte, size_t len) {
    char* d = (char*)dest;
    while (len--) *d++ = (char)byte;
    return dest;
}
