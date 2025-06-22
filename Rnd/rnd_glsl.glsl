#version 300 core

int test_2() {
    int a = 10000;
    int b = 0;
    if (a == 0) {
        b = 1;
    } else if (a == 1) {
        b = 2;
    }
    return b;
}

void main() {
    test_2();
}

