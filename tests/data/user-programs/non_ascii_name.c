/* A cafe till, with a function named in French. */
int café_total(int cups, int price) {
    return cups * price;
}

int main(void) {
    return café_total(3, 4) == 12 ? 0 : 1;
}
