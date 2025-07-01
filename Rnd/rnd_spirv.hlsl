uniform float3x3 u_matA;
uniform float3x3 u_matB;
uniform float u_arr[10];

void frag_main()
{
    float a0[10] = u_arr;
    float a1 = a0[0];
    float3 v0 = float3(1.0f, 2.0f, 3.0f);
    float v1 = v0.y;
    float v2 = v0.y;
}

void main()
{
    frag_main();
}
