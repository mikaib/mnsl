uniform float u_iTime;
uniform float2 u_iResolution;
uniform sampler2D u_iChannel0;
uniform sampler2D u_iChannel1;
uniform sampler2D u_iChannel2;
uniform sampler2D u_iChannel3;

static float4 gl_FragCoord;
static float2 in_TexCoord;
static float4 out_FragColour;

struct SPIRV_Cross_Input
{
    float2 in_TexCoord : TEXCOORD0;
    float4 gl_FragCoord : VPOS;
};

struct SPIRV_Cross_Output
{
    float4 out_FragColour : COLOR1;
};

float4 getUV()
{
    return gl_FragCoord / float4(u_iResolution.xy, 0.0f, 1.0f);
}

void frag_main()
{
    float4 uv = getUV();
    float3 col = 0.5f.xxx + (0.5f.xxx * cos((u_iTime.xxx + uv.xyx) + float3(float(0), float(2), float(4))));
    out_FragColour = float4(col.xyz, 1.0f);
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    gl_FragCoord = stage_input.gl_FragCoord + float4(0.5f, 0.5f, 0.0f, 0.0f);
    in_TexCoord = stage_input.in_TexCoord;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.out_FragColour = float4(out_FragColour);
    return stage_output;
}
