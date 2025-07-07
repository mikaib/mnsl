#version 450

int add_TInt_TInt_RTTInt(int x, int y)
{
    return x + y;
}

void main()
{
    int x = add_TInt_TInt_RTTInt(5, 6);
    int y = add_TInt_TInt_RTTInt(3, 4);
}

