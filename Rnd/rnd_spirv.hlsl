uniform float3x3 u_matA;
uniform float3x3 u_matB;
uniform float u_arrA[10];
uniform float3 u_arrB[10];
uniform float3x3 u_arrC[10];

void frag_main()
{
    float a0[10] = u_arrA;
    float a1 = a0[0];
    float3 a2[10] = u_arrB;
    float3 v0 = float3(1.0f, 2.0f, 3.0f);
    float v1 = v0.y;
    float v2 = v0.y;
    float3x3 m0 = u_matA;
    float3 mr0 = m0[0];
    float mrc0 = m0[0].x;
    int row = 1;
    int col = 2;
    float mrc1 = m0[row][col];
    int idx = 1;
    a0[idx] = 5.0f;
    v0.x = 5.0f;
    m0[idx].x = 5.0f;
    m0[idx].y = 6.0f;
    m0[idx] = float3(1.0f, 2.0f, 3.0f);
    m0[idx] = 5.0f.xxx;
    a2[idx].x = 5.0f;
    a2[idx].y = 6.0f;
    a2[idx] = 7.0f.xxx;
    m0[idx][idx] = float(4);
    float3x3 p0 = mul(u_matB, u_matA);
    float3x3 p1 = mul(u_matA, u_matB);
    float3x3 p2 = mul(float3x3(2.0f.xxx, 2.0f.xxx, 2.0f.xxx), u_matA);
    float3x3 p3 = mul(u_matA, float3x3(2.0f.xxx, 2.0f.xxx, 2.0f.xxx));
    float3 p5 = mul(float3(1.0f, 2.0f, 3.0f), u_matA);
    float3 p6 = mul(u_matA, float3(1.0f, 2.0f, 3.0f));
    float3x3 p7 = mul(u_matA, u_arrC[idx]);
    float3 p8 = mul(u_matA, u_arrC[idx][idx]);
    float3x3 _246 = mul(u_matA, float3x3(float3(u_arrC[idx][idx][idx], u_arrC[idx][idx][idx], u_arrC[idx][idx][idx]), float3(u_arrC[idx][idx][idx], u_arrC[idx][idx][idx], u_arrC[idx][idx][idx]), float3(u_arrC[idx][idx][idx], u_arrC[idx][idx][idx], u_arrC[idx][idx][idx])));
    float3x3 p9 = _246;
    float3x3 m1 = float3x3(float3(1.0f, 0.0f, 0.0f), float3(0.0f, 1.0f, 0.0f), float3(0.0f, 0.0f, 1.0f));
    float4x4 m2 = float4x4(float4(1.0f, 0.0f, 0.0f, 0.0f), float4(0.0f, 1.0f, 0.0f, 0.0f), float4(0.0f, 0.0f, 1.0f, 0.0f), float4(0.0f, 0.0f, 0.0f, 1.0f));
    float3x3 m3 = float3x3(6.0f.xxx, 6.0f.xxx, 6.0f.xxx);
    float4x4 m4 = float4x4(8.0f.xxxx, 8.0f.xxxx, 8.0f.xxxx, 8.0f.xxxx);
}

void main()
{
    frag_main();
}
