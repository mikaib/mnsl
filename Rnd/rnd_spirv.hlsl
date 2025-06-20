uniform float2 u_u_Vec;
uniform float2 u_u_VecList[10];

void frag_main()
{
    float2 x = u_u_Vec;
    x = float2(float(1), float(2));
}

void main()
{
    frag_main();
}
