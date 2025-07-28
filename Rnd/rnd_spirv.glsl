#version 450

uniform sampler2D u_Texture[16];

layout(location = 0) in vec4 in_Colour;
layout(location = 1) in vec2 in_TexCoords;
layout(location = 2) flat in int in_texId;
layout(location = 3) out vec4 out_FragColour;

void main()
{
    vec2 x = vec2(float(2)) / vec2(textureSize(u_Texture[in_texId], 0));
}

