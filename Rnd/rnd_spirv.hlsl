int multiply(int x, int y)
{
    return x * y;
}

float halfOf(int x)
{
    return float(x) / float(2);
}

int squared(int x)
{
    return x * x;
}

void frag_main()
{
    int x = squared(multiply(int(halfOf(multiply(1, 2))), 3));
    float y = float(5) / float(2);
    float a1 = float(5) / 2.0f;
    float a2 = 2.0f / float(5);
    float a3 = 2.0f / 5.0f;
    float2 v1 = float2(float(1), float(2)) / float(2).xx;
    float2 v2 = float(2).xx / float2(float(1), float(2));
    float2 v3 = float2(float(1), float(2)) / float2(float(3), float(4));
    float v = float(5) / float(2);
}

void main()
{
    frag_main();
}
