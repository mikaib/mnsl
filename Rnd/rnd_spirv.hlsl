uniform sampler2D u_Texture;

static float2 in_TexCoord;
static float4 out_FragColour;

struct SPIRV_Cross_Input
{
    float2 in_TexCoord : TEXCOORD0;
};

struct SPIRV_Cross_Output
{
    float4 out_FragColour : COLOR1;
};

void frag_main()
{
    out_FragColour = tex2D(u_Texture, in_TexCoord);
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    in_TexCoord = stage_input.in_TexCoord;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.out_FragColour = float4(out_FragColour);
    return stage_output;
}
