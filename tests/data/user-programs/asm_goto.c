int is_positive(int x) {
    asm goto("testl %0, %0\n\tjg %l[positive]" : : "r"(x) : "cc" : positive);
    return 0;
positive:
    return 1;
}

int main(void) {
    return is_positive(5) && !is_positive(-5) ? 0 : 1;
}
