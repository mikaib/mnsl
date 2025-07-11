#version 450

int test(int x)
{
    int y = x * 2;
    int _mnsl_tmp_x = x;
    _mnsl_tmp_x++;
    return _mnsl_tmp_x;
}

void main()
{
    int v = test(1);
}

