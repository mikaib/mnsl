#version 300 core

vec2 add(vec2 x, int y) {
    return x + vec2(y);
}

vec2 squared(vec2 x) {
    return x * x;
}

void main() {
    vec2 x = add(squared(vec2(5)), 1);
}

