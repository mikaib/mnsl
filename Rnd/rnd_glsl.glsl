#version 300 core

int test(int x) {
    int y = x * 2;
    x = x + 1;
    return x;
}

void main() {
    int v = test(1);
}

