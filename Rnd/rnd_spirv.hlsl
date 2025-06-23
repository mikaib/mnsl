void frag_main()
{
    float3 v = float(1).xxx;
    float3 _43 = float3(float(1), float(2), float(3));
    v = float3(_43.z, _43.y, _43.x);
}

void main()
{
    frag_main();
}
