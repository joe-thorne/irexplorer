#include <stdio.h>

int average(const int *values, int count) {
    int total = 0;
    for (int i = 0; i < count; i++) {
        total += values[i]
    }
    return total / count;
}

int main(void) {
    int values[] = {3, 5, 7};
    printf("%d\n", average(values, 3));
    return mean;
}
