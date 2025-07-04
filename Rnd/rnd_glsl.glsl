#version 300 core

int test(int x) {
    int v = x;
    x = x * 5;
    x = 5;
    int t = x;
    return x;
}

void main() {
    int v = test(3);
}

