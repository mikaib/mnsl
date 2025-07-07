int add_TInt_TInt_RTTInt(int x, int y)
{
    return x + y;
}

void frag_main()
{
    int x = add_TInt_TInt_RTTInt(5, 6);
    int y = add_TInt_TInt_RTTInt(3, 4);
}

void main()
{
    frag_main();
}
