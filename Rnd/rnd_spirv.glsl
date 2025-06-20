#version 450

uniform sampler2D u_Texture;

layout(location = 0) in vec2 in_TexCoord;
layout(location = 1) out vec4 out_FragColour;

void main()
{
    out_FragColour = texture(u_Texture, in_TexCoord);
}

