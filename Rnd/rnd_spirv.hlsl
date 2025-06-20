uniform float2 u_u_Vec;
uniform float2 u_u_VecList[10];

float2 echo(float2 x)
{
    return x;
}

float test(float x)
{
    float _mnsl_param_x = x + float(1);
    _mnsl_param_x = x * float(2);
    _mnsl_param_x = float(5);
    return x;
}

void frag_main()
{
    float2 vecA = float(1).xx * u_u_Vec;
    float xA = vecA.x;
    float yA = vecA.y;
    float xB = u_u_Vec.x;
    float yB = u_u_Vec.y;
    float2 vecC = vecA.yx;
    float2 vecD = u_u_Vec.xy;
    xA = float(1);
    vecA.x = float(1);
    vecA.y = float(2);
    float2 _108 = (vecA.x).xx;
    vecA = float2(_108.x, _108.y);
    float3 vecE = vecA.xyx;
    float3 vecF = echo(vecA).xxy;
    float va = 1.0f;
    va += float(1);
    va *= float(2);
    va = test(va);
    float qa = va;
    qa /= float(2);
    int idx = 0;
    float2 vecList[10] = u_u_VecList;
    float2 vecG = vecList[idx];
    float2 vecH = u_u_VecList[idx];
    float listX = u_u_VecList[idx].x;
    float listY = u_u_VecList[idx].y;
    float3 listSwizzle = u_u_VecList[idx].xxy;
    float vecGx = vecG.x;
    float vecGy = vecG.y;
    float3 vecGxyx = vecG.xyx;
    float subswizzle = u_u_VecList[idx].xy.yx.x;
}

void main()
{
    frag_main();
}
