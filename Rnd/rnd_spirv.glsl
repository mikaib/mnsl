#version 450

float test(float x)
{
    return (2.0 * float(3)) + (-(float(1) * x));
}

float cool(float x)
{
    float _mnsl_param_x = x * float(2);
    _mnsl_param_x += 5.0;
    return test(_mnsl_param_x);
}

void main()
{
    float test_1 = 1.2000000476837158203125;
    float someVar = cool(test_1);
    someVar += float(1);
    int q = 3;
}

