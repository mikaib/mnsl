#version 300 core

float __mnsl_generic_0(float x, float y) {
    float z = x + y;
    return z;
}

void main() {
    vec2 res = vec2(__mnsl_generic_0(float(1), float(2)));
}

