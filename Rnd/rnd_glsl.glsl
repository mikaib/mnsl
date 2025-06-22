#version 300 core

int test(int x) {
    return x;
}

void main() {
    if (1 == 2) {
        test(0);
    }
    if (1) {
        test(1);
    } else if (0) {
        test(0);
    } else {
        test(2);
    }
}

