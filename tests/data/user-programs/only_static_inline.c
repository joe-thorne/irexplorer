static int square(int x) {
    return x * x;
}

static inline int cube(int x) {
    return x * square(x);
}

inline int sum_of_cubes(int n) {
    int total = 0;
    for (int i = 1; i <= n; i++) {
        total += cube(i);
    }
    return total;
}
