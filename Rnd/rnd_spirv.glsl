#version 450

int test_1()
{
    int a = 10000;
    if (a == 0)
    {
        return 1;
    }
    else
    {
    }
    return 2;
}

int test_2()
{
    int a = 10000;
    if (a == 0)
    {
        return 1;
    }
    else
    {
    }
    if (a == 1)
    {
        return 2;
    }
    else
    {
    }
    return 3;
}

int test_3()
{
    int a = 10000;
    if (a == 0)
    {
        return 1;
    }
    else
    {
        if (a == 1)
        {
            return 2;
        }
        else
        {
        }
        if (a == 2)
        {
            return 3;
        }
        else
        {
        }
    }
    return 4;
}

int test_4()
{
    int a = 10000;
    if (a == 0)
    {
        return 1;
    }
    else
    {
        if (a == 1)
        {
            return 2;
        }
        else
        {
            if (a == 2)
            {
                return 3;
            }
            else
            {
                return 4;
            }
        }
    }
    return 5;
}

int test_5()
{
    int a = 10000;
    if (a == 0)
    {
        return 1;
    }
    else
    {
        if (a == 1)
        {
            return 2;
        }
        else
        {
            if (a == 2)
            {
                return 3;
            }
            else
            {
                return 4;
            }
        }
        if (a == 4)
        {
            return 5;
        }
        else
        {
        }
    }
    return 6;
}

int test_6()
{
    int a = 1;
    int b = 1;
    if (a == b)
    {
        return 1;
    }
    else
    {
        return 2;
    }
}

void main()
{
}

