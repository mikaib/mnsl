int test(int x)
{
    int y = x * 2;
    int _mnsl_tmp_x = x;
    _mnsl_tmp_x++;
    return _mnsl_tmp_x;
}

void frag_main()
{
    int v = test(1);
}

void main()
{
    frag_main();
}
