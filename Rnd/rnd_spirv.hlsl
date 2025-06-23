int test_1()
{
    int x = 0;
    int y = 0;
    while (y < x)
    {
        y++;
    }
    return y;
}

int test_2()
{
    int x = 0;
    int y = 0;
    while (y < x)
    {
        if (y == 0)
        {
            y++;
        }
        else
        {
            if (y == 1)
            {
                y += 2;
            }
            else
            {
                return 1;
            }
        }
        y++;
    }
    return y;
}

int test_3()
{
    int x = 0;
    int y = 0;
    while (y < x)
    {
        int z = y * 2;
        int w = x * 3;
        while (z < w)
        {
            if (z == 0)
            {
                z++;
            }
            else
            {
                if (z == 1)
                {
                    z += 2;
                }
                else
                {
                    z += 3;
                }
            }
            z++;
        }
        if (y == 0)
        {
            y += 6;
        }
        else
        {
            if (y == 1)
            {
                y += 2;
            }
            else
            {
                y += 3;
            }
        }
        y += 9;
    }
    return y;
}

void frag_main()
{
}

void main()
{
    frag_main();
}
