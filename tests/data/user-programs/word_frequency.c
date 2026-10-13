/* Word frequency report: counts the words in a passage with a hash table,
 * sorts them by count, and prints the most common words with a few statistics. */
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TABLE_SIZE 256
#define MAX_WORD 24
#define TOP_WORDS 8

struct entry {
    char word[MAX_WORD];
    int count;
    int first_seen;
};

struct table {
    struct entry slots[TABLE_SIZE];
    int used;
};

static const char *passage =
    "The quick brown fox jumps over the lazy dog. The dog sleeps, and the fox "
    "runs into the forest. In the forest the fox finds a river; the river is "
    "cold and the fox is quick. A lazy dog never finds the river, but the "
    "quick fox always does. Over the hills and over the river the fox runs.";

/* FNV-1a over the word's bytes. */
static unsigned int hash_word(const char *word) {
    unsigned int hash = 2166136261u;
    for (const char *p = word; *p != '\0'; p++) {
        hash ^= (unsigned char)*p;
        hash *= 16777619u;
    }
    return hash;
}

static void table_init(struct table *table) {
    memset(table, 0, sizeof *table);
}

/* Adds one occurrence of a word, probing linearly from its hash. */
static int table_add(struct table *table, const char *word, int position) {
    unsigned int index = hash_word(word) % TABLE_SIZE;
    for (int probe = 0; probe < TABLE_SIZE; probe++) {
        struct entry *slot = &table->slots[index];
        if (slot->count == 0) {
            strncpy(slot->word, word, MAX_WORD - 1);
            slot->count = 1;
            slot->first_seen = position;
            table->used++;
            return 1;
        }
        if (strcmp(slot->word, word) == 0) {
            slot->count++;
            return 0;
        }
        index = (index + 1) % TABLE_SIZE;
    }
    return -1;
}

static int table_lookup(const struct table *table, const char *word) {
    unsigned int index = hash_word(word) % TABLE_SIZE;
    for (int probe = 0; probe < TABLE_SIZE; probe++) {
        const struct entry *slot = &table->slots[index];
        if (slot->count == 0) {
            return 0;
        }
        if (strcmp(slot->word, word) == 0) {
            return slot->count;
        }
        index = (index + 1) % TABLE_SIZE;
    }
    return 0;
}

/* Copies the next lowercase word from *text into word, returning its length. */
static int next_word(const char **text, char *word) {
    const char *p = *text;
    while (*p != '\0' && !isalpha((unsigned char)*p)) {
        p++;
    }
    int length = 0;
    while (isalpha((unsigned char)*p)) {
        if (length < MAX_WORD - 1) {
            word[length++] = (char)tolower((unsigned char)*p);
        }
        p++;
    }
    word[length] = '\0';
    *text = p;
    return length;
}

static int count_words(struct table *table, const char *text) {
    char word[MAX_WORD];
    int position = 0;
    while (next_word(&text, word) > 0) {
        if (table_add(table, word, position) < 0) {
            fprintf(stderr, "table full at word %d\n", position);
            break;
        }
        position++;
    }
    return position;
}

/* More frequent words first; ties keep the order the words first appeared in. */
static int by_count(const void *a, const void *b) {
    const struct entry *x = a;
    const struct entry *y = b;
    if (x->count != y->count) {
        return y->count - x->count;
    }
    return x->first_seen - y->first_seen;
}

static int collect(const struct table *table, struct entry *out) {
    int n = 0;
    for (int i = 0; i < TABLE_SIZE; i++) {
        if (table->slots[i].count > 0) {
            out[n++] = table->slots[i];
        }
    }
    qsort(out, (size_t)n, sizeof out[0], by_count);
    return n;
}

static double mean_length(const struct entry *entries, int n) {
    long letters = 0;
    long words = 0;
    for (int i = 0; i < n; i++) {
        letters += (long)strlen(entries[i].word) * entries[i].count;
        words += entries[i].count;
    }
    return words > 0 ? (double)letters / (double)words : 0.0;
}

static const struct entry *longest(const struct entry *entries, int n) {
    const struct entry *best = NULL;
    size_t best_length = 0;
    for (int i = 0; i < n; i++) {
        size_t length = strlen(entries[i].word);
        if (length > best_length) {
            best = &entries[i];
            best_length = length;
        }
    }
    return best;
}

static int singletons(const struct entry *entries, int n) {
    int count = 0;
    for (int i = n - 1; i >= 0 && entries[i].count == 1; i--) {
        count++;
    }
    return count;
}

static void print_bar(int count, int widest) {
    int width = widest > 0 ? count * 30 / widest : 0;
    for (int i = 0; i < width; i++) {
        putchar('#');
    }
    putchar('\n');
}

static void report(const struct entry *entries, int n, int total) {
    int shown = n < TOP_WORDS ? n : TOP_WORDS;
    printf("%d words, %d distinct\n", total, n);
    for (int i = 0; i < shown; i++) {
        printf("%-10s %3d ", entries[i].word, entries[i].count);
        print_bar(entries[i].count, entries[0].count);
    }
    const struct entry *word = longest(entries, n);
    if (word != NULL) {
        printf("longest word: %s\n", word->word);
    }
    printf("mean length: %.2f letters\n", mean_length(entries, n));
    printf("words seen once: %d\n", singletons(entries, n));
}

int main(void) {
    static struct table table;
    static struct entry entries[TABLE_SIZE];
    table_init(&table);
    int total = count_words(&table, passage);
    int n = collect(&table, entries);
    report(entries, n, total);
    int foxes = table_lookup(&table, "fox");
    int cats = table_lookup(&table, "cat");
    printf("fox: %d, cat: %d\n", foxes, cats);
    return foxes > 0 && cats == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
