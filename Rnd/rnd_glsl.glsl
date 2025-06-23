#version 300 core

int test_1() {
    int x = 0;
    int y = 0;
    while (y < x) {
        y = y + 1;
    }
    return y;
}

int test_2() {
    int x = 0;
    int y = 0;
    while (y < x) {
        if (y == 0) {
            y = y + 1;
        } else if (y == 1) {
            y = y + 2;
        } else {
            return 1;
        }
        y = y + 1;
    }
    return y;
}

int test_3() {
    int x = 0;
    int y = 0;
    while (y < x) {
        int z = y * 2;
        int w = x * 3;
        while (z < w) {
            if (z == 0) {
                z = z + 1;
            } else if (z == 1) {
                z = z + 2;
            } else {
                z = z + 3;
            }
            z = z + 1;
        }
        if (y == 0) {
            y = y + 6;
        } else if (y == 1) {
            y = y + 2;
        } else {
            y = y + 3;
        }
        y = y + 9;
    }
    return y;
}

void main() {
    test_1();
    test_2();
    test_3();
}

