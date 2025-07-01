#version 450

uniform mat4 u_MVP;

layout(location = 0) in vec3 in_Position;
layout(location = 1) in vec4 in_Colour;
layout(location = 2) in vec2 in_TexCoords;
layout(location = 3) out vec4 out_Colour;
layout(location = 4) out vec2 out_TexCoords;

void main()
{
    gl_Position = vec4(in_Position * u_MVP, 1.0);
    out_Colour = in_Colour;
    out_TexCoords = in_TexCoords;
}

