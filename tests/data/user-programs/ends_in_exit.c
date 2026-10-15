#include <stdio.h>
#include <stdlib.h>

static void fail(const char *message) {
    fprintf(stderr, "error: %s\n", message);
    exit(EXIT_FAILURE);
}

int parse_digit(char c) {
    if (c < '0' || c > '9') {
        fail("not a digit");
    }
    return c - '0';
}

int main(void) {
    int total = 0;
    for (const char *p = "2024"; *p != '\0'; p++) {
        total = total * 10 + parse_digit(*p);
    }
    return total == 2024 ? 0 : 1;
}
