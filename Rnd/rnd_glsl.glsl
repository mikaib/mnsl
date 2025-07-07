#version 300 core

vec2 __mnsl_generic_1(vec2 x, vec2 y) {
    return x + y;
}

vec2 __mnsl_generic_0(vec2 x) {
    return x * x;
}

void main() {
    vec2 x = __mnsl_generic_1(__mnsl_generic_0(vec2(5)), vec2(1));
}

