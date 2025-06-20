#version 450

uniform vec2 u_u_VecList[10];

void main()
{
    vec2 list = u_u_VecList;
    vec2 first = list.x;
    float x = first.x;
    float y = first.y;
}

