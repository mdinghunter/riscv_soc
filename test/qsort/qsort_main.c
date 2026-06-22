// See LICENSE for license details.
// Quicksort benchmark (adapted from riscv-tests)
#include "../common/util.h"
#include "dataset1.h"

#define INSERTION_THRESHOLD 10
#define NSTACK 50

#define SWAP(a,b) do { typeof(a) temp=(a);(a)=(b);(b)=temp; } while (0)
#define SWAP_IF_GREATER(a,b) do { if ((a) > (b)) SWAP(a,b); } while (0)

static void insertion_sort(int n, type arr[]) {
    type *i, *j, value;
    for (i = arr+1; i < arr+n; i++) {
        value = *i; j = i;
        while (value < *(j-1)) { *j = *(j-1); if (--j == arr) break; }
        *j = value;
    }
}

void sort(int n, type arr[]) {
    type* ir = arr+n;
    type* l  = arr+1;
    type* stack[NSTACK];
    type** stackp = stack;
    for (;;) {
        if (ir-l < INSERTION_THRESHOLD) {
            insertion_sort(ir-l+1, l-1);
            if (stackp == stack) break;
            ir = *stackp--;
            l  = *stackp--;
        } else {
            SWAP(arr[((l-arr)+(ir-arr))/2-1], l[0]);
            SWAP_IF_GREATER(l[-1], ir[-1]);
            SWAP_IF_GREATER(l[0],  ir[-1]);
            SWAP_IF_GREATER(l[-1], l[0]);
            type* i = l+1;
            type* j = ir;
            type  a = l[0];
            for (;;) {
                while (*i++ < a);
                while (*(j-- - 2) > a);
                if (j < i) break;
                SWAP(i[-1], j[-1]);
            }
            l[0]   = j[-1];
            j[-1]  = a;
            stackp += 2;
            if (ir-i+1 >= j-l) { stackp[0]=ir; stackp[-1]=i; ir=j-1; }
            else                { stackp[0]=j-1; stackp[-1]=l; l=i; }
        }
    }
}

int main(int argc, char* argv[]) {
    // input_data is const (in rodata); copy to stack so sort() can modify it
    int i;
    type work[DATA_SIZE];
    for (i = 0; i < DATA_SIZE; i++) work[i] = input_data[i];
    setStats(1);
    sort(DATA_SIZE, work);
    setStats(0);
    return verify(DATA_SIZE, work, verify_data);
}
