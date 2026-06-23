int binary_search(const int *a, int n, int key) {
    int lo = 0;
    int hi = n;

    while (lo < hi) {
        int mid = lo + (hi - lo) / 2;

        if (a[mid] < key) {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }

    if (lo < n && a[lo] == key) {
        return (int)lo;
    }

    return -1;
}
