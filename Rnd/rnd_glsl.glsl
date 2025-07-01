#version 300 core

uniform mat3 u_matA;
uniform mat3 u_matB;
uniform float u_arr[10];

void main() {
    float a0[10] = u_arr;
    float a1 = a0[0];
    vec3 v0 = vec3(1.0, 2.0, 3.0);
    float v1 = v0.y;
    float v2 = v0.y;
    mat3 m0 = u_matA;
    vec3 mr0 = m0[0];
    float mrc0 = m0[0][0 + 1];
    int row = 1;
    int col = 2;
    float mrc1 = m0[row][col];
}

