#version 300 core

in vec3 in_Position;
in vec4 in_Colour;
in vec2 in_TexCoords;
out vec4 frag_Colour;
out vec2 frag_TexCoords;
uniform mat4 u_MVP;

void main() {
    gl_Position = vec4(in_Position, 1.0) * u_MVP;
    frag_Colour = in_Colour;
    frag_TexCoords = in_TexCoords;
}

