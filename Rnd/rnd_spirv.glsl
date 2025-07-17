#version 450

uniform sampler2D u_Texture;

layout(location = 0) in vec4 in_Colour;
layout(location = 1) in vec2 in_TexCoords;
layout(location = 2) out vec4 out_FragColour;

void main()
{
    vec2 x = fwidth(in_TexCoords);
    vec2 y = dFdx(in_TexCoords);
    vec2 z = dFdy(in_TexCoords);
    vec2 w = vec2(textureSize(u_Texture, 0));
    vec2 q = w * vec2(float(2));
}

