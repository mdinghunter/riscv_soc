// See LICENSE for license details.
#include "../common/util.h"
#include "dataset1.h"

void vvadd(int n, const int a[], const int b[], int c[]) {
    int i;
    for (i = 0; i < n; i++) c[i] = a[i] + b[i];
}

int main(int argc, char* argv[]) {
    int results_data[DATA_SIZE];
    setStats(1);
    vvadd(DATA_SIZE, input1_data, input2_data, results_data);
    setStats(0);
    return verify(DATA_SIZE, results_data, verify_data);
}
