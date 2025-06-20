#version 300 core

uniform vec2 u_u_Vec;
uniform vec2 u_u_VecList[10];

vec2 echo(vec2 x) {
    return x;
}

float test(float x) {
    x = x + float(1);
    x = x * float(2);
    x = float(5);
    return x;
}

void main() {
    vec2 vecA = vec2(1) * u_u_Vec;
    float xA = vecA.x;
    float yA = vecA.y;
    float xB = u_u_Vec.x;
    float yB = u_u_Vec.y;
    vec2 vecC = vecA.yx;
    vec2 vecD = u_u_Vec.xy;
    xA = float(1);
    vecA.x = float(1);
    vecA.y = float(2);
    vecA.xy = (vec2(vecA.x));
    vec3 vecE = vecA.xyx;
    vec3 vecF = echo(vecA).xxy;
    float va = 1.0;
    va = va + float(1);
    va = va * float(2);
    va = test(va);
    float qa = va;
    qa = qa / float(2);
    int idx = 0;
    vec2 vecList[10] = u_u_VecList;
    vec2 vecG = vecList[idx];
    vec2 vecH = u_u_VecList[idx];
    float listX = u_u_VecList[idx].x;
    float listY = u_u_VecList[idx].y;
    vec3 listSwizzle = u_u_VecList[idx].xxy;
    float vecGx = vecG.x;
    float vecGy = vecG.y;
    vec3 vecGxyx = vecG.xyx;
    float subswizzle = u_u_VecList[idx].xy.yx.x;
}

