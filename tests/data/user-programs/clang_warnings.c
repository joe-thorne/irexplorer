// Compiles with more than 20 of clang's default warnings, some with notes, so only the first 20 are shown.
#include <stdio.h>

int count_set_bits(unsigned value) {
    int count = 0;
    unsigned bit;
    while (bit = value & 1u) {
        count += bit;
        value >>= 1;
    }
    return count;
}

int sum_to(int limit) {
    int total = 0;
    for (int i = 0; i < limit; i++) {
        total + i;
        total += i;
    }
    return total;
}

int is_same(int value) {
    return value == value;
}

unsigned char small_constant(void) {
    unsigned char byte = 300;
    return byte;
}

long wide_shift(int value) {
    return value << 40;
}

int first_positive(const int *values, int count) {
    int found;
    for (int i = 0; i < count; i++) {
        if (found = values[i] > 0) {
            return values[i];
        }
    }
    return 0;
}

int skip_empty(int value) {
    if (value > 10);
    return value;
}

int truncated_half(void) {
    int half = 2.5;
    return half;
}

int last_of_four(void) {
    int four[4] = {1, 2, 3, 4};
    return four[4];
}

int not_equal(int a, int b) {
    if (!a == b) {
        return 1;
    }
    return 0;
}

int array_size(int values[8]) {
    return sizeof(values) / sizeof(values[0]);
}

void print_total(long total, double mean) {
    printf("total %d\n", total);
    printf("mean %d\n", mean);
}

int scaled_sum(const int *values, int count) {
    int total = 0;
    for (int i = 0; i < count; i++) {
        if (total = total + values[i] * 2) {
            total == 0;
        }
    }
    return total;
}

int clamp(int value) {
    char low = -200;
    char high = 200;
    if (value < low) {
        return low;
    }
    if (value > high) {
        return high;
    }
    return value;
}

int max_of(const int *values, int count) {
    int best = values[0];
    for (int i = 1; i < count; i++) {
        if (best = values[i] > best ? values[i] : best) {
            best == values[i];
        }
    }
    return best;
}

int bump(int i) {
    i = i++ + 1;
    return i < i ? 0 : i;
}

int main(void) {
    int values[6] = {3, -1, 4, 1, -5, 9};
    print_total(sum_to(10), 2.5);
    return first_positive(values, 6) + max_of(values, 6) + scaled_sum(values, 6) + clamp(values[5])
        + count_set_bits(255u) + is_same(1) + small_constant() + (int)wide_shift(1) + skip_empty(3)
        + truncated_half() + last_of_four() + not_equal(1, 2) + array_size(values) + bump(2);
}
