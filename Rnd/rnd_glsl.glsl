#version 300 core

uniform vec2 u_u_VecList[10];

void main() {
    vec2 list = u_u_VecList;
    vec2 first = list[0];
    float x = first.x;
    float y = first.y;
}

