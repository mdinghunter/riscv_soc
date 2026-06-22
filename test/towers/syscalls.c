// Bare-metal syscall stubs for simple RV32I pipeline.
// No HTIF, no CSRs — setStats is a no-op, exit spins.

extern int main(int argc, char** argv);

void setStats(int enable) { (void)enable; }

void exit(int code) {
    (void)code;
    while (1) {}
}

void _init(int cid, int nc) {
    (void)cid; (void)nc;
    exit(main(0, 0));
}
