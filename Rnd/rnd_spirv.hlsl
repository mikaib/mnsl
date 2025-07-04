int test(int x)
{
    int v = x;
    x *= 5;
    x = 5;
    int t = x;
    return x;
}

void frag_main()
{
    int _48 = test(3);
    int v = _48;
}

void main()
{
    frag_main();
}
