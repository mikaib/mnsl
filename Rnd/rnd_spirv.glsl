#version 450

int test()
{
    int x = 0;
    int y = 100;
    while (x < y)
    {
        if (y == 10)
        {
            y += 5;
            continue;
        }
        else
        {
            if (y == 50)
            {
                break;
            }
            else
            {
            }
        }
        y++;
    }
    return y;
}

void main()
{
}

