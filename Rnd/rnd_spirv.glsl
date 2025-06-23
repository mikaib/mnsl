#version 450

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

int test_4()
{
    int x = 0;
    int y = 0;
    while (y < x)
    {
        int z = y * 2;
        int w = x * 3;
        int i = z;
        while (i < w)
        {
            if (i == 0)
            {
                z++;
            }
            else
            {
                if (i == 1)
                {
                    z += 2;
                }
                else
                {
                    z += 3;
                }
            }
            i++;
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
        int j_1 = 0;
        while (j_1 < 3)
        {
            y += j_1;
            j_1++;
        }
        j_1 = 0;
        while (j_1 < 3)
        {
            y += j_1;
            j_1++;
        }
        y += 9;
    }
    return y;
}

void main()
{
}

