# test.S - RV32I branch predictor test program
# Three workloads: always-taken loop, countdown, alternating branch
# No data memory or stack required.

.section .text
.global _start

_start:
    # --- 1. Fibonacci via JAL (tests JAL + always-taken backward branch) ---
    li   a0, 20
    jal  ra, fib          # a0 = fib(20) = 6765

    # --- 2. Count-down loop (backward branch taken 49x, not-taken once) ---
    li   t0, 50
count_loop:
    addi t0, t0, -1
    bnez t0, count_loop

    # --- 3. Alternating branch (50% taken — stresses PHT) ---
    li   t0, 0
    li   t1, 40
    li   t2, 0
alt_loop:
    andi t3, t0, 1        # lsb alternates 0,1,0,1...
    beqz t3, alt_skip     # taken on even iterations only
    add  t2, t2, t0       # accumulate odd values
alt_skip:
    addi t0, t0, 1
    blt  t0, t1, alt_loop

halt:
    j    halt             # spin forever (halt signal)

# -------------------------------------------------------------------
# fib(n): iterative Fibonacci — n in a0, result in a0
# Clobbers: t0, t1, t2.  Does NOT use the stack.
# -------------------------------------------------------------------
fib:
    beqz a0, fib_done
    li   t0, 0
    li   t1, 1
fib_loop:
    add  t2, t0, t1
    mv   t0, t1
    mv   t1, t2
    addi a0, a0, -1
    bnez a0, fib_loop
    mv   a0, t0
fib_done:
    ret
