#version 300 core

int test() {
    int a = 1;
    int b = 2;
    if (a == b) {
        return 1;
    } else if (a < b) {
        return 2;
    } else if (a > b) {
        return 3;
    } else {
        return 4;
    }
}

void main() {
    test();
}

