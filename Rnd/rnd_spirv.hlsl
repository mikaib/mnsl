uniform float2 u_u_VecList[10];

void frag_main()
{
    float2 list = u_u_VecList;
    float2 first = list.x;
    float x = first.x;
    float y = first.y;
}

void main()
{
    frag_main();
}
