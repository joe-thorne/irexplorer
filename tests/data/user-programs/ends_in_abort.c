#include <stdlib.h>

int checked_divide(int numerator, int denominator) {
    if (denominator == 0) {
        abort();
    }
    return numerator / denominator;
}

int main(void) {
    return checked_divide(84, 2) == 42 ? 0 : 1;
}
