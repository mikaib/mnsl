#version 300 core

int test() {
    int x = 0;
    int y = 100;
    while (x < y) {
        if (y == 10) {
            y = y + 5;
            continue;
        } else if (y == 50) {
            break;
        }
        y = y + 1;
    }
    return y;
}

void main() {
    test();
}

