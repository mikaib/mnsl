#version 450

uniform vec2 u_u_Vec;
uniform vec2 u_u_VecList[10];

void main()
{
    vec2 x = u_u_Vec;
    x = vec2(float(1), float(2));
}

