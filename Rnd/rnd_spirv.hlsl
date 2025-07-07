float2 _mnsl_generic_0(float2 x)
{
    return x * x;
}

float2 _mnsl_generic_1(float2 x, float2 y)
{
    return x + y;
}

void frag_main()
{
    float2 x = _mnsl_generic_1(_mnsl_generic_0(float(5).xx), float(1).xx);
}

void main()
{
    frag_main();
}
