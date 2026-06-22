// See LICENSE for license details.
#include "../common/util.h"
#include "multiply.h"
#include "dataset1.h"

int main(int argc, char* argv[]) {
    int i;
    int results_data[DATA_SIZE];
    setStats(1);
    for (i = 0; i < DATA_SIZE; i++)
        results_data[i] = multiply(input_data1[i], input_data2[i]);
    setStats(0);
    return verify(DATA_SIZE, results_data, verify_data);
}
