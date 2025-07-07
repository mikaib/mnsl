#version 450

vec2 squared(vec2 x)
{
    return x * x;
}

vec2 add(vec2 x, int y)
{
    return x + vec2(float(y));
}

void main()
{
    vec2 x = add(squared(vec2(float(5))), 1);
}

