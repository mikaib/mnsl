#version 300 core

float test_TFloat_TFloat_RTTFloat(float x, float y) {
    float z = x + y;
    return z;
}

void main() {
    vec2 res = test_TFloat_TFloat_RTTFloat(float(1), float(2));
}

