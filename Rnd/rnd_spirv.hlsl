uniform float4x4 u_MVP;

static float4 gl_Position;
static float3 in_Position;
static float4 in_Colour;
static float2 in_TexCoords;
static float4 out_Colour;
static float2 out_TexCoords;

struct SPIRV_Cross_Input
{
    float3 in_Position : TEXCOORD0;
    float4 in_Colour : TEXCOORD1;
    float2 in_TexCoords : TEXCOORD2;
};

struct SPIRV_Cross_Output
{
    float4 out_Colour : COLOR3;
    float4 out_TexCoords : COLOR4;
    float4 gl_Position : POSITION;
};

void frag_main()
{
    gl_Position = mul(u_MVP, float4(in_Position, 1.0f));
    out_Colour = in_Colour;
    out_TexCoords = in_TexCoords;
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    in_Position = stage_input.in_Position;
    in_Colour = stage_input.in_Colour;
    in_TexCoords = stage_input.in_TexCoords;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.gl_Position = gl_Position;
    stage_output.out_Colour = float4(out_Colour);
    stage_output.out_TexCoords = float4(out_TexCoords, 0.0, 0.0);
    return stage_output;
}
