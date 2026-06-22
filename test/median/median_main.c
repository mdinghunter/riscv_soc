// See LICENSE for license details.
#include "../common/util.h"
#include "median.h"
#include "dataset1.h"

int main(int argc, char* argv[]) {
    int results_data[DATA_SIZE];
    setStats(1);
    median(DATA_SIZE, input_data, results_data);
    setStats(0);
    return verify(DATA_SIZE, results_data, verify_data);
}
