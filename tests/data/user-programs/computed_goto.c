int run(const unsigned char *code, int n) {
    static void *const ops[] = {&&increment, &&double_it, &&stop};
    int value = 0;
    int pc = 0;
    goto *ops[code[pc]];
increment:
    value += 1;
    if (++pc >= n) return value;
    goto *ops[code[pc]];
double_it:
    value *= 2;
    if (++pc >= n) return value;
    goto *ops[code[pc]];
stop:
    return value;
}

int main(void) {
    const unsigned char program[] = {0, 1, 0, 1, 2};
    return run(program, 5) == 6 ? 0 : 1;
}
