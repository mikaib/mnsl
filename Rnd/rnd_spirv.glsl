#version 450

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

void main()
{
    int x = squared(multiply(int(halfOf(multiply(1, 2))), 3));
    float y = float(5) / float(2);
    float a1 = float(5) / 2.0;
    float a2 = 2.0 / float(5);
    float a3 = 2.0 / 5.0;
    vec2 v1 = vec2(float(1), float(2)) / vec2(float(2));
    vec2 v2 = vec2(float(2)) / vec2(float(1), float(2));
    vec2 v3 = vec2(float(1), float(2)) / vec2(float(3), float(4));
    float v = float(5) / float(2);
}

