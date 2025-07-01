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
    float3x3 m0 = u_matA;
    float3 mr0 = m0[0];
    float mrc0 = m0[0][0 + 1];
    int row = 1;
    int col = 2;
    float mrc1 = m0[row][col];
}

void main()
{
    frag_main();
}
