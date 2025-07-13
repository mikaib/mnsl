uniform sampler2D u_Texture;

static float4 in_Colour;
static float2 in_TexCoords;
static float4 out_FragColour;

struct SPIRV_Cross_Input
{
    float4 in_Colour : TEXCOORD0;
    float2 in_TexCoords : TEXCOORD1;
};

struct SPIRV_Cross_Output
{
    float4 out_FragColour : COLOR2;
};

uint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)
{
    uint2 ret;
    Tex.GetDimensions(Level, ret.x, ret.y, Param);
    return ret;
}

void frag_main()
{
    float2 x = fwidth(in_TexCoords);
    float2 y = ddx(in_TexCoords);
    float2 z = ddy(in_TexCoords);
    uint _62_dummy_parameter;
    float2 w = float2(int2(spvTextureSize(u_Texture, 0u, _62_dummy_parameter)));
    float2 q = w * float(2).xx;
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    in_Colour = stage_input.in_Colour;
    in_TexCoords = stage_input.in_TexCoords;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.out_FragColour = float4(out_FragColour);
    return stage_output;
}
