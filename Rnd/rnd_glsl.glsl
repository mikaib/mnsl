#version 300 core

uniform vec2 u_u_Vec;
uniform vec2 u_u_VecList[10];

void main() {
    vec2 x = u_u_Vec;
    x = vec2(1, 2);
}

