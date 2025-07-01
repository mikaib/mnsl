#version 300 core

uniform mat3 u_matA;
uniform mat3 u_matB;
uniform float u_arrA[10];
uniform vec3 u_arrB[10];
uniform mat3 u_arrC[10];

void main() {
    float a0[10] = u_arrA;
    float a1 = a0[0];
    vec3 a2[10] = u_arrB;
    vec3 v0 = vec3(1.0, 2.0, 3.0);
    float v1 = v0.y;
    float v2 = v0.y;
    mat3 m0 = u_matA;
    vec3 mr0 = m0[0];
    float mrc0 = m0[0][0];
    int row = 1;
    int col = 2;
    float mrc1 = m0[row][col];
    int idx = 1;
    a0[idx] = 5.0;
    v0.x = 5.0;
    m0[idx].x = 5.0;
    m0[idx].y = 6.0;
    m0[idx] = vec3(1.0, 2.0, 3.0);
    m0[idx] = vec3(5.0);
    a2[idx].x = 5.0;
    a2[idx].y = 6.0;
    a2[idx] = vec3(7.0);
    m0[idx][idx] = float(4);
    mat3 p0 = u_matA * u_matB;
    mat3 p1 = u_matB * u_matA;
    mat3 p2 = u_matA * mat3(2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0);
    mat3 p3 = mat3(2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0) * u_matA;
    vec3 p5 = u_matA * vec3(1.0, 2.0, 3.0);
    vec3 p6 = vec3(1.0, 2.0, 3.0) * u_matA;
    mat3 p7 = u_arrC[idx] * u_matA;
    vec3 p8 = u_arrC[idx][idx] * u_matA;
    mat3 p9 = mat3(u_arrC[idx][idx][idx], u_arrC[idx][idx][idx], u_arrC[idx][idx][idx], u_arrC[idx][idx][idx], u_arrC[idx][idx][idx], u_arrC[idx][idx][idx], u_arrC[idx][idx][idx], u_arrC[idx][idx][idx], u_arrC[idx][idx][idx]) * u_matA;
    mat3 m1 = mat3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
    mat4 m2 = mat4(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0);
    mat3 m3 = mat3(6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0);
    mat4 m4 = mat4(8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0);
}

