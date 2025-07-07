float2 squared(float2 x)
{
    return x * x;
}

float2 add(float2 x, int y)
{
    return x + float(y).xx;
}

void frag_main()
{
    float2 x = add(squared(float(5).xx), 1);
}

void main()
{
    frag_main();
}
