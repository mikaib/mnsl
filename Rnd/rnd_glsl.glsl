#version 300 core

float test(float x) {
    return 2.0 * float(3) + -float(1) * x;
}

float cool(float x) {
    x = x * float(2);
    x = x + 5.0;
    return test(x);
}

void main() {
    float test = 1.2;
    float someVar = cool(test);
    someVar = someVar + float(1);
    int q = 3;
}

