// See LICENSE for license details.
#include <stddef.h>
#include "../common/util.h"
#include "dataset1.h"

extern void* memcpy(void* dest, const void* src, size_t len);

int main(int argc, char* argv[]) {
    int results_data[DATA_SIZE];
    setStats(1);
    memcpy(results_data, input_data, sizeof(int) * DATA_SIZE);
    setStats(0);
    return verify(DATA_SIZE, results_data, input_data);
}
