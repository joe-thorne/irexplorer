#include <stddef.h>

static int partition(int *a, int low, int high) {
    int pivot = a[high];
    int i = low - 1;

    for (int j = low; j < high; ++j) {
        if (a[j] <= pivot) {
            ++i;

            int tmp = a[i];
            a[i] = a[j];
            a[j] = tmp;
        }
    }

    int tmp = a[i + 1];
    a[i + 1] = a[high];
    a[high] = tmp;

    return i + 1;
}

void quick_sort(int *a, int low, int high) {
    if (low < high) {
        int p = partition(a, low, high);

        quick_sort(a, low, p - 1);
        quick_sort(a, p + 1, high);
    }
}
