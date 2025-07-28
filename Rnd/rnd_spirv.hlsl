uniform sampler2D u_Texture[16];

static float4 in_Colour;
static float2 in_TexCoords;
static int in_texId;
static float4 out_FragColour;

struct SPIRV_Cross_Input
{
    float4 in_Colour : TEXCOORD0;
    float2 in_TexCoords : TEXCOORD1;
    int in_texId : TEXCOORD2;
};

struct SPIRV_Cross_Output
{
    float4 out_FragColour : COLOR3;
};

uint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)
{
    uint2 ret;
    Tex.GetDimensions(Level, ret.x, ret.y, Param);
    return ret;
}

void frag_main()
{
    uint _60_dummy_parameter;
    float2 x = float(2).xx / float2(int2(spvTextureSize(u_Texture[in_texId], uint(0), _60_dummy_parameter)));
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    in_Colour = stage_input.in_Colour;
    in_TexCoords = stage_input.in_TexCoords;
    in_texId = stage_input.in_texId;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.out_FragColour = float4(out_FragColour);
    return stage_output;
}
