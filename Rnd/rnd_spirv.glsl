#version 450

vec2 _mnsl_generic_0(vec2 x)
{
    return x * x;
}

vec2 _mnsl_generic_1(vec2 x, vec2 y)
{
    return x + y;
}

void main()
{
    vec2 x = _mnsl_generic_1(_mnsl_generic_0(vec2(float(5))), vec2(float(1)));
}

