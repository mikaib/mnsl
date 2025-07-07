#version 300 core

float test_TFloat_TFloat_TFloat_RTTFloat(float x, float y, float w) {
    float z = x + y;
    return z;
}

void main() {
    vec2 res = vec2(test_TFloat_TFloat_TFloat_RTTFloat(float(1), float(2), 2.5));
}

