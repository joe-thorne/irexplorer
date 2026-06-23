int score(int x, int scale) {
    int limit    = scale * 32;
    int wasted   = scale * scale - scale * scale;
    int adjusted = x - 128;
    int weighted = adjusted * scale;

    if (weighted > limit)
        return limit;

    return weighted + wasted;
}
